unit Edge.Realtime.History;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, System.JSON, System.StrUtils,
  System.Threading, System.Generics.Collections, System.SyncObjs, System.Math;

type
  IRealtimeSessionLogger = interface(IInterface)
    ['{DF39BDC8-E75E-4A1C-9A04-79ED41140301}']
    /// <summary>
    /// Starts a new realtime logging session.
    /// </summary>
    /// <param name="SessionStart">
    /// The <c>TDateTime</c> value representing the start time of the session.
    /// This timestamp is used to generate the session log file name.
    /// </param>
    /// <remarks>
    /// If a session is already running, it will be stopped before starting a new one.
    /// This method initializes the log file and internal queue, and launches the background writer task.
    /// The log file will be created in the base directory with a unique name derived from <paramref name="SessionStart"/>.
    /// </remarks>
    procedure StartSession(const SessionStart: TDateTime);

    /// <summary>
    /// Logs a realtime event to the current session.
    /// </summary>
    /// <param name="Data">
    /// The <c>TJSONObject</c> containing the event data to be logged.
    /// The object will be serialized and appended to the session log file with a timestamp.
    /// </param>
    /// <remarks>
    /// If no session is running or <paramref name="Data"/> is <c>nil</c>, the event will be ignored.
    /// Events are enqueued and written asynchronously to the log file.
    /// If the internal queue is full, the oldest event is dropped to make room for the new one (drop-oldest strategy).
    /// </remarks>
    procedure LogEvent(const Data: TJSONObject);

    /// <summary>
    /// Stops the current realtime logging session and finalizes the log file.
    /// </summary>
    /// <remarks>
    /// This method signals the background writer task to stop, waits for all pending events to be written,
    /// and then releases internal resources.
    /// If no session is active, this method has no effect.
    /// </remarks>
    procedure StopSession;

    /// <summary>
    /// Returns the full path of the current session log file.
    /// </summary>
    /// <returns>
    /// The full file name and path of the active log file as a <c>string</c>.
    /// If no session is running, returns an empty string.
    /// </returns>
    /// <remarks>
    /// This method is thread-safe.
    /// </remarks>
    function  CurrentFile: string;

    /// <summary>
    /// Indicates whether a realtime logging session is currently active.
    /// </summary>
    /// <returns>
    /// <c>True</c> if a session is running; otherwise, <c>False</c>.
    /// </returns>
    /// <remarks>
    /// This method is thread-safe.
    /// </remarks>
    function  IsRunning: Boolean;
  end;

  TGetSessionLoggerEvent = procedure(out Logger: IRealtimeSessionLogger) of object;

  TSessionEventLogger = class(TInterfacedObject, IRealtimeSessionLogger)
  private
    FQueue: TThreadedQueue<string>;
    FTask: ITask;
    FActive: Boolean;
    FLogFile: string;
    FLock: TCriticalSection;

    FBaseDir: string;
    FFlushEvery: Integer;
    FQueueCapacity: Integer;
    FPushTimeout: Cardinal;
    FPopTimeout: Cardinal;

    class function DefaultBaseDir: string; static;
    class function BuildFileName(const BaseDir: string; const SessionStart: TDateTime): string; static;
    procedure EnsureStopped_NoLock;
  public
    constructor Create(
      const ABaseDir: string = ''; AFlushEvery: Integer = 50;
      AQueueCapacity: Integer = 8192; APushTimeout: Cardinal = 0; APopTimeout: Cardinal = 250);
    destructor Destroy; override;

    procedure StartSession(const SessionStart: TDateTime);
    procedure LogEvent(const Data: TJSONObject);
    procedure StopSession;
    function  CurrentFile: string;
    function  IsRunning: Boolean;
  end;

implementation

{ TSessionEventLogger }

class function TSessionEventLogger.DefaultBaseDir: string;
begin
  Result := TPath.Combine(TPath.GetDocumentsPath, TPath.Combine('EdgeRealtime', 'Sessions'));
end;

class function TSessionEventLogger.BuildFileName(const BaseDir: string; const SessionStart: TDateTime): string;
begin
  var Stamp := FormatDateTime('yyyymmdd_hhnnss_zzz', SessionStart);
  Result := TPath.Combine(BaseDir, Format('session_%s.jsonl', [Stamp]));
