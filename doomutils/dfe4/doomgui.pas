{****************************************************************************
*                      The DOOM Hacker's Tool Kit                           *
*****************************************************************************
* Unit:    DOOMGUI                                                          *
* Purpose: Graphical User Interface Routines                                *
* Date:    4/28/94                                                          *
* Author:  Joshua Jackson        Internet: joshjackson@delphi.com           *
****************************************************************************}

unit DOOMGUI;

interface

uses Graph,GUIEvent,GUIObj;

const	wcWhite		= 5;
		wcLtGrey		= 86;
		wcGrey		= 95;
		wcDkGrey		= 99;
		wcBlack		= 0;
		wcLtBlue		= 198;
		wcBlue		= 204;
		wcDkBlue		= 207;
		wcLtGreen	= 124;
		wcGreen		= 120;
		wcDkGreen	= 124;
		wcLtPink		= 171;
		wcPink		= 174;
		wcRed			= 177;
		wcDkRed		= 185;
		wcLtPurple	= 252;
		wcPurple		= 253;
		wcDkPurple	= 254;
		wcLtYellow	= 228;
		wcYellow		= 231;

type	PGraphView=^TGraphView;
		PGraphGroup=^TGraphGroup;
		TGraphView=object
			Owner:PGraphGroup;
			Next:PGraphView;
			Prev:PGraphView;
			Bounds:TGraphRect;
			Constructor Init(R:TGraphRect);
			Function EventAvail:Boolean; virtual;
			Procedure GetEvent(var Event:TGraphEvent); virtual;
			Procedure PutEvent(var Event:TGraphEvent); virtual;
			Procedure Draw; virtual;
			Destructor Done; virtual;
		end;
		TGraphGroup=object(TGraphView)
			Current:PGraphView;
			GroupList:PGraphView;
			xs,ys,xe,ye:word;
			Constructor Init(R:TGraphRect);
			Procedure Insert(SubView:PGraphView); virtual;
			Procedure Draw; virtual;
			Procedure Delete(SubView:PGraphView); virtual;
			Destructor Done; virtual;
		end;
		PGraphWindow=^TGraphWindow;
		TGraphWindow=object(TGraphGroup)
			Constructor Init(R:TGraphRect);
			Function InWindow(x,y:word):boolean;
			Procedure Draw; virtual;
		end;
		PGraphButton=^TGraphButton;
		TGraphButton=object(TGraphView)
			IsPressed:byte;
			Xs,Ys,Xe,Ye:word;
			XOfs,YOfs:word;
			TitleStr:string;
			TitleColor:word;
			Constructor Init(R:TGraphRect;TColor:word;Title:string);
			Function InButton(x,y:word):boolean; virtual;
			Procedure Press; virtual;
			Procedure Release; virtual;
			Procedure Toggle; virtual;
			Procedure Draw; virtual;
		end;
		PGraphText=^TGraphText;
		TGraphText=object(TGraphView)
			DataStr:string;
			Constructor Init(R:TGraphRect;TextStr:String);
			Procedure Draw; virtual;
		end;

implementation

Constructor TGraphView.Init(R:TGraphRect);

	begin
		Owner:=Nil;
	end;

Function TGraphView.EventAvail:Boolean;

	begin
	end;

Procedure TGraphView.GetEvent(var Event:TGraphEvent);

	begin
	end;

Procedure TGraphView.PutEvent(var Event:TGraphEvent);

	begin
	end;

Procedure TGraphView.Draw;

	begin
	end;

Destructor TGraphView.Done;

	begin
	end;

Constructor TGraphGroup.Init(R:TGraphRect);

	begin
		Bounds:=r;
		GroupList:=Nil;
		Owner:=Nil;
		Next:=Nil;
	end;

Procedure TGraphGroup.Insert(SubView:PGraphView);

	begin
		if GroupList=Nil then begin
			GroupList:=SubView;
			SubView^.Prev:=Nil;
			Current:=SubView;
		 end
		else
			SubView^.Prev:=Current;
		SubView^.Owner:=@Self;
		Current^.Next:=SubView;
		SubView^.Next:=Nil;
		Current:=SubView;
	end;

Procedure TGraphGroup.Draw;

	var SubView:PGraphView;

	begin
		SubView:=GroupList;
		while SubView <> Nil do begin
			SubView^.Draw;
			SubView:=SubView^.Next;
		end;
	end;

Procedure TGraphGroup.Delete(SubView:PGraphView);

	begin
	end;

Destructor TGraphGroup.Done;

	var SubView,TempView:PGraphView;

	begin
		SubView:=GroupList;
		while SubView <> Nil do begin
			TempView:=SubView^.Next;
			Dispose(SubView, Done);
			SubView:=TempView;
		end;
	end;

Constructor TGraphWindow.Init(R:TGraphRect);

	begin
		Bounds:=R;
		GroupList:=Nil;
		Owner:=Nil;
	end;

Function TGraphWindow.InWindow(x,y:word):boolean;

	begin
		if (x>=xs) and (x<=xe) and (y>=ys) and (y<=ye) then
			InWindow:=True
		else
			InWindow:=False;
	end;

