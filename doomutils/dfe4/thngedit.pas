{$R+}
unit THNGEDIT;

interface

uses Dialogs,Drivers,PtchComp,Objects,ListMenu;

const cmThingTable= 	100;
		cmCopyItem	= 104;
		cmPasteItem = 105;
		cmAutoCreate= 106;
		cmCopySpecial=107;
		cmIncThing	=	2000;
		cmDecThing	=	2001;
		cmFirstThing=	2002;
		cmLastThing	=	2003;
		cmBitEditor	=	2004;
		cmThingJump	=	2006;

type  PJumpList=^TJumpList;
		TJumpList=object(TScrollerMenu)
			Constructor Init;
			Destructor Done; virtual;
		end;
		PThingEditor=^TThingEditor;
		TThingEditor=object(TDialog)
			CurThing:word;
			ClipBoard:TThingEntry;
			InputLine:array[1..21] of PNumericInputLine;
			Constructor Init;
			Procedure HandleEvent(var Event:TEvent); virtual;
			Procedure Draw; virtual;
			Procedure SetInputLineData(t:integer);
			Procedure GetInputLineData(t:integer);
			Destructor Done; virtual;
		end;
		PBitField=^TBitField;
		TBitField=Object(TCheckBoxes)
			Procedure HandleEvent(var Event:TEvent); virtual;
		end;
		PBitEditor=^TBitEditor;
		TBitEditor=Object(TDialog)
			Bits1,Bits2:PBitField;
			Constructor Init(ThingBits:longint);
			Function GetValue:Longint;
		end;

implementation

uses app,views,Strings;

var	JumpThingList:PCollection;

Function GetSoundName(t,n:word):string;

	var	v:word;

	begin
		v:=ThingTable^[t][n];
		if v > v12SoundEntries then begin
			GetSoundName:='ERROR';
			exit;
		end;
		if v>0 then
			GetSoundName:=StrPas(@SoundTable^[v])
		else
			GetSoundName:='none';
	end;

Function GetFrameName(t,n:word):string;

	var	v,s:word;
			c:char;
			TempStr:string;

	begin
		v:=ThingTable^[t][n];
		if v > v12FrameEntries then begin
			GetFrameName:='ERROR';
			exit;
		end;
		if v > 0 then begin
			TempStr:=StrPas(@SpriteTable^[(FrameTable^[v][1] and $FFF)]);
			TempStr:=TempStr+chr(FrameTable^[v][2] + ord('A'));
			GetFrameName:=TempStr;
		 end
		else
			GetFrameName:='NONE'
	end;

Constructor TJumpList.Init;

	var 	R:Trect;
			t:integer;

	Procedure InitThingList;

		var 	t:integer;

		begin
			JumpThingList:=New(PCollection, Init(105,2));
			for t:=1 to 103 do
				JumpThingList^.Insert(NewStr(ThingNames[t]^));
		end;

	begin
		InitThingList;
		Inherited Init('Thing Jump List', JumpThingList);
		R.Assign(35,5,45,7);
		InsertBefore(New(PButton, Init(R,'~O~k',cmOk,bfDefault)),ListScroller);
		R.Assign(35,7,45,9);
		InsertBefore(New(PButton, Init(R,'~C~ancel',cmCancel,bfNormal)),ListScroller);
		R.Assign(3,15,47,16);
		Insert(New(PStaticText, init(R,'Please make jump selection from thing list')));
		ListScroller^.Select;
	end;

Destructor TJumpList.Done;

	var 	t:integer;
			p:PString;

	begin
		for t:=1 to 103 do begin
			p:=JumpThingList^.at(0);
			JumpThingList^.atDelete(0);
			DisposeStr(p);
		end;
		Dispose(JumpThingList, Done);
		Inherited Done;
	end;

