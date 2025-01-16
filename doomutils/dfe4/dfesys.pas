{****************************************************************************
*                      The DOOM Hacker's Tool Kit                           *
*****************************************************************************
* Program: DFE v2.50                                                        *
* Purpose: DOOM 2.50 Front End                                              *
* Date:    6/27/94                                                          *
* Author:  Joshua Jackson        Internet: jsoftware@delphi.com             *
****************************************************************************}

uses 	DFEComm,app,objects,menus,views,memory,dialogs,strings,Dos,crt,Timer,
		Wad,StdDlg,MsgBox,DFEConfg,IPXFER,HistList,sbc,DFEMenus,
		ItemLoc1,Drivers,scrsav;

const	cmOnePlayerMenu	= 100;
		cmSerialMenu		= 101;
		cmIPXMenu			= 102;
		cmModemMenu			= 103;
		cmViewMaps			= 105;
		cmOnePlayerConfig = 106;
		cmSerialConfig		= 107;
		cmIPXConfig			= 108;
		cmModemConfig		= 109;
		cmPWADconfig		= 110;
		cmIPXsend			= 111;
		cmIPXrec				= 112;
		cmSoundPlayer		= 113;
		cmSoundConfig		= 114;
		cmItemLocator		= 116;
		cmTagAssociate		= 117;
		cmMapStats			= 118;
		cmExeHacker			= 119;
		cmPWadPathConfig	= 120;
		cmPlayDemo			= 121;
		cmNull				= 255;

		gtNormal				= 00;
		gtIPXNet				= 01;
		gtModem				= 02;
		gtDirLinkModem		= 03;
		gtSerial				= 04;

		v12FileSize			= 580391;

Const	Restart:boolean = false;

type	PMyApp=^TMyApp;
		TMyApp=Object(Tapplication)
			Constructor Init;
			Procedure QueryRestart;
			Procedure InitMenuBar; virtual;
			Procedure InitSound;
			Procedure Idle; virtual;
			Procedure GetEvent(var Event:TEvent); virtual;
			Procedure HandleEvent(Var Event:TEvent); virtual;
			Function GetPalette:PPalette; virtual;
			Procedure RunDoom(GameType:integer;Params:string);
			Procedure OnePlayerMenu;
			Procedure SerialMenu;
			Procedure IPXMenu;
			Procedure ModemMenu;
			Procedure PlayDemo;
			Procedure LocateItems;
			Procedure SendNet;
			Procedure RecNet;
			Procedure ExeHacker;
			Destructor Done; virtual;
		end;
		SelLevelArray=array[1..4] of PCluster;

var	MyApp:TMyApp;
		Debug:boolean;
		ScreenSaver:PScreenSaver;

Constructor TMyApp.Init;

	var 	Regs:Registers;
			E:TEvent;
			AboutBox:PWindow;
			R:TRect;
			ch:char;
			WDir:PWadDirectory;

	begin
		TApplication.Init;
		ScreenSaver:=New(PScreenSaver,Init(MakeMovingStarScreenSaver,120));
		EnableCommands([100..255]);
		if not Debug then begin
			R.Assign(28,6,52,15);
			AboutBox:=New(PWindow,Init(R,'',0));
			With AboutBox^ do begin
				Flags:=0;
				R.Assign(4,2,21,3);
				Insert(New(PStaticText,Init(R,'DOOM! Front End')));
				R.Assign(11,4,13,5);
				Insert(New(PStaticText,Init(R,'by')));
				R.Assign(4,6,21,7);
				Insert(New(PStaticText,Init(R,'Jackson Software')));
			end;
			Desktop^.Insert(AboutBox);
			delay(1000);
			Desktop^.Delete(AboutBox);
			Dispose(AboutBox,Done);
		end;
		InitDefaults;
		if DFEDefaults.Sound.UseSound then
			InitSound
		else
			DisableCommands([cmSoundPlayer]);
		Regs.ax:=$7A00;
		Intr($2F,Regs);
		if Regs.al <> $FF then
			DisableCommands([cmIPXMenu,cmIPXSend,cmIPXrec]);
		while keypressed do
			ch:=ReadKey;
		E.What:=evKeyDown;
		E.Command:=evKeyDown;
		E.KeyCode:=kbAltG;
		PutEvent(E);
	end;

