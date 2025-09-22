unit Realtime.Events.Server;

interface

uses
  System.SysUtils, System.JSON, System.Generics.Collections,
  REST.Json.Types, REST.JsonReflect, REST.Json,
  Audio.Web.Assets, Realtime.API.JsonParams, Realtime.Types,
  JSON.PolymorphicMapper, Realtime.Events.DTOs.Helper;

type

  {$REGION 'session'}

  TSession_created = class(TRawJsonBase)
  private
    FType: string;
    [JsonNameAttribute('event_id')] FEventId: string;
    FSession: TSession;
  public
    property &Type: string read FType write FType;
    property EventId: string read FEventId write FEventId;
    property Session: TSession read FSession write FSession;
    destructor Destroy; override;
    class function FromJson(const Value: string): TSession_created;
  end;

  TSession_updated = TSession_created;

  {$ENDREGION}

  {$REGION 'conversation'}

  TConversation_item_added = class(TRawJsonBase)
  private
    FType: string;
    [JsonNameAttribute('event_id')] FEventId: string;
    FItem: TResponseItem;
    [JsonNameAttribute('previous_item_id')] FPreviousItemId: string;
  public
    property &Type: string read FType write FType;
    property EventId: string read FEventId write FEventId;
    property Item: TResponseItem read FItem write FItem;
    property PreviousItemId: string read FPreviousItemId write FPreviousItemId;
    destructor Destroy; override;
    class function FromJson(const Value: string): TConversation_item_added;
  end;

  Tconversation_item_done = TConversation_item_added;

  TConversation_item_retrieved = TConversation_item_added;

  TConversation_item_input_audio_transcription_completed = class(TRawJsonBase)
  private
    FType: string;
    [JsonNameAttribute('content_index')] FContentIndex: Int64;
    [JsonNameAttribute('event_id')]      FEventId: string;
    [JsonNameAttribute('item_id')]       FItemId: string;
    FLogprobs: TArray<TLogprobs>;
    FTranscript: string;
    FUsage: TUsage;
  public
    property &Type: string read FType write FType;
    property ContentIndex: Int64 read FContentIndex write FContentIndex;
    property EventId: string read FEventId write FEventId;
    property ItemId: string read FItemId write FItemId;
    property Logprobs: TArray<TLogprobs> read FLogprobs write FLogprobs;
    property Transcript: string read FTranscript write FTranscript;
    property Usage: TUsage read FUsage write FUsage;
    destructor Destroy; override;
    class function FromJson(const Value: string): TConversation_item_input_audio_transcription_completed;
  end;

  TConversation_item_input_audio_transcription_delta = class(TRawJsonBase)
  private
    FType: string;
    [JsonNameAttribute('content_index')] FContentIndex: Int64;
    [JsonNameAttribute('event_id')]      FEventId: string;
    [JsonNameAttribute('item_id')]       FItemId: string;
    FDelta: string;
    FLogprobs: TArray<TLogprobs>;
    FObfuscation: string;
  public
    property &Type: string read FType write FType;
    property ContentIndex: Int64 read FContentIndex write FContentIndex;
    property EventId: string read FEventId write FEventId;
    property ItemId: string read FItemId write FItemId;
    property Delta: string read FDelta write FDelta;
    property Logprobs: TArray<TLogprobs> read FLogprobs write FLogprobs;
    property Obfuscation: string read FObfuscation write FObfuscation;
    destructor Destroy; override;
    class function FromJson(const Value: string): TConversation_item_input_audio_transcription_delta;
  end;

  TConversation_item_input_audio_transcription_segment = class(TRawJsonBase)
  private
    FType: string;
    [JsonNameAttribute('content_index')] FContentIndex: Int64;
    FEnd: Double;
    [JsonNameAttribute('event_id')]      FEventId: string;
    FId: string;
    [JsonNameAttribute('item_id')]       FItemId: string;
    FSpeaker: string;
    FStart: Double;
    FText: string;
  public
    property &Type: string read FType write FType;
    property ContentIndex: Int64 read FContentIndex write FContentIndex;
    property &End: Double read FEnd write FEnd;
    property EventId: string read FEventId write FEventId;
    property Id: string read FId write FId;
    property ItemId: string read FItemId write FItemId;
    property Speaker: string read FSpeaker write FSpeaker;
    property Start: Double read FStart write FStart;
    property Text: string read FText write FText;
    class function FromJson(const Value: string): TConversation_item_input_audio_transcription_segment;
  end;

  TConversation_item_input_audio_transcription_failed = class(TRawJsonBase)
  private
    FType: string;
    [JsonNameAttribute('content_index')] FContentIndex: Int64;
    FError: TTranscriptionError;
    [JsonNameAttribute('event_id')]      FEventId: string;
    [JsonNameAttribute('item_id')]       FItemId: string;
  public
    property &Type: string read FType write FType;
    property ContentIndex: Int64 read FContentIndex write FContentIndex;
    property Error: TTranscriptionError read FError write FError;
    property EventId: string read FEventId write FEventId;
    property ItemId: string read FItemId write FItemId;
    destructor Destroy; override;
    class function FromJson(const Value: string): TConversation_item_input_audio_transcription_failed;
  end;

  TConversation_item_truncated = class(TRawJsonBase)
  private
    FType: string;
    [JsonNameAttribute('audio_end_ms')]  FAudioEndMs: Int64;
    [JsonNameAttribute('content_index')] FContentIndex: Int64;
    [JsonNameAttribute('event_id')]      FEventId: string;
    [JsonNameAttribute('item_id')]       FItemId: string;
  public
    property &Type: string read FType write FType;
    property AudioEndMs: Int64 read FAudioEndMs write FAudioEndMs;
    property ContentIndex: Int64 read FContentIndex write FContentIndex;
    property EventId: string read FEventId write FEventId;
    property ItemId: string read FItemId write FItemId;
    class function FromJson(const Value: string): TConversation_item_truncated;
  end;

  TConversation_item_deleted = class(TRawJsonBase)
  private
    FType: string;
    [JsonNameAttribute('event_id')]      FEventId: string;
    [JsonNameAttribute('item_id')]       FItemId: string;
  public
    property &Type: string read FType write FType;
    property EventId: string read FEventId write FEventId;
    property ItemId: string read FItemId write FItemId;
    class function FromJson(const Value: string): TConversation_item_deleted;
  end;

  {$ENDREGION}

  {$REGION 'input_audio_buffer'}

  TInput_audio_buffer_committed = class(TRawJsonBase)
  private
    FType: string;
    [JsonNameAttribute('event_id')] FEventId: string;
    [JsonNameAttribute('item_id')]  FItemId: string;
    [JsonNameAttribute('previous_item_id')] FPreviousItemId: string;
  public
    property &Type: string read FType write FType;
    property EventId: string read FEventId write FEventId;
    property ItemId: string read FItemId write FItemId;
    property PreviousItemId: string read FPreviousItemId write FPreviousItemId;
    class function FromJson(const Value: string): TInput_audio_buffer_committed;
  end;

  TInput_audio_buffer_cleared = class(TRawJsonBase)
  private
    FType: string;
    [JsonNameAttribute('event_id')] FEventId: string;
  public
    property &Type: string read FType write FType;
    property EventId: string read FEventId write FEventId;
    class function FromJson(const Value: string): TInput_audio_buffer_cleared;
  end;

  TInput_audio_buffer_speech_started = class(TRawJsonBase)
  private
    FType: string;
    [JsonNameAttribute('audio_start_ms')] FAudioStartMs: Int64;
    [JsonNameAttribute('event_id')]       FEventId: string;
    [JsonNameAttribute('item_id')]        FItemId: string;
  public
    property &Type: string read FType write FType;
    property AudioStartMs: Int64 read FAudioStartMs write FAudioStartMs;
    property EventId: string read FEventId write FEventId;
    property ItemId: string read FItemId write FItemId;
    class function FromJson(const Value: string): TInput_audio_buffer_speech_started;
  end;

  TInput_audio_buffer_speech_stopped = class(TRawJsonBase)
  private
    FType: string;
    [JsonNameAttribute('audio_end_ms')] FAudioEndMs: Int64;
    [JsonNameAttribute('event_id')]     FEventId: string;
    [JsonNameAttribute('item_id')]      FItemId: string;
  public
    property &Type: string read FType write FType;
    property AudioEndMs: Int64 read FAudioEndMs write FAudioEndMs;
    property EventId: string read FEventId write FEventId;
    property ItemId: string read FItemId write FItemId;
    class function FromJson(const Value: string): TInput_audio_buffer_speech_stopped;
  end;

  TInput_audio_buffer_timeout_triggered = class(TRawJsonBase)
  private
    FType: string;
    [JsonNameAttribute('audio_start_ms')] FAudioStartMs: Int64;
    [JsonNameAttribute('audio_end_ms')] FAudioEndMs: Int64;
    [JsonNameAttribute('event_id')]       FEventId: string;
    [JsonNameAttribute('item_id')]        FItemId: string;
  public
    property &Type: string read FType write FType;
    property AudioStartMs: Int64 read FAudioStartMs write FAudioStartMs;
    property AudioEndMs: Int64 read FAudioEndMs write FAudioEndMs;
    property EventId: string read FEventId write FEventId;
    property ItemId: string read FItemId write FItemId;
    class function FromJson(const Value: string): TInput_audio_buffer_timeout_triggered;
  end;

  {$ENDREGION}

  {$REGION 'output_audio_buffer'}

  TOutput_audio_buffer_started = class(TRawJsonBase)
  private
    FType: string;
    [JsonNameAttribute('event_id')]    FEventId: string;
    [JsonNameAttribute('response_id')] FResponseId: string;
  public
    property &Type: string read FType write FType;
    property EventId: string read FEventId write FEventId;
    property ResponseId: string read FResponseId write FResponseId;
    class function FromJson(const Value: string): TOutput_audio_buffer_started;
  end;

  TOutput_audio_buffer_stopped = TOutput_audio_buffer_started;

  TOutput_audio_buffer_cleared = TOutput_audio_buffer_started;

  {$ENDREGION}

  {$REGION 'response'}

  TResponse_created = class(TRawJsonBase)
  private
    FType: string;
    FResponse: TResponseResource;
    [JsonNameAttribute('event_id')] FEventId: string;
  public
    property &Type: string read FType write FType;
    property Response: TResponseResource read FResponse write FResponse;
    property EventId: string read FEventId write FEventId;
    destructor Destroy; override;
    class function FromJson(const Value: string): TResponse_created;
  end;

  TResponse_done = TResponse_created;

  TResponse_output_item_added = class(TRawJsonBase)
  private
    FType: string;
    [JsonNameAttribute('event_id')] FEventId: string;
    FItem: TResponseItem;
    [JsonNameAttribute('output_index')]  FOutputIndex: Int64;
    [JsonNameAttribute('response_id')]   FResponseId: string;
  public
    property &Type: string read FType write FType;
    property EventId: string read FEventId write FEventId;
    property Item: TResponseItem read FItem write FItem;
    property OutputIndex: Int64 read FOutputIndex write FOutputIndex;
    property ResponseId: string read FResponseId write FResponseId;
    destructor Destroy; override;
    class function FromJson(const Value: string): TResponse_output_item_added;
  end;

  TResponse_output_item_done = TResponse_output_item_added;

  TResponse_content_part_added = class(TRawJsonBase)
  private
    FType: string;
    [JsonNameAttribute('content_index')] FContentIndex: Int64;
    [JsonNameAttribute('event_id')]      FEventId: string;
    [JsonNameAttribute('item_id')]       FItemId: string;
    [JsonNameAttribute('output_index')]  FOutputIndex: Int64;
    FPart: TContentPart;
    [JsonNameAttribute('response_id')]   FResponseId: string;
  public
    property &Type: string read FType write FType;
    property ContentIndex: Int64 read FContentIndex write FContentIndex;
    property EventId: string read FEventId write FEventId;
    property ItemId: string read FItemId write FItemId;
    property OutputIndex: Int64 read FOutputIndex write FOutputIndex;
    property Part: TContentPart read FPart write FPart;
    property ResponseId: string read FResponseId write FResponseId;
    destructor Destroy; override;
    class function FromJson(const Value: string): TResponse_content_part_added;
  end;

  TResponse_content_part_done = TResponse_content_part_added;

  TResponse_output_text_delta = class(TRawJsonBase)
  private
    FType: string;
    [JsonNameAttribute('content_index')] FContentIndex: Int64;
    FDelta: string;
    [JsonNameAttribute('event_id')]      FEventId: string;
    [JsonNameAttribute('item_id')]       FItemId: string;
    [JsonNameAttribute('output_index')]  FOutputIndex: Int64;
    [JsonNameAttribute('response_id')]   FResponseId: string;
  public
    property &Type: string read FType write FType;
    property ContentIndex: Int64 read FContentIndex write FContentIndex;
    property Delta: string read FDelta write FDelta;
    property EventId: string read FEventId write FEventId;
    property ItemId: string read FItemId write FItemId;
    property OutputIndex: Int64 read FOutputIndex write FOutputIndex;
    property ResponseId: string read FResponseId write FResponseId;
    class function FromJson(const Value: string): TResponse_output_text_delta;
  end;

  TResponse_output_text_done = class(TRawJsonBase)
  private
    FType: string;
    [JsonNameAttribute('content_index')] FContentIndex: Int64;
    [JsonNameAttribute('event_id')]      FEventId: string;
    [JsonNameAttribute('item_id')]       FItemId: string;
    [JsonNameAttribute('output_index')]  FOutputIndex: Int64;
    [JsonNameAttribute('response_id')]   FResponseId: string;
    FText: string;
  public
    property &Type: string read FType write FType;
    property ContentIndex: Int64 read FContentIndex write FContentIndex;
    property EventId: string read FEventId write FEventId;
    property ItemId: string read FItemId write FItemId;
    property OutputIndex: Int64 read FOutputIndex write FOutputIndex;
    property ResponseId: string read FResponseId write FResponseId;
    property Text: string read FText write FText;
    class function FromJson(const Value: string): TResponse_output_text_done;
  end;

  TResponse_output_audio_transcript_delta = class(TRawJsonBase)
  private
    FType: string;
    [JsonNameAttribute('content_index')] FContentIndex: Int64;
    [JsonNameAttribute('event_id')]      FEventId: string;
    [JsonNameAttribute('item_id')]       FItemId: string;
    FDelta: string;
    [JsonNameAttribute('output_index')]  FOutputIndex: Int64;
    [JsonNameAttribute('response_id')]   FResponseId: string;
    FObfuscation: string;
  public
    property &Type: string read FType write FType;
    property ContentIndex: Int64 read FContentIndex write FContentIndex;
    property EventId: string read FEventId write FEventId;
    property ItemId: string read FItemId write FItemId;
    property Delta: string read FDelta write FDelta;
    property OutputIndex: Int64 read FOutputIndex write FOutputIndex;
    property ResponseId: string read FResponseId write FResponseId;
    property Obfuscation: string read FObfuscation write FObfuscation;
    class function FromJson(const Value: string): TResponse_output_audio_transcript_delta;
  end;

  TResponse_output_audio_transcript_done = class(TRawJsonBase)
  private
    FType: string;
    [JsonNameAttribute('content_index')] FContentIndex: Int64;
    [JsonNameAttribute('event_id')]      FEventId: string;
    [JsonNameAttribute('item_id')]       FItemId: string;
    [JsonNameAttribute('output_index')]  FOutputIndex: Int64;
    [JsonNameAttribute('response_id')]   FResponseId: string;
    FTranscript: string;
  public
    property &Type: string read FType write FType;
    property ContentIndex: Int64 read FContentIndex write FContentIndex;
    property EventId: string read FEventId write FEventId;
    property ItemId: string read FItemId write FItemId;
    property OutputIndex: Int64 read FOutputIndex write FOutputIndex;
    property ResponseId: string read FResponseId write FResponseId;
    property Transcript: string read FTranscript write FTranscript;
    class function FromJson(const Value: string): TResponse_output_audio_transcript_done;
  end;

  TResponse_output_audio_delta = class(TRawJsonBase)
  private
    FType: string;
    [JsonNameAttribute('content_index')] FContentIndex: Int64;
    FDelta: string;
    [JsonNameAttribute('event_id')]      FEventId: string;
    [JsonNameAttribute('item_id')]       FItemId: string;
    [JsonNameAttribute('output_index')]  FOutputIndex: Int64;
    [JsonNameAttribute('response_id')]   FResponseId: string;
  public
    property &Type: string read FType write FType;
    property ContentIndex: Int64 read FContentIndex write FContentIndex;
    property Delta: string read FDelta write FDelta;
    property EventId: string read FEventId write FEventId;
    property ItemId: string read FItemId write FItemId;
    property OutputIndex: Int64 read FOutputIndex write FOutputIndex;
    property ResponseId: string read FResponseId write FResponseId;
    class function FromJson(const Value: string): TResponse_output_audio_delta;
  end;

  TResponse_output_audio_done = class(TRawJsonBase)
  private
    FType: string;
    [JsonNameAttribute('content_index')] FContentIndex: Int64;
    [JsonNameAttribute('event_id')]      FEventId: string;
    [JsonNameAttribute('item_id')]       FItemId: string;
    [JsonNameAttribute('output_index')]  FOutputIndex: Int64;
    [JsonNameAttribute('response_id')]   FResponseId: string;
  public
    property &Type: string read FType write FType;
    property ContentIndex: Int64 read FContentIndex write FContentIndex;
    property EventId: string read FEventId write FEventId;
    property ItemId: string read FItemId write FItemId;
    property OutputIndex: Int64 read FOutputIndex write FOutputIndex;
    property ResponseId: string read FResponseId write FResponseId;
    class function FromJson(const Value: string): TResponse_output_audio_done;
  end;

  TResponse_function_call_arguments_delta = class(TRawJsonBase)
  private
    FType: string;
    [JsonNameAttribute('call_id')] FCallId: string;
    FDelta: string;
    [JsonNameAttribute('event_id')]      FEventId: string;
    [JsonNameAttribute('item_id')]       FItemId: string;
    [JsonNameAttribute('output_index')]  FOutputIndex: Int64;
    [JsonNameAttribute('response_id')]   FResponseId: string;
  public
    property &Type: string read FType write FType;
    property CallId: string read FCallId write FCallId;
    property Delta: string read FDelta write FDelta;
    property EventId: string read FEventId write FEventId;
    property ItemId: string read FItemId write FItemId;
    property OutputIndex: Int64 read FOutputIndex write FOutputIndex;
    property ResponseId: string read FResponseId write FResponseId;
    class function FromJson(const Value: string): TResponse_function_call_arguments_delta;
  end;

  TResponse_function_call_arguments_done = class(TRawJsonBase)
  private
    FType: string;
    FArguments: string;
    [JsonNameAttribute('call_id')] FCallId: string;
    [JsonNameAttribute('event_id')]      FEventId: string;
    [JsonNameAttribute('item_id')]       FItemId: string;
    [JsonNameAttribute('output_index')]  FOutputIndex: Int64;
    [JsonNameAttribute('response_id')]   FResponseId: string;
  public
    property &Type: string read FType write FType;
    property Arguments: string read FArguments write FArguments;
    property CallId: string read FCallId write FCallId;
    property EventId: string read FEventId write FEventId;
    property ItemId: string read FItemId write FItemId;
    property OutputIndex: Int64 read FOutputIndex write FOutputIndex;
    property ResponseId: string read FResponseId write FResponseId;
    class function FromJson(const Value: string): TResponse_function_call_arguments_done;
  end;

  TResponse_mcp_call_arguments_delta = class(TRawJsonBase)
  private
    FType: string;
    FDelta: string;
    [JsonNameAttribute('event_id')]     FEventId: string;
    [JsonNameAttribute('item_id')]      FItemId: string;
    FObfuscation: string;
    [JsonNameAttribute('output_index')] FOutputIndex: Int64;
    [JsonNameAttribute('response_id')]  FResponseId: string;
  public
    property &Type: string read FType write FType;
    property Delta: string read FDelta write FDelta;
    property EventId: string read FEventId write FEventId;
    property ItemId: string read FItemId write FItemId;
    property Obfuscation: string read FObfuscation write FObfuscation;
    property OutputIndex: Int64 read FOutputIndex write FOutputIndex;
    property ResponseId: string read FResponseId write FResponseId;
    class function FromJson(const Value: string): TResponse_mcp_call_arguments_delta;
  end;

  TResponse_mcp_call_arguments_done = class(TRawJsonBase)
  private
    FType: string;
    FArguments: string;
    [JsonNameAttribute('event_id')]     FEventId: string;
    [JsonNameAttribute('item_id')]      FItemId: string;
    [JsonNameAttribute('output_index')] FOutputIndex: Int64;
    [JsonNameAttribute('response_id')]  FResponseId: string;
  public
    property &Type: string read FType write FType;
    property Arguments: string read FArguments write FArguments;
    property EventId: string read FEventId write FEventId;
    property ItemId: string read FItemId write FItemId;
    property OutputIndex: Int64 read FOutputIndex write FOutputIndex;
    property ResponseId: string read FResponseId write FResponseId;
    class function FromJson(const Value: string): TResponse_mcp_call_arguments_done;
  end;

  TResponse_mcp_call_in_progress = class(TRawJsonBase)
  private
    FType: string;
    [JsonNameAttribute('event_id')]     FEventId: string;
    [JsonNameAttribute('item_id')]      FItemId: string;
    [JsonNameAttribute('output_index')] FOutputIndex: Int64;
  public
    property &Type: string read FType write FType;
    property EventId: string read FEventId write FEventId;
    property ItemId: string read FItemId write FItemId;
    property OutputIndex: Int64 read FOutputIndex write FOutputIndex;
    class function FromJson(const Value: string): TResponse_mcp_call_in_progress;
  end;

  TResponse_mcp_call_completed = TResponse_mcp_call_in_progress;

  TResponse_mcp_call_failed = TResponse_mcp_call_in_progress;

  {$ENDREGION}

  {$REGION 'MCP list tools'}

  TMcp_list_tools_in_progress = class(TRawJsonBase)
  private
    FType: string;
    [JsonNameAttribute('event_id')]     FEventId: string;
    [JsonNameAttribute('item_id')]      FItemId: string;
  public
    property &Type: string read FType write FType;
    property EventId: string read FEventId write FEventId;
    property ItemId: string read FItemId write FItemId;
    class function FromJson(const Value: string): TMcp_list_tools_in_progress;
  end;

  TMcp_list_tools_completed = TMcp_list_tools_in_progress;

  Tmcp_list_tools_failed = TMcp_list_tools_in_progress;

  {$ENDREGION}

  {$REGION 'rate limits'}

  TRate_limits_updated = class(TRawJsonBase)
  private
    FType: string;
    [JsonNameAttribute('event_id')]    FEventId: string;
    [JsonNameAttribute('rate_limits')] FTateLimits: TRateLimits;
  public
    property &Type: string read FType write FType;
    property EventId: string read FEventId write FEventId;
    property TateLimits: TRateLimits read FTateLimits write FTateLimits;
    destructor Destroy; override;
  end;

  {$ENDREGION}

