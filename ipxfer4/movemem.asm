;----------------------------------------------------------------------------
; Program: MOVEMEM.ASM
; Purpose: High speed raw memory moving
;
; WARNING:  This program requires an 80386 or better processor!
;---------------------------------------------------------------------------
.386

code segment use16
assume cs:code

public	Move32
public	Fill32

Move32 Proc

mframe     	struc                  	;Structure for stack access
mbp0       	dw ?                   	;Gets BP
mret_adr0  	dw ?                   	;Return address to caller
mCount     	dw ?                  	;Bytes to move
MoveDest   	dd ?                   	;Destination
MoveSource 	dd ?                   	;Source
mframe     	ends                   	;End of structure

frame      	equ [ bp - mbp0 ]       	;Address structure elements

	push  bp               	;Prepare for parameter addressing
	mov   bp,sp            	;through BP register

		mov dx,ds
		cld
		mov bx,Frame.mCount
		mov cx,bx
		and bx,3
		shr cx,2
		lds si,Frame.MoveSource
		les di,Frame.MoveDest
		rep movsd
		cmp bx,1
		jl @@MoveDone
		mov cx,bx
		rep movsb
	@@MoveDone:
		mov ds,dx


	pop   bp               	;Get registers from stack
	ret   10               	;Return to caller, remove
									;arguments from stack
Move32 Endp

Fill32 proc

fframe     	struc                  	;Structure for stack access
fbp0       	dw ?                   	;Gets BP
fret_adr0  	dw ?                   	;Return address to caller
fCount     	dw ?                  	;Bytes to fill
fValue	  	dd ?                   	;Value to fill with
FillDest   	dd ?                   	;Destination
fframe     	ends                   	;End of structure

frame      	equ [ bp - fbp0 ]       	;Address structure elements

	push  bp               	;Prepare for parameter addressing
	mov   bp,sp            	;through BP register

		mov dx,ds
		cld
		mov bx,Frame.fCount
		mov cx,bx
		and bx,3
		shr cx,2
		mov eax,Frame.fValue
		les di,Frame.FillDest
		rep stosd
		cmp bx,1
		jl @@FillDone
		mov cx,bx
		rep movsb
	@@FillDone:
		mov ds,dx

	pop   bp               	;Get registers from stack
	ret   10               	;Return to caller, remove

Fill32 endp

code ends
end