Procedure TMyApp.QueryRestart;

	var 	Control:word;

	begin
		Control:=MessageBox('Your changes will not take effect until DFE is restarted, Restart now?',
			Nil,mfInformation+mfYesButton+mfNoButton);
		if Control=cmYes then begin
			Restart:=True;
			Message(@Self, evCommand, cmQuit, Nil);
		end;
	end;

Procedure TMyApp.InitSound;

	begin
		if DFEdefaults.Sound.BaseAddr=0 then begin
			MessageBox('Sound Blaster options have not been set.',Nil,mfWarning+mfOkButton);
			DisableCommands([cmSoundPlayer]);
			exit;
		end;
		sbDMA:=DFEdefaults.Sound.DMA;
		sbIRQ:=DFEdefaults.Sound.IRQ;
		sbIOAddr:=DFEdefaults.Sound.BaseAddr;
		if not SysInitSB then begin
			MessageBox('Could not initialize Sound Blaster.',Nil,mfWarning+mfOkButton);
			DisableCommands([cmSoundPlayer]);
			exit;
		end;
	end;

Procedure TMyApp.Idle;

	begin
		Inherited Idle;
		if ScreenSaver<>nil then
			ScreenSaver^.CountDown;
{		if Debug then begin
			Gotoxy(65,1);
			writeln(MemAvail);
		end;}
	end;

Procedure TMyApp.GetEvent(var Event:TEvent);

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

Procedure TMyApp.HandleEvent(Var Event:TEvent);

	begin
		TApplication.HandleEvent(Event);
		if Event.What=evKeyDown then
			if Event.KeyCode=GetAltCode('S') then
				if ScreenSaver<>nil then
					ScreenSaver^.Options;
		if Event.What=evCommand then begin
			Case Event.Command of
				cmOnePlayerMenu:OnePlayerMenu;
				cmSerialMenu:SerialMenu;
				cmIPXMenu:IPXMenu;
				cmModemMenu:ModemMenu;
				cmPlayDemo:PlayDemo;
				cmViewMaps:MapViewMenu;
				cmSoundPlayer:PlaySounds;
				cmOnePlayerConfig:OnePlayerSetup;
				cmSerialConfig:SerialSetup;
				cmIPXConfig:IPXSetup;
				cmModemConfig:ModemSetup;
				cmPWADconfig:PWadListSetup;
				cmPWadPathConfig:PWadPathSetup;
				cmSoundConfig:if SoundSetup=cmOk then QueryRestart;
				cmItemLocator:LocateItems;
				cmTagAssociate:FindLineDefTags;
				cmMapStats:MapStatistics;
				cmIPXsend:SendNet;
				cmIPXrec:RecNet;
				cmExeHacker:ExeHacker;
			else
				exit;
			end;
			ClearEvent(Event);
		end;
	end;