implementation

{ TConversation_item_input_audio_transcription_completed }

destructor TConversation_item_input_audio_transcription_completed.Destroy;
begin
  for var Item in FLogprobs do
    Item.Free;
  if Assigned(FUsage) then
    FUsage.Free;
  inherited;
end;

class function TConversation_item_input_audio_transcription_completed.FromJson(
  const Value: string): TConversation_item_input_audio_transcription_completed;
begin
  Result := TRawJsonBase.FromJson<TConversation_item_input_audio_transcription_completed>(Value);
end;

{ TResponse_output_audio_transcript_done }

class function TResponse_output_audio_transcript_done.FromJson(
  const Value: string): TResponse_output_audio_transcript_done;
begin
  Result := TRawJsonBase.FromJson<TResponse_output_audio_transcript_done>(Value);
end;

{ TConversation_item_input_audio_transcription_delta }

destructor TConversation_item_input_audio_transcription_delta.Destroy;
begin
  for var Item in FLogprobs do
    Item.Free;
  inherited;
end;

class function TConversation_item_input_audio_transcription_delta.FromJson(
  const Value: string): TConversation_item_input_audio_transcription_delta;
begin
  Result := TRawJsonBase.FromJson<TConversation_item_input_audio_transcription_delta>(Value);
end;