Constructor TThingEditor.Init;

	var 	R:TRect;
			t:integer;

	begin
		R.Assign(6,2,76,22);
		Inherited Init(R, 'Thing Table Editor');
		R.Assign(5,17,19,19);
		Insert(New(PButton, init(R,'~B~it Editor',cmBitEditor,bfNormal)));
		R.Assign(38,17,46,19);
		Insert(New(PButton, Init(R,'~N~ext',cmIncThing,bfNormal)));
		R.Assign(47,17,59,19);
		Insert(New(PButton, Init(R,'~P~revious',cmDecThing,bfNormal)));
		R.Assign(60,17,68,19);
		Insert(New(PButton, Init(R,'~J~ump',cmThingJump,bfNormal)));
		CurThing:=1;
		R.Assign(2,4,17,5);
		Insert(New(PStaticText, Init(R,'Thing ID#:')));
		R.Assign(2,5,17,6);
		Insert(New(PStaticText, Init(R,'Hit Points:')));
		R.Assign(2,6,17,7);
		Insert(New(PStaticText, Init(R,'Speed:')));
		R.Assign(2,7,17,8);
		Insert(New(PStaticText, Init(R,'Width:')));
		R.Assign(2,8,17,9);
		Insert(New(PStaticText, Init(R,'Height:')));
		R.Assign(2,9,17,10);
		Insert(New(PStaticText, Init(R,'Missle Damage:')));
		R.Assign(2,10,17,11);
		Insert(New(PStaticText, Init(R,'Reaction Time:')));
		R.Assign(2,11,17,12);
		Insert(New(PStaticText, Init(R,'Pain Chance:')));
		R.Assign(2,12,17,13);
		Insert(New(PStaticText, Init(R,'Mass:')));
		R.Assign(26,4,46,5);
		Insert(New(PStaticText, Init(R,'Alert Sound#:')));
		R.Assign(26,5,46,6);
		Insert(New(PStaticText, Init(R,'Attack Sound#:')));
		R.Assign(26,6,46,7);
		Insert(New(PStaticText, Init(R,'Pain Sound#:')));
		R.Assign(26,7,46,8);
		Insert(New(PStaticText, Init(R,'Death Sound#:')));
		R.Assign(26,8,46,9);
		Insert(New(PStaticText, Init(R,'Action Sound#:')));
		R.Assign(26,9,46,10);
		Insert(New(PStaticText, Init(R,'First Normal Frame#:')));
		R.Assign(26,10,46,11);
		Insert(New(PStaticText, Init(R,'First Moving Frame#:')));
		R.Assign(26,11,46,12);
		Insert(New(PStaticText, Init(R,'Injury Frame#:')));
		R.Assign(26,12,46,13);
		Insert(New(PStaticText, Init(R,'Close Attack Frame#:')));
		R.Assign(26,13,46,14);
		Insert(New(PStaticText, Init(R,'Far Attack Frame#:')));
		R.Assign(26,14,46,15);
		Insert(New(PStaticText, Init(R,'Death Frame#:')));
		R.Assign(26,15,46,16);
		Insert(New(PStaticText, Init(R,'Explode Death Frame#:')));
		for t:=1 to 9 do begin
			R.Assign(18,3+t,24,4+t);
			InputLine[t]:=New(PNumericInputLine, Init(R, 4));
			Insert(InputLine[t]);
		end;
		for t:=1 to 12 do begin
			R.Assign(47,3+t,55,4+t);
			InputLine[t+9]:=New(PNumericInputLine, Init(R, 4));
			Insert(InputLine[t+9]);
		end;
		SetInputLineData(CurThing);
		InputLine[1]^.Select;
	end;

Procedure TThingEditor.HandleEvent(var Event:TEvent);

	var	B:PBitEditor;
			J:PJumpList;

	begin

		if (Event.What = evCommand) and (Event.Command = cmClose) then begin
			EnableCommands([cmThingTable]);
			DeskTop^.Delete(@Self);
			DeskTop^.Redraw;
			ClearEvent(Event);
			exit;
		end;
		Inherited HandleEvent(Event);
		if (Event.What=evCommand) then begin
			case Event.Command of
				cmBitEditor:begin
					B:=New(PBitEditor, Init(ThingTable^[CurThing][22]));
					if Desktop^.ExecView(B) <> cmCancel then
						ThingTable^[CurThing][22]:=B^.GetValue;
					Dispose(B, Done);
				end;
				cmIncThing:begin
					if CurThing < 103 then begin
						GetInputLineData(CurThing);
						Inc(CurThing);
						SetInputLineData(CurThing);
						DrawView;
					end;
				end;
				cmDecThing:begin
					if CurThing > 1 then begin
						GetInputLineData(CurThing);
						Dec(CurThing);
						SetInputLineData(CurThing);
						DrawView;
					end;
				end;
				cmThingJump:begin
					J:=New(PJumpList, Init);
					if DeskTop^.ExecView(J) = cmOk then begin
						GetInputLineData(CurThing);
						CurThing:=J^.Selected + 1;
						SetInputLineData(CurThing);
						DrawView;
					end;
					Dispose(J, Done);
				end;
				cmItemChanged:begin
					GetInputLineData(CurThing);
					DrawView;
				end;
				cmCopyItem:if (State and sfFocused) <> 0 then begin
					EnableCommands([cmPasteItem]);
					GetInputLineData(CurThing);
					ClipBoard:=ThingTable^[CurThing];
					ClearEvent(Event);
				end;
				cmPasteItem:if (State and sfFocused) <> 0 then begin
					ThingTable^[CurThing]:=ClipBoard;
					SetInputLineData(CurThing);
					DrawView;
					ClearEvent(Event);
				end;
			end;
		end;
	end;

