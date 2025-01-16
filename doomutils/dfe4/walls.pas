{****************************************************************************
*                      The DOOM Hacker's Tool Kit                           *
*****************************************************************************
* Unit   : OBJCACHE                                                         *
* Purpose: Object Cache Memory Allocation Deamon                            *
* Date:    4/28/94                                                          *
* Author:  Joshua Jackson        Internet: joshjackson@delphi.com           *
****************************************************************************}

{$O+,F+}
unit Walls;

interface

uses	Wad,WadDecl,Things,ObjCache;

const	MaxPatches = 128;

type  PWallTexture=^TWallTexture;
		TWallTexture=object
			Name		:objnamestr;
			Patches  :word;
			Image		:^BA;
			Width		:word;
			Height	:word;
			Constructor Init(WDir:PWadDirectory;TextName:ObjNameStr);
			Procedure Draw(Scale,XOfs,YOfs:integer);
			Destructor Done;
		end;

implementation

uses 	crt,graph;

Constructor TWallTexture.Init(WDir:PWadDirectory;TextName:ObjNameStr);

	type 	IA=array[1..16000] of longint;
			POffsetList=^TOffsetList;
			TOffsetList=array[0..320] of longint;
			SpDim=record
				xsize	:integer;
				ysize	:integer;
				xofs	:integer;
				yofs	:integer;
			end;
			PatchDesc=record
				xofs	:integer;
				yofs	:integer;
				PNum	:word;
				junk	:longint;
			end;
			PatchList=array[1..MaxPatches] of PatchDesc;

	var	l,t:word;
			C1,ObjCache:PObjectCache;
			NumTex:Longint;
			Offsets:^IA;
			TexOfs,TexDirStart:longint;
			TempName:ObjNameStr;
			sd:SpDim;
			x,y:integer;
			srow,rowlen:byte;
			spSize:word;
			pixel:byte;
			PatchOfs:POffsetList;
			PList:^PatchList;
			RowBuff:array[1..320] of byte;

	begin
		for t:=1 to length(TextName) do begin
			if TextName[t] = #32 then
				TextName[t]:=#0;
			TextName[t]:=UpCase(TextName[t]);
		end;
		Name:=TextName;
		TexOfs:=0;
		l:=WDir^.FindObject('TEXTURE1');
		if l=0 then begin
			TextMode(co80);
			writeln('TWallTexture_Init: Could not locate TEXTURE1.');
			WDir^.Done;
			halt;
		end;
		C1:=New(PObjectCache, Init(WDir, WDir^.FindObject('TEXTURE1')));
		TexDirStart:=WDir^.DirEntry^[WDir^.FindObject('TEXTURE1')].ObjStart;
		c1^.CacheRead(NumTex,4);
		GetMem(Offsets, NumTex * 4);
		c1^.CacheRead(Offsets^, NumTex * 4);
		for l:=1 to NumTex do begin
			c1^.SetPos(Offsets^[l]);
			c1^.CacheRead(TempName[1], 8);
			if TempName = TextName then begin
				Name:=TempName;
				TexOfs:=Offsets^[l] + TexDirStart;
				c1^.IncPos(4);
				c1^.CacheRead(Width, 2);
				c1^.CacheRead(Height, 2);
				c1^.IncPos(4);
				c1^.CacheRead(Patches, 2);
				break;
			end;
		end;
		FreeMem(Offsets, NumTex * 4);
		Dispose(c1, done);
		if TexOfs=0 then begin
			C1:=New(PObjectCache, Init(WDir, WDir^.FindObject('TEXTURE2')));
			TexDirStart:=WDir^.DirEntry^[WDir^.FindObject('TEXTURE2')].ObjStart;
			c1^.CacheRead(NumTex,4);
			GetMem(Offsets, NumTex * 4);
			c1^.CacheRead(Offsets^, NumTex * 4);
			for l:=1 to NumTex do begin
				c1^.SetPos(Offsets^[l]);
				c1^.CacheRead(TempName[1], 8);
				if TempName = TextName then begin
					Name:=TempName;
					TexOfs:=Offsets^[l] + TexDirStart;
					c1^.IncPos(4);
					c1^.CacheRead(Width, 2);
					c1^.CacheRead(Height, 2);
					c1^.IncPos(4);
					c1^.CacheRead(Patches, 2);
					break;
				end;
			end;
			FreeMem(Offsets, NumTex * 4);
			Dispose(c1, done);
		end;
		if TexOfs = 0 then begin
			Dispose(WDir, Done);
			writeln('TWallTexture_Init: Texture name: ',TextName,' Not Found');
			halt(1);
		end;
		GetMem(Image, Width * Height);	{Allocate Memory For Texture}
		fillchar(Image^,Width * Height,#0);
		c1:=New(PObjectCache, Init(WDir, WDir^.FindObject('PNAMES  ')));
		GetMem(PList, Patches * 10);
		Seek(WDir^.WadFile, TexOfs + 22);
		BlockRead(WDir^.WadFile, PList^, Patches * 10);
		c1^.IncPos(2);
		for t:=1 to Patches do begin
			c1^.SetPos(((PList^[t].PNum ) * 8) + 4);
			c1^.CacheRead(TempName, 8);
			{writeln ('          Loading Patch: ',TempName);}
			l:=WDir^.FindObject(TempName);
			if l=0 then begin
				TextMode(co80);
				writeln('WallTexure_Init: Could not locate patch ID: ',TempName);
				WDir^.Done;
				halt;
			end;
			seek(WDir^.WadFile,WDir^.DirEntry^[l].ObjStart);
			BlockRead(WDir^.WadFile,sd.XSize,8);
			spSize:=sd.xSize * sd.ySize;					{Calc Total Patch Image Size}
			if spSize > 64000 then begin					{Error Check}
				TextMode(co80);
				writeln('WallTexture_Init: Invalid Patch Image Size');
				WDir^.Done;
				halt;
			end;
			GetMem(PatchOfs, sd.xSize * 4);		{Allocate Row Offset Buffer}
			ObjCache:=New(PObjectCache, Init(WDir, l));
			ObjCache^.IncPos(8);
			ObjCache^.CacheRead(PatchOfs^,sd.xSize * 4);
			for x:= 0 to sd.xsize - 1 do begin   {-1}
				ObjCache^.SetPos(PatchOfs^[x]);
				ObjCache^.CacheRead(SRow,1);
				while srow<>255 do begin
					ObjCache^.CacheRead(RowLen,1);
					ObjCache^.CacheRead(RowBuff, RowLen+2);
					for y:=0 to rowlen  do begin {-1}
						pixel:=RowBuff[y+2];
						l:=(x + PList^[t].xofs) + (srow + y + PList^[t].yofs) * Width;
						if l < (Width * Height) then
							Image^[l]:=Pixel;
					end; {for y}
					ObjCache^.CacheRead(SRow,1);
				end; {while}
			end; {for x}
			Dispose(ObjCache, Done);
			freemem(PatchOfs, sd.xsize * 4);
		end;
		Dispose(c1, Done);
		FreeMem(PList, Patches * 10);
	end;

Procedure TWallTexture.Draw(Scale,XOfs,YOfs:integer);

	var 	y1,y2,x1,x2:word;
			xPix,yPix,oxpix,oypix:word;
			xSize:integer;
			TempStr:string;

	begin
		oxpix:=0;
		oypix:=0;
		XSize:=Width;
		for y1:=0 to (Height - 1) do begin
			yPix:=word(longint(y1 * Scale) div 100);
			for y2:=oypix to ypix do begin
				oxpix:=0;
				for x1:=0 to (Width - 1) do begin
					xPix:=word(longint(x1 * Scale) div 100);
					for x2:=oxpix to xpix do begin
						PutPixel(x2+Xofs,y2+YOfs,Image^[(y1*xSize)+x1]);
					end;
					oxpix:=xpix+1;
				end;
			end;
			oypix:=ypix + 1;
		end;
	end;

Destructor TWallTexture.Done;

	begin
		FreeMem(Image, Width * Height);
	end;

end.
