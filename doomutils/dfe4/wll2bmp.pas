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
	WDir:=New(PWadDirectory, Init('D:\DOOM\DOOM.WAD'));
	Wall:=New(PWallTexture, Init(WDir, 'COMPOHSO'));
	write('Writing BMP, ');
	WALL2BMP(WDir,Wall);
	Dispose(Wall, Done);
	writeln('Complete.');
	Dispose(WDir, Done);
end.