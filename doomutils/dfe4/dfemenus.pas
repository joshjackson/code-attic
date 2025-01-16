{$O+,F+}
unit DFEMenus;

interface

uses 	App,Wad,WadDecl,Drivers,Objects,Dialogs,Dos,LoadPwad,Views,DFEConfg,
		StdDlg,SPlayer,MsgBox,MapStats,DFEComm,Memory;

Procedure SetLevelData(R:TRect;var SelLevel:PRadioButtons;Level:word);
Procedure SetMenuData(MenuNum:byte;var Param1,Param2:string);
Procedure MapViewMenu;
Procedure PlaySounds;
Procedure FindLineDefTags;
Procedure MapStatistics;

implementation

Procedure SetLevelData(R:TRect;var SelLevel:PRadioButtons;Level:word);

	begin
		case Level of
			1:SelLevel:=New(PRadioButtons, Init(R,
			  NewSItem('~1~ Hanger',
			  NewSItem('~2~ Nuclear Plant',
			  NewSItem('~3~ Toxin Refinery',
			  NewSItem('~4~ Command Control',
			  NewSItem('~5~ Phobos Lab',
			  NewSItem('~6~ Central Processing',
			  NewSItem('~7~ Computer Station',
			  NewSItem('~8~ Phobos Anomaly',
			  NewSItem('~9~ Military Base',
			  nil)))))))))));
			2:SelLevel:=New(PRadioButtons, Init(R,
			  NewSItem('~1~ Deimos Anomaly',
			  NewSItem('~2~ Containment Area',
			  NewSItem('~3~ Refinery',
			  NewSItem('~4~ Deimos Lab',
			  NewSItem('~5~ Command Center',
			  NewSItem('~6~ Halls of the Damned',
			  NewSItem('~7~ Spawning Vats',
			  NewSItem('~8~ Towel of Babel',
			  NewSItem('~9~ Fortress of Mystery',
			  nil)))))))))));
			3:SelLevel:=New(PRadioButtons, Init(R,
			  NewSItem('~1~ Hell Keep',
			  NewSItem('~2~ Slough of Despair',
			  NewSItem('~3~ Pandemonium',
			  NewSItem('~4~ House of Pain',
			  NewSItem('~5~ Unholy Cathedrial',
			  NewSItem('~6~ Mount Erebus',
			  NewSItem('~7~ Limbo',
			  NewSItem('~8~ DIS',
			  NewSItem('~9~ Warrens',
			  nil)))))))))));
		end;
	end;

