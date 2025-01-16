uses DOS,CRT,IPX,Graph;

Procedure Video_Initialize;

	var	gd,gm:integer;

	begin
		gd:=9;
		gm:=1;
		InitGraph(gd,gm,'d:\bp\bgi');
	end;

Procedure IPX_Initialize;

	begin
		if not IPXInstalled then begin
			ErrorBox('IPX not detected.');
			halt;
		end;
	end;

begin
	Video_Initialize;
	IPX_Initialize;
end.
