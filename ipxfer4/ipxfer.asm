.386
code segment USE16
assume cs:code,ds:code,ss:code
org 0

;== Constants =========================================================

cmd_fld  equ 2                  	;Offset command field in data block
status   equ 3                   ;Offset status field in data block
num_dev  equ 13                  ;Offset number of supported devices
changed  equ 14                  ;Offset medium changed?
end_adr  equ 14                  ;Offset driver end addr. in data block
b_adr    equ 14                  ;Offset buffer address in data block
num_cmd  equ 16                  ;Functions 0-16 are supported
num_db   equ 18                  ;Offset number in data block
bpb_adr  equ 18                  ;Offset Address of BPB of the media
sector   equ 27                  ;Offset first sector number
dev_des  equ 22                  ;Offset device description of RAM disk

;== Data  =============================================================

frst_b   equ this byte           ;First byte of the driver

;-- Device driver header ----------------------------------------------

    dw -1,-1                ;Link to next driver
    dw 0100100000000001b    ;Driver attribute
    dw offset strat         ;Pointer to strategy routine
    dw offset intr          ;Pointer to interrupt routine
    db 1                    ;Devices supported
    db 'IPXFER$'            ;These bytes give the name

;-- Jump table for individual functions -------------------------------

fct_tab  dw offset init     ;Function  0: Initialization
    dw offset med_test      ;Function  1: Media test
    dw offset get_bpb       ;Function  2: Created BPB
    dw offset read          ;function  3: Direct read
    dw offset read          ;Function  4: Read
    dw offset dummy         ;Function  5: Read, remain in buffer
    dw offset dummy         ;Function  6: Input status
    dw offset dummy         ;Function  7: Erase input buffer
    dw offset write         ;Function  8: Write
    dw offset write         ;Function  9: Write & verify
    dw offset dummy         ;Function 10: Output status
    dw offset dummy         ;Function 11: Clear output buffer
    dw offset write         ;Function 12: Direct write
    dw offset dummy         ;Function 13: Open (Ver. 3.0 and up)
    dw offset dummy         ;Function 14: Close
    dw offset no_rem        ;Function 15: Changeable medium?
    dw offset write         ;Function 16: Output until busy


db_ptr   dw (?),(?)              ;Pass data block address

bpb_ptr  dw offset bpb,(?)       ;Accept BPB address

boot_sek db 3 dup (0)            ;Jump to the boot routine is
             							;normally stored here
			db "IPXFER$$"           ;Name of creator & version number
bpb      db 501 dup (0)

;== Driver routines and functions =====================================

strat    proc far           ;Strategy routine

    mov  cs:db_ptr,bx       ;Set data block address in
    mov  cs:db_ptr+2,es     ;the DB_PTR variable

    ret                     ;Return to caller

strat    endp

;--- IPXFER Driver Link Table -----------------------------------------
LinkTable:
   NetReadProc		dd 00000000

;--- IPXFER Driver Local Variables ------------------------------------
I_2f 			dd 00000000 ;INT 2F Chain Address
IPXFER_Drv 	db 0   		;PRCS_Drv designation
Active  		db 0			;Device active flag
Connected	db 0			;Connected to remote system
MediaChg		db 0			;Media Changed Flag

;----------------------------------------------------------------------
Int_2f:
   cmp ah,0f6h
   je Is_Func
   jmp dword ptr cs:[I_2f]

Is_Func:
   cmp al,0
   jne a1
   jmp Inst_2f
a1:
   cmp al,1
   jne a2
   jmp Link_Driver
a2:
   cmp al,2
   jne a3
   jmp set_BPB
a3:
   cmp al,2
   jne a3
   jmp set_Status
	iret

Inst_2f:
   mov al,0FFh
   iret

Link_Driver:
	cmp al,2
   push bx
   push es
   push cs
   pop es
   mov di, offset NetReadProc
	pop ax
   stosw
   pop ax
   stosw
   iret

set_BPB:
   push cs
   pop es
   mov di,offset BPB
   mov cx,356
   rep movsw
   iret

Set_Status:
	mov cs:Active, bh
   mov cs:Connected, bl
	iret

Get_Status:
	mov bh, cs:Active
   mov bl, cs:Connected
	iret

intr     proc far          ;Interrupt routine

   push ax                 ;Place registers on stack
   push bx
   push cx
   push dx
   push di
   push si
   push bp
   push ds
   push es
   pushf                   	;Set flag register

   push cs                 	;Set data segment register (code
   pop  ds                 	;and data are identical)

   cmp  Active,1
   jne  No_Jump

   les  di,dword ptr db_ptr	;Address of data block to ES:DI
   mov  bl,es:[di+cmd_fld] 	;Get command code
   cmp  bl,num_cmd         	;Is command code permitted?
   jle  bc_ok              	;Yes --> BC_OK

   mov  ax,8003h           	;Code for "Unknown command"
   jmp  intr_end     			;Return to caller

   ;-- Command code was O.K. --> Execute command ----------------

