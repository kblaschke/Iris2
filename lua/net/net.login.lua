-- packet handlers for game startup
-- see also lib.packet.lua and lib.protocol.lua

gLoginFlags = 0x0000003F
gTooltipSupport = false
gPWReplace = "??????" -- prevent username/password appearing in debug dump

gCities = {}
gCharacterList = {}

function LoginDebug2 (txt) 
	--~ print("#>--<#LoginDebug2:"..os.date("%H:%M:%S")..":"..txt)
end

-- TODO : write Set_ClientFeatures function !!
function gPacketHandler.kPacket_Server_List ()  -- 0x5E  --0xa8 - Recieve Serverlist from LoginServer
	LoginDebug2("r:0x5E kPacket_Server_List")
	local input = GetRecvFIFO()
	local id = input:PopNetUint8()
	local serverlist = {}
	serverlist.size = input:PopNetUint16()
	serverlist.flags = input:PopNetUint8()
	serverlist.iServerNumber = input:PopNetUint16()	-- index on which server we play (maybe it's important later)
	printdebug("login",sprintf("NET: server list: size=0x%04x flags=0x%02x number=0x%04x\n",serverlist.size,serverlist.flags,serverlist.iServerNumber))

	-- use flag to find out the server emulator
	gServerEmulator	= serverlist.flags
	printdebug("login",sprintf("-> Emulator=: %s\n",gServerType[gServerEmulator] or "Unknown Server"))

	serverlist.servers = {}
	serverlist.servers_by_index = {}
	gSubServerNamesByID = {}
	for i = 0,serverlist.iServerNumber - 1 do
		local server = {}
		server.index = input:PopNetUint16()
		server.name = input:PopFilledString(32)
		server.full = input:PopNetUint8()
		server.tz = input:PopNetUint8() -- timezone
		server.ip = input:PopNetUint32()
		serverlist.servers[i] = server
		serverlist.servers_by_index[server.index] = server
		gSubServerNamesByID[server.index] = server.name
		
		local a = math.mod(floor(server.ip / 1),256)
		local b = math.mod(floor(server.ip / (256)),256)
		local c = math.mod(floor(server.ip / (256*256)),256)
		local d = math.mod(floor(server.ip / (256*256*256)),256)
		
		print("############# + + ++ +++ + +++ + +gSubServerNamesByID",server.index,server.name,a.."."..b.."."..c.."."..d)

		printdebug("login",sprintf("NET: [%i] '%s' full=%i tz=%i ip=%x\n",server.index,server.name,server.full,server.tz,server.ip))
	end
	MainMenuShowServerList(serverlist)
	NotifyListener("Hook_Packet_Server_List",serverlist)
end

-- len: 0x10C
function Send_SystemSpecs() -- 0xD9
	LoginDebug2("s:0xD9 Send_SystemSpecs")
	printdebug("login","NET: Send_SystemSpecs:")
	local out = GetSendFIFO()
	out:PushNetUint8(kPacket_Metrics)
	out:PushNetUint8(hex2num("0x02"))
	out:PushNetUint32(hex2num("0x442C637A"))
	out:PushNetUint32(hex2num("0x00000005"))
	out:PushNetUint32(hex2num("0x00000001"))
	out:PushNetUint32(hex2num("0x00000A28"))
	out:PushNetUint8(hex2num("0x02"))
	out:PushNetUint32(hex2num("0x00000006"))
	out:PushNetUint32(hex2num("0x0000000F"))
	out:PushNetUint32(hex2num("0x0000095A"))
	out:PushNetUint8(hex2num("0x02"))
	out:PushNetUint32(hex2num("0x00000600"))
	out:PushNetUint32(hex2num("0x00000500"))
	out:PushNetUint32(hex2num("0x00000400"))
	out:PushNetUint16(hex2num("0x0000"))
	out:PushNetUint16(hex2num("0x0020")) -- 48
	for i=1, 76 do
		out:PushNetUint8(0)
	end	-- 124
	out:PushNetUint32(hex2num("0x10020000"))
	out:PushNetUint32(hex2num("0x71C20000"))
	out:PushNetUint32(hex2num("0x01080002"))
	out:PushNetUint8(hex2num("0x06"))
	out:PushNetUint8(hex2num("0x10"))
	out:PushNetUint8(hex2num("0x64"))
	out:PushNetUint8(hex2num("0x00"))
	out:PushNetUint8(hex2num("0x65"))
	out:PushNetUint32(hex2num("0x00750000")) -- 145
	for i=1, 123 do
		out:PushNetUint8(0)
	end
	out:SendPacket()
end

-- Recieve Serverredirect from LoginServer (0x8c)
function gPacketHandler.kPacket_Server_Redirect () -- 0x8c
	LoginDebug2("r:0x8c kPacket_Server_Redirect")
	local input = GetRecvFIFO()
	local id = input:PopNetUint8()
	
	-- local gameserverip = input:PopNetUint32()
	local ip1 = input:PopNetUint8()
	local ip2 = input:PopNetUint8()
	local ip3 = input:PopNetUint8()
	local ip4 = input:PopNetUint8()
	local gameserverip = ip1.."."..ip2.."."..ip3.."."..ip4
	
	local gameserverport = input:PopNetUint16()
	local gameserveraccount = input:PopNetUint32()
	print(sprintf("NET: server redirect: id=0x%08x ip=%s port=%i AccountNr.:0x%08x\n",
			id,gameserverip,gameserverport,gameserveraccount))
	printdebug("login",sprintf("NET: server redirect: id=0x%08x ip=%s port=%i AccountNr.:0x%08x\n",
			id,gameserverip,gameserverport,gameserveraccount))
	printdebug("login",sprintf("DEBUG IP STRINGS %s <> %s\n",gameserverip,GetHostByName(gLoginServerIP)))

	if (gAltenatePostLoginHandling or ClientVersionIsPost7000()) then
		print("#######!!!!!!!!! REDIRECT : reconnect with NetConnectWithKey2")
		local res = NetConnectWithKey2(gameserverip,gameserverport,gameserveraccount)
		if (not res) then
			FatalErrorMessage("kPacket_Server_Redirect : login server redirect failed")
		end
		if (gHuffmanCompression) then NetStartHuffman() end
	else 
		-- login & gameserver are not the same: redirect is received
		if ((gServerType[gServerEmulator] == "SpherePolUox3") or (gameserverip ~= GetHostByName(gLoginServerIP)) or (gameserverport ~= gLoginServerPort)) then
			--disconnect from Loginserver
			printdebug("login","NET: disconnect from loginserver")
			NetDisconnect()
			print("##########!!!!!!!!!!!!!  kPacket_Server_Redirect NetDisconnect")
			--connect to gameserver
			printdebug("login","NET: connect to gameserver")
			local res = NetConnectWithKey(gameserverip,gameserverport,gameserveraccount)
			if (not res) then
				FatalErrorMessage("kPacket_Server_Redirect : login server redirect failed")
			end
		end

		--if Server support Huffman compress NetworkPackages turn it on (nearly all Emus should support this)
		if (gHuffmanCompression) then NetStartHuffman() end
	end

	Send_GameServer_PostLogin(gLoginname,gPassword,gameserveraccount)
end

-- Receive Client Features - this enabled several Features in Client   kPacket_Features 0xB9
--[[ TODO: Enable/Disable some client features
Flags:
0x01 = Enable T2A Features: chat button, new regions
0x02 = Enable LBR Features: skills, map
0x801C = Enable AOS features: new classes, skills, map, fightbook
0x8020 = Enable 6th Character Slot
0x0040 = Enable SE Features: new classes, spells, map
0x0080 = Enable ML Features: new race, spells
]]--
--NET: Client features received: 0x80fb
function gPacketHandler.kPacket_Features () -- 0xB9
	LoginDebug2("r:0xB9 kPacket_Features")
	local input = GetRecvFIFO()
	local id = input:PopNetUint8()
	if (ClientVersionIsPost60142()) then 
		gClientFeatures = input:PopNetUint32()
	else
		gClientFeatures = input:PopNetUint16()
	end
	printdebug("login",sprintf("NET: Client features received: 0x%04x\n",gClientFeatures))
end

-- Receive Character List from GameServer
function gPacketHandler.kPacket_Character_List() -- 0xA9
	LoginDebug2("r:0xA9 kPacket_Character_List")
	local characterslots = 5
	local input = GetRecvFIFO()
	local id = input:PopNetUint8()
	local charlist = {}
	charlist.size = input:PopNetUint16()
	local iBytesLeft = charlist.size - 3
	charlist.charnumber = input:PopNetUint8()
	iBytesLeft = iBytesLeft - 1
	
	

	--TODO: ?? check, because POL and Lonewolf sends current charnumber, not the number of slots

	printdebug("login",sprintf("NET: character list: size=%d charlist.charnumber=%d\n",charlist.size,charlist.charnumber))

	--~ print("login:charlist:hexdump" )
	--~ print(FIFOHexDump(input,0,iBytesLeft))
	charlist.charnumber = math.max(5,charlist.charnumber)
	
	for i = 0, charlist.charnumber-1 do
		gCharacterList[i] = {}
		gCharacterList[i].name=input:PopFilledString(30)
		gCharacterList[i].pw=input:PopFilledString(30)
		iBytesLeft = iBytesLeft - 2*30
		printdebug("login",sprintf("NET: CharacterID: %i Name: %s Password: %s\n",i,gCharacterList[i].name,gCharacterList[i].pw))
	end
	charlist.chars = gCharacterList
	
	charlist.citynumber = input:PopNetUint8()
	iBytesLeft = iBytesLeft - 1
	printdebug("login",sprintf("NET: Citynumber: %d\n",charlist.citynumber))
	local iBytesPerCity = 1+30+1+30+1
	local iTransmittedCityNumber = math.floor((iBytesLeft - 4) / iBytesPerCity)
	if (iTransmittedCityNumber ~= charlist.citynumber) then
		print("kPacket_Character_List WARNING : city number mismatch : num,real = ",charlist.citynumber,iTransmittedCityNumber)
		charlist.citynumber = min(charlist.citynumber,iTransmittedCityNumber)
	end
	for i = 0,charlist.citynumber-1 do
		iBytesLeft = iBytesLeft - iBytesPerCity
		gCities[i] = {}
		gCities[i].i=i
		gCities[i].index=input:PopNetUint8()
		gCities[i].name=input:PopFilledString(30)
		gCities[i].terminator1=input:PopNetUint8()
		gCities[i].tavern=input:PopFilledString(30)
		gCities[i].terminator2=input:PopNetUint8()

		printdebug("login",sprintf("NET: Index: %i City: %s Tavern: %s\n",gCities[i].index,gCities[i].name,gCities[i].tavern))
	end
	charlist.cities = gCities

	-- TODO : Serverspecific handling for Revelation Emu
	iBytesLeft = iBytesLeft - 4
	charlist.flags = input:PopNetUint32()
	printdebug("login",sprintf("ServerFlag: 0x%08x\n",charlist.flags))
	if (iBytesLeft > 0) then 
		print("kPacket_Character_List WARNING, bytes left, dumping",iBytesLeft)
		input:PopRaw(iBytesLeft)
	end

	--Flags list: 
	--0x02 = send config/req logout (IGR?) 
	--0x04 = single character (siege) 
	--0x08 = enable npcpopup menus 
	--0x10 = unknown 
	--0x20: enable common AOS features (tooltip thing/fight system book, but not AOS monsters/map/skills) 
	if ( TestBit(charlist.flags,hex2num("0x20")) ) then gTooltipSupport=true end

	--[[
	Flags (each flag is for each feature, if you need to combine features, you need to summ flags):
	0x2 = overwrite configuration button;
	0x4 = limit 1 character per account;
	0x8 = enable context menus;
	0x10 = limit character slots;
	0x20 = paladin and necromancer classes enable common AOS features (tooltip thing/fight system book, but not AOS monsters/map/skills);
	0x40 = 6th character slot;
	0x80 = samurai and ninja classes;
	0x100 = elven race;
	0x200 = KR support flag1;
	0x400 = KR support flag2
	]]--
	
	NotifyListener("Hook_Packet_Character_List",charlist)
	MainMenuShowCharList(charlist)
end

-- Receive Login Confirm from GameServer
function gPacketHandler.kPacket_Login_Confirm() -- 0x1B
	LoginDebug2("r:0x1B kPacket_Login_Confirm")
	local input = GetRecvFIFO()
	local id = input:PopNetUint8()

	local mobiledata = {}
	mobiledata.serial	= input:PopNetUint32()
	mobiledata.unknown1 = input:PopNetUint32()
	mobiledata.artid	= input:PopNetUint16()
	mobiledata.xloc	= input:PopNetUint16()
	mobiledata.yloc	= input:PopNetUint16()
	mobiledata.zloc	= input:PopNetInt8()
	--~ mobiledata.zloc	= gUse16BitZ and input:PopNetInt16() or input:PopNetInt8()
	mobiledata.zoldhigh	= input:PopInt8()
	mobiledata.dir	= input:PopNetUint8()

	mobiledata.unknown2 = input:PopNetUint16()
	mobiledata.unknown3 = input:PopNetUint32()

	mobiledata.unknown4 = input:PopNetUint32()
	mobiledata.flag	= input:PopNetUint8()
	mobiledata.notoriety = input:PopNetUint8()

	mobiledata.unknown5 = input:PopNetUint32()
	mobiledata.unknown6 = input:PopNetUint16()
	mobiledata.unknown7 = input:PopNetUint8()
	
	mobiledata.hue	= 0
	local playerid = mobiledata.serial

	gLoginConfirmPlayerSerial = mobiledata.serial
	print("#########!!!!!!!!!gLoginConfirmPlayerSerial",gLoginConfirmPlayerSerial)

	--Send Client ident string
	if (gAltenatePostLoginHandling) then
		-- this is only for special shards 
		InvokeLater(1000,SendLoginConfirmSpecials)
	else
		-- normally call this
		SendLoginConfirmSpecials()
	end
	--~ Send_UpdateRangeRequest(gUpdateRange_Base)

	StartInGame()
	
	-- TODO : HintStartPosition(mobiledata.xloc, mobiledata.yloc, mobiledata.zloc) hint for campos ?
	UpdatePlayerBodySerial(mobiledata.serial)
	CreateOrUpdateMobile(mobiledata)
end

function SendLoginConfirmSpecials ()
	print("#########!!!!!!!!!SendLoginConfirmSpecials",gAltenatePostLoginHandling,gLoginConfirmPlayerSerial)
	if (gLoginConfirmPlayerSerial) then
		Send_ClientQuery(gRequest_Skills,gLoginConfirmPlayerSerial,true)
	end
	Send_ClientVersion(gClientVersion or "4.0.11c5 3D") 
	Send_Screensize()
	Send_ClientLanguage(gLanguage or "ENU") 
	Send_UnknownCommand() 
	if (not gAltenatePostLoginHandling) then Send_UnknownSE() end
	if (gPlayerBackPack) then Send_DoubleClick(gPlayerBackPack.serial) end
	gSendSelfDoubleClickAtNextContainerContents = true
	--~ if (gLoginConfirmPlayerSerial) then Send_DoubleClick(BitwiseOR(gLoginConfirmPlayerSerial,0x80000000)) end -- 0x800... : prevents dismount, and only opens paperdoll
	Send_ClientQuery(gRequest_States,gLoginConfirmPlayerSerial,true)
	if (gAltenatePostLoginHandling) then 
		gNet_AlternatePostLogin_UnknownSESenderRevision = (gNet_AlternatePostLogin_UnknownSESenderRevision or 0) + 1
		local myrev = gNet_AlternatePostLogin_UnknownSESenderRevision
		RegisterIntervalStepper(4000,function ()
			if (not gInGameStarted) then return end
			if (myrev ~= gNet_AlternatePostLogin_UnknownSESenderRevision) then return true end
			Send_UnknownSE(math.random(1,255))
			end) 
	end
end

-- if packet is received we can Start the Game now !
-- works on RunUO...don't know if all servers send this !?
-- StartGame Packet
function gPacketHandler.kPacket_Login_Complete()
	LoginDebug2("r:0x55 kPacket_Login_Complete")
	local input = GetRecvFIFO()
	local id = input:PopNetUint8()
	printdebug("login",sprintf("NET: Login_Complete with id: %i\n",id))
	GuiAddChatLine("NET: Login_Complete with id: " .. id) 

	--Start World
	--~ StartInGame()
end

kLoginRejectReason = {}
kLoginRejectReason.CharNoExist		= {code=1,text="CharNoExist(character deleted?)"}
kLoginRejectReason.CharExists		= {code=2,text="CharExists(charname taken?)"}
kLoginRejectReason.CharInWorld		= {code=5,text="another character is already online"}
kLoginRejectReason.LoginSyncError	= {code=6,text="LoginSyncError"}
kLoginRejectReason.IdleWarning		= {code=7,text="server is idle"}

-- Loginserver Login rejected - Errorcode returned
function gPacketHandler.kPacket_Login_Reject() -- 0x53
	LoginDebug2("r:0x53 kPacket_Login_Reject")
	local input = GetRecvFIFO()
	local id = input:PopNetUint8()
	local value = input:PopNetUint8()
	local txt = "?"
	for k,v in pairs(kLoginRejectReason) do if (value == v.code) then txt = v.text end end
	local msg = sprintf("Login_Reject %d %s",value,txt)
	print(msg)
	FatalErrorMessage(msg) 
end

kAccountLoginRejectReason = {}
kAccountLoginRejectReason.Invalid		= {code=0x00,text="Invalid username"}
kAccountLoginRejectReason.InUse			= {code=0x01,text="account is already in use"}
kAccountLoginRejectReason.Blocked		= {code=0x02,text="Banned account"}
kAccountLoginRejectReason.BadPass		= {code=0x03,text="wrong password"}
kAccountLoginRejectReason.v7ok			= {code=0xFB,text="uo_protocol_v7_login_ok_bug"}
kAccountLoginRejectReason.Idle			= {code=0xFE,text="idle"}
kAccountLoginRejectReason.BadComm		= {code=0xFF,text="badcom or illegal username/pw"}
		
-- GameServer Login failed - Errorcode returned
function gPacketHandler.kPacket_Account_Login_Failed() -- 0x82
	LoginDebug2("r:0x82 kPacket_Account_Login_Failed")
	local input = GetRecvFIFO()
	local id = input:PopNetUint8()
	local value = input:PopNetUint8()
	if (value == kAccountLoginRejectReason.v7ok) then 
		print("kAccountLoginRejectReason.v7ok,see 0xb9 sent right before") -- http://docs.polserver.com/packets/index.php?Packet=0xB9
		return
	end
	
	local txt = "communications failed"
	for k,v in pairs(kAccountLoginRejectReason) do if (value == v.code) then txt = k.." "..v.text end end
	local msg = sprintf("Account_Login_Failed %d %s",value,txt)
	print(msg)
	MainMenuLoginRejected(msg) 
	--~ FatalErrorMessage(msg) 
end

-- Server requests Clientversion (NEW?)
function gPacketHandler.kPacket_Client_Version() -- 0xBD
	LoginDebug2("r:0xBD kPacket_Client_Version")
	local input = GetRecvFIFO()
	local id = input:PopNetUint8()
	local value = input:PopNetUint16()
	printdebug("login",sprintf("NET: Request Clientversion = %i\n",value))
	GuiAddChatLine("NET: Request Clientversion " .. value)

	--Send Client ident string
	Send_ClientVersion(gClientVersion or "4.0.11c5 3D")
end

-- Send Packets -----------------------------------------------------------

function UOLoginPushFilledStringAddByte (fifo,str,filllen,addbyte)
	if (true) then fifo:PushFilledString(str,filllen) return end -- deactivated for now
	-- original seem to place addbyte=0x74 after the first 0 byte in the string.. (hybrid check?) ..nope...
	local namefifo = CreateFIFO()
	namefifo:PushFilledString(str,filllen)
	local bWaitForFirstZero = true
	local bNextZeroReplaced = false
	for i = 0,namefifo:Size()-1 do 
		local c = namefifo:PeekNetUint8(i)
		if (c == 0 and bNextZeroReplaced) then c = addbyte bNextZeroReplaced = false end
		if (c == 0 and bWaitForFirstZero) then bWaitForFirstZero = false bNextZeroReplaced = true end
		fifo:PushNetUint8(c)
	end
	namefifo:Destroy()
end

-- send login server request 0x80
-- answered by 0xA8 kPacket_Server_List which calls MainMenuShowServerList
function Send_Account_Login_Request	(sName,sPassword,iSeed) -- 0x80
	gLoginname = sName
	if (sPassword == "") then sPassword = GetStoredPassword(gLoginServerIP,gLoginServerPort,gLoginname) or sPassword end
	gPassword = sPassword
	LoginDebug2("s:0x80 Send_Account_Login_Request")
	printdebug("login",sprintf("NET: Account_Login_Request: Name: %s Password: %s\n",gPWReplace or sName,gPWReplace or sPassword))
	local out = GetSendFIFO()
	out:PushNetUint8(kPacket_Account_Login_Request) -- 0x80
	
	
	UOLoginPushFilledStringAddByte(out,sName,30,0x74)
	out:PushFilledString(sPassword,30)
	out:PushNetUint8(iSeed or hex2num("0x5D"))
	out:SendPacket()
	gNextPingTime = gMyTicks + gPingInterval
end

-- send gameserverselect to loginserver : kPacket_Server_Select 0xA0
-- answered by kPacket_Server_Redirect 0x8C
-- which calls Send_GameServer_PostLogin kPacket_Post_Login 0x91 
function Send_GameServer_Select(iGameServerID) -- 0xA0
	LoginDebug2("s:0xA0 Send_GameServer_Select")
	printdebug("login",sprintf("NET: GameServer_Select: %i\n",iGameServerID))
	giGameServerID = iGameServerID
	local out = GetSendFIFO()
	out:PushNetUint8(kPacket_Server_Select) -- 0xA0
	out:PushNetUint16(iGameServerID)
	out:SendPacket()
end

-- send postlogin to gameserver  kPacket_Post_Login 0x91
-- something is wrong...runuo & wolfpack detects invalid client
-- answered by kPacket_Features 0xB9 and  kPacket_Character_List 0xA9
function Send_GameServer_PostLogin(sName,sPassword,iAccount) -- 0x91
	LoginDebug2("s:0x91 Send_GameServer_PostLogin")
	printdebug("login",sprintf("NET: GameServer_PostLogin: Name: %s Password: %s AccountNr.: 0x%08x\n",gPWReplace or sName,gPWReplace or sPassword,iAccount))
	local out = GetSendFIFO()
	out:PushNetUint8(kPacket_Post_Login) -- 0x91
	out:PushNetUint32(iAccount)
	UOLoginPushFilledStringAddByte(out,sName,30,0x74)
	out:PushFilledString(sPassword,30)
	out:SendPacket()
end

-- send characterselect to gameserver
function Send_CharCreate(chardata)
	local skillid = gCharCreateSkillIDs["Stealth"]
	assert(	chardata.skill1 ~= skillid and
			chardata.skill2 ~= skillid and
			chardata.skill3 ~= skillid,"Stealth skill not allowed at charcreate")
	local skillid = gCharCreateSkillIDs["Remove Trap"]
	assert(	chardata.skill1 ~= skillid and
			chardata.skill2 ~= skillid and
			chardata.skill3 ~= skillid,"Remove Trap skill not allowed at charcreate")
	local skillid = gCharCreateSkillIDs["Spellweaving"]
	assert(	chardata.skill1 ~= skillid and
			chardata.skill2 ~= skillid and
			chardata.skill3 ~= skillid,"Spellweaving skill not allowed at charcreate")
			
	local out = GetSendFIFO()
	out:PushNetUint8(kPacket_CharacterCreation) -- 0x00
	out:PushNetUint32(hex2num("0xedededed"))
	out:PushNetUint32(hex2num("0xffffffff"))
	out:PushNetUint8(hex2num("0x00"))
	out:PushFilledString(chardata.name,30)
	
	-- old : password
	out:PushNetUint16(0)						-- 2
	out:PushNetUint32(gLoginFlags) 				-- 4 -- login flags, for available maps/facets etc, (previous : chardata.flags or 0)
	out:PushNetUint32(0)						-- 4
	out:PushNetUint32(0)						-- 4
	out:PushNetUint8(chardata.prof or 0)		-- 1
	out:PushFilledString("",15)
			
	out:PushNetUint8(chardata.sex) -- (0=male, 1=female, 2=elf male, 3=elf female)
	out:PushNetUint8(chardata.str)
	out:PushNetUint8(chardata.dex)
	out:PushNetUint8(chardata.int)
	out:PushNetUint8(chardata.skill1) -- (see list below)
	out:PushNetUint8(chardata.skill1value)
	out:PushNetUint8(chardata.skill2) -- (see list below)
	out:PushNetUint8(chardata.skill2value)
	out:PushNetUint8(chardata.skill3) -- (see list below)
	out:PushNetUint8(chardata.skill3value)
	out:PushNetUint16(chardata.skinColor)
	out:PushNetUint16(chardata.hairStyle) -- The artwork number for the character's hair.
	out:PushNetUint16(chardata.hairColor)
	out:PushNetUint16(chardata.facialHair) -- The artwork number for the character's beard.
	out:PushNetUint16(chardata.facialHairColor)
	out:PushNetUint16(chardata.location) --  The character's starting city (as listed in the character list).
	out:PushNetUint16(hex2num("0x0000"))
	out:PushNetUint16(chardata.slot) -- is this really 16 bit ?  The character slot number.
	out:PushNetUint32(gServerSeed) -- The user's gameplay encryption key ? clientIP ?    (runuo2.0 : clientIP)
	out:PushNetUint16(chardata.shirtColor)
	out:PushNetUint16(chardata.pantsColor)
	out:SendPacket()
end

-- send characterselect to gameserver  0x5D
--[[
       -- -- -- -- -- -- -- --  -- -- -- -- -- -- -- --
0000   5D ED ED ED ED 47 68 6F  6E 67 6F 6C 61 73 00 00   ]....Ghongolas..
0010   00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00   ................
0020   00 00 00 00 00 00 00 00  3F 00 00 00 00 00 00 00   ........?.......
0030   30 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00   0...............
0040   00 00 00 00 02 0A 00 02  0F                        .........
]]--
function Send_Character_Select(iCharacterID,iAccount) -- 0x5D
	LoginDebug2("s:0x5D Send_Character_Select")
	printdebug("login",sprintf("NET: Character_Select: %i Name: %s Password: %s AccountNr.:%x\n",
			iCharacterID,gCharacterList[iCharacterID].name,gCharacterList[iCharacterID].pw,iAccount))
			
	gCharName = gCharacterList[iCharacterID].name
	gCharID = iCharacterID
	
	local out = GetSendFIFO()
	out:PushNetUint8(kPacket_Pre_Login) -- 0x5D		--  1 :  1
	out:PushNetUint32(hex2num("0xedededed"))		--  4 :  5
	out:PushFilledString(gCharName,30)				-- 30 : 35

	
			
			
	--	out:PushFilledString(gCharacterList[iCharacterID].pw,30)

	out:PushNetUint16(0)							--  2 : 37
	
			
													--  4 : 41
	--~ out:PushNetUint32(0x0000001F)	-- RunUO uses this unknown flags (maybe for map 3,4 support) (pre.08.02.2008)
	out:PushNetUint32(gLoginFlags)		-- 6.0.9.2 RunUO uses this unknown flags (maybe for map 3,4 support) (08.02.2008:ghoul:packetlog from razor login has 0x3f here)
	-- razor : int flags = pvSrc.ReadInt32();
	
	
	-- new : 31.03.2009
	out:PushNetUint8(0x00)
	out:PushNetUint8(0x00)
	out:PushNetUint8(0x00)
	out:PushNetUint32(0x00000000)
	
	-- addr0x30
	out:PushNetUint32(0x37000000) -- was 0x30000000  before?
	out:PushNetUint32(0x00000000)
	out:PushNetUint32(0x00000000)
	out:PushNetUint32(0x00000000)
	
	-- addr0x40
	out:PushNetUint8(0x00)
	
	out:PushNetUint32(iCharacterID)
	
	out:PushNetUint8(0x7F)
	out:PushNetUint8(0x0C)
	out:PushNetUint8(0x22)
	out:PushNetUint8(0x38)
	
	--[[ old :31.03.2009
	out:PushFilledString("",6)					--  6 : 47 -- obsolete for RunUO
	--~ out:PushNetUint16(hex2num("0x004B"))		--  2 : 49 -- obsolete for RunUO - 0x4A (2D_V.5.0.8.2_ML) 0x4B (2D_V.5.0.9.1_ML) (pre.08.02.2008)
	out:PushNetUint16(hex2num("0x0030"))		--  2 : 49 -- obsolete for RunUO - 6.0.9.2 (08.02.2008:ghoul:packetlog from razor login has 0x30 here)
	out:PushFilledString("",16)					-- 16 : 65 -- obsolete for RunUO

	out:PushNetUint32(iCharacterID)				--  4 : 69
	--~ int charSlot = pvSrc.ReadInt32();
	
	out:PushNetUint32(hex2num("0xC0A83016"))	--  4 : 73 --TODO: check: iAccount or GameServerIP
	]]--
	out:SendPacket()
