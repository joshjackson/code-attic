
Unit Win95API;

Interface

Uses LFN, DOS;

Type PVolumeInfo =   ^TVolumeInfo;
    TVolumeInfo =   Record
        RootName :   string;
        FileSysName :   string;
        FileSysFlags :   Word;
        MaxNameLen :   Word;
        MaxPathLen :   Word;
    End;

Procedure InitWin95;

Function LFNReadFile(Handle:word; Var Data; Count:word; Var Result:word):   boolean;
Function LFNWriteFile(Handle:word; Var Data; Count:word; Var Result:word):   boolean;
Procedure LFNCloseFile(Handle:word);

Var LFNSupport:   boolean;

Implementation

Function LFNReadFile(Handle:word; Var Data; Count:word; Var Result:word):   boolean;

Var Regs:   Registers;

Begin
    Regs.AX := $3F00;
    Regs.BX := Handle;
    Regs.CX := Count;
    Regs.DS := Seg(Data);
    Regs.DX := Ofs(Data);
    MsDos(Regs);
    Result := Regs.Ax;
    If (Regs.Flags And fCarry) <> 0 Then
        LFNReadFile := False
    Else
        LFNReadFile := True;
End;

Function LFNWriteFile(Handle:word; Var Data; Count:word; Var Result:word):   boolean;

Var Regs:   Registers;

Begin
    Regs.AX := $3F00;
    Regs.BX := Handle;
    Regs.CX := Count;
    Regs.DS := Seg(Data);
    Regs.DX := Ofs(Data);
    MsDos(Regs);
    Result := Regs.Ax;
    If (Regs.Flags And fCarry) <> 0 Then
        LFNWriteFile := False
    Else
        LFNWriteFile := True;
End;

Procedure LFNCloseFile(Handle:word);

Var Regs:   Registers;

Begin
    Regs.AX := $3E00;
    Regs.BX := Handle;
    MsDos(Regs);
End;

Procedure InitWin95;

Var Tmpstr:   string;

Begin
    If LFNGetDir(0, tmpstr) > 255 Then
        LFNSupport := False
    Else
        LFNSupport := True;
    If LFNSupport Then
        Begin
        End;
End;

Begin
    InitWin95;
End.
