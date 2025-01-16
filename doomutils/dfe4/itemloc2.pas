{$F+,O+}
unit ItemLoc2;

interface

uses 	Wad,WadDecl,Maps,Graph,Crt,Things,Dos,DOOMGui,Mouse,ThingDef,GUIObj,
		SpriteView,DFEVideo;

Procedure FindItem(WadName:PathStr;LevelName:ObjNameStr;ThingMask:word);

implementation

var	WDir:PWadDirectory;
		DoomDir:PWadDirectory;
		WMap:PWadMap;
		WMapViewer:PWadMapViewer;
		SpViewer:PSpriteViewer;
		CurrentThing:word;

Procedure WhereIs(ThingNum:word;var Sequence:word;var x,y:integer);

	var	t:integer;
			TT:Word;

	begin
		with WMap^ do begin
			for t:=Sequence to WMap^.NumThings do begin
				TT:=ThingList^[t].ThingType;
				if TT=ThingNum then begin
					x:=(((ThingList^[t].x-MidX) * IntScale div 65536)+320);
					y:=(((ThingList^[t].y-MidY) * (-IntScale) div 65536)+240);
					Sequence:=t+1;
					exit;
				end;
			end;
		end;
		x:=-1;
		y:=-1;
	end;

Procedure WhatNumberIs(var Sequence:word;x,y:integer);

	var 	x1,y1,x2,y2,t,TT:word;

	begin
		x1:=x-1;
		y1:=y-1;
		x2:=x+1;
		y2:=y+1;
		WMap^.GetThingInArea(x1,y1,x2,y2);
		with WMap^ do begin
			for t:=0 to WMap^.NumThings do begin
				TT:=ThingList^[t].ThingType;
				x:=(((ThingList^[t].x-MidX) * IntScale div 65536)+320);
				y:=(((ThingList^[t].y-MidY) * (-IntScale) div 65536)+240);
				if (x=x1) and (y=y1) then begin
					Sequence:=t+1;
					exit;
				 end
			end;
		end;
	end;

Procedure FindItem(WadName:PathStr;LevelName:ObjNameStr;ThingMask:word);

	var 	TempStr:string;
			ch:char;
			ScaleInc,XOfs,YOfs:word;
			t,MouseX,MouseY,MouseButtons:integer;
			x1,x2,y1,y2:word;
			d:integer;
			ThingNum,ThingDefNum:word;
			SpriteID:ObjNameStr;
			Sprite:PWadThing;
			NextButton:PGraphButton;
			R:TGraphRect;
			ReDraw:boolean;

	Procedure HilightItem;

		var 	x,y:integer;
				WT:TThing;
				TempStr:string;

		begin
			with WMap^ do begin
				WT:=ThingList^[CurrentThing - 1];
				x:=(((WT.x-MidX) * IntScale div 65536)+320);
				y:=(((WT.y-MidY) * (-IntScale) div 65536)+240);
			end;
			SetColor(wcRed);
			Line(x-5,y-5,x+5,y-5);
			line(x+5,y-5,x+5,y+5);
			Line(x+5,y+5,x-5,y+5);
			Line(x-5,y+5,x-5,y-5);
			TempStr:='Levels ';
			with WT do begin
				if (Attributes and 1) = 1 then
					TempStr:=TempStr+'1 2 ';
				if (Attributes and 2) = 2 then
					TempStr:=TempStr+'3 ';
				if (Attributes and 4) = 4 then
					TempStr:=TempStr+'4 5 ';
				if (Attributes and 16) = 16 then
					TempStr:=TempStr+'MultiPlayer';
			end;
			OutTextXY(1,25,TempStr);
		end;

	Function ButtonPress(AButton:PGraphButton):Boolean;

		begin
			HideMousePointer;
			AButton^.Press;
			ShowMousePointer;
			DrawFakeCursor(MouseX,MouseY);
			while (MouseButtons and 1)=1 do begin
				GetMouseCoords(MouseX,MouseY,MouseButtons);
				if not NextButton^.InButton(MouseX,MouseY) then begin
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
		writeln('Item Locator v1.00');
		writeln('By Jackson Software');
		writeln;
		delay(500);
		writeln('ThingDef_Init');
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
		WMap^.ViewerMask:=248;
		WMap^.ThingMask:=ThingMask;
		CurrentThing:=0;
		WhereIs(ThingMask, CurrentThing, d, d);
		if d=-1 then begin
			writeln;
			writeln('=========================ERROR===========================');
			writeln('Level ',LevelName,' does not contain the specified object');
			writeln;
			writeln('               Press Enter to Continue');
			writeln('=========================================================');
			readln;
			if DOOMDir <> WDir then
				Dispose(DOOMDir,Done);
			Dispose(WDir,Done);
			Dispose(WMap, Done);
			exit;
		end;
		writeln('MapView_Init');
		R.Assign(1,1,60,15);
		NextButton:=New(PGraphButton, Init(R,0,'Next'));
		R.Assign(1,1,640,480);
		WMapViewer:=New(PWadMapViewer, Init(R));
		WMapViewer^.Insert(WMap);
		WMapViewer^.Insert(NextButton);
		writeln('Video_Init');
		ReDraw:=True;
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
		ShowMousePointer;
		repeat
			if ReDraw then begin
				HideMousePointer;
				ClearDevice;
				WMapViewer^.Draw;
				HiLightItem;
				ShowMousePointer;
			end;
			ReDraw:=False;
			ch:='~';
			if UseMouse then begin
				GetMouseCoords(MouseX,MouseY,MouseButtons);
				str(MouseX,Tempstr);
				DrawFakeCursor(MouseX,MouseY);
				if (MouseButtons and 1)=1 then begin
					if NextButton^.InButton(MouseX,MouseY) then begin
						if ButtonPress(NextButton) then begin
							NextButton^.IsPressed:=0;
							WhereIs(ThingMask, CurrentThing, d, d);
							if d < 0 then begin
								CurrentThing:=0;
								WhereIs(ThingMask, CurrentThing, d, d);
							end;
							Redraw:=True;
						end;
					 end
					else begin
						x1:=MouseX - WMap^.ScaleInc;
						x2:=MouseX + WMap^.ScaleInc;
						y1:=Mousey - WMap^.ScaleInc;
						y2:=Mousey + WMap^.ScaleInc;
						ThingNum:=WMap^.GetThingInArea(x1,y1,x2,y2);
						if ThingNum <> 0 then begin
							WhatNumberIs(CurrentThing, x1, y1);
							HideMousePointer;
							ClearDevice;
							WMapViewer^.Draw;
							HiLightItem;
							SpViewer:=New(PSpriteViewer, Init(ThingNum, DOOMDir));
							SpViewer^.Draw;
							SpViewer^.Done;
							Dispose(SpViewer);
							ShowMousePointer;
						end;
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
