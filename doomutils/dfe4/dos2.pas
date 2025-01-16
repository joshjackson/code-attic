unit DOS2;

interface

uses DOS;

Function FilesInDir(FSpec:PathStr;FAttr:word):longint;

implementation

Function FilesInDir(FSpec:PathStr;FAttr:word):longint;

	var	sr:SearchRec;
			NumFiles:longint;

	begin
		NumFiles:=0;
		FindFirst(FSpec, FAttr, sr);
		if DOSError <> 0 then begin
			FilesInDir:=0;
			exit;
		end;
		while DOSError = 0 do begin
			Inc(NumFiles);
			FindNext(sr);
		end;
		FilesInDir:=NumFiles;
	end;

end.