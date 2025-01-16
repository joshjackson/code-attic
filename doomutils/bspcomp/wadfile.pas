unit WadFile;

interface

uses Wads,Objects;

Const FILEBUFFSIZE = 61440;

type	PWadHeader=^TWadHeader;
			TWadHeader=record
				ID				:array[1..4] of char;
        DirEntries  :longint;
        DirStart		:longint;
			end;

    PStorage=^TStorage;
		POutputWad=^TOutputWad;
		TOutputWad=Object(TCollection)
    	WadFile:File;
      WadName:String[80];
      WadHeader:PWadHeader;
      Constructor Init(FName:String);
      Procedure FreeItem(i:pointer); virtual;
      Function At(i:integer):PWadDirEntry;
      Procedure AddName(EName:ObjNameStr);
      Procedure AddLenName(EName:ObjNameStr;Size:longint);
      Procedure AddFromFile(FName:String;EName:ObjNameStr);
      Procedure AddFromWad(WDir:PWadDirectory; EntryNum:integer);
      Procedure AddStorage(S:PStorage; EName:ObjNameStr; ESize:longint);
      Procedure AddCollection(C:PCollection; EName:ObjNameStr; ESize:longint);
      Procedure AddBuff(var B; EName:ObjNameStr; Size:Longint);
      Procedure AppendData(var B; Size:Longint);
      Procedure SafeWrite(var B; Size:Longint);
			Destructor Done; virtual;
     private
     	Procedure FileTransfer(var F:File; Start,Length:Longint);
    end;

    TStorage=Object(TCollection)
			Description:PString;
			Constructor Init(ALimit, ADelta:integer; Desc:String);
			Procedure Error(code, info:integer); virtual;
      Destructor Done; virtual;
		end;


implementation

Constructor TStorage.Init(ALimit, ADelta:integer; Desc:String);

	begin
		TCollection.Init(Alimit, ADelta);
		Description:=NewStr(Desc);
	end;

Procedure TStorage.Error(code, info:integer);

	begin
		writeln;
		writeln;
		if code = coIndexError then begin
			writeln(Description^,'.error: Collection index error (',info,', ',count,')');
			Halt(1);
		end else
			TCollection.Error(Code, info);
	end;

Destructor TStorage.Done;

	begin
   	TCollection.Done;
  	DisposeStr(Description);
  end;

