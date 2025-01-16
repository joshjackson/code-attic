var a,b:array[1..2048] of byte;

Procedure FastMove(var S,D;Count:word);

	begin asm
		mov dx,ds
		cld
		mov bx,Count
		mov cx,bx
		and bx,1
		shr cx,1
		lds si,S
		les di,D
		rep movsw
		cmp bx,1
		jne @@Done
		movsb
	@@Done:
		mov ds,dx
	end end;

begin
	move(a,b,1);
	FastMove(a,b,2048);
end.