unit Realtime.Conversation.HistoryExtractor;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  System.Generics.Defaults, System.JSON, System.DateUtils, System.StrUtils;

type
  TConvMessage = record
    Ts : TDateTime;
    Role : string;
    Text : string;
    class function Create(const ATs: TDateTime; const ARole, AText: string): TConvMessage; static;
  end;

  TConversationExtractor = class
  private
    type
      TMsgAcc = record
        TsISO : string;
        Role : string;
        Text : string;
        /// <summary>
        ///   JSONL order of appearance
        /// </summary>
        Seq : Integer;
        /// <summary>
        ///   For added/done merger and choice by priority
        /// </summary>
        ItemId : string;
        /// <summary>
        ///   Internal tag for debug
        /// </summary>
        Source : string;
        /// <summary>
        ///   Source priority (higher = better)
        /// </summary>
        Prio : Integer;
        class function Create(const ATsISO, ARole, AText: string): TMsgAcc; static;
      end;

  private
    FAcc : TList<TMsgAcc>;
    FOut : TList<TConvMessage>;
    /// <summary>
    /// Sequential counter
    /// </summary>
    FSeq : Integer;
    /// <summary>
    /// item_id -> index in FAcc
    /// </summary>
    FByItemId : TDictionary<string, Integer>;
    FErrorCnt : Integer;

    {--- Parsing helpers }
    class function ISO8601ToDateTimeSafe(const S: string): TDateTime; static;
    class function GetStringDef(const Obj: TJSONObject; const Name, Def: string): string; static;
    class function FirstTextFromItemContent(const Item: TJSONObject): string; static;
    class function FirstContentTypeFromItemContent(const Item: TJSONObject): string; static;

    {--- Pipeline }
    procedure ParseLine(const Line: string);
    procedure DispatchEvent(const TsISO: string; const Ev: TJSONObject);

    {--- Handles }
    procedure HandleConversationItem(const TsISO, EType: string; const Ev: TJSONObject);
    procedure HandleUserAudioCompleted(const TsISO: string; const Ev: TJSONObject);
    procedure HandleAssistantAudioDone(const TsISO: string; const Ev: TJSONObject);

    procedure MaybeAddItemMessage(const TsISO, EType: string; const ItemObj: TJSONObject);
    procedure AddMessage(const TsISO, Role, Text, ItemId, Source: string; const Priority: Integer); overload;

    procedure SortAccChronologically;
    procedure DeduplicateAdjacent;

    procedure BuildOutputArray;

  public
    constructor Create;
    destructor Destroy; override;

    function FromStrings(const Lines: TStrings): TArray<TConvMessage>;
    function FromStream(AStream: TStream; const Encoding: TEncoding = nil): TArray<TConvMessage>;
    function FromFile(const AFileName: string): TArray<TConvMessage>;

    class function ExtractFromJsonl(const AFileName: string): TArray<TConvMessage>; static;
  end;

implementation

{$REGION 'Dev note'}

