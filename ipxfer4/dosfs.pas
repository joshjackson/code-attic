
Unit DosFs;

Interface

Uses Objects,DPMI;

Type  PBPB =   ^TBPB;
    TBPB =   Record
        BytesPerSect :   word;
        SectPerClust :   byte;
        ResSects   :   word;
        NumFats   :   byte;
        RootSize   :   word;
        TotalSects  :   word;
        MediaDesc  :   byte;
        FatSects   :   word;
        SectPerTrack :   word;
        NumHeads   :   word;
        HiddenSects  :   word;
        TotalBigSects :   longint;
        DriveNum   :   byte;
        Reserved   :   byte;
        Signature  :   byte;
        SerialNum  :   longint;
        VolumeLabel  :   array[1..11] Of char;
        Reserved2  :   array[1..8] Of byte;
    End;
    PBootRecord =   ^TBootRecord;
    TBootRecord =   Record
        Jmp    :   array[1..3] Of byte;
        OEMID    :   array[1..8] Of char;
        BPB    :   TBPB;
        BootCode   :   array[1..452] Of byte;
    End;
    PDirEntry =   ^TDirEntry;
    TDirEntry =   Record
        FileName  :   array[1..8] Of char;
        FileExt  :   array[1..3] Of char;
        Attrib  :   byte;
        VerInfo  :   byte;
        CreationMs :   byte;
        CreationTime:   word;
        CreationDate:   word;
        LastAccess :   word;
        EAHandle  :   word;
        FileTime  :   word;
        FileDate  :   word;
        StartClust :   word;
        FileLen  :   longint;
    End;
    PLFNEntry =   ^TLFNEntry;
    TLFNEntry =   Record
        OrdVal  :   byte;
        LFN1   :   array[1..10] Of char;
        Attrib  :   byte;
        LFNType  :   byte;
        CheckSum  :   byte;
        LFN2   :   array[1..12] Of char;
        StartClust :   word;
        LFN3   :   array[1..4] Of char;
    End;
    PSectorRequestBlock =   ^TSectorRequestBlock;
    TSectorRequestBlock =   Record
        StartSect:   longint;
        NumSect:   word;
        DataPtr:   longint;
        SectData:   byte;
    End;
    PSectorBlock =   ^TSectorBlock;
    TSectorBlock =   Record
        SectorNum:   longint;
        Sector:   array[1..512] Of byte;
    End;

Type PSectorCollection =   ^TSectorCollection;
    TSectorCollection =   Object(TCollection)
        Function At(Index:integer):   PSectorBlock;
        Procedure FreeItem(Item:Pointer);
        virtual;
    End;

Type  PDriveManager =   ^TDriveManager;
    PFATManager =   ^TFATManager;
    PDirectoryManager =   ^TDirectoryManager;
    PSectorCache =   ^TSectorCache;
    TDriveManager =   Object(TObject)
        InitFailed:   byte;
        Drive:   byte;
        BootSect:   TBootRecord;
        BPB:   PBPB;
        DataStart:   longint;
        FATMgr:   PFATManager;
        DirMgr:   PDirectoryManager;
        Cache:   PSectorCache;
        Constructor Init(DriveNum:byte;Cached:boolean);
        Destructor Done;
        virtual;
        Function ReadSector(Var Buff; StartSect:Longint; NumSect:word):   word;
        Function ReadCluster(Var Buff; ClustNum:word):   word;
        Function WriteSector(Var Buff; StartSect:Longint; NumSect:word):   word;
        Function WriteCluster(Var Buff; ClustNum:word):   word;
        Private 
            IOBuffer:   Pointer;
            IODosSeg:   Word;
            Function ValidateDrive:   boolean;
    End;
    TFATManager =   Object(TObject)
        Owner:   PDriveManager;
        FatBuffer:   PSectorCollection;
        Constructor Init(Drive:PDriveManager);
        Destructor Done;
        virtual;
    End;
    TDirectoryManager =   Object(TCollection)
        Owner:   PDriveManager;
        constructor Init(Drive:PDriveManager);
        destructor Done;
        virtual;
    End;
    TSectorCache =   Object(TCollection)
        Owner:   PDriveManager;
        Constructor Init(Drive:PDriveManager);
        Destructor Done;
        virtual;
    End;

Const erBadDrive  =   01;
    erSectorRead =   02;
    erSectorWrite =   03;

Implementation

Uses DOS,WinAPI;

{----------------------------------------------------------------------------
 TDriveManager Object: Drive access core function
 ----------------------------------------------------------------------------}
Constructor TDriveManager.Init(DriveNum:byte;Cached:boolean);

Var tmpw:   word;

