unit Edge.Registry.Helper;

interface

uses
  Winapi.Windows, System.SysUtils, System.Win.Registry;

procedure SetUserEnvVar(const Name, Value: string; Expandable: Boolean = False);

function ReadEnvFromRegistry(const Name: string): string;

implementation

procedure SetUserEnvVar(const Name, Value: string; Expandable: Boolean = False);
var
  EnvKey: HKEY;
  Status: Longint;
  DataSize: DWORD;
begin
  Status := RegCreateKeyEx(HKEY_CURRENT_USER, 'Environment', 0, nil,
                           REG_OPTION_NON_VOLATILE, KEY_SET_VALUE,
                           nil, EnvKey, nil);
  if Status <> ERROR_SUCCESS then
    RaiseLastOSError(Status);
  try
    DataSize := (Length(Value) + 1) * SizeOf(Char); // Unicode
    Status := RegSetValueEx(EnvKey, PChar(Name), 0, REG_SZ,
                            PByte(PChar(Value)), DataSize);
    if Status <> ERROR_SUCCESS then
      RaiseLastOSError(Status);
  finally
    RegCloseKey(EnvKey);
  end;
end;

function ReadEnvFromRegistry(const Name: string): string;

  function ReadFrom(const Root: HKEY; const SubKey, ValueName: string): string;
  var R: TRegistry;
  begin
    Result := '';
    R := TRegistry.Create(KEY_READ);
    try
      R.RootKey := Root;
      if R.OpenKeyReadOnly(SubKey) and R.ValueExists(ValueName) then
        Result := R.ReadString(ValueName);
    finally
      R.Free;
    end;
  end;

begin
  Result := ReadFrom(HKEY_CURRENT_USER, 'Environment', Name);
  if not Result.Trim.IsEmpty then
    Exit;

  Result := ReadFrom(HKEY_LOCAL_MACHINE,
            'SYSTEM\CurrentControlSet\Control\Session Manager\Environment', Name);
end;

end.
