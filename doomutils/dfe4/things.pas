{****************************************************************************
*                      The DOOM Hacker's Tool Kit                           *
*****************************************************************************
* Unit: 	  THINGS                                                           *
* Purpose: Loading and displaying Picture Format objects from the WAD File  *
* Date:    4/28/94                                                          *
* Author:  Joshua Jackson        Internet: joshjackson@delphi.com           *
****************************************************************************}

{$F-}
unit Things;

interface

uses Wads,WadDecl,ObjCache,VirtScrn;

type  PWadThing=^TWadThing;
		TWadThing=object
			SBuff:PPictureBuff;
			Constructor Init(WDir:PWadDirectory;ThingName:ObjNameStr);
			Procedure Draw(Scale,XOffset,YOffset:word);
			Procedure VDraw(Scale,XOffset,YOffset:word;VBuff:PVirtualScreen);
			Function Height:word;
			Function Width:word;
			Destructor Done;
		end;

implementation

uses Graph,Crt;

Constructor TWadThing.Init(WDir:PWadDirectory;ThingName:ObjNameStr);

	type	POffsetList=^TOffsetList;
			TOffsetList=array[0..320] of longint;
			SpDim=record
				xsize	:word;
				ysize	:word;
				xofs	:integer;
				yofs	:integer;
			end;

	var	sd:SpDim;
			x,y:integer;
			srow,rowlen:byte;
			spSize,l:word;
			pixel:byte;
			Offsets:POffsetList;
			BuffPos:word;
			RowBuff:array[1..320] of byte;
			ObjCache:PObjectCache;

	begin
		BuffPos:=0;
		l:=WDir^.FindObject(ThingName);
		if l=0 then begin
			TextMode(co80);
			writeln('WadThing_Init: Could not locate picture ID: ',ThingName);
			WDir^.Done;
			halt;
		end;
		{seek(WDir^.WadFile,WDir^.DirEntry^[l].ObjStart);}
            wdir^.SeekEntry(l);
		New(Sbuff);										{Allocate New Sprite Descriptor}
		BlockRead(WDir^.WadFile,sd.XSize,8);
		spSize:=sd.xSize * sd.ySize;					{Calc Total Sprite Image Size}
		if spSize > 64000 then begin					{Error Check}
			TextMode(co80);
			writeln('WadThing_Init: Invalid Image Size');
			WDir^.Done;
			halt;
		end;
		GetMem(Sbuff^.Image,spSize);	{Allocate Sprite Image Buffer}
		fillchar(Sbuff^.Image^,spsize,#0);
		GetMem(Offsets, sd.xSize * 4);		{Allocate Row Offset Buffer}
		ObjCache:=New(PObjectCache, Init(WDir, l));
		ObjCache^.IncPos(8);
		ObjCache^.CacheRead(Offsets^,sd.xSize * 4);
		for x:= 0 to sd.xsize - 1 do begin   {-1}
			ObjCache^.SetPos(Offsets^[x]);
			ObjCache^.CacheRead(SRow,1);
			while srow<>255 do begin
				ObjCache^.CacheRead(RowLen,1);
				ObjCache^.CacheRead(RowBuff, RowLen+2);
				for y:=0 to rowlen - 1  do begin {-1}
					pixel:=RowBuff[y+2];
					l:=x +  ((srow + y) * sd.xsize);
					if l < spSize then begin
						Sbuff^.Image^[l]:=Pixel;
{						PutPixel(x,y,Pixel);}
					end;
				end; {for y}
				ObjCache^.CacheRead(SRow,1);
			end; {while}
		end; {for x}
		ObjCache^.Done;
		Dispose(ObjCache);
		freemem(offsets, sd.xsize * 4);
		SBuff^.x:=sd.xsize;
		SBuff^.y:=sd.ysize;
		SBuff^.xofs:=sd.xofs;
		SBuff^.yofs:=sd.yofs;
	end;

Procedure TWadThing.Draw(Scale,XOffset,YOffset:word);

	var 	y1,y2,x1,x2:word;
			xPix,yPix,oxpix,oypix:word;
			xSize:word;

	begin
		oxpix:=0;
		oypix:=0;
		XSize:=SBuff^.x;
		for y1:=0 to (SBuff^.y - 1) do begin
			yPix:=word(longint(y1 * Scale) div 100);
			for y2:=oypix to ypix do begin
				oxpix:=0;
				for x1:=0 to (SBuff^.x - 1) do begin
					xPix:=word(longint(x1 * Scale) div 100);
					for x2:=oxpix to xpix do begin
						PutPixel(x2+Xoffset,y2+YOffset,Sbuff^.Image^[(y1*xSize)+x1]);
					end;
					oxpix:=xpix+1;
				end;
			end;
			oypix:=ypix + 1;
		end;
	end;

Procedure TWadThing.VDraw(Scale,XOffset,YOffset:word;VBuff:PVirtualScreen);

	var 	y1,y2,x1,x2:word;
			xPix,yPix,oxpix,oypix:word;
			xSize:word;
			p:longint;

	begin
		oxpix:=0;
		oypix:=0;
		XSize:=SBuff^.x;
		for y1:=0 to (SBuff^.y - 1) do begin
			yPix:=word(longint(y1 * Scale) div 100);
			for y2:=oypix to ypix do begin
				oxpix:=0;
				for x1:=0 to (SBuff^.x - 1) do begin
					xPix:=word(longint(x1 * Scale) div 100);
					for x2:=oxpix to xpix do begin
						p:=((y2 + YOffset) * 320) + x2 + XOffset;
						VBuff^.ScrnBuff^[p]:=SBuff^.Image^[(y1*xSize)+x1];
					end;
					oxpix:=xpix+1;
				end;
			end;
			oypix:=ypix + 1;
		end;
	end;

Function TWadThing.Height:word;

	begin
		Height:=SBuff^.y;
	end;

Function TWadThing.Width:word;

	begin
		Width:=SBuff^.x;
	end;

Destructor TWadThing.Done;

	begin
		FreeMem(SBuff^.Image,SBuff^.y * SBuff^.x);
		Dispose(SBuff);
	end;

end.
