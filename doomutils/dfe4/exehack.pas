uses  DFEComm,app,dialogs,views,objects,drivers,Menus,Strings,crt,MsgBox,
		PtchComp,thngedit,HistList,Memory,AmmoEdit,ScrSav;

{Thing Editor Commands}
Const cmThingTable= 100;
		cmAmmoTable	= 101;
		cmFrameTable= 102;
		cmApplyPatch= 103;
		cmCopyItem	= 104;
		cmPasteItem = 105;
		cmAutoCreate= 106;
		cmCopySpecial=107;
		cmSaveDFEPatch	=2101;
		cmLoadDEHPatch	=2102;
		cmSaveDEHPatch	=2103;

Type	TExeHackApp=Object(TApplication)
			Constructor Init;
			Procedure Idle; virtual;
			Procedure GetEvent(var Event:TEvent); virtual;
			Procedure HandleEvent(var Event:TEvent); virtual;
			Procedure InitMenuBar; virtual;
			Procedure InitStatusLine; virtual;
			Function GetPalette:PPalette; virtual;
			Procedure EditThingTable;
			Procedure EditAmmoTable;
			Destructor Done; virtual;
		 private
			ThingEditor:PThingEditor;
			AmmoEditor:PAmmoEditor;
		end;

var ScreenSaver:PScreenSaver;

Procedure NotImplemented;

	begin
		MessageBox('Reserved for future implementation.',Nil,mfOkButton+mfInformation);
	end;

Constructor TExeHackApp.Init;

	begin
		Inherited Init;
		ScreenSaver:=New(PScreenSaver,Init(MakeMovingStarScreenSaver,120));
		DisableCommands([cmPasteItem,cmCopySpecial]);
		ThingEditor:=New(PThingEditor, Init);
		AmmoEditor:=New(PAmmoEditor, Init);
	end;

Procedure TExeHackApp.Idle;

	begin
		Inherited Idle;
		if ScreenSaver<>nil then
			ScreenSaver^.CountDown;
	end;

Procedure TExeHackApp.GetEvent(var Event:TEvent);

	begin
		Inherited GetEvent(Event);
		if Event.What<>evNothing then
			if ScreenSaver<>nil then
				if Event.What=evKeyDown then begin
					if ScreenSaver^.Saving then
						Event.What:=evNothing;
						ScreenSaver^.HeartBeat;
					end else
						if Event.What and evMouse<>0 then
							ScreenSaver^.HeartBeat;
	end;

Procedure TExeHackApp.HandleEvent(var Event:TEvent);

	begin
		TApplication.HandleEvent(Event);
		if Event.What=evKeyDown then
			if Event.KeyCode=GetAltCode('S') then
				if ScreenSaver<>nil then
					ScreenSaver^.Options;
		if Event.What=evCommand then begin
			Case Event.Command of
				cmThingTable:EditThingTable;
				cmAmmoTable:EditAmmoTable;
				cmFrameTable:NotImplemented;
				cmLoadDEHPatch:begin
					LoadDEHPatch;
					ThingEditor^.SetInputLineData(ThingEditor^.CurThing);
					ThingEditor^.DrawView;
					AmmoEditor^.SetInputLineData(AmmoEditor^.CurAmmo);
					AmmoEditor^.DrawView;
				end;
				cmSaveDEHPatch:SaveDEHPatch;
				cmSaveDFEPatch:CompilePatch;
				cmAutoCreate:NotImplemented;
				cmCopySpecial:NotImplemented;
				cmApplyPatch:ApplyPatch;
			else
				exit;
			end;
			ClearEvent(Event);
		end;
		if Event.What=evKeyDown then begin
			if Event.KeyCode=kbPgDn then
				ThingEditor^.Select;
			if Event.KeyCode=kbPgUp then
				AmmoEditor^.Select;
		end;
	end;

procedure TExeHackApp.InitMenuBar;

	var	r:TRect;

	begin
		GetExtent(r);
		R.B.Y:=1;
		MenuBar:=New(PMenuBar,Init(r,NewMenu(
			NewSubMenu('~T~ables',hcNoContext,NewMenu(
				NewItem('~T~hing Table','',0,cmThingTable,hcNoContext,
				NewItem('~A~mmo Table','',0,cmAmmoTable,hcNoContext,
				NewItem('~F~rame Table','',0,cmFrameTable,hcNoContext,
				Nil)))),
			NewSubMenu('~E~dit',hcNoContext,NewMenu(
				NewItem('~C~opy','Shift+Del',kbShiftDel,cmCopyItem,hcNoContext,
				NewItem('~P~aste','Shift+Ins',kbShiftIns,cmPasteItem,hcNoContext,
				NewItem('Copy ~S~pecial','',0,cmCopySpecial,hcNoContext,
				NewItem('~A~utoCreate','',0,cmAutoCreate,hcNoContext,
				Nil))))),
			NewSubMenu('P~a~tches',hcNoContext,NewMenu(
				NewItem('~C~ompile Patch','Alt+F9',kbAltF9,cmSaveDFEPatch,hcNoContext,
				NewItem('L~o~ad DeHacked Patch','F3',kbF3,cmLoadDEHPatch,hcNoContext,
				NewItem('S~a~ve DeHacked Patch','F2',kbF2,cmSaveDEHPatch,hcNoContext,
				NewItem('A~p~ply Patch','',0,cmApplyPatch,hcNoContext,
				Nil))))),
			Nil))))));
		end;