procedure TMyApp.InitMenuBar;

	var	r:TRect;

	begin
		GetExtent(r);
		R.B.Y:=1;
		MenuBar:=New(PMenuBar,Init(r,NewMenu(
			NewSubMenu('~G~ames',hcNoContext,NewMenu(
				NewItem('~O~ne Player','',0,cmOnePlayerMenu,hcNoContext,
				NewItem('~S~erial Link','',0,cmSerialMenu,hcNoContext,
				NewItem('~I~PX Network','',0,cmIPXMenu,hcNoContext,
				NewItem('~M~odem Link','',0,cmModemMenu,hcNoContext,
				NewItem('~P~lay Demo','',0,cmPlayDemo,hcNoContext,
				NewLine(
				NewSubMenu('~C~onfiguration',hcNoContext,NewMenu(
					NewItem('P~W~ad Path','',0,cmPWadPathConfig,hcNoContext,
					NewItem('~O~ne Player','',0,cmOnePlayerConfig,hcNoContext,
					NewItem('~S~erial Link','',0,cmSerialConfig,hcNoContext,
					NewItem('~I~PX Network','',0,cmIPXConfig,hcNoContext,
					NewItem('~M~odem Link','',0,cmModemConfig,hcNoContext,
					NewItem('~P~Wad List','',0,cmPWADconfig,hcNoContext,
					Nil))))))),
				Nil)))))))),
			NewSubMenu('~R~esources',hcNoContext,NewMenu(
				NewSubMenu('~M~aps',hcNoContext,NewMenu(
					NewItem('Map ~V~iewer','',0,cmViewMaps,hcNoContext,
					NewItem('~I~tem Locator','',0,cmItemLocator,hcNoContext,
					NewItem('~L~ineDef Tags','',0,cmTagAssociate,hcNoContext,
					NewItem('Map ~S~tatistics','',0,cmMapStats,hcNoContext,
					nil))))),
				NewItem('S~o~unds','',0,cmSoundPlayer,hcNoContext,
				NewLine(
				NewSubMenu('~C~onfigurations',hcNoContext,NewMenu(
					NewItem('~S~ound Blaster','',0,cmSoundConfig,hcNoContext,
					Nil)),
				Nil))))),
			NewSubMenu('~E~xeHack',hcNoContext,NewMenu(
				NewItem('~D~OOM.EXE Hacker','',0,cmExeHacker,hcNoContext,
				Nil)),
			NewSubMenu('~I~PXFER',hcNoContext,NewMenu(
				NewItem('~S~end Files','F2',kbF2,cmIPXsend,hcNoContext,
				NewItem('~R~eceive Files','F3',kbF3,cmIPXrec,hcNoContext,
				Nil))),
			Nil)))))));
	end;

Function TMyApp.GetPalette:PPalette;

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

Procedure TMyApp.RunDoom(GameType:integer;Params:string);

	var 	RunName:String;
			R:TRect;
			e:TEvent;
			S,Rn:array[0..79] of char;
			InfoBox:PWindow;
			SwapErr:word;

	begin
		case GameType of
			gtNormal:RunName:='DOOM.EXE';
			gtModem,gtSerial,gtDirLinkModem:RunName:='SERSETUP.EXE';
			gtIPXNet:RunName:='IPXSETUP.EXE';
		end;
		DoneTimer;
		DoneHistory;
		DoneSysError;
		DoneEvents;
		DoneVideo;
		DoneMemory;
		if Debug then begin
			writeln(RunName,' ',Params);
			writeln(MemAvail);
			readln;
		 end
		else begin
			SetLaunchCommand(RunName+' '+Params);
			halt(0);
		end;
		delay(500);
		InitTimer;
		InitMemory;
		InitVideo;
		InitEvents;
		InitSysError;
		InitHistory;
		Redraw;
		E.What:=evKeyDown;
		E.Command:=evKeyDown;
		E.KeyCode:=kbAltG;
		PutEvent(E);
	end;

Procedure TMyApp.OnePlayerMenu;

	var	DmParam,TmpStr:String;

	begin
		SetMenuData(1,DmParam,TmpStr);
		if DmParam<>'' then
			RunDoom(gtNormal,DmParam);
	end;


Procedure TMyApp.SerialMenu;

	var	ModeParam,DmParam:String;

	begin
		SetMenuData(2,DmParam,ModeParam);
		if DmParam<>'' then
			RunDoom(gtSerial,DmParam);
	end;

Procedure TMyApp.IPXMenu;

	var	DmParam,TmpStr:String;

	begin
		SetMenuData(3,DmParam,TmpStr);
		if DmParam<>'' then
			RunDoom(gtIPXNet,DmParam);
	end;

