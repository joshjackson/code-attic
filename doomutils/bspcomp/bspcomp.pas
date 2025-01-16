uses 	Wads, Mapentries, PickNodes, MakeNode, BSPGlobals, WadFile, Blockmap,
		effects,
{$IFNDEF WINDOWS}
	crt,Memory;
{$ELSE}
	wincrt,OMemory,Strings;
{$ENDIF}

{initially creates all segs, one for each line def}
Function CreateSegs:PSegList;

	var 	n,fv,tv:integer;
			dx,dy:longint;
         cs:PSegList;
         ts:PSeg;

   begin
	   cs:=New(PSegList, Init(200,50));
      {step through linedefs and get side numbers}
		for n:=0 to LineDefs^.Count - 1	do begin
			fv:=linedefs^.At(n)^.v0;
			tv:=linedefs^.At(n)^.v1;
			{create normal seg}
			if LineDefs^.At(n)^.sidedef0 <> -1 then begin
				new(ts);
				ts^.v0:=fv;
				ts^.v1:=tv;
				dx:= vertices.At(tv)^.x - vertices.At(fv)^.x;
				dy:= vertices.At(tv)^.y - vertices.At(fv)^.y;
				ts^.angle:=ComputeAngle(dx,dy);
				ts^.linedef:=n;
				ts^.lineofs:=0;
				ts^.SideDef:=0;
            cs^.Insert(ts);
			end;

         {create flipped seg}
			if linedefs^.At(n)^.sidedef1 <> -1 then begin
				New(ts);
				ts^.v0:=tv;
				ts^.v1:=fv;
				dx:=vertices.At(fv)^.x-vertices.At(tv)^.x;
				dy:=vertices.At(fv)^.y-vertices.At(tv)^.y;
				ts^.angle:=ComputeAngle(dx,dy);
				ts^.linedef:=n;
				ts^.LineOfs:=0;
				ts^.SideDef:=1;
            cs^.Insert(ts);
			end;
      end;
		CreateSegs:=cs;
	end;

Procedure ReverseNodes(tn:PBSPNode);

	var	Pnodes:PNode;

	begin
      new(PNodes);
		if (tn^.chright and $8000) = 0 then begin
			ReverseNodes(tn^.nextr);
			tn^.chright:=tn^.nextr^.node_num;
      end;
		if (tn^.chleft and $8000) = 0 then begin
			ReverseNodes(tn^.nextl);
			tn^.chleft:=tn^.nextl^.node_num;
      end;
		pnodes^.x0:=tn^.x;
		pnodes^.y0:=tn^.y;
		pnodes^.dx:=tn^.dx;
		pnodes^.dy:=tn^.dy;
		pnodes^.rbox.y0:=tn^.miny1;
		pnodes^.rbox.y1:=tn^.maxy1;
		pnodes^.rbox.x0:=tn^.minx1;
		pnodes^.rbox.x1:=tn^.maxx1;
		pnodes^.lbox.y0:=tn^.miny2;
		pnodes^.lbox.y1:=tn^.maxy2;
		pnodes^.lbox.x0:=tn^.minx2;
		pnodes^.lbox.x1:=tn^.maxx2;
		pnodes^.rchild:=tn^.chright;
		pnodes^.lchild:=tn^.chleft;
      nodelist^.Insert(pnodes);
		tn^.node_num:=nodelist^.count - 1;
   end;

Procedure DisposeNodes(var bnode:PBSPNode);

	Procedure DisposeNode(var node:PBSPNode);

   	begin
	   	if node <> Nil then begin
		      if node^.nextr <> Nil then begin
		      	DisposeNode(node^.nextr);
               Dispose(node^.nextr);
            end;
		   	if node^.nextl <> Nil then begin
		      	DisposeNode(node^.nextl);
               Dispose(node^.nextl);
            end;
	      end;
      end;

	begin
   	if bnode^.nextl <> Nil then
      	DisposeNodes(bnode^.nextl);
      if bnode^.nextr <> Nil then
      	DisposeNodes(bnode^.nextr);
      Dispose(bNode);
   end;

