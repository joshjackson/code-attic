.286
STACK_LEN  equ 72                 ;Number of words in the internal stack

ExecStruc struc                   ;Data structure for EXEC function
EsSegEnv  dw ?                    ;Segment address of environment blocks
EsCmdPAdr dd ?                    ;Pointer to command line parameters
EsFCB1Adr dd ?                    ;Pointer to FCB #1
EsFCB2Adr dd ?                    ;Pointer to FCB #2

ExecStruc ends

public     SwapOutAndExec         ;Gives a Turbo Pascal program the
											 ;ability to pass the address of
											 ;the assembler handler
public     InitSwapa              ;Initialization procedure

;== Data segment ===========================================================

DATA   segment word public

extrn  PrefixSeg : word           ;Segment address of PSP in Turbo variables

DATA   ends

;== Program ===============================================================

CODE       segment byte public    ;Program segment


;== Variables in code segment ===============================================

CodeStart  equ this word          ;Code begins here which is copied to
											 ;the Turbo program

;-- Variables needed by the Swap routines for uploading and downloading ----

CoStAddr   dd ?                   ;Orig. address of PARA(CodeStart)
CoStLen    dw ?                   ;Number of words swapped w/ CoStAddr
StackPtr   dw ?                   ;Gets old stack pointer
StackSeg   dw ?                   ;Gets old stack segment
TurboSeg   dw ?                   ;Segment address - Turbo code segment

;-- Variables needed for program configuration and command execution -------

NewStack   dw STACK_LEN dup (?)   ;New stack
EndStack   equ this word          ;End of stack

Command    dd ?                   ;Pointer to command
CmdPara    dd ?                   ;Pointer to command line parameters
ToDisk     db ?                   ;True when disk swapping occurs
Handle     dw ?                   ;Disk or EMS handle
Len        dd ?                   ;Number of bytes saved

FCB1       db  16 dup (0)       ;FCB #1 for PSP
FCB2       db  16 dup (0)       ;FCB #2 for PSP
CmdBuf     db 128 dup (0)       ;Commands following prg. name
PrgName    db  64 dup (0)       ;Program name
ExecData   ExecStruc <0, CmdBuf, FCB1, FCB2>   ;Data structure for EXEC

OldPara    dw ?                   ;Number of previously reserved paragraphs
FrameSeg   dw ?                   ;Segment address of EMS page frame
Error_Code db 0                   ;Error code for caller

TerMes     db 13,10,13,10
			  db "ษอออออออออออออออออออออออออออออออออออออออออออออออออป",13,10
			  db "บ Done_Swap: The DOOM Font End program could      บ",13,10
			  db "บ            not be reloaded back into memory.    บ",13,10
			  db "บ            Program execution terminated!        บ",13,10
			  db "ศอออออออออออออออออออออออออออออออออออออออออออออออออผ"
			  db 13,10,13,10,"$"

Msg1       db 13,10,13,10
			  db "ษออออออออออออออออออออออออออออป",13,10
			  db "บ Init_Swap: Swapping out    บ",13,10
			  db "ศออออออออออออออออออออออออออออผ"
			  db 13,10,13,10,"$"


;== Procedures =============================================================

;---------------------------------------------------------------------------
;-- StartSwap : Coordinate swapping of Turbo Pascal program

StartSwap  proc far

			  assume cs:code, ds:nothing

			  ;-- Store current stack and initialize new stack ----------------

			  cli                    ;Suppress interrupts
			  mov   StackPtr,sp      ;Mark current stack
			  mov   StackSeg,ss
			  push  cs               ;Install new stack
			  pop   ss
			  mov   sp,offset EndStack - 2
			  sti                    ;Re-enable interrupts

			  push  cs               ;Set DS to CS
			  pop   ds
			  assume cs:code, ds:code

			  ;-- Overwrite unnecessary memory --------------------------------

			  cmp   ToDisk,0         ;Write to EMS memory?
			  je    Ems              ;Yes ---> Ems

			  call  Write2File       ;No ---> Write to file
			  jnc   ShrinkMem        ;No error ---> ShrinkMem

			  mov   Error_Code, 1    ;File output error?
			  jmp   short GetBack    ;return to Turbo

Ems:       mov   ah,41h           ;Pass segment address of the page frame
			  int   67h              ;Call EMM
			  mov   FrameSeg,bx      ;Place result in variables

			  call  Write2Ems        ;Write program to EMS

			  ;-- Provide number of currently allocated paragraphs ------------

