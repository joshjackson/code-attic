{$F+,O+}
unit SuperIO;

Interface

	var PassHideChar:char;

Function Space(s:integer):string;
Function BuffInput(var RetStr:string):integer;
Function PasswordInput(length:integer):String;
Function KeyCode:integer;
Procedure PrepCompStr(var s:string);
Procedure MidPrint(m:string;y:integer);
Procedure Print(y,x:integer;m:string);
Function Left(s:string;cnt:integer):string;
Function Right(s:string;cnt:integer):string;
Function Mid(s:string;index,cnt:integer):string;
Procedure EditLine(var a:string;var e:integer);
Function RTrim(s:string):string;
Function LTrim(s:string):string;

Implementation

uses crt;

   var TempStr:string[2];
		 Quit:Boolean;
       MaxLen:integer;
       GetPassword:boolean;
       PasswordTemp:String;

Procedure Beep;

   begin
        Sound(999);
        delay(250);
        NoSound;
   end;

Function Space(s:integer):string;

   var t:integer;
       TempStr:string;

   begin
		  TempStr:='';
        for t:=1 to s do
            TempStr:=TempStr + ' ';
        Space:=TempStr;
   end;

Function Left(s:string;cnt:integer):string;

   var TempStr:string;
       l:integer;

   begin
		  TempStr:=s;
		  l:=Length(TempStr);
        delete(TempStr,cnt+1,l-cnt);
        Left:=TempStr;
   end;

Function Right(s:string;cnt:integer):string;

   var TempStr:string;
       l:integer;

   begin
        TempStr:=s;
        l:=Length(TempStr);
        delete(TempStr,1,l-cnt);
        Right:=TempStr;
   end;

Function Mid(s:string;index,cnt:integer):string;

	var l:integer;

   begin
        if cnt=-1 then begin
           l:=Length(s);
           Mid:=copy(s,index,l-index+1);
			  end
        else
            Mid:=copy(s,index,cnt);
   end;

Function Str2Word(Str:string):word;

var WordTemp:word;

   begin
        Str:=Str+Chr(0)+Chr(0);
        Move(Str[1],WordTemp,2);
		  Str2Word:=WordTemp;
	end;

Function GetKeys:string;

var TempKey:string;

	begin
        TempKey:='';
        TempKey:=ReadKey;
        if TempKey=chr(0) then begin
           TempKey:=ReadKey;
           TempKey:='';
        end;
        GetKeys:=TempKey;
   end;

Function Buffinput(var RetStr:string):integer;

	Begin
		  Quit:=False;
        MaxLen:=Length(RetStr);
        RetStr:='';
        While not Quit do begin
              TempStr:='';
              While TempStr='' do
						  TempStr:=GetKeys;
              case Str2Word(TempStr) of
                   27:Quit:=True;
                   8:begin
                          if Length(RetStr)>0 then begin
                             Delete(RetStr,Length(RetStr),1);
                             GotoXY(WhereX-1,WhereY);
                             write(' ');
                             GotoXY(WhereX-1,WhereY);
                             end
                          else begin
                              Sound(1000);
										delay(200);
										NoSound;
                          end
                     end;
                   13:Quit:=True;
              else
                  if Length(RetStr)<MaxLen then
							if GetPassword then begin
                        if PassHideChar<>Chr(0) then
                           Write(PassHideChar);
                        RetStr:=RetStr+TempStr;
                        end
                     else
                         begin
                              Write(TempStr);
                              RetStr:=RetStr+TempStr;
                         end {if}
                  else begin
                       Sound(1000);
							  delay(200);
							  NoSound;
                  end  {if}
              end {Case of}
        end; {While Do}
         BuffInput:=Str2Word(TempStr);
   end; {Buffinput}

Function PasswordInput(length:integer):String;

Var Ptemp:integer;

   begin
        GetPassword:=True;
        For Ptemp:=1 to Length do
            PasswordTemp:=PasswordTemp+' ';
        Ptemp:=BuffInput(PasswordTemp);
        PasswordInput:=PasswordTemp;
        GetPassword:=False;
	end;

