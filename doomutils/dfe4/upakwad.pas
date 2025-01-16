uses Wad,Crt,SuperIO;

var	WDir:PwadDirectory;
		Path,SearchName:string;
		t,x:word;

begin
	CLRSCR;

	writeln('Initializing Wad File Directory...');
	WDir:=New(PWadDirectory, Init('D:\DOOM\XXXDOOM.WAD'));

	writeln('Breaking Down Wad File Directory...');
	for t:=1 to WDir^.DirEntries do begin
		if WDir^.DirEntry^[t].ObjLength=0 then begin
			SearchName:=WDir^.DirEntry^[t].ObjName;
			if Rtrim(SearchName)='' then continue;
			if Pos('_START', SearchName)<>0 then begin
				Path:=Path+'\'+Rtrim(SearchName);
				writeln(Path);
			 end
			else if Pos('_END', SearchName)<>0 then begin
				for x:=Length(Path) downto 1 do begin
					if Path[x]='\' then begin
						Path:=Left(Path, x - 1);
						Break;
					end;
				end;
			 end
			else begin
				Path:='D:\'+RTrim(WDir^.DirEntry^[t].ObjName);  {Must Be A Level}
				writeln(Path);
				for x:=1 to 10 do										 {10 Entries/Level}
					writeln(Path+'\'+WDir^.DirEntry^[t+x].ObjName);
				Path:='D:';
				t:=t+10;
			end;
		 end
		else
			writeln(Path+'\'+WDir^.DirEntry^[t].ObjName);
	end;
	writeln('Disposing of Wad Directory...');
	Dispose(WDir, Done);
end.
