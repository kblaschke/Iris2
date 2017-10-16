-- simple mobile, no equipment, fixed size packet 0x77
function gPacketHandler.kPacket_Naked_MOB ()
	local input = GetRecvFIFO()
	local id = input:PopNetUint8()
	
	local mobiledata = {}
	mobiledata.serial		= input:PopNetUint32()
	mobiledata.artid 		= input:PopNetUint16()
	mobiledata.xloc	 		= input:PopNetUint16()
	mobiledata.yloc	 		= input:PopNetUint16()
	mobiledata.zloc	 		= gUse16BitZ_MobMove and input:PopNetInt16() or input:PopNetInt8()
	mobiledata.dir			= input:PopNetUint8()
	mobiledata.hue			= input:PopNetUint16() -- hue/skin color
	mobiledata.flag			= input:PopNetUint8()
	mobiledata.notoriety	= input:PopNetUint8()
	
	if (mobiledata.serial == GetPlayerSerial() and (not gPacketVideoPlaybackRunning)) then 
		local x,y,z = GetPlayerPos()
		if (x) then
			mobiledata.xloc = x
			mobiledata.yloc = y
			mobiledata.zloc = z
		end
	end
	
	--~ print("#>--<#kPacket_Naked_MOB",sprintf("0x%08x",mobiledata.serial),mobiledata.xloc,mobiledata.yloc)
	--~ local xloc,yloc = GetPlayerPos()
	--~ local dist = dist2max(xloc,yloc,mobiledata.xloc,mobiledata.yloc)
	--~ if (dist > gUpdateRange_MobileDestroy) then print("kPacket_Naked_MOB : dist >= ",dist) end
	
	--~ if (mobiledata.serial == 0x001b5369) then
		--~ printdebug("corpse","CORPSECODE kPacket_Naked_MOB",mobiledata.artid,mobiledata.flag,mobiledata.notoriety)
	--~ end
	
	if (not gDebug_DisableMobiles) then 
		local mobile = CreateOrUpdateMobile(mobiledata)
		NotifyListener("Hook_MobileMove",mobile)
	end
end

