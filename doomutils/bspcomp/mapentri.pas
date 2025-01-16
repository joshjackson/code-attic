unit MapEntries;

interface

uses Objects,Wads;

{Wad Map Things}
type  PThing=^TThing;
		TThing=Record
			x		:integer;
			y		:integer;
			Angle	:integer;
			ID		:integer;
			Attr  :integer;
		end;
		PThingList=^TThingList;
		TThingList=Object(TCollection)
			Constructor Init(ALimit,ADelta:integer);
			Procedure FreeItem(Item:Pointer); virtual;
			Function At(Index:integer):PThing; virtual;
		end;
		PMapSize=^TMapSize;
		TMapSize=Record
			orgx	:integer;
			orgy	:integer;
			sizex	:word;
			sizey	:word;
		end;
		PMapBounds=^TMapBounds;
		TMapBounds=record
			minx,
			miny,
			maxx,
			maxy	:integer;
		end;

{Wad Map Vertexes}
type  PVertex=^TVertex;
		TVertex=Record
			x		:integer;
			y		:integer;
		end;
		PVertexList=^TVertexList;
		TVertexList=Object(TCollection)
			Constructor Init(ALimit,ADelta:integer);
			Procedure FreeItem(Item:Pointer); virtual;
			Function At(Index:integer):PVertex; virtual;
		end;

{Wad Map LineDefs}
type  PLineDef=^TLineDef;
		TLineDef=Record
			v0       :integer;
			v1       :integer;
			Attr     :word;
			LineType	:word;
			Tag      :integer;
			SideDef0	:integer;
			SideDef1 :integer;
		end;
		PLineDefList=^TLineDefList;
		TLineDefList=Object(TCollection)
			Constructor Init(ALimit,ADelta:integer);
			Procedure FreeItem(Item:Pointer); virtual;
			Function At(Index:integer):PLineDef; virtual;
		end;

{Wad Map SideDefs}
type  PSideDef=^TSideDef;
		TSideDef=record
			XOfs     	:integer;
			YOfs     	:integer;
			UpTexture   :ObjNameDef;
			LoTexture   :ObjNameDef;
			NormTexture :ObjNameDef;
			Sector      :word;
		end;
		PSideDefList=^TSideDefList;
		TSideDefList=Object(TCollection)
			Constructor Init(ALimit,ADelta:integer);
			Procedure FreeItem(Item:Pointer); virtual;
			Function At(Index:integer):PSideDef; virtual;
		end;

{Wad Map Segs}
Type	PSeg=^TSeg;
		TSeg=Record
			v0			:integer;
			v1			:integer;
			Angle		:word;
			LineDef  :integer;
			SideDef	:integer;
			LineOfs	:integer;
		end;
		PSegList=^TSegList;
		TSegList=Object(TCollection)
			Constructor Init(ALimit, ADelta:integer);
			Procedure FreeItem(Item:Pointer); virtual;
			Function At(Index:Integer):PSeg; virtual;
		end;

{Wad Map SSectors}
type	PSSector=^TSSector;
		TSSector=record
			NumSegs	:integer;
			StartSeg	:integer;
		end;
		PSSectorList=^TSSectorList;
		TSSectorList=Object(TCollection)
			Constructor Init(ALimit,ADelta:integer);
			Procedure FreeItem(Item:Pointer); virtual;
			Function At(Index:integer):PSSector; virtual;
		end;

{Wad Map Nodes}
type	TNodeBox=Record
			y1		:integer;
			y0		:integer;
			x0		:integer;
			x1		:integer;
		end;
		PNode=^TNode;
		TNode=Record
			x0		:integer;
			y0		:integer;
			dx		:integer;
			dy		:integer;
			rbox	:TNodeBox;
			lbox	:TNodeBox;
			rchild:word;
			lchild:word;
		end;
		PNodeList=^TNodeList;
		TNodeList=Object(TCollection)
			Constructor Init(ALimit,ADelta:integer);
			Procedure FreeItem(Item:Pointer); virtual;
			Function At(Index:integer):PNode; virtual;
		end;

