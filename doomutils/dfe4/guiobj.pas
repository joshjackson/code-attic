unit GUIObj;

interface

const evMouseDown = $0001;
		evMouseUp   = $0002;
		evMouseMove = $0004;
		evMouseAuto = $0008;
		evKeyDown   = $0010;
		evCommand   = $0100;
		evBroadcast = $0200;
		evNothing  	= $0000;
		evMouse    	= $000F;
		evKeyboard 	= $0010;
		evMessage  	= $FF00;


type  PGraphPoint=^TGraphPoint;
		TGraphPoint=record
			X	:integer;
			Y	:integer;
		end;
		TGraphRect=object
			A	:TGraphPoint;
			B	:TGraphPoint;
			Procedure Assign(xa,ya,xb,yb:integer);
			Procedure Move(adx,ady:integer);
			Procedure Grow(adx,ady:integer);
		end;
		PGraphEvent=^TGraphEvent;
		TGraphEvent = record
			What: Word;
			case Word of
				evNothing: ();
				evMouse: (
					Buttons: Byte;
					Double: Boolean;
					Where: TGraphPoint);
				evKeyDown: (
					case Integer of
					0: (KeyCode: Word);
					1: (CharCode: Char;
						 ScanCode: Byte));
				evMessage: (
					Command: Word;
					case Word of
						0: (InfoPtr: Pointer);
						1: (InfoLong: Longint);
						2: (InfoWord: Word);
						3: (InfoInt: Integer);
						4: (InfoByte: Byte);
						5: (InfoChar: Char));
		end;

implementation

Procedure TGraphRect.Assign(xa,ya,xb,yb:integer);

	begin
		a.x:=xa;
		a.y:=ya;
		b.x:=xb;
		b.y:=yb;
	end;

Procedure TGraphRect.Move(adx,ady:integer);

	var	Width,Height:word;

	begin
		Width:=b.x - a.x;
		Height:=b.y - a.y;
		a.x:=adx;
		a.y:=ady;
		b.x:=adx + Width;
		b.y:=ady + Height;
	end;

Procedure TGraphRect.Grow(adx,ady:integer);

	begin
		dec(a.x, adx);
		dec(a.y, ady);
		inc(b.x, adx);
		inc(b.y, ady);
	end;


end.