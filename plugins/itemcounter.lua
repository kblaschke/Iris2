-- counts items like regs,bandages,potions...

--~ regchange usage after cast : kPacket_Object_to_Object kPacket_Destroy kPacket_Show_Item 

if (not gDisabledPlugins.itemcounter) then 

if (gItemCounterDialog) then gItemCounterDialog:Destroy() gItemCounterDialog = nil end

kItemCounterUsageType_UseInHand = 1
kItemCounterUsageType_Use = 2

kItemCounterLowAmount = 10
kItemCounterBagType = 0xe76

gItemCounterTypeGroups = {
	{ -- mageregs
		{name="blackperl"	,artid=0xf7a},
		{name="bloodmoss"	,artid=0xf7b}, 
		{name="mandrake"	,artid=0xf86},
		{name="garlic"		,artid=0xf84},
		{name="ginseng"		,artid=0xf85},
		{name="nightshade"	,artid=0xf88},
		{name="spidersilk"	,artid=0xf8d},    
		{name="sulfurusash"	,artid=0xf8c},  
	},
	{ -- necroregs
		{name="pigiron"		,artid=0xf8a},
		{name="noxcrystal"	,artid=0xf8e},
		{name="demonblood"	,artid=0xf7d},
		{name="gravedust"	,artid=0xf8f},
		{name="batwing"		,artid=0xf78},
	},
	{ -- pots
		{name="gheal"		,artid=3852,	usagetype=kItemCounterUsageType_UseInHand},
		{name="gcure"		,artid=3847,	usagetype=kItemCounterUsageType_UseInHand},
		{name="refresh"		,artid=3851,	usagetype=kItemCounterUsageType_UseInHand},
		{name="explo"		,artid=3853,	usagetype=kItemCounterUsageType_UseInHand},
		{name="dexpot"		,artid=0xF08,	usagetype=kItemCounterUsageType_UseInHand},
		{name="strpot"		,artid=0xF09,	usagetype=kItemCounterUsageType_UseInHand},
	},
	-- individual
	{{name="blankscroll"	,artid=0xef3}},
	{{name="board"			,artid=0x1bd7}},
	{{name="log"			,artid=0x1bdd}},
	{{name="ore"			,artid=0x19b9}},
	{{name="ingot"			,artid=0x1bf2}},
	{{name="bottle"			,artid=0xf0e,hue=0}},
	{{name="gold"		,artid=0xeef,hue=0}},
	{{name="sand"		,artid=0xeef,hue=2107}}, -- pangaea
	{{name="shovel"		,artid=0xf39}},
	{{name="bandas"		,artid=0xe21,	usagetype=kItemCounterUsageType_Use}},
	{{name="arrows"		,artid=3903,hue=0}},
	{{name="bolts"		,artid=0x1bfb,hue=0}},
	{{name="gheal"		,artid=0xf0e,hue=2125}},
	
	{ -- tailor
		{name="cloth"			,artid=0x1766},
		{name="spoolofthread"	,artid=0xfa0},
		{name="boltofcloth"		,artid=0xf95},
		{name="cotton"			,artid=0xdf9},
		{name="ballofyard"		,artid=0xe1d},
		{name="ballofyard"		,artid=0xe1e},
		{name="ballofyard"		,artid=0xe1f},
	},
}

gItemCounterTypesByArtID 	= {}
for k,group in pairs(gItemCounterTypeGroups) do 
	for k2,v in pairs(group) do 
		gItemCounterTypesByArtID[v.artid] = true 
	end
end


function ItemCounterOne (artid,baglist,hue) 
	local c = MacroCmd_Item_SumByArtID(artid,hue) 
	for k,bag in pairs(baglist or ItemCounterGetBagList() or {}) do c = c + MacroCmd_Item_SumByArtID(artid,hue,bag) end
	return c
end

-- dynamicdata.iContainerSerial
RegisterListener("Mobile_UpdateStats",	function (mobile) if (IsPlayerMobile(mobile)) then gItemCounterNeedsUpdate = true end end)
RegisterListener("Dynamic_Update",		function (item) if (gItemCounterTypesByArtID[item.artid]) then gItemCounterNeedsUpdate = true end end)
RegisterListener("Dynamic_Destroy",		function (item) if (gItemCounterTypesByArtID[item.artid]) then gItemCounterNeedsUpdate = true end end)
RegisterStepper(function () if (gItemCounterNeedsUpdate) then ItemCounterUpdate() end end)
-- item:IsInContainer(GetPlayerBackPackSerial())

function ItemCounterGetBagList () return MacroCmd_Item_FindByArtID(kItemCounterBagType) end

