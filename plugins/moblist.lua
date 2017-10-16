
if (not gDisabledPlugins.moblist) then 

kMobList_CatW = 100
kMobList_CatItemH = 16
kMobList_CatItemBarH = 5
kMobList_CatItemBarYOff = 4
kMobList_CatDist = 0

kMoblist_npc_titles = {
	["[HEALERw]"]		= " the wandering healer",
	["[HEALER]"]		= " the healer",
	["[ESCORT]"]		= " the seeker of adventure",
	["[BSMITH]"]		= " the blacksmith",
	["[ASMITH]"]		= " the armorsmith",
	["[WSMITH]"]		= " the weaponsmith",
	["[TAIL]"]			= " the tailor",
	["[WEAV]"]			= " the weaver",
	["[TANN]"]			= " the tanner",
	["[FUR]"]			= " the furtrader",
	["[TINK]"]			= " the tinker",
	["[CARP]"]			= " the carpenter",
	["[ARCH]"]			= " the architect",
	["[BOW]"]			= " the bowyer",
	["[ESTA]"]			= " the real estate broker",
	["[HAIR]"]			= " the hairstylist",
	["[PROV]"]			= " the provisioner",
	["[COBB]"]			= " the cobbler",
	["[ALCH]"]			= " the alchemist",
	["[HERB]"]			= " the herbalist",
	["[NEWS]"]			= " the town crier",
	["[BANK]"]			= " the banker",
	["[MINT]"]			= " the minter",
	["[INN]"]			= " the innkeeper",
	["[JEWEL]"]			= " the jeweler",
	["[AUCTION]"]		= " the Auctioner",
}




kMainTargetListMarkerOffX = -7
kMainTargetListMarkerOffY = -2

kMobListCat_Self	= 1
kMobListCat_Friends	= 2
kMobListCat_Players	= 3
kMobListCat_Pets	= 4
kMobListCat_Rest	= 5
kMobList_MaxCat 	= kMobListCat_Rest

gSpellCastRange = 12

if (not cUOMobList) then
	cUOMobList = RegisterWidgetClass("UOMobList")
	cUOMobListItem = RegisterWidgetClass("UOMobListItem")

	gMobListNameShortCuts = {
		["deathwatch beetle hatchling"] = "dwb-hatchling",
		["DeathWatch Beetle hatchling"] = "DWB-Hatchling",
	}

	RegisterListener("Hook_Window_Resize",function (vw,vh) if (gMobList) then gMobList:Reposition(vw,vh) end end)
	RegisterListener("Hook_PostLoad",function () gMobList = GetDesktopWidget():CreateChild("UOMobList") end)
	RegisterListener("Hook_AttackReqSend",function (serial) SelectMobile(serial) end)
	RegisterListener("Hook_SelectMobile",function (serial) MobListSetMainTargetSerial(serial) end)
end

function cUOMobList:Reposition (vw,vh)
	self:SetPos(vw-kMobList_CatW,230)
end

function cUOMobList:Init (parentwidget,params)
	self:InitAsGroup(parentwidget,params)
	self.items = {}
	self.partyWidgetList = {}
	self.uoamWidgetList = {}
	self.catgroup = {}
	for i=1,kMobList_MaxCat do self.catgroup[i] = self:CreateChild("Group") end
	
	self.gfx_maintarget_listmarker = self:CreateChild("UOText",{x=0,y=0,text=">",col={r=1,g=0,b=0},bold=true})
	self.gfx_maintarget_listmarker:SetVisible(false)
	self.gfx_maintarget_listmarker2 = self:CreateChild("UOText",{x=0,y=0,text=">",col={r=0,g=0,b=1},bold=true})
	self.gfx_maintarget_listmarker2:SetVisible(false)
	self.gfx_maintarget = gRootWidget.tooltip:CreateChild("UOText",{x=0,y=0,text="",col={r=1,g=0,b=0},bold=true,html=true})
	self.gfx_maintarget_line = gRootWidget.tooltip:CreateChild("LineList",{matname="BaseWhiteNoLighting",bDynamic=true,r=1,g=0,b=0})
	
	local vw,vh = GetViewportSize()
	self:Reposition(vw,vh)
	
	RegisterListener("Hook_HUDStep",				function () 		self:Step() end)
	RegisterListener("Hook_MobName",				function (serial,name,clilocid) self:MobName(serial,name,clilocid) end) -- from several text/speak packets..
	RegisterListener("Hook_ToolTipUpdate",			function (serial)	self:ToolTipUpdate(serial) self:UpdatePartyNameTooltip(serial) end)
	RegisterListener("Hook_LabelUpdate",			function (serial)	self:ToolTipUpdate(serial) self:UpdatePartyNameTooltip(serial) end)
	RegisterListener("Hook_Object_CreateMobile",	function (mobile)	self:AddMob(mobile) end)
	RegisterListener("Hook_Object_DestroyMobile",	function (mobile)	self:RemoveMob(mobile) end)
	RegisterListener("Hook_UpdatePartyMemberList",	function ()			print("moblist:Hook_UpdatePartyMemberList") self:RecalcCat() self:UpdatePartyMemberList() self:UpdateAllNameGfx() end)
	RegisterListener("Hook_UOAM_PosUpdate",			function () 		self:UOAMUpdate() end)
