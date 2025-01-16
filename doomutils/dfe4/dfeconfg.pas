{$F+,O+}
unit DFECONFG;

interface

uses Objects;

type  TOnePlayerConfig=record
         PWads:longint;
			Skill:longint;
			Monsters:longint;
		end;
		TSerialConfig=record
      	PWads:longint;
      	Skill:longint;
			Monsters:longint;
			ComPort:longint;
      end;
		TIPXConfig=record
			PWads:longint;
			Skill:longint;
         Monsters:longint;
         Players:longint;
			Socket:word;
		end;
      TModemConfig=record
      	PWads:longint;
      	Skill:longint;
         Monsters:longint;
			ComPort:longint;
			Phone:string;
		end;
		TSBConfig=record
			UseSound	:Boolean;
			BaseAddr	:word;
			IRQ		:word;
			DMA		:word;
		end;
		TConfigFile=record
			OnePlayer	:TOnePlayerConfig;
			Serial		:TSerialConfig;
			IPX			:TIPXConfig;
			Modem			:TModemConfig;
			PwadList		:Array[0..4] of String;
			PWadPath		:String;
			Sound       :TSBConfig;
		end;

var	DFEdefaults:TConfigFile;

Procedure InitDefaults;
Procedure SaveDefaults;
Procedure OnePlayerSetup;
Procedure SerialSetup;
Procedure IPXSetup;
Procedure ModemSetup;
Procedure PWadListSetup;
Procedure PWadPathSetup;
Function OnePlayerPWads(AddFileParam:Boolean):string;
Function SerialPWads(AddFileParam:Boolean):string;
Function IPXPWads(AddFileParam:Boolean):string;
Function ModemPWads(AddFileParam:Boolean):string;
Function SoundSetup:word;

implementation

uses	Dialogs,StdDlg,Views,App,MsgBox;

