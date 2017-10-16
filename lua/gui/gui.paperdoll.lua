-- TODO : admin char paperdoll body broken : bodyid,bodygumpid =     987     0x03db  : body gump id unknown unknown  ( GM admin robe)
-- TODO : gump.def must be parsed, simple format
-- packet handlers for paperdolls (clother and equipment of player, npcs..)
-- see also lib.packet.lua and lib.protocol.lua
-- see also net.mobile.lua, especially kPacket_Equipped_MOB
-- mobileserial : also known as character/player id

-- Created 08.03.2008 12:25:56, with GumpStudio & Iris2 Lua Export Plugin
-- Exported Iris2 GumpExporter ver 1.0.
local playerPaperdoll = {}
playerPaperdoll.bSupportsGuiSys2 = true
playerPaperdoll.dialogId = 1000001
playerPaperdoll.x = 120
playerPaperdoll.y = 100
playerPaperdoll.Data =
 "{ page 0 }" ..
 "{ gumppic 4 4 2000 paperdollpic }" ..
 "{ button 187 50 2031 2032 1 0 0 btnhelp }" ..
 "{ button 187 76 2006 2007 1 0 1 btnoptions }" ..
 "{ text 36 265 0 0 paperdollname }" ..
 "{ button 84 6 113 113 1 0 2 btnvirtues }" ..
 "{ button 187 102 2009 2010 1 0 3 btnquit }" ..
 "{ button 187 130 22453 22455 1 0 4 btnquests }" ..
 "{ button 187 156 2015 2016 1 0 5 btnskills }" ..
 "{ button 187 181 22450 22452 1 0 6 btnguild }" ..
 "{ button 187 205 2021 2022 1 0 7 btnpeace }" ..
 "{ button 187 233 2027 2028 1 0 8 btnstatus }" ..
 "{ button 165 210 11060 11060 1 0 9 btnweaponability }" ..
 
 "{ gumppictiled 6 84 21 21 9274 miniequipback1 }" ..
 "{ gumppic 6 84 9028 miniequip1 }" ..
 "{ gumppictiled 6 107 21 21 9274 miniequipback2 }" ..
 "{ gumppic 6 107 9028 miniequip2 }" ..
 "{ gumppictiled 6 130 21 21 9274 miniequipback3 }" ..
 "{ gumppic 6 130 9028 miniequip3 }" ..
 "{ gumppictiled 6 153 21 21 9274 miniequipback4 }" ..
 "{ gumppic 6 153 9028 miniequip4 }" ..
 "{ gumppictiled 6 176 21 21 9274 miniequipback5 }" ..
 "{ gumppic 6 176 9028 miniequip5 }"..
 "{ button 27 200 2002 2002 1 0 10 charprofile }" ..
 "{ button 44 200 2002 2002 1 0 11 partymanifest }"

playerPaperdoll.textline = {
 [0] = "paperdoll_name",
}
playerPaperdoll.functions = {
 -- help
 [0]	= function (widget,mousebutton) if (mousebutton == 1) then Send_RequestHelp() end end,
 -- options
 [1]	= function (widget,mousebutton) OpenConfigDialog() end,
 -- virtues
 [2]	= function (widget,mousebutton)
			if (mousebutton == 1) then
				GumpReturnMsg(GetPlayerSerial(),kGumpTypeVirtue,1,nil,1, GetPlayerSerial()) -- special case
			end
		  end,
 -- quit
 [3]	= function (widget,mousebutton) if (mousebutton == 1) then OpenQuit() end end,
 -- quests
 [4]	= function (widget,mousebutton)
			if (mousebutton == 1) then
				Send_AOSCommand(kPacket_AOS_Command_QuestGumpRequest,gPlayerBodySerial)
			end
		  end,
 -- skills
 [5]	= function (widget,mousebutton)
 			if (mousebutton == 1) then
 				ToggleSkill()
 		  	end
 		  end,
 -- guild
 [6]	= function (widget,mousebutton)
			if (mousebutton == 1) then
				Send_AOSCommand(kPacket_AOS_Command_GuildGumpRequest,gPlayerBodySerial)
			end
		  end,
 -- peace
 [7]	= function (widget,mousebutton)
			if (mousebutton == 1) then
				Send_CombatMode(IsWarModeActive() and gWarmode_Normal or gWarmode_Combat)
			end
		  end,
 -- status
 [8]	= function (widget,mousebutton)
 			if (mousebutton == 1) then
 				ToggleStatusAos()
 			end
 		  end,
 -- weaponability
 [9]	= function (widget,mousebutton)
 			if (mousebutton == 1) then
 				-- current equipped weapon
				local a,b = GetWeaponSpecialsForMobile(GetPlayerMobile())
				local mx,my = GetMousePos()
				if (a) then CreateQuickCastButtonWeaponability(mx-48,my,a) end
 				if (b) then CreateQuickCastButtonWeaponability(mx+16,my,b) end
 			end
 		  end,
		  
	-- character profile
	[10]   = function (widget,mousebutton) if (mousebutton == 1) then Send_RequestCharacterProfile() end end,
	-- party manifest
	[11]   = function (widget,mousebutton) if (mousebutton == 1) then TogglePartyList() end end,
}