end

function cUOMobList:UpdatePartyNameTooltip	(serial)
	local widget = self.partyWidgetList[serial]
	if (not widget) then return end
	widget.name = MobListShortenName(GetItemTooltipOrLabel(serial) or "???+")
	widget:SetUOHtml(widget.name,true)
end

function cUOMobList:UpdatePartyMemberList	()
	local partylist = GetPartyMemberList() -- {[serial]=true,...}
	local partyWidgetList = self.partyWidgetList
	for serial,v in pairs(partylist) do
		local widget = partyWidgetList[serial]
		if ((not widget) and serial ~= GetPlayerSerial()) then
			local name = MobListShortenName(GetItemTooltipOrLabel(serial) or "???#")
			widget = gRootWidget.tooltip:CreateChild("UOText",{x=0,y=0,text=name,col={r=0,g=1,b=0},bold=true,html=true})
			widget.name = name
			partyWidgetList[serial] = widget
		end
	end
	for serial,widget in pairs(partyWidgetList) do
		if (not partylist[serial]) then -- left party
			widget:Destroy()
			partyWidgetList[serial] = nil 
		end
	end
end

function cUOMobList:StepPartyMarkers	()
	for serial,widget in pairs(self.partyWidgetList) do
		local xloc,yloc,iFacet,bIsOnSameFacet = PartySystem_GetMemberPos(serial)
		local zloc = gPlayerZLoc or 0
		
		if (xloc) then
			local px,py = gCurrentRenderer:UOPosToPixelPos(xloc,yloc,zloc)
			local w,h = widget:GetSize()
			local minx,miny,maxx,maxy = 0,64,gViewportW-160,gViewportH-32
			local x = max(minx,min(maxx-w,(px or 0)-0.5*w))
			local y = max(miny,min(maxy-h,(py or 0)))
			widget:SetPos(x,y)
		end
		if (widget.oldbIsOnSameFacet ~= bIsOnSameFacet) then
			widget.oldbIsOnSameFacet = bIsOnSameFacet 
			widget.params.col = bIsOnSameFacet and {r=0,g=1,b=0} or {r=0.5,g=0.5,b=0.5}
			widget:SetUOHtml(widget.name,true)
		end
	end
end


-- triggered when uoam-data-packet is received
function cUOMobList:UOAMUpdate	()
	local uoamWidgetList = self.uoamWidgetList
	local uoamPosList = UOAM_GetOtherPositions()
	for name,data in pairs(uoamPosList) do -- {xloc=?,yloc=?,bIsOnSameFacet=?}
		local widget = uoamWidgetList[name]
		if (not widget) then 
			widget = gRootWidget.tooltip:CreateChild("UOText",{x=0,y=0,text=name,col={r=0,g=1,b=0},bold=true,html=true})
			uoamWidgetList[name] = widget
		end
		widget.xloc,widget.yloc = data.xloc,data.yloc
		widget.bIsOnSameFacet = data.bIsOnSameFacet
	end
	for name,widget in pairs(uoamWidgetList) do
		if (not uoamPosList[name]) then -- logged out
			widget:Destroy()
			uoamWidgetList[name] = nil
		end
	end
end

