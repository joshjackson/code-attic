unit IPX;

interface

type  TLocalAddr=record
			Network	:array[1..4] of byte;
			node     :array[1..6] of byte;
		end;
		TNodeAddr=record
			Node   	:array[1..6] of byte;
		end;
		PIPXPacket=^TIPXPacket;
		TIPXPacket=record
			PacketChecksum				:word;
			PacketLength				:word;
			PacketTransportControl  :byte;
			PacketType					:byte;
			dNetwork						:array[1..4] of byte;
			dNode							:array[1..6] of byte;
			dSocket						:word;
			sNetwork						:array[1..4] of byte;
			sNode							:array[1..6] of byte;
			sSocket						:word;
		end;
		PECB=^TECB;
		TECB=record
			Link				:longint;
			ESRAddr			:longint;
			InUseFlag		:byte;
			CompletionCode :byte;
			ECBsocket		:word;
			IPXWork			:longint;
			DriverWork		:array[1..12] of byte;
			ImmediateAddr	:array[1..6] of byte;
			FragmentCount	:word;
			FAddr				:array[1..2] of word;
			FSize				:word;
		end;
		TPacketBuff=array[1..512] of byte;
		PDataPacketHeader=^TDataPacketHeader;
		TDataPacketHeader=record
			CRC		:longint;
			Sequence	:longint;
		end;
		PPacket=^TPacket;
		TPacket=record
			ECB					:TECB;
			IPXPacket			:TIPXPacket;
			FilePacketHeader  :TDataPacketHeader;
			PacketData			:TPacketBuff;
		end;
		PACKPacket=^TACKPacket;
		TACKPacket=record
			ECB		:TECB;
			IPXPacket:TIPXPacket;
			Sequence	:longint;
			Signal   :byte;
			Node		:array[1..6] of byte;
			Network	:array[1..4] of byte;
		end;

Function IPXInstalled:boolean;

implementation

uses DOS,CRT;

var	Regs:Registers;

Function IPXInstalled:boolean;

	begin
		Regs.ax:=$7A00;
		Intr($2F, Regs);
		if Regs.al=$FF then
			IPXInstalled:=True
		else
			IPXInstalled:=False;
	end;

Procedure CloseSocket(SocketNum:word); assembler;

	asm
		pusha
		mov 	bx,1
		mov 	dx,SocketNum
		int 	$7a
		popa
	end;

Procedure RelinquishControl; assembler;

	asm
		pusha
		mov 	bx,$0A
		int 	$7A
		popa
	end;

Procedure IPXListenForPacket(var ThePacket);

	var return_code:byte;

	begin
		asm
			pusha
			push bp
			les si,ThePacket
			mov bx,4
			int $7a
			pop bp
			mov return_code,al
			popa
		end;
{		if return_code > 0 then begin
			Error('Error Listening For Packet.');
		end;}
	end;

Function SwapWord(w:word):word; assembler;

	asm
		mov	ax,w
		xchg	ah,al
	end;

Procedure IPXSendPacket(var ThePacket); far; assembler;

	asm
		pusha
		les si,ThePacket
		mov bx,3
		int $7A
		popa
	end;

Function IPXPacketComplete(var Packet):boolean;

	begin
		if TPacket(Packet).ecb.InUseFlag > 0 then
			IPXPacketComplete:=False
		else
			IPXPacketComplete:=True;
	end;

Function IPXErrorMsg:string;

	begin
	end;

end.