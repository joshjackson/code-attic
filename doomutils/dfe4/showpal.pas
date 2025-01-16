uses Wad,Graph,SpriteView,DOOMGui,GUIObj,GUIEvent,ThingDef;

var WDir:PWadDirectory;
	 gd,gm:integer;
	 TempStr:string;
	 SpView:PSpriteViewer;

Procedure SVGA256DriverProc; external;
{$L SVGA256}

function DetectVGA256 : Integer;

	begin
		DetectVGA256:=2;
	end;

begin
	InitThingDefs;
	WDir:=New(PWadDirectory, Init('C:\DOOM\DOOM.WAD'));
	gd:=InstallUserDriver('svga256',@DetectVGA256);
	if RegisterBGIDriver(@SVGA256DriverProc) < 0 then begin
		writeln('MapView_InitVideo: ',GraphErrorMsg(GraphResult));
		halt;
	end;
	gm:=2;
	InitGraph(gd,gm,'');
	WDir^.SetWadPalette(0);
	SpView:=New(PSpriteViewer, Init(3007, WDir));
	SpView^.Draw;
	readln;
	SpView^.Done;
	WDir^.RestorePalette;
	WDir^.Done;
	Dispose(WDir);
	DoneThingDefs;
	CloseGraph;
end.
