Program PWadCompiler;

uses App,Objects,Drivers,StdDlg,MsgBox,Wad,WadDecl,PWADComp,Views,Menus,
	  DFEConfg,ListMenu,Dialogs,SuperIO,Timer,Crt,Memory,PWCDECL;

Const	cmCreatePWad	=	100;
		cmOpenWad		=	101;
		cmCloseWad		=	102;
		cmCloseProject	=	103;
		cmCompilePWad	=	104;
		cmAddLevel		=  105;
		cmAddAllLevels	=	106;
		cmRenameLevel	=	107;
		cmRemoveLevel	=	108;
		cmChangePWad	=	109;
		cmAddSound		=	110;
		cmRenameSound	=	111;
		cmAddAllSounds	=	112;
		cmAddSong 		=	114;
		cmRenameSongs	=	115;
		cmAddAllSongs	=	116;
		cmAddMisc		=	117;
		cmRenameMisc	=	118;
		cmAddAllMisc	=	119;

		cmAddLevels		=	200;
		cmAddSounds		=	201;
		cmAddSongs		=	202;
		cmAddSprites	=	203;
		cmAddMiscs		=	204;
		cmAddTextures	=	205;

Type  PPWadListBox=^TPwadListBox;
		TPWadListBox=object(TScrollerMenu)
			Constructor Init(ATitle:TTitleStr);
			Procedure HandleEvent(var Event:TEvent); virtual;
			Procedure Draw; virtual;
		end;
		PAddLevelBox=^TAddLevelBox;
		TAddLevelBox=Object(TSelectorList)
			Constructor Init(LevelList,ToLevelList:PLevelList);
			Procedure HandleEvent(var Event:TEvent); virtual;
		end;
		PAddEntryBox=^TAddEntryBox;
		TAddEntryBox=object(TDialog)
			Constructor Init;
			Procedure HandleEvent(var Event:TEvent); virtual;
			Procedure AddLevels(CurPWad:word);
			Procedure AddSprites(CurPWad:word);
			Procedure AddSounds(CurPWad:word);
			Procedure AddSongs(CurPWad:word);
			Destructor Done; virtual;
		end;
		PPWadCreator=^TPWadCreator;
		TPWadCreator=Object(TApplication)
			ProjectBox:PAddEntryBox;
			PWadListBox:PPWadListBox;
			Constructor Init;
			Procedure InitMenuBar; virtual;
			Procedure InitStatusLine; virtual;
			Procedure HandleEvent(Var Event:TEvent); virtual;
			Procedure Idle; virtual;
			Function OpenProject:word;
			Function OpenPWad:Word;
			Function ClosePWad:word;
			Procedure CloseProject;
			Procedure CompilePWad;
			Destructor Done; virtual;
		end;

Var	InputPWads:PWadCollection;
		OutputPWad:PPWadDef;
		CurDir:String;
		CurrentPWad:integer;
		ProjectUpdated:boolean;

Function GetWadName(WDir:PWadDirectory):string;

	var	TempStr:String[8];

	begin
		TempStr:='        ';
		move(WDir^.WadName[1], Tempstr[1], 8);
		GetWadName:=RTrim(TempStr);
	end;

{TPWadListBox Object Declatations---------------------------------------}

Constructor TPwadListBox.Init(Atitle:TTitleStr);

	var   R:Trect;

	begin
		Inherited Init(ATitle, InputPWads);
		R.Assign(35,8,45,10);
		Insert(New(PButton, Init(R,'~C~ancel',cmCancel,bfNormal)));
		if InputPWads^.Count > 0 then begin
			R.Assign(35,6,45,8);
			Insert(New(PButton, Init(R,'~O~k',cmOk,bfDefault)));
			ListScroller^.Select;
		end;
	end;

Procedure TPwadListBox.HandleEvent(var Event:TEvent);

	begin
		if (Event.What = evBroadcast) and (Event.Command = cmItemFocused) then
			DrawView;
		inherited HandleEvent(Event);
	end;

