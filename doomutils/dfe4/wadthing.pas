unit WadThing;

interface

uses Wads,WadDecl,VirtScrn;

type	PThingDecoder=^TThingDecoder;
		TThingDecoder=Object
			RowBuffer:BAP;
			PixelBuffer:BAP;
			RowSize,PixelSize:longint;
			XSize,YSize,XOfs,YOfs:integer;
			Constructor Init(WDir:PWadDirectory;N:ObjNameStr);
			Procedure Transfer(X,Y,Scale:word;VScrn:PVirtualScreen);
			Destructor Done;
		end;

implementation

uses	Crt,Memory;

{$l wadthing.obj}
Procedure DecodeSprite(var Dest,PBuff,RowBuff;Xofs,Yofs,X,Y:word); external;

Constructor TThingDecoder.Init(WDir:PWadDirectory;N:ObjNameStr);

	var	p:word;

	begin
		p:=WDir^.FindObject(N);
		if p=0 then begin
			TextMode(CO80);
			writeln('PWadDirectory.FindObject: Unable to locate ',N);
			halt(1);
		end;
		{Seek(WDir^.WadFile,WDir^.DirEntry^[p].ObjStart);}
            WDir^.SeekEntry(p);
		BlockRead(WDir^.WadFile,XSize,2);
		BlockRead(WDir^.WadFile,YSize,2);
		BlockRead(WDir^.WadFile,XOfs,2);
		BlockRead(WDir^.WadFile,YOfs,2);
		RowSize:=4 * XSize;
		PixelSize := WDir^.EntrySize(p) - 8 - (4 * XSize);
		if PixelSize > 65520 then begin
			TextMode(CO80);
			writeln('ThingDecoder.Init: ',N,' structure too large for FastDecode');
			halt(1);
		end;
		RowBuffer:=MemAllocSeg(RowSize);
		PixelBuffer:=MemAllocSeg(PixelSize);
		BlockRead(WDir^.WadFile,RowBuffer^,RowSize);
		BlockRead(WDir^.WadFile,PixelBuffer^,PixelSize);
	end;

Procedure TThingDecoder.Transfer(X,Y,Scale:word;VScrn:PVirtualScreen);

	begin
		DecodeSprite(VScrn^.ScrnBuff^,PixelBuffer^,RowBuffer^,x,y,XSize,YSize);
	end;

Destructor TThingDecoder.Done;

	begin
		FreeMem(PixelBuffer, PixelSize);
		FreeMem(RowBuffer, PixelSize);
	end;

end.
