uses DFEVIDEO,DOOMFONT,WAD,WADDECL,THINGS;

var WDir:PWadDirectory;
	 WThing:PWadThing;


begin
	InitFonts;
	WDir:=New(PWadDirectory, Init('D:\DOOM\DOOM.WAD'));
	InitVideo;
	WDir^.SetWadPalette(0);
	WThing:=New(PWadThing, Init(Wdir,'M_DOOM  '));
	WThing^.Draw(100,240,1);
	Dispose(WThing, Done);
	{WThing:=New(PWadThing, Init(Wdir,'WIMAP0  '));
	WThing^.Draw(100,1,200);
	Dispose(WThing, Done);}
	DrawFont(270,50,1,'DFE 4.00');
	DrawFont(190,65,1,'THE DOOM FRONT END');
	DrawFont(40,100,1,'This version of DFE is intended for use with IPX network competitions.');
	DrawFont(30,120,1,'It has been equiped with special features that are soley for multiplayer');
	DrawFont(95,130,1,'games being played on IPX based local area networks.');
	DrawFont(50,150,1,'It does not contain any support for serial or modem games.  Limited');
	DrawFont(26,160,1,'support for single player has been added for the sole purpose of testing');
	DrawFont(150,170,1,'PWADS prior to playing a multiplayer game.');
	DrawFont(170,390,1,'DFE is a product of jackson software');
	DrawFont(215,400,1,'Written by: Joshua Jackson');
	readln;
	DoneFonts;
	WDir^.RestorePalette;
	DoneVideo;
	Dispose(Wdir, Done);
end.