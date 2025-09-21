unit Edge.Audio2;

interface

uses
  Winapi.Windows, Winapi.Messages, Winapi.WebView2, Winapi.ActiveX,
  System.SysUtils, System.Classes, System.StrUtils, System.IOUtils, System.JSON, system.UITypes,
  Vcl.Forms, Vcl.Edge, Vcl.Dialogs,
  Edge.Audio.Interfaces, Edge.Audio.Events2, Audio.JSON.Parser2, Audio.Web.Assets,
  Edge.Audio.JsBridge;

const
  HTML_INDEX = 'index.html';

type
  TEdgeAudio = class;

  {$REGION 'Audio capture'}

  TEdgeAudioCapture = class(TInterfacedObject, IEdgeAudioCapture)
  private
    FOwner: TEdgeAudio;
    FProcessOnAudio: Boolean;
    function GetProcessOnAudio: Boolean;
    procedure SetProcessOnAudio(const Value: Boolean);
  public
    constructor Create(const AOwner: TEdgeAudio);
    procedure MicOff; virtual;
    procedure MicOn; virtual;
    procedure MicToggle; virtual;
    procedure StartCapture; virtual;
    property ProcessOnAudio: Boolean read GetProcessOnAudio write SetProcessOnAudio;
  end;

  {$ENDREGION}

  {$REGION 'Audio player'}

  TEdgeAudioPlayer = class(TInterfacedObject, IEdgeAudioPlayer)
  private
    FOwner: TEdgeAudio;
    FIsPlaying: Boolean;
    function GetIsPlaying: Boolean;
    procedure SetIsPlaying(const Value: Boolean);
  public
    constructor Create(const AOwner: TEdgeAudio);
    procedure SetVolume(const Value: Double); virtual;
    procedure Stop; virtual;
    property IsPlaying: Boolean read GetIsPlaying write SetIsPlaying;
  end;

  {$ENDREGION}

  {$REGION 'WebRTC'}

  TWebRTC = class(TInterfacedObject, IWebRTC)
  private
    FOwner: TEdgeAudio;
  public
    constructor Create(const AOwner: TEdgeAudio);
    procedure Send(const Body: string);
  end;


  {$ENDREGION}

  TEdgeAudio = class(TInterfacedObject, IEdgeAudio)
  const
    VIRTUAL_HOST = 'localapp';
  private
    FEdgeBrowser: TEdgeBrowser;
    FEventEngineManager: IAudioEventEngineManager;
    FHtmlIndex: string;
    FWebPath: string;
    FCloseClick: TAudioEventProc;
    FMicClick: TAudioStringEventProc;
    FAudioPlayProc: TAudioEventProc;
    FAudioEndProc: TAudioEventProc;

    FRealtimeJsReadyProc: TAudioEventProc;
    FRealtimeConnectedProc: TAudioEventProc;
    FRealtimeClosedProc: TAudioEventProc;
    FRealtimePcStateProc: TAudioStringEventProc;
    FRealtimeDataChannelOpenProc: TAudioEventProc;
    FRealtimeDataChannelCloseProc: TAudioEventProc;
    FRealtimeTrackAddedProc: TAudioEventProc;
    FRealtimeEventProc: TAudioJSONObjectProc;

    FEdgeAudioCapture: IEdgeAudioCapture;
    FEdgeAudioPlayer: IEdgeAudioPlayer;
    FWebRTC: IWebRTC;
    FJsonObject: TJSONObject;
    FIsReady: Boolean;
    FAwaitingIndex: Boolean;
    FPendingNavigate: Boolean;
    FOnWebReady: TAudioEventProc;
    function GetCloseClick: TAudioEventProc;
    procedure SetCloseClick(const Value: TAudioEventProc);
    function GetMicClick: TAudioStringEventProc;
    procedure SetMicClick(const Value: TAudioStringEventProc);
    function GetAudioPlayProc: TAudioEventProc;
    procedure SetAudioPlayProc(const Value: TAudioEventProc);
    function GetAudioEndProc: TAudioEventProc;
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

    function GetHtmlIndex: string;
    function GetJsonObject: TJSONObject;
    function GetBrowser: TEdgeBrowser;
    function GetEdgeAudioCapture: IEdgeAudioCapture;
    function GetEdgeAudioPlayer: IEdgeAudioPlayer;
    procedure SetHtmlIndex(const Value: string);
    procedure JSExecute(const Code: string);
    function GetWebPath: string;
    procedure SetWebPath(const Value: string);
    function GetOnWebReady: TAudioEventProc;
    procedure SetOnWebReady(const Value: TAudioEventProc);
    procedure SetWebRTC(const Value: IWebRTC);
    function GetWebRTC: IWebRTC;
  protected
    procedure EdgeBrowserCreateWebViewCompleted(Sender: TCustomEdgeBrowser;
      AResult: HRESULT);
    procedure EdgeBrowserPermissionRequested(Sender: TCustomEdgeBrowser;
      Args: TPermissionRequestedEventArgs);
    procedure EdgeBrowserWebMessageReceived(Sender: TCustomEdgeBrowser;
      Args: TWebMessageReceivedEventArgs);
    procedure EdgeBrowserNavigationCompleted(Sender: TCustomEdgeBrowser;
      IsSuccess: Boolean;
      WebErrorStatus: COREWEBVIEW2_WEB_ERROR_STATUS);
  public
    constructor Create(const AEdgeBrowser: TEdgeBrowser);
    procedure DisableCaptureOnSpeech(const Value: Boolean);
    procedure DisplayError(const Value: string; const DurationMs: Integer = 7000);
    procedure DoOnException(Sender: TObject; E: Exception);
    procedure Navigate;
    procedure NavigateToIndex;

    property Capture: IEdgeAudioCapture read GetEdgeAudioCapture;
    property HtmlIndex: string read GetHtmlIndex write SetHtmlIndex;
    property Player: IEdgeAudioPlayer read GetEdgeAudioPlayer;
    property WebPath: string read GetWebPath write SetWebPath;
    property WebRTC: IWebRTC read GetWebRTC write SetWebRTC;

    property AudioEndProc: TAudioEventProc read GetAudioEndProc write SetAudioEndProc;
    property AudioPlayProc: TAudioEventProc read GetAudioPlayProc write SetAudioPlayProc;
    property CloseClick: TAudioEventProc read GetCloseClick write SetCloseClick;
    property MicClick: TAudioStringEventProc read GetMicClick write SetMicClick;
    property OnWebReady: TAudioEventProc read GetOnWebReady write SetOnWebReady;

    property RealtimeJsReadyProc: TAudioEventProc read GetRealtimeJsReady write SetRealtimeJsReady;
    property RealtimeConnectedProc: TAudioEventProc read GetRealtimeConnected write SetRealtimeConnected;
    property RealtimeClosedProc: TAudioEventProc read GetRealtimeClosed write SetRealtimeClosed;
    property RealtimePcStateProc: TAudioStringEventProc read GetRealtimePcState write SetRealtimePcState;

    property RealtimeDataChannelOpenProc: TAudioEventProc read GetRealtimeDataChannelOpen write SetRealtimeDataChannelOpen;
    property RealtimeDataChannelCloseProc: TAudioEventProc read GetRealtimeDataChannelClose write SetRealtimeDataChannelClose;
    property RealtimeTrackAddedProc: TAudioEventProc read GetRealtimeTrackAdded write SetRealtimeTrackAdded;
    property RealtimeEventProc: TAudioJSONObjectProc read GetRealtimeEvent write SetRealtimeEvent;
  end;

