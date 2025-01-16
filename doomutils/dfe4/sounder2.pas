unit Sounder2;

  {$C FIXED PRELOAD PERMANENT}
  {$M 65520,64500,655350}
interface

uses WadDecl;

var	sbDMA,SbIOAddr,SbIRQ:word;
		CH_BASE,CH_COUNT:word;
		DMA_Complete:boolean;
		SBVectSet:boolean;

Function InitSB:boolean;
Procedure SetSbIOAddr(NewAddr:word);
Procedure SetSbIRQ(NewIRQ:word);
Procedure SetVoice(State:integer);
Procedure DPMI_PlayBuff(BuffAddr,SoundSize:longint);
Procedure PlayBuff(sBuff:PSoundBuff;BuffAddr:longint);
Procedure StopBuff;
Function SysInitSB:Boolean;
Procedure SysDoneSB;

Implementation

uses DOS,CRT;

CONST	DMA			=0;   	{DMA Constants}
		CH0_BASE 	=0;
		CH0_COUNT 	=1;
		CH1_BASE 	=2;
		CH1_COUNT 	=3;
		CH2_BASE 	=4;
		CH2_COUNT 	=5;
		CH3_BASE 	=6;
		CH3_COUNT 	=7;
		DMA_STATUS  =8;
		DMA_CMD		=8;
		DMA_REQUEST =9;
		DMA_MASK		=10;
		DMA_MODE		=11;
		DMA_FF		=12;
		DMA_TMP		=13;
		DMA_CLEAR	=13;
		DMA_CLRMSK	=14;
		DMA_WRMSK	=15;
		DMAPAGE		=$80;

		DSP_WRITE_STATUS	=$C;		{Sound Blaster Constants}
		DSP_WRITE_DATA		=$C;

PROCEDURE cli;
INLINE
  (
  $FA    {CLI}
  );

PROCEDURE sti;
INLINE
  (
  $FB    {STI}
  );

{$F+}


var	IRQVect:pointer;
		OldExit:Pointer;

Function InitSB:boolean;

	var RetVal:Boolean;

	begin
		asm
			 mov al,1
			 mov dx,sbIOaddr
			 add dx,6
			 out dx,al
			 in	al,dx
			 in	al,dx
			 in	al,dx
			 in	al,dx
			 mov al,0
			 out dx,al
			 add dx,4
			 mov cx,100
		@@1:
			 in al,dx
			 cmp al,0AAh
			 je @@2
			 loop @@1
			 mov  RetVal,False
			 jmp @@3
		@@2:
			 mov RetVal,True
		@@3:
		end;
		InitSb:=RetVal;
	end;

Procedure SetSbIOAddr(NewAddr:word);

	begin
		SbIOAddr:=NewAddr;
	end;

Procedure writeDAC(v:byte);

	var b:byte;

	begin
		repeat
			b:=port[sbIOAddr+DSP_WRITE_STATUS];
		until (b and $80)=0;
		port[sbIOAddr+DSP_WRITE_DATA]:=v;
	end;

Procedure SetVoice(State:Integer);

	begin
		case State of
			1:writeDAC($D1);	{Voice On}
			0:writeDAC($D3);	{Voice Off}
		end;
	end;

Procedure SetSampleRate(Rate:word);

	var	tc:byte;

	begin
		tc:=(256 - (1000000 div rate));
		writeDAC($40);
		writeDAC(tc);
	end;

Procedure SetPICStatus;

	var im,tm:byte;

	begin
		im:=port[$21];
		tm:=(1 shl sbIRQ) xor $FF;
		port[$21]:=(im and tm);
		sti;
	end;

