unit thread_re;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, RegExpr, dateutils;

Type
   TShowStatusEvent = procedure(Status: String) of Object;
   TGetResultEvent = procedure(Result: TRegExpr) of Object;

   TMyThread = class(TThread)
   private
     FIsDebug: boolean;
     fStatusText : string;
     FOnShowStatus: TShowStatusEvent;
     FOnGetResult: TGetResultEvent;
     FRe: TRegExpr;
     FResultCount: int64;
     FStartTime: TDateTime;

     procedure DebugSleep;
   protected
     procedure Execute; override;
     procedure ShowStatus;
     procedure GetResult;
   public

     Constructor Create(CreateSuspended : boolean);
     destructor Destroy; override;

     property StatusText : string read fStatusText;

     property Re: TRegExpr read FRe write FRe;
     property ResultCount: Int64 read FResultCount;
     property StartTime: TDateTime  read FStartTime;
     property IsDebug: Boolean read FIsDebug write FIsDebug;
     property OnShowStatus: TShowStatusEvent read FOnShowStatus write FOnShowStatus;
     property OnGetResult: TGetResultEvent read FOnGetResult write FOnGetResult;
     function GetTimeout: integer;
   end;

implementation

function TMyThread.GetTimeout: integer;
var
  dNow, dThen: TDateTime;
begin
  dNow  := Now();
  dThen := FStartTime;

  Result :=  SecondsBetween(dNow,dThen);
end;

procedure TMyThread.ShowStatus;
begin
  if Assigned(FOnShowStatus) then
  begin
    FOnShowStatus(fStatusText);
  end;
end;


procedure TMyThread.GetResult;
begin
  if Assigned(FOnGetResult) then
  begin
    FOnGetResult(FRe);
  end;
end;

constructor TMyThread.Create(CreateSuspended : boolean);
begin

  IsDebug:=False;
  FreeOnTerminate:=False;

  FRe := TRegExpr.Create;

  FResultCount := 0;

  Synchronize(@Showstatus);

  inherited Create(CreateSuspended);
end;



destructor TMyThread.Destroy;
var
  i: integer;
begin
 FRe.Free;
end;

procedure TMyThread.DebugSleep;
begin
 if (FIsDebug) then Sleep(500);
end;

procedure TMyThread.Execute;
var
  newStatus : string = '0';
begin

  FResultCount := 0;
  FStartTime   := Now;

  fStatusText := 'Starting...';
  Synchronize(@Showstatus);
  DebugSleep;

  try

  FRe.InputString := 'i?'+FRe.InputString;
  if (not FRe.Exec(FRe.InputString)) then Terminate
  else
   begin

     fStatusText := 'Running...';
     FResultCount := FResultCount + 1;

     DebugSleep;
     Synchronize(@Showstatus);
     DebugSleep;
     Synchronize(@GetResult);
     DebugSleep;


  while (not Terminated) and (FRe.ExecNext()) do
    begin
      FResultCount := FResultCount + 1;

      DebugSleep;
      Synchronize(@GetResult);
      DebugSleep;
    end;

  end;

  Except
    On ERegExpr do
     begin
      DebugSleep;
      fStatusText := 'Error in expression!';
      Synchronize(@Showstatus);
      DebugSleep;
      Exit;
     end;
  end;

  DebugSleep;
  fStatusText := 'Terminated...';
  Synchronize(@Showstatus);
  DebugSleep;
end;

end.




