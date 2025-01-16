{$F+,O+}
unit WriteWAV;

interface

uses Wad,WadDecl,Sounds,App,MsgBox,Views;

Procedure Sound2Wav(ASound:PWadSound);

implementation

Type 	TWaveHeader=record
			ID1		:array[1..4] of char; {'RIFF'}
			TotalSize:longint;
			ID2		:array[1..8] of char; {'WAVEfmt '}
			PHeader	:longint; {16L}
			FTag		:word;	 {1}
			nChannels:word;	 {1}
			SampRate	:longint;
			AvgRate	:longint;
			BlockAlgn:word;	 {1}
			Bits		:word;	 {8}
			ID3		:array[1..4] of char; {'data'}
		end;

{$I-}
Procedure Sound2Wav(ASound:PWadSound);

	var 	FileName:String;
			TempStr:string;
			t:integer;
			Control:word;
			f:file;
			Wh:TWaveHeader;
			DataLen:Longint;


	begin
		FileName:='';
		Control:=0;
		for t:=1 to 8 do
			if (ASound^.ID[t] <> #00) and (ASound^.ID[t] <> #32) then
				FileName:=FileName+ASound^.ID[t];
		FileName:=FileName+'.WAV';
		Control:=InputBox('Export Sound (Wave Format)','Enter filename:',FileName,64);
		if Control<>cmOk then exit;
		assign(f, FileName);
		rewrite(f,1);
		if IOResult <> 0 then begin
			MessageBox('Could not create specified file.',Nil,mfOkButton+mfError);
			Exit;
		end;
		with Wh do begin
			ID1:='RIFF';
			TotalSize:=Longint(ASound^.SoundBuff^.Samples) + SizeOf(TWaveHeader) - 4;
			ID2:='WAVEfmt ';
			PHeader:=16;
			FTag:=1;
			nChannels:=1;
			SampRate:=Longint(ASound^.SoundBuff^.SampleRate);
			AvgRate:=SampRate;
			BlockAlgn:=1;
			Bits:=8;
			ID3:='data';
			DataLen:=Longint(ASound^.SoundBuff^.Samples);
		end;
		BlockWrite(f, Wh, SizeOf(TWaveHeader));
		BlockWrite(f, DataLen, 4);
		BlockWrite(f, ASound^.SoundBuff^.Sound^, DataLen);
		close(f);
	end;
{$I+}
end.