-- Created 08.03.2008 12:25:56, with GumpStudio & Iris2 Lua Export Plugin
-- Exported Iris2 GumpExporter ver 1.0.
local npcPaperdoll = {}
npcPaperdoll.bSupportsGuiSys2 = true
npcPaperdoll.dialogId = 1000002
npcPaperdoll.x = 120
npcPaperdoll.y = 100
npcPaperdoll.Data =
 "{ page 0 }" ..
 "{ gumppic 4 4 2001 paperdollpic }" ..
 "{ text 36 263 0 0 paperdollname }" ..
 "{ button 187 233 2027 2028 1 0 0 btnstatus }"
npcPaperdoll.textline = {
 [0] = "paperdoll_name",
}
npcPaperdoll.functions = {
 -- status
 [0]	= function (widget,mousebutton)
			if (mousebutton == 1) then
				OpenHealthbar(widget:GetDialog().uoPaperdoll.mobile)
			end
		  end
}



kClientSideGump_Paperdoll_Own	= playerPaperdoll -- own paperdoll, including buttons like quest,skills..
kClientSideGump_Paperdoll_Other	= npcPaperdoll -- paperdoll of someone else, no buttons



-- initial body positon in gump
local BodyWidget_x	= 9
local BodyWidget_y	= 19

gPaperdolls = {}

RegisterListener("Hook_WarmodeChange",function () UpdatePaperdollWarPeaceButton() end)

function GetPaperDoll (serial) return serial and gPaperdolls[serial] end

function UpdatePaperdollWarPeaceButton()
	local paperdoll = GetPaperDoll(GetPlayerSerial())
	local dialog = paperdoll and paperdoll.dialog
	local widget = dialog and dialog.controls["btnpeace"]
	if (widget) then
		if (IsWarModeActive()) then
			widget:SetButtonGumpIDs(0x7E8,0x7E9,0x7EA) -- normal,pressed,over
		else
			widget:SetButtonGumpIDs(0x7E5,0x7E6,0x7E7) -- normal,pressed,over
		end
	end
end

local function GetPaperdollBodyAndBaseID (bodyid)
	local bodygumpid = nil
	local base_id = kGumpBaseId_Male

	--Human-Male Paperdoll
	if (bodyid == 400 or
		bodyid == 744 or  --Necromancy Transfromed Model
		bodyid == 987)	  --GameMaster v2 + GM Robe should be displayed
	then
		bodygumpid = hex2num("0x0C")
		base_id = kGumpBaseId_Male
	--Human-Savage_Male
	elseif (bodyid == 183 or
			bodyid == 185 or
			bodyid == 750)
	then
		bodygumpid = hex2num("0x79")
		base_id = kGumpBaseId_Male
	--Human-Female Paperdoll
	elseif (bodyid == 401 or
			bodyid == 745)  --Necromancy Transfromed Model
	then
		bodygumpid = hex2num("0x0D")
		base_id = kGumpBaseId_Female
	--Human-Savage_Female
	elseif (bodyid == 184 or
			bodyid == 186 or
			bodyid == 751)
	then
		bodygumpid = hex2num("0x78")
		base_id = kGumpBaseId_Female
	--Male-Elf Paperdoll
	elseif (bodyid == 605)
	then
		bodygumpid = hex2num("0x0E")
		base_id = kGumpBaseId_Male
	--Female-Elf Paperdoll
	elseif (bodyid == 606)
	then
		bodygumpid = hex2num("0x0F")
		base_id = kGumpBaseId_Female
	--Lord British
	elseif (bodyid == 990)
	then
		bodygumpid = hex2num("0x3DE")
		base_id = kGumpBaseId_Male
	--Blackthorn
	elseif (bodyid == 991)
	then
		bodygumpid = hex2num("0x3DF")
		base_id = kGumpBaseId_Male
	--Dupre (wrong paperdoll ?!)
	elseif (bodyid == 994)
	then
		bodygumpid = hex2num("0x3E2")
	--Player Ghosts
	elseif (bodyid == 402 or
			bodyid == 403 or
			bodyid == 607 or
			bodyid == 608 or
			bodyid == 970)
	then
		bodygumpid = hex2num("0x3DB")
	else
		-- unknown
		--bodygumpid = hex2num("0x3DF")
	end
	return bodygumpid,base_id
