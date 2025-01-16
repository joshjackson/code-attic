{$F-}
unit swap;

interface

uses DOS, Ems, WadDecl, Crt;

function ExecPrg    ( Command : string ) : byte;
function ExecCommand( Command : string ) : byte;

const SwapPath : string[ 80 ] = 'C:\DFE_SWAP.FIL';

		SwapErrOk       = 0;                     { no error, everything O.K. }
		SwapErrStore    = 1;      { Turbo Pascal program could not be stored }
		SwapErrNotFound = 2;                             { program not found }
		SwapErrNoAccess = 5;                      { access to program denied }
		SwapErrNoRAM    = 8;                             { not enough memory }

		AllowEMSswap:boolean = True;

implementation

{$L swapa}                                      { include assembler module }

Procedure PrepSwapFile(FLen:Longint;S:String);

	var	f:file;
			p:longint;
			B:Pointer;
			Regs:Registers;

	begin
		s:=s+#00;
		Regs.AX:=$4301;
		Regs.CX:=0;
		Regs.DS:=Seg(S);
		Regs.DX:=Ofs(S) + 1;
		MsDos( Regs );
		Regs.AH := $41;                 { function number for "erase file" }
		Regs.DS:=Seg(S);
		Regs.DX:=Ofs(S) + 1;
		MsDos( Regs );
		assign(f, S);
		rewrite(f,1);
		for p:=1 to (FLen div 10240) do
			BlockWrite(F, B^, 10240);
		BlockWrite(F, B^, FLen mod 10240);
		close(f)
	end;

function SwapOutAndExec( Command,
								 CmdPara : string;
								 ToDisk  : boolean;
								 Handle  : word;
								 Len     : longint ) : byte ; external;

function InitSwapa : word ; external;


var Len : longint;                          { number of bytes to be stored }

function NewExec( CmdLine, CmdPara : string ) : byte;

var Regs,                          { processor register for interrupt call }
	 Regs1    : Registers;
	 SwapFile : string[ 81 ];             { name of the temporary Swap-file }
	 ToDisk   : boolean;                 { store on disk or in EMS-memory ? }
	 Handle   : integer;                               { EMS or file handle }
	 Pages    : integer;                     { number of EMS pages required }

begin

  ToDisk := TRUE;                                          { store on disk }
  if AllowEMSswap then begin
	  if ( EmsInst ) then                                  { is EMS available? }
		 begin                                                            { Yes }
			Pages  := ( Len + 16383 ) div 16384;        { determine pages needed }
			Handle := EmsAlloc( Pages );                        { allocate pages }
			ToDisk := ( EmsError <> EmsErrOk );        { allocation successful ? }
			if not ToDisk then
			  EmsSaveMapping( Handle );                           { save mapping }
		 end;
  end;

  if ToDisk then                                    { store in EMS memory? }
	 begin                                                    { no, on disk }

		SwapFile := SwapPath;
		SwapFile[ byte(SwapFile[0]) + 1 ] := #0;
		PrepSwapFile(Len, SwapFile);
		Regs.AX := $3D02;
		Regs.CX := Hidden or SysFile;
		Regs.DS := seg( SwapFile );
		Regs.DX := ofs( SwapFile ) + 1;
		MsDos( Regs );
		if ( Regs.Flags and FCarry = 0 ) then
		  Handle := Regs.AX
		else
		  begin
			 NewExec := SwapErrStore;
			 exit;
		  end;
	 end;

	 SwapVectors;                                  { reset interrupt vectors }
	 NewExec := SwapOutAndExec( CmdLine, CmdPara, ToDisk, Handle, Len );
	 SwapVectors;                          { install Turbo-Int-Handler again }

	 if ToDisk then                                { was it stored on disk? }
		begin                                                          { yes }
		  Regs1.AH := $3E;
		  Regs1.BX := Regs.AX;
		  MsDos( Regs1 );
		  Regs.AH := $41;                 { function number for "erase file" }
		  Regs.DS:=Seg(SwapFile);
		  Regs.DX:=Ofs(SwapFile) + 1;
		  MsDos( Regs );
		end
	 else                                       { no, storage in EMS memory }
		begin
		  EmsRestoreMapping( Handle );               { restore mapping again }
		  EmsFree( Handle );            { release allocated EMS memory again }
		end;
end;

function ExecCommand( Command : string ) : byte;

var ComSpec : string;                             { command processor path }

begin
  Len := ( longint(Seg(HeapEnd^)-(PrefixSeg+$10)) * 16 ) - InitSwapa;
  ComSpec := GetEnv( 'COMSPEC' );             { get command processor path }
  ExecCommand := NewExec( ComSpec, '/c'+ Command  ); { execute prg/command }
end;

function ExecPrg( Command : string ) : byte;

const Text_Sep : set of char = [ ' ',#9,'-','/','>','<',#0,'|' ];

var i        : integer;                           { index in source string }
	 CmdLine,                                             { accepts command }
	 Para     : string;                                 { accepts parameter }

begin

  Len := ( longint(Seg(HeapEnd^)-(PrefixSeg+$10)) * 16 ) - InitSwapa;
  CmdLine := '';                                        { clear the string }
  i := 1;               { begin with the first letter in the source string }
  while not ( (Command[i] in Text_Sep) or ( i > length( Command ) ) ) do
	 begin                                      { character is not Text_Sep }
		CmdLine := CmdLine + Command[ i ];                { accept in string }
		inc( i );                    { set I to next character in the string }
	 end;

  Para := '';                                      { no parameter detected }

  while (i<=length(Command)) and ( (Command[i]=#9) or (Command[i]=' ') ) do
	 inc( i );

  while i <= length( Command ) do
	 begin
		Para := Para + Command[ i ];
		inc( i );
	 end;

  ExecPrg := NewExec( CmdLine, Para );   { execute command through NewExec }
end;

begin
  Len := ( longint(Seg(HeapEnd^)-(PrefixSeg+$10)) * 16 ) - InitSwapa;
end.