unit Realtime.Events.DTOs.Helper;

interface

uses
  System.SysUtils, System.JSON, System.Generics.Collections,
  REST.Json.Types, REST.JsonReflect, REST.Json,
  Audio.Web.Assets, Realtime.API.JsonParams, Realtime.Types,
  JSON.PolymorphicMapper;

type
  TResponseItem = class;

  {$REGION 'conversation.item.input_audio_transcription.completed'}

  TLogprobs = class(TRawJsonBase)
  private
    TBytes: TArray<Integer>;
    FLogprob: Double;
    FToken: string;
  public
    property Bytes: TArray<Integer> read TBytes write TBytes;
    property Logprob: Double read FLogprob write FLogprob;
    property Token: string read FToken write FToken;
  end;

  TInputTokenDetails = class(TRawJsonBase)
  private
    [JsonNameAttribute('audio_tokens')] FAudioTokens: Int64;
    [JsonNameAttribute('text_tokens')]  FTextTokens: Int64;
  public
    property AudioTokens: Int64 read FAudioTokens write FAudioTokens;
    property TextTokens: Int64 read FTextTokens write FTextTokens;
  end;

  TUsage = class(TRawJsonBase)
  private
    FType: string;
    {--- Token Usage }
    [JsonNameAttribute('input_tokens')]  FInputTokens: Int64;
    [JsonNameAttribute('output_tokens')] FOutputTokens: Int64;
    [JsonNameAttribute('total_tokens')]  FTotalTokens: Int64;
    [JsonNameAttribute('input_token_details')] FInputTokenDetails: TInputTokenDetails;
    {--- Duration Usage }
    FSeconds: Double;
  public
    property &Type: string read FType write FType;
    property InputTokens: Int64 read FInputTokens write FInputTokens;
    property OutputTokens: Int64 read FOutputTokens write FOutputTokens;
    property TotalTokens: Int64 read FTotalTokens write FTotalTokens;
    property InputTokenDetails: TInputTokenDetails read FInputTokenDetails write FInputTokenDetails;
    property Seconds: Double read FSeconds write FSeconds;
    destructor Destroy; override;
  end;

  {$ENDREGION}

  {$REGION 'session'}

  TClientSecret = class(TRawJsonBase)
  private
    [JsonNameAttribute('expires_at')]
    FExpiresAt: Int64;
    FValue: string;
  public
    property ExpiresAt: Int64 read FExpiresAt write FExpiresAt;
    property Value: string read FValue write FValue;
  end;

  TAudioFormat = class(TRawJsonBase)
  private
    FType: string;
    FRate: Int64;
  public
    property &Type: string read FType write FType;
    property Rate: Int64 read FRate write FRate;
  end;

  TNoiseReduction = class(TRawJsonBase)
  private
    FType: string;
  public
    property &Type: string read FType write FType;
  end;

  TTranscription = class(TRawJsonBase)
  private
    FModel: string;
    FLanguage: string;
    FPrompt: string;
  public
    property Model: string read FModel write FModel;
    property Language: string read FLanguage write FLanguage;
    property Prompt: string read FPrompt write FPrompt;
  end;

  TPrompt = class(TRawJsonBase)
  private
    FId: string;
    [JSONMarshalled(False)] FVariables: TJSONValue;
    FVersion: string;
    procedure SetVariables(const Value: TJSONValue);
  protected
    class function RawMaps: TArray<TRawMap>; override;
  public
    property Id: string read FId write FId;
    property Variables: TJSONValue read FVariables write SetVariables;
    property Version: string read FVersion write FVersion;
    destructor Destroy; override;
  end;

  TAlwaysNever = class(TRawJsonBase)
  private
    [JsonNameAttribute('read_only')]
    FReadOnly: Boolean;
    [JsonNameAttribute('tool_names')]
    FToolNames: TArray<string>;
  public
    property ReadOnly: Boolean read FReadOnly write FReadOnly;
    property ToolNames: TArray<string> read FToolNames write FToolNames;
  end;

  TMCPToolApprovalFilter = class(TRawJsonBase)
  private
    FAlways: TAlwaysNever;
    FNever: TAlwaysNever;
  public
    property Always: TAlwaysNever read FAlways write FAlways;
    property Never: TAlwaysNever read FNever write FNever;
    destructor Destroy; override;
  end;

  TAllowedTools = class
  private
    [JsonNameAttribute('read_only')]
    FReadOnly: Boolean;
    [JsonNameAttribute('tool_names')]
    FToolNames: TArray<string>;
  public
    property ReadOnly: Boolean read FReadOnly write FReadOnly;
    property ToolNames: TArray<string> read FToolNames write FToolNames;
  end;

  TTool = class(TRawJsonBase)
  private
    FType: string;
    {--- Function }
    FDescription: string;
    FName: string;
    [JSONMarshalled(False)] FParameters: TJSONValue;
    {--- MCP }
    [JsonNameAttribute('server_label')]
    FServerLabel: string;
    [JSONMarshalled(False)] FJSONAllowedTools: TJSONValue;
    [JSONMarshalled(False)] FAllowedTools: TAllowedTools;
    [JSONMarshalled(False)] FAllowedToolsArray: TArray<string>;
    FAuthorization: string;
    [JsonNameAttribute('connector_id')]
    FConnectorId: string;
    [JSONMarshalled(False)] FHeaders: TJSONValue;
    [JSONMarshalled(False)] FJSONRequireApproval: TJSONValue;
    [JSONMarshalled(False)] FrequireApproval: TMCPToolApprovalFilter;
    [JsonNameAttribute('server_description')]
    FServerDescription: string;
    [JsonNameAttribute('server_url')]
    FServerUrl: string;
    procedure SetParameters(const Value: TJSONValue);
    procedure SetHeaders(const Value: TJSONValue);
    procedure SetJSONRequireApproval(const Value: TJSONValue);
    procedure SetJSONAllowedTools(const Value: TJSONValue);
  protected
    class function RawMaps: TArray<TRawMap>; override;
  public
    property &Type: string read FType write FType;
    {--- Function }
    property Description: string read FDescription write FDescription;
    property Name: string read FName write FName;
    property Parameters: TJSONValue read FParameters write SetParameters;
    {--- MCP }
    property ServerLabel: string read FServerLabel write FServerLabel;
    property JSONAllowedTools: TJSONValue read FJSONAllowedTools write SetJSONAllowedTools;
    property AllowedTools: TAllowedTools read FAllowedTools;
    property AllowedToolsArray: TArray<string> read FAllowedToolsArray;
    property Authorization: string read FAuthorization write FAuthorization;
    property ConnectorId: string read FConnectorId write FConnectorId;
    property Headers: TJSONValue read FHeaders write SetHeaders;
    property JSONRequireApproval: TJSONValue read FJSONRequireApproval write SetJSONRequireApproval;
    property RquireApproval: TMCPToolApprovalFilter read FrequireApproval;
    property ServerDescription: string read FServerDescription write FServerDescription;
    property ServerUrl: string read FServerUrl write FServerUrl;
    destructor Destroy; override;
  end;

  TTurnDetection = class(TRawJsonBase)
  private
    [JsonNameAttribute('create_response')]
    FCreateResponse: Boolean;
    FEagerness: string;
    [JsonNameAttribute('idle_timeout_ms')]
    FIdleTimeoutMs: Variant;
    [JsonNameAttribute('interrupt_response')]
    FInterruptResponse: Boolean;
    [JsonNameAttribute('prefix_padding_ms')]
    FPrefixPaddingMs: Int64;
    [JsonNameAttribute('silence_duration_ms')]
    FSilenceDurationMs: Int64;
    FThreshold: Double;
    FType: string;
  public
    property CreateResponse: Boolean read FCreateResponse write FCreateResponse;
    property Eagerness: string read FEagerness write FEagerness;
    property IdleTimeoutMs: Variant read FIdleTimeoutMs write FIdleTimeoutMs;
    property InterruptResponse: Boolean read FInterruptResponse write FInterruptResponse;
    property PrefixPaddingMs: Int64 read FPrefixPaddingMs write FPrefixPaddingMs;
    property SilenceDurationMs: Int64 read FSilenceDurationMs write FSilenceDurationMs;
    property Threshold: Double read FThreshold write FThreshold;
    property &Type: string read FType write FType;
  end;

  TAudioInput = class(TRawJsonBase)
  private
    FFormat: TAudioFormat;
    [JsonNameAttribute('noise_reduction')]
    FNoiseReduction: TNoiseReduction;
    FTranscription: TTranscription;
    [JsonNameAttribute('turn_detection')]
    FTurnDetection: TTurnDetection;
  public
    property Format: TAudioFormat read FFormat write FFormat;
    property NoiseReduction: TNoiseReduction read FNoiseReduction write FNoiseReduction;
    property Transcription: TTranscription read FTranscription write FTranscription;
    property TurnDetection: TTurnDetection read FTurnDetection write FTurnDetection;
    destructor Destroy; override;
  end;

  TAudioOutput = class(TRawJsonBase)
  private
    FFormat: TAudioFormat;
    FSpeed: Double;
    FVoice: string;
  public
    property Format: TAudioFormat read FFormat write FFormat;
    property Speed: Double read FSpeed write FSpeed;
    property Voice: string read FVoice write FVoice;
    destructor Destroy; override;
  end;

  TAudio = class(TRawJsonBase)
  private
    FInput: TAudioInput;
    FOutput: TAudioOutput;
  public
    property Input: TAudioInput read FInput write FInput;
    property Output: TAudioOutput read FOutput write FOutput;
    destructor Destroy; override;
  end;

  TAudio_output = class(TRawJsonBase)
  private
    FOutput: TAudioOutput;
  public
    property Output: TAudioOutput read FOutput write FOutput;
    destructor Destroy; override;
  end;

  TTracing = class(TRawJsonBase)
  private
    [JsonNameAttribute('group_id')]
    FGroupId: string;
    [JSONMarshalled(False)] FMetadata: TJSONValue;
    [JsonNameAttribute('workflow_name')]
    FWorkflowName: string;
    procedure SetMetadata(const Value: TJSONValue);
  protected
    class function RawMaps: TArray<TRawMap>; override;
  public
    property GroupId: string read FGroupId write FGroupId;
    property Metadata: TJSONValue read FMetadata write SetMetadata;
    property WorkflowName: string read FWorkflowName write FWorkflowName;
    destructor Destroy; override;
  end;

  TTruncation = class
  private
    [JsonNameAttribute('retention_ratio')]
    FRetentionRatio: Double;
    FType: string;
  public
    property RetentionRatio: Double read FRetentionRatio write FRetentionRatio;
    property &Type: string read FType write FType;
  end;

  TSession = class(TRawJsonBase)
  private
    FAudio: TAudio;
    [JsonNameAttribute('client_secret')]
    FClientSecret: TClientSecret;
    FInclude: TArray<string>;
    FInstructions: string;
    [JsonNameAttribute('max_response_output_tokens')]
    FMaxResponseOutputTokens: Variant;
    FModel: string;
    [JsonNameAttribute('output_modalities')]
    FOutputModalities: TArray<string>;
    FPrompt: TPrompt;
    FTemperature: Double;
    [JsonNameAttribute('tool_choice')]
    FToolChoice: string;
    FTools: TArray<TTool>;
    [JSONMarshalled(False)] FJSONTracing: TJSONValue;
    [JSONMarshalled(False)] FTracing: TTracing;
    [JSONMarshalled(False)] FJSONTruncation: TJSONValue;
    [JSONMarshalled(False)] FTruncation: TTruncation;
    FType: string;
    procedure SetJSONTracing(const Value: TJSONValue);
    procedure SetJSONTruncation(const Value: TJSONValue);
  protected
    class function RawMaps: TArray<TRawMap>; override;
  public
    property Audio: TAudio read FAudio write FAudio;
    property ClientSecret: TClientSecret read FClientSecret write FClientSecret;
    property Include: TArray<string> read FInclude write FInclude;
    property Instructions: string read FInstructions write FInstructions;
    property MaxResponseOutputTokens: Variant read FMaxResponseOutputTokens write FMaxResponseOutputTokens;
    property Model: string read FModel write FModel;
    property OutputModalities: TArray<string> read FOutputModalities write FOutputModalities;
    property Prompt: TPrompt read FPrompt write FPrompt;
    property Temperature: Double read FTemperature write FTemperature;
    property ToolChoice: string read FToolChoice write FToolChoice;
    property Tools: TArray<TTool> read FTools write FTools;
    property JSONTracing: TJSONValue read FJSONTracing write SetJSONTracing;
    property Tracing: TTracing read FTracing;
    property JSONTruncation: TJSONValue read FJSONTruncation write SetJSONTruncation;
    property &Type: string read FType write FType;
    destructor Destroy; override;
  end;

  {$ENDREGION}

  {$REGION 'response.created -> response'}

  TCachedTokensDetails = class(TRawJsonBase)
  private
    [JsonNameAttribute('audio_tokens')]  FAudioTokens: Int64;
    [JsonNameAttribute('image_tokens')] FImageTokens: Int64;
    [JsonNameAttribute('text_tokens')]  FTextTokens: Int64;
  public
    property AudioTokens: Int64 read FAudioTokens write FAudioTokens;
    property ImageTokens: Int64 read FImageTokens write FImageTokens;
    property TextTokens: Int64 read FTextTokens write FTextTokens;
  end;

  TResourceInputTokenDetails = class(TRawJsonBase)
  private
    [JsonNameAttribute('audio_tokens')]  FAudioTokens: Int64;
    [JsonNameAttribute('cached_tokens')] FCachedTokens: Int64;
    [JsonNameAttribute('cached_tokens_details')] FCachedTokensDetails: TCachedTokensDetails;
    [JsonNameAttribute('image_tokens')] FImageTokens: Int64;
    [JsonNameAttribute('text_tokens')]  FTextTokens: Int64;
  public
    property AudioTokens: Int64 read FAudioTokens write FAudioTokens;
    property CachedTokens: Int64 read FCachedTokens write FCachedTokens;
    property CachedTokensDetails: TCachedTokensDetails read FCachedTokensDetails write FCachedTokensDetails;
    property ImageTokens: Int64 read FImageTokens write FImageTokens;
    property TextTokens: Int64 read FTextTokens write FTextTokens;
    destructor Destroy; override;
  end;

  TResourceOutputTokenDetails = class(TRawJsonBase)
  private
    [JsonNameAttribute('audio_tokens')] FAudioTokens: Int64;
    [JsonNameAttribute('text_tokens')]  FTextTokens: Int64;
  public
    property AudioTokens: Int64 read FAudioTokens write FAudioTokens;
    property TextTokens: Int64 read FTextTokens write FTextTokens;
  end;

  TResponseResourceUsage = class(TRawJsonBase)
  private
    [JsonNameAttribute('input_token_details')]  FInputTokenDetails: TResourceInputTokenDetails;
    [JsonNameAttribute('input_token_details')]  FInputTokens: Int64;
    [JsonNameAttribute('output_token_details')] FOutputTokenDetails: TResourceOutputTokenDetails;
    [JsonNameAttribute('output_tokens')]        FOutputTokens: Int64;
    [JsonNameAttribute('output_tokens')]        FTotalTokens: Int64;
  public
    property InputTokenDetails: TResourceInputTokenDetails read FInputTokenDetails write FInputTokenDetails;
    property InputTokens: Int64 read FInputTokens write FInputTokens;
    property OutputTokenDetails: TResourceOutputTokenDetails read FOutputTokenDetails write FOutputTokenDetails;
    property OutputTokens: Int64 read FOutputTokens write FOutputTokens;
    property TotalTokens: Int64 read FTotalTokens write FTotalTokens;
    destructor Destroy; override;
  end;

  TResponseResource = class(TRawJsonBase)
  private
    FAudio: TAudio_output;
    [JsonNameAttribute('conversation_id')] FConversationId: string;
    FId: string;
    [JsonNameAttribute('max_output_tokens')] FMaxOutputTokens: Variant;
    [JSONMarshalled(False)] FJSONMetadata: TJSONValue;
    [JSONMarshalled(False)] FMetadata: string;
    FObject: string;
    FOutput: TArray<TResponseItem>;
    [JsonNameAttribute('output_modalities')] FOutputModalities: TArray<string>;
    FStatus: string;
    FUsage: TResponseResourceUsage;
    procedure SetJSONMetadata(const Value: TJSONValue);
  protected
    class function RawMaps: TArray<TRawMap>; override;
  public
    property Audio: TAudio_output read FAudio write FAudio;
    property ConversationId: string read FConversationId write FConversationId;
    property Id: string read FId write FId;
    property MaxOutputTokens: Variant read FMaxOutputTokens write FMaxOutputTokens;
    property JSONMetadata: TJSONValue read FJSONMetadata write SetJSONMetadata;
    property Metadata: string read FMetadata;
    property &Object: string read FObject write FObject;
    property Output: TArray<TResponseItem> read FOutput write FOutput;
    property OutputModalities: TArray<string> read FOutputModalities write FOutputModalities;
    property Status: string read FStatus write FStatus;
    property Usage: TResponseResourceUsage read FUsage write FUsage;
    destructor Destroy; override;
  end;

  {$ENDREGION}

  {$REGION 'response.content_part.added -> part'}

  TContentPart = class(TRawJsonBase)
  private
    FAudio: string;
    FText: string;
    FTranscript: string;
    FType: string;
  public
    property Audio: string read FAudio write FAudio;
    property Text: string read FText write FText;
    property Transcript: string read FTranscript write FTranscript;
    property &Type: string read FType write FType;
  end;

  {$ENDREGION}

  {$REGION 'response.output_item.added -> item'}

  TMessageContent = class(TRawJsonBase)
  private
    FType: string;
    FAudio: string;
    FDetail: string;
    [JsonNameAttribute('image_url')] FImageUrl: string;
    FText: string;
    FTranscript: string;
  public
    property &Type: string read FType write FType;
    property Audio: string read FAudio write FAudio;
    property Detail: string read FDetail write FDetail;
    property ImageUrl: string read FImageUrl write FImageUrl;
    property Text: string read FText write FText;
    property Transcript: string read FTranscript write FTranscript;
  end;

  TRealtime_role_message_item = class(TRawJsonBase)
  private
    FType: string;
    FContent: TArray<TMessageContent>;
    FRole: string;
    FId: string;
    FObject: string;
    FStatus: string;
  public
    property &Type: string read FType write FType;
    property Content: TArray<TMessageContent> read FContent write FContent;
    property Role: string read FRole write FRole;
    property Id: string read FId write FId;
    property &Object: string read FObject write FObject;
    property Status: string read FStatus write FStatus;
    destructor Destroy; override;
  end;

  TRealtime_function_call_item = class(TRealtime_role_message_item)
  private
    FArguments: string;
    FName: string;
    [JsonNameAttribute('call_id')] FCallId: string;
  public
    property Arguments: string read FArguments write FArguments;
    property Name: string read FName write FName;
    property CallId: string read FCallId write FCallId;
  end;

  TRealtime_function_call_output_item = class(TRealtime_function_call_item)
  private
    FOutput: string;
  public
    property Output: string read FOutput write FOutput;
  end;

  TRealtime_MCP_approval_response = class(TRealtime_function_call_output_item)
  private
    [JsonNameAttribute('call_id')] FApprovalRequestId: string;
    FApprove: Boolean;
    FReason: string;
  public
    property ApprovalRequestId: string read FApprovalRequestId write FApprovalRequestId;
    property Approve: Boolean read FApprove write FApprove;
    property Reason: string read FReason write FReason;
  end;

  TMCPTool = class(TRawJsonBase)
  private
    [JSONMarshalled(False)] FJSONInputSchema: TJSONValue;
    [JSONMarshalled(False)] FInputSchema: string;
    FName: string;
    [JSONMarshalled(False)] FJSONAnnotations: TJSONValue;
    FDescription: string;
    procedure SetJSONInputSchema(const Value: TJSONValue);
    procedure SetJSONAnnotations(const Value: TJSONValue);
  protected
    class function RawMaps: TArray<TRawMap>; override;
  public
    property JSONInputSchema: TJSONValue read FJSONInputSchema write SetJSONInputSchema;
    property InputSchema: string read FInputSchema;
    property Name: string read FName write FName;
    property JSONAnnotations: TJSONValue read FJSONAnnotations write SetJSONAnnotations;
    property Description: string read FDescription write FDescription;
    destructor Destroy; override;
  end;

  TRealtime_MCP_list_tools = class(TRealtime_MCP_approval_response)
  private
    [JsonNameAttribute('server_label')] FServerLabel: string;
    FTools: TArray<TMCPTool>;
  public
    property ServerLabel: string read FServerLabel write FServerLabel;
    property Tools: TArray<TMCPTool> read FTools write FTools;
    destructor Destroy; override;
  end;

  TRealtimeResponseError = class(TRawJsonBase)
  private
    FCode: Int64;
    FMessage: string;
    FType: string;
  public
    property Code: Int64 read FCode write FCode;
    property Message: string read FMessage write FMessage;
    property &Type: string read FType write FType;
  end;

  TRealtime_MCP_tool_call = class(TRealtime_MCP_list_tools)
  private
    [JsonNameAttribute('approval_request_id')] FApprovalRequestId: string;
    FError: TRealtimeResponseError;
  public
    property ApprovalRequestId: string read FApprovalRequestId write FApprovalRequestId;
    property Error: TRealtimeResponseError read FError write FError;
    destructor Destroy; override;
  end;

  TRealtime_MCP_approval_request = class(TRealtime_MCP_tool_call)
  private
  public
  end;

  TResponseItem = class(TRealtime_MCP_approval_request);

  {$ENDREGION}

  {$REGION 'conversation.item.input_audio_transcription.failed -> Error'}

  TTranscriptionError = class(TRawJsonBase)
  private
    FCode: string;
    FMessage: string;
    FParam: string;
    FType: string;
  public
    property Code: string read FCode write FCode;
    property Message: string read FMessage write FMessage;
    property Param: string read FParam write FParam;
    property &Type: string read FType write FType;
  end;

  {$ENDREGION}

  {$REGION 'rate_limits.updated'}

  TRateLimits = class(TRawJsonBase)
  private
    FLimit: Int64;
    FName: string;
    FRemaining: Int64;
    [JsonNameAttribute('reset_seconds')] FResetSeconds: Double;
  public
    property Limit: Int64 read FLimit write FLimit;
    property Name: string read FName write FName;
    property Remaining: Int64 read FRemaining write FRemaining;
    property ResetSeconds: Double read FResetSeconds write FResetSeconds;
  end;

  {$ENDREGION}

