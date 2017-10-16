-- functions concerning mobiles (movable entities, npcs, monsters and the player)
-- see also net/net.skill.lua

--[[
the following fields are available : 
mobile.serial		
mobile.artid		
mobile.xloc			
mobile.yloc 		
mobile.zloc			
mobile.dir			
mobile.hue			
mobile.flag			
mobile.notoriety	
mobile.amount	-- only kPacket_Equipped_MOB, corpse related ?
mobile.dir2		-- only kPacket_Equipped_MOB, unknown

CreateOrUpdateMobile (mobiledata,equipmentdata)

Mobile_Update 				(mobile_or_serial,mobiledata,equipmentdata)
Mobile_UpdateFlags			(mobile_or_serial)
Mobile_UpdateStats 			(mobile_or_serial,stats)
Mobile_UpdateHealth 		(mobile_or_serial,curvalue,maxvalue)
Mobile_UpdateMana 			(mobile_or_serial,curvalue,maxvalue)
Mobile_UpdateStamina		(mobile_or_serial,curvalue,maxvalue)
Mobile_NameHint 			(mobile_or_serial,model,charname,message) 
Mobile_SetName	 			(mobile_or_serial,shortname,longname) 
Mobile_Destroy				(mobile_or_serial)
Mobile_DisplayTextOverHead	(mobile_or_serial,message,r,g,b)

each of those is also available as method you can call like mobile:(...) without the first param and without the Mobile_
]]--

-- kMobileGhostArtIDs = {402,403,607,608,970}
function IsGhostBodyID (bodyid) return in_array(bodyid,kMobileGhostArtIDs) end

gMobileSerialMemory = {}
function IsOrWasMobile (serial) return gMobileSerialMemory[serial] end

gMobilePrototype = {}
gbMobileMethodWrappersInitialized = false

function GetMobile (mobile_or_serial) 
	if (not mobile_or_serial) then return nil end
	if (type(mobile_or_serial) == "table") then return mobile_or_serial end
	return gMobiles[mobile_or_serial] -- look up by serial
end

function InitMobileMethodWrappers ()
	-- create method wrapppers, e.g. Mobile_UpdateFlags(serial) calls mobile:UpdateFlags()
	if (not gbMobileMethodWrappersInitialized) then 
		gbMobileMethodWrappersInitialized = true
		for method_name,method_impl in pairs(gMobilePrototype) do
			local mymethod_impl = method_impl
			_G["Mobile_"..method_name] = function (mobile_or_serial,...)
				local mobile = GetMobile(mobile_or_serial)
				if (mobile) then return mymethod_impl(mobile,...) end
			end
		end
	end
end

-- constructor, don't call directly, use CreateOrUpdateMobile() instead
function InitializeMobile	(serial)
	assert(serial ~= 0)
	InitMobileMethodWrappers()
	
	-- create base object and register in mobile-list
	local mobile = InitializeObject(serial)
	gMobiles[serial] = mobile
	
	-- install methods
	ArrayOverwrite(mobile,gContainerPrototype)
	ArrayOverwrite(mobile,gMobilePrototype)
	
	mobile.content = {}
	mobile.stats = {}
	mobile.serial = serial		
	mobile.artid = 0		
	mobile.xloc = 0
	mobile.yloc = 0
	mobile.zloc = 0		
	mobile.dir = 0			
	mobile.hue = 0			
	mobile.flag = 0			
	mobile.notoriety = 0	
	mobile.amount = 0
	mobile.ismobile = true -- needed to identify type in 2d renderer and for asserts
	mobile:UpdateFlags()
	
	NotifyListener("Hook_Object_CreateMobile",mobile)
	
	-- for mobile names and tooltips
	if (not gDisableSingleClickOnMobInit) then Send_SingleClick(serial,true) end
	gMobileSerialMemory[serial] = true
	
	return mobile
end

-- called from kPacket_Naked_MOB kPacket_Equipped_MOB kPacket_Teleport
function CreateOrUpdateMobile (mobiledata,equipmentdata)
	local mobile = GetMobile(mobiledata.serial)
	if (not mobile) then mobile = InitializeMobile(mobiledata.serial) end
	mobile:Update(mobiledata,equipmentdata)
	return mobile
end

function gMobilePrototype:NotifyListener	(eventname)
	NotifyListener(eventname..self.serial,self)
	NotifyListener(eventname,self)
end


-- ##### ##### ##### ##### ##### updates


