unit Realtime.Params;

interface

uses
  System.SysUtils, System.JSON, System.Math, Realtime.API.JsonParams, Realtime.Types,
  Realtime.Schema;

type

  {$REGION 'Create client secret -> session'}

  TAudioFormatParams = class(TJSONParam)
    /// <summary>
    ///   The audio format. audio/pcm or audio/pcmu or audio/pcma
    /// </summary>
    function &Type(const Value: TAudioType): TAudioFormatParams;

    /// <summary>
    ///   The sample rate of the audio. Always 24000.
    /// </summary>
    function Rate(const Value: Integer = 24000): TAudioFormatParams;

    class function New(const Value: TAudioType): TAudioFormatParams; overload;
    class function New(const Value: string): TAudioFormatParams; overload;
  end;

  TNoiseReduction = class(TJSONParam)
    /// <summary>
    ///   Type of noise reduction. near_field is for close-talking microphones such as headphones,
    ///   far_field is for far-field microphones such as laptop or conference room microphones.
    /// </summary>
    function &Type(const Value: TNoiseReductionType): TNoiseReduction;

    class function New(const Value: TNoiseReductionType): TNoiseReduction; overload;
    class function New(const Value: string): TNoiseReduction; overload;
  end;

  TTranscriptionParams = class(TJSONParam)
    /// <summary>
    ///   The language of the input audio. Supplying the input language in ISO-639-1 (e.g. en) format
    ///   will improve accuracy and latency.
    /// </summary>
    function Language(const Value: string): TTranscriptionParams; overload;

    /// <summary>
    ///   The language of the input audio. Supplying the input language in ISO-639-1 (e.g. en) format
    ///   will improve accuracy and latency.
    /// </summary>
    function Language(const Value: TLanguageCodes): TTranscriptionParams; overload;

    /// <summary>
    ///   The model to use for transcription. Current options are whisper-1, gpt-4o-transcribe-latest,
    ///   gpt-4o-mini-transcribe, and gpt-4o-transcribe.
    /// </summary>
    function Model(const Value: string): TTranscriptionParams;

    /// <summary>
    ///   An optional text to guide the model's style or continue a previous audio segment.
    /// </summary>
    /// <remarks>
    ///   For whisper-1, the prompt is a list of keywords. For gpt-4o-transcribe models, the prompt is a
    ///   free text string, for example "expect words related to technology".
    /// </remarks>
    function Prompt(const Value: string): TTranscriptionParams;

    class function New(const Model: string): TTranscriptionParams;
  end;

  TTurnDetectionParams = class(TJSONParam)
    /// <summary>
    ///   Whether or not to automatically generate a response when a VAD stop event occurs.
    /// </summary>
    function CreateResponse(const Value: Boolean): TTurnDetectionParams;

    /// <summary>
    ///   Used only for semantic_vad mode. The eagerness of the model to respond. low will wait longer
    ///   for the user to continue speaking, high will respond more quickly. auto is the default and is
    ///   equivalent to medium. low, medium, and high have max timeouts of 8s, 4s, and 2s respectively.
    /// </summary>
    function Eagerness(const Value: TEagernessType): TTurnDetectionParams;

    /// <summary>
    ///   Optional timeout after which a model response will be triggered automatically. This is useful
    ///   for situations in which a long pause from the user is unexpected, such as a phone call. The
    ///   model will effectively prompt the user to continue the conversation based on the current
    ///   context.
    /// </summary>
    /// <remarks>
    /// <para>
    ///   - The timeout value will be applied after the last model response's audio has finished playing,
    ///   i.e. it's set to the response.done time plus audio playback duration.
    /// </para>
    /// <para>
    ///   - An input_audio_buffer.timeout_triggered event (plus events associated with the Response)
    ///   will be emitted when the timeout is reached. Idle timeout is currently only supported for
    ///   server_vad mode.
    /// </para>
    /// </remarks>
    function IdleTimeoutMs(const Value: Integer): TTurnDetectionParams;

    /// <summary>
    ///   Whether or not to automatically interrupt any ongoing response with output to the default
    ///   conversation (i.e. conversation of auto) when a VAD start event occurs.
    /// </summary>
    function InterruptResponse(const Value: Boolean): TTurnDetectionParams;

    /// <summary>
    ///   Used only for server_vad mode. Amount of audio to include before the VAD detected speech
    ///   (in milliseconds). Defaults to 300ms.
    /// </summary>
    function PrefixPaddingMs(const Value: Integer = 300): TTurnDetectionParams;

    /// <summary>
    ///   Used only for server_vad mode. Duration of silence to detect speech stop (in milliseconds).
    ///   Defaults to 500ms. With shorter values the model will respond more quickly, but may jump in
    ///   on short pauses from the user.
    /// </summary>
    function SilenceDurationMs(const Value: Integer = 500): TTurnDetectionParams;

    /// <summary>
    ///   Used only for server_vad mode. Activation threshold for VAD (0.0 to 1.0), this defaults to 0.5.
    ///   A higher threshold will require louder audio to activate the model, and thus might perform
    ///   better in noisy environments.
    /// </summary>
    function Threshold(const Value: Double = 0.5): TTurnDetectionParams;

    /// <summary>
    ///   Type of turn detection.
    /// </summary>
    /// <remarks>
    /// <para>
    ///   - server_vad to turn on simple Server VAD
    /// </para>
    /// <para>
    ///   - semantic_vad to turn on Semantic VAD.
    /// </para>
    /// </remarks>
    function &Type(const Value: string): TTurnDetectionParams; overload;

    /// <summary>
    ///   Type of turn detection.
    /// </summary>
    /// <remarks>
    /// <para>
    ///   - server_vad to turn on simple Server VAD
    /// </para>
    /// <para>
    ///   - semantic_vad to turn on Semantic VAD.
    /// </para>
    /// </remarks>
    function &Type(const Value: TTurnDetectionType): TTurnDetectionParams; overload;

    class function New(const Value: string): TTurnDetectionParams; overload;
    class function New(const Value: TTurnDetectionType): TTurnDetectionParams; overload;
  end;

  TAudioInputParams = class(TJSONParam)
    /// <summary>
    ///   The format of the input audio.
    /// </summary>
    function Format(const Value: TAudioFormatParams): TAudioInputParams;

    /// <summary>
    ///   Configuration for input audio noise reduction. This can be set to null to turn off.
    /// </summary>
    /// <remarks>
    ///   Noise reduction filters audio added to the input audio buffer before it is sent to VAD and
    ///   the model. Filtering the audio can improve VAD and turn detection accuracy (reducing false
    ///   positives) and model performance by improving perception of the input audio.
    /// </remarks>
    function NoiseReduction(const Value: TNoiseReduction): TAudioInputParams;

    /// <summary>
    ///   Configuration for input audio transcription, defaults to off and can be set to null to turn
    ///   off once on.
    /// </summary>
    /// <remarks>
    ///   Input audio transcription is not native to the model, since the model consumes audio directly.
    ///   Transcription runs asynchronously through the /audio/transcriptions endpoint and should be
    ///   treated as guidance of input audio content rather than precisely what the model heard.
    ///   The client can optionally set the language and prompt for transcription, these offer additional
    ///   guidance to the transcription service.
    /// </remarks>
    function Transcription(const Value: TTranscriptionParams): TAudioInputParams;

    /// <summary>
    ///   Configuration for turn detection, ether Server VAD or Semantic VAD. This can be set to null to
    ///   turn off, in which case the client must manually trigger model response.
    /// </summary>
    /// <remarks>
    /// <para>
    ///   - Server VAD means that the model will detect the start and end of speech based on audio volume
    ///   and respond at the end of user speech.
    /// </para>
    /// <para>
    ///   - Semantic VAD is more advanced and uses a turn detection model (in conjunction with VAD) to
    ///   semantically estimate whether the user has finished speaking, then dynamically sets a timeout
    ///   based on this probability. For example, if user audio trails off with "uhhm", the model will
    ///   score a low probability of turn end and wait longer for the user to continue speaking.
    ///   This can be useful for more natural conversations, but may have a higher latency.
    /// </para>
    /// </remarks>
    function TurnDetection(const Value: TTurnDetectionParams): TAudioInputParams;

    class function New: TAudioInputParams;
  end;

  TAudioOutputParams = class(TJSONParam)
    /// <summary>
    ///   The format of the output audio.
    /// </summary>
    function Format(const Value: TAudioFormatParams): TAudioOutputParams;

    /// <summary>
    ///   The speed of the model's spoken response as a multiple of the original speed. 1.0 is the default
    ///   speed. 0.25 is the minimum speed. 1.5 is the maximum speed. This value can only be changed in
    ///   between model turns, not while a response is in progress.
    /// </summary>
    /// <remarks>
    ///   This parameter is a post-processing adjustment to the audio after it is generated, it's also
    ///   possible to prompt the model to speak faster or slower.
    /// </remarks>
    function Speed(const Value: Double = 1.0): TAudioOutputParams;

    /// <summary>
    ///   The voice the model uses to respond. Voice cannot be changed during the session once the model
    ///   has responded with audio at least once.
    /// </summary>
    /// <remarks>
    ///   Current voice options are alloy, ash, ballad, coral, echo, sage, shimmer, verse, marin, and
    ///   cedar. We recommend marin and cedar for best quality.
    /// </remarks>
    function Voice(const Value: TVoiceType): TAudioOutputParams;

    class function New: TAudioOutputParams;
  end;

  TAudioParams = class(TJSONParam)
    /// <summary>
    ///   Configuration for input audio.
    /// </summary>
    function Input(const Value: TAudioInputParams): TAudioParams;

    /// <summary>
    ///   Configuration for output audio.
    /// </summary>
    function Output(const Value: TAudioOutputParams): TAudioParams;

    class function New: TAudioParams;
  end;

  TPromptParams = class(TJSONParam)
    /// <summary>
    ///   The unique identifier of the prompt template to use.
    /// </summary>
    function Id(const Value: string): TPromptParams;

    /// <summary>
    ///   Optional map of values to substitute in for variables in your prompt. The substitution values
    ///   can either be strings, or other Response input types like images or files.
    /// </summary>
    function Variables(const Value: TJSONObject): TPromptParams;

    /// <summary>
    ///   Optional version of the prompt template.
    /// </summary>
    function Version(const Value: string): TPromptParams;

    class function New(const Id: string): TPromptParams;
  end;

  TToolChoiceParams = class(TJSONParam);

  TFunctionToolParams = class(TToolChoiceParams)
    /// <summary>
    ///   The name of the function to call.
    /// </summary>
    function Name(const Value: string): TFunctionToolParams;

    /// <summary>
    ///   For function calling, the type is always function.
    /// </summary>
    function &Type(const Value: string = 'function'): TFunctionToolParams;

    class function New(const Name: string): TFunctionToolParams;
  end;

  TMCPToolParams = class(TToolChoiceParams)
    /// <summary>
    ///   The name of the tool to call on the server.
    /// </summary>
    function Name(const Value: string): TMCPToolParams;

    /// <summary>
    ///   For MCP tools, the type is always mcp.
    /// </summary>
    function &Type(const Value: string = 'mcp'): TMCPToolParams;

    /// <summary>
    ///   The label of the MCP server to use.
    /// </summary>
    function ServerLabel(const Value: string): TMCPToolParams;

    class function New(const ServerLabel: string): TMCPToolParams;
  end;

  TToolsParams = class(TJSONParam);

  TFunctionParams = class(TToolsParams)
    /// <summary>
    ///   The description of the function, including guidance on when and how to call it, and guidance
    ///   about what to tell the user when calling (if anything).
    /// </summary>
    function Description(const Value: string): TFunctionParams;

    /// <summary>
    ///   The name of the function.
    /// </summary>
    function Name(const Value: string): TFunctionParams;

    /// <summary>
    ///   Parameters of the function in JSON Schema.
    /// </summary>
    function Parameters(const Value: TJSONObject): TFunctionParams;

    /// <summary>
    ///   The type of the tool, i.e. function.
    /// </summary>
    function &Type(const Value: string = 'function'): TFunctionParams;

    class function New: TFunctionParams;
  end;

  TAllowedToolsParams = class(TJSONParam)
    /// <summary>
    ///   Indicates whether or not a tool modifies data or is read-only. If an MCP server is
    ///   annotated with read OnlyHint , it will match this filter.
    /// </summary>
    function ReadOnly(const Value: Boolean): TAllowedToolsParams;

    /// <summary>
    ///   List of allowed tool names.
    /// </summary>
    function ToolNames(const Value: TArray<string>): TAllowedToolsParams;
  end;

  TAlwaysOrNeverParams = class(TJSONParam)
    function ReadOnly(const Value: Boolean): TAlwaysOrNeverParams;
    function ToolNames(const Value: TArray<string>): TAlwaysOrNeverParams;
  end;

  TRequireApprovalParams = class(TJSONParam)
    /// <summary>
    ///   Specify which of the MCP server's tools require approval. Can be always, never, or a filter
    ///   object associated with tools that require approval.
    /// </summary>
    function Always(const Value: TAlwaysOrNeverParams): TRequireApprovalParams;

    /// <summary>
    ///   Specify a single approval policy for all tools. One of always or never. When set to always,
    ///   all tools will require approval. When set to never, all tools will not require approval.
    /// </summary>
    function Never(const Value: TAlwaysOrNeverParams): TRequireApprovalParams;
  end;

  TMCPParams = class(TToolsParams)
    /// <summary>
    ///   A label for this MCP server, used to identify it in tool calls.
    /// </summary>
    function ServerLabel(const Value: string): TMCPParams;

    /// <summary>
    ///   The type of the MCP tool. Always mcp.
    /// </summary>
    function &Type(const Value: string = 'mcp'): TMCPParams;

    /// <summary>
    ///   List of allowed tool names or a filter object.
    /// </summary>
    function AllowedTools(const Value: TArray<string>): TMCPParams; overload;

    /// <summary>
    ///   List of allowed tool names or a filter object.
    /// </summary>
    function AllowedTools(const Value: TAllowedToolsParams): TMCPParams; overload;

    /// <summary>
    ///   An OAuth access token that can be used with a remote MCP server, either with a custom MCP
    ///   server URL or a service connector. Your application must handle the OAuth authorization flow
    ///   and provide the token here.
    /// </summary>
    function Authorization(const Value: string): TMCPParams;

    /// <summary>
    ///   Identifier for service connectors, like those available in ChatGPT. One of server_url or
    ///   connector_id must be provided. Learn more about service connectors here.
    /// </summary>
    /// <remarks>
    ///   Currently supported connector_id values are:
    /// <para>
    ///   - Dropbox: connector_dropbox
    /// </para>
    /// <para>
    ///   - Gmail: connector_gmail
    /// </para>
    /// <para>
    ///   - Google Calendar: connector_googlecalendar
    /// </para>
    /// <para>
    ///   - Google Drive: connector_googledrive
    /// </para>
    /// <para>
    ///   - Microsoft Teams: connector_microsoftteams
    /// </para>
    /// <para>
    ///   - Outlook Calendar: connector_outlookcalendar
    /// </para>
    /// <para>
    ///   - Outlook Email: connector_outlookemail
    /// </para>
    /// <para>
    ///   - SharePoint: connector_sharepoint
    /// </para>
    /// </remarks>
    function ConnectorId(const Value: TConnectorType): TMCPParams;

    /// <summary>
    ///   Optional HTTP headers to send to the MCP server. Use for authentication or other purposes.
    /// </summary>
    function Headers(const Value: TJSONObject): TMCPParams;

    /// <summary>
    ///   Specify which of the MCP server's tools require approval.
    /// </summary>
    function RequireApproval(const Value: string = 'always'): TMCPParams; overload;

    /// <summary>
    ///   Specify which of the MCP server's tools require approval.
    /// </summary>
    function RequireApproval(const Value: TRequireApprovalParams): TMCPParams; overload;

    /// <summary>
    ///   Optional description of the MCP server, used to provide more context.
    /// </summary>
    function ServerDescription(const Value: string): TMCPParams;

    /// <summary>
    ///   The URL for the MCP server. One of server_url or connector_id must be provided.
    /// </summary>
    function ServerUrl(const Value: string): TMCPParams;

    class function New(const ServerLabel: string): TMCPParams;
  end;

  TTracingParams = class(TJSONParam)
    /// <summary>
    ///   The group id to attach to this trace to enable filtering and grouping in the Traces Dashboard.
    /// </summary>
    function GroupId(const Value: string): TTracingParams;

    /// <summary>
    ///   The arbitrary metadata to attach to this trace to enable filtering in the Traces Dashboard.
    /// </summary>
    function Metadata(const Value: TJSONObject): TTracingParams;

    /// <summary>
    ///   The name of the workflow to attach to this trace. This is used to name the trace in the Traces
    ///   Dashboard.
    /// </summary>
    function WorkflowName(const Value: string): TTracingParams;

    class function New: TTracingParams;
  end;

  TTruncationParams = class(TJSONParam)
    /// <summary>
    ///   Fraction of post-instruction conversation tokens to retain (0.0 - 1.0) when the conversation
    ///   exceeds the input token limit.
    /// </summary>
    function RetentionRatio(const Value: Double): TTruncationParams;

    /// <summary>
    ///   Use retention ratio truncation.
    /// </summary>
    function &Type(const Value: string): TTruncationParams;

    class function New: TTruncationParams;
  end;

  TSessionParams = class(TJSONParam)
    function &Type(const Value: string): TSessionParams;
    /// <summary>
    ///   Configuration for input and output audio.
    /// </summary>
    function Audio(const Value: TAudioParams): TSessionParams;

    /// <summary>
    ///   Additional fields to include in server outputs. item.input_audio_transcription.
    ///   logprobs: Include logprobs for input audio transcription.
    /// </summary>
    function Include(const Value: TArray<string>): TSessionParams;

    /// <summary>
    ///   The default system instructions (i.e. system message) prepended to model calls.
    ///   This field allows the client to guide the model on desired responses.
    /// </summary>
    /// <remarks>
    /// <para>
    ///   - The model can be instructed on response content and format, (e.g. "be extremely succinct",
    ///   "act friendly", "here are examples of good responses") and on audio behavior
    ///   (e.g. "talk quickly", "inject emotion into your voice", "laugh frequently"). The instructions
    ///   are not guaranteed to be followed by the model, but they provide guidance to the model on the
    ///   desired behavior.
    /// </para>
    /// <para>
    ///   - Note that the server sets default instructions which will be used if this field is not set
    ///   and are visible in the session.created event at the start of the session.
    /// </para>
    /// </remarks>
    function Instructions(const Value: string): TSessionParams;

    /// <summary>
    ///   Maximum number of output tokens for a single assistant response, inclusive of tool calls.
    /// </summary>
    /// <remarks>
    ///   Provide an integer between 1 and 4096 to limit output tokens, or inf for the maximum available
    ///   tokens for a given model. Defaults to inf.
    /// </remarks>
    function MaxOutputTokens(const Value: Integer): TSessionParams;

    /// <summary>
    ///   The Realtime model used for this session.
    /// </summary>
    function Model(const Value: string): TSessionParams;

    /// <summary>
    ///   The set of modalities the model can respond with. It defaults to ["audio"], indicating that the
    ///   model will respond with audio plus a transcript. ["text"] can be used to make the model respond
    ///   with text only. It is not possible to request both text and audio at the same time.
    /// </summary>
    function OutputModalities(const Value: TArray<string>): TSessionParams;

    /// <summary>
    ///   Reference to a prompt template and its variables.
    /// </summary>
    function Prompt(const Value: TPromptParams): TSessionParams;

    /// <summary>
    ///   How the model chooses tools. Provide one of the string modes or force a specific function/MCP
    ///   tool.
    /// </summary>
    function ToolChoice(const Value: TToolChoiceParams): TSessionParams; overload;

    /// <summary>
    ///   How the model chooses tools. Provide one of the string modes or force a specific function/MCP
    ///   tool.
    /// </summary>
    function ToolChoice(const Value: string): TSessionParams; overload;

    /// <summary>
    ///   How the model chooses tools. Provide one of the string modes or force a specific function/MCP
    ///   tool.
    /// </summary>
    function ToolChoice(const Value: TToolChoiceType): TSessionParams; overload;

    /// <summary>
    ///   Tools available to the model.
    /// </summary>
    function Tools(const Value: TArray<TToolsParams>): TSessionParams;

    /// <summary>
    ///   Realtime API can write session traces to the Traces Dashboard. Set to null to disable tracing.
    ///   Once tracing is enabled for a session, the configuration cannot be modified. auto will create
    ///   a trace for the session with default values for the workflow name, group id, and metadata.
    /// </summary>
    function Tracing(const Value: TTracingParams): TSessionParams;

    /// <summary>
    ///   Controls how the realtime conversation is truncated prior to model inference. The default is
    ///   auto.
    /// </summary>
    function Truncation(const Value: string): TSessionParams; overload;

    /// <summary>
    ///   Controls how the realtime conversation is truncated prior to model inference. The default is
    ///   auto.
    /// </summary>
    function Truncation(const Value: TTruncationParams): TSessionParams; overload;

    class function NewSession: TSessionParams;
    class function NewTranscription: TSessionParams;
  end;

  TExpiresAfterParams = class(TJSONParam)
    /// <summary>
    ///   The anchor point for the client secret expiration, meaning that seconds will be added to the
    ///   created_at time of the client secret to produce an expiration timestamp. Only created_at is
    ///   currently supported.
    /// </summary>
    function Anchor(const Value: string): TExpiresAfterParams;

    /// <summary>
    ///   The number of seconds from the anchor point to the expiration. Select a value between 10 and
    ///   7200 (2 hours). This default to 600 seconds (10 minutes) if not specified.
    /// </summary>
    function Seconds(const Value: Integer = 600): TExpiresAfterParams;
  end;

  {$ENDREGION}

  {$REGION 'Response create -> response'}

  TResponseAudioParams = class(TJSONParam)
    function Output(const Value: TAudioOutputParams): TResponseAudioParams;
  end;

  TInputParams = class(TJSONParam);

  {$REGION 'TInputParams class inheritance'}

  {$REGION 'Contents'}

  TSystemContent = class(TJSONParam)
    /// <summary>
    ///   The text content.
    /// </summary>
    function Text(const Value: string): TSystemContent;

    /// <summary>
    ///   The content type. Always input_text for system messages.
    /// </summary>
    function &Type(const Value: string = 'input_text'): TSystemContent;

    class function New(const Text: string): TSystemContent;
  end;

  TUserContent = class(TJSONParam)
    /// <summary>
    ///   Base64-encoded audio bytes (for input_audio), these will be parsed as the format specified
    ///   in the session input audio type configuration. This defaults to PCM 16-bit 24kHz mono if not
    ///   specified.
    /// </summary>
    function Audio(const Value: string): TUserContent;

    /// <summary>
    ///   The detail level of the image (for input_image). auto will default to high.
    /// </summary>
    function Detail(const Value: string = 'auto'): TUserContent;

    /// <summary>
    ///   Base64-encoded image bytes (for input_image) as a data URI. For example
    ///   data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAA.... Supported formats are PNG and JPEG.
    /// </summary>
    function ImageUrl(const Value: string): TUserContent;

    /// <summary>
    ///   The text content (for input_text).
    /// </summary>
    function Text(const Value: string): TUserContent;

    /// <summary>
    ///   Transcript of the audio (for input_audio). This is not sent to the model, but will be
    ///   attached to the message item for reference.
    /// </summary>
    function Transcript(const Value: string): TUserContent;

    /// <summary>
    ///   The content type (input_text, input_audio, or input_image).
    /// </summary>
    function &Type(const Value: TInputType): TUserContent;

    class function New(const AType: TInputType): TUserContent;
  end;

  TAssistantContent = class(TJSONParam)
    /// <summary>
    ///   Base64-encoded audio bytes, these will be parsed as the format specified in the session output
    ///   audio type configuration. This defaults to PCM 16-bit 24kHz mono if not specified.
    /// </summary>
    function Audio(const Value: string): TAssistantContent;

    /// <summary>
    ///   The text content.
    /// </summary>
    function Text(const Value: string): TAssistantContent;

    /// <summary>
    ///   The transcript of the audio content, this will always be present if the output type is audio.
    /// </summary>
    function Transcript(const Value: string): TAssistantContent;

    /// <summary>
    ///   The content type, output_text or output_audio depending on the session output_modalities
    ///   configuration.
    /// </summary>
    function &Type(const Value: TOutputType): TAssistantContent;

    class function New(const AType: TOutputType): TAssistantContent;
  end;

  {$ENDREGION}

  TMCPTool = class(TJSONParam)
    /// <summary>
    ///   The JSON schema describing the tool's input.
    /// </summary>
    function InputSchema(const Value: TSchemaParams): TMCPTool;

    /// <summary>
    ///   The name of the tool.
    /// </summary>
    function Name(const Value: string): TMCPTool;

    /// <summary>
    ///   Additional annotations about the tool.
    /// </summary>
    function Annotations(const Value: TJSONObject): TMCPTool;

    /// <summary>
    ///   The description of the tool.
    /// </summary>
    function Description(const Value: string): TMCPTool;
  end;

  TMCPError = class(TJSONParam)
    function Code(const Value: string): TMCPError;
    function Message(const Value: string): TMCPError;
    function &Type(const Value: string): TMCPError;
  end;

  TSystemMessageParams = class(TInputParams)
    /// <summary>
    ///   The content of the message.
    /// </summary>
    function Content(const Value: TArray<TSystemContent>): TSystemMessageParams; overload;

    /// <summary>
    ///   The content of the message.
    /// </summary>
    function Content(const Value: TArray<string>): TSystemMessageParams; overload;

    /// <summary>
    ///   The role of the message sender. Always system.
    /// </summary>
    function Role(const Value: TRoleType = TRoleType.system): TSystemMessageParams;

    /// <summary>
    ///   The type of the item. Always message.
    /// </summary>
    function &Type(const Value: string = 'message'): TSystemMessageParams;

    /// <summary>
    ///   The unique ID of the item. This may be provided by the client or generated by the server.
    /// </summary>
    function Id(const Value: string): TSystemMessageParams;

    /// <summary>
    ///   Identifier for the API object being returned - always realtime.item. Optional when creating
    ///   a new item.
    /// </summary>
    function &Object(const Value: string = 'realtime.item'): TSystemMessageParams;

    /// <summary>
    ///   The status of the item. Has no effect on the conversation.
    /// </summary>
    function Status(const Value: string): TSystemMessageParams;

    class function New: TSystemMessageParams; overload;
    class function New(const Value: TArray<string>): TSystemMessageParams; overload;
  end;

  TUserMessageParams = class(TInputParams)
    /// <summary>
    ///   The content of the message.
    /// </summary>
    function Content(const Value: TArray<TUserContent>): TUserMessageParams;

    /// <summary>
    ///   The role of the message sender. Always user.
    /// </summary>
    function Role(const Value: TRoleType = TRoleType.user): TUserMessageParams;

    /// <summary>
    ///   The type of the item. Always message.
    /// </summary>
    function &Type(const Value: string = 'message'): TUserMessageParams;

    /// <summary>
    ///   The unique ID of the item. This may be provided by the client or generated by the server.
    /// </summary>
    function Id(const Value: string): TUserMessageParams;

    /// <summary>
    ///   Identifier for the API object being returned - always realtime.item. Optional when creating
    ///   a new item.
    /// </summary>
    function &Object(const Value: string = 'realtime.item'): TUserMessageParams;

    /// <summary>
    ///   The status of the item. Has no effect on the conversation.
    /// </summary>
    function Status(const Value: string): TUserMessageParams;

    class function New: TUserMessageParams;
  end;

  TAssistantMessageParams = class(TInputParams)
    /// <summary>
    ///   The content of the message.
    /// </summary>
    function Content(const Value: TArray<TAssistantContent>): TAssistantMessageParams;

    /// <summary>
    ///   The role of the message sender. Always assistant.
    /// </summary>
    function Role(const Value: TRoleType = TRoleType.assistant): TAssistantMessageParams;

    /// <summary>
    ///   The type of the item. Always message.
    /// </summary>
    function &Type(const Value: string = 'message'): TAssistantMessageParams;

    /// <summary>
    ///   The unique ID of the item. This may be provided by the client or generated by the server.
    /// </summary>
    function Id(const Value: string): TAssistantMessageParams;

    /// <summary>
    ///   Identifier for the API object being returned - always realtime.item. Optional when creating
    ///   a new item.
    /// </summary>
    function &Object(const Value: string = 'realtime.item'): TAssistantMessageParams;

    /// <summary>
    ///   The status of the item. Has no effect on the conversation.
    /// </summary>
    function Status(const Value: string): TAssistantMessageParams;

    class function New: TAssistantMessageParams;
  end;

  TFunctionCallParams = class(TInputParams)
    /// <summary>
    ///   The arguments of the function call. This is a JSON-encoded string representing the arguments
    ///   passed to the function, for example {"arg1": "value1", "arg2": 42}.
    /// </summary>
    function Arguments(const Value: string): TFunctionCallParams;

    /// <summary>
    ///   The name of the function being called.
    /// </summary>
    function Name(const Value: string): TFunctionCallParams;

    /// <summary>
    ///   The type of the item. Always function_call.
    /// </summary>
    function &Type(const Value: string = 'function_call'): TFunctionCallParams;

    /// <summary>
    ///   The ID of the function call.
    /// </summary>
    function CallId(const Value: string): TFunctionCallParams;

    /// <summary>
    ///   The unique ID of the item. This may be provided by the client or generated by the server.
    /// </summary>
    function Id(const Value: string): TFunctionCallParams;

    /// <summary>
    ///   Identifier for the API object being returned - always realtime.item. Optional when creating
    ///   a new item.
    /// </summary>
    function &Object(const Value: string = 'realtime.item'): TFunctionCallParams;

    /// <summary>
    ///   The status of the item. Has no effect on the conversation.
    /// </summary>
    function Status(const Value: string): TFunctionCallParams;

    class function New: TFunctionCallParams;
  end;

  TFunctionCallOutputParams = class(TInputParams)
    /// <summary>
    ///   The ID of the function call this output is for.
    /// </summary>
    function CallId(const Value: string): TFunctionCallOutputParams;

    /// <summary>
    ///   The output of the function call, this is free text and can contain any information or simply
    ///   be empty.
    /// </summary>
    function Output(const Value: string): TFunctionCallOutputParams;

    /// <summary>
    ///   The type of the item. Always function_call_output.
    /// </summary>
    function &Type(const Value: string = 'function_call_output'): TFunctionCallOutputParams;

    /// <summary>
    ///   The unique ID of the item. This may be provided by the client or generated by the server.
    /// </summary>
    function Id(const Value: string): TFunctionCallOutputParams;

    /// <summary>
    ///   Identifier for the API object being returned - always realtime.item. Optional when creating
    ///   a new item.
    /// </summary>
    function &Object(const Value: string = 'realtime.item'): TFunctionCallOutputParams;

    /// <summary>
    ///   The status of the item. Has no effect on the conversation.
    /// </summary>
    function Status(const Value: string): TFunctionCallOutputParams;

    class function New: TFunctionCallOutputParams;
  end;

  TMCPApprovalResponseParams = class(TInputParams)
    /// <summary>
    ///   The ID of the approval request being answered.
    /// </summary>
    function ApprovalRequestId(const Value: string): TMCPApprovalResponseParams;

    /// <summary>
    ///   Whether the request was approved.
    /// </summary>
    function Approve(const Value: Boolean): TMCPApprovalResponseParams;

    /// <summary>
    ///   The unique ID of the approval response.
    /// </summary>
    function Id(const Value: string): TMCPApprovalResponseParams;

    /// <summary>
    ///   The type of the item. Always mcp_approval_response.
    /// </summary>
    function &Type(const Value: string = 'mcp_approval_response'): TMCPApprovalResponseParams;

    /// <summary>
    ///   Optional reason for the decision.
    /// </summary>
    function Reason(const Value: string): TMCPApprovalResponseParams;

    class function New: TMCPApprovalResponseParams;
  end;

  TMCPListToolsParams = class(TInputParams)
    /// <summary>
    ///   The label of the MCP server.
    /// </summary>
    function ServerLabel(const Value: string): TMCPListToolsParams;

    /// <summary>
    ///   The tools available on the server.
    /// </summary>
    function Tools(const Value: TArray<TMCPTool>): TMCPListToolsParams;

    /// <summary>
    ///   The type of the item. Always mcp_list_tools.
    /// </summary>
    function &Type(const Value: string = 'mcp_list_tools'): TMCPListToolsParams;

    /// <summary>
    ///   The unique ID of the list.
    /// </summary>
    function Id(const Value: string): TMCPListToolsParams;

    class function New: TMCPListToolsParams;
  end;

  TMCPToolCall = class(TInputParams)
    /// <summary>
    ///   A JSON string of the arguments passed to the tool.
    /// </summary>
    function Arguments(const Value: string): TMCPToolCall;

    /// <summary>
    ///   The unique ID of the tool call.
    /// </summary>
    function Id(const Value: string): TMCPToolCall;

    /// <summary>
    ///   The name of the tool that was run.
    /// </summary>
    function Name(const Value: string): TMCPToolCall;

    /// <summary>
    ///   The label of the MCP server running the tool.
    /// </summary>
    function ServerLabel(const Value: string): TMCPToolCall;

    /// <summary>
    ///   The type of the item. Always mcp_tool_call.
    /// </summary>
    function &Type(const Value: string = 'mcp_tool_call'): TMCPToolCall;

    /// <summary>
    ///   The ID of an associated approval request, if any.
    /// </summary>
    function ApprovalRequestId(const Value: string): TMCPToolCall;

    /// <summary>
    ///   The error from the tool call, if any.
    /// </summary>
    function Error(const Value: TMCPError): TMCPToolCall;

    /// <summary>
    ///   The output from the tool call.
    /// </summary>
    function Output(const Value: string): TMCPToolCall;

    class function New: TMCPToolCall;
  end;

  TMCPApprovalRequest = class(TInputParams)
    /// <summary>
    ///   A JSON string of arguments for the tool.
    /// </summary>
    function Arguments(const Value: string): TMCPApprovalRequest;

    /// <summary>
    ///   The unique ID of the approval request.
    /// </summary>
    function Id(const Value: string): TMCPApprovalRequest;

    /// <summary>
    ///   The name of the tool to run.
    /// </summary>
    function Name(const Value: string): TMCPApprovalRequest;

    /// <summary>
    ///   The label of the MCP server making the request.
    /// </summary>
    function ServerLabel(const Value: string): TMCPApprovalRequest;

    /// <summary>
    ///   The type of the item. Always mcp_approval_request.
    /// </summary>
    function &Type(const Value: string = 'mcp_approval_request'): TMCPApprovalRequest;

    class function New: TMCPApprovalRequest;
  end;

  {$ENDREGION}

  TResponseParams = class(TJSONParam)
    /// <summary>
    ///   Configuration for audio input and output.
    /// </summary>
    function Audio(const Value: TResponseAudioParams): TResponseParams;

    /// <summary>
    ///   Controls which conversation the response is added to. Currently supports auto and none, with
    ///   auto as the default value.
    /// </summary>
    /// <remarks>
    ///   The auto value means that the contents of the response will be added to the default
    ///   conversation. Set this to none to create an out-of-band response which will not add items to
    ///   default conversation.
    /// </remarks>
    function Conversation(const Value: string): TResponseParams;

    /// <summary>
    ///   Input items to include in the prompt for the model. Using this field creates a new context for
    ///   this Response instead of using the default conversation.
    /// </summary>
    /// <remarks>
    ///   An empty array [] will clear the context for this Response. Note that this can include
    ///   references to items that previously appeared in the session using their id.
    /// </remarks>
    function Input(const Value: TArray<TInputParams>): TResponseParams;

    /// <summary>
    ///   The default system instructions (i.e. system message) prepended to model calls. This field
    ///   allows the client to guide the model on desired responses.
    /// </summary>
    /// <remarks>
    ///   The model can be instructed on response content and format, (e.g. "be extremely succinct",
    ///   "act friendly", "here are examples of good responses") and on audio behavior (e.g. "talk
    ///   quickly", "inject emotion into your voice", "laugh frequently"). The instructions are not
    ///   guaranteed to be followed by the model, but they provide guidance to the model on the desired
    ///   behavior. Note that the server sets default instructions which will be used if this field is
    ///   not set and are visible in the session.created event at the start of the session.
    /// </remarks>
    function Instructions(const Value: string): TResponseParams;

    /// <summary>
    ///   Maximum number of output tokens for a single assistant response, inclusive of tool calls.
    /// </summary>
    /// <remarks>
    ///   Provide an integer between 1 and 4096 to limit output tokens, or inf for the maximum available
    ///   tokens for a given model. Defaults to inf.
    /// </remarks>
    function MaxOutputTokens(const Value: Integer): TResponseParams;

    /// <summary>
    ///   Set of 16 key-value pairs that can be attached to an object. This can be useful for storing
    ///   additional information about the object in a structured format, and querying for objects via
    ///   API or the dashboard.
    /// </summary>
    /// <remarks>
    ///   Keys are strings with a maximum length of 64 characters. Values are strings with a maximum
    ///   length of 512 characters.
    /// </remarks>
    function Metadata(const Value: TJSONObject): TResponseParams;

    /// <summary>
    ///   The set of modalities the model used to respond, currently the only possible values are
    ///   ["audio"], ["text"].
    /// </summary>
    /// <remarks>
    ///   Audio output always include a text transcript. Setting the output to mode text will disable
    ///   audio output from the model.
    /// </remarks>
    function OutputModalities(const Value: TArray<string>): TResponseParams;

    /// <summary>
    ///   Reference to a prompt template and its variables.
    /// </summary>
    function Prompt(const Value: TPromptParams): TResponseParams;

    /// <summary>
    ///   How the model chooses tools. Provide one of the string modes or force a specific function/MCP tool.
    /// </summary>
    function ToolChoice(const Value: TToolChoiceParams): TResponseParams; overload;

    /// <summary>
    ///   How the model chooses tools. Provide one of the string modes or force a specific function/MCP tool.
    /// </summary>
    function ToolChoice(const Value: string): TResponseParams; overload;

    /// <summary>
    ///   How the model chooses tools. Provide one of the string modes or force a specific function/MCP tool.
    /// </summary>
    function ToolChoice(const Value: TToolChoiceType): TResponseParams; overload;

    /// <summary>
    ///   Tools available to the model.
    /// </summary>
    function Tools(const Value: TArray<TToolsParams>): TResponseParams;
  end;

  {$ENDREGION}