{ TResponse_output_audio_transcript_delta }

class function TResponse_output_audio_transcript_delta.FromJson(
  const Value: string): TResponse_output_audio_transcript_delta;
begin
  Result := TRawJsonBase.FromJson<TResponse_output_audio_transcript_delta>(Value);
end;

{ TResponse_output_item_added }

destructor TResponse_output_item_added.Destroy;
begin
  if Assigned(FItem) then
    Fitem.Free;
  inherited;
end;

class function TResponse_output_item_added.FromJson(
  const Value: string): TResponse_output_item_added;
begin
  Result := TRawJsonBase.FromJson<TResponse_output_item_added>(Value);
end;

{ TSession_created }

destructor TSession_created.Destroy;
begin
  if Assigned(FSession) then
    FSession.Free;
  inherited;
end;

class function TSession_created.FromJson(const Value: string): TSession_created;
begin
  Result := TRawJsonBase.FromJson<TSession_created>(Value);
end;

{ TInput_audio_buffer_speech_started }

class function TInput_audio_buffer_speech_started.FromJson(
  const Value: string): TInput_audio_buffer_speech_started;
begin
  Result := TRawJsonBase.FromJson<TInput_audio_buffer_speech_started>(Value);
end;

{ TInput_audio_buffer_speech_stopped }