end

-- base_id = kGumpBaseId_Female or kGumpBaseId_Male
function GetPaperdollItemGumpID (artid,base_id)
	local t = GetStaticTileType(artid)
	if (not t) then return end
	local animid = t.miAnimID
	local gumpid = animid + base_id
	if ((not PreLoadGump(gumpid)) and base_id == kGumpBaseId_Female) then gumpid = animid+kGumpBaseId_Male end -- fallback to male
	if (GetPaperdollLayerFromTileType(artid) == kLayer_Backpack) then gumpid = animid+kGumpBaseId_Male end -- no female backpack
	return gumpid
end

-- Don't call this directly, use RebuildPaperdoll() instead (need to rebuild completely on change because of layerorder)
-- item fields : serial artid layer hue (=-1 if not set)
local function CreatePaperdollItemWidget(layer, paperdoll, item, base_id, blockedlayers)
	local dialog = paperdoll.dialog

	if (paperdoll.bSupportsGuiSys2) then 
		--~ print("TODO : CreatePaperdollItemWidget") 
		if (not blockedlayers[layer]) then
			item.widget = dialog:CreateChild("UOPaperdollItemWidget",{paperdoll=paperdoll,item=item,base_id=base_id,x=BodyWidget_x,y=BodyWidget_y})
		end
		local side = gLayerOrderPositionAndArtOverwrite[layer]
		if side then
			local x,y = unpack(side)
			item.widget2 = dialog:CreateChild("UOPaperdollItemWidget",{paperdoll=paperdoll,item=item,base_id=base_id,x=x,y=y,useart=true,onsidebar=true})
		end
		
		return 
	end
	
	-- from here on : code for old-guisystem paperdoll
	
	-- Fallback to female
	local gumpid = GetPaperdollItemGumpID(item.artid) 
	
	if (not gumpid) then
		print("WARNING : CreatePaperdollItemWidget : unknown gump",item.artid)
		return
		-- TODO : dummy gfx type for each layer ?
	end
	
	
	
	if (not blockedlayers[layer]) then
		item.widget = MakeBorderGumpPart(dialog.rootwidget, gumpid, BodyWidget_x, BodyWidget_y, 0, 0, 0, item.hue)
		PaperdollItemWidgetInit(item.widget,layer,paperdoll,item,base_id)
	end
	
	-- additonal widget in jewelry slot
	if gLayerOrderPositionAndArtOverwrite[layer] then
		local x,y = unpack(gLayerOrderPositionAndArtOverwrite[layer])
		
		local minx,miny,maxx,maxy = GetArtVisibleAABB(item.artid + 0x4000)
		local cx = minx + (maxx - minx)/2
		local cy = miny + (maxy - miny)/2

		item.widget2 = MakeArtGumpPart(  dialog.rootwidget, item.artid, x-cx,y-cy, nil,nil,nil, item.hue)
		PaperdollItemWidgetInit(item.widget2,layer,paperdoll,item,base_id)
	end
end
	
