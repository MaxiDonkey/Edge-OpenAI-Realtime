unit Realtime.Session;

interface

uses
  System.SysUtils, Realtime.API.JsonParams, Realtime.API.Client, Realtime.Params;

type
  TSessionUpdateParams = class(TJSONParam)
    /// <summary>
    ///   Optional client-generated ID used to identify this event. This is an arbitrary string that
    ///   a client may assign. It will be passed back if there is an error with the event, but the
    ///   corresponding session.updated event will not include it.
    /// </summary>
    function EventId(const Value: string): TSessionUpdateParams;

    /// <summary>
    ///   Update the Realtime session. Choose either a realtime session or a transcription session.
    /// </summary>
    function Session(const Value: TSessionParams): TSessionUpdateParams;

    /// <summary>
    ///   The event type, must be session.update.
    /// </summary>
    function &Type(const Value: string = 'session.update'): TSessionUpdateParams;
  end;

  TSessionRoute = class(TRealtimeAPIRoute)
    /// <summary>
    ///   Send this event to update the session’s configuration. The client may send this event
    ///   at any time to update any field except for voice and model. voice can be updated only
    ///   if there have been no other audio outputs yet.
    /// </summary>
    /// <remarks>
    ///   When the server receives a session.update, it will respond with a session.updated event
    ///   showing the full, effective configuration. Only the fields that are present in the
    ///   session.update are updated. To clear a field like instructions, pass an empty string.
    ///   To clear a field like tools, pass an empty array. To clear a field like turn_detection,
    ///   pass null.
    /// </remarks>
    procedure Update(const ParamProc: TProc<TSessionUpdateParams>);
  end;

implementation

{ TSessionUpdateParams }

function TSessionUpdateParams.Session(
  const Value: TSessionParams): TSessionUpdateParams;
begin
  Result := TSessionUpdateParams(Add('session', Value.Detach));
end;

function TSessionUpdateParams.&Type(const Value: string): TSessionUpdateParams;
begin
  Result := TSessionUpdateParams(Add('type', Value));
end;

function TSessionUpdateParams.EventId(
  const Value: string): TSessionUpdateParams;
begin
  Result := TSessionUpdateParams(Add('event_id', Value));
end;

{ TSessionRoute }

procedure TSessionRoute.Update(const ParamProc: TProc<TSessionUpdateParams>);
begin
  API.Send<TSessionUpdateParams>(ParamProc);
end;

end.
