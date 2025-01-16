{*********************************************************************}
{*                             SNAPSHOT!                             *}
{*-------------------------------------------------------------------*}
{*    Task           : Takes a 'SNAP SHOT' of a 320x200/256 screen   *}
{*                     when card is set for paging mode              *}
{*-------------------------------------------------------------------*}
{*    Author         : Joshua Jackson                                *}
{*    Developed on   : 01/31/94                                      *}
{*    Last update    : 02/04/94                                      *}
{*********************************************************************}

program SNAPSHOT;

uses DOS, CRT;                                { Add DOS and CRT units }

{$M 3072, 0, 5120}     { Reserve 3K for the stack and 5K for the heap }
{$L snpshota}                                        { Timer Routines }
{$L v3220pa}                                    {Screen Read Routines }

procedure TsrInit( PrcPtr   : word;   { Offset address: TSR procedure }
						 ResPara  : word   { Number of pars. to be reserved }
					  ) ; external ;                           { ID string }
function  TsrIsInst( i2F_fctno : byte ) : boolean ; external ;
procedure TsrUnInst; external;                        { Uninstall TSR }
procedure TsrSetPtr( Offset : word ); external;
function  TsrCanUnInst : boolean; external;
Function  GetPix(x,y:integer):byte; external;
Procedure SetPage(Page:byte); external;

{$F+}                                  { FAR procedures and functions }
procedure TsrCall ; external;
procedure TsrSetHotKey( KeyMask  : word;         { Hotkey (see CONST) }
								ScCode   : byte                   { Scan code }
							 ) ; external;
{$F-}

{-- Constants --------------------------------------------------------}

		{-- Scan codes for different keys -------------------------}

const SC_ESC             = $01;      SC_Z               = $2C;
		SC_1               = $02;      SC_X               = $2D;
		SC_2               = $03;      SC_C               = $2E;
		SC_3               = $04;      SC_V               = $2F;
		SC_4               = $05;      SC_B               = $30;
		SC_5               = $06;      SC_N               = $31;
		SC_6               = $07;      SC_M               = $32;
		SC_7               = $08;      SC_COMMA           = $33;
		SC_8               = $09;      SC_PERIOD          = $34;
		SC_9               = $0A;      SC_SLASH           = $35;
		SC_0               = $0B;      SC_SHIFT_RIGHT     = $36;
		SC_HYPHEN          = $0C;      SC_ASTERISK        = $37;
		SC_EQUALS          = $0D;      SC_ALT             = $38;
		SC_BACKSPACE       = $0E;      SC_SPACE           = $39;
		SC_TAB             = $0F;      SC_CAPS            = $3A;
		SC_Q               = $10;      SC_F1              = $3B;
		SC_W               = $11;      SC_F2              = $3C;
		SC_E               = $12;      SC_F3              = $3D;
		SC_R               = $13;      SC_F4              = $3E;
      SC_T               = $14;      SC_F5              = $3F;
      SC_Y               = $15;      SC_F6              = $40;
      SC_U               = $16;      SC_F7              = $41;
      SC_I               = $17;      SC_F8              = $42;
		SC_O               = $18;      SC_F9              = $43;
      SC_P               = $19;      SC_F10             = $44;
      SC_LBRACKET        = $1A;      SC_NUM_LOCK        = $45;
      SC_RBRACKET        = $1B;      SC_SCROLL_LOCK     = $46;
      SC_ENTER           = $1C;      SC_CURSOR_HOME     = $47;
		SC_CONTROL         = $1D;      SC_CURSOR_UP       = $48;
      SC_A               = $1E;      SC_CURSOR_PG_UP    = $49;
      SC_S               = $1F;      SC_NUM_MINUS       = $4A;
		SC_D               = $20;      SC_CURSOR_LEFT     = $4B;
      SC_F               = $21;      SC_NUM_5           = $4C;
      SC_G               = $22;      SC_CURSOR_RIGHT    = $4D;
      SC_H               = $23;      SC_NUM_PLUS        = $4E;
      SC_J               = $24;      SC_CURSOR_END      = $4F;
      SC_K               = $25;      SC_CURSOR_DOWN     = $50;
      SC_L               = $26;      SC_CURSOR_PG_DOWN  = $51;
      SC_SEMICOLON       = $27;      SC_INSERT          = $52;
      SC_APOSTROPHE      = $28;      SC_DELETE          = $53;
      SC_GRAVE           = $29;      SC_SYS_REQUEST     = $54;
      SC_SHIFT_LEFT      = $2A;      SC_F11             = $57;
      SC_BACKSLASH       = $2B;      SC_F12             = $58;
		SC_NOKEY           = $80;               { No more keys }

      {-- Bit masks for the different toggle keys --------------------}

      LSHIFT =     1;                                { Left SHIFT key }
		RSHIFT =     2;                               { Right SHIFT key }
      CTRL   =     4;                                      { CTRL key }
      ALT    =     8;                                       { ALT key }
		SYSREQ =  1024;                { SYS-REQ key (AT keyboard only) }
      BREAK  =  4096;                                     { BREAK key }
      NUM    =  8192;                                  { NUM LOCK key }
      CAPS   = 16384;                                 { CAPS LOCK key }
      INSERT = 32768;                                    { INSERT key }

      I2F_CODE   = $C4;                      { Function number INT 2F }
      I2F_FCT_0  = $AA;                 { Code for INT 2F, function 0 }
      I2F_FCT_1  = $BB;                 { Code for INT 2F, function 1 }

