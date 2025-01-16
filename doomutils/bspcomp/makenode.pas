(*- MAKENODE.PAS ------------------------------------------------------------*
 Recursively create nodes and return the pointers.
*---------------------------------------------------------------------------*)
unit MakeNode;

interface

uses MapEntries,BSPGlobals,PickNodes;

Function CreateNode(ts:PSegList):PBSPNode;
Procedure DivideSegs(ts:PSegList;var rs,ls:PSegList);
Function IsItConvex(ts:PSegList):boolean;
Function CreateSSector(tmps:PSegList):word;
Function ComputeAngle(dx,dy:integer):word;

implementation

{$IFNDEF WINDOWS}
uses crt;
{$ELSE}
uses wincrt;
{$ENDIF}

Function CreateNode(ts:PSegList):PBSPNode;

	var	tn:PBSPNode;
			rights:PSegList;
			lefts:PSegList;

	begin
		New(tn);														(*Create a node*)
      rights:=Nil;
      Lefts:=Nil;
		DivideSegs(ts,rights,lefts);							(*Divide node in two*)

      Dispose(ts, done);

	   gotoxy(18,16);
	   write(MemAvail);
      clreol;

		Inc(num_nodes);
      gotoxy(18,13);
      write(num_nodes);
      clreol;

		tn^.x:=node_x;											(* store node line info*)
		tn^.y:=node_y;
		tn^.dx:=node_dx;
		tn^.dy:=node_dy;

		FindLimits(lefts);										(* Find limits of vertices	*)

		tn^.maxy2:=lmaxy;
		tn^.miny2:=lminy;
		tn^.minx2:=lminx;
		tn^.maxx2:=lmaxx;

		(* Check lefthand side*)
		if IsItConvex(lefts) then begin
	      (* still segs remaining*)
			tn^.nextl:=CreateNode(lefts);
			tn^.chleft:=0;
		end else	begin
			tn^.nextl:=Nil;
			tn^.chleft:=CreateSSector(lefts) or $8000;
		end;

		(* Find limits of vertices*)
		FindLimits(rights);

		tn^.maxy1:=lmaxy;
		tn^.miny1:=lminy;
		tn^.minx1:=lminx;
		tn^.maxx1:=lmaxx;

		(* Check righthand side*)
		if(IsItConvex(rights)) then begin
	      (* still segs remaining*)
			tn^.nextr:=CreateNode(rights);
			tn^.chright:=0;
		end else	begin
			tn^.nextr:=Nil;
			tn^.chright:=CreateSSector(rights) or $8000;
		end;

		CreateNode:=tn;
	end;

(*---------------------------------------------------------------------------*
 Split a list of segs (ts) into two using the method described at bottom of
 file, this was taken from OBJECTS.C in the DEU5beta source.

 This is done by scanning all of the segs and finding the one that does
 the least splitting and has the least difference in numbers of segs on either
 side.
 If the ones on the left side make a SSector, then create another SSector
 else put the segs into lefts list.
 If the ones on the right side make a SSector, then create another SSector
 else put the segs into rights list.
*---------------------------------------------------------------------------*)