bc_ok:
	shl  bl,1               	;Calculate pointer in jump table
	xor  bh,bh              	;Clear BH
   call [fct_tab+bx]       	;Call function
   jmp intr_end


No_Jump:
	les  di,dword ptr db_ptr				;Data block address after ES:DI
   mov  ax,8002h           				;executed by error
   cmp  byte ptr es:[di+cmd_fld],00h   ;Only INIT is permitted
   jne  short intr_end     				;Error --> Return to caller

   call init               				;Can only be function 00H

   ;-- End execution of the function ----------------------------

intr_end label near

    push cs
    pop  ds
    les  di,dword ptr db_ptr
    or   ax,0100h           ;Set ready bit
    mov  es:[di+status],ax  ;Save entire contents in status field

    popf                    ;Pop flag register
    pop  es                 ;Pop remaining registers
    pop  ds
    pop  bp
    pop  si
    pop  di
    pop  dx
    pop  cx
    pop  bx
    pop  ax

    ret                     ;Return to caller

intr     endp

dummy    proc near               ;This routine does nothing

    xor  ax,ax              ;Clear busy bit
    ret                     ;Return to caller

dummy    endp

;----------------------------------------------------------------------

med_test proc near               		;Hard disk medium cannot be changed

    mov  al,cs:MediaChg						;Get the Media change flag
    mov  byte ptr es:[di+changed],al
    xor  ax,ax              				;Clear busy bit
    mov 	cs:MediaChg, al					;Cleat the Media change flag
    ret                     				;Return to caller

med_test endp

;----------------------------------------------------------------------

get_bpb  proc near               ;Pass address of BPB to DOS

    mov  word ptr es:[di+bpb_adr],offset bpb
    mov  word ptr es:[di+bpb_adr+2],ds

    xor  ax,ax              		;Clear busy bit
    ret                     		;Return to caller

get_bpb  endp

;----------------------------------------------------------------------

no_rem   proc near               ;Remote medium can be changed

    mov  ax,0              		;Clear busy bit
    ret                     		;Return to caller

no_rem   endp

;----------------------------------------------------------------------

write proc near

   mov  ax,8001h          			;Write protected.
   ret

write endp

;----------------------------------------------------------------------
Send_block db "HJ"    	;Read / Write
           dw 0000   	;Number of sectors
           dw 00000000  ;First Sector

read    proc near

	mov  bx,es:[di+num_db]  	;Number of sectors read
   mov  dx,es:[di+Sector]  	;Number of first sector
   mov  cx,es:[di+Sector+2]  	;Number of first sector
   les  di,es:[di+b_adr]		;Address of buffer to ES:DI
   lds  si,dword ptr Send_Block
   mov  word ptr cs:[si+2],bx
   mov  word ptr cs:[si+4],dx
   mov  word ptr cs:[si+6],cx
   xor  ax,ax
   pushf
	call dword ptr cs:[NetReadProc]  ;simulate an interrupt call
   cmp  ax,1
   jne  no_err
   mov  ax,8006h
no_err:
   ret

read    endp

Receive proc

   ret

Receive endp

init     proc near               ;Initialization routine

   mov  word ptr es:[di+end_adr],offset init      ;Set end address
   mov  es:[di+end_adr+2],cs                      ;of driver
   mov  byte ptr es:[di+num_dev],1                ;1 device supported
   mov  word ptr es:[di+bpb_adr],offset bpb_ptr   ;BPB pointer
   mov  es:[di+bpb_adr+2],cs                      ;address
   mov  ax,cs                          ;Segment address: start of RAM disk
   mov  bpb_ptr+2,ax                   ;Segment address: BPB in BPB pointer
   mov  al,es:[di+dev_des]             ;Get device designation
   mov  IPXFER_Drv,al                  ;Store in installation message
   mov  ah,09h             				;Display message
   mov  dx,offset ddmes
   int  21h
   mov ax,352fh                        ;Get the current INT 2F Address
   int 21h
   mov si,offset I_2f
   mov word ptr cs:[si],bx
   mov word ptr cs:[si+2],es
   mov ax,252fh								;Set our new handler Address
   push cs
   pop ds
   mov dx,offset Int_2f
   int 21h
   xor  ax,ax              				;Everything is O.K.
   ret                     				;Return to caller

Inst_err:
   pop di
   pop es
   mov dx,offset No_inst
   mov ah,9
   int 21h
   xor ax,ax
   ret

init     endp

ddmes db "ษออออออออออออออออออออออออออออออออออออออออออออป",10,13
      db "บ  IPXFER 4.10  LAN Device Driver v.01 beta  บ",10,13
      db "บ                                            บ",10,13
      db "บ       ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ        บ",10,13
      db "บ       ณ  Device Driver Installed  ณ        บ",10,13
      db "บ       ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู        บ",10,13
      db "บ                                            บ",10,13
      db "บ     Copyright 1996   Jackson Software      บ",10,13
      db "ศออออออออออออออออออออออออออออออออออออออออออออผ",10,10,13,"$"

No_Inst db "IPXFER ERROR: Device driver initialization failure.",10,10,13,"$"

code ends
end

