uses VirtScrn,crt,Wads,WadDecl,Things,Timer,WadThing;

var	Scrn:PVirtualScreen;
		c:char;
		WDir:PWadDirectory;
      WThing:PWadThing;
		WDec:array[1..4] of PThingDecoder;
		f:longint;
		t,tim:real;
		s1,s2,s3,s4:pointer;

begin
	TerminateOnWadError:=True;
	WDir:=New(PWadDirectory, Init('D:\GAMES\DOOM\DOOM.WAD'));
   WThing:=New(PWadThing, Init(WDir, 'TITLEPIC'));
	WDec[1]:=New(PThingDecoder, Init(WDir,'PLAYA1  '));
	WDec[2]:=New(PThingDecoder, Init(WDir,'PLAYB1  '));
	WDec[3]:=New(PThingDecoder, Init(WDir,'PLAYC1  '));
	WDec[4]:=New(PThingDecoder, Init(WDir,'PLAYD1  '));
	{readln;}
	InitVirtualScreens(2);
	InitVideoMode;
	WDir^.SetWadPalette(0);
	InitTimer;
	t:=0;
	f:=0;
	ClearTimer;
	repeat
		{VideoPage[1]^.Clear;}
		WThing^.VDraw(100,0,0,VideoPage[1]);
		WDec[1]^.Transfer(100,100,0,VideoPage[1]);
		VideoPage[1]^.Transfer;
		VideoPage[1]^.Activate;

		{VideoPage[2]^.Clear;}
		WThing^.VDraw(100,0,0,VideoPage[2]);
		WDec[2]^.Transfer(100,100,0,VideoPage[2]);
		VideoPage[2]^.Transfer;
		VideoPage[2]^.Activate;

		{VideoPage[1]^.Clear;}
		WThing^.VDraw(100,0,0,VideoPage[1]);
		WDec[3]^.Transfer(100,100,0,VideoPage[1]);
		VideoPage[1]^.Transfer;
		VideoPage[1]^.Activate;

		{VideoPage[2]^.Clear;}
		WThing^.VDraw(100,0,0,VideoPage[2]);
		WDec[4]^.Transfer(100,100,0,VideoPage[2]);
		VideoPage[2]^.Transfer;
		VideoPage[2]^.Activate;

		f:=f+4;
		if KeyPressed then
			c:=ReadKey;
	until c=#27;
	t:=timerticks;
	tim:=t / 18.2;
	DoneVideoMode;
	writeln('Frames: ',f,'  Time: ',tim:3:2);
	writeln('Frames per sec: ',(f / tim):3:2);
	readln;
	DoneVirtualScreens;
end.