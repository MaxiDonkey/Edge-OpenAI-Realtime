unit Edge.Sessions.FileFinder;

interface

uses
  System.SysUtils, System.IOUtils, System.RegularExpressions, System.Generics.Collections;


function FindLatestSessionFile(const FolderPath: string;
  const Prefix: string = 'session_';
  const Extension: string = '.jsonl'): string;

function FindPreviousSessionFile(const FolderPath: string;
  const Prefix: string = 'session_';
  const Extension: string = '.jsonl'): string;

implementation

function FindLatestSessionFile(const FolderPath, Prefix, Extension: string): string;
begin
  Result := EmptyStr;
  var bestName := EmptyStr;
  var bestPath := EmptyStr;
  var pattern := '^' + Prefix + '\d{8}_\d{6}_\d{3}' + Extension + '$';

  var candidates := TDirectory.GetFiles(FolderPath, Prefix + '*' + Extension, TSearchOption.soTopDirectoryOnly);
  for var path in candidates do
  begin
    var fileName := TPath.GetFileName(path);
    if not TRegEx.IsMatch(fileName, pattern, [roIgnoreCase]) then
      Continue;

    if (bestName = EmptyStr) or (CompareText(fileName, bestName) > 0) then
      begin
        bestName := fileName;
        bestPath := path;
      end;
  end;

  Result := bestPath;
end;

function FindPreviousSessionFile(const FolderPath, Prefix, Extension: string): string;
begin
  Result := EmptyStr;

  if not TDirectory.Exists(FolderPath) then
    Exit;

  var pattern := '^' + Prefix + '\d{8}_\d{6}_\d{3}' + Extension + '$';

  {--- Pre-selection by name pattern }
  var files := TDirectory.GetFiles(FolderPath, Prefix + '*' + Extension, TSearchOption.soTopDirectoryOnly);

  {--- In-place Regex filtering on filename }
  var kept := 0;
  for var i := 0 to High(files) do
    if TRegEx.IsMatch(TPath.GetFileName(files[i]), pattern, [roIgnoreCase]) then
      begin
        files[kept] := files[i];
        Inc(kept);
      end;
  SetLength(files, kept);

  {--- No penultimate }
  if Length(files) < 2 then
    Exit;

  {--- ASC sorting (Lexicographic). All paths have the same folder => equivalent to sorting by name. }
  TArray.Sort<string>(files);

  {--- Last = High(files), second to last = High(files)-1 }
  Result := files[High(files) - 1];
end;

end.
