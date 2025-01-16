
Unit RecProcs;

Interface

Uses IPX, Dos, Timer, Crt, Window, SuperIO;

{$I PACKETS.INC}

Type PFRec =   ^TFrec;
    TFRec =   Record
        Attr:   byte;
        Time:   longint;
        Size:   longint;
        FileName:   String[12];
    End;
    PFileBuffer =   ^TFileBuffer;
    TFileBuffer =   array[1..1024] Of byte;
    TParams =   Record
        Recurse:   boolean;
        OvrReadOnly:   Boolean;
        GetHidden:   Boolean;
        VolLabel:   Boolean;
        OvrNewer:   Boolean;
        SkipFile:   Boolean;
        NoConfirm:   Boolean;
        Statistics:   Boolean;
        FSpec:   PathStr;
        LocalPath:   PathStr;
        Dest:   PathStr;
    End;

Const NUMRECBUFFS =   10;
    OutPackets:   longint =   0;
    InPackets:   longint =   0;
    TotalBytesIn:   longint =   0;
    TotalFileBytes:   longint =   0;

Var ServerAddr:   TLocalAddr;
    ReceiveBuffer:   Array[1..NUMRECBUFFS] Of TNetPacket;
    SendBuffer:   TNetPacket;
    Connected:   boolean;
    CurrentAddr:   TLocalAddr;
    Sequence:   Longint;
    CurRecBuff:   integer;
    Params:   TParams;

Procedure Error(s:String);
Procedure Initialize;
Function Attach:   boolean;
Function Detach:   boolean;
Function FindFirstFile(FSpec:String; AttrMask:word; Var FRec:TFRec):   integer;
Function FindNextFile(Var FRec:TFRec):   Integer;
Function OpenFile(FName:String):   Integer;
Function CloseFile:   boolean;
Function ReadFile(Var FBuff:TFileBuffer):   Integer;

Implementation

Procedure Error(s:String);

Var ch:   char;

Begin
    MakeWind(20,10,60,10,15,4,2,1);
    TextAttr := 78;
    MidPrint(S,10);
    TextAttr := 79;
    MidPrint('[IPXFER ERROR]',9);
    MidPrint('[press any key to continue]',11);
    ch := ReadKey;
    RestScrn;
    RestCsr;
    TextAttr := 7;
End;

Procedure Initialize;

Var t:   integer;
    c:   char;