{-- Type declarations ------------------------------------------------}

	  {-- Declaration of procedure and function types which copy     --}
     {-- procedures and functions in the already installed copy     --}
	  {-- of the TSR.                                                --}

Type
	  WoAPrcK  = procedure;              { Procedure without arguments }
	  SHKPrcK = procedure( KeyMask : word;              { TsrSetHotkey }
									ScCode  : byte );
	  PPtrT  = record       { Union for creating the procedure pointer }
					 case integer of
						1 : ( WoAPrc  : WoAPrcK  );
						2 : ( SHKPrc : SHKPrcK );
				  end;
	  PB=array[1..768] of byte;

const Call : PPtrT = ( WoAPrc : TsrCall );

{-- Global variables -------------------------------------------------}

var ATimes : integer;                     { Number of TSR activations }
	 SnapPath:string;
	 SnapDelay:word;
	 PalBuff:PB;

{*********************************************************************}
{* ResPara: Calculates the number of paragraphs which must be        *}
{*          allocated for the program.                               *}
{* Input   : None                                                    *}
{* Output  : The number of paragraphs to be reserved                 *}
{*********************************************************************}

function ResPara : word;

begin
  {-- Compute the number of bytes needed, using the proper method ----}

  {$ifdef VER50}                                     { Turbo Ver. 5.0 }
	 ResPara := Seg(FreePtr^)+$1000-PrefixSeg;  { Number of paragraphs }
  {$endif}

  {$ifdef VER55}                                     { Turbo Ver. 5.5 }
	 ResPara := Seg(FreePtr^)+$1000-PrefixSeg;  { Number of paragraphs }
  {$endif}

  {$ifdef VER60}                                     { Turbo Ver. 6.0 }
	 ResPara := Seg(HeapEnd^)-PrefixSeg;
  {$endif}

  {$ifdef VER70}                                     { Turbo Ver. 7.0 }
	 ResPara := Seg(HeapEnd^)-PrefixSeg;
  {$endif}
end;

{*********************************************************************}
{* ParamGetHotKey: Checks command line parameters for the hotkey     *}
{*                 switch (/T) and implements these keys.            *}
{* Input   : KEYMASK = Variable for storing the key mask             *}
{*           SCCODE  = Variable for storing the scan code            *}
{* Output  : TRUE if the hotkeys are supported, otherwise FALSE      *}
{* Info    : - Parameters not beginning with /T are ignored as       *}
{*             parameters, but may be handled as other routines      *}
{*           - If no parameter exists for /T, SC_NOKEY is placed in  *}
{*             the appropriate variable.                             *}
{*********************************************************************}

