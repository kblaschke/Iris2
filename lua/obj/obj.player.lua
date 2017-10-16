-- stuff concerning player (body,backpack,equipment...)
-- see also net.mobile.lua net.paperdoll.lua net.container.lua

gUpdateRange_Base = 18 -- runuo2 update range is hardcoded to 18, leave a bit of tolerance for walking  (dist=max(dx,dy))
gUpdateRange_Add_DynamicDestroy	= 17 -- multisize
gUpdateRange_Add_MobileDestroy	= 0
gUpdateRange_Add_MobileZombie	= 0

gPlayerBodySerial = 0
gPlayerBackPack = false

function SetUpDateRange (range)
	gUpdateRange_Base = range
	-- not usually used, update range hardcoded to 18 on runuo2-svn, nothing else accepted
	gUpdateRange_DynamicDestroy	= range + gUpdateRange_Add_DynamicDestroy -- bigger than update range : big items like multis
	gUpdateRange_MobileDestroy	= range + gUpdateRange_Add_MobileDestroy	
	gUpdateRange_MobileZombie	= range + gUpdateRange_Add_MobileZombie -- if mobile is furhter away from player than this, then the mobile might be a zombie (dead on server, but still in client cache)
end
SetUpDateRange(gUpdateRange_Base)

function IsPlayerMobile (mobile) 
	return mobile and (mobile.serial == gPlayerBodySerial)
end

-- adjust backpack art and maybe paperdoll !!
-- items in backpack are updated -> update graphic here also
-- called from kPacket_Equipped_MOB and UpdatePlayerBodySerial
function PlayerBackpackItemUpdated ()
	-- warning ! don't trigger network send here
	local backpack = GetPlayerBackPackItem()
	if (backpack) then
		printdebug("player","PlayerBackpackItemUpdated: BACKPACK UPDATE")
		if ((not gPlayerBackPack) or (gPlayerBackPack.serial ~= backpack.serial)) then
			-- backpack item changed
			gPlayerBackPack = backpack
			if (not gDisableAutoOpenBackpack) then 
				if (gPlayerBackPack and (not gAltenatePostLoginHandling)) then Send_DoubleClick(gPlayerBackPack.serial) end
			end
		end
	-- else TODO : maybe check if backpack was removed ? must look if playerid is available so far
	end
end

-- returns cur,max
function GetPlayerWeight ()
	local playermobile = GetPlayerMobile()
	local stats = playermobile and playermobile.stats
	if (stats) then return stats.curWeight,stats.maxWeight end
end

function IsPlayerGhost ()
	local playermobile = GetPlayerMobile()
	return playermobile and playermobile.bIsGhost
end

function GetPlayerGold ()
	local playermobile = GetPlayerMobile()
	return playermobile and playermobile.stats and playermobile.stats.gold or 0
end

function GetPlayerMobile ()
	return gPlayerBodySerial and GetMobile(gPlayerBodySerial)
end
function GetPlayerSerial () return gPlayerBodySerial end

-- used by secure trade, mobile.name is filled by kPacket_Mobile_Stats
function GetPlayerName ()
	local mobile = GetPlayerMobile() if (not mobile) then return end
	local name = GetItemTooltipOrLabel(mobile.serial) or mobile.name 
	if (not name) then return end
	local a,b,nameshort = string.find(name,"%s*([^\n%[]+)%s+") -- remove guild tag and title
	nameshort = nameshort and string.gsub(string.gsub(nameshort,"^Lord ",""),"^Lady ","")
	return nameshort
end

function GetPlayerBackPackSerial () return gPlayerBackPack and gPlayerBackPack.serial end

function GetPlayerBackPackContainer ()
	if (not gPlayerBackPack) then return end -- not yet received from server
	return GetOrCreateContainer(gPlayerBackPack.serial) 
end

function GetPlayerBackPackItem ()
	local playermobile = GetPlayerMobile()
	if (playermobile) then return GetMobileEquipmentItem(playermobile,kLayer_Backpack) end
end

-- only available some time after login, see PlayerBackpackItemUpdated()
function TogglePlayerBackpack ()
	if (gPlayerBackPack) then
		if (IsContainerAlreadyOpen(gPlayerBackPack.serial)) then
			-- close backpack
			CloseContainer(gPlayerBackPack.serial)
		else
			-- open backpack
			Send_DoubleClick(gPlayerBackPack.serial)
		end
	else
		printdebug("player","backpack not available")
	end
end

function IsWarModeActive () return gActWarmode == gWarmode_Combat end

-- TODO : move to obj.player.lua ?
-- called from kPacket_SetPlayerWarmode
function NotifyWarmode	(flag)
	if (flag == gWarmode_Normal) then
		gActWarmode=gWarmode_Normal
		AddFadeLines("Peace be with you!")
		JournalAddText("","Peace be with you!")
		--printf("NET: kPacket_SetPlayerWarmode id: 0x%02x gWarmode: normal\n",id)
	end
	if (flag == gWarmode_Combat) then
		gActWarmode=gWarmode_Combat
		AddFadeLines("You go into War!")
		JournalAddText("","You go into War!")
		--printf("NET: kPacket_SetPlayerWarmode id: 0x%02x gWarmode: combat\n",id)
	end
	NotifyListener("Hook_WarmodeChange",IsWarModeActive())
	HealthBarSetWarMode()
end


-- called from handlers of kPacket_Login_Confirm and kPacket_Teleport
function UpdatePlayerBodySerial (serial)
	if (gPlayerBodySerial ~= serial) then 
		print("WARNING ! playerbody serial changed old,new=",gPlayerBodySerial,serial)

		-- update player serial and player backpack
		gPlayerBodySerial = serial
		PlayerBackpackItemUpdated()

		-- reinit player status dialog and stuff like this
		OpenPlayerHealthbar()
	end
end

function GetPlayerWeapon () local playermobile = GetPlayerMobile() return playermobile and playermobile:GetWeapon() end 

function PlayerGetMount ()
	local playermobile = GetPlayerMobile()
	return playermobile and playermobile:GetEquipmentAtLayer(kLayer_Mount)
end
function PlayerHasMount () return PlayerGetMount() ~= nil end

function GetUODistToPlayer(xloc,yloc) return gPlayerXLoc and max(abs(xloc-gPlayerXLoc),abs(yloc-gPlayerYLoc)) or 0 end

function GetUODistToPos (xloc,yloc,xloc2,yloc2)
	return max(abs(xloc - xloc2),abs(yloc - yloc2))
end
function IsOutsideRange (xloc,yloc,xloc2,yloc2,range)
	return abs(xloc - xloc2) > range or abs(yloc - yloc2) > range
end

-- destroy objects outside view range
function DestroyObjectsFarFromPlayer (player_xloc,player_yloc)
	local t = Client_GetTicks()
	local range_destroy = gUpdateRange_DynamicDestroy
	-- dynamics
	for k,dynamic in pairs(GetDynamicList()) do 
		if (DynamicIsInWorld(dynamic) and IsOutsideRange(dynamic.xloc,dynamic.yloc,player_xloc,player_yloc,range_destroy)) then
			DestroyObjectBySerial(dynamic.serial) 
		end 
	end
	-- mobiles
	local range_destroy	= gUpdateRange_MobileDestroy
	local range_zombie	= gUpdateRange_MobileZombie
	for k,mobile in pairs(GetMobileList()) do 
		if (IsOutsideRange(mobile.xloc,mobile.yloc,player_xloc,player_yloc,range_destroy)) then
			DestroyObjectBySerial(mobile.serial)
		end 
	end
end