(*
    Developer Note - Realtime.Conversation.HistoryExtractor
    =======================================================

    Purpose
    -------
    Extract a readable conversation timeline (timestamp, role, text) from a JSONL
    stream of realtime events (OpenAI Realtime / Assistants style).
    This unit consolidates scattered signals (items added/done, audio transcripts, etc.),
    resolves duplicates, arbitrates by priority, and produces a compact sequence of
    TConvMessage.

    Expected input (implicit schema)
    --------------------------------
    Each line is a JSON (JSONL) with at minimum:
      - ts   : ISO8601 timestamp (UTC or local).
      - event: object with type and depending on case item, item_id, transcript, …

    Handled event types:
      - conversation.item.added / conversation.item.done
        (field item with type="message", role in [user,assistant],
         and a content array of objects { type, text|transcript }).
      - conversation.item.input_audio_transcription.completed
        (fields transcript, item_id).
      - response.output_audio_transcript.done
        (fields transcript, item_id).

    Output
    ------
    TArray<TConvMessage> where each element has:
      - Ts   : TDateTime local (ISO8601 conversion, handling suffix Z).
      - Role : user or assistant.
      - Text : consolidated text.

    Processing pipeline (overview)
    ------------------------------
    1) Parse line by line (ParseLine) : ignore empty or malformed lines (error counter increments).
    2) Dispatch (DispatchEvent) : routes to a dedicated handler depending on event.type.
    3) Accumulate (FAcc : TList<TMsgAcc>) :
       - Each candidate message is wrapped in TMsgAcc with metadata: Seq (JSONL order),
         TsISO, Role, Text, ItemId, Source, Prio.
       - Merge by item_id : if an item_id already exists, replace ONLY if the new signal
         has a higher priority (handles added/done/transcript arbitration).
    4) Sort (SortAccChronologically) : primarily by Seq (file order), fallback to
       Ts, then Role, then Text. This guarantees stability with equal/close timestamps.
    5) Deduplicate (DeduplicateAdjacent) :
       - Remove exact adjacent duplicates (same role + same text).
       - Time-window dedup C_DUP_WINDOW_MS = 250 ms on key (Role|Text) to drop near-repetitions.
    6) Compact (BuildOutputArray) :
       - Merge consecutive messages of the same role using space concatenation
         (keep Ts of the first element in group).

    Priorities (source arbitration)
    -------------------------------
    Higher = better (overwrites previous entries with same item_id).

      - USER:
          PRIO_USER_INPUT_TEXT (conversation.item.added/done input_text)        = 10
          PRIO_USER_AUDIO_COMPLETED (input_audio_transcription.completed)       = 40
      - ASSISTANT:
          PRIO_ASSIST_ADDED_OUTPUT_TEXT (item.added output_text)                = 10
          PRIO_ASSIST_DONE_OUTPUT_TEXT  (item.done  output_text)                = 20
          PRIO_ASSIST_DONE_OUTPUT_AUDIO (item.done  output_audio.transcript)    = 30
          PRIO_ASSIST_RESP_OUT_AUDIO_DONE (response.output_audio_transcript)    = 40

    Text extraction rules
    ---------------------
    - In conversation.item.*:
      - content[0].type in {input_text, output_text}  ⇒ use text
      - content[0].type = output_audio                ⇒ use transcript if present
    - In *.transcription.completed / *.audio_transcript.done:
      - use field transcript (finalized text).

    Timestamps
    ----------
    - ISO8601ToDateTimeSafe handles suffix Z (UTC) and converts to local time.
    - Sorting primarily uses Seq (file order) to avoid bias from equal or slightly
      disordered timestamps.

    Robustness strategies
    ---------------------
    - Graceful handling of partial shapes : missing fields ⇒ message skipped.
    - Merge by item_id + priorities ⇒ best version is kept (e.g. final transcript replaces draft).
    - Deduplication by adjacency + 250ms window ⇒ clean output without redundant repetitions.

    Complexity
    ----------
    - Time: O(N log N) due to sorting (N = #valid lines). Other passes are linear.
    - Memory: O(N) for accumulator + dictionaries (FByItemId, last-timestamps map).

    Points of attention
    -------------------
    - Only user and assistant roles are preserved (others ignored).
    - Consecutive merge uses space as separator (no punctuation added). Adapt if needed.
    - FByItemId indexes the last retained occurrence of an item_id (safe read-modify-write).
    - FErrorCnt counts malformed lines but is not exposed (could be useful for telemetry).

    Extensibility
    -------------
    - To support new event types: add handler + define a priority.
    - Merge policy: replace space with configurable separator; add time-based max-gap.
    - Deduplication: adjust C_DUP_WINDOW_MS or key definition (include Source).
    - Time zone handling: add option to skip local conversion if raw UTC is needed.

    Public API
    ----------
    - FromStrings, FromStream, FromFile : multi-source ingestion, UTF-8 by default.
    - ExtractFromJsonl(AFileName) : static helper.
    - TConvMessage : minimal record (Ts, Role, Text) for export (CSV/Markdown/UI).

    Summary
    -------
    The component turns a noisy event stream into a coherent conversation timeline,
    arbitrating duplicates with item_id and priorities, smoothing short-term repetitions,
    and compacting messages by role. The result is ready for display, logging, or analytic
    post-processing.
*)

