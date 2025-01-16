uses App,PWCDECL,GroupPWads,PWadComp,Drivers,WadDecl,Wad;

type	TApp=Object(TApplication)
			Procedure HandleEvent(var E:TEvent); virtual;
		end;

var	PWadList:PWadCollection;

Procedure GroupPwad;

	var	Wad1,Wad2:PWadDirectory;
			e1,e2:PPWadEntry;

	begin
		PWadList:=New(PWadCollection, Init(5,2));
		TerminateOnWadError:=True;
		Wad2:=New(PWadDirectory, Init('D:\DOOM\DOOM.WAD'));
		Wad1:=New(PWadDirectory, Init('D:\DOOM\DOOM1.WAD'));
		New(e1);
		New(e2);
		e2^.NameStr:='D:\DOOM\DOOM.WAD';
		e2^.Dir:=Wad1;
		e1^.NameStr:='D:\DOOM\DOOM1.WAD';
		e1^.Dir:=Wad2;
		PWadList^.Insert(e1);
		PWadList^.Insert(e2);
		BuildCompoundPWad(PWadList);
		Dispose(e1);
		Dispose(e2);
		Dispose(Wad1,Done);
		Dispose(Wad2,Done);
		Dispose(PWadList,Done);
	end;

Procedure TApp.HandleEvent(var E:TEvent);

	begin
		Inherited HandleEvent(E);
		if E.What=evKeyDown then begin
			if E.KeyCode=kbAltA then
				GroupPWad;
		end;
	end;

var	MApp:TApp;



begin
	MApp.Init;
	MApp.Run;
	MApp.Done;
end.