function PaperdollItemWidgetInit (widget,layer,paperdoll,item,base_id)
	widget.mbIgnoreMouseOver = false
	widget.uoPaperdoll = paperdoll
	widget.item = item

	widget.onMouseDown = function (widget,mousebutton) end

	-- TODO : find a cleaner solution to override the mousepick tipp
	widget.onMouseEnter = function () -- item tooltip (clientside,debuginfos)
							local name = GetStaticTileTypeName(item.artid) or ""
							info = sprintf("equipment %s (artid=%04x=%d)",name,item.artid,item.artid)
							gCurrentRenderer.gMousePickTippOverride = info
							Client_SetBottomLine(gCurrentRenderer.gMousePickTippOverride)
						end

	widget.onMouseLeave = function () 
		gCurrentRenderer.gMousePickTippOverride = false
		Client_SetBottomLine("")
	end

	if (gTooltipSupport) then
		widget.tooltip_offx = kUOToolTippOffX
		widget.tooltip_offy = kUOToolTippOffY
		widget.stylesetname = gGuiDefaultStyleSet
		widget.on_simple_tooltip = function (widget)
				local  tooltiptext = AosToolTip_GetText(widget.item.serial) or ""
				return (tooltiptext .. " \n ") or "?"
			end -- add newline, workaround for tooltip sizecalc bug
	end
end

-- destroys old widgets if neccessary
local function DestroyPaperdollItemWidgets (paperdoll) 
	if (paperdoll.mobile) then
		for k,item in pairs(GetMobileEquipmentList(paperdoll.mobile)) do
			if (item.widget) then item.widget:Destroy()  item.widget = nil end
			if (item.widget2) then item.widget2:Destroy()  item.widget2 = nil end
		end
	end
end

-- close dialog and destroys all widgets
local function ClosePaperdoll (paperdoll)
	if (paperdoll and paperdoll.dialog) then 
		NotifyListener("Hook_ClosePaperdoll",paperdoll)
		DestroyPaperdollItemWidgets(paperdoll)
		paperdoll.dialog:Destroy()
		paperdoll.dialog = nil
		gPaperdolls[paperdoll.mobileserial] = nil
		-- TODO : send network message ?
	end
end

-- ----------------------------------------------- End of local functions -----------------------------

-- rebuild needed on update to have correct layerorder
-- paperdoll.bIsPlayer (check if is player or npc)
function RebuildPaperdoll (paperdoll)
	if (not gGumpLoader) then return end

	local mobile = GetMobile(paperdoll.mobileserial)
	paperdoll.mobile = mobile
	paperdoll.bIsPlayer = IsPlayerMobile(mobile)
	
	-- create paperdoll dialog for player or mobile if neccessary
	local dialog = paperdoll.dialog
	if (not dialog) then
		if (paperdoll.bIsPlayer) then
			dialog = GumpParser( playerPaperdoll, true )
		else
			dialog = GumpParser( npcPaperdoll, true )
		end

		-- save paperdolldialog as paperdoll
		paperdoll.dialog = dialog
		dialog.uoPaperdoll = paperdoll

		-- overwrite the onMouseDown function from gumpparser
		dialog.SendClose = function (widget,returnvalue) ClosePaperdoll(paperdoll) end
	end

	-- visually change the Peace/Warmode Button when opening the Paperdoll when in combat mode
	UpdatePaperdollWarPeaceButton()

	-- update paperdoll name and color
	--~ local r,g,b = GetNotorietyColor(paperdoll.mobile and paperdoll.mobile.notoriety or 0)
	--~ dialog.controls["paperdollname"].gfx:SetCharHeight(gFontDefs["Gump"].size + 2)
	--~ dialog.controls["paperdollname"].gfx:SetColour( {r,g,b,1.0} )
	--~ dialog.controls["paperdollname"].gfx:SetFont(gFontDefs["Gump"].name)
	--~ dialog.controls["paperdollname"].gfx:SetText(paperdoll.name)
	
	local name = paperdoll.name or "Unknown"
	local sname = string.gsub(name, ",", ",<BR>")
	dialog.controls["paperdollname"]:SetUOHtml("<BASEFONT COLOR=#000000>"..sname.."</BASEFONT>", true)
