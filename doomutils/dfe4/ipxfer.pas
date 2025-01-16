{$O+,F+}
unit IPXFER;

interface

Procedure IPXSend(FileSpec:String);
Procedure IPXrec;
Function IsIPXInstalled:boolean;

implementation

uses
{$IFDEF DFE}
	App,MsgBox,
{$ENDIF}
	Dos,IPXNET,Window,Crt,Timer,SuperIO;

Function IsIPXInstalled:boolean; assembler;

	asm
		pusha
		mov ax,$7A00
		int $2F
		cmp al,$FF
		jne @@1
		mov al,True
		jmp @@2
	@@1:
		mov al,False
	@@2:
		popa
	end;


var Abort:boolean;

Procedure Error(ErrMsg:string);

	begin
	{$IFDEF DFE}
		MessageBox(ErrMsg,nil,mfOkButton+mfInformation);
		DeskTop^.Redraw;
	{$ELSE}
		writeln('IPXFER Error: '+ErrMsg);
	{$ENDIF}
		ShutDownNetwork;

	end;

Procedure IPXSend(FileSpec:String);

	var	FCB:SearchRec;
			t:integer;
			j:longint;
			PacketNum,LastPacket:longint;
			ACKPacketNum,LastACKPacket:Longint;

	Procedure InitiateFileTransfer(FileName:String);

		var 	f:file;
				fs,fp,fp2:longint;
				r:word;
				s:byte;
				Buff:TPacketBuff;
				ch:char;
				Complete:boolean;
				StartTime:Longint;

		Procedure UpdateStatus;

			var	TotalMin,TotalSec:word;
					PC:byte;
					Bars:byte;
					TTime,CPS:longint;

			begin
				TTime:=(((TimerTotal - StartTime) * 100) div 182);
				if TTime > 0 then
					CPS:=(fp * 10) div TTime
				else
					CPS:=0;
				if fs > 0 then
					PC:=(fp * 100) div fs
				else
					PC:=0;
				gotoxy(57,10);
				write(CPS,'     ');
				gotoxy(62,15);
				write(PC,'%');
				gotoxy(10,15);
				for Bars:=1 to (PC div 2) do
					write(#176);
				gotoxy(22,12);
				write(fp);
				gotoxy(57,12);
				write(fs - fp,'  ');
			end;

		begin
			ClearTimer;
			Complete:=false;
			repeat
				SendACKPacket(ftINIT,0,ndGlobal);
				s:=WaitForACK(J);
				case s of
					ftABRT:begin
							Error('File Transfer Aborted');
							exit;
						  end;
					ftCTS:break;
				end;
				ch:=' ';
				if KeyPressed then begin
					ch:=ReadKey;
					if ch=#27 then begin
						Error('File Transfer Aborted');
						Abort:=True;
						exit;
					end;
				end;
			until false;
			assign(f,FileName);
			reset(f,1);
			gotoxy(22,10);
			write(FileName,Space(12 - Length(FileName)));
			fs:=FileSize(f);
			StartTime:=TimerTotal;
			gotoxy(22,11);
			write(fs);
			repeat
				fp:=FilePos(f);
				FillChar(Buff, 1024, #00);
				BlockRead(f, Buff, 1024, r);
				SendFilePacket(Buff,FileName,fs,fp,ndRemote);
				UpdateStatus;
				if (r < 1024) or ((fp + r) >= fs) then
					Complete:=True;
				ClearTimer;
				repeat
					case WaitForACK(fp2) of
						ftABRT:begin
							close(f);
							Error('File Transfer Aborted');
							exit;
						 end;
						ftNAK:Seek(f, fp);
						ftACK:Break;
					end;
					if KeyPressed then begin
						ch:=ReadKey;
						if ch=#27 then begin
							Error('File Transfer Aborted');
							Abort:=True;
							exit;
						end;
					end;
				until false;
			until complete;
			close(f);
		end;

	begin
		InitNetwork(True);
		Abort:=False;
		FindFirst(FileSpec, Archive, FCB);
		if DosError <> 0 then begin
			Error('No matching files found.');
			exit;
		end;
		while DosError = 0 do begin
			MakeWind(10,10,70,15,15,1,1,1);
			TextAttr:=31;
			Gotoxy(10,10);
			write('Filename:');
			gotoxy(40,10);
			write('CPS:');
			gotoxy(40,11);
			write('ACKSignal:');
			Gotoxy(10,11);
			write('Size:');
			gotoxy(10,12);
			write('Bytes Sent:');
			gotoxy(40,12);
			write('Bytes Remaining:');
			GotoXY(10,14);
			writeln('Last Message:');
			TextAttr:=0;
			gotoxy(10,15);
			write('                                                  ');
			TextAttr:=31;
			InitiateFileTransfer(FCB.Name);
			if Abort then begin
				Exit;
			end;
			for t:=1 to 50 do begin
				SendACKPacket(ftEOF, 0, ndRemote);
				if WaitForACK(j) = ftAEF then
					Break;
			end;
			if t >=50 then begin
				Error('ACKSignal AEF never received.');
				Exit;
			end;
			FindNext(FCB);
		end;
		for t:=1 to 20 do begin
			SendACKPacket(ftEOT, 0, ndRemote);
			if WaitForACK(j) = ftAET then
				Break;
		end;
		ShutDownNetwork;
	end;

Procedure IPXRec;

	var	Buff:TPacketBuff;
			fn:string;
			fp2,t,fp,fs,s,j:longint;
			gfp:shortint;
			f:file;
			ch:char;
			Complete:boolean;
			StartTime:longint;
			InitACK:byte;

	Label NextFile;

	Procedure UpdateStatus;

		var	TotalMin,TotalSec:word;
				PC:byte;
				Bars:byte;
				TTime,CPS:longint;

		begin
			TTime:=(((TimerTotal - StartTime) * 100) div 182);
			if TTime > 0 then
				CPS:=(fp * 10) div TTime
			else
				CPS:=0;
			if fs > 0 then
				PC:=(fp * 100) div fs
			else
				PC:=0;
			gotoxy(57,10);
			write(CPS,'     ');
			gotoxy(62,15);
			write(PC,'%');
			gotoxy(10,15);
			for Bars:=1 to (PC div 2) do
				write(#176);
			gotoxy(26,12);
			write(fp,'     ');
			gotoxy(57,12);
			write(fs - fp,'  ');
		end;

	begin
		cleartimer;
		Abort:=False;
		InitNetwork(False);
		Complete:=False;
		repeat
			MakeWind(10,10,70,15,15,1,1,1);
			TextAttr:=31;
			Gotoxy(10,10);
			write('Filename:');
			gotoxy(40,10);
			write('CPS:');
			gotoxy(40,11);
			write('ACKSignal:');
			Gotoxy(10,11);
			write('Size:');
			gotoxy(10,12);
			write('Bytes Received:');
			gotoxy(40,12);
			write('Bytes Remaining:');
			GotoXY(10,14);
			writeln('Last Message:');
			TextAttr:=0;
			gotoxy(10,15);
			write('                                                  ');
			TextAttr:=31;
			for t:=1 to 50 do begin
				InitACK:=WaitForACK(j);
				if InitACK=ftINIT then
					break;
				if InitACK=ftEOT then begin
					Complete:=True;
					break;
				end;
				if KeyPressed then begin
					ch:=ReadKey;
					if ch=#27 then begin
						Error('File Transfer Aborted.');
						Abort:=True;
						exit;
					end;
				end;
			end;
			if Complete then begin
				SendACKPacket(ftAET, 0, ndRemote);
				ShutDownNetwork;
				exit;
			end;
			if t >= 50 then begin
				Error('Timeout.');
				Exit;
			end;
			t:=0;
			StartTime:=TimerTotal;
			repeat
				SendACKPacket(ftCTS,0,ndRemote);
				gfp:=GetFilePacket(Buff,fn,fp,fs);
				if KeyPressed then begin
					ch:=ReadKey;
					if ch=#27 then begin
						Error('File Transfer Aborted.');
						Abort:=True;
						exit;
					end;
				end;
			until gfp <> 0;
			repeat
				case gfp of
					1:Begin
						if t=0 then begin
							assign(f, fn);
							gotoxy(26,10);
							write(fn);
							gotoxy(26,11);
							write(fs);
							rewrite(f, 1);
							fp:=0;
						end;
						fp2:=FilePos(f);
						if (fs - fp2) > 1024 then begin
							BlockWrite(f,Buff,1024);
							UpdateStatus;
						 end
						else begin
							BlockWrite(f,buff,fs-fp2);
							gotoxy(1,3);
							UpdateStatus;
							SendACKPacket(ftACK,0,ndRemote);
							For t:=1 to 20 do begin
								if WaitForACK(j)=ftEOF then
									Break;
							end;
							if t >=20 then begin
								Error('ACKSignal EOF never received.');
								exit;
							end;
							SendACKPacket(ftAEF,0,ndRemote);
							Close(f);
							goto NextFile
						end;
						ClearTimer;
						SendACKPacket(ftACK,0,ndRemote);
						repeat
							if TimerTicks >=5 then begin
								SendACKPacket(ftACK,0,ndRemote);
								ClearTimer;
							end;
							gfp:=GetFilePacket(Buff,fn,fp,fs);
							if KeyPressed then begin
								ch:=ReadKey;
								if ch=#27 then begin
									SendACKPacket(ftABRT, 0, ndRemote);
									Close(f);
									Error('File Transfer Aborted.');
									Exit;
								end;
							end;
						until gfp <> 0;
						inc(t);
					  end;
					-1:begin
							SendACKPacket(ftNAK,0,ndRemote);
							ClearTimer;
							repeat
								if TimerTicks >= 5 then begin
									SendACKPacket(ftNAK,0,ndRemote);
									cleartimer;
								end;
								gfp:=GetFilePacket(Buff,fn,fp,fs);
								if KeyPressed then begin
									ch:=ReadKey;
									if ch=#27 then begin
										SendACKPacket(ftABRT, 0, ndRemote);
										Close(f);
										Error('File Transfer Aborted.');
										Exit;
									end;
								end;
							until gfp <> 0;
						end;
				end;
				if keypressed then
					ch:=readkey;
			until (ch=#27) or Abort;
		NextFile:
		until (ch=#27) or Abort;
		ShutDownNetwork;
	end;

end.