
Unit DPMI;

Interface

Uses Dos;

Type  TRealIntStruct =   Record
    EDI  :   Longint;
    ESI  :   Longint;
    EBP  :   Longint;
    Res  :   Longint;
    EBX  :   Longint;
    EDX  :   Longint;
    ECX  :   Longint;
    EAX  :   Longint;
    Flags  :   word;
    ES   :   word;
    DS   :   word;
    FS   :   word;
    GS   :   word;
    IP   :   word;
    CS   :   word;
    SP   :   word;
    SS   :   word;
End;

{$l MOVEMEM.OBJ}

Procedure Move32(Var Source; Var Dest; Count:word);
Function AllocBuffer(Var BuffSize:word):   Pointer;
Function FreeBuffer(Buffer:Pointer;Size:Word):   Boolean;
Procedure CallInt(IntNo:byte; Var Regs:Registers);

Implementation

Uses Memory, WinAPI;

Procedure Move32(Var Source; Var Dest; Count:word);
external;

Function AllocBuffer(Var BuffSize:word):   Pointer;

Var TempSel,TempSeg:   word;
    l:   longint;
    NumBlocks:   word;

Begin
    {$IFNDEF DPMI}
    AllocBuffer := MemAllocSeg(BuffSize);
      {$ELSE}
    l := GlobalDosAlloc(BuffSize);
    AllocBuffer := Ptr(l And $FFFF, 0);
    BuffSize := (l And $FFFF0000) shr 16;

{      	if (BuffSize < 16) or (BuffSize > 65520) then begin
         	AllocBuffer:=Nil;
            Exit;
         end;
      	NumBlocks:=BuffSize Div 16;
         if (BuffSize Mod 16) > 0 then Inc(NumBlocks);
         asm
         	pusha
         	mov ax, $0100
				mov bx, ss:NumBlocks
            int $31
            jnc @@Ok
            mov ss:TempSel,0
            jmp @@Done
         @@Ok:
         	mov ss:TempSel,dx
            mov ss:TempSeg,ax
			@@Done:
         	popa
         end;
         AllocBuffer:=ptr(TempSel, 0);}
      {$ENDIF}
End;

Function FreeBuffer(Buffer:Pointer;Size:Word):   Boolean;

Var  TempSel:   Word;
    RetCode:   word;

Begin
{$IFNDEF DPMI}
    If Buffer <> Nil Then
        Begin
            FreeMem(Buffer, Size);
            FreeBuffer := True;
        End
    Else
        FreeBuffer := False;
{$ELSE}
    TempSel := Seg(Buffer);
    GlobalDosFree(TempSel);
    Exit;
    asm
		pusha
		mov ax, $0101
		mov dx, ss:   TempSel
        int $31
        jnc @@Ok
        mov ss:   RetCode, ax
        jmp @@Done
      @@Ok:
        mov ss:   RetCode, 0
      @@Done:
        popa
	End;
	If RetCode > 0 Then
		FreeBuffer := False
	Else
		FreeBuffer := True;
{$ENDIF}
End;

Procedure CallRealInt(IntNo:byte;Var R:Registers);

Var  RealRegs:   TRealIntStruct;
    TempSeg,TempOfs:   word;

Begin
    With RealRegs Do
        Begin
            EDI := R.di;
            ESI := R.si;
            EBP := R.bp;
            Res := 0;
            EBX := R.bx;
            EDX := R.dx;
            ECX := R.cx;
            EAX := R.ax;
            Flags := R.Flags;
            ES := R.es;
            DS := R.ds;
            SS := 0;
            SP := 0;
        End;
    TempSeg := Seg(RealRegs);
    TempOfs := Ofs(RealRegs);
    asm
    pusha
    mov bl,IntNo
    mov bh,0;
    mov es,TempSeg
    mov di,TempOfs
    mov cx,0
    mov ax,$0300
    int $31
    popa
End;
With RealRegs Do
    Begin
        R.di := EDI;
        R.si := ESI;
        R.bp := EBP;
        R.bx := EBX;
        R.dx := EDX;
        R.cx := ECX;
        R.ax := EAX;
        R.Flags := Flags;
        R.es := ES;
        R.DS := DS;
    End;
End;

Procedure CallInt(IntNo:byte; Var Regs:Registers);

Begin
{$IFNDEF DPMI}
    intr(intno, Regs);
{$ELSE}
    CallRealInt(IntNo, Regs);
{$ENDIF}
End;

End.
