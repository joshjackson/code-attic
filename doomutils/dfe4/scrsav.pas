{
        SCRSAV.PAS - A ScreenSaving unit (version 4) for TurboVision 2.0


        This ScreenSaving-unit for TurboVision 2.0 is (c) by Edwin Groothuis
        You are allowed to use this unit in your programs if you agree to
        these two rules:

        1. You give me proper credit in the documentation of the program.
        2. You tell me you're using this unit.

        If you don't agree with these two rules, you're not allowed to
        use it!

        How to use this ScreenSaving-unit:

        Initialisation:

        - Add the ScrSav-unit to the uses-command.
        - Make the (global) variable ScreenSaver as PScreenSaver
        - In the Initialisation of an Application, put the following
          line behind the Inherited Init:
            Inherited Init;
            ScreenSaver:=New(PScreenSaver,Init(MakeStandardScreenSaver,6));

        Heartbeat:
        To tell the ScreenSaver that the user isn't idle at this moment,
        put the following line in the Application^.GetEvent:
          Inherited GetEvent(E);
          if E.What<>evNothing then
            if ScreenSaver<>nil then
              if E.What=evKeyDown then
              begin
                if ScreenSaver^.Saving then
                  E.What:=evNothing;
                ScreenSaver^.HeartBeat;
              end else
                if E.What and evMouse<>0 then
                  ScreenSaver^.HeartBeat;

        CountDown:
        To let the ScreenSaver know the user is idle at this moment, put
        the following line in the Application^.Idle:
          Inherited Idle;
          if ScreenSaver<>nil then
            ScreenSaver^.CountDown;

        Options:
        What is a ScreenSaver without options? You can change the
        options by calling the ScreenSaver^.Options-procedure. The user
        gets a nice options-dialog and he can change some settings. If
        you have added more ScreenSaver-modules, please add them in the
        constants ScreenSaverNames and ScreenSaverProcs. Make sure you
        put them in alphabetic order!


        Now start your application. After 6 seconds your screen will
        go blank. There are several ScreenSavers designed by me, if
        you have created more, I would like to have a copy of them ;-)

        A small note about the use of a delay in the ScreenSaver^.Update:
        It's not nice to use the Delay-function of the Crt-unit. Instead
        of using that, you'd better check if a certain time (100 ms, 200 ms
        and so on) has elapsed. See the StarFieldScreenSaver.Update-function
        for an example of it.

        Send all your suggestions/money/cards (I love to get cards from
        people who are using my programs) to:

        Edwin Groothuis                ECA-BBS
        Johann Strausslaan 1           tel. +31-40-550352 (up to 14k4/V42b)
        5583ZA Aalst-Waalre            FTN: 2:284/205@fidonet
        The Netherlands                     115:3145/102@pascal-net
                                       request SCRSAV for the last version!
}


unit      ScrSav;

interface

uses      Views,Objects;

type      PScreenSaver=^TScreenSaver;
          TScreenSaver=object
                         constructor Init(_W:PView;Time:word);
                         destructor Done;
                         procedure Activate;
                         procedure Deactivate;
                         procedure HeartBeat;
                         procedure CountDown;
                         procedure Update;virtual;
                         function  Saving:boolean;
                         procedure Options;
                         procedure Enable(b:boolean);
                       private
                         W:PView;
                         LastBeat:longint;
                         _Saving:boolean;
                         SavedScreen:pointer;
                         SavingTime:word;
                         CursorVisible:boolean;
                         Enabled:boolean;
                         Testing:boolean;
                       end;


type      PStandardScreenSaver=^TStandardScreenSaver;
          TStandardScreenSaver=object(TView)
                                 constructor Init;
                                 procedure Draw;virtual;
                               end;


function  MakeStandardScreenSaver  :PStandardScreenSaver;
function  MakeMovingStarScreenSaver:PStandardScreenSaver;
function  MakeWormScreenSaver      :PStandardScreenSaver;
function  MakeStarFieldScreenSaver :PStandardScreenSaver;


implementation

uses      Drivers,App,Dialogs,InpLong;

