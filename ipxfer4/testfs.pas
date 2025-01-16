Uses Dosfs;

Var TestDrv:PDriveManager;

begin
	TestDrv:=New(PDriveManager, Init(0, False));
end.