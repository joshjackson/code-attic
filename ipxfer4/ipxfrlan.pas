{$F+,O+}
Unit IPXFRLAN;

interface

uses IPX,Crt;


Function IPXFERSys:boolean;
Function RegisterDriver:boolean;
Procedure Initialize;
Function Attach:boolean;
Function SendAndWait(var Packet:TNetEvent; DataSize, WaitVal:word; MaxSend, Dest:integer):boolean;


implementation

uses Timer;


end.