Procedure TThingEditor.Draw;

	var	B:TDrawBuffer;
			TempStr:string;
			C:integer;

	procedure SetString;

		begin
			if TempStr<>'[ERROR]   ' then
				MoveStr(B,TempStr,GetColor(1))
			else
				MoveStr(B,TempStr,159);
		end;

	begin
		Inherited Draw;
		ShowCursor;
		TempStr:='Thing Name: '+ThingNames[CurThing]^;
		MoveStr(B,TempStr,GetColor(2));
		WriteLine(2, 2, 31, 1, B);
		Str(CurThing, TempStr);
		TempStr:='Thing Number: '+TempStr+'   ';
		MoveStr(B,TempStr,GetColor(2));
		WriteLine(35, 2, 18, 1, B);

		{Display Sounds}
		TempStr:='['+GetSoundName(CurThing,5)+']   ';
		SetString;
		WriteLine(56, 4, 8, 1, B);
		TempStr:='['+GetSoundName(CurThing,7)+']   ';
		SetString;
		WriteLine(56, 5, 8, 1, B);
		TempStr:='['+GetSoundName(CurThing,10)+']   ';
		SetString;
		WriteLine(56, 6, 8, 1, B);
		TempStr:='['+GetSoundName(CurThing,15)+']   ';
		SetString;
		WriteLine(56, 7, 8, 1, B);
		TempStr:='['+GetSoundName(CurThing,21)+']   ';
		SetString;
		WriteLine(56, 8, 8, 1, B);

		{Display Frames}
		TempStr:='['+GetFrameName(CurThing,2)+']   ';
		SetString;
		WriteLine(56, 9, 7, 1, B);
		TempStr:='['+GetFrameName(CurThing,4)+']   ';
		SetString;
		WriteLine(56, 10, 7, 1, B);
		TempStr:='['+GetFrameName(CurThing,8)+']   ';
		SetString;
		WriteLine(56, 11, 7, 1, B);
		TempStr:='['+GetFrameName(CurThing,11)+']   ';
		SetString;
		WriteLine(56, 12, 7, 1, B);
		TempStr:='['+GetFrameName(CurThing,12)+']   ';
		SetString;
		WriteLine(56, 13, 7, 1, B);
		TempStr:='['+GetFrameName(CurThing,13)+']   ';
		SetString;
		WriteLine(56, 14, 7, 1, B);
		TempStr:='['+GetFrameName(CurThing,14)+']   ';
		SetString;
		WriteLine(56, 15, 7, 1, B);
	end;

Procedure TThingEditor.SetInputLineData(t:integer);

	var 	x:integer;
			Temp:Longint;

	begin
		for x:=1 to 21 do begin
			case x of
				1:Temp:=ThingTable^[t][1];
				2:Temp:=ThingTable^[t][3];
				3:begin
					if (t = 1) or ((ThingTable^[t][22] and 1024) = 0) then
						Temp:=ThingTable^[t][16]
					else
						Temp:=ThingTable^[t][16] div 65536;
				end;
				4:Temp:=ThingTable^[t][17] div 65536;
				5:Temp:=ThingTable^[t][18] div 65536;
				6:Temp:=ThingTable^[t][20];
				7:Temp:=ThingTable^[t][6];
				8:Temp:=ThingTable^[t][9];
				9:Temp:=ThingTable^[t][19];
				10:Temp:=ThingTable^[t][5];
				11:Temp:=ThingTable^[t][7];
				12:Temp:=ThingTable^[t][10];
				13:Temp:=ThingTable^[t][15];
				14:Temp:=ThingTable^[t][21];
				15:Temp:=ThingTable^[t][2];
				16:Temp:=ThingTable^[t][4];
				17:Temp:=ThingTable^[t][8];
				18:Temp:=ThingTable^[t][11];
				19:Temp:=ThingTable^[t][12];
				20:Temp:=ThingTable^[t][13];
				21:Temp:=ThingTable^[t][14];
				22:Temp:=ThingTable^[t][22];
			end;
			InputLine[x]^.SetData(Temp);
			InputLine[x]^.DrawView;
		end;
	end;