implementation

{ TRealtime_role_message_item }

destructor TRealtime_role_message_item.Destroy;
begin
  for var Item in FContent do
    Item.Free;
  inherited;
end;

{ TMCPTool }

destructor TMCPTool.Destroy;
begin
  if Assigned(FJSONInputSchema) then
    FJSONInputSchema.Free;
  if Assigned(FJSONAnnotations) then
    FJSONAnnotations.Free;
  inherited;
end;

class function TMCPTool.RawMaps: TArray<TRawMap>;
begin
  Result := [
    TRawMap.Create('input_schema', 'FJSONInputSchema'),
    TRawMap.Create('annotations', 'FJSONAnnotations')
  ];
end;

procedure TMCPTool.SetJSONAnnotations(const Value: TJSONValue);
begin
  ReplaceJsonValue(FJSONAnnotations, Value);
end;

procedure TMCPTool.SetJSONInputSchema(const Value: TJSONValue);
var
  Obj: TJSONObject;
begin
  ReplaceJsonValue(FJSONInputSchema, Value);
  Obj := Value as TJSONObject;
  if Assigned(Obj) then
    FInputSchema := Obj.ToJSON;
end;

{ TRealtime_MCP_list_tools }

destructor TRealtime_MCP_list_tools.Destroy;
begin
  for var Item in FTools do
    Item.Free;
  inherited;