Procedure TPWadListBox.Draw;

	var   B:TDrawBuffer;
			S:String;
			TempStr:string;

	begin
		Inherited Draw;
		if MenuList^.Count > 0 then begin
			S:=String(MenuList^.At(ListScroller^.Focused)^);
			MoveChar(B, ' ', GetColor(1), Size.X);
			TempStr:='File: '+S+'.WAD';
			MoveStr(B,TempStr,GetColor(1));
			WriteLine(2, Size.Y-5, Size.X-4, 1, B);
			MoveChar(B, ' ', GetColor(1), Size.X);
			Str(OutputPWad^.CheckDependancy(InputPWads^.At(ListScroller^.Focused)^.Dir),S);
			TempStr:='Entries in use: '+S;
			MoveStr(B,TempStr,GetColor(1));
			WriteLine(2, Size.Y-3, Size.X-4, 1, B);
		end;
	end;

{TAddEntryBox Object Declatations---------------------------------------}

Constructor TAddEntryBox.Init;

	var	R:TRect;

	begin
		R.Assign(5,1,75,21);
		TDialog.Init(R, 'PWad Editor');
		Flags:=0;
		R.Assign(3,1,19,2);
		Insert(New(PStaticText, Init(R, 'Current Project:')));
		R.Assign(30,1,50,2);
		Insert(New(PStaticText, Init(R, 'Current PWad:')));
		R.Assign(25,3,65,4);
		Insert(New(PStaticText, Init(R, 'Change Default Input PWad')));
		R.Assign(3,3,19,5);
		Insert(New(PButton, Init(R,'~C~hange PWad',cmChangePWad,bfNormal)));
		R.Assign(25,5,65,6);
		Insert(New(PStaticText, Init(R, 'Add Levels to PWad')));
		R.Assign(3,5,19,7);
		Insert(New(PButton, Init(R,'Add ~L~evels',cmAddLevels,bfNormal)));
		R.Assign(25,7,65,8);
		Insert(New(PStaticText, Init(R, 'Add Sounds to PWad')));
		R.Assign(3,7,19,9);
		Insert(New(PButton, Init(R,'Add ~S~ounds',cmAddSounds,bfNormal)));
		R.Assign(25,9,65,10);
		Insert(New(PStaticText, Init(R, 'Add Songs to PWad')));
		R.Assign(3,9,19,11);
		Insert(New(PButton, Init(R,'Add S~o~ngs',cmAddSongs,bfNormal)));
		R.Assign(25,11,65,12);
		Insert(New(PStaticText, Init(R, 'Add Sprites to PWad')));
		R.Assign(3,11,19,13);
		Insert(New(PButton, Init(R,'Add Sp~r~ites',cmAddSprites,bfNormal)));
		R.Assign(25,13,65,14);
		Insert(New(PStaticText, Init(R, 'Add Textures to PWad')));
		R.Assign(3,13,19,15);
		Insert(New(PButton, Init(R,'Add ~T~extures',cmAddTextures,bfNormal)));
		R.Assign(25,15,65,16);
		Insert(New(PStaticText, Init(R, 'Add Misc Entries to PWad')));
		R.Assign(3,15,19,17);
		Insert(New(PButton, Init(R,'Add ~M~isc',cmAddTextures,bfNormal)));
	end;

Procedure TAddEntryBox.HandleEvent(var Event:TEvent);

	var	PWadList:PPWadListBox;

	begin
		TDialog.HandleEvent(Event);
		if Event.What=evCommand then begin
			case Event.Command of
				cmChangePWad:begin
					PWadList:=New(PPWadListBox, Init('Select Default PWad'));
					if DeskTop^.ExecView(PWadList) = cmOk then
						CurrentPWad:=PWadList^.Selected;
					Dispose(PWadList, Done);
				end;
				cmAddLevels:begin
					if InputPWads^.Count = 0 then begin
						ErrorBox('You must first open a PWad before Adding Levels');
						exit;
					end;
					AddLevels(CurrentPWad);
				end;
				cmAddSprites:begin
					if InputPWads^.Count = 0 then begin
						ErrorBox('You must first open a PWad before Adding Sprites');
						exit;
					end;
					AddSprites(CurrentPWad);
				end;
			end;
		end;
	end;

