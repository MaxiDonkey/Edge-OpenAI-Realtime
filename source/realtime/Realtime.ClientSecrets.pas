unit Realtime.ClientSecrets;

interface

uses
  System.SysUtils,
  Realtime.API.JsonParams, Realtime.Async.Support, Realtime.API.Client, Realtime.Params,
  Realtime.DTOs;

type
  TClientSecretParams = class(TJSONParam)
    /// <summary>
    ///   Configuration for the client secret expiration.
    /// </summary>
    /// <remarks>
    ///   Expiration refers to the time after which a client secret will no longer be valid
    ///   for creating sessions. The session itself may continue after that time once started.
    ///   A secret can be used to create multiple sessions until it expires.
    /// </remarks>
    function ExpiresAfter(const Value: TExpiresAfterParams): TClientSecretParams;

    /// <summary>
    ///   Session configuration to use for the client secret. Choose either a realtime session
    ///   or a transcription session.
    /// </summary>
    function Session(const Value: TSessionParams): TClientSecretParams;

    class function New: TClientSecretParams;
  end;

  TClientSecretsRoute = class(TRealtimeAPIRoute)
    procedure AsyncCreate(const ParamProc: TProc<TClientSecretParams>;
      const CallBacks: TFunc<TAsyncSessionResponse>);

    /// <summary>
    ///   Create a Realtime client secret with an associated session configuration.
    /// </summary>
    /// <remarks>
    ///   The created client secret and the effective session object. The client secret is a string
    ///   that looks like ek_1234.
    /// </remarks>
    function Create(const ParamProc: TProc<TClientSecretParams>): TSessionResponse;
  end;

implementation

{ TClientSecretParams }

function TClientSecretParams.ExpiresAfter(
  const Value: TExpiresAfterParams): TClientSecretParams;
begin
  Result := TClientSecretParams(Add('expires_after', Value.detach));
end;

class function TClientSecretParams.New: TClientSecretParams;
begin
  Result := TClientSecretParams.Create;
end;

function TClientSecretParams.Session(
  const Value: TSessionParams): TClientSecretParams;
begin
  Result := TClientSecretParams(Add('session', Value.Detach));
end;

{ TClientSecretsRoute }

procedure TClientSecretsRoute.AsyncCreate(
  const ParamProc: TProc<TClientSecretParams>;
  const CallBacks: TFunc<TAsyncSessionResponse>);
begin
  with TAsynCallBackExec<TAsyncSessionResponse, TSessionResponse>.Create(CallBacks) do
  try
    Sender := Use.Param.Sender;
    OnStart := Use.Param.OnStart;
    OnSuccess := Use.Param.OnSuccess;
    OnError := Use.Param.OnError;
    Run(
      function: TSessionResponse
      begin
        Result := Self.Create(ParamProc);
      end);
  finally
    Free;
  end;
end;

function TClientSecretsRoute.Create(
  const ParamProc: TProc<TClientSecretParams>): TSessionResponse;
begin
  Result := API.Post<TSessionResponse, TClientSecretParams>('realtime/client_secrets', ParamProc);
end;

end.

