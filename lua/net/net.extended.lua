-- 0xF0 kPacket_ExtBundledPacket
kPacket_ExtSubCommand_PartyQueryPos		= 0x00
kPacket_ExtSubCommand_PartyPosAck		= 0x01

-- answer : kPacket_ExtBundledPacket
function	PartySendQueryPos () 
	if (gDisableSendingPartyPos) then return end
	if (not IsPlayerInPartyWithOthers()) then return end -- don't send if alone
	local out = GetSendFIFO()
	out:PushNetUint8(kPacket_ExtBundledPacket) -- 0xF0
	out:PushNetUint16(4)
	out:PushNetUint8(kPacket_ExtSubCommand_PartyQueryPos)  
	out:SendPacket()
end

-- party positon, has to be requested regularly : PartySendQueryPos
function gPacketHandler.kPacket_ExtBundledPacket() -- 0xF0
	local input = GetRecvFIFO()
	local popped_start = input:GetTotalPopped()
	local id = input:PopNetUint8()
	local size = input:PopNetUint16()
	local subcmd = input:PopNetUint8()
	
	if (subcmd == kPacket_ExtSubCommand_PartyPosAck) then
		local partyposlist = {}
		while (true) do
			local memberpos = {}
			memberpos.serial	= input:PopNetUint32()
			if (memberpos.serial == 0) then break end -- termination
			memberpos.xloc		= input:PopNetUint16()
			memberpos.yloc		= input:PopNetUint16()
			memberpos.facet		= input:PopNetUint8() -- mapid
			--~ print("partypos",memberpos.serial,memberpos.xloc,memberpos.yloc,memberpos.facet)
			partyposlist[memberpos.serial] = memberpos
		end
		NotifyListener("Hook_PartyPos",partyposlist) -- {[serial]={serial=?,xloc=?,yloc=?,facet=?},...}
	end
	

	-- check if all data was used
	local used = input:GetTotalPopped() - popped_start
	local rest = size - used
	if (rest < 0) then
		printf("FATAL ! kPacket_ExtBundledPacket : subcmd 0x%02x (used=%d size=%d) popped too much\n",subcmd,used,size)
		print("FATAL ! kPacket_ExtBundledPacket -> forced Crash")
		NetCrash()
	end
	if (rest > 0) then
		printf("WARNING ! kPacket_ExtBundledPacket : subcmd 0x%02x (used=%d size=%d) popped to few\n",subcmd,used,size)
		input:PopRaw(rest)
	end
end