--	dialog.controls["paperdollname"]:SetText(name)
	
	-- remove old item widgets
	DestroyPaperdollItemWidgets(paperdoll)

	-- create bodywidget and item widgets
	if (mobile) then
		local bodyid = mobile.artid
		local bodygumpid,base_id = GetPaperdollBodyAndBaseID(bodyid)
		
		-- destroy old bodywidget
		if (dialog.bodywidget) then dialog.bodywidget:Destroy()  dialog.bodywidget = nil end
		
		local skinhue = mobile.hue
		if (skinhue >= 0x8000) then skinhue = skinhue - 0x8000 end
		
		-- create bodywidget
		if (bodygumpid) then
			dialog.bodywidget = dialog:CreateChild("UOImage",{gump_id=bodygumpid,x=BodyWidget_x,y=BodyWidget_y,hue=skinhue})
		else 
			--print("Open_Paperdoll : unknown bodyid ",bodyid,sprintf("0x%04x",bodyid))
			-- TODO : fallback/default bodyid ?
		end
	
		-- 2d stitching
		local blockedlayers = {}
		for blocker,blockedlist in pairs(gPaperdollBlockingLayers) do 
			if GetMobileEquipmentItem(mobile,blocker) then
				for k,blocked in pairs(blockedlist) do blockedlayers[blocked] = true end
			end
		end
		
		paperdoll.bSupportsGuiSys2 = true
		-- preload / bulkload to atlas
		for index,layer in pairs(gLayerOrder) do 
			local k = gLayerTypeName[layer]
			local item = GetMobileEquipmentItem(mobile,layer)
			if (item) then 
				AosToolTip_GetText(item.serial)
				local gumpid = GetPaperdollItemGumpID(item.artid,base_id)
				if (gumpid) then PreLoadGump(gumpid) end
				if gLayerOrderPositionAndArtOverwrite[layer] then PreLoadArt(item.artid + 0x4000) end
			end
		end
		-- create item widgets
		for index,layer in pairs(gLayerOrder) do 
			local k = gLayerTypeName[layer]
			local item = GetMobileEquipmentItem(mobile,layer)
			if (item) then CreatePaperdollItemWidget(layer,paperdoll,item,base_id,blockedlayers) end
		end
	end

	if (mobile and mobile.name ~= paperdoll.name) then 
		mobile.name = paperdoll.name 
		mobile:Update()
	end
	
	NotifyListener("Hook_RebuildPaperdoll",paperdoll)
end

-- triggered by mobile destruction
function DestroyPaperdollByMobileSerial (serial)
	local paperdoll = gPaperdolls[serial]
	if (not paperdoll) then return end
	ClosePaperdoll(paperdoll)
end

-- called from kPacket_Open_Paperdoll, TogglePlayerPaperdoll and OpenPaperdoll
function HandleOpenPaperdoll (paperdoll)
	paperdoll.mobileserial	= paperdoll.serial
	paperdoll.Close = ClosePaperdoll
	
	-- close old paperdoll
	local oldpaperdoll = gPaperdolls[paperdoll.mobileserial]
	if (oldpaperdoll) then oldpaperdoll:Close() end 
	
	-- register paperdoll
	gPaperdolls[paperdoll.mobileserial] = paperdoll
	
	RebuildPaperdoll(paperdoll)
end

-- toggles the player paperdoll
function TogglePlayerPaperdoll ()
	local playermobile = GetPlayerMobile()

	-- Check if there is a mobile to display
	if (not playermobile) then
		-- No mobile to display so provide at least a menu to quit
		OpenQuit()
		return
	end
	
	if (playermobile.serial and gPaperdolls[playermobile.serial]) then
		gPaperdolls[playermobile.serial]:Close()
	else
		local paperdoll = {}
		paperdoll.serial= playermobile.serial
		paperdoll.name	= playermobile.name
		paperdoll.flag	= 0
		
		HandleOpenPaperdoll(paperdoll)
	end
end

-- open/reposition the requested paperdoll
function OpenPaperdoll (x,y,serial)
	local p = gPaperdolls[serial]
			
	if p then
		RebuildPaperdoll(p)
	else
		local paperdoll = {}
		local m = GetMobile(serial)
		paperdoll.serial	= serial
		paperdoll.name		= m and m.name or serial
		paperdoll.flag		= 0
		
		HandleOpenPaperdoll(paperdoll)
	end
	
	local p = gPaperdolls[serial]
	if p.dialog and p.dialog.rootwidget and p.dialog.rootwidget.gfx then
		p.dialog.rootwidget.gfx:SetPos(x, y)
	end
end
