unit Realtime;

interface

uses
  System.SysUtils, System.Classes,
  Realtime.API.Client, Realtime.Params, Realtime.DTOs, Realtime.ClientSecrets,
  Realtime.Events.Server, Realtime.Events.DTOs.Helper, Realtime.Session,
  Realtime.InputAudioBuffer, Realtime.Conversation, Realtime.Response,
  Realtime.OutputAudioBuffer, Realtime.Schema;

const
  VERSION = 'Realtimev1.0.0';

type
  IRealTime = interface
    ['{F7DB225D-4C9C-40C0-9C74-C93B3EE5E24A}']
    function GetAPI: TRealtimeAPI;
    function GetAPIKey: string;
    function GetBaseUrl: string;
    function GetSendMethod: TSendProc;
    function GetUrlForCall: string;
    function GetVersion: string;
    procedure SetAPIKey(const Value: string);
    procedure SetBaseUrl(const Value: string);
    procedure SetSendMethod(const Value: TSendProc);

    function GetClientSecretsRoute: TClientSecretsRoute;
    function GetSessionRoute: TSessionRoute;
    function GetInputAudioBufferRoute: TInputAudioBufferRoute;
    function GetConversationRoute: TConversationRoute;
    function GetResponseRoute: TResponseRoute;
    function GetOutputAudioBufferRoute: TOutputAudioBufferRoute;
    property ClientSecrets: TClientSecretsRoute read GetClientSecretsRoute;
    property Session: TSessionRoute read GetSessionRoute;
    property InputAudioBuffer: TInputAudioBufferRoute read GetInputAudioBufferRoute;
    property Conversation: TConversationRoute read GetConversationRoute;
    property Response: TResponseRoute read GetResponseRoute;
    property OutputAudioBuffer: TOutputAudioBufferRoute read GetOutputAudioBufferRoute;
    property API: TRealtimeAPI read GetAPI;
    property APIKey: string read GetAPIKey write SetAPIKey;
    property BaseURL: string read GetBaseUrl write SetBaseUrl;
    property SendMethod: TSendProc read GetSendMethod write SetSendMethod;
    property UrlForCall: string read GetUrlForCall;
    property Version: string read GetVersion;
  end;

  TRealTimeFactory = class
    class function CreateInstance(const APIKey: string): IRealTime;
  end;

  TRealTime = class(TInterfacedObject, IRealTime)
  private
    FAPI: TRealtimeAPI;
    FClientSecretsRoute: TClientSecretsRoute;
    FSessionRoute: TSessionRoute;
    FInputAudioBufferRoute: TInputAudioBufferRoute;
    FConversationRoute: TConversationRoute;
    FResponseRoute: TResponseRoute;
    FOutputAudioBufferRoute: TOutputAudioBufferRoute;

    function GetAPI: TRealtimeAPI;
    function GetAPIKey: string;
    function GetBaseUrl: string;
    function GetSendMethod: TSendProc;
    function GetUrlForCall: string;
    function GetVersion: string;
    procedure SetAPIKey(const Value: string);
    procedure SetBaseUrl(const Value: string);
    procedure SetSendMethod(const Value: TSendProc);

    function GetClientSecretsRoute: TClientSecretsRoute;
    function GetSessionRoute: TSessionRoute;
    function GetInputAudioBufferRoute: TInputAudioBufferRoute;
    function GetConversationRoute: TConversationRoute;
    function GetResponseRoute: TResponseRoute;
    function GetOutputAudioBufferRoute: TOutputAudioBufferRoute;

  public
    constructor Create; overload;
    constructor Create(const AAKey: string); overload;
    destructor Destroy; override;

    property API: TRealtimeAPI read GetAPI;
    property APIKey: string read GetAPIKey write SetAPIKey;
    property BaseURL: string read GetBaseUrl write SetBaseUrl;
  end;

  {$REGION 'Realtime.Schema'}

  TPropertyItem = Realtime.Schema.TPropertyItem;
  TSchemaParams = Realtime.Schema.TSchemaParams;

  {$ENDREGION}

  {$REGION 'Realtime.Events.DTOs.Helper'}

  TClientSecret = Realtime.Events.DTOs.Helper.TClientSecret;
  TTranscription = Realtime.Events.DTOs.Helper.TTranscription;
  TPrompt = Realtime.Events.DTOs.Helper.TPrompt;
  TTool = Realtime.Events.DTOs.Helper.TTool;
  TTurnDetection = Realtime.Events.DTOs.Helper.TTurnDetection;
  TSession = Realtime.Events.DTOs.Helper.TSession;

  {$ENDREGION}

  {$REGION 'Realtime.Params'}

  TAudioFormatParams = Realtime.Params.TAudioFormatParams;
  TNoiseReduction = Realtime.Params.TNoiseReduction;
  TTranscriptionParams = Realtime.Params.TTranscriptionParams;
  TTurnDetectionParams = Realtime.Params.TTurnDetectionParams;
  TAudioInputParams = Realtime.Params.TAudioInputParams;
  TAudioOutputParams = Realtime.Params.TAudioOutputParams;
  TAudioParams = Realtime.Params.TAudioParams;
  TPromptParams = Realtime.Params.TPromptParams;
  TToolChoiceParams = Realtime.Params.TToolChoiceParams;
  TFunctionToolParams = Realtime.Params.TFunctionToolParams;
  TMCPToolParams = Realtime.Params.TMCPToolParams;
  TToolsParams = Realtime.Params.TToolsParams;
  TFunctionParams = Realtime.Params.TFunctionParams;
  TAllowedToolsParams = Realtime.Params.TAllowedToolsParams;
  TAlwaysOrNeverParams = Realtime.Params.TAlwaysOrNeverParams;
  TRequireApprovalParams = Realtime.Params.TRequireApprovalParams;
  TMCPParams = Realtime.Params.TMCPParams;
  TTracingParams = Realtime.Params.TTracingParams;
  TTruncationParams = Realtime.Params.TTruncationParams;
  TSessionParams = Realtime.Params.TSessionParams;
  TExpiresAfterParams = Realtime.Params.TExpiresAfterParams;


  TResponseAudioParams = Realtime.Params.TResponseAudioParams;
  TInputParams = Realtime.Params.TInputParams;
  TSystemContent = Realtime.Params.TSystemContent;
  TUserContent = Realtime.Params.TUserContent;
  TAssistantContent = Realtime.Params.TAssistantContent;
  TMCPTool = Realtime.Params.TMCPTool;
  TMCPError = Realtime.Params.TMCPError;
  TSystemMessageParams = Realtime.Params.TSystemMessageParams;
  TUserMessageParams = Realtime.Params.TUserMessageParams;
  TAssistantMessageParams = Realtime.Params.TAssistantMessageParams;
  TFunctionCallParams = Realtime.Params.TFunctionCallParams;
  TFunctionCallOutputParams = Realtime.Params.TFunctionCallOutputParams;
  TMCPApprovalResponseParams = Realtime.Params.TMCPApprovalResponseParams;
  TMCPListToolsParams = Realtime.Params.TMCPListToolsParams;
  TMCPToolCall = Realtime.Params.TMCPToolCall;
  TMCPApprovalRequest = Realtime.Params.TMCPApprovalRequest;
  TResponseParams = Realtime.Params.TResponseParams;

  {$ENDREGION}

  {$REGION 'Realtime.DTOs'}

  TSessionResponse = Realtime.DTOs.TSessionResponse;
  TAsyncSessionResponse = Realtime.DTOs.TAsyncSessionResponse;

  {$ENDREGION}

  {$REGION 'Realtime.ClientSecrets'}

  TClientSecretParams = Realtime.ClientSecrets.TClientSecretParams;

  {$ENDREGION}

  {$REGION 'Realtime.Session'}

  TSessionUpdateParams = Realtime.Session.TSessionUpdateParams;

  {$ENDREGION}

  {$REGION 'Realtime.Conversation'}

  TConversationItemCreateParams = Realtime.Conversation.TConversationItemCreateParams;
  TConversationItemRetrieveParams = Realtime.Conversation.TConversationItemRetrieveParams;
  TConversationItemTruncateParams = Realtime.Conversation.TConversationItemTruncateParams;
  TConversationItemDeleteParams = Realtime.Conversation.TConversationItemDeleteParams;

  {$ENDREGION}

  {$REGION 'Realtime.InputAudioBuffer'}

  TInputAudioBufferAppendParams = Realtime.InputAudioBuffer.TInputAudioBufferAppendParams;
  TInputAudioBufferCommitParams = Realtime.InputAudioBuffer.TInputAudioBufferCommitParams;
  TInputAudioBufferClearParams = Realtime.InputAudioBuffer.TInputAudioBufferClearParams;

  {$ENDREGION}

  {$REGION 'Realtime.Response'}

  TResponseCancelParams = Realtime.Response.TResponseCancelParams;
  TResponseCreateParams = Realtime.Response.TResponseCreateParams;

  {$ENDREGION}

  {$REGION 'Realtime.OutputAudioBuffer'}

  TOutputAudioBufferParams = Realtime.OutputAudioBuffer.TOutputAudioBufferParams;

  {$ENDREGION}

  {$REGION 'Realtime.Events.Server'}

  /// <summary>
  ///   Returned when a Session is created. Emitted automatically when a new connection is established
  ///   as the first server event. This event will contain the default Session configuration.
  /// </summary>
  TSession_created = Realtime.Events.Server.TSession_created;

  /// <summary>
  ///   Returned when a session is updated with a session.update event, unless there is an error.
  /// </summary>
  TSession_updated = Realtime.Events.Server.TSession_updated;

  /// <summary>
  ///   Sent by the server when an Item is added to the default Conversation.
  /// </summary>
  /// <remarks>
  ///   This can happen in several cases:
  /// <para>
  ///   - When the client sends a conversation.item.create event.
  /// </para>
  /// <para>
  ///   - When the input audio buffer is committed. In this case the item will be a user message containing
  ///   the audio from the buffer.
  /// </para>
  /// <para>
  ///   - When the model is generating a Response. In this case the conversation.item.added event will be
  ///   sent when the model starts generating a specific Item, and thus it will not yet have any content
  ///   (and status will be in_progress).
  /// </para>
  ///   The event will include the full content of the Item (except when model is generating a Response)
  ///   except for audio data, which can be retrieved separately with a conversation.item.retrieve event
  ///   if necessary.
  /// </remarks>
  TConversation_item_added = Realtime.Events.Server.TConversation_item_added;

  /// <summary>
  ///   Returned when a conversation item is finalized.
  /// </summary>
  /// <remarks>
  ///   The event will include the full content of the Item except for audio data, which can be retrieved
  ///   separately with a conversation.item.retrieve event if needed.
  /// </remarks>
  Tconversation_item_done = Realtime.Events.Server.Tconversation_item_done;

  /// <summary>
  ///   Returned when a conversation item is retrieved with conversation.item.retrieve.
  /// </summary>
  /// <remarks>
  ///   This is provided as a way to fetch the server's representation of an item, for example to get
  ///   access to the post-processed audio data after noise cancellation and VAD. It includes the full
  ///   content of the Item, including audio data.
  /// </remarks>
  TConversation_item_retrieved = Realtime.Events.Server.TConversation_item_retrieved;

  /// <summary>
  ///   This event is the output of audio transcription for user audio written to the user audio buffer.
  ///   Transcription begins when the input audio buffer is committed by the client or server (when VAD
  ///   is enabled). Transcription runs asynchronously with Response creation, so this event may come
  ///   before or after the Response events.
  /// </summary>
  /// <remarks>
  ///   Realtime API models accept audio natively, and thus input transcription is a separate process run
  ///   on a separate ASR (Automatic Speech Recognition) model. The transcript may diverge somewhat from
  ///   the model's interpretation, and should be treated as a rough guide.
  /// </remarks>
  TConversation_item_input_audio_tanscription_completed = Realtime.Events.Server.TConversation_item_input_audio_tanscription_completed;

  /// <summary>
  ///   Returned when the text value of an input audio transcription content part is updated with incremental
  //    transcription results.
  /// </summary>
  TConversation_item_input_audio_transcription_delta = Realtime.Events.Server.TConversation_item_input_audio_transcription_delta;

  /// <summary>
  ///   Returned when an input audio transcription segment is identified for an item.
  /// </summary>
  TConversation_item_input_audio_transcription_segment = Realtime.Events.Server.TConversation_item_input_audio_transcription_segment;

  /// <summary>
  ///   Returned when input audio transcription is configured, and a transcription request for a user
  ///   message failed.
  /// </summary>
  /// <remarks>
  ///   These events are separate from other error events so that the client can identify the related Item.
  /// </remarks>
  TConversation_item_input_audio_transcription_failed = Realtime.Events.Server.TConversation_item_input_audio_transcription_failed;

  /// <summary>
  ///   Returned when an earlier assistant audio message item is truncated by the client with a
  ///   conversation.item.truncate event. This event is used to synchronize the server's understanding
  ///   of the audio with the client's playback.
  /// </summary>
  /// <remarks>
  ///   This action will truncate the audio and remove the server-side text transcript to ensure there
  ///   is no text in the context that hasn't been heard by the user.
  /// </remarks>
  TConversation_item_truncated = Realtime.Events.Server.TConversation_item_truncated;

  /// <summary>
  ///   Returned when an item in the conversation is deleted by the client with a conversation.item.delete
  ///   event. This event is used to synchronize the server's understanding of the conversation history
  ///   with the client's view.
  /// </summary>
  TConversation_item_deleted = Realtime.Events.Server.TConversation_item_deleted;

  /// <summary>
  ///   Returned when an input audio buffer is committed, either by the client or automatically in server
  ///   VAD mode. The item_id property is the ID of the user message item that will be created, thus a
  ///   conversation.item.created event will also be sent to the client.
  /// </summary>
  TInput_audio_buffer_committed = Realtime.Events.Server.TInput_audio_buffer_committed;

  /// <summary>
  ///   Returned when the input audio buffer is cleared by the client with a input_audio_buffer.clear event.
  /// </summary>
  TInput_audio_buffer_cleared = Realtime.Events.Server.TInput_audio_buffer_cleared;

  /// <summary>
  ///   Sent by the server when in server_vad mode to indicate that speech has been detected in the audio
  ///   buffer. This can happen any time audio is added to the buffer (unless speech is already detected).
  ///   The client may want to use this event to interrupt audio playback or provide visual feedback to
  ///   the user.
  /// </summary>
  /// <remarks>
  ///   The client should expect to receive a input_audio_buffer.speech_stopped event when speech stops.
  ///   The item_id property is the ID of the user message item that will be created when speech stops
  ///   and will also be included in the input_audio_buffer.speech_stopped event (unless the client
  ///   manually commits the audio buffer during VAD activation).
  /// </remarks>
  TInput_audio_buffer_speech_started = Realtime.Events.Server.TInput_audio_buffer_speech_started;

  /// <summary>
  ///   Returned in server_vad mode when the server detects the end of speech in the audio buffer.
  ///   The server will also send an conversation.item.created event with the user message item that
  ///   is created from the audio buffer.
  /// </summary>
  TInput_audio_buffer_speech_stopped = Realtime.Events.Server.TInput_audio_buffer_speech_stopped;

  /// <summary>
  ///   Returned when the Server VAD timeout is triggered for the input audio buffer. This is configured
  ///   with idle_timeout_ms in the turn_detection settings of the session, and it indicates that there
  ///   hasn't been any speech detected for the configured duration.
  /// </summary>
  /// <remarks>
  /// <para>
  ///   The audio_start_ms and audio_end_ms fields indicate the segment of audio after the last model
  ///   response up to the triggering time, as an offset from the beginning of audio written to the input
  ///   audio buffer. This means it demarcates the segment of audio that was silent and the difference
  ///   between the start and end values will roughly match the configured timeout.
  /// </para>
  /// <para>
  ///   The empty audio will be committed to the conversation as an input_audio item (there will be a
  ///   input_audio_buffer.committed event) and a model response will be generated. There may be speech
  ///   that didn't trigger VAD but is still detected by the model, so the model may respond with
  ///   something relevant to the conversation or a prompt to continue speaking.
  /// </para>
  /// </remarks>
  TInput_audio_buffer_timeout_triggered = Realtime.Events.Server.TInput_audio_buffer_timeout_triggered;

  TOutput_audio_buffer_started = Realtime.Events.Server.TOutput_audio_buffer_started;
  TOutput_audio_buffer_stopped = Realtime.Events.Server.TOutput_audio_buffer_stopped;
  TOutput_audio_buffer_cleared = Realtime.Events.Server.TOutput_audio_buffer_cleared;

  /// <summary>
  ///   Returned when a new Response is created. The first event of response creation, where the response
  ///   is in an initial state of in_progress.
  /// </summary>
  TResponse_created = Realtime.Events.Server.TResponse_created;

  /// <summary>
  ///   Returned when a Response is done streaming. Always emitted, no matter the final state. The
  ///   Response object included in the response.done event will include all output Items in the Response
  ///   but will omit the raw audio data.
  /// </summary>
  /// <remarks>
  /// <para>
  ///   Clients should check the status field of the Response to determine if it was successful (completed)
  ///   or if there was another outcome: cancelled, failed, or incomplete.
  /// </para>
  /// <para>
  ///   A response will contain all output items that were generated during the response, excluding any audio
  ///   content.
  /// </para>
  /// </remarks>
  TResponse_done = Realtime.Events.Server.TResponse_done;

  /// <summary>
  ///   Returned when a new Item is created during Response generation.
  /// </summary>
  TResponse_output_item_added = Realtime.Events.Server.TResponse_output_item_added;

  /// <summary>
  ///   Returned when an Item is done streaming. Also emitted when a Response is interrupted, incomplete,
  ///   or cancelled.
  /// </summary>
  TResponse_output_item_done = Realtime.Events.Server.TResponse_output_item_done;

  /// <summary>
  ///   Returned when a new content part is added to an assistant message item during response generation.
  /// </summary>
  TResponse_content_part_added = Realtime.Events.Server.TResponse_content_part_added;

  /// <summary>
  ///   Returned when a content part is done streaming in an assistant message item. Also emitted when a
  ///   Response is interrupted, incomplete, or cancelled.
  /// </summary>
  TResponse_content_part_done = Realtime.Events.Server.TResponse_content_part_done;

  /// <summary>
  ///   Returned when the text value of an "output_text" content part is updated.
  /// </summary>
  TResponse_output_text_delta = Realtime.Events.Server.TResponse_output_text_delta;

  /// <summary>
  ///   Returned when the text value of an "output_text" content part is done streaming. Also emitted
  ///   when a Response is interrupted, incomplete, or cancelled.
  /// </summary>
  TResponse_output_text_done = Realtime.Events.Server.TResponse_output_text_done;

  /// <summary>
  ///   Returned when the model-generated transcription of audio output is updated.
  /// </summary>
  TResponse_output_audio_transcript_delta = Realtime.Events.Server.TResponse_output_audio_transcript_delta;

  /// <summary>
  ///   Returned when the model-generated transcription of audio output is done streaming. Also emitted
  ///   when a Response is interrupted, incomplete, or cancelled.
  /// </summary>
  TResponse_output_audio_transcript_done = Realtime.Events.Server.TResponse_output_audio_transcript_done;

  /// <summary>
  ///   Returned when the model-generated audio is updated.
  /// </summary>
  TResponse_output_audio_delta = Realtime.Events.Server.TResponse_output_audio_delta;

  /// <summary>
  ///   Returned when the model-generated audio is done. Also emitted when a Response is interrupted,
  ///   incomplete, or cancelled.
  /// </summary>
  TResponse_output_audio_done = Realtime.Events.Server.TResponse_output_audio_done;

  /// <summary>
  ///   Returned when the model-generated function call arguments are updated.
  /// </summary>
  TResponse_function_call_arguments_delta = Realtime.Events.Server.TResponse_function_call_arguments_delta;

  /// <summary>
  ///   Returned when the model-generated function call arguments are done streaming. Also emitted when a
  ///   Response is interrupted, incomplete, or cancelled.
  /// </summary>
  TResponse_function_call_arguments_done = Realtime.Events.Server.TResponse_function_call_arguments_done;

  /// <summary>
  ///   Returned when MCP tool call arguments are updated during response generation.
  /// </summary>
  TResponse_mcp_call_arguments_delta = Realtime.Events.Server.TResponse_mcp_call_arguments_delta;

  /// <summary>
  ///   Returned when MCP tool call arguments are finalized during response generation.
  /// </summary>
  TResponse_mcp_call_arguments_done = Realtime.Events.Server.TResponse_mcp_call_arguments_done;

  /// <summary>
  ///   Returned when an MCP tool call has started and is in progress.
  /// </summary>
  TResponse_mcp_call_in_progress = Realtime.Events.Server.TResponse_mcp_call_in_progress;

  /// <summary>
  ///   Returned when an MCP tool call has completed successfully.
  /// </summary>
  TResponse_mcp_call_completed = Realtime.Events.Server.TResponse_mcp_call_completed;

  /// <summary>
  ///   Returned when an MCP tool call has failed.
  /// </summary>
  TResponse_mcp_call_failed = Realtime.Events.Server.TResponse_mcp_call_failed;

  /// <summary>
  ///   Returned when listing MCP tools is in progress for an item.
  /// </summary>
  TMcp_list_tools_in_progress = Realtime.Events.Server.TMcp_list_tools_in_progress;

  /// <summary>
  ///   Returned when listing MCP tools has completed for an item.
  /// </summary>
  TMcp_list_tools_completed = Realtime.Events.Server.TMcp_list_tools_completed;

  /// <summary>
  ///   Returned when listing MCP tools has failed for an item.
  /// </summary>
  Tmcp_list_tools_failed = Realtime.Events.Server.Tmcp_list_tools_failed;

  /// <summary>
  ///   Emitted at the beginning of a Response to indicate the updated rate limits.
  /// </summary>
  /// <remarks>
  ///   When a Response is created some tokens will be "reserved" for the output tokens, the rate
  ///   limits shown here reflect that reservation, which is then adjusted accordingly once the
  ///   Response is completed.
  /// </remarks>
  TRate_limits_updated = Realtime.Events.Server.TRate_limits_updated;

  {$ENDREGION}