Procedure ClearDefaults;

	var t:integer;

	begin
		with DFEDefaults do begin
			FillChar(OnePlayer, Sizeof(TOnePlayerConfig), #00);
			FillChar(Serial, Sizeof(TSerialConfig), #00);
			FillChar(IPX, Sizeof(TIPXConfig), #00);
			FillChar(Modem, Sizeof(TModemConfig), #00);
			FillChar(Sound, Sizeof(TSBConfig), #00);
			Modem.Phone:='';
			Sound.UseSound:=True;
			for t:=0 to 4 do
				PWadList[t]:='';
		end;
	end;

{$I-}
Procedure InitDefaults;

	var	F:File of TConfigFile;

	begin
		assign(F, 'DFESYS\DFE.CFG');
		reset(F);
		if IOResult <> 0 then begin
			MessageBox('DFE.CFG not found... Defaults cleared.',Nil,mfWarning+mfOkButton);
			ClearDefaults;
			SaveDefaults;
			exit;
		end;
		Read(F,DFEdefaults);
		if IOResult <> 0 then begin
			Close(f);
			MessageBox('DFE.CFG is invalid... Defaults cleared.',Nil,mfWarning+mfOkButton);
			ClearDefaults;
			SaveDefaults;
		 end
		else
			close(F);
	end;
{$I+}

Procedure SaveDefaults;

	var	F:File of TConfigFile;

	begin
		assign(F, 'DFESYS\DFE.CFG');
		rewrite(F);
		write(F, DFEDefaults);
		close(F);
	end;

Procedure OnePlayerSetup;

	var	PWads,Monsters:PCheckBoxes;
			Skill:PRadioButtons;
			Dialog1:PDialog;
			R:Trect;
			Control:word;
			TempFlag:longint;
			t:integer;

	begin
		R.Assign(9,2,61,19);
		Dialog1:=New(PDialog, Init(R, 'One Player Defaults'));
		R.Assign(2,1,15,2);
		Dialog1^.Insert(New(PStaticText, Init(R, 'Default PWADs')));
		with DFEDefaults do begin
			TempFlag:=0;
			for t:=0 to 4 do begin
				if PWadList[t]='' then
					PWadList[t]:='(None)'
				else
					TempFlag:=TempFlag or longint(1 shl t);
			end;
			R.Assign(2,2,19,7);
			PWads:=New(PCheckBoxes, Init(R,
				NewSItem(PWadList[0],
				NewSItem(PWadList[1],
				NewSItem(PWadList[2],
				NewSItem(PWadList[3],
				NewSItem(PWadList[4],
				Nil)))))));
{			PWads^.EnableMask:=TempFlag;}
			PWads^.Value:=OnePlayer.PWads;
			R.Assign(2,8,15,9);
			Dialog1^.Insert(New(PStaticText, Init(R, 'Default Skill')));
			R.Assign(2,9,28,14);
			Skill:=New(PRadioButtons, Init(R,
				NewSItem('I''m too young to die',
				NewSItem('Hey, not too rough',
				NewSItem('Hurt me plenty',
				NewSItem('Ultra Violence',
				NewSItem('NIGHTMARE!',
				Nil)))))));
			Skill^.Value:=OnePlayer.Skill;
			R.Assign(30,1,50,2);
			Dialog1^.Insert(New(PStaticText, Init(R, 'Monster Defaults')));
			R.Assign(30,2,50,4);
			Monsters:=New(PCheckBoxes, Init(R,
				NewSItem('No Monsters',
				NewSItem('Respawn',
				Nil))));
			Monsters^.Value:=OnePlayer.Monsters;
		end;
		With Dialog1^ do begin
			Insert(PWads);
			Insert(Skill);
			Insert(Monsters);
			R.Assign(30,14,38,16);
			Insert(New(PButton, Init(R,'~O~k',cmOK,bfDefault)));
			R.Assign(40,14,50,16);
			Insert(New(PButton, Init(R,'~C~ancel',cmCancel,bfNormal)));
		end;
		Control:=DeskTop^.ExecView(Dialog1);
		if Control=cmOK then begin
			with DFEDefaults do begin
				OnePlayer.PWads:=PWads^.Value;
				OnePlayer.Skill:=Skill^.Value;
				OnePlayer.Monsters:=Monsters^.Value;
				for t:=0 to 4 do
					if POS('(None)',PWadList[t]) > 0 then
						PWadList[t]:='';
			end;
			SaveDefaults;
		end;
		Dispose(Dialog1,Done);
	end;

Procedure SerialSetup;

	var	PWads,Monsters:PCheckBoxes;
			Skill,ComPort:PRadioButtons;
			Dialog1:PDialog;
			R:Trect;
			Control:word;
			TempFlag:longint;
			t:integer;

	begin
		R.Assign(9,2,65,19);
		Dialog1:=New(PDialog, Init(R, 'Serial Defaults'));
		R.Assign(2,1,15,2);
		Dialog1^.Insert(New(PStaticText, Init(R, 'Default PWADs')));
		with DFEDefaults do begin
			TempFlag:=0;
			for t:=0 to 4 do begin
				if PWadList[t]='' then
					PWadList[t]:='(None)'
				else
					TempFlag:=TempFlag or longint(1 shl t);
			end;
			R.Assign(2,2,19,7);
			PWads:=New(PCheckBoxes, Init(R,
				NewSItem(PWadList[0],
				NewSItem(PWadList[1],
				NewSItem(PWadList[2],
				NewSItem(PWadList[3],
				NewSItem(PWadList[4],
				Nil)))))));
{			PWads^.EnableMask:=TempFlag;}
			PWads^.Value:=Serial.PWads;
			R.Assign(2,8,15,9);
			Dialog1^.Insert(New(PStaticText, Init(R, 'Default Skill')));
			R.Assign(2,9,28,14);
			Skill:=New(PRadioButtons, Init(R,
				NewSItem('I''m too young to die',
				NewSItem('Hey, not too rough',
				NewSItem('Hurt me plenty',
				NewSItem('Ultra Violence',
				NewSItem('NIGHTMARE!',
				Nil)))))));
			Skill^.Value:=Serial.Skill;
			R.Assign(30,1,54,2);
			Dialog1^.Insert(New(PStaticText, Init(R, 'Monster Defaults')));
			R.Assign(30,2,50,6);
			Monsters:=New(PCheckBoxes, Init(R,
				NewSItem('No Monsters',
				NewSItem('Respawn',
				NewSItem('DeathMatch',
				NewSItem('Use Deathmatch 2.0',
				Nil))))));
			Monsters^.Value:=Serial.Monsters;
			R.Assign(30,7,50,8);
			Dialog1^.Insert(New(PStaticText, Init(R, 'COM Port Defaults')));
			R.Assign(30,8,50,13);
			ComPort:=New(PRadioButtons, Init(R,
				NewSItem('COM1',
				NewSItem('COM2',
				NewSItem('COM3',
				NewSItem('COM4',
				Nil))))));
			ComPort^.Value:=Serial.ComPort;
		end;
		With Dialog1^ do begin
			Insert(PWads);
			Insert(Skill);
			Insert(Monsters);
			Insert(ComPort);
			R.Assign(30,14,38,16);
			Insert(New(PButton, Init(R,'~O~k',cmOK,bfDefault)));
			R.Assign(40,14,50,16);
			Insert(New(PButton, Init(R,'~C~ancel',cmCancel,bfNormal)));
		end;
		Control:=DeskTop^.ExecView(Dialog1);
		if Control=cmOK then begin
			with DFEDefaults do begin
				Serial.PWads:=PWads^.Value;
				Serial.Skill:=Skill^.Value;
				Serial.Monsters:=Monsters^.Value;
				Serial.ComPort:=ComPort^.Value;
				for t:=0 to 4 do
					if POS('(None)',PWadList[t]) > 0 then
						PWadList[t]:='';
			end;
			SaveDefaults;
		end;
		Dispose(Dialog1,Done);
	end;

Procedure IPXSetup;

	var	PWads,Monsters:PCheckBoxes;
			Skill,Players:PRadioButtons;
			Socket:PInputLine;
			Dialog1:PDialog;
			R:Trect;
			Control:word;
			TempFlag:longint;
			TempStr:String;
			t:integer;

	begin
		R.Assign(9,2,65,20);
		Dialog1:=New(PDialog, Init(R, 'IPX Network Defaults'));
		R.Assign(2,1,15,2);
		Dialog1^.Insert(New(PStaticText, Init(R, 'Default PWADs')));
		with DFEDefaults do begin
			TempFlag:=0;
			for t:=0 to 4 do begin
				if PWadList[t]='' then
					PWadList[t]:='(None)'
				else
					TempFlag:=TempFlag or longint(1 shl t);
			end;
			R.Assign(2,2,19,7);
			PWads:=New(PCheckBoxes, Init(R,
				NewSItem(PWadList[0],
				NewSItem(PWadList[1],
				NewSItem(PWadList[2],
				NewSItem(PWadList[3],
				NewSItem(PWadList[4],
				Nil)))))));
{			PWads^.EnableMask:=TempFlag;}
			PWads^.Value:=IPX.PWads;
			R.Assign(2,8,15,9);
			Dialog1^.Insert(New(PStaticText, Init(R, 'Default Skill')));
			R.Assign(2,9,28,14);
			Skill:=New(PRadioButtons, Init(R,
				NewSItem('I''m too young to die',
				NewSItem('Hey, not too rough',
				NewSItem('Hurt me plenty',
				NewSItem('Ultra Violence',
				NewSItem('NIGHTMARE!',
				Nil)))))));
			Skill^.Value:=IPX.Skill;
			R.Assign(30,1,50,2);
			Dialog1^.Insert(New(PStaticText, Init(R, 'Monster Defaults')));
			R.Assign(30,2,54,6);
			Monsters:=New(PCheckBoxes, Init(R,
				NewSItem('No Monsters',
				NewSItem('Respawn',
				NewSItem('Deathmatch',
				NewSItem('Use Deathmatch 2.0',
				Nil))))));
			Monsters^.Value:=IPX.Monsters;
			R.Assign(30,7,50,8);
			Dialog1^.Insert(New(PStaticText, Init(R, 'Player Defaults')));
			R.Assign(30,8,50,12);
			Players:=New(PRadioButtons, Init(R,
				NewSItem('2 Players',
				NewSItem('3 Players',
				NewSItem('4 Players',
				Nil)))));
			Players^.Value:=IPX.Players;
			Str(IPX.Socket, TempStr);
			R.Assign(30,12,50,13);
			Dialog1^.Insert(New(PStaticText, Init(R, 'Socket (0=Default)')));
			R.Assign(30,13,37,14);
			Socket:=New(PInputLine, Init(R, 5));
			Socket^.Data^:=TempStr;
		end;
		With Dialog1^ do begin
			Insert(PWads);
			Insert(Skill);
			Insert(Monsters);
			Insert(Players);
			Insert(Socket);
			R.Assign(30,15,38,17);
			Insert(New(PButton, Init(R,'~O~k',cmOK,bfDefault)));
			R.Assign(40,15,50,17);
			Insert(New(PButton, Init(R,'~C~ancel',cmCancel,bfNormal)));
		end;
		Control:=DeskTop^.ExecView(Dialog1);
		if Control=cmOK then begin
			with DFEDefaults do begin
				IPX.PWads:=PWads^.Value;
				IPX.Skill:=Skill^.Value;
				IPX.Monsters:=Monsters^.Value;
				IPX.Players:=Players^.Value;
				val(Socket^.Data^,IPX.Socket,Control);
				if Control <> 0 then begin
					MessageBox('Socket must be in DECIMAL format.',Nil,mfError+mfOkButton);
					IPX.Socket:=0;
				end;
				for t:=0 to 4 do
					if POS('(None)',PWadList[t]) > 0 then
						PWadList[t]:='';
			end;
			SaveDefaults;
		end;
		Dispose(Dialog1,Done);
	end;

Procedure ModemSetup;

	var	PWads,Monsters:PCheckBoxes;
			ComPort,Skill:PRadioButtons;
			Phone:PInputLine;
			Dialog1:PDialog;
			R:Trect;
			Control:word;
			TempFlag:longint;
			t:integer;

	begin
		R.Assign(9,2,65,21);
		Dialog1:=New(PDialog, Init(R, 'Modem Defaults'));
		R.Assign(2,1,15,2);
		Dialog1^.Insert(New(PStaticText, Init(R, 'Default PWADs')));
		with DFEDefaults do begin
			TempFlag:=0;
			for t:=0 to 4 do begin
				if PWadList[t]='' then
					PWadList[t]:='(None)'
				else
					TempFlag:=TempFlag or longint(1 shl t);
			end;
			R.Assign(2,2,19,7);
			PWads:=New(PCheckBoxes, Init(R,
				NewSItem(PWadList[0],
				NewSItem(PWadList[1],
				NewSItem(PWadList[2],
				NewSItem(PWadList[3],
				NewSItem(PWadList[4],
				Nil)))))));
{			PWads^.EnableMask:=TempFlag;}
			PWads^.Value:=Modem.PWads;
			R.Assign(2,8,15,9);
			Dialog1^.Insert(New(PStaticText, Init(R, 'Default Skill')));
			R.Assign(2,9,28,14);
			Skill:=New(PRadioButtons, Init(R,
				NewSItem('I''m too young to die',
				NewSItem('Hey, not too rough',
				NewSItem('Hurt me plenty',
				NewSItem('Ultra Violence',
				NewSItem('NIGHTMARE!',
				Nil)))))));
			Skill^.Value:=Modem.Skill;
			R.Assign(30,1,50,2);
			Dialog1^.Insert(New(PStaticText, Init(R, 'Monster Defaults')));
			R.Assign(30,2,54,7);
			Monsters:=New(PCheckBoxes, Init(R,
				NewSItem('No Monsters',
				NewSItem('Respawn',
				NewSItem('DeathMatch',
				NewSItem('Use Deathmatch 2.0',
				Nil))))));
			Monsters^.Value:=Modem.Monsters;
			R.Assign(30,7,50,8);
			Dialog1^.Insert(New(PStaticText, Init(R, 'COM Port Defaults')));
			R.Assign(30,8,50,13);
			ComPort:=New(PRadioButtons, Init(R,
				NewSItem('COM1',
				NewSItem('COM2',
				NewSItem('COM3',
				NewSItem('COM4',
				Nil))))));
			ComPort^.Value:=Modem.ComPort;
			R.Assign(30,13,50,14);
			Dialog1^.Insert(New(PStaticText, Init(R, 'Default Phone Number')));
			R.Assign(30,14,44,15);
			Phone:=New(PInputLine, Init(R, 12));
			Phone^.Data^:=Modem.Phone;
		end;
		With Dialog1^ do begin
			Insert(PWads);
			Insert(Skill);
			Insert(Monsters);
			Insert(ComPort);
			Insert(Phone);
			R.Assign(30,16,38,18);
			Insert(New(PButton, Init(R,'~O~k',cmOK,bfDefault)));
			R.Assign(40,16,50,18);
			Insert(New(PButton, Init(R,'~C~ancel',cmCancel,bfNormal)));
		end;
		Control:=DeskTop^.ExecView(Dialog1);
		if Control=cmOK then begin
			with DFEDefaults do begin
				Modem.PWads:=PWads^.Value;
				Modem.Skill:=Skill^.Value;
				Modem.Monsters:=Monsters^.Value;
				Modem.ComPort:=ComPort^.Value;
				Modem.Phone:=Phone^.Data^;
				for t:=0 to 4 do
					if POS('(None)',PWadList[t]) > 0 then
						PWadList[t]:='';
			end;
			SaveDefaults;
		end;
		Dispose(Dialog1,Done);
	end;

Procedure PWadListSetup;

	var 	NewPWadList:Array[0..4] of PInputLine;
			R:Trect;
         Dialog1:PDialog;
         t:integer;
			Control:word;
			TempStr:String;

	begin
		R.Assign(5,2,33,14);
		Dialog1:=New(PDialog, Init(R, 'PWad List Defaults'));
		for t:=0 to 4 do begin
			Str(t, TempStr);
			TempStr:='PWad #'+TempStr+':';
			R.Assign(2,2+t,11,3+t);
			Dialog1^.Insert(New(PStaticText, Init(R, TempStr)));
			R.assign(12,2+t,26,3+t);
			NewPWadList[t]:=New(PInputLine, Init(R, 12));
			NewPWadList[t]^.Data^:=DFEDefaults.PWadList[t];
			Dialog1^.Insert(NewPWadList[t]);
		end;
		R.Assign(5,8,13,10);
		Dialog1^.Insert(New(PButton, Init(R,'~O~k',cmOK,bfDefault)));
		R.Assign(15,8,25,10);
		Dialog1^.Insert(New(PButton, Init(R,'~C~ancel',cmCancel,bfNormal)));
		Control:=Desktop^.ExecView(Dialog1);
		if Control=cmOK then begin
			for t:=0 to 4 do
				DFEDefaults.PWadList[t]:=NewPWadList[t]^.Data^;
			SaveDefaults;
		end;
		dispose(Dialog1,Done);
	end;

Procedure PWadPathSetup;

	var	s:string;

	begin
		s:=DFEDefaults.PWadPath;
		if InputBox('PWad Path','Enter Pathname',s,64) = cmOk then begin
			DFEDefaults.PWadPath:=s;
			SaveDefaults;
		end;
	end;

Function OnePlayerPWads(AddFileParam:Boolean):string;

	var	TempStr:String;
   		t:integer;

	begin
   	TempStr:='';
		if AddFileParam then
			TempStr:='-file ';
      with DFEDefaults do begin
	      for t:=0 to 4 do
				if OnePlayer.PWads and (1 shl t) > 0 then
	         	TempStr:=TempStr+PWadList[t]+' '
		end;
      OnePlayerPWads:=TempStr;
	end;

Function SerialPWads(AddFileParam:Boolean):string;

	var	TempStr:String;
   		t:integer;

	begin
   	TempStr:='';
   	if AddFileParam then
      	TempStr:='-file ';
      with DFEDefaults do begin
			for t:=0 to 4 do
				if Serial.PWads and (1 shl t) > 0 then
            	if PWadList[t] <> '' then
		         	TempStr:=TempStr+PWadList[t]+' '
		end;
      SerialPWads:=TempStr;
	end;

Function IPXPWads(AddFileParam:Boolean):string;

	var	TempStr:String;
   		t:integer;

	begin
   	TempStr:='';
		if AddFileParam then
      	TempStr:='-file ';
      with DFEDefaults do begin
	      for t:=0 to 4 do
	      	if IPX.PWads and (1 shl t) > 0 then
					if PWadList[t] <> '' then
						TempStr:=TempStr+PWadList[t]+' '
		end;
      IPXPWads:=TempStr;
	end;

Function ModemPWads(AddFileParam:Boolean):string;

	var	TempStr:String;
   		t:integer;

	begin
		TempStr:='';
   	if AddFileParam then
			TempStr:='-file ';
		with DFEDefaults do begin
			for t:=0 to 4 do
				if Modem.PWads and (1 shl t) > 0 then
					if PWadList[t] <> '' then
						TempStr:=TempStr+PWadList[t]+' '
		end;
		ModemPWads:=TempStr;
	end;

Function SoundSetup:Word;

	var	IOAddr,DMA,IRQ:PRadioButtons;
			R:TRect;
			Dialog1:PDialog;
			Control:word;

	begin
		Control:=MessageBox('Do you wish to use the Sound Blaster options?',Nil,
			mfYesButton+mfNoButton+mfConfirmation);
		if Control=cmNo then Begin
			if DFEDefaults.Sound.UseSound then
				SoundSetup:=cmOk
			else
				SoundSetup:=cmCancel;
			DFEDefaults.Sound.UseSound:=False;
			SaveDefaults;
			exit;
		end;
		DFEDefaults.Sound.UseSound:=True;
		R.Assign(5,2,37,14);
		Dialog1:=New(PDialog,Init (R, 'Sound Blaster Setup'));
		Dialog1^.Flags:=1;
		R.Assign(2,2,15,3);
		Dialog1^.Insert(New(PStaticText, Init(R, 'IO Address')));
		R.Assign(2,3,15,5);
		IOAddr:=New(PRadioButtons, Init(R,
			NewSItem('220h',
			NewSItem('240h',
			Nil))));
		if DFEDefaults.Sound.BaseAddr=$220 then
			IOAddr^.Value:=0
		else
			IOAddr^.Value:=1;
		R.Assign(2,6,15,7);
		Dialog1^.Insert(New(PStaticText, Init(R, 'IRQ')));
		R.Assign(2,7,15,10);
		IRQ:=New(PRadioButtons, Init(R,
			NewSItem('2',
			NewSItem('5',
			NewSItem('7',
			Nil)))));
		case DFEDefaults.Sound.IRQ of
			2:IRQ^.Value:=0;
			5:IRQ^.Value:=1;
			7:IRQ^.Value:=2;
		end;
		R.Assign(16,2,30,3);
		Dialog1^.Insert(New(PStaticText, Init(R, 'DMA Channel')));
		R.Assign(16,3,30,6);
		DMA:=New(PRadioButtons, Init(R,
			NewSItem('0',
			NewSItem('1',
			NewSItem('3',
			Nil)))));
		case DFEdefaults.Sound.DMA of
			0:DMA^.Value:=0;
			1:DMA^.Value:=1;
			3:DMA^.Value:=2;
		end;
		R.Assign(16,9,26,11);
		Dialog1^.Insert(New(PButton, Init(R,'~O~k',cmOK,bfDefault)));
		Dialog1^.Insert(IOAddr);
		Dialog1^.Insert(IRQ);
		Dialog1^.Insert(DMA);
		Control:=Desktop^.ExecView(Dialog1);
		if Control=cmOk then begin
			if (IOAddr^.Value and 1)=0 then
				DFEDefaults.Sound.BaseAddr:=$220
			else
				DFEDefaults.Sound.BaseAddr:=$240;
			case (IRQ^.Value and 7) of
				0:DFEDefaults.Sound.IRQ:=2;
				1:DFEDefaults.Sound.IRQ:=5;
				2:DFEDefaults.Sound.IRQ:=7;
			end;
			case (DMA^.Value and 7) of
				0:DFEDefaults.Sound.DMA:=0;
				1:DFEDefaults.Sound.DMA:=1;
				2:DFEDefaults.Sound.DMA:=3;
			end;
			SaveDefaults;
			SoundSetup:=cmOk;
		 end
		else
			SoundSetup:=cmCancel;
		Dispose(Dialog1, Done);
	end;
end.