function ParamGetHotKey( var KeyMask : word;
								 var ScCode  : byte ) : boolean;

type ToggleKey = record
						 Name : string[6];
						 WVal : word;
					  end;

const TogKeys : array[ 1..9 ] of ToggleKey =
					  ( ( Name: 'LSHIFT'; WVal : LSHIFT ),
						 ( Name: 'RSHIFT'; WVal : RSHIFT ),
						 ( Name: 'CTRL';   WVal : CTRL   ),
						 ( Name: 'ALT';    WVal : ALT    ),
						 ( Name: 'SYSREQ'; WVal : SYSREQ ),
						 ( Name: 'BREAK';  WVal : BREAK  ),
						 ( Name: 'NUM';    WVal : NUM    ),
						 ( Name: 'CAPS';   WVal : CAPS   ),
						 ( Name: 'INSERT'; WVal : INSERT )
						);

var i , j,                                             { Loop counter }
	 code,                                  { For scan code conversion }
	 dummy : integer;                         { Error variable for VAL }
	 arg   : string;                                 { Argument access }

begin
  KeyMask := 0;
  ScCode := SC_NOKEY;

  for i := 1 to ParamCount do                  { Execute command line }
	 begin
		arg := ParamStr(i);                              { Get argument }
		for j := 1 to length(arg) do     { Convert string to upper case }
		  arg[j] := upcase(arg[j]);
		if ( arg[1] = '/' ) and ( arg[2] = 'T' ) then
		  begin                                     { /T argument found }
			 delete( arg, 1, 2 );              { Remove '/T' from string }
			 val( arg, code, dummy );      { Convert remainder to binary }
			 if ( dummy = 0 ) then                    { Conversion O.K.? }
				begin                                               { Yes }
				  if ( code > 0 ) and ( code < 128 ) then   { Valid code? }
					 ScCode := Code                        { Yes --> Store }
				  else
					 begin                                  { Invalid code }
						ParamGetHotKey := false;
						exit;                     { End function with FALSE }
					 end;
				end
			 else    { If not a number, must be the name of a toggle key }
				begin
				  j := 1;                       { Search toggle key array }
				  while ( j < 10 ) and ( arg <> TogKeys[j].Name ) do
					 j := j + 1;
				  if ( j < 10 ) then                        { Name found? }
					 KeyMask := KeyMask or TogKeys[j].WVal  { Yes --> Flag }
				  else
					 begin          { No --> Neither number nor toggle key }
						ParamGetHotKey := false;
						exit;                     { End function with FALSE }
					 end;
				end;
		  end;
	 end;
  ParamGetHotKey := true;               { If everything checks out    }
end;                                    { so far, parameters are O.K. }

{*********************************************************************}
{* EndTPrc: Called by the assembler module when the TSR program is   *}
{*          uninstalled.                                             *}
{* Input   : None                                                    *}
{* Output  : None                                                    *}
{* Info    : This procedure must be a FAR procedure to permit access *}
{*           from the installed copy of the TSR.                     *}
{*********************************************************************}

{$F+}

procedure EndTPrc;

begin
  TextBackground( Black );                          { Dark background }
  TextColor( LightGray );                                { Light text }
  writeln('The TSR was called ', ATimes, ' times.');
end;

{$F-}

{*********************************************************************}
{* Tsr: Called by the assembler module                               *}
{* Input   : None                                                    *}
{* Output  : None                                                    *}
{* Info    : This procedure must be in the main program and may not  *}
{*           be turned into a FAR procedure by the $F+ compiler      *}
{*           directive.                                              *}
{*********************************************************************}

