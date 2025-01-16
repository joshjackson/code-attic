unit BSPGlobals;

interface

{$IFNDEF WINDOWS}
uses Wads,MapEntries,crt,timer;
{$ELSE}
uses Wads,MapEntries,wincrt,timer;
{$ENDIF}

const	Expand		:boolean	=	False;
		LevelsOnly  :boolean	=	False;
      Optimal		:boolean =  False;
      Flip			:boolean	=	False;
      BuildBSP		:boolean	=	True;
		Pacifist		:boolean	=	False;

{Map Data}
var	LevelName	:ObjNameStr;

var	Vertices:TVertexList;
		LineDefs:PLineDefList;
      Segs:PSegList;
      PSegs:PSegList;
      SideDefs:PSideDefList;
      SSectors:PSSectorList;
      Things:PThingList;
      Sectors:PSectorList;
      NodeList:PNodeList;

		node_x,node_y,node_dx,node_dy:integer;
		lminx,lmaxx,lminy,lmaxy:integer;
		mapminx,mapmaxx,mapminy,mapmaxy:integer;

		psx,psy,pex,pey,pdx,pdy:longint;
		lsx,lsy,lex,ley:longint;

      num_nodes:longint;

type	PBSPNode=^TBSPNode;
		TBSPNode=Record
			x, y		:integer;
			dx, dy	:integer;
   		maxy1,miny1,minx1,maxx1:integer;		{bounding rectangle 1}
   		maxy2,miny2,minx2,maxx2:integer;		{bounding rectangle 2}
   		chright,chleft:word;						{Node or SSector (if high bit is set)}
			nextr,nextl:PBSPNode;
			node_num	:integer;						{starting at 0 (but reversed when done)}
		end;
      TSplitter=Record
      	halfx,
			halfy,
			halfsx,
			halfsy:	integer;
      end;
      bool=wordbool;

var	sp:TSplitter;

const	rootnode:PBSPNode = Nil;

Procedure ProgError(s:string);
Procedure FindLimits(ts:PSegList);
Function SplitDist(ts:PSeg):longint;
Procedure Progress;

implementation

Procedure ProgError(s:String);

	begin
   	gotoxy(1,22);
   	write(s);
      clreol;
      writeln;
      halt;
   end;

Procedure FindLimits(ts:PSegList);

	var 	minx,miny,maxx,maxy:longint;
   		t:integer;
         v0,v1:integer;

   begin
		minx:=32767;
		maxx:=-32767;
		miny:=32767;
		maxy:=-32767;
      for t:=0 to ts^.Count -1 do begin
			v0:=ts^.At(t)^.v0;
			v1:=ts^.At(t)^.v1;
			if(vertices.At(v0)^.x < minx) then minx:=vertices.At(v0)^.x;
			if(vertices.At(v0)^.x > maxx) then maxx:=vertices.At(v0)^.x;
			if(vertices.At(v0)^.y < miny) then miny:=vertices.At(v0)^.y;
			if(vertices.At(v0)^.y > maxy) then maxy:=vertices.At(v0)^.y;
			if(vertices.At(v1)^.x < minx) then minx:=vertices.At(v1)^.x;
			if(vertices.At(v1)^.x > maxx) then maxx:=vertices.At(v1)^.x;
			if(vertices.At(v1)^.y < miny) then miny:=vertices.At(v1)^.y;
			if(vertices.At(v1)^.y > maxy) then maxy:=vertices.At(v1)^.y;
      end;
		lminx:=minx;
		lmaxx:=maxx;
		lminy:=miny;
		lmaxy:=maxy;
   end;

Function SplitDist(ts:PSeg):longint;

	var t,dx,dy:real;

   begin
		if ts^.SideDef=0 then begin
	      dx:=vertices.At(linedefs^.At(ts^.linedef)^.v0)^.x-vertices.At(ts^.v0)^.x;
			dy:=vertices.At(linedefs^.At(ts^.linedef)^.v0)^.y-vertices.At(ts^.v0)^.y;

			if (dx=0) and (dy=0) then writeln('Failed SplitDist 0,0');
			t:=sqrt((dx*dx) + (dy*dy));
	      SplitDist:=Round(t);
	   	exit;
		end else begin
			dx:=vertices.At(linedefs^.At(ts^.linedef)^.v1)^.x-vertices.At(ts^.v0)^.x;
			dy:=vertices.At(linedefs^.At(ts^.linedef)^.v1)^.y-vertices.At(ts^.v0)^.y;
			if (dx=0) and (dy=0) then writeln('Failed SplitDist 0,0');
			t:=sqrt((dx*dx) + (dy*dy));
	      SplitDist:=Round(t);
	   	exit;
		end;
	end;

const oldtick:longint = 0;

Procedure Progress;

	var r:real;

	begin
      if (TimerTicks <> oldtick) then begin
	   	gotoxy(18,17);
         r:=TimerTicks / 18.2;
         writeln(r:3:1);
         oldtick:=timerticks;
      end;
   end;

begin
	InitTimer;
end.