-- every frame
function cUOMobList:UOAMStep	()
	for name,widget in pairs(self.uoamWidgetList) do -- {xloc=?,yloc=?,bIsOnSameFacet=?}
		local xloc,yloc,zloc = widget.xloc,widget.yloc,(gPlayerZLoc or 0)
		local px,py = gCurrentRenderer:UOPosToPixelPos(xloc,yloc,zloc)
		local w,h = widget:GetSize()
		local minx,miny,maxx,maxy = 0,64,gViewportW-160,gViewportH-32
		local x = max(minx,min(maxx-w,(px or 0)-0.5*w))
		local y = max(miny,min(maxy-h,(py or 0)))
		widget:SetPos(x,y)
		if (widget.oldbIsOnSameFacet ~= widget.bIsOnSameFacet) then
			widget.oldbIsOnSameFacet = widget.bIsOnSameFacet 
			widget.params.col = widget.bIsOnSameFacet and {r=0,g=0.5,b=0} or {r=0.5,g=0.5,b=0.5}
			widget:SetUOHtml(name,true)
		end
	end
end

function cUOMobList:ToolTipUpdate		(serial)
	local mobile = GetMobile(serial)
	local item = mobile and mobile.moblist_item
	if (item) then item:UpdateName() end
end
function cUOMobList:MobName		(serial,name,clilocid)
	local mobile = GetMobile(serial)
	local item = mobile and mobile.moblist_item
	if (item and (not item.lowname)) then item:UpdateName(name,clilocid) end
end
function cUOMobList:AddMob		(mobile)
	self.bNeedsReGroup = true
	local item = self:CreateChild("UOMobListItem",{serial=mobile.serial,mobile=mobile,moblist=self})
	mobile.moblist_item = item
	self.items[item] = true
end
function cUOMobList:RemoveMob	(mobile) 
	local item = mobile.moblist_item
	if (not item) then return end
	mobile.moblist_item = nil
	self.items[item] = nil
	item:Destroy()
	self.bNeedsReGroup = true 
end

function cUOMobList:RecalcCat ()
	for item,v in pairs(self.items) do item:RecalcCat() end
end
function cUOMobList:UpdateAllNames ()
	for item,v in pairs(self.items) do item.old_fulltext = nil item:UpdateName() end
end

function cUOMobList:UpdateMainTargetListMarker ()
	if (self.maintarget_serial) then
		local mobile = GetMobile(self.maintarget_serial)
		local moblist_item = mobile and mobile.moblist_item
		if (moblist_item) then 
			local ax,ay = moblist_item:GetDerivedPos()
			local bx,by = self:GetDerivedPos()
			local y = ay-by
			self.gfx_maintarget_listmarker:SetVisible(true)
			self.gfx_maintarget_listmarker:SetPos(kMainTargetListMarkerOffX,kMainTargetListMarkerOffY+y)
		else
			self.gfx_maintarget_listmarker:SetVisible(false)
		end
	else
		self.gfx_maintarget_listmarker:SetVisible(false)
	end
end

function cUOMobList:UpdateSmartTargetIndicator ()
	local serial = MacroCmd_GetSmartTargetForLastSpell()
	local ypos = nil
	
	if (serial) then
		local mobile = GetMobile(serial)
		local moblist_item = mobile and mobile.moblist_item
		if (moblist_item) then 
			local ax,ay = moblist_item:GetDerivedPos()
			local bx,by = self:GetDerivedPos()
			ypos = ay-by
		end
	end
	-- only update if changed
	if (self.mySmartTargetIndicator_lastypos ~= ypos) then
		self.mySmartTargetIndicator_lastypos  = ypos
		if (ypos) then
			self.gfx_maintarget_listmarker2:SetVisible(true)
			self.gfx_maintarget_listmarker2:SetPos(kMainTargetListMarkerOffX-5,kMainTargetListMarkerOffY+ypos)
		else 
			self.gfx_maintarget_listmarker2:SetVisible(false)
		end
	end
end