Procedure TGraphWindow.Draw;

	var SubView:PGraphView;

	begin
		if Owner=Nil then begin
			xs:=Bounds.a.x;
			xe:=Bounds.b.x;
			ys:=Bounds.a.y;
			ye:=Bounds.b.y;
		 end
		else begin
			xs:=Bounds.a.x+Owner^.Bounds.a.x;
			xe:=Bounds.b.x+Owner^.Bounds.a.x;
			ys:=Bounds.a.y+Owner^.Bounds.a.y;
			ye:=Bounds.b.y+Owner^.Bounds.a.y;
		end;
		Setcolor(wcLtGrey);
		line(xs,ys,xe,ys);
		line(xs+1,ys+1,xe-1,ys+1);
		line(xs,ys,xs,ye);
		line(xs+1,ys+1,xs+1,ye-1);
		Setcolor(wcDkGrey);
		line(xs,ye,xe,ye);
		line(xs+1,ye-1,xe-1,ye-1);
		line(xe,ye,xe,ys);
		line(xe-1,ye-1,xe-1,ys+1);
		SetFillStyle(SolidFill,wcGrey);
		bar(xs+2,ys+2,xe-2,ye-2);
		SubView:=GroupList;
		while SubView <> Nil do begin
			SubView^.Draw;
			SubView:=SubView^.Next;
		end;
	end;


Constructor TGraphButton.Init(R:TGraphRect;TColor:word;Title:string);

	var	BuffSize:word;

	begin
		Bounds:=r;
		TitleStr:=Title;
		TitleColor:=TColor;
		IsPressed:=0;
		Owner:=Nil;
		Next:=Nil;
	end;

Function TGraphButton.InButton(x,y:word):boolean;

	begin
		if (x>=xs) and (x<=xe) and (y>=ys) and (y<=ye) then
			InButton:=True
		else
			InButton:=False;
	end;

Procedure TGraphButton.Press;

	begin
		if Owner=Nil then begin
			xs:=Bounds.a.x;
			xe:=Bounds.b.x;
			ys:=Bounds.a.y;
			ye:=Bounds.b.y;
		 end
		else begin
			xs:=Bounds.a.x+Owner^.Bounds.a.x;
			xe:=Bounds.b.x+Owner^.Bounds.a.x;
			ys:=Bounds.a.y+Owner^.Bounds.a.y;
			ye:=Bounds.b.y+Owner^.Bounds.a.y;
		end;
		XOfs:=((Xe - Xs) - TextWidth(TitleStr)) div 2;
		YOfs:=((Ye - Ys) - TextHeight(TitleStr)) div 2;
		Setcolor(wcDkGrey);
		line(xs,ys,xe,ys);
		line(xs+1,ys+1,xe-1,ys+1);
		line(xs,ys,xs,ye);
		line(xs+1,ys+1,xs+1,ye-1);
		Setcolor(wcLtGrey);
		line(xs,ye,xe,ye);
		line(xs+1,ye-1,xe-1,ye-1);
		line(xe,ye,xe,ys);
		line(xe-1,ye-1,xe-1,ys+1);
		SetFillStyle(SolidFill,wcGrey);
		bar(xs+2,ys+2,xe-2,ye-2);
		SetColor(TitleColor);
		SetTextStyle(0,0,1);
		OutTextXY(xs+XOfs,ys+YOfs,TitleStr);
		IsPressed:=1;
	end;

Procedure TGraphButton.Release;


	begin
		if Owner=Nil then begin
			xs:=Bounds.a.x;
			xe:=Bounds.b.x;
			ys:=Bounds.a.y;
			ye:=Bounds.b.y;
		 end
		else begin
			xs:=Bounds.a.x+Owner^.Bounds.a.x;
			xe:=Bounds.b.x+Owner^.Bounds.a.x;
			ys:=Bounds.a.y+Owner^.Bounds.a.y;
			ye:=Bounds.b.y+Owner^.Bounds.a.y;
		end;
		XOfs:=((Xe - Xs) - TextWidth(TitleStr)) div 2;
		YOfs:=((Ye - Ys) - TextHeight(TitleStr)) div 2;
		Setcolor(wcLtGrey);
		line(xs,ys,xe,ys);
		line(xs+1,ys+1,xe-1,ys+1);
		line(xs,ys,xs,ye);
		line(xs+1,ys+1,xs+1,ye-1);
		Setcolor(wcDkGrey);
		line(xs,ye,xe,ye);
		line(xs+1,ye-1,xe-1,ye-1);
		line(xe,ye,xe,ys);
		line(xe-1,ye-1,xe-1,ys+1);
		SetFillStyle(SolidFill,wcGrey);
		bar(xs+2,ys+2,xe-2,ye-2);
		SetTextStyle(0,0,1);
		SetColor(TitleColor);
		OutTextXY(xs+XOfs,ys+YOfs,TitleStr);
		IsPressed:=0;
	end;

Procedure TGraphButton.Toggle;

	begin
		IsPressed:=IsPressed xor 1;
		Draw;
	end;

Procedure TGraphButton.Draw;

	begin
		if IsPressed=1 then
			Press
		else
			Release;
	end;

Constructor TGraphText.Init(R:TGraphRect;TextStr:string);

	begin
		Bounds:=r;
		DataStr:=TextStr;
		Owner:=Nil;
		Next:=Nil;
	end;

Procedure TGraphText.Draw;

	begin
		SetColor(wcBlack);
		if Owner<>Nil then
			OutTextXY(Owner^.Bounds.a.x+Bounds.a.x,Owner^.Bounds.a.y+Bounds.a.y,DataStr)
		else
			OutTextXY(Bounds.a.x,Bounds.a.y,DataStr);
	end;

end.
