{****************************************************************************
*                      The DOOM Hacker's Tool Kit                           *
*****************************************************************************
* Unit   : FLOORS                                                           *
* Purpose: Loading and Displaying Floor Textures                            *
* Date:    4/28/94                                                          *
* Author:  Joshua Jackson        Internet: joshjackson@delphi.com           *
****************************************************************************}

{$F+,O+}
unit Floors;

interface

uses Wad,WadDecl,Graph;

type	PFloorTexture=^TFloorTexture;
		TFloorTexture=object
			Constructor Init(WDir:PWadDirectory;FloorName:ObjNameStr);
			Procedure Draw(Scale,XOffset,YOffset:word);
			Destructor Done;
		 private
			FBuff:PFloorBuff;
		end;

implementation

uses Crt;

Constructor TFloorTexture.Init(WDir:PWadDirectory;FloorName:ObjNameStr);

	var l:word;

	begin
		l:=WDir^.FindObject(FloorName);
		if l=0 then begin
			TextMode(co80);
			writeln('TFloorTexture_Init: Could not locate Texture ID: ',FloorName);
			WDir^.Done;
			halt;
		end;
		seek(WDir^.WadFile,WDir^.DirEntry^[l].ObjStart);
		New(Fbuff);										{Allocate New Floor Descriptor}
		GetMem(FBuff^.Image, 4096);
		BlockRead(WDir^.WadFile,FBuff^.Image^[0],4096);
	end;

Procedure TFloorTexture.Draw(Scale,XOffset,YOffset:word);

	var 	y1,y2,x1,x2:word;
			xPix,yPix,oxpix,oypix:word;
			xSize:word;

	begin
		oxpix:=0;
		oypix:=0;
		XSize:=64;
		for y1:=0 to 63 do begin
			yPix:=word(longint(y1 * Scale) div 100);
			for y2:=oypix to ypix do begin
				oxpix:=0;
				for x1:=0 to 63 do begin
					xPix:=word(longint(x1 * Scale) div 100);
					for x2:=oxpix to xpix do begin
						PutPixel(x2+Xoffset,y2+YOffset,Fbuff^.Image^[(y1*xSize)+x1]);
					end;
					oxpix:=xpix+1;
				end;
			end;
			oypix:=ypix+1;
		end;
	end;

Destructor TFloorTexture.Done;

	begin
		FreeMem(FBuff^.Image, 4096);
		Dispose(FBuff);
	end;

end.