function gMobilePrototype:UpdateContent () self.bEquipmentChanged = true self:Update() end

function gMobilePrototype:SetNotoriety(notoriety) self.notoriety = notoriety end -- also written by other means, don't use for notify, only used for walk-ack

function gMobilePrototype:GetSqDistToPos (xloc,yloc)
	local dx = self.xloc - xloc
	local dy = self.yloc - yloc
	return dx*dx + dy*dy
end

function gMobilePrototype:RequestEquipToolTips ()
	for index,layer in pairs(gLayerOrder) do 
		local item = GetMobileEquipmentItem(self,layer)
		if (item) then AosToolTip_GetText(item.serial) end
	end
end

-- returns nil if not available
function gMobilePrototype:GetRelHP ()
	return self.stats and self.stats.curHits and self.stats.maxHits and self.stats.curHits / self.stats.maxHits
end

-- updates mobile status, and the position of the graphical representation and other things
function gMobilePrototype:Update (mobiledata,equipmentdata)
	if (self.bDestructionInProgress) then return end -- avoid updates during destruction
	if (self.bEquipmentUpdateInProgress) then return end -- update triggered by
	
	if (mobiledata) then for k,v in pairs(mobiledata) do self[k] = v end end
	self:UpdateFlags()
	
	-- request basic stats info
	if (not self.stat_request_sent) then  
			self.stat_request_sent = true
		if (not gPacketVideoPlaybackRunning) then 
			Send_ClientQuery(gRequest_States,self.serial)
		end
	end
	
	-- update life stats in gui elements
	if (self.stats.curHits and self.stats.maxHits) then
		if (self.serial == gPlayerBodySerial) then
			-- for player
			SetHitpoints(self.stats.curHits/self.stats.maxHits)
			if (self.stats.curMana)		then 
				SetMana(	self.stats.curMana		/self.stats.maxMana		) 
			end
			if (self.stats.curStamina)	then SetStamina(self.stats.curStamina	/self.stats.maxStamina	) end
			-- update big_stats window
			UpdateStatusAos()
		else
			-- for other mobiles
			SetNpcHealthbarHitpoints(self, self.stats.curHits / self.stats.maxHits)
		end
	end
	
	-- full equipment overwrite
	if (equipmentdata) then
		self.bEquipmentUpdateInProgress = true -- prevent self:Update during equipment update...
		
		-- self:DestroyContent() -- destroy old equipment items  .. doesn't work as expected, closes backpack when player becomes invis
		for serial,object in pairs(self:GetContent()) do 
			local bFound = false
			for layer,dynamicdata in pairs(equipmentdata) do 
				if (dynamicdata.serial == object.serial) then bFound = true break end
			end
			if (not bFound) then object:Destroy() end
		end

		for layer,dynamicdata in pairs(equipmentdata) do
			CreateOrUpdateDynamic(dynamicdata,self)
		end
		self.bEquipmentUpdateInProgress = false
	end
	
	local bIsPlayer = self.serial == gPlayerBodySerial

	-- formchange
	if (self.oldartid ~= self.artid) then
		self.oldartid = self.artid
		self.bEquipmentChanged = true
	end
	
	-- if something related to equipment might have changed 
	-- this can also have happened if equipmentdata=nil, e.g. when an equipment item was destroyed directly
	-- maybe only in UpdateContent and/or if equipmentdata is set ?
	if (self.bEquipmentChanged) then
		self.bEquipmentChanged = false
		NotifyListener("Hook_MobileEquipmentChanged",self)
		if (bIsPlayer) then PlayerBackpackItemUpdated() end
		self:RequestEquipToolTips()
		local paperdoll = gPaperdolls[self.serial]
		if (paperdoll) then RebuildPaperdoll(paperdoll) end
		
		-- TODO : UpdateMobileModel does check for changes, but still a little expensive, only call if neccessary ?
		gCurrentRenderer:UpdateMobileModel(self)
	end
	

	self:NotifyListener("Mobile_Update")

	-- currently only for human (not elfs)
	local bIsGhost = IsGhostBodyID(self.artid)	
	if (bIsGhost ~= self.bIsGhost) then
		self.bIsGhost = bIsGhost
		if (bIsGhost) then
			printdebug("player","mobile is now ghost. isplayer,newartid = ",bIsPlayer,self.artid) 
		else
			printdebug("player","mobile is not ghost anymore. isplayer,newartid = ",bIsPlayer,self.artid)
		end
	end

	gCurrentRenderer:UpdateMobile( self )

	-- TODO : center Mobilename overhead, dont use fixed height - check height of mobiles (big dragons)