{$ENDREGION}

const
  /// <summary>
  ///   Additional deduplication window (exact role+text) ~ 250ms
  /// </summary>
  C_DUP_WINDOW_MS = 250;

  {--- Priorities (higher = better) }

  /// <summary>
  ///   USER: conversation.item.added/done (input_text)
  /// </summary>
  PRIO_USER_INPUT_TEXT = 10;

  /// <summary>
  ///   USER: conversation.item.input_audio_transcription.completed
  /// </summary>
  PRIO_USER_AUDIO_COMPLETED = 40;

  /// <summary>
  ///   ASSISTANT: conversation.item.added (output_text)
  /// </summary>
  PRIO_ASSIST_ADDED_OUTPUT_TEXT = 10;

  /// <summary>
  ///   ASSISTANT: conversation.item.done (output_text)
  /// </summary>
  PRIO_ASSIST_DONE_OUTPUT_TEXT = 20;

  /// <summary>
  ///   ASSISTANT: conversation.item.done  (output_audio.transcript)
  /// </summary>
  PRIO_ASSIST_DONE_OUTPUT_AUDIO = 30;

  /// <summary>
  ///   ASSISTANT: response.output_audio_transcript.done
  /// </summary>
  PRIO_ASSIST_RESP_OUT_AUDIO_DONE = 40;

class function TConversationExtractor.GetStringDef(
  const Obj: TJSONObject;
  const Name, Def: string): string;
begin
  if not Assigned(Obj) then
    Exit(Def);
  var V := Obj.Values[Name];
  Result := IfThen(Assigned(V), V.Value, Def);
end;

class function TConversationExtractor.ISO8601ToDateTimeSafe(const S: string): TDateTime;
begin
  var L := S;
  var HasZ := L.EndsWith('Z', True);

  if HasZ then
    L := L.Substring(0, L.Length - 1);

  Result := ISO8601ToDate(L, False);

  if HasZ then
    Result := TTimeZone.Local.ToLocalTime(Result);
end;

class function TConversationExtractor.FirstTextFromItemContent(
  const Item: TJSONObject): string;
begin
  Result := EmptyStr;

  if not Assigned(Item) then Exit;

  var Arr := Item.Values['content'] as TJSONArray;
  if not Assigned(Arr) then Exit;

  for var I := 0 to Arr.Count - 1 do
    begin
      if not (Arr.Items[I] is TJSONObject) then
        Continue;

      var CObj  := TJSONObject(Arr.Items[I]);
      var CType := GetStringDef(CObj, 'type', '');

      if (CType = 'input_text') or (CType = 'output_text') then
        Exit(GetStringDef(CObj, 'text', ''))
      else
      if (CType = 'output_audio') then
        {--- TTS transcript possibly }
        Exit(GetStringDef(CObj, 'transcript', ''));
    end;
end;

class function TConversationExtractor.FirstContentTypeFromItemContent(
  const Item: TJSONObject): string;
begin
  Result := EmptyStr;

  if not Assigned(Item) then Exit;

  var Arr := Item.Values['content'] as TJSONArray;
  if not Assigned(Arr) then Exit;

  for var I := 0 to Arr.Count - 1 do
    if Arr.Items[I] is TJSONObject then
      begin
        var CObj := TJSONObject(Arr.Items[I]);
        Exit(GetStringDef(CObj, 'type', ''));
      end;
end;

class function TConversationExtractor.ExtractFromJsonl(
  const AFileName: string): TArray<TConvMessage>;
begin
  with TConversationExtractor.Create do
    try
      Result := FromFile(AFileName);
    finally
      Free;
    end;
end;

