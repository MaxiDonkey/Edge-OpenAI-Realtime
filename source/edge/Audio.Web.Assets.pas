unit Audio.Web.Assets;

interface

uses
  System.SysUtils, System.IOUtils;

type
  TAudioWeb = record
  const
    ERROR_MSG =
      '"web" folder not found : '#10#10 +
      '   • Please copy this folder to the same folder as the application. '#10#10 +
      '   • The "web" folder is located at the root of the project and contains the HTML/JS/CSS files.';
  public
    class function WebPath: string; static;
  end;

  function JsonQuoted(const S: string): string;

implementation

uses System.JSON;

function JsonQuoted(const S: string): string;
begin
  var Json := TJSONString.Create(S);
  try
    Result := Json.ToString;
  finally
    Json.Free;
  end;
end;


{ TAudioWeb }

class function TAudioWeb.WebPath: string;
begin
  Result := TPath.Combine(ExtractFilePath(ParamStr(0)), 'web');

  if not System.SysUtils.DirectoryExists(Result) then
    Result := '../../web';

  if not System.SysUtils.DirectoryExists(Result) then
    raise Exception.Create(ERROR_MSG);
end;

end.