end

-- sets self.flag_* from self.flag
function gMobilePrototype:UpdateFlags	(bForceChange)
	self.flag_female			= TestBit( self.flag, kMobileFlag_Unknown2 )
	self.flag_poisoned			= IsMobilePoisoned(self) -- kMobileFlag_Poisoned
	self.flag_yellowhits		= IsMobileMortaled(self) -- kMobileFlag_GoldenHealth
	self.flag_factionship		= TestBit( self.flag, kMobileFlag_FactionShip )
	self.flag_explicitmovable	= TestBit( self.flag, kMobileFlag_Movable )
	self.flag_warmode	 		= TestBit( self.flag, kMobileFlag_WarMode )
	self.flag_hidden			= TestBit( self.flag, kMobileFlag_Hidden )
	
	if (self.old_flag ~= self.flag or bForceChange) then -- only if a change has occurred
		self.old_flag  = self.flag
		StatBar_UpdateMobileFlags(self)
		self:NotifyListener("Mobile_UpdateFlags")
	end
end


-- sets the lockstate of the stats (send by server)
-- lockstate (0=up, 1=down, 2=locked)
function gMobilePrototype:UpdateStatsLockState (str, dex, int)
	-- print("DEBUG","StatsLockStateUpdate",self.serial, str, dex, int)
	self.statslockstate = {str, dex, int}
	UpdateStatusAos()
end

function gMobilePrototype:UpdateStats (stats)
	-- local oldhp = mobile.stats.curHits or stats.curHits
	self.name = stats.name
	local oldstats = self.stats
	self.stats = stats
	if (stats.flag) then self.flag = stats.flag end
	self:NotifyListener("Mobile_UpdateStats")
	-- not needed due to normal damage packet
	-- TODO is this ok for every server?
	-- gCurrentRenderer:NotifyHPChange(self, mobile.stats.curHits)
	
	if (self.serial == gPlayerBodySerial) then
		local last_value = oldstats.str
		local value = stats.str
		if value and last_value and (last_value ~= value) then
			-- display change
			AddFadeLines("Attribute Strength is now "..sprintf("%3.0f",value).." -> "..sprintf("%3.0f",(value-last_value)),gStatsInfoFadeLineColor)
		end
		
		last_value = oldstats.dex
		value = stats.dex
		if value and last_value and (last_value ~= value) then
			-- display change
			AddFadeLines("Attribute Dexterity is now "..sprintf("%3.0f",value).." -> "..sprintf("%3.0f",(value-last_value)),gStatsInfoFadeLineColor)
		end
		
		last_value = oldstats.int
		value = stats.int
		if value and last_value and (last_value ~= value) then
			-- display change
			AddFadeLines("Attribute Intelligence is now "..sprintf("%3.0f",value).." -> "..sprintf("%3.0f",(value-last_value)),gStatsInfoFadeLineColor)
		end
	end
	
	self:Update()
end

function gMobilePrototype:UpdateHealth (curvalue,maxvalue)
	-- TODO pol sends normal hp update and x/1000 hp update ???? so i ignore the strange one
	if ((maxvalue ~= 1000) and self.stats) then
	
		local oldcur = self.stats.curHits or 0
		local oldmax = self.stats.maxHits or 0
		
		if self.stats.curHits then
			-- if there was a change, plop a text
			local old = self.stats.curHits
			gCurrentRenderer:NotifyHPChange(self, curvalue)
		end
		-- update values
		self.stats.curHits = curvalue
		self.stats.maxHits = maxvalue

		self:NotifyListener("Mobile_UpdateStats")
		if (IsPlayerMobile(self)) then NotifyListener("Mobile_UpdateHealth",self,oldcur,oldmax,curvalue,maxvalue) end
		self:Update()
	end
end

function gMobilePrototype:UpdateMana (curvalue,maxvalue)
	if (self and self.stats) then
		-- update values
		
		local oldcur = self.stats.curMana or 0
		local oldmax = self.stats.maxMana or 0
		
		if self.stats.curMana then
			-- if there was a change, plop a text
			local old = self.stats.curMana
			gCurrentRenderer:NotifyManaChange(self, curvalue)
		end

		self.stats.curMana = curvalue
		self.stats.maxMana = maxvalue

		if (self.serial == gPlayerBodySerial) then
			SetMana(curvalue/maxvalue)
			-- update big_stats window
			UpdateStatusAos()
		end

		self:NotifyListener("Mobile_UpdateStats")
		NotifyListener("Mobile_UpdateMana",self,oldcur,oldmax,curvalue,maxvalue)
		self:Update()
	end
