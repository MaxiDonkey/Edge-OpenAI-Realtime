unit Realtime.Types;

interface

uses
  System.SysUtils, System.Classes, System.Net.HttpClient, System.Net.URLClient,
  System.JSON, System.Net.HttpClientComponent;

type
  TRoleType = (
    user,
    assistant,
    system
  );

  TRoleTypeHelper = record Helper for TRoleType
    const
       RoleNames: array[TRoleType] of string = (
         'user',
         'assistant',
         'system'
       );
    class function TryParse(const S: string; out Value: TRoleType): Boolean; static;
    class function Parse(const S: string): TRoleType; static;
    function ToString: string;
  end;

  TInputType = (
    input_text,
    input_audio,
    input_image
  );

  TInputTypeHelper = record Helper for TInputType
    const
      InputNames: array[TInputType] of string = (
        'input_text',
        'input_audio',
        'input_image'
      );
    class function TryParse(const S: string; out Value: TInputType): Boolean; static;
    class function Parse(const S: string): TInputType; static;
    function ToString: string;
  end;

  TOutputType = (
    output_text,
    output_audio
  );

  TOutputTypeHelper = record Helper for TOutputType
    const
      OutputNames: array[TOutputType] of string = (
        'output_text',
        'output_audio'
      );
    class function TryParse(const S: string; out Value: TOutputType): Boolean; static;
    class function Parse(const S: string): TOutputType; static;
    function ToString: string;
  end;

  TAudioType = (
    audio_pcm,
    audio_pcmu,
    audio_pcma
  );

  TAudioTypeHelper = record Helper for TAudioType
    const
      AudioTypeNames: array[TAudioType] of string = (
       'audio/pcm',
       'audio/pcmu',
       'audio/pcma'
      );
    class function TryParse(const S: string; out Value: TAudioType): Boolean; static;
    class function Parse(const S: string): TAudioType; static;
    function ToString: string;
  end;

  TNoiseReductionType = (
    near_field,
    far_field
  );

  TNoiseReductionTypeHelper = record Helper for TNoiseReductionType
    const
      NoiseReductionTypeNames: array[TNoiseReductionType] of string = (
        'near_field',
        'far_field'
      );
    class function TryParse(const S: string; out Value: TNoiseReductionType): Boolean; static;
    class function Parse(const S: string): TNoiseReductionType; static;
    function ToString: string;
  end;

  TTurnDetectionType = (
    semantic_vad,
    server_vad
  );

  TTurnDetectionTypeHelper = record Helper for TTurnDetectionType
    const
      TurnDetectionTypeNames: array[TTurnDetectionType] of string = (
        'semantic_vad',
        'server_vad'
      );
    class function TryParse(const S: string; out Value: TTurnDetectionType): Boolean; static;
    class function Parse(const S: string): TTurnDetectionType; static;
    function ToString: string;
  end;

  {$SCOPEDENUMS ON}

  TEagernessType = (
    low,
    medium,
    high,
    auto
  );

  TEagernessTypeHelper = record Helper for TEagernessType
    const
      EagernessTypeNames: array[TEagernessType] of string = (
        'low',
        'medium',
        'high',
        'auto'
      );
    class function TryParse(const S: string; out Value: TEagernessType): Boolean; static;
    class function Parse(const S: string): TEagernessType; static;
    function ToString: string;
  end;

  {$SCOPEDENUMS OFF}

  TVoiceType = (
    alloy,
    ash,
    ballad,
    coral,
    echo,
    sage,
    shimmer,
    verse,
    marin,
    cedar
  );

  TVoiceTypeHelper = record Helper for TVoiceType
    const
      VoiceTypeNames: array[TVoiceType] of string = (
        'alloy',
        'ash',
        'ballad',
        'coral',
        'echo',
        'sage',
        'shimmer',
        'verse',
        'marin',
        'cedar'
      );
    class function TryParse(const S: string; out Value: TVoiceType): Boolean; static;
    class function Parse(const S: string): TVoiceType; static;
    function ToString: string;
  end;

  TConnectorType = (
    server_url,
    connector_dropbox,
    connector_gmail,
    connector_googlecalendar,
    connector_googledrive,
    connector_microsoftteams,
    connector_outlookcalendar,
    connector_outlookemail,
    connector_sharepoint
  );

  TConnectorTypeHelper = record Helper for TConnectorType
    const
      ConnectorTypeNames: array[TConnectorType] of string = (
        'server_url',
        'connector_dropbox',
        'connector_gmail',
        'connector_googlecalendar',
        'connector_googledrive',
        'connector_microsoftteams',
        'connector_outlookcalendar',
        'connector_outlookemail',
        'connector_sharepoint'
      );
    class function TryParse(const S: string; out Value: TConnectorType): Boolean; static;
    class function Parse(const S: string): TConnectorType; static;
    function ToString: string;
  end;

  {$SCOPEDENUMS ON}

  TToolChoiceType = (
    none,
    auto,
    required
  );

  TToolChoiceTypeHelper = record Helper for TToolChoiceType
    const
      ToolChoiceTypeNames: array[TToolChoiceType] of string = (
        'none',
        'auto',
        'required'
      );
    class function TryParse(const S: string; out Value: TToolChoiceType): Boolean; static;
    class function Parse(const S: string): TToolChoiceType; static;
    function ToString: string;
  end;

  TLanguageCodes = (
    af, ar, az, be, bg, bs, ca, cs, cy, da, de,  el, en, es, et,
    fa, fi, fr, gl, he, hi, hr, hu, hy, id, &is, it, ja, kk, kn,
    ko, lt, lv, mi, mk, mr, ms, ne, nl, no, pl,  pt, ro, ru, sk,
    sl, sr, sv, sw, ta, th, tl, tr, uk, ur, vi, zh, none
  );

  TLanguageCodesHelper = record Helper for TLanguageCodes
    const
      LanguageCodesNames: array[TLanguageCodes] of string = (
        'af', 'ar', 'az', 'be', 'bg', 'bs', 'ca', 'cs', 'cy', 'da', 'de', 'el', 'en', 'es', 'et',
        'fa', 'fi', 'fr', 'gl', 'he', 'hi', 'hr', 'hu', 'hy', 'id', 'is', 'it', 'ja', 'kk', 'kn',
        'ko', 'lt', 'lv', 'mi', 'mk', 'mr', 'ms', 'ne', 'nl', 'no', 'pl', 'pt', 'ro', 'ru', 'sk',
        'sl', 'sr', 'sv', 'sw', 'ta', 'th', 'tl', 'tr', 'uk', 'ur', 'vi', 'zh', 'none'
      );
    class function TryParse(const S: string; out Value: TLanguageCodes): Boolean; static;
    class function Parse(const S: string): TLanguageCodes; static;
    function ToString: string;
  end;

  /// <summary>
  /// Type contains the list of data types as defined by :
  /// <para>
  /// - https://spec.openapis.org/oas/v3.0.3#data-types
  /// </para>
  /// </summary>
  TSchemaType = (
    /// <summary>
    /// Not specified, should not be used.
    /// </summary>
    unspecified,
    /// <summary>
    /// String type.
    /// </summary>
    &string,
    /// <summary>
    /// Number type.
    /// </summary>
    number,
    /// <summary>
    /// Integer type.
    /// </summary>
    &integer,
    /// <summary>
    /// Boolean type.
    /// </summary>
    &boolean,
    /// <summary>
    /// Array type.
    /// </summary>
    &array,
    /// <summary>
    /// Object type.
    /// </summary>
    &object
  );

  TSchemaTypeHelper = record Helper for TSchemaType
    const
      SchemaNames: array[TSchemaType] of string = (
        'unspecified',
        'string',
        'number',
        'integer',
        'boolean',
        'array',
        'object'
      );
    class function TryParse(const S: string; out Value: TSchemaType): Boolean; static;
    class function Parse(const S: string): TSchemaType; static;
    function ToString: string;
  end;


  {$SCOPEDENUMS OFF}

