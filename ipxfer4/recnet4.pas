

{****************************************************************************
 * Program    : IPXFER v4.00  Recnet Client v.99 beta                       *
 * Last Update: 12/01/95                                                    *
 * Written by : Joshua Jackson (jayjay@sal-junction.com)                    *
 * Purpose    : Client for IPXFER v4.00 Sendnet Server                      *
 ****************************************************************************}

{$M 32768, 16384, 655360}

Uses Crt, IPX, Timer, Dos, RecProcs, Window, SuperIO, RecStats;

Const FileCount:   longint =   0;
    BuffPtr:   integer =   0;
    NumBuffs =   10;
    CACHESIZE =   NumBuffs * 1024;

Var FileCache:   array[1..NumBuffs] Of TFileBuffer;
    ExitProcChain:   pointer;

Function ConfirmOverwrite(FName:PathStr):   boolean;

Var c:   char;

Begin
    MakeWind(5,12,75,13,15,3,2,1);
    TextAttr := 63;
    MidPrint('[Confirmation]',11);
    MidPrint('(Y/N/A)',14);
    TextAttr := 48;
    Print(12,6,'The following file already exists, overwrite it?');
    Print(13,6,FName);
    Repeat
        c := upcase(ReadKey);
    Until (c = 'Y') Or (c = 'N') Or (c = 'A');
    Case c Of 
        'N':   ConfirmOverwrite := False;
        'Y':   ConfirmOverwrite := True;
        'A':
               Begin
                   ConfirmOverwrite := True;
                   Params.NoConfirm := True;
               End;
    End;
End;

Function ValidateFile(APath:String; AFile:TFRec):   Boolean;

Var FRec:   SearchRec;
    SystemFiles:   word;
    Valid:   boolean;

Begin
    ValidateFile := True;
    Valid := True;
    FindFirst(APath + AFile.FileName, AnyFile, FRec);
    If DosError <> 0 Then
        Exit;
    If Params.SkipFile Then
        Begin
            ValidateFile := False;
            exit;
        End;
    If ((FRec.Attr And ReadOnly) > 0) Then
        Valid := Valid And Params.OvrReadOnly;
    If Params.OvrNewer Then
        Begin
            If FRec.Time <= AFile.Time Then
                Begin
                    Valid := False;
                    Exit;
                End;
            exit;
        End;
    If Not (Valid And Params.NoConfirm) Then
        Valid := ConfirmOverwrite(APath + AFile.FileName);
    ValidateFile := Valid;
End;

Procedure CopyFile(LocalPath,FPath:String;AFile:TFRec);

Var f:   file;
    ReadCount:   integer;
    FileBuff:   TFileBuffer;
    FName:   PathStr;

Begin
    FName := FPath + AFile.FileName;
    If Not ValidateFile(LocalPath, AFile) Then
        Exit;
    MakeStatusWindow(LocalPath, AFile.FileName, AFile.Size);
    If OpenFile(FName) = 0 Then
        Begin
            assign(f, LocalPath + AFile.FileName);
            SetFAttr(f, 0);
            rewrite(f, 1);
            Repeat
                Inc(BuffPtr);
                If BuffPtr > NumBuffs Then
                    Begin
                        BlockWrite(f, FileCache, CACHESIZE);
                        BuffPtr := 1;
                    End;
                ReadCount := ReadFile(FileCache[BuffPtr]);
                If ReadCount = -1 Then
                    Begin
                        Error('Timeout reading file packet.');
                        writeln(' ReadCount = -1');
                        CloseSocket(SocketID);
                        Halt;
                    End;
                UpdateStatus(FilePos(f));
            Until ReadCount <> 1024;
            BlockWrite(f, FileCache, (1024 * (BuffPtr - 1)) + ReadCount);
            If IOResult <> 0 Then
                Begin
                    Error('Error writing to local file.');
                    writeln('Error writing to local file... disk may be full.');
                    CloseSocket(SocketID);
                    Halt;
                End;
            If Not CloseFile Then
                Begin
                    Error('Timeout attempting to close remote file.');
                    writeln('neCloseFileReply never received.');
                    CloseSocket(SocketID);
                    Halt;
                End;
            SetFTime(f, AFile.Time);
            close(f);
            SetFAttr(f, AFile.Attr);
            TotalFileBytes := TotalFileBytes + AFile.Size;
        End
    Else
        Begin
            Error('Timeout attempting to open remote file.');
            writeln('CopyFile: OpenFile(',FName,') <> 0');
            CloseSocket(SocketID);
            Halt;
        End;
    Inc(FileCount);
    BuffPtr := 0;
