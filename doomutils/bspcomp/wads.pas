{$T-}
Unit Wads;

interface

uses Objects;

Type	ObjNameDef=array[1..8] of char;
		ObjNameStr=String[8];

type	PWadDirectory=^TWadDirectory;
		PWADDirEntry=^TWADDirEntry;

		TWADDirEntry=record
			ObjStart :longint;
			ObjLength:longint;
			ObjName  :ObjNameDef;
		end;

		TWadDirectory=object(TCollection)
			WadName		:array[1..9] of char;
			PathName		:PString;
			IsDOOM2		:boolean;
			WadFile		:file;
			WadID			:array[1..4] of char;
			DirEntries	:longint;
			DirStart		:longint;
			Constructor Init(WadFileName:String);
			Function At(Index: integer):PWadDirEntry;
			Procedure FreeItem(P: Pointer); virtual;
			Procedure DisplayWadDir;
			Function FindObject(ObjName:ObjNameStr):integer;
			Function FindObjectFrom(ObjName:ObjNameStr;Start:word):integer;
			Procedure SetWadPalette(PlayPalNum:integer);
			Procedure RestorePalette;
			Procedure SeekEntry(E: integer);
			Function	EntryPos(e: integer):longint;
			Function EntrySize(e: integer):longint;
			Function EntryName(e: integer):ObjNameStr;
			Procedure ReadEntry(e:integer; var Buff);
			Destructor Done; virtual;
		 private
			Function ValidEntry(e:integer):Boolean;
		end;

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
		wrTooBig			= 09;
		wrBadIndex		= 10;
		ShowInit			:boolean=False;
		WadPaletteIsSet:Boolean=false;

		ThingPos			= 1;
		LineDefPos		= 2;
		SideDefPos		= 3;
		VertexPos		= 4;
		SegsPos			= 5;
		SSectorsPos		= 6;
		NodesPos			= 7;
		SectorsPos		= 8;
		RejectPos		= 9;
		BlockMapPos		= 10;

Function ObjNameDefToStr(O:ObjNameDef):ObjNameStr;
Function WadResultMsg(ErrNum:byte):string;

implementation

{$IFDEF WINDOWS}
Uses WinCrt,WinDos;
{$ELSE}
Uses Crt,WinDos,Dos;
{$ENDIF}

var	OldPalette:array[1..768] of byte;