ShrinkMem: mov   ax,TurboSeg      ;Segment address of Turbo code segment
			  sub   ax,11h           ;Allocate 10 paragraphs for PSP and 1
											 ;for MCB
			  mov   es,ax            ;ES now pointer to Turbo prog. MCB
			  mov   bx,es:[3]        ;Get number of paragraphs allocated
			  mov   OldPara,bx       ;and place in variable

			  ;-- Calculate the number of paragraphs needed and reduce  --
			  ;-- memory requirements by this amount                    --

			  inc   ax               ;AX now points to the PSP
			  mov   es,ax            ;for function call to ES
			  mov   bx,CostLen       ;Number of words needed by Swap routine
			  add   bx,128+7         ;Recalculate and round off PSP
			  mov   cl,3             ;Divide by 8 words (per paragraph)
			  shr   bx,cl

			  mov   ah,4Ah           ;Function number for "change size"
			  int   21h              ;Call DOS interrupt

			  ;-- Execute specified command line using the EXE function ------

			  mov   bp,ds            ;Store DS

			  mov   ax,cs            ;Set ES and DS to CS
			  mov   es,ax
			  mov   ds,ax

			  ;-- Enter segment address of code segments in the pointer -----
			  ;-- to the EXEC structure

			  mov   word ptr ExecData.EsFCB1Adr + 2,ax
			  mov   word ptr ExecData.EsFCB1Adr + 2,ax
			  mov   word ptr ExecData.EsCmdPAdr + 2,ax

			  mov   bx,offset ExecData  ;ES:BX point to parameter block
			  mov   dx,offset PrgName   ;DS:DX point to command string

			  mov   ax,4B00h         ;Function number for "EXEC"
			  int   21h              ;Call DOS interrupt
			  mov   ds,bp            ;Move DS
			  jnc   ReMem            ;No error ---> ReMem

			  mov   Error_Code,ah    ;Note ErrorCode

			  ;-- Return memory to original size ------------------------------

ReMem:     mov   ax,TurboSeg      ;Set Turbo code segment address
			  sub   ax,10h           ;to start of PSP
			  mov   es,ax            ;and load into ES
			  mov   bx,OldPara       ;Old number of paragraphs

			  mov   ah,4Ah           ;Function number for "change size"
			  int   21h              ;Call DOS interrupt
			  jnc   GetBack          ;No error ---> GetBack

			  jmp   Terminate        ;Error in ReMem --> End program

			  ;-- Return to program -------------------------------------------

GetBack:   cmp   ToDisk,0         ;Write to EMS memory?
			  je    Ems1             ;Yes ---> Ems1

			  call  GetFromFile      ;No, reload as file
			  jnc   CloseUp          ;No error ---> CloseUp

			  jmp   Terminate        ;Read error, end program

Ems1:      call  GetFromEms       ;Get Turbp Pascal program from EMS memory

			  ;-- Restore old stack -------------------------------------------

CloseUp:   cli                    ;Suppress interrupts
			  mov   ss,StackSeg
			  mov   sp,StackPtr
			  sti                    ;Re-enable interrupts

			  ;-- Prepare registers for swap ----------------------------------

			  push  cs                       ;Push DS to CS
			  pop   ds
			  assume cs:code, ds:code

			  mov   cx,CoStLen               ;Number of words to be swapped
			  mov   di,cx                    ;Move number of words to DI
			  dec   di                       ;Decrement by one word
			  shl   di,1                     ;Double it
			  mov   si,di                    ;move to SI
			  add   di,word ptr CostAddr     ;DI+offset addr. of Swap routine
			  mov   es,word ptr CostAddr + 2 ;ES gets old CS of Swap routine
			  mov   ds,TurboSeg              ;Seg addr. of start of code

			  ret                            ;Return to SwapOutAndExec

StartSwap  endp

;---------------------------------------------------------------------------
;-- Write2Ems : Write program to be swapped to EMS memory
;-- Input     : BX = Segment address of EMS page frame
;--             DS = Codesegment

EMS_PLEN   equ 16384                   ;Length of an EMS page

HiWLen     dw    ?                     ;Remaining Hi-Word length

