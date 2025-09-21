unit Edge.Audio.Events2;

interface

uses
  Winapi.Windows,
  System.SysUtils, System.Classes, System.JSON, System.IOUtils,
  System.NetEncoding, System.Net.HttpClient, System.Net.HttpClientComponent,
  Edge.Audio.Interfaces;

type
  {$REGION 'Types and enumeration'}

  TAudioEventKind = (
    mic_button_clicked,
    close_click,
    audio_active,
    audio_inactive,
    audio_ended,
    // WebRTC/Realtime locals
    rt_js_ready,
    rt_connected,
    rt_closed,
    rt_pc_state,
    rt_dc_open,
    rt_dc_close,
    rt_track_added,
    rt_event_sent,
    rt_error,
    oai_event,
    // Ignored
    rt_info,
    rt_debug,
    rt_mic_attached,
    audio_waiting,
    audio_stalled,
    audio_track_muted,
    audio_track_unmuted,
    audio_track_ended,
    audio_capture_started,
    audio_error,
    audio_warn,
    audio_capture_stopped,
    audio_vad_params,
    audio_autoplay_blocked
  );

  TAudioEventKindHelper = record Helper for TAudioEventKind
  const
    AudioEventNames: array[TAudioEventKind] of string = (
      'mic_button_clicked',
      'close_click',
      'audio_active',
      'audio_inactive',
      'audio_ended',
      // WebRTC/Realtime locals
      'rt_js_ready',
      'rt_connected',
      'rt_closed',
      'rt_pc_state',
      'rt_dc_open',
      'rt_dc_close',
      'rt_track_added',
      'rt_event_sent',
      'rt_error',
      'oai_event',
      //Ignored
      'rt_info',
      'rt_debug',
      'rt_mic_attached',
      'audio_waiting',
      'audio_stalled',
      'audio_track_muted',
      'audio_track_unmuted',
      'audio_track_ended',
      'audio_capture_started',
      'audio_error',
      'audio_warn',
      'audio_capture_stopped',
      'audio_vad_params',
      'audio_autoplay_blocked'
    );
    class function TryParse(const S: string; out Value: TAudioEventKind): Boolean; static;
    class function Parse(const S: string): TAudioEventKind; static;
    function ToString: string;
  end;

  {$ENDREGION}

  {$REGION 'Interfaces'}

  IAudioEventHandler = interface
    function CanHandle(EventKind: TAudioEventKind): Boolean;

    function Handle(const EdgeAudio: IEdgeAudio): Boolean;
  end;

  IAudioEventEngineManager = interface
    ['{75E613F7-B1E7-4B4B-B897-B1EC11CEA4C6}']
    function AggregateAudioEvents(const EdgeAudio: IEdgeAudio): Boolean;
  end;

  {$ENDREGION}

  {$REGION 'Execution engine'}

  TEventExecutionEngine = class
  private
    FHandlers: TArray<IAudioEventHandler>;
  public
    procedure RegisterHandler(AHandler: IAudioEventHandler);
    function AggregateAudioEvents(const EdgeAudio: IEdgeAudio): Boolean;
  end;

  TEventEngineManager = class(TInterfacedObject, IAudioEventEngineManager)
   private
    class var FInstance: TEventEngineManager;
    FEngine: TEventExecutionEngine;
    procedure EventExecutionEngineInitialize;
  public
    constructor Create;
    class function Instance: IAudioEventEngineManager; static;
    function AggregateAudioEvents(const EdgeAudio: IEdgeAudio): Boolean;
    destructor Destroy; override;
  end;

  {$ENDREGION}

  {$REGION 'Audio capture'}

  TMicButtonClicked = class(TInterfacedObject, IAudioEventHandler)
    function CanHandle(EventKind: TAudioEventKind): Boolean;

    function Handle(const EdgeAudio: IEdgeAudio): Boolean;
  end;

  TCloseClick = class(TInterfacedObject, IAudioEventHandler)
    function CanHandle(EventKind: TAudioEventKind): Boolean;

    function Handle(const EdgeAudio: IEdgeAudio): Boolean;
  end;

  {$ENDREGION}

  {$REGION 'Audio player'}

  TAudioActive = class(TInterfacedObject, IAudioEventHandler)
    function CanHandle(EventKind: TAudioEventKind): Boolean;

    function Handle(const EdgeAudio: IEdgeAudio): Boolean;
  end;

  TAudioInactive = class(TInterfacedObject, IAudioEventHandler)
    function CanHandle(EventKind: TAudioEventKind): Boolean;

    function Handle(const EdgeAudio: IEdgeAudio): Boolean;
  end;

  TAudioEnded = class(TInterfacedObject, IAudioEventHandler)
    function CanHandle(EventKind: TAudioEventKind): Boolean;

    function Handle(const EdgeAudio: IEdgeAudio): Boolean;
  end;

  {$ENDREGION}

  {$REGION 'realtime-webrtc-globals'}

  TRtJsReady = class(TInterfacedObject, IAudioEventHandler)
    function CanHandle(EventKind: TAudioEventKind): Boolean;

    function Handle(const EdgeAudio: IEdgeAudio): Boolean;
  end;

  TRtConnected = class(TInterfacedObject, IAudioEventHandler)
    function CanHandle(EventKind: TAudioEventKind): Boolean;

    function Handle(const EdgeAudio: IEdgeAudio): Boolean;
  end;

  TRtClosed = class(TInterfacedObject, IAudioEventHandler)
    function CanHandle(EventKind: TAudioEventKind): Boolean;

    function Handle(const EdgeAudio: IEdgeAudio): Boolean;
  end;

  TRtDcOpen = class(TInterfacedObject, IAudioEventHandler)
    function CanHandle(EventKind: TAudioEventKind): Boolean;

    function Handle(const EdgeAudio: IEdgeAudio): Boolean;
  end;

  TRtDcClose = class(TInterfacedObject, IAudioEventHandler)
    function CanHandle(EventKind: TAudioEventKind): Boolean;

    function Handle(const EdgeAudio: IEdgeAudio): Boolean;
  end;

  TRtTrackAdded = class(TInterfacedObject, IAudioEventHandler)
    function CanHandle(EventKind: TAudioEventKind): Boolean;

    function Handle(const EdgeAudio: IEdgeAudio): Boolean;
  end;

  TRtPcState = class(TInterfacedObject, IAudioEventHandler)
    function CanHandle(EventKind: TAudioEventKind): Boolean;

    function Handle(const EdgeAudio: IEdgeAudio): Boolean;
  end;

  TRtError = class(TInterfacedObject, IAudioEventHandler)
    function CanHandle(EventKind: TAudioEventKind): Boolean;

    function Handle(const EdgeAudio: IEdgeAudio): Boolean;
  end;

  TOaiEvent = class(TInterfacedObject, IAudioEventHandler)
    function CanHandle(EventKind: TAudioEventKind): Boolean;

    function Handle(const EdgeAudio: IEdgeAudio): Boolean;
  end;

  TRtEventSent = class(TInterfacedObject, IAudioEventHandler)
    function CanHandle(EventKind: TAudioEventKind): Boolean;

    function Handle(const EdgeAudio: IEdgeAudio): Boolean;
  end;

  {$ENDREGION}