implementation

const
  DLL_ISSUE =
    'To ensure full support for the Edge browser, please copy the "WebView2Loader.dll" file into the executable''s directory.'+ sLineBreak +
    'You can find this file in the project''s DLL folder.';

{$REGION 'Dev note'}

(*******************************************************************************
  DEV NOTE – ARCHITECTURE & MECHANICS OF Edge.Audio

  This unit centralizes audio management for a Delphi application based on
  WebView2 (Edge Chromium), integrating with the VCL TEdgeBrowser UI component.

  The architecture is structured around three main building blocks:
    1. Audio capture (TEdgeAudioCapture): handles microphone state, capture,
       UI animation, and JS/web synchronization.
    2. Audio playback (TEdgeAudioPlayer & subcomponents): controls playback,
       volume, pause, seek, and advanced parameters (Talkover, VAD).
    3. Filtering/processing (THighPassFilter): dynamically manages the high-pass
       filter via JS injection.

  Communication between Delphi and JS is performed via TEdgeBrowser events,
  using JSON serialization for both downwards (Delphi → JS) and upwards (JS → Delphi)
  communication (audio, UI, feedback).

  WebView2 navigation is performed locally via a "virtual host" to avoid CORS restrictions
  and securely serve HTML/JS/CSS assets.

  Overall flow:
    ● Initialization: installs event handlers and navigates to the HTML index page.
    ● Capture and playback: controlled by Delphi via JS command injection.
    ● WebView2 events are routed to handlers which orchestrate business logic.
    ● Extension/evolution: interfaces IEdgeAudioCapture & IEdgeAudioPlayer are key extension points.

  ----------------------------------------------------------------------------
                         Architecture – Quick Diagram
  ----------------------------------------------------------------------------

  TEdgeAudio
      ├─ Capture : TEdgeAudioCapture
      │      ├─ StartCapture/StopCapture/AudioBlock/AnimStart...
      │      └─ (→ JS via JSExecute)
      │
      ├─ Player : TEdgeAudioPlayer
      │      ├─ Play/Pause/SeekTo/SetVolume/PlayAudio/Stop
      │      └─ (→ JS via JSExecute)
      │      ├─ TalkoverParams : TEdgeAudioPlayerTalkover
      │      └─ VADParams      : TEdgeAudioPlayerVAD
      │
      ├─ HighPassFilter : THighPassFilter
      │      └─ SetFrequency (→ JS via JSExecute)
      │
      ├─ Events : TEventEngineManager
      │      └─ AggregateAudioEvents(JSON)
      │
      └─ WebView2/JS Bridge
             ├─ OnWebMessageReceived → Parse/Route JSON events
             ├─ OnPermissionRequested → Microphone authorization
             └─ JSExecute() → Execute commands in browser

  General flow:
      [Delphi UI/Code] ↔ [TEdgeAudio] ↔ [WebView2/JS/HTML] ↔ [Audio Engine JS]

  ---------------------------------------------------------------------------
  Example of downward call:
      TEdgeAudio.Player.TalkoverParams.SetDurationMs
           └─ JSExecute('setTalkoverParams({ms: 1400})')

  ---------------------------------------------------------------------------


  +-----------------+
  | TEdgeAudio      |
  +-----------------+
      │
      ├── Capture          (TEdgeAudioCapture)
      │       └── [StartCapture, AudioBlock, ...]
      │
      ├── Player           (TEdgeAudioPlayer)
      │       ├─ TalkoverParams (TEdgeAudioPlayerTalkover)
      │       └─ VADParams      (TEdgeAudioPlayerVAD)
      │
      ├── HighPassFilter   (THighPassFilter)
      │
      └── JS/Browser Bridge (TEdgeBrowser/WebView2)
              └── [JSExecute, OnWebMessageReceived, ...]

*******************************************************************************)