Write2Ems  proc near

			  push  ds                    ;Push DS onto stack
			  cld                         ;Increment on string instructions
			  mov   es,bx                 ;ES points to the page frame

			  mov   bp,word ptr Len       ;Move Lo-Word length to BP
			  mov   ax,word ptr Len + 2   ;Move Hi-Word length to AX
			  mov   HiWLen,ax             ;and then to variable

			  mov   dx,Handle             ;Move EMS Handle to DX
			  xor   bx,bx                 ;Start with first logical page

			  assume cs:code, ds:nothing

			  jmp short WriECalc          ;Jump in the loop

WriELoop:  ;-- Register allocation within this loop -----------------------
			  ;
			  ;  AX        = Times this, times that
			  ;  BX        = Number of logical EMS pages to be addressed
			  ;  CX        = Number of bytes to be copied in this execution
			  ;  DX        = EMS handle
			  ;  ES:DI     = Pointer to first page in EMS page frame (Target)
			  ;  DS:SI     = Pointer to first word to be copied      (Start)
			  ;  HiWLen:BP = Number of bytes remaining to be copied

			  mov   ax,4400h              ;Function number for illustration
			  int   67h                   ;Call EMM

			  mov   si,offset CodeEnd     ;Offset for Swapping
			  xor   di,di                 ;Write to the start of the EMS page
			  mov   ax,cx                 ;Move number to AX
			  rep movsb                   ;Copy memory

			  sub   bp,ax                 ;Remainder of written bytes
			  sbb   HiWLen,0              ;Decrement

			  inc   bx                    ;Increment number of logical page

			  mov   ax,ds                 ;Starting segment to AX
			  add   ax,EMS_PLEN shr 4     ;Increment by written paragraphs
			  mov   ds,ax                 ;and move to DS

WriECalc:  mov   cx,EMS_PLEN           ;Write EMS_PLEN bytes
			  cmp   HiWLen,0              ;More than 64K?
			  ja    WriELoop              ;Yes ---> WriELoop
			  cmp   bp,cx                 ;No ---> More than EMS_PLEN bytes?
			  jae   WriELoop              ;Yes ---> Continue writing
			  mov   cx,bp                 ;No ---> Write remainder
			  or    cx,cx                 ;No more bytes to write?
			  jne   WriELoop              ;No ---> WriELoop

WriERet:   pop   ds                    ;Pop DS off of stack
			  ret                         ;Return to caller

Write2Ems  endp

;---------------------------------------------------------------------------
;-- GetFromEms : Get the swapped program from EMS memory
;-- Input   : DS = Code segment

GetFromEms proc near

			  push  ds                    ;Push DS onto the stack
			  cld                         ;Increment on string instructions

			  mov   bp,word ptr Len       ;Move Lo-Word length to BP
			  mov   ax,word ptr Len + 2   ;Move Hi-Word length to AX
			  mov   HiWLen,ax             ;and from there to variable

			  mov   dx,Handle             ;Move EMS handle to DX
			  xor   bx,bx                 ;Start with first logical page

			  mov   ds,FrameSeg           ;DS points to the page frame
			  push  cs                    ;Set ES to the code segment
			  pop   es

			  assume cs:code, ds:nothing

			  jmp short GetECalc          ;Jump to the loop

GetELoop:  ;-- Register allocation within this loop -----------------------
			  ;
			  ;  AX        = times this, times that
			  ;  BX        = Number of logical EMS pages to be swapped
			  ;  CX        = Number of bytes to be copied in this execution
			  ;  DX        = EMS handle
			  ;  DS:SI     = Pointer to first page in EMS page frame (Start)
			  ;  ES:DI     = Pointer to target address in memory
			  ;  HiWLen:BP = Number of bytes still to be copied

			  mov   ax,4400h              ;Function number for illustration
			  int   67h                   ;Call EMM

			  mov   di,offset CodeEnd     ;Offset for Swapping
			  xor   si,si                 ;Write to the start of the EMS page
			  mov   ax,cx                 ;Move number to AX
			  rep movsb                   ;Copy memory

			  sub   bp,ax                 ;Remainder of written bytes
			  sbb   HiWLen,0              ;Decrement

			  inc   bx                    ;Increment number of logical page

			  mov   ax,es                 ;Move starting segment to AX
			  add   ax,EMS_PLEN shr 4     ;Increment by written paragraphs
			  mov   es,ax                 ;and move it to ES

