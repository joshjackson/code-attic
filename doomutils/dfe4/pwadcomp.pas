unit PWADCOMP;

interface

uses Wad,WadDecl,Objects,Gauges,Dialogs,App;

const	otPWad	= 01;
		otRaw		= 02;
		otBMP		= 03;
		otWAV		= 04;

Type	PGroupDir=^TGroupDir;
		TGroupDir=record
			EntryNum	:word;
			NewName	:ObjNameStr;
			OwnerType:byte;
			Owner		:PWadDirectory;
			Start		:Longint;
		end;
		TWadHeader=record
			ID				:array[1..4] of char;
			DirEntries  :longint;
			DirStart		:longint;
		end;
		TDirEntry=record
			Start		:longint;
			Size		:longint;
			Name		:ObjNameStr;
		end;
		PPWadDef=^TPWadDef;
		TPWadDef=object(TCollection)
			WadFileName:string;
			OutFile:File;
			Constructor Init(FName:String);
			Function TotalSize:Longint;
			Function CheckDependancy(WDir:PWadDirectory):word;
			Function FindObject(N:ObjNameStr):word;
			Function At(Index:integer):PGroupDir;
			Procedure FreeItem(Item:Pointer); virtual;
			Procedure Compile;
			Procedure AddEntry(WDir:PWadDirectory;Entry:word;NewName:ObjNameStr);
			Procedure DeleteWithOwner(WDir:PWadDirectory);
		Private
			Procedure WriteHeader(ID:String;NumEntries,StartPos:Longint);
			Procedure CopyEntry(Num:word);
			Procedure WriteDirectory;
		end;

Procedure ErrorBox(S:String);
Procedure CreatePWad;

implementation

uses Memory,MsgBox,Crt,Drivers,StdDlg;

Procedure ErrorBox(S:String);

	begin
		MessageBox(S,Nil,mfOkButton);
	end;

