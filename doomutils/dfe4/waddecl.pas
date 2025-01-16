{****************************************************************************
*                      The DOOM Hacker's Tool Kit                           *
*****************************************************************************
* Unit:    WADDECL                                                          *
* Purpose: WAD File type declarations                                       *
* Date:    4/28/94                                                          *
* Author:  Joshua Jackson        Internet: jsoftware@delphi.com             *
****************************************************************************}

{$O+,F+}
unit WadDecl;

interface

uses	Objects;

const MaxEntries=4095;                       {64k worth}

type  BA=array[0..65528] of byte;
		BAP=^BA;
		PCoOrds=^TCoOrds;
		PWADDirEntry=^TWADDirEntry;
		PWADDirList=^TWADDirList;
		PPictureBuff=^TPictureBuff;
		PSoundBuff=^TSoundBuff;
		ObjNameStr=array[1..8] of char;
		PLevelEntries=^TLevelEntries;
		PThing=^TThing;
		PLineDef=^TLineDef;
		PVertext=^TVertex;
		PSector=^Tsector;
		PSideDef=^TSideDef;
		PThingList=^TThingList;
		PVertexList=^TVertexList;
		PLineDefList=^TLineDefList;
		PSectorList=^TSectorList;
		PSideDefList=^TSideDefList;
		PFloorBuff=^TFloorBuff;
		TCoOrds=record
			x  :integer;
			y  :integer;
			z  :integer;
		end;
		TWADDirEntry=record
			ObjStart :longint;
			ObjLength:longint;
			ObjName  :ObjNameStr;
		end;
		TWADDirList=array[1..MaxEntries] of TWADDirEntry;
		TPictureBuff=record
			x     :word;
			y     :word;
			xofs  :integer;
			yofs  :integer;
			Name  :array[1..8] of char;
			Image :^BA;
		end;
		TSoundBuff=record
			Junk1       :integer;
			SampleRate  :integer;
			Samples     :word;
			Junk2       :integer;
			Sound       :BAP;
		end;
		TLevelEntries=record
			MapID       :TWadDirEntry;
			Things      :TWadDirEntry;
			LineDefs    :TWadDirEntry;
			SideDefs    :TWadDirEntry;
			Vertexes    :TWadDirEntry;
			Segs        :TWadDirEntry;
			SSectors    :TWadDirEntry;
			Nodes       :TWadDirEntry;
			Sectors     :TWadDirEntry;
			Reject      :TWadDirEntry;
			Blockmap    :TWadDirEntry;
		end;
		TThing=record
			x           :integer;
			y           :integer;
			Angle       :integer;
			ThingType   :word;
			Attributes  :word;
		end;
		TLineDef=record
			StartVertex :integer;
			EndVertex   :integer;
			Attributes  :word;
			LineDefType :word;
			Tag         :integer;
			RightSideDef:integer;
			LeftSideDef :integer;
		end;
		TVertex=record
			x           :integer;
			y           :integer;
		end;
		TSector=record
			FloorHeight    :integer;
			CeilingHeight  :integer;
			FloorTexture   :array[1..8] of char;
			CeilingTexture :array[1..8] of char;
			LightLevel     :integer;
			SectorCode     :integer;
			Tag            :word;
		end;
		TSideDef=record
			XOffset     :integer;
			YOffset     :integer;
			UpTexture   :array[1..8] of char;
			LoTexture   :array[1..8] of char;
			NormTexture :array[1..8] of char;
			Sector      :word;
		end;
		TThingList=Array[0..6551] of TThing;
		TVertexList=Array[0..16381] of TVertex;
		TLineDefList=Array[0..4679] of TLineDef;
		TSectorList=Array[0..2519] of TSector;
		TSideDefList=Array[0..5000] of PSideDef;  {Note: Array of pointers!}
		TFloorBuff=record
			Name        :array[1..8] of char;
			Image       :^BA;
		end;

Function Hex_String(Number: Longint): String;

implementation

Function Hex_String(Number: Longint): String;

	Function Hex_Char(Number: Word): Char;
		Begin
			If Number<10 then
				Hex_Char:=Char(Number+48)
			else
				Hex_Char:=Char(Number+55);
		end; { Function Hex_Char }

	Var
		S: String;
	Begin
		S:='';
		S:=Hex_Char((Number and $F0000000) shr 28);
		S:=S+Hex_Char((Number and $0F000000) shr 24);
		S:=S+Hex_Char((Number and $00F00000) shr 20);
		S:=S+Hex_Char((Number and $000F0000) shr 16);
		S:=S+Hex_Char((Number and $0000F000) shr 12);
		S:=S+Hex_Char((Number and $00000F00) shr 8);
		S:=S+Hex_Char((Number and $000000F0) shr 4);
		S:=S+Hex_Char(Number and $0000000F);
		Hex_String:='0x'+S;
	end; { Function Hex_String }

end.
