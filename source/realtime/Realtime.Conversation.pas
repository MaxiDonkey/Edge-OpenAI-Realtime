unit Realtime.Conversation;

interface

uses
  System.SysUtils, Realtime.API.JsonParams, Realtime.API.Client, Realtime.Params;

type
  TConversationItemCreateParams = class(TJSONParam)
    /// <summary>
    ///   Optional client-generated ID used to identify this event.
    /// </summary>
    function EventId(const Value: string): TConversationItemCreateParams;

    /// <summary>
    ///   A single item within a Realtime conversation.
    /// </summary>
    function Item(const Value: TInputParams): TConversationItemCreateParams;

    /// <summary>
    ///   The ID of the preceding item after which the new item will be inserted.
    /// </summary>
    /// <remarks>
    /// <para>
    ///   If not set, the new item will be appended to the end of the conversation.
    /// </para>
    /// <para>
    ///   If set to root, the new item will be added to the beginning of the conversation.
    /// </para>
    /// <para>
    ///   If set to an existing ID, it allows an item to be inserted mid-conversation.
    /// </para>
    /// <para>
    ///   If the ID cannot be found, an error will be returned and the item will not be added.
    /// </para>
    /// </remarks>
    function PreviousItemId(const Value: string): TConversationItemCreateParams;

    /// <summary>
    ///   The event type, must be conversation.item.create.
    /// </summary>
    function &Type(const Value: string = 'conversation.item.create'): TConversationItemCreateParams;

    class function New: TConversationItemCreateParams;
  end;

  TConversationItemRetrieveParams = class(TJSONParam)
    /// <summary>
    ///   Optional client-generated ID used to identify this event.
    /// </summary>
    function EventId(const Value: string): TConversationItemRetrieveParams;

    /// <summary>
    ///   The ID of the item to retrieve.
    /// </summary>
    function ItemId(const Value: string): TConversationItemRetrieveParams;

    /// <summary>
    ///   The event type, must be conversation.item.retrieve.
    /// </summary>
    function &Type(const Value: string = 'conversation.item.retrieve'): TConversationItemRetrieveParams;

    class function New: TConversationItemRetrieveParams;
  end;

  TConversationItemTruncateParams = class(TJSONParam)
    /// <summary>
    ///   Inclusive duration up to which audio is truncated, in milliseconds. If the audio_end_ms
    ///   is greater than the actual audio duration, the server will respond with an error.
    /// </summary>
    function AudioEndMs(const Value: Integer): TConversationItemTruncateParams;

    /// <summary>
    ///   The index of the content part to truncate. Set this to 0.
    /// </summary>
    function ContentIndex(const Value: Integer): TConversationItemTruncateParams;

    /// <summary>
    ///   Optional client-generated ID used to identify this event.
    /// </summary>
    function EventId(const Value: string): TConversationItemTruncateParams;

    /// <summary>
    ///   The ID of the item to retrieve.
    /// </summary>
    function ItemId(const Value: string): TConversationItemTruncateParams;

    /// <summary>
    ///   The event type, must be conversation.item.truncate.
    /// </summary>
    function &Type(const Value: string = 'conversation.item.truncate'): TConversationItemTruncateParams;

    class function New: TConversationItemTruncateParams;
  end;

  TConversationItemDeleteParams = class(TJSONParam)
    /// <summary>
    ///   Optional client-generated ID used to identify this event.
    /// </summary>
    function EventId(const Value: string): TConversationItemDeleteParams;

    /// <summary>
    ///   The ID of the item to retrieve.
    /// </summary>
    function ItemId(const Value: string): TConversationItemDeleteParams;

    /// <summary>
    ///   The event type, must be conversation.item.delete.
    /// </summary>
    function &Type(const Value: string = 'conversation.item.delete'): TConversationItemDeleteParams;

    class function New: TConversationItemDeleteParams;
  end;

  TConversationRoute = class(TRealtimeAPIRoute)
    /// <summary>
    ///   Add a new Item to the Conversation's context, including messages, function calls, and
    ///   function call responses.
    /// </summary>
    /// <remarks>
    /// <para>
    ///   This event can be used both to populate a "history" of the
    ///   conversation and to add new items mid-stream, but has the current limitation that it
    ///   cannot populate assistant audio messages.
    /// </para>
    ///   If successful, the server will respond with a conversation.item.created event, otherwise
    ///   an error event will be sent.
    /// </remarks>
    procedure Create(const ParamProc: TProc<TConversationItemCreateParams>);

    /// <summary>
    ///   Send this event when you want to retrieve the server's representation of a specific item
    ///   in the conversation history.
    /// </summary>
    /// <remarks>
    ///   This is useful, for example, to inspect user audio after noise cancellation and VAD. The
    ///   server will respond with a conversation.item.retrieved event, unless the item does not
    ///   exist in the conversation history, in which case the server will respond with an error.
    /// </remarks>
    procedure Retrieve(const ParamProc: TProc<TConversationItemRetrieveParams>);

    /// <summary>
    ///   Send this event to truncate a previous assistant message’s audio. The server will produce
    ///   audio faster than realtime, so this event is useful when the user interrupts to truncate
    ///   audio that has already been sent to the client but not yet played. This will synchronize
    ///   the server's understanding of the audio with the client's playback.
    /// </summary>
    /// <remarks>
    /// <para>
    ///   Truncating audio will delete the server-side text transcript to ensure there is not text
    ///   in the context that hasn't been heard by the user.
    /// </para>
    ///   If successful, the server will respond with a conversation.item.truncated event.
    /// </remarks>
    procedure Truncate(const ParamProc: TProc<TConversationItemTruncateParams>);

    /// <summary>
    ///   Send this event when you want to remove any item from the conversation history. The server
    ///   will respond with a conversation.item.deleted event, unless the item does not exist in the
    ///   conversation history, in which case the server will respond with an error.
    /// </summary>
    procedure Delete(const ParamProc: TProc<TConversationItemDeleteParams>);
  end;

