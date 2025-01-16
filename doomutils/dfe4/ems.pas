unit Ems;

interface

uses Dos;

{-- declaration of functions and procedures that can be called from  ------}
{-- other programs                                                   ------}

function  EmsGetFreePage   : integer;
function  EmsGetPtr        ( PhysPage : byte ) : pointer;
function  EmsAlloc         ( Amount : integer ) : integer;
procedure EmsMap           ( Handle, LogPage : integer; PhysPage : byte );
procedure EmsFree          ( Handle : integer );
procedure EmsRestoreMapping( Handle : integer );
procedure EmsSaveMapping   ( Handle : integer );

{-- constants, public -----------------------------------------------------}

const {--------------------------------------------- EMS error codes ------}

      EmsErrOk        = $00;   { everything o.k., no error                 }
      EmsErrSw        = $80;   { error in EMM (software)                   }
      EmsErrHw        = $81;   { EMS hardware error                        }
      EmsErrInvHandle = $83;   { invalid EMS handle                        }
      EmsErrFkt       = $84;   { invalid function called                   }
      EmsErrNoHandles = $85;   { no more handles free                      }
      EmsErrSaResMap  = $86;   { error while saving or restoring Mapping   }
      EmsErrToMany    = $87;   { more pages were requested than are        }
                               { physically available                      }
      EmsErrNoPages   = $88;   { more pages requested than are free        }
      EmsErrNullPages = $89;   { null page requested                       }
      EmsErrLogPInv   = $8A;   { logical page does not belong to handle    }
      EmsErrPhyPInv   = $8B;   { invalid physical page number              }
      EmsErrMapFull   = $8C;   { Mapping memory region is full             }
      EmsErrMapSaved  = $8D;   { Mapping already saved                     }
      EmsErrMapRes    = $8E;   { attempt to restore Mapping without        }
                               { previously saving it                      }

{-- global variables accessible to other programs -------------------------}

var EmsInst    : boolean;      { contains TRUE if EMS memory is available }
    EmsPages    : integer;                     { total number of EMS pages }
    EmsVersion,                  { EMS version number (32 = 3.2, 40 = 4.0) }
    EmsError    : byte;                          { stores EMM error number }

implementation

{-- constants internal to this program ------------------------------------}

const EMS_INT = $67;              { interrupt vector for accessing the EMM }

{-- global variables internal to this module ------------------------------}

var EmsFrameSeg : word;           { segment address of the EMS page frames }

{***************************************************************************
*  EmsInit : Initialializes the unit                                       *
***************************************************************************}

procedure EmsInit;

type EmmName  = array [1..8] of char; { name of the EMM from driver header }
     EmmNaPtr = ^EmmName;               { pointer to name in driver header }

const Name : EmmName = 'EMMXXXX0';                    { name of EMS driver }

var Regs  : Registers;            { processor registers for interrupt call }

begin
  {-- start by determining if EMS memory and the proper EMM are installed -}

  Regs.ax := $35 shl 8 + EMS_INT;              { get interrupt vector with }
  msdos( Regs );                               { DOS function $35          }

  EmsInst := ( EmmNaPtr(Ptr(Regs.ES,10))^ = Name );  { compare driver name }

  if ( EmsInst ) then                               { is an EMM installed? }
    begin                                                            { yes }

      {-- get total number of EMS pages -----------------------------------}
      Regs.AH := $42;             { function no. for "get number of pages" }
      intr( EMS_INT, Regs );                                    { call EMM }
      EmsPages := Regs.DX;                   { store total number of pages }

      {-- get segment address of EMS page frame ---------------------------}
      Regs.AH := $41;  { Function no. for "get segment add. of page frame" }
      intr( EMS_INT, Regs );                                    { call EMM }
      EmsFrameSeg := Regs.BX;                      { store segment address }

      {-- get version number of EMM ---------------------------------------}
      Regs.AH := $46;          { function no. for "get EMM version number" }
      intr( EMS_INT, Regs );                                    { call EMM }
      EmsVersion := ( Regs.AL and 15 ) + ( Regs.AL shr 4 ) * 10;

      EmsError := EmsErrOk;                                { no errors yet }

    end;
end;

{***************************************************************************
*  EmsGetPtr : returns a pointer to one of the four physical pages of the  *
*              EMS page frame                                              *
**------------------------------------------------------------------------**
*  Input   : PhysPage = number of the physical page                        *
*  Output  : pointer to this page                                          *
***************************************************************************}

function EmsGetPtr( PhysPage : byte ) : pointer;

begin
  EmsGetPtr := ptr( EmsFrameSeg, PhysPage shl 14 );
end;

