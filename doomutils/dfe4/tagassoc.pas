{$F+,O+}
unit TagAssoc;

interface

uses 	Wad,WadDecl,Maps,Graph,Crt,Dos,DOOMGui,Mouse,GUIObj,DFEVideo,MapStats;

Procedure ShowTagAssociations(WadName:PathStr;LevelName:ObjNameStr);

implementation

const	taLineDef=1;
		taSector	=2;

var	WDir:PWadDirectory;
		DoomDir:PWadDirectory;
		WMap:PWadMap;
		WMapViewer:PWadMapViewer;

Procedure ShowTagAssociations(WadName:PathStr;LevelName:ObjNameStr);

	var 	TempStr:string;
			ch:char;
			t,MouseX,MouseY,MouseButtons:integer;
			x1,x2,y1,y2:word;
			CurrentMode:byte;
			CurrentLineDef,OldLineDef:Integer;
			CurrentSector,OldSector:integer;
			ModeButton:PGraphButton;
			R:TGraphRect;

	Procedure HilightSector(S:word);

		var 	SD1,SD2:TSideDef;
				SDP1,SDP2:Longint;
				t:integer;
				TagNum:integer;

		begin
			HideMousePointer;
			with WMap^ do begin
				if OldSector >=0 then begin
					TagNum:=SectorList^[OldSector].Tag;
					for t:=0 to NumLines do begin
						SDP2:=LineDefList^[t].LeftSideDef;
						SDP1:=LineDefList^[t].RightSideDef;
						if ((SDP1 >= 0) and (SideDefList^[SDP1]^.Sector = OldSector)) or
							((SDP2 >= 0) and (SideDefList^[SDP2]^.Sector = OldSector)) then
								DrawLineDef(t,-1);
						if (LineDefList^[t].Tag=TagNum) and (TagNum > 0) then
							DrawLineDef(t,-1);
					end;
				end;
				TagNum:=SectorList^[CurrentSector].Tag;
				for t:=0 to NumLines do begin
					SDP2:=LineDefList^[t].LeftSideDef;
					SDP1:=LineDefList^[t].RightSideDef;
					if ((SDP1 >= 0) and (SideDefList^[SDP1]^.Sector = s)) or
						((SDP2 >= 0) and (SideDefList^[SDP2]^.Sector = s)) then
							DrawLineDef(t, wcRed);
					if (LineDefList^[t].Tag=TagNum) and (TagNum > 0) then
						DrawLineDef(t,wcYellow);
				end;
			end;
			ShowMousePointer;
		end;

	Procedure HiLightLineDef(l:integer);

		var 	t:integer;
				tag:integer;
				SD:integer;

		begin
			HideMousePointer;
			with WMap^ do begin
				if OldLineDef >=0 then begin
					for t:=0 to NumLines do begin
						SD:=LineDefList^[t].RightSideDef;
						if SD < 0 then
							Tag:=0
						else
							Tag:=SectorList^[SideDefList^[SD]^.Sector].Tag;
						if (Tag > 0) and (Tag=LineDefList^[OldLineDef].Tag) then
							DrawLineDef(t, -1)
						else begin
							SD:=LineDefList^[t].LeftSideDef;
							if SD < 0 then
								Tag:=0
							else
								Tag:=SectorList^[SideDefList^[SD]^.Sector].Tag;
							if (Tag > 0) and (Tag=LineDefList^[OldLineDef].Tag) then
								DrawLineDef(t, -1)
						end;
					end;
					DrawLineDef(OldLineDef, -1);
				end;
				for t:=0 to NumLines do begin
					SD:=LineDefList^[t].RightSideDef;
					if SD < 0 then
						Tag:=0
					else
						Tag:=SectorList^[SideDefList^[SD]^.Sector].Tag;
					Tag:=SectorList^[SideDefList^[LineDefList^[t].RightSideDef]^.Sector].Tag;
					if (Tag > 0) and (Tag=LineDefList^[l].Tag) then
						DrawLineDef(t, wcYellow)
					else begin
						SD:=LineDefList^[t].LeftSideDef;
						if SD < 0 then
							Tag:=0
						else
							Tag:=SectorList^[SideDefList^[SD]^.Sector].Tag;
						if (Tag > 0) and (Tag=LineDefList^[l].Tag) then
							DrawLineDef(t, wcYellow)
					end;
				end;
				DrawLineDef(l, wcRed);
			end;
			ShowMousePointer;
		end;

	Function ButtonPress(AButton:PGraphButton):Boolean;

		begin
			HideMousePointer;
			AButton^.Press;
			ShowMousePointer;
			DrawFakeCursor(MouseX,MouseY);
			while (MouseButtons and 1)=1 do begin
				GetMouseCoords(MouseX,MouseY,MouseButtons);
				if not AButton^.InButton(MouseX,MouseY) then begin
					AButton^.Release;
						DrawFakeCursor(MouseX,MouseY);
				 end
				else begin
					HideMousePointer;
					AButton^.Press;
					ShowMousePointer;
						DrawFakeCursor(MouseX,MouseY);
				end;
			end;
			if AButton^.IsPressed=1 then
				ButtonPress:=True
			else
				ButtonPress:=False;
		end;

	begin
		TextAttr:=7;
		ClrScr;
		writeln('LineDef Tag Associator v1.00');
		writeln('By Jackson Software');
		writeln;
		delay(500);
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
		WMap^.ViewerMask:=504;
		WMap^.ThingMask:=0;
		writeln('MapView_Init');
		R.Assign(1,1,60,15);
		ModeButton:=New(PGraphButton, Init(R,0,'Mode'));
		R.Assign(1,1,640,480);
		WMapViewer:=New(PWadMapViewer, Init(R));
		WMapViewer^.Insert(WMap);
		WMapViewer^.Insert(ModeButton);
		writeln('Video_Init');
		InitVideo;
		if not In256ColorMode then begin
			Dispose(WMapViewer,Done);
			if DOOMDir <> WDir then
				Dispose(DOOMDir,Done);
			Dispose(WDir,Done);
			DoneVideo;
			exit;
		end;
		if In256ColorMode then
			DOOMDir^.SetWadPalette(0);
		FakeCursor:=True;
		InitMouse;
		WMap^.ScaleInc:=1;
		CurrentMode:=taSector;
		OldLineDef:=-1;
		OldSector:=-1;
		ClearDevice;
		WMapViewer^.Draw;
		ShowMousePointer;
		SetColor(wcGreen);
		SetTextStyle(0,0,1);
		OutTextXY(2,30,'Mode: Sector');
		repeat
			ch:='~';
			if UseMouse then begin
				GetMouseCoords(MouseX,MouseY,MouseButtons);
				DrawFakeCursor(MouseX,MouseY);
				if (MouseButtons and 1) = 1 then begin
					if ModeButton^.InButton(MouseX, MouseY) then begin
						if ButtonPress(ModeButton) then begin
							ModeButton^.IsPressed:=0;
							if CurrentMode=taLineDef then begin
								CurrentMode:=taSector;
								OldSector:=-1;
								TempStr:='Sector'
							 end
							else begin
								CurrentMode:=taLineDef;
								OldLineDef:=-1;
								TempStr:='LineDef';
							end;
							HideMousePointer;
							ClearDevice;
							WMapViewer^.Draw;
							ShowMousePointer;
							SetColor(wcGreen);
							SetTextStyle(0,0,1);
							OutTextXY(2,30,'Mode: '+TempStr);
						end;
					end;
				end;
				x1:=MouseX;
				x2:=MouseX + 2;
				y1:=MouseY;
				y2:=MouseY + 2;
				if CurrentMode=taSector then begin
					CurrentSector:=WMap^.GetSectorInArea(x1,y1,x2,y2);
					if (CurrentSector <> OldSector) and (CurrentSector >= 0) then begin
	{					if WMap^.SectorList^[CurrentSector].Tag > 0 then begin}
							HilightSector(CurrentSector);
							OldSector:=CurrentSector;
							Sound(50);
							delay(10);
							NoSound;
	{					 end
						else CurrentSector:=OldSector;}
					end;
				 end
				else begin
					CurrentLineDef:=WMap^.GetLineDefInArea(x1,y1,x2,y1);
					UpdateFakeCursor;
					if (CurrentLineDef <> OldLineDef) and (CurrentLineDef >=0) then begin
						HiLightLineDef(CurrentLineDef);
						OldLineDef:=CurrentLineDef;
						Sound(50);
						delay(10);
						NoSound;
					end;
				end;
			end;
			if KeyPressed then
				ch:=ReadKey;
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
	end;

end.