end;

constructor TSessionEventLogger.Create(
  const ABaseDir: string; AFlushEvery: Integer; AQueueCapacity: Integer; APushTimeout, APopTimeout: Cardinal);
begin
  inherited Create;
  FBaseDir := IfThen(not ABaseDir.IsEmpty, ABaseDir, DefaultBaseDir);
  FFlushEvery := Max(1, AFlushEvery);
  FQueueCapacity := Max(64, AQueueCapacity);
  FPushTimeout := APushTimeout;
  FPopTimeout := APopTimeout;
  FLock := TCriticalSection.Create;
end;

destructor TSessionEventLogger.Destroy;
begin
  try
    StopSession;
  finally
    FLock.Free;
    inherited;
  end;
end;

function TSessionEventLogger.CurrentFile: string;
begin
  FLock.Acquire;
  try
    Result := FLogFile;
  finally
    FLock.Release;
  end;
end;

function TSessionEventLogger.IsRunning: Boolean;
begin
  FLock.Acquire;
  try
    Result := FActive;
  finally
    FLock.Release;
  end;
end;

procedure TSessionEventLogger.StartSession(const SessionStart: TDateTime);
begin
  FLock.Acquire;
  try
    if FActive then
      EnsureStopped_NoLock;

    TDirectory.CreateDirectory(FBaseDir);
    FLogFile := BuildFileName(FBaseDir, SessionStart);

    FQueue := TThreadedQueue<string>.Create(FQueueCapacity, FPushTimeout, FPopTimeout);
    FActive := True;

    FTask := TTask.Run(
      procedure
      var
        Writer: TStreamWriter;
        Line: string;
        SinceFlush: Integer;
      begin
        try
          Writer := TStreamWriter.Create(FLogFile, True, TEncoding.UTF8);
        except
          FActive := False;
          FreeAndNil(FQueue);
          Exit;
        end;

        try
          SinceFlush := 0;
          while FActive do
            begin
              {--- PopItem blocks until FPopTimeout; in case of timeout => Default(string) = '' }
              Line := FQueue.PopItem;
              if not Line.IsEmpty then
                begin
                  Writer.WriteLine(Line);
                  Inc(SinceFlush);
                  if SinceFlush >= FFlushEvery then
                    begin
                      Writer.Flush;
                      SinceFlush := 0;
                    end;
                end;
            end;

          {--- Final drain (non-blocking beyond FPopTimeout) }
          repeat
            Line := FQueue.PopItem;
            if not Line.IsEmpty then
              Writer.WriteLine(Line);
          until Line = EmptyStr;
          Writer.Flush;
        finally
          Writer.Free;
        end;
      end);
  finally
    FLock.Release;
  end;
end;

procedure TSessionEventLogger.LogEvent(const Data: TJSONObject);
var
  QSz: NativeInt;
  Dropped: string;
begin
  if (Data = nil) or (FQueue = nil) or (not FActive) then
    Exit;

  var Ts := FormatDateTime('yyyy-mm-dd"T"hh:nn:ss.zzz', Now);
  var Line := Format('{"ts":"%s","event":%s}', [Ts, Data.ToJSON]);

  try
    case FQueue.PushItem(Line, QSz) of
      wrSignaled:
        ; {--- OK }

      wrTimeout:
        begin
          {--- Drop-oldest strategy (immediate: the queue is full, therefore not empty) }
          FQueue.PopItem(QSz, Dropped); // No timeout passed as parameter!
          FQueue.PushItem(Line, QSz);   // Try again (non-blocking if FPushTimeout=0)
        end;
    else
      {--- wrAbandoned, wrError: we ignore (best-effort) }
    end;
  except
    {--- Best effort: never escalate to DoOnListen }
  end;
end;

procedure TSessionEventLogger.EnsureStopped_NoLock;
begin
  if not FActive then Exit;

  FActive := False;
  if Assigned(FTask) then
    FTask.Wait;

  FreeAndNil(FQueue);
  FTask := nil;
  FLogFile := EmptyStr;
end;

procedure TSessionEventLogger.StopSession;
begin
  FLock.Acquire;
  try
    EnsureStopped_NoLock;
  finally
    FLock.Release;
  end;
end;

end.
