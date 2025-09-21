unit Edge.Realtime.Control;

interface

uses
  System.Classes, System.SysUtils, System.IOUtils, System.Math,
  System.JSON, System.Threading, System.SyncObjs,
  Vcl.Forms, Vcl.Controls, Vcl.ExtCtrls, Vcl.Edge, Vcl.Dialogs,
  Edge.Audio2, Edge.Audio.Interfaces, Edge.Realtime.Bridge, Edge.Realtime.History,
  Edge.Sessions.FileFinder, Edge.Registry.Helper,
  Realtime, Realtime.Types, Realtime.API.Client, RealTime.Conversation,
  Realtime.Conversation.HistoryExtractor,
  WebRTC.Core;

type
  TAudioNotifyEvent = procedure(Sender: TObject) of object;
  TAudioStringEvent = procedure(Sender: TObject; const Value: string) of object;
  TAudioDoubleEvent = procedure(Sender: TObject; const Value: Double) of object;
  TVolumeChangedEvent = procedure (Sender: TCustomEdgeBrowser; AVolume: Double) of object;

  {$REGION 'Transcription settings'}

  TTranscription = class(TPersistent)
  const
    C_MODEL = 'gpt-4o-mini-transcribe';
  strict private
    FOwner: TComponent;
    FLanguage: TLanguageCodes;
    FModel: string;
    FPrompt: TStrings;
  private
    procedure SetPrompt(const Value: TStrings);
  public
    constructor Create(const AOwner: TComponent);
    destructor Destroy; override;
    procedure Assign(Source: TPersistent); override;
  published
    /// <summary>
    /// Specifies the language code used for input audio transcription.
    /// </summary>
    property Language: TLanguageCodes read FLanguage write FLanguage;

    /// <summary>
    /// Specifies the transcription model to be used for audio processing.
    /// </summary>
    property Model: string read FModel write FModel;

    /// <summary>
    /// Specifies an optional prompt to guide or influence the model’s transcription behavior.
    /// </summary>
    property Prompt: TStrings read FPrompt write SetPrompt;
  end;

  {$ENDREGION}

  {$REGION 'VADParam settings'}

  TVADParamSettings = class(TPersistent)
  const
    C_EXPIRE_AFTER = 600;
    C_MODEL = 'gpt-realtime';
    C_INSTRUCTIONS =
      'You address your counterpart informally due to your long-standing relationship; your delivery is expressive and often punctuated by laughter.';
  strict private
    FOwner: TComponent;
    FCreateResponse: Boolean;
    FExpireAfter: Integer;
    FInstructions: TStrings;
    FInterruptResponse: Boolean;
    FModel: string;
    FNoiseReduction: TNoiseReductionType;
  private
    procedure SetInstructions(const Value: TStrings);
    procedure SetExpireAfter(const Value: Integer);
  public
    constructor Create(const AOwner: TComponent);
    destructor Destroy; override;
    procedure Assign(Source: TPersistent); override;
  published
    /// <summary>
    /// Specifies whether the system should automatically generate a response when a turn is detected.
    /// </summary>
    property Create_response: Boolean read FCreateResponse write FCreateResponse;

    /// <summary>
    /// Specifies the expiration time in seconds for the client secret used to create sessions.
    /// </summary>
    property Expire_after: Integer read FExpireAfter write SetExpireAfter;

    /// <summary>
    /// Specifies the default system instructions provided to the model for guiding responses.
    /// </summary>
    property Instructions: TStrings read FInstructions write SetInstructions;

    /// <summary>
    /// Specifies whether ongoing model responses should be interrupted when new user input is detected.
    /// </summary>
    property Interrupt_response: Boolean read FInterruptResponse write FInterruptResponse;

    /// <summary>
    /// Specifies the name of the model used for realtime processing or transcription.
    /// </summary>
    property Model: string read FModel write FModel;

    /// <summary>
    /// Specifies the type of noise reduction applied to input audio.
    /// </summary>
    property Noise_reduction: TNoiseReductionType read FNoiseReduction write FNoiseReduction;
  end;

  {$ENDREGION}

  {$REGION 'VAD semantic settings'}

  TVADSemanticSettings = class(TPersistent)
  strict private
    FOwner: TComponent;
    FEagerness: TEagernessType;
  public
    constructor Create(const AOwner: TComponent);
    procedure Assign(Source: TPersistent); override;
  published
    /// <summary>
    /// Specifies the eagerness level for semantic VAD turn detection.
    /// </summary>
    property Eagerness: TEagernessType read FEagerness write FEagerness;
  end;

  {$ENDREGION}

  {$REGION 'VAD server settings'}

  TVADServer = class(TPersistent)
  const
    C_PREFIX_PADDING_MS = 300;
    C_SILENCE_DURATION_MS = 500;
    C_THRESHOLD = 0.5;
  strict private
    FOwner: TComponent;
    FIdleTimeoutMs: Integer;
    FPrefixPaddingMs: Integer;
    FSilenceDurationMs: Integer;
    FThreshold: Double;
  private
    procedure SetThreshold(const Value: Double);
  public
    constructor Create(const AOwner: TComponent);
    procedure Assign(Source: TPersistent); override;
  published
    /// <summary>
    /// Specifies the idle timeout in milliseconds before the system automatically triggers a model response.
    /// </summary>
    property Idle_timeout_ms: Integer read FIdleTimeoutMs write FIdleTimeoutMs;

    /// <summary>
    /// Specifies the amount of audio (in milliseconds) to include before detected speech when using VAD.
    /// </summary>
    property Prefix_padding_ms: Integer read FPrefixPaddingMs write FPrefixPaddingMs;

    /// <summary>
    /// Specifies the duration of silence (in milliseconds) required to detect the end of speech.
    /// </summary>
    property Silence_duration_ms: Integer read FSilenceDurationMs write FSilenceDurationMs;

    /// <summary>
    /// Specifies the activation threshold for voice activity detection (VAD).
    /// </summary>
    property Threshold: Double read FThreshold write SetThreshold;
  end;

  {$ENDREGION}

  {$REGION 'Voice settings'}

  TVoiceSettings = class(TPersistent)
  strict private
    FOwner: TComponent;
    FSpeed: Double;
    FVoice: TVoiceType;
    FVolume: Double;
  private
    procedure SetSpeed(const Value: Double);
  public
    constructor Create(const AOwner: TComponent);
    procedure Assign(Source: TPersistent); override;
  published
    /// <summary>
    /// Specifies the playback speed multiplier for the synthesized voice output.
    /// </summary>
    property Speed: Double read FSpeed write SetSpeed;

    /// <summary>
    /// Specifies the voice type used for synthesized speech output.
    /// </summary>
    property Voice: TVoiceType read FVoice write FVoice;

    /// <summary>
    /// Gets or sets the playback volume multiplier for the audio control.
    /// Accepts values from <c>0.0</c> (mute) up to <c>1.0</c> (maximum normal volume),
    /// as well as values greater than <c>1.0</c> to apply additional amplification using
    /// the Web Audio API gain node.
    /// </summary>
    property Volume: Double read FVolume write FVolume;
  end;

  {$ENDREGION}

  {$REGION 'Web settings'}

  TWebSettings = class(TPersistent)
  strict private
    FOwner: TComponent;
    FHtmlIndex: string;
    FPath: string;
  public
    constructor Create(const AOwner: TComponent);
    procedure Assign(Source: TPersistent); override;
  published
    /// <summary>
    /// Gets or sets the main HTML file (index) to be loaded by the embedded browser
    /// for the audio engine web interface.
    /// </summary>
    /// <remarks>
    /// The <c>HtmlIndex</c> property specifies the filename (e.g., <c>realtime.html</c>)
    /// that acts as the entry point for the web assets used by the audio engine. This file
    /// should exist in the directory defined by the <see cref="Path"/> property. If not set,
    /// the default value is <c>realtime.html</c>. Change this value if your web assets
    /// require a different startup HTML file.
    /// </remarks>
    property HtmlIndex: string read FHtmlIndex write FHtmlIndex;

    /// <summary>
    /// Gets or sets the file system or relative path to the web assets used by the embedded audio engine.
    /// Set this property to specify where the control should load its HTML, JavaScript, and other web resources for the audio pipeline.
    /// </summary>
    property Path: string read FPath write FPath;
  end;

  {$ENDREGION}

  {$REGION 'EdgeRealtime settings'}

  TDataChannelNotifyEvent = procedure (DC: IDataChannel) of object;
  TPcNotifyEvent = procedure (S: string) of object;
  TJSONNotifyEvent = procedure (Data: TJSONObject) of object;
  TGetAPIKeyEvent = procedure(out Key: string) of object;

  TRealtimeSettings = class(TPersistent)
  strict private
    FOwner: TComponent;
    FAutoResume: Boolean;
    FCatchExceptions: Boolean;
    FOnGetAPIKey: TGetAPIKeyEvent;
    FTranscription: TTranscription;
    FTurnDetection: TTurnDetectionType;
    FVoiceSettings: TVoiceSettings;
    FVADParamSettings: TVADParamSettings;
    FVADSemanticSettings: TVADSemanticSettings;
    FVADServer: TVADServer;
    FWebSettings: TWebSettings;

  private
    procedure RTGetKey(out Key: string);
    procedure SetVoiceSettings(const Value: TVoiceSettings);
    procedure SetVADParamSettings(const Value: TVADParamSettings);
    procedure SetVADSemanticSettings(const Value: TVADSemanticSettings);
    procedure SetVADServer(const Value: TVADServer);
    procedure SetTranscription(const Value: TTranscription);
    procedure SetWebSettings(const Value: TWebSettings);

  public
    constructor Create(AOwner: TComponent);
    destructor Destroy; override;
    procedure Assign(Source: TPersistent); override;
    property OnGetAPIKey: TGetAPIKeyEvent read FOnGetAPIKey write FOnGetAPIKey;

  published
    /// <summary>
    /// Gets or sets whether the control automatically resumes the previous conversation history
    /// when a new realtime data channel is established.
    /// </summary>
    /// <remarks>
    /// When <c>AutoResume</c> is set to <c>True</c>, the component will attempt to restore the last
    /// session's conversation history (if available) upon connection to a new realtime data channel.
    /// This is useful for creating seamless user experiences in scenarios where conversation context
    /// needs to persist across reconnections or application restarts. If set to <c>False</c>,
    /// each new session will start with an empty conversation history.
    /// </remarks>
    property AutoResume: Boolean read FAutoResume write FAutoResume default False;

    /// <summary>
    /// Enables or disables global exception handling for the audio control.
    /// When set to <c>True</c>, unhandled exceptions occurring within the control or its audio pipeline are automatically caught and displayed using the configured error handler.
    /// When set to <c>False</c>, exceptions will propagate normally, allowing the application to handle them using its default mechanisms.
    /// </summary>
    property CatchExceptions: Boolean read FCatchExceptions write FCatchExceptions;

    /// <summary>
    /// Gets or sets the transcription configuration for the realtime audio session.
    /// </summary>
    /// <remarks>
    /// The <c>Transcription</c> property encapsulates all parameters related to input audio transcription,
    /// including the transcription model, target language, and optional prompts for guiding the
    /// transcription process. This configuration is used when the realtime audio session requires
    /// parallel speech-to-text transcription, such as providing user guidance, enabling captions,
    /// or generating transcripts of spoken input.
    /// </remarks>
    property Transcription: TTranscription read FTranscription write SetTranscription;

    /// <summary>
    /// Gets or sets the mode of turn detection used for realtime voice activity detection (VAD).
    /// </summary>
    /// <remarks>
    /// The <c>TurnDetection</c> property controls how the component determines when a user's turn to speak
    /// has started or ended during a realtime audio session. Supported modes typically include simple
    /// server-side VAD (<c>server_vad</c>), which uses audio volume thresholds to detect speech, and
    /// semantic VAD (<c>semantic_vad</c>), which leverages a model to provide more natural, context-aware
    /// detection of conversation turns. The selected mode influences latency, interruption behavior,
    /// and the naturalness of conversational flow.
    /// </remarks>
    property TurnDetection: TTurnDetectionType read FTurnDetection write FTurnDetection;

    /// <summary>
    /// Gets or sets the parameters used for voice activity detection (VAD) and realtime session control.
    /// </summary>
    /// <remarks>
    /// The <c>VAD_Param</c> property provides advanced configuration for voice activity detection and
    /// session behavior, including response generation, expiration timing, model selection, noise reduction,
    /// conversational instructions, and interruption policies. Adjust these settings to control
    /// how the audio pipeline detects speech, manages conversation flow, handles response interruptions,
    /// and filters input audio. Modifying this property allows for fine-tuning of VAD sensitivity,
    /// conversational style, and real-time interaction fidelity.
    /// </remarks>
    property VAD_Param: TVADParamSettings read FVADParamSettings write SetVADParamSettings;

    /// <summary>
    /// Gets or sets the semantic VAD (Voice Activity Detection) parameters for turn detection.
    /// </summary>
    /// <remarks>
    /// The <c>VAD_Semantic</c> property provides configuration settings for semantic turn detection,
    /// which leverages a language model to determine conversational boundaries more naturally than
    /// basic VAD. This includes options such as <c>Eagerness</c>, which controls how quickly the
    /// model decides the user has finished speaking. Adjust these settings to refine the responsiveness
    /// and naturalness of realtime conversational interactions when using semantic VAD mode.
    /// This property is only relevant when <see cref="TurnDetection"/> is set to <c>semantic_vad</c>.
    /// </remarks>
    property VAD_Semantic: TVADSemanticSettings read FVADSemanticSettings write SetVADSemanticSettings;

    /// <summary>
    /// Gets or sets the server-side VAD (Voice Activity Detection) parameters for turn detection.
    /// </summary>
    /// <remarks>
    /// The <c>VAD_Server</c> property provides detailed configuration for server-based VAD algorithms,
    /// which detect speech boundaries using audio signal characteristics (such as volume thresholds
    /// and silence durations). Parameters include idle timeout, prefix padding, silence duration,
    /// and activation threshold. These settings determine how quickly and accurately the system responds
    /// to user speech in realtime sessions when <see cref="TurnDetection"/> is set to <c>server_vad</c>.
    /// Adjusting these values allows fine control over sensitivity, responsiveness, and handling of
    /// pauses or brief interruptions in the user's speech.
    /// </remarks>
    property VAD_Server: TVADServer read FVADServer write SetVADServer;

    /// <summary>
    /// Gets or sets the voice synthesis parameters for model audio output.
    /// </summary>
    /// <remarks>
    /// The <c>Voice</c> property configures the voice synthesis settings for audio responses
    /// generated by the realtime model. This includes the choice of voice (timbre and style)
    /// and the playback speed. Adjust these settings to customize the auditory personality and
    /// pacing of spoken responses during a realtime session. Available voice options include
    /// multiple high-quality neural voices; the selected voice and speed will apply to all
    /// assistant-generated speech for the session.
    /// </remarks>
    property Voice: TVoiceSettings read FVoiceSettings write SetVoiceSettings;

    /// <summary>
    /// Gets or sets the web asset configuration used by the embedded audio engine.
    /// </summary>
    /// <remarks>
    /// The <c>Web</c> property encapsulates all parameters related to the location
    /// and entry point of the web resources required for the audio pipeline, including
    /// the startup HTML file (<see cref="HtmlIndex"/>) and the directory path (<see cref="Path"/>).
    /// Configure this property to specify where the embedded browser should load its HTML,
    /// JavaScript, and related assets. Adjust these settings if your web assets are stored
    /// in a custom location or require a different entry file.
    /// </remarks>
    property Web: TWebSettings read FWebSettings write SetWebSettings;
  end;

  {$ENDREGION}

  TCustomEdgeRealtimeControl = class;

  TConversationHistory = class
  private
    FOwner: TCustomEdgeRealtimeControl;
    FInjected: Boolean;
    procedure UserItemCreate(const Value: string);
    procedure AssistantItemCreate(const Value: string);
  public
    constructor Create(const AOwner: TCustomEdgeRealtimeControl);

    /// <summary>
    /// Loads and injects conversation history from the specified file.
    /// </summary>
    procedure InjectFromFile(const FileName: string);
  end;

  TCustomEdgeRealtimeControl = class(TCustomPanel)
  const
    HTML_EMPTY = '<html><body style="background: %s; margin:0"></body></html>';
  type
    TShutdownKind = (skRuntime, skFinal);
  private
    FBrowser: TEdgeBrowser;
    FAudio: IEdgeAudio;
    FWire: TEdgeRealtimeWire;
    FRealtime: IRealTime;
    FHistory: TConversationHistory;

    FOnCloseClick: TAudioNotifyEvent;
    FOnCapturePreviewCompleted: TWebViewStatusEvent;
    FOnContainsFullScreenElementChanged: TContainsFullScreenElementChangedEvent;
    FOnMicClick: TAudioStringEvent;
    FOnAudioPlay: TAudioNotifyEvent;
    FOnAudioEnd: TAudioNotifyEvent;
    FOnClose: TNotifyEvent;
    FOnDataChannel: TDataChannelNotifyEvent;
    FOnError: TGetStrProc;
    FOnListen: TJSONNotifyEvent;
    FOnOpen: TNotifyEvent;
    FOnPcState: TPcNotifyEvent;

    FOnPrintCompleted: TPrintCompletedEvent;
    FOnPrintToPDFCompleted: TPrintToPDFCompletedEvent;
    FOnVolumeChanged: TVolumeChangedEvent;
    FOnZoomFactorChanged: TZoomFactorChangedEvent;
    FAudioSettings: TRealtimeSettings;
    FOldExceptionEvent: TExceptionEvent;
    FExceptionHooked: Boolean;
    FSessionLogger: IRealtimeSessionLogger;
    FShuttingDown: Boolean;
    FReady: Boolean;

    procedure ApplyAllRuntime;
    procedure CreateInnerBrowser;
    function GetAudioFormat: TAudioFormatParams;
    function GetExpiresAfterParams: TExpiresAfterParams;
    function GetIsPlaying: Boolean;
    function GetNoiseReduction: TNoiseReduction;
    function GetSession: TSessionParams;
    function GetSessionEventLogger: IRealtimeSessionLogger;
    function GetTranscription:  TTranscriptionParams;
    function GetTurnDetection: TTurnDetectionParams;
    procedure HookEdgeAudioEvents;
    procedure HookInnerBrowserEvents;
    procedure HookWireEvents;
    function IsShuttingDown: Boolean;
    procedure NavigateToEmptyHtml;
    procedure OnErrorDisplay(const Error: string);
    procedure PartialCleaning;
    procedure PartialCleaningOnError(const Error: string);
    function ResolveApiKey(const Rts: TRealtimeSettings): string;
    procedure SafeUnhookAll;
    procedure SetAudioSettings(const Value: TRealtimeSettings);
    procedure ValidateSettings(out Error: string);
  protected
    procedure DoAudioEnd;
    procedure DoAudioPlay;
    procedure DoCloseClick;
    procedure DoMicClick(const S: string);
    procedure DoOnClose;
    procedure DoOnDatachannel(DC: IDataChannel);
    procedure DoOnError(ErrorMessage: string);
    procedure DoOnListen(Data: TJSONObject);
    procedure DoOnPcState(S: string);
    procedure InitializeRuntime;
    procedure InternalShutdown(const Kind: TShutdownKind);
    procedure InvokeUI(const Proc: TProc);
    procedure Loaded; override;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    procedure UnhookBrowserEvents;
    procedure UnhookEdgeBridgeEvents;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Assign(Source: TPersistent); override;

    /// <summary>
    /// Cleanly closes the current connection (WebRTC / Realtime / logger / hooks).
    /// </summary>
    procedure CloseConnection;

    /// <summary>
    /// Closes the realtime audio control, hiding the UI, releasing resources,
    /// disconnecting all active sessions, and resetting the embedded browser state.
    /// </summary>
    /// <remarks>
    /// This method hides the control, terminates any ongoing WebRTC or audio sessions,
    /// navigates the embedded Edge browser to an empty state, and triggers all cleanup
    /// routines necessary to fully shut down the realtime audio engine.
    /// If invoked at design-time, this method exits immediately with no action.
    /// Use <c>Close</c> to perform an orderly shutdown of the realtime control,
    /// releasing audio and browser resources safely for reuse or application exit.
    /// </remarks>
    procedure Close;

    /// <summary>
    /// Displays an error message in the control for the specified duration.
    /// </summary>
    procedure DisplayError(const Value: string; const DurationMs: Integer = 7000);

    /// <summary>
    /// Handles exceptions that occur within the control or its audio pipeline.
    /// </summary>
    procedure DoOnException(Sender: TObject; E: Exception);

    /// <summary>
    /// Disables or turns off the microphone input for the audio session.
    /// </summary>
    procedure MicOff;

    /// <summary>
    /// Enables or turns on the microphone input for the audio session.
    /// </summary>
    procedure MicOn;

    /// <summary>
    /// Toggles the microphone input between enabled and disabled states.
    /// </summary>
    procedure MicToggle;

    /// <summary>
    /// Opens and initializes the realtime audio control, making it visible and ready for realtime interactions.
    /// </summary>
    /// <remarks>
    /// This method creates and configures all underlying components required for a realtime audio session,
    /// including the embedded Edge browser, audio engine, signaling wire, and conversation history handler.
    /// If the control is already initialized or is in design mode, no action is taken.
    /// Upon successful initialization, the <c>OnRTOpen</c> event is triggered.
    /// Use <c>Open</c> to start or restart the realtime audio pipeline and prepare the control for user interaction.
    /// </remarks>
    procedure Open;

    /// <summary>
    /// Reinitializes the realtime audio control, performing a full shutdown and restart of all underlying components.
    /// </summary>
    /// <remarks>
    /// This method cleanly closes the current session—including audio engine, browser, and signaling wire—and then
    /// re-initializes the entire realtime stack. Use <c>Reinitialize</c> to recover from errors, apply major configuration changes,
    /// or restart the control after a previous session has ended. If called at design time, this method exits without action.
    /// </remarks>
    procedure Reinitialize;

    /// <summary>
    /// Sets the OpenAI API key used for authenticating API requests.
    /// </summary>
    procedure SetOpenAIKey(const Value: string);

    /// <summary>
    /// Sets the playback volume for audio output.
    /// </summary>
    procedure SetVolume(const Value: Double);

    /// <summary>
    /// Provides access to the underlying audio interface for low-level audio operations.
    /// </summary>
    property EdgeAudio: IEdgeAudio read FAudio;

    /// <summary>
    /// Provides access to the embedded Edge browser component used for rendering web content.
    /// </summary>
    property EdgeBrowser: TEdgeBrowser read FBrowser;

    /// <summary>
    /// Provides access to the conversation history associated with the current audio session.
    /// </summary>
    property History: TConversationHistory read FHistory;

    /// <summary>
    /// Indicates whether audio playback is currently active.
    /// </summary>
    property IsPlaying: Boolean read GetIsPlaying;

    /// <summary>
    /// Indicates whether the control is fully initialized and ready for realtime audio interactions.
    /// </summary>
    /// <remarks>
    /// The <c>Alive</c> property returns <c>True</c> when the embedded Edge browser, audio engine,
    /// signaling wire, and all session parameters have been successfully initialized and configured.
    /// When <c>Alive</c> is <c>False</c>, the control may not be able to accept user input, transmit audio,
    /// or participate in realtime conversations. Applications should check this property before invoking
    /// realtime actions or accessing dependent interfaces such as <see cref="EdgeAudio"/> or <see cref="Wire"/>.
    /// </remarks>
    property Alive: Boolean read FReady;

    /// <summary>
    /// Provides access to the realtime session interface for managing audio interactions.
    /// </summary>
    property Realtime: IRealtime read FRealtime;

    /// <summary>
    /// Provides access to the realtime signaling and communication wire interface.
    /// </summary>
    property Wire: TEdgeRealtimeWire read FWire;

  published
    property Settings: TRealtimeSettings read FAudioSettings write SetAudioSettings;
    property OnContainsFullScreenElementChanged: TContainsFullScreenElementChangedEvent read FOnContainsFullScreenElementChanged write FOnContainsFullScreenElementChanged;
    property OnCapturePreviewCompleted: TWebViewStatusEvent read FOnCapturePreviewCompleted write FOnCapturePreviewCompleted;
    property OnPrintCompleted: TPrintCompletedEvent read FOnPrintCompleted write FOnPrintCompleted;
    property OnPrintToPDFCompleted: TPrintToPDFCompletedEvent read FOnPrintToPDFCompleted write FOnPrintToPDFCompleted;
    property OnRTAudioEnd: TAudioNotifyEvent read FOnAudioEnd write FOnAudioEnd;
    property OnRTAudioPlay: TAudioNotifyEvent read FOnAudioPlay write FOnAudioPlay;
    property OnRTClose: TNotifyEvent read FOnClose write FOnClose;
    property OnRTCloseClick: TAudioNotifyEvent read FOnCloseClick write FOnCloseClick;
    property OnRTDataChannel: TDataChannelNotifyEvent read FOnDataChannel write FOnDataChannel;
    property OnRTError: TGetStrProc read FOnError write FOnError;
    property OnRTListen: TJSONNotifyEvent read FOnListen write FOnListen;
    property OnRTMicClick: TAudioStringEvent read FOnMicClick write FOnMicClick;
    property OnRTOpen: TNotifyEvent read FOnOpen write FOnOpen;
    property OnRTPcState: TPcNotifyEvent read FOnPcState write FOnPcState;
    property OnRTVolumeChanged: TVolumeChangedEvent read FOnVolumeChanged write FOnVolumeChanged;
    property OnZoomFactorChanged: TZoomFactorChangedEvent read FOnZoomFactorChanged write FOnZoomFactorChanged;
  end;

  TEdgeRealtimeControl = class(TCustomEdgeRealtimeControl)
  published
    property Align;
    property Anchors;
    property BevelOuter default bvNone;
    property BorderWidth;
    property BorderStyle;
    property Caption;
    property Color;
    property Constraints;
    property Ctl3D;
    property DoubleBuffered;
    property DoubleBufferedMode;
    property Enabled;
    property FullRepaint;
    property ParentBackground;
    property ParentColor;
    property ParentCtl3D;
    property ParentDoubleBuffered;

    /// <summary>
    /// Gets or sets the audio engine settings for this control, including voice activity detection (VAD),
    /// talkover and interruption behavior, high-pass filtering, and audio pipeline paths.
    /// Use this property to configure or query all runtime audio parameters in a single object.
    /// </summary>
    property Settings;
    property TabStop;
    property TabOrder;
    property Visible;
    property OnAlignInsertBefore;
    property OnAlignPosition;
    property OnCanResize;

    /// <summary>
    /// Occurs when the capture preview process has finished and the resulting screenshot has been saved.
    /// Use this event to respond after a capture preview completes in the control.
    /// </summary>
    property OnCapturePreviewCompleted;
    property OnConstrainedResize;

    /// <summary>
    /// Occurs when the fullscreen state of an HTML element inside the WebView changes.
    /// Use this event to respond when content enters or exits fullscreen mode.
    /// </summary>
    property OnContainsFullScreenElementChanged;
    property OnEnter;
    property OnExit;

    /// <summary>
    /// Occurs when a print operation has finished in the control.
    /// Use this event to handle post-processing or UI updates after printing completes.
    /// </summary>
    property OnPrintCompleted;

    /// <summary>
    /// Occurs when a print-to-PDF operation has completed in the control.
    /// Use this event to handle actions or updates after a PDF file has been generated.
    /// </summary>
    property OnPrintToPDFCompleted;
    property OnResize;

    /// <summary>
    /// Occurs when audio playback reaches the end within the realtime control.
    /// </summary>
    /// <remarks>
    /// The <c>OnRTAudioEnd</c> event is triggered when the audio engine completes playback of the current audio output,
    /// whether synthesized or streamed. Use this event to update playback status, reset UI elements, or perform actions
    /// that should occur when audio finishes.
    /// </remarks>
    property OnRTAudioEnd;

    /// <summary>
    /// Occurs when audio playback starts or resumes within the realtime control.
    /// </summary>
    /// <remarks>
    /// The <c>OnRTAudioPlay</c> event is triggered whenever the audio engine begins playing synthesized or streamed audio output.
    /// Use this event to update playback indicators, synchronize UI elements, or trigger actions that should occur when audio starts.
    /// </remarks>
    property OnRTAudioPlay;

    /// <summary>
    /// Occurs when the realtime audio session has been closed and all resources have been released.
    /// </summary>
    /// <remarks>
    /// The <c>OnRTClose</c> event is triggered after the control completes a full shutdown of the realtime audio session,
    /// including the disconnection of the audio engine, browser, and signaling wire.
    /// Use this event to handle cleanup tasks, update the user interface, or respond to session termination in your application.
    /// </remarks>
    property OnRTClose;

    /// <summary>
    /// Occurs when the user clicks the close button or initiates a close action in the control.
    /// Use this event to handle cleanup or UI updates when closing.
    /// </summary>
    property OnRTCloseClick;

    /// <summary>
    /// Occurs when a new realtime data channel has been established during the audio session.
    /// </summary>
    /// <remarks>
    /// The <c>OnRTDataChannel</c> event is triggered each time a new WebRTC data channel is created for the realtime session.
    /// Use this event to access the underlying data channel interface, handle custom signaling, or implement low-latency data exchange
    /// alongside audio interactions.
    /// </remarks>
    property OnRTDataChannel;

    /// <summary>
    /// Occurs when a new message or event is received from the realtime audio session.
    /// </summary>
    /// <remarks>
    /// The <c>OnRTListen</c> event is fired whenever the realtime engine delivers a new message, event, or update—
    /// typically in the form of a JSON object representing conversation data, state changes, or model output.
    /// Use this event to process, display, or log realtime responses and events as they occur during the session.
    /// </remarks>
    property OnRTListen;

    /// <summary>
    /// Occurs when the user interacts with the microphone control (e.g., toggles, activates, or deactivates the mic).
    /// Use this event to handle microphone input actions.
    /// </summary>
    property OnRTMicClick;

    /// <summary>
    /// Occurs when the realtime audio control has been successfully opened and initialized.
    /// </summary>
    /// <remarks>
    /// The <c>OnRTOpen</c> event is triggered after all underlying components—such as the audio engine,
    /// embedded Edge browser, and signaling wire—have been fully initialized and the control is ready for interaction.
    /// Use this event to perform custom actions or UI updates in response to the successful startup of the realtime audio session.
    /// </remarks>
    property OnRTOpen;

    /// <summary>
    /// Occurs when the realtime peer connection state changes during the audio session.
    /// </summary>
    /// <remarks>
    /// The <c>OnRTPcState</c> event is triggered whenever the underlying WebRTC or signaling peer connection
    /// transitions to a new state (e.g., connecting, connected, disconnected, or failed).
    /// Use this event to monitor connection health, update status indicators, or implement custom connection management logic.
    /// </remarks>
    property OnRTPcState;

    /// <summary>
    /// Occurs when the audio volume is changed in the control.
    /// Use this event to respond to volume adjustments by the user or application.
    /// </summary>
    property OnRTVolumeChanged;

    /// <summary>
    /// Occurs when the zoom factor of the WebView changes.
    /// Use this event to handle UI updates or scaling when the zoom level is adjusted.
    /// </summary>
    property OnZoomFactorChanged;
  end;

