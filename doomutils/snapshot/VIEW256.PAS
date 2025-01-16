uses DOS, Crt;

var	PalBuff,OldPalette:array[1..768] of byte;
		ScrnPtr:pointer;
		f:file;
		Regs:registers;
		t:integer;
		ch:char;

begin
	if ParamCount = 0 then begin
		writeln('Useage: VIEW256  filename.256');
		writeln;
		writeln('where filename is the name of a valid SNAPSHOT output file');
		halt(1);
	end;
	assign(f,paramstr(1));
	reset(f,1);
	Regs.ax:=$13;
	intr($10, Regs);
	with regs do begin
		Regs.ax:=$1017;
		Regs.es:=Seg(OldPalette);
		Regs.dx:=ofs(OldPalette);
		Regs.bx:=0;
		Regs.cx:=256;
		Intr($10,Regs);
	end;
	Blockread(f,PalBuff,768);
	for t:=1 to 768 do
		PalBuff[t]:=PalBuff[t] div 4;
	with regs do begin
		ax:=$1012;
		bx:=0;
		cx:=256;
		es:=seg(PalBuff);
		dx:=ofs(PalBuff);
		Intr($10,Regs);
	end;
	ScrnPtr:=Ptr(SegA000,0000);
	BlockRead(f, ScrnPtr^, 64000);
	close(f);
	repeat
	until KeyPressed;
	repeat
		ch:=readkey;
	until not keypressed;
	with regs do begin
		ax:=$1012;
		bx:=0;
		cx:=256;
		es:=seg(OldPalette);
		dx:=ofs(OldPalette);
		Intr($10,Regs);
	end;
	TextMode(co80);
end.