class function TInput_audio_buffer_speech_stopped.FromJson(
  const Value: string): TInput_audio_buffer_speech_stopped;
begin
  Result := TRawJsonBase.FromJson<TInput_audio_buffer_speech_stopped>(Value);
end;

{ TInput_audio_buffer_timeout_triggered }

class function TInput_audio_buffer_timeout_triggered.FromJson(
  const Value: string): TInput_audio_buffer_timeout_triggered;
begin
  Result := TRawJsonBase.FromJson<TInput_audio_buffer_timeout_triggered>(Value);
end;

{ TInput_audio_buffer_committed }

class function TInput_audio_buffer_committed.FromJson(
  const Value: string): TInput_audio_buffer_committed;
begin
  Result := TRawJsonBase.FromJson<TInput_audio_buffer_committed>(Value);
end;

{ TInput_audio_buffer_cleared }

class function TInput_audio_buffer_cleared.FromJson(
  const Value: string): TInput_audio_buffer_cleared;
begin
  Result := TRawJsonBase.FromJson<TInput_audio_buffer_cleared>(Value);
end;

{ TConversation_item_added }

destructor TConversation_item_added.Destroy;
begin
  if Assigned(FItem) then
    FItem.Free;
  inherited;
end;

class function TConversation_item_added.FromJson(
  const Value: string): TConversation_item_added;
