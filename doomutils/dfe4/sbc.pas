unit SBC;

  {$C FIXED PRELOAD PERMANENT}
  {$M 65520,64500,655350}
interface

uses WadDecl;

var	sbDMA,SbIOAddr,SbIRQ:word;
		CH_BASE,CH_COUNT:word;
		SBVectSet:boolean;

Function InitSB:boolean;
Procedure SetVoice(State:integer);
Procedure PlayBuff(sBuff:PSoundBuff;BuffAddr:longint);
Procedure StopBuff;
Function SysInitSB:Boolean;
Function DMA_Complete:boolean;
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

Procedure dspwrite(b:byte);

	begin
		while ((port[sbIOaddr + $0C] and $80) <> 0) do;
		port[sbIOAddr + $0C]:=b;
	end;

procedure sbhaltdma;

	begin
		dspwrite($D0);
	end;

Procedure spkon;

	begin
		dspwrite($D1);
	end;

Procedure spkoff;

	begin
		dspwrite($D3);
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
		dspwrite($40);
		dspwrite(tc);
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
		dspwrite($48);		{Setup DAC for DMA Transfer}
		dspwrite(DataLen and $FF);
		dspwrite((DataLen shr 8) and $FF);
		dspwrite($14);
		dspwrite(DataLen and $FF);
		dspwrite((DataLen shr 8) and $FF);
	end;

Function SysInitSB:boolean;

	begin
		if not InitSB then begin
			SysInitSB:=False;
			exit
		end;
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
	end;

Function dmacount:word;

	var	x:word;
			j:byte;

	begin
		x:=Port[CH_COUNT];
		x:=x or (Port[CH_COUNT] shl 8);
		if x=$FFFF then
			j:=Port[sbIoAddr + $0E];
		dmacount:=x;
	end;

Function DMA_Complete:Boolean;

	begin
		if dmacount = $FFFF then
			DMA_Complete:=True
		else
			DMA_Complete:=False;
	end;

procedure SysDoneSB;

	begin
	end;

Procedure PlayBuff(sBuff:PSoundBuff;BuffAddr:longint);

	begin
		spkon;
		SetSampleRate(sBuff^.SampleRate);
		SetDMAStatus(BuffAddr,sBuff^.Samples);
		SetDACStatus(sBuff^.Samples);
	end;

Procedure StopBuff;

	begin
		sbhaltdma;
		spkoff;
	end;

end.
