{***************************************************************************
*  SWAPDEMO : demonstrates the use of the functions ExecCommand and        *
*             ExecPrg from the SWAP unit                                   *
**------------------------------------------------------------------------**
*  Author           : MICHAEL TISCHER                                      *
*  developed on     : 06/14/1989                                           *
*  last update on   : 03/01/1990                                           *
***************************************************************************}

program SwapDemo;

{$M 16384, 0, 655360}                   { allocate all of memory for Turbo }

uses Crt, Dos, Swap;                             { include the three units }

{***************************************************************************
*                        M A I N  P R O G R A M                            *
***************************************************************************}

var ComSpec : string;                             { command processor path }
    ErrCode : byte;                            { error code of ExecCommand }
begin
  writeln;
  writeln('лллллллллллл SWAPDEMO - (c) 1989 by Michael Tischer лллл');
  writeln;

  writeln('This is a demonstration of the SWAP unit. Setting the heap');
  writeln('size to 655,360 in the $M compiler directive ensures that');
  writeln('Turbo Pascal allocates all available memory before the');
  writeln('program starts.');
  writeln;
  writeln('On calling the EXEC procedure from Turbo, no other program');
  writeln('can be called, demonstrated by the following test call.');
  writeln;
  write( 'Exec(''\COMMAND.COM'', ''/cdir *.*'') ');

  ComSpec := GetEnv( 'COMSPEC' );             { get command processor path }
  Exec( ComSpec, '/cdir *.*' );                        { display directory }
  if ( DosError <> 0 ) then                                      { error ? }
    begin                                               { yes, as expected }
      TextColor( $0 );
      TextBackground( $F );
      write( '<--- Error, no memory!');
      TextColor( $7 );
      TextBackground( $0 );
      writeln;
      writeln;
      writeln('Now the new EXEC COMMAND procedure will execute, which ');
      writeln('places most of the memory on disk or in EMS memory. ');
      writeln;
      writeln( 'ExecCommand( ''dir *.*'' ) ');

      ErrCode := ExecCommand( 'dir *.*' );
      writeln;
      if ( ErrCode = SwapErrOk ) then
        writeln('Everything O.K. SwapDemo terminated. ')
      else
        write('Error');
        case ErrCode of                         { read & act on error code }
          SwapErrStore    : writeln(' during memory storage!');
          SwapErrNotFound : writeln(': program not found!');
          SwapErrNoAccess : writeln(': access denied!');
          SwapErrNoRam    : writeln(': program too large!');
       end;
    end;
end.