end;

{ TRealtime_MCP_tool_call }

destructor TRealtime_MCP_tool_call.Destroy;
begin
  if Assigned(FError) then
    FError.Free;
  inherited;
end;

{ TSession }

destructor TSession.Destroy;
begin
  if Assigned(FAudio) then
    FAudio.Free;
  if Assigned(FClientSecret) then
    FClientSecret.Free;
  if Assigned(FPrompt) then
    FPrompt.Free;
  for var Item in FTools do
    Item.Free;
  if Assigned(FJSONTracing) then
    FJSONTracing.Free;
  if Assigned(FTracing) then
    FTracing.Free;
  if Assigned(FJSONTruncation) then
    FJSONTruncation.Free;
  if Assigned(FTruncation) then
    FTruncation.Free;
  inherited;
end;

{ TAudio }

class function TSession.RawMaps: TArray<TRawMap>;
begin
  Result := [
    TRawMap.Create('tracing', 'JSONTracing'),
    TRawMap.Create('truncation', 'JSONTruncation')
  ];
end;

procedure TSession.SetJSONTracing(const Value: TJSONValue);
var
  Obj: TJSONObject;
begin
  ReplaceJsonValue(FJSONTracing, Value);
  if TryAsObject(Value, Obj) then
    FTracing := TJson.JsonToObject<TTracing>(Obj.ToJSON)
