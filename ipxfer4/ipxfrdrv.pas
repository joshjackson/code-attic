{$F+,O+}
{$M 4096,0,0}

Uses CRT,TIMER,ipx;

{$I PACKETS.INC}

Type  PBlockDescriptor =   ^TBlockDescriptor;
    TBlockDescriptor =   Record
        ID:   array[1..2] Of char;
        NumSect:   word;
        StartSect:   longint;
    End;

Var SendingPacket:   TNetPacket;
    ReceivingPacket:   TNetPacket;
    Sequence:   longint;
    ServerAddr:   TLocalAddr;
    CurrentAddr:   TLocalAddr;
    Connected:   Boolean;

Var ISR_Addr:   pointer;

Function IPXFERSys:   boolean;
assembler;

asm
mov ax,$F600
int $2f
cmp al,$FF
jne @@NoInst
mov ax,1
jmp @@Out
@@NoInst:
            xor ax,ax
            @@Out:
End;

Function RegisterDriver:   boolean;
assembler;

asm
pusha
mov ax,$F601
les bx,dword ptr[ISR_Addr]
int $2f
cmp al,0
jne @@NoLink
mov ax,1
jmp @@Out
@@NoLink:
            xor ax,ax
            @@Out:
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

Var t:   integer;
    b:   integer;

Begin
    RetrievePacket := False;
    If ReceivingPacket.ECB.InUseFlag=0 Then
        Begin
         {Copy the return address into the temorary buffer}
            If Not CompareNode(@ReceivingPacket.IPXHeader.sNetwork, @LocalAddr)
                Then
                Begin
                    Move(ReceivingPacket.IPXHeader.sNetwork, CurrentAddr, Sizeof(TLocalAddr));
          {Copy the received packet into an Event structure}
                    Move(ReceivingPacket.NetData, Packet, sizeof(TNetEvent));
          {Signal a received event}
                    RetrievePacket := True;
                End;
         {Repost the ECB}
            IPXListenForPacket(ReceivingPacket);
         {Inc(InPackets);}
            Exit;
        End
    Else
        RelinquishControl;
End;


Function ValidatePacket(Packet:PNetEvent):   word;

Begin
    ValidatePacket := neNothing;
      {Ensure that the packet is in sequence}
    If Packet^.Sequence = Sequence Then
      {Return the type of NetEvent we received}
        ValidatePacket := Packet^.What
End;

Function SendPacket(Event:TNetEvent; DataSize:word; Dest:integer):   Boolean;

Var  TempAddr:   TLocalAddr;
    ClearToSend:   Boolean;
    ti:   longint;

Begin
  {Check if IPX is still using the Sending ECBs}
    ti := TimerTotal;
    ClearToSend := False;
    While (TimerTotal - ti) < 18 Do
        Begin
            If (SendingPacket.ecb.InUseFlag <> 0) Then
                RelinquishControl {Give IPX an extra time slice}
            Else
                Begin
                    ClearToSend := True;
                    Break;
                End;
        End;
    If Not ClearToSend Then
        Begin
            SendPacket := False;
            Exit;
        End;
  {Set Destination Address}
    If Dest=-1 Then
        TempAddr := GlobalAddr
    Else
        TempAddr := ServerAddr;
    move(TempAddr.Node,SendingPacket.IPXHeader.dNode,6);
    move(TempAddr.Node,SendingPacket.ecb.ImmediateAddr,6);
  {Specify Destination Socket}
    SendingPacket.IPXHeader.dsocket := SocketID;
  {Set the size of the packet}
    SendingPacket.ecb.fsize := sizeof(TIPXPacket) + DataSize + EVENTSIZE;
      {Set the packet sequence number}
    Event.Sequence := Sequence;
      {Place the data into the packet}
    move(Event, SendingPacket.NetData, EVENTSIZE + DataSize);
  {Faster than Federal Express!!}
    IPXSendPacket(SendingPacket);
    {Inc(OutPackets);}
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

Function RequestSector(SectNum:Longint; Count:word; Var Buff):   boolean;

Var Request:   PpSectorRead;
    Reply:   PpSectorReadReply;
    NewEvent:   TNetEvent;

Begin
    NewEvent.What := neAttachRequest;
    Request := @NewEvent.Data;
      {Store our address in the packet}
    Move(SectNum, Request^.Sector, 4);
    Move(Count, Request^.Count, 2);
      {Send the read request}
    Connected := False;
    If SendAndWait(NewEvent, Sizeof(TpConnectRequest), neSectorReadReply, 10, 1)
        Then
        Begin
            Reply := @NewEvent.Data;
            If Reply^.ReturnCode = 0 Then
                Begin
          {Signal a successful connection}
                    RequestSector := True;
            {Store the return address to the server}
                    Move(Reply, Buff, 512 * Count);
                    exit;
                End;
        End;
    RequestSector := False;
