unit Mouse;

interface

type  CursorArray=array[1..256] of byte;

const	UseMouse:Boolean=false;
		MouseIsVisible:boolean=false;
		FakeCursor:boolean=false;
		StdCursor:cursorarray          = (0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
													 0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
													 0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,
													 0,0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,
													 0,0,0,0,0,1,1,1,1,1,1,1,1,1,1,1,
													 0,0,0,0,0,0,1,1,1,1,1,1,1,1,1,1,
													 0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,1,
													 0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,
													 0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,
													 0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,
													 0,0,1,0,0,0,1,1,1,1,1,1,1,1,1,1,
													 0,1,1,0,0,0,1,1,1,1,1,1,1,1,1,1,
													 1,1,1,1,0,0,0,1,1,1,1,1,1,1,1,1,
													 1,1,1,1,0,0,0,1,1,1,1,1,1,1,1,1,
													 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
													 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1);

		WaitCursor:cursorarray          = (1,1,0,0,0,0,0,0,0,0,0,0,0,1,1,1,
													  1,1,1,0,0,0,0,0,0,0,0,0,1,1,1,1,
													  1,1,1,0,0,0,0,0,0,0,0,0,1,1,1,1,
													  1,1,1,0,0,0,0,0,0,0,0,0,1,1,1,1,
													  1,1,1,0,0,1,1,1,1,1,0,0,1,1,1,1,
													  1,1,1,1,0,0,1,1,1,0,0,1,1,1,1,1,
													  1,1,1,1,1,0,0,1,0,0,1,1,1,1,1,1,
													  1,1,1,1,1,1,0,1,0,1,1,1,1,1,1,1,
													  1,1,1,1,1,1,0,0,0,1,1,1,1,1,1,1,
													  1,1,1,1,1,0,0,1,0,0,1,1,1,1,1,1,
													  1,1,1,1,0,0,0,0,0,0,0,1,1,1,1,1,
													  1,1,1,0,0,0,0,0,0,0,0,0,1,1,1,1,
													  1,1,1,0,0,0,0,1,0,0,0,0,1,1,1,1,
													  1,1,1,0,0,0,1,1,1,0,0,0,1,1,1,1,
													  1,1,1,0,0,1,1,1,1,1,0,0,1,1,1,1,
													  1,1,0,0,0,0,0,0,0,0,0,0,0,1,1,1);

Type	PMouseCursorDef=^TMouseCursorDef;
		TMouseCursorDef=record
			XSize		:word;
			YSize		:word;
			Reserved	:word;
			ImageBuff:array[1..256] of byte;
		end;

Procedure InitMouse;
Procedure DrawFakeCursor(x,y:word);
Procedure UpdateFakeCursor;
Procedure ShowMousePointer;
procedure HideMousePointer;
procedure SetPointerType(NewPointer:byte);
Procedure GetMouseCoords(var x,y,buttons:integer);
procedure SetMouseCoords(x,y:integer);
procedure SetMouseLimits(x0,y0,x1,y1:integer);
procedure ResetMouseLimits;
Procedure DoneMouse;

implementation

uses Dos,Graph,crt;

const MouseInt=$33;

type 	Ba=Array[1..1024] of byte;

var	Regs:Registers;
		OldX,OldY:word;
		MouseBuff:pointer;
		FakeCursorDef:TMouseCursorDef;
      OldXSpeed,OldYSpeed,OldWarp:integer;

{initialize the mouse driver}

Procedure InitMouse;

	var t:integer;

	begin
   	Regs.ax:=$1b;
      Intr($33,Regs);
      OldXSpeed:=Regs.bx;
      OldYSpeed:=Regs.cx;
		OldWarp:=Regs.dx;
		regs.ax:=$0000;
		intr(MouseInt,regs);
		if regs.ax=$FFFF then
			UseMouse:=TRUE
		else
			UseMouse:=FALSE;
		if FakeCursor then begin
			GetMem(MouseBuff,imagesize(1,1,17,17));
			regs.ax:=$1A;
			regs.bx:=500;
			regs.cx:=500;
			regs.dx:=50;
			intr($33,regs);
			FakeCursorDef.XSize:=15;
			FakeCursorDef.YSize:=15;
			SetMouseLimits(0,0,6264,4792);
			for t:=1 to 256 do
				if StdCursor[t] = 0 then
					FakeCursorDef.ImageBuff[t]:=15
				else
					FakeCursorDef.ImageBuff[t]:=0;
		end;
	end;

