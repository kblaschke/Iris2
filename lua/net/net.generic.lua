-- kPacket_Generic_Command 0xBF 
-- http://docs.polserver.com/packets/index.php?Packet=0xBF

gGenericSubCommands = {}
gGenericSubCommands.kPacket_Generic_SubCommand_FastWalkInit			= 0x01
gGenericSubCommands.kPacket_Generic_SubCommand_FastWalkAddKey		= 0x02
gGenericSubCommands.kPacket_Generic_SubCommand_CloseGenericGump		= 0x04
gGenericSubCommands.kPacket_Generic_SubCommand_Screensize			= 0x05
gGenericSubCommands.kPacket_Generic_SubCommand_PartySystem			= 0x06
gGenericSubCommands.kPacket_Generic_SubCommand_QuestArrow			= 0x07
gGenericSubCommands.kPacket_Generic_SubCommand_MapChange			= 0x08
gGenericSubCommands.kPacket_Generic_SubCommand_DisarmRequest		= 0x09
gGenericSubCommands.kPacket_Generic_SubCommand_AOSTooltip			= 0x10
--(0x0A) Sent by using the client Wrestle Stun Macro key in Options.
--This is no longer used since AoS was introduced. The Macro selection that used it was removed.
gGenericSubCommands.kPacket_Generic_SubCommand_Wrestling_Stun		= 0x0A
gGenericSubCommands.kPacket_Generic_SubCommand_ClientLanguage		= 0x0B	-- Client sends Client-language to Server
gGenericSubCommands.kPacket_Generic_SubCommand_CloseStatus			= 0x0C
gGenericSubCommands.kPacket_Generic_SubCommand_3DClientAction		= 0x0E	-- Client Sent. Server responds with Play Animation packets.
gGenericSubCommands.kPacket_Generic_SubCommand_PopupRequest			= 0x13	-- Client -> Server packet
gGenericSubCommands.kPacket_Generic_SubCommand_DisplayPopup			= 0x14
gGenericSubCommands.kPacket_Generic_SubCommand_PopupEntrySelect		= 0x15
gGenericSubCommands.kPacket_Generic_SubCommand_CodexOfWisdom		= 0x17
gGenericSubCommands.kPacket_Generic_SubCommand_EnableMapDiff		= 0x18
gGenericSubCommands.kPacket_Generic_SubCommand_ExtendedStats		= 0x19
gGenericSubCommands.kPacket_Generic_SubCommand_ExtendedStats2		= 0x1A
gGenericSubCommands.kPacket_Generic_SubCommand_NewSpellbook			= 0x1B	-- Create New Spellbook
gGenericSubCommands.kPacket_Generic_SubCommand_SpellSelected		= 0x1C	-- Client -> Server packet ! Doppelclick auf Spell
gGenericSubCommands.kPacket_Generic_SubCommand_RevisionCustomHouse	= 0x1D	-- Sends a house Revision number for handling client multi cache.
															-- If revision is newer than what client has it asks for the new multi packets to cache it.
gGenericSubCommands.kPacket_Generic_SubCommand_HouseSerial			= 0x1E
gGenericSubCommands.kPacket_Generic_SubCommand_Ability_Icon			= 0x21	-- nodata just (bf 00 05 21) , used together with weapon abilities / combat skills
gGenericSubCommands.kPacket_Generic_SubCommand_OldDamage			= 0x22	-- Done!
gGenericSubCommands.kPacket_Generic_SubCommand_UnknownSE			= 0x24	-- Client -> Server packet
gGenericSubCommands.kPacket_Generic_SubCommand_EnableSESpellIcons	= 0x25
gGenericSubCommands.kPacket_Generic_SubCommand_SpeedMode			= 0x26
gGenericSubCommands.kPacket_Generic_SubCommand_NewRaceGender		= 0x2A
gGenericSubCommands.kPacket_Generic_SubCommand_IrisInfo				= 0xA0 -- iris-special, for iris aware servers
--[[
-race_gender-packet
Client -> Server 
BYTE 	0xBF 
WORD 	Length ( 15 ) 
WORD 	Subcommand - 0x2A 
WORD 	BodyHue 
WORD 	HairId 
WORD 	HairHue 
WORD 	BeardId 
WORD 	BeardHue
]]--
gGenericSubCommands.kPacket_Generic_SubCommand_BandageTarget		= hex2num("0x2C")	-- Client -> Server packet,For use with the new Bandage Self client macro. Introduced in 5.0.4x