const     NumScreenSavers=4;
const     ScreenSaverNames:array[0..NumScreenSavers-1] of string[20]=
                            (
                             'Moving Star',
                             'Standard',
                             'Starfield',
                             'Worm'
                             );
          ScreenSaverProcs:array[0..NumScreenSavers-1] of function:
                            PStandardScreenSaver=(
                                                  MakeMovingStarScreenSaver,
                                                  MakeStandardScreenSaver,
                                                  MakeStarfieldScreenSaver,
                                                  MakeWormScreenSaver
                                                  );

const     cmTest=1000;

{----------------------------------------------------------------------------}
{ Object-definitions of the screensave-routines. Note that these are not the
  screensaverobject!                                                         }
type      PMovingStarScreenSaver=^TMovingStarScreenSaver;
          TMovingStarScreenSaver=object(TStandardScreenSaver)
                                   constructor Init;
                                   procedure Draw;virtual;
                                 private
                                   dx,dy,x,y:array[1..10] of integer;
                                   LastUpdate:longint;
                                 end;

          PWormScreenSaver=^TWormScreenSaver;
          TWormScreenSaver=object(TStandardScreenSaver)
                             constructor Init;
                             procedure Draw;virtual;
                           private
                             x,y:array[1..10] of integer;
                             states:array[1..10] of char;
                             dx,dy:integer;
                             LastUpdate:longint;
                           end;

          PStarFieldScreenSaver=^TStarFieldScreenSaver;
          TStarFieldScreenSaver=object(TStandardScreenSaver)
                                   constructor Init;
                                   procedure Draw;virtual;
                                 private
                                   states:array[1..7] of char;
                                   starstate,x,y:array[1..10] of integer;
                                   LastUpdate:longint;
                                 end;

{----------------------------------------------------------------------------}
{ Object-definition of the screensaver                                       }
type      PScrSavDialog=^TScrSavDialog;
          TScrSavDialog=object(TDialog)
                          UserSavingTime:PInputLine;
                          LB:PListBox;
                          TestButton:PButton;
                          Timer:PRadioButtons;

                          procedure HandleEvent(var E:TEvent);virtual;
                        end;

var       CurrentScreenSaver:PScreenSaver;

{----------------------------------------------------------------------------}
{----------------------------------------------------------------------------}
{ Initialise the ScreenSaver.
  Notes:
    *18.2 is because the timertick goes 18.2 times/second                    }
constructor TScreenSaver.Init(_W:PView;Time:word);
begin
  _Saving:=false;
  SavingTime:=round(Time*18.2);
  HeartBeat;
  W:=_W;
  Enabled:=true;
  Testing:=false;
  CurrentScreenSaver:=@Self;
end;

{----------------------------------------------------------------------------}
{ Disposes the ScreenSaver                                                   }
destructor TScreenSaver.Done;
begin
  if W<>nil then
    Dispose(W,Done);
  CurrentScreenSaver:=nil;
end;

{----------------------------------------------------------------------------}
{ Activate the ScreenSaver
  First, allocate the memory for the Screen.
  Second, copy the contents of the screen to the allocated memory.           }
procedure TScreenSaver.Activate;
begin
  if Enabled then
  begin
    _Saving:=true;
    GetMem(SavedScreen,ScreenWidth*ScreenHeight*2);
    Move(ScreenBuffer^,SavedScreen^,ScreenWidth*ScreenHeight*2);
    if W<>nil then
      Desktop^.Insert(W);
    Update;
  end;
end;

{----------------------------------------------------------------------------}
{ Deactivate the ScreenSaver.
  First, copy the contents of the SavedScreen to the ScreenBuffer.
  Second, dispose the memory allocated
  Third, give the application a Redraw                                       }
procedure TScreenSaver.Deactivate;
begin
  if W<>nil then
    Desktop^.Delete(W);
  Move(SavedScreen^,ScreenBuffer^,ScreenWidth*ScreenHeight*2);
  FreeMem(SavedScreen,ScreenWidth*ScreenHeight*2);
  Application^.Redraw;
  _Saving:=false;
  if Testing then
  begin
    Testing:=false;
    Enabled:=false;
  end;
end;

{----------------------------------------------------------------------------}
{ The use is doing something, so stop the CountDown
  First, deactivate the ScreenSaver if Saving
  Second, update the timer                                                   }
procedure TScreenSaver.HeartBeat;
var       TT:longint absolute $40:$6c;
begin
  if Saving then Deactivate;
  LastBeat:=TT;
end;