end;

procedure TSession.SetJSONTruncation(const Value: TJSONValue);
var
  Obj: TJSONObject;
begin
  ReplaceJsonValue(FJSONTruncation, Value);
  if TryAsObject(Value, Obj) then
    FTruncation := TJson.JsonToObject<TTruncation>(Obj.ToJSON)
end;

{ TAudioInput }

destructor TAudioInput.Destroy;
begin
  if Assigned(FFormat) then
    FFormat.Free;
  if Assigned(FNoiseReduction) then
    FNoiseReduction.Free;
  if Assigned(FTranscription) then
    FTranscription.Free;
  if Assigned(FTurnDetection) then
    FTurnDetection.Free;
  inherited;
end;

{ TAudio }

destructor TAudio.Destroy;
begin
  if Assigned(FInput) then
    FInput.Free;
  if Assigned(FOutput) then
    FOutput.Free;
  inherited;
end;

{ TAudioOutput }

destructor TAudioOutput.Destroy;
begin
  if Assigned(FFormat) then
    FFormat.Free;
  inherited;
end;

{ TPrompt }

destructor TPrompt.Destroy;
begin
  if Assigned(FVariables) then
    FVariables.Free;
  inherited;
end;

class function TPrompt.RawMaps: TArray<TRawMap>;
begin
  Result := [
    TRawMap.Create('variables', 'variables')
  ];
