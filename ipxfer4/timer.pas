
Unit Timer;

Interface

Uses DOS;

Procedure InitTimer;
Procedure DoneTimer;
Procedure ClearTimer;
Function TimerVal:   longint;
Function TimerTicks:   longint;
Function TimerTotal:   Longint;

Implementation

Var TimerValue:   longint;
    TimerTotalTicks:   longint;
    OldInt_8:   Pointer;
    ExitProcChain:   pointer;
    TimerActive:   boolean;

{$F+,S-,I-,V-,B-}
Procedure STI;
Inline($FB);

Procedure CallOldInt(sub:pointer);

Begin
    InLine($9C/$FF/$5E/$06);
End;

Procedure INT_8(Flags,CS,IP,AX,BX,CX,DX,SI,DI,DS,ES,BP:word);
interrupt;

Begin
    CallOldInt(OldInt_8);
    inc(TimerValue);
    inc(TimerTotalTicks);
    STI;
End;
{$F-}

Procedure ClearTimer;

Begin
    TimerValue := 0;
End;

Function TimerVal:   longint;

Begin
    TimerVal := (TimerValue * 10) Div 182
End;

Function TimerTicks:   longint;

Begin
    TimerTicks := TimerValue;
End;

Function TimerTotal:   Longint;

Begin
    TimerTotal := TimerTotalTicks;
End;

{$F+}
Procedure EndTimerSession;

Begin
    If TimerActive Then
        SetIntVec($08,OldInt_8);
    ExitProc := ExitProcChain;
End;
{$F-}

Procedure InitTimer;

Begin
    If Not timeractive Then
        Begin
            TimerValue := 0;
            TimerTotalTicks := 0;
            GetIntVec($08,OldInt_8);
            SetIntVec($08,@INT_8);
            TimerActive := True;
        End;
End;

Procedure DoneTimer;

Begin
    If TimerActive Then
        SetIntVec($08,OldInt_8);
End;

Begin
    TimerActive := False;
    ExitProcChain := ExitProc;
    ExitProc := @EndTimerSession;
End.
