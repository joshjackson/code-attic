
Program Sendnet4;

Uses 
      {Turbo Vision Interface Units}
Objects,App,Menus,Dialogs,Views,MsgBox,Drivers, Status,
      {Other Stuff}
Timer, Crt,
      {IPX Network Interface Units}
IPX, Network, Server,
      {Windows 95 Support}
Win95API;

Type TSendnet =   Object(TApplication)
    Server:   TServer;
    ServerInitialized:   boolean;
    StatusWindow:   PServerStatus;
    ConnectionStatus:   PConnectionStatus;
    OldTics:   longint;
    Constructor Init;
    Procedure InitMenuBar;
    virtual;
    Function GetPalette:   PPalette;
    virtual;
    Procedure Idle;
    virtual;
    Procedure HandleEvent(Var Event:TEvent);
    virtual;
    Procedure DisplayStatus;
    Procedure ConnectStatus;
    Procedure TerminateConnection;
    Procedure About;
    Function Valid(Command: Word):   Boolean;
    virtual;
    Destructor Done;
    virtual;
End;

TQuickServer =   Object
    Server:   TServer;
    ServerInitialized:   boolean;
    OldTics:   longint;
    Constructor Init;
    Procedure Run;
    Destructor Done;
End;

Constructor TSendnet.Init;

Var E:   TEvent;

Begin
    TApplication.Init;
    InitTimer;
    ServerInitialized := False;
      {Check to see if IPX is installed}
    If Not IPXInstalled Then
        Begin
            MessageBox('Fatal Error: IPX not detected.',Nil,$0401);
            E.What := evCommand;
            E.Command := cmQuit;
            E.InfoPtr := Nil;
            PutEvent(E);
        End
    Else
        Begin
       {Attempt to initialize the server}
            Server.Init;
            If Not Server.ServerInitOk Then
                Begin
                    MessageBox('TServer.Init:'+Server.ServerError,Nil,$0401);
                    E.What := evCommand;
                    E.Command := cmQuit;
                    E.InfoPtr := Nil;
                    PutEvent(E);
                End
            Else
                Begin
                    ServerInitialized := True;
                    StatusWindow := New(PServerStatus, Init(@Server));
                    Desktop^.Insert(StatusWindow);
                    ConnectionStatus := New(PConnectionStatus, Init);
                    DisableCommands([cmDisplayStatus, cmConnectStatus]);
                    Desktop^.Insert(ConnectionStatus);
                End;
        End;
End;

Procedure TSendnet.InitMenuBar;

Var R:   TRect;

Begin
    GetExtent(r);
    R.B.Y := 1;
    MenuBar := New(PMenuBar,Init(r,NewMenu(
               NewSubMenu('~S~erver',hcNoContext,NewMenu(
               NewItem('~A~bout','',0,cmAboutServer,hcNoContext,
               NewLine(
               NewItem('~S~tatus','',0,cmDisplayStatus,hcNoContext,
               NewItem('~C~onnections','',0,cmConnectStatus,hcNoContext,
               NewItem('Shut ~D~own','Alt-X',kbAltX,cmQuit,hcNoContext,
               Nil)))))),
               Nil))));
End;

Function TSendnet.GetPalette:   PPalette;

Const MyBackColor:   TPalette =   CColor;

Var t:   integer;

Begin
    For t:=8 To 15 Do
        MyBackColor[t+24] := MyBackColor[t];
    MyBackColor[46] := #16;
    MyBackColor[50] := #15;
    MyBackColor[42] := #$2F;
    MyBackColor[17] := #24;
    MyBackColor[47] := #23;
    MyBackColor[48] := #31;
    MyBackColor[49] := #30;
    GetPalette := @MyBackColor;
End;

Procedure TSendnet.Idle;

Begin
    TApplication.Idle;
    If ServerInitialized Then
        Begin
            Server.ProcessEvents;
            If (TimerTotal - OldTics) > 9 Then
                Begin
                    StatusWindow^.Update;
                    ConnectionStatus^.Update;
                    OldTics := TimerTotal;
                End;
        End;
End;

Procedure TSendnet.HandleEvent(Var Event:TEvent);

Begin
    TApplication.HandleEvent(Event);
    If Event.What = evCommand Then
        Begin
            Case Event.Command Of 
                cmDisplayStatus:   DisplayStatus;
                cmAboutServer:   About;
                cmConnectStatus:   ConnectStatus;
                cmTerminateConnection:   TerminateConnection;
            End;
        End;
End;

Procedure TSendnet.DisplayStatus;

Begin
    DisableCommands([cmDisplayStatus]);
    StatusWindow^.Show;
End;

Procedure TSendnet.ConnectStatus;

Begin
    DisableCommands([cmConnectStatus]);
    ConnectionStatus^.Show;
End;

Procedure TSendnet.TerminateConnection;

Var ConnNo:   longint;

Begin
    ConnNo := ConnectionStatus^.ConnectionList^.Value + 1;
    If ConnectionTable^[ConnNo].IsConnected Then
        If MessageBox('Are you sure you wish to terminate this connection?',Nil,
           $0303) = cmYes Then
            Server.KillUser(ConnNo);
End;

Procedure TSendnet.About;

Var Box:   PAboutBox;

Begin
    Box := New(PAboutBox, Init);
    Desktop^.ExecView(Box);
    Dispose(Box, Done);
End;

Function TSendNet.Valid(Command: Word):   Boolean;

