{$F+,O+}
unit MapStats;

interface

uses Wad,WadDecl;

Procedure DisplayMapStatistics(WDir:PWadDirectory;LevelName:String);

implementation

uses Objects,Views,App,Dialogs,Crt;

var	Monsters:array[1..10] of word;
		Weapons:array[1..6] of word;
		Secrets:word;
		DMatch:word;
		CoOps:array[1..4] of word;
		Keys:array[1..3] of word;
		Dialog1:PDialog;
		Things:PThingList;
		ListSize:word;
		t,Thing:word;
		R:TRect;
		Level:ObjNameStr;

Function ValStr(w:word):string;

	var s:string;

	begin
		Str(w, s);
		ValStr:=s;
	end;

Procedure DisplayMapStatistics(WDir:PWadDirectory;LevelName:String);

	begin
		for t:=1 to 8 do
			Level[t]:=LevelName[t];
		for t:=1 to 10 do
			Monsters[t]:=0;
		for t:=1 to 3 do
			Keys[t]:=0;
		for t:=1 to 6 do
			Weapons[t]:=0;
		for t:=1 to 4 do
			CoOps[t]:=0;
		DMatch:=0;
		with WDir^ do begin
			Thing:=FindObject(Level);
			if Thing=0 then begin
				TextMode(co80);
				writeln('MapStat_init: Error in WAD directory: ',LevelName);
				halt(1);
			end;
			Inc(Thing);
			ListSize:=DirEntry^[Thing].ObjLength;
			GetMem(Things, ListSize);
			Seek(WadFile, DirEntry^[Thing].ObjStart);
			BlockRead(WadFile, Things^, ListSize);
		end;
		for t:=0 to (ListSize div Sizeof(TThing)) do begin
			Thing:=Things^[t].ThingType;
			Case Thing of
				1:Inc(CoOps[1]); {Player 1 start}
				2:Inc(CoOps[2]); {Player 2 start}
				3:Inc(CoOps[3]); {Player 3 start}
				4:Inc(CoOps[4]); {Player 4 start}
				11:Inc(DMatch); {DeathMatch Start}
				3001:Inc(Monsters[3]); {IMP}
				3002:Inc(Monsters[4]); {DEMON}
				3003:Inc(Monsters[6]); {BARON OF HELL}
				3004:Inc(Monsters[1]); {FORMER HUMAN}
				3005:Inc(Monsters[8]); {CACODEMON}
				3006:Inc(Monsters[7]); {LOST SOUL}
				16:Inc(Monsters[9]); {CYBER-DEMON}
				9:Inc(Monsters[2]); {FORMER HUMAN SERGEANT}
				7:Inc(Monsters[10]); {Spider Demon}
				58:Inc(Monsters[5]); {Spectre}
				2005:Inc(Weapons[1]); {Chainsaw}
				2001:Inc(Weapons[2]); {Shotgun}
				2002:Inc(Weapons[3]); {Chaingun}
				2003:Inc(Weapons[4]); {Rocket launcher}
				2004:Inc(Weapons[5]); {Plasma gun}
				2006:Inc(Weapons[6]); {BFG9000}
			end;
		end;
		R.Assign(9,2,71,21);
		LevelName[0]:=#4;
		Dialog1:=New(PDialog, Init(R, 'Map Statistics: '+LevelName));
		with Dialog1^ do begin
			R.Assign(3,2,30,3);
			Insert(New(PstaticText, Init(R, 'Player 1:   '+ValStr(CoOps[1]))));
			R.Assign(3,3,30,4);
			Insert(New(PstaticText, Init(R, 'Player 2:   '+ValStr(CoOps[2]))));
			R.Assign(3,4,30,5);
			Insert(New(PstaticText, Init(R, 'Player 3:   '+ValStr(CoOps[3]))));
			R.Assign(3,5,30,6);
			Insert(New(PstaticText, Init(R, 'Player 4:   '+ValStr(CoOps[4]))));
			R.Assign(3,6,30,7);
			Insert(New(PstaticText, Init(R, 'DeathMatch: '+ValStr(DMatch))));
			R.Assign(3,8,30,9);
			Insert(New(PstaticText, Init(R, 'ChainSaws       : '+ValStr(Weapons[1]))));
			R.Assign(3,9,30,10);
			Insert(New(PstaticText, Init(R, 'Shotguns        : '+ValStr(Weapons[2]))));
			R.Assign(3,10,30,11);
			Insert(New(PstaticText, Init(R, 'Chainguns       : '+ValStr(Weapons[3]))));
			R.Assign(3,11,30,12);
			Insert(New(PstaticText, Init(R, 'Rocket Launchers: '+ValStr(Weapons[4]))));
			R.Assign(3,12,30,13);
			Insert(New(PstaticText, Init(R, 'Plasma Guns     : '+ValStr(Weapons[5]))));
			R.Assign(3,13,30,14);
			Insert(New(PstaticText, Init(R, 'BFG9000s        : '+ValStr(Weapons[6]))));
			R.Assign(31,2,60,3);
			Insert(New(PstaticText, Init(R, 'Former Humans   : '+ValStr(Monsters[1]))));
			R.Assign(31,3,60,4);
			Insert(New(PstaticText, Init(R, 'Former Sergeants: '+ValStr(Monsters[2]))));
			R.Assign(31,4,60,5);
			Insert(New(PstaticText, Init(R, 'Imps            : '+ValStr(Monsters[3]))));
			R.Assign(31,5,60,6);
			Insert(New(PstaticText, Init(R, 'Demons          : '+ValStr(Monsters[4]))));
			R.Assign(31,6,60,7);
			Insert(New(PstaticText, Init(R, 'Spectres        : '+ValStr(Monsters[5]))));
			R.Assign(31,7,60,8);
			Insert(New(PstaticText, Init(R, 'Barons          : '+ValStr(Monsters[6]))));
			R.Assign(31,8,60,9);
			Insert(New(PstaticText, Init(R, 'Lost Souls      : '+ValStr(Monsters[7]))));
			R.Assign(31,9,60,10);
			Insert(New(PstaticText, Init(R, 'Cacodemons      : '+ValStr(Monsters[8]))));
			R.Assign(31,10,60,11);
			Insert(New(PstaticText, Init(R, 'Cyberdemons     : '+ValStr(Monsters[9]))));
			R.Assign(31,11,60,12);
			Insert(New(PstaticText, Init(R, 'Spiderdemons    : '+ValStr(Monsters[10]))));
			R.Assign(26,16,36,18);
			Insert(New(PButton, Init(R,'~O~k',cmOk,bfDefault)));
		end;
		Desktop^.ExecView(Dialog1);
		Dispose(Dialog1,Done);
		FreeMem(Things, ListSize);
	end;

end.