implementation

{ TExpiresAfterParams }

function TExpiresAfterParams.Anchor(const Value: string): TExpiresAfterParams;
begin
  Result := TExpiresAfterParams(Add('anchor', Value));
end;

function TExpiresAfterParams.Seconds(const Value: Integer): TExpiresAfterParams;
begin
  Result := TExpiresAfterParams(Add('seconds', EnsureRange(Value, 10, 7200)));
end;

{ TSessionParams }

function TSessionParams.Audio(const Value: TAudioParams): TSessionParams;
begin
  Result := TSessionParams(Add('audio', Value.Detach));
end;

function TSessionParams.Include(const Value: TArray<string>): TSessionParams;
begin
  Result := TSessionParams(Add('include', Value));
end;

function TSessionParams.Instructions(const Value: string): TSessionParams;
begin
  Result := TSessionParams(Add('instructions', Value));
end;

function TSessionParams.MaxOutputTokens(const Value: Integer): TSessionParams;
begin
  Result := TSessionParams(Add('max_output_tokens', EnsureRange(Value, 1, 4096)));
end;

function TSessionParams.Model(const Value: string): TSessionParams;
begin
  Result := TSessionParams(Add('model', Value));
end;

class function TSessionParams.NewSession: TSessionParams;
begin
  Result := TSessionParams.Create.&Type('realtime');
