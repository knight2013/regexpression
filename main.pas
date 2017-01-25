unit main;

{$mode objfpc}{$H+}

interface

uses
  {$ifdef unix}
  cthreads,
  cmem, // the c memory manager is on some systems much faster for multi-threading
{$endif}
  Classes, SysUtils, FileUtil, SynMemo, SynEdit, SynHighlighterAny, Forms,
  Controls, Graphics, Dialogs, StdCtrls, ExtCtrls, ComCtrls, thread_re,
  dateutils, RegExpr, ShellApi;

type

  { TForm1 }

  TForm1 = class(TForm)
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    cbxGroups: TComboBox;
    CheckBox1: TCheckBox;
    CheckBox2: TCheckBox;
    CheckBox3: TCheckBox;
    CheckBox4: TCheckBox;
    CheckBox5: TCheckBox;
    CheckBox6: TCheckBox;
    Edit1: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    lblMatched: TLabel;
    lbAnswer: TListBox;
    memAnswer: TSynMemo;
    memGroupMember: TSynMemo;
    Panel1: TPanel;
    Panel2: TPanel;
    Panel4: TPanel;
    Panel5: TPanel;
    pnlGroups: TPanel;
    Panel3: TPanel;
    Splitter1: TSplitter;
    Splitter2: TSplitter;
    Splitter3: TSplitter;
    StatusBar1: TStatusBar;
    SynAnySyn1: TSynAnySyn;
    memExp: TSynMemo;
    memText: TSynMemo;
    Timer1: TTimer;
    UpDown1: TUpDown;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure cbxGroupsClick(Sender: TObject);
    procedure cbxGroupsCloseUp(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure Label6Click(Sender: TObject);
    procedure lbAnswerClick(Sender: TObject);
    procedure StartEnabled(AEnabled: boolean);
    procedure OnShowStatus(Status: string);
    procedure OnGetResult(Result: TRegExpr);
    procedure OnTerminate(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  Form1: TForm1;
  MyThread: TMyThread;
  Terminated: boolean;

implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.StartEnabled(AEnabled: boolean);
begin
 Button1.Enabled := AEnabled;
 Button2.Enabled := not AEnabled;
 memExp.ReadOnly  := not AEnabled;
 memText.ReadOnly := not AEnabled;
 Panel1.Enabled  := AEnabled;
end;

procedure TForm1.Button1Click(Sender: TObject);
begin
  lbAnswer.Clear;

  pnlGroups.Hide;

  Button2Click(nil);

  StartEnabled(False);


  MyThread := TMyThread.Create(true);
  MyThread.OnShowStatus :=@OnShowStatus;
  MyThread.OnGetResult :=@OnGetResult;
  MyThread.OnTerminate:=@OnTerminate;

  MyThread.Re.Expression:=  Trim(memExp.Text);
  MyThread.Re.InputString:= memText.Text;

  MyThread.Re.ModifierM := CheckBox1.Checked;
  MyThread.Re.ModifierG := CheckBox2.Checked;
  MyThread.Re.ModifierI := CheckBox3.Checked;
  MyThread.Re.ModifierR := CheckBox4.Checked;
  MyThread.Re.ModifierS := CheckBox5.Checked;
  MyThread.Re.ModifierX := CheckBox6.Checked;

  //MyThread.FreeOnTerminate:=True;
  MyThread.IsDebug:=False;
  MyThread.Start;

  Terminated := False;

end;

procedure TForm1.Button2Click(Sender: TObject);
begin

    if (MyThread<>nil) then
     begin

       StatusBar1.Panels[0].Text:='Status: Terminated';

       Terminated := True;
       MyThread.Terminate;
      end;

end;

procedure TForm1.Button3Click(Sender: TObject);
begin
  Close;
end;

procedure TForm1.cbxGroupsClick(Sender: TObject);
begin

end;

procedure TForm1.cbxGroupsCloseUp(Sender: TObject);
var
  re: TRegExpr;
begin
  re:= TRegExpr.Create;
  Re.Expression:=memExp.Text;
  Re.Exec(memAnswer.Text);
  memGroupMember.Text := Re.Match[ TComboBox(Sender).ItemIndex + 1];
  re.Free;

end;

procedure TForm1.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  if (MyThread<>nil) then
   begin
     MyThread.Terminate;
     while (MyThread<>nil) do Application.ProcessMessages;
   end;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  memExp.Clear;
  memText.Clear;
  memAnswer.Clear;
  memGroupMember.Clear;
end;

procedure TForm1.Label6Click(Sender: TObject);
begin
  ShellExecute(0,nil, PChar('cmd'),PChar('/c start http://'+TLabel(Sender).Caption+'/'),nil,0)
end;

function CalcGroupStr(memExpText, memAnswerText: AnsiString): integer;
var
  re: TRegExpr;
  i, cnt: integer;
begin
  i:= 0;
  Result := 0;
  re:= TRegExpr.Create;
  Re.Expression:=memExpText;
  if Re.Exec(memAnswerText) then
    begin
      while Re.MatchPos[i]<>-1 do
        i:= i + 1;
      Result := i -1;
    end;

  re.Free;

end;

procedure TForm1.lbAnswerClick(Sender: TObject);
var i, cnt: integer;
begin

  if lbAnswer.ItemIndex < 0 then Exit;

  memAnswer.Lines.Text:=lbAnswer.Items[lbAnswer.ItemIndex];

  cbxGroups.Clear;

  cnt := CalcGroupStr(memExp.Text, memAnswer.Text) ;

  for i:= 0 to cnt-1 do
    cbxGroups.Items.Add('Group '+IntToStr(i+1));

  if (cnt=0) then
    begin
     pnlGroups.Hide;
    end
  else
   begin
    cbxGroups.ItemIndex:=0;
    pnlGroups.Show;
    cbxGroupsCloseUp(cbxGroups);
   end;

end;

procedure TForm1.OnTerminate(Sender: TObject);
begin

 Terminated := True;
 StartEnabled(True);
 FreeAndNil(MyThread);

end;

procedure TForm1.OnShowStatus(Status: string);
begin
  StatusBar1.Panels[0].Text:='Status: ' + Status;
end;

procedure TForm1.OnGetResult(Result: TRegExpr);
begin
    lbAnswer.Items.Add( Result.Match[0] );

    StatusBar1.Panels[2].Text:='Result: ' + leftStr(Result.Match[0], 255);

    lblMatched.Caption := 'Matched: ' + IntToStr(MyThread.ResultCount);

end;

procedure TForm1.Timer1Timer(Sender: TObject);
begin
if (MyThread<>nil) and (not Terminated) then
   begin


    StatusBar1.Panels[1].Text:='Time,sec: ' + IntToStr( MyThread.GetTimeout );


     if ( MyThread.GetTimeout > UpDown1.Position ) then
         begin
          KillThread(MyThread.Handle);


          StatusBar1.Panels[0].Text:='Status: Timeout';
          StatusBar1.Panels[2].Text:='';
          StatusBar1.Panels[1].Text:='';


          StartEnabled(True);

          FreeAndNil(MyThread);

         end;
   end;
end;

end.