{Wad Map Sectors}
type	PSector=^TSector;
		TSector=record
			FloorHeight    :integer;
			CeilingHeight  :integer;
			FloorTexture   :ObjNameDef;
			CeilingTexture :ObjNameDef;
			LightLevel     :integer;
			SectorCode     :integer;
			Tag            :word;
		end;
		PSectorList=^TSectorList;
		TSectorList=Object(TCollection)
			Constructor Init(ALimit,ADelta:integer);
			Procedure FreeItem(Item:Pointer); virtual;
			Function At(Index:integer):PSector; virtual;
		end;

Function LoadThings(WDir:PWadDirectory; LevelPos:integer):PThingList;
Function LoadLineDefs(WDir:PWadDirectory; LevelPos:integer):PLineDefList;
Function LoadSideDefs(WDir:PWadDirectory; LevelPos:integer):PSideDefList;
Function LoadVertexes(WDir:PWadDirectory; LevelPos:integer):PVertexList;
Function LoadSegs(WDir:PWadDirectory; LevelPos:integer):PSegList;
Function LoadSSectors(WDir:PWadDirectory; LevelPos:integer):PSSectorList;
Function LoadNodes(WDir:PWadDirectory; LevelPos:integer):PNodeList;
Function LoadSectors(WDir:PWadDirectory; LevelPos:integer):PSectorList;

Procedure InitMapData(WDir:PWadDirectory;LevelPos:integer;
							 var Things:PThingList; var LineDefs:PLineDefList;
							 var SideDefs:PSideDefList; var Vertexes:PVertexList;
							 var Sectors:PSectorList);

Procedure LoadTextureList(WDir:PWadDirectory; var WallTextures:PStringCollection;
									var FloorTextures:PStringCollection);

Function GetOppositeSector(Vertexes:PVertexList; LineDefs:PLineDefList; SideDefs:
									PSideDefList; ld1:integer; firstside:Boolean):integer;

Procedure GetMapBounds(var M:TMapBounds; V:PVertexList; L:PLineDefList);
Procedure GetMapSize(var M:TMapSize; V:PVertexList; L:PLineDefList);

implementation

{$IFNDEF WINDOWS}
uses	Crt,CStuff;
{$ELSE}
uses WinCrt,CStuff;
{$ENDIF}

{ThingList Object Declaration----------------------------------------------}
Constructor TThingList.Init(ALimit, ADelta:integer);

	begin
		Inherited Init(ALimit, ADelta);
	end;

Procedure TThingList.FreeItem(Item:Pointer);

	begin
		if Item <> Nil then Dispose(PThing(Item));
	end;

Function TThingList.At(Index:integer):PThing;

	begin
		At:=PThing(TCollection.at(Index));
	end;

{VertexList Object Declaration----------------------------------------------}
Constructor TVertexList.Init(ALimit, ADelta:integer);

	begin
		Inherited Init(ALimit, ADelta);
	end;

Procedure TVertexList.FreeItem(Item:Pointer);

	begin
		if Item <> Nil then Dispose(PVertex(Item));
	end;

Function TVertexList.At(Index:integer):PVertex;

	begin
		At:=PVertex(TCollection.at(Index));
	end;

{LineDefList Object Declaration---------------------------------------------}
Constructor TLineDefList.Init(ALimit, ADelta:integer);

	begin
		Inherited Init(ALimit, ADelta);
	end;

Procedure TLineDefList.FreeItem(Item:Pointer);

	begin
		if Item <> Nil then Dispose(PLineDef(Item));
	end;

Function TLineDefList.At(Index:integer):PLineDef;

	begin
		At:=PLineDef(TCollection.at(Index));
	end;

{SideDefList Object Declaration---------------------------------------------}
Constructor TSideDefList.Init(ALimit, ADelta:integer);

	begin
		Inherited Init(ALimit, ADelta);
	end;

Procedure TSideDefList.FreeItem(Item:Pointer);

	begin
		if Item <> Nil then Dispose(PSideDef(Item));
	end;

Function TSideDefList.At(Index:integer):PSideDef;

	begin
		At:=PSideDef(TCollection.at(Index));
	end;