implementation

{ TAudioTypeHelper }

class function TAudioTypeHelper.Parse(const S: string): TAudioType;
begin
  if not TryParse(S, Result) then
    raise EConvertError.CreateFmt('Unknown audio type: %s', [S]);
end;

function TAudioTypeHelper.ToString: string;
begin
  Result := AudioTypeNames[Self];
end;

class function TAudioTypeHelper.TryParse(const S: string;
  out Value: TAudioType): Boolean;
begin
  for var Item := Low(TAudioType) to High(TAudioType) do
    if SameText(S, AudioTypeNames[Item]) then
      begin
        Value := Item;
        Exit(True);
      end;
  Result := False;
end;

{ TEagernessTypeHelper }

class function TEagernessTypeHelper .Parse(const S: string): TEagernessType;
begin
  if not TryParse(S, Result) then
    raise EConvertError.CreateFmt('Unknown eagerness type: %s', [S]);
end;

function TEagernessTypeHelper.ToString: string;
begin
  Result := EagernessTypeNames[Self];
end;

class function TEagernessTypeHelper.TryParse(const S: string;
  out Value: TEagernessType): Boolean;
begin
  for var Item := Low(TEagernessType) to High(TEagernessType) do
    if SameText(S, EagernessTypeNames[Item]) then
      begin
        Value := Item;
        Exit(True);
      end;
  Result := False;