Procedure TAddEntryBox.AddLevels(CurPWad:word);

	var 	x,e,t,m,p:word;
			s:string[8];
			TempName:ObjNameStr;
			TempEntry:PPWadLevelEntry;
			LevelEntry:PGroupDir;
			LevelList,ToLevelList:PLevelList;
			WDir:PWadDirectory;
			AddLevelBox:PAddLevelBox;

	begin
		WDir:=InputPWads^.At(CurPWad)^.Dir;
		LevelList:=New(PLevelList, Init(27,1));
		for e:=1 to 3 do begin
			for m:=1 to 9 do begin
				TempName:='        ';
				TempName[1]:='E';
				TempName[3]:='M';
				Str(e, s);
				TempName[2]:=s[1];
				Str(m, s);
				TempName[4]:=s[1];
				p:=WDir^.FindObject(TempName);
				if p = 0 then Continue;
				Inc(p);
				if WDir^.DirEntry^[p].ObjName<>'THINGS  ' then begin
					New(TempEntry);
					TempEntry^.Name:='        ';
					Move(WDir^.DirEntry^[p-1].ObjName[1], TempEntry^.Name[1], 8);
					TempEntry^.EntryNum:=p - 1;
					LevelList^.Insert(TempEntry);
				end;
			end;
		end;
		if LevelList^.Count = 0 then begin
			MessageBox('No Levels to Add!',Nil,mfOkButton + mfError);
			Dispose(LevelList, Done);
		end;
		ToLevelList:=New(PLevelList, Init(27,1));
		AddLevelBox:=New(PAddLevelBox, Init(LevelList,ToLevelList));
		if (Desktop^.ExecView(AddLevelBox)=cmOk) and (AddLevelBox^.ToList^.Count > 0) then begin
			for t:=0 to (ToLevelList^.Count - 1) do begin
				New(LevelEntry);
				FillChar(LevelEntry^, SizeOf(TGroupDir), #00);
				LevelEntry^.Owner:=TPWadEntry(InputPWads^.At(CurrentPWad)^).Dir;
				TempEntry:=AddLevelBox^.ToList^.At(t);
				LevelEntry^.EntryNum:=TempEntry^.EntryNum;
				Move(TempEntry^.Name[1],LevelEntry^.NewName[1],Ord(TempEntry^.Name[0]));
				LevelEntry^.EntryNum:=TempEntry^.EntryNum;
				OutputPWad^.Insert(LevelEntry);
				for x:=1 to 10 do begin
					New(LevelEntry);
					FillChar(LevelEntry^, SizeOf(TGroupDir), #00);
					LevelEntry^.Owner:=TPWadEntry(InputPWads^.At(CurrentPWad)^).Dir;
					TempEntry:=AddLevelBox^.ToList^.At(t);
					LevelEntry^.EntryNum:=TempEntry^.EntryNum + x;
					Move(LevelEntry^.Owner^.DirEntry^[LevelEntry^.EntryNum].ObjName,
						LevelEntry^.NewName,8);
					OutputPWad^.Insert(LevelEntry);
				end;
			end;
		end;
		Dispose(AddLevelBox, Done);
		Dispose(LevelList, Done);
		Dispose(ToLevelList, Done);
	end;

Procedure TAddEntryBox.AddSprites(CurPWad:word);

	begin

	end;

Procedure TAddEntryBox.AddSounds(CurPWad:word);

	begin

	end;

Procedure TAddEntryBox.AddSongs(CurPWad:word);

	begin

	end;

Destructor TAddEntryBox.Done;

	begin
		TDialog.Done;
	end;

{TAddLevelBox Object Declarations---------------------------------------}

Constructor TAddLevelBox.Init(LevelList,ToLevelList:PLevelList);

	var	R:Trect;

	begin
		Inherited Init('Add Levels', LevelList, ToLevelList);
		R.Assign(25,3,45,5);
		Insert(New(PButton, Init(R,'~A~dd ->',cmAddLevel,bfNormal)));
		R.Assign(25,5,45,7);
		Insert(New(PButton, Init(R,'~R~ename ->',cmAddLevel,bfNormal)));
		R.Assign(25,7,45,9);
		Insert(New(PButton, Init(R,'Add A~l~l ->',cmAddAllLevels,bfNormal)));
		R.Assign(25,9,45,11);
		Insert(New(PButton, Init(R,'<- R~e~move',cmRemoveLevel,bfNormal)));
		R.Assign(25,11,45,13);
		Insert(New(PButton, Init(R,'~D~one',cmOk,bfNormal)));
	end;

Procedure TAddLevelBox.HandleEvent(var Event:TEvent);

	var	t:integer;

	begin
		Inherited HandleEvent(Event);
		if Event.What=evCommand then begin
			case Event.Command of
				cmAddLevel:begin
					MoveTo(FromScroller^.Focused);
					ProjectUpdated:=True;
				end;
				cmAddAllLevels:for t:=1 to FromList^.Count do begin
					MoveTo(0);
					ProjectUpdated:=True;
				end;
				cmRemoveLevel:begin
					MoveFrom(ToScroller^.Focused);
					ProjectUpdated:=True;
				end;
			end;
		end;
	end;

{TPWadCreator Object Declatations---------------------------------------}

Constructor TPWadCreator.Init;

	var	t:integer;

	begin
		TApplication.Init;
		InitTimer;
		ClearTimer;
		ChDir('\BP\DOOM\WHTK');
		GetDir(0, CurDir);
		DisableCommands([cmCloseProject,cmCompilePWad,cmCloseWad,cmOpenWad]);
		InitDefaults;
		ChDir(DFEDefaults.PWadPath);
		InputPWads:=New(PWadCollection, Init(10,0));
	end;

Procedure TPWadCreator.InitMenuBar;

	var   r:TRect;

	begin
		GetExtent(r);
		R.B.Y:=1;
		MenuBar:=New(PMenuBar,Init(r,NewMenu(
			NewSubMenu('~P~roject',hcNoContext,NewMenu(
				NewItem('~C~reate','',0,cmCreatePWad,hcNoContext,
				NewItem('~C~lose','',0,cmCloseProject,hcNoContext,
				NewItem('~E~xit','',0,cmQuit,hcNoContext,
			Nil)))),
			NewSubMenu('P~W~ads',hcNoContext,NewMenu(
				NewItem('~O~pen PWad','F3',kbF3,cmOpenWad,hcNoContext,
				NewItem('~C~lose PWad','Alt-F3',kbAltF3,cmCloseWad,hcNoContext,
			Nil))),
		Nil)))));
	end;

Procedure TPWadCreator.InitStatusLine;

	var	R:TRect;

	begin
		GetExtent(R);
		R.A.Y:=R.B.Y - 1;
		StatusLine:=New(PStatusLine, Init(R, NewStatusDef(0, $FFFF,
			NewStatusKey('~ALT-X~ Return to DFE', kbAltX, cmQuit,
			NewStatusKey('~ALT+F9~ Compile', kbAltF9, cmCompilePWad,
			Nil)),
		Nil)));
	end;

Procedure TPWadCreator.HandleEvent(var Event:TEvent);

	begin
		TApplication.HandleEvent(Event);
		if Event.What=EvCommand then begin
			case Event.Command of
				cmCreatePWad:OpenProject;
				cmOpenWad:OpenPWad;
				cmCloseWad:ClosePWad;
				cmCloseProject:CloseProject;
				cmCompilePWad:CompilePWad;
			end;
		end;
	end;

Procedure TPWadCreator.Idle;

	begin
		TApplication.Idle;
		if TimerTicks >= 2 then begin
			GotoXy(70,1);
			write(MemAvail);
			ClearTimer;
		end;
	end;

Function TPWadCreator.OpenProject:word;

	var 	TempStr,NewWad:String;
			t,Control:word;

	begin
		Repeat
			NewWad:='';
			Control:=InputBox('Create PWad','PWad Name',NewWad,12);
			if Control <> cmOk then
				Exit;
			for t:=1 to length(NewWad) do
				NewWad[t]:=UpCase(NewWad[t]);
			if Pos('.',NewWad)=0 then
				NewWad:=NewWad+'.WAD';
			if Pos('.WAD', NewWad)=0 then
				ErrorBox('PWads MUST have a .WAD extention!')
			else
				Break;
		until False;
		DisableCommands([cmCreatePWad]);
		EnableCommands([cmCloseProject,cmCompilePWad,cmOpenWad]);
		ProjectUpdated:=False;
		OutputPWad:=New(PPWadDef, Init(NewWad));
		ProjectBox:=New(PAddEntryBox, Init);
		Desktop^.Insert(ProjectBox);
{		for t:=1 to 2000 do begin
			OutputPWad^.AddEntry(InputPWads[1],t,InputPwads[1]^.DirEntry^[t].ObjName);
		end;}
	end;

Function TPWadCreator.OpenPWad:word;

	var	FileBox:PFileDialog;
			Control:word;
			FileName:String;
			t:integer;
			TE:PPWadEntry;

	begin
		if InputPWads^.Count = 10 then begin
			ErrorBox('A maximum 10 PWads can be opened at once.');
			Exit;
		end;
		FileBox:=New(PFileDialog, Init('*.WAD','Open PWad','*.WAD',fdOpenButton,100));
		Control:=DeskTop^.ExecView(FileBox);
		if Control=cmFileOpen then
			Control:=cmOk;
		if Control=cmOk then begin
			FileBox^.GetFileName(FileName);
			if Pos('.',FileName) = 0 then
				FileName:=FileName + '.WAD';
			TerminateOnWadError:=False;
			New(TE);
			TE^.Dir:=New(PWadDirectory, Init(FileName));
			Dispose(FileBox, Done);
			if WadResult <> 0 then begin
				ErrorBox(WadResultMsg(WadResult));
				exit;
			end;
			TE^.NameStr:=GetWadName(TE^.Dir);
			InputPWads^.Insert(TE);
			EnableCommands([cmCloseWad]);
			exit;
		end;
		Dispose(FileBox, Done);
	end;

Function TPwadCreator.ClosePWad:word;

	var	Sel,Control:word;
			Temp:PPWadEntry;

	begin
		if InputPWads^.Count = 0 then begin
			ErrorBox('No PWads currently open!');
			exit;
		end;
		PWadListBox:=New(PPWadListBox, Init('Close PWad'));
		Control:=Desktop^.Execview(PWadListBox);
		if Control=cmOk then begin
			Sel:=PWadListBox^.Selected;
			Dispose(PWadListBox, Done);
			if OutputPWad^.CheckDependancy(InputPWads^.At(Sel)^.Dir) > 0 then begin
				if MessageBox('Selected PWad has entries in use, close anyway?',Nil,
					mfYesButton + mfNoButton) = cmNo then begin
						Dispose(PWadListBox, Done);
						Exit;
				end;
																																																						OutputPWad^.DeleteWithOwner(InputPWads^.At(Sel)^.Dir);
			end;
			Temp:=InputPWads^.At(CurrentPWad);
			Dispose(InputPWads^.At(Sel)^.Dir, Done);
			InputPWads^.AtFree(Sel);
			if CurrentPWad = Sel then
				CurrentPWad:=0
			else
				CurrentPWad:=InputPWads^.IndexOf(Temp);
			exit;
		end;
		Dispose(PWadListBox, Done);
	end;

Procedure TPWadCreator.CloseProject;

	var t,Control:word;

	begin
		if ProjectUpdated then begin
			Control:=MessageBox('Changes have been made since last compile, Continue?',
				Nil,mfYesButton + mfNoButton + mfWarning);
			if Control=cmNo then
				Exit;
		end;
		if InputPWads^.Count > 0 then begin
			for t:=0 to (InputPWads^.Count - 1) do
				Dispose(InputPWads^.At(t)^.Dir, Done);
			InputPWads^.FreeAll;
		end;
		Dispose(OutputPWad, Done);
		Dispose(ProjectBox, Done);
		EnableCommands([cmCreatePWad]);
		DisableCommands([cmCloseProject,cmCompilePWad]);
	end;

Procedure TPWadCreator.CompilePWad;

	begin
		ProjectUpdated:=False;
		if OutputPWad^.Count = 0 then begin
			ErrorBox('No entries to compile.');
			exit;
		end;
		OutputPWad^.Compile;
	end;

Destructor TPWadCreator.Done;

	begin
		TApplication.Done;
		ChDir(CurDir);
	end;

var PWadCreator:TPWadCreator;

begin
	PWadCreator.Init;
	PWadCreator.Run;
	PWadCreator.Done;
end.