
Unit RecStats;

Interface

Procedure MakeStatusWindow(FPath:String;FName:String;FSize:Longint);
Procedure UpdateStatus(FPos:longint);

Implementation

Uses Window,SuperIO,Crt;

Var CurSize:   Longint;
    BlockSize:   Longint;

Procedure MakeStatusWindow(FPath:String;FName:String;FSize:Longint);

Begin
    MakeWind(5,10,75,15,15,1,2,1);
    CurSize := FSize;
    BlockSize := FSize Div 60;
    If BlockSize = 0 Then
        BlockSize := 1;
    TextAttr := 31;
    MidPrint('[Transfer Information]',9);
    MidPrint('[Press ESC to abort]',16);
    TextAttr := 30;
    Print(10,6,'Path:');
    Print(11,6,'Filename:');
    Print(11,40,'File size:');
    Print(13,6,'Bytes Received:');
    Print(13,40,'Bytes Remaining:');
    TextAttr := 31;
    Print(10,12,FPath);
    Print(11,16,FName);
    GotoXY(51,11);
    write(FSize);
    Print(15,7,'0%');
    Print(15,71,'100%');
    TextAttr := 15;
    Print(15,10,Space(60));
End;

Procedure UpdateStatus(FPos:longint);

Var TmpStr:   String[60];
    CurBlcks:   Byte;

Begin
    TextAttr := 31;
    GotoXY(22,13);
    Write(FPos);
    GotoXY(57,13);
    Write(CurSize - FPos,'          ');
    GotoXY(10,15);
    CurBlcks := FPos Div BlockSize;
    If CurBlcks > 60 Then
        CurBlcks := 60;
    FillChar(TmpStr[1], CurBlcks, #176);
    TmpStr[0] := Char(CurBlcks);
    TextAttr := 31;
    Write(TmpStr);
End;
End.