{$ENDREGION}

function JsNumber(const A: Double): string;
begin
  var FS := TFormatSettings.Create;
  FS.DecimalSeparator := '.';
  Result := FormatFloat('0.##############', A, FS);
end;

{ TEdgeAudio }

constructor TEdgeAudio.Create(const AEdgeBrowser: TEdgeBrowser);
begin
  inherited Create;
  FEdgeBrowser := AEdgeBrowser;
  FHtmlIndex := HTML_INDEX;
  FAwaitingIndex := True;

  if csDesigning in FEdgeBrowser.ComponentState then
    Exit;

  {--- Set the default path to the web folder containing the HTML, JS, and CSS source files. }
  FWebPath := TAudioWeb.WebPath;

  {--- Create Audio capture. }
  FEdgeAudioCapture := TEdgeAudioCapture.Create(Self);

  {--- Create Audio player. }
  FEdgeAudioPlayer := TEdgeAudioPlayer.Create(Self);

  FWebRTC := TWebRTC.Create(Self);

  {--- Create Event manager. }
  FEventEngineManager := TEventEngineManager.Instance;

  if not FileExists('WebView2Loader.dll') then
    begin
      MessageDLG(DLL_ISSUE, TMsgDlgType.mtError, [mbOk], 0);
      Application.Terminate;
    end;

  FEdgeBrowser.OnCreateWebViewCompleted := EdgeBrowserCreateWebViewCompleted;
  FEdgeBrowser.OnPermissionRequested := EdgeBrowserPermissionRequested;
  FEdgeBrowser.OnWebMessageReceived := EdgeBrowserWebMessageReceived;
  FEdgeBrowser.OnNavigationCompleted := EdgeBrowserNavigationCompleted;
