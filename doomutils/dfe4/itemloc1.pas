{$F+,O+}
unit ItemLoc1;

interface
uses 	ThingDef,App,Dialogs,Views,Drivers,Menus,StdDlg,Objects,ListMenu,
		Dos,LoadPwad,WadDecl,Wad,DFEComm,Memory;

type 	DescType=string[65];
		PItemMenu=^TItemMenu;
		TItemMenu=object(TScrollerMenu)
			Constructor Init;
			Procedure HandleEvent(var Event:TEvent); virtual;
			Procedure Draw; virtual;
			Procedure LocateItem(ItemNum:word);
			Destructor Done; virtual;
		end;
		PItemCollection=^TItemCollection;
		TItemCollection=object(TStringCollection)
			Constructor Init(ALimit,ADelta:Integer);
			Function Compare(Key1,Key2:Pointer):Integer; virtual;
		end;

implementation

const	cmFindItem	= 115;

var	ThingList:PItemCollection;
		Instance:word;

Constructor TItemCollection.Init(ALimit,ADelta:Integer);

	begin
		Inherited Init(ALimit, ADelta);
		Duplicates:=True;
	end;

Function TItemCollection.Compare(Key1,Key2:Pointer):Integer;

	begin
		Compare:=-1;
	end;

Constructor TItemMenu.Init;

	var 	R:Trect;
			t:integer;
			TempDesc:String;

	begin
		if Instance = 0 then begin
			InitThingDefs;
			ThingList:=New(PItemCollection, Init(TotalThingDefs,2));
			ThingList^.Duplicates:=True;
			for t:=0 to TotalThingDefs - 1 do begin
				Move(ThingDefs^[t+1].Desc, TempDesc[1], 65);
				TempDesc[0]:=#65;
				ThingList^.Insert(NewStr(TempDesc));
			end;
		end;
		Inherited Init('Item List', ThingList);
		R.Assign(35,5,45,7);
		InsertBefore(New(PButton, Init(R,'~F~ind',cmFindItem,bfDefault)),ListScroller);
		R.Assign(35,7,45,9);
		InsertBefore(New(PButton, Init(R,'~C~lose',cmCancel,bfNormal)),ListScroller);
		ListScroller^.Select;
		Inc(Instance);
	end;

Procedure TItemMenu.HandleEvent(var Event:TEvent);

	begin
		if (Event.What = evBroadcast) and (Event.Command = cmItemFocused) then
			DrawView
		else if (Event.What = evCommand) and ((Event.Command = cmFindItem) or
				(Event.Command = cmOk)) then begin
			LocateItem(ListScroller^.Focused);
			ClearEvent(Event);
		end;
		inherited HandleEvent(Event);
	end;

Procedure TItemMenu.Draw;

	var	B:TDrawBuffer;
			TempStr:string;

	begin
		Inherited Draw;
		if MenuList^.Count > 0 then begin
			MoveChar(B, ' ', GetColor(1), Size.X);
			TempStr:='Sprite ID: '+ThingDefs^[ListScroller^.Focused+1].PictID;
			MoveStr(B,TempStr,GetColor(1));
			WriteLine(2, Size.Y-4, Size.X-4, 1, B);
			MoveChar(B, ' ', GetColor(1), Size.X);
			Str(ThingDefs^[ListScroller^.Focused+1].Num,TempStr);
			TempStr:='Thing ID: '+TempStr;
			MoveStr(B,TempStr,GetColor(1));
			WriteLine(2, Size.Y-3, Size.X-4, 1, B);
			MoveChar(B, ' ', GetColor(1), Size.X);
			TempStr:=ThingDefs^[ListScroller^.Focused+1].Desc;
			MoveStr(B,TempStr,GetColor(1));
			WriteLine(2, Size.Y-2, Size.X-4, 1, B);
		end;
	end;

Procedure TItemMenu.LocateItem(ItemNum:word);

	var 	PWadName:PathStr;
			SelLevel:PRadioButtons;
			Dialog1:PDialog;
			R:Trect;
			LevName:ObjNameStr;
			TempStr:PString;
			Control:word;
			LevelNames:LevelNameArray;

	begin
		if GetPWadName(PWadName,27,LevelNames,SelLevel)=cmOk then begin
			R.Assign(9,5,72,18);
			Dialog1:=New(PDialog, Init(R, 'Select PWAD Map'));
			R.Assign(34,3,60,4);
			Dialog1^.Insert(New(PstaticText, Init(R,'Select the Map to search.')));
			R.Assign(46,8,56,10);
			Dialog1^.Insert(New(PButton, Init(R,'~C~ancel',cmCancel,bfNormal)));
			R.Assign(34,8,44,10);
			Dialog1^.Insert(New(PButton, Init(R,'~O~k',cmOk,bfDefault)));
			Dialog1^.Insert(SelLevel);
			Control:=DeskTop^.ExecView(Dialog1);
			if Control=cmOk then begin
				with SelLevel^ do
					TempStr:=Strings.at(Value);
				LevName:='        ';
				move(TempStr^[1], LevName[1],4);
				Dispose(Dialog1, Done);
				TerminateOnWadError:=True;
				DoneSysError;
				DoneEvents;
				DoneVideo;
				SetMapCommands(dcItemLoc,PWadName,LevName,0,ThingDefs^[ItemNum + 1].Num);
				DoneDosMem;
				{FindItem(PWadName, LevName, ThingDefs^[ItemNum + 1].Num);}
				{$IFDEF DEBUG}
					DFELaunch('D:\BP\UNITS\MAPVIEW.EXE');
				{$ELSE}
					DFELaunch('DFESYS\MAPVIEW.EXE');
				{$ENDIF}
				InitDosMem;
				InitVideo;
				InitEvents;
				InitSysError;
				TerminateOnWadError:=False;
				DeskTop^.Redraw;
				if MenuBar <> Nil then
					MenuBar^.draw;
				if StatusLine <> Nil then
					StatusLine^.draw;
			 end
			else
				Dispose(Dialog1, Done);
		end;
	end;

Destructor TItemMenu.Done;

	begin
		if Instance=1 then begin
			Dispose(ThingList, Done);
			DoneThingDefs;
		end;
		Inherited Done;
		Dec(Instance);
	end;

Begin
Instance:=0;
end.