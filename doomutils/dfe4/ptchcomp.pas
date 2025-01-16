unit PtchComp;

interface

uses Objects,Dialogs,Drivers;

{Registered DOOM 1.2 Table offsets}
const v12ThingEntries=	103;
		v12FrameEntries=	512;
		v12SpriteEntries=	105;
		v12SoundEntries=	61;
		v12NumAmmo		=	4;
		v12WeaponEntries= 8;
		v12ThingStart	=	$8B3C8;
		v12AmmoStart	=	$85B7C;
		v12WeaponStart	=	$85B9C;
		v12FrameStart	=	$87BA8;
		v12SpriteStart	=	$87A04;
		v12SoundStart	=	$8714C;
		v12DataStart	=	$6F414;
		v12FileSize		=  580391;
		dmPatchLen		=	663;
		cmItemChanged=	2005;

Type	PSoundEntry=^TSoundEntry;
		TSoundEntry=array[1..7] of char;
		PSoundTable=^TSoundTable;
		TSoundTable=array[1..v12SoundEntries] of TSoundEntry;
		PSpriteEntry=^TSpriteEntry;
		TSpriteEntry=array[1..5] of char;
		PSpriteTable=^TSpriteTable;
		TSpriteTable=array[0..105] of TSpriteEntry;
		PFrameEntry=^TFrameEntry;
		TFrameEntry=array[1..7] of longint;
		PFrameTable=^TFrameTable;
		TFrameTable=array[0..v12FrameEntries] of TFrameEntry;
		PThingEntry=^TThingEntry;
		TThingEntry=array[1..22] of longint;
		PThingTable=^TThingTable;
		TThingTable=array[1..v12ThingEntries] of TThingEntry;
		TMaxAmmoTable=array[0..v12NumAmmo] of Longint;
		TPerAmmoTable=array[0..v12NumAmmo] of Longint;
		TWeaponEntry=array[1..6] of Longint;
		PWeaponTable=^TWeaponTable;
		TWeaponTable=array[1..v12WeaponEntries] of TWeaponEntry;
		PNumericInputLine=^TNumericInputLine;
		TNumericInputLine=object(TInputLine)
			Value:longint;
			Procedure HandleEvent(var Event:TEvent); virtual;
			Procedure GetData(var Rec); virtual;
			Procedure SetData(var Rec); virtual;
			Function DataSize:word; virtual;
		end;

Procedure LoadDEHpatch;
Procedure SaveDEHpatch;
Procedure CompilePatch;
Procedure ApplyPatch;

var	ThingTable:PThingTable;
		ThingNames:array[1..104] of PString;
		FrameTable:PFrameTable;
		SpriteTable:PSpriteTable;
		SoundTable:PSoundTable;
		MaxAmmoTable:TMaxAmmoTable;
		PerAmmoTable:TPerAmmoTable;
		WeaponTable:PWeaponTable;

implementation

uses App,StdDlg,MsgBox,Views,Strings;

Procedure PatchData; external;
{$L dmpatch}

Procedure TNumericInputLine.HandleEvent(var Event:TEvent);

	begin
		if Event.What = evKeyDown then begin
			case Event.CharCode of
				#33..#47,#65..#126,#128..#255: begin
					ClearEvent(Event);
					Exit;
				end;
				#13:Event.KeyCode:=kbTab;
			end;
			case Event.KeyCode of
				kbTab,kbShiftTab:begin
					Inherited HandleEvent(Event);
					Message(Owner, evCommand, cmItemChanged, Nil);
					exit;
				end;
			end;
		 end
		else if Event.What = evMouseDown then begin
			Inherited HandleEvent(Event);
			Message(Owner, evMessage, cmItemChanged, Nil);
			exit;
		end;
		Inherited HandleEvent(Event);
	end;

Procedure TNumericInputLine.GetData(var Rec);

	var	c:integer;

	begin
		val(Data^, Value, C);
		if c <> 0 then
			Value:=0;
		longint(Rec):=Value;
	end;