constructor TConversationExtractor.Create;
begin
  inherited Create;
  FAcc := TList<TMsgAcc>.Create;
  FOut := TList<TConvMessage>.Create;
  FByItemId := TDictionary<string, Integer>.Create;
  FSeq := 0;
  FErrorCnt := 0;
end;

destructor TConversationExtractor.Destroy;
begin
  FByItemId.Free;
  FOut.Free;
  FAcc.Free;
  inherited;
end;

procedure TConversationExtractor.AddMessage(
  const TsISO, Role, Text, ItemId, Source: string;
  const Priority: Integer);
var
  M : TMsgAcc;
  Idx : Integer;
begin
  if Text.IsEmpty or not ((Role = 'user') or (Role = 'assistant')) then
    Exit;

  {--- If we have an item_id, we merge by priority }
  if not ItemId.IsEmpty and FByItemId.TryGetValue(ItemId, Idx) then
    begin
      {--- We only replace if the new source has a better priority }
      var Keep := Priority > FAcc[Idx].Prio;
      if Keep then
        begin
          {--- IMPORTANT: read-modify-write
               copy of the element }
          M := FAcc[Idx];

          {--- We keep the original order (Seq) to respect the JSONL order }
          M.Role   := Role;
          M.Text   := Text;

          {--- TsISO: we can keep the original for display (order guaranteed by Seq) }
          M.Source := Source;
          M.Prio   := Priority;

          {--- We write the modified element }
          FAcc[Idx] := M;
        end;
      Exit;
    end;

  {--- new message: save }
  Inc(FSeq);
  M := TMsgAcc.Create(TsISO, Role, Text);
  M.Seq    := FSeq;
  M.ItemId := ItemId;
  M.Source := Source;
  M.Prio   := Priority;
  FAcc.Add(M);

  if not ItemId.Trim.IsEmpty then
    FByItemId.AddOrSetValue(ItemId, FAcc.Count - 1);
end;

procedure TConversationExtractor.MaybeAddItemMessage(
  const TsISO, EType: string; const ItemObj: TJSONObject);
var
  Prio: Integer;
  Source: string;
begin
  if not Assigned(ItemObj) then Exit;

  var ItemType := GetStringDef(ItemObj, 'type', '');
  if ItemType <> 'message' then Exit;

  var Role := GetStringDef(ItemObj, 'role', '');
  if not ((Role = 'user') or (Role = 'assistant')) then Exit;

  var ItemId := GetStringDef(ItemObj, 'id', '');
  var C0Type := FirstContentTypeFromItemContent(ItemObj);
  var Text := FirstTextFromItemContent(ItemObj);

  {--- Priority by role / content type / added vs done }
  if Role = 'user' then
    begin
      {--- input_text from conversation.item.added/done }
      Prio   := PRIO_USER_INPUT_TEXT;
      Source := EType + '(' + C0Type + ')';
    end
  else
    begin
      {--- assistant }
      if SameText(EType, 'conversation.item.added') then
        begin
          if C0Type = 'output_text' then
            Prio := PRIO_ASSIST_ADDED_OUTPUT_TEXT
          else
          if C0Type = 'output_audio' then
            Prio := PRIO_ASSIST_DONE_OUTPUT_AUDIO
          else
            Prio := PRIO_ASSIST_ADDED_OUTPUT_TEXT;
        end
      else
        begin
          {--- conversation.item.done }
          if C0Type = 'output_audio'
            then Prio := PRIO_ASSIST_DONE_OUTPUT_AUDIO
          else
            Prio := PRIO_ASSIST_DONE_OUTPUT_TEXT;
        end;
      Source := EType + '(' + C0Type + ')';
    end;

  AddMessage(TsISO, Role, Text, ItemId, Source, Prio);
end;

procedure TConversationExtractor.HandleConversationItem(
  const TsISO, EType: string; const Ev: TJSONObject);