Procedure PrepCompStr(var s:string);

   var TempStr1:string;
       P1,P2,t:byte;

	begin
        P1:=1;
        p2:=Length(s);
        for t:=1 to p2 do begin
            if s[t]=chr(0) then s[t]:=' ';
            s[t]:=UpCase(s[t]);
        end;
        for t:=1 to p2 do begin
            if (s[t]<> ' ') and (s[t]<> chr(0)) then begin
               P1:=t;
               t:=p2;
            end;
		  end;
		  for t:=p2 downto p1 do begin
            if (s[t]<> ' ') and (s[t]<> chr(0)) then begin
               p2:=t;
               t:=p1;
            end;
        end;
		  TempStr1:=copy(s,p1,p2);
        s:=TempStr1;
   end;

Procedure MidPrint(m:string;y:integer);

   var l:byte;

   begin
        l:=40-(length(m) div 2);
        gotoXY(l,y);
        write(m);
	end;

Procedure Print(y,x:integer;m:string);

   begin
        gotoXY(x,y);
        write(m);
	end;

Function KeyCode:integer;

   var s:string;
       i:integer;

   begin
        s:=ReadKey;
        if s=chr(0) then
           s:=s+ReadKey
        else
			  s:=s+chr(0);
		  move(s[1],i,2);
        KeyCode:=i;
   end;

Procedure EditLine(var a:string;var e:integer);

	var Row,Col,l,_insert:integer;
       KeyNum:integer;
       Quit:boolean;
       _Ptr:byte;
       Kee:Char;
       original:string;

   begin
        Row:=WhereY;
        Col:=WhereX;
        l:=Length(a);
        _ptr:=0;
		  _insert:=0;
		  Quit:=False;
        original:=a;

        repeat
              gotoXY(Col,Row);
              write(a);
				  gotoXY(Col+_ptr,Row);
              KeyNum:=KeyCode;
              case KeyNum of

                   20992: _insert:=_insert XOR 1;

                   8:begin
                     if _ptr > 0 then begin
                        a:=a+chr(0);
                        a:=Left(a,_ptr - 1)+Mid(a,_ptr+1,-1);
                        _ptr:=_ptr-1;
                        end;
							end;

						 21248:begin
								 a:=a+chr(0);
								 a:=Left(a,_ptr)+Mid(a,_ptr+2,-1);
								 end;

						 18432:begin
								 e:=-1;
								 Quit:=True;
								 end;

						 20480:begin
								 e:=1;
								 Quit:=True;
								 end;

						 19200:if (_ptr>0) then dec(_ptr);

						 19712:if _ptr < (l - 1) then inc(_ptr);

						 13:begin
							 e:=1;
							 Quit:=True;
							 end;

						 18176:_ptr:=0;

						 20224:_ptr:=l-1;

						 27:begin
							 e:=2;
							 Quit:=True;
							 end;

						 256..32767: Beep;

						 0..31: Beep;

						 else begin
								kee:=chr(KeyNum);
								if _Insert=1 then begin
									a:=Left(a,_ptr)+kee+Mid(a,_ptr+1,-1);
									a:=Left(a,l)
									end
								else if _ptr < l then
									  a[_ptr+1]:=kee;
								if _ptr<l then
									inc(_ptr)
								else
									 beep;
						 end;
				  end;
		  until Quit
	end;

Function RTrim(s:string):string;

	var	t:byte;
			SPos:byte;

	begin
		RTrim:='';
		if Length(s) = 0 then
			exit;
		SPos:=0;
		for t:=Length(s) downto 1 do
			if (s[t]<>' ') and (s[t]<>#0) then begin
				SPos:=t;
				Break;
			end;
		if SPos = 0 then
			exit;
		RTrim:=Left(s, SPos);
	end;

Function LTrim(s:string):string;

	var	t:byte;
			SPos:byte;

	begin
		LTrim:='';
		if Length(s) = 0 then
			exit;
		SPos:=0;
		for t:=1 to Length(s) do
			if (s[t]<>' ') and (s[t]<>#0) then begin
				SPos:=t;
				Break;
			end;
		if SPos = 0 then
			exit;
		LTrim:=Right(S, Length(s) - SPos+1);
	end;

begin
	  PassHideChar:=Chr(176);
	  TempStr:='';
	  PasswordTemp:='';
     GetPassword:=False;
end.