Procedure TNumericInputLine.SetData(var Rec);

	begin
		Value:=Longint(Rec);
		Str(Value, Data^);
	end;

Function TNumericInputLine.DataSize:word;

	begin
		DataSize:=4;
	end;

Procedure PatchErr(S:String);

	begin
		MessageBox(S,Nil,mfError+mfOkButton);
	end;


Procedure LoadDEHpatch;

	var	FD:PFileDialog;
			F:File;
			FileName:String;
			c:byte;
			Control:word;

	{$I-}
	begin
		FD:=New(PFileDialog,Init('*.DEH','Load DOOM Patch (DeHacked)','~N~ame', fdOpenButton, 102));
		Control:=DeskTop^.ExecView(FD);
		if Control=cmOk then
			Control:=cmFileOpen;
		If Control=cmFileOpen then begin
			FD^.GetFileName(FileName);
			Dispose(FD, Done);
			assign(F,FileName);
			reset(F,1);
			if IOResult <> 0 then begin
				PatchErr('Unable to open patch file.');
				exit;
			end;
			blockread(f,c,1);
			if c <> 12 then begin
				PatchErr('Invalid Version Number!');
				Close(f);
				exit;
			end;
			blockread(f,c,1);
			if (c < 1) or (c > 2) then begin
				PatchErr('Unsupported File Type!');
				Close(f);
				exit;
			end;
			BlockRead(f,ThingTable^,SizeOf(TThingEntry) * v12ThingEntries);
			BlockRead(f,MaxAmmoTable,SizeOf(Longint) * v12NumAmmo);
			BlockRead(f,PerAmmoTable,SizeOf(Longint) * v12NumAmmo);
			BlockRead(f,WeaponTable^,Sizeof(TWeaponEntry) * v12WeaponEntries);
			if c=2 then begin
				BlockRead(f,FrameTable^,Sizeof(TFrameEntry) * v12FrameEntries);
				MessageBox('DeHacked v1.3 Patch Loaded',Nil,mfOkButton+mfInformation)
			 end
			else
				MessageBox('DeHacked v1.2 Patch Loaded',Nil,mfOkButton+mfInformation);
			Close(f);
		 end
		else
			Dispose(FD, Done);
	end;
	{$I+}

Procedure SaveDEHpatch;

	var	FD:PFileDialog;
			F:File;
			FileName:String;
			Control:word;
			c:byte;

	{$I-}
	begin
		FD:=New(PFileDialog,Init('*.DEH','Save DOOM Patch (DeHacked)','~N~ame', fdOkButton, 102));
		Control:=Desktop^.ExecView(FD);
		if Control=cmFileOpen then
			Control:=cmOk;
		if Control=cmOk then begin
			FD^.GetFileName(FileName);
			if Pos('.',FileName) = 0 then
				FileName:=FileName + '.DEH';
			Dispose(FD, Done);
			Assign(f,FileName);
			Rewrite(f,1);
			if IOResult <> 0 then begin
				PatchErr('Could not open path file!');
				exit;
			end;
			c:=12;
			BlockWrite(f,c,1); {Write DOOM Version}
			c:=2;
			BlockWrite(f,c,1); {Write DeHacked Version Number}
			BlockWrite(f,ThingTable^,SizeOf(TThingEntry) * v12ThingEntries);
			BlockWrite(f,MaxAmmoTable,SizeOf(Longint) * v12NumAmmo);
			BlockWrite(f,PerAmmoTable,SizeOf(Longint) * v12NumAmmo);
			BlockWrite(f,WeaponTable^,Sizeof(TWeaponEntry) * v12WeaponEntries);
			BlockWrite(f,FrameTable^,Sizeof(TFrameEntry) * v12FrameEntries);
			Close(f);
			MessageBox('DeHacked v1.3 Patch Written',Nil,mfOkButton+mfInformation)
		 end
		else
			Dispose(FD, Done);
	end;
	{$I+}