{***************************************************************************
*  EmsGetFreePage : gets the number of free EMS pages (1 page = 16K)       *
**------------------------------------------------------------------------**
*  Output  : the number of free pages                                      *
***************************************************************************}

function EmsGetFreePage : integer;

var Regs : Registers;             { processor registers for interrupt call }

begin
  Regs.AH := $42;                 { function no. for "get number of pages" }
  intr( EMS_INT, Regs );                                        { call EMM }
  EmsGetFreePage := Regs.BX;                 { return number of free pages }
end;
{***************************************************************************
*  EmsAlloc : allocates a given number of EMS pages                        *
**------------------------------------------------------------------------**
*  Input   : Amount = number of pages to allocate                          *
*  Output  : handle for later access to the allocated pages                *
*  Info    : if an error occurs, the variable EmsError will contain a      *
*            value not equal to 0 (an error code) after the function call  *
***************************************************************************}

function EmsAlloc( Amount : integer ) : integer;

var Regs : Registers;             { processor registers for interrupt call }

begin
  Regs.AH := $43;                      { function no. for "allocate pages" }
  Regs.BX := Amount;                     { number of pages is passed to BX }
  intr( EMS_INT, Regs );                                        { call EMM }
  EmsAlloc := Regs.DX;                        { the handle is passed to DX }
  EmsError := Regs.AH;                                            { error? }
end;
{***************************************************************************
* EmsMap : loads one of the allocated logical pages into one of the 4      *
*           physical pages of the EMS page frame                           *
*-------------------------------------------------------------------------**
*  Input   : Handle   = handle that identifies the allocated page          *
*            LogPage  = number of the logical page to be loaded            *
*            PhysPage = the physical page number                           *
*  Info    : if an error occurs, the variable EmsError will contain a      *
*            value other than 0 (error code) after the function call       *
***************************************************************************}

procedure EmsMap( Handle, LogPage : integer; PhysPage : byte );

var Regs : Registers;             { processor registers for interrupt call }

begin
  Regs.AH := $44;            { function no. for "map expanded memory page" }
  Regs.DX := Handle;                { load the parameters in the registers }
  Regs.BX := LogPage;
  Regs.Al := PhysPage;
  intr( EMS_INT, Regs );                                        { call EMM }
  EmsError := Regs.AH;                                            { error? }
end;

{***************************************************************************
*  EmsFree : frees EMS pages previously allocated with EmsAlloc            *
**------------------------------------------------------------------------**
*  Input   : Handle = the handle under which the pages were allocated      *
*  Info    : if an error occurs, the variable EmsError will contain a      *
*            value other than 0 (error code) after the function call       *
***************************************************************************}

procedure EmsFree( Handle : integer );

var Regs : Registers;             { processor registers for interrupt call }

begin
  Regs.AH := $45;             { function number for "release handle & EMS" }
  Regs.DX := Handle;                      { load parameter in the register }
  intr( EMS_INT, Regs );                                        { call EMM }
  EmsError := Regs.AH;                                            { error? }
end;

{***************************************************************************
* EmsSaveMapping : saves a mapping of the current logical EMS pages in     *
*                   the four physical pages of the EMS page frame          *
**------------------------------------------------------------------------**
*  Input   : Handle = the handle under which the pages were allocated      *
*  Info    : if an error occurs, the variable EmsError will contain a      *
*            value other than 0 (error code) after the function call       *
***************************************************************************}

procedure EmsSaveMapping( Handle : integer );

var Regs : Registers;             { processor registers for interrupt call }

begin
  Regs.AH := $47;                     { function number for "save mapping" }
  Regs.DX := Handle;                  { load the parameter in the register }
  intr( EMS_INT, Regs );                                        { call EMM }
  EmsError := Regs.AH;                                            { error? }
end;

{***************************************************************************
*  EmsRestoreMapping : retrieves a mapping previously saved with the       *
*                      procedure EmsSaveMapping                            *
**------------------------------------------------------------------------**
*  Input   : Handle = the handle under which the pages were allocated      *
*  Info    : if an error occurs, the variable EmsError will contain a      *
*            value other than 0 (error code) after the function call       *
***************************************************************************}

procedure EmsRestoreMapping( Handle : integer );

var Regs : Registers;             { processor registers for interrupt call }

begin
  Regs.AH := $48;                  { function number for "restore mapping" }
  Regs.DX := Handle;                      { load parameter in the register }
  intr( EMS_INT, Regs );                                        { call EMM }
  EmsError := Regs.AH;                                            { error? }
end;

{**----------------------------------------------------------------------**}
{** Starting code of the unit                                            **}
{**----------------------------------------------------------------------**}

begin
  EmsInit;                                           { initialize the unit }
end.