end;

{ TVoiceTypeHelper }

class function TVoiceTypeHelper.Parse(const S: string): TVoiceType;
begin
  if not TryParse(S, Result) then
    raise EConvertError.CreateFmt('Unknown voice type: %s', [S]);
end;

function TVoiceTypeHelper.ToString: string;
begin
  Result := VoiceTypeNames[Self];
end;

class function TVoiceTypeHelper.TryParse(const S: string;
  out Value: TVoiceType): Boolean;
begin
  for var Item := Low(TVoiceType) to High(TVoiceType) do
    if SameText(S, VoiceTypeNames[Item]) then
      begin
        Value := Item;
        Exit(True);
      end;
  Result := False;
end;

{ TConnectorTypeHelper }

class function TConnectorTypeHelper.Parse(const S: string): TConnectorType;
begin
  if not TryParse(S, Result) then
    raise EConvertError.CreateFmt('Unknown connector type: %s', [S]);
end;

function TConnectorTypeHelper.ToString: string;
begin
  Result := ConnectorTypeNames[Self];
end;

class function TConnectorTypeHelper.TryParse(const S: string;
  out Value: TConnectorType): Boolean;
begin
  for var Item := Low(TConnectorType) to High(TConnectorType) do
    if SameText(S, ConnectorTypeNames[Item]) then
      begin
        Value := Item;
        Exit(True);
      end;
  Result := False;
end;

{ TToolChoiceTypeHelper }

class function TToolChoiceTypeHelper.Parse(const S: string): TToolChoiceType;
begin
  if not TryParse(S, Result) then
    raise EConvertError.CreateFmt('Unknown tool choice type: %s', [S]);
end;

function TToolChoiceTypeHelper.ToString: string;
begin
  Result := ToolChoiceTypeNames[Self];
end;

class function TToolChoiceTypeHelper.TryParse(const S: string;
  out Value: TToolChoiceType): Boolean;
begin
  for var Item := Low(TToolChoiceType) to High(TToolChoiceType) do
    if SameText(S, ToolChoiceTypeNames[Item]) then
      begin
        Value := Item;
        Exit(True);
      end;
  Result := False;
end;

{ TNoiseReductionTypeHelper }

class function TNoiseReductionTypeHelper.Parse(
  const S: string): TNoiseReductionType;
begin
  if not TryParse(S, Result) then
    raise EConvertError.CreateFmt('Unknown noise reduction type: %s', [S]);
end;

function TNoiseReductionTypeHelper.ToString: string;
begin
  Result := NoiseReductionTypeNames[Self];
end;

class function TNoiseReductionTypeHelper.TryParse(const S: string;
  out Value: TNoiseReductionType): Boolean;
begin
  for var Item := Low(TNoiseReductionType) to High(TNoiseReductionType) do
    if SameText(S, NoiseReductionTypeNames[Item]) then
      begin
        Value := Item;
        Exit(True);
      end;
  Result := False;
