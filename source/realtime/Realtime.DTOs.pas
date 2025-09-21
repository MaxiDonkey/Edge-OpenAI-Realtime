unit Realtime.DTOs;

interface

uses
  System.SysUtils, System.JSON, System.Generics.Collections,
  REST.Json.Types, REST.JsonReflect, REST.Json,
  Audio.Web.Assets,
  Realtime.API.JsonParams, Realtime.Types, Realtime.Events.DTOs.Helper, Realtime.Async.Support,
  JSON.PolymorphicMapper;

type
  TSessionResponse = class(TRawJsonBase)
  private
    [JsonNameAttribute('expires_at')]
    FExpiresAt: Int64;
    FSession: TSession;
    FValue: string;
  public
    property ExpiresAt: Int64 read FExpiresAt write FExpiresAt;
    property Session: TSession read FSession write FSession;
    property Value: string read FValue write FValue;
    destructor Destroy; override;
  end;

  TAsyncSessionResponse = TAsynCallBack<TSessionResponse>;

implementation

{ TSessionResponse }

destructor TSessionResponse.Destroy;
begin
  if Assigned(FSession) then
    FSession.Free;
  inherited;
end;

end.