end;

procedure TPrompt.SetVariables(const Value: TJSONValue);
begin
  ReplaceJsonValue(FVariables, Value);
end;

{ TTool }

destructor TTool.Destroy;
begin
  if Assigned(FParameters) then
    FParameters.Free;
  if Assigned(FJSONAllowedTools) then
    FJSONAllowedTools.Free;
  if Assigned(FAllowedTools) then
    FAllowedTools.Free;
  if Assigned(FHeaders) then
    FHeaders.Free;
  if Assigned(FJSONRequireApproval) then
    FJSONRequireApproval.Free;
  if Assigned(FrequireApproval) then
    FrequireApproval.Free;
  inherited;
end;

class function TTool.RawMaps: TArray<TRawMap>;
begin
  Result := [
    TRawMap.Create('parameters', 'parameters'),
    TRawMap.Create('headers', 'headers'),
    TRawMap.Create('require_approval', 'JSONRequireApproval'),
    TRawMap.Create('allowed_tools', 'JSONAllowedTools')
  ];
end;

procedure TTool.SetHeaders(const Value: TJSONValue);
begin
  ReplaceJsonValue(FHeaders, Value);
end;

procedure TTool.SetJSONAllowedTools(const Value: TJSONValue);
var
  Obj : TJSONObject;
  S   : string;
