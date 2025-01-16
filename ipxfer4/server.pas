

{****************************************************************************
 * Program    : IPXFER v4.00                                                *
 * Unit       : Server                                                      *
 * Last Update: 11/22/95                                                    *
 * Written by : Joshua Jackson (jayjay@sal-junction.com)                    *
 * Purpose    : Sendnet server routines                                     *
 ****************************************************************************}

Unit Server;

Interface

Uses DOS, IPX, Network, Memory, MsgBox, Views, Win95API, LFN;

Type  PServer =   ^TServer;
    TServer =   Object
        ServerInitOK:   Boolean;
        IOBuffer:   PIOBuffer;
        ServerError:   String[80];
        RunCycle:   boolean;
        ServerDrive:   byte;
        StartPath:   PathStr;
        Constructor Init;
        Function OpenSockets:   boolean;
        Procedure CloseSockets;
        Procedure ProcessEvents;
        Procedure HandleEvent(Var Event:TNetEvent);
        Procedure AttachUser(Var Event:TNetEvent);
        Procedure DetatchUser(Var Event:TNetEvent);
        Procedure KillUser(ConnectionNum:integer);
        Procedure IdentifyServer(Event:TNetEvent);
        Procedure NetFindFirst(Event:TNetEvent);
        Procedure NetFindNext(Event:TNetEvent);
        Procedure NetOpenFile(Event:TNetEvent);
        Procedure NetReadFile(Event:TNetEvent);
        Procedure NetCloseFile(Event:TNetEvent);
        Procedure NetReadSector(Event:TNetEvent);
        Function ActiveConnections:   integer;
        Destructor Done;
    End;

    PSectorRequestBlock =   ^TSectorRequestBlock;
    TSectorRequestBlock =   Record
        StartSect:   longint;
        NumSect:   word;
        DataPtr:   pointer;
    End;



{QuickServe: set to true if the command line parameter -q was specified. It
             forces the server to execute in quick mode, allowing only one
             connection and will terminate after the client disconnects. This
             allows the server to be used as a command line utility rather
             than an application}

Const QuickServe:   boolean =   false;

Implementation

Uses Crt;

{---------------------------------------------------------------------------
	TServer.Init: Initalize the server -> Connection Manager, IOBuffers,
	and File manager}

Constructor TServer.Init;

Var t:   integer;

