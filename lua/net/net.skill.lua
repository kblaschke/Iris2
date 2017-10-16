-- see also net.mobile.lua
-- stuff for skills

-- Request SkillUse
function Send_Request_SkillUse(skillid)
	gLastUsedSkillID = skillid
	local s = tostring(skillid-1).." 0"	-- i dont know why we must -1 here :)
	local size = 4+string.len(s)+1
	
	local out = GetSendFIFO()
	out:PushNetUint8(kPacket_Request_SkillOrSpell)
	out:PushNetUint16(size)
	out:PushNetUint8(hex2num("0x24"))
	out:PushFilledString(s,string.len(s)+1)	-- adds a 0 byte after the string
	out:SendPacket()
--	print("-Request_SkillUse",skillid,size)
end

-- sends the server the lock state of one skill (more skills are possible but not used in this function)
-- lockstate (0=up, 1=down, 2=locked)
function Send_SkillLockState(skillid, lockstate)
	print("Send_SkillLockState",skillid,lockstate)
	local out = GetSendFIFO()
	out:PushNetUint8(kPacket_Skills)
	out:PushNetUint16(6)
	out:PushNetUint16(skillid) -- 00 0A = camping
	out:PushNetUint8(lockstate)
	out:SendPacket()
--	print("-Send_SkillLockState skillid",skillid,"state",lockstate)
end

-- triggered by Send_ClientQuery(gRequest_Skills,mobile.serial)
-- TODO : check if gSkillNumber calc is right, check other Emus, check Single Skill Update!!!!
-- TODO : display/update skills
function gPacketHandler.kPacket_Skills()
	local input = GetRecvFIFO()
	local id = input:PopNetUint8()
	local size = input:PopNetUint16()
	local skill_type = input:PopNetUint8()	--0x00= full list, 0x01 GodView, 0x02 full list with skillcap, 0x03 GodView+SkillCap, 0xDF single skill update with cap, 0xFF = single skill update
	-- printf("NET (todo): Skills id: %i Size: %i Loop_Value: %i\n",id,size,skill_type)

	local bHasCap = skill_type == hex2num("0x02") or skill_type == hex2num("0x03") or skill_type == hex2num("0xdf")
	if (skill_type == hex2num("0xFF")) then gSkillNumber = (size-4)/7 end
	if (skill_type == hex2num("0xDF")) then gSkillNumber = (size-4)/9 end

	if ((skill_type == hex2num("0x00")) or (skill_type == hex2num("0x02")) or (skill_type == hex2num("0x03"))) then
		while true do
			local skill_id = input:PopNetUint16()			--id # of skill 0x01-0x2e
			if (skill_id == 0) then break end
			local skill_value = input:PopNetUint16()		--skill_value*10
			local skill_base_value = input:PopNetUint16()	--unmodified value *10
			local skill_lock_state = input:PopNetUint8()	--(0=up, 1=down, 2=locked)
			local skill_name = glSkillNames[skill_id] or ("unknown_"..skill_id)
			local skill_cap
			if (bHasCap) then skill_cap = input:PopNetUint16() end
			printdebug("skill",sprintf("NET (todo): skill: %s [id=%i] skill_value: %i skill_base_value: %i locked?: %i\n",skill_name,skill_id,skill_value,skill_base_value,skill_lock_state))
			SkillUpdate(skill_id,skill_value,skill_base_value,skill_lock_state,skill_name,skill_cap)
		end
		-- TODO : check for other Emus (RunUO sends always 0x0000)
		--if (skill_type == hex2num("0x00")) then
			--local temp = input:PopNetUint16()
		--end
	elseif((skill_type == hex2num("0xFF")) or (skill_type == hex2num("0xDF"))) then
		--single Skill Update
		local skill_id = input:PopNetUint16()+1			--id # of skill 0x01-0x2e, skillid + 1!!!!! ???? uo is superstrange
		local skill_value = input:PopNetUint16()		--skill_value*10
		local skill_base_value = input:PopNetUint16()	--unmodified value *10
		local skill_lock_state = input:PopNetUint8()	--(0=up, 1=down, 2=locked)
		local skill_name = glSkillNames[skill_id] or ("unknown_"..skill_id)
		local skill_cap
		if (bHasCap) then skill_cap = input:PopNetUint16() end
		printdebug("skill",sprintf("NET (todo): skill: %s [id=%i] skill_value: %i skill_base_value: %i locked?: %i\n",skill_name,skill_id,skill_value,skill_base_value,skill_lock_state))
		SkillUpdate(skill_id,skill_value,skill_base_value,skill_lock_state,skill_name,skill_cap)
	end
	
	NotifyListener("Hook_Player_Skills",gPlayerSkills)
end