implementation

{ TRealTime }

constructor TRealTime.Create;
begin
  inherited Create;
  FAPI := TRealtimeAPI.Create;
end;

constructor TRealTime.Create(const AAKey: string);
begin
  Create;
  APIKey := AAKey;
end;

destructor TRealTime.Destroy;
begin
  FClientSecretsRoute.Free;
  FSessionRoute.Free;
  FInputAudioBufferRoute.Free;
  FConversationRoute.Free;
  FResponseRoute.Free;
  FOutputAudioBufferRoute.Free;

  FAPI.Free;
  inherited;
end;

function TRealTime.GetAPI: TRealtimeAPI;
begin
  Result := FAPI;
end;

function TRealTime.GetBaseUrl: string;
begin
  Result := FAPI.BaseURL;
end;

function TRealTime.GetClientSecretsRoute: TClientSecretsRoute;
begin
  if not Assigned(FClientSecretsRoute) then
    FClientSecretsRoute := TClientSecretsRoute.CreateRoute(API);
  Result := FClientSecretsRoute;
end;

function TRealTime.GetConversationRoute: TConversationRoute;
begin
  if not Assigned(FConversationRoute) then
    FConversationRoute := TConversationRoute.CreateRoute(API);
  Result := FConversationRoute;
end;

function TRealTime.GetInputAudioBufferRoute: TInputAudioBufferRoute;
begin
  if not Assigned(FInputAudioBufferRoute) then
    FInputAudioBufferRoute := TInputAudioBufferRoute.CreateRoute(API);
  Result := FInputAudioBufferRoute;