begin
  ReplaceJsonValue(FJSONAllowedTools, Value);
  if TryAsObject(Value, Obj) then
    FAllowedTools := TJson.JsonToObject<TAllowedTools>(Obj.ToJSON)
  else
  if Value is TJSONArray then
    begin
      var JA := TJSONArray(Value);
      for var I := 0 to JA.Count - 1 do
        begin
          if TRawJsonBase.TryAsString(JA.Items[I], S) then
            FAllowedToolsArray := FAllowedToolsArray + [S];
        end;
    end;
end;

procedure TTool.SetJSONRequireApproval(const Value: TJSONValue);
var
  Obj: TJSONObject;
begin
  ReplaceJsonValue(FJSONRequireApproval, Value);
  if TryAsObject(Value, Obj) then
    FrequireApproval := TJson.JsonToObject<TMCPToolApprovalFilter>(Obj.ToJSON)
end;

procedure TTool.SetParameters(const Value: TJSONValue);
begin
  ReplaceJsonValue(FParameters, Value);
end;

{ TMCPToolApprovalFilter }

destructor TMCPToolApprovalFilter.Destroy;
begin
  if Assigned(FAlways) then
    FAlways.Free;
  if Assigned(FNever) then
    FNever.Free;
  inherited;
end;

{ TTracing }

