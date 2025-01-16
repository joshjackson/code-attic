unit BlockMap;

interface

const	nmax:integer	=	20;

Type	PBlockList=^TBlockList;
		TBlockList=Array[0..32759] of integer;
      PBlockArray=^TBlockArray;
      TBlockArray=Array[0..16380] of PBlockList;

function CreateBlockmap(var BlockMap:PBlockList):longint;

implementation

{$IFNDEF WINDOWS}
uses Memory, BSPGlobals,Crt;
{$ELSE}
uses OMemory, BSPGlobals,WinCrt;
{$ENDIF}

(******************************************************************************
	MODULE:		BLOCKMAP.C
	WRITTEN BY:	Robert Fenske, Jr. (rfenske@swri.edu)
				Southwest Research Institute
				Electromagnetics Division
				6220 Culebra
				San Antonio, Texas 78238-5166
	CREATED:	Feb. 1994
	DESCRIPTION:	This module contains routines to generate the BLOCKMAP
			section.  See the generation routine for an explanation
			of the method used to generate the BLOCKMAP.  The
			optimizations for the horizontal LINEDEF, vertical
			LINEDEF, and single block cases came from ideas
			presented in the Unofficial DOOM Specs written by
			Matt Fell.  The BLOCKMAP packing idea came from Jason
			Hoffoss.

			DOOM is a trademark of id Software, Inc.
******************************************************************************)


Procedure Blockfree(block:PBlockList);

	var	k:integer;

	begin
   	k:=0;
      while(0 <= block^[k]) do Inc(k);
      if block^[k] <> -1 then begin
      	write('Terminator = ',block^[k],' k = ',k);
      	ProgError('Failed CreateBlockmap: Invaild Blocklist Terminator.');
      end;
      FreeMem(block, (k + 1) * 2);
   end;

(******************************************************************************
	ROUTINE:	blockmap_add_line(block,lndx,nlines)
	WRITTEN BY:	Robert Fenske, Jr.
	CREATED:	Feb. 1994
	DESCRIPTION:	This routine adds the LINEDEF lndx to the block's
			block LINEDEF list.  If no list exists yet for the
			block, one is created.  Memory is allocated for no more
			than twelve LINEDEFS (to save memory); only if more
			than twelve LINEDEFS are in a single block is more
			memory allocated.  I chose twelve because a statistical
			analysis of many WADs showed that about 99% of the
			BLOCKMAP blocks contained less than twelve LINEDEFS.
******************************************************************************)
	{local void blockmap_add_line(block,lndx,nlines)}
