{$F+,O+}
unit ListMenu;

interface

uses Views,Dialogs,Drivers,Memory,Objects,crt,MsgBox;

const	cmItemFocused	= 152;

type  PScrollerList=^TScrollerList;
		TScrollerList=object(TListBox)
			Procedure HandleEvent(var Event:TEvent); virtual;
			Procedure FocusItem(Item: Integer); virtual;
		end;
		PScrollerMenu=^TScrollerMenu;
		TScrollerMenu=object(TDialog)
			MenuList:PCollection;
			ListScroller:PScrollerList;
			ScrollBar:PScrollBar;
			Constructor Init(ATitle:TTitleStr;List:PCollection);
			Procedure HandleEvent(var Event:TEvent); virtual;
			Function Selected:word;
			Destructor Done; virtual;
		end;
		PSelectorList=^TSelectorList;
		TSelectorList=Object(TDialog)
			FromList:PCollection;
			ToList:PCollection;
			FromScroller:PScrollerList;
			ToScroller:PScrollerList;
			FromScrollBar:PScrollBar;
			ToScrollBar:PScrollBar;
			Constructor Init(ATitle:TTitleStr;FromLst,ToLst:PCollection);
			Procedure HandleEvent(var Event:TEvent); virtual;
			Procedure MoveTo(Index:Integer);
			Procedure MoveFrom(Index:integer);
			Destructor Done; virtual;
		end;

implementation

Procedure TScrollerList.HandleEvent(var Event:TEvent);

	begin
		if (Event.What = evMouseDown) and (Event.Double) then begin
			Event.What := evCommand;
			Event.Command := cmOK;
			PutEvent(Event);
			ClearEvent(Event);
		 end
		else inherited HandleEvent(Event);
	end;

Procedure TScrollerList.FocusItem(Item:integer);

	begin
		Inherited FocusItem(Item);
		Message(Owner, evBroadCast, cmItemFocused, List^.at(Item));
	end;

Constructor TScrollerMenu.Init(ATitle:TTitleStr;List:PCollection);

	var 	R:Trect;
			t:integer;

	begin
		R.Assign(14,1,63,20);
		Inherited Init(R,ATitle);
		if List^.Count > 0 then begin
			R.Assign(31,2,32,13);
			ScrollBar:=New(PScrollBar, Init(R));
			R.Assign(2,2,31,13);
			ListScroller:=New(PScrollerList, Init(R,1,ScrollBar));
			ListScroller^.NewList(List);
			Insert(Scrollbar);
			Insert(ListScroller);
		 end
		else begin
			R.Assign(8,8,32,9);
			Insert(New(PstaticText, init(R, 'No list to display.')));
		end;
		MenuList:=List;
	end;

Procedure TScrollerMenu.HandleEvent(var Event:TEvent);

	begin
		inherited HandleEvent(Event);
		if (Event.What = evBroadcast) and (Event.Command = cmItemFocused) then begin
			DrawView;
		end;
	end;

Function TScrollerMenu.Selected:word;

	begin
		if MenuList^.Count > 0 then
			Selected:=ListScroller^.Focused
		else
			Selected:=0;
	end;

Destructor TScrollerMenu.Done;

	begin
		Inherited Done;
	end;

Constructor TSelectorList.Init(ATitle:TTitleStr;FromLst,ToLst:PCollection);

	var	R:Trect;

	begin
		R.Assign(5,1,75,20);
		Inherited Init(R,ATitle);
		R.Assign(20,2,21,13);
		FromScrollBar:=New(PScrollBar, Init(R));
		R.Assign(2,2,20,13);
		FromScroller:=New(PScrollerList, Init(R,1,FromScrollBar));
		FromScroller^.NewList(FromLst);
		Insert(FromScrollbar);
		Insert(FromScroller);

		R.Assign(66,2,67,13);
		ToScrollBar:=New(PScrollBar, Init(R));
		R.Assign(48,2,66,13);
		ToScroller:=New(PScrollerList, Init(R,1,ToScrollBar));
		ToScroller^.NewList(ToLst);
		Insert(ToScrollbar);
		Insert(ToScroller);

		FromList:=FromLst;
		ToList:=ToLst;
	end;

Procedure TSelectorList.HandleEvent(var Event:TEvent);

	begin
		Inherited HandleEvent(Event);
	end;

Procedure TSelectorList.MoveTo(Index:integer);

	var	P:Pointer;

	begin
		if (Index > (FromList^.Count - 1)) or (FromList^.Count = 0) then
			Exit;
		P:=FromList^.At(Index);
		ToList^.Insert(P);
		FromList^.Delete(P);
		ToScroller^.SetRange(ToList^.Count);
		FromScroller^.SetRange(FromList^.Count);
		ToScroller^.DrawView;
		FromScroller^.DrawView;
	end;

Procedure TSelectorList.MoveFrom(Index:integer);

	var	P:Pointer;

	begin
		if (Index > (ToList^.Count - 1)) or (ToList^.Count = 0) then
			Exit;
		P:=ToList^.At(Index);
		FromList^.Insert(P);
		ToList^.Delete(P);
		FromScroller^.SetRange(FromList^.Count);
		ToScroller^.SetRange(ToList^.Count);
		ToScroller^.DrawView;
		FromScroller^.DrawView;
	end;

Destructor TSelectorList.Done;

	begin
		Inherited Done;
	end;

end.