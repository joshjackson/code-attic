unit BMPOUT;

interface

uses WadDecl,Wad,Walls;

Procedure Wall2BMP(WDir:PWadDirectory;Wall:PWallTexture);

implementation

TYPE 	TBMPheader=record      						{BMP File Header Structure}
			id			:array[1..2] of char;
			FileSize :longint;
			Res 		:array[1..4] of char;
			HeaderLen:longint;
			Infosize :longint;
			XPix 		:longint;
			YPix		:longint;
			BitPlanes:integer;
			Bits		:integer;
			Comp		:longint;
			ImageSize:longint;
			XPels		:longint;
			YPels		:longint;
			ClrUsed	:longint;
			ClrImp	:longint;
		end;
		TBMPpalette=record
			B			:byte;
			G			:byte;
			R			:byte;
			Filler	:byte;
		end;
		BA=array[0..65530] of byte;
		PSpriteBuff=^SpriteBuff;
		SpriteBuff=record
			x		:integer;
			y		:integer;
			Image	:^BA;
		end;

{Procedure ReadIt(fn:string;var SBuff:PSpriteBuff);

	var	bh:TBMPheader;
			bp:array[0..255] of TBMPpalette;
			f:file;
			t:integer;
			pBuff:array[0..767] of byte;
			regs:registers;

	begin
		assign(f,fn);
		reset(f,1);
		BlockRead(f,bh,54);
		BlockRead(f,bp,1024);
		for t:=0 TO 255 do begin
			PBuff[t*3]:=bp[t].r div 4;
			PBuff[t*3+1]:=bp[t].g div 4;
			PBuff[t*3+2]:=bp[t].b div 4;
		end;
		with regs do begin
			ax:=$1012;
			bx:=0;
			cx:=255;
			es:=seg(PBuff);
			dx:=ofs(PBuff);
			Intr($10,Regs);
		end;
		for t:=63 downto 0 do begin
			BlockRead(f,sBuff^.Image^[t*64],64);
		end;
		close(f);
		SBuff^.x:=64;
		sBuff^.y:=64;
	end;}

Procedure Wall2BMP(WDir:PWadDirectory;Wall:PWallTexture);

	var 	BH:TBMPHeader;
			BP:array[1..256] of TBMPpalette;
			PBuff:Array[1..768] of byte;
			TotalImageSize:Longint;
			t,PPalPos:word;
			f:file;
			FileName:String;

	begin
		FileName:='';
		for t:=1 to 8 do begin
			if (Wall^.Name[t] <> #32) and (Wall^.Name[t] <> #00) then
				FileName:=FileName+Wall^.Name[t]
			else
				break;
		end;
		FileName:=FileName+'.BMP';
		Assign(f, FileName);
		Rewrite(f, 1);
		TotalImageSize:=longint(Wall^.Width * Wall^.Height);
		{Construct a BMP Header}
		BH.ID:='BM';
		BH.FileSize:=1078 + TotalImageSize;
		BH.XPix:=Wall^.Width;
		BH.YPix:=Wall^.Height;
		BH.HeaderLen:=1078;
		BH.Infosize:=$28;
		BH.BitPlanes:=1;
		BH.Bits:=8;
		BH.Comp:=0;
		BH.ImageSize:=TotalImageSize;
		BH.ClrUsed:=256;
		BH.ClrImp:=256;

		{Construct BMP Palette}
		PPalPos:=WDir^.FindObject('PLAYPAL ');
		Seek(WDir^.WadFile, WDir^.DirEntry^[PPalPos].ObjStart);
		BlockRead(WDir^.WadFile, PBuff, 768);
		for t:=1 to 256 do begin
			BP[t].r:=PBuff[((t-1) * 3) + 1];
			BP[t].g:=PBuff[((t-1) * 3) + 2];
			BP[t].b:=PBuff[((t-1) * 3) + 3];
			BP[t].filler:=0;
		end;

		{Write the BMP Header}
		BlockWrite(f, BH, Sizeof(TBMPHeader));
		{Write the BMP Palette}
		BlockWrite(f, BP, Sizeof(TBMPpalette) * 256);

		{Write the BMP Body}
		for t:=(Wall^.Height - 1) downto 0 do
			BlockWrite(f, Wall^.Image^[(t*Wall^.Width)], Wall^.Width);

		{All done}
		close(f);
	end;

begin
end.