end;

class function TSessionParams.NewTranscription: TSessionParams;
begin
  Result := TSessionParams.Create.&Type('transcription');
end;

function TSessionParams.OutputModalities(const Value: TArray<string>): TSessionParams;
begin
  Result := TSessionParams(Add('output_modalities', Value));
end;

function TSessionParams.Prompt(const Value: TPromptParams): TSessionParams;
begin
  Result := TSessionParams(Add('prompt', Value.Detach));
end;

function TSessionParams.ToolChoice(
  const Value: TToolChoiceParams): TSessionParams;
begin
  Result := TSessionParams(Add('tool_choice', Value.Detach));
end;

function TSessionParams.ToolChoice(const Value: string): TSessionParams;
begin
  Result := TSessionParams(Add('tool_choice', Value));
end;

function TSessionParams.ToolChoice(
  const Value: TToolChoiceType): TSessionParams;
begin
  Result := TSessionParams(Add('tool_choice', Value.ToString));
end;

function TSessionParams.Tools(
  const Value: TArray<TToolsParams>): TSessionParams;
begin
  var JSONArray := TJSONArray.Create;
  for var Item in Value do
    JSONArray.Add(Item.Detach);
  Result := TSessionParams(Add('tools', JSONArray));
end;

function TSessionParams.Tracing(const Value: TTracingParams): TSessionParams;
begin
  Result := TSessionParams(Add('tracing', Value.Detach));
