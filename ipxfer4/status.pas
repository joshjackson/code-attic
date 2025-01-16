

{****************************************************************************
 * Program    : IPXFER v4.00                                                *
 * Unit       : Status                                                      *
 * Last Update: 11/24/95                                                    *
 * Written by : Joshua Jackson (jayjay@sal-junction.com)                    *
 * Purpose    : Server status window definitions                            *
 ****************************************************************************}
{$O+}

Unit Status;

Interface

Uses Objects, App, Dialogs, Views, Server, Network, Drivers, IPX;

{$I STRUCTS.INC}

Type PServerStatus =   ^TServerStatus;
    TServerStatus =   Object(TDialog)
        ServerMemory:   PStaticText;
        Connections:   PStaticText;
        PacketsSent:   PStaticText;
        PacketsReceived:   PStaticText;
        FilesOpen:   PStaticText;
        TheServer:   PServer;
        Constructor Init(AServer:PServer);
        Procedure Update;
        Procedure HandleEvent(Var Event:TEvent);
        virtual;
    End;

    PAboutBox =   ^TAboutBox;
    TAboutBox =   Object(TDialog)
        Constructor Init;
    End;

    PConnectionStatus =   ^TConnectionStatus;
    TConnectionStatus =   Object(TDialog)
        ConnectionList:   PRadioButtons;
        PrevConnections:   integer;
        Constructor Init;
        Procedure Update;
        Procedure HandleEvent(Var Event:TEvent);
        virtual;
    End;

    PDebugBox =   ^TDebugBox;
    TDebugBox =   Object(TDialog)
    End;

Implementation

Const cmConnectionDetails =   1000;

Function AddText(x,y:integer;V:PGroup;s:String):   PStaticText;

Var R:   TRect;
    P:   PStaticText;

Begin
    R.Assign(x,y,x+Length(s),y+1);
    p := New(PStaticText, Init(R, s));
    v^.Insert(p);
    AddText := p;
End;

Constructor TServerStatus.Init(AServer:PServer);

Var R:   TRect;

Begin
    R.Assign(5,15,75,21);
    TDialog.Init(R, 'Server Status');
    AddText(2,1,@Self, 'Memory:');
    ServerMemory := AddText(10,1,@Self,'0       ');
    AddText(2,2,@Self, 'Active Connections:');
    Connections := AddText(22,2,@Self,'0  ');
    AddText(2,3,@Self, 'Packets Sent:');
    PacketsSent := AddText(16,3,@Self,'0      ');
    AddText(30,3,@Self, 'Packets Received:');
    PacketsReceived := AddText(48,3,@Self,'0      ');
    AddText(2,4,@Self, 'Open Files:');
    FilesOpen := AddText(14,4,@Self,'0  ');
    TheServer := AServer;
End;

Procedure TServerStatus.Update;

Var s:   string[15];

Begin
    If GetState(sfVisible) Then
        Begin
         {Check amount of avail memory}
            Str(MemAvail, s);
            ServerMemory^.Text^ := s;
         {Check number of open files}
            Str(OpenClientFiles, s);
            FilesOpen^.Text^ := s;
         {Get number of active connections}
            Str(TheServer^.ActiveConnections, s);
            Connections^.Text^ := s;
         {Get number of packets in/out}
            Str(PacketsOut, s);
            PacketsSent^.Text^ := s;
            Str(PacketsIn, s);
            PacketsReceived^.Text^ := s;
            Redraw;
        End;
End;

Procedure TServerStatus.HandleEvent(Var Event:TEvent);

Begin
    If (Event.What=evCommand) And (Event.Command=cmClose) Then
        Begin
            EnableCommands([cmDisplayStatus]);
            Hide;
            ClearEvent(Event);
        End
    Else
        TDialog.HandleEvent(Event);
End;

{---------------------------------------------------------------------------}
Constructor TConnectionStatus.Init;

Var r:   trect;

Begin
    R.Assign(5,2,55,13);
    TDialog.Init(R, 'Connection Status');
    AddText(2,1,@Self,'Connections:');
    R.Assign(2,2,47,7);
    ConnectionList := New(PRadioButtons, Init(R,
                      NewSItem('0000:000000000000',
                      NewSItem('0000:000000000000',
                      NewSItem('0000:000000000000',
                      NewSItem('0000:000000000000',
                      NewSItem('0000:000000000000',
                      NewSItem('0000:000000000000',
                      NewSItem('0000:000000000000',
                      NewSItem('0000:000000000000',
                      NewSItem('0000:000000000000',
                      NewSItem('0000:000000000000', Nil))))))))))));
    Insert(ConnectionList);
    R.Assign(4,8,20,10);

{Insert(New(PButton, Init(R, 'Show ~D~etails', cmConnectionDetails, bfDefault)));}
      {R.Assign(22,8,35,10);}
    Insert(New(PButton, Init(R, '~T~erminate', cmTerminateConnection, bfNormal))
    );
    ConnectionList^.Focus;
    PrevConnections := -1;
End;

Procedure TConnectionStatus.Update;

Var  t:   integer;
    tempconn:   PConnectionEntry;
    s:   PString;
    FirstStr, PrevStr, CurStr:   PSItem;
    R:   TRect;
    CurVal:   Longint;

Begin
    CurStr := Nil;
    PrevStr := Nil;
    For t:=1 To MAXCONNECTIONS Do
        Begin
            tempconn := @ConnectionTable^[t];
            New(CurStr);
            s := NewStr('0000:'+PrintNodeAddr(@tempconn^.NodeAddress.node));
            CurStr^.Value := s;
            CurStr^.Next := Nil;
            If PrevStr <> Nil Then
                PrevStr^.Next := CurStr
            Else
                FirstStr := CurStr;
            PrevStr := CurStr;
        End;
    Lock;
    CurVal := ConnectionList^.Value;
    Dispose(ConnectionList, Done);
    R.Assign(2,2,47,7);
    ConnectionList := New(PRadioButtons, Init(R, FirstStr));
    ConnectionList^.SetData(CurVal);
    Insert(ConnectionList);
    Unlock;
End;

Procedure TConnectionStatus.HandleEvent(Var Event:TEvent);

Begin
    If (Event.What=evCommand) And (Event.Command=cmClose) Then
        Begin
            EnableCommands([cmConnectStatus]);
            Hide;
            ClearEvent(Event);
        End
    Else
        TDialog.HandleEvent(Event);
End;


{---------------------------------------------------------------------------
	TAboutBox.Init: About box definition.}

Constructor TAboutBox.Init;

Var R:   TRect;

Begin
    R.Assign(23,4,57,18);
    TDialog.Init(R,'About');
    AddText(11,2,@Self,'IPXFER v'+IPXFER_VERSION);
    AddText(7,4,@Self,'Sendnet Server v'+SENDNET_VERSION);
    AddText(6,6,@Self,'Copyright (c) 1995 by');
    AddText(9,8,@Self,'Jackson Software');
    AddText(5,9,@Self,' (jayjay@newreach.net) ');
    R.Assign(11,11,23,13);
    Insert(New(PButton, Init(R, '~O~k', cmOk, bfDefault)));
End;

End.