{SegList Object Declaration-------------------------------------------------}
Constructor TSegList.Init(ALimit, ADelta:integer);

	begin
		Inherited Init(ALimit, ADelta);
	end;

Procedure TSegList.FreeItem(Item:Pointer);

	begin
		if Item <> Nil then Dispose(PSeg(Item));
	end;

Function TSegList.At(Index:integer):PSeg;

	begin
		At:=PSeg(TCollection.at(Index));
	end;

{SSectorList Object Declaration---------------------------------------------}
Constructor TSSectorList.Init(ALimit, ADelta:integer);

	begin
		Inherited Init(ALimit, ADelta);
	end;

Procedure TSSectorList.FreeItem(Item:Pointer);

	begin
		if Item <> Nil then Dispose(PSSector(Item));
	end;

Function TSSectorList.At(Index:integer):PSSector;

	begin
		At:=PSSector(TCollection.at(Index));
	end;

{SSectorList Object Declaration---------------------------------------------}
Constructor TNodeList.Init(ALimit, ADelta:integer);

	begin
		Inherited Init(ALimit, ADelta);
	end;

Procedure TNodeList.FreeItem(Item:Pointer);

	begin
		if Item <> Nil then Dispose(PNode(Item));
	end;

Function TNodeList.At(Index:integer):PNode;

	begin
		At:=PNode(TCollection.at(Index));
	end;

{SectorList Object Declaration---------------------------------------------}
Constructor TSectorList.Init(ALimit, ADelta:integer);

	begin
		Inherited Init(ALimit, ADelta);
	end;

Procedure TSectorList.FreeItem(Item:Pointer);

	begin
		if Item <> Nil then Dispose(PSector(Item));
	end;

Function TSectorList.At(Index:integer):PSector;

	begin
		At:=PSector(TCollection.at(Index));
	end;

Function LoadThings(WDir:PWadDirectory; LevelPos:integer):PThingList;

	var	l,t,i:integer;
			Temp:pointer;
			Things:PThingList;

	begin
		inc(LevelPos);
		if Pos('THINGS',WDir^.EntryName(LevelPos)) = 0 then begin
         {$IFNDEF WINDOWS}
         TextMode(CO80);
         {$ENDIF}
			writeln('LoadThings: LevelPos is not a valid level entry. ',LevelPos);
			Halt(1);
		end;
		t:=WDir^.At(LevelPos)^.ObjLength div SizeOf(TThing);
		WDir^.SeekEntry(LevelPos);
		Things:=New(PThingList, Init(t, 5));
		for i:=1 to t do begin
			New(PThing(Temp));
			BlockRead(WDir^.WadFile, Temp^, SizeOf(TThing));
			Things^.Insert(Temp);
		end;
		LoadThings:=Things;
	end;

Function LoadLineDefs(WDir:PWadDirectory; LevelPos:integer):PLineDefList;

	var	t,i:integer;
			Temp:pointer;
			LineDefs:PLineDefList;

	begin
		inc(LevelPos, 2);
		if Pos('LINEDEFS',WDir^.EntryName(LevelPos)) = 0 then begin
         {$IFNDEF WINDOWS}
         TextMode(CO80);
         {$ENDIF}
			writeln('LoadLineDefs: LevelPos is not a valid level entry.');
			Halt(1);
		end;
		t:=WDir^.At(LevelPos)^.ObjLength div SizeOf(TLineDef);
		WDir^.SeekEntry(LevelPos);
		LineDefs:=New(PLineDefList, Init(t, 5));
		for i:=1 to t do begin
			New(PLineDef(Temp));
			BlockRead(WDir^.WadFile, Temp^, SizeOf(TLineDef));
			LineDefs^.Insert(Temp);
		end;
		LoadLineDefs:=LineDefs;
	end;