implementation

{ TConversationItemCreateParams }

function TConversationItemCreateParams.Item(
  const Value: TInputParams): TConversationItemCreateParams;
begin
  Result := TConversationItemCreateParams(Add('item', Value.Detach));
end;

class function TConversationItemCreateParams.New: TConversationItemCreateParams;
begin
  Result := TConversationItemCreateParams.Create.&Type();
end;

function TConversationItemCreateParams.PreviousItemId(
  const Value: string): TConversationItemCreateParams;
begin
  Result := TConversationItemCreateParams(Add('previous_item_id', Value));
end;

function TConversationItemCreateParams.&Type(
  const Value: string): TConversationItemCreateParams;
begin
  Result := TConversationItemCreateParams(Add('type', Value));
end;

function TConversationItemCreateParams.EventId(
  const Value: string): TConversationItemCreateParams;
begin
  Result := TConversationItemCreateParams(Add('event_id', Value));
end;

{ TConversationRoute }

procedure TConversationRoute.Create(
  const ParamProc: TProc<TConversationItemCreateParams>);
begin
  API.Send<TConversationItemCreateParams>(ParamProc);
end;

procedure TConversationRoute.Delete(
  const ParamProc: TProc<TConversationItemDeleteParams>);
begin
  API.Send<TConversationItemDeleteParams>(ParamProc);
end;

procedure TConversationRoute.Retrieve(
  const ParamProc: TProc<TConversationItemRetrieveParams>);
begin
  API.Send<TConversationItemRetrieveParams>(ParamProc);
end;

procedure TConversationRoute.Truncate(
  const ParamProc: TProc<TConversationItemTruncateParams>);
begin
  API.Send<TConversationItemTruncateParams>(ParamProc);
end;

{ TConversationItemRetrieveParams }

function TConversationItemRetrieveParams.&Type(
  const Value: string): TConversationItemRetrieveParams;
begin
  Result := TConversationItemRetrieveParams(Add('type', Value));
end;

function TConversationItemRetrieveParams.EventId(
  const Value: string): TConversationItemRetrieveParams;
begin
  Result := TConversationItemRetrieveParams(Add('event_id', Value));
end;

function TConversationItemRetrieveParams.ItemId(
  const Value: string): TConversationItemRetrieveParams;
begin
  Result := TConversationItemRetrieveParams(Add('item_id', Value));
end;

class function TConversationItemRetrieveParams.New: TConversationItemRetrieveParams;
begin
  Result := TConversationItemRetrieveParams.Create.&Type();
end;

{ TConversationItemTruncateParams }

function TConversationItemTruncateParams.&Type(
  const Value: string): TConversationItemTruncateParams;
begin
  Result := TConversationItemTruncateParams(Add('type', Value));
end;

function TConversationItemTruncateParams.AudioEndMs(
  const Value: Integer): TConversationItemTruncateParams;
begin
  Result := TConversationItemTruncateParams(Add('audio_end_ms', Value));
end;

function TConversationItemTruncateParams.ContentIndex(
  const Value: Integer): TConversationItemTruncateParams;
begin
  Result := TConversationItemTruncateParams(Add('content_index', Value));
end;

function TConversationItemTruncateParams.EventId(
  const Value: string): TConversationItemTruncateParams;
begin
  Result := TConversationItemTruncateParams(Add('event_id', Value));
end;

function TConversationItemTruncateParams.ItemId(
  const Value: string): TConversationItemTruncateParams;
begin
  Result := TConversationItemTruncateParams(Add('item_id', Value));
end;

class function TConversationItemTruncateParams.New: TConversationItemTruncateParams;
begin
  Result := TConversationItemTruncateParams.Create.&Type();
end;

{ TConversationItemDeleteParams }

function TConversationItemDeleteParams.&Type(
  const Value: string): TConversationItemDeleteParams;
begin
  Result := TConversationItemDeleteParams(Add('type', Value));
end;

function TConversationItemDeleteParams.EventId(
  const Value: string): TConversationItemDeleteParams;
begin
  Result := TConversationItemDeleteParams(Add('event_id', Value));
end;

function TConversationItemDeleteParams.ItemId(
  const Value: string): TConversationItemDeleteParams;
begin
  Result := TConversationItemDeleteParams(Add('item_id', Value));
end;

class function TConversationItemDeleteParams.New: TConversationItemDeleteParams;
begin
  Result := TConversationItemDeleteParams.Create.&Type();
end;

end.
