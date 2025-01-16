;----------------------------------------------------------------------------
; Program: MOVEMEM.ASM
; Purpose: High speed raw memory moving
;
; WARNING:  This program requires an 80386 or better processor!
;---------------------------------------------------------------------------
.386

data segment byte public use16

	extrn	vio_seg:word

data ends

code segment use16
assume cs:code,ds:data

public	Move32
public	Fill32
public	TransferScrn

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


plane	db	0

PIXX	equ	320
SC_INDEX		equ 	3c4h;Index register for sequencer ctrl.
SC_MAP_MASK equ 	2   ;Number of map mask register
SC_MEM_MODE	equ	4   ;Number of memory mode register

TransferScrn	proc	near

sframe     	struc                  	;Structure for stack access
bp0        	dw ?                   	;Gets BP
ret_adr0   	dw ?                   	;Return address to caller
BuffAddr   	dd ?                   	;Source
sframe     	ends                   	;End of structure

frame      	equ [ bp - bp0 ]       	;Address structure elements

	push  bp               	;Prepare for parameter addressing
	mov   bp,sp            	;through BP register

			push	ds
			push	es
			xor	ah,ah
			mov 	plane,0
			mov 	es,vio_seg
			lds	si,frame.BuffAddr
		@@BitLoop:
			xor 	ch,ch
			mov 	cl,plane
			mov	si,0
			add   si,cx
			mov 	ah,01b
			shl   ah,cl
			mov   al,SC_MAP_MASK   ;Register number to AL
			mov   dx,SC_INDEX      ;load sequencer index address
			out   dx,ax            ;Load bit mask register
			xor 	di,di
			mov 	bx,0
		@@CopyLoopY:
			push 	bx
			mov 	cx,0 	;PIXX / 4
		@@CopyLoopX:
			push 	cx
			mov 	ax,PIXX / 4
			mul	bl
			add	ax,cx
			mov   di,ax
			mov	al,[si]
			mov	ah,[si + 4]
			stosw
			add	si,8
			pop 	cx
			inc	cx
			inc	cx
			cmp 	cx,80
			jne	@@CopyLoopX
			pop 	bx
			inc	bx
			cmp	bx,200
			jne	@@CopyLoopY
			Inc 	Plane
			cmp   Plane,4
			jne   @@BitLoop
			pop	es
			pop	ds

	pop   bp               	;Get registers from stack
	ret   4               	;Return to caller, remove
									;arguments from stack

TransferScrn endp

code ends
end