Procedure SetMenuData(MenuNum:byte;var Param1,Param2:string);

	var	R:Trect;
			SelModem,SelGame,Monsters,SelSkill,Players:PCluster;
			DialNum:PInputLine;
			SelLevel:PRadioButtons;
			Dialog1,Dialog2:PDialog;
			ComPort:PCluster;
			Control,Episode:word;
			TmpStr,DmParam,ModeParam:string;
			ExtFile:PathStr;
			ExtLevelPos:byte;
			jb:byte;
			FileName: FNameStr;
			LevelNames:LevelNameArray;
			TempStr:String;

	begin
		Case MenuNum of
			1:begin
				R.Assign(2,1,30,5);
				SelGame:=New(PRadioButtons, Init(R,
				  NewSItem('~K~nee-Deep In The Dead',
				  NewSItem('~S~hores Of Hell',
				  NewSItem('~I~nferno!',
				  NewSItem('~L~oad External Wad File',
				  nil))))));
				R.Assign(20,6,60,15);
				Dialog1:=New(PDialog,Init(r,'Episodes'));
				with Dialog1^ do begin
					R.Assign(5,6,15,8);
					Insert(New(PButton,Init(R,'~O~k',cmOk,bfDefault)));
					R.Assign(25,6,35,8);
					Insert(New(PButton,Init(R,'~C~ancel',cmCancel,bfNormal)));
					Insert(SelGame);
				end;
				Control:=Desktop^.ExecView(Dialog1);
				Dispose(Dialog1,Done);
				Param1:='';
				DmParam:='';
				if Control <> cmOk then
					exit;
				Episode:=SelGame^.Value + 1;
				if Episode=4 then begin
					Control:=GetPwadName(ExtFile,27,LevelNames,SelLevel);
					if Control=cmOK then begin
						if WadResult<>wrOk then
							exit;
						Episode:=4;
						Param1:=OnePlayerPWads(True)+ExtFile+' ';
					end;
				 end
				else
					Param1:=OnePlayerPWads(True);
				if Param1='-file ' then Param1:='';
				if Control=cmOK then begin
					R.Assign(35, 4, 60, 9);
					SelSkill:=New(PRadioButtons, Init(R,
					  NewSItem('~I~''m too young to die',
					  NewSItem('~H~ey Not too Rough',
					  NewSItem('H~u~rt Me Plenty',
					  NewSItem('U~l~tra Violence',
					  NewSItem('~N~ightmare!',
					  nil)))))));
					SelSkill^.Value:=DFEDefaults.OnePlayer.Skill;
					R.Assign(35, 1, 60, 3);
					Monsters:=New(PCheckBoxes, Init(R,
					  NewSItem('No ~M~onsters',
					  NewSItem('~R~espawn',
					  nil))));
					Monsters^.Value:=DFEDefaults.OnePlayer.Monsters;
					R.Assign(2, 1, 32, 10);
					if Episode < 4 then
						SetLevelData(R,SelLevel,Episode);
					R.Assign(8,4,71,18);
					Dialog2:=New(PDialog,Init(r,'Game Options'));
					with Dialog2^ do begin
						Insert(Monsters);
						Insert(SelSkill);
						R.Assign(25,11,35,13);
						Insert(New(PButton,Init(R,'~C~ancel',cmCancel,bfNormal)));
						R.Assign(12,11,22,13);
						Insert(New(PButton,Init(R,'~O~k',cmOk,bfDefault)));
						Insert(SelLevel);
					end;
					Control:=Desktop^.ExecView(Dialog2);
					if Control=cmOk then begin
{					while Desktop^.ExecView(Dialog2)=cmOk do begin}
						if Episode < 4 then begin
							Str(Episode,TmpStr);
							DmParam:='-devparm -warp '+TmpStr+' ';
							Str(SelLevel^.Value + 1,TmpStr);
							DmParam:=DmParam+TmpStr
						 end
						else begin
							DmParam:='-devparm -warp ';
							DmParam:=DmParam+LevelNames[SelLevel^.Value+1][2]+' ';
							DmParam:=DmParam+LevelNames[SelLevel^.Value+1][4];
						end;
						Str(SelSkill^.Value + 1,TmpStr);
						DmParam:=DmParam+' -skill '+TmpStr+' ';
						if (Monsters^.Value and 1) = 1 then
							DmParam:=DmParam+'-nomonsters ';
						if (Monsters^.Value and 2) = 2 then
							DmParam:=DmParam+'-respawn';
					 end
					else
						Param1:='';
					Dispose(Dialog2, Done);
					Param1:=Param1+DmParam;
				end;
			  end;
			2:begin
				R.Assign(2,1,30,5);
				SelGame:=New(PRadioButtons, Init(R,
				  NewSItem('~K~nee-Deep In The Dead',
				  NewSItem('~S~hores Of Hell',
				  NewSItem('~I~nferno!',
				  NewSItem('~L~oad External Wad File',
				  nil))))));
				R.Assign(20,7,60,16);
				Dialog1:=New(PDialog,Init(r,'Episodes'));
				with Dialog1^ do begin
					R.Assign(5,6,15,8);
					Insert(New(PButton,Init(R,'~O~k',cmOk,bfDefault)));
					R.Assign(25,6,35,8);
					Insert(New(PButton,Init(R,'~C~ancel',cmCancel,bfNormal)));
					Insert(SelGame);
				end;
				Control:=Desktop^.ExecView(Dialog1);
				Dispose(Dialog1,Done);
				Param1:='';
				DmParam:='';
				if Control <> cmOk then
					exit;
				Episode:=SelGame^.Value + 1;
				if Episode=4 then begin
					Control:=GetPwadName(ExtFile,27,LevelNames,SelLevel);
					if Control=cmOK then begin
						if WadResult<>wrOk then
							exit;
						Episode:=4;
						Param1:=SerialPWads(True)+ExtFile+' ';
					end;
				 end
				else
					Param1:='-file '+SerialPWads(False);
				if Param1='-file ' then Param1:='';
				if Control=cmOK then begin
					R.Assign(35,12,60,14);
					ComPort:=New(PRadioButtons, Init(R,
					  NewSItem('COM1',
					  NewSItem('COM2',
					  NewSItem('COM3',
					  NewSItem('COM4',
					  nil))))));
					ComPort^.Value:=DFEDefaults.Serial.ComPort;
					R.Assign(35, 6, 60, 11);
					SelSkill:=New(PRadioButtons, Init(R,
					  NewSItem('~I~''m too young to die',
					  NewSItem('~H~ey Not too Rough',
					  NewSItem('H~u~rt Me Plenty',
					  NewSItem('U~l~tra Violence',
					  NewSItem('~N~ightmare!',
					  nil)))))));
					SelSkill^.Value:=DFEDefaults.Serial.Skill;
					R.Assign(35, 1, 59, 5);
					Monsters:=New(PCheckBoxes, Init(R,
					  NewSItem('No ~M~onsters',
					  NewSItem('~R~espawn',
					  NewSItem('~D~eath Match',
					  NewSItem('~U~se Deathmatch 2.0',
					  nil))))));
					Monsters^.Value:=DFEDefaults.Serial.Monsters;
					R.Assign(2, 1, 33, 10);
					if Episode < 4 then
						SetLevelData(R,SelLevel,Episode);
					R.Assign(8,3,71,18);
					Dialog2:=New(PDialog,Init(r,'Serial Game Options'));
					with Dialog2^ do begin
						Insert(Monsters);
						Insert(SelSkill);
						Insert(ComPort);
						R.Assign(15,12,25,14);
						Insert(New(PButton,Init(R,'~C~ancel',cmCancel,bfNormal)));
						R.Assign(2,12,12,14);
						Insert(New(PButton,Init(R,'~O~k',cmOk,bfDefault)));
						Insert(SelLevel);
					end;
					Control:=Desktop^.ExecView(Dialog2);
					if Control=cmOk then begin
						if Episode < 4 then begin
							Str(Episode,TmpStr);
							DmParam:='-devparm -warp '+TmpStr+' ';
							Str(SelLevel^.Value + 1,TmpStr);
							DmParam:=DmParam+TmpStr
						 end
						else begin
							DmParam:='-devparm -warp ';
							DmParam:=DmParam+LevelNames[SelLevel^.Value+1][2]+' ';
							DmParam:=DmParam+LevelNames[SelLevel^.Value+1][4];
						end;
						Str(SelSkill^.Value + 1,TmpStr);
						DmParam:=DmParam+' -skill '+TmpStr+' ';
						DmParam:=DmParam+' -COM';
						Str(ComPort^.Value + 1,TmpStr);
						ModeParam:='COM'+TmpStr+':9600,N,8,1';
						DmParam:=DmParam+TmpStr+' ';
						if (Monsters^.Value and 1) = 1 then
							DmParam:=DmParam+'-nomonsters ';
						if (Monsters^.Value and 2) = 2 then
							DmParam:=DmParam+'-respawn ';
						if (Monsters^.Value and 4) = 4 then
							if (Monsters^.Value and 8) = 8 then
								DmParam:=DmParam+'-altdeath '
							else
								DmParam:=DmParam+'-deathmatch '
					 end
					else
						Param1:='';
					Dialog2^.Done;
					Dispose(Dialog2);
				end;
				Param2:=ModeParam;
				Param1:=Param1+dmParam;
			  end;
			3:begin
				R.Assign(2,1,30,5);
				SelGame:=New(PRadioButtons, Init(R,
				  NewSItem('~K~nee-Deep In The Dead',
				  NewSItem('~S~hores Of Hell',
				  NewSItem('~I~nferno!',
				  NewSItem('~L~oad External Wad File',
				  nil))))));
				R.Assign(20,7,60,16);
				Dialog1:=New(PDialog,Init(r,'Episodes'));
				with Dialog1^ do begin
					R.Assign(5,6,15,8);
					Insert(New(PButton,Init(R,'~O~k',cmOk,bfDefault)));
					R.Assign(25,6,35,8);
					Insert(New(PButton,Init(R,'~C~ancel',cmCancel,bfNormal)));
					Insert(SelGame);
				end;
				Control:=Desktop^.ExecView(Dialog1);
				Dispose(Dialog1,Done);
				Param1:='';
				DmParam:='';
				if Control <> cmOk then
					exit;
				Episode:=SelGame^.Value + 1;
				if Episode=4 then begin
					Control:=GetPwadName(ExtFile,27,LevelNames,SelLevel);
					if Control=cmOK then begin
						if WadResult<>wrOk then
							exit;
						Episode:=4;
						Param1:=IPXPWads(True)+ExtFile+' ';
					end;
				 end
				else
					Param1:='-file '+IPXPWads(False);
				if Param1='-file ' then Param1:='';
				if Control=cmOK then begin
					R.Assign(35,12,60,15);
					Players:=New(PRadioButtons, Init(R,
					  NewSItem('Two Players',
					  NewSItem('Three Players',
					  NewSItem('Four Players',
					  nil)))));
					Players^.Value:=DFEDefaults.IPX.Players;
					R.Assign(35, 6, 60, 11);
					SelSkill:=New(PRadioButtons, Init(R,
					  NewSItem('~I~''m too young to die',
					  NewSItem('~H~ey Not too Rough',
					  NewSItem('H~u~rt Me Plenty',
					  NewSItem('U~l~tra Violence',
					  NewSItem('~N~ightmare!',
					  nil)))))));
					SelSkill^.Value:=DFEDefaults.IPX.Skill;
					R.Assign(35, 1, 59, 5);
					Monsters:=New(PCheckBoxes, Init(R,
					  NewSItem('No ~M~onsters',
					  NewSItem('~R~espawn',
					  NewSItem('~D~eathmatch',
					  NewSItem('~U~se Deathmatch 2.0',
					  nil))))));
					Monsters^.Value:=DFEDefaults.IPX.Monsters;
					R.Assign(2, 1, 33, 10);
					if Episode < 4 then
						SetLevelData(R,SelLevel,Episode);
					R.Assign(8,3,71,19);
					Dialog2:=New(PDialog,Init(r,'IPX Network Game Options'));
					with Dialog2^ do begin
						Insert(Monsters);
						Insert(SelSkill);
						Insert(Players);
						R.Assign(15,13,25,15);
						Insert(New(PButton,Init(R,'~C~ancel',cmCancel,bfNormal)));
						R.Assign(2,13,12,15);
						Insert(New(PButton,Init(R,'~O~k',cmOk,bfDefault)));
						Insert(SelLevel);
					end;
					Control:=Desktop^.ExecView(Dialog2);
					if Control=cmOk then begin
						if Episode < 4 then begin
							Str(Episode,TmpStr);
							DmParam:='-devparm -warp '+TmpStr+' ';
							Str(SelLevel^.Value + 1,TmpStr);
							DmParam:=DmParam+TmpStr
						 end
						else begin
							DmParam:='-devparm -warp ';
							DmParam:=DmParam+LevelNames[SelLevel^.Value+1][2]+' ';
							DmParam:=DmParam+LevelNames[SelLevel^.Value+1][4];
						end;
						Str(SelSkill^.Value + 1,TmpStr);
						DmParam:=DmParam+' -skill '+TmpStr+' ';
						DmParam:=DmParam+' -nodes ';
						Str(Players^.Value + 2,TmpStr);
						DmParam:=DmParam+TmpStr+' ';
						if (Monsters^.Value and 1) = 1 then
							DmParam:=DmParam+'-nomonsters ';
						if (Monsters^.Value and 2) = 2 then
							DmParam:=DmParam+'-respawn ';
						if (Monsters^.Value and 4) = 4 then
							if (Monsters^.Value and 8) = 8 then
								DmParam:=DmParam+'-altdeath '
							else
								DmParam:=DmParam+'-deathmatch ';
						if DFEDefaults.IPX.Socket <> 0 then begin
							Str(DFEDefaults.IPX.Socket,TempStr);
							DmParam:=DmParam+'-port '+TempStr;
						end;
					 end
					else
						Param1:='';
					Dialog2^.Done;
					Dispose(Dialog2);
				end;
				Param1:=Param1+DmParam;
			  end;
			4:begin
				R.Assign(2,1,30,5);
				SelGame:=New(PRadioButtons, Init(R,
				  NewSItem('~K~nee-Deep In The Dead',
				  NewSItem('~S~hores Of Hell',
				  NewSItem('~I~nferno!',
				  NewSItem('~L~oad External Wad File',
				  nil))))));
				R.Assign(20,7,60,16);
				Dialog1:=New(PDialog,Init(r,'Episodes'));
				with Dialog1^ do begin
					R.Assign(5,6,15,8);
					Insert(New(PButton,Init(R,'~O~k',cmOk,bfDefault)));
					R.Assign(25,6,35,8);
					Insert(New(PButton,Init(R,'~C~ancel',cmCancel,bfNormal)));
					Insert(SelGame);
				end;
				Control:=Desktop^.ExecView(Dialog1);
				Dispose(Dialog1,Done);
				Param1:='';
				DmParam:='';
				if Control <> cmOk then
					exit;
				Episode:=SelGame^.Value + 1;
				if Episode=4 then begin
					Control:=GetPwadName(ExtFile,27,LevelNames,SelLevel);
					if Control=cmOK then begin
						if WadResult<>wrOk then
							exit;
						Episode:=4;
						Param1:=ModemPWads(True)+ExtFile+' ';
					end;
				 end
				else
					Param1:='-file '+ModemPWads(False);
				if Param1='-file ' then Param1:='';
				if Control=cmOK then begin
					R.Assign(35,12,60,16);
					ComPort:=New(PRadioButtons, Init(R,
					  NewSItem('COM1',
					  NewSItem('COM2',
					  NewSItem('COM3',
					  NewSItem('COM4',
					  nil))))));
					ComPort^.Value:=DFEDefaults.Modem.Comport;
					R.Assign(2,11,28,14);
					SelModem:=New(PRadioButtons, Init(R,
					  NewSItem('~A~lready Connected',
					  NewSItem('~W~ait For Call',
					  NewSItem('~D~ial:',
					  nil)))));
					R.Assign(12,13,25,14);
					DialNum:=New(PInputLine, Init(R,11));
					DialNum^.Data^:=DFEDefaults.Modem.Phone;
					R.Assign(35, 6, 60, 11);
					SelSkill:=New(PRadioButtons, Init(R,
					  NewSItem('~I~''m too young to die',
					  NewSItem('~H~ey Not too Rough',
					  NewSItem('H~u~rt Me Plenty',
					  NewSItem('U~l~tra Violence',
					  NewSItem('~N~ightmare!',
					  nil)))))));
					SelSkill^.Value:=DFEDefaults.Modem.Skill;
					R.Assign(35, 1, 59, 5);
					Monsters:=New(PCheckBoxes, Init(R,
					  NewSItem('No ~M~onsters',
					  NewSItem('~R~espawn',
					  NewSItem('~D~eath Match',
					  NewSItem('~U~se Deathmatch 2.0',
					  nil))))));
					Monsters^.Value:=DFEDefaults.Modem.Monsters;
					R.Assign(2, 1, 28, 10);
					if Episode < 4 then
						SetLevelData(R,SelLevel,Episode);
					R.Assign(8,2,71,20);
					Dialog2:=New(PDialog,Init(r,'Game Options'));
					with Dialog2^ do begin
						Insert(SelModem);
						Insert(DialNum);
						Insert(Monsters);
						Insert(SelSkill);
						Insert(ComPort);
						R.Assign(15,15,25,17);
						Insert(New(PButton,Init(R,'~C~ancel',cmCancel,bfNormal)));
						R.Assign(2,15,12,17);
						Insert(New(PButton,Init(R,'~O~k',cmOk,bfDefault)));
						Insert(SelLevel);
					end;
					Control:=Desktop^.ExecView(Dialog2);
					if Control=cmOk then begin
						DmParam:='';
						if SelModem^.Value = 2 then
							DmParam:=DmParam+'-dial '+DialNum^.Data^;
						if SelModem^.Value = 1 then
							DmParam:=DmParam+'-answer ';
						if Episode < 4 then begin
							Str(Episode,TmpStr);
							DmParam:=DmParam+' -devparm -warp '+TmpStr+' ';
							Str(SelLevel^.Value + 1,TmpStr);
							DmParam:=DmParam+TmpStr
						 end
						else begin
							DmParam:=DmParam+' -devparm -warp ';
							DmParam:=DmParam+LevelNames[SelLevel^.Value+1][2]+' ';
							DmParam:=DmParam+LevelNames[SelLevel^.Value+1][4];
						end;
						Str(SelSkill^.Value + 1,TmpStr);
						DmParam:=DmParam+' -skill '+TmpStr+' ';
						DmParam:=DmParam+' -COM';
						Str(ComPort^.Value + 1,TmpStr);
						ModeParam:='COM'+TmpStr+':9600,N,8,1';
						DmParam:=DmParam+TmpStr+' ';
						if (Monsters^.Value and 1) = 1 then
							DmParam:=DmParam+'-nomonsters ';
						if (Monsters^.Value and 2) = 2 then
							DmParam:=DmParam+'-respawn ';
						if (Monsters^.Value and 4) = 4 then
							if (Monsters^.Value and 8) = 8 then
								DmParam:=DmParam+'-altdeath '
							else
								DmParam:=DmParam+'-deathmatch '
					 end
					else
						Param1:='';
					Dialog2^.Done;
					Dispose(Dialog2);
				end;
				Param1:=Param1+DmParam;
				Param2:=ModeParam;
			  end;
		end;
	end;

