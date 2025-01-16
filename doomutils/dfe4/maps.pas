{****************************************************************************
*                      The DOOM Hacker's Tool Kit                           *
*****************************************************************************
* Unit: 	  MAPS                                                             *
* Purpose: Loading and displaying the Maps from the WAD File                *
* Date:    4/28/94                                                          *
* Author:  Joshua Jackson        Internet: joshjackson@delphi.com           *
****************************************************************************}

{$O+,F+}
unit Maps;

interface

uses Wad,WadDecl,DOOMGUI,GUIObj,ObjCache,Mouse;

type  PWadMapViewer=^TWadMapViewer;
		TWadMapViewer=TGraphGroup;
		PWadMap=^TWadMap;
		TWadMap=Object(TGraphView)
			LevelEntries:PLevelEntries;
			ThingList	:PThingList;
			VertexList	:PVertexList;
			LineDefList	:PLineDefList;
			SectorList	:PSectorList;
			SideDefList	:PSideDefList;	{These often grow to more than 64k}
			ViewerMask	:word;
			ThingMask	:word;
			ScaleInc,XOffset,YOffset:word;
			MidX,MidY,MaxX,MaxY,MinX,MinY:integer;
			ScaleX,ScaleY,Scale:real;
			IntScale:Longint;
			NumSides,NumThings,NumLines:word;
			Constructor Init(WDir:PWadDirectory;LevelName:ObjNameStr);
			Procedure Draw; virtual;
			Procedure DrawLineDef(l,Color:integer);
			Procedure SetScale(NewScaleInc,NewXOffset,NewYOffset:word);
			Function GetThingInArea(var x1,y1,x2,y2:word):word;
			Function IsLineDefInside(l,x0,y0,x1,y1:integer):boolean;
			Function GetLineDefInArea(x0,y0,x1,y1:integer):integer;
			Function GetSectorInArea(x0,y0,x1,y1:word):integer;
			Function SecretSector(L:word):boolean;
			Function LineDefHasTag(l:word):boolean;
			Function SectorHasTag(l:word):boolean;
			Destructor Done; virtual;
		end;

implementation

uses crt,graph;

Function OnSkillLevel(Attr,ViewerMask:word):boolean;

	var TempAttr:word;

	begin
		TempAttr:=(ViewerMask and 64);
		if (TempAttr=0) and ((Attr and 16) = 16) then begin
			OnSkillLevel:=False;
			exit;
		end;
		TempAttr:=(ViewerMask and 56) shr 3;
		if (TempAttr and (Attr and 7)) = TempAttr then
			OnSkillLevel:=True
		else
			OnSkillLevel:=False;
	end;


