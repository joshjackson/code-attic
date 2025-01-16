{****************************************************************************
*                      The DOOM Hacker's Tool Kit                           *
*****************************************************************************
* Unit: 	  THINGDEF                                                         *
* Purpose: Thing Definitions, Identification, and Cross Referencing         *
* Date:    5/06/94                                                          *
* Author:  Joshua Jackson        Internet: joshjackson@delphi.com           *
****************************************************************************}

{$O+,F+}												{Allow for overlaying}
unit ThingDef;

interface

uses WadDecl,Wad;

const	MaxThingDefs=829;							{64k worth}

type	PThingDef=^TThingDef;
		PThingDefArray=^TThingDefArray;
		TThingDef=record
			Num		:word;
			PictID   :array[1..4] of char;
			AnimSeq  :array[1..7] of char;
			DefType  :byte;
			Desc     :array[1..65] of char;
		end;
		TThingDefArray=array[1..MaxThingDefs] of TThingDef;

var	TotalThingDefs:word;							{DO NOT modify!}
		ThingDefs:PThingDefArray;

Procedure InitThingDefs;
Function GetThingDefFromID(ThingID:word):word;
Function CrossRefThingDef(ThingID:word;WDir:PWadDirectory):word;
Function GetThingNumViews(ThingID:word;WDir:PWadDirectory):word;
Function GetThingDefFromSpriteName(SpriteName:ObjNameStr):word;
Procedure DoneThingDefs;

implementation

var	IsInitialized:boolean;

Procedure InitThingDefs;

	var	f:file;

	begin
		if not IsInitialized then begin
			assign(f,'dfesys\thing.def');
			reset(f,1);
			TotalThingDefs:=FileSize(f) div SizeOf(TThingDef);
			if TotalThingDefs > MaxThingDefs then
				TotalThingDefs:=MaxThingDefs;
			GetMem(ThingDefs,TotalThingDefs * SizeOf(TThingDef));
			BlockRead(f,ThingDefs^[1],TotalThingDefs * SizeOf(TThingDef));
			close(f);
			IsInitialized:=True;
		end;
	end;

Function GetThingDefFromID(ThingID:word):word;

	var	t:word;

	begin
		for t:=1 to TotalThingDefs do begin
			if ThingID=ThingDefs^[t].Num then begin
				GetThingDefFromID:=t;
				exit;
			end;
		end;
		GetThingDefFromID:=0;
	end;

Function GetThingDefFromSpriteName(SpriteName:ObjNameStr):word;

	var	t:word;
			TempName:array[1..4] of char;

	begin
		for t:=1 to 4 do
			TempName[t]:=UpCase(SpriteName[t]);
		for t:=1 to TotalThingDefs do begin
			if SpriteName=ThingDefs^[t].PictID then begin
				GetThingDefFromSpriteName:=t;
				exit;
			end;
		end;
		GetThingDefFromSpriteName:=0;
	end;

Function CrossRefThingDef(ThingID:word;WDir:PWadDirectory):word;

	var 	ThingDefNum:word;
			SpriteStart:word;
			SpriteEnd:word;
			t:integer;
			SpriteName:array[1..4] of char;

	begin
		CrossRefThingDef:=0;
		ThingDefNum:=GetThingDefFromID(ThingID);
		if ThingDefNum=0 then
			exit;
		SpriteStart:=WDir^.FindObject('S_START ');
		if SpriteStart=0 then
			exit;
		SpriteEnd:=WDir^.FindObject('S_END   ');
		if SpriteEnd=0 then
			SpriteEnd:=WDir^.DirEntries;
		for t:=(SpriteStart + 1) to (SpriteEnd - 1) do begin
			Move(WDir^.DirEntry^[t].ObjName[1],SpriteName[1],4);
			if SpriteName=ThingDefs^[ThingDefNum].PictID then begin
				CrossRefThingDef:=t;
				exit
			end;
		end;
	end;

Function GetThingNumViews(ThingID:word;WDir:PWadDirectory):word;

	var   SpriteName:Array[1..4] of char;
			ThingDefNum:word;
			ThingViewStart:word;
			SpriteEnd:word;
			NumViews:word;
			t:word;

	begin
		NumViews:=0;
		GetThingNumViews:=0;
		ThingDefNum:=GetThingDefFromID(ThingID);
		if ThingDefNum=0 then
			exit;
		ThingViewStart:=CrossRefThingDef(ThingID,WDir);
		if ThingViewStart=0 then
			exit;
		SpriteEnd:=WDir^.FindObject('S_END   ');
		if SpriteEnd=0 then
			SpriteEnd:=WDir^.DirEntries;
		for t:=(ThingViewStart) to (SpriteEnd - 1) do begin
			Move(WDir^.DirEntry^[t].ObjName[1],SpriteName[1],4);
			if SpriteName=ThingDefs^[ThingDefNum].PictID then
				Inc(NumViews);
		end;
		GetThingNumViews:=NumViews;
	end;

Procedure DoneThingDefs;

	begin
		if IsInitialized then begin
			FreeMem(ThingDefs,TotalThingDefs * SizeOf(TThingDef));
			IsInitialized:=False;
		end;
	end;

begin
	IsInitialized:=False;
end.