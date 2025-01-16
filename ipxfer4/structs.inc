const 	MAXCONNECTIONS =  10;
		MAXRECEIVEBUFFERS	=	10;
      	MAXSENDBUFFERS		=	5;
      	SocketID				=	$1111;
{		SocketID				=  $2121;}
      {General System Event Classes}
      neNothing		=  $0000;
		neSystem			=	$000F;
      neFileRequest	=	$0FF0;
      {Specific Network Events/Requests}
      neAttachRequest	=	$0001;
      neAttachReply		=	$0002;
      neInformDetach		=	$0003;
      neDetachConfirm   =	$0004;
      neIdentifyRequest	=  $0005;	{New to version 4.1}
      neIdentifyReply   =  $0006;	{New to version 4.1}

      neRetrieveInfo		=	$0010;
      neInfoReply			=	$0020;
      neFindFirst			=	$0030;
      neFindFirstReply	=	$0040;
      neFindNext			=	$0050;
		neFindNextReply	=	$0060;
      neOpenFile			=	$0070;
      neOpenFileReply	=	$0080;
      neReadFile			=	$0090;
      neReadFileReply	=	$00A0;
      neCloseFile			=	$00B0;
      neCloseFileReply	=	$00C0;
      neSectorRead		=  $00D0;	{New to version 4.01}
      neSectorReadReply =  $00E0;	{New to version 4.01}

      {Server commands}
		cmDisplayStatus		= 100;
		cmDownServer			= 101;
      cmAboutServer			= 102;
      cmConnectStatus		= 103;
      cmTerminateConnection= 104;

      EVENTSIZE				= 10;
      EventID					= 'HJ';

      IPXFER_Version			= '4.10';
      SENDNET_Version		= '2.00';
      RECNET_Version			= '1.14';

      SERVER_Version_Int   = $0200;

type  PLocalAddr=^TLocalAddr;
		TLocalAddr=record
			Network	:array[1..4] of byte;
			node     :array[1..6] of byte;
		end;
      PNodeAddr=^TNodeAddr;
		TNodeAddr=record
			Node   	:array[1..6] of byte;
		end;
		PIPXPacket=^TIPXPacket;
		TIPXPacket=record
			PacketChecksum				:word;
			PacketLength				:word;
			PacketTransportControl  :byte;
			PacketType					:byte;
			dNetwork						:array[1..4] of byte;
			dNode							:array[1..6] of byte;
			dSocket						:word;
			sNetwork						:array[1..4] of byte;
			sNode							:array[1..6] of byte;
			sSocket						:word;
		end;
		PECB=^TECB;
		TECB=record
			Link				:longint;
			ESRAddr			:longint;
			InUseFlag		:byte;
			CompletionCode :byte;
			ECBsocket		:word;
			IPXWork			:longint;
			DriverWork		:array[1..12] of byte;
			ImmediateAddr	:array[1..6] of byte;
			FragmentCount	:word;
 			FAddr				:array[1..2] of word;
			FSize				:word;
		end;
      NodeStr=string[12];

type	PNetEvent=^TNetEvent;
		TNetEvent=record
      	EventID	:word;   {Must equal "HJ"}
			What		:word;
         Who		:integer;   {For internal server use}
         Sequence	:longint;
      	Data		:array[1..1152] of byte;
		end;

      PNetPacket=^TNetPacket;
      TNetPacket=record
      	ecb		:TECB;
         IPXHeader:TIPXPacket;
         NetData	:TNetEvent;
      end;