end

-- client identification  0x34
function Send_ClientQuery(iMode,iCharacterID,bAlternateForced)
	if (gbDisableClientQuery and (not bAlternateForced)) then return end
	LoginDebug2("s:0x34 Send_ClientQuery"..iMode..sprintf(":0x%08x",iCharacterID))
	--~ print(_TRACEBACK())
	local out = GetSendFIFO()
	out:PushNetUint8(kPacket_Client_Query) -- 0x34
	out:PushNetUint32(hex2num("0xedededed"))
	out:PushNetUint8(iMode)
	out:PushNetUint32(iCharacterID)
	out:SendPacket()
end

-- Submits ClientVersion to Server
function Send_ClientVersion(sClientVersion)
	LoginDebug2("s:0xBD Send_ClientVersion")
	printdebug("login",sprintf("NET: Client_Version: Client identified as %s.\n", sClientVersion))
	local out = GetSendFIFO()
	local size = string.len(sClientVersion)
	out:PushNetUint8(kPacket_Client_Version) -- 0xBD
	out:PushNetUint16(4+size)
	out:PushFilledString(sClientVersion,size)
	out:PushNetUint8(0)
	out:SendPacket()
end

-- Submits Client Language to Server
function Send_ClientLanguage(lang)
	LoginDebug2("s:0xBF Send_ClientLanguage")
	printdebug("login",sprintf("NET: Client submits ClientLanguage=%s\n",lang))
	local out = GetSendFIFO()
	out:PushNetUint8(kPacket_Generic_Command) -- 0xBF
	out:PushNetUint16(hex2num("0x09"))
	out:PushNetUint16(kPacket_Generic_SubCommand_ClientLanguage)
	out:PushFilledString(string.lower(lang), 3)
	out:PushNetUint8(0)
	out:SendPacket()