Procedure DivideSegs(ts:PSegList;var rs,ls:PSegList);

   var	rights,lefts:PSegList;

         new_rs,new_ls,add_to_rs,add_to_ls,
			new_best,best,tmps,news:PSeg;
         newv:PVertex;

			num_secs_r,num_secs_l,last_sec_r,last_sec_l:integer;
			num,least_splits,least:integer;
			fv,tv,num_new:integer;
			bangle,cangle,cangle2,cfv,ctv,dx,dy:integer;
			x,y:integer;
			ival:integer;
         s1,s2:integer;

	begin
      rights:=New(PSegList, Init(20,20));
      lefts:=New(PSegList, Init(20,20));

		num_new:=0;
		FindLimits(ts);							(* Find limits of this set of Segs*)
		sp.halfsx:=(lmaxx - lminx) div 2;		(* Find half width of Node*)
		sp.halfsy:=(lmaxy - lminy) div 2;
		sp.halfx:=lminx + sp.halfsx;			(* Find middle of Node*)
		sp.halfy:=lminy + sp.halfsy;

		best:=PickNode(ts);						(* Pick best node to use.*)

		if (best = Nil) then ProgError('Failed DivideSegs.');

		node_x:=vertices.At(best^.v0)^.x;
		node_y:=vertices.At(best^.v0)^.y;
		node_dx:=vertices.At(best^.v1)^.x-vertices.At(best^.v0)^.x;
		node_dy:=vertices.At(best^.v1)^.y-vertices.At(best^.v0)^.y;

	(* When we get to here, best is a pointer to the partition seg.
		Using this partition line, we must split any lines that are intersected
		into a left and right half, flagging them to be put their respective sides
		Ok, now we have the best line to use as a partitioning line, we must
	   split all of the segs into two lists (rightside & leftside).				 *)

		psx:=vertices.At(best^.v0)^.x;			(* Partition line coords*)
		psy:=vertices.At(best^.v0)^.y;
		pex:=vertices.At(best^.v1)^.x;
		pey:=vertices.At(best^.v1)^.y;
		pdx:=psx - pex;								(* Partition line DX,DY*)
		pdy:=psy - pey;

      s1:=0;
      while (s1 < ts^.count) do begin
	      tmps:=ts^.At(s1);
			progress;									(* Something for the user to look at.*)
			add_to_rs:=Nil;
			add_to_ls:=Nil;
			if(tmps <> best) then begin
				lsx:=vertices.At(tmps^.v0)^.x;	(* Calculate this here, cos it doesn't*)
				lsy:=vertices.At(tmps^.v0)^.y;	(* change for all the interations of*)
				lex:=vertices.At(tmps^.v1)^.x;		(* the inner loop!*)
				ley:=vertices.At(tmps^.v1)^.y;
				ival:=DoLinesIntersect;
				(* If intersecting !!*)
				if (((ival and 64) > 0) and ((ival and 2) > 0)) or
					(((ival and 32) > 0) and ((ival and 4) > 0)) then	begin
					ComputeIntersection(x,y);
					{writeln('Splitting Linedef ',tmps^.linedef,' at ',x,',',y);}

					New(newv);
	            newv^.x:=x;
	            newv^.y:=y;
	            vertices.Insert(newv);
               gotoxy(18,7);
               write(vertices.count);
               clreol;

					new(news);
					news^.v0:=vertices.count - 1;
					news^.v1:=tmps^.v1;
					tmps^.v1:=vertices.count - 1;
					news^.linedef:=tmps^.linedef;
					news^.angle:=tmps^.angle;
					news^.sidedef:=tmps^.sidedef;
					news^.lineofs:=SplitDist(news);
               ts^.AtInsert(s1 + 1,news);
	(*				printf("splitting dist:=%d\n",news^.dist);*)
	(*				printf("splitting vertices:=%d,%d,%d,%d\n",tmps^.start,tmps^.end,news^.start,news^.end);*)
					if (ival and 32) > 0 then add_to_ls:=tmps;
					if (ival and 64) > 0 then add_to_rs:=tmps;
					if (ival and 2) > 0 then add_to_ls:=news;
					if (ival and 4) > 0 then add_to_rs:=news;
					inc(s1);
					inc(num_new);
				(* Not split, which side ?*)
				end else	begin
					if (ival and 34) > 0 then add_to_ls:=tmps;
					if (ival and 68) > 0 then add_to_rs:=tmps;
	            (* On same line*)
					if ((ival and 1) > 0) and ((ival and 16) > 0) then	begin
						if(tmps^.sidedef = best^.sidedef) then add_to_rs:=tmps;
						if(tmps^.sidedef <> best^.sidedef) then add_to_ls:=tmps;
					end
				end
			end else add_to_rs:=tmps;						(* This is the partition line*)

	(*		printf("Val:=%X\n",val);*)

				(* CHECK IF SHOULD ADD RIGHT ONE *)
			if add_to_rs <> Nil then begin
				new(new_rs);
				if(add_to_rs = best) then new_best:=new_rs;
				new_rs^.v0:=add_to_rs^.v0;
				new_rs^.v1:=add_to_rs^.v1;
				new_rs^.linedef:=add_to_rs^.linedef;
				new_rs^.angle:=add_to_rs^.angle;
				new_rs^.sidedef:=add_to_rs^.sidedef;
				new_rs^.lineofs:=add_to_rs^.lineofs;
	      	Rights^.Insert(new_rs);
	      end;

      (* CHECK IF SHOULD ADD LEFT ONE *)
			if add_to_ls <> Nil then begin
				new(new_ls);
				if(add_to_ls = best) then new_best:=new_ls;
				new_ls^.v0:=add_to_ls^.v0;
				new_ls^.v1:=add_to_ls^.v1;
				new_ls^.linedef:=add_to_ls^.linedef;
				new_ls^.angle:=add_to_ls^.angle;
				new_ls^.sidedef:=add_to_ls^.sidedef;
				new_ls^.lineofs:=add_to_ls^.lineofs;
	      	Lefts^.Insert(new_ls);
			end;
      	inc(s1);
		end;

		if rights^.Count = 0 then begin
         rights^.Insert(new_best);
	      lefts^.Delete(new_best);
		end;

		if lefts^.Count = 0 then begin
         lefts^.Insert(new_best);
	      rights^.Delete(new_best);
		end;

	{printf("Made %d new Vertices and Segs\n",num_new);*)}

		rs:=rights;
		ls:=lefts;
	end;