end;

procedure TEdgeAudio.EdgeBrowserCreateWebViewCompleted(
  Sender: TCustomEdgeBrowser; AResult: HRESULT);
begin
  {--- Checks that the WebView creation was successful and that the object is valid }
  if (AResult <> S_OK) or not FEdgeBrowser.WebViewCreated then Exit;

  if (csDesigning in FEdgeBrowser.ComponentState) then Exit;

  {--- If navigation is requested before the TabView is ready then the flag is consumed now. }
  if FPendingNavigate then
    begin
      FPendingNavigate := False;
      NavigateToIndex;
    end;
end;

procedure TEdgeAudio.EdgeBrowserNavigationCompleted(Sender: TCustomEdgeBrowser;
  IsSuccess: Boolean; WebErrorStatus: COREWEBVIEW2_WEB_ERROR_STATUS);
begin
  if not IsSuccess then Exit;

  {--- Trigger "ready" only once, on the first success after request }
  if FAwaitingIndex and not FIsReady then
    begin
      FIsReady := True;
      FAwaitingIndex := False;
      if Assigned(FOnWebReady) then
        FOnWebReady();
    end;
end;

procedure TEdgeAudio.EdgeBrowserPermissionRequested(Sender: TCustomEdgeBrowser;
  Args: TPermissionRequestedEventArgs);
var
  Kind: COREWEBVIEW2_PERMISSION_KIND;
begin
  {--- Retrieve the COM interface containing the permission request information }
  var Permissions := Args as ICoreWebView2PermissionRequestedEventArgs;

  {--- Check if the requested permission is for the microphone }
  var IsMicrophonePermission :=
    (Permissions.Get_PermissionKind(Kind) = S_OK) and
    (Kind = COREWEBVIEW2_PERMISSION_KIND_MICROPHONE);

  if IsMicrophonePermission then
    {--- If it is a request for access to the microphone → authorize }
    Permissions.Set_State(COREWEBVIEW2_PERMISSION_STATE_ALLOW)
  else
    {--- Otherwise → refuse all other permissions (camera, geolocation, etc.) }
    Permissions.Set_State(COREWEBVIEW2_PERMISSION_STATE_DENY);
end;

procedure TEdgeAudio.EdgeBrowserWebMessageReceived(Sender: TCustomEdgeBrowser;
  Args: TWebMessageReceivedEventArgs);
var
  rawJson : string;
  pMsg : PWideChar;
begin
  var WebArgs := Args.ArgsInterface as ICoreWebView2WebMessageReceivedEventArgs;

  {--- We ALWAYS get the JSON }
  if WebArgs.Get_WebMessageAsJson(pMsg) <> S_OK then
    Exit;

  try
    rawJson := pMsg;
  finally
    CoTaskMemFree(pMsg);
  end;

  {--- Raw trace to diagnose a problem }
  OutputDebugString(PChar('WEB:' + rawJson));

  {--- Parser object (also handles the "string containing a json" case) }
  FJsonObject := TAudioJSONData.ParseToObject(rawJson);
  if not Assigned(FJsonObject) then
    Exit;

  {--- Process JSON according to its event type }
  try
    if Assigned(FEventEngineManager) and not FEventEngineManager.AggregateAudioEvents(Self) then
      begin
        {--- Processing the rejected event, if necessary }

      end;
  finally
    FJsonObject.Free;
  end;
end;

function TEdgeAudio.GetAudioEndProc: TAudioEventProc;
begin
  Result := FAudioEndProc;
end;

function TEdgeAudio.GetAudioPlayProc: TAudioEventProc;
begin
  Result := FAudioPlayProc;
end;

function TEdgeAudio.GetBrowser: TEdgeBrowser;
begin
  Result := FEdgeBrowser;
end;

function TEdgeAudio.GetCloseClick: TAudioEventProc;
begin
  Result := FCloseClick;
end;

function TEdgeAudio.GetEdgeAudioCapture: IEdgeAudioCapture;
begin
  Result := FEdgeAudioCapture;
end;

function TEdgeAudio.GetEdgeAudioPlayer: IEdgeAudioPlayer;
begin
  Result := FEdgeAudioPlayer;
end;

function TEdgeAudio.GetHtmlIndex: string;
begin
  Result := FHtmlIndex;