{$F-}                                    { Don't make a FAR procedure }

procedure Tsr;

type FB=array[0..319] of byte;


var PdKey  : char;
	 TempStr:string;
	 BitPlane:byte;
	 f:file;
	 b:byte;
	 FileBuff:FB;
	 t,x:word;
	 Regs:Registers;

begin
	Regs.ax:=$0f00;
	Intr($10,Regs);
	if (Regs.ax and $FF) = $13 then begin
		inc( ATimes );                             { Increment call counter }
		Str(ATimes,TempStr);
		TempStr:=SnapPath+'BP1'+TempStr+'.256';
		sound(1000);
		delay(35);
		nosound;
		SetPage(0);
		assign(f,TempStr);
		rewrite(f,1);
		BlockWrite(f,PalBuff[1],768);
		{Seek(f,768);}
		for t:=0 to 199 do begin
			for x:=0 to 319 do begin
				FileBuff[x]:=GetPix(x,t);
			end;
			BlockWrite(f,FileBuff[1],320);
		end;
		close(f);
		Str(ATimes,TempStr);
		TempStr:=SnapPath+'BP2'+TempStr+'.256';
		sound(1000);
		delay(35);
		nosound;
		SetPage(1);
		assign(f,TempStr);
		rewrite(f,1);
		BlockWrite(f,PalBuff[1],768);
		Seek(f,768);
		for t:=0 to 199 do begin
			for x:=0 to 319 do begin
				FileBuff[x]:=GetPix(x,t);
			end;
			BlockWrite(f,FileBuff[1],320);
		end;
		close(f);
	end;
end;

Procedure SetDelay;

	var Regs:Registers;

	begin
		Regs.ax:=$C4CC;
		Regs.cx:=(SnapDelay * 10) div 182;
		Intr($2F,Regs);
	end;

{$I-}
Procedure ReadConfig;

	var cf:text;
		 t:integer;
		 TempStr:String;
		 rc:word;

	begin
		assign(cf,'snapshot.cfg');
		reset(cf);
		if IOResult<>0 then begin
			writeln('TsrInit_ReadConfig: Could not access SNAPSHOT.CFG');
			halt;
		end;
		readln(cf,SnapPath);
		readln(cf,TempStr);
		Val(TempStr,SnapDelay,rc);
		if rc<>0 then begin
			writeln('TsrInit_ReadConfig: Error converting SnapDelay');
			halt;
      end;
      SetDelay;
	end;
{$I-}

{*********************************************************************}
{**                           MAIN PROGRAM                          **}
{*********************************************************************}

var KeyMask : word;
    ScCode : byte;

begin
  writeln('SNAPSHOT! (c) 1994 by Jackson Software');
  if not ParamGetHotKey( KeyMask, ScCode ) then
	 begin                          { Error in command line parameters }
      writeln( 'Illegal command line parameters');
      exit;
	 end;

  {-- Command line parameters were O.K. ------------------------------}

  if ( TsrIsInst( I2F_CODE ) = FALSE ) then         { Program already }
																	 { installed?      }
	 begin                                                        { No }
		ATimes := 0;                  { Program hasn't been enabled yet }
		ReadConfig;
		writeln( 'TSR now installed. ' );
		if ( KeyMask = 0 ) and ( ScCode = SC_NOKEY ) then { No params.? }
		  begin                               { No --> Default is ALT-H }
			 TsrSetHotkey( ALT, SC_R );
			 writeln( 'Press <ALT> + R to Reset');
		  end
		else                             { Install user-defined hotkeys }
		  TsrSetHotkey( KeyMask, ScCode );
		TsrInit( Ofs(Tsr), ResPara );                 { Install program }
	 end
  else                                    { Program already installed }
	 begin
		if ( KeyMask = 0 ) and ( ScCode = SC_NOKEY ) then { No params.? }
        begin                               { No --> Try uninstalling }
          if TsrCanUnInst then
				begin
              TsrSetPtr(ofs(EndTPrc));           { Call End procedure }
              Call.WoAPrc;                       { in installed copy  }
              TsrUnInst;
              writeln( 'Program now uninstalled.');
            end
          else
            writeln( 'Program cannot be uninstalled.');
        end
      else                                     { Implement new hotkey }
        begin
          writeln( 'New hotkey implemented' );
          TsrSetPtr(ofs(TsrSetHotKey));
			 Call.SHKPrc( KeyMask, ScCode );
        end
    end;
end.
