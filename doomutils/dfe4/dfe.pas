{$IFDEF DPMI}
	Halt Right Here!!
{$ENDIF}

{$M 16384,0,0}
{$F+}

Uses CRT,DOS,Memory,WadDecl,Swap,IPXFer,Timer;

const	dcTerminate	=	0;
		dcLaunchDoom=	1;
		dcRestart	=	2;
		dcIPXSend	=  3;
		dcIPXRec		=  4;
		dcViewMaps	= 	5;

		FanFare:boolean = False;

Type	PDFECommBlock=^TDFECommBlock;
		TDFECommBlock=record
			Command:word;
			  case Word of
				 0: (ExitCode: byte);
				 1: (RunCmd: string;
					  PathStr: string);
				 2: (IPXInstalled:boolean;
					  StartupMsg:string);
				 3: (WadName:PathStr;
					  LevelName:ObjNameStr;
					  ViewerMask:word;
					  ThingMask:word);
		end;
		IntVect=Procedure;

var	CommSeg,CommOfs:word;
		BuffSeg,BuffOfs:word;
		OldIntVect:Pointer;
		Temp21Vect:pointer;
		OldExitProc:pointer;
		CommBuff:TDFECommBlock;
		SoundBuff:pointer;

Procedure DFE_ISR; Far; Assembler;

	asm
		jmp @@0

	@@TmpAddr: dd 00000000

	@@0:
		cmp 	ah,$F4
		je    @@1
		push ax
		push cx
		push si
		push di
		push ds
		push es
		push cs
		pop es
		mov ax,seg OldIntVect
		mov ds,ax
		mov si,offset OldIntVect
		mov di,offset @@TmpAddr
		mov cx,2
		rep movsw
		pop es
		pop ds
		pop di
		pop si
		pop cx
		pop ax
		jmp dword ptr cs:[@@TmpAddr]
		iret
	@@1:
		cmp al,0
		jne @@2
		mov al,$80
		iret
	@@2:
		cmp al,1
		jne @@3
		push ds
		mov ax,seg CommSeg
		mov ds,ax
		mov bx,CommSeg
		mov di,CommOfs
		pop ds
		iret
	@@3:
		mov al,$FF
		iret
	end;

Procedure DFEExitProc;

	begin
		ExitProc:=OldExitProc;
		SetIntVec($21, OldIntVect);
		if FanFare then begin
			Writeln('Thanks for using the DOOM Front End v3.99b - Beta Release');
			writeln;
			writeln('written by:  Joshua Jackson         jsoftware@delphi.com');
			writeln;
			writeln('Jackson Software');
			writeln('10506 Bayard Road');
			writeln('Minerva, OH 44657');
			writeln('(216) 868-1169');
			writeln;
			writeln('The latest release of DFE is available at the following location:');
			writeln;
			writeln('The official DOOM FTP site: infant2.sphs.indiana.edu');
			writeln('                            /pub/doom/misc/');
			writeln;
			writeln('Or write the EMAIL address above for a UUEncoded copy.');
			writeln;
			writeln('Please send suggestions, comments, bug reports, etc to the internet');
			writeln('address listed above, or leave mail for Joshua Jackson on Software Creations.');
			writeln;
			writeln('If you find this program useful, please send $10 to the above address for');
			writeln('registration.');
		 end
		else begin
			writeln('If you are having trouble getting DFE to function properly, please contact');
			writeln('me at:');
			writeln;
			writeln('Internet:  jsoftware@delphi.com');
			writeln;
			writeln('Snail:     Jackson Software');
			writeln('           10506 Bayard Rd.');
			writeln('           Minerva, OH  44657');
			writeln;
			writeln('Phone:     (216) 868-1169');
		end;
	end;

Procedure InitSystem;

	begin
		CommSeg:=Seg(CommBuff);
		CommOfs:=Ofs(CommBuff);
		GetIntVec($21, OldIntVect);
		SetIntVec($21, @DFE_ISR);
		OldExitProc:=ExitProc;
		ExitProc:=@DFEExitProc;
	end;

Procedure LaunchSystem;

	var fsr:SearchRec;

	begin
		{$IFNDEF DEBUG}
			FindFirst('DFESYS\DFESYS.EXE',anyfile,fsr);
			if DosError<>0 then begin
				writeln('DFE Loader Error: DFESYS\DFESYS.EXE not found.');
				writeln;
				halt(1);
			end;
		{$ENDIF}
		if IsIpxInstalled then
			CommBuff.IPXInstalled:=True
		else
			CommBuff.IPXInstalled:=False;
		CommBuff.StartupMsg:='Well, this much must be working!';
		SwapVectors;
		GetIntVec($21, Temp21Vect);
		SetIntVec($21, SaveInt21);
		{$IFNDEF DEBUG}
			Exec('DFESYS\DFESYS.EXE','');
		{$ELSE}
			Exec('D:\BP\UNITS\DFESYS.EXE','');
		{$ENDIF}
		SetIntVec($21, Temp21Vect);
		SwapVectors;
	end;

Procedure ExecuteCommand;

	begin
		Case CommBuff.Command of
			dcTerminate:begin
								FanFare:=True;
								halt(CommBuff.ExitCode);
							end;
			dcRestart:exit;
			dcLaunchDoom:begin
								DoneTimer;
								ExecPrg(CommBuff.RunCmd);
								InitTimer;
							 end;
		else begin
				writeln('DFE Loader Error: Invalid System Command: ',CommBuff.Command);
				halt(1);
			end;
		end;
	end;

begin
	writeln('DOOM Front End v3.99b - Beta Release');
	writeln('by: Jackson Software');
	delay(1000);
	clrscr;
	InitSystem;
	repeat
		LaunchSystem;
		ExecuteCommand;
	until false;
end.
