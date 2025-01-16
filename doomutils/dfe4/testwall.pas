	uses    Graph,Wad,Walls;

	var     WDir:PWadDirectory;
			WT:PWallTexture;
			gd,gm:integer;

	begin
		{Initalize WAD directory}
		WDir:=New(PWadDirectory, Init('D:\DOOM\XXXDOOM.WAD'));
		{Initalize Floor Texture}
		WT:=New(PWallTexture, Init(WDir, 'TITLEPIC'));

		gd:=InstallUserDriver('BGI256',Nil);
		{640x480x256}
		gm:=2;
		{Initialize Graphics}
		InitGraph(gd,gm,'\bp\bgi');

		{Set the Play Palette}
		WDir^.SetWadPalette(0);

		{Draw the texture 2:1 scale at coords 5,5}
		WT^.Draw(100,5,5);

		{Wait for the ENTER key}
		readln;

		{Restore the palette}
		WDir^.RestorePalette;

		{Shut down graphics}
		CloseGraph;

		{Clean up the heap}
		Dispose(WT, Done);
		Dispose(WDir, Done);
	end.