begin
  if (EType = 'conversation.item.added') or (EType = 'conversation.item.done') then
    begin
      var ItemObj := Ev.Values['item'] as TJSONObject;
      MaybeAddItemMessage(TsISO, EType, ItemObj);
    end;
end;

procedure TConversationExtractor.HandleUserAudioCompleted(
  const TsISO: string; const Ev: TJSONObject);
begin
  var Text := GetStringDef(Ev, 'transcript', '');
  var ItemId := GetStringDef(Ev, 'item_id', '');
  AddMessage(TsISO, 'user', Text, ItemId, 'input_audio_transcription.completed', PRIO_USER_AUDIO_COMPLETED);
end;

procedure TConversationExtractor.HandleAssistantAudioDone(
  const TsISO: string; const Ev: TJSONObject);
begin
  var Text := GetStringDef(Ev, 'transcript', '');
  var ItemId := GetStringDef(Ev, 'item_id', '');
  AddMessage(TsISO, 'assistant', Text, ItemId, 'response.output_audio_transcript.done', PRIO_ASSIST_RESP_OUT_AUDIO_DONE);
end;

procedure TConversationExtractor.DispatchEvent(const TsISO: string; const Ev: TJSONObject);
begin
  if not Assigned(Ev) then Exit;

  var EType := GetStringDef(Ev, 'type', '');

  if (EType = 'conversation.item.added') or (EType = 'conversation.item.done') then
    begin
      HandleConversationItem(TsISO, EType, Ev);
      Exit;
    end;

  if (EType = 'conversation.item.input_audio_transcription.completed') then
    begin
      HandleUserAudioCompleted(TsISO, Ev);
      Exit;
    end;

  if (EType = 'response.output_audio_transcript.done') then
    begin
      HandleAssistantAudioDone(TsISO, Ev);
      Exit;
    end;
end;

procedure TConversationExtractor.ParseLine(const Line: string);
var
  Root: TJSONObject;
  Ev: TJSONObject;
  TsISO: string;
begin
  var L := Line.Trim;
  if L.IsEmpty then Exit;

  Root := nil;
  try
    Root := TJSONObject.ParseJSONValue(L) as TJSONObject;
    if not Assigned(Root) then Exit;

    TsISO := GetStringDef(Root, 'ts', '');
    if TsISO.Trim.IsEmpty then Exit;

    Ev := Root.Values['event'] as TJSONObject;
    DispatchEvent(TsISO, Ev);
  except
    on E: Exception do
    begin
      Inc(FErrorCnt);
      {--- The malformed line is ignored }
    end;
  end;

  if Assigned(Root) then
    Root.Free;
end;

procedure TConversationExtractor.SortAccChronologically;
begin
  {--- The order of appearance (Seq) is respected. Fallback to ts/role/text if equal. }
  FAcc.Sort(TComparer<TMsgAcc>.Construct(
    function(const L, R: TMsgAcc): Integer
    var
      DL: TDateTime;
      DR: TDateTime;
    begin
      Result := L.Seq - R.Seq;
      if Result <> 0 then Exit;

      DL := ISO8601ToDateTimeSafe(L.TsISO);
      DR := ISO8601ToDateTimeSafe(R.TsISO);

      var C := CompareDateTime(DL, DR);
      if C <> 0 then Exit(C);

      C := CompareText(L.Role, R.Role);
      if C <> 0 then Exit(C);

      Result := CompareStr(L.Text, R.Text);
    end));
end;

procedure TConversationExtractor.DeduplicateAdjacent;
var
  CurrTs, PrevTs: TDateTime;
