unit AmmoEdit;

interface

uses Dialogs,Drivers,PtchComp;

Const cmAmmoTable	= 101;
		cmCopyItem	= 104;
		cmPasteItem = 105;
		cmAutoCreate= 106;
		cmCopySpecial=107;
		cmIncAmmo	= 2200;
		cmDecAmmo	= 2201;

type	PAmmoEditor=^TAmmoEditor;
		TAmmoEditor=object(TDialog)
			CurAmmo:integer;
			OldAmmo:integer;
			ClipBoard:TWeaponEntry;
			InputLine:array[1..8] of PNumericInputLine;
			Constructor Init;
			Procedure HandleEvent(var Event:TEvent); virtual;
			Procedure Draw; virtual;
			Procedure SetInputLineData(t:integer);
			Procedure GetInputLineData(t:integer);
		end;

implementation

uses App,Objects,MsgBox,Views,Strings,Crt;

Function GetFrameName(t,n:word):string;

	var	v,s:word;
			c:char;
			TempStr:string;

	begin
		v:=WeaponTable^[t][n];
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

Function WeaponName(t:integer):string;

	begin
		case t of
			1:WeaponName:='Punch';
			2:WeaponName:='Pistol';
			3:WeaponName:='Shotgun';
			4:WeaponName:='Chaingun';
			5:WeaponName:='Rocket Launcher';
			6:WeaponName:='Plasma Gun';
			7:WeaponName:='BFG9000';
			8:WeaponName:='Chainsaw';
		else
			WeaponName:='ERROR';
		end;
	end;

Function AmmoName(t:integer):string;

	var	l:longint;

	begin
		l:=WeaponTable^[t][1];
		case l of
			0:AmmoName:='Bullets';
			1:AmmoName:='Shells';
			2:AmmoName:='Energy Cells';
			3:AmmoName:='Rockets';
			4:AmmoName:='Unknown';
			5:AmmoName:='N/A';
		else
			AmmoName:='ERROR';
		end;
	end;

Constructor TAmmoEditor.Init;

	var 	R:TRect;
			t:integer;

	begin
		ShowCursor;
		R.Assign(4,1,50,17);
		Inherited Init(R, 'Ammo Table Editor');
		R.Assign(20,13,30,15);
		Insert(New(PButton, Init(R,'~N~ext',cmIncAmmo,bfNormal)));
		R.Assign(31,13,43,15);
		Insert(New(PButton, Init(R,'~P~revious',cmDecAmmo,bfNormal)));
		CurAmmo:=1;
		R.Assign(2,4,17,5);
		Insert(New(PStaticText, Init(R,'Ammo ID#:')));
		R.Assign(2,5,17,6);
		Insert(New(PStaticText, Init(R,'Max Ammo Cap:')));
		R.Assign(2,6,17,7);
		Insert(New(PStaticText, Init(R,'Ammo per Item:')));
		R.Assign(2,7,18,8);
		Insert(New(PStaticText, Init(R,'Bobbing1 Frame#:')));
		R.Assign(2,8,18,9);
		Insert(New(PStaticText, Init(R,'Bobbing2 Frame#:')));
		R.Assign(2,9,18,10);
		Insert(New(PStaticText, Init(R,'Bobbing3 Frame#:')));
		R.Assign(2,10,18,11);
		Insert(New(PStaticText, Init(R,'Shooting Frame#:')));
		R.Assign(2,11,17,12);
		Insert(New(PStaticText, Init(R,'Firing Frame#:')));
		for t:=1 to 8 do begin
			R.Assign(18,3+t,24,4+t);
			InputLine[t]:=New(PNumericInputLine, Init(R, 4));
			Insert(InputLine[t]);
		end;
		SetInputLineData(CurAmmo);
		InputLine[1]^.Select;
	end;

Procedure TAmmoEditor.HandleEvent(var Event:TEvent);

	begin

		if (Event.What = evCommand) and (Event.Command = cmClose) then begin
			EnableCommands([cmAmmoTable]);
			DeskTop^.Delete(@Self);
			DeskTop^.Redraw;
			ClearEvent(Event);
			exit;
		end;
		Inherited HandleEvent(Event);
		if (Event.What=evCommand) then begin
			case Event.Command of
				cmIncAmmo:begin
					if CurAmmo < 8 then begin
						GetInputLineData(CurAmmo);
						Inc(CurAmmo);
						SetInputLineData(CurAmmo);
						DrawView;
					end;
				end;
				cmDecAmmo:begin
					if CurAmmo > 1 then begin
						GetInputLineData(CurAmmo);
						Dec(CurAmmo);
						SetInputLineData(CurAmmo);
						DrawView;
					end;
				end;
				cmItemChanged:begin
					GetInputLineData(CurAmmo);
					SetInputLineData(CurAmmo);
					DrawView;
				end;
				cmCopyItem:if (State and sfFocused) <> 0 then begin
					EnableCommands([cmPasteItem]);
					GetInputLineData(CurAmmo);
					ClipBoard:=WeaponTable^[CurAmmo];
					ClearEvent(Event);
				end;
				cmPasteItem:if (State and sfFocused) <> 0 then begin
					WeaponTable^[CurAmmo]:=ClipBoard;
					SetInputLineData(CurAmmo);
					DrawView;
					ClearEvent(Event);
				end;
			end;
		end;
	end;

