uses WAD;

var	f:file;
		PalBuff:array[1..768] of byte;
		WDir:PWadDirectory;
		PalPos:word;
      dname:string;

begin
	if ParamCount=0 then begin
		writeln;
		writeln('USAGE: INJPAL  filename.256 [doompath\iwadname.wad]');
		writeln;
		writeln('where filename is the name of a valid SNAPSHOT output file.');
		halt(1);
	end;
	assign(f,paramstr(1));
	reset(f,1);
	if FileSize(F) <> 64768 then begin
		writeln;
		close(f);
		writeln('Invalid file length: ',ParamStr(1));
		halt(1);
	end;
	writeln;
	writeln('PostProcessing: ',ParamStr(1));
   if paramcount = 2 then
   	dname:=paramstr(2)
   else
   	dname:='DOOM2.WAD';
	WDir:=New(PWadDirectory, Init(dname));
	PalPos:=WDir^.FindObject('PLAYPAL ');
	seek(WDir^.WadFile, WDir^.DirEntry^[PalPos].ObjStart);
	BlockRead(WDir^.WadFile, PalBuff, 768);
	BlockWrite(f, PalBuff, 768);
	close(f);
	Dispose(WDir, Done);
end.
