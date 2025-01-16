;============================================================================
;DOOM Patching Routine for DFE's ExeHacker
;
;For registered DOOM 1.2 ONLY!
;
;by: Joshua Jackson          jsoftware@delphi.com
;
;Must be assembled with MASM (TASM will error on the @F directives)
;============================================================================

code segment
assume cs:code
org 100h

begin:
	jmp   start

PatchLen dw 0000

PatchMsg db 'DFE-Patch v1.00  (For registered DOOM 1.2 ONLY)',10,13
			db 'by: Jackson Software',10,13
			db 10,13
			db 'Warning...  This file modifies the DOOM.EXE file.',10,13,10,13
			db "You should either make a backup copy of DOOM.EXE or run DFE's",10,13
			db 'Patch-Back option.',10,13,10,13
			db 'Do you wish to continue with the DOOM Patch?','$'

PatchMsg2   db 10,13,'DOOM.EXE File size in invalid!',10,13,'$'

PatchMsg3   db 10,10,13,'Patching DOOM.EXE file...',10,13,'$'
PatchMsg4   db 10,10,13,'Patch Aborted.',10,13,'$'
PatchMsg5   db 10,10,13,'Error Patching DOOM.EXE.',10,13,'$'
PatchMsg6   db 10,10,13,'DOOM.EXE Successfully Patched.',10,13,'$'

DmFileName  db 'DOOM.EXE',0
dmFileHand  dw 0000
dmFileLen   dd 580391

Start:
	push  cs
	pop   ds
	mov   ah,9
	mov   dx,offset PatchMsg
	int   21h
	mov   ah,1
	int   21h
	cmp   al,'y'
	je    DoPatch
	cmp   al,'Y'
	je    DoPatch
	mov   ah,9
	mov   dx,offset PatchMsg4
	int   21h
	mov   ax,4C01h
	int   21h

DoPatch:
	mov   ax,3D02h
	mov   dx,offset DmFileName
	int   21h
	jnc   @F
	mov   ah,9
	mov   dx,offset PatchMsg5
	int   21h
	mov   ax,4C01h
	int   21h

@@:
	mov   DmFileHand,ax
	mov   ax,4202h
	mov   bx,dmFileHand
	xor   cx,cx
	xor   dx,dx
	int   21h
	mov   si,offset DmFileLen
	mov   bx,word ptr [si]
	cmp   bx,ax
	je    @F

SizeErr:
	mov   ah,9
	mov   dx,offset PatchMsg2
	int   21h
	mov   bx,dmFileHand
	call  CloseFile
	mov   ax,4C01h
	int   21h

@@:
	mov   bx,word ptr [si+2]
	cmp   bx,dx
	jne   SizeErr

	mov   ah,9
	mov   dx,offset PatchMsg3
	int   21h
	mov   ax,PatchLen
	cmp   ax,0
	je    @F
	mov   cx,ax
	mov   si,offset Patch_Begin
	jmp   PatchLoop

@@:
	mov   ah,9
	mov   dx,offset PatchMsg5
	int   21h
	mov   bx,dmFileHand
	call  CloseFile
	mov   ax,4C01h
	int   21h

PatchLoop:
	push  cx
	mov   ax,4200h
	mov   bx,dmFileHand
	mov   dx,word ptr [si]
	mov   cx,word ptr [si+2]
	int   21h
	jnc   @F
	mov   ah,9
	mov   dx,offset PatchMsg5
	int   21h
	mov   bx,dmFileHand
	call  CloseFile
	mov   ax,4C01h
	int   21h

@@:
	mov   ah,40h
	mov   bx,dmFileHand
	mov   cx,word ptr [si+4]
	add   si,6
	mov   dx,si
	add   si,cx
	int   21h
	pop   cx
	loop  PatchLoop

	mov   ah,9
	mov   dx,offset PatchMsg6
	int   21h
	mov   ax,4C00h
	int   21h

CloseFile   Proc
	cmp   bx,0
	je    @F
	mov   ah,3Eh
	int   21h

@@:
	ret
CloseFile   Endp

Patch_Begin:

code ends
end begin

