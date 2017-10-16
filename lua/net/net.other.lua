-- packet handlers for all other packets that don't fit into the other categories
-- see also lib.packet.lua and lib.protocol.lua
-- see also net.popup.lua
-- see also net.generic.lua
-- see also net.extended.lua

gActWarmode = 0
		
gNextPingTime = 0
gPingInterval = 61000 --61000 exact pingpong time from client->server->client (61sec) in msec, 1000=1second

function PingStep ()
	if (gLastKnownNextPingTime ~= gNextPingTime) then 
		gLastKnownNextPingTime = gNextPingTime
		print("PingStep NextTimeUpdateDetected t/next",gMyTicks,gNextPingTime)
	end
	--~ print("pingstep",gNextPingTime,gMyTicks,gMyTicks >= gNextPingTime,IsNetConnected(),gPingActive)
	if (gMyTicks >= gNextPingTime and IsNetConnected() and gPingActive) then
		if (gNextPingTime > 0 and (not gStartGameWithoutNetwork)) then Send_Ping() end -- don't send the first time...
		gNextPingTime = gMyTicks + gPingInterval
	end
end

-- 0x73 : send every gPingInterval
function Send_Ping ()
	print("sendping")
	local out = GetSendFIFO()
	out:PushNetUint8(kPacket_Ping)
	out:PushNetUint8(0) -- value, usually 0
	out:SendPacket()
	--print("PingPong")
end




-- answered by kPacket_Change_Update_Range from server
function Send_UpdateRangeRequest(range)	-- 0xC8
	print("Send_UpdateRangeRequest",range)
	local out = GetSendFIFO()
	out:PushNetUint8(kPacket_Change_Update_Range)
	out:PushNetUint8(range)
	out:SendPacket()
end

function IsMobilePoisoned (mobile) return mobile.bHealtBarCol_Green  or TestBit(mobile.flag,kMobileFlag_Poisoned) end
function IsMobileMortaled (mobile) return mobile.bHealtBarCol_Yellow or TestBit(mobile.flag,kMobileFlag_GoldenHealth) end

-- http://docs.polserver.com/packets/index.php?Packet=0x17      Health bar status update (KR)
-- new in v7000 ? used on poison state
function gPacketHandler.kPacket_Script_Tree_Command ()	-- 0x17
	local input = GetRecvFIFO()
	local id = input:PopNetUint8()
    local size = input:PopNetUint16()
	print("kPacket_Script_Tree_Command")
	print(FIFOHexDump(input,0,size-3))
	if (size == 1+2+4+2+2+1) then 
		local serial		= input:PopNetUint32()
		local unknown1		= input:PopNetUint16()
		local healthbarcol	= input:PopNetUint16() --  (1=green, 2=yellow, >2=red?)
		local action		= input:PopNetUint8() --  BYTE[1] Flag (0=Remove health bar color, 1=Enable health bar color)
		print("healthbarcol = ",serial,unknown1,healthbarcol,action)
		local bEnable		= action ~= 0  -- poisonlevel ?  lesser:1 greater:3
		local mask
		if (healthbarcol == 1) then mask = kMobileFlag_Poisoned end
		if (healthbarcol == 2) then mask = kMobileFlag_GoldenHealth end
		local mobile = GetMobile(serial)
		if (mobile and mask) then
			if (healthbarcol == 1) then mobile.bHealtBarCol_Green = bEnable end
			if (healthbarcol == 2) then mobile.bHealtBarCol_Yellow = bEnable end
			--~ if (bEnable) then 
				--~ if (not TestBit(mobile.flag,mask)) then mobile.flag = mobile.flag + mask end
			--~ else
				--~ if (    TestBit(mobile.flag,mask)) then mobile.flag = mobile.flag - mask end
			--~ end
			mobile:UpdateFlags(true)
			print("healthbarcol:mobile",serial,mobile.bHealtBarCol_Green,mobile.bHealtBarCol_Yellow,mobile.flag)
		end
	else 
		input:PopRaw(size-3)
	end
	
