unit Edge.Audio.Interfaces;

interface

uses
  System.SysUtils, System.JSON, Vcl.Edge;

type
  TAudioEventProc = reference to procedure;
  TAudioStringEventProc = reference to procedure(Value: string);
  TAudioJSONObjectProc = reference to procedure (Data: TJSONObject);

  {$REGION 'Audio capture'}

  IEdgeAudioCapture = interface
    ['{3FF66DB6-2A4E-40E7-9A86-3ED3C4EA3FC5}']

    /// <summary>
    /// Ensures the microphone is turned off for sending captured audio (disables
    /// capture sending) without tearing down the capture engine.
    /// </summary>
    /// <remarks>
    /// This procedure instructs the embedded WebView to set the capture gating to
    /// the "off" state (it invokes the page logic that toggles the microphone
    /// sending flag if it is currently enabled). The call is idempotent — if the
    /// microphone is already off, the request has no effect. When transitioning
    /// from an active sending state the implementation attempts to stop any active
    /// recorder and clears buffered chunks to avoid transmitting partial data.
    /// <para>
    /// • The command is forwarded asynchronously to the WebView via the JavaScript
    /// bridge, and returns immediately. It does not stop or close the underlying
    /// capture stream or audio context; to fully stop capture use the capture
    /// lifecycle methods (for example <c>StartCapture</c>/<c>StopCapture</c>).
    /// </para>
    /// <para>
    /// • Because this operation communicates with the WebView and updates UI-related
    /// state, callers should execute or marshal the call on the UI/main thread when
    /// required by the VCL/Edge runtime. Any resulting UI changes or webview events
    /// (for example microphone icon updates) will be delivered via the normal
    /// WebView message callbacks.
    /// </para>
    /// </remarks>
    procedure MicOff;

    /// <summary>
    /// Ensures the microphone sending is enabled so captured audio segments may be forwarded to the host.
    /// </summary>
    /// <remarks>
    /// This procedure instructs the embedded WebView to clear its capture-gating flag
    /// and enable transmission of recorded audio segments (it invokes the page logic
    /// that toggles the microphone sending flag if it is currently disabled). The
    /// call is idempotent — if the microphone sending is already enabled the request
    /// has no effect.
    /// <para>
    /// • <c>MicOn</c> only controls whether captured audio is forwarded (the "sending"
    /// gate). It does not start the underlying capture engine or create media streams;
    /// to start or stop the actual capture pipeline use <c>StartCapture</c> /
    /// <c>StopCapture</c>. Likewise, this procedure does not change VAD parameters,
    /// recording timeslices, or other capture configuration — it simply restores the
    /// ability to transmit captured segments after a prior block or manual disable.
    /// </para>
    /// <para>
    /// • The command is forwarded asynchronously to the WebView via the JavaScript
    /// bridge, and returns immediately. Because the operation interacts with the
    /// WebView and host UI state, callers should execute or marshal this call on
    /// the UI/main thread when required by the VCL/Edge runtime to avoid threading
    /// issues. Any resulting UI updates (for example mic icon state) or WebView
    /// events will be delivered via the standard message callbacks.
    /// </para>
    /// </remarks>
    procedure MicOn;

    /// <summary>
    /// Toggles the microphone sending state: if capture sending is currently
    /// enabled it will be disabled, and if it is disabled it will be enabled.
    /// </summary>
    /// <remarks>
    /// This procedure sends a toggle command to the embedded WebView (it invokes
    /// the page's <c>toggleMic()</c> logic), and returns immediately. It is a
    /// convenience method that flips the internal <c>blockAudioSend</c> flag and
    /// updates the UI (for example the microphone icon) accordingly. When toggling
    /// from enabled-to-disabled the implementation attempts to stop any active
    /// recorder and clears buffered chunks to avoid transmitting partial data.
    /// <para>
    /// • <c>MicToggle</c> controls only the "sending" gate for captured audio; it
    /// does not start or stop the underlying capture engine or change VAD/timeslice
    /// settings. To manage the capture lifecycle use <c>StartCapture</c> /
    /// <c>StopCapture</c> and to explicitly set a known mic state use
    /// <c>MicOn</c> / <c>MicOff</c>.
    /// </para>
    /// <para>
    /// • The operation is forwarded asynchronously to the WebView via the JavaScript
    /// bridge and should be executed or marshaled on the UI/main thread when
    /// required by the VCL/Edge runtime to avoid threading issues. Any resulting
    /// WebView events or UI updates will be delivered through the standard message
    /// callbacks.
    /// </para>
    /// </remarks>
    procedure MicToggle;

    /// <summary>
    /// Starts microphone capture and the host side voice-activity-detection (VAD)
    /// pipeline used to produce recorded audio segments.
    /// </summary>
    /// <remarks>
    /// <para>
    /// • This procedure requests and configures the browser media stack to begin
    /// capturing audio from the user's microphone. It forwards a command to the
    /// embedded WebView to call <c>navigator.mediaDevices.getUserMedia</c> with
    /// common audio constraints (echo cancellation, noise suppression, auto gain
    /// control), creates an <c>AudioContext</c> and an audio analysis chain
    /// (including a high-pass <c>BiquadFilterNode</c> whose cutoff is initialized
    /// from <c>window.highpassFrequency</c> or any previously requested value),
    /// attaches an <c>AnalyserNode</c> for VAD measurement, and constructs a
    /// <c>MediaRecorder</c> configured to emit <c>audio/webm;codecs=opus</c>
    /// chunks which are buffered and later sent as segments.
    /// </para>
    /// <para>
    /// • The operation is asynchronous and may prompt the user for microphone
    /// permission. Success and failure are reported via WebView messages:
    /// <c>audio_capture_started</c> is emitted when capture begins, and
    /// <c>audio_error</c> is emitted on failure (for example permission denied or
    /// lack of API support). Callers should observe those messages rather than
    /// assuming the capture started synchronously.
    /// </para>
    /// <para>
    /// • Once started, the VAD loop runs on animation frames to detect speech and
    /// will start/stop the recorder based on configured VAD parameters. Recorded
    /// segments are delivered as <c>audio_segment</c> messages (base64 payloads)
    /// to the host when a segment is finalized. Adjust VAD behavior and timeslice
    /// via the VAD parameter interface (<c>VADParams</c>) or by calling the
    /// corresponding setter methods on the capture interface prior to or during
    /// capture.
    /// </para>
    /// <para>
    ///  IMPORTANT considerations:
    /// </para>
    /// <para>
    /// • This call does not block playback — playback and capture may run concurrently
    /// unless the application blocks capture explicitly.
    /// </para>
    /// <para>
    /// • Permissions are required; the host may need to handle or pre-authorize
    /// microphone permission in the WebView.
    /// </para>
    /// <para>
    /// • Browser/platform support for <c>MediaRecorder</c>, <c>captureStream</c>, and
    /// audio codecs varies; failures are reported via <c>audio_error</c>.
    /// </para>
    /// <para>
    /// • The procedure allocates an <c>AudioContext</c> and associated nodes; callers
    /// should call <c>StopCapture</c> to release those resources when capture is
    /// no longer needed.
    /// </para>
    /// <para>
    /// • A previously set pending high-pass frequency (if any) is applied when the
    /// filter is created; use the high-pass filter interface to change the cutoff
    /// at runtime.
    /// </para>
    /// </remarks>
    procedure StartCapture;
  end;

  {$ENDREGION}

  {$REGION 'Audio player'}

  IEdgeAudioPlayer = interface
    ['{A7441D77-9008-4CE8-9F7B-EF689EBB893A}']
    function GetIsPlaying: Boolean;
    procedure SetIsPlaying(const Value: Boolean);

    /// <summary>
    /// Gets a flag that indicates whether the embedded player is currently
    /// playing or streaming a response audio.
    /// </summary>
    /// <remarks>
    /// The value is maintained from playback events emitted by the embedded WebView
    /// (for example <c>audio_play</c>, <c>audio_pause</c>, <c>audio_stream_started</c>,
    /// <c>audio_stream_ended</c>, and <c>audio_ended</c>). It is intended for callers
    /// that need to know whether a response audio is in progress (for example to avoid
    /// initiating capture or processing while playback is active). This property is
    /// observational only and does not control playback — use the <c>Player</c> methods
    /// to start, stop, or control audio. Updates are driven by WebView messages and
    /// may have slight delivery latency, so the value should not be relied upon for
    /// hard real-time synchronization.
    /// </remarks>
    property IsPlaying: Boolean read GetIsPlaying write SetIsPlaying;

    /// <summary>
    /// Sets the playback volume for the embedded audio player. Accepts both
    /// standard volume levels (0.0–1.0) and amplification values greater than 1.0
    /// to apply additional gain via the Web Audio API.
    /// </summary>
    /// <param name="Value">
    /// A linear volume multiplier. Values in the range <c>0.0</c> to <c>1.0</c>
    /// map to the HTMLMediaElement's native <c>volume</c> property (0 = muted,
    /// 1 = full). Values greater than <c>1.0</c> enable an internal Web Audio
    /// <c>GainNode</c> to amplify the output (for example <c>2.0</c> is 2× gain).
    /// Negative values are treated as <c>0.0</c>.
    /// </param>
    /// <remarks>
    /// This procedure forwards the request to the embedded WebView and takes effect
    /// immediately when the web content is ready. For values ≤ <c>1.0</c> the
    /// player simply adjusts the media element's <c>volume</c>. For values
    /// <c>1.0</c> the implementation lazily creates a Web Audio <c>AudioContext</c>
    /// and a <c>GainNode</c> connected to a <c>MediaElementSource</c> to provide
    /// additional amplification beyond the native element volume. When amplification
    /// is used, the media element's own volume is held at <c>1.0</c> and the
    /// effective output level is controlled by the gain node.
    /// Be cautious when using amplification values significantly above <c>1.0</c>,
    /// as this can introduce distortion or clipping and may produce very loud
    /// output depending on the system and output device. Also note that creating
    /// an <c>AudioContext</c> consumes additional resources and that browser or
    /// platform policies may affect audio context lifetimes or autoplay behavior.
    /// This call does not change capture state; if capture gating is required,
    /// adjust capture state separately via the capture interface.
    /// </remarks>
    procedure SetVolume(const Value: Double);

    /// <summary>
    /// Stops playback and resets the player to the start of the current track,
    /// and restores capture sending so microphone capture may resume.
    /// </summary>
    /// <remarks>
    /// This procedure instructs the embedded player to stop playback (it pauses the
    /// media element and seeks the playhead to zero) and then unblocks audio
    /// capture/gating by calling the capture interface's unblock routine. The
    /// implementation forwards the commands to the embedded WebView via the JavaScript
    /// bridge (<c>stopAudio()</c>) and will take effect when the WebView is ready.
    /// Use <c>Stop</c> when you need to immediately cease playback and allow the
    /// microphone/capture pipeline to continue sending captured segments. This
    /// call does not free or destroy the player or capture resources and does not
    /// close the WebView; it only changes playback and capture gating state. Any
    /// playback-related events emitted by the WebView (for example pause/ended)
    /// will be delivered through the usual event callbacks handled by the host.
    /// </remarks>
    procedure Stop;
  end;

  {$ENDREGION}

  {$REGION 'WebRTC'}

  IWebRTC = interface
    ['{BF7B2AAD-F9C2-4869-9C88-D4BA27D3DCED}']
    procedure Send(const Body: string);
  end;

  {$ENDREGION}

  {$REGION 'Events'}

  IEdgeAudioEvent = interface
    function GetCloseClick: TAudioEventProc;
    function GetMicClick: TAudioStringEventProc;
    function GetAudioPlayProc: TAudioEventProc;
    function GetAudioEndProc: TAudioEventProc;

    procedure SetCloseClick(const Value: TAudioEventProc);
    procedure SetMicClick(const Value: TAudioStringEventProc);
    procedure SetAudioPlayProc(const Value: TAudioEventProc);
    procedure SetAudioEndProc(const Value: TAudioEventProc);

    function GetRealtimeJsReady: TAudioEventProc;
    procedure SetRealtimeJsReady(const Value: TAudioEventProc);
    function GetRealtimeConnected: TAudioEventProc;
    procedure SetRealtimeConnected(const Value: TAudioEventProc);
    function GetRealtimeClosed: TAudioEventProc;
    procedure SetRealtimeClosed(const Value: TAudioEventProc);
    function GetRealtimePcState: TAudioStringEventProc;
    procedure SetRealtimePcState(const Value: TAudioStringEventProc);
    function GetRealtimeDataChannelOpen: TAudioEventProc;
    procedure SetRealtimeDataChannelOpen(const Value: TAudioEventProc);
    function GetRealtimeDataChannelClose: TAudioEventProc;
    procedure SetRealtimeDataChannelClose(const Value: TAudioEventProc);
    function GetRealtimeTrackAdded: TAudioEventProc;
    procedure SetRealtimeTrackAdded(const Value: TAudioEventProc);
    function GetRealtimeEvent: TAudioJSONObjectProc;
    procedure SetRealtimeEvent(const Value: TAudioJSONObjectProc);

    function GetOnWebReady: TAudioEventProc;
    procedure SetOnWebReady(const Value: TAudioEventProc);

    /// <summary>
    /// Installs a host callback that fires when the embedded page’s realtime
    /// JavaScript bootstrap completes and the host–web bridge is ready.
    /// </summary>
    /// <remarks>
    /// <para>
    /// • The callback is invoked once the WebView client has initialized its
    /// realtime layer (created the JS runtime objects, bound message handlers, and
    /// completed bridge registration). Treat this as the earliest safe point to
    /// send realtime commands or query JS-side readiness-dependent state.
    /// </para>
    /// <para>
    /// • Invocation originates from the WebView message-dispatch context and is
    /// not guaranteed to run on the VCL/main UI thread. If you update VCL
    /// controls from this handler, marshal to the UI thread to avoid threading
    /// issues with the VCL/Edge runtime.
    /// </para>
    /// <para>
    /// • The handler should return quickly. Keep workloads lightweight and defer
    /// expensive operations to a background task to avoid blocking message
    /// processing and UI responsiveness.
    /// </para>
    /// <para>
    /// • Assigning this property does not itself trigger initialization; the
    /// event is emitted by the page during its startup sequence after navigation
    /// completes. To react earlier to navigation, use the browser’s navigation
    /// events; to react to general web readiness, see <c>OnWebReady</c>.
    /// </para>
    /// </remarks>
    property RealtimeJsReadyProc: TAudioEventProc read GetRealtimeJsReady write SetRealtimeJsReady;

    /// <summary>
    /// Installs a host callback that is triggered when the embedded realtime WebRTC
    /// connection is successfully established.
    /// </summary>
    /// <remarks>
    /// <para>
    /// • The callback is invoked when the page-side realtime logic emits a
    /// "connected" event, indicating that the WebRTC peer connection and data
    /// channel have transitioned to the connected state and realtime communication
    /// is now possible.
    /// </para>
    /// <para>
    /// • Use this event to update UI state, enable send controls, or trigger host
    /// logic that depends on an active realtime (WebRTC) connection. Do not attempt
    /// to send messages before this event; messages sent prior to connection may be
    /// lost or rejected by the page.
    /// </para>
    /// <para>
    /// • The callback is invoked from the WebView message-dispatch context and is
    /// not guaranteed to execute on the VCL/main UI thread. If UI updates are
    /// required, marshal the handler to the UI thread to avoid threading issues.
    /// </para>
    /// <para>
    /// • Keep the handler lightweight; long-running operations should be delegated
    /// to background tasks to maintain message throughput and UI responsiveness.
    /// </para>
    /// <para>
    /// • The event is complementary to <c>RealtimeClosedProc</c>, which fires when
    /// the connection is lost or intentionally closed.
    /// </para>
    /// </remarks>
    property RealtimeConnectedProc: TAudioEventProc read GetRealtimeConnected write SetRealtimeConnected;

    /// <summary>
    /// Installs a host callback that is triggered when the embedded realtime WebRTC
    /// connection is closed or lost.
    /// </summary>
    /// <remarks>
    /// <para>
    /// • The callback is invoked when the page-side realtime logic emits a "closed"
    /// event, indicating that the WebRTC peer connection and/or data channel have
    /// been disconnected, failed, or otherwise terminated. This may occur due to
    /// remote hangup, network interruption, or explicit closure from either side.
    /// </para>
    /// <para>
    /// • Use this event to update UI state, disable realtime controls, clean up
    /// any host resources tied to the connection, or trigger reconnection logic
    /// as appropriate for your application.
    /// </para>
    /// <para>
    /// • The callback is invoked from the WebView message-dispatch context and is
    /// not guaranteed to execute on the VCL/main UI thread. If you interact with
    /// VCL components, marshal the handler to the UI thread to avoid threading
    /// issues.
    /// </para>
    /// <para>
    /// • Keep the callback body lightweight and non-blocking. If substantial
    /// cleanup or error recovery is needed, delegate that work to a background
    /// thread or asynchronous task to maintain UI responsiveness.
    /// </para>
    /// <para>
    /// • The event is complementary to <c>RealtimeConnectedProc</c>, which fires
    /// when the realtime connection becomes active.
    /// </para>
    /// </remarks>
    property RealtimeClosedProc: TAudioEventProc read GetRealtimeClosed write SetRealtimeClosed;

    /// <summary>
    /// Installs a host callback that receives state changes from the embedded
    /// WebRTC PeerConnection.
    /// </summary>
    /// <param name="Value">
    /// A string describing the new PeerConnection state (for example, "new", "connecting",
    /// "connected", "disconnected", "failed", or "closed"). The value reflects the
    /// <c>RTCPeerConnection.connectionState</c> or a normalized UI-facing state emitted
    /// by the embedded realtime logic.
    /// </param>
    /// <remarks>
    /// <para>
    /// • The callback is invoked each time the underlying WebRTC PeerConnection
    /// changes state, allowing the host to track connection health, update UI
    /// indicators, log events, or trigger recovery logic as appropriate.
    /// </para>
    /// <para>
    /// • The provided state string is suitable for direct display, conditional
    /// logic, or telemetry. See the WebRTC specification for possible values and
    /// their semantics.
    /// </para>
    /// <para>
    /// • The handler is called from the WebView message-dispatch context and is
    /// not guaranteed to execute on the VCL/main UI thread. If you interact with
    /// VCL components, marshal UI work to the main thread to avoid threading
    /// issues.
    /// </para>
    /// <para>
    /// • Keep the handler lightweight and non-blocking; if substantial processing
    /// is required (e.g., logging, analytics, failover), delegate to background
    /// tasks to maintain UI responsiveness.
    /// </para>
    /// <para>
    /// • This event is complementary to <c>RealtimeConnectedProc</c> and
    /// <c>RealtimeClosedProc</c>, and is emitted on every connection state change,
    /// not just on connection or disconnection.
    /// </para>
    /// </remarks>
    property RealtimePcStateProc: TAudioStringEventProc read GetRealtimePcState write SetRealtimePcState;

    /// <summary>
    /// Installs a host callback that is triggered when the embedded WebRTC
    /// DataChannel transitions to the open state.
    /// </summary>
    /// <remarks>
    /// <para>
    /// • The callback is invoked when the WebView’s realtime logic emits a "data
    /// channel open" event, indicating that the WebRTC DataChannel has been
    /// successfully established and is now ready for bidirectional messaging.
    /// </para>
    /// <para>
    /// • Use this event to enable UI controls or host logic that requires an active
    /// realtime channel (for example, to permit sending or receiving data).
    /// </para>
    /// <para>
    /// • The callback is called from the WebView message-dispatch context and is
    /// not guaranteed to execute on the VCL/main UI thread. If your handler interacts
    /// with VCL components, marshal work to the UI thread to avoid threading issues.
    /// </para>
    /// <para>
    /// • Keep the handler short and non-blocking. Delegate any heavy logic or resource
    /// initialization to a background task to ensure smooth UI and message processing.
    /// </para>
    /// <para>
    /// • The event is complementary to <c>RealtimeDataChannelCloseProc</c>, which fires
    /// when the data channel is closed or lost.
    /// </para>
    /// </remarks>
    property RealtimeDataChannelOpenProc: TAudioEventProc read GetRealtimeDataChannelOpen write SetRealtimeDataChannelOpen;

    /// <summary>
    /// Installs a host callback that is triggered when the embedded WebRTC
    /// DataChannel transitions to the closed state.
    /// </summary>
    /// <remarks>
    /// <para>
    /// • The callback is invoked when the WebView’s realtime logic emits a "data channel close"
    /// event, indicating that the WebRTC DataChannel has been closed, either due to remote
    /// shutdown, local intent, or a network/interruption failure.
    /// </para>
    /// <para>
    /// • Use this event to update UI state, disable data-dependent controls, clean up
    /// any resources associated with the realtime data channel, or initiate reconnection
    /// or recovery logic as appropriate.
    /// </para>
    /// <para>
    /// • The callback is called from the WebView message-dispatch context and is
    /// not guaranteed to execute on the VCL/main UI thread. Marshal to the UI thread
    /// if interacting with VCL components or thread-sensitive resources.
    /// </para>
    /// <para>
    /// • Keep the handler lightweight and non-blocking; delegate substantial cleanup
    /// or recovery work to background threads to preserve UI responsiveness.
    /// </para>
    /// <para>
    /// • The event is complementary to <c>RealtimeDataChannelOpenProc</c>, which fires
    /// when the data channel becomes available.
    /// </para>
    /// </remarks>
    property RealtimeDataChannelCloseProc: TAudioEventProc read GetRealtimeDataChannelClose write SetRealtimeDataChannelClose;

    /// <summary>
    /// Installs a host callback that is triggered when a new media track
    /// (typically audio) is added to the embedded realtime WebRTC PeerConnection.
    /// </summary>
    /// <remarks>
    /// <para>
    /// • The callback is invoked when the WebView’s realtime logic emits a
    /// "track added" event, indicating that a new remote media stream (such as an
    /// incoming audio track) has been received and attached to the PeerConnection.
    /// </para>
    /// <para>
    /// • Use this event to update UI elements, initialize host-side audio playback,
    /// process media metadata, or otherwise react to new incoming media in the
    /// realtime session.
    /// </para>
    /// <para>
    /// • The callback is called from the WebView message-dispatch context and is not
    /// guaranteed to execute on the VCL/main UI thread. Marshal to the UI thread if
    /// updating VCL controls or interacting with thread-affine resources.
    /// </para>
    /// <para>
    /// • The handler should be lightweight and non-blocking; if significant processing
    /// (such as decoding or analysis) is required, delegate to a background thread or
    /// asynchronous task to preserve UI responsiveness.
    /// </para>
    /// <para>
    /// • If you need to distinguish the type of track (e.g., audio vs. video), inspect
    /// the accompanying data or extend the event interface to receive the track "kind".
    /// </para>
    /// </remarks>
    property RealtimeTrackAddedProc: TAudioEventProc read GetRealtimeTrackAdded write SetRealtimeTrackAdded;

    /// <summary>
    /// Installs a host callback that receives all raw realtime (OpenAI or custom)
    /// event objects emitted by the embedded page as JSON payloads.
    /// </summary>
    /// <param name="Data">
    /// The <c>TJSONObject</c> representing the full event object as received from
    /// the web client. The object typically contains an <c>event</c> field, a <c>payload</c>,
    /// and additional metadata or data as defined by the realtime protocol.
    /// </param>
    /// <remarks>
    /// <para>
    /// • The callback is invoked for every realtime "oai_event" (or compatible) message
    /// emitted by the page, allowing host code to inspect, deserialize, dispatch, or log
    /// the full event payload at the application level.
    /// </para>
    /// <para>
    /// • Use this event to handle advanced or custom realtime events, perform analytics,
    /// extend protocol coverage, or bridge additional JS-side event types into Delphi code.
    /// </para>
    /// <para>
    /// • The provided <c>TJSONObject</c> is owned by the <c>TEdgeAudio</c> instance and is
    /// only valid for the duration of the event handler; do not store references or attempt
    /// to free the object.
    /// </para>
    /// <para>
    /// • The handler is called from the WebView message-dispatch context and is not
    /// guaranteed to run on the VCL/main UI thread. Marshal to the UI thread if interacting
    /// with VCL components or other thread-affine resources.
    /// </para>
    /// <para>
    /// • Keep the handler lightweight and non-blocking. For complex event handling,
    /// deserialization, or persistence, delegate to background tasks to preserve UI and
    /// message responsiveness.
    /// </para>
    /// <para>
    /// • This property provides a generic passthrough for all JS-side realtime event
    /// payloads and can be used in conjunction with typed event handlers for specific
    /// events (e.g., connection, data channel, track).
    /// </para>
    /// </remarks>
    property RealtimeEventProc: TAudioJSONObjectProc read GetRealtimeEvent write SetRealtimeEvent;

    /// <summary>
    /// Installs a host callback that is triggered when the embedded web audio UI
    /// has finished loading and is ready for interaction.
    /// </summary>
    /// <remarks>
    property OnWebReady: TAudioEventProc read GetOnWebReady write SetOnWebReady;

    /// <summary>
    /// Installs a host callback that is invoked when the embedded UI requests a close action.
    /// </summary>
    /// <remarks>
    /// <para>
    /// • The callback is stored by the <c>TEdgeAudio</c> instance and is executed by the WebView
    /// message handler when a close event is received from the page. The handler invokes the
    /// callback after parsing the incoming message and performing any required host side checks.
    /// </para>
    /// <para>
    /// • The callback may be invoked from the WebView message handling context and is not guaranteed
    /// to run on the VCL/main UI thread. Implementations that touch UI components must marshal
    /// those operations to the main thread to avoid threading issues in the VCL/Edge runtime.
    /// </para>
    /// <para>
    /// • Setting or clearing the callback does not itself close the WebView or change capture/playback
    /// state — it merely installs a notification hook so the host can respond (for example by
    /// hiding UI, stopping capture, or performing cleanup). The host is responsible for performing
    /// any actual shutdown or navigation actions in response to the callback invocation.
    /// </para>
    /// <para>
    /// • Keep the callback body lightweight; if expensive work is required, delegate to a background
    /// task to avoid blocking the message handler thread and to keep the UI responsive.
    /// </para>
    /// </remarks>
    property CloseClick: TAudioEventProc read GetCloseClick write SetCloseClick;

    /// <summary>
    /// Installs a host callback that receives microphone button events from the embedded UI.
    /// </summary>
    /// <remarks>
    /// <para>
    /// • The provided callback is stored by the <c>TEdgeAudio</c> instance and is invoked by
    /// the WebView message handler when the user toggles the microphone control in the
    /// embedded UI. The handler supplies a normalized textual state (for example <c>'on'</c>
    /// or <c>'off'</c>); callers should treat the argument as authoritative for the UI state
    /// but not as a command to change capture lifecycle — it is a notification hook only.
    /// </para>
    /// <para>
    /// • The callback may be executed from the WebView message handling context and is not
    /// guaranteed to run on the VCL/main UI thread. If the callback interacts with VCL UI
    /// components or other thread-affine resources, callers must marshal those operations to
    /// the main thread to avoid threading issues in the VCL/Edge runtime.
    /// </para>
    /// <para>
    /// • The callback should be lightweight. If substantial processing is required in response
    /// to a mic state change (for example logging, file I/O, or network work), delegate that
    /// work to a background thread or task to avoid blocking the message handler and keep the
    /// UI responsive.
    /// </para>
    /// <para>
    /// • Installing this callback does not itself change the capture pipeline or the mic sending
    /// state; it only notifies the host about UI-initiated changes. To programmatically change
    /// the mic sending state use the capture interface methods (<c>MicOn</c>, <c>MicOff</c>,
    /// <c>MicToggle</c>) or the capture lifecycle methods (<c>StartCapture</c>/<c>StopCapture</c>).
    /// </para>
    /// </remarks>
    property MicClick: TAudioStringEventProc read GetMicClick write SetMicClick;

    /// <summary>
    /// Installs a host callback that is invoked when playback starts in the embedded player.
    /// </summary>
    /// <remarks>
    /// <para>
    /// • The callback is stored by the <c>TEdgeAudio</c> instance and is executed by the WebView
    /// message handler when playback begins or when a streaming source signals that playback
    /// has started. This provides a notification hook for the host to update UI, start related
    /// logic, or coordinate application state in response to playback initiation.
    /// </para>
    /// <para>
    /// • The callback may be invoked from the WebView message handling context and is not guaranteed
    /// to run on the VCL/main UI thread. If the callback manipulates VCL components or other
    /// thread-affine resources, callers must marshal those operations to the main thread to avoid
    /// threading issues in the VCL/Edge runtime.
    /// </para>
    /// <para>
    /// • Keep the callback body short and non-blocking. Playback start events can occur frequently in
    /// some workflows (for example when streaming many short tracks), so expensive processing should
    /// be delegated to background tasks to avoid blocking the message handler and to keep the UI
    /// responsive.
    /// </para>
    /// <para>
    /// • Installing this callback does not itself start or stop playback; it only registers a handler
    /// to be notified when the embedded player reports a start event. For stopping or controlling
    /// playback, use the player interface methods (<c>Play</c>, <c>Pause</c>, <c>Stop</c>, etc.).
    /// </para>
    /// </remarks>
    property AudioPlayProc: TAudioEventProc read GetAudioPlayProc write SetAudioPlayProc;

    /// <summary>
    /// Installs a host callback that is invoked when playback or streaming of a response finishes.
    /// </summary>
    /// <remarks>
    /// <para>
    /// • The callback is stored by the <c>TEdgeAudio</c> instance and is executed by the WebView
    /// message handler when the player reports that playback or a streaming response has completed.
    /// This notification hook is suitable for host side actions that should run once playback has
    /// finished, such as updating UI state, releasing temporary resources, resuming microphone capture,
    /// or starting follow-up processing.
    /// </para>
    /// <para>
    /// • The callback may be invoked from the WebView message handling context and is not guaranteed
    /// to run on the VCL/main UI thread. If the callback manipulates VCL UI components or other
    /// thread-affine resources, callers must marshal those operations to the main thread to avoid
    /// threading issues in the VCL/Edge runtime.
    /// </para>
    /// <para>
    /// • The end notification is observational — it is driven by browser/JavaScript events and may
    /// have slight delivery latency. If your logic requires tight synchronization with playback state,
    /// consider also observing related playback events (<c>audio_stream_started</c>, <c>audio_play</c>,
    /// <c>audio_pause</c>) in combination with the end callback.
    /// </para>
    /// <para>
    /// • Keep the callback body lightweight. End events are infrequent compared with time updates,
    /// but the callback runs on the message handling path; expensive processing should be delegated
    /// to a background thread or task to avoid blocking the message handler and to keep the UI responsive.
    /// </para>
    /// </remarks>
    property AudioEndProc: TAudioEventProc read GetAudioEndProc write SetAudioEndProc;
  end;

  {$ENDREGION}

  IEdgeAudio = interface(IEdgeAudioEvent)
    ['{53C18069-B282-4DB9-B615-85A96C8690E9}']
    function GetBrowser: TEdgeBrowser;
    function GetEdgeAudioCapture: IEdgeAudioCapture;
    function GetEdgeAudioPlayer: IEdgeAudioPlayer;
    function GetJsonObject: TJSONObject;
    function GetHtmlIndex: string;
    function GetWebPath: string;
    function GetWebRTC: IWebRTC;

    procedure SetHtmlIndex(const Value: string);
    procedure SetWebPath(const Value: string);
    procedure SetWebRTC(const Value: IWebRTC);

    /// <summary>
    /// Controls whether playback is automatically interrupted and capture sending is blocked
    /// when live microphone activity is detected (talkover).
    /// </summary>
    /// <remarks>
    /// <para>
    /// • This method enables or disables the automatic blocking of capture during playback based on
    /// live microphone activity. When enabled, the system monitors the microphone in real-time
    /// and will automatically pause playback and prevent new captured audio segments from being sent
    /// whenever sustained voice activity is detected, as configured by the current talkover parameters.
    /// This is useful for implementing "barge-in" or talkover functionality, ensuring that
    /// user speech can always interrupt and take precedence over audio playback.
    /// </para>
    /// <para>
    /// • Internally, this method sets the <c>window.autoBlockCaptureDuringPlayback</c> property
    /// in the embedded WebView. If enabled while playback is already in progress, capture
    /// sending will be blocked immediately. If disabled while capture is blocked due to playback,
    /// normal capture sending will be restored. The change takes effect immediately and will
    /// remain active until changed again.
    /// </para>
    /// <para>
    /// • Typical usage: call <c>DisableCaptureOnSpeech(True)</c> to ensure microphone speech always interrupts
    /// playback and pauses audio output, or <c>DisableCaptureOnSpeech(False)</c> to allow playback and capture
    /// to operate independently (for example, to permit talkover or simultaneous capture).
    /// </para>
    /// <para>
    /// • This method does not itself start or stop capture or playback; it only sets the gating
    /// policy. Ensure that talkover and VAD parameters are configured as desired via the appropriate
    /// interfaces (<c>IEdgeAudioPlayerTalkover</c> and <c>IEdgeAudioPlayerVAD</c>)
    /// for optimal behavior.
    /// </para>
    /// </remarks>
    procedure DisableCaptureOnSpeech(const Value: Boolean);

    /// <summary>
    /// Displays a transient error message in the embedded audio UI.
    /// </summary>
    /// <param name="Value">
    /// The text of the error message to display. This string is shown verbatim
    /// inside the UI's toast/notification element; it should be short and suitable
    /// for user display.
    /// </param>
    /// <param name="DurationMs">
    /// Duration in milliseconds (ms) for which the error message should remain
    /// visible before automatically fading out. The default is <c>7000</c>
    /// (7 seconds). Must be a non-negative integer.
    /// </param>
    /// <remarks>
    /// <para>
    /// • This procedure forwards a request to the embedded WebView via the
    /// JavaScript bridge (using <c>TAudioScript.ShowToast</c>) to display the
    /// message in a toast-style UI element.
    /// </para>
    /// <para>
    /// • The call is asynchronous: the method returns immediately after sending the
    /// script to the WebView. The actual display and fade-out are handled entirely
    /// on the web side.
    /// </para>
    /// <para>
    /// • This is a UI helper only. It does not log the error, raise exceptions,
    /// or interrupt capture/playback state. If you need structured error handling,
    /// call <c>DoOnException</c> or implement your own logging in addition to this
    /// method.
    /// </para>
    /// <para>
    /// • Because the call interacts with the WebView, it must be executed from the
    /// UI/main thread as required by the VCL/Edge runtime.
    /// </para>
    /// </remarks>
    procedure DisplayError(const Value: string; const DurationMs: Integer = 7000);

    /// <summary>
    /// Default exception handler that displays an error message in the embedded audio UI.
    /// </summary>
    /// <param name="Sender">
    /// The object that raised the exception. This is typically supplied by the
    /// VCL or framework when wiring <c>DoOnException</c> as an application-wide
    /// or component-level exception handler.
    /// </param>
    /// <param name="E">
    /// The exception instance that was raised. Its <c>Message</c> property is
    /// extracted and shown to the user in the audio UI.
    /// </param>
    /// <remarks>
    /// <para>
    /// • This method provides a simple bridge from Delphi exceptions to the
    /// WebView-based UI by calling <see cref="DisplayError"/> with the exception
    /// message. It is intended as a user-facing notification mechanism rather than
    /// a logging or diagnostic facility.
    /// </para>
    /// <para>
    /// • The procedure does not re-raise the exception, write logs, or perform
    /// recovery logic. If you need structured error handling, persistence, or
    /// recovery, add additional logic in your own exception handler in addition to
    /// or instead of this method.
    /// </para>
    /// <para>
    /// • Typical usage: assign <c>DoOnException</c> to the <c>Application.OnException</c>
    /// event or to a component’s <c>OnException</c> callback to surface unexpected
    /// errors directly in the audio UI.
    /// </para>
    /// <para>
    /// • Because <see cref="DisplayError"/> interacts with the WebView, this method
    /// should be invoked from the UI/main thread when required by the VCL/Edge
    /// runtime.
    /// </para>
    /// </remarks>
    procedure DoOnException(Sender: TObject; E: Exception);

    /// <summary>
    /// Navigates the embedded WebView to the audio UI entry page (e.g. <c>audio.html</c>)
    /// located under <see cref="WebPath"/> using a local <c>file:///</c> URL.
    /// </summary>
    /// <remarks>
    /// <para>
    /// • This method issues a navigation on the underlying <see cref="EdgeBrowser"/> to the
    /// HTML index defined by the component (default <c>audio.html</c>) in the folder given by
    /// <see cref="WebPath"/>. The path is expanded and combined as
    /// <c>file:///[ExpandFileName(WebPath)]/audio.html</c>.
    /// </para>
    /// <para>
    /// • Navigation is asynchronous: the call returns immediately. Use the browser’s
    /// <c>OnNavigationCompleted</c> event (handled internally to raise the component’s ready
    /// signal) to detect when the page is fully loaded. If you need to run scripts after load,
    /// do so from that callback.
    /// </para>
    /// <para>
    /// • At design time (when the browser is hosted in the IDE and not initialized),
    /// the procedure is a no-op.
    /// </para>
    /// <para>
    /// • <b>Requirements:</b> <see cref="WebPath"/> must point to a folder that contains the
    /// UI assets (HTML/JS/CSS) and the index file. If the folder or index file is missing,
    /// the WebView will navigate to a blank/error page as determined by the runtime.
    /// </para>
    /// <para>
    /// • This method performs a direct <c>file:///</c> navigation. If you need a secure
    /// context or relaxed CORS for local assets, prefer <c>NavigateToIndex</c>, which maps a
    /// virtual host to the local folder before navigating.
    /// </para>
    /// <para>
    /// • Threading: call from the UI/main thread as required by VCL/WebView2.
    /// </para>
    /// </remarks>
    procedure Navigate;

    /// <summary>
    /// Gets the capture interface used to control microphone capture and to access
    /// the most recently saved captured audio segment.
    /// </summary>
    /// <remarks>
    /// The returned interface is owned by the <c>TEdgeAudio</c> instance and must
    /// not be freed by the caller. Calls are forwarded to the embedded WebView via
    /// the JavaScript bridge and take effect immediately if the WebView is ready.
    /// Use this property whenever you need programmatic control of microphone
    /// capture or to retrieve the most recent captured file for processing.
    /// </remarks>
    property Capture: IEdgeAudioCapture read GetEdgeAudioCapture;

    /// <summary>
    /// Gets the underlying TEdgeBrowser instance used by the audio subsystem.
    /// </summary>
    /// <remarks>
    /// The returned browser instance is owned by the <c>TEdgeAudio</c> object and
    /// must not be freed by the caller. Use this property when you need direct,
    /// low-level access to the WebView (for example to execute scripts, subscribe
    /// to additional WebView events, adjust navigation, or configure host-to-web
    /// mappings). Keep in mind that many WebView operations must be performed on
    /// the UI/main thread; callers should marshal calls to the appropriate thread
    /// when required by the VCL/Edge runtime. Changes to the browser (navigation,
    /// settings, permission handling) may affect the audio component's behavior,
    /// so coordinate modifications carefully with the audio lifecycle.
    /// </remarks>
    property EdgeBrowser: TEdgeBrowser read GetBrowser;

    /// <summary>
    /// Gets or sets the file name of the HTML index (entry point) used to load the audio UI in the embedded WebView.
    /// </summary>
    /// <remarks>
    /// <para>
    /// This property determines the name of the HTML file that acts as the main entry point for the embedded audio client UI.
    /// By default, this is set to <c>audio.html</c>, but it can be customized to point to a different HTML file as needed
    /// (for example, to support multiple UI versions, languages, or application modes).
    /// </para>
    /// <para>
    /// • The property value is combined with the <see cref="WebPath"/> property when calling <see cref="Navigate"/> or
    /// <see cref="NavigateToIndex"/> to construct the full file URL (<c>file:///.../audio.html</c> by default).
    /// </para>
    /// <para>
    /// • Changing the <c>HtmlIndex</c> property does not automatically reload the WebView; after updating the property,
    /// call <see cref="Navigate"/> or <see cref="NavigateToIndex"/> to apply the change and load the new HTML entry point.
    /// </para>
    /// <para>
    /// • The specified file must exist in the folder referenced by <see cref="WebPath"/>; navigation will fail if the file
    /// is missing or inaccessible, resulting in a blank or error page in the embedded browser.
    /// </para>
    /// <para>
    /// • Typical usage: assign a custom HTML file name (such as <c>audio.en.html</c> or <c>audio.dev.html</c>)
    /// to support alternative UIs or runtime environments. The change takes effect on the next navigation.
    /// </para>
    /// </remarks>
    property HtmlIndex: string read GetHtmlIndex write SetHtmlIndex;

    /// <summary>
    /// Exposes the parsed JSON payload of the most recently received WebView message.
    /// </summary>
    /// <remarks>
    /// <para>
    /// The object is owned by <c>TEdgeAudio</c> and is transient: it is created when a
    /// message arrives, remains valid for the duration of the current dispatch
    /// (<c>EdgeBrowser1WebMessageReceived</c> / <c>AggregateAudioEvents</c>), and is freed
    /// immediately afterward. Do not store the reference or attempt to free it.
    /// </para>
    /// <para>
    /// Intended for event handlers to inspect fields such as <c>event</c>,
    /// <c>value</c>, <c>payload</c>, <c>duration</c>, or <c>t</c>. Use
    /// <c>TJSONObject.GetValue&lt;T&gt;</c> (with defaults) to read values safely.
    /// </para>
    /// <para>
    /// Access occurs on the WebView message handling context and is not guaranteed to be
    /// the VCL main thread; marshal any UI work to the UI thread as needed. Treat the
    /// returned object as read-only—mutating it has no effect on the original message.
    /// </para>
    /// </remarks>
    property JsonObject: TJSONObject read GetJsonObject;

    /// <summary>
    /// Gets the player interface used to control audio playback and to configure
    /// player-related behavior such as talkover and VAD parameters.
    /// </summary>
    /// <remarks>
    /// The returned interface is owned by the <c>TEdgeAudio</c> instance and must
    /// not be freed by the caller. Calls are proxied to the embedded WebView via
    /// the JavaScript bridge and take effect immediately when the WebView is ready.
    /// Use this property for programmatic control of playback and for adjusting
    /// talkover and VAD settings that affect how playback interacts with live
    /// microphone input.
    /// </remarks>
    property Player: IEdgeAudioPlayer read GetEdgeAudioPlayer;

    /// <summary>
    /// Gets or sets the filesystem path to the folder containing the web assets
    /// (HTML, JavaScript, CSS) used by the embedded audio UI.
    /// </summary>
    /// <remarks>
    /// <para>
    /// • This path is combined with the HTML index file name (by default
    /// <c>audio.html</c>) when calling <see cref="Navigate"/> or
    /// <see cref="NavigateToIndex"/> to load the audio client into the
    /// embedded <c>TEdgeBrowser</c>.
    /// </para>
    /// <para>
    /// • By default, the property is initialized to the value returned by
    /// <c>TAudioWeb.WebPath</c>. Applications may override it to point to a
    /// custom or relocated copy of the web resources.
    /// </para>
    /// <para>
    /// • The folder must contain the expected resource files referenced by the
    /// audio client (JavaScript, styles, and the index HTML). If the files are
    /// missing or inaccessible, navigation will fail and the component will not
    /// function correctly.
    /// </para>
    /// <para>
    /// • The value can be absolute or relative; if relative, it is resolved
    /// against the current working directory when navigation occurs.
    /// </para>
    /// <para>
    /// • Changing this property does not automatically reload the WebView.
    /// Call <see cref="Navigate"/> or <see cref="NavigateToIndex"/> after
    /// updating the path to refresh the embedded client.
    /// </para>
    /// </remarks>
    property WebPath: string read GetWebPath write SetWebPath;

    /// <summary>
    /// Gets or sets the interface instance used for low-level realtime (WebRTC)
    /// communication between the host and the embedded audio page.
    /// </summary>
    /// <remarks>
    /// <para>
    /// • Assign an <c>IWebRTC</c> implementation to connect host-side logic with the
    /// embedded WebView’s realtime data channel and peer connection layer. This enables
    /// programmatic sending of string-based messages to the web client and integration
    /// with custom realtime protocols or signaling flows.
    /// </para>
    /// <para>
    /// • The interface instance is used by the <c>TEdgeAudio</c> component and is
    /// not owned or freed by the component; lifetime and memory management are the
    /// responsibility of the caller. Replace or clear the instance as needed to
    /// change realtime host logic or to disconnect.
    /// </para>
    /// <para>
    /// • Assigning or updating this property does not automatically start or stop
    /// the WebRTC connection. Use the corresponding capture and player methods to
    /// control the realtime lifecycle.
    /// </para>
    /// <para>
    /// • The <c>Send</c> method on the <c>IWebRTC</c> interface may be called from
    /// the host to transmit messages to the embedded JS page. Message handling and
    /// protocol details depend on your specific integration.
    /// </para>
    /// <para>
    /// • When interacting with VCL components from WebRTC callbacks or event handlers,
    /// ensure correct threading (marshal to the UI thread as required).
    /// </para>
    /// </remarks>
    property WebRTC: IWebRTC read GetWebRTC write SetWebRTC;
  end;

implementation

end.
