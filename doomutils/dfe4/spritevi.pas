{$O+,F+}
unit SpriteView;

interface

uses Wad,Waddecl,Things,DOOMGUI,ThingDef,GuiObj,Graph;

Type 	PSpriteViewer=^TSpriteViewer;
		TSpriteViewer=object(TGraphGroup)
			ViewerFlags:byte;
			ViewWindow:PGraphWindow;
			TheSprite:PWadThing;
			WDir:PWadDirectory;
			constructor Init(ThingID:word;WadDir:PWadDirectory);
			procedure Draw; virtual;
			destructor Done; virtual;
		end;

implementation

var	In256ColorMode:boolean;

Constructor TSpriteViewer.Init(ThingID:word;WadDir:PWadDirectory);

	var 	ThingDefNum:word;
			R:TGraphRect;
			TempStr:string;
			SpritePictID:ObjNameStr;

	begin
		ViewerFlags:=0;
		WDir:=WadDir;
		R.Assign(320,240,640,480);
		Bounds:=R;
		ViewWindow:=New(PGraphWindow, Init(R));
		ThingDefNum:=GetThingDefFromID(ThingID);
		R.Assign(5,5,635,15);
		ViewWindow^.Insert(New(PGraphText, Init(R,'Description: '+ThingDefs^[ThingDefNum].Desc)));
		R.Assign(5,20,635,35);
		ViewWindow^.Insert(New(PGraphText, Init(R,'Sprite ID: '+ThingDefs^[ThingDefNum].PictID)));
		Str(ThingDefs^[ThingDefNum].Num,TempStr);
		R.Assign(5,35,635,50);
		ViewWindow^.Insert(New(PGraphText, Init(R,'Thing ID Number: '+TempStr)));
		ThingDefNum:=CrossRefThingDef(ThingID,WDir);
		Move(WDir^.DirEntry^[ThingDefNum].ObjName,SpritePictID,8);
		if ThingDefNum<>0 then
			TheSprite:=New(PWadThing, Init(WDir, SpritePictID))
		else
			TheSprite:=Nil;
	end;

Procedure TSpriteViewer.Draw;

	var 	ThingDefNum:word;
			R:TGraphRect;
			TempStr:string;
			SubView:PGraphView;

	begin
		if (ViewerFlags and 1) = 1 then
			exit;
		ViewWindow^.Draw;
		if TheSprite <> Nil then begin
			SetFillStyle(SolidFill,wcBlack);
			Bar(335,295,570,470);
			TheSprite^.Draw(100,340,300);
		 end
		else begin
			SetColor(0);
			OutTextXY(340,300,'No Sprite View Available');
		end;
	end;

Destructor TSpriteViewer.Done;

	begin
		ViewWindow^.Done;
		Dispose(ViewWindow);
		if TheSprite<>Nil then begin
			TheSprite^.Done;
			Dispose(TheSprite);
		end;
	end;

begin
{$IFDEF DFE}
	writeln('SysSpriteView_Init');
{$ENDIF}
end.