Function LoadSideDefs(WDir:PWadDirectory; LevelPos:integer):PSideDefList;

	var	t,i:integer;
			Temp:pointer;
			SideDefs:PSideDefList;

	begin
		Inc(LevelPos,3);
		if Pos('SIDEDEFS',WDir^.EntryName(LevelPos)) = 0 then begin
         {$IFNDEF WINDOWS}
         TextMode(CO80);
         {$ENDIF}
			writeln('LoadSideDefs: LevelPos is not a valid level entry.');
			Halt(1);
		end;
		t:=WDir^.At(LevelPos)^.ObjLength div SizeOf(TSideDef);
		WDir^.SeekEntry(LevelPos);
		SideDefs:=New(PSideDefList, Init(t, 5));
		for i:=1 to t do begin
			New(PSideDef(Temp));
			BlockRead(WDir^.WadFile, Temp^, SizeOf(TSideDef));
			SideDefs^.Insert(Temp);
		end;
		LoadSideDefs:=SideDefs;
	end;

Function LoadVertexes(WDir:PWadDirectory; LevelPos:integer):PVertexList;

	var	t,i:integer;
			Temp:pointer;
			Vertexes:PVertexList;

	begin
		Inc(LevelPos,4);
		if Pos('VERTEXES',WDir^.EntryName(LevelPos)) = 0 then begin
         {$IFNDEF WINDOWS}
         TextMode(CO80);
         {$ENDIF}
			writeln('LoadVertexes: LevelPos is not a valid level entry.');
			halt(1);
		end;
		t:=WDir^.At(LevelPos)^.ObjLength div SizeOf(TVertex);
		WDir^.SeekEntry(LevelPos);
		Vertexes:=New(PVertexList, Init(t, 5));
		for i:=1 to t do begin
			New(PVertex(Temp));
			BlockRead(WDir^.WadFile, Temp^, SizeOf(TVertex));
			Vertexes^.Insert(Temp);
		end;
		LoadVertexes:=Vertexes;
	end;

Function LoadSegs(WDir:PWadDirectory; LevelPos:integer):PSegList;

	var	t,i:integer;
			Temp:pointer;
			Segs:PSegList;

	begin
		Inc(LevelPos,5);
		if Pos('SEGS',WDir^.EntryName(LevelPos)) = 0 then begin
         {$IFNDEF WINDOWS}
         TextMode(CO80);
         {$ENDIF}
			writeln('LoadSegs: LevelPos is not a valid level entry.');
			halt(1);
		end;
		t:=WDir^.EntrySize(LevelPos) div SizeOf(TSeg);
		WDir^.SeekEntry(LevelPos);
		Segs:=New(PSegList, Init(t, 5));
		for i:=1 to t do begin
			New(PSeg(Temp));
			BlockRead(WDir^.WadFile, Temp^, SizeOf(TSeg));
			Segs^.Insert(Temp);
		end;
		LoadSegs:=Segs;
	end;

Function LoadSSectors(WDir:PWadDirectory; LevelPos:integer):PSSectorList;

	var	t,i:integer;
			Temp:pointer;
			SSectors:PSSectorList;

	begin
		Inc(LevelPos,6);
		if Pos('SSECTORS',WDir^.EntryName(LevelPos)) = 0 then begin
         {$IFNDEF WINDOWS}
         TextMode(CO80);
         {$ENDIF}
			writeln('LoadSSectors: LevelPos is not a valid level entry.');
			halt(1);
		end;
		t:=WDir^.EntrySize(LevelPos) div SizeOf(TSSector);
		WDir^.SeekEntry(LevelPos);
		SSectors:=New(PSSectorList, Init(t, 5));
		for i:=1 to t do begin
			New(PSSector(Temp));
			BlockRead(WDir^.WadFile, Temp^, SizeOf(TSSector));
			SSectors^.Insert(Temp);
		end;
		LoadSSectors:=SSectors;
	end;