Procedure MapViewMenu;

	var	r:TRect;
			Episode,Control:integer;
			SelGame,Monsters,SelSkill:PCluster;
			SelLevel:PRadioButtons;
			Dialog1,Dialog2:PDialog;
			TmpStr:String;
			ExtFile,WadName:PathStr;
			DmParam:ObjNameStr;
			ViewerMask,ThingMask:word;
			LevelNames:LevelNameArray;

	begin
		R.Assign(2,1,30,5);
		SelGame:=New(PRadioButtons, Init(R,
		  NewSItem('~K~nee-Deep In The Dead',
		  NewSItem('~S~hores Of Hell',
		  NewSItem('~I~nferno!',
		  NewSItem('~E~xternal Map',
		  nil))))));
		R.Assign(20,7,60,16);
		Dialog1:=New(PDialog,Init(r,'Episodes'));
		with Dialog1^ do begin
			R.Assign(5,6,15,8);
			Insert(New(PButton,Init(R,'~O~k',cmOk,bfDefault)));
			R.Assign(25,6,35,8);
			Insert(New(PButton,Init(R,'~C~ancel',cmCancel,bfNormal)));
			Insert(SelGame);
		end;
		Control:=Desktop^.ExecView(Dialog1);
		Episode:=SelGame^.Value + 1;
		ExtFile:='DOOM.WAD';
		if Control=cmOk then begin
			if Episode=4 then begin
				Control:=GetPwadName(ExtFile,27,LevelNames,SelLevel);
				if Control=cmOK then begin
					if WadResult<>wrOk then begin
						Dispose(Dialog1,Done);
						exit;
					end;
					Episode:=4;
				end;
			end;
		end;
		if Control=cmOK then begin
			R.Assign(35, 6, 60, 11);
			SelSkill:=New(PRadioButtons, Init(R,
			  NewSItem('~I~''m too young to die',
			  NewSItem('~H~ey Not too Rough',
			  NewSItem('H~u~rt Me Plenty',
			  NewSItem('U~l~tra Violence',
			  NewSItem('~N~ightmare!',
			  nil)))))));
			R.Assign(35, 1, 55, 5);
			Monsters:=New(PCheckBoxes, Init(R,
			  NewSItem('Show ~M~onsters',
			  NewSItem('Show ~W~eapons',
			  NewSItem('Show ~G~oodies',
			  NewSItem('Muti~P~layer',
			  nil))))));
			R.Assign(2, 1, 28, 10);
			SetLevelData(R,SelLevel,Episode);
			R.Assign(8,2,71,16);
			Dialog2:=New(PDialog,Init(r,'Map Viewer Options'));
			with Dialog2^ do begin
				Insert(Monsters);
				Insert(SelSkill);
				R.Assign(15,11,25,13);
				Insert(New(PButton,Init(R,'~C~ancel',cmCancel,bfNormal)));
				R.Assign(2,11,12,13);
				Insert(New(PButton,Init(R,'~O~k',cmOk,bfDefault)));
				Insert(SelLevel);
			end;
{			Control:=Desktop^.ExecView(Dialog2);
			if Control=cmOk then begin}
			while Desktop^.ExecView(Dialog2)=cmOk do begin
				ViewerMask:=0;
				ThingMask:=0;
				if Episode < 4 then begin
					DmParam:='E M     ';
					Str(Episode,TmpStr);
					DmParam[2]:=TmpStr[1];
					Str(SelLevel^.Value + 1,TmpStr);
					DmParam[4]:=TmpStr[1];
				 end
				else begin
					TmpStr:=LevelNames[SelLevel^.Value + 1]+'        ';
					move(TmpStr[1],DmParam[1],8);
				end;
				if (Monsters^.Value and 1) = 1 then
					ViewerMask:=ViewerMask or 1;
				if (Monsters^.Value and 2) = 2 then
					ViewerMask:=ViewerMask or 4;
				if (Monsters^.Value and 4) = 4 then
					ViewerMask:=ViewerMask or 2;
				if (Monsters^.Value and 8) = 8 then
					ViewerMask:=ViewerMask or 64;
				if (SelSkill^.Value=3) or (SelSkill^.Value=4) then
					ViewerMask:=ViewerMask or 32;
				if SelSkill^.Value=2 then
					ViewerMask:=ViewerMask or 16;
				if (SelSkill^.Value=0) or (SelSkill^.Value=1) then
					ViewerMask:=ViewerMask or 8;
				DoneSysError;
				DoneEvents;
				DoneVideo;
				TerminateOnWadError:=True;
				WadName:=ExtFile;
				SetMapCommands(dcViewMaps,WadName,DmParam,ViewerMask,0);
				DoneDosMem;
				{$IFDEF DEBUG}
					DFELaunch('D:\BP\UNITS\MAPVIEW.EXE');
				{$ELSE}
					DFELaunch('DFESYS\MAPVIEW.EXE');
				{$ENDIF}
				InitDosMem;
				{ViewMap(WadName,DmParam,ViewerMask,0);}
				TerminateOnWadError:=False;
				InitVideo;
				InitEvents;
				InitSysError;
				DeskTop^.Redraw;
				MenuBar^.draw;
				StatusLine^.draw;
			end;
			Dispose(Dialog2, Done);
		end;
		Dialog1^.Done;
		Dispose(Dialog1);
	end;