Procedure SetDMAStatus(BuffAddr:longint;DataLen:word);

	var	t:word;

	begin
		{Set DMA Mode}
		port[DMA_MASK]:=5;
		port[DMA_FF]:=0;
		port[DMA_MODE]:=$49;
		{Set Transfer Address}
		t:=(BuffAddr shr 16);
		port[DMAPAGE+3]:=t;
		t:=(BuffAddr and $FFFF);
		port[CH_BASE]:=(t and $FF);
		port[CH_BASE]:=(t shr 8);
		{Set Transfer Length Byte Count}
		port[CH_COUNT]:=(DataLen and $FF);
		port[CH_COUNT]:=(DataLen shr 8) and $FF;
		{Unmask DMA Channel}
		port[DMA_MASK]:=1;
	end;

Procedure SetDACStatus(DataLen:word);

	begin
		{Set Up Sound Blaster for transfer}
		writeDAC($48);		{Setup DAC for DMA Transfer}
		writeDAC(DataLen and $FF);
		writeDAC((DataLen shr 8) and $FF);
		writeDAC($14);
		writeDAC(DataLen and $FF);
		writeDAC((DataLen shr 8) and $FF);
	end;

{$F+,S-,W-}
procedure IRQProc(Flags, CS, IP, AX, BX, CX, DX, SI, DI, DS, ES, BP: Word);

	interrupt;
	begin
		STI;
		DMA_Complete:=True;
		port[$20]:=$20;
	end;
{$F-,S+}

Procedure SetSbIRQ(NewIRQ:word);

	begin
		SbIRQ:=NewIRQ;
	end;

Function SysInitSB:boolean;

	begin
		SbVectSet:=False;
		if not InitSB then begin
			SysInitSB:=False;
			exit
		end;
		CLI;
		GetIntVec($08+sbIRQ,IRQVect);
		SetIntVec($08+sbIRQ,@IRQProc);
		STI;
		DMA_Complete:=False;
		SysInitSB:=True;
		case sbDMA of
			0:begin
				CH_BASE:=CH0_BASE;
				CH_COUNT:=CH0_COUNT;
			  end;
			1:begin
				CH_BASE:=CH1_BASE;
				CH_COUNT:=CH1_COUNT;
			  end;
			3:begin
				CH_BASE:=CH3_BASE;
				CH_COUNT:=CH3_COUNT;
			  end;
		end;
		SbVectSet:=True;
	end;

Procedure SysDoneSB;

	begin
		if SbVectSet then begin
			SetIntVec($08+sbIRQ,IRQVect);
			SetVoice(0);
		end;
	end;

Procedure DPMI_PlayBuff(BuffAddr,SoundSize:longint);


	begin
		DMA_complete:=False;
		if SoundSize > 26000 then begin
			SetSampleRate(11025);
			SetPICStatus;
			SetDMAStatus(BuffAddr,26000);
			SetDACStatus(26000);
			SetVoice(1);
			while not DMA_complete do begin end;
			if not KeyPressed then begin
				SetVoice(0);
				InitSb;
				DMA_Complete:=False;
				BuffAddr:=((BuffAddr shr 4)+1000) shl 4;
				SetSampleRate(11025);
				SetPICStatus;
				SetDMAStatus(BuffAddr,SoundSize - 26000);
				SetDACStatus(SoundSize - 26000);
				SetVoice(1);
			end;
		 end
		else begin
			DMA_complete:=False;
			SetSampleRate(11025);
			SetPICStatus;
			SetDMAStatus(BuffAddr,SoundSize);
			SetDACStatus(SoundSize);
			SetVoice(1);
		end;
	end;

Procedure PlayBuff(sBuff:PSoundBuff;BuffAddr:longint);

	type TBuff=Array[0..46080] of byte;

	begin
		DMA_complete:=False;
		SetSampleRate(sBuff^.SampleRate);
		SetPICStatus;
		SetDMAStatus(BuffAddr,sBuff^.Samples);
		SetDACStatus(sBuff^.Samples);
		SetVoice(1);
	end;

Procedure StopBuff;

	begin
		SetVoice(0);
	end;

begin
	DMA_Complete:=False;
end.