implementation

{$REGION 'Dev note'}

(******************************************************************************
  DEV NOTE – ARCHITECTURE & USAGE OF Edge.Realtime.Control

  This unit defines TEdgeRealtimeControl and related classes, providing a high-level
  VCL component for real-time, low-latency voice interaction powered by OpenAI's
  Realtime API, with full browser embedding and advanced audio pipeline features.

  Architecture Overview:
    - The control embeds a Microsoft Edge (WebView2) browser for running the web-based
      audio engine, handling device access, signal routing, and WebRTC support.
    - Audio input/output and all VAD (Voice Activity Detection) features are managed
      through the IEdgeAudio and IRealtime interfaces, abstracted for plug-and-play use.
    - The component exposes granular configuration objects for transcription, voice,
      semantic and server-side VAD, noise reduction, and conversation logging.
    - Session authentication is handled via ephemeral client secrets; the OpenAI API key
      can be supplied interactively or from environment/registry for ease of deployment.
    - Conversation history is injectable and restorable, supporting seamless user
      experience across reconnects and application restarts.

  Integration & Extension:
    - Settings are fully persistent and assignable at design- or runtime.
    - All low-level audio and conversation signals are available via events and public
      interfaces for custom extension.
    - Error handling and logging can be overridden for robust integration into larger
      systems.

  Best Practices:
    - Always provide a valid OpenAI API key before session start.
    - Use the TurnDetection property to fine-tune VAD behavior (semantic vs. server).
    - Adjust VAD_Param, VAD_Semantic, and VAD_Server for optimal performance
      according to your target environment (e.g., headset vs. conference mic).
    - Persist and restore conversation history as needed using the AutoResume property
      and the History interface.

  For advanced scenarios, refer to the documentation and source code for detailed
  extension points and subclassing guidelines.

******************************************************************************)

