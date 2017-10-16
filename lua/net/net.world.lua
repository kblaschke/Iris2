-- packet handlers for things affecting the game world, e.g. time, light, season...
-- see also lib.packet.lua and lib.protocol.lua

-- Note: if id2 = 1, then this is a season change. 
-- Note: if season change, then id1 = (0=spring, 1=summer, 2=fall, 3=winter, 4 = desolation)
function gPacketHandler.kPacket_Game_Season()
	local input = GetRecvFIFO()
	local id = input:PopNetUint8()
	local season = input:PopNetUint8()
	local seasonchange = input:PopNetUint8()
	printdebug("net",sprintf("NET: Game_Season id: %i season: %i seasonchange: %i\n",id,season,seasonchange))

	--~ print("season change",season,gSeasonIDs[season])
	if (seasonchange == 1) then
		gSeasonSetting = season
	elseif (gSeasonSetting ~= season) then
		gSeasonSetting = season
	end
end


-- Personal light level
function gPacketHandler.kPacket_Light_Change()
	local input = GetRecvFIFO()
	local id = input:PopNetUint8()
	local creature_id = input:PopNetUint32()
	local creature_light = input:PopNetUint8()
	printdebug("net",sprintf("NET: Light_Change id: %i creature_id: %i creature_light: %i\n",id,creature_id,creature_light))
	
	local f = gIgnoreGlobalLightLevel and 1 or (creature_light/0x1F)
	
	local mobile = GetMobile(creature_id)
	if mobile and gCurrentRenderer then
		gCurrentRenderer:SetPersonalLight(mobile, f)
	end
end


-- Overall light level  - 0 is brightest (day), 9 is OSI night, max is 31 (black)
--~ 0x00 - day
--~ 0x09 - OSI night
--~ 0x1F - Black
--~ Max normal val = 0x1F
function gPacketHandler.kPacket_Sunlight() -- ProtocolRecv_Globallight
	local input = GetRecvFIFO()
	local id = input:PopNetUint8()
	local sunlight = input:PopNetUint8()
	printdebug("net",sprintf("NET: Sunlight id: %i sunlight: %i\n",id,sunlight))
	gReceivedSunlight = true

	local f = gIgnoreGlobalLightLevel and 1 or (1 - (sunlight/0x1F))

	if gCurrentRenderer then
		gCurrentRenderer:SetSunLight(f)
	end
end

-- Submits Server GameTime to Client (4 bytes)
function gPacketHandler.kPacket_Game_Time()
	local input = GetRecvFIFO()
	local id = input:PopNetUint8()
	local hour = input:PopNetUint8()
	local minute = input:PopNetUint8()
	local second = input:PopNetUint8()
	printdebug("net",sprintf("NET (todo): Game_Time id: %i Hour: %i Min: %i Sec: %i\n",id, hour, minute, second))
	
	-- set Caelum Date
	gCurrentRenderer:UpdateMapEnvironment(hour,minute,second)
end

function gPacketHandler.kPacket_Logout()
	local input = GetRecvFIFO()
	local id = input:PopNetUint8()
	print("Serverside Logout because of inactivity.")
	print("FATAL ! kPacket_Logout -> forced Crash")
	NetCrash()
end

--[[
58 - New Region
Create a new region
0x6A bytes
byte	ID (58)	   
char[40]	Area Name
dword	0	   
word	X	   
word	Y	   
word	Width	   
Word	Height	   
Word	Z1	   
Word	Z2	   
char[40]	Description
Word	Sound FX	   
Word	Music
Word	Night Sound FX
Byte	Dungeon
Word	Light
]]--
function gPacketHandler.kPacket_New_Region()
	local input = GetRecvFIFO()
	local id = input:PopNetUint8()
	local areaname = input:PopFilledString(40)
	local unknown = input:PopNetUint32()
	local xloc = input:PopNetUint16()
	local yloc = input:PopNetUint16()
	local width = input:PopNetUint16()
	local height = input:PopNetUint16()
	local z1 = input:PopNetUint16()
	local z2 = input:PopNetUint16()
	local description = input:PopFilledString(40)

	local soundfx = input:PopNetUint16()
	local music = input:PopNetUint16()
	local nightsoundfx = input:PopNetUint16()
	local dungeon = input:PopNetUint8()
	local light = input:PopNetUint8()
	printdebug("net",sprintf("NET (todo): Areaname: %s Description: %s Music: %i Dungeon: %i Light: %i\n",areaname, description, music, dungeon, light))
end
