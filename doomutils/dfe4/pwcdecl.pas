unit PWCDECL;

interface

uses Wad,WadDecl,Objects;

type  PPWadEntry=^TPWadEntry;
		TPWadEntry=record
			NameStr:String[50];
			Dir:PWadDirectory;
		end;
		PPwadLevelEntry=^TPWadLevelEntry;
		TPWadLevelEntry=record
			Name:string[8];
			EntryNum:word;
		end;
		PLevelList=^TLevelList;
		TLevelList=Object(TCollection)
			Function At(Index:integer):PPWadLevelEntry;
			Procedure FreeItem(P:Pointer); virtual;
		end;
		PWadCollection=^TWadCollection;
		TWadCollection=Object(TCollection)
			Function At(Index:integer):PPWadEntry; virtual;
			Procedure FreeItem(P:Pointer); virtual;
		end;

implementation

Function TLevelList.At(Index:integer):PPWadLevelEntry;

	begin
		At:=TCollection.At(Index);
	end;

Procedure TLevelList.FreeItem(P:Pointer);

	begin
		Dispose(PPWadLevelEntry(P));
	end;

Function TWadCollection.At(Index:integer):PPWadEntry;

	begin
		At:=TCollection.At(Index);
	end;

Procedure TWadCollection.FreeItem(P:Pointer);

	begin
		Dispose(PPWadEntry(P));
	end;

end.

