{****************************************************************************
*                      The DOOM Hacker's Tool Kit                           *
*****************************************************************************
* Unit:    VirtScrn                                                         *
* Purpose: Provides a 320x200x256 tweaked video mode for high speed         *
*          animation sequencing                                             *
* Date:    7/14/94                                                          *
* Author:  Joshua Jackson        Internet: jsoftware@delphi.com             *
****************************************************************************}
{$F-}
unit VIRTSCRN;

interface

type  PVirtualBuffer=^TVirtualBuffer;
		TVirtualBuffer=array[0..63999] of byte;
		PVirtualScreen=^TVirtualScreen;
		TVirtualScreen=object
			ScreenPage:byte;
			ScrnBuff:PVirtualBuffer;
			constructor Init;
			Procedure ValidateIO;
			procedure Insert(var Data;x,y,xofs,yofs,Scale:word);
			Procedure Clear;
			procedure Transfer;
			procedure Activate;
			destructor Done;
		end;

Procedure InitVirtualScreens(I:integer);
Procedure DoneVirtualScreens;
Procedure InitVideoMode;
Procedure DoneVideoMode;

var	VideoPage:array[1..4] of PVirtualScreen;

implementation

{$l \doomprg\pas\whtk\dfe\movemem.obj}

uses Crt,Memory;{,ObjCache;}

Procedure Move32(var s,d;c:word); external;
Procedure Fill32(var d;v:longint;c:word); external;
Procedure TransferScrn(var s);external;