Begin
    Inherited Init;
    Drive := DriveNum;
    If Not ValidateDrive Then
        Begin
            InitFailed := erBadDrive;
            exit;
        End;
    tmpw := 65520;
    IOBuffer := AllocBuffer(tmpw);
    If IOBuffer = Nil Then
        Begin
            Writeln('Fatal Error: AllocBuffer failed to allocate disk I/O buffer');
            halt(1);
        End;
      {$IFDEF DPMI}
    IODosSeg := tmpw;
      {$ELSE}
    IODosSeg := Seg(IOBuffer);
      {$ENDIF}
    If ReadSector(BootSect, 0, 1) > 0 Then
        Begin
            InitFailed := erSectorRead;
            exit;
        End;
    BPB := @BootSect.BPB;
    DataStart := (BPB^.NumFats * BPB^.FatSects) + BPB^.ResSects + (BPB^.RootSize Div 32);
    FatMgr := New(PFATManager, Init(@Self));
    DirMgr := New(PDirectoryManager, Init(@Self));
End;

Function TDriveManager.ReadSector(Var Buff; StartSect:Longint; NumSect:word):   word;

Var ReqBlock:   PSectorRequestBlock;
    Regs:   Registers;
    p:   pointer;

Begin
    ReqBlock := IOBuffer;
    ReqBlock^.StartSect := StartSect;
    ReqBlock^.NumSect := NumSect;
    ReqBlock^.DataPtr := IODosSeg + (Sizeof(TSectorRequestBlock) - 1) shl 16;
    Regs.ax := Drive;
    Regs.cx := $FFFF;
    Regs.bx := 0;
    Regs.ds := IODosSeg;
    CallInt($25, Regs);
    If (Regs.Flags And fCarry) > 0 Then
        ReadSector := Regs.ax
    Else
        Begin
            p := Ptr(Seg(ReqBlock), Ofs(ReqBlock^.SectData));
            Move(p^, Buff, NumSect * 512);
            ReadSector := 0;
        End;
End;

Function TDriveManager.ReadCluster(Var Buff; ClustNum:word):   word;

Var LogicalSect:   longint;

Begin
    LogicalSect := ((ClustNum - 2) * BPB^.SectPerClust) + DataStart;
    ReadCluster := ReadSector(Buff, LogicalSect, BPB^.SectPerClust);
End;

Function TDriveManager.WriteSector(Var Buff; StartSect:Longint; NumSect:word):   word;

Begin
End;

Function TDriveManager.WriteCluster(Var Buff; ClustNum:word):   word;

Begin
End;

Function TDriveManager.ValidateDrive:   boolean;

Begin
    ValidateDrive := True;
End;

Destructor TDriveManager.Done;

Begin
    Inherited Done;
End;

{----------------------------------------------------------------------------
 TFATManager: File Allocation Table Manager
 ----------------------------------------------------------------------------}
Constructor TFATManager.Init(Drive:PDriveManager);

Var  TempSect:   PSectorBlock;
    t:   word;
    StartSect, EndSect:   longint;

Begin
    Inherited Init;
    Owner := Drive;
    StartSect := Owner^.BPB^.ResSects;
    EndSect := StartSect + Owner^.BPB^.FatSects;
    FatBuffer := New(PSectorCollection, Init(Owner^.BPB^.FatSects, 1));
    writeln('TFatManager.Init: Reading ',EndSect - StartSect,' fat sectors');
    For t:= StartSect To EndSect Do
        Begin
            New(TempSect);
            TempSect^.SectorNum := t;
            Owner^.ReadSector(TempSect^.Sector, t, 1);
            FatBuffer^.Insert(TempSect);
        End;
End;

Destructor TFATManager.Done;

Begin
    Dispose(FatBuffer, Done);
    Inherited Done;
End;

{----------------------------------------------------------------------------
 TDirectoryManager: Directory Services mananger
 ----------------------------------------------------------------------------}
Constructor TDirectoryManager.Init(Drive:PDriveManager);

Begin
    Inherited Init(50,1);

End;

Destructor TDirectoryManager.Done;

Begin
    Inherited Done;
End;

{----------------------------------------------------------------------------
 TSectorCollection: A collection object for storing upto 16384 Sectors
 ----------------------------------------------------------------------------}
Function TSectorCollection.At(Index:integer):   PSectorBlock;

Begin
    At := TCollection.At(Index);
End;

Procedure TSectorCollection.FreeItem(Item:Pointer);

Begin
    If Item <> Nil Then Dispose(PSectorBlock(Item));
End;

{----------------------------------------------------------------------------
 TSectorCache: Hard drive sector caching object
 ----------------------------------------------------------------------------}
Constructor TSectorCache.Init(Drive:PDriveManager);

Begin
    Inherited Init(1000,1);
End;

Destructor TSectorCache.Done;

Begin
    Inherited Done;
End;

End.
