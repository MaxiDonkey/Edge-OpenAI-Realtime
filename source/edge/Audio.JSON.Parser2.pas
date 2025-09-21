unit Audio.JSON.Parser2;

interface

uses
  System.SysUtils, System.JSON;

type
  TAudioJSONData = record
    class function ParseToObject(const S: string): TJSONObject; static;
  end;

implementation

{ TAudioJSONData }

class function TAudioJSONData.ParseToObject(const S: string): TJSONObject;
var
  JSONValue: TJSONValue;
begin
  Result := nil;
  JSONValue := TJSONObject.ParseJSONValue(S);
  if not Assigned(JSONValue) then Exit;
  try
    {--- case 1: already an object }
    if JSONValue is TJSONObject then
      Exit(TJSONObject(JSONValue.Clone))
    else
    {--- case 2: we received a STRING which contains a JSON object }
    if JSONValue is TJSONString then
      begin
        var Str := TJSONString(JSONValue).Value;
        JSONValue.Free;
        JSONValue := TJSONObject.ParseJSONValue(Str);
        if Assigned(JSONValue) and (JSONValue is TJSONObject) then
          Exit(TJSONObject(JSONValue.Clone));
      end;
  finally
    JSONValue.Free;
  end;
end;

end.
