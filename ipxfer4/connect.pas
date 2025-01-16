
Unit Connect;

Interface

Type 
	PConnectionEntry =   ^TConnectionEntry;
    TConnectionEntry =   Object
        NetManager:   TNetManager;
        NetAddress:   TNetAddress;
        UserName:   String[15];
        ComputerName:   String[25];


        Implementation

    End.
