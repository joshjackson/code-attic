{$F+,O+}
unit SPlayer;

interface

uses 	App,Views,Menus,Dialogs,Drivers,Memory,Objects,MsgBox,Sounds,Wad,WadDecl,ListMenu,
		sbc,Crt,WriteWav;

const	cmDoMenu			= 151;
		cmItemFocused	= 152;
		cmPlaySound		= 153;
		cmExportSound	= 154;

type  PSoundDef=^TSoundDef;
		TSoundDef=record
			ID			:String[8];
			Desc		:string[55];
			ObjPos	:longint;
			ObjLen	:longint;
		end;
		PSoundPlayer=^TSoundPlayer;
		TSoundPlayer=object(TScrollerMenu)
			WadDir:PWadDirectory;
			Constructor Init(WDir:PWadDirectory);
			Procedure HandleEvent(var Event:TEvent); virtual;
			Procedure Draw; virtual;
			Destructor Done; virtual;
		end;

Implementation

var	SoundDefs:PCollection;

Procedure InitSoundDefs(WDir:PWadDirectory);

	var 	f:file of TSoundDef;
			S:PSoundDef;
			TmpName:ObjNameStr;
			SPos:word;

	begin
		assign(F,'DFESYS\SOUND.DEF');
		reset(f);
		SoundDefs:=New(PCollection, Init(65,5));
		while not eof(f) do begin
			New(S);
			Read(F, S^);
			FillChar(TmpName, 8, #00);
			Move(S^.ID[1], TmpName, Ord(S^.ID[0]));
			SPos:=WDir^.FindObject(TmpName);
			if SPos > 0 then begin
				S^.ObjLen:=WDir^.DirEntry^[SPos].ObjLength;
				S^.ObjPos:=WDir^.DirEntry^[SPos].ObjStart;
				SoundDefs^.Insert(S)
			 end
			else
				Dispose(S);
		end;
		close(f);
	end;


Constructor TSoundPlayer.Init(WDir:PWadDirectory);

	var 	R:Trect;
			t:integer;

	begin
		InitSoundDefs(WDir);
		Inherited Init('WAD Sound Player', SoundDefs);
		EnableCommands([cmPlaySound]);
		if SoundDefs^.Count=0 then begin
			DisableCommands([cmPlaySound]);
			R.Assign(5, Size.Y-3, Size.X-4, Size.Y-2);
			Insert(New(PstaticText, Init(R, 'No valid sounds in WAD file.')));
			R.Assign(35,7,45,9);
			Insert(New(PButton, Init(R,'~C~lose',cmCancel,bfDefault)));
		 end
		else begin
			R.Assign(35,5,45,7);
			InsertBefore(New(PButton, Init(R,'~P~lay',cmPlaySound,bfDefault)),ListScroller);
			R.Assign(35,7,45,9);
			InsertBefore(New(PButton, Init(R,'~C~lose',cmCancel,bfNormal)),ListScroller);
			R.Assign(35,9,45,11);
			Insert(New(PButton, Init(R,'~E~xport',cmExportSound,bfNormal)));
			ListScroller^.Select;
		end;
		WadDir:=WDir;
	end;

Procedure TSoundPlayer.HandleEvent(var Event:TEvent);

	var 	SBSound:PWadSound;
			SName:ObjNameStr;
			TempRec:PSoundDef;

	begin
		if (Event.What = evBroadcast) and (Event.Command = cmItemFocused) then
			DrawView
		else if (Event.What = evCommand) and ((Event.Command = cmPlaySound) or
				(Event.Command = cmOk) or (Event.Command = cmExportSound))then begin
			FillChar(SName, 8, #00);
			TempRec:=MenuList^.at(Selected);
			Move(TempRec^.ID[1],SName,Ord(TempRec^.ID[0]));
			WadResult:=0;
			SBSound:=New(PWadSound, Init(WadDir, SName));
			if WadResult<>wrOk then begin
				MessageBox(WadResultMsg(WadResult),Nil,mfError+ mfOkButton);
				exit;
			end;
			if Event.Command = cmExportSound then
				Sound2Wav(SBSound);
			SBSound^.PlaySound;
			Repeat
			until (SBSound^.IsComplete) or (KeyPressed);
			SBSound^.EndSound;
			Dispose(SBSound,done);
			ClearEvent(Event);
		end;
		inherited HandleEvent(Event);
	end;

Procedure TSoundPlayer.Draw;

	var	B:TDrawBuffer;
			S:PSoundDef;
			TempStr:string;
			D:Real;

	begin
		Inherited Draw;
		if MenuList^.Count > 0 then begin
			MoveChar(B, ' ', GetColor(1), Size.X);
			S:=MenuList^.At(ListScroller^.Focused);
			TempStr:='Description: '+S^.Desc;
			MoveStr(B,TempStr,GetColor(1));
			WriteLine(2, Size.Y-4, Size.X-4, 1, B);
			MoveChar(B, ' ', GetColor(1), Size.X);
			D:=S^.ObjLen / 11025;
			Str(D:2:2, TempStr);
			TempStr:='Duration: '+TempStr+' sec';
			MoveStr(B,TempStr,GetColor(1));
			WriteLine(2, Size.Y-3, Size.X-4, 1, B);
			MoveChar(B, ' ', GetColor(1), Size.X);
			TempStr:='Sound ID: '+S^.ID;
			MoveStr(B,TempStr,GetColor(1));
			WriteLine(2, Size.Y-2, Size.X-4, 1, B);
			Str(S^.ObjLen, TempStr);
			TempStr:='Size: '+TempStr;
			MoveChar(B, ' ', GetColor(1), Size.X);
			MoveStr(B,TempStr,GetColor(1));
			WriteLine(25, Size.Y-2, Size.X-29, 1, B);
		end;
	end;

Destructor TSoundPlayer.Done;

	var	s:PSoundDef;
			t:integer;

	begin
		for t:=0 to SoundDefs^.count-1 do begin
			s:=SoundDefs^.at(0);
			SoundDefs^.atDelete(0);
			Dispose(s);
		end;
		Dispose(SoundDefs, Done);
		Inherited Done;
	end;

end.