end;

function TSessionParams.Truncation(
  const Value: TTruncationParams): TSessionParams;
begin
  Result := TSessionParams(Add('truncation', Value.Detach));
end;

function TSessionParams.Truncation(const Value: string): TSessionParams;
begin
  Result := TSessionParams(Add('truncation', Value));
end;

function TSessionParams.&Type(const Value: string): TSessionParams;
begin
  Result := TSessionParams(Add('type', Value));
end;

{ TPromptParams }

function TPromptParams.Id(const Value: string): TPromptParams;
begin
  Result := TPromptParams(Add('id', Value));
end;

class function TPromptParams.New(const Id: string): TPromptParams;
begin
  Result := TPromptParams.Create.Id(Id);
end;

function TPromptParams.Variables(const Value: TJSONObject): TPromptParams;
begin
  Result := TPromptParams(Add('variables', Value));
end;

function TPromptParams.Version(const Value: string): TPromptParams;
begin
  Result := TPromptParams(Add('version', Value));
end;

{ TAudioFormatParams }

class function TAudioFormatParams.New(
  const Value: TAudioType): TAudioFormatParams;
begin
  Result := TAudioFormatParams.Create.&Type(Value);
end;

class function TAudioFormatParams.New(const Value: string): TAudioFormatParams;
begin
  Result := TAudioFormatParams.Create.&Type(TAudioType.Parse(Value));