-- Equipped_MOB packet (0x78)
-- TODO: Debug and check why RunUO sends kPacket_Equipped_MOB with artid == Zero
function gPacketHandler.kPacket_Equipped_MOB() -- ProtocolRecv_AddMobile
	local input = GetRecvFIFO()
	local fifolen_start = input:Size()
	local id = input:PopNetUint8()
	local iPacketSize = input:PopNetUint16()
	
	local mobiledata = {}
	mobiledata.serial	= input:PopNetUint32()
	mobiledata.artid	= input:PopNetUint16()

	-- this is related to corpse stuff, some encoded modelid
	if (TestBit(mobiledata.serial,hex2num("0x80000000"))) then
			mobiledata.amount = input:PopNetUint16()
	else 	mobiledata.amount = 1 end -- amount/Corpse Model Num
	
	mobiledata.xloc = input:PopNetUint16()
	mobiledata.yloc = input:PopNetUint16()
	
	-- the usage of this and on which servers it occurs on is unknown
	if (TestBit(mobiledata.xloc,hex2num("0x8000"))) then
			mobiledata.dir2 = input:PopNetUint16()
	else 	mobiledata.dir2 = -1 end

	mobiledata.zloc			= gUse16BitZ and input:PopNetInt16() or input:PopNetInt8()
	mobiledata.dir			= input:PopNetUint8()
	mobiledata.hue			= input:PopNetUint16()  -- dye/skin color
	mobiledata.flag			= input:PopNetUint8()
	mobiledata.notoriety	= input:PopNetUint8() -- TODO : (2's complement signed)
	
	mobiledata.serial		= BitwiseAND(mobiledata.serial,hex2num("0x7fffffff"))
	mobiledata.xloc			= BitwiseAND(mobiledata.xloc,hex2num("0x7fff"))
	
	local equipmentdata = {}

	while true do 
		if ( iPacketSize < (fifolen_start - input:Size()+4) ) then break end
		
		local dynamicdata = {}
		dynamicdata.serial = input:PopNetUint32()
		if (dynamicdata.serial == 0) then break end
		
		if ( iPacketSize < (fifolen_start - input:Size()+3) ) then break end
		dynamicdata.artid_base = input:PopNetUint16()
		dynamicdata.layer = input:PopNetUint8()
		if (TestBit(dynamicdata.artid_base,hex2num("0x8000")) and ( iPacketSize >= (fifolen_start - input:Size()+2) )) then
				dynamicdata.hue = input:PopNetUint16()
		else	dynamicdata.hue = 0 -- TODO : default value ?
		end
		dynamicdata.artid_base = BitwiseAND(dynamicdata.artid_base,hex2num("0x7fff"))
		if (equipmentdata[dynamicdata.layer]) then print("warning ! Equipped_MOB : layer contains more than one item",dynamicdata.layer) end
		equipmentdata[dynamicdata.layer] = dynamicdata
	end
	
	if ((not gDebug_DisableMobiles) or mobiledata.serial == GetPlayerSerial()) then 
		--~ print("#>--<#kPacket_Equipped_MOB",sprintf("0x%08x",mobiledata.serial),mobiledata.xloc,mobiledata.yloc)
		CreateOrUpdateMobile(mobiledata,equipmentdata)
		if (mobiledata.serial == GetPlayerSerial()) then NotifyListener("Hook_Player_Full_equip",mobiledata,equipmentdata) end
	end
end

-- 0x20 Teleport packet (also known as ProtocolRecv_Draw_Player)
-- Note: Only used with the character being played by the client. 
-- TODO : center cam on player etc. , check z_location on the ground
function gPacketHandler.kPacket_Teleport()
	local input = GetRecvFIFO()
	local id = input:PopNetUint8()
	
	local mobiledata = {}
	mobiledata.serial				= input:PopNetUint32()
	mobiledata.artid				= input:PopNetUint16()
	mobiledata.teleport_unknown1 	= input:PopNetUint8()
	mobiledata.hue 					= input:PopNetUint16()
	mobiledata.flag 				= input:PopNetUint8()
	mobiledata.xloc 				= input:PopNetUint16()
	mobiledata.yloc 				= input:PopNetUint16()
	mobiledata.teleport_unknown2	= input:PopNetUint16()
	mobiledata.dir 					= input:PopNetUint8()
	mobiledata.zloc 				= gUse16BitZ and input:PopNetInt16() or input:PopNetInt8()
	
	--~ print("#>--<#kPacket_Teleport",sprintf("0x%08x",mobiledata.serial),mobiledata.xloc,mobiledata.yloc)
	NotifyTeleport(mobiledata) -- calls CreateOrUpdateMobile and assigns playerid

	if (gReceivedSunlight and gAltenatePostLoginHandling and (not gFirstTeleportHandled)) then
		gFirstTeleportHandled = true
		--~ Send_DoubleClick(0x4192CF5B) -- todo : remembered backpack id ?
	end
end


-- Character Animation (0x6e)
function gPacketHandler.kPacket_Animation ()	-- [0x6e] 14 Bytes
	local input = GetRecvFIFO()
	local id = input:PopNetUint8()

	local animdata = {}
	animdata.mobileserial	= input:PopNetUint32()	
	animdata.m_animation		= input:PopNetUint16()
	animdata.m_framecount	= input:PopNetUint16()  -- is this the start-frame ? is this mobile-direction ?
	animdata.m_repeat		= input:PopNetUint16()	--repeat (1 = once / 2 = twice / 0 = repeat forever)
	animdata.m_animForward	= input:PopNetUint8()	--(0x00=forward, 0x01=backwards)
	animdata.m_repeatFlag	= input:PopNetUint8()	--(0 - Don't repeat / 1 repeat)
	animdata.m_frameDelay	= input:PopNetUint8()	--(0x00 - fastest / 0xFF - Too slow to watch)
	printdebug("animation","Animation "..vardump2(animdata))

	gCurrentRenderer:MobileStartServerSideAnim(animdata)
	
	gAnimCounter = gAnimCounter or {}
	gAnimCounter[animdata.mobileserial] = gAnimCounter[animdata.mobileserial] or {}
	gAnimCounter[animdata.mobileserial][animdata.m_animation] = (gAnimCounter[animdata.mobileserial][animdata.m_animation] or 0) + 1
	
	NotifyListener("Hook_Packet_Animation",animdata)
end

-- Note: For characters other than the player, curHits and maxHits are not the actual values.
-- maxHits is a fixed value, and curHits works like a percentage.
-- triggered by Send_ClientQuery(gRequest_States,playermobile.serial)
-- TODO : Set also HP,Stamina,Mana here
function gPacketHandler.kPacket_Mobile_Stats() -- 0x11
	local input = GetRecvFIFO()
	local id = input:PopNetUint8()
	local iPacketSize = input:PopNetUint16()
	local iBytesLeft = iPacketSize - 3
	local stats = {}
	
	-- returns nil if there are enough bytes left => the "or" clause gets executed
	function MySave_Prepare (needed)
		if (iBytesLeft >= needed) then iBytesLeft = iBytesLeft - needed return end
		input:PopRaw(iBytesLeft) 
		iBytesLeft = 0 
		print("underflow in kPacket_Mobile_Stats, flag,iPacketSize=",stats.mobstatversion,iPacketSize) 
		return 0 -- return 0 -> pop is skipped
	end
	function MySave_PopNetUint8  () return MySave_Prepare(1) or input:PopNetUint8()  end
	function MySave_PopNetUint16 () return MySave_Prepare(2) or input:PopNetUint16() end
	function MySave_PopNetUint32 () return MySave_Prepare(4) or input:PopNetUint32() end

	local mobileserial		= MySave_PopNetUint32()
	MySave_Prepare(30)
	stats.name				= input:PopFilledString(30)
	
	stats.curHits			= MySave_PopNetUint16()
	stats.maxHits 			= MySave_PopNetUint16()
	stats.bCanChangeName	= MySave_PopNetUint8() ~= 0	--(0x1 = allowed, 0 = not allowed)
	
	
	stats.mobstatversion	= MySave_PopNetUint8()
	
	--~ print("stats.mobstatversion",hex(stats.mobstatversion))
	
	-- mobstatversion : http://docs.polserver.com/packets/index.php?Packet=0x11
    --~ * 0x00: no more data following (end of packet here).
    --~ * 0x01: T2A Extended Info
    --~ * 0x03: UOR Extended Info
    --~ * 0x04: AOS Extended Info (4.0+)
    --~ * 0x05: UOML Extended Info (5.0+)
    --~ * 0x06: UOKR Extended Info (UOKR+)

	
	
	-- more data following
	if (in_array( stats.mobstatversion, {1,3,4,5})) then
		stats.sex			= MySave_PopNetUint8() -- * 0x00 - Male  * 0x01 - Female
		
		stats.str			= MySave_PopNetUint16()
		stats.dex			= MySave_PopNetUint16()
		stats.int			= MySave_PopNetUint16()
		
		stats.curStamina	= MySave_PopNetUint16()
		stats.maxStamina	= MySave_PopNetUint16()
		stats.curMana		= MySave_PopNetUint16()
		stats.maxMana		= MySave_PopNetUint16()
		stats.gold			= MySave_PopNetUint32()
		stats.armor			= MySave_PopNetUint16() -- resistPhysical (old clients: AC).
		stats.curWeight		= MySave_PopNetUint16()

		if (stats.mobstatversion == 5) then
			stats.maxWeight	= MySave_PopNetUint16()
			stats.race		= MySave_PopNetUint8()
		elseif stats.curWeight then
			-- set hardcoded max weight fallback
			stats.maxWeight = (40 + math.floor(stats.str*35/10))
		end
		
		-- overload check
		if stats.curWeight and stats.maxWeight then
			if stats.curWeight > stats.maxWeight and gPlayerLastOverloadCheckWeight ~= stats.curWeight then
				GuiAddChatLine("You carry too much! "..stats.curWeight.. " / "..stats.maxWeight,gStatsInfoFadeLineColor)
				gPlayerLastOverloadCheckWeight = stats.curWeight
			end
			if stats.curWeight < stats.maxWeight and gPlayerLastOverloadCheckWeight then
				GuiAddChatLine("Weight is normal! "..stats.curWeight.. " / "..stats.maxWeight,gStatsInfoFadeLineColor)
				gPlayerLastOverloadCheckWeight = nil
			end
		end
		
		if (in_array( stats.mobstatversion, {3,4,5} )) then -- Followers (pets)
			stats.statcap	= MySave_PopNetUint16()		-- The character's total allowable sum of Strength, Intelligence, and Dexterity
			stats.curPet	= MySave_PopNetUint8()			
			stats.maxPet	= MySave_PopNetUint8()
			
			if (in_array( stats.mobstatversion, {4,5} )) then -- Resistances
				stats.fireresist	= MySave_PopNetUint16()
				stats.coldresist	= MySave_PopNetUint16()
				stats.poisonresist	= MySave_PopNetUint16()
				stats.energyresist	= MySave_PopNetUint16()
				stats.luck			= MySave_PopNetUint16()
				stats.minDamage		= MySave_PopNetUint16()
				stats.maxDamage		= MySave_PopNetUint16()
				stats.tithing		= MySave_PopNetUint32()
			end
		end
	end

	if (iBytesLeft == 2 and gPolServer) then stats.unknown_pol = MySave_PopNetUint16() end -- avoid annoying warning in console
	--printf("NET : kPacket_Mobile_Stats mobile=0x%08x name=%s\n",mobileserial,stats.name)
	
	local mobile = GetMobile(mobileserial)
	Mobile_UpdateStats(mobileserial,stats)
end

--[[
Mobile Stats    0x11  	
Show Mobile .. 0xD3
Rename MOB  0x75  	
MOB Name	0x98  	
kPacket_Naked_MOB    	0x77  	
kPacket_Update_Mobile	0xD2  (extended 0x20)  similar to the Naked MOB packet.   pos..

0xD2 : kPacket_Update_Mobile : "Extended 0x20"  25 Byte length
    * BYTE cmd
    * Preamble: Exactly like 0x20
    * BYTE[2] unknown 1
    * BYTE[2] unknown 2
    * BYTE[2] unknown 3

Note: currently unknown's don't seem to do anything.
That packet has never been sighted on OSI servers as well.
We probably have to wait till OSI activates it/finishes implementation., to see what it does.

]]--

--[[
Mobile Flag Byte: maybe those are similar to the kPacket_Show_Item flag/status byte ?
0x00 - None
0x02 - Female
0x04 - Poisoned
0x08 - YellowHits // healthbar gets yellow
0x10 - FactionShip // unsure why client needs to know
0x20 - Movable if normally not
0x40 - War mode
0x80 - Hidden 
]]--

--# Update Current Health [0xA1]
-- TODO : not only player gets update packets here - also the defender of a combat
function gPacketHandler.kPacket_HP_Health()
	local input = GetRecvFIFO()
	local id = input:PopNetUint8()
	local mobileserial	= input:PopNetUint32()
	local maxvalue 		= input:PopNetUint16()
	local curvalue 		= input:PopNetUint16()
	printdebug("mobile",sprintf("NET: update HP: mobile_serial=0x%08x  %i / %i\n",mobileserial,curvalue,maxvalue))
	
	Mobile_UpdateHealth(mobileserial,curvalue,maxvalue)
end

--# Update Current Mana [0xA2]
-- TODO : not only player gets update packets here
function gPacketHandler.kPacket_Mana_Health()
	local input = GetRecvFIFO()
	local id = input:PopNetUint8()
	local mobileserial 	= input:PopNetUint32()
	local maxvalue 		= input:PopNetUint16()
	local curvalue 		= input:PopNetUint16()
	printdebug("mobile",sprintf("NET: update MANA: mobile_serial=0x%08x  %i / %i\n",mobileserial,curvalue,maxvalue))
	
	Mobile_UpdateMana(mobileserial,curvalue,maxvalue)
end

--# Update Current Stamina [0xA3]
-- TODO : not only player gets update packets here
function gPacketHandler.kPacket_Stamina()
	local input = GetRecvFIFO()
	local id = input:PopNetUint8()
	local mobileserial	= input:PopNetUint32()
	local maxvalue		= input:PopNetUint16()
	local curvalue		= input:PopNetUint16()
	printdebug("mobile",sprintf("NET: update STAMINA: mobile_serial=0x%08x  %i / %i\n",mobileserial,curvalue,maxvalue))

	Mobile_UpdateStamina(mobileserial,curvalue,maxvalue)
end


function gPacketHandler.kPacket_Damage()
	local input = GetRecvFIFO()
	local packetid		= input:PopNetUint8()
	local mobile_serial = input:PopNetUint32()
	local damage		= input:PopNetUint16()
	printdebug("mobile",sprintf("NET: kPacket_Damage: mobile_serial=0x%08x  damage=%i\n",mobile_serial,damage))
	
	gCurrentRenderer:NotifyDamage( mobile_serial, damage)
end


-- Fighting - Swing [0x2F] 10bytes
-- TODO : handle animation
-- TODO : is this packet actually used ?
function gPacketHandler.kPacket_Swing()
	local input = GetRecvFIFO()
	local id = input:PopNetUint8()
	local unknown1 = input:PopNetUint8()
	local attacker_serial = input:PopNetUint32()
	local defender_serial = input:PopNetUint32()
	printdebug("mobile",sprintf("NET: kPacket_Swing Animation: attacker=0x%08x defender=0x%08x\n",attacker_serial,defender_serial))
	
	gCountSwings = true
	if (gCountSwings and gSwingCounter and attacker_serial == GetPlayerSerial()) then 
		local timesincelast = 0
		local t = Client_GetTicks()
		if (gLastSwingTime) then timesincelast = t - gLastSwingTime end
		gLastSwingTime = t
		local hits = 0
		local blockedhits = 0
		local swings = gSwingCounter[attacker_serial]
		for mobileserial,arr in pairs(gAnimCounter or {}) do
			for m_animation,count in pairs(arr) do
				if (mobileserial ~= GetPlayerSerial() and m_animation == 0x00000014) then hits = hits + count end
				--~ printf("anim mob=0x%08x(%s) anim=0x%08x count=%d\n",mobileserial,(mobileserial == GetPlayerSerial()) and "self" or "other",m_animation,count)
			end
		end
		for mobileserial,arr in pairs(gEffectCounter or {}) do
			for effectid,count in pairs(arr) do
				if (mobileserial ~= GetPlayerSerial() and effectid == 0x37b9) then blockedhits = blockedhits + count end
				--~ printf("effect mob=0x%08x(%s) effectid=0x%08x count=%d\n",mobileserial,(mobileserial == GetPlayerSerial()) and "self" or "other",effectid,count)
			end
		end
		--~ printf("#### swings:%d hits:%d blockedhits:%d timesincelast=%d\n",swings,hits,blockedhits,timesincelast)
	end
	
	gSwingCounter = gSwingCounter or {}
	gSwingCounter[attacker_serial] = (gSwingCounter[attacker_serial] or 0) + 1
end

-- http://docs.polserver.com/packets/index.php?Packet=0xE2
function gPacketHandler.kPacket_MobStateAnimKR() -- 0xE2, 10bytes
	local input = GetRecvFIFO()
	local id = input:PopNetUint8()
	local serial	= input:PopNetUint32() -- Mobile serial
	local action	= input:PopNetUint16()
	local unknown1	= input:PopNetUint8() -- unknown (0x00)
	local actionsub	= input:PopNetUint8() -- Secondary/Sub Action
	local unknown2	= input:PopNetUint8() -- Last byte appears a random number from 0 to 59. Could this be a loop or timer?
	--~ print("MobStateAnimKR",serial,action,unknown1,actionsub,unknown2)
end
--[[
	thanks to cougar from vm : 
	public enum AnimationType
	{
		None		= -1,
		Attack		= 0,
		Parry		= 1,
		Block		= 2,
		Die			= 3,
		Impact		= 4,
		Fidget		= 5,
		Eat			= 6,
		Emote		= 7,
		Alert		= 8,
		TakeOff		= 9,
		Land		= 10,
		Spell		= 11,
		StartCombat = 12,
		EndCombat	= 13,
		Pillage		= 14,
		Spawn		= 15// 3D Only
	}
	public enum AttackSubType
	{
		AttackBareHand		= 0,
		AttackBow			= 1,
		AttackCrossbow		= 2,
		AttackSmashOverHead	= 3,
		AttackSmash			= 4,
		AttackStab			= 5,
		AttackCrush			= 6,
		AttackSwing			= 7,
		AttackBackStab		= 8,
	}
	public enum EmoteSubType { Bow 		= 0, Salute		= 1, Walk		= 2, }
	public enum FidgetSubType { Idle 		= 0, }
	public enum EatSubType { Eat 		= 0, }
	public enum ImpactSubType { GetHit 		= 0, }
	public enum SpellSubType { Cast 		= 0, WaveHands 	= 1, }
	public enum DieSubType { Die			= 0, }
	public enum BlockSubType { Block		= 0, }
]]--

-- TODO : what is the result of this packet?
--BYTE cmd 
--BYTE action (2=ghost, 1=resurrect, 0=from server)
function gPacketHandler.kPacket_Death()
	local input = GetRecvFIFO()
	local id = input:PopNetUint8()
	local action = input:PopNetUint8()
	
	print("kPacket_Death",action)
	if (action == 0x02) then
		gGotDeath = true
		print("you are dead")
	end
	
	-- > BandagePacket ( BandagePacket.cs ) ??????	
	--local item_serial = input:PopNetUint32()		-- use item on target mobile
	--local mobile_target = input:PopNetUint32()
	printdebug("mobile",sprintf("NET: kPacket_Death: player is now (2=ghost, 1=resurrect, 0=from server)=%i\n",action))
end
