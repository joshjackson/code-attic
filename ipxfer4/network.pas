
{****************************************************************************
 * Program    : IPXFER v4.00 beta 1                                         *
 * Unit       : Network                                                     *
 * Last Update: 11/24/95                                                    *
 * Written by : Joshua Jackson (jayjay@sal-junction.com)                    *
 * Purpose    : Common network routines                                     *
 ****************************************************************************}

Unit Network;

Interface

Uses IPX,Dos,Objects,crt, LFN, Win95API;

{$I PACKETS.INC}

Type PReceiveBuffers =   ^TReceiveBuffers;
    TReceiveBuffers =   array[1..MAXRECEIVEBUFFERS] Of TNetPacket;

    PSendBuffers =   ^TSendBuffers;
    TSendBuffers =   array[1..MAXSENDBUFFERS] Of TNetPacket;

    PSearchRec =   ^SearchRec;

    PSearchRecs =   ^TSearchRecs;
    TSearchRecs =   Array[1..50] Of PSearchRec;

    PLFNSearchRecs =   ^TLFNSearchRecs;
    TLFNSearchRecs =   Array[1..50] Of ^TLFNSearchRec;

    PConnectionEntry =   ^TConnectionEntry;
    TConnectionEntry =   Record
        IsConnected:   boolean;
        NodeAddress:   TLocalAddr;
        ConnectTime:   longint;
        PacketsSent:   longint;
        PacketsReceived:   longint;
        ClientFile:   file;
        ClientLongFile:   Word;
        FileIsOpen:   Boolean;
        ClientDirectory:   String;
        ClientSearchRecs:   PSearchRecs;
        ClientLFNSearchRecs:   PLFNSearchRecs;
        Sequence:   Longint;
        StartDepth:   integer;
        SearchDepth:   integer;
    End;

    PConnectionTable =   ^TConnectionTable;
    TConnectionTable =   Array[1..MAXCONNECTIONS] Of TConnectionEntry;

      {IPX Packet Manager object declaration}
    PIOBuffer =   ^TIOBuffer;
    TIOBuffer =   Object
        ReceiveBuffer:   PReceiveBuffers;
        SendBuffer:   PSendBuffers;
        CurrentReceiveBuffer:   integer;
        CurrentSendBuffer:   integer;
        constructor Init(MaxConnect:byte);
        Function CompareNode(n1,n2:PLocalAddr):   boolean;
        Function WhoIs(rp:integer):   integer;
        Function RetrieveEvent(Var Event:TNetEvent):   boolean;
        Procedure PutEvent(Event:TNetEvent; DataSize:word; Dest:integer);
        destructor Done;
    End;

Var ConnectionTable:   PConnectionTable;
    PacketsIn, PacketsOut:   longint;

Function OpenClientFiles:   integer;
Function CalcSearchDepth(s:String):   integer;
Procedure SetSearchDepth(Conn:PConnectionEntry; NewDepth:integer);

Implementation

Function OpenClientFiles:   integer;

Var c,t:   integer;

Begin
    c := 0;
    For t:=1 To MAXCONNECTIONS Do
        Begin
            If ConnectionTable^[t].IsConnected And ConnectionTable^[t].
               FileIsOpen Then
                Inc(c);
        End;
    OpenClientFiles := c;
End;

Function CalcSearchDepth(s:String):   integer;

Var  t, Depth:   integer;

Begin
    Depth := 0;
    For t:=1 To Length(s) Do
        If s[t] = '\' Then
            Inc(Depth);
    CalcSearchDepth := Depth + 1;
End;

Procedure SetSearchDepth(Conn:PConnectionEntry; NewDepth:integer);

Begin
    If NewDepth > Conn^.SearchDepth Then
        Begin
            If LFNSupport Then
                New(Conn^.ClientLFNSearchRecs^[NewDepth])
            Else
                New(Conn^.ClientSearchRecs^[NewDepth]);
            Conn^.SearchDepth := NewDepth;
        End
    Else If NewDepth < Conn^.SearchDepth Then
             Begin
                 If LFNSupport Then
                     Begin
                         LFNFindClose(Conn^.ClientLFNSearchRecs^[Conn^.
                                      SearchDepth]^);
                         Dispose(Conn^.ClientSearchRecs^[Conn^.SearchDepth]);
                     End
                 Else
                     Dispose(Conn^.ClientSearchRecs^[Conn^.SearchDepth]);
                 Conn^.SearchDepth := NewDepth;
             End;
End;

Constructor TIOBuffer.Init(MaxConnect:byte);

Var t:   integer;

