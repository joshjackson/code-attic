	uses    Graph,Wad,Things;

	var     WDir:PWadDirectory;
			T:PWadThing;
			gd,gm:integer;

	begin
		{Initalize WAD directory}
		WDir:=New(PWadDirectory, Init('D:\DOOM\DOOM.WAD'));
		{Initalize WadThing (an imp)}
		T:=New(PWadThing, Init(WDir, 'CYBRA1  '));

		gd:=InstallUserDriver('BGI256',Nil);
		{640x480x256}
		gm:=2;
		{Initialize Graphics}
		InitGraph(gd,gm,'');

		{Set the Play Palette}
		WDir^.SetWadPalette(0);

		{Draw the thing 2:1 scale at coords 5,5}
		T^.Draw(50,5,5);

		{Wait for the ENTER key}
		readln;

		{Restore the palette}
		WDir^.RestorePalette;

		{Shut down graphics}
		CloseGraph;

		{Clean up the heap}
		Dispose(T, Done);
		Dispose(WDir, Done);
	end.
