uses App,Drivers,Dialogs,MsgBox,Objects,ListMenu,Menus,Views,StdDlg;

const	cmNewPWad	=	100;
		cmSavePWad	=	101;

Type	PDirEntry=^TDirEntry;
		TDirEntry=record
			Start		:longint;
			Size		:longint;
			Name		:array[1..8] of char;
		end;
		PWadHeader=^TWadHeader;
		TWadHeader=record
			ID				:array[1..4] of char;
			DirEntries  :longint;
			DirStart		:longint;
		end;
		PDirStruct=^TDirStruct;
		TDirStruct=array[0..16000] of PDirEntry;
		TMyApp=object(TApplication)
			PWad:File;
			PWadName:string;
			WadDir:PDirStruct;
			Constructor Init;
			Procedure HandleEvent(var Event:TEvent); virtual;
			Procedure InitMenuBar; virtual;
			Procedure NewPWad;
			Destructor Done; virtual;
		end;

Constructor TMyApp.Init;

	begin
		Inherited Init;
		DisableCommands([cmSavePWad]);
	end;

Procedure TMyApp.InitMenuBar;

	var	r:TRect;

	begin
		GetExtent(r);
		R.B.Y:=1;
		MenuBar:=New(PMenuBar,Init(r,NewMenu(
			NewSubMenu('~C~ompile',hcNoContext,NewMenu(
				NewItem('~N~ew PWad','',0,cmNewPWad,hcNoContext,
				NewItem('~S~ave PWad','',0,cmSavePWad,hcNoContext,
				Nil))),
			Nil))));
		end;

Procedure TMyApp.HandleEvent(var Event:TEvent);

	begin
		Inherited HandleEvent(Event);
		if Event.What=evCommand then begin
			Case Event.Command of
				cmNewPWad:NewPWad;
			end;
		end;
	end;

Destructor TMyApp.Done;

	begin
		Inherited Done;
	end;

Procedure TMyApp.NewPWad;

	var	fd:PFileDialog;
			Control:word;
			FileName:String;

	begin
		fd:=New(PFileDialog, init('*.WAD','Create New PWad','Name', fdOkButton, 100));
		Control:=DeskTop^.ExecView(fd);
		if Control=cmOk then begin
			fd^.GetFileName(FileName);
			Dispose(fd, Done);
			if Pos('.', FileName)=0 then
				FileName:=FileName+'.WAD';
			assign(Pwad, FileName);
			rewrite(PWad, 1);
			PWadName:=FileName;
			EnableCommands([cmSavePWad]);
			DisableCommands([cmNewPWad]);
		 end
		else
			Dispose(fd, Done);
	end;

var	MyApp:TMyApp;

begin
	MyApp.Init;
	MyApp.Run;
	MyApp.Done;
end.