--[[
--new sincec KR
gGenericSubCommands.kPacket_Generic_SubCommand_KR_HouseGumpResponse = hex2num("0x2F")	-- BF.2F - KR House Menu Gump Response
gGenericSubCommands.kPacket_Generic_SubCommand_KR_HouseGumpResponse_default = hex2num("0x63")	--BF.2F.63 - KR Default House Menu Gump Response
gGenericSubCommands.kPacket_Generic_SubCommand_KR_HouseGumpResponse_pubpriv = hex2num("0x65")	--BF.2F.65 - KR Change Public/Private House Menu Gump Response
gGenericSubCommands.kPacket_Generic_SubCommand_KR_HouseGumpResponse_convert = hex2num("0x66")	--BF.2F.66 - KR Convert into the customizable House Menu Gump Response
gGenericSubCommands.kPacket_Generic_SubCommand_KR_HouseGumpResponse_relocate= hex2num("0x68")	--BF.2F.68 - KR Relocate Moving Crate House Menu Gump Response
gGenericSubCommands.kPacket_Generic_SubCommand_KR_HouseGumpResponse_sign	= hex2num("0x69")	--BF.2F.69 - KR Change Sign House Menu Gump Response
gGenericSubCommands.kPacket_Generic_SubCommand_KR_HouseGumpResponse_hanger	= hex2num("0x6A")	--BF.2F.6A - KR Change Sign Hanger House Menu Gump Response
gGenericSubCommands.kPacket_Generic_SubCommand_KR_HouseGumpResponse_post	= hex2num("0x6B")	--BF.2F.6B - KR Change Sign Post House Menu Gump Response
gGenericSubCommands.kPacket_Generic_SubCommand_KR_HouseGumpResponse_foundation= hex2num("0x6C")	--BF.2F.6C - KR Change Foundation Style House Menu Gump Response
gGenericSubCommands.kPacket_Generic_SubCommand_KR_HouseGumpResponse_rename	= hex2num("0x6D")	--BF.2F.6D - KR Rename House Menu Gump Response
gGenericSubCommands.kPacket_Generic_SubCommand_KR_HouseGumpResponse_demolish= hex2num("0x6E")	--BBF.2F.6E - KR Demolish House Menu Gump Response
gGenericSubCommands.kPacket_Generic_SubCommand_KR_HouseGumpResponse_trade	= hex2num("0x6F")	--BF.2F.6F - KR Trade House Menu Gump Response
gGenericSubCommands.kPacket_Generic_SubCommand_KR_HouseGumpResponse_primary	= hex2num("0x70")	--BF.2F.70 - KR Make Primary House Menu Gump Response
gGenericSubCommands.kPacket_Generic_SubCommand_KR_HouseGumpResponse_coowner	= hex2num("0x71")	--BF.2F.71 - KR Change To Co-Owner House Menu Gump Response
gGenericSubCommands.kPacket_Generic_SubCommand_KR_HouseGumpResponse_friend	= hex2num("0x72")	--BF.2F.72 - KR Change To Friend House Menu Gump Response
gGenericSubCommands.kPacket_Generic_SubCommand_KR_HouseGumpResponse_access	= hex2num("0x73")	--BF.2F.73 - KR Change To Access House Menu Gump Response
gGenericSubCommands.kPacket_Generic_SubCommand_KR_HouseGumpResponse_primary	= hex2num("0x74")	--BF.2F.74 - KR Ban House Menu Gump Response
--a.s.o. to BF.2F.80
gGenericSubCommands.kPacket_Generic_SubCommand_TargetbyResource		= hex2num("0x30")	---BF.30 - KR Target By Resource Macro
]]--
gGenericSubCommandNamesByID = {}
for k,v in pairs(gGenericSubCommands) do _G[k] = v gGenericSubCommandNamesByID[v] = k end