End;

Procedure Transfer(Specs:PathStr);

Var Attr:   word;
    Path:   PathStr;
    FName:   NameStr;
    FExt:   ExtStr;
    TheFile:   TFRec;
    LocalPath:   PathStr;
    t,l,sresult:   integer;

Begin
      {$I-}
    FSplit(Specs, Path, FName, FExt);
    LocalPath := '';
    l := length(Params.LocalPath);
    For t:=1 To (Length(Path) - l) Do
        LocalPath := LocalPath + Path[l + t];
    LocalPath := Params.Dest + LocalPath;
    If Params.GetHidden Then
        Attr := Archive + ReadOnly + SysFile + Hidden
    Else
        Attr := Archive;
    sresult := FindFirstFile(Specs, Attr, TheFile);
    While sresult = 0 Do
        Begin
            CopyFile(LocalPath, Path, TheFile);
            sresult := FindNextFile(TheFile);
        End;
      {Recurse sub dirs}
    If Params.Recurse Then
        Begin
            Attr := Attr + Directory;
            sresult := FindFirstFile(Specs, Attr, TheFile);
            While sresult = 0 Do
                Begin
                    If (TheFile.Attr And Directory) > 0 Then
                        Begin
                            MkDir(LocalPath+TheFile.FileName);
                            If IOResult = 0 Then;
                            If IOResult <> 0 Then
                                Begin
                                    Error(

                                 'Transfer: Unable to create and/or change to: '
                                          +TheFile.FileName);
                                    CloseSocket(SocketID);
                                    Halt;
                                End;
                            Transfer(Path+TheFile.FileName+'\'+FName+FExt);
                        End;
                    sresult := FindNextFile(TheFile);
                End;
        End;
End;

Procedure DisplayHelp;

Begin
    writeln;
    writeln('USAGE: RECNET <filespec> [destination] [-srhpyd]');
    writeln;
    writeln('   filespec    : file specifications for transfer (eg: *.*)');
    writeln('   destination : * location for received files');
    writeln('   -s          : recurse sub-directories');
    writeln('   -r          : * overwrite read-only files');
    writeln('   -h          : * retrieve hidden/system files as well');
      {writeln('   -v          : * retrieve volume label');}
      {writeln('   -n          : * overwrite only files with newer date/time');}
    writeln(

        '   -p          : do not overwrite any existing files, simply skip them'
    );
    writeln('   -y          : overwrite all files without prompting');
    writeln('   -?          : display this screen');
    writeln('   -d          : Display transfer statistics upon completion');
    writeln;
    writeln(

 '  NOTE: Options marked with a "*" are not available in the shareware version.'
    );
End;

Procedure InitParams;

Var Help:   boolean;
    tmpstr:   string;
    dum:   DirStr;
    fn:   NameStr;
    fe:   ExtStr;
    t1,t2:   integer;

Begin
    Help := False;
    FillChar(Params, Sizeof(TParams), #00);
    If ParamCount = 0 Then
        Begin
            DisplayHelp;
            Halt(1);
        End;
    For t1:=1 To ParamCount Do
        Begin
            tmpstr := ParamStr(t1);
            If (tmpstr[1] = '-') Or (tmpstr[1] = '/') Then
                Begin
                    For t2:=2 To Length(tmpstr) Do
                        Begin
                            Case upcase(tmpstr[t2]) Of 
                                '?':
                                       Begin
                                           Help := True;
                                           Break;
                                       End;
                                'S':   Params.Recurse := True;
                                'R':   Params.OvrReadOnly := True;
                                'H':   Params.GetHidden := True;
								{'V':Params.VolLabel:=True;}
								{'N':Params.OvrNewer:=True;}
                                'P':   Params.SkipFile := True;
                                'Y':   Params.NoConfirm := True;
                                'D':   Params.Statistics := True;
                                Else
                                    Begin
                                        Help := True;
                                        Break;
                                    End;
                            End;
                        End;
                    If Help Then
                        Begin
                            DisplayHelp;
                            Halt(1);
                        End;
                End
            Else If Params.FSpec = '' Then
                     Begin
                         FSplit(tmpstr,Params.LocalPath,fn,fe);
                         Params.FSpec := tmpstr;
                         Continue;
                     End
            Else If Params.Dest = '' Then
                     Begin
                         Params.Dest := tmpstr;
                         If (Length(Params.Dest) > 0) And (Params.Dest[Length(
                            Params.Dest)] <> '\') Then
                             Params.Dest := Params.Dest + '\';
                         Continue;
                     End
            Else
                Begin
                    DisplayHelp;
                    Halt(1);
                End;
        End;
      {if Params.FSpec = '' then Params.FSpec:='*.*';}
    If Params.FSpec = '' Then
        Begin
            DisplayHelp;
            Halt(1);
        End;
End;

{$F+}
Procedure EndSession;

Begin
    ShowCsr;
    ExitProc := ExitProcChain;
End;
{$F-}

Var q:   longint;
    Temp:   TFRec;
    TTime:   real;
    CPS:   longint;

Begin
    writeln;
    writeln('IPXFER v'+IPXFER_Version+'  RECENT Client  v'+RECNET_Version);
    writeln('Copyright (c) 1996  Jackson Software');
    writeln;
    delay(1000);
    ExitProcChain := ExitProc;
    ExitProc := @EndSession;
    HideCsr;
    InitParams;
    Initialize;
    InitTimer;
    writeln('Begining file transfer:');
    write('      Attach:');
    SaveCsr;
    SaveScrn;
    If Attach Then
        writeln(' Successful.')
    Else
        Begin
            Error('Unable to attach to server.');
            CloseSocket(SocketID);
            writeln(' neAttachReply never received.');
            halt(1);
        End;
    write('      Transfer:');
    SaveCsr;
    SaveScrn;
    Transfer(Params.FSpec);
    RestScrn;
    RestCsr;
    TextAttr := 7;
    If FileCount = 0 Then
        writeln(' No matching files, no files transfered.')
    Else
        writeln(' Sucessfully transferred ',FileCount,' files.');
    write('      Detach:');
    SaveCsr;
    SaveScrn;
    If Not Detach Then
        writeln(' Successful.')
    Else
        writeln(' neDetachConfirm never received.');
    If Params.Statistics Then
        Begin
            TTime := TimerTotal / 18.2;
            If TTime = 0 Then
                TTime := 1;
            TotalBytesIn := InPackets * (Sizeof(TNetEvent) + Sizeof(TIPXPacket))
            ;
            writeln;
            writeln('Transfer statistics:');
            writeln('   File bytes received: ', TotalFileBytes:12);
            writeln('   Raw bytes received:  ', TotalBytesIn:12);
            writeln('   Transfer Time:       ', TTime:12:1);
            CPS := Round(TotalFileBytes / TTime);
            writeln('   CPS:                 ', CPS:12);
            CPS := Round(TotalBytesIn / TTime);
            writeln('   Raw CPS:             ', CPS:12);
            writeln('   Packets recevied:    ', InPackets:12);
            writeln('   Packets sent:        ', OutPackets:12);
        End;
    DoneTimer;
    CloseSocket(SocketID);
End.