implementation

{$REGION 'Dev note'}

(******************************************************************************
  DEV NOTE – ARCHITECTURE & MECHANICS OF Edge.Audio.Events

  This unit implements an extensible audio event engine for the Edge audio pipeline.
  It manages the routing and handling of asynchronous events from the JS/WebView2
  frontend to Delphi-side handlers (for capture, playback, interruption, etc.).

  MECHANICS:
    ● Each incoming JSON event includes a typed "event" field (TAudioEventKind).
    ● A central engine (TEventEngineManager) aggregates and routes events
      (AggregateAudioEvents), dispatching each message to the matching handler
      using the "CanHandle/Handle" pattern.
    ● Handlers (classes implementing IAudioEventHandler) perform the business logic:
      saving audio segments, triggering callbacks, updating UI, etc.
    ● The design ensures that unknown/unhandled events never block the pipeline,
      except for explicit errors.


  --------------------------------------------------------------------------
                          ARCHITECTURE DIAGRAM
  --------------------------------------------------------------------------

  +-------------------------+
  | TEventEngineManager     |        // Singleton
  +-------------------------+
            │
            │ owns
            ▼
    +-----------------------+
    | TEventExecutionEngine |
    +-----------------------+
            │
            │ contains
            ▼
      +-----------------------------+
      | [IAudioEventHandler array]  |  (TMicButtonClicked, TAudioSegment, ...)
      +-----------------------------+
            │
            │ Handle(EventKind) via "CanHandle"
            ▼
      +-----------------------+
      | Application Logic     |  (EdgeAudio callbacks, save segment, etc)
      +-----------------------+


  --------------------------------------------------------------------------
                   FUNCTIONAL FLOW DIAGRAM (main flow)
  --------------------------------------------------------------------------

  EdgeAudio.Events.AggregateAudioEvents
          │
          └───► Parse JSON → event : string → TAudioEventKind
                    │
                    └───► TEventExecutionEngine.AggregateAudioEvents
                                │
                                └───► For each handler:
                                            ├─ .CanHandle(event)? yes → .Handle(...)
                                            └─ else, next
                                │
                                └───► If no handler: ignore by default
                                        If error: DisplayError()
  --------------------------------------------------------------------------
  Extension points:
    - To add a new event: implement IAudioEventHandler and register it.
    - No changes required in the engine itself.

******************************************************************************)


