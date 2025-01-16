unit effects;

interface

Function ExpansionValid(e:integer):boolean;
Procedure ExpandLevel;
Procedure FlipLevel;

implementation

uses	crt, BSPGlobals;

(******************************************************************************
	ROUTINE:	ExpansionValid  Returns TRUE if level can be expanded by a factor
            of e.  NOTE: set e=1 to ensure level can be processed at all.
******************************************************************************)
Function ExpansionValid(e:integer):boolean;

	var x0,x1,y0,y1:longint;

   begin
     	x0:=lminx * e;
      x1:=lmaxx * e;
      y0:=lminy * e;
      y1:=lmaxy * e;
      if (x0 < -32768) or (x1 > MAXINT) or (y0 < -32768) or (y1 > MAXINT) then begin
      	ExpansionValid:=False;
         exit;
      end;
      x0:=(x1 - x0 + 1) div 128;
      y0:=(y1 - y0 + 1) div 128;
      if (x0 * y0) > 16379 then
      	ExpansionValid:=False;
   end;

(******************************************************************************
	ROUTINE:	ExpandLevel  Increases a level's size by 200%
******************************************************************************)
Procedure ExpandLevel;

	var	t:integer;
   		xofs,yofs:integer;

	begin
   	gotoxy(1,25);
      write('Expanding level...');
      clreol;
      FindLimits(Segs);
      xofs:=(lmaxx - lminx) div 2;
		yofs:=(lmaxx - lminy) div 2;
      for t:=0 to Vertices.count - 1 do begin
      	Vertices.At(t)^.x:=Vertices.At(t)^.x * 2;
			Vertices.At(t)^.y:=Vertices.At(t)^.y * 2;
      end;
      for t:=0 to Things^.count - 1 do begin
      	Things^.At(t)^.x:=Things^.At(t)^.x * 2;
			Things^.At(t)^.y:=Things^.At(t)^.y * 2;
      end;
   end;

(******************************************************************************
	ROUTINE:	FlipLevel  Flips map around Y axis
******************************************************************************)
Procedure FlipLevel;

	var	tang:integer;
   		temp,i:integer;

	begin
   	for i:=0 to things^.Count - 1 do    {negate X coordinate}
	    	things^.At(i)^.x:=-1 * things^.At(i)^.x;
      for i:=0 to vertices.Count - 1 do   {negate X coordinate}
	    	vertices.At(i)^.x:=-1 * vertices.At(i)^.x;
	  	for i:=0 to LineDefs^.Count -1 do begin	{swap from and to vertices}
	    	temp:=LineDefs^.At(i)^.v0;
	    	linedefs^.At(i)^.v0:=LineDefs^.At(i)^.v1;
	    	LineDefs^.At(i)^.v1:=temp;
  		end;
	  		for i:=0 to NodeList^.Count - 1 do begin
	    		NodeList^.At(i)^.x0:=-1 * NodeList^.At(i)^.x0;		{negate X coordinate}
	    		NodeList^.At(i)^.dx:=-1 * NodeList^.At(i)^.dx;		{negate X offset}
	    		temp:=-1 * NodeList^.At(i)^.rbox.x1;						{swap right and left}
	    		NodeList^.At(i)^.rbox.x1:=-1 * NodeList^.At(i)^.lbox.x0;{bounding box X}
	    		NodeList^.At(i)^.lbox.x0:=temp;							{coordinates: min for}
	    		temp:=-1 * NodeList^.At(i)^.rbox.x0;								{max and negate}
   	 		NodeList^.At(i)^.rbox.x0:=-1 * NodeList^.At(i)^.lbox.x1;
		 		NodeList^.At(i)^.lbox.x1:=temp;
	    		temp:=NodeList^.At(i)^.rbox.y1;								{swap right and left}
	    		NodeList^.At(i)^.rbox.y1:=NodeList^.At(i)^.lbox.y1;	{bounding box Y}
	    		NodeList^.At(i)^.lbox.y1:=temp;							{min/max coordinates}
	    		temp:=NodeList^.At(i)^.rbox.y0;
	    		NodeList^.At(i)^.rbox.y0:=NodeList^.At(i)^.lbox.y0;
	    		NodeList^.At(i)^.lbox.y0:=temp;
	    		temp:=NodeList^.At(i)^.rchild;								{swap node subtrees}
	    		NodeList^.At(i)^.rchild:=NodeList^.At(i)^.lchild;
	    		NodeList^.At(i)^.lchild:=temp;
	  		end;
	  		for i:=0 to PSegs^.Count-1 do begin
	    		temp:=PSegs^.At(i)^.v1;									{swap from and to vertices}
	    		PSegs^.At(i)^.v1:=PSegs^.At(i)^.v0;
	    		PSegs^.At(i)^.v0:=temp;
	    		tang:=-integer(PSegs^.At(i)^.angle);								{negate angle}
	    		PSegs^.At(i)^.angle:=word(tang);
	  		end;
   end;

end.