end

-- Submits Screensize
function Send_Screensize()
	LoginDebug2("s:0xBF Send_Screensize")
	printdebug("login",sprintf("NET: Client submits Screensize=%s\n","x,y"))
	local out = GetSendFIFO()
	out:PushNetUint8(kPacket_Generic_Command) -- 0xBF
	out:PushNetUint16(0x0D)
	out:PushNetUint16(kPacket_Generic_SubCommand_Screensize)
	out:PushNetUint32(0x00000320)
	out:PushNetUint32(0x3FE9AC28)
	out:SendPacket()
end

-- Submits Unknown Cmd2
function Send_UnknownCommand()
	LoginDebug2("s:0xBF Send_UnknownCommand")
	printdebug("login",sprintf("NET: Client submits Unknowncmd=%s\n","0x0A0000001F"))
	local out = GetSendFIFO()
	out:PushNetUint8(kPacket_Generic_Command) -- 0xBF
	out:PushNetUint16(0x0A)
	out:PushNetUint16(0x000F)
	out:PushNetUint32(0x0A000000)
	out:PushNetUint8(0x3F) -- old:0x1F
	out:SendPacket()
end



-- Submits UnknownSE
function Send_UnknownSE(databyte)
	LoginDebug2("s:0xBF Send_UnknownSE")
	printdebug("login",sprintf("NET: Client submits UnknownSE%s\n",""))
	local out = GetSendFIFO()
	out:PushNetUint8(kPacket_Generic_Command) -- 0xBF
	out:PushNetUint16(0x06)
	out:PushNetUint16(kPacket_Generic_SubCommand_UnknownSE)
	out:PushNetUint8(databyte or 0x83)
	out:SendPacket()
end
