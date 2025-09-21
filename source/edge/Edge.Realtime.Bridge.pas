unit Edge.Realtime.Bridge;

interface

uses
  System.SysUtils, System.JSON,
  Vcl.Edge,
  Edge.Audio.Interfaces, Edge.Audio2,
  WebRTC.Core, Edge.WebRTC.Adapter, Audio.Web.Assets;

type
  TBasicProc = reference to procedure;
  TProcStr = reference to procedure(S: string);
  TProcJSON = reference to procedure(Data: TJSONObject);
  TProcDC = reference to procedure(DC: IDataChannel);
  TSignalFn = reference to function (Url, Bearer, OfferSdp: string): string;

  /// <summary>
  /// Lightweight facade to drive WebRTC Realtime on the Edge/WebView2 side
  /// </summary>
  TEdgeRealtimeWire = class(TInterfacedObject)
  private
    FAudio: IEdgeAudio;
    FFactory: IWebRTCFactory;
    FPeer: IPeerConnection;
    FDC: IDataChannel;
    FSignal  : TSignalFn;

    FOnConnected     : TBasicProc;
    FOnClosed        : TBasicProc;
    FOnPcState       : TProcStr;
    FOnRemoteAudio   : TBasicProc;
    FOnError         : TProcStr;
    FOnDataChannel   : TProcDC;
    FOnOaiEvent      : TProcJSON;

    procedure AttachOaiEvent;
    procedure ExecJS(const Code: string);
  public
    /// <summary>
    /// Created with factory injected (mockable). If Factory = nil, use TEdgeWebRTCFactory.
    /// </summary>
    constructor Create(const Browser: TEdgeBrowser; const Factory: IWebRTCFactory = nil);

    /// <summary>
    /// Navigation + auto-start when the page is ready
    /// </summary>
    procedure Boot(const WebPath, Url, Bearer: string;
      const WhenReadyProc: TProc;
      const Signal: TSignalFn = nil);

    /// <summary>
    /// Navigates the embedded browser to the specified web path.
    /// </summary>
    procedure Navigate(const WebPath: string);

    /// <summary>
    /// Run RT.init + RT.connect (the JS page remains the master of the SDP)
    /// </summary>
    procedure Start(const Url, Bearer: string; const Signal: TSignalFn = nil);

    /// <summary>
    /// Send via DataChannel (direct JS fallback if FDC not yet ready)
    /// </summary>
    procedure Send(Json: string);

    /// <summary>
    /// Closes the peer/page properly
    /// </summary>
    procedure Close;

    /// <summary>
    /// Provides access to the Edge audio subsystem associated with the current WebRTC session.
    /// </summary>
    /// <remarks>
    /// This property exposes the <see cref="IEdgeAudio"/> interface, allowing direct control of audio capture,
    /// playback, and advanced features such as speech detection, mute, and device selection.
    /// </remarks>
    property Audio: IEdgeAudio read FAudio;

    /// <summary>
    /// Provides direct access to the underlying WebRTC data channel used for realtime messaging.
    /// </summary>
    /// <remarks>
    /// This property exposes the <see cref="IDataChannel"/> interface, which enables low-latency,
    /// bidirectional data transfer between peers. Use this property for advanced scenarios
    /// where you need to interact with the data channel directly (for example, for custom protocols,
    /// file transfer, or signaling).
    /// </remarks>
    property DataChannel: IDataChannel read FDC;

    /// <summary>
    /// Gets or sets the signaling function used for exchanging SDP offers and answers during WebRTC negotiation.
    /// </summary>
    /// <remarks>
    /// This delegate is invoked to perform the signaling step between peers, typically by sending an SDP offer
    /// (and optionally a bearer token) to a remote endpoint and receiving the corresponding SDP answer.
    /// You can assign a custom function to integrate with your own signaling backend (e.g., HTTP, WebSocket, etc.).
    /// </remarks>
    property SignalFn: TSignalFn read FSignal write FSignal;

    /// <summary>
    /// Event triggered when the WebRTC peer connection is successfully established.
    /// </summary>
    property OnConnected: TBasicProc read FOnConnected write FOnConnected;

    /// <summary>
    /// Event triggered when the WebRTC peer connection is closed or disconnected.
    /// </summary>
    property OnClosed: TBasicProc read FOnClosed write FOnClosed;

    /// <summary>
    /// Event triggered whenever the state of the WebRTC peer connection changes.
    /// </summary>
    property OnPcState: TProcStr read FOnPcState write FOnPcState;

    /// <summary>
    /// Event triggered when a remote audio track is received from the peer connection.
    /// </summary>
    property OnRemoteAudioTrack: TBasicProc  read FOnRemoteAudio   write FOnRemoteAudio;

    /// <summary>
    /// Event triggered when an error occurs during the WebRTC session or signaling process.
    /// </summary>
    property OnError: TProcStr read FOnError write FOnError;

    /// <summary>
    /// Event triggered when a new data channel is opened on the peer connection.
    /// </summary>
    property OnDataChannel: TProcDC read FOnDataChannel write FOnDataChannel;

    /// <summary>
    /// Event triggered when a realtime JSON event is received from the underlying audio or WebRTC subsystem.
    /// </summary>
    property OnOaiEvent: TProcJSON read FOnOaiEvent write FOnOaiEvent;
  end;

implementation

