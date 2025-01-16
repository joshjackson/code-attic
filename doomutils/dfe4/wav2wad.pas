unit

interface

uses dos,crt;

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
		TWadHeader=record
			Junk1			:integer;
			SampleRate	:integer;
			Samples		:word;
			Junk2			:integer;
		end;
		BA=array[1..65520] of byte;
		BAP=^BA;

Function Wav2Wad(WaveName:string;

implementation


var	f1,f2:file;
		t,x:word;
		WavH:TWaveHeader;
		WadH:TWadHeader;
		Data:BAP;

begin
	if ParamCount <> 2 then begin
		writeln('Usage: WAV2WAD file1.wav file2.ext');
		halt(1);
	end;
	assign(f1, ParamStr(1));
	assign(f2, ParamStr(2));
	reset(f1,1);
	rewrite(f2,1);
	writeln('Reading Wave Header...');
	blockread(f1, WavH, Sizeof(TWaveHeader));
	if WavH.ID1 <> 'RIFF' then begin
		writeln('Invalid Wave File Header.');
		close(f1);
		close(f2);
		halt(1);
	end;
	if (WavH.SampRate < 11000) or (WavH.SampRate > 12000) then begin
		writeln('Invalid Sample Rate for DOOM.');
		close(f1);
		close(f2);
		halt(1);
	end;
	WadH.SampleRate:=11025;
	WadH.Junk1:=3;
	WadH.Junk2:=0;
	New(Data);
	write('Reading Data...');
	BlockRead(f1, Data^, 65520, t);
	writeln(t,' Samples used.');
	WADH.Samples:=t div 2;
	writeln('Writing WAD sound file...');
	BlockWrite(f2, WadH, Sizeof(TWadHeader));
	blockwrite(f2,Data^,t);
	close(f1);
	close(f2);
	writeln('Complete.');
end.