Procedure TAmmoEditor.Draw;

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
		TempStr:='Weapon Name: '+WeaponName(CurAmmo);
		MoveStr(B,TempStr,GetColor(2));
		WriteLine(2, 2, Length(TempStr), 1, B);
		TempStr:='Ammo Type: '+AmmoName(CurAmmo);
		MoveStr(B,TempStr,GetColor(2));
		WriteLine(2, 3, Length(TempStr), 1, B);

		{Display Frames}
		TempStr:='['+GetFrameName(CurAmmo,2)+']   ';
		SetString;
		WriteLine(25, 7, 7, 1, B);
		TempStr:='['+GetFrameName(CurAmmo,3)+']   ';
		SetString;
		WriteLine(25, 8, 7, 1, B);
		TempStr:='['+GetFrameName(CurAmmo,4)+']   ';
		SetString;
		WriteLine(25, 9, 7, 1, B);
		TempStr:='['+GetFrameName(CurAmmo,5)+']   ';
		SetString;
		WriteLine(25, 10, 7, 1, B);
		TempStr:='['+GetFrameName(CurAmmo,6)+']   ';
		SetString;
		WriteLine(25, 11, 7, 1, B);
	end;

Procedure TAmmoEditor.SetInputLineData(t:integer);

	var 	x:integer;
			Temp:Longint;

	begin
		for x:=1 to 8 do begin
			case x of
				1:Temp:=WeaponTable^[t][1];
				2:begin
					Temp:=WeaponTable^[t][1];
					if Temp > 5 then Temp:=0;
					if Temp = 5 then begin
						if InputLine[2]^.GetState(sfVisible) then
							InputLine[2]^.Hide
					 end
					else
						if not InputLine[2]^.GetState(sfVisible) then begin
							InputLine[2]^.Show;
							InputLine[2]^.DrawView;
						end;
					if Temp >= 5 then
						Temp:=0
					else
						Temp:=MaxAmmoTable[Temp];
				end;
				3:begin
					Temp:=WeaponTable^[t][1];
					if Temp > 5 then Temp:=0;
					if Temp = 5 then begin
						if InputLine[3]^.GetState(sfVisible) then
							InputLine[3]^.Hide
					 end
					else
						if not InputLine[3]^.GetState(sfVisible) then begin
							InputLine[3]^.Show;
							InputLine[3]^.DrawView;
						end;
					if Temp >= 5 then
						Temp:=0
					else
						Temp:=PerAmmoTable[Temp];
				end;
				4:Temp:=WeaponTable^[t][2];
				5:Temp:=WeaponTable^[t][3];
				6:Temp:=WeaponTable^[t][4];
				7:Temp:=WeaponTable^[t][5];
				8:Temp:=WeaponTable^[t][6];
			end;
			InputLine[x]^.SetData(Temp);
			InputLine[x]^.DrawView;
		end;
	end;

Procedure TAmmoEditor.GetInputLineData(t:integer);

	var 	x:integer;
			Temp:longint;

	begin
		for x:=1 to 8 do begin
			case x of
				1:InputLine[x]^.GetData(WeaponTable^[t][1]);
				2:Begin
					InputLine[1]^.GetData(Temp);
					if (Temp <> OldAmmo) then begin
						if Temp < 5 then
							InputLine[x]^.SetData(MaxAmmoTable[Temp]);
					end;
					{Temp:=WeaponTable^[t][1];}
					if Temp < 5 then
						InputLine[x]^.GetData(MaxAmmoTable[Temp]);
				end;
				3:Begin
					InputLine[1]^.GetData(Temp);
					if (Temp <> OldAmmo) then begin
						if Temp < 5 then
							InputLine[x]^.SetData(PerAmmoTable[Temp]);
						OldAmmo:=Temp;
					end;
					{Temp:=WeaponTable^[t][1];}
					if Temp < 5 then
						InputLine[x]^.GetData(PerAmmoTable[Temp]);
				end;
				4:InputLine[x]^.GetData(WeaponTable^[t][2]);
				5:InputLine[x]^.GetData(WeaponTable^[t][3]);
				6:InputLine[x]^.GetData(WeaponTable^[t][4]);
				7:InputLine[x]^.GetData(WeaponTable^[t][5]);
				8:InputLine[x]^.GetData(WeaponTable^[t][6]);
			end;
			InputLine[x]^.DrawView;
		end;
	end;

end.