End;


{****************************************************************************
 * ISR_1 - NetReadSectors:  Called by the IPXFER.SYS device driver.         *
 ****************************************************************************}

Procedure NetReadSectors(Flags, CS, IP, AX, BX, CX, DX, SI, DI, DS, ES, BP: Word
);
interrupt;

Var BlockDesc:   PBlockDescriptor;
    DosBuffer:   pointer;
    DosBSeg,DosBOfs:   word;
    SectCnt:   word;

Begin
    BlockDesc := Ptr(DS,SI);
    DosBSeg := ES;
    DosBOfs := DI;
    For SectCnt:=0 To (BlockDesc^.NumSect - 1) Do
        Begin
            DosBuffer := Ptr(DosBSeg, DosBOfs);
            If Not RequestSector(BlockDesc^.StartSect + SectCnt, 1, DosBuffer^)
                Then
                Begin
                    AX := 1;
                    exit;
                End;
            DosBSeg := DosBSeg + 32;
        End;
    AX := 0;
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


{****************************************************************************
 * ISR_2 - Int_2F: Multiplex interrupt handler for external utility calls   *
 ****************************************************************************}

Procedure Int_2F(Flags, CS, IP, AX, BX, CX, DX, SI, DI, DS, ES, BP: Word);
interrupt;

Begin
    If (AX And $00F0) = $F0 Then
        Begin
            Case AX Of 
                $F0:   AX := $00FF;
                $F1:{Set_BPB};
                $F2:
                       Begin
                           If Attach Then
                               AX := 0
                           Else
                               AX := 1
                       End;
            End;
        End;
End;

Procedure Initialize;

Var  OpenSockets:   boolean;
    c:   char;

Begin
    writeln;
    Writeln('IPXFER 4.1 network shell  -  IPXFRLAN v.01 Beta');
    writeln('Copyright (c) 1996  Jackson Software');
    If Not IPXInstalled Then
        Begin
            writeln('Fatal Error: IPX is not loaded.');
            Halt(1);
        End;
    GetLocalAddress;
    writeln('Local Node Address: ',PrintNodeAddr(@LocalAddr.Node));
    FillChar(GlobalAddr.Node, 6, #255);
    FillChar(GlobalAddr.Network, 4 ,#00);
    If Not IPXFERSys Then
        Begin
            writeln('Fatal Error: IPXFER.SYS is not installed.');
            writeln;
            writeln('Please install the IPXFER.SYS file in your CONFIG.SYS');
            Halt(1);
        End;
    If RegisterDriver Then
        writeln('Successfully linked to device driver.')
    Else
        Begin
            writeln(
                    'Fatal Error: Unable to register with IPXFERSYS device driver.'
            );
            halt(1);
        End;
    OpenSockets := False;
    Case OpenSocket(SocketID) Of 
        00:   OpenSockets := true;
        $FF:
               Begin
                   writeln;
                   writeln('IPX Channel already open, use it anyway? (Y/N)');
                   Repeat
                       c := UpCase(ReadKey);
                   Until (c = 'Y') Or (c = 'N');
                   If c = 'Y' Then
                       OpenSockets := True;
               End;
        $FE:   writeln('IPX Socket table is full.');
    End;
    If Not OpenSockets Then
        Begin
            writeln('Fatal Error: Failed to open IPX socket.');
            Halt(1);
        End;
    FillChar(ReceivingPacket, Sizeof(TNetPacket), #00);
    ReceivingPacket.ecb.InUseFlag := $1D;
    ReceivingPacket.ecb.ECBSocket := SocketID;
    ReceivingPacket.ecb.FragmentCount := 1;
    ReceivingPacket.ecb.FAddr[1] := ofs(ReceivingPacket.IPXHeader);
    ReceivingPacket.ecb.FAddr[2] := seg(ReceivingPacket.IPXHeader);
    ReceivingPacket.ecb.FSize := sizeof(TNetEvent) - sizeof(TECB);
    IPXListenForPacket(ReceivingPacket);
    FillChar(SendingPacket, Sizeof(TNetPacket), #00);
    SendingPacket.ecb.ECBSocket := SocketID;
    SendingPacket.ecb.FragmentCount := 1;
    SendingPacket.ecb.FAddr[1] := ofs(SendingPacket.IPXHeader);
    SendingPacket.ecb.FAddr[2] := seg(SendingPacket.IPXHeader);
    Move(Localaddr.network[1],SendingPacket.ipxHeader.dNetwork[1],4);
    SendingPacket.IPXHeader.dSocket := SwapWord(SocketID);
    If Not Attach Then
        Begin
            CloseSocket(SocketID);
            Writeln;
            Writeln('Unable to find the Sendnet server.');
            Halt(1);
        End;
    ISR_Addr := @NetReadSectors;
End;

Begin
    writeln('Hello.');
    Initialize;
End.