Procedure CreatePWad;

	var	Compiler:PPWadDef;
			WDir:PWadDirectory;
			t:longint;
			x:integer;
			PD:PGroupDir;

	begin
		WDir:=New(PWadDirectory, Init('D:\DOOM\DOOM.WAD'));
		Compiler:=New(PPWadDef, Init('testtest.wad'));
		for t:=1 to WDir^.DirEntries do begin
			New(PD);
			FillChar(PD^, Sizeof(TGroupDir), #00);
			PD^.Owner:=WDir;
			PD^.NewName:=WDir^.DirEntry^[t].ObjName;
			PD^.EntryNum:=t;
			for x:=1 to 8 do
				if PD^.NewName[x] = #32 then PD^.NewName[x]:=#00;
			if PD^.NewName[1] = #00 then
				Dispose(PD)
			else if (PD^.NewName[1]='D') and ((PD^.NewName[2]='S') or (PD^.NewName[2]='P')) then
				Compiler^.Insert(PD);
		end;
		Compiler^.Compile;
	end;

Constructor TPWadDef.Init(FName:String);

	begin
		TCollection.Init(512, 5);
		WadFileName:=FName;
	end;

Procedure TPWadDef.FreeItem(Item:Pointer);

	begin
		if Item <> Nil then Dispose(PGroupDir(Item));
	end;

Function TPWadDef.At(Index:integer):PGroupDir;

	begin
		At:=PGroupDir(TCollection.At(Index));
	end;

Procedure TPWadDef.Compile;

	var   R:Trect;
			CompileBox:PDialog;
			StatusNum:PPercentGauge;
			StatusBar:PBarGauge;
			TempStr:String;
			t:word;
			InputWad,InputEntry,OutputEntry,
			NumWritten,CurrentSize:PStaticText;
			Temp:TGroupDir;
			E:TEvent;

	begin
		{Setup our compiler Status Window}
		R.assign(10,5,70,15);
		CompileBox:=New(PDialog, Init(R, 'Compiling PWAD'));
		CompileBox^.Flags:=0;
		R.Assign(3,2,28,3);
		CompileBox^.Insert(New(PstaticText, Init(R, 'Output PWAD: '+WadFileName)));
		R.Assign(29,2,40,3);
		CompileBox^.Insert(New(PstaticText, Init(R, 'Input WAD:')));
		R.Assign(40,2,52,3);
		InputWad:=New(PstaticText, Init(R, '        '));
		CompileBox^.Insert(InputWad);
		R.Assign(3,3,11,4);
		CompileBox^.Insert(New(PstaticText, Init(R, 'Reading:')));
		R.Assign(12,3,21,4);
		InputEntry:=New(PstaticText, Init(R, '         '));
		CompileBox^.Insert(InputEntry);
		R.Assign(29,3,41,4);
		CompileBox^.Insert(New(PstaticText, Init(R, 'Writing:')));
		R.Assign(38,3,51,4);
		OutputEntry:=New(PstaticText, Init(R, '         '));
		CompileBox^.Insert(OutputEntry);
		R.Assign(3,5,25,6);
		Str(Count, TempStr);
		CompileBox^.Insert(New(PstaticText, Init(R, 'Total Entries: '+TempStr)));
		R.Assign(29,5,45,6);
		CompileBox^.Insert(New(PstaticText, Init(R, 'Entries Written:')));
		R.Assign(46,5,55,6);
		NumWritten:=New(PstaticText, Init(R, '         '));
		CompileBox^.Insert(NumWritten);
		R.Assign(34,8,47,9);
		CompileBox^.Insert(New(PstaticText, Init(R, 'Current Size:')));
		R.Assign(48,8,58,9);
		CurrentSize:=New(PstaticText, Init(R, '         '));
		CompileBox^.Insert(CurrentSize);
		R.Assign(27,8,31,9);
		StatusNum:=New(PPercentGauge, Init(R, Count));
		CompileBox^.Insert(StatusNum);
		R.Assign(3,8,26,9);
		StatusBar:=New(PBarGauge, Init(R, Count));
		CompileBox^.Insert(StatusBar);
		{Place it on the Desktop}
		DeskTop^.Insert(CompileBox);
		{Open the output file}
		FileMode:=2;		{Read/Write}
		assign(OutFile, WadFileName);
		rewrite(OutFile, 1);
		{Place a dummy header into the PWad}
		WriteHeader('PWAD',0,0);
		{Copy the data in the PWad and set Start value for directory}
		For t:=0 to (Count - 1) do begin
			Temp:=TGroupDir(At(t)^);
			Move(Temp.Owner^.DirEntry^[Temp.EntryNum].ObjName,InputEntry^.Text^[1], 8);
			InputEntry^.Draw;
			Move(Temp.NewName, OutputEntry^.Text^[1], 8);
			OutputEntry^.Draw;
			Move(Temp.Owner^.WadName,InputWad^.Text^[1],8);
			InputWad^.Draw;
			CopyEntry(t);
			Str(FilePos(OutFile) - 1, TempStr);
			CurrentSize^.Text^:=TempStr;
			CurrentSize^.Draw;
			Str(t + 1, TempStr);
			NumWritten^.Text^:=TempStr;
			NumWritten^.Draw;
			E.What:=evBroadcast;
			E.Command:=cmUpdateGauge;
			E.InfoLong:=t + 1;
			StatusBar^.HandleEvent(E);
			StatusNum^.HandleEvent(E);
		end;
		{Write the PWad's Finalized Header}
		WriteHeader('PWAD', Count, FilePos(OutFile));
		{Write the PWad's Directory Structure}
		WriteDirectory;
		{Close our PWad}
		Close(OutFile);
		readln;
		Dispose(CompileBox, Done);
	end;

Function TPWadDef.TotalSize:Longint;

	var	t:integer;
			s:longint;
			Temp:TGroupDir;

	begin
		if Count = 0 then begin
			TotalSize:=0;
			exit;
		end;
		s:=0;
		for t:=0 to (Count - 1) do begin
			Temp:=TGroupDir(At(t)^);
			s:=s+(Temp.Owner^.DirEntry^[Temp.EntryNum].ObjLength)
		end;
		s:=s + (Count * 16) + 12;
		TotalSize:=s;
	end;

Function TPWadDef.FindObject(N:ObjNameStr):word;

	var	t,x:word;

	begin
		if Count = 0 then begin
			FindObject:=0;
			exit;
		end;
		for x:=1 to 8 do begin
			if N[x] = ' ' then
				N[x]:=#00;
		end;
		for t:=0 to (Count - 1) do
			if At(t)^.NewName=N then begin
				FindObject:=t + 1;
				exit;
			end;
		FindObject:=0;
	end;


Procedure TPWadDef.AddEntry(WDir:PWadDirectory;Entry:word;NewName:ObjNameStr);

	var	Temp:PGroupDir;
			t:byte;

	begin
		New(Temp);
		Temp^.Owner:=WDir;
		Temp^.EntryNum:=Entry;
		for t:=1 to 8 do
			if NewName[t]=' ' then NewName[t]:=#00;
		Temp^.NewName:=NewName;
		Insert(Temp);
	end;

Function TPWadDef.CheckDependancy(WDir:PWadDirectory):word;

	var n,t:word;

	begin
		n:=0;
		if Count = 0 then begin
			CheckDependancy:=0;
			exit;
		end;
		for t:=0 to (Count - 1) do
			if TGroupDir(At(t)^).Owner = Wdir then
				Inc(n);
		CheckDependancy:=n;
	end;

Procedure TPWadDef.DeleteWithOwner(Wdir:PWadDirectory);

	var t,p:integer;

	begin
		if Count = 0 then
			exit;
		p:=0;
		for t:=0 to (Count - 1) do begin
			if TGroupDir(At(p)^).Owner = WDir then
				AtFree(p)
			else
				Inc(p);
		end;
	end;

Procedure TPWadDef.WriteHeader(ID:String;NumEntries,StartPos:longint);

	var	WH:TWadHeader;
			fp:longint;

	begin
		fp:=FilePos(OutFile);
		Seek(OutFile, 0);
		Move(ID[1], WH.ID, 4);
		WH.DirEntries:=NumEntries;
		WH.DirStart:=StartPos;
		BlockWrite(OutFile, WH, Sizeof(TWadHeader));
		if fp > 0 then
			Seek(OutFile, fp);
	end;

Procedure TPWadDef.CopyEntry(Num:word);

	Type	CopyBuffer=Array[1..64000] of byte;

	var	t:integer;
			p,c:longint;
			Temp:TGroupDir;
			CopyBuff:^CopyBuffer;

	begin
		TGroupDir(At(Num)^).Start:=FilePos(OutFile);
		Temp:=TGroupDir(At(Num)^);
		CopyBuff:=MemAllocSeg(64000);
		if CopyBuff=Nil then begin
			MessageBox('PWMGR: Insufficient Memory.',Nil,mfError+mfOkButton);
			TextMode(CO80);
			Halt(1);
		end;
		p:=Temp.Owner^.DirEntry^[Temp.EntryNum].ObjLength div 64000;
		c:=Temp.Owner^.DirEntry^[Temp.EntryNum].ObjLength mod 64000;
		Seek(Temp.Owner^.WadFile, Temp.Owner^.DirEntry^[Temp.EntryNum].ObjStart);
		for t:=1 to p do begin
			BlockRead(Temp.Owner^.WadFile, CopyBuff^, 64000);
			BlockWrite(OutFile, CopyBuff^, 64000);
		end;
		BlockRead(Temp.Owner^.WadFile, CopyBuff^, c);
		BlockWrite(OutFile, CopyBuff^, c);
		FreeMem(CopyBuff, 64000);
	end;

Procedure TPWadDef.WriteDirectory;

	var	t:word;
			Temp:TGroupDir;
			DE:TDirEntry;

	begin
		for t:=0 to (Count - 1) do begin
			Temp:=TGroupDir(at(t)^);
			DE.Start:=Temp.Start;
			DE.Size:=Temp.Owner^.DirEntry^[Temp.EntryNum].ObjLength;
			if DE.Size = -1 then DE.Size:=0;
			DE.Name:=Temp.NewName;
			BlockWrite(OutFile, DE, SizeOf(TDirEntry));
		end;
	end;

end.