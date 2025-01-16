uses App,Menus,Views,Dialogs,Drivers,Memory,Objects,crt,MsgBox;

const	cmDoMenu	= 101;
		cmNull	= 102;

type	PMyApp=^TMyApp;
		TMyApp=object(TApplication)
         Function GetPalette:PPalette; virtual;
			Procedure HandleEvent(var Event:TEvent); virtual;
         Procedure TestMenu;
         Procedure InitMenuBar; virtual;
      end;
      PScrollerMenu=^TScrollerMenu;
      TScrollerMenu=object(TDialog)
         MenuList:PStringCollection;
         ListScroller:PListBox;
         ScrollBar:PScrollBar;
			Constructor Init(ATitle:TTitleStr;List:PStringCollection);
         Procedure HandleEvent(var Event:TEvent); virtual;
			Function Selected:word;
         Destructor Done; virtual;
		end;

Constructor TScrollerMenu.Init(ATitle:TTitleStr;List:PStringCollection);

	var 	R:Trect;
         t:integer;

	begin
  		R.Assign(15,1,64,20);
   	Inherited Init(R,ATitle);
      R.Assign(31,2,32,13);
      ScrollBar:=New(PScrollBar, Init(R));
		R.Assign(2,2,31,13);
   	ListScroller:=New(PListBox, Init(R,1,ScrollBar));
      ListScroller^.NewList(List);
      R.Assign(35,5,45,7);
      Insert(New(PButton, Init(R,'~O~k',cmOk,bfDefault)));
      R.Assign(35,7,45,9);
      Insert(New(PButton, Init(R,'~C~ancel',cmCancel,bfNormal)));
      Insert(Scrollbar);
      Insert(ListScroller);
   end;

Procedure TScrollerMenu.HandleEvent(var Event:TEvent);

	begin
		if (Event.What = evMouseDown) and (Event.Double) then begin
			Event.What := evCommand;
			Event.Command := cmOK;
			PutEvent(Event);
			ClearEvent(Event);
		 end
		else inherited HandleEvent(Event);
	end;

Function TScrollerMenu.Selected:word;

	begin
   	Selected:=ListScroller^.Focused;
   end;

Destructor TScrollerMenu.Done;

	begin
   	Dispose(ListScroller, Done);
      Inherited Done;
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

Procedure TMyApp.HandleEvent(Var Event:TEvent);

	begin
		TApplication.HandleEvent(Event);
		if Event.What=evCommand then begin
			Case Event.Command of
         	cmDoMenu:TestMenu;
			else
				exit;
			end;
			ClearEvent(Event);
		end;
	end;

Procedure TMyApp.TestMenu;

	var	TheMenu:PScrollerMenu;
   		TheItems:PStringCollection;
   		R:Trect;
         Item:Array[1..16] of pstring;
         t:integer;
         Control:word;
         TempStr:String;
         PStr:PString;

   begin
   	R.Assign(5,15,65,20);
      TheItems:=New(PStringCollection, Init(16,2));
      for t:=1 to 16 do begin
			Str(t, TempStr);
         New(Item[t]);
         Item[t]^:='Item #'+TempStr;
	      TheItems^.Insert(Item[t]);
      end;
   	TheMenu:=New(PScrollerMenu, Init('The Items',TheItems));
      Control:=Desktop^.ExecView(TheMenu);
      if control=cmOK then begin
      	Pstr:=TheItems^.at(TheMenu^.Selected);
      	MessageBox('Your Selection:  '+Pstr^,Nil,mfInformation+mfOkButton)
       end
		else
   		MessageBox('Your Selection: Cancel',Nil,mfInformation+mfOkButton);

   end;

procedure TMyApp.InitMenuBar;

	var	r:TRect;

	begin
		GetExtent(r);
		R.B.Y:=1;
		MenuBar:=New(PMenuBar,Init(r,NewMenu(
			NewSubMenu('~T~est',hcNoContext,NewMenu(
				NewItem('~M~enu','',0,cmDoMenu,hcNoContext,
            Nil)),
			Nil))));
	end;

var MyApp:TMyApp;

begin
	MyApp.Init;
   MyApp.Run;
   MyApp.Done;
end.