Procedure PlaySounds;

	var 	SPlay:PSoundPlayer;
			WDir:PWadDirectory;
			ExtFile:string;
			R:TRect;
			Dialog1:PFileDialog;
			Control:word;

	begin
		Dialog1:=New(PFileDialog,Init('*.WAD','Load WAD File','WAD Files',fdOkButton,103));
		Control:=Desktop^.ExecView(Dialog1);
		if (Control=cmOK) or (Control=cmFileOpen) then begin
			ExtFile:=Dialog1^.Directory^+(Dialog1^.FileName^.Data^);
			R.Assign(2, 1, 28, 10);
			Dispose(Dialog1, Done);
			WadResult:=0;
			WDir:=New(PWadDirectory, Init(ExtFile));
			if WadResult<>wrOk then begin
				MessageBox(WadResultMsg(WadResult),Nil,mfError+ mfOkButton);
				exit;
			end;
			SPlay:=New(PSoundPlayer, Init(WDir));
			DeskTop^.ExecView(SPlay);
			Dispose(WDir, Done);
			Dispose(SPlay, Done)
		 end
		else
			Dispose(Dialog1, Done);
	end;

Procedure FindLineDefTags;

	var	r:TRect;
			Episode,Control:integer;
			SelGame:PCluster;
			SelLevel:PRadioButtons;
			Dialog1,Dialog2:PDialog;
			TmpStr:String;
			ExtFile,WadName:PathStr;
			DmParam:ObjNameStr;
			LevelNames:LevelNameArray;

	begin
		R.Assign(2,1,30,5);
		SelGame:=New(PRadioButtons, Init(R,
		  NewSItem('~K~nee-Deep In The Dead',
		  NewSItem('~S~hores Of Hell',
		  NewSItem('~I~nferno!',
		  NewSItem('~E~xternal Map',
		  nil))))));
		R.Assign(20,7,60,16);
		Dialog1:=New(PDialog,Init(r,'Episodes'));
		with Dialog1^ do begin
			R.Assign(5,6,15,8);
			Insert(New(PButton,Init(R,'~O~k',cmOk,bfDefault)));
			R.Assign(25,6,35,8);
			Insert(New(PButton,Init(R,'~C~ancel',cmCancel,bfNormal)));
			Insert(SelGame);
		end;
		Control:=Desktop^.ExecView(Dialog1);
		Episode:=SelGame^.Value + 1;
		ExtFile:='DOOM.WAD';
		if Control=cmOk then begin
			if Episode=4 then begin
				Control:=GetPwadName(ExtFile,27,LevelNames,SelLevel);
				if Control=cmOK then begin
					if WadResult<>wrOk then begin
						Dispose(Dialog1, Done);
						exit;
					end;
					Episode:=4;
				end;
			end;
		end;
		if Control=cmOK then begin
			R.Assign(2, 1, 28, 10);
			SetLevelData(R,SelLevel,Episode);
			R.Assign(11,2,46,16);
			Dialog2:=New(PDialog,Init(r,'Map Level Selections'));
			with Dialog2^ do begin
				R.Assign(15,11,25,13);
				Insert(New(PButton,Init(R,'~C~ancel',cmCancel,bfNormal)));
				R.Assign(2,11,12,13);
				Insert(New(PButton,Init(R,'~O~k',cmOk,bfDefault)));
				Insert(SelLevel);
			end;
			{Control:=Desktop^.ExecView(Dialog2);
			if Control=cmOk then begin}
			while Desktop^.ExecView(Dialog2)=cmOk do begin
				if Episode < 4 then begin
					DmParam:='E M     ';
					Str(Episode,TmpStr);
					DmParam[2]:=TmpStr[1];
					Str(SelLevel^.Value + 1,TmpStr);
					DmParam[4]:=TmpStr[1];
				 end
				else begin
					TmpStr:=LevelNames[SelLevel^.Value + 1]+'        ';
					move(TmpStr[1],DmParam[1],8);
				end;
				DoneSysError;
				DoneEvents;
				DoneVideo;
				WadName:=ExtFile;
				SetMapCommands(dcTagAssoc,WadName,DmParam,0,0);
				DoneDosMem;
				{$IFDEF DEBUG}
					DFELaunch('D:\BP\UNITS\MAPVIEW.EXE');
				{$ELSE}
					DFELaunch('DFESYS\MAPVIEW.EXE');
				{$ENDIF}
				{ShowTagAssociations(WadName,DmParam);}
				InitDosMem;
				TerminateOnWadError:=False;
				InitVideo;
				InitEvents;
				InitSysError;
				DeskTop^.Redraw;
				MenuBar^.draw;
				StatusLine^.draw;
			end;
			Dispose(Dialog2, Done);
		end;
		Dialog1^.Done;
		Dispose(Dialog1);
	end;