begin
  FOut.Clear;
  var LastRole := EmptyStr;
  var LastText := EmptyStr;

  var MapLastTs := TDictionary<string, TDateTime>.Create;
  try
    var WinDays := C_DUP_WINDOW_MS / MSecsPerDay;

    for var I := 0 to FAcc.Count - 1 do
    begin
      CurrTs := ISO8601ToDateTimeSafe(FAcc[I].TsISO);

      {--- Immediate adjacent dedup }
      if (FOut.Count > 0) and
         (SameText(FOut.Last.Role, FAcc[I].Role)) and
         (FOut.Last.Text = FAcc[I].Text) then
        Continue;

      {--- Duplicate window Δt (role+text replicated very close together) }
      var Key := FAcc[I].Role + '|' + FAcc[I].Text;
      if MapLastTs.TryGetValue(Key, PrevTs) then
        begin
          if (CurrTs - PrevTs) <= WinDays then
            begin
              {--- We drop the repetition too close }
              Continue;
            end;
        end;

      FOut.Add(TConvMessage.Create(CurrTs, FAcc[I].Role, FAcc[I].Text));
      MapLastTs.AddOrSetValue(Key, CurrTs);

      LastRole := FAcc[I].Role;
      LastText := FAcc[I].Text;
    end;
  finally
    MapLastTs.Free;
  end;
end;

procedure TConversationExtractor.BuildOutputArray;
{--- Merge consecutive USERs }

  function JoinWithSpace(const A, B: string): string;
  begin
    {--- Merge with spaces }
    Result := TrimRight(A) + ' ' + TrimLeft(B);
  end;

var
  Last, Curr: TConvMessage;
begin
  {--- Merges consecutive messages of the same role (user or assistant) }
  if FOut.Count <= 1 then Exit;

  var Merged := TList<TConvMessage>.Create;
  try
    for var I := 0 to FOut.Count - 1 do
    begin
      Curr := FOut[I];

      if (Merged.Count > 0) and SameText(Merged.Last.Role, Curr.Role) then
        begin
          Last := Merged[Merged.Count - 1];

          {--- Keep the Ts of the first }
          Last.Text := JoinWithSpace(Last.Text, Curr.Text);
          Merged[Merged.Count - 1] := Last;
        end
      else
        Merged.Add(Curr);
    end;

    FOut.Clear;
    for var J := 0 to Merged.Count - 1 do
      FOut.Add(Merged[J]);
  finally
    Merged.Free;
  end;
end;

function TConversationExtractor.FromStrings(const Lines: TStrings): TArray<TConvMessage>;
begin
  FAcc.Clear;
  FOut.Clear;
  FByItemId.Clear;
  FSeq := 0;
  FErrorCnt := 0;

  for var I := 0 to Lines.Count - 1 do
    ParseLine(Lines[I]);

  SortAccChronologically;
  DeduplicateAdjacent;
  {--- Consecutive USER merge (second pass) }
  BuildOutputArray;

  Result := FOut.ToArray;
end;

function TConversationExtractor.FromStream(AStream: TStream; const Encoding: TEncoding): TArray<TConvMessage>;
begin
  var SL := TStringList.Create;
  try
    SL.LineBreak := sLineBreak;
    SL.Text := EmptyStr;
    if Assigned(Encoding) then
      SL.LoadFromStream(AStream, Encoding)
    else
      SL.LoadFromStream(AStream, TEncoding.UTF8);
    Result := FromStrings(SL);
  finally
    SL.Free;
  end;
end;

function TConversationExtractor.FromFile(const AFileName: string): TArray<TConvMessage>;
begin
  var SL := TStringList.Create;
  try
    SL.LoadFromFile(AFileName, TEncoding.UTF8);
    Result := FromStrings(SL);
  finally
    SL.Free;
  end;
end;

{ TConvMessage }

class function TConvMessage.Create(const ATs: TDateTime; const ARole,
  AText: string): TConvMessage;
begin
  Result.Ts   := ATs;
  Result.Role := ARole;
  Result.Text := AText;
end;

{ TConversationExtractor.TMsgAcc }

class function TConversationExtractor.TMsgAcc.Create(
  const ATsISO, ARole, AText: string): TMsgAcc;
begin
  Result.TsISO  := ATsISO;
  Result.Role   := ARole;
  Result.Text   := AText;
  Result.Seq    := 0;
  Result.ItemId := EmptyStr;
  Result.Source := EmptyStr;
  Result.Prio   := 0;
end;

end.