end;

{ TTurnDetectionTypeHelper }

class function TTurnDetectionTypeHelper.Parse(
  const S: string): TTurnDetectionType;
begin
  if not TryParse(S, Result) then
    raise EConvertError.CreateFmt('Unknown turn detection type: %s', [S]);
end;

function TTurnDetectionTypeHelper.ToString: string;
begin
  Result := TurnDetectionTypeNames[Self];
end;

class function TTurnDetectionTypeHelper.TryParse(const S: string;
  out Value: TTurnDetectionType): Boolean;
begin
  for var Item := Low(TTurnDetectionType) to High(TTurnDetectionType) do
    if SameText(S, TurnDetectionTypeNames[Item]) then
      begin
        Value := Item;
        Exit(True);
      end;
  Result := False;
end;

{ TLanguageCodesHelper }

class function TLanguageCodesHelper.Parse(const S: string): TLanguageCodes;
begin
  if not TryParse(S, Result) then
    raise EConvertError.CreateFmt('Unknown language code: %s', [S]);
end;

function TLanguageCodesHelper.ToString: string;
begin
  Result := LanguageCodesNames[Self];
end;

class function TLanguageCodesHelper.TryParse(const S: string;
  out Value: TLanguageCodes): Boolean;
begin
  for var Item := Low(TLanguageCodes) to High(TLanguageCodes) do
    if SameText(S, LanguageCodesNames[Item]) then
      begin
        Value := Item;
        Exit(True);
      end;
  Result := False;
end;

{ TRoleTypeHelper }

class function TRoleTypeHelper.Parse(const S: string): TRoleType;
begin
  if not TryParse(S, Result) then
    raise EConvertError.CreateFmt('Unknown role type: %s', [S]);
end;

function TRoleTypeHelper.ToString: string;
begin
  Result := RoleNames[Self];
end;

class function TRoleTypeHelper.TryParse(const S: string;
  out Value: TRoleType): Boolean;
begin
  for var Item := Low(TRoleType) to High(TRoleType) do
    if SameText(S, RoleNames[Item]) then
      begin
        Value := Item;
        Exit(True);
      end;
  Result := False;
end;

{ TInputTypeHelper }

class function TInputTypeHelper.Parse(const S: string): TInputType;
begin
  if not TryParse(S, Result) then
    raise EConvertError.CreateFmt('Unknown input type: %s', [S]);
end;

function TInputTypeHelper.ToString: string;
begin
  Result := InputNames[Self];
end;

class function TInputTypeHelper.TryParse(const S: string;
  out Value: TInputType): Boolean;
begin
  for var Item := Low(TInputType) to High(TInputType) do
    if SameText(S, InputNames[Item]) then
      begin
        Value := Item;
        Exit(True);
      end;
  Result := False;
end;

{ TOutputTypeHelper }

class function TOutputTypeHelper.Parse(const S: string): TOutputType;
begin
  if not TryParse(S, Result) then
    raise EConvertError.CreateFmt('Unknown output type: %s', [S]);
end;

function TOutputTypeHelper.ToString: string;
begin
  Result := OutputNames[Self];
end;

class function TOutputTypeHelper.TryParse(const S: string;
  out Value: TOutputType): Boolean;
begin
  for var Item := Low(TOutputType) to High(TOutputType) do
    if SameText(S, OutputNames[Item]) then
      begin
        Value := Item;
        Exit(True);
      end;
  Result := False;
end;

{ TSchemaTypeHelper }

class function TSchemaTypeHelper.Parse(const S: string): TSchemaType;
begin
  if not TryParse(S, Result) then
    raise EConvertError.CreateFmt('Unknown schema type: %s', [S]);
end;

function TSchemaTypeHelper.ToString: string;
begin
  Result := SchemaNames[Self];
end;

class function TSchemaTypeHelper.TryParse(const S: string;
  out Value: TSchemaType): Boolean;
begin
  for var Item := Low(TSchemaType) to High(TSchemaType) do
    if SameText(S, SchemaNames[Item]) then
      begin
        Value := Item;
        Exit(True);
      end;
  Result := False;
end;

end.