begin
  Result := TRawJsonBase.FromJson<TConversation_item_added>(Value);
end;

{ TConversation_item_input_audio_transcription_failed }

destructor TConversation_item_input_audio_transcription_failed.Destroy;
begin
  if Assigned(FError) then
    FError.Free;
  inherited;
end;

class function TConversation_item_input_audio_transcription_failed.FromJson(
  const Value: string): TConversation_item_input_audio_transcription_failed;
begin
  Result := TRawJsonBase.FromJson<TConversation_item_input_audio_transcription_failed>(Value);
end;

{ TResponse_created }

destructor TResponse_created.Destroy;
begin
  if Assigned(FResponse) then
    FResponse.Free;
  inherited;
end;

class function TResponse_created.FromJson(
  const Value: string): TResponse_created;
begin
  Result := TRawJsonBase.FromJson<TResponse_created>(Value);
end;

{ TResponse_content_part_added }

destructor TResponse_content_part_added.Destroy;
begin
  if Assigned(FPart) then
    FPart.Free;
  inherited;
end;

class function TResponse_content_part_added.FromJson(
  const Value: string): TResponse_content_part_added;
begin
  Result := TRawJsonBase.FromJson<TResponse_content_part_added>(Value);
end;

{ TOutput_audio_buffer_started }

