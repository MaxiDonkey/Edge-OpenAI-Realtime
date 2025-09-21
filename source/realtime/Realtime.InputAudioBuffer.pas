unit Realtime.InputAudioBuffer;

interface

uses
  System.SysUtils, Realtime.API.JsonParams, Realtime.API.Client, Realtime.Params;

type
  TInputAudioBufferAppendParams = class(TJSONParam)
    /// <summary>
    ///   Base64-encoded audio bytes. This must be in the format specified by the input_audio_format
    ///   field in the session configuration.
    /// </summary>
    function Audio(const Value: string): TInputAudioBufferAppendParams;

    /// <summary>
    ///   Optional client-generated ID used to identify this event.
    /// </summary>
    function EventId(const Value: string): TInputAudioBufferAppendParams;

    /// <summary>
    ///   The event type, must be input_audio_buffer.append.
    /// </summary>
    function &Type(const Value: string = 'input_audio_buffer.append'): TInputAudioBufferAppendParams;

    class function New: TInputAudioBufferAppendParams;
  end;

  TInputAudioBufferCommitParams = class(TJSONParam)
    /// <summary>
    ///   Optional client-generated ID used to identify this event.
    /// </summary>
    function EventId(const Value: string): TInputAudioBufferCommitParams;

    /// <summary>
    ///   The event type, must be input_audio_buffer.commit.
    /// </summary>
    function &Type(const Value: string = 'input_audio_buffer.commit'): TInputAudioBufferCommitParams;

    class function New: TInputAudioBufferCommitParams;
  end;

  TInputAudioBufferClearParams = class(TJSONParam)
    /// <summary>
    ///   Optional client-generated ID used to identify this event.
    /// </summary>
    function EventId(const Value: string): TInputAudioBufferClearParams;

    /// <summary>
    ///   The event type, must be input_audio_buffer.clear.
    /// </summary>
    function &Type(const Value: string = 'input_audio_buffer.clear'): TInputAudioBufferClearParams;

    class function New: TInputAudioBufferClearParams;
  end;

  TInputAudioBufferRoute = class(TRealtimeAPIRoute)
    /// <summary>
    ///   Send this event to append audio bytes to the input audio buffer. The audio buffer is temporary
    ///   storage you can write to and later commit. A "commit" will create a new user message item in
    ///   the conversation history from the buffer content and clear the buffer. Input audio transcription
    ///    (if enabled) will be generated when the buffer is committed
    /// </summary>
    /// <remarks>
    /// <para>
    ///   If VAD is enabled the audio buffer is used to detect speech and the server will decide when to
    ///   commit. When Server VAD is disabled, you must commit the audio buffer manually. Input audio
    ///   noise reduction operates on writes to the audio buffer.
    /// </para>
    /// <para>
    ///   The client may choose how much audio to place in each event up to a maximum of 15 MiB, for
    ///   example streaming smaller chunks from the client may allow the VAD to be more responsive.
    ///   Unlike most other client events, the server will not send a confirmation response to this event.
    /// </para>
    /// </remarks>
    procedure Append(const ParamProc: TProc<TInputAudioBufferAppendParams>);

    /// <summary>
    ///   Send this event to commit the user input audio buffer, which will create a new user message
    ///   item in the conversation. This event will produce an error if the input audio buffer is empty.
    //    When in Server VAD mode, the client does not need to send this event, the server will commit
    ///   the audio buffer automatically.
    /// </summary>
    /// <remarks>
    ///   Committing the input audio buffer will trigger input audio transcription (if enabled in session
    ///   configuration), but it will not create a response from the model. The server will respond with
    ///   an input_audio_buffer.committed event.
    /// </remarks>
    procedure Commit(const ParamProc: TProc<TInputAudioBufferCommitParams>);

    /// <summary>
    ///   Send this event to clear the audio bytes in the buffer. The server will respond with an
    ///   input_audio_buffer.cleared event.
    /// </summary>
    procedure Clear(const ParamProc: TProc<TInputAudioBufferClearParams>);
  end;

implementation

{ TInputAudioBufferAppendParams }

function TInputAudioBufferAppendParams.&Type(
  const Value: string): TInputAudioBufferAppendParams;
begin
  Result := TInputAudioBufferAppendParams(Add('type', Value));
end;

function TInputAudioBufferAppendParams.Audio(
  const Value: string): TInputAudioBufferAppendParams;
begin
  Result := TInputAudioBufferAppendParams(Add('audio', Value));
end;

function TInputAudioBufferAppendParams.EventId(
  const Value: string): TInputAudioBufferAppendParams;
begin
  Result := TInputAudioBufferAppendParams(Add('event_id', Value));
end;

class function TInputAudioBufferAppendParams.New: TInputAudioBufferAppendParams;
begin
  Result := TInputAudioBufferAppendParams.Create.&Type();
end;

{ TInputAudioBufferCommitParams }

class function TInputAudioBufferCommitParams.New: TInputAudioBufferCommitParams;
begin
  Result := TInputAudioBufferCommitParams.Create.&Type();
end;

function TInputAudioBufferCommitParams.&Type(
  const Value: string): TInputAudioBufferCommitParams;
begin
  Result := TInputAudioBufferCommitParams(Add('type', Value));
end;

function TInputAudioBufferCommitParams.EventId(
  const Value: string): TInputAudioBufferCommitParams;
begin
  Result := TInputAudioBufferCommitParams(Add('event_id', Value));
end;

{ TInputAudioBufferClearParams }

class function TInputAudioBufferClearParams.New: TInputAudioBufferClearParams;
begin
  Result := TInputAudioBufferClearParams.Create.&Type();
end;

function TInputAudioBufferClearParams.&Type(
  const Value: string): TInputAudioBufferClearParams;
begin
  Result := TInputAudioBufferClearParams(Add('type', Value));
end;

function TInputAudioBufferClearParams.EventId(
  const Value: string): TInputAudioBufferClearParams;
begin
  Result := TInputAudioBufferClearParams(Add('event_id', Value));
end;

{ TInputAudioBufferRoute }

procedure TInputAudioBufferRoute.Append(
  const ParamProc: TProc<TInputAudioBufferAppendParams>);
begin
  API.Send<TInputAudioBufferAppendParams>(ParamProc);
end;

procedure TInputAudioBufferRoute.Clear(
  const ParamProc: TProc<TInputAudioBufferClearParams>);
begin
  API.Send<TInputAudioBufferClearParams>(ParamProc);
end;

procedure TInputAudioBufferRoute.Commit(
  const ParamProc: TProc<TInputAudioBufferCommitParams>);
begin
  API.Send<TInputAudioBufferCommitParams>(ParamProc);
end;

end.
