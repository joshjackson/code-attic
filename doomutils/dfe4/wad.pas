{****************************************************************************
*                      The DOOM Hacker's Tool Kit                           *
*****************************************************************************
* Unit: 	  WAD                                                              *
* Purpose: Loading WAD File directory and much more                         *
* Date:    4/28/94                                                          *
* Author:  Joshua Jackson        Internet: jsoftware@delphi.com             *
****************************************************************************}

{$O+,F+}
unit wad;

interface

uses WadDecl,Objects;

type	PWadDirectory=^TWadDirectory;
		TWadDirectory=object
			WadName		:array[1..9] of char;
			WadFile		:file;
			WadID			:array[1..4] of char;
			DirEntries	:longint;
			DirStart		:longint;
			DirEntry 	:PWADDirList;
			Constructor Init(WadFileName:String);
			Procedure DisplayWadDir;
			Function FindObject(ObjName:ObjNameStr):word;
			Function FindObjectFrom(ObjName:ObjNameStr;Start:word):word;
			Procedure SetWadPalette(PlayPalNum:integer);
			Procedure RestorePalette;
			Destructor Done;
		end;

Function WadResultMsg(ErrNum:byte):string;

Const TerminateOnWadError:boolean=True;
		WadResult		:Integer = 0;
		wrOk				= 00;
		wrInvalidFile	= 01;
		wrMaxEntries	= 02;
		wrNoObject		= 03;
		wrNoSound		= 04;
		wrBadImageSize = 05;
		wrNoPicture		= 06;
		wrNoPalette		= 07;
		wrNoFile			= 08;
		ShowInit			:boolean=False;
		WadPaletteIsSet:Boolean=false;

implementation

uses crt,windos,dos;

var	OldPalette:array[1..768] of byte;

{TWadDirectory Object Declaration--------------------------------------}

Function TWadDirectory.FindObject(ObjName:ObjNameStr):word;

	var	t,x:integer;
			TempName:ObjNameStr;

	begin
		for t:=8 downto 1 do begin
			if ObjName[t] = ' ' then
				ObjName[t]:= #0;
			ObjName[t]:=Upcase(ObjName[t]);
		end;
		for t:=1 to DirEntries do begin
			for x:=1 to 8 do
				if ObjName[x]='?' then
					TempName[x]:=DirEntry^[t].ObjName[x]
				else
					TempName[x]:=ObjName[x];
			if DirEntry^[t].ObjName = TempName then begin
				FindObject:=t;
				exit;
			end;
		end;
		FindObject:=0;
	end;

Function TWadDirectory.FindObjectFrom(ObjName:ObjNameStr;Start:word):word;

	var	t,x:integer;
			TempName:ObjNameStr;

	begin
		for t:=8 downto 1 do begin
			if ObjName[t] = ' ' then
				ObjName[t]:= #0;
			ObjName[t]:=Upcase(ObjName[t]);
		end;
		for t:=Start to DirEntries do begin
			for x:=1 to 8 do
				if ObjName[x]='?' then
					TempName[x]:=DirEntry^[t].ObjName[x]
				else
					TempName[x]:=ObjName[x];
			if DirEntry^[t].ObjName = TempName then begin
				FindObjectFrom:=t;
				exit;
			end;
		end;
		FindObjectFrom:=0;
	end;

Procedure TWadDirectory.SetWadPalette(PlayPalNum:integer);

	var 	Regs:Registers;
			PalEnt:word;
			PBuff:array[1..768] of byte;

	begin
		if Not WadPaletteIsSet then begin
			with regs do begin
				Regs.ax:=$1017;
				Regs.es:=Seg(OldPalette);
				Regs.dx:=ofs(OldPalette);
				Regs.bx:=0;
				Regs.cx:=256;
				Intr($10,Regs);
			end;
		end;
		PalEnt:=FindObject('PLAYPAL ');
		if PalEnt=0 then begin
			if TerminateOnWadError then begin
				TextMode(CO80);
				writeln('SetWadPalette: Could not locate PLAYPAL');
				halt(1);
			 end
			else begin
				WadResult:=wrNoPalette;
				exit;
			end;
		end;
		Seek(WadFile,DirEntry^[PalEnt].ObjStart + (768 * PlayPalNum));
		Blockread(WadFile,Pbuff,768);
		for PalEnt:=1 to 768 do
			Pbuff[PalEnt]:=Pbuff[PalEnt] div 4;
		with regs do begin
			ax:=$1012;
			bx:=0;
			cx:=256;
			es:=seg(PBuff);
			dx:=ofs(PBuff);
			Intr($10,Regs);
		end;
		WadResult:=wrOk;
		WadPaletteIsSet:=True;
	end;