GetECalc:  mov   cx,EMS_PLEN           ;Write EMS_PLEN bytes
			  cmp   HiWLen,0              ;More than 64K?
			  ja    GetELoop              ;Yes ---> GetELoop
			  cmp   bp,cx                 ;No ---> More than EMS_PLEN bytes?
			  jae   GetELoop              ;Yes ---> Continue writing
			  mov   cx,bp                 ;No ---> Write remainder
			  or    cx,cx                 ;No more bytes to write?
			  jne   GetELoop              ;No ---> GetELoop

GetERet:   pop   ds                    ;Pop DS off of stack
			  ret                         ;Return to caller

GetFromEms endp

;---------------------------------------------------------------------------
;-- Write2File : Write the program to be swapped to a file
;-- Returns    : Carry-Flag = 1 : Error

SwpName	  db 'C:\DFE_SWAP.FIL',00

Write2File proc near

NUM_WRITE  = 2048                      ;Bytes to be written per execution
													;to power of 2 (max. 2^16)
			  assume cs:code, ds:code

			  push  ds                    ;Push DS onto stack

			  mov   bp,4000h              ;Function number for "Write"
			  mov   bx,Handle             ;Load file handle

WriFStart: mov   di,word ptr Len       ;Move Lo-Word length to DI
			  mov   si,word ptr Len + 2   ;Move Hi-Word length to SI
			  mov   dx,offset CodeEnd     ;Write offset address
			  jmp   short WriFCalc        ;Compute no. of bytes to be written

WriFLoop:  ;-- Register allocation within this loop -----------------
			  ;
			  ;  AX        = times this, times that
			  ;  BX        = DOS file handle
			  ;  CX        = Number of bytes to be read/written
			  ;  DS:DX     = Address at which they should be read/written
			  ;  DI:SI     = Number of bytes still to be copied
			  ;  BP        = Number of DOS funtion to be called

			  mov   ax,bp                 ;Load DOS function number
			  int   21h                   ;Call DOS interrupt
			  jc    WriFEnd               ;Error ---> WriFEnd
			  mov   ax,ds                 ;Starting segment to AX
			  add   ax,NUM_WRITE shr 4    ;Increment by written paragraphs
			  mov   ds,ax                 ;and move to DS
			  sub   di,cx                 ;Decrement remainder of
			  sbb   si,0                  ;written bytes

WriFCalc:  mov   cx,NUM_WRITE          ;Write NUM_WRITE bytes
			  cmp   si,0                  ;More than 64K?
			  ja    WriFLoop              ;Yes ---> WriFLoop
			  cmp   di,cx                 ;No ---> More than NUM_WRITE bytes?
			  jae   WriFLoop              ;Yes ---> Continue writing
			  mov   cx,di                 ;No ---> Write remainder
			  or    cx,cx                 ;No more bytes to write?
			  jne   WriFLoop              ;No ---> WriFLoop

WriFEnd:   pop   ds                    ;Reload DS
WriFRet:   ret                         ;Return to caller

Write2File endp

;---------------------------------------------------------------------------
;-- GetFromFile : Return the swapped program to memory
;-- Returns    : Carry-Flag = 1 : Error

GetFromFile proc near

			  assume cs:code, ds:code

			  push  ds               ;Push DS onto the stack

			  ;-- Move file pointer to the start of file ----------------

			  mov   ax,4200h         ;DOS function number
			  mov   bx,Handle        ;Load file handle
			  xor   cx,cx            ;CX:DX gives its position
			  mov   dx,cx
			  int   21h              ;Call DOS interrupt
			  jc    WriFRet          ;Error ---> WriFRet

			  ;-- Load file into memory with the help of Write2File -----

			  mov   bp,3F00h         ;Function number for "Read"
			  jmp   WriFStart        ;Jump to Write2File

GetFromFile endp

;---------------------------------------------------------------------------
;-- Terminate : The system can't return to the original Turbo Pascal
;--             program. The program ends with an error code.

Terminate  label near

			  ;-- Display error message ---------------------------------------

			  push  cs               ;Set DS to CS
			  pop   ds
			  mov   dx,offset TerMes ;DS:DX points to the error message
			  mov   ah,9             ;Function number for "Display string"
			  int   21h              ;Display DOS interrupt

			  mov   ax,4C01h         ;End program with error code
			  int   21h


;===========================================================================

CodeEnd    equ this byte          ;Copy code from the start of the Turbo
											 ;Pascal program to this point

