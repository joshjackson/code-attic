unit Window;

Interface

uses Crt,SuperIO;

type MenuArray=array[1..22] of ^string;

procedure Jtitle;
procedure AddMenuItem(Item:integer;MenuItem:string;var Choices:MenuArray);
procedure MenuDone(Items:integer;var Choices:MenuArray);
function MakeMenu(y,x,Items,Fore,Back:integer;var Choices:MenuArray):integer;
procedure MakeWind(x1,y1,x2,y2:integer;Fore,Back:byte;border,shadow:integer);
Function Hex(l:longint;SigDig:byte):string;
procedure PrintC(x,y:integer;s:string;c:integer);
Procedure SaveScrn;
Procedure RestScrn;
Procedure SaveCsr;
Procedure RestCsr;
Procedure HideCsr;
Procedure ShowCsr;

var 	VioSeg:word;
      CsrSize:word;

implementation

type MenuItemsType=record
		  ItemNum:byte;
		  Items:array[1..15] of string[65];
	  end;

var x,y,xl,yl:integer;
	 c:byte;
	 ScrnBuff:array[1..4000] of byte;
	 cx,cy:word;

procedure Jtitle;

	Type sp=array[0..3999] of byte;

	Var Scrn:string[80];
		 Scrnp:^sp;
		 t:integer;

	begin
		  Scrn:='';
		  Scrnp:=ptr(VioSeg,0000);
		  for t:=0 to 1999 do begin
				Scrnp^[t*2]:=219;
				Scrnp^[(t*2)+1]:=24;
		  end;
		  TextAttr:=16 + 8;
		  for t:=1 to 80 do
				Scrn:=Scrn+' ';
		  GotoXY(1,1);
		  write(Scrn);
		  FillChar(Scrn[1],80,chr(220));
		  GotoXY(1,2);
		  write(Scrn);
		  TextAttr:=15;
		  gotoXY(30,2);
		  write(' Jackson Software ');
	end;

procedure MakeWind(x1,y1,x2,y2:integer;Fore,Back:byte;border,shadow:integer);

	type AttrType=array[1..4] of byte;

	var t1:integer;
		 ShadowTemp,ColorTemp:byte;
		 ScrnTemp:string;
		 Box:array[1..6] of char;
		 Attr:^AttrType;
		 ScrnPos:word;

	begin
		  ColorTemp:=TextAttr;
		  TextBackground(Back);
		  TextColor(Fore);
		  ScrnTemp:='';
		  for t1:=1 to (x2-x1+1) do
				ScrnTemp:=ScrnTemp+' ';
		  for t1:=y1 to y2 do begin
				gotoXY(x1,t1);
				write(ScrnTemp);
		  end;
		  case border of
				 2:begin
						  Box[1]:='É';
						  Box[2]:='»';
						  Box[3]:='È';
						  Box[4]:='¼';
						  Box[5]:='Í';
						  Box[6]:='º';
					end;
				 1:begin
						  Box[1]:='Ú';
						  Box[2]:='¿';
						  Box[3]:='À';
						  Box[4]:='Ù';
						  Box[5]:='Ä';
						  Box[6]:='³';
					end;
				 3:begin
						  Box[1]:=' ';
						  Box[2]:=' ';
						  Box[3]:=' ';
						  Box[4]:=' ';
						  Box[5]:=' ';
						  Box[6]:=' ';
					end;
					4:begin
						  Box[1]:=' ';
						  Box[2]:=' ';
						  Box[3]:=' ';
						  Box[4]:=' ';
						  Box[5]:=' ';
						  Box[6]:=' ';
					end
		  end;
		  Attr:=ptr(VioSeg,$0000);
		  gotoXY(x1-1,y1-1);
		  write(Box[1]);
		  for t1:=x1 to x2 do
				write(Box[5]);
		  write(Box[2]);
		  for t1:=y1 to y2 do begin
				gotoXY(x1-1,t1);
				write(Box[6]);
				gotoXY(x2+1,t1);
				write(Box[6]);
		  end;
		  gotoXY(x1-1,y2+1);
		  write(Box[3]);
		  for t1:=x1 to x2 do
				write(Box[5]);
		  Attr^[(y2 * 160) + (t1 * 2) + 1]:=Ord(Box[4]);
		  Attr^[(y2 * 160) + (t1 * 2) + 2]:=TextAttr;
		  TextAttr:=ColorTemp;
		  if shadow > 0 then begin
			  case shadow of
					 1:ShadowTemp:=8;
					 2:ShadowTemp:=0;
					 else ShadowTemp:=0;
			  end;
			  for t1:=(y1-1) to (y2+1) do begin
					ScrnPos:=(t1*160)+(x2*2)+4;
					Attr^[ScrnPos]:=ShadowTemp;
					Attr^[ScrnPos+2]:=ShadowTemp;
			  end;
			  for t1:=(x1+1) to (x2+1) do begin
					ScrnPos:=((y2+1)*160)+(t1*2);
					Attr^[ScrnPos]:=ShadowTemp;
			  end;
		  end;
	end;