end;

function TAudioFormatParams.Rate(const Value: Integer): TAudioFormatParams;
begin
  Result := TAudioFormatParams(Add('rate', Value));
end;

function TAudioFormatParams.&Type(const Value: TAudioType): TAudioFormatParams;
begin
  Result := TAudioFormatParams(Add('type', Value.ToString));
end;

{ TAudioParams }

function TAudioParams.Input(const Value: TAudioInputParams): TAudioParams;
begin
  Result := TAudioParams(Add('input', Value.Detach));
end;

class function TAudioParams.New: TAudioParams;
begin
  Result := TAudioParams.Create;
end;

function TAudioParams.Output(const Value: TAudioOutputParams): TAudioParams;
begin
  Result := TAudioParams(Add('output', Value.Detach));
end;

{ TAudioInputParams }

function TAudioInputParams.Format(
  const Value: TAudioFormatParams): TAudioInputParams;
begin
  Result := TAudioInputParams(Add('format', Value.Detach));
end;

class function TAudioInputParams.New: TAudioInputParams;
begin
  Result := TAudioInputParams.Create;
end;

function TAudioInputParams.NoiseReduction(
  const Value: TNoiseReduction): TAudioInputParams;
begin
  Result := TAudioInputParams(Add('noise_reduction', Value.Detach));
end;

function TAudioInputParams.Transcription(
  const Value: TTranscriptionParams): TAudioInputParams;
begin
  Result := TAudioInputParams(Add('transcription', Value.Detach));
end;

function TAudioInputParams.TurnDetection(
  const Value: TTurnDetectionParams): TAudioInputParams;
begin
  Result := TAudioInputParams(Add('turn_detection', Value.Detach));
end;

{ TAudioOutputParams }

