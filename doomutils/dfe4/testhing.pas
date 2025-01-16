	uses    Graph,Wad,Things;

	var     DDir,WDir:PWadDirectory;
			T:PWadThing;
			gd,gm:integer;

	begin
		{Initalize WAD directory}
		WDir:=New(PWadDirectory, Init('D:\DOOM\DOOM.WAD'));
		DDir:=New(PWadDirectory, Init('D:\DOOM\DOOM.WAD'));
		{Initalize WadThing (an imp)}

		gd:=InstallUserDriver('BGI256',Nil);
		{640x480x256}
		gm:=2;
		{Initialize Graphics}
		InitGraph(gd,gm,'D:\BP\BGI');

		{Set the Play Palette}
		DDir^.SetWadPalette(0);
		T:=New(PWadThing, Init(WDir, 'MANFA1  '));

		{Draw the thing 2:1 scale at coords 5,5}
		T^.Draw(200,5,5);

		{Wait for the ENTER key}
		readln;

		{Restore the palette}
		DDir^.RestorePalette;

		{Shut down graphics}
		CloseGraph;

		{Clean up the heap}
		Dispose(T, Done);
		Dispose(WDir, Done);
		Dispose(DDir,Done);
	end.
