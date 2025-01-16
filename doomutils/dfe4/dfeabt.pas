uses DFEVIDEO,DOOMFONT,WAD,WADDECL,THINGS,CRT,Graph;

var	WDir:PWadDirectory;

Procedure WaitForKey;

	var	c:char;

	begin
		While KeyPressed do
			c:=ReadKey;
		c:=ReadKey;
	end;

Procedure Intro;

	var WThing1,WThing2:PWadThing;
		 t:integer;

	begin
		Writeln('Initializing.');
		writeln('   Loadinig font tables...');
		InitFonts;
		writeln('   Loading DOOM.WAD Directory...');
		writeln('   Loading Graphics...');
		WThing1:=New(PWadThing, Init(Wdir,'M_DOOM  '));
		WThing2:=New(PWadThing, Init(Wdir,'PLAYB1  '));
		WThing1^.Draw(100,255,1);
		WThing2^.Draw(100,210,1);
		WThing2^.Draw(100,385,1);
		Dispose(WThing1, Done);
		Dispose(WThing2, Done);
		WThing1:=New(PWadThing,Init(WDir,'STDISK  '));
		CenterFont(50,1,'DFE 4.00');
		CenterFont(65,1,'THE DOOM FRONT END');
		CenterFont(100,1,'WELCOME TO THE DOOM FRONT END!');
		CenterFont(120,1,'THIS PROGRAM PROVIDES A USER FIENDLY TEXT INTERFACE FOR SELECTING HUNDREDS');
		CenterFont(130,1,'OF DIFFERNENT POSSIBLE GAME COMBINATIONS.');
		CenterFont(150,1,'DFE SUPPORTS ALL GAMES TYPES, INCLUDING SINGLE PLAYER, MODEM, SERIAL AND IPX');
		CenterFont(160,1,'NETWORK. IT ALSO HAS BUILT IN SUPPORT FOR DOOM 1.4 AND ABOVE DEATHMATCH V2.0.');
		CenterFont(180,1,'OTHER FEATURES INCLUDE BUILT IN MAP VIEWING, LINEDEF TAG ASSOCIATING, ITEM');
		CenterFont(190,1,'LOCATING, STATISTICS COLLECTION, SOUND PLAYING, SPRITE VIEWING FEATURES, EXE');
		CenterFont(200,1,'HACKING - V1.2 ONLY, AND PWAD COMPILING.');
		CenterFont(220,1,'IF YOU ARE USING AN IPX BASED NETWORK, YOU CAN ALSO USE THE IPXFER OPTION');
		CenterFont(230,1,'TO QUICKLY TRANSFER FILES BETWEEN TWO MACHINES.');
		CenterFont(450,1,'DFE IS A PRODUCT OF JACKSON SOFTWARE');
		CenterFont(460,1,'AUTHOR: JOSHUA JACKSON');
		SetFillStyle(SolidFill,0);
		for t:=1 to 10 do begin
			CenterFont(300,2,'INITIALIZING...');
			WThing1^.Draw(100,210,300);
			delay(50);
			Bar(100,300,500,330);
			WThing1^.Draw(100,210,300);
			delay(50);
		end;
		Bar(100,300,500,330);
		Dispose(WThing1,Done);
		CenterFont(300,2,'PRESS ANY KEY TO CONTINUE...');
		WaitForKey;
		Bar(0,100,639,390);
	end;

Procedure Setup;

	var	WThing:PWadThing;

	begin
		CenterFont(100,2,'SELECT YOUR GAME TYPE:');
		DrawFont(150,160,2,'COOPERATIVE');
		WThing:=New(PWadThing, Init(Wdir, 'STFST01 '));
		WThing^.Draw(100,100,150);
		Dispose(WThing, Done);
		DrawFont(150,210,2,'DEATHMATCH');
		WThing:=New(PWadThing, Init(Wdir, 'STFKILL0'));
		WThing^.Draw(100,100,200);
		Dispose(WThing, Done);
		WaitForKey;
	end;

begin
	if Test8086 < 2 then begin
		writeln('You may wish to get yourself a REAL computer!');
		writeln;
		writeln('DOOM requires at least an 80386!! (and so does DFE :)');
		writeln;
		halt(1);
	end;
	WDir:=New(PWadDirectory, Init('D:\DOOM\DOOM.WAD'));
	InitVideo;
	WDir^.SetWadPalette(0);
	Intro;
	Setup;
	DoneFonts;
	WDir^.RestorePalette;
	DoneVideo;
	Dispose(Wdir, Done);
end.