{$ENDREGION}

{ TCustomEdgeRealtimeControl }

procedure TCustomEdgeRealtimeControl.ApplyAllRuntime;
begin
  {--- Set the volume value }
  SetVolume(Abs(Settings.Voice.Volume));
end;

procedure TCustomEdgeRealtimeControl.Assign(Source: TPersistent);
begin
  if Source is TCustomEdgeRealtimeControl then
    begin
      Settings.Assign(TCustomEdgeRealtimeControl(Source).Settings);
    end;
  inherited Assign(Source);
end;

procedure TCustomEdgeRealtimeControl.Close;
begin
  if (csDesigning in ComponentState) then Exit;

  Hide;
  if Assigned(FOnClose) then FOnClose(Self);
  NavigateToEmptyHtml;
  CloseConnection;
end;

procedure TCustomEdgeRealtimeControl.CloseConnection;
begin
  if (csDesigning in ComponentState) then Exit;
  try
    InternalShutdown(skRuntime);
  except
    on E: Exception do OnErrorDisplay(E.Message);
  end;
end;

constructor TCustomEdgeRealtimeControl.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  BevelOuter := bvNone;
  ControlStyle := ControlStyle + [csAcceptsControls];
  ParentBackground := False;
  ParentColor := False;
  StyleElements := [seFont, seBorder];
  FAudioSettings := TRealtimeSettings.Create(Self);
  FReady := False;