function TAudioOutputParams.Format(
  const Value: TAudioFormatParams): TAudioOutputParams;
begin
  Result := TAudioOutputParams(Add('format', Value.Detach));
end;

class function TAudioOutputParams.New: TAudioOutputParams;
begin
  Result := TAudioOutputParams.Create;
end;

function TAudioOutputParams.Speed(const Value: Double): TAudioOutputParams;
begin
  Result := TAudioOutputParams(Add('speed', EnsureRange(Value, 0.25, 1.5)));
end;

function TAudioOutputParams.Voice(const Value: TVoiceType): TAudioOutputParams;
begin
  Result := TAudioOutputParams(Add('voice', Value.ToString));
end;

{ TNoiseReduction }

class function TNoiseReduction.New(
  const Value: TNoiseReductionType): TNoiseReduction;
begin
  Result := TNoiseReduction.Create.&Type(Value);
end;

class function TNoiseReduction.New(const Value: string): TNoiseReduction;
begin
  Result := TNoiseReduction.Create.&Type(TNoiseReductionType.Parse(Value));
end;

function TNoiseReduction.&Type(
  const Value: TNoiseReductionType): TNoiseReduction;
begin
  Result := TNoiseReduction(Add('type', Value.ToString));
end;

{ TTranscriptionParams }

function TTranscriptionParams.Language(
  const Value: string): TTranscriptionParams;
begin
  Result := TTranscriptionParams(Add('language', Value));
end;

function TTranscriptionParams.Language(
  const Value: TLanguageCodes): TTranscriptionParams;
begin
  Result := TTranscriptionParams(Add('language', Value.ToString));
end;

function TTranscriptionParams.Model(const Value: string): TTranscriptionParams;
begin
  Result := TTranscriptionParams(Add('model', Value));
end;

class function TTranscriptionParams.New(
  const Model: string): TTranscriptionParams;
begin
  Result := TTranscriptionParams.Create.Model(Model);
end;

function TTranscriptionParams.Prompt(const Value: string): TTranscriptionParams;
begin
  Result := TTranscriptionParams(Add('prompt', Value));
end;

{ TTurnDetectionParams }

function TTurnDetectionParams.&Type(const Value: string): TTurnDetectionParams;
begin
  Result := TTurnDetectionParams(Add('type', Value));
end;

function TTurnDetectionParams.&Type(
  const Value: TTurnDetectionType): TTurnDetectionParams;
begin
  Result := TTurnDetectionParams(Add('type', Value.ToString));
end;

function TTurnDetectionParams.Eagerness(
  const Value: TEagernessType): TTurnDetectionParams;
begin
  Result := TTurnDetectionParams(Add('eagerness', Value.ToString));
end;

function TTurnDetectionParams.CreateResponse(
  const Value: Boolean): TTurnDetectionParams;
begin
  Result := TTurnDetectionParams(Add('create_response', Value));
end;

function TTurnDetectionParams.IdleTimeoutMs(
  const Value: Integer): TTurnDetectionParams;
begin
  Result := TTurnDetectionParams(Add('idle_timeout_ms', Value));
end;

function TTurnDetectionParams.InterruptResponse(
  const Value: Boolean): TTurnDetectionParams;
begin
  Result := TTurnDetectionParams(Add('interrupt_response', Value));
end;

class function TTurnDetectionParams.New(
  const Value: TTurnDetectionType): TTurnDetectionParams;
begin
  Result := TTurnDetectionParams.Create.&Type(Value);
end;

class function TTurnDetectionParams.New(
  const Value: string): TTurnDetectionParams;
begin
  Result := TTurnDetectionParams.Create.&Type(Value);
end;

function TTurnDetectionParams.PrefixPaddingMs(
  const Value: Integer): TTurnDetectionParams;
begin
  Result := TTurnDetectionParams(Add('prefix_padding_ms', Value));
end;

function TTurnDetectionParams.SilenceDurationMs(
  const Value: Integer): TTurnDetectionParams;
begin
  Result := TTurnDetectionParams(Add('silence_duration_ms', Value));
end;

function TTurnDetectionParams.Threshold(
  const Value: Double): TTurnDetectionParams;
begin
  Result := TTurnDetectionParams(Add('threshold', EnsureRange(value, 0.0, 1.0), 7));
end;

{ TTruncationParams }

function TTruncationParams.&Type(const Value: string): TTruncationParams;
begin
  Result := TTruncationParams(Add('type', Value));
end;

class function TTruncationParams.New: TTruncationParams;
begin
  Result := TTruncationParams.Create;
end;

function TTruncationParams.RetentionRatio(
  const Value: Double): TTruncationParams;
begin
  Result := TTruncationParams(Add('retention_ratio', EnsureRange(Value, 0.0, 1.0)));
end;

{ TTracingParams }

function TTracingParams.GroupId(const Value: string): TTracingParams;
begin
  Result := TTracingParams(Add('group_id', Value));
end;

function TTracingParams.Metadata(const Value: TJSONObject): TTracingParams;
begin
  Result := TTracingParams(Add('metadata', Value));
end;

class function TTracingParams.New: TTracingParams;
begin
  Result := TTracingParams.Create;
end;

function TTracingParams.WorkflowName(const Value: string): TTracingParams;
begin
  Result := TTracingParams(Add('workflow_name', Value));
end;

{ TFunctionParams }

function TFunctionParams.&Type(const Value: string): TFunctionParams;
begin
  Result := TFunctionParams(Add('type', Value));
end;

function TFunctionParams.Description(const Value: string): TFunctionParams;
begin
  Result := TFunctionParams(Add('description', Value));
end;

function TFunctionParams.Name(const Value: string): TFunctionParams;
begin
  Result := TFunctionParams(Add('name', Value));
end;

class function TFunctionParams.New: TFunctionParams;
begin
  Result := TFunctionParams.Create.&Type();
end;

function TFunctionParams.Parameters(const Value: TJSONObject): TFunctionParams;
begin
  Result := TFunctionParams(Add('parameters', Value));
end;

{ TMCPParams }

function TMCPParams.AllowedTools(
  const Value: TArray<string>): TMCPParams;
begin
  Result := TMCPParams(Add('allowed_tools', Value));
end;

function TMCPParams.AllowedTools(
  const Value: TAllowedToolsParams): TMCPParams;
begin
  Result := TMCPParams(Add('allowed_tools', Value.Detach));
end;

function TMCPParams.Authorization(const Value: string): TMCPParams;
begin
  Result := TMCPParams(Add('authorization', Value));
end;

function TMCPParams.ConnectorId(
  const Value: TConnectorType): TMCPParams;
begin
  Result := TMCPParams(Add('connector_id', Value.ToString));
end;

function TMCPParams.Headers(const Value: TJSONObject): TMCPParams;
begin
  Result := TMCPParams(Add('headers', Value));
end;

class function TMCPParams.New(const ServerLabel: string): TMCPParams;
begin
  Result := TMCPParams.Create.&Type().ServerLabel(ServerLabel);
end;

function TMCPParams.RequireApproval(
  const Value: TRequireApprovalParams): TMCPParams;
begin
  Result := TMCPParams(Add('require_approval', Value.Detach));
end;

function TMCPParams.RequireApproval(const Value: string): TMCPParams;
begin
  Result := TMCPParams(Add('require_approval', Value));
end;

function TMCPParams.ServerDescription(const Value: string): TMCPParams;
begin
  Result := TMCPParams(Add('server_description', Value));
end;

function TMCPParams.ServerLabel(const Value: string): TMCPParams;
begin
  Result := TMCPParams(Add('server_label', Value));
end;

function TMCPParams.ServerUrl(const Value: string): TMCPParams;
begin
  Result := TMCPParams(Add('server_url', Value));
end;

function TMCPParams.&Type(const Value: string): TMCPParams;
begin
  Result := TMCPParams(Add('type', Value));
end;

{ TAllowedToolsParams }

function TAllowedToolsParams.ReadOnly(
  const Value: Boolean): TAllowedToolsParams;
begin
  Result := TAllowedToolsParams(Add('read_only', Value));
end;

function TAllowedToolsParams.ToolNames(
  const Value: TArray<string>): TAllowedToolsParams;
begin
  Result := TAllowedToolsParams(Add('tool_names', Value));
end;

{ TRequireApprovalParams }

function TRequireApprovalParams.Always(
  const Value: TAlwaysOrNeverParams): TRequireApprovalParams;
begin
  Result := TRequireApprovalParams(Add('always', Value.Detach));
end;

function TRequireApprovalParams.Never(
  const Value: TAlwaysOrNeverParams): TRequireApprovalParams;
begin
  Result := TRequireApprovalParams(Add('never', Value.Detach));
end;

{ TAlwaysOrNeverParams }

function TAlwaysOrNeverParams.ReadOnly(
  const Value: Boolean): TAlwaysOrNeverParams;
begin
  Result := TAlwaysOrNeverParams(Add('read_only', Value));
end;

function TAlwaysOrNeverParams.ToolNames(
  const Value: TArray<string>): TAlwaysOrNeverParams;
