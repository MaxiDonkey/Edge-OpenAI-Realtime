unit Edge.WebRTC.Adapter;

interface

uses
  System.SysUtils, System.Classes, System.JSON, System.StrUtils,
  WebRTC.Core, Edge.Audio.Interfaces, Audio.Web.Assets;

const
  DEFAULT_DC = 'oai-events';

type
  TEdgePeer = class(TInterfacedObject, IPeerConnection, IPageOffer)
  private
    FAudio: IEdgeAudio;
    FSink: IPeerEvents;
    FDCOpen: Boolean;
    FDefaultDC: IDataChannel;
    procedure JS(const Code: string);
    procedure Hook;
  public
    constructor Create(const AAudio: IEdgeAudio);

    procedure SetEvents(const Sink: IPeerEvents);
    function  CreateDataChannel(const ALabel: string): IDataChannel;

    function TryCreateOffer(out Sdp: string): Boolean;
    procedure SetLocalDescription(const Sdp: string; const Kind: string = 'offer');
    procedure SetRemoteDescription(const Sdp: string; const Kind: string = 'answer');
    procedure AddIceCandidate(const CandidateLine, SdpMid: string; SdpMLineIndex: Integer);

    procedure AttachLocalMicrophone;
    procedure DetachLocalMicrophone;

    function DataChannel: IDataChannel;

    procedure Close;

    function ConnectInPage(const Url, Bearer: string): Boolean;
  end;

  TEdgeWebRTCFactory = class(TInterfacedObject, IWebRTCFactory)
  private
    FAudio: IEdgeAudio;
  public
    constructor Create(const A: IEdgeAudio);
    function CreatePeer(const Options: IInterface = nil): IPeerConnection;
  end;

implementation

type
  /// <summary>
  /// DataChannel trivial facade
  /// </summary>
  /// <remarks>
  /// We go through RT.sendEvent on the JS side (text/binary if necessary)
  /// </remarks>
  TEdgeDataChannel = class(TInterfacedObject, IDataChannel)
  private
    FAudio: IEdgeAudio;
    FLabel: string;
    FPeer: TEdgePeer;
  public
    constructor Create(const AAudio: IEdgeAudio; const ALabel: string; const APeer: TEdgePeer);
    function Label_: string;
    function ReadyState: string;
    procedure Send(const Text: string); overload;
    procedure Send(const Bytes: TBytes); overload;
    procedure Close;
  end;

{ TEdgePeer }

constructor TEdgePeer.Create(const AAudio: IEdgeAudio);
begin
  inherited Create;
  FAudio := AAudio;
  Hook;
end;

procedure TEdgePeer.Hook;
begin
  {--- Mapping all your existing events to IPeerEvents }
  FAudio.RealtimeConnectedProc :=
    procedure
    begin
      if Assigned(FSink) then
        FSink.OnConnected;
    end;

  FAudio.RealtimeClosedProc :=
    procedure
    begin
      if Assigned(FSink) then
        FSink.OnClosed;
    end;

  FAudio.RealtimePcStateProc :=
    procedure (S: string)
    begin
      if Assigned(FSink) then FSink.OnStateChange(S);
    end;

  FAudio.RealtimeDataChannelOpenProc :=
    procedure
    begin
      FDCOpen := True;
      var channel := TEdgeDataChannel.Create(FAudio, DEFAULT_DC, Self);
      if FDefaultDC = nil then
        FDefaultDC := channel;
      if Assigned(FSink) then
        FSink.OnDataChannel(channel);
    end;

  FAudio.RealtimeDataChannelCloseProc :=
    procedure
    begin
      FDCOpen := False;
      FDefaultDC := nil;
      if Assigned(FSink) then
        FSink.OnClosed;
      end;

  FAudio.RealtimeTrackAddedProc :=
    procedure
    begin
      if Assigned(FSink) then
        FSink.OnRemoteAudioTrack;
    end;

  {--- If we want to route RT._onDCMessage → OnMessageText on the app side,
       we use RealtimeEventProc (oai_event): giving the app the freedom to (de)serialize. }
end;

procedure TEdgePeer.JS(const Code: string);
begin
  FAudio.EdgeBrowser.ExecuteScript(Code);
end;

procedure TEdgePeer.SetEvents(const Sink: IPeerEvents);
begin
  FSink := Sink;
end;

function TEdgePeer.CreateDataChannel(const ALabel: string): IDataChannel;
begin
  var JCode :=
    '''
      try {
        RT && RT.createDataChannel(%s);
      } catch (e) {
        chrome?.webview?.postMessage?.({
          event: "rt_error",
          message: String(e)
        });
      }
    ''';
  JS(Format(JCode, [JsonQuoted(ALabel)]));

  Result := TEdgeDataChannel.Create(FAudio, ALabel, Self);
  if (FDefaultDC = nil) and SameText(ALabel, DEFAULT_DC) then
    FDefaultDC := Result;
end;

