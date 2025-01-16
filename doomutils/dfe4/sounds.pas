{****************************************************************************
*                      The DOOM Hacker's Tool Kit                           *
*****************************************************************************
* Unit:    SOUNDS                                                           *
* Purpose: Loading and Playing WAD file sounds                              *
* Date:    4/28/94                                                          *
* Author:  Joshua Jackson        Internet: jsoftware@delphi.com             *
****************************************************************************}

{$O+,F+}
{$C FIXED,PERMANENT,PRELOAD}
unit Sounds;

interface

uses Wad,WadDecl,Crt;

Type  PWadSound=^TWadSound;
		TWadSound=object
			DMABuff:BAP; {used by DPMI}
			ID:ObjNameStr;
			SoundBuff:PSoundBuff;
			Constructor Init(WDir:PWadDirectory;SndName:ObjNameStr);
			Procedure PlaySound;
			Function IsComplete:boolean;
			Procedure EndSound;
			Destructor Done;
		private
			IsPlaying:Boolean;
			sbBuff:word;
			RealSeg:word;
		end;

implementation

uses SBC,Dos,Memory;

var   BuffPtr:BAP;

Constructor TWadSound.Init(WDir:PWadDirectory;SndName:ObjNameStr);

	var   l:word;

	begin
		l:=WDir^.FindObject(SndName);
		if l=0 then begin
			if TerminateOnWadError then begin
				TextMode(co80);
				writeln('ReadSound: Could not locate sound ID: ',SndName);
				halt(1);
			 end
			else begin
				WadResult:=wrNoSound;
				exit;
			end;
		end;
		seek(WDir^.WadFile,WDir^.DirEntry^[l].ObjStart);
		New(SoundBuff);                  {Allocate New Sound Descriptor}
		BlockRead(WDir^.WadFile,SoundBuff^,8);
		SoundBuff^.Sound:=MemAllocSeg(SoundBuff^.Samples);
		BlockRead(WDir^.WadFile,SoundBuff^.Sound^,SoundBuff^.Samples);
		IsPlaying:=False;
		ID:=SndName;
	end;

Procedure TWadSound.PlaySound;

	var   TempAddr:word;
			Regs:Registers;
			MemSize:word;
			BuffAddr:longint;
			MsgStr,TempStr:string;
			t:word;

	begin
		if IsPlaying then
			EndSound;
		BuffPtr:=@SoundBuff^.Sound^;
		BuffAddr:=(longint(Seg(BuffPtr^)) shl 4) + Ofs(BuffPtr^);
		PlayBuff(SoundBuff,BuffAddr);
		IsPlaying:=True;
	end;

Function TWadSound.IsComplete;

	begin
		IsComplete:=DMA_Complete;
	end;

Procedure TWadSound.EndSound;

	begin
		if not IsPlaying then
			exit;
		StopBuff;
		IsPlaying:=False;
		SetVoice(0);
	end;

Destructor TWadSound.Done;

	begin
		FreeMem(SoundBuff^.Sound,SoundBuff^.Samples); {Dispose Sound Data}
		Dispose(SoundBuff);                           {Dispose Sound Descriptor}
	end;

end.