begin
  Result := TAlwaysOrNeverParams(Add('tool_names', Value));
end;

{ TFunctionToolParams }

class function TFunctionToolParams.New(const Name: string): TFunctionToolParams;
begin
  Result := TFunctionToolParams.Create.&Type().Name(Name);
end;

function TFunctionToolParams.&Type(const Value: string): TFunctionToolParams;
begin
  Result := TFunctionToolParams(Add('type', Value));
end;

function TFunctionToolParams.Name(const Value: string): TFunctionToolParams;
begin
  Result := TFunctionToolParams(Add('name', Value));
end;

{ TMCPToolParams }

class function TMCPToolParams.New(const ServerLabel: string): TMCPToolParams;
begin
  Result := TMCPToolParams.Create.&Type().ServerLabel(ServerLabel);
end;

function TMCPToolParams.ServerLabel(const Value: string): TMCPToolParams;
begin
  Result := TMCPToolParams(Add('server_label', Value));
end;

function TMCPToolParams.&Type(const Value: string): TMCPToolParams;
begin
  Result := TMCPToolParams(Add('type', Value));
end;

function TMCPToolParams.Name(const Value: string): TMCPToolParams;
begin
  Result := TMCPToolParams(Add('name', Value));
end;

{ TResponseAudioParams }

function TResponseAudioParams.Output(
  const Value: TAudioOutputParams): TResponseAudioParams;
begin
  Result := TResponseAudioParams(Add('output', Value.Detach));
end;

{ TResponseParams }

function TResponseParams.Audio(
  const Value: TResponseAudioParams): TResponseParams;
begin
  Result := TResponseParams(Add('audio', Value.Detach));
end;

function TResponseParams.Conversation(const Value: string): TResponseParams;
begin
  Result := TResponseParams(Add('conversation', Value));
end;

function TResponseParams.Input(
  const Value: TArray<TInputParams>): TResponseParams;
begin
  var JSONArray := TJSONArray.Create;
  for var Item in Value do
    JSONArray.Add(Item.Detach);
  Result := TResponseParams(Add('input', JSONArray));
end;

function TResponseParams.Instructions(const Value: string): TResponseParams;
begin
  Result := TResponseParams(Add('instructions', Value));
end;

function TResponseParams.MaxOutputTokens(const Value: Integer): TResponseParams;
begin
  Result := TResponseParams(Add('max_output_tokens', Value));
end;

function TResponseParams.Metadata(const Value: TJSONObject): TResponseParams;
begin
  Result := TResponseParams(Add('metadata', Value));
end;

function TResponseParams.OutputModalities(
  const Value: TArray<string>): TResponseParams;
begin
  Result := TResponseParams(Add('output_modalities', Value));
end;

function TResponseParams.Prompt(const Value: TPromptParams): TResponseParams;
begin
  Result := TResponseParams(Add('prompt', Value.Detach));
end;

function TResponseParams.ToolChoice(
  const Value: TToolChoiceParams): TResponseParams;
begin
   Result := TResponseParams(Add('tool_choice', Value.Detach));
end;

function TResponseParams.ToolChoice(const Value: string): TResponseParams;
begin
  Result := TResponseParams(Add('tool_choice', Value));
end;

function TResponseParams.ToolChoice(
  const Value: TToolChoiceType): TResponseParams;
begin
  Result := TResponseParams(Add('tool_choice', Value.ToString));
end;

function TResponseParams.Tools(
  const Value: TArray<TToolsParams>): TResponseParams;
begin
  var JSONArray := TJSONArray.Create;
  for var Item in Value do
    JSONArray.Add(Item.Detach);
  Result := TResponseParams(Add('tools', JSONArray));
end;

{ TSystemMessageParams }

function TSystemMessageParams.&Type(const Value: string): TSystemMessageParams;
begin
  Result := TSystemMessageParams(Add('type', Value));
end;

function TSystemMessageParams.&Object(
  const Value: string): TSystemMessageParams;
begin
  Result := TSystemMessageParams(Add('object', Value));
end;

function TSystemMessageParams.Content(
  const Value: TArray<TSystemContent>): TSystemMessageParams;
begin
  var JSONArray := TJSONArray.Create;
  for var Item in Value do
    JSONArray.add(Item.Detach);
  Result := TSystemMessageParams(Add('content', JSONArray));
end;

function TSystemMessageParams.Content(
  const Value: TArray<string>): TSystemMessageParams;
begin
  var JSONArray := TJSONArray.Create;
  for var Item in Value do
    JSONArray.add(TSystemContent.New(Item).Detach);
  Result := TSystemMessageParams(Add('content', JSONArray));
end;

function TSystemMessageParams.Id(const Value: string): TSystemMessageParams;
begin
  Result := TSystemMessageParams(Add('id', Value));
end;

class function TSystemMessageParams.New: TSystemMessageParams;
begin
  Result := TSystemMessageParams.create
    .Role()
    .&Type()
//    .&Object()
end;

class function TSystemMessageParams.New(
  const Value: TArray<string>): TSystemMessageParams;
begin
  Result := New.Content(Value);
end;

function TSystemMessageParams.Role(
  const Value: TRoleType): TSystemMessageParams;
begin
  Result := TSystemMessageParams(Add('role', Value.ToString));
end;

function TSystemMessageParams.Status(const Value: string): TSystemMessageParams;
begin
  Result := TSystemMessageParams(Add('status', Value));
end;

{ TSystemContent }

function TSystemContent.&Type(const Value: string): TSystemContent;
begin
  Result := TSystemContent(Add('type', Value));
end;

class function TSystemContent.New(const Text: string): TSystemContent;
begin
  Result := TSystemContent.Create.&Type().Text(Text);
end;

function TSystemContent.Text(const Value: string): TSystemContent;
begin
  Result := TSystemContent(Add('text', Value));
end;

{ TUserContent }

function TUserContent.Audio(const Value: string): TUserContent;
begin
  Result := TUserContent(Add('audio', Value));
end;

function TUserContent.Detail(const Value: string): TUserContent;
begin
  Result := TUserContent(Add('detail', Value));
end;

function TUserContent.ImageUrl(const Value: string): TUserContent;
begin
  Result := TUserContent(Add('image_url', Value));
end;

class function TUserContent.New(const AType: TInputType): TUserContent;
begin
  Result := TUserContent.Create.&Type(AType);
end;

function TUserContent.Text(const Value: string): TUserContent;
begin
  Result := TUserContent(Add('text', Value));
end;

function TUserContent.Transcript(const Value: string): TUserContent;
begin
  Result := TUserContent(Add('transcript', Value));
end;

function TUserContent.&Type(const Value: TInputType): TUserContent;
begin
  Result := TUserContent(Add('type', Value.ToString));
end;

{ TUserMessageParams }

function TUserMessageParams.&Type(const Value: string): TUserMessageParams;
begin
  Result := TUserMessageParams(Add('type', Value));
end;

function TUserMessageParams.&Object(const Value: string): TUserMessageParams;
begin
  Result := TUserMessageParams(Add('object', Value));
end;

function TUserMessageParams.Content(
  const Value: TArray<TUserContent>): TUserMessageParams;
begin
  var JSONArray := TJSONArray.Create;
  for var Item in Value do
    JSONArray.add(Item.Detach);
  Result := TUserMessageParams(Add('content', JSONArray));
end;

function TUserMessageParams.Id(const Value: string): TUserMessageParams;
begin
  Result := TUserMessageParams(Add('id', Value));
end;

class function TUserMessageParams.New: TUserMessageParams;
begin
  Result := TUserMessageParams.create
    .Role()
    .&Type()
//    .&Object()
end;

function TUserMessageParams.Role(const Value: TRoleType): TUserMessageParams;
begin
  Result := TUserMessageParams(Add('role', Value.ToString));
end;

function TUserMessageParams.Status(const Value: string): TUserMessageParams;
begin
  Result := TUserMessageParams(Add('status', Value));
end;

{ TAssistantContent }

function TAssistantContent.&Type(const Value: TOutputType): TAssistantContent;
begin
  Result := TAssistantContent(Add('type', Value.ToString));
end;

function TAssistantContent.Audio(const Value: string): TAssistantContent;
begin
  Result := TAssistantContent(Add('audio', Value));
end;

class function TAssistantContent.New(
  const AType: TOutputType): TAssistantContent;
begin
  Result := TAssistantContent.Create.&Type(AType);
end;

function TAssistantContent.Text(const Value: string): TAssistantContent;
begin
  Result := TAssistantContent(Add('text', Value));
end;

function TAssistantContent.Transcript(const Value: string): TAssistantContent;
begin
  Result := TAssistantContent(Add('transcript', Value));
end;

{ TAssistantMessageParams }

function TAssistantMessageParams.&Type(
  const Value: string): TAssistantMessageParams;
begin
  Result := TAssistantMessageParams(Add('type', Value));
end;

function TAssistantMessageParams.&Object(
  const Value: string): TAssistantMessageParams;
begin
  Result := TAssistantMessageParams(Add('object', Value));
end;

