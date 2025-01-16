{$M 4096,0,0}
uses Dos,Crt,Memory;

var 	dmpath:string;
		f:SearchRec;

begin
	ClrScr;
	writeln('NET-DOOM Installation.');
	writeln;
	writeln('Please enter you DOOM directory (including drive letter)');
	write('>');
	readln(dmpath);
	if dmpath[length(dmpath)]<>'\' then
		dmpath:=dmpath+'\';
	FindFirst(dmpath+'DOOM.EXE', AnyFile, f);
	if DosError<>0 then begin
		writeln('DOOM.EXE was not found in ',dmpath);
		halt(1);
	end;
	writeln;
	writeln('Installing DFE...');
	SwapVectors;
	Exec('PKUNZIP.EXE','DFEINST.ZIP -o -d '+dmpath);
	SwapVectors;
	writeln;
	writeln;
	writeln;
	writeln('Installing Network Drivers...');
	SwapVectors;
	Exec('PKUNZIP.EXE','NETWORK.ZIP C:\NETWORK -d -o');
	SwapVectors;
   if DosError <> 0 then begin
   	writeln('Exec return error code: ',DosError);
      writeln(MemAvail);
      halt;
   end;
	writeln;
	writeln('NET-DOOM files have been installed.');
	writeln;
	writeln('To Execute the DOOM front end, simply type DFE when in your');
	writeln('DOOM directory.');
	writeln;
	writeln('See the DFE.TXT file in your DOOM directory for more info on DFE');
end.