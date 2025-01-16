Unit GroupPWads;

interface

uses Wad,WadDecl,PWadComp,PWCDECL,crt;

Procedure BuildCompoundPWad(PWL:PWadCollection);

implementation

var	MainDir:PWadDirectory;
		CurPWad:PPWadEntry;
		Compiler:PPWadDef;
		PWadList:PWadCollection;

Function IsLevelName(N:ObjNameStr):boolean;

	begin
		if (N[1]='E') and (N[3]='M') and ((N[5]=' ') or (N[5]=#00)) then
			IsLevelName:=True
		else
			IsLevelName:=False;
	end;

Procedure AddEntry(EName:ObjNameStr);

	var	t,e:word;

	begin
		for t:=1 to 8 do
			if EName[t]=' ' then EName[t]:=#00;
		if Compiler^.FindObject(EName) > 0 then
			Exit;
		{for t:=(PWadList^.Count - 1) downto 0 do begin}
		for t:=0 to (PWadList^.Count - 1) do begin
			CurPWad:=PWadList^.At(t);
			e:=CurPWad^.Dir^.FindObject(EName);
			if e > 0 then begin
				Compiler^.AddEntry(CurPWad^.Dir,e,EName);
				exit;
			end;
		end;
	end;

Procedure AddLevels;

	var	e,m:word;
			p,t,r:word;
			ts:string[3];
			tn:ObjNameStr;

	begin
		for t:=(PWadList^.Count - 1) downto 0 do begin
			CurPWad:=PWadList^.At(t);
			tn:='E M     ';
			for e:=1 to 3 do begin
				for m:=1 to 9 do begin
					Str(e,ts);
					tn[2]:=ts[1];
					str(m,ts);
					tn[4]:=ts[1];
					if Compiler^.FindObject(tn) > 0 then
						Continue;
					p:=CurPWad^.Dir^.FindObject(tn);
					if p > 0 then
						for r:=p to p+10 do
							Compiler^.AddEntry(CurPWad^.Dir,r,CurPWad^.Dir^.DirEntry^[r].ObjName);
				end;
			end;
		end;
	end;
{508 588-7718}
Procedure AddSongs;

	var 	t,e:word;

	begin
		for t:=(PWadList^.Count - 1) downto 0 do begin
			CurPWad:=PWadList^.At(t);
			with CurPWad^.Dir^ do begin
				for e:=1 to DirEntries do begin
					if (DirEntry^[e].ObjName[1] = 'D') and (DirEntry^[e].ObjName[2] = '_') then begin
						if Compiler^.FindObject(DirEntry^[e].ObjName) > 0 then
							Continue;
						Compiler^.AddEntry(CurPWad^.Dir,e,DirEntry^[e].ObjName);
					end;
				end;
			end;
		end;
	end;

Procedure AddSounds;

	var 	t,e:word;

	begin
		for t:=(PWadList^.Count - 1) downto 0 do begin
			CurPWad:=PWadList^.At(t);
			with CurPWad^.Dir^ do begin
				for e:=1 to DirEntries do begin
					if (DirEntry^[e].ObjName[1] = 'D') and ((DirEntry^[e].ObjName[2] = 'S')
					or (DirEntry^[e].ObjName[2] = 'P')) then begin
						if Compiler^.FindObject(DirEntry^[e].ObjName) > 0 then
							Continue;
						Compiler^.AddEntry(CurPWad^.Dir,e,DirEntry^[e].ObjName);
					end;
				end;
			end;
		end;
	end;

Procedure AddAmmun;

	var 	t,e,c:word;
			tn:ObjNameStr;
			IsAmm:Boolean;

	begin
		tn:='AMMNUM  ';
		for t:=(PWadList^.Count - 1) downto 0 do begin
			CurPWad:=PWadList^.At(t);
			with CurPWad^.Dir^ do begin
				for e:=1 to DirEntries do begin
					IsAmm:=True;
					for c:=1 to 6 do
						if DirEntry^[e].ObjName[c] <> tn[c] then begin
							IsAmm:=False;
							Break;
						end;
						if not IsAmm then Continue;
						if Compiler^.FindObject(DirEntry^[e].ObjName) > 0 then
							Continue;
						Compiler^.AddEntry(CurPWad^.Dir,e,DirEntry^[e].ObjName);
				end;
			end;
		end;
	end;

Procedure AddStBar;

	var 	t,e:word;

	begin
		for t:=(PWadList^.Count - 1) downto 0 do begin
			CurPWad:=PWadList^.At(t);
			with CurPWad^.Dir^ do begin
				for e:=1 to DirEntries do begin
					if (DirEntry^[e].ObjName[1] = 'S') and (DirEntry^[e].ObjName[2] = 'T') then begin
						if Compiler^.FindObject(DirEntry^[e].ObjName) > 0 then
							Continue;
						Compiler^.AddEntry(CurPWad^.Dir,e,DirEntry^[e].ObjName);
					end;
				end;
			end;
		end;
	end;

Procedure AddTextMsg;

	var 	t,e:word;

	begin
		for t:=(PWadList^.Count - 1) downto 0 do begin
			CurPWad:=PWadList^.At(t);
			with CurPWad^.Dir^ do begin
				for e:=1 to DirEntries do begin
					if (DirEntry^[e].ObjName[1] = 'M') and (DirEntry^[e].ObjName[2] = '_') then begin
						if Compiler^.FindObject(DirEntry^[e].ObjName) > 0 then
							Continue;
						Compiler^.AddEntry(CurPWad^.Dir,e,DirEntry^[e].ObjName);
					end;
				end;
			end;
		end;
	end;

Procedure AddSummaries;

	var 	t,e:word;

	begin
		for t:=(PWadList^.Count - 1) downto 0 do begin
			CurPWad:=PWadList^.At(t);
			with CurPWad^.Dir^ do begin
				for e:=1 to DirEntries do begin
					if (DirEntry^[e].ObjName[1] = 'W') and (DirEntry^[e].ObjName[2] = 'I') then begin
						if Compiler^.FindObject(DirEntry^[e].ObjName) > 0 then
							Continue;
						Compiler^.AddEntry(CurPWad^.Dir,e,DirEntry^[e].ObjName);
					end;
				end;
			end;
		end;
	end;

Procedure AddBorders;

	var 	t,e,c:word;
			tn:ObjNameStr;
			IsBrdr:boolean;

	begin
		tn:='BRDR_   ';
		for t:=(PWadList^.Count - 1) downto 0 do begin
			CurPWad:=PWadList^.At(t);
			with CurPWad^.Dir^ do begin
				for e:=1 to DirEntries do begin
					IsBrdr:=True;
					for c:=1 to 5 do
						if DirEntry^[e].ObjName[c] <> tn[c] then begin
							IsBrdr:=False;
							Break;
						end;
						if not IsBrdr then Continue;
						if Compiler^.FindObject(DirEntry^[e].ObjName) > 0 then
							Continue;
						Compiler^.AddEntry(CurPWad^.Dir,e,DirEntry^[e].ObjName);
				end;
			end;
		end;
	end;

Procedure AddSprites;

	var 	t,e,ss,se,x:word;
			HasSprites:Boolean;

	begin
		HasSprites:=False;
		for t:=(PWadList^.Count - 1) downto 0 do begin
			CurPWad:=PWadList^.At(t);
			e:=CurPWad^.Dir^.FindObject('S_START ');
			if e > 0 then begin
				HasSprites:=True;
				Compiler^.AddEntry(CurPWad^.Dir,e,'S_START ');
				Break;
			end;
		end;
		if not HasSprites then exit;
		for t:=(PWadList^.Count - 1) downto 0 do begin
			CurPWad:=PWadList^.At(t);
			with CurPWad^.Dir^ do begin
				ss:=FindObject('S_START ');
				if ss = 0 then	Continue;
				se:=FindObject('S_END   ');
				if se=0 then begin
					textmode(co80);
					writeln('AddSprites: PWAD is missing S_END');
					halt(1);
				end;
				for x:=(ss + 1) to (se - 1) do begin
					if Compiler^.FindObject(DirEntry^[x].ObjName)=0 then
						Compiler^.AddEntry(CurPWad^.Dir,x,DirEntry^[x].ObjName);
				end;
			end;
		end;
		Compiler^.AddEntry(CurPWad^.Dir,se,'S_END   ');
	end;

Procedure AddWallPtch;

	var 	t,e,ss,se,x:word;
			HasWalls:Boolean;

	begin
		HasWalls:=False;
		for t:=(PWadList^.Count - 1) downto 0 do begin
			CurPWad:=PWadList^.At(t);
			e:=CurPWad^.Dir^.FindObject('P_START ');
			if e > 0 then begin
				HasWalls:=True;
				Compiler^.AddEntry(CurPWad^.Dir,e,'P_START ');
				Break;
			end;
		end;
		if not HasWalls then exit;
		for t:=(PWadList^.Count - 1) downto 0 do begin
			CurPWad:=PWadList^.At(t);
			with CurPWad^.Dir^ do begin
				ss:=FindObject('P_START ');
				if ss = 0 then	Continue;
				se:=FindObject('P_END   ');
				if se=0 then begin
					textmode(co80);
					writeln('AddWallPtch: PWAD is missing P_END');
					halt(1);
				end;
				for x:=(ss + 1) to (se - 1) do begin
					if Compiler^.FindObject(DirEntry^[x].ObjName)=0 then
						Compiler^.AddEntry(CurPWad^.Dir,x,DirEntry^[x].ObjName);
				end;
			end;
		end;
		Compiler^.AddEntry(CurPWad^.Dir,se,'P_END   ');
	end;

Procedure AddFloors;

	var 	t,e,ss,se,x:word;
			HasFloors:Boolean;

	begin
		HasFloors:=False;
		for t:=(PWadList^.Count - 1) downto 0 do begin
			CurPWad:=PWadList^.At(t);
			e:=CurPWad^.Dir^.FindObject('F_START ');
			if e > 0 then begin
				HasFloors:=True;
				Compiler^.AddEntry(CurPWad^.Dir,e,'F_START ');
				Break;
			end;
		end;
		if not HasFloors then exit;
		for t:=(PWadList^.Count - 1) downto 0 do begin
			CurPWad:=PWadList^.At(t);
			with CurPWad^.Dir^ do begin
				ss:=FindObject('F_START ');
				if ss = 0 then	Continue;
				se:=FindObject('F_END   ');
				if se=0 then begin
					textmode(co80);
					writeln('AddFloors: PWAD is missing F_END');
					halt(1);
				end;
				for x:=(ss + 1) to (se - 1) do begin
					if Compiler^.FindObject(DirEntry^[x].ObjName)=0 then
						Compiler^.AddEntry(CurPWad^.Dir,x,DirEntry^[x].ObjName);
				end;
			end;
		end;
		Compiler^.AddEntry(CurPWad^.Dir,se,'F_END   ');
	end;

Procedure AddJunk;

	var 	t,e:word;

	begin
		for t:=(PWadList^.Count - 1) downto 0 do begin
			CurPWad:=PWadList^.At(t);
			with CurPWad^.Dir^ do begin
				for e:=1 to DirEntries do begin
					Gotoxy(70,1);
					write(t,' ',e);
					if Compiler^.FindObject(DirEntry^[e].ObjName) > 0 then
						Continue;
					Compiler^.AddEntry(CurPWad^.Dir,e,DirEntry^[e].ObjName);
				end;
			end;
		end;
	end;

Procedure BuildCompoundPWad(PWL:PWadCollection);

	var	t,e:word;

	begin
		PWadList:=PWL;
		{PMainDir:=New(PWadDirectory, Init('D:\DOOM\DOOM.WAD'));}
		Compiler:=New(PPWadDef, Init('DMTEMP.WAD'));
		AddEntry('PLAYPAL ');
		AddEntry('COLORMAP');
		AddEntry('ENDOOM  ');
		AddEntry('DEMO1   ');
		AddEntry('DEMO2   ');
		AddEntry('DEMO3   ');
		AddLevels;
		AddEntry('TEXTURE1');
		AddEntry('TEXTURE2');
		AddEntry('PNAMES  ');
		AddEntry('GENMIDI ');
		AddEntry('DMXGUS  ');
		AddSongs;
		AddSounds;
		AddEntry('HELP1   ');
		AddEntry('HELP2   ');
		AddEntry('CREDIT  ');
		AddEntry('VICTORY2');
		AddEntry('TITLEPIC');
		AddEntry('PFUB1   ');
		AddEntry('PFUB2   ');
		AddEntry('END0    ');
		AddEntry('END1    ');
		AddEntry('END2    ');
		AddEntry('END3    ');
		AddEntry('END4    ');
		AddEntry('END5    ');
		AddEntry('END6    ');
		AddAmmun;
		AddStBar;
		AddTextMsg;
		AddBorders;
		AddSummaries;
		AddSprites;
		AddWallPtch;
		AddFloors;
		AddJunk;
		Compiler^.Compile;
		Dispose(Compiler, Done);
	end;

end.