;---------------------------------------------------------------------------
;-- SwapOutAndExec : Swaps the current program to EMS memory or hard disk
;--                  and starts another program using the DOS EXEC function
;-- Call from Turbo: SwapOutAndExec( Command,
;--                                CmdPara : string;
;--                                ToDisk  : boolean;
;--                                Handle  : word;
;--                                Len     : longint );
;-- Info         : The Command and CmdPara parameters must be configured
;--                as strings in DOS format.

SwapOutAndExec proc near

ACommand   equ dword ptr [bp+16]  ;Constants for accessing the
ACmdPara   equ dword ptr [bp+12]  ;specified arguments
AToDisk    equ  byte ptr [bp+10]
AHandle    equ  word ptr [bp+ 8]
ALen       equ dword ptr [bp+ 4]
ARG_LEN    equ 16                 ;Lengths of arguments

			  assume cs:code, ds:data

			  push  bp               ;Enable access to the arguments
			  mov   bp,sp

			  ;-- Copy program name to buffer in code segment -----------------

			  push   ds
			  push   ax
			  push   dx
			  push   cs
			  pop    ds
			  mov    ah,9
			  mov    dx,offset Msg1
			  int    21h
			  pop    dx
			  pop    ax
			  pop    ds

			  mov   dx,ds            ;Mark DS
			  push  cs               ;Set ES to CS
			  pop   es

			  lds   si,ACommand      ;DS:SI points to command buffer
			  mov   di,offset PrgName ;ES:DI points to PrgName
			  cld                    ;Increment on string instructions
			  lodsb                  ;Read length of Pascal string
			  cmp   al,64            ;More than 64 characters?
			  jbe   CmdCopy          ;No ---> CmdCopy

			  mov   al,64            ;Yes ---> Copy a maximum of 64 characters

CmdCopy:   xor   ah,ah            ;Set Hi-Byte to 0 length and
			  mov   cx,ax            ;load into the counter
			  rep movsb              ;Copy string

			  ;-- Copy command line in buffer in code segment -----------------

			  lds   si,ACmdPara      ;DS:SI points to CmdPara buffer
			  mov   di,offset CmdBuf ;ES:DI points to CmdBuf
			  lodsb                  ;Read length of Pascal string
			  cmp   al,126           ;More than 126 characters?
			  jbe   ParaCopy         ;No ---> ParaCopy

			  mov   al,126           ;Yes ---> Copy maximum of 126 characters

ParaCopy:  stosb                  ;Store length as first byte
			  xor   ah,ah            ;Set Hi-Byte to 0 length and
			  mov   cx,ax            ;load into the counter
			  rep movsb              ;Copy string

			  mov   al,0dH           ;Add carriage return
			  stosb

			  ;-- Transfer filename from command line to FCBs -----------------

			  push  cs               ;Transfer CS to DS
			  pop   ds

			  mov   si,offset CmdBuf+1 ;DS:SI points to CmdBuf + 1
			  mov   di,offset FCB1   ;ES:DI points to FCB #1
			  mov   ax,2901h         ;Function no.:"Transfer filename to FCB"
			  int   21h              ;Call DOS interrupt

			  mov   di,offset FCB2   ;ES:DI now points to FCB #2
			  mov   ax,2901h         ;Function no.: "Transfer filename to FCB"
			  int   21h              ;Call DOS interrupt

			  mov   ds,dx            ;Move old value into DS

			  ;-- Transfer remaining parameters to variables ------------------

			  les   ax,ALen          ;Change length
			  mov   word ptr Len + 2,es
			  mov   word ptr Len,ax

			  mov   al,AToDisk       ;Change disk flag
			  mov   ToDisk,al

			  mov   ax,AHandle       ;Change handle
			  mov   Handle,ax

			  push  ds               ;Push DS onto the stack

			  ;-- Exchange variables and program code between labels CodeStart -
			  ;-- and CodeEnd with the contents of the PSP code segment

			  mov   ax,PrefixSeg             ;ES:DI points to start of Turbo
			  add   ax,10h                   ;program following PSP
			  mov   TurboSeg,ax              ;Mark addr. of Turbo code segment
			  mov   es,ax
			  xor   di,di

			  push  cs                       ;Set DS to CS
			  pop   ds
			  assume cs:code, ds:code

			  mov   si,offset CodeStart      ;DS:SI points to CodeStart
			  and   si,0FFF0h                ;Round off at start of paragraph

			  mov   cx,CostLen               ;Get number of words to be swapped
			  mov   word ptr CoStAddr,si     ;Mark address of
			  mov   word ptr CoStAddr + 2,ds ;PARA(Codestart)

			  mov   dx,es            ;Mark target segment in DX
			  cld                    ;Increment on SI/DI string instructions

			  ;-- Swap loop ---------------------------------------------------

