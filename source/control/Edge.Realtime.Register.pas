unit Edge.Realtime.Register;

interface

uses
  System.Classes,
  {$IFDEF DESIGNTIME}
  DesignIntf,
  {$ENDIF}
  Edge.Realtime.Control;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Edge Audio', [TEdgeRealtimeControl]);
end;

end.