function cUOMobList:SetMainTarget (serial,name)
	if (serial == 0 or serial == GetPlayerSerial() or serial == self.maintarget_serial) then serial = nil end
	if (serial and (not IsOrWasMobile(serial))) then return end
	self.maintarget_serial = serial
	self:UpdateMainTargetListMarker()
	--~ print("UOMobList:SetMainTarget",serial,name)
	local gfx  = self.gfx_maintarget
	local gfx2 = self.gfx_maintarget_line
	if (self.maintarget_serial) then
		gfx:SetVisible(true)
		gfx2:SetVisible(true)
		name = name or MobListShortenName(GetItemTooltipOrLabel(serial) or "???")
		local r,g,b = 1,1,1
		local mobile = GetMobile(serial)
		local notoriety = mobile and mobile.notoriety
		if (notoriety) then r,g,b = GetNotorietyColor(notoriety) end
		gfx:SetCol(r,g,b)
		gfx:SetUOHtml(name,true)
		MacroSetLastTarget(serial)
	else
		gfx:SetVisible(false)
		gfx2:SetVisible(false)
	end
end

function cUOMobList:UpdateAllNameGfx ()
	for item,v in pairs(self.items) do item:UpdateNameGfx() end
end

function cUOMobList:Step ()
	if (self.bNeedsReGroup) then
		self.bNeedsReGroup = false
		for k,group in pairs(self.catgroup) do group.itemcount = 0 end
		for item,v in pairs(self.items) do item:ReGroup(self.catgroup) end
		-- reposition groups
		local y = 0
		for k,group in ipairs(self.catgroup) do 
			group:SetPos(0,y) y = y + kMobList_CatItemH * group.itemcount + ((group.itemcount > 0) and kMobList_CatDist or 0)
		end
		self:UpdateMainTargetListMarker()
	end
	for item,v in pairs(self.items) do item:Step() end
	
	-- uoam-name-widgets
	self:UOAMStep()
	self:StepPartyMarkers()
	self:UpdateSmartTargetIndicator()
	
	-- maintarget text : update position on screen
	if (self.maintarget_serial) then
		local mobile = GetMobile(self.maintarget_serial)
		local xloc,yloc,zloc,notoriety
		local bInRange = true
		if (mobile) then 
			xloc,yloc,zloc = gCurrentRenderer:GetExactMobilePos(mobile)
			notoriety = mobile.notoriety
			self.maintarget_last_xloc = xloc
			self.maintarget_last_yloc = yloc
			self.maintarget_last_zloc = zloc
			self.maintarget_last_notoriety = notoriety
		else
			bInRange = false
			xloc = self.maintarget_last_xloc or 0
			yloc = self.maintarget_last_yloc or 0
			zloc = self.maintarget_last_zloc or 0
			notoriety = self.maintarget_last_notoriety or 0
		end
		local zadd = 10
		local gfx  = self.gfx_maintarget
		local gfx2 = self.gfx_maintarget_line
		local px,py = gCurrentRenderer:UOPosToPixelPos(xloc,yloc,zloc)
		local w,h = gfx:GetSize()
		local minx,miny,maxx,maxy = 0,64,gViewportW-160,gViewportH-32
		local x = max(minx,min(maxx-w,(px or 0)-0.5*w))
		local y = max(miny,min(maxy-h,(py or 0)))
		gfx:SetPos(x,y)
		local f = 0.5 -- bigger -> longer line
		local fi = 1 - f
		local x = max(minx,min(maxx,(px or 0)))
		local y = max(miny,min(maxy,(py or 0)))
		local x2 = x*fi + f*gViewportW*0.5
		local y2 = y*fi + f*gViewportH*0.5
		local r,g,b = GetNotorietyColor(notoriety)
		local brightness = 1
		if (IsOutsideRange(xloc,yloc,gPlayerXLoc,gPlayerYLoc,gSpellCastRange)) then brightness = 0.3 end
		if (not bInRange) then brightness = 0.1 end
		gfx2:SetColParam(r*brightness,g*brightness,b*brightness) 
		gfx2:SetLineList({{x2,y2,0,x,y,0}})
	end
end

-- ***** ***** ***** ***** ***** UOMobListItem