Function IsLevelName(n:ObjNameStr):boolean;

	Function IsNumeric(c:char):boolean;

   	begin
      	if (c < '0') or (c > '9') then
         	IsNumeric:=False
         else
         	IsNumeric:=True
      end;

	begin
		if (n[1]= 'E') and (n[3]='M') and (n[5]=#00) then
      	IsLevelName:=True
		else if (pos('MAP', n) = 1) and (n[6]=#00) and IsNumeric(n[4]) and
			IsNumeric(n[5]) then
			IsLevelName:=True
		else
			IsLevelName:=False;
   end;

Procedure PreProcessLevel(tv:PVertexList);

	type	TBoolArray=Array[0..65519] of boolean;

	var	VBuff:^TBoolArray;
   		t:integer;
         tmpv:PVertex;

   begin
   	VBuff:=MemAllocSeg(tv^.Count);
      if VBuff=Nil then
      	ProgError('Failed PreProcessLevel: Insufficient Memory');
      for t:=0 to LineDefs^.Count - 1 do begin
         if (t and 15) = 0 then
		   	Progress;
			VBuff^[LineDefs^.At(t)^.v0]:=True;
			VBuff^[LineDefs^.At(t)^.v1]:=True;
      end;
      for t:=0 to tv^.Count - 1 do begin
      	if VBuff^[t] then begin
         	new(tmpv);
            tmpv^:=tv^.At(t)^;
		      vertices.Insert(tmpv);
			end;
      end;
      FreeMem(VBuff, tv^.Count);
   end;

Procedure ClearStatus;

	var t:integer;

	begin
   	for t:=6 to 13 do begin
      	gotoxy(18,t);
         clreol;
      end;
      gotoxy(1,22);
      clreol;
   end;

var	WDir:PWadDirectory;
		OutputWad:POutputWad;
      PBlockMap:PBlockList;
		Outwad,TestWad:String[80];
      {$IFDEF WINDOWS}
      TextAttr:integer;
      {$ENDIF}

Procedure ExecuteBSP;

	var	lp,n,x,t:integer;
   		vu:boolean;
         tv:PVertexList;
         Reject_size:word;
         RejectBuff:pointer;
         bms:longint;
         on:ObjNameStr;

	begin
	   TextAttr:=15;
	   writeln;
	   writeln('Input Wad File : ', testwad);
	   writeln('Output Wad File: ', outwad);
	   writeln;
	   writeln('Level          : ');
	   writeln('Vertices       : ');
	   writeln('LineDefs       : ');
	   writeln('SideDefs       : ');
	   writeln('Sectors        : ');
	   writeln('Segs           : ');
	   writeln('SSectors       : ');
	   writeln('Nodes          : ');
	   writeln;
		if Expand or LevelsOnly or Optimal then begin
	     	write('Options:       : ');
         if Optimal then write('Optimal, ');
	      if Expand then write('Expand, ');
         if Flip then write('Flip, ');
         if Pacifist then write('Pacifist, ');
	      if LevelsOnly then write('Levels Only');
	      if LevelName <> '' then write(': ',LevelName);
	      writeln;
	   end else
		   writeln;
	   writeln('Memory         : ');
	   writeln('Elapsed time   : ');

	   TextAttr:=14;
	   gotoxy(18,16);
	   write(MemAvail);
		clreol;

	   {Opens and reads directory}
		WDir:=New(PWadDirectory, Init(testwad));
	   OutputWad:=New(POutputWad, Init(outwad));
	   for t:=0 to WDir^.Count - 1 do begin
			on:=WDir^.EntryName(t);
         if (not IsLevelName(on)) and (not LevelsOnly) then begin
         	gotoxy(1,25);
            write('Adding resource: ',WDir^.EntryName(t));
				OutputWad^.AddFromWad(WDir, t);
            Continue;
         end;
         if (LevelName <> '') and (WDir^.FindObject(LevelName) <> t) then
         	Continue;
         if Not IsLevelName(on) then
         	Continue;
         lp:=t;
	   	ClearStatus;
		   gotoxy(18,16);
		   write(MemAvail);
		   gotoxy(18,6);
		   writeln(WDir^.EntryName(lp));
			InitMapData(Wdir, lp, Things, LineDefs, SideDefs, tv, Sectors);
		   vertices.init(tv^.Count, 30);
		   gotoxy(1,25);
		   write('Preprocessing Level...');
		   Clreol;
	      {Clear unused vertices}
         PreProcessLevel(tv);
		   Dispose(tv, done);
		   gotoxy(18, 7);
		   write(vertices.Count);
	      clreol;

		   gotoxy(1,25);
		   write('Creating Segs...');
		   clreol;
	      {Create initial segs}
			segs:=CreateSegs;
		   gotoxy(18,10);
		   write(Sectors^.Count);
	      clreol;
		   gotoxy(18,9);
		   write(SideDefs^.Count);
	      clreol;
		   gotoxy(18,8);
		   write(LineDefs^.Count);
	      clreol;
	      {Find limits of vertices}
			FindLimits(segs);
	      {store as map limits}
			mapminx:=lminx;
			mapmaxx:=lmaxx;
			mapminy:=lminy;
			mapmaxy:=lmaxy;

	      {If requested, expand the level to twice its original size}
	      if Expand then begin
         	gotoxy(1,25);
            write('Expanding Level...');
            clreol;
	      	if not ExpansionValid(2) then begin
	         	gotoxy(1,22);
	            write('>>This level is too large to expand, it will remain unchanged!<<');
	         end else begin
	         	ExpandLevel;
               {Reset level limits}
					FindLimits(segs);
					mapminx:=lminx;
					mapmaxx:=lmaxx;
					mapminy:=lminy;
					mapmaxy:=lmaxy;
            end;
	      end else
	      	if not ExpansionValid(1) then
		      	ProgError('Level is to large to process... aborting.');

		   gotoxy(1,25);
			write('Building BSP...');
		   clreol;
	      {recursively create nodes}
			psegs:=New(PSegList, Init(200, 50));
			ssectors:=New(PSSectorList, Init(100, 50));
	      num_nodes:=0;
			rootnode:=CreateNode(segs);

	      {Reverse Node list and store in NodeList}
			nodelist:=New(PNodeList, Init(num_nodes,20));
			ReverseNodes(rootnode);

         if Flip then begin
			   gotoxy(1,25);
			   write('Flipping Level...');
			   Clreol;
            FlipLevel;
         end;

		   DisposeNodes(rootnode);

		   gotoxy(1,25);
		   write('Outputting WAD file...');
		   clreol;

	      OutputWad^.AddName(WDir^.EntryName(lp));
	      OutputWad^.AddCollection(Things, 'THINGS', Sizeof(TThing));
			OutputWad^.AddCollection(LineDefs, 'LINEDEFS', Sizeof(TLineDef));
	      OutputWad^.AddCollection(SideDefs, 'SIDEDEFS', Sizeof(TSideDef));
	      OutputWad^.AddCollection(@Vertices, 'VERTEXES', Sizeof(TVertex));
	      OutputWad^.AddCollection(PSegs, 'SEGS', Sizeof(TSeg));
	      OutputWad^.AddCollection(SSectors, 'SSECTORS', Sizeof(TSSector));
	      OutputWad^.AddCollection(NodeList, 'NODES', Sizeof(TNode));
	      OutputWad^.AddCollection(Sectors, 'SECTORS', Sizeof(TSector));

	      {Free up some working room for Reject and BlockMap}
	      Dispose(Things, Done);
	      Dispose(SideDefs, Done);
	      Dispose(PSegs, Done);
	      Dispose(SSectors, Done);
	      Dispose(NodeList, Done);

			{Create a "blank" reject field}
	      Reject_size:=Word(Sqr(Longint(Sectors^.Count) + 7) div 8);
	      RejectBuff:=MemAllocSeg(Reject_size);
	      if RejectBuff = Nil then
	      	ProgError('Failed MemAllocSeg: Insufficient Memory.');
         if Pacifist then
		      FillChar(RejectBuff^, Reject_size, #255)
         else
		      FillChar(RejectBuff^, Reject_size, #00);
	      OutputWad^.AddBuff(RejectBuff^, 'REJECT', Reject_size);
	      FreeMem(RejectBuff, Reject_size);

	      Dispose(Sectors, Done);

		   gotoxy(1,25);
		   write('Creating Blockmap...');
	      clreol;
			bms:=CreateBlockmap(PBlockMap);
	      OutputWad^.AddBuff(PBlockMap^, 'BLOCKMAP', bms * 2);
			freemem(PBlockMap, 65520);

		   gotoxy(1,25);
		   write('Outputting WAD file...');
		   clreol;

		   Vertices.Done;
		   Dispose(LineDefs,Done);
	      {Get next level name (if any)}
	      if LevelName='' then begin
			   lp:=WDir^.FindObjectFrom('E?M?    ', lp+1);
			   if lp=-1 then
			   	lp:=WDir^.FindObjectFrom('MAP??   ', lp+1);
	      end else
	      	lp:=-1;
	      gotoxy(18,16);
	      write(memavail);
	      clreol;
         inc(t, 10);
         if LevelsOnly and (LevelName <> '') then
         	Break;
	   end;
	   {Dispose of Input Wad directory and close file}
	   Dispose(WDir, Done);
	   gotoxy(1,25);
	   write('Writing Wad file Directory...');
	   clreol;
	   Dispose(OutputWad, Done);
	   gotoxy(1,25);
	   write('Complete.');
	   clreol;
	   gotoxy(18,16);
	   writeln(Memavail);
		gotoxy(1,23);
	end;

Procedure ParseCommandLine;

	var	t,x:integer;
   		s:string[80];
         Help:Boolean;

	begin
	   TextAttr:=7;
	   ClrScr;
	   TextAttr:=31;
		writeln(' ** DOOM/DOOM II/Heretic BSP node builder ver 1.0 (c) 1995 Jackson Software ** ');
		if(ParamCount = 0) then begin
	   	TextAttr:=79;
      	writeln;
			writeln(' This Node builder was created from a cross-breed of many others, as well as   ');
         writeln(' many of my personal modifications and enhancements.                           ');
         writeln('                                                                               ');
			writeln(' Credits should go to :                                                        ');
			writeln(' Matt Fell         for the Doom Specs.                                         ');
			writeln(' Raphael Quinet    for DEU and the BSP generation ideas.                       ');
         writeln(' Collin Reed       for BSP12X for its many enhancements to DEU''s code.         ');
         writeln(' Robert Fenske Jr. for the Enhanced Blockmap formula.                          ');
         writeln(' ID Software       for their kick-butt games and releasing their BSP code.     ');
         writeln;
         writeln(' For usage info, use the parameter -h.                                         ');
         writeln('                                                                               ');
         writeln(' Written by: Joshua Jackson                                                    ');
         writeln;
         textattr:=7;
			Halt;
	   end;

      TestWad:='';
      outwad:='';
      LevelName:='';
      Help:=False;

      for t:=1 to ParamCount do begin
         s:=ParamStr(t);
         if (s[1] = '-') or (s[1] = '/') then begin
				case Upcase(s[2]) of
					'E':Expand:=True;
               'L':begin
               	LevelsOnly:=True;
                  if Length(s) > 2 then begin
                     if (Length(s) > 7) and (Length(s) < 6) then begin
                     	Help:=True;
                        Break;
                     end;
                     for x:=3 to Length(s) do
                     	LevelName:=LevelName + s[x];
                  end;
               end;
               'H':Begin
               	Help:=True;
                  Break;
               end;
               'O':Optimal:=True;
               'F':Flip:=True;
               'P':Pacifist:=True;
            	else begin
               	Help:=True;
                  Break;
               end;
            end;
         end else begin
         	if testwad='' then begin
					testwad:=s;
               if pos('.', s) = 0 then
               	testwad:=testwad+'.wad';
            end else if outwad='' then begin
					outwad:=s;
               if pos('.', s) = 0 then
               	outwad:=outwad+'.wad';
				end else begin
            	help:=true;
               break;
            end;
         end;
      end;
      if outwad='' then outwad:='tmp.wad';
      if Help or (testwad = '') then begin
      	TextAttr:=7;
      	writeln;
         writeln('Usage: BSPCOMP {inwad[.wad]} [outwad[.wad]] [-e] [-l[LevName]] [-h]');
         writeln;
         writeln('   inwad       The name of the input Wad file.');
         writeln('   outwad      The name of the output Wad file. (tmp.wad is default)');
         writeln('   -e          Expands input levels to twice their orginal size (if possible)');
         writeln('   -l[LevName] Process levels ONLY. If specified, LevName is the only level');
			writeln('               processed.');
         writeln('   -h          Displays this screen');
         writeln('   -o          Optimal BSP calculations (Takes a lot longer and the benefits');
         writeln('               are usually not noticable. For more info, read the .DOC file.');
         writeln('   -f          Flip map around its Y axis');
         writeln('   -p          Pacifist Monsters (run README for more info.)');
         writeln;
         writeln('Type BSPCOMP alone for credits and program info.');
         halt;
      end;
   end;

begin
   {$IFDEF WINDOWS}
  	strcopy(WindowTitle,'BSPCOMP ver 1.0');
   InitWinCrt;
   {$ENDIF}
   ParseCommandLine;
	ExecuteBSP;
	{$IFDEF WINDOWS}
   DoneWinCrt;
   {$ENDIF}
end.
