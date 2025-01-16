unit DFEComm;

interface

uses Dos,WadDecl;

const	dcTerminate	=	0;
		dcLaunchDoom=	1;
		dcRestart	=	2;
		dcIPXSend	=  3;
		dcIPXRec		=  4;
		dcViewMaps	= 	5;
		dcTagAssoc	=  6;
		dcItemLoc	=  7;

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

Procedure SetTerminateCommand(ErrCode:byte);
Procedure SetRestartCommand;
Procedure SetLaunchCommand(S:String);
Procedure SetIPXFERcommand(Send:boolean;FSpecs,OldDir:string);
Procedure DFELaunch(PrgName:String);
Procedure SetMapCommands(Cmd:byte;WadName:PathStr;LevelName:ObjNameStr;M1,M2:word);

var	IPXInstalled:boolean;
		CommBuff:PDFECommBlock;

implementation

{$IFNDEF DPMI}
	uses CRT;
{$ELSE}
	uses WINAPI,CRT;
{$ENDIF}

var	Regs:Registers;
		LongAddr:longint;
		CommSeg,CommOfs:word;

Procedure SetLaunchCommand(S:String);

	begin
		CommBuff^.Command:=dcLaunchDoom;
		CommBuff^.RunCmd:=S;
	end;

Procedure SetTerminateCommand(ErrCode:byte);

	begin
		CommBuff^.Command:=dcTerminate;
		CommBuff^.ExitCode:=ErrCode;
	end;

Procedure SetRestartCommand;

	begin
		CommBuff^.Command:=dcRestart;
	end;

Procedure SetIPXFERcommand(Send:boolean;FSpecs,OldDir:string);

	begin
		CommBuff^.PathStr:=OldDir;
		if Send then begin
			CommBuff^.Command:=dcIPXsend;
			CommBuff^.RunCmd:=FSpecs;
		 end
		else
			CommBuff^.Command:=dcIPXrec;
	end;

Procedure SetMapCommands(Cmd:byte;WadName:PathStr;LevelName:ObjNameStr;M1,M2:word);

	begin
		CommBuff^.Command:=Cmd;
		CommBuff^.WadName:=WadName;
		CommBuff^.LevelName:=LevelName;
		CommBuff^.ViewerMask:=M1;
		CommBuff^.ThingMask:=M2;
	end;

Procedure DFELaunch(PrgName:string);

	var	Temp21:pointer;

	begin
		SwapVectors;
		GetIntVec($21, Temp21);
		SetIntVec($21, SaveInt21);
		Exec(PrgName,'');
		SetIntVec($21, Temp21);
		SwapVectors;
		SetTerminateCommand(1);
	end;

Function IsLoaderInstalled:boolean; assembler;

	asm
		mov ax,$F400
		int $21
		cmp al,$80
		jne @@1
		mov al,True
		jmp @@2
	@@1:
		mov al,False
	@@2:
	end;

begin
{$IFNDEF DEBUG}
		if not IsLoaderInstalled then begin
			writeln('This program is for internal use by the DOOM Front End.');
			halt(1);
		end;
		asm
			pusha
			mov ax,$F401
			int $21
			mov CommSeg,bx
			mov CommOfs,di
			popa
		end;
	{$IFDEF DPMI}
		LongAddr:=(Longint(CommSeg) shl 4);
		CommSeg:=AllocSelector(0);
		SetSelectorBase(CommSeg, LongAddr);
		SetSelectorLimit(CommSeg, 64000);
	{$ENDIF}
		CommBuff:=Ptr(CommSeg, CommOfs);
		IPXInstalled:=CommBuff^.IPXInstalled;
{$ELSE}
		New(CommBuff);
{$ENDIF}
end.