function cUOMobListItem:Init (parentwidget,params)
	self:InitAsGroup(parentwidget,params)
	self:SetIgnoreBBoxHit(false)
	self:SetConsumeChildHit(true)
	self.serial = params.serial
	self.mobile = params.mobile
	self.moblist = params.moblist
	self.text = self:CreateChild("UOText",{x=0,y=0,text="",col={r=1,g=1,b=1},fontid=2,bold=true,html=true})
	self.text:SetIgnoreBBoxHit(false)
	self.bNameUnknown = true
	
	local mobile = params.mobile
	local w,h = kMobList_CatW,kMobList_CatItemBarH
	local xoff,yoff = 0,kMobList_CatItemH+kMobList_CatItemBarYOff-kMobList_CatItemBarH
	self.fillw = w
	self.fillh = h
	
	local paramb = MakeSpritePanelParam_BorderPartMatrix(GetPlainTextureGUIMat("simplebutton.png"),w,h, xoff,yoff, 0,0, 4,8,4, 4,8,4, 32,32, 1,1, false, false)
	local paramf = MakeSpritePanelParam_BorderPartMatrix(GetPlainTextureGUIMat("simplebutton.png"),w,h, xoff,yoff, 0,0, 4,8,4, 4,8,4, 32,32, 1,1, false, false)
	paramb.r,paramb.g,paramb.b = 1,0,0
	self.border	= self:CreateChild("Image",{gfxparam_init=paramb})
	self.fill	= self:CreateChild("Image",{gfxparam_init=paramf,bVertexBufferDynamic=true})
	
	self:UpdateName()
	self:RecalcCat()
end

function MobListShortenName (text) return UOShortenName(text) end

function cUOMobListItem:on_mouse_left_drag_start	() 
	if (self.mobile and gKeyPressed[key_lalt]) then 
		local widget = OpenHealthbarAtMouse(self.mobile) 
		if (widget) then widget:BringToFront() widget:StartMouseMove() end
	end
end

function cUOMobListItem:UpdateName(name,clilocid)
	if (name and (not self.lowname)) then self.lowname = name self.namecliloc = clilocid end
	local tooltip = GetItemTooltipOrLabel(self.serial)
	local text = tooltip or self.lowname
	

	
	self.bNameUnknown = false
	if (not text) then self.bNameUnknown = true text = "unknown" end
	local bNameUpdate = false
	if (self.old_fulltext ~= text) then 
		self.old_fulltext = text
		bNameUpdate = true
		local fulltext = text
		text = MobListShortenName(text)
		
		--~ print("UOMobListItem:UpdateName","#"..(text or "").."#")
		text = gMobListNameShortCuts[text] or text
		
		-- npcs friends
		self.bIsNPC = false 
		if (StringContains(text,"guildmaster")) then text = "[GUILD]"..string.gsub(text,"guildmaster","") end
		for k,v in pairs(kMoblist_npc_titles) do 
			if (StringContains(text,v)) then self.bIsNPC = true text = k..string.gsub(text,v,"") end
		end
		
		local labelhue = GetItemLabelHue(self.serial)
		if (labelhue == kPlayerVendorLabelHue) then self.bIsNPC = true end
	
		text = string.gsub(text,"^([^%[%]]+)(%[.+%])","%2%1")
		self.old_text = text
		
		-- check friends
		self.bIsFriendlyGuild = false
		for k,guildtag in pairs(gFriendlyGuildTags) do if (StringContains(text,guildtag)) then self.bIsFriendlyGuild = true break end end
		--~ if (StringContains(text,"hazk")) then print("ghaz:",self.bIsFriendlyGuild) end
		
		-- check pets
		self.bIsPet = StringContains(fulltext,"(summoned)") or StringContains(fulltext,"(tame)")
		local mobile = self.mobile
		if (mobile.artid == 574 and mobile.hue == 0) then self.bIsPet = true end -- blade spirit
		if (mobile.artid == 164 and mobile.hue == 0) then self.bIsPet = true end -- energy vortex
	end
	
	
	self:RecalcCat()
	if (bNameUpdate) then self:UpdateNameGfx() end
end


function cUOMobListItem:UpdateNameGfx()
	local mobile = self.mobile
	local serial = self.serial
	local r,g,b = GetNotorietyColor(mobile.notoriety)
	local labelhue = GetItemLabelHue(serial)
	if (labelhue == kPlayerVendorLabelHue) then r,g,b = 0,1,1 end
	self.text.params.col = {r=r,g=g,b=b}
	local text = self.old_text
	--~ print("moblist:UpdateNameGfx",serial,IsMobileInParty(serial),text)
	if (labelhue) then r,g,b = GetHueColor(labelhue-1) end
	text = sprintf("<BASEFONT COLOR=#%02X%02X%02X>",floor(r*255),floor(g*255),floor(b*255)).."+".."</BASEFONT>"..text
	if (IsMobileInParty(serial)) then text = "<BASEFONT COLOR=#00FF00>#</BASEFONT>"..text end
	self.text:SetUOHtml(text,true) -- .." "..self.cat
