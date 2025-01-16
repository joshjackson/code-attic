{$F-}
uses Crt,Wad,WadDecl,Things;

var	x,y:integer;
		WDir:PWadDirectory;
		WThing:array[1..5] of PWadThing;
		c:char;

begin
	WDir:=New(PWadDirectory, Init('D:\DOOM\DOOM.WAD'));
	WThing[1]:=New(PWadThing, Init(WDir,'PLAYA1  '));
	WThing[2]:=New(PWadThing, Init(WDir,'PLAYB1  '));
	WThing[3]:=New(PWadThing, Init(WDir,'PLAYC1  '));
	WThing[4]:=New(PWadThing, Init(WDir,'PLAYD1  '));
	SetVideoMode;
	WDir^.SetWadPalette(0);
	WThing[1]^.VDraw(100,1,1,0,0);
	WThing[2]^.VDraw(100,1,1,1,0);
	Repeat
		ShowVideoPage(0);
		c:=ReadKey;
		ShowVideoPage(1);
		c:=ReadKey;
	until c=#27;
	WDir^.RestorePalette;
	TextMode(co80);
end.