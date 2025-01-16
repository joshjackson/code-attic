.386
Code	Segment public use16
assume cs:code

public DecodeSprite

CurCol		dw	0000;
RowPtr		dw	0000;
PixelStart	dw 0000;
RowAdj		dw	0000;
SRow			db	00;

DecodeSprite Proc Near

sframe     	struc                  	;Structure for stack access
bp0        	dw ?                   	;Gets BP
ret_adr0   	dw ?                   	;Return address to caller
ySize 		dw	?                    ;Height of decoded sprite
xSize      	dw ?                    ;Width of decoded sprite
yOfs			dw ?
xOfs			dw	?
RowBuff		dd	?							;Row buffer address
PixelBuff	dd ?							;Pixel data buffer
Dest      	dd ?                   	;Destination
sframe     	ends                   	;End of structure

frame      	equ [ bp - bp0 ]       	;Address structure elements

	push  bp               	;Prepare for parameter addressing
	mov   bp,sp            	;through BP register

	push	ds
	push	es
	lgs	bx,ss:frame.RowBuff	;Initialize pointers
	lds	si,ss:frame.PixelBuff
	mov	cs:PixelStart,si	;Save pixel buffer starting offset
	les	di,ss:frame.Dest
	mov	cs:CurCol,0			;Clear pixel row counter
	mov	cs:RowPtr,0			;Clear row pointer

	mov	ax,ss:frame.xsize		;Calculate row pointer ajust value
	shl	ax,2
	add	ax,8
	mov	cs:RowAdj,ax

DecodeLoop1:
	mov	bx,cs:RowPtr
	mov	ax,gs:[bx]			;Load row pointer
	sub	ax,cs:RowAdj		;Adjust Pointer
	add	cs:RowPtr,4			;Increment row buffer index
	mov	si,cs:PixelStart	;Set SI to start of pixel data
	add	si,ax					;Set pointer into pixel buffer

	lodsb							;Get the first byte of the row data

DecodeLoop2:
	cmp	al,0FFh				;Is it the end of row marker?
	je		EndRow
	mov	cs:SRow,al			;Save the starting row
	lodsb          			;Load the pixel count
	inc	si						;Skip the junk 0
	xor 	ch,ch
	mov 	cl,al    			;Setup the pixel counter
	xor	bx,bx

DecodeLoop3:
	push 	cx
	lodsb							;Get a pixel
	push	ax
	push	bx
	add	bx,ss:frame.yofs
	add	bl,cs:SRow
	mov	ax,320
	mul	bx
	add	ax,ss:frame.xofs
	add	ax,cs:CurCol
	mov 	di,ax
	pop	bx
	pop	ax
	inc	bx
	cmp	di,64000
	jae	TooBig
	stosb

TooBig:
	pop	cx
	loop DecodeLoop3

	inc	si
	lodsb
	jmp	DecodeLoop2

EndRow:
	inc	cs:CurCol
	mov	ax,cs:CurCol
	cmp	ax,ss:frame.xsize
	jne   DecodeLoop1

	pop	es
	pop	ds
	pop   bp               	;Get registers from stack
	ret   20               	;Return to caller, remove
									;arguments from stack
DecodeSprite Endp

Code Ends
End