end;

destructor TCustomEdgeRealtimeControl.Destroy;
{$REGION 'Dev note'}

(*
    It is strongly recommended to thoroughly safeguard all resource cleanup in this destructor,
    especially when running in design-time within the IDE. Avoid assumptions about object states,
    guard all external calls (such as audio interfaces or browser components) with try/except blocks,
    and always check object validity before freeing. Failure to do so can lead to IDE crashes
    or instability when the component is destroyed in the designer. Defensive programming here
    improves both runtime robustness and design-time safety.
*)

{$ENDREGION}
begin
  InternalShutdown(skFinal);
  try
    FreeAndNil(FAudioSettings);
  except
  end;

  inherited;
end;

procedure TCustomEdgeRealtimeControl.UnhookBrowserEvents;
{--- NOTE: We’re making the UnhookBrowserEvents method rock solid (belt and suspenders approach). }
begin
  if not Assigned(FBrowser) then Exit;

  try FBrowser.OnEnter := nil; except end;
  try FBrowser.OnExit := nil; except end;
  try FBrowser.OnCapturePreviewCompleted := nil; except end;
  try FBrowser.OnContainsFullScreenElementChanged := nil; except end;
  try FBrowser.OnPrintCompleted := nil; except end;
  try FBrowser.OnPrintToPDFCompleted := nil; except end;
  try FBrowser.OnZoomFactorChanged := nil; except end;