Procedure DrawFakeCursor(x,y:word);


	begin
		if not UseMouse then
			exit;
		if MouseIsVisible  and ((x <> OldX) or (y <> OldY)) then begin
			if OldX > 783 then
				OldX:=783;
			PutImage(OldX,OldY,MouseBuff^,NormalPut);
			GetImage(x,y,x+16,y+16,MouseBuff^);
			{SetColor(15);}
			PutImage(x,y,FakeCursorDef,xorPut);
			OldX:=x;
			OldY:=y;
		end;
	end;

Procedure UpdateFakeCursor;

	var	x,y,b:integer;

	begin
		GetMouseCoOrds(x,y,b);
      y:=y+8;
		DrawFakeCursor(x,y);
	end;

{show the pointer}

Procedure ShowMousePointer;

	var x,y,b:integer;

	begin
		if not UseMouse then
			exit;
		if not FakeCursor then begin
			regs.ax:=$0001;
			intr(MouseInt,regs);
		 end
		else begin
			GetMouseCoOrds(x,y,b);
			x:=x div 8;
			y:=y div 8;
			GetImage(x,y,x+16,y+16,MouseBuff^);
			Oldx:=x;
			Oldy:=y;
			DrawFakeCursor(x,y);
		end;
      if FakeCursor then
      	UpdateFakeCursor;
		MouseIsVisible:=True;
	end;

{hide the pointer}

procedure HideMousePointer;

	begin
		if not UseMouse then
			exit;
		if not FakeCursor then begin
			regs.ax:=$0002;
			intr(MouseInt,regs);
		 end
		else
			PutImage(OldX,OldY,MouseBuff^,NormalPut);
		MouseIsVisible:=False;
	end;

Procedure SetPointerType(NewPointer:byte);

	var	TempArry:cursorarray;
			t:integer;

	begin
		if FakeCursor then begin
			case NewPointer of
				1:TempArry:=StdCursor;
				2:TempArry:=WaitCursor;
			 else
				TempArry:=StdCursor;
			end;
			for t:=1 to 256 do
				if TempArry[t] = 0 then
					FakeCursorDef.ImageBuff[t]:=15
				else
					FakeCursorDef.ImageBuff[t]:=0;
		end;
	end;

{read pointer coordinates}

Procedure GetMouseCoords(var x,y,buttons:integer);

	begin
		if not UseMouse then
			exit;
		regs.ax:=$0003;
		intr(MouseInt,regs);
		x:=regs.cx;
		y:=regs.dx;
		buttons:=regs.bx;
		if FakeCursor then begin
			x:=x div 8;
			y:=y div 8;
		end;
	end;

{change pointer coordinates}

procedure SetMouseCoords(x,y:integer);

	begin
		if not UseMouse then
			exit;
		regs.ax:=$0004;
		regs.cx:=x;
		regs.dx:=y;
		intr(MouseInt,regs);
	end;

{set horizontal and vertical limits (constrain pointer in a box)}

procedure SetMouseLimits(x0,y0,x1,y1:integer);

	begin
		if not UseMouse then
			exit;
		regs.ax:=$0007;
		regs.cx:=x0;
		regs.dx:=x1;
		intr(MouseInt,regs);
		regs.ax:=$0008;
		regs.cx:=y0;
		regs.dx:=y1;
		intr(MouseInt,regs);
	end;


{reset horizontal and vertical limits}

procedure ResetMouseLimits;

	begin
		if not UseMouse then
			exit;
		regs.ax:=$0007;
		regs.cx:=0;
		regs.dx:=640;
		intr(MouseInt,regs);
		regs.ax:=$0008;
		regs.cx:=0;
		regs.dx:=480;
		intr(MouseInt,regs);
	end;

Procedure DoneMouse;

	begin
		if not UseMouse then
			exit;
		if FakeCursor then begin
			ResetMouseLimits;
			regs.ax:=$1A;
			regs.bx:=OldXSpeed;
			regs.cx:=OldYSpeed;
			regs.dx:=OldWarp;
			intr($33,regs);
			if MouseIsVisible then
				HideMousePointer;
			FreeMem(MouseBuff,imagesize(1,1,17,17));
		end;
	end;

end.