Function LoadNodes(WDir:PWadDirectory; LevelPos:integer):PNodeList;

	var	t,i:integer;
			Temp:pointer;
			Nodes:PnodeList;

	begin
		Inc(LevelPos,7);
		if Pos('NODES',WDir^.EntryName(LevelPos)) = 0 then begin
         {$IFNDEF WINDOWS}
         TextMode(CO80);
         {$ENDIF}
			writeln('LoadNodes: LevelPos is not a valid level entry.');
			halt(1);
		end;
		t:=WDir^.EntrySize(LevelPos) div SizeOf(TNode);
		WDir^.SeekEntry(LevelPos);
		Nodes:=New(PNodeList, Init(t, 5));
		for i:=1 to t do begin
			New(PNode(Temp));
			BlockRead(WDir^.WadFile, Temp^, SizeOf(TNode));
			Nodes^.Insert(Temp);
		end;
		LoadNodes:=Nodes;
	end;

Function LoadSectors(WDir:PWadDirectory; LevelPos:integer):PSectorList;

	var	t,i:integer;
			Temp:pointer;
			Sectors:PSectorList;

	begin
		Inc(LevelPos,8);
		if Pos('SECTORS',WDir^.EntryName(LevelPos)) = 0 then begin
         {$IFNDEF WINDOWS}
         TextMode(CO80);
         {$ENDIF}
			writeln('LoadSectors: LevelPos is not a valid level entry.');
			Halt(1);
		end;
		t:=WDir^.At(LevelPos)^.ObjLength div SizeOf(TSector);
		WDir^.SeekEntry(LevelPos);
		Sectors:=New(PSectorList, Init(t, 5));
		for i:=1 to t do begin
			New(PSector(Temp));
			BlockRead(WDir^.WadFile, Temp^, SizeOf(TSector));
			Sectors^.Insert(Temp);
		end;
		LoadSectors:=Sectors;
	end;

Procedure InitMapData(WDir:PWadDirectory;LevelPos:integer;
							 var Things:PThingList; var LineDefs:PLineDefList;
							 var SideDefs:PSideDefList; var Vertexes:PVertexList;
							 var Sectors:PSectorList);

	begin
		{$IFDEF DEBUG}
		writeln('   Reading Things');
		{$ENDIF}
		Things:=LoadThings(WDir, LevelPos);
		{$IFDEF DEBUG}
		writeln('   Reading LineDefs');
		{$ENDIF}
		LineDefs:=LoadLineDefs(WDir, LevelPos);
		{$IFDEF DEBUG}
		writeln('   Reading SideDefs');
		{$ENDIF}
		SideDefs:=LoadSideDefs(WDir, LevelPos);
		{$IFDEF DEBUG}
		writeln('   Reading Vertexes');
		{$ENDIF}
		Vertexes:=LoadVertexes(WDir, LevelPos);
		{$IFDEF DEBUG}
		writeln('   Reading Sectors');
		{$ENDIF}
		Sectors:=LoadSectors(WDir, LevelPos);
	end;