Procedure TWadDirectory.RestorePalette;

	var	Regs:Registers;

	begin
		if WadPaletteIsSet then begin
			with regs do begin
				ax:=$1012;
				bx:=0;
				cx:=256;
				es:=seg(OldPalette);
				dx:=ofs(OldPalette);
				Intr($10,Regs);
			end;
		end;
		WadPaletteIsSet:=False;
	end;

{$I-}
Constructor TWadDirectory.Init(WadFileName:String);

	var	DirSize:longint;

	begin
		if ShowInit then
			writeln('W_Init: Initializing WAD file');
		assign(WadFile,WadFileName);
		reset(WadFile,1);
		if IOResult<>0 then begin
			if TerminateOnWadError then begin
				TextMode(CO80);
				writeln('WadDirectory_Init: Error Reading WAD FILE: ',WadFileName,':',IOResult);
				halt(1);
			 end
			else begin
				WadResult:=wrNoFile;
				exit;
			end;
		end;
		WadFileName:=WadFileName+#0;
		FillChar(WadName,8,#0);
		filesplit(@WadFileName,NIL,@WadName,NIL);
		blockread(WadFile,WadID,12);
		if (WadID<>'IWAD') and (WadID<>'PWAD') then begin
			if TerminateOnWadError then begin
				TextMode(CO80);
				Close(WadFile);
				writeln('W_Init: ',WadFileName,' is not a valid WAD file');
				halt(1);
			 end
			else begin
				WadResult:=wrInvalidFile;
				exit;
			end;
		end;
		if DirEntries > MaxEntries then begin
			if TerminateOnWadError then begin
				TextMode(CO80);
				Close(WadFile);
				write('   W_Init_Alloc: Can not allocate for more than ',MaxEntries);
				writeln(' Directory Entries');
				halt(1);
			 end
			else begin
				WadResult:=wrMaxEntries;
				exit;
			end;
		end;
		DirSize:=DirEntries * 16;
		GetMem(DirEntry, DirSize);
		FillChar(DirEntry^,DirSize,#00);
		if ShowInit then
			writeln('   W_Init_Alloc: ',DirSize,' Allocated for directory');
		seek(WadFile, DirStart);
		BlockRead(WadFile, DirEntry^, DirSize);
		WadResult:=wrOk;
	end;

Procedure TWadDirectory.DisplayWadDir;

	var	x:word;

	begin
		writeln('Directory of WAD: ',WadName);
		for x:=1 to DirEntries do begin
			with DirEntry^[x] do begin
				writeln(ObjName,'         ',ObjStart,'          ',ObjLength);
			end;
		end;
	end;

Destructor TWadDirectory.Done;

	var	DirSize:word;

	begin
		close(WadFile);
		DirSize:=DirEntries * 16;
		FreeMem(DirEntry, DirSize);
	end;

Function WadResultMsg(ErrNum:byte):string;

	begin
		case ErrNum of
			wrOk:WadResultMsg:='';
			wrInvalidFile:WadResultMsg:='Invalid WAD file Format';
			wrMaxEntries:WadResultMsg:='Too many WAD directory Entries';
			wrNoObject:WadResultMsg:='Specified WAD Object Not Found';
			wrNoSound:WadResultMsg:='Specified WAD Sound Not Found';
			wrBadImageSize:WadResultMsg:='Invalid WAD Image Size';
			wrNoPicture:WadResultMsg:='Specified Picture ID Not Found';
			wrNoPalette:WadResultMsg:='PLAYPAL Entry Not Found';
			wrNoFile:WadResultMsg:='Error Accessing WAD File';
		else
			WadResultMsg:='Unknown WAD file Error'
		end;
	end;

end.