Constructor TWadMap.Init(WDir:PWadDirectory;LevelName:ObjNameStr);

	var	Entry,LevelPos:word;
			R:TGraphRect;
			t:integer;
			sdnum:word;

	begin
		Owner:=Nil;
		Next:=Nil;
		ScaleInc:=1;
		XOffset:=0;
		YOffset:=0;
		R.Assign(0,0,639,479);
		Bounds:=R;
		New(LevelEntries);
		LevelPos:=WDir^.FindObject(LevelName);
		if LevelPos=0 then begin
			writeln('TWapMap_Init: Invalid Level Name ',LevelName);
			halt;
		end;
		LevelEntries^.MapID:=WDir^.DirEntry^[LevelPos];
		LevelEntries^.Things:=WDir^.DirEntry^[LevelPos+1];
		LevelEntries^.LineDefs:=WDir^.DirEntry^[LevelPos+2];
		LevelEntries^.SideDefs:=WDir^.DirEntry^[LevelPos+3];
		LevelEntries^.Vertexes:=WDir^.DirEntry^[LevelPos+4];
		LevelEntries^.Segs:=WDir^.DirEntry^[LevelPos+5];
		LevelEntries^.SSectors:=WDir^.DirEntry^[LevelPos+6];
		LevelEntries^.Nodes:=WDir^.DirEntry^[LevelPos+7];
		LevelEntries^.Sectors:=WDir^.DirEntry^[LevelPos+8];
		LevelEntries^.Reject:=WDir^.DirEntry^[LevelPos+9];
		LevelEntries^.BlockMap:=WDir^.DirEntry^[LevelPos+10];
		GetMem(ThingList,LevelEntries^.Things.ObjLength);
		Seek(WDir^.WadFile,LevelEntries^.Things.ObjStart);
		BlockRead(WDir^.WadFile,ThingList^,LevelEntries^.Things.ObjLength);
		GetMem(VertexList,LevelEntries^.Vertexes.ObjLength);
		Seek(WDir^.WadFile,LevelEntries^.Vertexes.ObjStart);
		BlockRead(WDir^.WadFile,VertexList^,LevelEntries^.Vertexes.ObjLength);
		GetMem(LineDefList,LevelEntries^.LineDefs.ObjLength);
		Seek(WDir^.WadFile,LevelEntries^.LineDefs.ObjStart);
		BlockRead(WDir^.WadFile,LineDefList^,LevelEntries^.LineDefs.ObjLength);
		GetMem(SectorList,LevelEntries^.Sectors.ObjLength);
		Seek(WDir^.WadFile,LevelEntries^.Sectors.ObjStart);
		BlockRead(WDir^.WadFile,SectorList^,LevelEntries^.Sectors.ObjLength);
		NumSides:=(LevelEntries^.SideDefs.ObjLength div Sizeof(TSideDef));
		GetMem(SideDefList, NumSides * Sizeof(PSideDef));
		Seek(WDir^.WadFile,LevelEntries^.SideDefs.ObjStart);
		for t:=0 to NumSides - 1 do begin
			new(SideDefList^[t]);
			BlockRead(WDir^.WadFile,SideDefList^[t]^,Sizeof(TSideDef));
		end;
		MinX:=32000;
		MinY:=32000;
		MaxX:=-32000;
		MaxY:=-32000;
		for t:=0 to ((LevelEntries^.Vertexes.ObjLength div 4) -1) do begin
			if VertexList^[t].x < MinX then
				MinX:=VertexList^[t].x;
			if VertexList^[t].x > MaxX then
				MaxX:=VertexList^[t].x;
			if VertexList^[t].y < MinY then
				MinY:=VertexList^[t].y;
			if VertexList^[t].y > Maxy then
				MaxY:=VertexList^[t].y;
		end;
		MidX:=(MinX+MaxX) div 2;
		MidY:=(MinY+MaxY) div 2;
		ScaleX:=(320 / (MaxX - MidX)) * 0.90;
		ScaleY:=(240 / (MaxY - MidY)) * 0.90;
		if ScaleX < ScaleY then
			Scale:=ScaleX
		else
			Scale:=ScaleY;
		ScaleInc:=1;
		IntScale:=Round(Scale * 65536);
		NumThings:=((LevelEntries^.Things.ObjLength div 10) -1);
		NumLines:=((LevelEntries^.LineDefs.ObjLength div 14) - 1);
		XOffset:=0;
		XOffset:=0;
	end;

Function	TWadMap.SecretSector(l:word):boolean;

	var	SD1:longint;
			TSD:TSideDef;

	begin
		SD1:=LineDefList^[l].RightSideDef;
		if SD1 > 0 then begin
			if SectorList^[SideDefList^[SD1]^.Sector].SectorCode = 9 then begin
				SecretSector:=True;
				exit;
			end;
		end;
		SD1:=LineDefList^[l].LeftSideDef;
		if SD1 >=0 then begin
			if SectorList^[SideDefList^[SD1]^.Sector].SectorCode = 9 then begin
				SecretSector:=True;
				exit;
			end;
		end;
		SecretSector:=False;
	end;

Function TWadMap.LineDefHasTag(l:word):boolean;

	begin
		if LineDefList^[l].Tag > 0 then
			LineDefHasTag:=true
		else
			LineDefHasTag:=False;
	end;

Function	TWadMap.SectorHasTag(l:word):boolean;

	var	SD1:longint;
			TSD:TSideDef;

	begin
		SD1:=LineDefList^[l].RightSideDef;
		if SD1 > 0 then begin
			if SectorList^[SideDefList^[SD1]^.Sector].Tag > 0 then begin
				SectorHasTag:=True;
				exit;
			end;
		end;
		SD1:=LineDefList^[l].LeftSideDef;
		if SD1 >=0 then begin
			if SectorList^[SideDefList^[SD1]^.Sector].Tag > 0 then begin
				SectorHasTag:=True;
				exit;
			end;
		end;
		SectorHasTag:=False;
	end;