end;

procedure TCustomEdgeRealtimeControl.UnhookEdgeBridgeEvents;
{--- NOTE: We’re making the UnhookEdgeBridgeEvents method rock solid (belt and suspenders approach). }
begin
  if not Assigned(FBrowser) then Exit;

  try FBrowser.OnCreateWebViewCompleted := nil; except end;
  try FBrowser.OnPermissionRequested    := nil; except end;
  try FBrowser.OnWebMessageReceived     := nil; except end;
  try FBrowser.OnNavigationCompleted    := nil; except end;
end;

procedure TCustomEdgeRealtimeControl.DisplayError(const Value: string;
  const DurationMs: Integer);
begin
  if csDesigning in ComponentState then Exit;

  InvokeUI(
    procedure
    begin
      if Assigned(FAudio) then
        FAudio.DisplayError(Value, DurationMs);
    end);
end;

procedure TCustomEdgeRealtimeControl.NavigateToEmptyHtml;
begin
  var CssColor := Format('#%.2x%.2x%.2x', [
    Color and $FF, (Color shr 8) and $FF, (Color shr 16) and $FF
  ]);
  EdgeBrowser.NavigateToString(Format(HTML_EMPTY, [CssColor]));
end;

procedure TCustomEdgeRealtimeControl.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited;

end;

procedure TCustomEdgeRealtimeControl.OnErrorDisplay(const Error: string);
begin
  FReady := False;
  DisplayError('Realtime init failed: ' + Error);
end;

procedure TCustomEdgeRealtimeControl.Open;
begin
  if (csDesigning in ComponentState) then Exit;

  if Alive then Exit;

  if not Visible then Show;
    InitializeRuntime;

    if Assigned(FOnOpen) then FOnOpen(Self);
end;

procedure TCustomEdgeRealtimeControl.PartialCleaning;
begin
  try
    SafeUnhookAll;
  except
  end;

  FRealtime := nil;
  FWire := nil;
  FAudio := nil;
end;

procedure TCustomEdgeRealtimeControl.PartialCleaningOnError(const Error: string);
begin
  OnErrorDisplay(Error);
  PartialCleaning;
end;

procedure TCustomEdgeRealtimeControl.Reinitialize;
begin
  if (csDesigning in ComponentState) then Exit;

  {--- Cleanly close the previous session (and invalidate callbacks) }
  CloseConnection;

  {--- Restart the runtime stack }
  InitializeRuntime;
end;

function TCustomEdgeRealtimeControl.ResolveApiKey(const Rts: TRealtimeSettings): string;
begin
  Result := EmptyStr;
  if Assigned(Rts.OnGetAPIKey) then
    Rts.OnGetAPIKey(Result);
end;

procedure TCustomEdgeRealtimeControl.CreateInnerBrowser;
begin
  if Assigned(FBrowser) then Exit;

  FBrowser := TEdgeBrowser.Create(Self);
  FBrowser.Parent := Self;
  FBrowser.Align := alClient;
  FBrowser.TabStop := False;
  FBrowser.DoubleBuffered := True;
end;

procedure TCustomEdgeRealtimeControl.HookEdgeAudioEvents;
begin
  if not Assigned(FAudio) then Exit;

  FAudio.AudioPlayProc :=
    procedure
    begin
      if IsShuttingDown then Exit;

      InvokeUI(
        procedure
        begin
          DoAudioPlay;
        end);
    end;

  FAudio.AudioEndProc :=
    procedure
    begin
      if IsShuttingDown then Exit;

      InvokeUI(
        procedure
        begin
          DoAudioEnd;
        end);
    end;

  FAudio.CloseClick :=
    procedure
    begin
      if IsShuttingDown then Exit;

      InvokeUI(
        procedure
        begin
          DoCloseClick;
        end);
    end;

  FAudio.MicClick :=
    procedure(S: string)
    begin
      if IsShuttingDown then Exit;

      InvokeUI(
        procedure
        begin
          DoMicClick(S);
        end);
    end;
end;

procedure TCustomEdgeRealtimeControl.HookInnerBrowserEvents;
begin
  if not Assigned(FBrowser) then Exit;

  FBrowser.OnEnter := Self.OnEnter;
  FBrowser.OnExit := Self.OnExit;
  FBrowser.OnCapturePreviewCompleted := FOnCapturePreviewCompleted;
  FBrowser.OnContainsFullScreenElementChanged := FOnContainsFullScreenElementChanged;
  FBrowser.OnPrintCompleted := FOnPrintCompleted;
  FBrowser.OnPrintToPDFCompleted := FOnPrintToPDFCompleted;
  FBrowser.OnZoomFactorChanged := FOnZoomFactorChanged;
end;

procedure TCustomEdgeRealtimeControl.HookWireEvents;
begin
  if not Assigned(FWire) then Exit;

  FWire.OnClosed :=
    procedure
    begin
      if IsShuttingDown then Exit;

      InvokeUI(
        procedure
        begin
          DoOnClose;
        end);
    end;

  FWire.OnDataChannel :=
    procedure (DC: IDataChannel)
    begin
      if IsShuttingDown then Exit;

      InvokeUI(
        procedure
        begin
          DoOnDatachannel(DC);
        end);
    end;

  FWire.OnError :=
    procedure (Msg: string)
    begin
      if IsShuttingDown then Exit;

      InvokeUI(
        procedure
        begin
          DoOnError(Msg);
        end);
    end;

  FWire.OnOaiEvent :=
    procedure (Data: TJSONObject)
    begin
      if IsShuttingDown then Exit;

      if Assigned(FSessionLogger) then
        try
          FSessionLogger.LogEvent(Data);
        except
        end;

      InvokeUI(
        procedure
        begin
          if Assigned(FOnListen) then FOnListen(Data);
        end);
    end;

  FWire.OnPcState :=
    procedure (S: string)
    begin
      if IsShuttingDown then Exit;

      InvokeUI(
        procedure
        begin
          DoOnPcState(S);
        end);
    end;