Procedure blockmap_add_line(var block:PBlockList; lndx:integer);

	var	k:integer;
   		newblock:PBlockList;

	begin
  		if block = nil then begin					(* allocate if no list yet *)
    		block:=MemAlloc(nmax * 2);
	      if block = Nil then
	      	ProgError('Failed CreateBlockmap: Insuffcient memory');
         fillchar(block^, nmax * 2, #00);
	    	block^[nmax-1]:=-1;
	  	end;
	   k:=0;
	   while (0 < block^[k]) do Inc(k); (* seek to end of list *)
	 	if (block^[k] = -1) then begin
	    	newblock:=MemAlloc((k + 1 + nmax) * 2);
	      if newblock = Nil then
	      	ProgError('Failed CreateBlockmap: Insuffcient memory');
	      fillchar(newblock^, (k + 1 + nmax) * 2, #00);
	    	Move(block^, newblock^, (k + 1) * 2);
	      FreeMem(block, (k + 1) * 2);
	    	block:=newblock;
	    	block^[k + nmax]:=-1;
      end;
	  	block^[k]:=lndx + 1;				(* add this LINEDEF *)
	end;

Function sgn(x:longint):integer;

	begin
   	if x < 0 then
      	sgn:=-1
      else if x > 0 then
      	sgn:=1
      else
      	sgn:=0;
   end;

(******************************************************************************
	ROUTINE:	blockmap_make(blockmap,lines,nlines,verts)
	WRITTEN BY:	Robert Fenske, Jr.
	CREATED:	Feb. 1994
	DESCRIPTION:	This routine builds the BLOCKMAP section given the
			LINEDEFS and VERTEXES.  The BLOCKMAP section has the
			following information (all are 16-bit words):

			block grid X origin
			block grid Y origin
			# blocks along X axis (total # blocks --> )
			# blocks along Y axis (N = Xn * Yn        )
			block 0 offset (# words)
			block 1 offset (# words)
				.
				.
			block N-1 offset (# words)
			block 0 data (M words: 0,LINEDEFs in block 0,FFFF)
			block 1 data (M words: 0,LINEDEFs in block 1,FFFF)
				.
				.
			block N-1 data (M words: 0,LINEDEFs in block N-1,FFFF)

			Block 0 is at the lower left, block 1 is to the right
			of block 0 along the x-axis, ..., block N-1 is at the
			upper right.  An N-element pointer array is allocated
			to hold pointers to the list of LINEDEFS in each block.
			If no LINEDEFS occur within a block, it's pointer will
			be NULL.  Then the LINEDEFS are scanned to find the
			blocks each line occupies, building the lists of
			LINEDEFS along the way.  Four cases are considered
			for each LINEDEF.  The line is either diagonal,
			horizontal, vertical, or resides in a single block
			(regardless of orientation).  The non-diagonal cases
			can be optimized since the blocks occupied can be
			directly calculated.  The diagonal case basically
			computes the blocks occupied on each row for all the
			rows between the LINEDEF endpoints.  Once this is
			complete the actual blockmap is allocated and filled.
			It returns the number of words in the blockmap.
	MODIFIED:		Robert Fenske, Jr.	Mar. 1994
			Added in the optimizations for the orthogonal line
			cases using the ideas presented in the Unofficial DOOM
			Specs written by Matt Fell.
				Robert Fenske, Jr.	Feb. 1995
			Added in packing of the map.  All the empty blocks
			reference a single block.  This idea came from
			Jason Hoffoss.
******************************************************************************)
function CreateBlockmap(var BlockMap:PBlockList):longint;
{long blockmap_make(register short **blockmap, register DOOM_LINE *lines,
                   long nlines, DOOM_VERT *verts)}
	var	xmin,ymin,xmax,ymax:integer;			(* map coords min/max *)
  			scl:longint;					(* line following scaling *)
  			size:longint;				(* block size (map coords) *)
  			xorig, yorig:integer;				(* blockmap x,y origin *)
  			xn, yn:integer;					(* # blocks in x,y dirs *)
  			xcc, xcl,
  			xf,yf, xt,yt:longint;
  			xd, yd:longint;					(* x direction, y direction *)
  			m:longint;					(* diagonal line slope *)
  			o, l, k, i:integer;
  			p:integer;					(* increment to next block *)
  			c:integer;					(* # blocks to consider *)
  			boxlist:PBlockArray;			(* array of blocks' lists *)
  			b,t:longint;

	begin
		p:=0;
	   c:=0;
	   size:=$80;
	  	xmin:=32767;
	  	ymin:=32767;
	  	xmax:=-32768;
	  	ymax:=-32768;
	  	for l:=0 to linedefs^.count - 1 do begin		(* find min/max map coords *)
	    	xf:=vertices.At(linedefs^.At(l)^.v0)^.x;
			yf:=vertices.At(linedefs^.At(l)^.v0)^.y;
	    	if (xf < xmin) then xmin:= xf;		(* check from vertex *)
	    	if (yf < ymin) then ymin:= yf;
	    	if (xmax < xf) then xmax:= xf;
	    	if (ymax < yf) then ymax:= yf;
	    	xt:=vertices.At(linedefs^.At(l)^.v1)^.x;
			yt:=vertices.At(linedefs^.At(l)^.v1)^.y;
	    	if (xt < xmin) then xmin:= xt;		(* check to vertex *)
	    	if (yt < ymin) then ymin:= yt;
	    	if (xmax < xt) then xmax:= xt;
	    	if (ymax < yt) then ymax:= yt;
		end;

	  	xorig:=xmin-8;				(* get x originend *)
	  	yorig:=ymin-8;				(* get y origin *)
	  	xn:=(xmax-xorig+size) div size;			(* get # in x direction *)
	  	yn:=(ymax-yorig+size) div size;			(* get # in y direction *)
	   boxlist:=MemAllocSeg(word(xn) * word(yn) * 4);
      FillChar(boxlist^, (xn * yn * 4), #00);
	  	scl:=81920 div (100+yn);			(* so scl*scl*size*yn<2^31-1 *)
	  	size:=size * scl;
	  	t:=0;					(* total len of all lists *)
		for l:=0 to linedefs^.count-1 do begin
         Progress;
	   	xf:=scl * longint(vertices.At(linedefs^.At(l)^.v0)^.x - xorig);
	   	yf:=scl * longint(vertices.At(linedefs^.At(l)^.v0)^.y - yorig);
	    	xt:=scl * longint(vertices.At(linedefs^.At(l)^.v1)^.x - xorig);
	    	yt:=scl * longint(vertices.At(linedefs^.At(l)^.v1)^.y - yorig);
	    	xd:=sgn(xt-xf);
		 	yd:=sgn(yt-yf);
			case ( 2 * integer((xf div size)=(xt div size)) + integer((yf div size)=(yt div size))) of
				0:begin
					c:=0;
					p:=yd*xn;(* diagonal line *)
		      end;
		     	1:begin
					c:=abs(xt div size - xf div size)+1;
					p:=xd;(* horizontal line *)
		      end;
		     	2:begin
					c:=abs(yt div size - yf div size)+1;
					p:=yd*xn;(* vertical line *)
		      end;
		     	3:begin
					c:=1;
				   p:=1;(* start,end same block *)
		      end;
		   end;
   		b:=xf div size + xn * (yf div size);			(* start @ this block *)
         i:=0;
         while i < c do begin (* add to lists for special *)
      		blockmap_add_line(boxlist^[b],l);	(* cases: horizontal*)
      		Inc(t);												(* vertical & single block *)
      		b:=b+p;
         	inc(i);
   		end;
   		if c = 0 then begin									(* handle diagonal lines *)
      		m:=scl * (yt-yf) div (xt-xf);					(* spanning > 1 block    *)

      		if m = 0 then
					m:=sgn(yt-yf)*sgn(xt-xf);	(* force a min non-0 slope *)
      		xcl:=xf;

    			if (yd = -1) then
					xcc:=xf + scl*((yf div size) * size - 1 - yf) div m
      		else
					xcc:=xf + scl*((yf div size) * size + size - yf) div m;

      		repeat
         		for c:=0 to abs(xcc div size - xcl div size) do begin
          			blockmap_add_line(boxlist^[b],l);
          			Inc(t);
            		b:=b + xd;
       			end;
        			b:=b+p-xd;
        			xcl:=xcc;
		  			xcc:=xcc + (yd*scl*size div m);
      			if (xd*xcc > xd*xt) then
		  				xcc:=xt;		(* don't overrun endpoint *)
      		until (xd*xcl) >= (xd*xt);
   		end;
		end;
		{Blockmap:=MemAllocSeg((4 + xn * yn + t + 2 * xn * yn) * 2);}
		Blockmap:=MemAllocSeg(65520);
  		if Blockmap=Nil then
  			ProgError('CreateBlockmap Failed: Insufficient memory');
  		Blockmap^[0]:=xorig;			(* fill in X,Y origin *)
  		Blockmap^[1]:=yorig;
  		Blockmap^[2]:=xn;				(* fill in # in X and *)
  		Blockmap^[3]:=yn;				(* Y directions       *)
      t:=4;
      k:=0;
  		for i:=0 to (xn*yn) - 1 do		(* count # empty blocks *)
    		if boxlist^[i] = Nil then
         	Inc(k);
  	 	o:=t;
      t:=t + xn * yn;
  		l:=t;
  		Blockmap^[t]:=0;				(* all empty blocks will *)
  		Blockmap^[t+1]:=-1;				(* point to this one     *)
      inc(t,2);
      for i:=0 to (xn*yn) - 1 do begin (* now fill in BLOCKMAP *)
    		if boxlist^[i] <> Nil then begin
      		Blockmap^[o]:=t;			(* offset in BLOCKMAP *)
            Inc(o);
      		Blockmap^[t]:=0;			(* always zero *)
            Inc(t);
            k:=0;
            while (0 < boxlist^[i]^[k]) do begin(* list of lines in this *)
        			Blockmap^[t]:=boxlist^[i]^[k]-1;	(* block                 *)
               inc(t);
               inc(k);
            end;
      		blockfree(boxlist^[i]);
      		Blockmap^[t]:=-1;			(* always -1 *)
            Inc(t);
      		if t >= 65520 then		(* remaining offsets are bad *)
	        		ProgError('Failed CreateBlockmap: BLOCKMAP structure too large');
    		end else begin
      		Blockmap^[o]:=l;			(* point to empty block *)
           	inc(o);
         end;
		end;
		freemem(boxlist, xn * yn * 4);
      CreateBlockmap:=t;	(* # words in BLOCKMAP *)
	end;

end.