Procedure LoadTextureList(WDir:PWadDirectory; var WallTextures:PStringCollection;
									var FloorTextures:PStringCollection);

	var	p:integer;
			t:integer;
			TexStart,TexPos,NumTex:Longint;
			FStart,FEnd:integer;
			TempStr:String[8];
			Temp:PString;

	begin
		{Load Wall Textures}
		p:=WDir^.FindObject('TEXTURE1');
		if p=-1 then begin
         {$IFNDEF WINDOWS}
         TextMode(CO80);
         {$ENDIF}
			writeln('LoadTextureList: Unable to locate TEXTURE1 Entry');
			Halt(1);
		end;
		TexStart:=WDir^.EntryPos(p);
		WDir^.SeekEntry(p);
		BlockRead(WDir^.WadFile, NumTex, 4);
		WallTextures:=New(PStringCollection, Init(NumTex, 5));
		WallTextures^.Duplicates:=True;
		for t:=1 to NumTex do begin
			Seek(WDir^.WadFile, TexStart + (4 * t));
			BlockRead(WDir^.WadFile,TexPos,4);
			Seek(WDir^.WadFile, TexStart + TexPos);
			Temp:=NewStr(FillStr(#00, 8));
			BlockRead(WDir^.WadFile, Temp^[1], 8);
			WallTextures^.Insert(Temp);
		end;
		{Check for TEXTURES2 entry (Registered DOOM 1 Only)}
		p:=WDir^.FindObject('TEXTURE2');
		if p >= 0 then begin
			TexStart:=WDir^.EntryPos(p);
			WDir^.SeekEntry(p);
			BlockRead(WDir^.WadFile, NumTex, 4);
			WallTextures:=New(PStringCollection, Init(NumTex, 5));
			for t:=1 to NumTex do begin
				Seek(WDir^.WadFile, TexStart + (4 * t));
				BlockRead(WDir^.WadFile,TexPos,4);
				Seek(WDir^.WadFile, TexStart + TexPos);
				Temp:=NewStr(FillStr(#00, 8));
				BlockRead(WDir^.WadFile, Temp^[1], 8);
			end;
		end;
		{Load Floor / Ceiling Textures}
		FStart:=WDir^.FindObject('F_START');
		if FStart < 0 then
			FloorTextures:=New(PStringCollection, Init(200,5))
		else begin
			FEnd:=WDir^.FindObject('F_END');
			if FEnd < 0 then begin
	         {$IFNDEF WINDOWS}
	         TextMode(CO80);
	         {$ENDIF}
				writeln('LoadTextureList: Missing F_END Entry');
				Halt(1);
			end;
			FloorTextures:=New(PStringCollection, Init(FEnd - FStart, 10));
		end;
		FloorTextures^.Duplicates:=True;
		FStart:=WDir^.FindObject('F1_START');
		if FStart >= 0 then begin
			FEnd:=WDir^.FindObject('F1_END');
			if FEnd < 0 then begin
	         {$IFNDEF WINDOWS}
	         TextMode(CO80);
   	      {$ENDIF}
				writeln('LoadTextureList: Missing F1_END Entry');
				Halt(1);
			end;
			for t:=(FStart + 1) to (FEnd - 1) do begin
				TempStr:=WDir^.EntryName(t);
				Temp:=NewStr(WDir^.EntryName(t)+FillStr(#00, 8 - Length(TempStr)));
				FloorTextures^.Insert(Temp);
			end;
		end;
		{Check for F2_START - Registered DOOM1 and DOOM2}
		FStart:=WDir^.FindObject('F2_START');
		if FStart >= 0 then begin
			FEnd:=WDir^.FindObject('F2_END');
			if FEnd < 0 then begin
	         {$IFNDEF WINDOWS}
	         TextMode(CO80);
   	      {$ENDIF}
				writeln('LoadTextureList: Missing F2_END Entry');
				Halt(1);
			end;
			for t:=(FStart + 1) to (FEnd - 1) do begin
				TempStr:=WDir^.EntryName(t);
				Temp:=NewStr(WDir^.EntryName(t)+FillStr(#00, 8 - Length(TempStr)));
				FloorTextures^.Insert(Temp);
			end;
		end;
		{Check for F3_START - DOOM2 Only}
		FStart:=WDir^.FindObject('F3_START');
		if FStart >= 0 then begin
			FEnd:=WDir^.FindObject('F3_END');
			if FEnd < 0 then begin
	         {$IFNDEF WINDOWS}
	         TextMode(CO80);
   	      {$ENDIF}
				writeln('LoadTextureList: Missing F3_END Entry');
				Halt(1);
			end;
			for t:=(FStart + 1) to (FEnd - 1) do begin
				TempStr:=WDir^.EntryName(t);
				Temp:=NewStr(WDir^.EntryName(t)+FillStr(#00, 8 - Length(TempStr)));
				FloorTextures^.Insert(Temp);
			end;
		end;
		if FloorTextures^.Count = 0 then begin
         {$IFNDEF WINDOWS}
         TextMode(CO80);
         {$ENDIF}
			writeln('LoadTextureList: No floor/ceiling textures found.');
			Halt(1);
		end;
		TempStr:=FillStr(#00, 8);
		TempStr[1]:='-';
		Temp:=NewStr(TempStr);
		WallTextures^.Insert(Temp);
		Temp:=NewStr(TempStr);
		FloorTextures^.Insert(Temp);
	end;

Function GetOppositeSector(Vertexes:PVertexList; LineDefs:PLineDefList; SideDefs:
									PSideDefList; ld1:integer; firstside:Boolean):integer;

	var	x0, y0, dx0, dy0:integer;
			x1, y1, dx1, dy1:integer;
			x2, y2, dx2, dy2:integer;
			v1, v2: PVertex;
			ld2, dist:integer;
			bestld, bestdist, bestmdist:integer;

	begin
		{get the coords for this LineDef}
		x0:=Vertexes^.At(LineDefs^.At(ld1)^.v0)^.x;
		y0:=Vertexes^.At(LineDefs^.At(ld1)^.v0)^.y;
		dx0:=Vertexes^.At(LineDefs^.At(ld1)^.v1)^.x - x0;
		dy0:=Vertexes^.At(LineDefs^.At(ld1)^.v1)^.y - y0;

		{find the normal vector for this LineDef}
		x1:=(dx0 + x0 + x0) div 2;
		y1:=(dy0 + y0 + y0) div 2;

		if firstside then begin
		  dx1:=dy0;
		  dy1:=-dx0;
		end else begin
		  dx1:=-dy0;
		  dy1:=dx0;
		end;

		bestld:=-1;
		{use a parallel to an axis instead of the normal vector (faster method)}
		if abs(dy1) > abs(dx1) then begin
			if dy1 > 0 then begin
			{get the nearest LineDef in that direction (increasing Y's: North)}
				bestdist:=32767;
				bestmdist:=32767;
				for ld2:=0 to (LineDefs^.Count - 1) do begin
					v1:=Vertexes^.At(LineDefs^.At(ld2)^.v0);
					v2:=Vertexes^.At(LineDefs^.At(ld2)^.v1);
					if (ld2 <> ld1) and ((v1^.x > x1) <> (v2^.x > x1)) then begin
						 x2:=v1^.x;
						 y2:=v1^.y;
						 dx2:=v2^.x - x2;
						 dy2:=v2^.y - y2;
						 dist:=y2 + longint((x1 - x2)) * longint(dy2) div longint(dx2);
						if (dist > y1) and ((dist < bestdist) or ((dist = bestdist) and
						((y2 + dy2 div 2) < bestmdist))) then begin
							bestld:=ld2;
							bestdist:=dist;
							bestmdist:=y2 + dy2 div 2;
						end;
					end;
				end;
			end else begin
				{get the nearest LineDef in that direction (decreasing Y's: South)}
				bestdist:=-32767;
				bestmdist:=-32767;
				for ld2:=0 to (LineDefs^.Count - 1) do begin
					v1:=Vertexes^.At(LineDefs^.At(ld2)^.v0);
					v2:=Vertexes^.At(LineDefs^.At(ld2)^.v1);
					if (ld2 <> ld1) and ((v1^.x > x1) <> (v2^.x > x1)) then begin
						x2:=v1^.x;
						y2:=v1^.y;
						dx2:=v2^.x - x2;
						dy2:=v2^.y - y2;
						dist:=y2 + longint(x1 - x2) * longint(dy2) div dx2;
						if (dist < y1) and ((dist > bestdist) or ((dist = bestdist) and
						((y2 + dy2 div 2) > bestmdist))) then begin
							bestld:=ld2;
							bestdist:=dist;
							bestmdist:=y2 + dy2 div 2;
						end;
					end;
				end;
			end;
		end else begin
			if dx1 > 0 then begin
				{get the nearest LineDef in that direction (increasing X's: East)}
				bestdist:=32767;
				bestmdist:=32767;
				for ld2:=0 to (LineDefs^.Count - 1) do begin
					v1:=Vertexes^.At(LineDefs^.At(ld2)^.v0);
					v2:=Vertexes^.At(LineDefs^.At(ld2)^.v1);
					if (ld2 <> ld1) and ((v1^.y > y1) <> (v2^.y > y1)) then begin
						x2:=v1^.x;
						y2:=v1^.y;
						dx2:=v2^.x - x2;
						dy2:=v2^.y - y2;
						dist:=x2 + longint(y1 - y2) * longint(dx2) div longint(dy2);
						if (dist > x1) and ((dist < bestdist) or ((dist = bestdist) and
						((x2 + dx2 div 2) < bestmdist))) then begin
							bestld:=ld2;
							bestdist:=dist;
							bestmdist:=x2 + dx2 div 2;
						end;
					end;
				end;
			end else begin
				{get the nearest LineDef in that direction (decreasing X's: West)}
				bestdist:=-32767;
				bestmdist:=-32767;
				for ld2:= 0 to (LineDefs^.Count - 1) do begin
					v1:=Vertexes^.At(LineDefs^.At(ld2)^.v0);
					v2:=Vertexes^.At(LineDefs^.At(ld2)^.v1);
					if (ld2 <> ld1) and ((v1^.y > y1) <> (v2^.y > y1)) then begin
						x2:=v1^.x;
						y2:=v1^.y;
						dx2:=v2^.x - x2;
						dy2:=v2^.y - y2;
						dist:=x2 + longint(y1 - y2) * longint(dx2) div longint(dy2);
						if (dist < x1) and ((dist > bestdist) or ((dist = bestdist) and
						((x2 + dx2 div 2) > bestmdist))) then begin
							bestld:=ld2;
							bestdist:=dist;
							bestmdist:=x2 + dx2 div 2;
						end;
					end;
				end;
			end;
		end;
		{no intersection: the LineDef was pointing outwards!}
		if bestld < 0 then begin
			GetOppositeSector:=-1;
			exit;
		end;

		{now look if this LineDef has a SideDef bound to one sector}
		if abs(dy1) > abs(dx1) then begin
			if ((Vertexes^.At(LineDefs^.At(bestld)^.v0)^.x <
			Vertexes^.At(LineDefs^.At(bestld)^.v1)^.x) = (dy1 > 0)) then
				x0:=LineDefs^.At(bestld)^.sidedef0
			else
				x0:=LineDefs^.At(bestld)^.sidedef1;
		end else begin
			if ((Vertexes^.At(LineDefs^.At(bestld)^.v0)^.y <
			Vertexes^.At(LineDefs^.At(bestld)^.v1)^.y) <> (dx1 > 0)) then
				x0:=LineDefs^.At(bestld)^.sidedef0
			else
				x0:=LineDefs^.At(bestld)^.sidedef1;
		end;
		{there is no SideDef on this side of the LineDef!}
		if x0 < 0 then begin
			GetOppositeSector:=-1;
			exit;
		end;

		{OK, we got it -- return the Sector number}
		GetOppositeSector:=SideDefs^.at(x0)^.sector;
	end;

Procedure GetMapBounds(var M:TMapBounds; V:PVertexList; L:PLineDefList);

	var	t:integer;
			v1,v2:PVertex;
			ld:PLineDef;

	begin
		with M do begin
			MinX:=32767;
			MinY:=32767;
			MaxX:=-32768;
			MaxY:=-32768;
			for t:=0 to (L^.Count - 1) do begin
				ld:=L^.At(t);
				v1:=V^.At(ld^.v1);
				v2:=V^.At(ld^.v1);
				if v1^.x < minx then minx:=v1^.x;
				if v1^.x > maxx then maxx:=v1^.x;
				if v1^.y < miny then miny:=v1^.y;
				if v1^.y > maxy then maxy:=v1^.y;
				if v2^.x < minx then minx:=v2^.x;
				if v2^.x > maxx then maxx:=v2^.x;
				if v2^.y < miny then miny:=v2^.y;
				if v2^.y > maxy then maxy:=v2^.y;
			end;
		end;
	end;

Procedure GetMapSize(var M:TMapSize; V:PVertexList; L:PLineDefList);

	var	Temp:TMapBounds;

	begin
		GetMapBounds(Temp, V, L);
		M.OrgX:=Temp.MinX;
		M.OrgY:=Temp.MinY;
		M.SizeX:=Abs(Temp.MinX) + Abs(Temp.MaxX);
		M.SizeY:=Abs(Temp.MinY) + Abs(Temp.MaxY);
	end;

end.