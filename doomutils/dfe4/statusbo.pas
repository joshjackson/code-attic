unit StatusBox;

interface

uses	Objects,Dialogs,Gauges,Views;

Type	PStatusBox=^TStatusBox;
		TStatusBox=Object(TDialog)
			StatBar:PBarGauge;
			Constructor Init(Loc:TPoint;MaxValue:longint;MsgStr:string;ATitle:TTitleStr);
		end;

implementation

Constructor TStatusBox.Init(Loc:TPoint;MaxValue:longint;MsgStr:string;ATitle:TTitleStr);

	var	R:TRect;

	begin
		R.A:=Loc;
		R.B.X:=Loc.X + 32;
		R.B.Y:=Loc.Y + 8;
		TDialog.Init(R,ATitle);
		R.Assign(3,2,29,4);
		Insert(New(PStaticText, Init(R, MsgStr)));
		R.Assign(2,5,4,6);
		Insert(New(PStaticText, Init(R, '0%')));
		R.Assign(26,5,30,6);
		Insert(New(PStaticText, Init(R, '100%')));
		R.Assign(5,5,25,6);
		StatBar:=New(PBarGauge, Init(R, MaxValue));
		Insert(StatBar);
	end;


end.