Procedure TExeHackApp.InitStatusLine;

	var	R:TRect;

	begin
		GetExtent(R);
		R.A.Y:=R.B.Y - 1;
		StatusLine:=New(PStatusLine, Init(R, NewStatusDef(0, $FFFF,
			NewStatusKey('~ALT-X~ Return to DFE', kbAltX, cmQuit,
			NewStatusKey('~F2~ Save', kbF2, cmSaveDEHPatch,
			NewStatusKey('~F3~ Load', kbF3, cmLoadDEHPatch,
			NewStatusKey('~ALT+F9~ Compile', kbAltF9, cmSaveDFEPatch,
			Nil)))),
		Nil)));
	end;

Function TExeHackApp.GetPalette:PPalette;

	const MyBackColor:TPalette=CColor;

	var	t:integer;

	begin
		for t:=8 to 15 do
			MyBackColor[t+24]:=MyBackColor[t];
		MyBackColor[46]:=#16;
		MyBackColor[50]:=#15;
		MyBackColor[42]:=#$2F;
		MyBackColor[17]:=#24;
		MyBackColor[47]:=#23;
		MyBackColor[48]:=#31;
		MyBackColor[49]:=#30;
		GetPalette:=@MyBackColor;
	end;

Procedure TExeHackApp.EditThingTable;

	begin
		DisableCommands([cmThingTable]);
		Desktop^.Insert(ThingEditor);
	end;

Procedure TExeHackApp.EditAmmoTable;

	begin
		DisableCommands([cmAmmoTable]);
		Desktop^.Insert(AmmoEditor);
	end;

Destructor TExeHackApp.Done;

	begin
		TProgram.Done;
		DoneHistory;
		DoneSysError;
		DoneEvents;
		DoneMemory;
		Dispose(ScreenSaver,Done);
	end;

var	TheApp:TExeHackApp;
		f:file;
		f2:text;
		InputBuff:PThingEntry;
		R:TRect;
		t:integer;
		c:integer;
		s:String[19];
		TempPtr:longint;

begin
	FrameTable:=New(PFrameTable);
	ThingTable:=New(PThingTable);
	SpriteTable:=New(PSpriteTable);
	SoundTable:=New(PSoundTable);
	WeaponTable:=New(PWeaponTable);
{$IFNDEF DEBUG}
	assign(f2, 'dfesys\thnglist.fil');
{$ELSE}
	assign(f2, 'thnglist.fil');
{$ENDIF}
	reset(f2);
	for t:=1 to 104 do begin
		readln(f2, s);
		ThingNames[t]:=NewStr(s);
	end;
	close(f2);
{$IFNDEF DEBUG}
	assign(f, 'DOOM.EXE');
{$ELSE}
	assign(f, 'D:\DOOM\DOOM.EXE');
{$ENDIF}
	reset(f,1);
	seek(f, v12ThingStart);
	for t:=1 to 103 do
		BlockRead(f, ThingTable^[t], Sizeof(TThingEntry));
	Seek(f, v12FrameStart);
	for t:=0 to 511 do
		BlockRead(f, FrameTable^[t], Sizeof(TFrameEntry));
	Seek(f, v12SoundStart);
	for t:=1 to v12SoundEntries do begin
		Seek(f, v12SoundStart+((t-1) * 36));
		BlockRead(f, TempPtr, Sizeof(Longint));
		TempPtr:=TempPtr+v12DataStart;
		Seek(f, TempPtr);
		BlockRead(f, SoundTable^[t], Sizeof(TSoundEntry));
	end;
	for t:=0 to v12SpriteEntries - 1 do begin
		Seek(f, v12SpriteStart+((t) * 4));
		BlockRead(f, TempPtr, Sizeof(Longint));
		TempPtr:=TempPtr+v12DataStart;
		Seek(f, TempPtr);
		BlockRead(f, SpriteTable^[t], Sizeof(TSpriteEntry));
	end;
	Seek(f, v12AmmoStart);
	BlockRead(f, MaxAmmoTable, Sizeof(Longint) * 4);
	BlockRead(f, PerAmmoTable, Sizeof(Longint) * 4);
	Seek(f, v12WeaponStart);
	for t:=1 to 8 do begin
		BlockRead(f,WeaponTable^[t], Sizeof(Longint) * 6);
	end;
	close(f);
	TheApp.Init;
	TheApp.Run;
	TheApp.Done;
end.