{$ENDREGION}

{ TAudioEventKindHelper }

class function TAudioEventKindHelper.Parse(const S: string): TAudioEventKind;
begin
  if not TryParse(S, Result) then
    raise EConvertError.CreateFmt('Unknown audio event kind: %s', [S]);
end;

function TAudioEventKindHelper.ToString: string;
begin
  Result := AudioEventNames[Self];
end;

class function TAudioEventKindHelper.TryParse(const S: string;
  out Value: TAudioEventKind): Boolean;
begin
  for var Item := Low(TAudioEventKind) to High(TAudioEventKind) do
    if SameText(S, AudioEventNames[Item]) then
      begin
        Value := Item;
        Exit(True);
      end;
  Result := False;
end;

{ TEventExecutionEngine }

function TEventExecutionEngine.AggregateAudioEvents(
  const EdgeAudio: IEdgeAudio): Boolean;
begin
  try
    var EventKind := TAudioEventKind.Parse(EdgeAudio.JsonObject.GetValue<string>('event', ''));

    for var Item in FHandlers do
      if Item.CanHandle(EventKind) then
        begin
          Exit(Item.Handle(EdgeAudio));
        end;

    {$REGION 'Dev note'}
     (*
       Not finding a matching event should not, on its own, cause Result to become false.
       It should only be set to false  when an error event is encountered. Otherwise, the
       process would  automatically fail whenever introduced a new event  that we haven’t
       yet defined.
     *)
     {$ENDREGION}

    Result := True;
  except
    on E: exception do
      begin
        var Error := AcquireExceptionObject;
        try
          Result := False;
          var ErrorMsg := (Error as Exception).Message;
          EdgeAudio.DisplayError(ErrorMsg);
        finally
          Error.Free;
        end;
      end;
  end;
end;

procedure TEventExecutionEngine.RegisterHandler(AHandler: IAudioEventHandler);
begin
  FHandlers := FHandlers + [AHandler];
end;

{ TEventEngineManager }

function TEventEngineManager.AggregateAudioEvents(
  const EdgeAudio: IEdgeAudio): Boolean;
begin
  var eventName := EdgeAudio.JsonObject.GetValue<string>('event', '');
  if not (eventName.StartsWith('audio_') or eventName.StartsWith('rt_') or
         (eventName = 'oai_event') or (eventName = 'mic_button_clicked') or
         (eventName = 'close_click')) then
    Exit(True);

  Result := FEngine.AggregateAudioEvents(EdgeAudio);
end;

constructor TEventEngineManager.Create;
begin
  inherited Create;
  EventExecutionEngineInitialize;
end;

destructor TEventEngineManager.Destroy;
begin
  FEngine.Free;
  if Self = FInstance then
    FInstance := nil;
  inherited;
end;

