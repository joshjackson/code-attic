{- PICKNODE.PAS ------------------------------------------------------------*
 To be able to divide the nodes down, this routine must decide which is the
 best Seg to use as a nodeline. It does this by selecting the line with least
 splits and has least difference of Segs on either side of it.
*---------------------------------------------------------------------------*}
unit PickNodes;

interface

uses CStuff,MapEntries,BSPGlobals;

Function PickNode(ts:PSegList):PSeg;
Function DoLinesIntersect:integer;
Procedure ComputeIntersection(var outx,outy:integer);

implementation

Function PickNode(ts:PSegList):PSeg;

	var   s1,s2:integer;
			num_splits,num_left,num_right:integer;
			min_splits,min_diff,ival:integer;
			part,check,best:PSeg;
			max,new,grade,bestgrade,seg_count:integer;
         skipval:integer;
         InResearch:boolean;

	begin
		min_splits:=32767;
		min_diff:=32767;
		best:=ts^.At(0);                    {Set best to first (failsafe measure)}
		grade:=0;
		BestGrade:=32767;

      if not Optimal then
	      SkipVal:=ts^.count div 40
      else
      	SkipVal:=1;
      if SkipVal = 0 then
	     	SkipVal:=1;
      InResearch:=False;

      repeat
	      s1:=0;
	      while (s1 < ts^.count) do begin {Use each Seg as partition}
				progress;                        {/* Something for the user to look at.*/}
				part:=ts^.At(s1);
				psx:=vertices.At(part^.v0)^.x;  {Calculate this here, cos it doesn't}
				psy:=vertices.At(part^.v0)^.y;  {change for all the interations of}
				pex:=vertices.At(part^.v1)^.x;  {the inner loop!}
				pey:=vertices.At(part^.v1)^.y;

				pdx:=psx-pex;              {Partition line DX,DY}
				pdy:=psy-pey;

				num_splits:=0;
				num_left:=0;
				num_right:=0;

				seg_count:=0;

	         s2:=0;
	         while (s2 < ts^.Count) do begin {Check partition against all Segs}
					check:=ts^.At(s2);
					Inc(seg_count);
					if s1 = s2 then
						Inc(num_right)                   {If same as partition, inc right count}
					else begin
						lsx:=vertices.At(check^.v0)^.x; {Calculate this here, cos it doesn't}
						lsy:=vertices.At(check^.v0)^.y; {change for all the interations of}
						lex:=vertices.At(check^.v1)^.x; {the inner loop!}
						ley:=vertices.At(check^.v1)^.y;
						ival:=DoLinesIntersect;          {get state of lines relation to each other}
						if ((ival and 64) > 0) and ((ival and 2) > 0) or
							((ival and 32) > 0) and ((ival and 4) > 0) then begin
							Inc(num_splits);                 {If line is split, inc splits}
							Inc(num_left);                   {and add one line into both}
							Inc(num_right);                  {sides}
						end else begin
							if ((ival and 1) > 0) and ((ival and 16) > 0) then begin {If line is totally in same}
																	{direction}
								if(check^.SideDef=part^.SideDef) then
									Inc(num_right)
								else
									Inc(num_left);          {add to side according to flip}
							end else begin                {So, now decide which side}
																	{the line is on}
								if(ival and 34) > 0 then Inc(num_left);   {and inc the appropriate}
								if(ival and 68) > 0 then Inc(num_right);{count}
							end;
						end;
					end;

	         	inc(s2);
				end;


	         if(num_right > 0) and (num_left > 0) then begin {Make sure at least one Seg is}
																			{on either side of the partition}
					max:=LMax(num_right,num_left);
					new:=(num_right + num_left) - seg_count;
					grade:=max + new * 8;

					if(grade < bestgrade) then begin
						bestgrade:=grade;
						best:=part;                   {and remember which Seg}
					end;

	      	end;
   	      if InResearch then
	           	Inc(s1)
	         else
	           	Inc(s1,SkipVal);
			end;
	      if Best = Nil then begin
	      	if InResearch or Optimal then begin
            	Best:=ts^.At(0);
               Break;
            end;
	      	InResearch:=True;
	      end;
      until not InResearch;
		PickNode:=Best;
	end;

{---------------------------------------------------------------------------*
 Because this is used a horrendous amount of times in the inner loops, the
 coordinate of the lines are setup outside of the routine in global variables
 psx,psy,pex,pey = partition line coordinates
 lsx,lsy,lex,ley = checking line coordinates
 The routine returns 'val' which has 3 bits assigned to the the start and 3
 to the end. These allow a decent evaluation of the lines state.
 bit 0,1,2 = checking lines starting point and bits 4,5,6 = end point
 these bits mean  0,4 = point is on the same line
						1,5 = point is to the left of the line
						2,6 = point is to the right of the line
 There are some failsafes in here, these mainly check for small errors in the
 side checker.
*---------------------------------------------------------------------------*}

Function DoLinesIntersect:integer;

	var   x,y:integer;
			ival:integer;
			dx2,dy2,dx3,dy3,a,b,l:longint;

	begin
		ival:=0;
		dx2:=psx - lsx;         {Checking line -> partition}
		dy2:=psy - lsy;
		dx3:=psx - lex;
		dy3:=psy - ley;

		a:=pdy*dx2 - pdx*dy2;
		b:=pdy*dx3 - pdx*dy3;

		if((a<0) and (b>0)) or ((a>0) and (b<0)) then begin   {Line is split, just check that}
			ComputeIntersection(x,y);
			dx2:=lsx - x;                          {Find distance from line start}
			dy2:=lsy - y;                          {to split point}
			if(dx2=0) and (dy2=0) then
				a:=0
			else begin
				l:=Round(sqrt((dx2*dx2)+(dy2*dy2)));   {If either ends of the split}
				if(l < 2) then a:=0;                   {are smaller than 2 pixs then}
			end;                                   {assume this starts on part line}
			dx3:=lex - x;                          {Find distance from line end}
			dy3:=ley - y;                          {to split point}
			if(dx3=0) and (dy3=0) then
				b:=0
			else begin
				l:=Round(sqrt((dx3*dx3)+(dy3*dy3)));      {same as start of line}
				if(l < 2) then b:=0;
			end;
		end;
		if(a = 0) then ival:=ival or 16;          {start is on middle}
		if(a < 0) then ival:=ival or 32;          {start is on left side}
		if(a > 0) then ival:=ival or 64;          {start is on right side}

		if(b = 0) then ival:=ival or 1;           {end is on middle}
		if(b < 0) then ival:=ival or 2;           {end is on left side}
		if(b > 0) then ival:=ival or 4;           {end is on right side}

		DoLinesIntersect:=ival;
	end;

{---------------------------------------------------------------------------*
 Calculate the point of intersection of two lines. ps?->pe? & ls?->le?
 returns int xcoord, int ycoord
*---------------------------------------------------------------------------*}

Procedure ComputeIntersection(var outx,outy:integer);

	var   a,b,a2,b2,l,l2,w,d,z:real;
			dx,dy,dx2,dy2:longint;

	begin
		dx:=pex - psx;
		dy:=pey - psy;
		dx2:=lex - lsx;
		dy2:=ley - lsy;

		if(dx = 0) and (dy = 0) then
			ProgError('Failed ComputeIntersection dx,dy');
		l:=Round(sqrt((dx*dx) + (dy*dy)));
		if(dx2 = 0) and (dy2 = 0) then
			ProgError('Failed ComputeIntersection dx2,dy2');
		l2:=Round(sqrt((dx2*dx2) + (dy2*dy2)));

		a:=dx / l;
		b:=dy / l;
		a2:=dx2 / l2;
		b2:=dy2 / l2;
		d:=b * a2 - a * b2;
		w:=lsx;
		z:=lsy;
		if(d <> 0.0) then begin
			w:=(((a*(lsy-psy))+(b*(psx-lsx))) / d);
			{printf("Intersection at (%f,%f)\n",x2+(a2*w),y2+(b2*w));}
			a:=lsx+(a2*w);
			b:=lsy+(b2*w);
			if a < 0 then
				a:=a - 0.5
			else
				a:=a + 0.5;
			if b < 0 then
				b:=b - 0.5
			else
				b:=b + 0.5;
		end;
		outx:=Trunc(a);
		outy:=Trunc(b);
	end;

end.
