
{****************************************************************************
 * Program    : IPXFER v4.00                                                *
 * Unit       : IPX                                                         *
 * Last Update: 11/26/95                                                    *
 * Written by : Joshua Jackson (jayjay@sal-junction.com)                    *
 * Purpose    : IPX I/O routines                                            *
 ****************************************************************************}

Unit IPX;

Interface

{$I STRUCTS.INC}

Var LocalAddr:   TLocalAddr;
    GlobalAddr:   TLocalAddr;

Function IPXInstalled: boolean;
Procedure GetLocalAddress;
Function OpenSocket(SocketNum:word): byte;
Procedure CloseSocket(SocketNum:word);
Procedure RelinquishControl;
Procedure IPXListenForPacket(Var ThePacket);
Function SwapWord(w:word):   word;
Procedure IPXSendPacket(Var ThePacket); far;
Function PrintNodeAddr(NodeAddr:PNodeAddr):   NodeStr;

Implementation

Uses DOS,CRT;

Var Regs:   Registers;

Function IPXInstalled:   boolean;

Begin
    Regs.ax := $7A00;
    Intr($2F, Regs);
    If Regs.al=$FF Then
        IPXInstalled := True
    Else
        IPXInstalled := False;
End;

Function OpenSocket(SocketNum:word):   byte;

	Var return_code:   byte;
		TheSocket:   word;

	Begin
		asm
		pusha
		push bp
		mov bx,0
		mov al,0
		mov dx,SocketNum
		Int $7A
		pop bp
		mov return_code,al
		mov TheSocket, dx
		popa
	End;
	OpenSocket := return_code;
End;

Procedure CloseSocket(SocketNum:word); assembler;

asm
	pusha
	mov  bx,1
	mov  dx,SocketNum
	int  $7a
	popa
End;

Procedure GetLocalAddress; assembler;

asm
	push es
	mov si,offset LocalAddr
	mov ax,seg LocalAddr
	mov es,ax
	mov bx,9
	int $7A
	pop es
End;

Procedure RelinquishControl; assembler;

asm
	pusha
	mov  bx,$0A
	int  $7A
	popa
End;

Procedure IPXListenForPacket(Var ThePacket);

Var return_code:   byte;

Begin
    asm
		pusha
		push bp
		les si,ThePacket
		mov bx,4
		int $7a
		pop bp
		mov return_code,al
		popa
	End;

{		if return_code > 0 then begin
			Error('Error Listening For Packet.');
		end;}
End;

Function SwapWord(w:word):   word; assembler;

asm
	mov ax,w
	xchg ah,al
End;

Procedure IPXSendPacket(Var ThePacket); assembler;

asm
	pusha
	les si,ThePacket
	mov bx,3
	int $7A
	popa
End;

Function PrintNodeAddr(NodeAddr:PNodeAddr):   NodeStr;

Const HexChars:   string[16] =   '0123456789ABCDEF';

Var  tmpstr:   string[12];
    t:   integer;
    b,b2:   byte;

Begin
    tmpstr := '';
    For t:=1 To 6 Do
        Begin
            b := NodeAddr^.node[t];
            tmpstr := tmpstr + HexChars[((b And $F0) shr 4) + 1] + HexChars[(b
                      And $0F) + 1];
        End;
    PrintNodeAddr := tmpstr;
End;

Begin
    FillChar(GlobalAddr.Node, 6, #255);
    FillChar(GlobalAddr.Network, 4 ,#00);
End.