procedure TEventEngineManager.EventExecutionEngineInitialize;
begin
  {--- NOTE: TEventEngineManager is a singleton }
  FEngine := TEventExecutionEngine.Create;
  FEngine.RegisterHandler(TMicButtonClicked.Create);
  FEngine.RegisterHandler(TCloseClick.Create);
  FEngine.RegisterHandler(TAudioActive.Create);
  FEngine.RegisterHandler(TAudioInactive.Create);
  FEngine.RegisterHandler(TAudioEnded.Create);

  FEngine.RegisterHandler(TRtJsReady.Create);
  FEngine.RegisterHandler(TRtConnected.Create);
  FEngine.RegisterHandler(TRtClosed.Create);
  FEngine.RegisterHandler(TRtDcOpen.Create);
  FEngine.RegisterHandler(TRtDcClose.Create);
  FEngine.RegisterHandler(TRtTrackAdded.Create);
  FEngine.RegisterHandler(TRtPcState.Create);
  FEngine.RegisterHandler(TRtError.Create);
  FEngine.RegisterHandler(TRtEventSent.Create);
  FEngine.RegisterHandler(TOaiEvent.Create);
end;

class function TEventEngineManager.Instance: IAudioEventEngineManager;
begin
  if FInstance = nil then
    FInstance := TEventEngineManager.Create;
  Result := FInstance;
end;

{ TMicButtonClicked }

function TMicButtonClicked.CanHandle(EventKind: TAudioEventKind): Boolean;
begin
  Result := EventKind = mic_button_clicked;
end;

function TMicButtonClicked.Handle(const EdgeAudio: IEdgeAudio): Boolean;
begin
  Result := True;
  var eventValue := EdgeAudio.JsonObject.GetValue<string>('value', '');
  if Assigned(EdgeAudio.MicClick) then
    EdgeAudio.MicClick(eventValue);
end;

{ TCloseClick }

function TCloseClick.CanHandle(EventKind: TAudioEventKind): Boolean;
begin
  Result := EventKind = close_click;
end;

function TCloseClick.Handle(const EdgeAudio: IEdgeAudio): Boolean;
begin
  Result := True;
  if Assigned(EdgeAudio.CloseClick) then
    EdgeAudio.CloseClick();
end;

{ TAudioEnded }

function TAudioEnded.CanHandle(EventKind: TAudioEventKind): Boolean;
begin
  Result := EventKind = audio_ended;
end;

function TAudioEnded.Handle(const EdgeAudio: IEdgeAudio): Boolean;
begin
  Result := True;
  EdgeAudio.Player.IsPlaying := False;
  if Assigned(EdgeAudio.AudioEndProc) then
    EdgeAudio.AudioEndProc();
end;

{ TRtPcState }

function TRtPcState.CanHandle(EventKind: TAudioEventKind): Boolean;
begin
  Result := EventKind = rt_pc_state;
end;

function TRtPcState.Handle(const EdgeAudio: IEdgeAudio): Boolean;
begin
  Result := True;
  var State := EdgeAudio.JsonObject.GetValue<string>('state', '');
  if Assigned(EdgeAudio.RealtimePcStateProc) then
    EdgeAudio.RealtimePcStateProc(State);
end;

{ TOaiEvent }

function TOaiEvent.CanHandle(EventKind: TAudioEventKind): Boolean;
begin
  Result := EventKind = oai_event;
end;

function TOaiEvent.Handle(const EdgeAudio: IEdgeAudio): Boolean;
begin
  // Récupérer l'objet brut "data"
  var DataVal := EdgeAudio.JsonObject.GetValue('data');
  if Assigned(DataVal) then
    begin
      Result := True;
      if Assigned(EdgeAudio.RealtimeEventProc) then
        EdgeAudio.RealtimeEventProc(DataVal as TJSONObject);
      //Créer un engine Event avec les events ex. EventType = response.done...
      //Désérialiser le JSON en une classe

      // Option 1: callback unique pour tout Realtime
      // EdgeAudio.RealtimeEventProc?.Invoke( (DataVal as TJSONObject) );

      // Option 2 (si on veut déjà router): switch sur data.type
      // var EventType := (DataVal as TJSONObject).GetValue<string>('type','');
      // if EventType = 'response.done' then ...
    end
  else
    begin
      Result := False;
    end;
end;

{ TRtEventSent }

function TRtEventSent.CanHandle(EventKind: TAudioEventKind): Boolean;
begin
  Result := EventKind = rt_event_sent;
end;

