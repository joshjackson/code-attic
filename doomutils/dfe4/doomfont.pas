unit DOOMFONT;

interface

uses DFEVIDEO,THINGS,WAD,WADDECL;

Procedure InitFonts;
Procedure CenterFont(Y,Scale:longint;S:String);
Procedure DrawFont(x,y,scale:word;s:string);
Procedure DoneFonts;

implementation

var 	FontArray:array[1..63] of PWadThing;
		Initialized:boolean;

Procedure InitFonts;

	var	t:integer;
			WDir:PWadDirectory;
			TempStr:string[8];
			TempName:ObjNameStr;

	begin
		WDir:=New(PWadDirectory, Init('D:\DOOM\DOOM.WAD'));
		for t:=33 to 95 do begin
			Str(t, TempStr);
			TempStr:='STCFN0'+TempStr;
			Move(TempStr[1], TempName, 8);
			FontArray[t-32]:=New(PWadThing, Init(WDir, TempName));
		end;
		Initialized:=True;
		Dispose(WDir, Done);
	end;

Procedure DrawFont(x,y,scale:word;s:string);

	var 	t,n:integer;
			c:word;

	begin
		if Scale=0 then Scale:=1;
		for t:=1 to Length(s) do begin
			s[t]:=UpCase(s[t]);
			if (s[t] < #33) or (s[t] > #95) then
				s[t]:=' ';
		end;
		c:=x;
		for t:=1 to Length(s) do begin
			if s[t]=' ' then begin
				Inc(C, (8 * Scale));
				Continue;
			end;
			n:=Ord(s[t])-32;
			FontArray[n]^.Draw(Scale * 100,c,y+((8 * Scale)-(FontArray[n]^.Height * Scale)));
			Inc(C, FontArray[n]^.Width * Scale);
		end;
	end;

Procedure CenterFont(Y,Scale:longint;S:String);

	var	x:longint;
			l,n:Longint;

	begin
		l:=0;
		for x:=1 to Length(s) do begin
			if s[x]=' ' then begin
				Inc(l, 8 * Scale);
				Continue;
			end;
			n:=Ord(s[x])-32;
			Inc(l, FontArray[n]^.Width * Scale);
		end;
		x:=320 - ((l div 2));
		DrawFont(x,y,Scale,s);
	end;

Procedure DoneFonts;

	var t:integer;

	begin
		For t:=1 to 26 do
			Dispose(FontArray[t],Done);
	end;

begin
	Initialized:=False;
end.