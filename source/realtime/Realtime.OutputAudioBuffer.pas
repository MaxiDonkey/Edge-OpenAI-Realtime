unit Realtime.OutputAudioBuffer;

interface

uses
  System.SysUtils, Realtime.API.JsonParams, Realtime.API.Client, Realtime.Params;

type
  TOutputAudioBufferParams = class(TJSONParam)
    /// <summary>
    ///   The unique ID of the client event used for error handling.
    /// </summary>
    function EventId(const Value: string): TOutputAudioBufferParams;

    /// <summary>
    ///   The event type, must be output_audio_buffer.clear.
    /// </summary>
    function &Type(const Value: string = 'output_audio_buffer.clear'): TOutputAudioBufferParams;

    class function New: TOutputAudioBufferParams;
  end;

  TOutputAudioBufferRoute = class(TRealtimeAPIRoute)
    /// <summary>
    ///   WebRTC Only: Emit to cut off the current audio response.
    /// </summary>
    /// <remarks>
    ///   This will trigger the server to stop generating audio and emit a output_audio_buffer.cleared
    ///   event. This event should be preceded by a response.cancel client event to stop the generation
    ///   of the current response.
    /// </remarks>
    procedure Clear(const ParamProc: TProc<TOutputAudioBufferParams>);
  end;

implementation

{ TOutputAudioBufferParams }

class function TOutputAudioBufferParams.New: TOutputAudioBufferParams;
begin
  Result := TOutputAudioBufferParams.Create.&Type();
end;

function TOutputAudioBufferParams.&Type(
  const Value: string): TOutputAudioBufferParams;
begin
  Result := TOutputAudioBufferParams(Add('type', Value));
end;

function TOutputAudioBufferParams.EventId(
  const Value: string): TOutputAudioBufferParams;
begin
  Result := TOutputAudioBufferParams(Add('event_id', Value));
end;

{ TOutputAudioBufferRoute }

procedure TOutputAudioBufferRoute.Clear(
  const ParamProc: TProc<TOutputAudioBufferParams>);
begin
  API.Send<TOutputAudioBufferParams>(ParamProc);
end;

end.
