{$F+,O+}
unit DFEVideo;

interface

var	SVGA256Driver:integer;
		In256ColorMode:Boolean;
		VideoDriver:pointer;
		DriverSize:word;

Procedure InitVideo;
Procedure DoneVideo;

implementation

uses Graph,Mouse,Crt;

function DetectVGA256 : Integer;

	begin
		DetectVGA256:=3;
	end;

Procedure InitVideo;

	var	gd,gm:integer;
			DF:File;

	begin
		Assign(DF, 'DFEVIDEO.DRV');
		Reset(DF, 1);
		DriverSize:=FileSize(DF);
		GetMem(VideoDriver, DriverSize);
		BlockRead(DF, VideoDriver^, DriverSize);
		Close(DF);
		if	RegisterBGIDriver(VideoDriver) < 0 then begin
			writeln('SysVideo_Init: ',GraphErrorMsg(GraphResult));
			halt;
		end;
		gd:=SVGA256Driver;
		gm:=3;
		InitGraph(gd,gm,'');
		gd:=GraphResult;
		if gd=grOK then begin
			SetViewPort(0,0,GetMaxX,GetMaxY,True);
			FakeCursor:=True;
			In256ColorMode:=True;
			exit;
		end;
		TextMode(CO80);
		writeln('=============================ERROR==============================');
		writeln(' DFE requires a VESA compatible card to switch to 256 color');
		writeln(' mode.  Please install your VESA driver before attempting to');
		writeln(' view maps/sprites.');
		writeln('                     Press ENTER to continue');
		writeln('================================================================');
		In256ColorMode:=False;
	end;

Procedure DisposeVideoDriver;

	begin
		FreeMem(VideoDriver, DriverSize);
	end;

Procedure DoneVideo;

	begin
		if In256ColorMode then
			CloseGraph;
		DisposeVideoDriver;
		In256ColorMode:=False;
	end;

begin
		SVGA256Driver:=InstallUserDriver('BGI256',@DetectVGA256);
		In256ColorMode:=False;
end.