Procedure TWadMap.Draw;

	var	x1,y1,x2,y2,t:integer;
			ch,SkillLevel:Char;
			TempStr:String;
			TT:word;
			SubView:PGraphView;
			NewScale:real;

	begin
		SetLineStyle(SolidLn,0,1);
		NewScale:=Scale * ScaleInc;
		IntScale:=Round(NewScale * 65536);
		for t:=0 to NumLines do begin
			SetColor(wcBlue);
			case LineDefList^[t].LineDefType of
				1,26..28,31..34:SetColor(wcLtBlue);   {Doors}
				11,51,52:SetColor(wcGreen);	{End Level}
			end;
			if GetColor <> wcGreen then begin
				if (ViewerMask and 256) = 256 then
					if LineDefHasTag(t) or SectorHasTag(t) then
						SetColor(wcPurple)
					else
						SetColor(wcDkGrey);
				if (ViewerMask and 128) = 128 then
					if ((LineDefList^[t].Attributes and 32) = 32) or SecretSector(t) then
						SetColor(wcLtGrey);
			end;
			x1:=(((VertexList^[LineDefList^[t].StartVertex].x-MidX) * IntScale div 65536) + 320)+(XOffset * ScaleInc);
			y1:=(((VertexList^[LineDefList^[t].StartVertex].Y-MidY) * (-IntScale) div 65536) + 240)+(YOffset * ScaleInc);
			x2:=(((VertexList^[LineDefList^[t].EndVertex].x-MidX) * IntScale div 65536) + 320)+(XOffset * ScaleInc);
			y2:=(((VertexList^[LineDefList^[t].EndVertex].Y-MidY) * (-IntScale) div 65536) + 240)+(YOffset * ScaleInc);
			Line(x1,y1,x2,y2);
		end;
		for t:=0 to NumThings do begin
			x1:=(((ThingList^[t].x-MidX) * IntScale div 65536)+320)+(XOffset * ScaleInc);
			y1:=(((ThingList^[t].y-MidY) * (-IntScale) div 65536)+240)+(YOffset * ScaleInc);
			SetColor(wcRed);
			TT:=ThingList^[t].ThingType;
			if ThingMask=0 then begin
				if OnSkillLevel(ThingList^[t].Attributes,ViewerMask) then begin
					if (ViewerMask and 1) = 1 then {Monsters}
						if (TT=$7) or (TT=$9) or (TT=$10) or (TT=$3A) or ((TT > $BB8) and (TT<$BBF)) then begin
							SetColor(wcRed);
							Circle(x1,y1,ScaleInc);
						end;
					if (ViewerMask and 2) = 2 then begin {Goodies}
						if (TT=$5) or (TT=$6) or (TT=$8) or (TT=$d) or (TT=$26) or (TT=$27) then begin
							SetColor(wcGreen);
							Circle(x1,y1,ScaleInc);
						end;
						if ((TT>$7D6) and (TT<$7EB)) or ((TT>$7FC) and (TT<$802)) then begin
							SetColor(wcGreen);
							Circle(x1,y1,ScaleInc);
						end;
					end;
					if (ViewerMask and 4) = 4 then {Weapons}
						if (TT > $7D0) and (TT<$7D7) then begin
							SetColor(wcYellow);
							Circle(x1,y1,ScaleInc);
						end;
				end;
			 end
			else if TT=ThingMask then begin
				SetColor(wcYellow);
				Circle(x1,y1,ScaleInc);
			end;
		end;
		OutTextXY(560,1,LevelEntries^.MapID.ObjName);
		str(ScaleInc,TempStr);
		OutTextXY(1,465,'Scale: '+TempStr+'x');
		Str(MemAvail,TempStr);
		OutTextXY(495,465,'MemAvail: '+TempStr);
	end;