type
  /// <summary>
  /// Internal sink that adapts IPeerEvents -> TEdgeRealtimeWire callbacks
  /// </summary>
  TWireSink = class(TInterfacedObject, IPeerEvents)
  private
    OW: TEdgeRealtimeWire;
  public
    constructor Create(AOwner: TEdgeRealtimeWire);
    procedure OnConnected;
    procedure OnClosed;
    procedure OnStateChange(const State: string);
    procedure OnIceCandidate(const CandidateLine, SdpMid: string; SdpMLineIndex: Integer);
    procedure OnDataChannel(const Ch: IDataChannel);
    procedure OnRemoteAudioTrack;
    procedure OnError(const MessageText: string);
  end;

{ TWireSink }

constructor TWireSink.Create(AOwner: TEdgeRealtimeWire);
begin
  inherited Create;
  OW := AOwner;
end;

procedure TWireSink.OnConnected;
begin
  if Assigned(OW.FOnConnected) then OW.FOnConnected();
end;

procedure TWireSink.OnClosed;
begin
  if Assigned(OW.FOnClosed) then OW.FOnClosed();
end;

procedure TWireSink.OnStateChange(const State: string);
begin
  if Assigned(OW.FOnPcState) then OW.FOnPcState(State);
end;

procedure TWireSink.OnIceCandidate(const CandidateLine, SdpMid: string; SdpMLineIndex: Integer);
begin
  {--- Not used in the flow (RT.connect handles SDP + ICE on the JS side) }
end;

procedure TWireSink.OnDataChannel(const Ch: IDataChannel);
begin
  OW.FDC := Ch;
  if Assigned(OW.FOnDataChannel) then OW.FOnDataChannel(Ch);
end;

procedure TWireSink.OnRemoteAudioTrack;
begin
  if Assigned(OW.FOnRemoteAudio) then OW.FOnRemoteAudio();
end;

procedure TWireSink.OnError(const MessageText: string);
begin
  if Assigned(OW.FOnError) then OW.FOnError(MessageText);
end;

{ TEdgeRealtimeWire }

constructor TEdgeRealtimeWire.Create(const Browser: TEdgeBrowser; const Factory: IWebRTCFactory);
begin
  inherited Create;
  {--- EdgeAudio Pack }
  FAudio := TEdgeAudio.Create(Browser);

  {--- Factory injectable }
  if Assigned(Factory) then
    FFactory := Factory
  else
    FFactory := TEdgeWebRTCFactory.Create(FAudio);

  {--- Peer + sink }
  FPeer := FFactory.CreatePeer(nil);
  FPeer.SetEvents(TWireSink.Create(Self));

  AttachOaiEvent;
end;

procedure TEdgeRealtimeWire.AttachOaiEvent;
begin
  {--- Raw pass-through from oai_event (Realtime JSON) to OnOaiEvent (if used) }
  FAudio.RealtimeEventProc :=
    procedure (Data: TJSONObject)
    begin
      if Assigned(FOnOaiEvent) then FOnOaiEvent(Data);
    end;
end;

procedure TEdgeRealtimeWire.Boot(const WebPath, Url, Bearer: string;
  const WhenReadyProc: TProc;
  const Signal: TSignalFn);
begin
  if Assigned(Signal) then
    FSignal := Signal;

  FAudio.OnWebReady :=
    procedure
    begin
      FAudio.DisableCaptureOnSpeech(True);
      if Assigned(WhenReadyProc) then
        WhenReadyProc();
      Start(Url, Bearer, FSignal);
    end;

  Navigate(WebPath);
end;

procedure TEdgeRealtimeWire.Navigate(const WebPath: string);
begin
  FAudio.WebPath := WebPath;
  FAudio.Navigate;
end;

procedure TEdgeRealtimeWire.ExecJS(const Code: string);
begin
  FAudio.EdgeBrowser.ExecuteScript(Code);
end;

procedure TEdgeRealtimeWire.Start(const Url, Bearer: string; const Signal: TSignalFn);
var
  Page : IPageOffer;
  Offer: string;
  Ans  : string;
begin
  if Assigned(Signal) then FSignal := Signal;

  {--- Path A: The page does the negotiating }
  if Supports(FPeer, IPageOffer, Page) then
    begin
      Page.ConnectInPage(Url, Bearer);
      Exit;
    end;

  {--- Path B: fallback host-offer (native/third-party WebRTC impl) }
  if not Assigned(FSignal) then
    raise Exception.Create('No signaling function provided for host-side SDP negotiation.');

  FPeer.AttachLocalMicrophone;

  if FPeer.TryCreateOffer(Offer) then
    begin
      FPeer.SetLocalDescription(Offer, 'offer');

      {--- POST offer → returns the SDP answer }
      Ans := FSignal(Url, Bearer, Offer);

      FPeer.SetRemoteDescription(Ans, 'answer');
    end
  else
    begin
      {--- Neither in-page nor host-offer → clearly indicated }
      if Assigned(FOnError) then
        FOnError('This adapter cannot create offers (no in-page and no host-side offer).')
      else
        raise ENotImplemented.Create('This adapter cannot create offers (no in-page and no host-side offer).');
    end;
end;

procedure TEdgeRealtimeWire.Send(Json: string);
begin
  if Assigned(FDC) then
    begin
      FDC.Send(Json)
    end
  else
    {--- Immediate fallback (if DC not yet “open”) — not blocking }
    begin
      var JCode :=
        '''
          try {
            window.RT && RT.sendEvent && RT.sendEvent(%s);
          } catch (e) {}
        ''';
      ExecJS(Format(JCode, [JsonQuoted(Json)]));
    end;
end;

procedure TEdgeRealtimeWire.Close;
begin
  if Assigned(FPeer) then FPeer.Close;
end;

end.