Begin
    {Allocate sending and receiving ECBs}
    New(ReceiveBuffer);
    New(SendBuffer);
      {Post the listening ECBs}
    Fillchar(ReceiveBuffer^, Sizeof(TNetPacket) * MAXRECEIVEBUFFERS, #00);
    For t:=1 To MAXRECEIVEBUFFERS Do
        Begin
            ReceiveBuffer^[t].ecb.InUseFlag := $1D;
            ReceiveBuffer^[t].ecb.ECBSocket := SocketID;
            ReceiveBuffer^[t].ecb.FragmentCount := 1;
            ReceiveBuffer^[t].ecb.FAddr[1] := ofs(ReceiveBuffer^[t].IPXHeader);
            ReceiveBuffer^[t].ecb.FAddr[2] := seg(ReceiveBuffer^[t].IPXHeader);
            ReceiveBuffer^[t].ecb.FSize := sizeof(TNetEvent) - sizeof(TECB);
            IPXListenForPacket(ReceiveBuffer^[t]);
        End;
    Fillchar(SendBuffer^, sizeof(TNetPacket) * MAXSENDBUFFERS, #00);
    For t:=1 To MAXSENDBUFFERS Do
        Begin
            SendBuffer^[t].ecb.ECBSocket := SocketID;
            SendBuffer^[t].ecb.FragmentCount := 1;
            SendBuffer^[t].ecb.FAddr[1] := ofs(SendBuffer^[t].IPXHeader);
            SendBuffer^[t].ecb.FAddr[2] := seg(SendBuffer^[t].IPXHeader);
            Move(Localaddr.network[1],SendBuffer^[t].ipxHeader.dNetwork[1],4);
            SendBuffer^[t].IPXHeader.dSocket := SwapWord(SocketID);
        End;
      {Reset Counters}
    CurrentReceiveBuffer := 1;
    CurrentSendBuffer := 1;
    PacketsIn := 0;
    PacketsOut := 0;
End;

Function TIOBuffer.CompareNode(n1,n2:PLocalAddr):   boolean;

Var t:   integer;

Begin
    CompareNode := True;
    For t:=1 To 6 Do
        Begin
            If n1^.Node[t] <> n2^.Node[t] Then
                CompareNode := False;
        End;
End;

Function TIOBuffer.WhoIs(rp:integer):   integer;

Var t:   integer;

Begin
    For t:=1 To MAXCONNECTIONS Do
        Begin
            If ConnectionTable^[t].IsConnected Then
                Begin
                    If CompareNode(@ReceiveBuffer^[rp].IPXHeader.sNetwork,@
                       ConnectionTable^[t].NodeAddress) Then
                        Begin
                            WhoIs := t;
                            Exit;
                        End;
                End;
        End;
    WhoIs := -1;
End;

Function TIOBuffer.RetrieveEvent(Var Event:TNetEvent):   boolean;

Procedure NextBuffer;
Begin
    Inc(CurrentReceiveBuffer);
    If CurrentReceiveBuffer > MAXRECEIVEBUFFERS Then
        CurrentReceiveBuffer := 1;
End;

Var t:   integer;

Begin
    For t:=1 To MAXRECEIVEBUFFERS Do
        Begin
            If ReceiveBuffer^[CurrentReceiveBuffer].ECB.InUseFlag=0 Then
                Begin
            {Copy the received packet into an Event structure}
                    Move(ReceiveBuffer^[CurrentReceiveBuffer].NetData, Event,
                         sizeof(TNetEvent));
            {Determine the sender of the packet}
                    Event.Who := WhoIs(CurrentReceiveBuffer);
            {Set the packet sequence value}
                    ConnectionTable^[Event.Who].Sequence := Event.Sequence;
            {Repost the ECB}
    {ReceiveBuffer^[t].ecb.InUseFlag:=$1D;}
                    IPXListenForPacket(ReceiveBuffer^[CurrentReceiveBuffer]);
            {Signal a received event}
                    RetrieveEvent := True;
            {Set counter}
                    NextBuffer;
                    Inc(PacketsIn);
                    Exit;
                End;
            NextBuffer;
        End;
      {No packets received}
    RetrieveEvent := False;
End;


{----------------------------------------------------------------------------
	TIOBuffer.PutEvent: Sends a network packet to specified receiver}

Procedure TIOBuffer.PutEvent(Event:TNetEvent; DataSize:word; Dest:integer);

Var  t:   integer;
    TempAddr:   TLocalAddr;
    ClearToSend:   Boolean;

Begin
  {Check if IPX is still using the Sending ECBs}
    ClearToSend := False;
    While Not ClearToSend Do
        Begin
            RelinquishControl; {Give IPX an extra time slice}
            For t:=1 To MAXSENDBUFFERS Do
                Begin
                    If SendBuffer^[t].ecb.InUseFlag = 0 Then
                        Begin
                            ClearToSend := True;
                            Break;
                        End;
                End;
        End;
  {Set Destination Address}
    If Dest=-1 Then
        TempAddr := GlobalAddr
    Else
        Begin
            TempAddr := ConnectionTable^[Dest].NodeAddress;
            Event.Sequence := ConnectionTable^[Dest].Sequence;
        End;
    move(TempAddr.Node,SendBuffer^[t].IPXHeader.dNode,6);
    move(TempAddr.Node,SendBuffer^[t].ecb.ImmediateAddr,6);
  {Specify Destination Socket}
    SendBuffer^[t].IPXHeader.dsocket := SocketID;
  {Set the size of the packet}
    SendBuffer^[t].ecb.fsize := sizeof(TIPXPacket) + DataSize + EVENTSIZE;
      {Place the data into the packet}
    move(Event, SendBuffer^[t].NetData, EVENTSIZE + DataSize);
  {Faster than Federal Express!!}
    IPXSendPacket(SendBuffer^[t]);
    Inc(PacketsOut);
End;


{----------------------------------------------------------------------------
	TIOBuffer.Done : Dispose of all sending and receiving ECBs
 	Warning			: All IPX Sockets must be closed before calling!!}

Destructor TIOBuffer.Done;

Begin
    {Dispose of ECBs}
    Dispose(ReceiveBuffer);
    Dispose(SendBuffer);
End;

End.