Begin
    If Not IPXInstalled Then
        Begin
            writeln('Fatal error:  IPX is not installed.');
            halt(1);
        End;
    GetLocalAddress;
    {Open the Network Socket}
    Case OpenSocket(SocketID) Of 
        $FF:
               Begin
                   writeln(
                           '      InitNetwork: OpenSocket = 0xFF (IPX Socket already open.)'
                   );
                   writeln(
                           '      --------------------------------------------------------'
                   );
                   writeln(
                           '                Do you wish to use the socket anyway?         '
                   );
                   writeln(
                           '                            ( Y / N )                         '
                   );
                   writeln(
                           '      --------------------------------------------------------'
                   );
                   Repeat
                       c := UpCase(readkey);
                   Until (c = 'Y') Or (c = 'N');
                   If c = 'N' Then
                       Halt(1);
               End;
        $FE:
               Begin
                   writeln(
                           '      InitNetwork: OpenSocket = 0xFE (IPX Socket table is full.)'
                   );
                   Halt(1);
               End;
    End;
      {Post the listening ECBs}
    For t:=1 To NUMRECBUFFS Do
        Begin
            Fillchar(ReceiveBuffer[t], Sizeof(TNetPacket), #00);
            ReceiveBuffer[t].ecb.InUseFlag := $1D;
            ReceiveBuffer[t].ecb.ECBSocket := SocketID;
            ReceiveBuffer[t].ecb.FragmentCount := 1;
            ReceiveBuffer[t].ecb.FAddr[1] := ofs(ReceiveBuffer[t].IPXHeader);
            ReceiveBuffer[t].ecb.FAddr[2] := seg(ReceiveBuffer[t].IPXHeader);
            ReceiveBuffer[t].ecb.FSize := sizeof(TNetEvent) - sizeof(TECB);
            IPXListenForPacket(ReceiveBuffer[t]);
        End;
      {Prepare the sending ECB}
    Fillchar(SendBuffer, sizeof(TNetPacket), #00);
    SendBuffer.ecb.ECBSocket := SocketID;
    SendBuffer.ecb.FragmentCount := 1;
    SendBuffer.ecb.FAddr[1] := ofs(SendBuffer.IPXHeader);
    SendBuffer.ecb.FAddr[2] := seg(SendBuffer.IPXHeader);
    Move(Localaddr.network[1],SendBuffer.ipxHeader.dNetwork[1],4);
    SendBuffer.IPXHeader.dSocket := SwapWord(SocketID);
      {Initialize the Sequence counter}
    Sequence := 0;
    CurRecBuff := 1;
End;

Function ValidatePacket(Packet:PNetEvent):   word;

Begin
    ValidatePacket := neNothing;
      {Check if the packet has a valid PacketID}
      {if Packet^.EventID = EventID then}
       {Ensure that the packet is in sequence}
    If Packet^.Sequence = Sequence Then
       {Return the type of NetEvent we received}
        ValidatePacket := Packet^.What
      {else
      	ValidatePacket:=neNothing;}
End;

Procedure SendPacket(Event:TNetEvent; DataSize:word; Dest:integer);

Var  TempAddr:   TLocalAddr;
    ClearToSend:   Boolean;
    ti:   longint;

Begin
  {Check if IPX is still using the Sending ECBs}
    ti := TimerTotal;
    ClearToSend := False;
    While (TimerTotal - ti) < 18 Do
        Begin
            If (SendBuffer.ecb.InUseFlag <> 0) Then
                RelinquishControl {Give IPX an extra time slice}
            Else
                Begin
                    ClearToSend := True;
                    Break;
                End;
        End;
    If Not ClearToSend Then
        Begin
            Error('Timeout attempting to send packet.');
            writeln('Timeout waiting for ECB Completion.');
            CloseSocket(SocketID);
            Halt;
        End;
  {Set Destination Address}
    If Dest=-1 Then
        TempAddr := GlobalAddr
    Else
        TempAddr := ServerAddr;
    move(TempAddr.Node,SendBuffer.IPXHeader.dNode,6);
    move(TempAddr.Node,SendBuffer.ecb.ImmediateAddr,6);
  {Specify Destination Socket}
    SendBuffer.IPXHeader.dsocket := SocketID;
  {Set the size of the packet}
    SendBuffer.ecb.fsize := sizeof(TIPXPacket) + DataSize + EVENTSIZE;
      {Set the packet sequence number}
    Event.Sequence := Sequence;
      {Place the data into the packet}
    move(Event, SendBuffer.NetData, EVENTSIZE + DataSize);
  {Faster than Federal Express!!}
    IPXSendPacket(SendBuffer);
    Inc(OutPackets);
End;

Function CompareNode(n1, n2:PLocalAddr):   boolean;

Var t:   integer;

Begin
    CompareNode := True;
    For t:=1 To 6 Do
        Begin
            If n1^.Node[t] <> n2^.Node[t] Then
                CompareNode := False;
        End;
End;

Function RetrievePacket(Var Packet:TNetEvent):   boolean;

Procedure NextBuff;
Begin
    Inc(CurRecBuff);
    If CurRecBuff > NUMRECBUFFS Then CurRecBuff := 1;
End;

Var t:   integer;
    b:   integer;

Begin
    RetrievePacket := False;
    For t:=1 To NUMRECBUFFS Do
        Begin
            If ReceiveBuffer[CurRecBuff].ECB.InUseFlag=0 Then
                Begin
          {Copy the return address into the temorary buffer}
                    If Not CompareNode(@ReceiveBuffer[CurRecBuff].IPXHeader.
                       sNetwork, @LocalAddr) Then
                        Begin
                            Move(ReceiveBuffer[CurRecBuff].IPXHeader.sNetwork,
                                 CurrentAddr, Sizeof(TLocalAddr));
           {Copy the received packet into an Event structure}
                            Move(ReceiveBuffer[CurRecBuff].NetData, Packet,
                                 sizeof(TNetEvent));
           {Signal a received event}
                            RetrievePacket := True;
                        End;
          {Repost the ECB}
    {ReceiveBuffer[CurRecBuff].ecb.InUseFlag:=$1D;}
                    IPXListenForPacket(ReceiveBuffer[CurRecBuff]);
                    Inc(InPackets);
                    Exit;
                End
            Else
                RelinquishControl;
            NextBuff;
        End;
End;

Function SendAndWait(Var Packet:TNetEvent; DataSize, WaitVal:word; MaxSend, Dest
                     :integer):   boolean;

Var ti:   longint;
    t:   integer;
    NewEvent:   TNetEvent;

Begin
      {Inc(Sequence);}
    ti := TimerTotal;
    For t:=1 To MaxSend Do
        Begin
            SendPacket(Packet, DataSize, Dest);
            While (TimerTotal - ti) < 18 Do
                Begin
                    If KeyPressed Then
                        Begin
                            If ReadKey=#27 Then
                                Begin
                                    Error('File transfer aborted.');
                                    writeln(' Aborted.');
                                    CloseSocket(SocketID);
                                    Halt;
                                End;
                        End;
                    If RetrievePacket(NewEvent) Then
                        Begin
                            If ValidatePacket(@NewEvent) = WaitVal Then
                                Begin
                                    Packet := NewEvent;
                                    SendAndWait := True;
                                    Exit;
                                End;
                        End;
                End;
            ti := TimerTotal;
        End;
    SendAndWait := False;
End;

Function Attach:   boolean;

Var  NewEvent:   TNetEvent;
    OutPacket:   PpConnectRequest;
    InPacket:   PpConnectReply;
    t:   integer;

Begin
    NewEvent.What := neAttachRequest;
    OutPacket := @NewEvent.Data;
      {Store our address in the packet}
    Move(LocalAddr.Node, OutPacket^.NodeAddr, 6);
      {Send the connect request}
    Connected := False;
    If SendAndWait(NewEvent, Sizeof(TpConnectRequest), neAttachReply, 20, -1)
        Then
        Begin
            InPacket := @NewEvent.Data;
            If InPacket^.Response = true Then
                Begin
          {Signal a successful connection}
                    Connected := True;
            {Store the return address to the server}
                    Move(CurrentAddr, ServerAddr, Sizeof(TLocalAddr));
                End;
        End;
    Attach := Connected;
End;

Function Detach:   boolean;

Var  NewEvent:   TNetEvent;
    OutPacket:   PpDisconnect;
    InPacket:   PpDisconnectReply;
    t:   integer;

Begin
    NewEvent.What := neInformDetach;
    OutPacket := @NewEvent.Data;
      {Send the disconnect request}
    If SendAndWait(NewEvent, Sizeof(TpDisconnect), neDetachConfirm, 2, 1) Then
        Begin
         {Signal a successful disconnection}
            Connected := False;
        End;
    Detach := Connected;
End;

Function FindFirstFile(FSpec:String; AttrMask:word; Var FRec:TFRec):   integer;

Var  NewEvent:   TNetEvent;
    OutPacket:   PpFindFirstFile;
    InPacket:   PpFindFileReply;
    t:   integer;

Begin
    NewEvent.What := neFindFirst;
    OutPacket := @NewEvent.Data;
    OutPacket^.NameSpec := FSpec;
    OutPacket^.Attr := AttrMask;
      {Send the FindFirst request}
    If SendAndWait(NewEvent, Sizeof(TpFindFirstFile), neFindFirstReply, 3, 1)
        Then
        Begin
            InPacket := @NewEvent.Data;
         {Signal a sucessfull FindFirst}
            FindFirstFile := InPacket^.ErrorCode;
            Move(InPacket^.Attr, FRec, Sizeof(FRec));
            Exit;
        End;
    FindFirstFile := -1;
End;

Function FindNextFile(Var FRec:TFRec):   Integer;

Var  NewEvent:   TNetEvent;
    InPacket:   PpFindFileReply;
    t:   integer;

Begin
    NewEvent.What := neFindNext;
      {Send the FindFirst request}
    If SendAndWait(NewEvent, Sizeof(TpFindNextFile), neFindNextReply, 3, 1) Then
        Begin
            InPacket := @NewEvent.Data;
         {Signal a sucessfull FindNext}
            FindNextFile := InPacket^.ErrorCode;
            Move(InPacket^.Attr, FRec, Sizeof(FRec));
            Exit;
        End;
    FindNextFile := -1;
End;

Function OpenFile(FName:String):   Integer;

Var  NewEvent:   TNetEvent;
    OutPacket:   PpOpenFile;
    InPacket:   PpOpenFileReply;
    t:   integer;

Begin
    NewEvent.What := neOpenFile;
    OutPacket := @NewEvent.Data;
    OutPacket^.NameSpec := FName;
      {Send the FindFirst request}
    If SendAndWait(NewEvent, Sizeof(TpOpenFile), neOpenFileReply, 3, 1) Then
        Begin
            InPacket := @NewEvent.Data;
            OpenFile := InPacket^.Response;
            Exit;
        End;
    OpenFile := 1;
End;

Function CloseFile:   boolean;

Var  NewEvent:   TNetEvent;
    t:   integer;

Begin
    NewEvent.What := neCloseFile;
      {Send the FindFirst request}
    If SendAndWait(NewEvent, Sizeof(TpCloseFile), neCloseFileReply, 3, 1) Then
        Begin
            CloseFile := True;
            Exit;
        End;
    CloseFile := False;
End;

Function ReadFile(Var FBuff:TFileBuffer):   Integer;

Var  NewEvent:   TNetEvent;
    InPacket:   PpReadFileReply;
    t:   integer;

Begin
    NewEvent.What := neReadFile;
      {Send the FindFirst request}
    If SendAndWait(NewEvent, Sizeof(TpReadFile), neReadFileReply, 3, 1) Then
        Begin
            InPacket := @NewEvent.Data;
            ReadFile := InPacket^.Result;
            If InPacket^.Result <> -1 Then
                Move(Inpacket^.Data, FBuff, InPacket^.Result)
            Else
                Begin
                    writeln('Error reading from file.');
                    Halt;
                End;
            Exit;
        End;
    ReadFile := -1;
End;

Begin
    InPackets := 0;
    OutPackets := 0;
End.