Procedure TWadMap.DrawLineDef(l,Color:integer);

	var	x1,y1,x2,y2:word;

	begin
		if Color=-1 then begin
			SetColor(wcBlue);
			case LineDefList^[l].LineDefType of
				1,26..28,31..34:SetColor(wcLtBlue);   {Doors}
				11,51,52:SetColor(wcGreen);	{end level}
			end;
			if GetColor <> wcGreen then begin
				if (ViewerMask and 256) = 256 then
					if LineDefHasTag(l) or SectorHasTag(l) then
						SetColor(wcPurple)
					else
						SetColor(wcDkGrey);
				if (ViewerMask and 128) = 128 then
					if ((LineDefList^[l].Attributes and 32) = 32) or SecretSector(l) then
						SetColor(wcLtGrey);
			end;
		 end
		else
			SetColor(Color);
		x1:=(((VertexList^[LineDefList^[l].StartVertex].x-MidX) * IntScale div 65536) + 320)+(XOffset * ScaleInc);
		y1:=(((VertexList^[LineDefList^[l].StartVertex].Y-MidY) * (-IntScale) div 65536) + 240)+(YOffset * ScaleInc);
		x2:=(((VertexList^[LineDefList^[l].EndVertex].x-MidX) * IntScale div 65536) + 320)+(XOffset * ScaleInc);
		y2:=(((VertexList^[LineDefList^[l].EndVertex].Y-MidY) * (-IntScale) div 65536) + 240)+(YOffset * ScaleInc);
		Line(x1,y1,x2,y2);
	end;

Procedure TWadMap.SetScale(NewScaleInc,NewXOffset,NewYOffset:word);

	begin
		ScaleInc:=NewScaleInc;
		XOffset:=NewXOffset;
		YOffset:=NewYOffset;
	end;

Function TWadMap.GetThingInArea(var x1,y1,x2,y2:word):word;

	var	x,y,t:integer;
			TT:word;

	begin
		for t:=0 to NumThings do begin
			x:=(((ThingList^[t].x-MidX) * IntScale div 65536)+320)+(XOffset * ScaleInc);
			y:=(((ThingList^[t].y-MidY) * (-IntScale) div 65536)+240)+(YOffset * ScaleInc);
			if ((x >= x1) and (x <= x2)) and ((y >= y1) and (y <= y2)) then begin
				TT:=ThingList^[t].ThingType;
				if ThingMask=0 then begin
					if (ViewerMask and 1) = 1 then {Monsters}
						if (TT=$7) or (TT=$9) or (TT=$10) or (TT=$3A) or ((TT > $BB8) and (TT<$BBF)) then begin
							GetThingInArea:=TT;
							exit;
						end;
					if (ViewerMask and 2) = 2 then begin {Goodies}
						if (TT=$5) or (TT=$6) or (TT=$8) or (TT=$d) or (TT=$26) or (TT=$27) then begin
							GetThingInArea:=TT;
							exit;
						end;
						if ((TT>$7D6) and (TT<$7EB)) or ((TT>$7FC) and (TT<$802)) then begin
							GetThingInArea:=TT;
							exit;
						end;
					end;
					if (ViewerMask and 4) = 4 then {Weapons}
						if (TT > $7D0) and (TT<$7D7) then begin
							GetThingInArea:=TT;
							exit;
						end;
				 end
				else if TT=ThingMask then begin
					GetThingInArea:=TT;
					x1:=x;
					y1:=y;
					exit;
				end;
			end;
		end;
		GetThingInArea:=0;
	end;