procedure AddMenuItem(Item:integer;MenuItem:string;var Choices:MenuArray);

	var t:integer;

   begin
        new(Choices[Item]);
        Choices[Item]^:=MenuItem;
   end;

procedure MenuDone(Items:integer;var Choices:MenuArray);

	var t:integer;

   begin
        for t:=1 to Items do
            Dispose(Choices[t]);
   end;

Function MakeMenu(y,x,Items,Fore,Back:integer;var Choices:MenuArray):integer;

	var KeyNum,mp,MaxLen,t:integer;
       Quit:boolean;

   begin
        TextAttr:=((Back and 7) * 16) + Fore;
        MaxLen:=30;
        for t:=1 to Items do
            if Length(Choices[t]^)>MaxLen then MaxLen:=Length(Choices[t]^);
		  for t:=1 to Items do begin
				Choices[t]^:=Space((MaxLen-Length(Choices[t]^)) div 2)+Choices[t]^;
				Choices[t]^:=Choices[t]^+Space(MaxLen - Length(Choices[t]^));
        end;
        MakeWind(y,x,y+Items-1,x+MaxLen+1,15,1,1,2);
        for t:=0 to Items-1 do begin
            gotoXY(x+1,y+t);
            write(Choices[t+1]^);
        end;
        mp:=0;
		  GotoXY(x+1,y+mp);
		  TextAttr:=((Fore and 7) * 16) + Fore;
        write(Choices[mp+1]^);
        Quit:=False;
        repeat
              KeyNum:=KeyCode;
              Case KeyNum of
                   18432:begin
                         GotoXY(x+1,y+mp);
								 TextAttr:=((Back and 7) * 16) + Fore;
								 write(Choices[mp+1]^);
								 dec(mp);
                         if mp=-1 then mp:=Items-1;
                         GotoXY(x+1,y+mp);
                         TextAttr:=((Fore and 7) * 16) + Fore;
                         write(Choices[mp+1]^);
                         end;
                   20480:begin
                         GotoXY(x+1,y+mp);
								 TextAttr:=((Back and 7) * 16) + Fore;
								 write(Choices[mp+1]^);
                         inc(mp);
                         if mp=Items then mp:=0;
                         GotoXY(x+1,y+mp);
                         TextAttr:=((Fore and 7) * 16) + Fore;
                         write(Choices[mp+1]^);
                         end;
                   27:begin
							 Quit:=True;
							 MakeMenu:=0;
							 end;
                   13:begin
                      Quit:=True;
                      MakeMenu:=mp+1;
                      end;
              end;
        until Quit=True;
   end;

Function Hex(l:longint;SigDig:byte):string;

	const HexDig:array[0..15] of char = '0123456789ABCDEF';

   var	t:integer;
   		v:longint;
   		tmpstr:string[8];

	begin
   	tmpstr:='';
      if (SigDig > 15) or (SigDig < 1) then
			SigDig:=15;
      for t:=0 to (SigDig - 1) do begin
	      v:=$f shl (4 * t);
         tmpstr:=HexDig[(l and v) shr (4 * t)] + tmpstr;
      end;
   	Hex:=tmpstr;
   end;

procedure PrintC(x,y:integer;s:string;c:integer);

	var NewX,NewY:integer;

	begin
      if x < 0 then
      	NewX:=WhereX
      else
      	NewX:=x;
      if y < 0 then
      	NewY:=WhereY
      else
      	NewY:=y;

   	GotoXY(Newx,Newy);

      TextAttr:=c;
      write(s);
   end;

Procedure SaveScrn;

	var t:word;

	begin
		for t:=0 to 3999 do
			ScrnBuff[t]:=Mem[VioSeg:t];
	end;

Procedure RestScrn;

	var t:word;

	begin
		for t:=0 to 3999 do
			Mem[VioSeg:t]:=ScrnBuff[t];
	end;

Procedure SaveCsr;

	begin
		cx:=WhereX;
		cy:=WhereY;
	end;

Procedure RestCsr;

	begin
		Gotoxy(cx,cy);
	end;

Procedure HideCsr; assembler;

	asm
   	mov ah, $01
      mov cx, $2020
      int $10
   end;

Procedure ShowCsr; assembler;

	asm
   	mov ah, $01
      mov cx, CsrSize
      int $10
   end;

begin
	if LastMode = Mono then
   	VioSeg:=SegB000
   else
   	VioSeg:=SegB800;
	asm
   	mov ah,3
      mov bh,0
      int $10
      mov CsrSize, CX
   end;
end.