function ItemCounterUpdate ()
	if (not gInGameStarted) then return end
	if (gNoOgre) then return end
	gItemCounterNeedsUpdate = false
	--~ print("itemcounter update")
	
	if (not gItemCounterDialog) then gItemCounterDialog = GetDesktopWidget():CreateChild("UOItemCounter") end
	
	gItemCounterDialog:Clear()
	
	-- items
	local baglist = ItemCounterGetBagList()
	
	for k,group in pairs(gItemCounterTypeGroups) do 
		local bGroupVisible = false
		for k2,v in pairs(group) do 
			v.curamount = ItemCounterOne(v.artid,baglist,v.hue)
			if (v.curamount > 0) then bGroupVisible = true end
		end
		if (bGroupVisible) then 
			for k2,v in pairs(group) do 
				gItemCounterDialog:AddItem(v,v.curamount,v.hue)
			end
		end
	end
	
	-- weight
	local curw,maxw = GetPlayerWeight()
	curw = curw or 0
	maxw = maxw or 0
	local r,g,b = 1,1,1
	if (curw > maxw*0.75) then r,g,b = 1,1,0 end
	if (curw > maxw) then r,g,b = 1,0,0 end
	gItemCounterDialog:AddText("W:")
	gItemCounterDialog:AddText(curw or 0,r,g,b)
	gItemCounterDialog:AddText("/")
	gItemCounterDialog:AddText(maxw or 0)
	if (ItemCounterGetCustomText) then gItemCounterDialog:AddText(ItemCounterGetCustomText() or "") end
end

gWidgetClass["UOItemCounter"] = nil -- unregister for reload
RegisterWidgetClass("UOItemCounter")


function gWidgetPrototype.UOItemCounter:AddText (text,r,g,b)
	return self:AddWidget(self:CreateChild("UOText",{x=self.nextx,y=0,text=text,col={r=r or 1,g=g or 1,b=b or 1},bold=true}))
end

function gWidgetPrototype.UOItemCounter:AddItem (data,amount,hue)
	local artid = data.artid
	local name = GetStaticTileTypeName(artid)
	local r,g,b = 1,1,1
	if (amount < kItemCounterLowAmount) then r,g,b = 1,0,0 end
	if (amount == 0) then r,g,b = 0.3,0,0 end
	local minx,miny,maxx,maxy = GetArtVisibleAABB(artid+0x4000)
	local icon = self:CreateChild("UOImage",{x=self.nextx-minx,y=0,art_id=artid,hue=hue})
	icon.on_mouse_left_click = function() NotifyListener("Hook_ItemCounter_Click",artid,hue) end
	icon.on_mouse_left_click_double = function()
		local t = data.usagetype
		if t then
			-- try to use it
			if t == kItemCounterUsageType_Use then
				MacroCmd_Item_UseByArtID(artid)
			elseif t == kItemCounterUsageType_UseInHand then
				job.create(function()
					local delay = 800
					-- unequip into backpack
					local twohand	= MacroCmd_GetPlayerEquipment(kLayer_TwoHanded)
					local onehand	= MacroCmd_GetPlayerEquipment(kLayer_OneHanded)
					if onehand then MacroCmd_DragDrop(onehand.serial,1) end
					if twohand then MacroCmd_DragDrop(twohand.serial,1) end
					job.wait(delay)
					-- use
					MacroCmd_Item_UseByArtID(artid)
					job.wait(delay)
					-- reequip
					if onehand then MacroCmd_DragAndEquip(onehand.serial, GetPlayerSerial()) end
					if twohand then MacroCmd_DragAndEquip(twohand.serial, GetPlayerSerial()) end
				end)
			end
		end
	end
	self:AddWidget(icon,maxx-minx)
	local text = self:AddText(amount,r,g,b)
	--~ text:SetIgnoreBBoxHit(false)
	--~ text.on_mouse_left_click = function() NotifyListener("Hook_ItemCounter_Click",artid) end
	self:AddSpace(2)
end
function gWidgetPrototype.UOItemCounter:AddWidget (widget,xmove)
	table.insert(self.widgets,widget)
	if (not xmove) then local l,t,r,b = widget:GetRelBounds() xmove = r end
	self.nextx = self.nextx + xmove
	return widget
end
function gWidgetPrototype.UOItemCounter:AddSpace (xmove)
	self.nextx = self.nextx + xmove
end

function gWidgetPrototype.UOItemCounter:Clear ()
	for k,item in pairs(self.widgets) do item:Destroy() end
	self.widgets = {}
	self.nextx = 0
end

function gWidgetPrototype.UOItemCounter:Init (parentwidget,params)
	self:InitAsGroup(parentwidget,params)
	self.widgets = {}
	self.nextx = 0
	self:SetPos(160,16)
end

ItemCounterUpdate()




	--~ MacroCmd_Item_SumByArtID
	-- MacroCmd_Item_SumByArtID(artid) 
end

