unit filefind;

interface

uses DOS,CRT;

implementation

var	Regs:Registers;

Function DeleteFile(f:string):word;

	begin
		f:=f+#00;
		Regs.ah:=$41;
		Regs.ds:=Seg(f);
		Regs.dx:=Ofs(f[1]);
		MsDos(Regs);
		if (Regs.Flags and fCarry) <> 0 then
			DeleteFile:=Regs.ax
		else
			DeleteFile:=0;
	end;

Procedure Whereis(f:string):string;

	begin
		dir


	end;

end.