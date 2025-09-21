unit Realtime.Response;

interface

uses
  System.SysUtils, Realtime.API.JsonParams, Realtime.API.Client, Realtime.Params;

type
  TResponseCancelParams = class(TJSONParam)
    /// <summary>
    ///   Optional client-generated ID used to identify this event.
    /// </summary>
    function EventId(const Value: string): TResponseCancelParams;

    /// <summary>
    ///   A specific response ID to cancel - if not provided, will cancel an in-progress response
    ///   in the default conversation.
    /// </summary>
    function ResponseId(const Value: string): TResponseCancelParams;

    /// <summary>
    ///   The event type, must be response.cancel.
    /// </summary>
    function &Type(const Value: string = 'response.cancel'): TResponseCancelParams;

    class function New: TResponseCancelParams;
  end;

  TResponseCreateParams = class(TJSONParam)
    /// <summary>
    ///   Optional client-generated ID used to identify this event.
    /// </summary>
    function EventId(const Value: string): TResponseCreateParams;

    /// <summary>
    ///   Create a new Realtime response with these parameters
    /// </summary>
    function Response(const Value: TResponseParams): TResponseCreateParams;

    /// <summary>
    ///   The event type, must be response.create.
    /// </summary>
    function &Type(const Value: string = 'response.create'): TResponseCreateParams;

    class function New: TResponseCreateParams;
  end;

  TResponseRoute = class(TRealtimeAPIRoute)
    /// <summary>
    ///   This event instructs the server to create a Response, which means triggering model inference.
    ///   When in Server VAD mode, the server will create Responses automatically.
    /// </summary>
    /// <remarks>
    /// <para>
    ///   A Response will include at least one Item, and may have two, in which case the second will be
    ///   a function call. These Items will be appended to the conversation history by default.
    /// </para>
    /// <para>
    ///   The server will respond with a response.created event, events for Items and content created, and
    ///   finally a response.done event to indicate the Response is complete.
    /// </para>
    /// <para>
    ///   The response.create event includes inference configuration like instructions and tools. If these
    ///   are set, they will override the Session's configuration for this Response only.
    /// </para>
    /// <para>
    ///   Responses can be created out-of-band of the default Conversation, meaning that they can have
    ///   arbitrary input, and it's possible to disable writing the output to the Conversation. Only one
    ///   Response can write to the default Conversation at a time, but otherwise multiple Responses can be
    ///   created in parallel. The metadata field is a good way to disambiguate multiple simultaneous
    ///   Responses.
    /// </para>
    /// <para>
    ///   Clients can set conversation to none to create a Response that does not write to the default
    ///   Conversation. Arbitrary input can be provided with the input field, which is an array accepting
    ///   raw Items and references to existing Items.
    /// </para>
    /// </remarks>
    procedure Create(const ParamProc: TProc<TResponseCreateParams>);

    /// <summary>
    ///   Send this event to cancel an in-progress response. The server will respond with a response.done
    ///   event with a status of response.status=cancelled.
    /// </summary>
    /// <remarks>
    ///   If there is no response to cancel, the server will respond with an error. It's safe to call
    ///   response.cancel even if no response is in progress, an error will be returned the session will
    ///   remain unaffected.
    /// </remarks>
    procedure Cancel(const ParamProc: TProc<TResponseCancelParams>);
  end;

implementation

{ TResponseCancelParams }

function TResponseCancelParams.&Type(
  const Value: string): TResponseCancelParams;
begin
  Result := TResponseCancelParams(Add('type', Value));
end;

function TResponseCancelParams.EventId(
  const Value: string): TResponseCancelParams;
begin
  Result := TResponseCancelParams(Add('event_id', Value));
end;

class function TResponseCancelParams.New: TResponseCancelParams;
begin
  Result := TResponseCancelParams.Create.&Type();
end;

function TResponseCancelParams.ResponseId(
  const Value: string): TResponseCancelParams;
begin
  Result := TResponseCancelParams(Add('response_id', Value));
end;

{ TResponseRoute }

procedure TResponseRoute.Cancel(const ParamProc: TProc<TResponseCancelParams>);
begin
  API.Send<TResponseCancelParams>(ParamProc);
end;

procedure TResponseRoute.Create(const ParamProc: TProc<TResponseCreateParams>);
begin
  API.Send<TResponseCreateParams>(ParamProc);
end;

{ TResponseCreateParams }

class function TResponseCreateParams.New: TResponseCreateParams;
begin
  Result := TResponseCreateParams.Create.&Type();
end;

function TResponseCreateParams.Response(
  const Value: TResponseParams): TResponseCreateParams;
begin
  Result := TResponseCreateParams(Add('response', Value.Detach));
end;

function TResponseCreateParams.&Type(
  const Value: string): TResponseCreateParams;
begin
  Result := TResponseCreateParams(Add('type', Value));
end;

function TResponseCreateParams.EventId(
  const Value: string): TResponseCreateParams;
begin
  Result := TResponseCreateParams(Add('event_id', Value));
end;

end.