Function ObjNameDefToStr(O:ObjNameDef):ObjNameStr;

	var	TempStr:String[8];
			t:integer;

	begin
		TempStr:='';
		for t:=1 to 8 do
			if (O[t] <> #00) and (O[t] <> ' ') then
				TempStr:=TempStr+O[t];
		ObjNameDefToStr:=TempStr;
	end;

{TWadDirectory Object Declaration--------------------------------------}
{$I-}
Constructor TWadDirectory.Init(WadFileName:String);

	var	DirSize:longint;
			C:longint;
			Temp:PWadDirEntry;

	begin
		Inherited Init(2500,10);
		PathName:=NewStr(WadFileName);
		if ShowInit then
			writeln('TWadDirectory.Init: Initializing WAD file');
		assign(WadFile,WadFileName);
		reset(WadFile,1);
		if IOResult<>0 then begin
			if TerminateOnWadError then begin
            {$IFNDEF WINDOWS}
				TextMode(CO80);
            {$ENDIF}
				writeln('TWadDirectory.Init: Error Reading WAD FILE: ',WadFileName);
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
            {$IFNDEF WINDOWS}
				TextMode(CO80);
            {$ENDIF}
				Close(WadFile);
				writeln('TWadDirectory.Init: ',WadFileName,' is not a valid WAD file');
				halt(1);
			 end
			else begin
				WadResult:=wrInvalidFile;
				exit;
			end;
		end;
		if DirEntries > MaxCollectionSize then begin
			if TerminateOnWadError then begin
            {$IFNDEF WINDOWS}
				TextMode(CO80);
            {$ENDIF}
				Close(WadFile);
				write('TWadDirectory.Init: Can not allocate for more than ',MaxCollectionSize,' entires.');
			 end
			else begin
				WadResult:=wrMaxEntries;
				exit;
			end;
		end;
		DirSize:=DirEntries * 16;
		SetLimit(DirEntries);
		if ShowInit then
			writeln('   TWadDirectory.Init: ',DirSize,' Allocated for directory.');
		seek(WadFile, DirStart);
		for c:=1 to DirEntries do begin
			New(Temp);
			BlockRead(WadFile, Temp^, SizeOf(TWadDirEntry));
			Insert(Temp);
		end;
		if FindObject('MAP??') >= 0 then
			IsDoom2:=True
		else
			IsDoom2:=False;
		WadResult:=wrOk;
	end;
{$I+}

Function TWadDirectory.At(Index: Integer):PWadDirEntry;

	begin
		At:=TCollection.At(Index);
	end;

Procedure TWadDirectory.FreeItem(P: Pointer);

	begin
		Dispose(PWadDirEntry(p));
	end;

Function TWadDirectory.FindObject(ObjName:ObjNameStr):integer;

	var	t,x:integer;
			TempName:ObjNameDef;

	begin
		{Convert to Upper case and change spaces to #00}
		x:=Length(ObjName);
		ObjName[0]:=#8;
		for t:=8 downto 1 do begin
			if (ObjName[t] = ' ') or (t > x) then
				ObjName[t]:= #0
			else
				ObjName[t]:=Upcase(ObjName[t]);
		end;
		{Scan directory for matching name using ? as a wildcard character}
		for t:=0 to (Count - 1) do begin
			for x:=1 to 8 do
				if ObjName[x]='?' then
					TempName[x]:=At(t)^.ObjName[x]
				else
					TempName[x]:=ObjName[x];
			if At(t)^.ObjName = TempName then begin
				FindObject:=t;
				exit;
			end;
		end;
		FindObject:=-1;
	end;

Function TWadDirectory.FindObjectFrom(ObjName:ObjNameStr;Start:word):integer;

	var	t,x:integer;
			TempName:ObjNameDef;

	begin
		x:=Length(ObjName);
		ObjName[0]:=#8;
		for t:=8 downto 1 do begin
			if (ObjName[t] = ' ') or (t > x) then
				ObjName[t]:= #0
			else
				ObjName[t]:=Upcase(ObjName[t]);
		end;
		for t:=Start to (Count - 1) do begin
			for x:=1 to 8 do
				if ObjName[x]='?' then
					TempName[x]:=At(t)^.ObjName[x]
				else
					TempName[x]:=ObjName[x];
			if At(t)^.ObjName = TempName then begin
				FindObjectFrom:=t;
				exit;
			end;
		end;
		FindObjectFrom:=-1;
	end;

{Sets the currect graphics palette to PLAYPAL0}
Procedure TWadDirectory.SetWadPalette(PlayPalNum:integer);


	var	{$IFNDEF WINDOWS}
         Regs:Registers;
         {$ELSE}
         Regs:TRegisters;
			{$ENDIF}
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
		if PalEnt=-1 then begin
			if TerminateOnWadError then begin
            {$IFNDEF WINDOWS}
            TextMode(CO80);
            {$ENDIF}
				writeln('SetWadPalette: Could not locate PLAYPAL');
				halt(1);
			 end
			else begin
				WadResult:=wrNoPalette;
				exit;
			end;
		end;
		Seek(WadFile,At(PalEnt)^.ObjStart + (768 * PlayPalNum));
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

{Restores the graphics palette to its original state}
Procedure TWadDirectory.RestorePalette;

	var   {$IFNDEF WINDOWS}
			Regs:Registers;
         {$ELSE}
         Regs:TRegisters;
         {$ENDIF}

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

{Displays a text directory listing}
Procedure TWadDirectory.DisplayWadDir;

	var	x:word;

	begin
		writeln('Directory of WAD: ',WadName);
		for x:=0 to Count do begin
			with At(x)^ do begin
				writeln(ObjName,'         ',ObjStart,'          ',ObjLength);
			end;
		end;
	end;

Procedure TWadDirectory.SeekEntry(e:integer);

	begin
		Seek(WadFile, At(e)^.ObjStart);
	end;

Function TWadDirectory.EntryPos(e:integer):longint;

	begin
		EntryPos:=At(e)^.ObjStart;
	end;

Function TWadDirectory.EntrySize(e:integer):longint;

	begin
		EntrySize:=At(e)^.ObjLength;
	end;

Function TWadDirectory.EntryName(e:integer):ObjNameStr;

	begin
		EntryName:=At(e)^.ObjName;
	end;

Procedure TWadDirectory.ReadEntry(e:integer; var Buff);

	begin
		if EntrySize(e) > 65520 then begin
			if TerminateOnWadError then begin
            {$IFNDEF WINDOWS}
            TextMode(CO80);
            {$ENDIF}
				writeln('TWadDirectory.ReadEntry: Entry size is > 64k');
				halt(1);
			end else begin
				WadResult:=wrTooBig;
				Exit;
			end;
		end;
		SeekEntry(e);
		BlockRead(WadFile, Buff, EntrySize(e));
	end;

Function TWadDirectory.ValidEntry(e:integer):Boolean;

	begin
		if (e < 0) or (e >= Count) then begin
			if TerminateOnWadError then begin
            {$IFNDEF WINDOWS}
            TextMode(CO80);
            {$ENDIF}
				writeln('TWadDirectory.ValidateEntryNum: Directory index out of range');
				halt(1);
			end;
			ValidEntry:=False;
			WadResult:=wrBadIndex;
		end else
			ValidEntry:=True;
	end;

Destructor TWadDirectory.Done;

	var	DirSize:word;

	begin
		Inherited Done;
		close(WadFile);
		DisposeStr(PathName);
	end;

{Returns a text messages for the WadErrorNum passed in ErrNum}
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
			wrTooBig:WadResultMsg:='Entry too large for ReadEntry (>64k)';
			wrBadIndex:WadResultMsg:='Directory index out of range';
		else
			WadResultMsg:='Unknown WAD file Error'
		end;
	end;


end.