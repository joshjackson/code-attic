{$F+,O+}
unit LoadPWAD;

interface

uses Wad,WadDecl,App,Objects,Views,Drivers,Dos,Dialogs,MsgBox,StdDlg;

Type	LevelNameArray=array[1..27] of PathStr;
		TWadDesc=Record
			PWadName		:PathStr;
			Desc			:string[30];
			TimesLoaded	:word;
			Rating		:byte;
			WadType		:byte;
		end;

Function GetPwadName(var ExtFile:PathStr;MaxLevels:integer;var LevelNames: LevelNameArray;
				var SelLevel:PRadioButtons):word;

implementation

Procedure FindLevelNames(FileSpec:PathStr;MaxLevels:integer;var Levels:LevelNameArray;
				R:TRect;var SelLevel:PRadioButtons);

	var   PDir:PWadDirectory;
			t,i1,i2,CurLevel:integer;
			tmpstr:string;
			Code:integer;
			TmpArray:PSItem;
			CurItem,ItemList:PSitem;

	begin
		TmpStr:=FileSpec;
		PDir:=new(PWadDirectory, Init(FileSpec));
		if WadResult<>wrOk then begin
			MessageBox(WadResultMsg(WadResult),Nil,mfError+ mfOkButton);
			exit;
		end;
		CurLevel:=1;
		CurItem:=Nil;
		ItemList:=Nil;
		Levels[1]:='';
		for t:=1 to PDir^.DirEntries do begin
			if (PDir^.DirEntry^[t].ObjName[1]='E') and (PDir^.DirEntry^[t].ObjName[3]='M') then begin
				tmpstr:=PDir^.DirEntry^[t].ObjName[2];
				val(TmpStr,i1,Code);
				if Code<>0 then
					continue;
				tmpstr:=PDir^.DirEntry^[t].ObjName[4];
				val(TmpStr,i2,Code);
				if Code<>0 then
					continue;
				Levels[CurLevel]:=PDir^.DirEntry^[t].ObjName;
				Levels[CurLevel][0]:=#4;
				if ItemList=Nil then begin
					ItemList:=New(PSItem);
					ItemList^.Value:=NewStr(Levels[CurLevel]);
					ItemList^.Next:=Nil;
					CurItem:=ItemList;
				 end
				else begin
					CurItem^.Next:=New(PSItem);
					CurItem:=CurItem^.Next;
					CurItem^.Value:=NewStr(Levels[CurLevel]);
					CurItem^.Next:=Nil;
				end;
				inc(CurLevel);
				if CurLevel=MaxLevels + 1 then begin
					PDir^.Done;
					Dispose(PDir);
					SelLevel:=New(PRadioButtons, Init(R,ItemList));
					exit;
				end;
			end;
		end;
		PDir^.Done;
		Dispose(PDir);
		SelLevel:=New(PRadioButtons, Init(R,ItemList));
	end;

Function GetPwadName(var ExtFile:PathStr;MaxLevels:integer;var LevelNames: LevelNameArray;
				var SelLevel:PRadioButtons):word;

	var 	Control:word;
			FDialog:PFileDialog;
			R:TRect;
			ListSize:word;

	begin
		if MaxLevels > 27 then MaxLevels:=27;
		ExtFile := '*.WAD';
		FDialog:=New(PFileDialog, Init('*.WAD', 'Select Wad File','~N~ame',fdOkButton,100));
		FDialog^.SetData(ExtFile);
		Control:=Desktop^.ExecView(FDialog);
		if Control=cmFileOpen then
			Control:=cmOk;
		if Control=cmOK then begin
			ExtFile:=FDialog^.Directory^+(FDialog^.FileName^.Data^);
			ListSize:=MaxLevels Div 9;
				if (ListSize Mod 9) > 0 then Inc(ListSize);
			ListSize:=(ListSize * 8);
			R.Assign(2, 1, ListSize, 10);
			SelLevel:=Nil;
			FindLevelNames(ExtFile,MaxLevels,LevelNames,R,SelLevel);
			if WadResult<>wrOk then begin
				GetPWadName:=cmCancel;
				Dispose(FDialog,Done);
				if SelLevel<>Nil then
					Dispose(SelLevel, Done);
				exit;
			end;
			if LevelNames[1]='' then begin
				MessageBox('No valid level entries found.',Nil,mfError+mfOkButton);
				GetPWadName:=cmCancel;
				if SelLevel<>Nil then
					Dispose(SelLevel, Done);
				Dispose(FDialog, Done);
				exit;
			 end
		end;
		Dispose(FDialog,Done);
		GetPWadName:=Control;
	end;

Procedure RebuildPWadFile;

	var	f:File of TWadDesc;

	begin
	end;

end.