Constructor TOutputWad.Init(FName:String);

	begin
   	TCollection.Init(50, 25);
   	WadName:=FName;
    Assign(WadFile, FName);
    Rewrite(WadFile ,1);
   	New(WadHeader);
    FillChar(WadHeader^, Sizeof(TWadHeader), #00);
    SafeWrite(WadHeader^, Sizeof(TWadHeader));
  end;

Procedure TOutputWad.FreeItem(I:Pointer);

	begin
   	if I<>Nil then Dispose(PWadDirEntry(I));
  end;

Function TOutputWad.At(i:integer):PWadDirEntry;

	begin
   	At:=TCollection.At(i);
  end;

Procedure TOutputWad.AddName(EName:ObjNameStr);

	var	E:PWadDirEntry;
   		T:Integer;

  begin
   	New(e);
    for t:=1 to Length(EName) do
    	if EName[t]=' ' then EName[t]:=#00;
    for t:=1 to (8 - Length(EName)) do
    	EName:=EName+#00;
    move(EName[1], E^.ObjName, 8);
    E^.ObjStart:=FileSize(WadFile);
    E^.ObjLength:=0;
    Insert(E);
  end;

Procedure TOutputWad.AddLenName(EName:ObjNameStr;Size:longint);

	var	E:PWadDirEntry;
   		T:Integer;

	begin
  	New(e);
    for t:=1 to Length(EName) do
    	if EName[t]=' ' then EName[t]:=#00;
    for t:=1 to (8 - Length(EName)) do
    	EName:=EName+#00;
    move(EName[1], E^.ObjName, 8);
    E^.ObjStart:=FileSize(WadFile);
    E^.ObjLength:=Size;
    Insert(E);
	end;

Procedure TOutputWad.AddFromFile(FName:String;EName:ObjNameStr);

	var	E:PWadDirEntry;
			F:File;
      t:integer;

	begin
  	New(E);
    for t:=1 to Length(EName) do
    	if EName[t]=' ' then EName[t]:=#00;
    for t:=1 to (8 - Length(EName)) do
    	EName:=EName+#00;
    move(EName[1], E^.ObjName, 8);
    E^.ObjStart:=FileSize(WadFile);
    Assign(F, FName);
    Reset(F, 1);
    E^.ObjLength:=FileSize(F);
    FileTransfer(F, 0, FileSize(F));
	end;

Procedure TOutputWad.AddFromWad(WDir:PWadDirectory; EntryNum:integer);

	var	e:PWadDirEntry;

	begin
   	New(E);
    E^:=WDir^.At(EntryNum)^;
    E^.ObjStart:=FileSize(WadFile);
    Seek(WadFile, FileSize(WadFile));
		FileTransfer(WDir^.WadFile, E^.ObjStart, E^.ObjLength);
    Insert(E);
  end;

Procedure TOutputWad.AddStorage(S:PStorage; EName:ObjNameStr; ESize:longint);

	var	e:PWadDirEntry;
   		t:integer;

	begin
   	New(E);
    for t:=1 to Length(EName) do
    	if EName[t]=' ' then EName[t]:=#00;
    for t:=1 to (8 - Length(EName)) do
    	EName:=EName+#00;
    move(EName[1], E^.ObjName, 8);
    E^.ObjStart:=FileSize(WadFile);
    E^.ObjLength:=S^.Count * ESize;
		for t:=0 to (S^.Count - 1) do
    	SafeWrite(S^.At(t)^, ESize);
    Insert(E);
	end;

Procedure TOutputWad.AddCollection(C:PCollection; EName:ObjNameStr; ESize:longint);

	var	e:PWadDirEntry;
   		t:integer;

	begin
   	New(E);
    for t:=1 to Length(EName) do
    	if EName[t]=' ' then EName[t]:=#00;
    for t:=1 to (8 - Length(EName)) do
    	EName:=EName+#00;
    move(EName[1], E^.ObjName, 8);
    E^.ObjStart:=FileSize(WadFile);
    E^.ObjLength:=C^.Count * ESize;
		for t:=0 to (C^.Count - 1) do
    	SafeWrite(C^.At(t)^, ESize);
    Insert(E);
  end;

Procedure TOutputWad.AddBuff(var B; EName:ObjNameStr; Size:Longint);

	var	E:PWadDirEntry;
   		t:integer;

	begin
   	New(E);
    for t:=1 to Length(EName) do
    	if EName[t]=' ' then EName[t]:=#00;
    for t:=1 to (8 - Length(EName)) do
    	EName:=EName+#00;
    move(EName[1], E^.ObjName, 8);
    E^.ObjLength:=Size;
    E^.ObjStart:=FileSize(WadFile);
    SafeWrite(B, Size);
    Insert(E);
  end;

Procedure TOutputWad.AppendData(var B; Size:Longint);

	begin
  	Seek(WadFile, FileSize(WadFile));
    SafeWrite(B, Size);
  end;

Procedure TOutputWad.SafeWrite(var B; Size:Longint);

	var c:word;

	begin
  	if Size > 65520 then begin
    	Writeln('TOutputWad.SafeWrite: Invalid Object Size.');
      Halt(1);
    end;
   	BlockWrite(WadFile, B, Size, C);
		if C < Size then begin
    	Writeln('TOutputWad.SafeWrite: Unable to write to file.');
      Halt(1);
  	end;
	end;

Destructor TOutputWad.Done;

	var	t:integer;

	begin
   	WadHeader^.DirEntries:=Count;
    WadHeader^.DirStart:=FileSize(WadFile);
    WadHeader^.ID:='PWAD';
    {Write to final header}
    Seek(WadFile,0);
    SafeWrite(WadHeader^, Sizeof(TWadHeader));
    {Write the directory}
    Seek(WadFile, FileSize(WadFile));
		for t:=0 to (count - 1) do
    	SafeWrite(At(t)^, Sizeof(TWadDirEntry));
    {Clean up after ourself}
    Close(WadFile);
    Dispose(WadHeader);
   	TCollection.Done;
  end;

Procedure TOutputWad.FileTransfer(var F:File; Start,Length:Longint);

	var	p:pointer;
   		PassCount:word;
      remain:word;
      w:word;

	begin
  	GetMem(p, FILEBUFFSIZE);
   	Seek(F, Start);
    PassCount:=Length div FILEBUFFSIZE;
    Remain:=Length mod FILEBUFFSIZE;
    for w:=1 to PassCount do begin
    	Blockread(F, p^, FILEBUFFSIZE);
      Blockwrite(WadFile, P^, FILEBUFFSIZE);
    end;
    Blockread(F, p^, Remain);
    Blockwrite(WadFile, p^, Remain);
    FreeMem(p, FILEBUFFSIZE);
  end;

end.