procedure TEdgePeer.SetLocalDescription(const Sdp, Kind: string);
begin
  {--- Kind = 'offer' | 'answer' }
  var JCode :=
    '''
      try {
        RT && RT.setRemoteDescription(%s, %s);
      } catch (e) {
        chrome?.webview?.postMessage?.({
          event: "rt_error",
          message: String(e)
        });
      }
    ''';
  JS(Format(JCode, [JsonQuoted(Kind), JsonQuoted(Sdp)]));
end;

procedure TEdgePeer.SetRemoteDescription(const Sdp, Kind: string);
begin
  {--- Kind = 'answer' | 'offer' (according to the scenario) }
  var JCode :=
    '''
      try {
        RT && RT.setRemoteDescription(%s, %s);
      } catch (e) {
        chrome?.webview?.postMessage?.({
          event: "rt_error",
          message: String(e)
        });
      }
    ''';
  JS(Format(JCode, [JsonQuoted(Kind), JsonQuoted(Sdp)]));
end;

function TEdgePeer.TryCreateOffer(out Sdp: string): Boolean;
begin
  Sdp := '';
  Result := False;
end;

procedure TEdgePeer.AddIceCandidate(const CandidateLine, SdpMid: string; SdpMLineIndex: Integer);
begin
  var JCode :=
    '''
      try {
        RT && RT.addIceCandidate(%s, %s, %d);
      } catch (e) {
        chrome?.webview?.postMessage?.({
          event: "rt_error",
          message: String(e)
        });
      }
    ''';

  JS(Format(JCode, [JsonQuoted(CandidateLine), JsonQuoted(SdpMid), SdpMLineIndex]));
end;

procedure TEdgePeer.AttachLocalMicrophone;
begin
  JS(
    '''
      try {
        RT && RT.attachLocalMicrophone && RT.attachLocalMicrophone();
      } catch (e) {
        chrome?.webview?.postMessage?.({
          event: "rt_error",
          message: String(e)
        });
      }
    '''
  );
end;

function TEdgePeer.DataChannel: IDataChannel;
begin
  Result := FDefaultDC;
end;

procedure TEdgePeer.DetachLocalMicrophone;
begin
  JS(
    '''
      try {
        RT && RT.micOff && RT.micOff();
      } catch (e) {
        chrome?.webview?.postMessage?.({
          event: "rt_error",
          message: String(e)
        });
      }
    '''
  );
end;

procedure TEdgePeer.Close;
begin
  FDefaultDC := nil;
  JS(
    '''
      try {
        RT && RT.close && RT.close();
      } catch (e) {
        chrome?.webview?.postMessage?.({
          event: "rt_error",
          message: String(e)
        });
      }
    '''
  );
end;

function TEdgePeer.ConnectInPage(const Url, Bearer: string): Boolean;
begin
  {--- We assume the page is already loaded.
       We delegate everything to RT.init/connect on the JS side }
  var JCode :=
     '''
       try {
         if (window.RT) {
           RT.setAudioElement("player");
           RT.init(%s, %s);
           RT.connect();
         }
       } catch (e) {
         chrome?.webview?.postMessage?.({
           event: "audio_error",
           message: String(e)
         });
       }
     ''';
  JS(Format(JCode, [JsonQuoted(Url), JsonQuoted(Bearer)]));
  Result := True;
end;

{ TEdgeWebRTCFactory }

constructor TEdgeWebRTCFactory.Create(const A: IEdgeAudio);
begin
  inherited Create;
  FAudio := A;
end;

function TEdgeWebRTCFactory.CreatePeer(const Options: IInterface): IPeerConnection;
begin
  Result := TEdgePeer.Create(FAudio);
end;

{ TEdgeDataChannel }

constructor TEdgeDataChannel.Create(const AAudio: IEdgeAudio; const ALabel: string; const APeer: TEdgePeer);
begin
  inherited Create;
  FAudio := AAudio;
  FLabel := ALabel;
  FPeer := APeer;
end;

procedure TEdgeDataChannel.Close;
begin
  var JCode :=
     '''
       try {
         RT && RT.closeDataChannel && RT.closeDataChannel(%s);
       } catch (e) {
         chrome?.webview?.postMessage?.({
           event: "rt_error",
           message: String(e)
         });
       }
     ''';
   FAudio.EdgeBrowser.ExecuteScript(Format(JCode, [JsonQuoted(FLabel)]));
end;

function TEdgeDataChannel.Label_: string;
begin
  Result := FLabel;
end;

function TEdgeDataChannel.ReadyState: string;
begin
  Result := IfThen(FPeer.FDCOpen, 'open', 'closed');
end;

procedure TEdgeDataChannel.Send(const Text: string);
begin
  var JCode :=
    '''
      try {
        RT && RT.sendEvent && RT.sendEvent(%s);
      } catch (e) {
        chrome?.webview?.postMessage?.({
          event: "rt_error",
          message: String(e)
        });
      }
    ''';
  FAudio.EdgeBrowser.ExecuteScript(Format(JCode, [JsonQuoted(Text)]));
end;

procedure TEdgeDataChannel.Send(const Bytes: TBytes);
begin
  {--- Option if we want binary → base64 + JS side atob/Uint8Array + dc.send
       Not relevant in this case. }
end;

end.

