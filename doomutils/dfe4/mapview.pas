uses DFEComm,MapRead,ItemLoc2,TagAssoc;

begin

	with CommBuff^ do
		case Command of
			dcViewMaps:ViewMap(WadName,LevelName,ViewerMask,ThingMask);
			dcTagAssoc:ShowTagAssociations(WadName,LevelName);
			dcItemLoc:FindItem(WadName,LevelName,ThingMask);
		else begin
			writeln('Unrecognized command: ',Command);
			readln;
		end;
	end;
end.
