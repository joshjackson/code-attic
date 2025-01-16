{****************************************************************************
*                      The DOOM Hacker's Tool Kit                           *
*****************************************************************************
* Unit:    AutoValidate                                                     *
* Purpose: PWad Auto-Validation Routines                                    *
* Date:    8/21/94                                                          *
* Author:  Joshua Jackson        Internet: jsoftware@delphi.com             *
****************************************************************************}

unit AutoValidate;

interface

uses Wad,WadDecl,Dos;

type	PPWadAutoValidator=^TPwadAutoValidator;
		TPWadAutoValidator=Object
			DeathMatch:Boolean;
			CoOperative:Boolean;
			HasSounds:Boolean;
			HasTextures:Boolean;
			HasSprites:Boolean;
			HasMusic:Boolean;
			HasDemos:Boolean;
			Constructor Init(WName:PathStr);
			Function Validate:integer;
			Function CheckDeathMatch:integer;
			Function CheckCoOperative:integer;
			Function CheckSounds:Boolean;
			Function CheckTextures:integer;
			Function CheckSprites:integer;
			Function CheckMusic:Boolean;
			Function CheckDemos:Boolean;
			Destructor Done;
		 private
			WDir:PWadDirectory;
			Status:integer;
		end;

implementation

uses Memory,MsgBox;

Constructor TPWadAutoValidator.Init(WName:PathStr);

	begin
		Status:=0;
		TerminateOnWadError:=False;
		WDir:=New(PWadDirectory, Init(WName));
		if WadResult <> 0 then Status:=WadResult;
	end;

Function TPWadAutoValidator.Validate:integer;

	var	t:integer;
			s:string;

	begin
		if Status <> 0 then begin
			s:='Auto-Validation Failure: '+WadResultMsg(Status);
			MessageBox(s,Nil,mfError + mfOkButton);
			Validate:=Status;
			Exit;
		end;
		case CheckDeathMatch of
			-1:Status:=-1;
			0:DeathMatch:=False;
			1:DeathMatch:=True;
		end;
		if Status < 0 then exit;
		case CheckCoOperative of
			-1:Status:=-1;
			0:DeathMatch:=False;
			1:DeathMatch:=True;
		end;
		if Status < 0 then exit;
		HasMusic:=CheckMusic;
		HasSounds:=CheckSounds;
		HasDemos:=CheckDemos;
	end;

Function TPWadAutoValidator.CheckDeathMatch:integer;

	var 	x,e,t,m,p:integer;
			s:string;
			TempName:ObjNameStr;
			TempBuff:^TThingList;

	begin
		for e:=1 to 3 do begin
			for m:=1 to 9 do begin
				TempName:='        ';
				TempName[1]:='E';
				TempName[3]:='M';
				Str(e, s);
				TempName[2]:=s[1];
				Str(m, s);
				TempName[4]:=s[1];
				p:=WDir^.FindObject(TempName);
				if p = 0 then Continue;
				Inc(p);
				if WDir^.DirEntry^[p].ObjName<>'THINGS  ' then
					Continue;
				TempBuff:=MemAllocSeg(WDir^.DirEntry^[p].ObjLength);
				if TempBuff = Nil then begin
					MessageBox('Insufficient Memory for Auto-Validation',Nil,
						mfError + mfOkButton);
					CheckDeathMatch:=-1;
					exit;
				end;
				Seek(WDir^.WadFile, WDir^.DirEntry^[p].ObjStart);
				BlockRead(WDir^.WadFile, TempBuff^, WDir^.DirEntry^[p].ObjLength);
				x:=0;
				for t:=1 to (WDir^.DirEntry^[p].ObjLength div SizeOf(TThing)) do begin
					if TempBuff^[t].ThingType=11 then Inc(x);
				end;
				if x < 4 then begin
					CheckDeathMatch:=0;
					Exit;
				end;
			end;
		end;
		CheckDeathMatch:=1;
	end;

Function TPWadAutoValidator.CheckCoOperative:integer;

	var 	x,e,t,m,p:integer;
			s:string;
			TempName:ObjNameStr;
			TempBuff:^TThingList;

	begin
		for e:=1 to 3 do begin
			for m:=1 to 9 do begin
				TempName:='        ';
				TempName[1]:='E';
				TempName[3]:='M';
				Str(e, s);
				TempName[2]:=s[1];
				Str(m, s);
				TempName[4]:=s[1];
				p:=WDir^.FindObject(TempName);
				if p = 0 then Continue;
				Inc(p);
				if WDir^.DirEntry^[p].ObjName<>'THINGS  ' then
					Continue;
				TempBuff:=MemAllocSeg(WDir^.DirEntry^[p].ObjLength);
				if TempBuff = Nil then begin
					MessageBox('Insufficient Memory for Auto-Validation',Nil,
						mfError + mfOkButton);
					CheckCoOperative:=-1;
					exit;
				end;
				Seek(WDir^.WadFile, WDir^.DirEntry^[p].ObjStart);
				BlockRead(WDir^.WadFile, TempBuff^, WDir^.DirEntry^[p].ObjLength);
				x:=0;
				for t:=1 to (WDir^.DirEntry^[p].ObjLength div SizeOf(TThing)) do begin
					if TempBuff^[t].ThingType=11 then Inc(x);
				end;
				if x < 4 then begin
					CheckCoOperative:=0;
					FreeMem(TempBuff, WDir^.DirEntry^[p].ObjLength);
					Exit;
				end;
				FreeMem(TempBuff, WDir^.DirEntry^[p].ObjLength);
			end;
		end;
		CheckCoOperative:=1;
	end;

Function TPWadAutoValidator.CheckSounds:Boolean;

	begin
		if WDir^.FindObject('DS_?????') > 0 then
			CheckSounds:=True;
	end;

Function TPWadAutoValidator.CheckTextures:integer;

	begin
	end;

Function TPWadAutoValidator.CheckSprites:integer;

	begin
	end;

Function TPWadAutoValidator.CheckMusic:Boolean;

	begin
		if WDir^.FindObject('D_??????') > 0 then
			CheckMusic:=True;
	end;

Function TPWadAutoValidator.CheckDemos:Boolean;

	begin
		if WDir^.FindObject('DEMO?   ') > 0 then
			CheckDemos:=True;
	end;

Destructor TPWadAutoValidator.Done;

	begin
		Dispose(WDir, Done);
	end;

end.