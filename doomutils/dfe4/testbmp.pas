uses Wad,Walls,BMPout,crt,WadDecl;

var	WDir:PWadDirectory;
		Wall:PWallTexture;
		TNames:text;
		TName:ObjNameStr;
		TempStr:string;
		t:integer;

begin
	clrscr;
	writeln('Loading WAD Directory');
	WDir:=New(PWadDirectory, Init('D:\games\heretic\heretic.WAD'));
	assign(TNames,'texnames');
	reset(TNames);
	while not eof(TNames) do begin
		readln(TNames, TempStr);
		for t:=1 to Length(TempStr) do begin
			if t=9 then
				break;
			TName[t]:=TempStr[t];
		end;
		write('Loading Wall Texture: ',TName,', ');
		Wall:=New(PWallTexture, Init(WDir, TName));
		write('Writing BMP, ');
		WALL2BMP(WDir,Wall);
		Dispose(Wall, Done);
		writeln('Complete.');
	end;
	Dispose(WDir, Done);
end.