Procedure TThingEditor.GetInputLineData(t:integer);

	var 	x:integer;
			Temp:longint;

	begin
		for x:=1 to 21 do begin
			case x of
				1:InputLine[x]^.GetData(ThingTable^[t][1]);
				2:InputLine[x]^.GetData(ThingTable^[t][3]);
				3:begin
					if (t = 1) or ((ThingTable^[t][22] and 1024) = 0) then
						InputLine[x]^.GetData(ThingTable^[t][16])
					else begin
						InputLine[x]^.GetData(Temp);
						ThingTable^[t][16]:=Temp * 65536;
					end;
				end;
				4:begin
					InputLine[x]^.GetData(ThingTable^[t][17]);{*}
					ThingTable^[t][17]:=ThingTable^[t][17] * 65536;
				end;
				5:begin
					InputLine[x]^.GetData(ThingTable^[t][18]);{*}
					ThingTable^[t][18]:=ThingTable^[t][18] * 65536;
				end;
				6:InputLine[x]^.GetData(ThingTable^[t][20]);
				7:InputLine[x]^.GetData(ThingTable^[t][6]);
				8:InputLine[x]^.GetData(ThingTable^[t][9]);
				9:InputLine[x]^.GetData(ThingTable^[t][19]);
				10:InputLine[x]^.GetData(ThingTable^[t][5]);
				11:InputLine[x]^.GetData(ThingTable^[t][7]);
				12:InputLine[x]^.GetData(ThingTable^[t][10]);
				13:InputLine[x]^.GetData(ThingTable^[t][15]);
				14:InputLine[x]^.GetData(ThingTable^[t][21]);
				15:InputLine[x]^.GetData(ThingTable^[t][2]);
				16:InputLine[x]^.GetData(ThingTable^[t][4]);
				17:InputLine[x]^.GetData(ThingTable^[t][8]);
				18:InputLine[x]^.GetData(ThingTable^[t][11]);
				19:InputLine[x]^.GetData(ThingTable^[t][12]);
				20:InputLine[x]^.GetData(ThingTable^[t][13]);
				21:InputLine[x]^.GetData(ThingTable^[t][14]);
				22:InputLine[x]^.GetData(ThingTable^[t][22]);
			end;
			InputLine[x]^.DrawView;
		end;
	end;

Destructor TThingEditor.Done;

	begin
		Inherited Done;
	end;

Procedure TBitField.HandleEvent(var Event:TEvent);

	begin
		if Event.What=evKeyDown then begin
			case Event.KeyCode of
				kbRight:begin
							Event.KeyCode:=kbShiftTab;
						  end;
				kbLeft:begin
							Event.KeyCode:=kbTab;
						  end;
			end;
		end;
		Inherited HandleEvent(Event);
	end;

Constructor TBitEditor.Init(ThingBits:longint);

	var	R:TRect;

	begin
		R.Assign(5,1,75,21);
		Inherited Init(R, 'BIT EDITOR');
		R.Assign(2,2,22,18);
		Bits1:=New(PBitField, Init(R,
			NewSItem('Gettable Thing',
			NewSItem('Obstacle',
			NewSItem('Can Be Hurt',
			NewSItem('Total Invis.',
			NewSItem('Automatics',
			NewSItem('Unknown',
			NewSItem('Unknown',
			NewSItem('Unknown',
			NewSItem('Hangs from Ceil.',
			NewSItem('Not on Ground',
			NewSItem('Proj/Player',
			NewSItem('Can Get Stuff',
			NewSItem('No Clipping',
			NewSItem('Unknown',
			NewSItem('Float Monsters',
			NewSItem('Semi-No Clip',
			Nil))))))))))))))))));
		R.Assign(23,2,43,18);
		Bits2:=New(PBitField,Init(R,
			NewSItem('Projectiles',
			NewSItem('Unknown',
			NewSItem('Patial Invis.',
			NewSItem('Blood/Puffs',
			NewSItem('Unknown',
			NewSItem('Unknown',
			NewSItem('Counts for Kill%',
			NewSItem('Counts for Item%',
			NewSItem('Unknown',
			NewSItem('Not In DMatch',
			NewSItem('Color1',
			NewSItem('Color2',
			NewSItem('Unknown',
			NewSItem('Unknown',
			NewSItem('Unknown',
			NewSItem('Unknown',
			Nil))))))))))))))))));
			Bits1^.Value:=ThingBits and $FFFF;
			Bits2^.Value:=(ThingBits and $FFFF0000) shr 16;
			R.Assign(50,16,60,18);
			Insert(New(PButton, Init(R,'~O~k', cmOk, bfDefault)));
			R.Assign(50,14,60,16);
			Insert(New(PButton, Init(R,'~C~ancel', cmCancel, bfNormal)));
			Insert(Bits2);
			Insert(Bits1);
	end;

Function TBitEditor.GetValue:longint;

	var	TempValue:longint;

	begin
		TempValue:=Bits1^.Value and $FFFF;
		TempValue:=TempValue or ((Bits2^.Value and $FFFF) shl 16);
		GetValue:=TempValue;
	end;

end.