procedure MapStatistics;

	var	r:TRect;
			Episode,Control:integer;
			SelGame:PCluster;
			SelLevel:PRadioButtons;
			Dialog1,Dialog2:PDialog;
			TmpStr:String;
			ExtFile,WadName:PathStr;
			DmParam:ObjNameStr;
			LevelNames:LevelNameArray;
			WDir:PWadDirectory;

	begin
		R.Assign(2,1,30,5);
		SelGame:=New(PRadioButtons, Init(R,
		  NewSItem('~K~nee-Deep In The Dead',
		  NewSItem('~S~hores Of Hell',
		  NewSItem('~I~nferno!',
		  NewSItem('~E~xternal Map',
		  nil))))));
		R.Assign(20,7,60,16);
		Dialog1:=New(PDialog,Init(r,'Episodes'));
		with Dialog1^ do begin
			R.Assign(5,6,15,8);
			Insert(New(PButton,Init(R,'~O~k',cmOk,bfDefault)));
			R.Assign(25,6,35,8);
			Insert(New(PButton,Init(R,'~C~ancel',cmCancel,bfNormal)));
			Insert(SelGame);
		end;
		Control:=Desktop^.ExecView(Dialog1);
		Episode:=SelGame^.Value + 1;
		ExtFile:='DOOM.WAD';
		if Control=cmOk then begin
			if Episode=4 then begin
				Control:=GetPwadName(ExtFile,27,LevelNames,SelLevel);
				if Control=cmOK then begin
					if WadResult<>wrOk then begin
						Dispose(Dialog1, Done);
						exit;
					end;
					Episode:=4;
				end;
			end;
		end;
		if Control=cmOK then begin
			R.Assign(2, 1, 28, 10);
			SetLevelData(R,SelLevel,Episode);
			R.Assign(11,2,46,16);
			Dialog2:=New(PDialog,Init(r,'Map Statistics'));
			with Dialog2^ do begin
				R.Assign(15,11,25,13);
				Insert(New(PButton,Init(R,'~C~ancel',cmCancel,bfNormal)));
				R.Assign(2,11,12,13);
				Insert(New(PButton,Init(R,'~O~k',cmOk,bfDefault)));
				Insert(SelLevel);
			end;
			{Control:=Desktop^.ExecView(Dialog2);
			if Control=cmOk then begin}
			while Desktop^.ExecView(Dialog2)=cmOk do begin
				if Episode < 4 then begin
					DmParam:='E M     ';
					Str(Episode,TmpStr);
					DmParam[2]:=TmpStr[1];
					Str(SelLevel^.Value + 1,TmpStr);
					DmParam[4]:=TmpStr[1];
					TmpStr:='        ';
					move(DmParam[1], TmpStr[1], 8);
				 end
				else begin
					TmpStr:=LevelNames[SelLevel^.Value + 1]+'        ';
					move(TmpStr[1],DmParam[1],8);
				end;
				WDir:=New(PWadDirectory, Init(ExtFile));
				if WadResult = wrOk then begin
					DisplayMapStatistics(WDir, TmpStr);
					Dispose(WDir, Done);
				 end
				else
					MessageBox(WadResultMsg(WadResult),Nil,mfError+ mfOkButton);
			end;
			Dispose(Dialog2, Done);
		end;
		Dispose(Dialog1, Done);
	end;

end.