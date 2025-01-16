{****************************************************************************
*                      The DOOM Hacker's Tool Kit                           *
*****************************************************************************
* Unit: 	  MAPREAD                                                          *
* Purpose: Map Viewer unit for DOOM Front End (DFE)                         *
* Date:    4/28/94                                                          *
* Author:  Joshua Jackson        Internet: joshjackson@delphi.com           *
****************************************************************************}

{$O+,F+}
unit MAPREAD;

interface

uses 	Wad,WadDecl,Maps,Graph,Crt,Things,Dos,DOOMGui,Mouse,ThingDef,GUIObj,
		SpriteView,DFEVideo;

Procedure ViewMap(WadName:PathStr;LevelName:ObjNameStr;ViewerMask,ThingMask:word);

implementation

var	WDir:PWadDirectory;
		DoomDir:PWadDirectory;
		WMap:PWadMap;
		WMapViewer:PWadMapViewer;
		SpViewer:PSpriteViewer;

Procedure ViewMap(WadName:PathStr;LevelName:ObjNameStr;ViewerMask,ThingMask:word);

	var 	TempStr:string;
			ch:char;
			ScaleInc,XOfs,YOfs:word;
			t,MouseX,MouseY,MouseButtons:integer;
			x1,x2,y1,y2:word;
			ThingNum,ThingDefNum:word;
			SpriteID:ObjNameStr;
			Sprite:PWadThing;
			Buttons:PGraphGroup;
			MButton,GButton,WButton,PButton:PGraphButton;
			Lev1Button,Lev3Button,Lev5Button:PGraphButton;
			R:TGraphRect;
			ReDraw:boolean;

	begin
		TextAttr:=7;
		ClrScr;
		writeln('Map Viewer v2.01');
		writeln('By Jackson Software');
		writeln;
		delay(500);
		writeln('ThingDef_Init');
		InitThingDefs;
		TempStr:=LevelName+'        ';
		Move(TempStr[1],LevelName,8);
		writeln('WAD_Init:  Initializing WAD file...');
		WDir:=New(PWadDirectory, Init(WadName));
		TempStr:='DOOM'+#00;
		DOOMDir:=WDir;
		for t:=1 to 4 do begin
			If WDir^.WadName[t] <> TempStr[t] then begin
				if MaxAvail < 64000 then begin
					writeln('Insufficent Memory To Load DOOM.WAD Directory.');
					halt;
				end;
				writeln('WAD_Init:  Intializing Main WAD file...');
				DOOMDir:=New(PWadDirectory, Init('DOOM.WAD'));
				Break;
			end;
		end;
		writeln('WadMap_Init: Initializing WAD file Map...');
		WMap:=New(PWadMap, Init(WDir,LevelName));
		WMap^.ViewerMask:=ViewerMask;
		WMap^.ThingMask:=ThingMask;
		In256ColorMode:=True;
		ScaleInc:=1;
		XOfs:=0;
		YOfs:=0;
		R.Assign(1,1,15,15);
		MButton:=New(PGraphButton, Init(R,0,'M'));
		R.Assign(17,1,32,15);
		GButton:=New(PGraphButton, Init(R,0,'G'));
		R.Assign(34,1,49,15);
		WButton:=New(PGraphButton, Init(R,0,'W'));
		R.Assign(51,1,65,15);
		PButton:=New(PGraphButton, Init(R,0,'P'));
		R.Assign(68,1,93,15);
		Lev1Button:=New(PGraphButton, Init(R,0,'12'));
		R.Assign(95,1,120,15);
		Lev3Button:=New(PGraphButton, Init(R,0,'3'));
		R.Assign(122,1,147,15);
		Lev5Button:=New(PGraphButton, Init(R,0,'45'));
		if (ViewerMask and 1) = 1 then
			MButton^.IsPressed:=1;
		if (ViewerMask and 2) = 2 then
			GButton^.IsPressed:=1;
		if (ViewerMask and 4) = 4 then
			WButton^.IsPressed:=1;
		if (ViewerMask and 64) = 64 then
			PButton^.IsPressed:=1;
		if (ViewerMask and 8) = 8 then begin
			Lev3Button^.IsPressed:=0;
			Lev5Button^.IsPressed:=0;
			Lev1Button^.IsPressed:=1;
		 end
		else if (ViewerMask and 16) = 16 then begin
			Lev1Button^.IsPressed:=0;
			Lev5Button^.IsPressed:=0;
			Lev3Button^.IsPressed:=1;
		 end
		else if (ViewerMask and 32) = 32 then begin
			Lev1Button^.IsPressed:=0;
			Lev3Button^.IsPressed:=0;
			Lev5Button^.IsPressed:=1;
		end;
		R.Assign(1,1,640,480);
		writeln('MapView_Init');
		WMapViewer:=New(PWadMapViewer, Init(R));
		WMapViewer^.Insert(WMap);
		WMapViewer^.Insert(MButton);
		WMapViewer^.Insert(GButton);
		WMapViewer^.Insert(WButton);
		WMapViewer^.Insert(PButton);
		WMapViewer^.Insert(Lev1Button);
		WMapViewer^.Insert(Lev3Button);
		WMapViewer^.Insert(Lev5Button);
		ReDraw:=True;
		writeln('MapVideo_Init');
		InitVideo;
		if not In256ColorMode then begin
			Dispose(WMapViewer,Done);
			if DOOMDir <> WDir then
				Dispose(DOOMDir,Done);
			Dispose(WDir,Done);
			DoneThingDefs;
			DoneVideo;
         exit;
      end;
		InitMouse;
		ShowMousePointer;
		if In256ColorMode then
			DOOMDir^.SetWadPalette(0);
		repeat
			if ReDraw then begin
				WMap^.ViewerMask:=ViewerMask;
				HideMousePointer;
				ClearDevice;
				WMapViewer^.Draw;
				ShowMousePointer;
			end;
			ReDraw:=True;
			ch:='~';
			if UseMouse then begin
				GetMouseCoords(MouseX,MouseY,MouseButtons);
				str(MouseX,Tempstr);
				if FakeCursor then
					DrawFakeCursor(MouseX,MouseY);
				if (MouseButtons and 1)=1 then begin
					if MButton^.InButton(MouseX,MouseY) then
						ch:='M'
					else if GButton^.InButton(MouseX,MouseY) then
						ch:='G'
					else if WButton^.InButton(MouseX,MouseY) then
						ch:='W'
					else if PButton^.InButton(MouseX,MouseY) then
						ch:='P'
					else if Lev1Button^.InButton(MouseX,MouseY) then
						ch:='1'
					else if Lev3Button^.InButton(MouseX,MouseY) then
						ch:='3'
					else if Lev5Button^.InButton(MouseX,MouseY) then
						ch:='5'
					else begin
						x1:=MouseX - WMap^.ScaleInc;
						x2:=MouseX + WMap^.ScaleInc;
						y1:=Mousey - WMap^.ScaleInc;
						y2:=Mousey + WMap^.ScaleInc;
						ThingNum:=WMap^.GetThingInArea(x1,y1,x2,y2);
						if ThingNum <> 0 then begin
							HideMousePointer;
							SpViewer:=New(PSpriteViewer, Init(ThingNum, DOOMDir));
							if In256ColorMode then begin
								SpViewer^.Draw;
							 end
							else begin
								SetColor(15);
								OutTextXy(335,450,'Sprite View Disabled...');
								OutTextXY(335,465,'System is in 16 Color Mode.');
							end;
							SpViewer^.Done;
							Dispose(SpViewer);
							ShowMousePointer;
						end;
					end;
				end;
			end;
			if KeyPressed then begin
				ch:=ReadKey;
				ch:=UpCase(ch);
			end;
			case ch of
				'+':if WMap^.ScaleInc < 10 then
						Inc(WMap^.ScaleInc);
				'-':if WMap^.ScaleInc > 1 then
						Dec(WMap^.ScaleInc);
				'S':ViewerMask:=ViewerMask xor 128;
				'M':Begin
						ViewerMask:=ViewerMask xor 1;
						MButton^.IsPressed:=MButton^.IsPressed xor 1;
					 end;
				'G':Begin
						ViewerMask:=ViewerMask xor 2;
						GButton^.IsPressed:=GButton^.IsPressed xor 1;
					 end;
				'W':Begin
						ViewerMask:=ViewerMask xor 4;
						WButton^.IsPressed:=WButton^.IsPressed xor 1;
					 end;
				'P':Begin
						ViewerMask:=ViewerMask xor 64;
						PButton^.IsPressed:=PButton^.IsPressed xor 1;
					 end;
				'1','2':begin
								ViewerMask:=(ViewerMask and 199) or 8;
								Lev3Button^.IsPressed:=0;
								Lev5Button^.IsPressed:=0;
								Lev1Button^.IsPressed:=1;
							end;
				'3':begin
						ViewerMask:=(ViewerMask and 199) or 16;
						Lev1Button^.IsPressed:=0;
						Lev5Button^.IsPressed:=0;
						Lev3Button^.IsPressed:=1;
					end;
				'4','5':begin
								ViewerMask:=(ViewerMask and 199) or 32;
								Lev1Button^.IsPressed:=0;
								Lev3Button^.IsPressed:=0;
								Lev5Button^.IsPressed:=1;
							end;
				#0:begin
						ch:=ReadKey;
						case ch of
							'H':WMap^.YOffset:=WMap^.YOffset+10;
							'K':WMap^.XOffset:=WMap^.XOffset+10;
							'P':WMap^.YOffset:=WMap^.YOffset-10;
							'M':WMap^.XOffset:=WMap^.XOffset-10;
							'G':WMap^.SetScale(1,0,0);
						end;
					end;
				else
					ReDraw:=False;
			end;
		until ch=#27;
		DoneMouse;
		ClearDevice;
		if In256ColorMode then
			DOOMDir^.RestorePalette;
		DoneVideo;
		Dispose(WMapViewer,Done);
		if DOOMDir <> WDir then
			Dispose(DOOMDir,Done);
		Dispose(WDir,Done);
		DoneThingDefs;
	end;

end.
