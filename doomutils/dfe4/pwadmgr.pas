uses 	app,dialogs,objects,drivers,dos,stddlg,msgbox,views,Menus,crt,ListMenu,
		AutoValidate,ScrSav,DFECONFG,StatusBox,Gauges,DOS2,PWadComp;

const cmCreateList   =  100;
		cmEditList     =  101;
		cmLoadList		=	102;
		cmDeletePWad   =  103;
		cmNextPWad		=  104;
		cmPrevPWad		=  105;
		cmJumpPWad		=  106;
		cmCreatePWad	=	200;

type  PPWadDesc=^TPWadDesc;
		TPWadDesc=record
			Name     :string[8];
			Size     :longint;
			FileName :pathstr;
			Desc     :string[50];
			Attr     :longint;
			PlayCnt  :longint;
		end;
		PPwadList=^TPWadList;
		TPWadList=Object(TCollection)
		end;
		PPWadManager=^TPWadManager;
		TPWadManager=object(TApplication)
			Constructor Init;
			Procedure Idle; virtual;
			Procedure GetEvent(var Event:TEvent); virtual;
			Procedure HandleEvent(var Event:TEvent); virtual;
			Procedure InitMenuBar; virtual;
			Destructor Done; virtual;
		end;
		PPWadEditWindow=^TPWadEditWindow;
		TPWadEditWindow=Object(TDialog)
			PWadName:PStaticText;
			PWadDesc:PInputLine;
			PWadAttr:PCheckBoxes;
			CurIndex:integer;
			Constructor Init(Index:integer);
			Procedure HandleEvent(Var Event:TEvent); virtual;
			Procedure UpdatePWadList;
			Procedure UpdateEditWindow;
		end;
		PPwadJumpList=^TPWadJumpList;
		TPWadJumpList=Object(TScrollerMenu)
			Constructor Init;
			Procedure HandleEvent(var Event:TEvent); virtual;
			Procedure Draw; virtual;
		end;

var   PWadList:PPWadList;
		ScreenSaver:PScreenSaver;

Procedure SavePWadList;

	var   F:File of TPWadDesc;
			t:integer;

	begin
		Assign(F, 'PWAD.DSC');
		Rewrite(F);
		For t:=0 to PWadList^.Count - 1 do
			write(F, TPWadDesc(PWadList^.At(t)^));
		Close(f);
	end;

