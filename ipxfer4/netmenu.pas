{****************************************************************************
 * Program    : IPXFER v4.10  IPXFER Lan options menu                       *
 * Last Update: 04/12/96                                                    *
 * Written by : Joshua Jackson (jayjay@sal-junction.com)                    *
 * Purpose    : Lan options/configuration program                           *
 ****************************************************************************}
{$O+}
Program NetMenu;

Uses App, Dialogs, Menus, Objects, Drivers, Crt;

{$I Structs.Inc}

type	PNetMenu=^TNetMenu;
		TNetMenu=Object(TApplication)
      end;

Procedure TNetMenu.InitMenuBar;

	var	R:TRect;

	begin
		GetExtent(r);
		R.B.Y:=1;
		MenuBar:=New(PMenuBar,Init(r,NewMenu(
			NewSubMenu('~S~erver',hcNoContext,NewMenu(
            NewItem('~A~bout','',0,cmAboutServer,hcNoContext,
            NewLine(
				NewItem('~S~tatus','',0,cmDisplayStatus,hcNoContext,
				NewItem('~C~onnections','',0,cmConnectStatus,hcNoContext,
				NewItem('Shut ~D~own','Alt-X',kbAltX,cmQuit,hcNoContext,
				Nil)))))),
		Nil))));
	end;

var	NetMenuApp:TNetMenu;

begin
   writeln;
   writeln('IPXFER '+IPXFER_Version+'  Network menu system v1.0');
   writeln('Copyright (c) 1996  Jackson Software');
   Delay(2000);
   NetMenuApp.Init;
	NetMenuApp.Run;
   NetMenuApp.Done;
end.