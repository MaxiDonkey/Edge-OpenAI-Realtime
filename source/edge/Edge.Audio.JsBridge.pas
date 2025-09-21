unit Edge.Audio.JsBridge;

interface

uses
  System.SysUtils, System.JSON;

type
  TAudioScript = record
  public
    class function ShowToast(const S: string; const DurationMs: Integer): string; static;
  end;

implementation

{ TAudioScript }

class function TAudioScript.ShowToast(const S: string;
  const DurationMs: Integer): string;
begin
  var JSON := TJSONString.Create(S);
  try
    var JCode :=
      '''
        (function(t,d){
          function go(){ if(window.showToast) window.showToast(t,d); else setTimeout(go,50); }
          go();
        })(%s,%d);
      ''';
    Result := Format(JCode, [JSON.ToString, DurationMs]);
  finally
    JSON.Free;
  end;
end;

end.