end;

function TEdgeAudio.GetJsonObject: TJSONObject;
begin
  Result := FJsonObject;
end;

function TEdgeAudio.GetMicClick: TAudioStringEventProc;
begin
  Result := FMicClick;
end;

function TEdgeAudio.GetOnWebReady: TAudioEventProc;
begin
  Result := FOnWebReady;
end;

function TEdgeAudio.GetRealtimeClosed: TAudioEventProc;
begin
  Result := FRealtimeClosedProc;
end;

function TEdgeAudio.GetRealtimeConnected: TAudioEventProc;
begin
  Result := FRealtimeConnectedProc;
end;

function TEdgeAudio.GetRealtimeDataChannelClose: TAudioEventProc;
begin
  Result := FRealtimeDataChannelCloseProc;
end;

function TEdgeAudio.GetRealtimeDataChannelOpen: TAudioEventProc;
begin
  Result := FRealtimeDataChannelOpenProc;
end;

function TEdgeAudio.GetRealtimeEvent: TAudioJSONObjectProc;
begin
  Result := FRealtimeEventProc;
end;

function TEdgeAudio.GetRealtimeJsReady: TAudioEventProc;
begin
  Result := FRealtimeJsReadyProc;
end;

function TEdgeAudio.GetRealtimePcState: TAudioStringEventProc;
begin
  Result := FRealtimePcStateProc;
end;

function TEdgeAudio.GetRealtimeTrackAdded: TAudioEventProc;
begin
  Result := FRealtimeTrackAddedProc;
end;

function TEdgeAudio.GetWebPath: string;
begin
  Result := FWebPath;
end;

function TEdgeAudio.GetWebRTC: IWebRTC;
begin
  Result := FWebRTC;
end;

procedure TEdgeAudio.JSExecute(const Code: string);
begin
  if Assigned(FEdgeBrowser) and FEdgeBrowser.WebViewCreated then
    FEdgeBrowser.ExecuteScript(Code);
end;

procedure TEdgeAudio.Navigate;
begin
  if not (csDesigning in FEdgeBrowser.ComponentState) then
    begin
      FIsReady := False;
      FAwaitingIndex := True;
      FEdgeBrowser.Navigate('file:///' + TPath.Combine(ExpandFileName(WebPath), FHtmlIndex));
    end;
end;

procedure TEdgeAudio.NavigateToIndex;
var
  WebView3: ICoreWebView2_3;
begin
  if (csDesigning in FEdgeBrowser.ComponentState) then Exit;

  if not FEdgeBrowser.WebViewCreated then
  begin
    FPendingNavigate := True;
    Exit;
  end;

  FIsReady := False;
  FAwaitingIndex := True;
  FPendingNavigate := False;

  {--- Retrieving the local path containing the HTML/JS files }
  var Folder := WebPath;

  {--- Checks if the WebView interface supports ICoreWebView2_3 }
  if not Supports(FEdgeBrowser.DefaultInterface, ICoreWebView2_3, WebView3) then
    Exit;

  {--- Configures a "virtual host" that maps a secure local URL to the folder containing
         the files (e.g. HTML/JS/CSS resources). }
  if WebView3.SetVirtualHostNameToFolderMapping(
      VIRTUAL_HOST, PChar(Folder),
      COREWEBVIEW2_HOST_RESOURCE_ACCESS_KIND_ALLOW) = S_OK
    then
      {--- If mapping succeeds, navigate to the HTML index via https://localapp/
           (which avoids CORS restrictions and uses a secure context) }
      FEdgeBrowser.Navigate('file:///' + TPath.Combine(ExpandFileName(Folder), FHtmlIndex));
end;

procedure TEdgeAudio.SetAudioEndProc(const Value: TAudioEventProc);
begin
  FAudioEndProc := Value;
end;

procedure TEdgeAudio.SetAudioPlayProc(const Value: TAudioEventProc);
begin
  FAudioPlayProc := Value;
end;

procedure TEdgeAudio.SetCloseClick(const Value: TAudioEventProc);
begin
  FCloseClick := Value;
end;

procedure TEdgeAudio.SetHtmlIndex(const Value: string);
begin
  FHtmlIndex := Value;
end;

procedure TEdgeAudio.SetMicClick(const Value: TAudioStringEventProc);
begin
  FMicClick := Value;
end;