const	SC_INDEX       = $3c4;             {Index register for sequencer ctrl.}
		SC_MAP_MASK    = 2   ;             {Number of map mask register}
		SC_MEM_MODE    = 4   ;             {Number of memory mode register}

		GC_INDEX       = $3ce;             {Index register for graphics ctrl.}
		GC_READ_MAP    = 4   ;             {Number of read map register}
		GC_GRAPH_MODE  = 5   ;             {Number of graphics mode register}
		GC_MISCELL     = 6   ;             {Number of miscellaneous register}

		CRTC_INDEX     = $3d4;             {Index register for CRT controllers}
		CC_MAX_SCAN    = 9   ;             {Number of maximum scan line reg.}
		CC_START_HI    = $0C ;             {Number of high start register}
		CC_UNDERLINE   = $14  ;            {Number of underline register}
		CC_MODE_CTRL   = $17  ;            {Number of mode control register}

		DAC_WRITE_ADR  = $3C8 ;            {DAC write address}
		DAC_READ_ADR   = $3C7 ;            {DAC read address}
		DAC_DATA       = $3C9 ;            {DAC data register}

		VERT_RESCAN    = $3DA ;            {Input status register #1}

		PIXX           = 320  ;            {Horizontal resolution}

var	Current_Page:byte;
		VideoModeSet:boolean;
		Vio_Seg:word;

Procedure InitVirtualScreens(I:integer);

	var	t:integer;

	begin
		if I > 4 then begin
			TextMode(CO80);
			writeln('V_Init: NumVirtualScreens > 4');
			halt;
		end else if I < 1 then begin
			writeln('V_Init: NumVirtualScreens < 1');
			halt;
		end;
		for t:=1 to I do begin
			VideoPage[t]:=New(PVirtualScreen, Init);
			VideoPage[t]^.ScreenPage:= t-1;
		end;
	end;

Procedure DoneVirtualScreens;

	var	t:integer;

	begin
		for t:=1 to 4 do
			if VideoPage[t] <> Nil then
				Dispose(VideoPage[t], Done);
	end;

{InitVideoMode  Initializes the 320x200x256 tweaked graphics mode}
Procedure InitVideoMode;

	begin
		vio_seg:=SegA000;
		current_page:=0;
		asm
			mov   ax,0013h         {Set normal mode 13H}
			int   10h

			mov   dx,GC_INDEX      {Memory division}
			mov   al,GC_GRAPH_MODE {Disable bit 4 of}
			out   dx,al            {graphic mode register}
			inc   dx               {in graphics controller}
			in    al,dx
			and   al,11101111b
			out   dx,al
			dec   dx

			mov   al,GC_MISCELL    {And change bit 1}
			out   dx,al            {in the miscellaneous}
			inc   dx               {register}
			in    al,dx
			and   al,11111101b
			out   dx,al

			mov   dx,SC_INDEX      {Modify memory mode register in}
			mov   al,SC_MEM_MODE   {sequencer controlller so no further}
			out   dx,al            {address division follows in}
			inc   dx               {bitplanes, and set the bitplane}
			in    al,dx            {currently in the}
			and   al,11110111b     {bit mask register}
			or    al,4
			out   dx,al

			mov   ax,SegA000       {Fill all four bitplanes with color}
			mov   vio_seg,ax       {code 00H and clear the screen}
			mov   es,ax
			xor   di,di
			mov   ax,di
			mov   cx,8000h
			rep   stosw

			mov   dx,CRTC_INDEX    {Set double word mode using bit 6}
			mov   al,CC_UNDERLINE  {in underline register of}
			out   dx,al            {CRT controller}
			inc   dx
			in    al,dx
			and   al,10111111b
			out   dx,al
			dec   dx

			{Using bit 6 in mode control reg.}
			{of CRT controller, change}
			{from word mode to byte mode}
			mov   al,CC_MODE_CTRL
			out   dx,al
			inc   dx
			in    al,dx
			or    al,01000000b
			out   dx,al
			mov 	VideoModeSet, True;
			mov	Current_Page, 0;
		end;
	end;
{DoneVideo  Restores text mode}
Procedure DoneVideoMode;

	begin
		TextMode(CO80);
		VideoModeSet:=False;
	end;

Constructor TVirtualScreen.Init;

	begin
		ScrnBuff:=MemAllocSeg(64000);
		FillChar(ScrnBuff^,64000,#0);
		if ScrnBuff=Nil then begin
			TextMode(CO80);
			writeln('MemAllocSeg failed on allocation of 64000 bytes.');
			halt;
		end;
	end;

{TVirtualScreen.ValidateIO  Ensures that the current video work page is the
									 Page specified by the Object's ScreenPage field}
Procedure TVirtualScreen.ValidateIO;

	var s:byte;

	begin
		s:=(ScreenPage * 4) + $A0;
		vio_seg:=word(s) shl 8;
	end;

{TVirtualScreen.Insert  Transfers the image from Data to the Object's
								screen buffer at the specified offset and scale}
Procedure TVirtualScreen.Insert(var Data;x,y,xofs,yofs,Scale:word);

	var 	Source:PVirtualBuffer;
			s,d,y2:word;

	begin
		Source:=@Data;
		for y2:=0 to (y-1) do begin
			s:=(x * y2);
			d:=(((yofs + y2) * 320))+xofs;
			Move32(Source^[s], ScrnBuff^[d], x);
		end;
	end;

{TVirtualScreen.Clear  Clears the virtual screen buffer}
Procedure TVirtualScreen.Clear;

	begin
		Fill32(ScrnBuff^[0], 0, 64000);
	end;

{TVirtualScreen.Transfer  Transfers the image from the Object's Screen
								  buffer to the screen page specifed in ScreenPage}
Procedure TVirtualScreen.Transfer;

	var	Plane:byte;
			s,o:word;

	begin
		ValidateIO;
		TransferScrn(ScrnBuff^);
		exit;
	end;

{TVirtualScreen.Activate  Switches the current display page to the page
								  number stored in the Object's ScreenPage field}
Procedure TVirtualScreen.Activate;

	var s:byte;

	begin
		s:=ScreenPage;
		asm
			xor 	ch,ch
			mov 	cl,s

			mov   al,64            {High byte of offset = page * 64}
			mul   cl
			mov   ah,al            {Move high byte of offset to AH}

			{-- Load new starting address ------------------------------}

			mov   dx,CRTC_INDEX    {Address CRT controller}
			mov   al,CC_START_HI   {Move register number}
			out   dx,ax            {to AL and exit}

			{-- Wait to return to starting screen design ---------------}

			mov   dx,VERT_RESCAN   {Wait for end of}
		@@sp3:
			in    al,dx            {vertical rescan}
			test  al,8
			jne   @@sp3

		@@sp4:
			in    al,dx            {Go to start of rescan}
			test  al,8
			je    @@sp4
		end;
	end;

Destructor TVirtualScreen.Done;

	begin
		FreeMem(ScrnBuff, 64000);
	end;

begin
	VideoModeSet:=False;
end.