{----------------------------------------------------------------------------}
{ CountDown to the SavingTime
  If not yet saving, look if it's time to save. If saving, update the screen }
procedure TScreenSaver.CountDown;
var       TT:longint absolute $40:$6c;
begin
  if not Saving then
  begin
    if (TT-LastBeat>SavingTime) then Activate;
  end else begin
    Update;
  end;
end;

{----------------------------------------------------------------------------}
{ Update
  Update the ScreenSaving-procedure. Override this one if you want a custom
  ScreenSaver                                                                }
procedure TScreenSaver.Update;
begin
  if Enabled then
    if W<>nil then
      W^.Draw;
end;

{----------------------------------------------------------------------------}
{ Saving
  Returns true if the Screen is being Saved.                                 }
function  TScreenSaver.Saving:boolean;
begin
  Saving:=_Saving;
end;


{----------------------------------------------------------------------------}
{----------------------------------------------------------------------------}
{ Handles the events for the options-dialog. The only exception that is
  really handled by this procedure is the command cmTest: Test the
  screensaver                                                                }
procedure TScrSavDialog.HandleEvent(var E:TEvent);
var       V:longint;
          W:Word;
begin
  if E.What<>evNothing then
  begin
    if Timer^.State and sfFocused<>0 then
    begin
      Inherited HandleEvent(E);
      Timer^.GetData(w);
      UserSavingTime^.SetState(sfDisabled,false);
      if W<>6 then
      begin
        case W of
          0: v:=30;
          1: v:=60;
          2: v:=120;
          3: v:=180;
          4: v:=240;
          5: v:=300;
        end;
        UserSavingTime^.SetData(v);
        UserSavingTime^.Draw;
        UserSavingTime^.SetState(sfDisabled,true);
      end;
    end;
    if E.What=evCommand then
      if E.Command=cmTest then
      begin
        Dispose(CurrentScreenSaver^.W,Done);
        CurrentScreenSaver^.W:=ScreenSaverProcs[LB^.Focused];

        CurrentScreenSaver^.Enabled:=true;
        CurrentScreenSaver^.Testing:=true;
        CurrentScreenSaver^.Activate;
      end;
  end;
  Inherited HandleEvent(E);
end;


{----------------------------------------------------------------------------}
{ Options
  Pops up a dialogbox with several functions, like enable/disable, time to
  save, which screensaver etc                                                }
procedure TScreenSaver.Options;
 function  MakeDialog : PScrSavDialog;
 var       Dlg : PScrSavDialog;
           R : TRect;
           Control : PView;
 begin
   R.Assign(4, 1, 49, 16);
   New(Dlg, Init(R, 'Screen Saver'));
   Dlg^.Options:=Dlg^.Options or ofCentered;

   R.Assign(2, 3, 20, 10);
   Dlg^.Timer := New(PRadioButtons, Init(R,
   NewSItem('30 seconds', NewSItem('60 seconds',
   NewSItem('120 seconds',NewSItem('180 seconds',
   NewSItem('240 seconds',NewSItem('300 seconds',
   NewSItem('user defined', Nil)))))))));
   Dlg^.Insert(Dlg^.Timer);

   R.Assign(1, 2, 13, 3);
   Dlg^.Insert(New(PLabel, Init(R, 'Saving time', Control)));

   R.Assign(6, 10, 20, 11);
   Dlg^.UserSavingTime := New(PInputLong, Init(R, 12, 0, 3600, 0));
   Dlg^.Insert(Dlg^.UserSavingTime);

   R.Assign(42, 3, 43, 7);
   Control := New(PScrollBar, Init(R));
   Dlg^.Insert(Control);

   R.Assign(22, 3, 42, 7);
   Dlg^.LB:= New(PListBox, Init(R, 1, PScrollbar(Control)));
   Dlg^.Insert(Dlg^.LB);

   R.Assign(21, 2, 33, 3);
   Dlg^.Insert(New(PLabel, Init(R, 'Which saver', Control)));

   R.Assign(22, 8, 42, 10);
   Control := New(PRadioButtons, Init(R,
   NewSItem('Enable saver',NewSItem('Disable saver', Nil))));
   Dlg^.Insert(Control);

   R.Assign(3, 12, 13, 14);
   Control := New(PButton, Init(R, 'O~K~', cmOK, bfDefault));
   Dlg^.Insert(Control);

{   R.Assign(17, 12, 27, 14);
   Control := New(PButton, Init(R, 'Cancel', cmCancel, bfNormal));
   Dlg^.Insert(Control);
}
   R.Assign(32, 12, 42, 14);
   Dlg^.TestButton := New(PButton, Init(R, 'Test', cmTest, bfNormal));
   Dlg^.Insert(Dlg^.TestButton);

   Dlg^.SelectNext(False);
   MakeDialog := Dlg;
 end;
type      TListBoxRec = record    {<-- omit if TListBoxRec is defined elsewhere}
                          PS : PStringCollection;
                          Selection : Integer;
                        end;
var       d:PScrSavDialog;
          DataRec : record
                      SavingTime : Word;
                      UserSavingTime : LongInt;
                      WhichSaver : TListBoxRec;
                      Enabled : Word;
                    end;
          s:string;
          i:word;
begin
  d:=MakeDialog;
  DataRec.SavingTime:=6;
  DataRec.UserSavingTime:=round(SavingTime/18.2);
  if Enabled then
    DataRec.Enabled:=0
  else
    DataRec.Enabled:=1;
  d^.UserSavingTime^.SetState(sfDisabled,true);
  DataRec.WhichSaver.PS:=New(PStringCollection,Init(5,5));
  for i:=0 to NumScreenSavers-1 do
    DataRec.WhichSaver.PS^.Insert(NewStr(ScreenSaverNames[i]));
  DataRec.WhichSaver.Selection:=0;
  d^.SetData(DataRec);
  d^.LB^.Draw;
  Enabled:=false;
  if (desktop^.execview(d))=cmOk then
  begin
    d^.GetData(DataRec);
    SavingTime:=round(DataRec.UserSavingTime*18.2);
    Enabled:=DataRec.Enabled=0;
    Dispose(CurrentScreenSaver^.W,Done);
    CurrentScreenSaver^.W:=ScreenSaverProcs[d^.LB^.Focused];
  end;
  DataRec.WhichSaver.PS^.Done;
  dispose(d);
end;

{----------------------------------------------------------------------------}
{ Enable or disable the screensaver                                          }
procedure TScreenSaver.Enable(b:boolean);
begin
  if b then
    Enabled:=true
  else
    Enabled:=false;
end;


{----------------------------------------------------------------------------}
{----------------------------------------------------------------------------}
function   MakeStandardScreenSaver:PStandardScreenSaver;
var        S:PStandardScreenSaver;
begin
  S:=new(PStandardScreenSaver,Init);
  MakeStandardScreenSaver:=S;
end;

{----------------------------------------------------------------------------}
constructor TStandardScreenSaver.Init;
var         R:TRect;
begin
  Application^.GetExtent(R);
  Inherited Init(R);
end;

{----------------------------------------------------------------------------}
procedure TStandardScreenSaver.Draw;
begin
  ClearScreen;
end;


{----------------------------------------------------------------------------}
{ The rest are examples of different ScreenSavers.                           }
{----------------------------------------------------------------------------}
{----------------------------------------------------------------------------}
function   MakeMovingStarScreenSaver:PStandardScreenSaver;
var        S:PMovingStarScreenSaver;
begin
  S:=new(PMovingStarScreenSaver,Init);
  MakeMovingStarScreenSaver:=S;
end;

{----------------------------------------------------------------------------}
constructor TMovingStarScreenSaver.Init;
var         i:byte;
begin
  Inherited Init;
  Randomize;
  for i:=1 to 10 do
  begin
    x[i]:=random(ScreenWidth div 2)+(ScreenWidth div 4);
    y[i]:=random(ScreenHeight div 2)+(ScreenHeight div 4);
    dx[i]:=random(2);if dx[i]=0 then dx[i]:=-1;
    dy[i]:=random(2);if dy[i]=0 then dy[i]:=-1;
  end;
end;

{----------------------------------------------------------------------------}
procedure TMovingStarScreenSaver.Draw;
var       i:byte;
          TT:longint absolute $40:$6c;
          B:TDrawBuffer;
begin
  if TT-LastUpdate>2 then
  begin
    LastUpdate:=TT;
    ClearScreen;
    for i:=1 to 10 do
    begin
      if x[i] in [0,ScreenWidth-3]  then dx[i]:=-dx[i];
      if y[i] in [0,ScreenHeight-3] then dy[i]:=-dy[i];
      inc(x[i],dx[i]);inc(y[i],dy[i]);
      MoveChar(B,'*',i,1);
      WriteLine(x[i],y[i],1,1,B);
    end;
  end;
end;

{----------------------------------------------------------------------------}
{----------------------------------------------------------------------------}
function   MakeWormScreenSaver:PStandardScreenSaver;
var        S:PWormScreenSaver;
begin
  S:=new(PWormScreenSaver,Init);
  MakeWormScreenSaver:=S;
end;

{----------------------------------------------------------------------------}
constructor TWormScreenSaver.Init;
var         i:byte;
            xx,yy:byte;
begin
  Inherited Init;
  States[10]:=' ';
  States[9]:=#2;States[8]:=#2;
  States[7]:=#2;States[6]:=#2;
  States[5]:=#2;States[4]:=#2;
  States[3]:=#2;States[2]:=#1;

  Randomize;
  xx:=(random(ScreenWidth div 2)+(ScreenWidth div 4)) mod ScreenWidth;
  yy:=(random(ScreenHeight div 2)+(ScreenHeight div 4)) mod ScreenHeight;
  for i:=1 to 10 do
  begin
	 x[i]:=xx;
	 y[i]:=yy;
  end;
  dx:=random(2);if dx=0 then dx:=-1;
  dy:=random(2);if dy=0 then dy:=-1;
end;

{----------------------------------------------------------------------------}
procedure TWormScreenSaver.Draw;
var       i:byte;
			 TT:longint absolute $40:$6c;
			 B:TDrawBuffer;
begin
  if TT-LastUpdate>2 then
  begin
	 LastUpdate:=TT;
	 ClearScreen;
	 if x[1]<1              then begin dx:=-dx;dy:=-random(3)+1;end;
	 if x[1]>ScreenWidth-4  then begin dx:=-dx;dy:=-random(3)+1;end;
	 if y[1]<1              then begin dy:=-dy;dx:=-random(3)+1; end;
	 if y[1]>ScreenHeight-4 then begin dy:=-dy;dx:=-random(3)+1;end;
	 for i:=10 downto 2 do
	 begin
		if i > 2 then
			MoveChar(B,States[i],2,1)
		else
			MoveChar(B,States[i],14,1);
		WriteLine(x[i],y[i],1,1,B);
		x[i]:=x[i-1];
		y[i]:=y[i-1];
	 end;
	 inc(x[1],dx);inc(y[1],dy);
	 x[1]:=x[1] mod ScreenWidth;
	 y[1]:=y[1] mod ScreenHeight;
  end;
end;


{----------------------------------------------------------------------------}
{----------------------------------------------------------------------------}
function   MakeStarfieldScreenSaver:PStandardScreenSaver;
var        S:PStarFieldScreenSaver;
begin
  S:=new(PStarFieldScreenSaver,Init);
  MakeStarfieldScreenSaver:=S;
end;

{----------------------------------------------------------------------------}
constructor TStarFieldScreenSaver.Init;
var         i:byte;
            R:TRect;
begin
  Inherited Init;
  Randomize;
  States[1]:='ú';States[2]:='ù';States[3]:='';
  States[4]:='o';States[5]:='*';States[6]:='';States[7]:=' ';
  for i:=1 to 10 do
  begin
    x[i]:=random(ScreenWidth-1)+2;
    y[i]:=random(ScreenHeight-1)+2;
    starstate[i]:=random(7)+1;
  end;
end;

{----------------------------------------------------------------------------}
procedure TStarFieldScreenSaver.Draw;
var       i:byte;
          TT:longint absolute $40:$6c;
          B:TDrawBuffer;
begin
  if TT-LastUpdate>2 then
  begin
    LastUpdate:=TT;
    ClearScreen;
    for i:=1 to 10 do
    begin
      MoveChar(B,States[StarState[i]],i,1);
      WriteLine(x[i],y[i],1,1,B);
      StarState[i]:=(StarState[i] mod 7)+1;
      if StarState[i]=1 then
      begin
        x[i]:=random(ScreenWidth)+1;
        y[i]:=random(ScreenHeight)+1;
      end;
    end;
  end;
end;

{----------------------------------------------------------------------------}

begin
  CurrentScreenSaver:=nil;
end.