Procedure CollectPWadList;

	var   InfoBox:PStatusBox;
			t:integer;
			CDBox:PChDirDialog;
			R:TRect;
			CurDir,WadDir:String;
			SR:SearchRec;
			TempDesc:PPWadDesc;
			Validator:PPWadAutoValidator;
			P:TPoint;
			Event:Tevent;

	begin
		P.X:=20;
		P.Y:=7;
		GetDir(0, CurDir);
		ChDir('D:\DOOM\WADS');
		GetDir(0, WadDir);
		InfoBox:=New(PStatusBox, Init(P,FilesInDir(WadDir+'\*.WAD ', AnyFile),
		'Collecting PWAD List...','Status'));
		DeskTop^.Insert(InfoBox);
		FindFirst(WadDir+'\*.WAD', AnyFile, SR);
		If DOSError <> 0 then begin
			Dispose(InfoBox, Done);
			MessageBox('Could not locate any PWADs in the specified directory!',Nil,
				mfInformation+mfOkButton);
			Dispose(CDBox, Done);
			ChDir(CurDir);
			Exit;
		end;
		while DosError = 0 do begin
			TempDesc:=New(PPwadDesc);
			FillChar(TempDesc^, Sizeof(TPwadDesc), #00);
			With TempDesc^ do begin
				For t:=1 to 12 do
					if SR.Name[t] <> '.' then
						Name:=Name+SR.Name[t]
					else
						Break;
				Size:=SR.Size;
				Desc:='';
				Attr:=0;
				PlayCnt:=0;
				Event.What := evBroadcast;
				Event.Command := cmAddGauge;
				Event.InfoLong := 1;
				InfoBox^.StatBar^.HandleEvent(Event);
			end;
			PWadList^.Insert(TempDesc);
			Validator:=New(PPWadAutoValidator, Init(WadDir+'\'+SR.Name));
			Validator^.Validate;
			Dispose(Validator, Done);
			FindNext(SR);
		end;
		Dispose(InfoBox, Done);
		ChDir(CurDir);
		SavePWadList;
	end;

Procedure EnterPWadDescriptions;

	var   R:TRect;
			EditWindow:PPWadEditWindow;
			SelWindow:PPWadJumpList;

	begin
		if (PWadList = Nil) or (PWadList^.Count = 0) then begin
			MessageBox('No PWads in list.',Nil,mfError + mfOkButton);
			exit;
		end;
		EditWindow:=New(PPWadEditWindow, Init(0));
		DeskTop^.ExecView(EditWindow);
		Dispose(EditWindow, Done);
	end;

Procedure DelPWad(Index:integer);

	var   P:PPWadDesc;

	begin
		P:=PWadList^.At(Index);
		if MessageBox('Delete PWAD: '+P^.Name+'?',Nil,mfConfirmation+
			mfYesButton+mfNoButton)=cmYes then begin
			PWadList^.AtDelete(Index);
			Dispose(P);
		end;
	end;

Procedure LoadPWadList;

	var   F:File of TPWadDesc;
			t:integer;
			TempDesc:PPwadDesc;

	begin
		Assign(F, 'PWAD.DSC');
		Reset(F);
		While Not eof(F) do begin
			New(TempDesc);
			Read(F, TempDesc^);
			PWadList^.Insert(TempDesc);
		end;
		Close(f);
	end;

{PWAD Jump List Object----------------------------------------------------}

Constructor TPwadJumpList.Init;

	var   R:Trect;

	begin
		Inherited Init('PWad Jump List', PWadList);
		R.Assign(35,8,45,10);
		Insert(New(PButton, Init(R,'~C~ancel',cmCancel,bfNormal)));
		if PWadList^.Count > 0 then begin
			R.Assign(35,6,45,8);
			Insert(New(PButton, Init(R,'~O~k',cmOk,bfDefault)));
			ListScroller^.Select;
		end;
	end;

Procedure TPwadJumpList.HandleEvent(var Event:TEvent);

	begin
		if (Event.What = evBroadcast) and (Event.Command = cmItemFocused) then
			DrawView;
		inherited HandleEvent(Event);
	end;

Procedure TPWadJumpList.Draw;

	var   B:TDrawBuffer;
			P:PPwadDesc;
			TempStr:string;

	begin
		Inherited Draw;
		if MenuList^.Count > 0 then begin
			P:=MenuList^.At(ListScroller^.Focused);
			MoveChar(B, ' ', GetColor(1), Size.X);
			TempStr:='Description: ';
			MoveStr(B,TempStr,GetColor(1));
			WriteLine(2, Size.Y-5, Size.X-4, 1, B);
			MoveChar(B, ' ', GetColor(1), Size.X);
			MoveStr(B,P^.Desc,GetColor(1));
			WriteLine(2, Size.Y-4, Size.X-4, 1, B);
			MoveChar(B, ' ', GetColor(1), Size.X);
			Str(P^.Size, TempStr);
			TempStr:='Size: '+TempStr;
			MoveStr(B,TempStr,GetColor(1));
			WriteLine(2, Size.Y-2, Size.X-4, 1, B);
		end;
	end;

{PWAD Edit Window Object--------------------------------------------------}

Constructor TPWadEditWindow.Init(Index:integer);

	var	R:Trect;

	begin
		R.Assign(5,3,70,20);
		inherited Init(R, 'Edit PWAD Descriptions');
		R.Assign(2,2,12,3);
		Insert(New(PStaticText, Init(R, 'PWad Name:')));
		R.Assign(13,2,22,3);
		PWadName:=New(PStaticText, Init(R, TPWadDesc(PWadList^.At(Index)^).Name));
		Insert(PWadName);
		R.Assign(2,4,14,5);
		Insert(New(PStaticText, Init(R, 'Description:')));
		R.Assign(2,5,54,6);
		PWadDesc:=New(PInputLine, Init(R, 50));
		PWadDesc^.Data^:=TPWadDesc(PWadList^.At(Index)^).Desc;
		R.Assign(2,7,21,11);
		PWadAttr:=New(PCheckBoxes, Init(R,
			NewSItem('D~e~athMatch',
			NewSItem('Co~O~perative',
			NewSItem('~S~ound PWad',
			NewSItem('~G~raphics PWad',
			Nil))))));
		PWadAttr^.Value:=TPWadDesc(PWadList^.At(Index)^).Attr;
		Insert(PWadAttr);
		R.Assign(20,14,28,16);
		Insert(New(PButton, Init(R,'~N~ext',cmNextPWad,bfDefault)));
		R.Assign(30,14,38,16);
		Insert(New(PButton, Init(R,'~P~rev',cmPrevPWad,bfNormal)));
		R.Assign(40,14,48,16);
		Insert(New(PButton, Init(R,'~J~ump',cmJumpPWad,bfNormal)));
		R.Assign(50,14,58,16);
		Insert(New(PButton, Init(R,'~D~one',cmOk,bfNormal)));
		R.Assign(5,14,15,16);
		Insert(New(PButton, Init(R,'Delete',cmDeletePWad,bfNormal)));
		Insert(PWadDesc);
		CurIndex:=Index;
		Flags:=1;
	end;

Procedure TPWadEditWindow.HandleEvent(var Event:TEvent);

	var	SelWindow:PPwadJumpList;

	begin
		if Event.What=evCommand then begin
			case Event.Command of
				cmNextPWad:begin
					UpdatePwadList;
					if CurIndex < (PWadList^.Count - 1) then begin
						Inc(CurIndex);
						UpdateEditWindow;
					end;
					ClearEvent(Event);
				end;
				cmPrevPWad:begin
					UpdatePWadList;
					if CurIndex > 0 then begin
						Dec(CurIndex);
						UpdateEditWindow;
					end;
					ClearEvent(Event);
				end;
				cmJumpPWad:begin
					UpdatePWadList;
					SelWindow:=New(PPWadJumpList, Init);
					if DeskTop^.ExecView(SelWindow)=cmOk then begin
						CurIndex:=SelWindow^.Selected;
						UpdateEditWindow;
					end;
				end;
				cmOk,cmCancel:begin
					if PWadList^.Count > 0 then
						UpdatePWadList;
					SavePWadList;
				end;
				cmDeletePWad:begin
					UpdatePWadList;
					DelPWad(CurIndex);
					if PWadList^.Count=0 then begin
						MessageBox('PWadList is empty.',Nil,mfInformation+mfOkButton);
						Message(@Self,evCommand,cmCancel,Nil);
					end else begin
						if CurIndex >= PWadList^.Count then
							CurIndex:=PWadList^.Count - 1;
						UpdateEditWindow;
					end;
				end;
			end;
		end;
		Inherited HandleEvent(Event);
	end;

Procedure TPWadEditWindow.UpdatePWadList;

	begin
		TPWadDesc(PWadList^.At(CurIndex)^).Desc:=PWadDesc^.Data^;
		TPWadDesc(PWadList^.At(CurIndex)^).Attr:=PWadAttr^.Value;
	end;

Procedure TPWadEditWindow.UpdateEditWindow;

	begin
		PWadDesc^.Data^:=TPWadDesc(PWadList^.At(CurIndex)^).Desc;
		PWadDesc^.SelectAll(True);
		PWadAttr^.Value:=TPWadDesc(PWadList^.At(CurIndex)^).Attr;
		PWadName^.Text^:=TPWadDesc(PWadList^.At(CurIndex)^).Name;
		Redraw;
	end;

{PWAD Manager Application Object-------------------------------------------}

Constructor TPWadManager.Init;

	begin
{     SetVideoMode(smCO80 + smFont8x8);}
		Inherited Init;
		ScreenSaver:=New(PScreenSaver,Init(MakeMovingStarScreenSaver,120));
		PWadList:=New(PPWadList, Init(10,5));
		InitDefaults;

	end;

Procedure TPWadManager.Idle;

	begin
		Inherited Idle;
		if ScreenSaver<>nil then
			ScreenSaver^.CountDown;
{		Gotoxy(70,1);
		write(MemAvail);}
	end;

Procedure TPwadManager.GetEvent(var Event:TEvent);

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

Procedure TPWadManager.HandleEvent(var Event:TEvent);

	begin
		Inherited HandleEvent(Event);
		if Event.What=evKeyDown then
			if Event.KeyCode=GetAltCode('S') then
				if ScreenSaver<>nil then
					ScreenSaver^.Options;
		if Event.What = evCommand then begin
			case Event.Command of
				cmCreateList:CollectPWadList;
				cmEditList:EnterPWadDescriptions;
				cmLoadList:LoadPWadList;
				cmCreatePWad:CreatePWad;
			end;
		end;
	end;

Procedure TPWadManager.InitMenuBar;

	var   r:TRect;

	begin
		GetExtent(r);
		R.B.Y:=1;
		MenuBar:=New(PMenuBar,Init(r,NewMenu(
			NewSubMenu('~L~ist',hcNoContext,NewMenu(
				NewItem('~L~oad','',0,cmLoadList,hcNoContext,
				NewItem('~C~reate','',0,cmCreateList,hcNoContext,
				NewItem('~E~dit','',0,cmEditList,hcNoContext,
			Nil)))),
			NewSubMenu('~C~ompiler',hcNoContext,NewMenu(
				NewItem('~C~reate PWad','',0,cmCreatePWad,hcNoContext,
			Nil)),
		Nil)))));
	end;

Destructor TPWadManager.Done;

	begin
		Inherited Done;
		Dispose(ScreenSaver,Done);
	end;

var   PWadManager:TPWadManager;

begin
	PWadManager.Init;
	PWadManager.Run;
	PWadManager.Done;
end.