Procedure TMyApp.ModemMenu;

	var	ModeParam,DmParam:String;

	begin
		SetMenuData(4,DmParam,ModeParam);
		if DmParam<>'' then
			RunDoom(gtModem,DmParam);
	end;

Procedure TMyApp.PlayDemo;

	begin
		MessageBox('Reserved for future implemenation', Nil, mfOkButton+mfInformation);
	end;

Procedure TMyApp.LocateItems;

	var	ItemLocator:PItemMenu;

	begin
		ItemLocator:=New(PItemMenu, Init);
		DeskTop^.ExecView(ItemLocator);
		Dispose(ItemLocator, Done);
	end;

Procedure TMyApp.SendNet;

	var	ChDirBox:PChDirDialog;
			CurrentDir:String;
			Control:word;
			FileSpec:string;

	begin
		GetDir(0, CurrentDir);
		ChDirBox:=New(PChDirDialog, Init(cdNormal, 101));
		Control:=Desktop^.ExecView(ChDirBox);
		Dispose(ChDirBox,Done);
		if Control=cmOK then begin
			FileSpec:='*.WAD';
			Control:=InputBox('Select files to send','Filename Specification:',
				FileSpec,12);
			if Control=cmOk then
				IPXSend(FileSpec);
		end;
		ChDir(CurrentDir);
		Desktop^.Redraw;
	end;

Procedure TMyApp.RecNet;

	var	ChDirBox:PChDirDialog;
			CurrentDir:String;
			Control:word;

	begin
		GetDir(0, CurrentDir);
		ChDirBox:=New(PChDirDialog, Init(cdNormal, 101));
		Control:=Desktop^.ExecView(ChDirBox);
		Dispose(ChDirBox,Done);
		if Control=cmOK then
				IPXrec;
		ChDir(CurrentDir);
		Desktop^.Redraw;
	end;

Procedure TMyApp.ExeHacker;

	var	AboutBox:PWindow;
			R:Trect;
			f:file;

	begin
		{$I-}
		assign(f,'DOOM.EXE');
		Reset(f, 1);
		{$I+}
		If IOResult <> 0 then begin
			MessageBox('Unable to open DOOM.EXE',
				Nil,mfOkButton+mfError);
			exit;
		end;
		if FileSize(f) <> v12FileSize then begin
			MessageBox('You MUST have Registered v1.2 or DOOM to use this option',
				Nil,mfOkButton+mfError);
			close(f);
			exit;
		end;
		close(f);
		R.Assign(28,6,52,9);
		AboutBox:=New(PWindow,Init(R,'ExeHacker',0));
		With AboutBox^ do begin
			Flags:=0;
			R.Assign(4,1,21,2);
			Insert(New(PStaticText,Init(R,'Initializing...')));
		end;
		Desktop^.Insert(AboutBox);
		delay(500);
		DoneSysError;
		DoneEvents;
		DoneDosMem;
		asm
			mov ah,1
			mov cx,1800
			int $10
		end;
		{$IFDEF DEBUG}
			DFELaunch('D:\BP\UNITS\EXEHACK.EXE');
		{$ELSE}
			DFELaunch('DFESYS\EXEHACK.EXE');
		{$ENDIF}
		InitDosMem;
		InitEvents;
		InitSysError;
		Desktop^.Delete(AboutBox);
		Dispose(AboutBox,Done);
		DeskTop^.Redraw;
		MenuBar^.draw;
		StatusLine^.draw;
	end;

Destructor TMyApp.Done;

	begin
		Inherited Done;
		SysDoneSB;
		Dispose(ScreenSaver,Done);
	end;

begin
{$IFDEF DEBUG}
	Debug:=True;
{$ENDIF}
	TerminateOnWadError:=False;
	Restart:=False;
	MyApp.Init;
	MyApp.Run;
	MyApp.Done;
	if Restart then
		SetRestartCommand
	else
		SetTerminateCommand(0);
end.
