unit netdoom;

interface

type	TDoomCom=record
   		ID					:longint;
         IntNum			:byte;
         {Communication between DOOM and the Driver}
			Command			:ShortInt;
         RemoteNode  	:ShortInt;
         DataLength		:ShortInt;
         {Common to All Nodes}
			NumNodes			:ShortInt;
         TicDup			:ShortInt; 	{1 = No Dupication, 2-5 = dup for slow nets}
         ExtraTics		:ShortInt; 	{1 = Send a backup tic in every packet}
         DeathMatch		:ShortInt;	{1 = Deathmatch}
   		SaveGame			:ShortInt;	{-1 = New game, 0-5 = load game}
   		Episode			:ShortInt;	{1 - 3}
         Map				:ShortInt;	{1 - 9}
         Skill				:ShortInt;	{1 - 5}
			{info specific to this node}
         ConsolePlayer  :ShortInt;	{0 - 3}
         NumPlayers		:ShortInt;	{1 - 4}
         AngleOffset		:ShortInt;	{1 = Left, 0 = Center, -1 = Right}
         Drone				:ShortInt;	{1 = Drone}
			{Data Packet}
         Data				:array[1..512] of byte;
		end;

Const	MAXNETNODES	= 8
		MAXPLAYERS	= 4
		CMD_SEND		= 1
		CMD_GET     = 2

uses