end

function cUOMobListItem:SetSelfAsMainTarget ()
	self.moblist:SetMainTarget(self.serial,self.old_text or "???")
end

function cUOMobListItem:Step ()
	local mobile = self.mobile
	if (self.old_notoriety ~= mobile.notoriety) then 
		self.old_notoriety  = mobile.notoriety
		self:RecalcCat()
		self:UpdateNameGfx()
		-- todo : update bar-background color ? not visible when full hp ?
	end
	
	-- healthbar color
	local r,g,b = 0,0.5,1 -- blue
	if (IsMobilePoisoned(mobile))	then r,g,b = 0,0.5,0 end
	if (IsMobileMortaled(mobile))	then r,g,b = 1,1,0 end
	local gfxparam = self.fill.params.gfxparam_init
	gfxparam.r = r 
	gfxparam.g = g 
	gfxparam.b = b 

	-- healthbar size
	local f_hp = mobile:GetRelHP() or 1
	self.fill:SetSize(max(0,min(1,f_hp)) * self.fillw,self.fillh)
end

function cUOMobListItem:RecalcCat ()
	local serial = self.serial	
	local mobile = self.mobile
	local notoriety = mobile.notoriety
	--~ kNotoriety_Friend = 2 -- friend (necro familiar,pets)
	--~ kNotoriety_Red = 6 -- murderer (summons,evortex)
	--~ print("moblist:RecalcCat",serial,"party:",IsMobileInParty(serial),self.old_text)
	if (self.bNameUnknown) then 								return self:SetCat(kMobListCat_Rest) end
	if (GetPlayerSerial() == serial) then						return self:SetCat(kMobListCat_Self) end
	if (IsMobileInParty(serial) or self.bIsFriendlyGuild) then	return self:SetCat(kMobListCat_Friends) end
	if (self.bIsPet) then										return self:SetCat(kMobListCat_Pets) end 
	if (self.namecliloc) then
		if (notoriety == kNotoriety_Friend) then return self:SetCat(kMobListCat_Pets) end 
		local bIsHuman = mobile.artid == 400 or mobile.artid == 401  -- red humands like brigards,cannibals,ronins,ninjas...
		if (notoriety == kNotoriety_Red and (not bIsHuman)) then return self:SetCat(kMobListCat_Pets) end -- evortex,undead..
	end
	if (self.namecliloc or self.bIsNPC or notoriety == kNotoriety_Neutral) then return self:SetCat(kMobListCat_Rest) end
	if (notoriety == kNotoriety_Friend) then 	return self:SetCat(kMobListCat_Friends) end 
	if (notoriety == kNotoriety_Invul) then 	return self:SetCat(kMobListCat_Rest) end 
	return self:SetCat(kMobListCat_Players)
end

function cUOMobListItem:SetCat (cat)
	--~ local mobile = self.mobile
	--~ local notoriety = mobile.notoriety
	--~ print("cUOMobListItem:SetCat",cat,notoriety,GetItemTooltipOrLabel(self.serial))
	if (self.cat == cat) then return end
	if (cat == kMobListCat_Players) then NotifyListener("Hook_Moblist_NewPlayer",self.mobile,self.old_text) end
	self.cat = cat
	self.params.moblist.bNeedsReGroup = true
	self:UpdateNameGfx()
end

function cUOMobListItem:ReGroup (catgrouplist)
	local catindex = self.cat or 1
	local group = catgrouplist[catindex]
	local mypos = group.itemcount
	self:SetParent(group)
	self:SetPos(0,kMobList_CatItemH * mypos)
	group.itemcount = group.itemcount + 1
end


-- not needed anymore, now in IrisLeftClickDown()
--~ function cUOMobListItem:on_mouse_left_down	() if (not IsTargetModeActive()) then self:SetSelfAsMainTarget() end end 


-- ***** ***** ***** ***** ***** rest

function MobListGetMainTargetSerial() return gMobList and gMobList.maintarget_serial end
function MobListSetMainTargetSerial(serial) if (gMobList) then gMobList:SetMainTarget(serial) end end
		

end