end

function gMobilePrototype:UpdateStamina(curvalue,maxvalue)
	if (self.stats) then
		-- update values
		self.stats.curStamina = curvalue
		self.stats.maxStamina = maxvalue

		if (self.serial == gPlayerBodySerial) then
			SetStamina(curvalue/maxvalue)
			-- update big_stats window
			UpdateStatusAos()
		end

		self:NotifyListener("Mobile_UpdateStats")
		self:Update()
	end
end

-- triggered from kPacket_Text kPacket_Text_Unicode
function gMobilePrototype:NameHint (model,charname,message) 
	--~ 	if (charname == message) then
	--~ 		if (string.sub(message,1,1) == "[") then
	--~ 			self.somestate = message -- TODO : outputs stuff like [invulnerable]  , purpose unknown, probably for tooltipp
	--~ 			--printf("CatchTooltippRequest : serial=0x%08x somestate=%s\n",serial,message)
	--~ 		end
	--~ 	end
	if (not self.name) then 
		self.name = charname
		self:Update()
		--if (charname ~= message) then print("gMobilePrototype:NameHint : unexpected text:",charname,message) return false end
	end
end


-- 
function gMobilePrototype:SetName (shortname,longname) 
	self.shortname = shortname
	self.longname = longname
	self.name = shortname
	self:Update()
end

-- ##### ##### ##### ##### ##### destruction


function gMobilePrototype:Destroy ()
	self.bDestructionInProgress = true
	if (self.bIsDead) then print("warning, double free mobile") return end -- already destroyed before
	self:NotifyListener("Mobile_Destroy")
	NotifyListener("Hook_Object_DestroyMobile",self)
	
	-- destroy Status Gump from NPC
	--~ CloseHealthbar(self)
	
	self:DestroyContent() -- warning, triggers self:Update()
	
	gCurrentRenderer:DestroyMobileGfx( self )
	
	gMobiles[self.serial] = nil
	CleanupObject(self)
end


-- ##### ##### ##### ##### ##### the rest


function gMobilePrototype:GetWeapon() return self:GetEquipmentAtLayer(kLayer_OneHanded) or self:GetEquipmentAtLayer(kLayer_TwoHanded) end
function gMobilePrototype:GetEquipmentAtLayer(layer)
	for k,dynamic in pairs(self:GetContent()) do if (dynamic.layer == layer) then return dynamic end end
end

-- TODO: displays the chat text over the head of the mobile, color is 16bit uo color
function gMobilePrototype:DisplayTextOverHead(message,r,g,b)
	r = r or 0
	g = g or 0
	b = b or 0
	printdebug("mobile","DisplayTextOverHead",self.serial,message,r,g,b)
	self.mlastChatText = message
	self.mlastChatTime = gMyTicks
	self.mlastChatColor = {r = r,g = g,b = b}
	self:Update() -- trigger change in renderer
end

-- return r,g,b
function GetNotorietyColor (n)
	if (n ==  kNotoriety_Invalid	) then return 0.0 , 0.0 , 0.0 end -- invalid/across server line
	if (n ==  kNotoriety_Blue		) then return 0.1 , 0.1 , 1.0 end -- innocent (blue)
	if (n ==  kNotoriety_Friend		) then return 0.0 , 1.0 , 0.0 end -- guilded/ally (green)
	if (n ==  kNotoriety_Neutral	) then return 1.0 , 1.0 , 0.3 end -- attackable but not criminal (original : gray, here : yellow)
	if (n ==  kNotoriety_Crime		) then return 0.5 , 0.5 , 0.5 end -- criminal (gray)
	if (n ==  kNotoriety_Orange		) then return 1.0 , 0.5 , 0.0 end -- enemy (orange)
	if (n ==  kNotoriety_Red		) then return 1.0 , 0.0 , 0.0 end -- murderer (red)
	if (n ==  kNotoriety_Invul		) then return 1.0 , 0.0 , 1.0 end -- unknown use (translucent (like 0x4000 hue)) 
	return 0.5,0.5,0.5
end