class function TOutput_audio_buffer_started.FromJson(
  const Value: string): TOutput_audio_buffer_started;
begin
  Result := TRawJsonBase.FromJson<TOutput_audio_buffer_started>(Value);
end;

{ TRate_limits_updated }

destructor TRate_limits_updated.Destroy;
begin
  if Assigned(FTateLimits) then
    FTateLimits.Free;
  inherited;
end;

{ TResponse_output_audio_done }

class function TResponse_output_audio_done.FromJson(
  const Value: string): TResponse_output_audio_done;
begin
  Result := TRawJsonBase.FromJson<TResponse_output_audio_done>(Value);
end;

{ TResponse_output_audio_delta }

class function TResponse_output_audio_delta.FromJson(
  const Value: string): TResponse_output_audio_delta;
begin
  Result := TRawJsonBase.FromJson<TResponse_output_audio_delta>(Value);
end;

{ TConversation_item_truncated }

class function TConversation_item_truncated.FromJson(
  const Value: string): TConversation_item_truncated;
begin
  Result := TRawJsonBase.FromJson<TConversation_item_truncated>(Value);
end;

{ TConversation_item_deleted }

class function TConversation_item_deleted.FromJson(
  const Value: string): TConversation_item_deleted;
begin
  Result := TRawJsonBase.FromJson<TConversation_item_deleted>(Value);
