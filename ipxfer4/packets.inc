{Transfer Packet Definitions for IPXFER 4.00}

Type  PpIdentifyRequest=^TpIdentifyRequest;		{New to version 4.1}
		TpIdentifyRequest=record
      	dummy:byte;
		end;
      PpIdentifyReply=^TpIdentifyReply;			{New to version 4.1}
      TpIdentifyReply=record
      	SrvVersion:integer;
         SrvName:string[15];
         SrvDesc:string[80];
      end;
		PpConnectRequest=^TpConnectRequest;
		TpConnectRequest=record
      	Dummy:byte;
         NodeAddr:array[1..6] of byte;
      end;
      PpConnectReply=^TpConnectReply;
      TpConnectReply=Record
      	Response:boolean;
         ServerName:string[15];
      end;
      PpDisconnect=^TpDisconnect;
      TpDisconnect=record
      	dummy:byte;
      end;
      PpDisconnectReply=^TpDisconnectReply;
      TpDisconnectReply=record
      	dummy:byte;
      end;
      PpFindFirstFile=^TpFindFirstFile;
      TpFindFirstFile=record
      	NameSpec:string[80];
         Attr:word;
      end;
      PpFindNextFile=^TpFindNextFile;
      TpFindNextFile=record
      	Dummy:byte;
      end;
      PpFindFileReply=^TpFindFileReply;
      TpFindFileReply=record
         Attr:byte;
         Time:longint;
			Size:longint;
      	FileName:String[12];
         ErrorCode:integer;
      end;
      PpOpenFile=^TpOpenFile;
      TpOpenFile=Record
			NameSpec:string[80];
      end;
      PpOpenFileReply=^TpOpenFileReply;
      TpOpenFileReply=record
         response:integer;
      end;
      PpReadFile=^TpReadFile;
      TpReadFile=record
      	dummy:byte;
      end;
      PpReadFileReply=^TpReadFileReply;
      TpReadFileReply=record
      	result:integer;
         data:array[1..1024] of byte;
      end;
      PpCloseFile=^TpCloseFile;
      TpCloseFile=record
         dummy:byte;
      end;
      PpCloseFileReply=^TpCloseFileReply;
      TpCloseFileReply=record
      	dummy:byte;
      end;
		{IPXFER 4.01 Additions}
      PpSectorRead=^TpSectorRead;
      TpSectorRead=record
         Sector:longint;
         Count:word;
      end;
      PpSectorReadReply=^TpSectorReadReply;
      TpSectorReadReply=record
      	ReturnCode:word;
         Data:Array[1..1024] of char;
      end;