procedure TEdgeAudio.SetOnWebReady(const Value: TAudioEventProc);
begin
  FOnWebReady := Value;
  if Assigned(FOnWebReady) and FIsReady then
    FOnWebReady();
end;

procedure TEdgeAudio.SetRealtimeClosed(const Value: TAudioEventProc);
begin
  FRealtimeClosedProc := Value;
end;

procedure TEdgeAudio.SetRealtimeConnected(const Value: TAudioEventProc);
begin
  FRealtimeConnectedProc := Value;
end;

procedure TEdgeAudio.SetRealtimeDataChannelClose(const Value: TAudioEventProc);
begin
  FRealtimeDataChannelCloseProc := Value;
end;

procedure TEdgeAudio.SetRealtimeDataChannelOpen(const Value: TAudioEventProc);
begin
  FRealtimeDataChannelOpenProc := Value;
end;

procedure TEdgeAudio.SetRealtimeEvent(const Value: TAudioJSONObjectProc);
begin
  FRealtimeEventProc := Value;
end;

procedure TEdgeAudio.SetRealtimeJsReady(const Value: TAudioEventProc);
begin
  FRealtimeJsReadyProc := Value;
end;

procedure TEdgeAudio.SetRealtimePcState(const Value: TAudioStringEventProc);
begin
  FRealtimePcStateProc := Value;
end;

procedure TEdgeAudio.SetRealtimeTrackAdded(const Value: TAudioEventProc);
begin
  FRealtimeTrackAddedProc := Value;
end;

procedure TEdgeAudio.SetWebPath(const Value: string);
begin
  FWebPath := Value;
end;

procedure TEdgeAudio.SetWebRTC(const Value: IWebRTC);
begin
  FWebRTC := Value;
end;

procedure TEdgeAudio.DisableCaptureOnSpeech(const Value: Boolean);
begin
  JSExecute(Format('window.autoBlockCaptureDuringPlayback = %s;',
                   [ IfThen(Value, 'true', 'false') ])
  );
end;

procedure TEdgeAudio.DisplayError(const Value: string;
  const DurationMs: Integer);
begin
  JSExecute(TAudioScript.ShowToast(Value, DurationMs));
end;

procedure TEdgeAudio.DoOnException(Sender: TObject; E: Exception);
begin
  DisplayError(E.Message);
end;

{ TEdgeAudioCapture }

constructor TEdgeAudioCapture.Create(const AOwner: TEdgeAudio);
begin
  inherited Create;
  FOwner := AOwner;
end;

function TEdgeAudioCapture.GetProcessOnAudio: Boolean;
begin
  Result := FProcessOnAudio;
end;

procedure TEdgeAudioCapture.MicOff;
begin
  FOwner.JSExecute('if (!blockAudioSend) toggleMic();');
end;

procedure TEdgeAudioCapture.MicOn;
begin
  FOwner.JSExecute('if (blockAudioSend) toggleMic();');
end;

procedure TEdgeAudioCapture.MicToggle;
begin
  FOwner.JSExecute('toggleMic();');
end;

procedure TEdgeAudioCapture.SetProcessOnAudio(const Value: Boolean);
begin
  FProcessOnAudio := Value;
end;

procedure TEdgeAudioCapture.StartCapture;
begin
  FOwner.JSExecute('startCapture();');
end;

{ TEdgeAudioPlayer }

constructor TEdgeAudioPlayer.Create(const AOwner: TEdgeAudio);
begin
  inherited Create;
  FOwner := AOwner;
end;

function TEdgeAudioPlayer.GetIsPlaying: Boolean;
begin
  Result := FIsPlaying;
end;

procedure TEdgeAudioPlayer.SetIsPlaying(const Value: Boolean);
begin
  FIsPlaying := Value;
end;

procedure TEdgeAudioPlayer.SetVolume(const Value: Double);
begin
  FOwner.JSExecute(Format('setVolume(%s);', [JsNumber(Value)]));
end;

procedure TEdgeAudioPlayer.Stop;
begin
  FOwner.JSExecute('stopAudio();');
end;

{ TWebRTC }

constructor TWebRTC.Create(const AOwner: TEdgeAudio);
begin
  inherited Create;
  FOwner := AOwner;
end;

procedure TWebRTC.Send(const Body: string);
begin
  FOwner.JSExecute('window.RT.sendEvent(JSON.stringify('+ Body + '));');
end;

end.