end;

function TRealTime.GetOutputAudioBufferRoute: TOutputAudioBufferRoute;
begin
  if not Assigned(FOutputAudioBufferRoute) then
    FOutputAudioBufferRoute := TOutputAudioBufferRoute.CreateRoute(API);
  Result := FOutputAudioBufferRoute;
end;

function TRealTime.GetResponseRoute: TResponseRoute;
begin
  if not Assigned(FResponseRoute) then
    FResponseRoute := TResponseRoute.CreateRoute(API);
  Result := FResponseRoute;
end;

function TRealTime.GetSendMethod: TSendProc;
begin
  Result := API.SendMethod;
end;

function TRealTime.GetSessionRoute: TSessionRoute;
begin
  if not Assigned(FSessionRoute) then
    FSessionRoute := TSessionRoute.CreateRoute(API);
  Result := FSessionRoute;
end;

function TRealTime.GetUrlForCall: string;
begin
  Result := FAPI.GetCallUrl;
end;

function TRealTime.GetVersion: string;
begin
  Result := VERSION;
end;

function TRealTime.GetAPIKey: string;
begin
  Result := FAPI.APIKey;
end;

procedure TRealTime.SetBaseUrl(const Value: string);
begin
  FAPI.BaseURL := Value;
end;

procedure TRealTime.SetSendMethod(const Value: TSendProc);
begin
  API.SendMethod := Value;
end;

procedure TRealTime.SetAPIKey(const Value: string);
begin
  FAPI.APIKey := Value;
end;

{ TRealTimeFactory }

class function TRealTimeFactory.CreateInstance(const APIKey: string): IRealTime;
begin
  Result := TRealTime.Create(APIKey);
end;

end.