function TAssistantMessageParams.Content(
  const Value: TArray<TAssistantContent>): TAssistantMessageParams;
begin
  var JSONArray := TJSONArray.Create;
  for var Item in Value do
    JSONArray.add(Item.Detach);
  Result := TAssistantMessageParams(Add('content', JSONArray));
end;

function TAssistantMessageParams.Id(
  const Value: string): TAssistantMessageParams;
begin
  Result := TAssistantMessageParams(Add('id', Value));
end;

class function TAssistantMessageParams.New: TAssistantMessageParams;
begin
  Result := TAssistantMessageParams.create
    .Role()
    .&Type()
//    .&Object()
end;

function TAssistantMessageParams.Role(
  const Value: TRoleType): TAssistantMessageParams;
begin
  Result := TAssistantMessageParams(Add('role', Value.ToString));
end;

function TAssistantMessageParams.Status(
  const Value: string): TAssistantMessageParams;
begin
  Result := TAssistantMessageParams(Add('status', Value));
end;

{ TFunctionCallParams }

function TFunctionCallParams.&Type(const Value: string): TFunctionCallParams;
begin
  Result := TFunctionCallParams(Add('type', Value));
end;

function TFunctionCallParams.&Object(const Value: string): TFunctionCallParams;
begin
  Result := TFunctionCallParams(Add('object', Value));
end;

function TFunctionCallParams.Status(const Value: string): TFunctionCallParams;
begin
  Result := TFunctionCallParams(Add('status', Value));
end;

function TFunctionCallParams.Arguments(
  const Value: string): TFunctionCallParams;
begin
  Result := TFunctionCallParams(Add('arguments', Value));
end;

function TFunctionCallParams.CallId(const Value: string): TFunctionCallParams;
begin
  Result := TFunctionCallParams(Add('call_id', Value));
end;

function TFunctionCallParams.Id(const Value: string): TFunctionCallParams;
begin
  Result := TFunctionCallParams(Add('id', Value));
end;

function TFunctionCallParams.Name(const Value: string): TFunctionCallParams;
begin
  Result := TFunctionCallParams(Add('name', Value));
end;

class function TFunctionCallParams.New: TFunctionCallParams;
begin
  Result := TFunctionCallParams.create
    .&Type()
//    .&Object()
end;

{ TFunctionCallOutputParams }

function TFunctionCallOutputParams.&Type(
  const Value: string): TFunctionCallOutputParams;
begin
  Result := TFunctionCallOutputParams(Add('type', Value));
end;

function TFunctionCallOutputParams.&Object(
  const Value: string): TFunctionCallOutputParams;
begin
  Result := TFunctionCallOutputParams(Add('object', Value));
end;

function TFunctionCallOutputParams.CallId(
  const Value: string): TFunctionCallOutputParams;
begin
  Result := TFunctionCallOutputParams(Add('call_id', Value));
end;

function TFunctionCallOutputParams.Id(
  const Value: string): TFunctionCallOutputParams;
begin
  Result := TFunctionCallOutputParams(Add('id', Value));
end;

class function TFunctionCallOutputParams.New: TFunctionCallOutputParams;
begin
  Result := TFunctionCallOutputParams.create
    .&Type()
//    .&Object()
end;

function TFunctionCallOutputParams.Output(
  const Value: string): TFunctionCallOutputParams;
begin
  Result := TFunctionCallOutputParams(Add('output', Value));
end;

function TFunctionCallOutputParams.Status(
  const Value: string): TFunctionCallOutputParams;
begin
  Result := TFunctionCallOutputParams(Add('status', Value));
end;

{ TMCPApprovalResponseParams }

function TMCPApprovalResponseParams.&Type(
  const Value: string): TMCPApprovalResponseParams;
begin
  Result := TMCPApprovalResponseParams(Add('type', Value));
end;

function TMCPApprovalResponseParams.ApprovalRequestId(
  const Value: string): TMCPApprovalResponseParams;
begin
  Result := TMCPApprovalResponseParams(Add('approval_request_id', Value));
end;

function TMCPApprovalResponseParams.Approve(
  const Value: Boolean): TMCPApprovalResponseParams;
begin
  Result := TMCPApprovalResponseParams(Add('approve', Value));
end;

function TMCPApprovalResponseParams.Id(
  const Value: string): TMCPApprovalResponseParams;
begin
  Result := TMCPApprovalResponseParams(Add('id', Value));
end;

class function TMCPApprovalResponseParams.New: TMCPApprovalResponseParams;
begin
  Result := TMCPApprovalResponseParams.create.&Type();
end;

function TMCPApprovalResponseParams.Reason(
  const Value: string): TMCPApprovalResponseParams;
begin
  Result := TMCPApprovalResponseParams(Add('reason', Value));
end;

{ TMCPListToolsParams }

function TMCPListToolsParams.Tools(
  const Value: TArray<TMCPTool>): TMCPListToolsParams;
begin
  var JSONArray := TJSONArray.Create;
  for var Item in Value do
    JSONArray.Add(Item.Detach);
  Result := TMCPListToolsParams(Add('tools', JSONArray));
end;

function TMCPListToolsParams.&Type(const Value: string): TMCPListToolsParams;
begin
  Result := TMCPListToolsParams(Add('type', Value));
end;

function TMCPListToolsParams.Id(const Value: string): TMCPListToolsParams;
begin
  Result := TMCPListToolsParams(Add('id', Value));
end;

class function TMCPListToolsParams.New: TMCPListToolsParams;
begin
  Result := TMCPListToolsParams.create.&Type();
end;

function TMCPListToolsParams.ServerLabel(
  const Value: string): TMCPListToolsParams;
begin
  Result := TMCPListToolsParams(Add('server_label', Value));
end;

{ TMCPTool }

function TMCPTool.Annotations(const Value: TJSONObject): TMCPTool;
begin
  Result := TMCPTool(Add('annotations', Value));
end;

function TMCPTool.Description(const Value: string): TMCPTool;
begin
  Result := TMCPTool(Add('description', Value));
end;

function TMCPTool.InputSchema(const Value: TSchemaParams): TMCPTool;
begin
  Result := TMCPTool(Add('input_schema', Value.Detach));
end;

function TMCPTool.Name(const Value: string): TMCPTool;
begin
  Result := TMCPTool(Add('name', Value));
end;

{ TMCPToolCall }

function TMCPToolCall.&Type(const Value: string): TMCPToolCall;
begin
  Result := TMCPToolCall(Add('type', Value));
end;

function TMCPToolCall.ApprovalRequestId(const Value: string): TMCPToolCall;
begin
  Result := TMCPToolCall(Add('approval_request_id', Value));
end;

function TMCPToolCall.Arguments(const Value: string): TMCPToolCall;
begin
  Result := TMCPToolCall(Add('arguments', Value));
end;

function TMCPToolCall.Error(const Value: TMCPError): TMCPToolCall;
begin
  Result := TMCPToolCall(Add('error', Value.Detach));
end;

function TMCPToolCall.Id(const Value: string): TMCPToolCall;
begin
  Result := TMCPToolCall(Add('id', Value));
end;

function TMCPToolCall.Name(const Value: string): TMCPToolCall;
begin
  Result := TMCPToolCall(Add('name', Value));
end;

class function TMCPToolCall.New: TMCPToolCall;
begin
  Result := TMCPToolCall.create.&Type();
end;

function TMCPToolCall.Output(const Value: string): TMCPToolCall;
begin
  Result := TMCPToolCall(Add('output', Value));
end;

function TMCPToolCall.ServerLabel(const Value: string): TMCPToolCall;
begin
  Result := TMCPToolCall(Add('server_label', Value));
end;

{ TMCPError }

function TMCPError.&Type(const Value: string): TMCPError;
begin
  Result := TMCPError(Add('type', Value));
end;

function TMCPError.Code(const Value: string): TMCPError;
begin
  Result := TMCPError(Add('code', Value));
end;

function TMCPError.Message(const Value: string): TMCPError;
begin
  Result := TMCPError(Add('message', Value));
end;

{ TMCPApprovalRequest }

function TMCPApprovalRequest.&Type(const Value: string): TMCPApprovalRequest;
begin
  Result := TMCPApprovalRequest(Add('type', Value));
end;

function TMCPApprovalRequest.Arguments(
  const Value: string): TMCPApprovalRequest;
begin
  Result := TMCPApprovalRequest(Add('arguments', Value));
end;

function TMCPApprovalRequest.Id(const Value: string): TMCPApprovalRequest;
begin
  Result := TMCPApprovalRequest(Add('id', Value));
end;

function TMCPApprovalRequest.Name(const Value: string): TMCPApprovalRequest;
begin
  Result := TMCPApprovalRequest(Add('name', Value));
end;

class function TMCPApprovalRequest.New: TMCPApprovalRequest;
begin
  Result := TMCPApprovalRequest.create.&Type();
end;

function TMCPApprovalRequest.ServerLabel(
  const Value: string): TMCPApprovalRequest;
begin
  Result := TMCPApprovalRequest(Add('server_label', Value));
end;

end.