Function TWadMap.GetSectorInArea(x0,y0,x1,y1:word):integer;

	var	m,t,curx,cur,Midx1,Midy1,x2,y2,x3,y3:integer;
			SD:TSideDef;
			SDP:Longint;
			TempStr1,TempStr2:string;

	begin
		curx:=MaxX+1;
		cur:=-1;
		MidX1:=(Round((Longint(x0-(XOffset * ScaleInc))-320) / Scale) + MidX);
		MidY1:=(Round((Longint(y0-(YOffset * ScaleInc))-240) / (-Scale)) + MidY);
		for t:=0 to NumLines do begin
			y2:=VertexList^[LineDefList^[t].StartVertex].Y;
			y3:=VertexList^[LineDefList^[t].EndVertex].Y;
			if (y2 > Midy1) <> (y3 > Midy1) then begin
				x2:=VertexList^[LineDefList^[t].StartVertex].x;
				y2:=VertexList^[LineDefList^[t].StartVertex].y;
				x3:=VertexList^[LineDefList^[t].EndVertex].x;
				y3:=VertexList^[LineDefList^[t].EndVertex].y;
				m:=x2+integer((longint((midy1-y2) * longint(x3-x2)) div (y3 - y2)));
{				m:=x2;}
				if (m >= MidX1) and (m < curx) then begin
					curx:=m;
					cur:=t;
				end;
			end;
		end;
		if cur>=0 then begin
			if VertexList^[LineDefList^[cur].StartVertex].y >
					VertexList^[LineDefList^[cur].EndVertex].y then
				cur:=LineDefList^[cur].RightSideDef
			else
				cur:=LineDefList^[cur].LeftSideDef;
			if cur>=0 then begin
				cur:=SideDefList^[cur]^.Sector;
			 end
			else
				cur:=-1
		 end
		else
			cur:=-1;
		GetSectorInArea:=cur;
	end;

Function TWadMap.IsLineDefInside(l,x0,y0,x1,y1:integer):boolean;

	var lx0,ly0,lx1,ly1,i:integer;

	begin
		IsLineDefInside:=True;
		lx0:=(((VertexList^[LineDefList^[l].StartVertex].x-MidX) * IntScale div 65536) + 320)+(XOffset * ScaleInc);
		ly0:=(((VertexList^[LineDefList^[l].StartVertex].Y-MidY) * (-IntScale) div 65536) + 240)+(YOffset * ScaleInc);
		lx1:=(((VertexList^[LineDefList^[l].EndVertex].x-MidX) * IntScale div 65536) + 320)+(XOffset * ScaleInc);
		ly1:=(((VertexList^[LineDefList^[l].EndVertex].Y-MidY) * (-IntScale) div 65536) + 240)+(YOffset * ScaleInc);
		if (lx0 >= x0) and (lx0 <= x1) and (ly0 >= y0) and (ly0 <= y1) then
			exit;
		if (lx1 >= x0) and (lx1 <= x1) and (ly1 >= y0) and (ly1 <= y1) then
			exit;
		if (ly0 > y0) <> (ly1 > y0) then begin
			i:=lx0+integer(longint(y0-ly0) * longint(lx1-lx0) div longint(ly1-ly0));
			if (i >= x0) and (i <= x1) then
				exit;
		end;
		if (ly0 > y1) <> (ly1 > y1) then begin
			i:=lx0+integer(longint(y1-ly0) * longint(lx1-lx0) div longint(ly1-ly0));
			if (i >= x0) and (i <= x1) then
				exit;
		end;
		if (lx0 > x0) <> (lx1 > x0) then begin
			i:=ly0+integer(longint(x0-lx0) * longint(ly1-ly0) div longint(lx1-lx0));
			if (i >= y0) and (i <= y1) then
				exit;
		end;
		if (lx0 > x1) <> (lx1 > x1) then begin
			i:=ly0+integer(longint(x1-lx0) * longint(ly1-ly0) div longint(lx1-lx0));
			if (i >= y0) and (i <= y1) then
				exit;
		end;
		IsLineDefInside:=False;
	end;

Function TWadMap.GetLineDefInArea(x0,y0,x1,y1:integer):integer;

	var t:integer;

	begin
		GetLineDefInArea:=-1;
		for t:=0 to NumLines do begin
			if IsLineDefInside(t,x0,y0,x1,y1) then begin
				GetLineDefInArea:=t;
				exit;
			end;
		end;
	end;

Destructor TWadMap.Done;

	var	TempView,SubView:PGraphView;
			t:integer;

	begin
		FreeMem(ThingList,LevelEntries^.Things.ObjLength);
		FreeMem(VertexList,LevelEntries^.Vertexes.ObjLength);
		FreeMem(LineDefList,LevelEntries^.LineDefs.ObjLength);
		FreeMem(SectorList,LevelEntries^.Sectors.ObjLength);
{		Dispose(SideDefList,Done);}
		for t:=0 to NumSides - 1 do
			Dispose(SideDefList^[t]);
		freemem(SideDefList, NumSides * Sizeof(PSideDef));
		Dispose(LevelEntries);
	end;

end.
