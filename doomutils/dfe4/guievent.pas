unit GUIEvent;

interface

uses GuiObj;

const MaxEvents	= 50;

type  PEventQueue=^TEventQueue;
		TEventQueue=array[1..MaxEvents] of TGraphEvent;


implementation

uses crt;

var	EventQ:PEventQueue;
		AddPos,CurPos,NumInQ:word;

Procedure InitGraphEvents;

	begin
	end;

Procedure AddEvent(Event:TGraphEvent);

	begin
	end;

Procedure DelEvent(Event:TGraphEvent);

	begin
	end;

Procedure GetMouseEvent(var Event:TGraphEvent);

	begin
	end;

Procedure GetKeyEvent(var Event:TGraphEvent);

	begin
		if KeyPressed then begin
			Event.What := evKeyDown;
			Event.CharCode := ReadKey;
			Event.InfoPtr := nil;
		end;
	end;

Procedure DoneGraphEvents;

	begin
	end;

end.