end;

{ TConversation_item_input_audio_transcription_segment }

class function TConversation_item_input_audio_transcription_segment.FromJson(
  const Value: string): TConversation_item_input_audio_transcription_segment;
begin
  Result := TRawJsonBase.FromJson<TConversation_item_input_audio_transcription_segment>(Value);
end;

{ TResponse_output_text_delta }

class function TResponse_output_text_delta.FromJson(
  const Value: string): TResponse_output_text_delta;
begin
  Result := TRawJsonBase.FromJson<TResponse_output_text_delta>(Value);
end;

{ TResponse_output_text_done }

class function TResponse_output_text_done.FromJson(
  const Value: string): TResponse_output_text_done;
begin
  Result := TRawJsonBase.FromJson<TResponse_output_text_done>(Value);
end;

{ TResponse_function_call_arguments_delta }

class function TResponse_function_call_arguments_delta.FromJson(
  const Value: string): TResponse_function_call_arguments_delta;
begin
  Result := TRawJsonBase.FromJson<TResponse_function_call_arguments_delta>(Value);
end;

{ TResponse_function_call_arguments_done }

class function TResponse_function_call_arguments_done.FromJson(
  const Value: string): TResponse_function_call_arguments_done;
begin
  Result := TRawJsonBase.FromJson<TResponse_function_call_arguments_done>(Value);
end;

{ TResponse_mcp_call_arguments_delta }

class function TResponse_mcp_call_arguments_delta.FromJson(
  const Value: string): TResponse_mcp_call_arguments_delta;
begin
  Result := TRawJsonBase.FromJson<TResponse_mcp_call_arguments_delta>(Value);
end;

{ TResponse_mcp_call_arguments_done }

class function TResponse_mcp_call_arguments_done.FromJson(
  const Value: string): TResponse_mcp_call_arguments_done;
begin
  Result := TRawJsonBase.FromJson<TResponse_mcp_call_arguments_done>(Value);
end;

{ TResponse_mcp_call_in_progress }

class function TResponse_mcp_call_in_progress.FromJson(
  const Value: string): TResponse_mcp_call_in_progress;
begin
  Result := TRawJsonBase.FromJson<TResponse_mcp_call_in_progress>(Value);
end;

{ TMcp_list_tools_in_progress }

class function TMcp_list_tools_in_progress.FromJson(
  const Value: string): TMcp_list_tools_in_progress;
begin
  Result := TRawJsonBase.FromJson<TMcp_list_tools_in_progress>(Value);
end;

end.