Begin
    ServerInitOK := False;
    {Initialize the connection table}
    ConnectionTable := MemAllocSeg(MaxConnections * sizeof(TConnectionEntry));
    If ConnectionTable=Nil Then
        Begin
            ServerError := 'Insufficient Memory';
            exit;
        End;
    FillChar(ConnectionTable^, MaxConnections * sizeof(TConnectionEntry), #00);
      {Open network sockets}
    If Not OpenSockets Then
        Exit;
      {Initialize sending/receiving buffers}
    IOBuffer := New(PIOBuffer, Init(MaxConnections));
      {Signal sucessful server initialization}
    ServerInitOk := True;
    If QuickServe Then
        RunCycle := true;
    GetDir(0, StartPath);
End;

Function TServer.OpenSockets:   boolean;

Var c:   char;

Begin
    OpenSockets := False;
    Case OpenSocket(SocketID) Of 
        00:   OpenSockets := true;
        $FF:
               Begin
                   If Not QuickServe Then
                       Begin
                           If MessageBox('IPX Channel already open, use it anyway?',Nil, $0300) = cmYes Then
                               OpenSockets := True;
                       End
                   Else
                       Begin
                           writeln;
                           writeln('IPX Channel already open, use it anyway? (Y/N)');
                           Repeat
                               c := UpCase(ReadKey);
                           Until (c = 'Y') Or (c = 'N');
                           If c = 'Y' Then
                               OpenSockets := True;
                       End
               End;
        $FE:
               Begin
                   If Not QuickServe Then
                       MessageBox('TServer.OpenSockets: IPX Socket table is full',Nil,$0401)
                   Else
                       writeln('IPX Socket table is full.');
               End;
    End;
End;

Procedure TServer.CloseSockets;

Begin
    CloseSocket(SocketID);
End;

{---------------------------------------------------------------------------
	TServer.ProcessEvents: Check for incoming / outgoing events.
   Must be called from a loop for server execution to take place}

Procedure TServer.ProcessEvents;

Var t:   integer;
    Event:   TNetEvent;

Begin
    RelinquishControl;
    For t:=1 To MaxConnections Do
        Begin
         {If an event is available then process it}
            If IOBuffer^.RetrieveEvent(Event) Then
                HandleEvent(Event)
        End;
End;

{---------------------------------------------------------------------------
	TServer.HandleEvent:Dispatch messages to default handlers}

Procedure TServer.HandleEvent(Var Event:TNetEvent);

Begin
    {Check to see if the incoming event is a connection or file system
      request}
    If (Event.What And neSystem) > 0 Then
        Begin
            Case Event.What Of 
                neAttachRequest:   AttachUser(Event);
                neInformDetach:   DetatchUser(Event);
                neIdentifyRequest:;
            End;
        End
    Else If ((Event.What And neFileRequest) > 0) And (Event.Who <> -1) Then
             Begin
                 Case Event.What Of 
                     neRetrieveInfo:;
                     neFindFirst:   NetFindFirst(Event);
                     neFindNext:   NetFindNext(Event);
                     neOpenFile:   NetOpenFile(Event);
                     neReadFile:   NetReadFile(Event);
                     neCloseFile:   NetCloseFile(Event);
                 End;
             End;
End;

{---------------------------------------------------------------------------
	TServer.ActiveConnections: Returns the number of connections to server}

Function TServer.ActiveConnections:   integer;

Var c,t:   integer;

Begin
    c := 0;
    For t:=1 To MaxConnections Do
        Begin
            If ConnectionTable^[t].IsConnected Then
                Inc(c);
        End;
    ActiveConnections := c;
End;

{---------------------------------------------------------------------------
	TServer.AttachUser: If possible, attaches a user to the server and places
   the necessary connection information in the connection tables.}

Procedure TServer.AttachUser(Var Event:TNetEvent);

Var TempConn:   PConnectionEntry;
    InPacket:   PpConnectRequest;
    OutPacket:   PpConnectReply;
    NewEvent:   TNetEvent;
    t:   integer;

Begin
    InPacket := @Event.Data;
    {Check to see if there are any available connection entries}
    If ActiveConnections = MAXCONNECTIONS Then
        Begin
       {Return a refusal for connection to the client}
            OutPacket := @NewEvent.Data;
            OutPacket^.Response := False;
            IOBuffer^.PutEvent(NewEvent, Sizeof(TpConnectReply), -1);
        End;
      {Check to see if the current node address is already in the
      connection table. If so, reset all connection info}
    If Event.Who <> -1 Then
        Begin
       {Reset the connection information}
            TempConn := @ConnectionTable^[Event.Who];
            If TempConn^.FileIsOpen Then
                Begin
                    If LFNSupport Then
                        LFNCloseFile(TempConn^.ClientLongFile)
                    Else
                        close(TempConn^.ClientFile);
                    TempConn^.FileIsOpen := False;
                End;
            For t:=1 To TempConn^.SearchDepth Do
                Begin
                    If LFNSupport Then
                        Begin
                            LFNFindClose(TempConn^.ClientLFNSearchRecs^[t]^);
                            If t <> 1 Then
                                Dispose(TempConn^.ClientLFNSearchRecs^[t]);
                        End
                    Else
                        If t <> 1 Then
                            Dispose(TempConn^.ClientSearchRecs^[t]);
                End;
            TempConn^.SearchDepth := 1;
            TempConn^.StartDepth := -1;
            t := Event.Who;
        End
    Else
        Begin
         {Determine the first available connection entry}
            TempConn := Nil;
            For t:=1 To MAXCONNECTIONS Do
                Begin
                    If Not ConnectionTable^[t].IsConnected Then
                        Begin
                            TempConn := @ConnectionTable^[t];
                            Break;
                        End;
                End;
         {This should never happen, but be prepared for anything!}
            If TempConn = Nil Then
                Begin
                    ClrScr;
                    writeln('TServer.AttachUser Fatal Error: ConnectionTable overflow.');
                    writeln('TServer Message: Shutting down.');
            {Perform minimal shut down and get the heck out.}
                    CloseSockets;
                    Halt(1);
                End;
       {Place the address information in the connection table}
            move(InPacket^.NodeAddr, TempConn^.NodeAddress.Node, 6);
         {Allocate the Search Records}
            If LFNSupport Then
                Begin
                    New(TempConn^.ClientLFNSearchRecs);
                    FillChar(TempConn^.ClientLFNSearchRecs^, Sizeof(TLFNSearchRecs), #00);
                End
            Else
                Begin
                    New(TempConn^.ClientSearchRecs);
                    FillChar(TempConn^.ClientSearchRecs^, Sizeof(TSearchRecs), #00);
                End;
            TempConn^.SearchDepth := 1;
            TempConn^.StartDepth := -1;
            If LFNSupport Then
                New(TempConn^.ClientLFNSearchRecs^[1])
            Else
                New(TempConn^.ClientSearchRecs^[1]);
         {Flag the entry as active}
            TempConn^.IsConnected := True;
        End;
      {Reply to the receiver that he is connected}
    NewEvent.What := neAttachReply;
    OutPacket := @NewEvent.Data;
    OutPacket^.Response := True;
    IOBuffer^.PutEvent(NewEvent, Sizeof(TpConnectReply), t);
End;

{--------------------------------------------------------------------------
	TServer.DetatchUser: Removes the connection information from the tables
   and further denies access to the server file functions}

Procedure TServer.DetatchUser(Var Event:TNetEvent);

Var TempConn:   PConnectionEntry;
    NewEvent:   TNetEvent;
    t:   integer;

Begin
    {Check to ensure that the detatching node is in the connection table
      if the node address is not present in the connection table then simply
		ignore the request}
    If Event.Who <> -1 Then
        Begin
            TempConn := @ConnectionTable^[Event.Who];
         {If the remote system has a file open, close it}
            If TempConn^.FileIsOpen Then
                If LFNSupport Then
                    LFNCloseFile(TempConn^.ClientLongFile)
            Else
                Close(TempConn^.ClientFile);
         {Clear the search recs}
            For t:=1 To TempConn^.SearchDepth Do
                Begin
                    If LFNSupport Then
                        Begin
                            LFNFindClose(TempConn^.ClientLFNSearchRecs^[t]^);
                            Dispose(TempConn^.ClientLFNSearchRecs^[t]);
                        End
                    Else
                        Dispose(TempConn^.ClientSearchRecs^[t]);
                End;
            If LFNSupport Then
                Dispose(TempConn^.ClientLFNSearchRecs)
            Else
                Dispose(TempConn^.ClientSearchRecs);
            NewEvent.What := neDetachConfirm;
            IOBuffer^.PutEvent(NewEvent, Sizeof(TpDisconnectReply), Event.Who);
         {Clear the connection entry for the remote system}
            FillChar(TempConn^, Sizeof(TConnectionEntry), #00);
            If ActiveConnections = 0 Then
                RunCycle := False;
        End;
End;



{---------------------------------------------------------------------------
TServer.KillUser: Terminates a clients link to the server.  Note that no
                   indiccation is send to the client that this has happened,
                   this should actuall only be used if the client crashes.}
Procedure TServer.KillUser(ConnectionNum:integer);

Var TempConn:   PConnectionEntry;
    NewEvent:   TNetEvent;
    t:   integer;

Begin
    {Check to ensure that the detatching node is in the connection table
      if the node address is not present in the connection table then simply
		ignore the request}
    TempConn := @ConnectionTable^[ConnectionNum];
      {If the remote system has a file open, close it}
    If TempConn^.FileIsOpen Then
        Begin
            If LFNSupport Then
                LFNCloseFile(TempConn^.ClientLongFile)
            Else
                Close(TempConn^.ClientFile);
        End;
      {Clear the search recs}
    For t:=1 To TempConn^.SearchDepth Do
        Begin
            If LFNSupport Then
                Begin
                    LFNFindClose(TempConn^.ClientLFNSearchRecs^[t]^);
                    Dispose(TempConn^.ClientLFNSearchRecs^[t]);
                End
            Else
                Dispose(TempConn^.ClientSearchRecs^[t]);
        End;
    If LFNSupport Then
        Dispose(TempConn^.ClientLFNSearchRecs)
    Else
        Dispose(TempConn^.ClientSearchRecs);
      {Clear the connection entry for the remote system}
    FillChar(TempConn^, Sizeof(TConnectionEntry), #00);
End;

{---------------------------------------------------------------------------
TServer.IdentifyServer: Reurns the Server's identity to recnet (for multi-
								server support). }

Procedure TServer.IdentifyServer(Event:TNetEvent);

Var   OutPacket:   PpIdentifyReply;
    NewEvent:   TNetEvent;

Begin
    OutPacket := @NewEvent.Data;
    OutPacket^.SrvVersion := SERVER_Version_Int;
    OutPacket^.SrvName := 'Test_Server';
    OutPacket^.SrvDesc := 'Test server for multi-server support';
    NewEvent.What := neIdentifyReply;
    IOBuffer^.PutEvent(NewEvent, Sizeof(TpFindFileReply), Event.Who);
End;

{---------------------------------------------------------------------------
TServer.NetFindFirst: Searches for the first file that fits the specs
                      sent by the client.}
Procedure TServer.NetFindFirst(Event:TNetEvent);

Var TempConn:   PConnectionEntry;
    PackTemp:   PpFindFirstFile;
    OutPacket:   PpFindFileReply;
    NewEvent:   TNetEvent;
    CurDepth:   integer;
    Result:   integer;

Begin
    TempConn := @ConnectionTable^[Event.Who];
    PackTemp := @Event.Data;
    If TempConn^.StartDepth = -1 Then
        TempConn^.StartDepth := CalcSearchDepth(PackTemp^.NameSpec) - 1;
    SetSearchDepth(TempConn, CalcSearchDepth(PackTemp^.NameSpec) - TempConn^.StartDepth);
    CurDepth := TempConn^.SearchDepth;
    OutPacket := @NewEvent.Data;
    With TempConn^ Do
        Begin
            If LFNSupport Then
                Begin
                    Result := LFNFindFirst(PackTemp^.NameSpec, PackTemp^.Attr, PackTemp^.Attr,
                              ClientLFNSearchRecs^[SearchDepth]^);
                End
            Else
                Begin
                    FindFirst(PackTemp^.NameSpec,PackTemp^.Attr,ClientSearchRecs^[SearchDepth]^);
                    Result := DosError;
                End;
            While Result = 0 Do
                Begin
                    If (ClientSearchRecs^[CurDepth]^.Name = '.') Or
                       (ClientSearchRecs^[CurDepth]^.Name = '..') Then
                        Begin
                            If LFNSupport Then
                                Begin
                                    Result := LFNFindNext(ClientLFNSearchRecs^[CurDepth]^);
                                End
                            Else
                                Begin
                                    FindNext(ClientSearchRecs^[CurDepth]^);
                                    Result := DosError;
                                End;
                        End
                    Else
                        Break;
                End;
            If LFNSupport Then
                Begin
                    OutPacket^.Attr := ClientLFNSearchRecs^[CurDepth]^.Attr;
                    OutPacket^.Time := ClientLFNSearchRecs^[CurDepth]^.CreationTime;
                    OutPacket^.Size := ClientLFNSearchRecs^[CurDepth]^.Size;
                    OutPacket^.FileName := ClientLFNSearchRecs^[CurDepth]^.Name;
                End
            Else
                Begin
                    OutPacket^.Attr := ClientSearchRecs^[CurDepth]^.Attr;
                    OutPacket^.Time := ClientSearchRecs^[CurDepth]^.Time;
                    OutPacket^.Size := ClientSearchRecs^[CurDepth]^.Size;
                    OutPacket^.FileName := ClientSearchRecs^[CurDepth]^.Name;
                End;
        End;
    If (Result <> 0) And (CurDepth > 1) Then
        SetSearchDepth(TempConn, CurDepth - 1);
    OutPacket^.ErrorCode := Result;
    NewEvent.What := neFindFirstReply;
    IOBuffer^.PutEvent(NewEvent, Sizeof(TpFindFileReply), Event.Who);
End;

{---------------------------------------------------------------------------
	TServer.NetFindNext: Searches for the next file based on the SearchRec
                        field of the client's connection entry.}
Procedure TServer.NetFindNext(Event:TNetEvent);

Var TempConn:   PConnectionEntry;
    OutPacket:   PpFindFileReply;
    NewEvent:   TNetEvent;
    CurDepth:   integer;
    Result:   integer;

Begin
    TempConn := @ConnectionTable^[Event.Who];
    With TempConn^ Do
        Begin
            CurDepth := SearchDepth;
            If LFNSupport Then
                Begin
                    Result := LFNFindNext(ClientLFNSearchRecs^[CurDepth]^);
                End
            Else
                Begin
                    FindNext(ClientSearchRecs^[CurDepth]^);
                    Result := DosError;
                End;
            OutPacket := @NewEvent.Data;
            OutPacket^.ErrorCode := Result;
            If (DosError <> 0) Then
                Begin
                    If LFNSupport Then
                        LFNFindClose(ClientLFNSearchRecs^[CurDepth]^);
                    If CurDepth > 1 Then
                        SetSearchDepth(TempConn, CurDepth - 1);
                End
            Else
                Begin
                    If LFNSupport Then
                        Begin
                            OutPacket^.Attr := ClientLFNSearchRecs^[CurDepth]^.Attr;
                            OutPacket^.Time := ClientLFNSearchRecs^[CurDepth]^.CreationTime;
                            OutPacket^.Size := ClientLFNSearchRecs^[CurDepth]^.Size;
                            OutPacket^.FileName := ClientLFNSearchRecs^[CurDepth]^.Name;
                        End
                    Else
                        Begin
                            OutPacket^.Attr := ClientSearchRecs^[CurDepth]^.Attr;
                            OutPacket^.Time := ClientSearchRecs^[CurDepth]^.Time;
                            OutPacket^.Size := ClientSearchRecs^[CurDepth]^.Size;
                            OutPacket^.FileName := ClientSearchRecs^[CurDepth]^.Name;
                        End;
                End;
        End;
    NewEvent.What := neFindNextReply;
    IOBuffer^.PutEvent(NewEvent, Sizeof(TpFindFileReply), Event.Who);
End;

{---------------------------------------------------------------------------
	TServer.NetOpenFile: Opens the requested file.
}
Procedure TServer.NetOpenFile(Event:TNetEvent);

Var TempConn:   PConnectionEntry;
    InPacket:   PpOpenFile;
    OutPacket:   PpOpenFileReply;
    NewEvent:   TNetEvent;
    ActionTaken:   word;
    Result:   integer;

Begin
    TempConn := @ConnectionTable^[Event.Who];
      {$I-}
    InPacket := @Event.Data;
    OutPacket := @NewEvent.Data;
    If LFNSupport Then
        Begin
            Result := LFNOpenFile(InPacket^.NameSpec, OpenAccessReadOnly + OpenShareDenyWrite,
                      Archive, FileOpen, ActionTaken, TempConn^.ClientLongFile);
        End
    Else
        Begin
            assign(TempConn^.ClientFile, InPacket^.NameSpec);
            reset(TempConn^.ClientFile, 1);
            If IOResult = 0 Then
                Result := 0
            Else
                Result := -1;
        End;
    If Result = 0 Then
        Begin
            TempConn^.FileIsOpen := True;
            OutPacket^.Response := 0;
        End
    Else
        Begin
            TempConn^.FileIsOpen := False;
            OutPacket^.Response := -1;
        End;
    NewEvent.What := neOpenFileReply;
    IOBuffer^.PutEvent(NewEvent, Sizeof(TpOpenFileReply), Event.Who);
      {$I+}
End;

{---------------------------------------------------------------------------
	TServer.NetReadFile: Reads and sends upto 1024 bytes of data.
}
Procedure TServer.NetReadFile(Event:TNetEvent);

Var TempConn:   PConnectionEntry;
    OutPacket:   PpReadFileReply;
    NewEvent:   TNetEvent;
    count:   word;
    Result:   integer;

Begin
    TempConn := @ConnectionTable^[Event.Who];
      {$I-}
    OutPacket := @NewEvent.Data;
    If LFNSupport Then
        Begin
            If LFNReadFile(TempConn^.ClientLongFile, OutPacket^.Data, 1024, Count) Then
                Result := 0
            Else
                Result := -1;
        End
    Else
        Begin
            BlockRead(TempConn^.ClientFile, OutPacket^.Data, 1024, count);
            If IOResult = 0 Then
                Result := 0
            Else
                Result := -1;
        End;
    If Result = 0 Then
        OutPacket^.Result := count
    Else
        OutPacket^.Result := -1;
      {$I+}
    NewEvent.What := neReadFileReply;
    IOBuffer^.PutEvent(NewEvent, Sizeof(TpReadFileReply), Event.Who);
End;

{---------------------------------------------------------------------------
	TServer.NetCloseFile: Closes the client's currently open file.
}
Procedure TServer.NetCloseFile(Event:TNetEvent);

Var TempConn:   PConnectionEntry;
    OutPacket:   PpCloseFileReply;
    NewEvent:   TNetEvent;

Begin
    TempConn := @ConnectionTable^[Event.Who];
      {$I-}
    OutPacket := @NewEvent.Data;
    If TempConn^.FileIsOpen Then
        Begin
            If LFNSupport Then
                LFNCloseFile(TempConn^.ClientLongFile)
            Else
                Close(TempConn^.ClientFile);
            TempConn^.FileIsOpen := False;
        End;
      {Clear the IOResult flag if set}
    If IOResult=0 Then;
      {$I+}
    NewEvent.What := neCloseFileReply;
    IOBuffer^.PutEvent(NewEvent, Sizeof(TpCloseFileReply), Event.Who);
End;

{---------------------------------------------------------------------------
	TServer.NetReadSector : Reads an absolute sector from the server's hard
								   drive}

Procedure TServer.NetReadSector(Event:TNetEvent);

Var TempConn:   PConnectionEntry;
    InPacket:   PpSectorRead;
    OutPacket:   PpSectorReadReply;
    NewEvent:   TNetEvent;
    count:   word;
    RetVal:   word;
    DriveID:   byte;
    RequestBlock:   TSectorRequestBlock;
    BlockPtr:   pointer;

Begin
    TempConn := @ConnectionTable^[Event.Who];
      {$I-}
    OutPacket := @NewEvent.Data;
    InPacket := @Event.Data;
    RequestBlock.NumSect := InPacket^.Count;
    RequestBlock.StartSect := InPacket^.Sector;
    RequestBlock.DataPtr := @OutPacket^.Data;
    BlockPtr := @RequestBlock;
    DriveID := ServerDrive;
    asm
    pusha
    mov al, DriveID
    mov cx, -1
    mov dx, 0
    lds bx, BlockPtr
    int $25
    pop dx
    jc @@Error
    xor ax,ax
    @@Error:
               mov RetVal, ax
               popa
End;
OutPacket^.ReturnCode := RetVal;
      {$I+}
NewEvent.What := neSectorReadReply;
IOBuffer^.PutEvent(NewEvent, Sizeof(TpReadFileReply), Event.Who);
End;

{---------------------------------------------------------------------------
	TServer.Done: Close down the server
   Warning     : Open connections will not be closed, simply terminated}

Destructor TServer.Done;

Var t:   integer;

Begin
    {Close network sockets}
    CloseSockets;
      {Shutdown IO Buffers}
    Dispose(IOBuffer, Done);
      {Destroy the connection tables}
    FreeMem(ConnectionTable, MaxConnections * sizeof(TConnectionEntry));
End;

Begin
   {Read only access to files}
    FileMode := 0;
End.