end
--~ 00 0d ba 5b 00 01 00 01 01                        |...[.....| -- lesser?
--~ 00 0d ba 5b 00 01 00 01 00                        |...[.....|
--~ 00 0d ba 5b 00 01 00 01 03                        |...[.....| -- greater poison
--~ 00 0d ba 5b 00 01 00 01 01                        |...[.....|

function gPacketHandler.kPacket_Change_Update_Range ()	-- 0xC8
	local input = GetRecvFIFO()
	local id = input:PopNetUint8()
	local range = input:PopNetUint8()
	print("######## kPacket_Change_Update_Range",range)
	SetUpDateRange(range)
end

-- Tracking Arrow
function gPacketHandler.kPacket_TrackingArrow ()	-- 0xba
	local input = GetRecvFIFO()
	local id = input:PopNetUint8()
	local arrow_active = input:PopNetUint8() -- 1:on 0:off(x=y=-1)
	local arrow_xloc = input:PopNetInt16()
	local arrow_yloc = input:PopNetInt16()
	
	local dx = arrow_xloc - (gPlayerXLoc or 0)
	local dy = arrow_yloc - (gPlayerYLoc or 0)
	
	if (arrow_active ~= 0) then print("TrackingArrow",dx,dy,"pos=",arrow_xloc,arrow_yloc) end
	

	printdebug("net",sprintf("NET: Trackingarrow is ON xLoc=0x%04x yLoc=0x%04x\n",arrow_xloc,arrow_yloc))

	-- Update Tracking Symbol
	-- because of renaming, it doesn't work with 2d renderer (renamed from ShowQuestArrow)
	if (gCurrentRenderer==Renderer3D) then
		gCurrentRenderer:UpdateTrackingArrow( arrow_active, arrow_xloc, arrow_yloc )
	end
end


-- thanks to sehlor for this     see also   OpenBrowser(url)
function gPacketHandler.kPacket_Web_Browser()
    local input = GetRecvFIFO()
    local id = input:PopNetUint8()
    local size = input:PopNetUint16()
    local url,size2 = FIFO_PopZeroTerminatedString(input, size-3)
	print("kPacket_Web_Browser remaining size",size2)
	--[[
    local file = io.open("tmp.url", "w")
    file:write("[InternetShortcut]\n")
    file:write("URL=" .. tostring(url) .. "\n")
    file:flush()
    file:close()
    io.popen(tostring("tmp.url"))
	]]--
	OpenBrowser(url) -- tipp: linux xdg-open http://www.somesite.com , see lugre.lua
end

--[[
Packet Name: Map Packet (cartography/treasure)
Packet Build:
BYTE[1] cmd 
BYTE[4] id 
BYTE[1] command 
? 1 = add map point. 
? 2 = add new pin with pin number.(insertion. other pins after the number are pushed back.) 
? 3 = change pin 
? 4 = remove pin 
? 5 = remove all pins on the map 
? 6 = toggle the 'editable' state of the map. 
? 7 = return msg from the server to the request 6 of the client. 
BYTE[1] plotting state (1=on, 0=off, valid only if command 7) 
BYTE[2] x location (relative to upper left corner of the map, in pixels, for points) 
BYTE[2] y location (relative to upper left corner of the map, in pixels, for points)
]]--
-- open Map Packet (cartography/treasure)
-- i think the map is hardcoded into the client (gump id)
-- char can have different maps, thats why there is a serial
function gPacketHandler.kPacket_Map_Command ()
	local input = GetRecvFIFO()
	local id = input:PopNetUint8()
	local map_serial = input:PopNetUint32()
	local map_cmd = input:PopNetUint8()
	local map_plot_state = input:PopNetUint8()
	local map_plot_x = input:PopNetUint16()
	local map_plot_y = input:PopNetUint16()
	printdebug("net",sprintf("NET: Map_Command map_serial: 0x%08x map_cmd: %d map_plot_state: %d map_plot_x: %d map_plot_y: %d\n",
								map_serial, map_cmd, map_plot_state, map_plot_x, map_plot_y) )
end

-- TODO : question : ghoulsblade : is this only for combat ? sience: don't know -> verify
-- currently we use this for the warmode target system
-- Target current Mobile
-- Cougar (tigah): denke die nutzen das current target noch für die bandage current target
-- und attack current target und use selected target makros
function gPacketHandler.kPacket_Current_Target()
	local input = GetRecvFIFO()
	local id = input:PopNetUint8()
	local mobile_serial = input:PopNetUint32()
	
	--printf("NET: (todo): Current_Target: mobile_serial: 0x%08x\n",id,mobile_serial)

	if (mobile_serial == 0) then
		printf("NET: attack refused\n")
		gCurrentRenderer:DeselectMobile()
	else
		gCurrentRenderer:SelectMobile(mobile_serial)
	end
	
end

-- 0x76 not important, ignored by palanthir
function gPacketHandler.kPacket_Server_Change ()
	local input = GetRecvFIFO()
	local id = input:PopNetUint8()
	local serverchange = {}
	serverchange.xLoc 		= input:PopNetUint16()
	serverchange.yLoc 		= input:PopNetUint16()
	serverchange.zLoc 		= gUse16BitZ and input:PopNetInt16() or input:PopNetInt8()
	serverchange.unknown_zhigh	= input:PopNetUint8()
	serverchange.unknown1 	= input:PopNetUint8()
	serverchange.boundx 	= input:PopNetUint16()
	serverchange.boundy 	= input:PopNetUint16()
	serverchange.boundw 	= input:PopNetUint16()
	serverchange.boundh 	= input:PopNetUint16()
	printf("NET: (ignored): kPacket_Server_Change: "..vardump2(serverchange).."\n")
end

-- send combat request to server, triggers kPacket_SetPlayerWarmode
function Send_CombatMode(iWarMode)
	local out = GetSendFIFO()
	out:PushNetUint8(kPacket_SetPlayerWarmode)
	out:PushNetUint8(iWarMode)
	out:PushNetUint16(hex2num("0x0032"))
	out:PushNetUint8(hex2num("0x00"))
	out:SendPacket()
end

-- Request Attack to Serial
function Send_AttackReq(mobile_serial)
	local out = GetSendFIFO()
	out:PushNetUint8(kPacket_Attack)
	out:PushNetUint32(mobile_serial)
	gLastAttackedMobileSerial = mobile_serial
	printdebug("net", sprintf("NET: Attack -> serial=0x%08x\n",mobile_serial) )
	NotifyListener("Hook_AttackReqSend",mobile_serial)
end



-- rename a mobile
function Send_Rename_MOB (serial, name)
	local out = GetSendFIFO()
	out:PushNetUint8(kPacket_Rename_MOB)
	out:PushNetUint32(serial)
	out:PushFilledString(name, 30)
	out:SendPacket()
end



-- open door  kPacket_Request_SkillOrSpell 0x12
function Send_OpenDoors ()
	print("Send_OpenDoors")
	local out = GetSendFIFO()
	out:PushNetUint8(kPacket_Request_SkillOrSpell)
	out:PushNetUint16(5)
	out:PushNetUint8(0x58)
	out:PushNetUint8(0x00)
	out:SendPacket()
	--~ 23:33:20.8944: Razor -> Server 0x12 (Length: 5)
	--~ 0000   12 00 05 58 00                                     ...X.
end



--Subcommand 0x1c: Spell selected, client side
--[[
word	Has Spellbook or Spell(2=no spell,1=has spellbook,0=no spellbook, but has spell)
dword	Serial ( if Has Spellbook )
byte	Expansions Flag
byte	Spell ID (if Spell ID = 0, this means last spell)
]]--
--BYTE[2] unknown, always 2
--BYTE[2] selected spell(0-indexed)+scroll offset from sub 0x1b
function Send_Spell(spellid,expansionflag)
	if (not(expansionflag)) then expansionflag=0 end
	if (not(spellid)) then
		print("no spellid defined")
		return
	end
	gLastSpellID = spellid
	gSmartLastSpellID = spellid -- set to nil on target or interrupt
	NotifyListener("Hook_SendSpell",spellid,expansionflag)
--	printf("NET: Send_Spell : spellid=%d\n",spellid)
	if (spellid < 10) then
		local out = GetSendFIFO()
		out:PushNetUint8(kPacket_Request_SkillOrSpell)
		out:PushNetUint16(6)
		out:PushNetUint8(hex2num("0x56"))
		out:PushFilledString(tostring(spellid),1)
		out:PushNetUint8(0)
		out:SendPacket()
	elseif (spellid < 65) then
		local out = GetSendFIFO()
		out:PushNetUint8(kPacket_Request_SkillOrSpell)
		out:PushNetUint16(7)
		out:PushNetUint8(hex2num("0x56"))
		out:PushFilledString(tostring(spellid),2)
		out:PushNetUint8(0)
		out:SendPacket()
	else
		local out = GetSendFIFO()
		out:PushNetUint8(kPacket_Generic_Command)
		out:PushNetUint16(9)
		out:PushNetUint16(kPacket_Generic_SubCommand_SpellSelected)
		out:PushNetUint16(hex2num("0x0002"))
		out:PushNetUint16(spellid)
		out:SendPacket()
	end
-- new spellpacket
--[[
	else
		local out = GetSendFIFO()
		out:PushNetUint8(hex2num("0xbf"))
		out:PushNetUint16(13)
		out:PushNetUint16(kPacket_Generic_SubCommand_SpellSelected)
		out:PushNetUint16(hex2num("0x0002"))
		out:PushNetUint32(0)
		out:PushNetUint8(expansionflag)
		out:PushNetUint8(spellid)
	end
]]--
end


-- Send Packets -----------------------------------------------------------

-- request serverside helppage
function Send_RequestHelp()
	local out = GetSendFIFO()
	out:PushNetUint8(kPacket_Request_Assistance)
	for i=1, 257 do
		out:PushNetUint8(0)
	end
	out:SendPacket()
end