destructor TTracing.Destroy;
begin
  if Assigned(FMetadata) then
    FMetadata.Free;
  inherited;
end;

class function TTracing.RawMaps: TArray<TRawMap>;
begin
  Result := [
    TRawMap.Create('Metadata', 'Metadata')
  ];
end;

procedure TTracing.SetMetadata(const Value: TJSONValue);
begin
  ReplaceJsonValue(FMetadata, Value);
end;

{ TUsage }

destructor TUsage.Destroy;
begin
  if Assigned(FInputTokenDetails) then
    FInputTokenDetails.Free;
  inherited;
end;

{ TAudio_output }

destructor TAudio_output.Destroy;
begin
  if Assigned(FOutput) then
    FOutput.Free;
  inherited;
end;

{ TResponseResource }

destructor TResponseResource.Destroy;
begin
  if Assigned(FAudio) then
    FAudio.Free;
  if Assigned(FJSONMetadata) then
    FJSONMetadata.Free;
  for var Item in FOutput do
    Item.Free;
  if Assigned(FUsage) then
    FUsage.Free;
  inherited;
end;

class function TResponseResource.RawMaps: TArray<TRawMap>;
begin
  Result := [
    TRawMap.Create('metadata', 'FJSONMetadata')
  ];
end;

procedure TResponseResource.SetJSONMetadata(const Value: TJSONValue);
var
  S: string;
begin
  ReplaceJsonValue(FJSONMetadata, Value);
  if TryAsString(Value, S) then
    FMetadata := S;
end;

{ TResponseResourceUsage }

destructor TResponseResourceUsage.Destroy;
begin
  if Assigned(FInputTokenDetails) then
    FInputTokenDetails.Free;
  if Assigned(FOutputTokenDetails) then
    FOutputTokenDetails.Free;
  inherited;
end;

{ TResourceInputTokenDetails }

destructor TResourceInputTokenDetails.Destroy;
begin
  if Assigned(FCachedTokensDetails) then
    FCachedTokensDetails.Free;
  inherited;
end;

end.
