uses 	App,Drivers,Views,ItemLoc1,Objects,Dialogs,StdDlg,Menus,Crt,SPlayer,Wad,
		Waddecl;

const	cmDoMenu=101;

type	TMyApp=object(TApplication)
			Constructor Init;
			Procedure HandleEvent(var Event:TEvent); virtual;
			Procedure Idle; virtual;
			Procedure DoMenu;
			Procedure InitMenuBar; virtual;
		end;

Var MyApp:TMyApp;

Constructor TMyApp.Init;

	begin
		Inherited Init;
	end;

Procedure TMyApp.HandleEvent(Var Event:TEvent);

	begin
		inherited HandleEvent(Event);
		if (Event.What = evCommand) and (Event.Command=cmDoMenu) then
			DoMenu;
		ClearEvent(Event);
	end;

Procedure TMyApp.Idle;

	begin
		Gotoxy(70,1);
		write(MemAvail);
	end;

Procedure TMyApp.DoMenu;

	var	{TheMenu:PSoundPlayer;}
			WDir:PWadDirectory;
			TheMenu:PItemMenu;

	begin
{		WDir:=New(PWadDirectory, Init('D:\DOOM\DOOM.WAD'));
		TheMenu:=New(PSoundPLayer, Init(WDir));}
		TheMenu:=New(PItemMenu, Init);
		DeskTop^.ExecView(TheMenu);
		Dispose(TheMenu, Done);
{		Dispose(Wdir, Done);}
	end;

Procedure TMyApp.InitMenuBar;

	var	R:Trect;

	begin
		GetExtent(r);
		R.B.Y:=1;
		MenuBar:=New(PMenuBar,Init(r,NewMenu(
			NewSubMenu('~T~est',hcNoContext,NewMenu(
				NewItem('~M~enu','',0,cmDoMenu,hcNoContext,
			Nil)),
		Nil))));
	end;

begin
	readln;
	MyApp.Init;
	MyApp.Run;
	MyApp.Done;
end.
Redraw