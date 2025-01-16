{$O+,F+}
unit DFEOVR;

interface

uses Overlay;

implementation

begin
	OvrInit('DFESYS.OVR');
   if OvrResult <> 0 then begin
     	writeln('SysOverlay_Init: Error intializing DFE.OVL');
     	halt(1);
	end;
	OvrSetBuf(40000);
	if OvrResult <> 0 then begin
		writeln('SysOverlay_Init: Could not set Overlay Buffer Size');
		halt(1);
	end;
end.