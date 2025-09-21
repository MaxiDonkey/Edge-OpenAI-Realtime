unit Realtime.API.Client;

interface

uses
  System.SysUtils, System.Classes, System.JSON, System.Net.URLClient,
  System.Net.HttpClient, System.NetConsts,
  REST.Json,
  Realtime.API.JsonParams, Realtime.Errors, Realtime.Exceptions,
  JSON.PolymorphicMapper;

type
  TSendProc = reference to procedure (S: string);

  TRealtimeAPI = class
  const
    URL_BASE = 'https://api.openai.com/v1';
    CALL_ENDPOINT = 'realtime/calls';
  private
    FAPIKey: string;
    FBaseUrl: string;
    FSendMethod: TSendProc;
    procedure SetBaseUrl(const Value: string);
  protected
    function GetClient: THTTPClient; virtual;
    function BuildUrl(const Endpoint: string): string;
    procedure DeserializeErrorData(const Code: Int64; const ResponseText: string); virtual;
    procedure RaiseError(Code: Int64; Error: TErrorCore);
    function Deserialize<T: class, constructor>(const Code: Int64; const ResponseText: string): T;
  public
    function Post<TResult: class, constructor; TParams: TJSONParam>(const Endpoint: string; ParamProc: TProc<TParams>): TResult; overload;
    procedure Send<TParams: TJSONParam>(ParamProc: TProc<TParams>);
    class function Parse<T: class, constructor>(const Value: string): T;
  public
    constructor Create; overload;
    constructor Create(const AAPIKey: string); overload;
    function GetCallUrl: string;
    property APIKey: string read FAPIKey write FAPIKey;
    property BaseUrl: string read FBaseUrl write SetBaseUrl;
    property SendMethod: TSendProc read FSendMethod write FSendMethod;
  end;

  TRealtimeAPIRoute = class
  private
    FAPI: TRealtimeAPI;
    procedure SetAPI(const Value: TRealtimeAPI);
  public
    property API: TRealtimeAPI read FAPI write SetAPI;
    constructor CreateRoute(AAPI: TRealtimeAPI); reintroduce; virtual;
  end;

implementation

{ TRealtimeAPI }

constructor TRealtimeAPI.Create;
begin
  inherited;
  FAPIKey := '';
  FBaseUrl := URL_BASE;
end;

function TRealtimeAPI.BuildUrl(const Endpoint: string): string;
begin
  Result := FBaseUrl.TrimRight(['/']) + '/' + Endpoint.TrimLeft(['/']);
end;

constructor TRealtimeAPI.Create(const AAPIKey: string);
begin
  Create;
  APIKey := AAPIKey;
end;

function TRealtimeAPI.Deserialize<T>(const Code: Int64;
  const ResponseText: string): T;
begin
  if (Code < 200) or (Code > 299) then
  begin
    DeserializeErrorData(Code, ResponseText);
    raise EInvalidResponse.Create(Code, 'HTTP error without details');
  end;

  if (Code <> 204) and ResponseText.Trim.IsEmpty then
    raise EInvalidResponse.Create(Code, 'Empty successful response');

  try
    Result := TRawJsonBase.FromJson<T>(ResponseText);
  except
    on E: Exception do
      raise EInvalidResponse.Create(Code, 'Parse error: ' + E.Message);
  end;

  if not Assigned(Result) then
    raise EInvalidResponse.Create(Code, 'Non-compliant response');
end;

procedure TRealtimeAPI.DeserializeErrorData(const Code: Int64;
  const ResponseText: string);
var
  Error: TError;
begin
  Error := nil;
  try
    try
      Error := TJson.JsonToObject<TError>(ResponseText);
    except
      Error := nil;
    end;

    if Assigned(Error) then
      RaiseError(Code, Error)
    else
      raise ERealtimeError.CreateFmt(
        'Server returned error code %d but response was not parseable: %s', [Code, ResponseText]);
  finally
    if Assigned(Error) then
      Error.Free;
  end;
end;

function TRealtimeAPI.GetClient: THTTPClient;
begin
  Result := THTTPClient.Create;
  Result.AcceptCharSet := 'utf-8';
  Result.CustomHeaders['Authorization'] := 'Bearer ' + ApiKey;
  Result.ContentType := 'application/json';
end;

class function TRealtimeAPI.Parse<T>(const Value: string): T;
begin
  Result := TJson.JsonToObject<T>(Value);
end;

function TRealtimeAPI.Post<TResult, TParams>(const Endpoint: string;
  ParamProc: TProc<TParams>): TResult;
var
  Response : TStringStream;
  Params   : TParams;
  Stream   : TStringStream;
  Client   : THTTPClient;
begin
  Response := TStringStream.Create('', TEncoding.UTF8);
  Params   := TParams.Create;
  Stream   := TStringStream.Create;
  Client   := GetClient;
  try
    if Assigned(ParamProc) then
      ParamProc(Params);
    Stream.WriteString(Params.JSON.ToJSON);
    Stream.Position := 0;
    var Code := Client.Post(BuildUrl(Endpoint), Stream, response).StatusCode;
    Result := Deserialize<TResult>(Code, Response.DataString)
  finally
    Client.Free;
    Stream.Free;
    Params.Free;
    Response.Free;
  end;
end;

procedure TRealtimeAPI.RaiseError(Code: Int64; Error: TErrorCore);
begin
  case Code of
    401:
      raise EAuthError.Create(Code, Error);
    403:
      raise ECountryNotSupported.Create(Code, Error);
    429:
      raise ERateLimitExceeded.Create(Code, Error);
    500:
      raise EServerError.Create(Code, Error);
    503:
      raise EEngineOverloaded.Create(Code, Error);
  else
    raise ERealtimeError.Create(Code, Error);
  end;
end;

procedure TRealtimeAPI.Send<TParams>(ParamProc: TProc<TParams>);
var
  Params: TParams;
begin
  Params := TParams.Create;
  try
    ParamProc(Params);
    if Assigned(FSendMethod) then
      FSendMethod(Params.ToJsonString);
  finally
    Params.Free;
  end;
end;

procedure TRealtimeAPI.SetBaseUrl(const Value: string);
begin
  FBaseUrl := Value;
end;

function TRealtimeAPI.GetCallUrl: string;
begin
  Result := BuildUrl(CALL_ENDPOINT);
end;

{ TRealtimeAPIRoute }

constructor TRealtimeAPIRoute.CreateRoute(AAPI: TRealtimeAPI);
begin
  inherited Create;
  FAPI := AAPI;
end;

procedure TRealtimeAPIRoute.SetAPI(const Value: TRealtimeAPI);
begin
  FAPI := Value;
end;

end.