dl_loop:   mov   ax,[si]          ;Load word from assembler module
			  mov   bx,es:[di]       ;Load word from Turbo Pascal program
			  stosw                  ;Write assm. module word to Turbo program
			  mov   [si],bx          ;Write Turbo program word to assm. module
			  inc   si               ;Set SI to next word
			  inc   si               ;(increment SI through STOSW)
			  loop  dl_loop          ;Use all words

			  ;-- Adapt segment address of code segment before calling the ---
			  ;-- StartSwap procedure so that variable references to the code
			  ;-- segment remain unchanged

			  mov   ax,offset CodeStart ;Compute number of paragraphs between
			  mov   cl,4                ;CodeStart and the start of the
			  shr   ax,cl               ;segment, and get segment address in
			  sub   dx,ax               ;DX


			  push  cs                  ;Return address to BACK label
			  mov   ax,offset back      ;Move onto the stack
			  push  ax

			  push  dx                  ;Push segment address onto stack
			  mov   ax,offset StartSwap ;Move offset address onto stack
			  push  ax

			  retf                      ;FAR-RET to StartSwap

Msg2       db 13,10,13,10
			  db "ษออออออออออออออออออออออออออออป",13,10
			  db "บ Done_Swap: Swapping in     บ",13,10
			  db "ศออออออออออออออออออออออออออออผ"
			  db 13,10,13,10,"$"

back:      ;----------------------------------------------------------------
			  ;-- Returns original program to main memory and executes the
			  ;-- program.
			  ;-- Registers have the following contents:
			  ;--   DS:SI = End of assembler code following the PSP
			  ;--   ES:DI = End of Turbo code in the SWAP unit
			  ;--   CX    = Number of words
			  ;----------------------------------------------------------------

			  assume cs:code, ds:nothing

			  std                    ;Decrement string instructions by SI/DI

			  ;-- Swap back loop ----------------------------------------------

			  push   ds
			  push   ax
			  push   dx
			  push   cs
			  pop    ds
			  mov    ah,9
			  mov    dx,offset Msg2
			  int    21h
			  pop    dx
			  pop    ax
			  pop    ds

ul_loop:   mov   bx,es:[di]       ;Get byte from old memory range
			  mov   ax,[si]          ;Get byte from current memory range
			  mov   [si],bx          ;Byte from old memory rng to current rng
			  dec   si               ;Set SI to previous word
			  dec   si
			  stosw                  ;Byte from current memory rng to old rng
			  loop  ul_loop          ;Repeat until memory ranges are exchanged

			  pop   ds               ;Pop DS off of stack
			  assume ds:data

			  pop   bp               ;Pop BP

			  ;-- MOV SP,BP must not be given, since SP doesn't change

			  xor   ah,ah            ;Place error code in AX
			  mov   al,Error_Code

			  ret ARG_LEN            ;Return to caller, clear arguments
											 ;from stack

SwapOutAndExec endp


;---------------------------------------------------------------------------
;-- InitSwapa : Computes the number of bytes/words allocated for a program
;--             swap with the start of the Turbo program in memory
;-- Input        : none
;-- Output       : number of bytes
;-- Pascal call  : function InitSWapa : word;
;-- Info         : This procedure must be called before the
;--                first call to SwapOutAndExec!

InitSwapa  proc near

			  assume cs:code, ds:data

			  mov   bx,offset CodeStart      ;AX points to start of code
			  and   bx,0FFF0h                ;Round off at start of paragraph
			  mov   ax,offset CodeEnd        ;BX points to end of code
			  sub   ax,bx                    ;Compute number of bytes
			  inc   ax                       ;Convert CX to words
			  shr   ax,1
			  mov   CoStLen,ax               ;Mark number of words to be swapped
			  shl   ax,1                     ;Convert to bytes

			  ;-- Return contents of AX as function result

			  ret                            ;Return to caller

InitSwapa  endp

;---------------------------------------------------------------------------

CODE       ends                   ;End of code segment
			  end                    ;End of program