end;

procedure TCustomEdgeRealtimeControl.InitializeRuntime;
var
  Error: string;
begin
  if csDesigning in ComponentState then Exit;

  FReady := False;

  try
    {--- Instantiate and embed the internal Edge browser component }
    CreateInnerBrowser;

    {--- Create conversation history handler for this control instance }
    if not Assigned(FHistory) then
      FHistory := TConversationHistory.Create(Self);

    {--- Validation }
    ValidateSettings(Error);

    {--- Solve the key }
    var Key := ResolveApiKey(Settings);

    {--- Create the realtime engine instance with the resolved OpenAI API key }
    FRealtime := TRealTimeFactory.CreateInstance(Key);

    {--- Create the realtime wire/signaling bridge using the embedded browser }
    FWire := TEdgeRealtimeWire.Create(FBrowser);

    {--- Obtain the audio interface from the wire }
    FAudio := FWire.Audio;

    {--- Set the entry point HTML file for the embedded audio engine,
         based on the configured web settings. }
    FAudio.HtmlIndex := Settings.Web.HtmlIndex;

    {--- Connect the wire's send method to the realtime engine }
    FRealtime.SendMethod := FWire.Send;

    {--- Backup the current global exception handler }
    FOldExceptionEvent := Application.OnException;

    {--- Optionally install a custom exception handler if enabled in settings }
    if Settings.CatchExceptions then
      begin
        Application.OnException := DoOnException;
        FExceptionHooked := True;
      end;

    {--- Attach audio-related events to their handlers (for Object Inspector and runtime use) }
    HookEdgeAudioEvents;

    {--- Attach browser UI and navigation events }
    HookInnerBrowserEvents;

    {--- Attach wire (signaling/data) events }
    HookWireEvents;

    {--- Configure the audio engine's web asset path if specified in settings }
    if not Settings.Web.Path.Trim.IsEmpty then
      FAudio.WebPath := Settings.Web.Path;

    {--- Create a realtime client secret with session configuration (for secure authentication) }
    var ClientSecret := FRealtime.ClientSecrets.Create(
      procedure (Params: TClientSecretParams)
      begin
        Params.ExpiresAfter(GetExpiresAfterParams);
        Params.Session(GetSession);
      end);

    try
      {--- Retrieve the ephemeral client secret (used for session initiation) }
      var EphemeralKey := ClientSecret.Value;

      {--- Create and initialize the session event logger (for conversation/session auditing) }
      FSessionLogger := GetSessionEventLogger;
      FSessionLogger.StartSession(Now);

      {--- Boot the signaling wire: supply web path, endpoint URL, and ephemeral key
           Callback applies runtime settings after initialization }
      try
        FWire.Boot(FAudio.WebPath, FRealtime.UrlForCall, EphemeralKey,
            procedure
            begin
              try
                {--- Resume the effective Audio instance post-Boot }
                FAudio := FWire.Audio;

                {--- Rewire ALL Audio callbacks to the correct instance }
                HookEdgeAudioEvents;

                {--- Also rewire the wire, in case Boot replaces internal delegates }
                HookWireEvents;

                ApplyAllRuntime;
              except
                on E: Exception do
                begin
                  PartialCleaningOnError(E.Message);
                end;
              end;
            end);
      except
        on E: Exception do
          begin
            PartialCleaningOnError(E.Message);
          end;
      end;

    finally
      ClientSecret.Free;
    end;
  except
    on E: Exception do
    begin
      PartialCleaningOnError(E.Message);
    end;
  end;

end;

procedure TCustomEdgeRealtimeControl.InternalShutdown(
  const Kind: TShutdownKind);
{--- NOTE: We’re making the InternalShutdown method rock solid (belt and suspenders approach). }
begin
  {--- Invalidates all previous init callbacks }
//  Inc(FInitSeq);

  {--- In final destruction, a real shutdown is reported }
  if Kind = skFinal then
    FShuttingDown := True;

  if Assigned(FRealtime) then
    FRealtime.SendMethod := nil;

  {--- Stop receiving events }
  try SafeUnhookAll; except end;
  UnhookBrowserEvents;
  UnhookEdgeBridgeEvents;

  {--- Stop audio (defensive) }
  try
    if Assigned(FAudio) then
      begin
        try if Assigned(FAudio.Capture) then FAudio.Capture.MicOff; except end;
        try if Assigned(FAudio.Player) then FAudio.Player.Stop; except end;
      end;
  except
  end;

  {--- Close the wire (WebRTC/Signaling) }
  try
    if Assigned(FWire) then FWire.Close;
  except
  end;

  {--- Logger }
  try
    if Assigned(FSessionLogger) then FSessionLogger.StopSession;
  except
  end;
  FSessionLogger := nil;

  {--- Restore exception handler if hooked }
  if FExceptionHooked then
    begin
      try Application.OnException := FOldExceptionEvent; except end;
      FExceptionHooked := False;
    end;

  {--- Releases / nullifications
       - At runtime, we release the wire to avoid leaks and keep the WebView.
       - In the end, the same + we can free up other resources further down in Destroy. }
  try FreeAndNil(FWire); except end;

  FRealtime := nil;
  FAudio := nil;

  if Kind = skFinal then
    begin
      try FreeAndNil(FHistory); except end;
    end;

  FReady := False;
end;

procedure TCustomEdgeRealtimeControl.InvokeUI(const Proc: TProc);
begin
  if TThread.CurrentThread.ThreadID = MainThreadID then
    Proc()
  else
    TThread.Queue(nil,
      procedure
      begin
        Proc();
      end);
end;

function TCustomEdgeRealtimeControl.IsShuttingDown: Boolean;
begin
  Result := FShuttingDown or (csDestroying in ComponentState);
end;

procedure TCustomEdgeRealtimeControl.Loaded;
begin
  inherited;
  InitializeRuntime;
end;

{--- Event Adapters }

procedure TCustomEdgeRealtimeControl.DoAudioEnd;
begin
  if Assigned(FOnAudioEnd) then FOnAudioEnd(Self);
end;

procedure TCustomEdgeRealtimeControl.DoAudioPlay;
begin
  if Assigned(FOnAudioPlay) then FOnAudioPlay(Self);
end;

procedure TCustomEdgeRealtimeControl.DoCloseClick;
begin
  if Assigned(FOnCloseClick) then FOnCloseClick(Self);
end;

procedure TCustomEdgeRealtimeControl.DoMicClick(const S: string);
begin
  if Assigned(FOnMicClick) then FOnMicClick(Self, S);
end;

procedure TCustomEdgeRealtimeControl.DoOnClose;
begin
  SafeUnhookAll;

  if Assigned(FSessionLogger) then
    try
      FSessionLogger.StopSession;
    except
    end;

  FReady := False;
end;

{$HINTS OFF}

procedure TCustomEdgeRealtimeControl.DoOnDatachannel(DC: IDataChannel);
{--- Intentional: DC is unused by design }
begin
  FReady := True;

  SetVolume(Abs(Settings.Voice.Volume));

  if Settings.AutoResume then
    begin
      var Prev := FindPreviousSessionFile('Sessions');
      if (Prev <> '') and FileExists(Prev) then
        History.InjectFromFile(Prev);
    end;

  if Assigned(FOnDataChannel) then FOnDataChannel(FWire.DataChannel);
end;

{$HINTS ON}

procedure TCustomEdgeRealtimeControl.DoOnError(ErrorMessage: string);
begin
  if Assigned(FOnError) then FOnError(ErrorMessage);
end;

procedure TCustomEdgeRealtimeControl.DoOnException(Sender: TObject; E: Exception);
begin
  if Assigned(FAudio) then
    FAudio.DisplayError(E.Message)
  else
    ShowMessage(E.Message);
end;

procedure TCustomEdgeRealtimeControl.DoOnListen(Data: TJSONObject);
begin
  if Assigned(FSessionLogger) then
    try
      FSessionLogger.LogEvent(Data);
    except
    end;

  InvokeUI(procedure
  begin
    if Assigned(FOnListen) then FOnListen(Data);
  end);
end;

procedure TCustomEdgeRealtimeControl.DoOnPcState(S: string);
begin
  if Assigned(FOnPcState) then FOnPcState(S);
end;

{--- Practical public methods }

procedure TCustomEdgeRealtimeControl.MicOn;
begin
  if (csDesigning in ComponentState) then Exit;

  if Assigned(FAudio) and Assigned(FAudio.Capture) then
    FAudio.Capture.MicOn;
end;

procedure TCustomEdgeRealtimeControl.MicOff;
begin
  if (csDesigning in ComponentState) then Exit;

  if Assigned(FAudio) and Assigned(FAudio.Capture) then
    FAudio.Capture.MicOff;
end;

procedure TCustomEdgeRealtimeControl.MicToggle;
begin
  if (csDesigning in ComponentState) then Exit;

  if Assigned(FAudio) and Assigned(FAudio.Capture) then
    FAudio.Capture.MicToggle;
end;

procedure TCustomEdgeRealtimeControl.SafeUnhookAll;
{--- NOTE: We’re making the SafeUnhookAll method rock solid (belt and suspenders approach). }
begin
  if Assigned(FAudio) then
    begin
      try FAudio.AudioPlayProc := nil; except end;
      try FAudio.AudioEndProc := nil; except end;
      try FAudio.CloseClick := nil; except end;
      try FAudio.MicClick := nil; except end;
    end;

  if Assigned(FWire) then
    begin
      try FWire.OnClosed := nil; except end;
      try FWire.OnDataChannel := nil; except end;
      try FWire.OnError := nil; except end;
      try FWire.OnOaiEvent := nil; except end;
      try FWire.OnPcState := nil; except end;
    end;
end;

procedure TCustomEdgeRealtimeControl.ValidateSettings(out Error: string);
begin
  Error := EmptyStr;

  if Settings.Voice.Volume < 0 then
    Settings.Voice.Volume := 0;

  if Settings.Voice.Speed < 0.25 then
    Settings.Voice.Speed := 0.25
  else if Settings.Voice.Speed > 1.5 then
    Settings.Voice.Speed := 1.5;

  if (Settings.VAD_Server.Threshold < 0.0) or (Settings.VAD_Server.Threshold > 1.0) then
    Settings.VAD_Server.Threshold := TVADServer.C_THRESHOLD;

  if Settings.VAD_Server.Silence_duration_ms < 50 then
    Settings.VAD_Server.Silence_duration_ms := TVADServer.C_SILENCE_DURATION_MS;

  if Settings.VAD_Server.Prefix_padding_ms < 0 then
    Settings.VAD_Server.Prefix_padding_ms := TVADServer.C_PREFIX_PADDING_MS;

  if Settings.VAD_Param.Expire_after < 10 then
    Settings.VAD_Param.Expire_after := 10;
end;

procedure TCustomEdgeRealtimeControl.SetAudioSettings(
  const Value: TRealtimeSettings);
begin
  FAudioSettings.Assign(Value);
end;

procedure TCustomEdgeRealtimeControl.SetOpenAIKey(const Value: string);
begin
  if (csDesigning in ComponentState) then Exit;

  SetUserEnvVar('OPENAI_API_KEY', Value.Trim);
end;

procedure TCustomEdgeRealtimeControl.SetVolume(const Value: Double);
begin
  var Volume := EnsureRange(Value, 0.0, 4.0);

  InvokeUI(
    procedure
    begin
      if Assigned(FAudio) and Assigned(FAudio.Player) then
        FAudio.Player.SetVolume(Volume);
      if Assigned(FOnVolumeChanged) then
        FOnVolumeChanged(FBrowser, Volume);
    end);
end;

function TCustomEdgeRealtimeControl.GetAudioFormat: TAudioFormatParams;
begin
  Result := TAudioFormatParams.New('audio/pcm').Rate(24000);
end;

function TCustomEdgeRealtimeControl.GetExpiresAfterParams: TExpiresAfterParams;
begin
  Result := TExpiresAfterParams.Create
    .Seconds(Settings.VAD_Param.Expire_after)
    .Anchor('created_at');
end;

function TCustomEdgeRealtimeControl.GetIsPlaying: Boolean;
begin
  Result := Assigned(FAudio) and Assigned(FAudio.Player) and FAudio.Player.IsPlaying;
end;

function TCustomEdgeRealtimeControl.GetNoiseReduction: TNoiseReduction;
begin
  Result := TNoiseReduction.New(Settings.VAD_Param.Noise_reduction);
end;

function TCustomEdgeRealtimeControl.GetSession: TSessionParams;
begin
  Result := TSessionParams.NewSession
    .Model(Settings.VAD_Param.Model)
    .Audio(
      TAudioParams.Create
        .Input(
          TAudioInputParams.Create
            .Format(GetAudioFormat)
            .NoiseReduction(GetNoiseReduction)
            .Transcription(GetTranscription)
            .TurnDetection(GetTurnDetection) )
        .Output(
          TAudioOutputParams.Create
            .Voice(Settings.Voice.Voice)
            .Speed(Settings.Voice.Speed) ))
    .OutputModalities(['audio']);

  if not Settings.VAD_Param.Instructions.Text.Trim.IsEmpty then
    Result.Instructions(Settings.VAD_Param.Instructions.Text);
end;

function TCustomEdgeRealtimeControl.GetSessionEventLogger: IRealtimeSessionLogger;
begin
  Result := TSessionEventLogger.Create(
    TPath.Combine(TPath.GetDirectoryName(ParamStr(0)), 'Sessions'),
    100,    // flush every
    16384,  // queue capacity
    0,      // push timeout: non-blocking producer
    250     // pop timeout: reactive shutdown
  );
end;

function TCustomEdgeRealtimeControl.GetTranscription: TTranscriptionParams;
begin
  Result := TTranscriptionParams.New(Settings.Transcription.Model);

  if Settings.Transcription.Language <> TLanguageCodes.none then
    Result.Language(Settings.Transcription.Language);

  if not Settings.Transcription.Prompt.Text.Trim.IsEmpty then
    Result.Prompt(Settings.Transcription.Prompt.Text);
end;

function TCustomEdgeRealtimeControl.GetTurnDetection: TTurnDetectionParams;
begin
  if Settings.TurnDetection = semantic_vad then
    begin
      Result := TTurnDetectionParams.New(Settings.TurnDetection)
        .CreateResponse(Settings.VAD_Param.Create_response)
        .InterruptResponse(Settings.VAD_Param.Interrupt_response)
        .Eagerness(Settings.VAD_Semantic.Eagerness);
    end
  else
    begin
      Result := TTurnDetectionParams.New(Settings.TurnDetection)
        .CreateResponse(Settings.VAD_Param.Create_response)
        .InterruptResponse(Settings.VAD_Param.Interrupt_response)
        .PrefixPaddingMs(Settings.VAD_Server.Prefix_padding_ms)
        .SilenceDurationMs(Settings.VAD_Server.Silence_duration_ms)
        .Threshold(Settings.VAD_Server.Threshold);

      if Settings.VAD_Server.Idle_timeout_ms > 10 then
        Result.IdleTimeoutMs(Settings.VAD_Server.Idle_timeout_ms);
    end;
end;

{ TRealtimeSettings }

procedure TRealtimeSettings.Assign(Source: TPersistent);
begin
  if Source is TRealtimeSettings then
    with Source as TRealtimeSettings do
      begin
        FAutoResume := TRealtimeSettings(Source).FAutoResume;
        FCatchExceptions := TRealtimeSettings(Source).FCatchExceptions;
        Transcription.Assign(TRealtimeSettings(Source).Transcription);
        VAD_Param.Assign(TRealtimeSettings(Source).VAD_Param);
        VAD_Semantic.Assign(TRealtimeSettings(Source).VAD_Semantic);
        VAD_Server.Assign(TRealtimeSettings(Source).VAD_Server);
        Voice.Assign(TRealtimeSettings(Source).Voice);
        FTurnDetection := TRealtimeSettings(Source).FTurnDetection;
        Web.Assign(TRealtimeSettings(Source).Web);
      end;
end;

constructor TRealtimeSettings.Create(AOwner: TComponent);
begin
  inherited Create;
  FOwner := AOwner;
  FCatchExceptions := True;
  FTranscription := TTranscription.Create(FOwner);
  FVADParamSettings := TVADParamSettings.Create(FOwner);
  FVADSemanticSettings := TVADSemanticSettings.Create(FOwner);
  FVADServer := TVADServer.Create(FOwner);
  FVoiceSettings := TVoiceSettings.Create(FOwner);
  FWebSettings := TWebSettings.Create(FOwner);
  FTurnDetection := semantic_vad;
  OnGetAPIKey := RTGetKey;
end;

destructor TRealtimeSettings.Destroy;
begin
  if Assigned(FTranscription) then FreeAndNil(FTranscription);
  if Assigned(FVADParamSettings) then FreeAndNil(FVADParamSettings);
  if Assigned(FVADSemanticSettings) then FreeAndNil(FVADSemanticSettings);
  if Assigned(FVADServer) then FreeAndNil(FVADServer);
  if Assigned(FVoiceSettings) then FreeAndNil(FVoiceSettings);
  if Assigned(FWebSettings) then FreeAndNil(FWebSettings);
  inherited;
end;

procedure TRealtimeSettings.RTGetKey(out Key: string);
begin
  if (FOwner is TComponent) and (csDesigning in TComponent(FOwner).ComponentState) then
    begin
      Key := EmptyStr;
      Exit;
    end;

  Key := ReadEnvFromRegistry('OPENAI_API_KEY');

  if Key.Trim.IsEmpty then
    repeat
      Key := InputBox('API KEY setter', 'Your OpenAI API KEY', '');
      if Key.Trim.ToLower = 'exit' then
        Application.Terminate;
      SetUserEnvVar('OPENAI_API_KEY', Key);
    until not Key.Trim.IsEmpty;
end;

procedure TRealtimeSettings.SetTranscription(const Value: TTranscription);
begin
  FTranscription.Assign(Value);
end;

procedure TRealtimeSettings.SetVADParamSettings(const Value: TVADParamSettings);
begin
  FVADParamSettings.Assign(Value);
end;

procedure TRealtimeSettings.SetVADSemanticSettings(const Value: TVADSemanticSettings);
begin
  FVADSemanticSettings.Assign(Value);
end;

procedure TRealtimeSettings.SetVADServer(const Value: TVADServer);
begin
  FVADServer.Assign(Value);
end;

procedure TRealtimeSettings.SetVoiceSettings(const Value: TVoiceSettings);
begin
  FVoiceSettings.Assign(Value);
end;

procedure TRealtimeSettings.SetWebSettings(const Value: TWebSettings);
begin
  FWebSettings.Assign(Value);
end;

{ TVoiceSettings }

procedure TVoiceSettings.Assign(Source: TPersistent);
begin
  if Source is TVoiceSettings then
    with Source as TVoiceSettings do
      begin
        FSpeed := TVoiceSettings(Source).FSpeed;
        FVoice := TVoiceSettings(Source).FVoice;
        FVolume := TVoiceSettings(Source).FVolume;
      end;
end;

constructor TVoiceSettings.Create(const AOwner: TComponent);
begin
  inherited Create;
  FOwner := AOwner;
  FSpeed := 1.0;
  FVoice := coral;
  FVolume := 0.8;
end;

procedure TVoiceSettings.SetSpeed(const Value: Double);
begin
  FSpeed := EnsureRange(Value, 0.25, 1.5);
end;

{ TVADParamSettings }

procedure TVADParamSettings.Assign(Source: TPersistent);
begin
  if Source is TVADParamSettings then
    with Source as TVADParamSettings do
      begin
        FCreateResponse := TVADParamSettings(Source).FCreateResponse;
        FExpireAfter := TVADParamSettings(Source).FExpireAfter;
        FInstructions.Assign(TVADParamSettings(Source).FInstructions);
        FInterruptResponse := TVADParamSettings(Source).FInterruptResponse;
        FModel := TVADParamSettings(Source).Model;
        FNoiseReduction := TVADParamSettings(Source).FNoiseReduction;
      end;
end;

constructor TVADParamSettings.Create(const AOwner: TComponent);
begin
  inherited Create;
  FOwner := AOwner;
  FCreateResponse := True;
  FExpireAfter := C_EXPIRE_AFTER;
  FInstructions := TStringList.Create;
  FInstructions.Text := C_INSTRUCTIONS;
  FInterruptResponse := True;
  FModel := C_MODEL;
  FNoiseReduction := far_field;  //Desktop microphone
end;

destructor TVADParamSettings.Destroy;
begin
  FInstructions.Free;
  inherited;
end;

procedure TVADParamSettings.SetExpireAfter(const Value: Integer);
begin
  FExpireAfter := EnsureRange(Value, 10, 7200);
end;

procedure TVADParamSettings.SetInstructions(const Value: TStrings);
begin
  FInstructions.Assign(Value);
end;

{ TVADSemanticSettings }

procedure TVADSemanticSettings.Assign(Source: TPersistent);
begin
  if Source is TVADSemanticSettings then
    with Source as TVADSemanticSettings do
      begin
        FEagerness := TVADSemanticSettings(Source).FEagerness;
      end;
end;

constructor TVADSemanticSettings.Create(const AOwner: TComponent);
begin
  inherited Create;
  FOwner := AOwner;
  FEagerness := TEagernessType.auto;
end;

{ TVADServer }

procedure TVADServer.Assign(Source: TPersistent);
begin
  if Source is TVADServer then
    with Source as TVADServer do
      begin
        FIdleTimeoutMs := TVADServer(Source).FIdleTimeoutMs;
        FPrefixPaddingMs := TVADServer(Source).FPrefixPaddingMs;
        FSilenceDurationMs := TVADServer(Source).FSilenceDurationMs;
        FThreshold := TVADServer(Source).FThreshold;
      end;
end;

constructor TVADServer.Create(const AOwner: TComponent);
begin
  inherited Create;
  FOwner := AOwner;
  FIdleTimeoutMs := 0;
  FPrefixPaddingMs := C_PREFIX_PADDING_MS;
  FSilenceDurationMs := C_SILENCE_DURATION_MS;
  FThreshold := C_THRESHOLD;
end;

procedure TVADServer.SetThreshold(const Value: Double);
begin
  FThreshold := EnsureRange(Value, 0.0, 1.0);
end;

{ TTranscription }

procedure TTranscription.Assign(Source: TPersistent);
begin
  if Source is TTranscription then
    with Source as TTranscription do
      begin
        FLanguage := TTranscription(Source).FLanguage;
        FModel := TTranscription(Source).FModel;
        FPrompt.Assign(TTranscription(Source).FPrompt);
      end
  else
    inherited;
end;

constructor TTranscription.Create(const AOwner: TComponent);
begin
  inherited Create;
  FOwner := AOwner;
  FLanguage := TLanguageCodes.none;
  FModel := C_MODEL;
  FPrompt := TStringList.Create;
end;

destructor TTranscription.Destroy;
begin
  FPrompt.Free;
  inherited;
end;

procedure TTranscription.SetPrompt(const Value: TStrings);
begin
  FPrompt.Assign(Value);
end;

{ TConversationHistory }

procedure TConversationHistory.AssistantItemCreate(const Value: string);
begin
  FOwner.Realtime.Conversation.Create(
    procedure (Params: TConversationItemCreateParams)
    begin
      Params.&Type()
        .Item( TAssistantMessageParams
            .New
            .Content([ TAssistantContent
                .New(TOutputType.output_text)
                .Text(Value)
            ])
        )
    end);
end;

constructor TConversationHistory.Create(const AOwner: TCustomEdgeRealtimeControl);
begin
  inherited Create;
  FOwner := AOwner;
  FInjected := False;
end;

procedure TConversationHistory.InjectFromFile(const FileName: string);
begin
  if not FileExists(FileName) or FInjected then Exit;

  var Extractor := TConversationExtractor.Create;
  try
    var Messages := Extractor.FromFile(FileName);
    FInjected := True;

    for var Item in Messages do
      if Item.Role = 'user' then
        UserItemCreate(Item.Text)
      else
        AssistantItemCreate(Item.Text);
  finally
    Extractor.Free;
  end;
end;

procedure TConversationHistory.UserItemCreate(const Value: string);
begin
  FOwner.Realtime.Conversation.Create(
    procedure (Params: TConversationItemCreateParams)
    begin
      Params.&Type()
        .Item( TUserMessageParams
            .New
            .Content([ TUserContent
                .New(TInputType.input_text)
                .Text(Value)
            ])
        )
    end);
end;

{ TWebSettings }

procedure TWebSettings.Assign(Source: TPersistent);
begin
  if Source is TWebSettings then
    with Source as TWebSettings do
      begin
        FHtmlIndex := TWebSettings(Source).FHtmlIndex;
        FPath := TWebSettings(Source).FPath;
      end;
end;

constructor TWebSettings.Create(const AOwner: TComponent);
begin
  inherited Create;
  FOwner := AOwner;
  FHtmlIndex := 'realtime.html';
  FPath := '..\..\web';
end;

end.