(*--------------------------------------------------------------------------*)

Function IsItConvex(ts:PSegList):boolean;

	var 	line,check:PSeg;
	   	sector,ival:integer;
	      tmp:PSeg;
	      s1,s2:integer;

	begin
		tmp:=ts^.At(0);
		if tmp^.sidedef = 1 then
			sector:=sidedefs^.At(linedefs^.At(tmp^.linedef)^.sidedef1)^.sector
	   else
			sector:=sidedefs^.At(linedefs^.At(tmp^.linedef)^.sidedef0)^.sector;

		for s1:=1 to ts^.Count - 1 do begin
	      line:=ts^.At(s1);
	      if (line^.sidedef) = 1 then begin
				if sidedefs^.At(linedefs^.At(line^.linedef)^.sidedef1)^.sector <> sector then begin
	            IsItConvex:=true;
	      		exit;
	         end;
	      end else	begin
				if sidedefs^.At(linedefs^.At(line^.linedef)^.sidedef0)^.sector <> sector then begin
		    		IsItConvex:=true;
	            exit;
				end;
	   	end;
	   end;

		(* all of the segs must be on the same side all the other segs *)

	   for s1:=0 to ts^.Count - 1 do begin
	   	line:=ts^.At(s1);
			psx:=vertices.At(line^.v0)^.x;
			psy:=vertices.At(line^.v0)^.y;
			pex:=vertices.At(line^.v1)^.x;
			pey:=vertices.At(line^.v1)^.y;
			pdx:=(psx - pex);									(* Partition line DX,DY*)
			pdy:=(psy - pey);
	      for s2:=0 to ts^.Count - 1 do begin
	      	check:=ts^.At(s2);
				if(line<>check) then	begin
					lsx:=vertices.At(check^.v0)^.x;	(* Calculate this here, cos it doesn't*)
					lsy:=vertices.At(check^.v0)^.y;	(* change for all the interations of*)
					lex:=vertices.At(check^.v1)^.x;	(* the inner loop!*)
					ley:=vertices.At(check^.v1)^.y;
					ival:=DoLinesIntersect;
					if (ival and 34) > 0 then begin
	               IsItConvex:=true;
	         		exit;
	            end;
				end;
			end;
		end;

		(* no need to split the list: these Segs can be put in a SSector *)
	   IsItConvex:=False;
	end;

(*--------------------------------------------------------------------------*)

Function CreateSSector(tmps:PSegList):word;

	var	n:integer;
         newss:PSSector;
         news,olds:PSeg;
         s1:integer;

	begin
		new(newss);
	   if PSegs^.Count > 0 then
			newss^.Startseg:=PSegs^.Count
	   else
	   	newss^.Startseg:=0;

		n:=newss^.StartSeg;

	   for s1:=0 to tmps^.Count - 1 do begin
	   	olds:=tmps^.At(s1);
	      new(news);
			news^.v0:=olds^.v0;
			news^.v1:=olds^.v1;
			news^.angle:=olds^.angle;
			news^.linedef:=olds^.linedef;
			news^.sidedef:=olds^.sidedef;
			news^.lineofs:=olds^.lineofs;
	      PSegs^.Insert(news);
		end;

		newss^.NumSegs:=PSegs^.Count-n;
	   SSectors^.Insert(newss);

   	CreateSSector:=SSectors^.Count - 1;
      gotoxy(18,12);
      write(SSectors^.Count);
      clreol;
      gotoxy(18,11);
      write(PSegs^.Count);
      clreol;
      dispose(tmps, done);
	end;

(*- translate (dx, dy) into an integer angle value (0-65535) ---------------*)

Function ComputeAngle(dx,dy:integer):word;

	var	w,Fangle:real;

	begin
	   if dx <> 0 then begin
	   	w:=(ArcTan(dy / dx) * (65536 / (Pi * 2)));
	      if dx < 0 then w:=w - 32768;
		end else begin
			fangle:=1.570796;
	      if dy < 0 then
	        	fangle:=-1 * fangle;
			w:=(fangle * (65536 / (Pi * 2)));
	   end;
      if w < 0 then w:=w+65536;
	   ComputeAngle:=Round(w);
	end;


(*---------------------------------------------------------------------------*

	This message has been taken, complete, from OBJECTS.C in DEU5beta source.
	It outlines the method used here to pick the nodelines.

	IF YOU ARE WRITING A DOOM EDITOR, PLEASE READ THIS:

   I spent a lot of time writing the Nodes builder.  There are some bugs in
   it, but most of the code is OK.  If you steal any ideas from this program,
   put a prominent message in your own editor to make it CLEAR that some
   original ideas were taken from DEU.  Thanks.

   While everyone was talking about LineDefs, I had the idea of taking only
   the Segs into account, and creating the Segs directly from the SideDefs.
   Also, dividing the list of Segs in two after each call to CreateNodes makes
   the algorithm faster.  I use several other tricks, such as looking at the
   two ends of a Seg to see on which side of the nodeline it lies or if it
   should be split in two.  I took me a lot of time and efforts to do this.

   I give this algorithm to whoever wants to use it, but with this condition:
   if your program uses some of the ideas from DEU or the whole algorithm, you
   MUST tell it to the user.  And if you post a message with all or parts of
   this algorithm in it, please post this notice also.  I don't want to speak
   legalese; I hope that you understand me...  I kindly give the sources of my
   program to you: please be kind with me...

   If you need more information about this, here is my E-mail address:
   quinet@montefiore.ulg.ac.be (Rapha‰l Quinet).

   Short description of the algorithm:
     1 - Create one Seg for each SideDef: pick each LineDef in turn.  If it
	 has a "first" SideDef, then create a normal Seg.  If it has a
	 "second" SideDef, then create a flipped Seg.
     2 - Call CreateNodes with the current list of Segs.  The list of Segs is
	 the only argument to CreateNodes.
     3 - Save the Nodes, Segs and SSectors to disk.  Start with the leaves of
	 the Nodes tree and continue up to the root (last Node).

   CreateNodes does the following:
     1 - Pick a nodeline amongst the Segs (minimize the number of splits and
	 keep the tree as balanced as possible).
     2 - Move all Segs on the right of the nodeline in a list (segs1) and do
	 the same for all Segs on the left of the nodeline (in segs2).
     3 - If the first list (segs1) contains references to more than one
	 Sector or if the angle between two adjacent Segs is greater than
	 180ø, then call CreateNodes with this (smaller) list.  Else, create
	 a SubSector with all these Segs.
     4 - Do the same for the second list (segs2).
     5 - Return the new node (its two children are already OK).

   Each time CreateSSector is called, the Segs are put in a global list.
   When there is no more Seg in CreateNodes' list, then they are all in the
   global list and ready to be saved to disk.
*---------------------------------------------------------------------------*)

end.