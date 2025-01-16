{****************************************************************************
*                      The DOOM Hacker's Tool Kit                           *
*****************************************************************************
* Unit   : OBJCACHE                                                         *
* Purpose: Object Cache Memory Allocation Deamon                            *
* Date:    4/28/94                                                          *
* Author:  Joshua Jackson        Internet: jsoftware@delphi.com             *
****************************************************************************}
{$F+,O+}
unit ObjCache;

interface

uses Wads,WadDecl,Crt,Memory;

const MaxLumps=15;
		MaxLumpSize=64000;

type  PCacheLump=^TCacheLump;
		TCacheLump=record
			Size     :word;
			Data     :BAP;
		end;
		PObjectCache=^TObjectCache;
		TObjectCache=Object
			Constructor Init(WDir:PWadDirectory;ObjNum:word);
			Procedure SetPos(NewPos:longint);
			Function CurPos:Longint;
			Procedure IncPos(IncVal:longint);
			Procedure CacheRead(var Dest;Count:word);
			Function GetSize:Longint;
			Destructor Done;
		 private
			NumLumps:byte;
			Lump:array[1..MaxLumps] of PCacheLump;
			CachePos:longint;
			LumpPos:word;
			CurLump:byte;
			Size:Longint;
		end;

Procedure FastMove(var S,D;Count:word);

implementation

Procedure FastMove(var S,D;Count:word);

	begin asm
		mov dx,ds
		cld
		mov bx,Count
		mov cx,bx
		and bx,1
		shr cx,1
		lds si,S
		les di,D
		rep movsw
		cmp bx,1
		jne @@Done
		movsb
	@@Done:
		mov ds,dx
	end end;


Constructor TObjectCache.Init(WDir:PWadDirectory;ObjNum:word);

	var   t:integer;

	begin
		if WDir^.EntrySize(ObjNum) > MaxAvail then begin
			TextMode(CO80);
			writeln('ObjectCache_Init: Insufficient Memory to Allocate Cache');
			halt(1);
		end;
		NumLumps:=WDir^.EntrySize(ObjNum) div MaxLumpSize;
		if NumLumps > MaxLumps then begin
			TextMode(CO80);
			writeln('ObjectCache_Init: NumLumps > MaxLumps');
			halt(1);
		end;
		for t:=1 to NumLumps do begin
			New(Lump[t]);
			Lump[t]^.Size:=MaxLumpSize;
			GetMem(Lump[t]^.Data,MaxLumpSize)
		end;
		if (WDir^.EntrySize(ObjNum) Mod MaxLumpSize) > 0 then begin
			Inc(NumLumps);
			new(Lump[NumLumps]);
			Lump[NumLumps]^.Size:=WDir^.EntrySize(ObjNum) Mod MaxLumpSize;
			GetMem(Lump[NumLumps]^.Data,Lump[NumLumps]^.Size)
		end;
		{Seek(WDir^.WadFile,WDir^.DirEntry^[ObjNum].ObjStart);}
            Wdir^.SeekEntry(ObjNum);
		for t:=1 to NumLumps do
			BlockRead(WDir^.WadFile,Lump[t]^.Data^,Lump[t]^.Size);
		Size:=GetSize;
		SetPos(0);
	end;

Procedure TObjectCache.SetPos(NewPos:longint);

	begin
		if NewPos > Size then begin
			TextMode(CO80);
			writeln('ObjectCache_SetPos: Attempted to set pointer past end of cache.');
			Halt;
		end;
		CurLump:=(NewPos div MaxLumpSize) + 1;
		LumpPos:=NewPos mod MaxLumpSize;
	end;

Function TObjectCache.CurPos:Longint;

	var   t:integer;
			TempPos:Longint;

	begin
		TempPos:=LumpPos;
		for t:=(CurLump - 1) Downto 1 do
			TempPos:=TempPos+Lump[t]^.Size;
		CurPos:=TempPos;
	end;

Procedure TObjectCache.IncPos(IncVal:longint);

	begin
		SetPos(CurPos + IncVal);
	end;

Procedure TObjectCache.CacheRead(var Dest;Count:word);

	var   DestPtr:pointer;
			Remaining,ReadSize:word;

	begin
		DestPtr:=@Dest;
		ReadSize:=Count;
		Remaining:=Count;
		if CurPos+Count > Size then begin
			TextMode(CO80);
			writeln('ObjectCache_CacheRead: Attempted to read past end of cache.');
			halt(1);
		end;
		repeat
			if (LumpPos+Remaining) > MaxLumpSize then
				ReadSize:=MaxLumpSize-LumpPos;
			Remaining:=Remaining-ReadSize;
{			move(Lump[CurLump]^.Data^[LumpPos],DestPtr^,ReadSize);}
			FastMove(Lump[CurLump]^.Data^[LumpPos],DestPtr^,ReadSize);
			if Remaining > 0 then begin
				{Longint(DestPtr):=Longint(DestPtr) + ReadSize;}
				DestPtr:=Ptr(Seg(DestPtr^), Ofs(DestPtr^)+ReadSize);
			end;
			SetPos(CurPos + ReadSize);
			ReadSize:=Remaining;
		until remaining = 0;
	end;

Function TObjectCache.GetSize:longint;

	var   t:integer;
			TempSize:longint;

	begin
		TempSize:=0;
		for t:=1 to NumLumps do
			TempSize:=TempSize+Lump[t]^.Size;
		GetSize:=TempSize;
	end;

Destructor TObjectCache.Done;

	var t:integer;

	begin
		for t:=1 to NumLumps do begin
			FreeMem(Lump[t]^.Data,Lump[t]^.Size);
			dispose(Lump[t]);
		end;
	end;

end.