Begin
    If (Command=cmQuit) And (Server.ActiveConnections > 0) And ServerInitialized
        Then
        Begin
            If MessageBox(
               'There are active connections, are you sure you wish to shut down the server?'
               ,
               Nil, $0303) = cmYes Then
                Valid := True
            Else
                Valid := False;
        End
    Else
        TApplication.Valid(Command);
End;

Destructor TSendnet.Done;

Begin
    If ServerInitialized Then
        Begin
            Dispose(StatusWindow, Done);
            Dispose(ConnectionStatus, Done);
            Server.Done;
        End;
    DoneTimer;
    TApplication.Done;
End;

Procedure DisplayHelp;

Begin
    Writeln;
    writeln('USAGE: SENDNET4 [-ql]');
    writeln;
    writeln('   -q    Forces the server to run in Quick mode. See the readme');
    writeln('         for more info on Quick mode.');
    writeln('   -l    Disable long filename support even if Win95 is running.');
End;

Procedure InitParams;

Var Help:   boolean;
    tmpstr:   string;
    t1,t2:   integer;

Begin
    Help := False;
    If ParamCount = 0 Then
        Begin
            Help := False;
            exit;
        End;
    For t1:=1 To ParamCount Do
        Begin
            tmpstr := ParamStr(t1);
            If (tmpstr[1] = '-') Or (tmpstr[1] = '/') Then
                Begin
                    For t2:=2 To Length(tmpstr) Do
                        Begin
                            Case upcase(tmpstr[t2]) Of 
                                'H':   Help := True;
                                'Q':   QuickServe := True;
                                'L':   LFNSupport := False;
                                Else
                                    Begin
                                        Help := True;
                                        Break;
                                    End;
                            End;
                        End;
                    If Help Then
                        Begin
                            DisplayHelp;
                            Halt(1);
                        End;
                End;
        End;
End;

Constructor TQuickServer.Init;

Begin
    InitTimer;
    ServerInitialized := False;
      {Attempt to initialize the server}
    Server.Init;
    If Not Server.ServerInitOk Then
        writeln('Server initialization failure.')
    Else
        ServerInitialized := True;
    OldTics := TimerTotal;
End;

Procedure TQuickServer.Run;

Const StatChars:   array[0..3] Of char =   '-\|/';

Var c:   char;
    cnt:   byte;
    x,y:   integer;

Procedure DisplayStats;

Begin
    inc(cnt);
    gotoxy(x,y);
    write(StatChars[cnt Mod 4]);
End;

Begin
    x := WhereX;
    y := WhereY;
    While Server.RunCycle Do
        Begin
            If (TimerTotal - OldTics) > 3 Then
                Begin
                    DisplayStats;
                    OldTics := TimerTotal;
                End;
            If KeyPressed Then
                Begin
                    c := ReadKey;
                    If c = #27 Then
                        Begin
                            gotoxy(x,y);
                            writeln('Aborting.');
                            Delay(1000);
                            Server.RunCycle := False;
                        End;
                End;
            Server.ProcessEvents;
        End;
End;

Destructor TQuickServer.Done;

Begin
    If ServerInitialized Then
        Server.Done;
    DoneTimer;
End;

Var SendnetApp:   TSendnet;
    QuickServer:   TQuickServer;

Begin
    ClrScr;
    TextAttr := 31;
    write(' ***   IPXFER v',IPXFER_VERSION,
          '   IPX File Transfer System   (c)1996 Jackson Software   *** ');
    TextAttr := 7;
    writeln('System initialization sequence:');
    writeln('   IPX communications module.');
    write('      IPXInstalled: ');
    If Not IPXInstalled Then
        Begin
            writeln('Failed.');
            Halt(1);
        End
    Else
        writeln('Detected.');
    GetLocalAddress;
    writeln('      GetLocalAddress: ',PrintNodeAddr(@LocalAddr.Node));
    writeln('   Initializing Network... Ok');
    writeln('   Network protocol module.');
    writeln('      MaxServerConnections: ',MAXCONNECTIONS);
    writeln('      IPX FIFO Queue Send Size: ',MAXSENDBUFFERS);
    writeln('      IPX FIFO Queue Receive Size: ',MAXRECEIVEBUFFERS);
    writeln('   InitParams: Checking command line parameters.');
    InitParams;
    writeln('   Initializing Server: ');
    write('      Kernel version: ');
    writeln('v',SENDNET_Version, ' - Full Version.');
    write('      Win95 API detection: ');
    If LFNSupport Then
        Begin
            writeln('OK... LFN Extensions enabled.');
        End
    Else
        writeln('Not present... LFN Extensions disabled.');

    write('      File System Init: ');
    If LFNSupport Then
        Begin
    {InitFS;}
        End
    Else
        writeln('<Disabled>');
    writeln('      Security Enforcement: <Disabled>');
    Delay(2000);
    If Not QuickServe Then
        Begin
            SendnetApp.Init;
            SendnetApp.Run;
            SendnetApp.Done;
        End
    Else
        Begin
            QuickServer.Init;
            writeln;
            write('   QuickServer running... ');
            QuickServer.Run;
            QuickServer.Done;
        End;
    ClrScr;
    Writeln('Thank you for using IPXFER!');
    writeln;
    writeln(
            'I would love to hear your comments and suggestions about this program.'
    );
    writeln(
            'Please feel free to write me and let me know of any inprovements that'
    );
    writeln('could be made or to inform me of any bugs that you have found.');
    writeln;
    writeln('EMail: jayjay@salamander.net');
End.
