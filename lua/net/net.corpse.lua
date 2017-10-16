-- handles special cases for corpses
--[[
Packet Build:
BYTE[1] cmd
BYTE[2] blockSize
BYTE[4] corpseID
repreat
	BYTE[1] itemLayer
	BYTE[4] itemID
until end
BYTE[1] terminator (0x00)

Notes:
Followed by a 0x3C message with the contents.
]]--

--Packet [89], Length: 13, Type: Server
--89, 00 0d, 40 02 37 3c, 0c, 7f fd f9 95, 00
--died anim ids:
--21	Die_Hard_Fwd_01
--22	Die_Hard_Back_01
--sit anim id: 76
--0x2006=kCorpseDynamicArtID
-- TODO : what is the result of this packet?
function  gPacketHandler.kPacket_Corpse_Equipment() -- [0x89]
	local input = GetRecvFIFO()
	local id = input:PopNetUint8()
	local blocksize = input:PopNetUint16()
	local container_serial = input:PopNetUint32()

	printdebug("equip",sprintf("NET: kPacket_Corpse_Equipment: blocksize: %i container_serial=0x%08x\n",blocksize,container_serial))
	
	blocksize=blocksize-7
	
	printdebug("corpse","CORPSECODE,kPacket_Corpse_Equipment",(blocksize - 1)/5)
	while (blocksize >= 5) do
		local item_layer = input:PopNetUint8()
		local item_serial = input:PopNetUint32()
		printdebug("corpse","CORPSECODE,kPacket_Corpse_Equipment + ",item_layer,item_serial)
		printdebug("equip",sprintf("NET: kPacket_Corpse_Equipment_Items: item_layer: %i item_serial=0x%08x\n",item_layer,item_serial))
		blocksize=blocksize-5
	end

	local terminator = input:PopNetUint8()	--always 0x00
--	Update_CorpseContainer(container_serial)
end

--Packet Name: Display Death Action | Packet Size: 13 Bytes
-- TODO : what is the result of this packet?
function  gPacketHandler.kPacket_Death_Animation() -- [0xAF]
	local input = GetRecvFIFO()
	local id = input:PopNetUint8()
	local player_serial = input:PopNetUint32()
	local corpse_serial = input:PopNetUint32()
	local terminator = input:PopNetUint32()
	printdebug("corpse","CORPSECODE,kPacket_Death_Animation",player_serial,corpse_serial,terminator)
	printdebug("animation",sprintf("NET: kPacket_Death_Animation: player_serial: 0x%08x corpse_serial=0x%08x\n",player_serial,corpse_serial))

	-- close healthbar  (thanks to Sehlor)
	local healthBar = gHealthbarDialogs[player_serial]
	if healthBar then
		healthBar:Destroy()
		gHealthbarDialogs[player_serial] = nil
	end

	-- TODO : really hide the mobile for a sec or so, as an naked-mob ubdate packet arrives in the same frame and it's not destroyed
	-- TODO : play anim on corpse-item if kPacket_Death_Animation is sent (not if only corpse is sent, e.g. arriving in an area with old)
	
	local mobile = GetMobile(player_serial)
	if (mobile) then 
		local iRepeatCount = 0 -- 0 = play once, -1 = loop infinity,  1:playtwice=repeatonce 2:play3times...
		if (mobile.bodygfx) then 
			local bWalk,bRun,bIdle,bHasMount,bWarMode,bHasStaff = false,false,false,false,false,false
			local bIsCorpse = true
			local iAnimID = BodyGfxGetStateAnimID(mobile.bodygfx:GetBodyID(),bWalk,bRun,bIdle,bHasMount,bWarMode,bHasStaff,bIsCorpse)
			mobile.bodygfx:SetDying()
			mobile.bodygfx:StartAnim(iAnimID,iRepeatCount) 
		end
	end
	-- similar to gCurrentRenderer:MobileStartServerSideAnim(animdata)
end