Procedure CompilePatch;

	var	f:file;
			FD:PFileDialog;
			t:integer;
			p:pointer;
			Control,TempSize:word;
			TempOfs:longint;
			FileName:string;
			CW:PWindow;
			R:Trect;

	begin
		FD:=New(PFileDialog,Init('*.COM','Compile DFE Patch','~N~ame', fdOkButton, 102));
		Control:=Desktop^.ExecView(FD);
		if Control=cmFileOpen then
			Control:=cmOk;
		if Control=cmOk then begin
			FD^.GetFileName(FileName);
			Dispose(FD, Done);
			if Pos('.',FileName) = 0 then
				FileName:=FileName + '.COM';
			assign(f,filename);
			rewrite(f, 1);
			p:=@PatchData;
			{Write COM shell}
			blockwrite(f, p^, dmPatchLen);
			{Write Thing Table}
			TempOfs:=v12ThingStart;
			TempSize:=SizeOf(TThingEntry) * v12ThingEntries;
			BlockWrite(f,TempOfs, 4);
			BlockWrite(f,TempSize, 2);
			BlockWrite(f,ThingTable^,TempSize);
			{Write Ammo Tables}
			TempOfs:=v12AmmoStart;
			TempSize:=Sizeof(Longint) * v12NumAmmo * 2;
			BlockWrite(f,TempOfs, 4);
			BlockWrite(f,TempSize, 2);
			BlockWrite(f,MaxAmmoTable,SizeOf(Longint) * v12NumAmmo);
			BlockWrite(f,PerAmmoTable,SizeOf(Longint) * v12NumAmmo);
			{Write Weapon Table}
			TempOfs:=v12WeaponStart;
			TempSize:=SizeOf(TWeaponEntry) * v12WeaponEntries;
			BlockWrite(f,TempOfs, 4);
			BlockWrite(f,TempSize, 2);
			BlockWrite(f,WeaponTable^,TempSize);
			{Write Frame Table}
			TempOfs:=v12FrameStart;
			TempSize:=Sizeof(TFrameEntry) * v12FrameEntries;
			BlockWrite(f,TempOfs, 4);
			BlockWrite(f,TempSize, 2);
			BlockWrite(f,FrameTable^,TempSize);
			seek(f, 3);
			TempSize:=4;
			BlockWrite(f, TempSize, 2);
			close(f);
			MessageBox('DFE Patch Successfully Compiled.', nil, mfOkButton+mfInformation);
		 end
		else
			Dispose(FD, Done);
	end;

Procedure ApplyPatch;

	var 	f:file;
			TempSize:Longint;

	begin
		assign(f, 'DOOM.EXE');
		reset(f,1);
		if IOResult <> 0 then begin
			MessageBox('Error patching DOOM.EXE', nil, mfOkButton);
			exit;
		end;
		Seek(f,v12ThingStart);
		TempSize:=SizeOf(TThingEntry) * v12ThingEntries;
		BlockWrite(f,ThingTable^,TempSize);
		{Write Ammo Tables}
		Seek(f,v12AmmoStart);
		TempSize:=Sizeof(Longint) * v12NumAmmo * 2;
		BlockWrite(f,MaxAmmoTable,SizeOf(Longint) * v12NumAmmo);
		BlockWrite(f,PerAmmoTable,SizeOf(Longint) * v12NumAmmo);
		{Write Weapon Table}
		Seek(f,v12WeaponStart);
		TempSize:=SizeOf(TWeaponEntry) * v12WeaponEntries;
		BlockWrite(f,WeaponTable^,TempSize);
		{Write Frame Table}
		Seek(f,v12FrameStart);
		TempSize:=Sizeof(TFrameEntry) * v12FrameEntries;
		BlockWrite(f,FrameTable^,TempSize);
		close(f);
		MessageBox('DOOM.EXE Successfully Patched.', nil, mfOkButton+mfInformation);
	end;

end.