-- TODO : implement all subpackets
function gPacketHandler.kPacket_Generic_Command() -- 0xBF
	local input = GetRecvFIFO()
	local popped_start = input:GetTotalPopped()
	local id = input:PopNetUint8()
	local size = input:PopNetUint16()
	local subcmd = input:PopNetUint16()
	if (gNetGenericCmdDebug) then printf("NET: kPacket_Generic_Command size=0x%04x subcmd=0x%04x=%s\n",size,subcmd,tostring(gGenericSubCommandNamesByID[subcmd])) end
	printdebug("net",sprintf("NET: kPacket_Generic_Command size=0x%04x subcmd=0x%04x=%s\n",size,subcmd,tostring(gGenericSubCommandNamesByID[subcmd])))

	-- FastWalkInit : 6 keys (runuo's fifosize 0-255)
	if (subcmd == kPacket_Generic_SubCommand_FastWalkInit) then -- 0x01
		local keys = {}
		for i = 1,6 do table.insert(keys,input:PopNetUint32()) end
		FastWalk_Init(keys)
	end

	-- FastWalkAddKey
	if (subcmd == kPacket_Generic_SubCommand_FastWalkAddKey) then
		FastWalk_PushKey(input:PopNetUint32())
	end

	--Subcommand 4: "Close Generic Gump" 
	--BYTE[4] dialogID // which gump to destroy (second ID in 0xB0 packet) 
	--BYTE[4] buttonId // response buttonID for packet 0xB1
	if (subcmd == kPacket_Generic_SubCommand_CloseGenericGump) then -- 0x04
		local dialogId = input:PopNetUint32()
		local buttonId = (size >= 5+4+4) and input:PopNetUint32() or 0
		local playermobile = GetPlayerMobile()
		CloseServerSideGump(playermobile.serial,dialogId,buttonId,true)
		printdebug("net",sprintf("NET: kPacket_Generic_SubCommand_CloseGenericGump (0xbf sub=0x04)"))
	end

	-- Party System
	if (subcmd == kPacket_Generic_SubCommand_PartySystem) then -- 0x06
		HandlePartySystemMessage(input,size)
	end

	-- Quest Arrow (mobile)
	if (subcmd == kPacket_Generic_SubCommand_QuestArrow) then --0x07
		-- TODO: check ... specification is: byte - Right Click (1=yes, 0=no)
		for i = 0, size-6 do
			local temp = input:PopNetUint8()
			print("NET (todo): 0xbf Quest_Arrow subcmd 0x07: "..temp)
		end
	end

	-- Map Change
	if (subcmd == kPacket_Generic_SubCommand_MapChange) then -- 0x08
		local mapid = input:PopNetUint8()
		MapChangeRequest(mapid)
	end

	if (subcmd == kPacket_Generic_SubCommand_CloseStatus) then	--0x0C
		local mobilestatus_serial = input:PopNetUint8()
		CloseHealthbar(mobilestatus_serial)
	end

	-- AOSTooltip
	if (subcmd == kPacket_Generic_SubCommand_AOSTooltip) then -- 0x10  DisplayEquipmentInfo in runuo
		local data = {}
		data.itemserial		= input:PopNetUint32()
		data.infonumber		= input:PopNetUint32()
		local sizeleft = size - (1+2+2+4+4)
		printdebug("net", sprintf("0xbf sub: kPacket_Generic_SubCommand_AOSTooltip itemserial=0x%08x infonumber=0x%08x\n",
									data.itemserial,data.infonumber) )
		data.attributes = {}
		local bHasPreAosAttributes = false
		local myPreAosAttributeLines = {}
		while (sizeleft > 0) do 
			local iAttributeID = input:PopNetInt32()
			sizeleft = sizeleft - 4
			if (iAttributeID == -1) then break
			elseif (iAttributeID == -3) then 
				-- crafter
				local len		= input:PopNetUint16()
				data.crafter	= input:PopFilledString(len)
				sizeleft = sizeleft - (2+len)
				table.insert(myPreAosAttributeLines,"crafted by:"..data.crafter)
			elseif (iAttributeID == -4) then 
				-- unidentified
				data.bUnidentified = true
				table.insert(myPreAosAttributeLines,"(unidentified)")
			else 
				local iAttributeCharges = input:PopNetInt16()
				data.attributes[iAttributeID] = iAttributeCharges
				local cliloctxt = GetCliloc(iAttributeID)
				table.insert(myPreAosAttributeLines,((iAttributeCharges > 0) and (iAttributeCharges..":") or "")..cliloctxt)
			end
		end
		if (#myPreAosAttributeLines > 0) then SetPreAOSAttributes(data.itemserial,myPreAosAttributeLines) end
		--~ print("kPacket_Generic_SubCommand_AOSTooltip",SmartDump(data))
		Send_AosToolTipRequest(data.itemserial)
	end

	-- display popup
	-- TODO : check if PopUp is already opened - use a popuplist with serials !?
	if (subcmd == kPacket_Generic_SubCommand_DisplayPopup) then -- 0x14
		local popupmenu = {}
		popupmenu.unknown1		= input:PopNetUint8() -- always 0x00
		popupmenu.unknown2		= input:PopNetUint8() -- always (0x01 for 2D, 0x02 for KR)
		popupmenu.serial		= input:PopNetUint32()
		popupmenu.numentries	= input:PopNetUint8() -- Number of entries in the popup
		popupmenu.entries		= {}
		local rest = size - (input:GetTotalPopped() - popped_start)
		print("kPacket_Generic_SubCommand_DisplayPopup unknown,nument,rest,rest_per_ent=",popupmenu.unknown1,popupmenu.unknown2,popupmenu.numentries,rest,rest/popupmenu.numentries)
		for i = 1, popupmenu.numentries do 
			local entry = {}
			popupmenu.entries[i] = entry
			entry.popupmenu = popupmenu
			entry.tag		= input:PopNetUint16() -- Entry Tag (this will be returned by the client on selection)
			entry.textid	= input:PopNetUint16() -- ID is the file number for intloc#.language e.g intloc6.enu and the index into that
			entry.text 		= GetPopupEntryText(entry.textid) or "unknown"
			entry.color	= 0
			
			local rest = size - (input:GetTotalPopped() - popped_start)
			if (rest < 2) then print("WARNING: kPacket_Generic_SubCommand_DisplayPopup underrun2",rest) break end
			
			entry.flags		= input:PopNetUint16() -- 0x01 = locked, 0x02 = arrow, 0x20 = color
			if (TestBit(entry.flags,kPopupEntryFlag_Color)) then
			
				local rest = size - (input:GetTotalPopped() - popped_start)
				if (rest < 2) then print("WARNING: kPacket_Generic_SubCommand_DisplayPopup underrun3",rest) break end
				
				entry.color	= input:PopNetUint16() 
				-- rgb 1555 color (ex, 0 = transparent, 0x8000 = solid black, 0x1F = blue, 0x3E0 = green, 0x7C00 = red)
			end
		end
		
		DisplayPopupMenu(popupmenu) -- see net.popup.lua
		NotifyListener("Hook_OpenPopupMenu",popupmenu)	
	end

	-- enable diff files for felucca,trammel,ilshenar,malas
	if (subcmd == kPacket_Generic_SubCommand_EnableMapDiff) then -- 0x18
		local mapnumbers = input:PopNetUint32()
		local myEnableDiff = {}
		for i = 0, mapnumbers-1 do
			myEnableDiff[i] = {}
			myEnableDiff[i].iNumPatchesMap 		= input:PopNetUint32() -- Number of map patches in this map
			myEnableDiff[i].iNumPatchesStatic	= input:PopNetUint32() -- Number of static patches in this map
		end
		EnableDiff(myEnableDiff) -- see lib.diff.lua
	end
	
	-- States LockInfo	-- bonded status
	if (subcmd == kPacket_Generic_SubCommand_ExtendedStats) then -- 0x19
		local party_cmd = input:PopNetUint8()
		--~ print("kPacket_Generic_SubCommand_ExtendedStats",party_cmd)
		if (party_cmd == hex2num("0x00")) then
			local party_serial = input:PopNetUint32()
			local party_value  = input:PopNetUint8()
			--printf("NET: States LockInfo party_cmd: 0x%02x party_serial: 0x%08x party_value: 0x%02x\n",party_cmd,party_serial,party_value)
		end
		-- statlock info
		--[[
			sent by server SERVER
			Subcommand: 0x19: Extended stats
			BYTE[1] type // always 2 ? never seen other value
			BYTE[4] serial
			BYTE[1] unknown // always 0 ?
			BYTE[1] lockBits // Bits: XXSS DDII (s=strength, d=dex, i=int), 0 = up, 1 = down, 2 = locked
		]]--
		if (party_cmd == hex2num("0x02")) then
			local serial = input:PopNetUint32()
			local value  = input:PopNetUint8()
			local lockflags  = input:PopNetUint8()
			local int = BitwiseAND(BitwiseSHR(lockflags, 0), 3)
			local dex = BitwiseAND(BitwiseSHR(lockflags, 2), 3)
			local str = BitwiseAND(BitwiseSHR(lockflags, 4), 3)
			
			local mobile = GetMobile(serial)
			if mobile then
				mobile:UpdateStatsLockState(str, dex, int)
			else
				print("NET: got statsLockStats from unknown mobile", serial, str, dex, int)
			end
			
			-- printf("NET: States LockInfo party_cmd: 0x%02x party_serial: 0x%08x party_value: 0x%02x party_lockflags: 0x%02x\n",party_cmd,party_serial,party_value,party_lockflags)
		end
		if (party_cmd == hex2num("0x1a")) then
			local party_stattype  = input:PopNetUint8()
			local party_lockvalue  = input:PopNetUint8()
			--printf("NET: States LockInfo party_cmd: 0x%02x party_stattype: 0x%02x party_lockvalue: 0x%02x\n",party_cmd,party_stattype,party_lockvalue)
		end
	end

	-- first bit of first byte = spell #1, second bit of first byte = spell #2, first bit of second byte = spell #8, etc
	-- Create Spellbook Container
	-- matix 0xff030000
	if (subcmd == kPacket_Generic_SubCommand_NewSpellbook) then -- 0x1B
		local spellbook = {}
		spellbook.old=false
		spellbook.matrix = {}
		spellbook.unknown = input:PopNetUint16()
		spellbook.serial = input:PopNetUint32()
		spellbook.itemid = input:PopNetUint16()
		spellbook.scrolloffset = input:PopNetUint16()	-- 1==regular, 101=necro, 201=paladin, 401=bushido, 501=ninjitsu, 601=spellweaving
		spellbook.matrix[1] = input:PopNetUint8()
		spellbook.matrix[2] = input:PopNetUint8()
		spellbook.matrix[3] = input:PopNetUint8()
		spellbook.matrix[4] = input:PopNetUint8()
		spellbook.matrix[5] = input:PopNetUint8()
		spellbook.matrix[6] = input:PopNetUint8()
		spellbook.matrix[7] = input:PopNetUint8()
		spellbook.matrix[8] = input:PopNetUint8()
		print("kPacket_Generic_SubCommand_NewSpellbook",spellbook.scrolloffset,spellbook.unknown,spellbook.serial,spellbook.itemid)
		printdebug("net",sprintf("NET: kPacket_Generic_SubCommand_NewSpellbook serial=0x%08x itemId=0x%04x offset=0x%04x\n",
								spellbook.serial, spellbook.itemid, spellbook.scrolloffset))
		Open_Spellbook(spellbook)
	end

	--Enable/Disable SE Spell Icons
	--OnCastSuccessful(spellid), OnEffectEnd (spellid), ClearCurrentMove, ClearAllMoves, SetCurrentMove
	if (subcmd == kPacket_Generic_SubCommand_EnableSESpellIcons) then -- 0x25
		local temp = input:PopNetUint8()		--always 1
		local abilityID = input:PopNetUint8()	--abilityID
		local active = input:PopNetUint8()		--0/1 On/Off
		printf("ABILITY\tSE Spell Icons abilityID: 0x%02x active: 0x%02x\n", abilityID, active)
	end

	-- Subcommand 0x21: (AOS) weapon-Ability icon confirm/end.  see also Send_AOSCommand_WeaponAbility
	-- Note: no data, just (bf 00 05 21) 
	if (subcmd == kPacket_Generic_SubCommand_Ability_Icon) then	-- 0x21
		EndWeaponAbility()
		NotifyListener("Hook_Deactivate_Ability")
	end

	-- Receives a CustomHouse Serial & Revision Hash Number
	if (subcmd == kPacket_Generic_SubCommand_RevisionCustomHouse) then	-- 0x1D
		local customhouseserial = input:PopNetUint32()
		local customhouserevision = input:PopNetUint32()
		printdebug("net",sprintf("NET: kPacket_Generic_SubCommand_RevisionCustomHouse customhouseserial=0x%08x customhouserevision=0x%08x\n",
								customhouseserial, customhouserevision))

		local dyn = GetDynamic(customhouseserial)
		-- check if houserevision exists
		if (dyn) then
			if (dyn.customhouserevision) then
				-- compare new_houserevisiont with old_houserevision, if different change to new
				if (customhouserevision~=dyn.customhouserevision) then
					Send_CustomHouseRevision(customhouseserial)
					printdebug("net",sprintf("NET: old-customhouse -> request new revision\n"))
				end
			else
				Send_CustomHouseRevision(customhouseserial)
				printdebug("net",sprintf("NET: old-customhouse -> request new revision\n"))
			end
		end
	end

	-- old-damage receive packet	(not used by RunUO?)
	if (subcmd == kPacket_Generic_SubCommand_OldDamage)	then	-- 0x22
		local olddamage_temp  = input:PopNetUint8()	-- always 1	?
		local olddamage_serial = input:PopNetUint32()
		local olddamage_amount = input:PopNetUint8()
--		printf("NET: Generic_SubCommand_OldDamage: mobile-serial: 0x%08x Damage_Amount: %i\n",olddamage_serial,olddamage_amount)
		if (olddamage_serial == gPlayerBodySerial) then
			GuiAddChatLine(sprintf("%s",olddamage_amount).." Damage received")
		else
			GuiAddChatLine(sprintf("%s",olddamage_amount).." Damage done")
		end
		
		-- show fading damage over the mobile
		-- TODO totally untested
		gCurrentRenderer:NotifyDamage(olddamage_serial,olddamage_amount)
	end

	--Speed Mode: 0x0 = Normal movement, 0x1 = Fast movement, 0x2 = Slow movement, 0x3 and above = Hybrid movement
	if (subcmd == kPacket_Generic_SubCommand_SpeedMode) then -- 0x26
		local speedboost = input:PopNetUint8()	--0/1 On/Off
		--printf("NET: Speed Mode	Speedboost: %i\n",speedboost)
	end
	
	--nerw Race/Gender packet (since Elfes) Lenght (7bytes)
	if (subcmd == kPacket_Generic_SubCommand_NewRaceGender) then -- 0x2a
		local player_gender = input:PopNetUint8()
		local player_race = input:PopNetUint8()
--		printf("NET: Gender: %s Race: %s\n", gGender[player_gender], gRace[player_race])
	end
	
	-- iris info request, only sent by iris aware servers
	if (subcmd == kPacket_Generic_SubCommand_IrisInfo) then
		Send_IrisInfo()
	end

	-- check if all data was used
	local used = input:GetTotalPopped() - popped_start
	local rest = size - used
	if (rest < 0) then
		printf("FATAL ! kPacket_Generic_Command : subcmd 0x%02x (used=%d size=%d) popped too much\n",subcmd,used,size)
		print("FATAL ! kPacket_Generic_Command -> forced Crash")
		NetCrash()
	end
	if (rest > 0) then
		printf("WARNING ! kPacket_Generic_Command : subcmd 0x%02x (used=%d size=%d) popped to few\n",subcmd,used,size)
		input:PopRaw(rest)
	end
end



-- sends the server the lock state of one stat
-- stat (0=str, 1=dex, 2=int)
-- lockstate (0=up, 1=down, 2=locked)
function Send_StatsLockState(stat, lockstate)
	-- print("DEBUG","Send_StatsLockState",stat,lockstate)
	local out = GetSendFIFO()
	out:PushNetUint8(kPacket_Generic_Command)
	out:PushNetUint16(7)
	out:PushNetUint16(kPacket_Generic_SubCommand_ExtendedStats2)
	out:PushNetUint8(stat)
	out:PushNetUint8(lockstate)
	out:SendPacket()
end

-- sends iris specific infos to the server, in response to kPacket_Generic_SubCommand_IrisInfo
function Send_IrisInfo()
	print("Send_IrisInfo")
	local out = GetSendFIFO()
	out:PushNetUint8(kPacket_Generic_Command)
	out:PushNetUint16(0x06)
	out:PushNetUint16(kPacket_Generic_SubCommand_IrisInfo) -- 0x00A0
	out:PushNetUint8(0x01)
	out:SendPacket()
end

-- triggers -- which came from kPacket_Generic_SubCommand_DisplayPopup
function Send_PopupRequest (serial)
	--- if there is already one open, close it
	if gPopupMenu ~= nil then gPopupMenu:Close() end
	gRunningPopupRequestTimeOut = gMyTicks + kRunningPopupRequestTimeOutInterval

	gPopupMenuSavedPosX,gPopupMenuSavedPosY = GetMousePos() -- TODO : maybe save mousepos at the time of contextrequest ?
	local out = GetSendFIFO()
	out:PushNetUint8(kPacket_Generic_Command)
	out:PushNetUint16(hex2num("0x09")) -- packet size
	out:PushNetUint16(kPacket_Generic_SubCommand_PopupRequest) -- Popup Request Sub-Command
	out:PushNetUint32(serial) -- Popup Request Sub-Command
	out:SendPacket()
end

-- sends kPacket_Generic_SubCommand_PopupEntrySelect after the user has choosen an answer to the popup
-- which came from kPacket_Generic_SubCommand_DisplayPopup
-- see also SendPopupChoice() from old iris
function Send_PopupAnswer (popupserial,entrytag)
	local out = GetSendFIFO()
	out:PushNetUint8(kPacket_Generic_Command)
	out:PushNetUint16(hex2num("0x0B")) -- packet size
	out:PushNetUint16(kPacket_Generic_SubCommand_PopupEntrySelect) -- Popup Request Sub-Command
	out:PushNetUint32(popupserial)
	out:PushNetUint16(entrytag)
	out:SendPacket()
end

function SendBandageSelf (bandageid) return SendBandageCommand(bandageid,GetPlayerSerial()) end
function SendBandageCommand (bandageid,targetid) 
	if (not bandageid) then
		local bandage = MacroCmd_Item_FindFirstByArtID(3617,0) -- find bandage in backpack
		if (not bandage) then return end
		bandageid = bandage.serial
	end
	local out = GetSendFIFO()
	out:PushNetUint8(kPacket_Generic_Command)
	out:PushNetUint16(0x0D) -- packet size
	out:PushNetUint16(kPacket_Generic_SubCommand_BandageTarget) -- 2C
	out:PushNetUint32(bandageid)
	out:PushNetUint32(targetid)
	out:SendPacket()
	-- 0000   BF 00 0D 00 2C 41 3D BC  CD 00 0D BA 5B            ....,A=.....[
	-- kPacket_Generic_SubCommand_BandageTarget=0x2D : bandages=0x413dbccd targetid=0x000dba5b
	return true
end


-- sends special kPacket_Speech to server
-- hybrid block ? weird response to kPacket_Text SYSTEM.gqSetHelpMessage.sethel. and kPacket_Compressed_Gump
-- see also gReceivedSetHelpMessage
function SendHelpMessageGumpResponse () 
	print("####!!!!!!!!!SendHelpMessageGumpResponse")
	local bytes = { 0x03, 0x00, 0x33, 0x20, 0x02, 0xB2, 0x00, 0x03,  0xDB, 0x13, 0x14, 0x3F, 0x45, 0x2C, 0x68, 0x38,
					0x03, 0x4D, 0x39, 0x47, 0x54, 0x9C, 0x7B, 0x08,  0xA8, 0x76, 0x7C, 0x7E, 0x98, 0x21, 0x04, 0xB4,
					0x20, 0x9E, 0xFD, 0x10, 0x32, 0x29, 0x1A, 0x03,  0x11, 0x26, 0x53, 0x50, 0x20, 0x22, 0x0D, 0x59,
					0x1C, 0x19, 0x41, }
	local out = GetSendFIFO()
	for k,v in ipairs(bytes) do out:PushNetUint8(v) end
	out:SendPacket()
end