function TRtEventSent.Handle(const EdgeAudio: IEdgeAudio): Boolean;
begin
  // log, status, ou callback
  OutputDebugString(PChar('RT event sent: ' + EdgeAudio.JsonObject.ToJSON));
  Result := True;
end;

{ TRtJsReady }

function TRtJsReady.CanHandle(EventKind: TAudioEventKind): Boolean;
begin
  Result := EventKind = rt_js_ready;
end;

function TRtJsReady.Handle(const EdgeAudio: IEdgeAudio): Boolean;
begin
  Result := True;
  if Assigned(EdgeAudio.RealtimeJsReadyProc) then
    EdgeAudio.RealtimeJsReadyProc();
end;

{ TRtConnected }

function TRtConnected.CanHandle(EventKind: TAudioEventKind): Boolean;
begin
  Result := EventKind = rt_connected;
end;

function TRtConnected.Handle(const EdgeAudio: IEdgeAudio): Boolean;
begin
  Result := True;
  if Assigned(EdgeAudio.RealtimeConnectedProc) then
    EdgeAudio.RealtimeConnectedProc();
end;

{ TRtClosed }

function TRtClosed.CanHandle(EventKind: TAudioEventKind): Boolean;
begin
  Result := EventKind = rt_closed;
end;

function TRtClosed.Handle(const EdgeAudio: IEdgeAudio): Boolean;
begin
  Result := True;
  if Assigned(EdgeAudio.RealtimeClosedProc) then
    EdgeAudio.RealtimeClosedProc();
end;

{ TRtDcOpen }

function TRtDcOpen.CanHandle(EventKind: TAudioEventKind): Boolean;
begin
  Result := EventKind = rt_dc_open;
end;

function TRtDcOpen.Handle(const EdgeAudio: IEdgeAudio): Boolean;
begin
  Result := True;
  if Assigned(EdgeAudio.RealtimeDataChannelOpenProc) then
    EdgeAudio.RealtimeDataChannelOpenProc();
end;

{ TRtDcClose }

function TRtDcClose.CanHandle(EventKind: TAudioEventKind): Boolean;
begin
  Result := EventKind = rt_dc_close;
end;

function TRtDcClose.Handle(const EdgeAudio: IEdgeAudio): Boolean;
begin
  Result := True;
  if Assigned(EdgeAudio.RealtimeDataChannelCloseProc) then
    EdgeAudio.RealtimeDataChannelCloseProc();
end;

{ TRtTrackAdded }

function TRtTrackAdded.CanHandle(EventKind: TAudioEventKind): Boolean;
begin
  Result := EventKind = rt_track_added;
end;

function TRtTrackAdded.Handle(const EdgeAudio: IEdgeAudio): Boolean;
begin
  Result := True;
  if Assigned(EdgeAudio.RealtimeTrackAddedProc) then
    EdgeAudio.RealtimeTrackAddedProc();
end;

{ TAudioActive }

function TAudioActive.CanHandle(EventKind: TAudioEventKind): Boolean;
begin
  Result := EventKind = audio_active;
end;

function TAudioActive.Handle(const EdgeAudio: IEdgeAudio): Boolean;
begin
  Result := True;
  EdgeAudio.Player.IsPlaying := True;
  if Assigned(EdgeAudio.AudioPlayProc) then
    EdgeAudio.AudioPlayProc();
end;

{ TAudioInactive }

function TAudioInactive.CanHandle(EventKind: TAudioEventKind): Boolean;
begin
  Result := EventKind = audio_inactive
end;

function TAudioInactive.Handle(const EdgeAudio: IEdgeAudio): Boolean;
begin
  Result := True;
  EdgeAudio.Player.IsPlaying := False;
  if Assigned(EdgeAudio.AudioEndProc) then
    EdgeAudio.AudioEndProc();
end;

{ TRtError }

function TRtError.CanHandle(EventKind: TAudioEventKind): Boolean;
begin
  Result := EventKind = rt_error;
end;

function TRtError.Handle(const EdgeAudio: IEdgeAudio): Boolean;
begin
  OutputDebugString(PChar('RT error: ' + EdgeAudio.JsonObject.ToJSON));
  var ErrorMessage := EdgeAudio.JsonObject.GetValue('message');
  raise Exception.CreateFmt('RT error: %s', [ErrorMessage]);
end;

end.
