-- TODO : detect server rejects item move (wait for object-to-object or object destroy message of the item being moved?)

if (not gDisabledPlugins.loot) then 
gLootPluginCutCorspes = false 
--~ gLootPluginCutCorspes = true 
gLootPluginMinGoldAmount = gLootPluginMinGoldAmount or 1500000

kLootPlugin_RecentlyClickedInterval = 4*1000
kLootPluginHideCorpseWithoutContentChangeTimeout = false -- if corpse does not contain interesting item and hasn't changed contents, hide it
--~ kLootPluginHideCorpseWithoutContentChangeTimeout = 500 -- if corpse does not contain interesting item and hasn't changed contents, hide it
gLootPlugin_LastContainerUpdateTime = {}
gLootPlugin_HiddenContainers = gLootPlugin_HiddenContainers or {}

function LootSetBackPackFullCallBack (fun) gLootBPFullCallBack = fun end

gLoot_TrashCorpseTypes = { 
	35,36,  --lizzardmen
	240, -- kappa
	}
gLoot_TrashCorpseTypesByID = {}
for k,v in pairs(gLoot_TrashCorpseTypes) do gLoot_TrashCorpseTypesByID[v] = true end

	
kCorpseContainerGumpID = 9
kLootArtID_Gold = 3823
kLoot_GoldWeight = 20/1000 -- 1000gold = 20 stones
-- artid=3791,3794,...(not corpse-art-id) : bones after animate undead
gStepperInterval = 700 -- serverside = 500, add a bit of tolerance

--~ Send_Take_Object(...) -- NextActionTime = now + 0.5 s   
--~ Send_Drop_Object_AutoStack(...)  -- no timeout
--~ Send_DoubleClick(..) : UseReq : NextActionTime = now + 0.5 s   

gLootPluginWantedWords = {
	--~ "mage armor", -- mage armor , mage weap
	--~ "mage weapon", -- mage armor , mage weap
	--~ "slayer",
	"Origami", -- paper
	
	"truth", -- mysticism : book of truth
	"mysticism",
	"Animated Weapon",
	"Bombard",
	"Cleansing Winds",
	"Eagle Strike",
	"Enchant",
	"Hail Storm",
	"Healing Stone",
	"Mass Sleep",
	"Nether Bolt",
	"Nether Cyclone",
	"Purge Magic",
	"Rising Colossus",
	"Sleep",
	"Spell Plague",
	"Spell Trigger",
	"Stone Form",
	
	"skull",
	"bank",
	"prism", -- crimson
	"enchanted", -- talisman-recharge?
	"atlas", -- travel atlas
	
	-- witchcraft stuff
	"boline", 
	"cauldron",
	"watering",
	
	--~ dreadhorn keys, no timer : Blighted Cotton, Thorny Briar, Gnaw's Fang, Irk's Brain, Lissith's Silk, and Sabrix's Eye
	"Brain",
	"Blighted",
	"Thorny",
	"Gnaw",
	"Lissith",
	"Sabrix",
	
	-- travesty keys : Red Key, Blue Key and Gold Key. From the High Executioner, Grand Mage, and Master Thief. 
	"Key",
	
	-- peerless reags
	"Corruption",
	"Putrefaction",
	"Taint",
	"Muculent",
	"Blight",
	"Scourge",
	"Captured Essence", -- shimmering effusion
	"Diseased Bark", -- melisande
	
	-- namd deko stuff
	"Travesty",  --  
	"Paroxysmus",  --  
	"Dread",  --  
	"Grizzle",  --  
	"Damned",  --  Tombstone Of The Damned  grizzle deko loot
	"Shimmering",  --  effusion deko
	"Melisande",
	"Hair Dye", -- Melisande
	
	-- Artifacts (Mondain's Legacy)
	"Aegis of Grace",
	"Blade Dance",
	"Bloodwood Spirit",
	"Bonesmasher",
	"Boomstick",
	"Brightsight Lenses",
	"Fey Leggings",
	"Flesh Ripper",
	"Helm of Swiftness",
	"Pads of the Cu Sidhe",
	"Quiver of Rage",
	"Quiver of the Elements",
	"Raed's Glory",
	"Righteous Anger",
	"Robe of the Eclipse",
	"Robe of the Equinox",
	"Soul Seeker",
	"Talon Bite",
	"Totem of the Void",
	"Wildfire Bow",
	"Windsong",

	-- other valuable stuff and peerless artis
	"talisman",
	"totem",
	"cincture",
	"Dread", -- Dread Horn stuff
	"Corroded",  -- melisande 
	"imprisoned",  --  
	"Grizzle",  -- Grizzle 
	"statue",  --  
	"Scepter of the Chief",  --  
	"Crystalline Ring",  --  shimmering
	"Mark of the Travesty",  --  
	
	"ancient",
	"legendary",
	"mythic", "mystic", "mystiq", -- i don't know how it is written exactly
	"crystal",
	"Radiant", -- radiant crystals, but can't hurt to search for this keyword also
	"rune",
	"maze", -- vm:relvinian
	"Ingeniously", 	-- tmap:6
	"Deviously",	-- tmap:5
	"+15",
	"255", 		-- arti dura
	"artefact", -- artis
	"rarity", 	-- artis
	"talisman", -- peerless loot
	"totem", -- labyrinth loot ? artefact
	"imprisoned", -- imprisoned squirrel/dog , peerless loot
	"oil", -- bomberoil ?
	"lifespan", -- bomberoil 
	"seconds", -- bomberoil 
	--~ "gargoyle",  
	--~ "channeling", -- spellchannel 
	-- todo : timer (bomberoil,shimmering effusion,paroxysm rope)
	
	-- imbuing
	"essence of ",
	"essence of balance",
	"essence of control",
	"goblin blood",
	"faery dust",
	"raptor", -- imbue:raptorteeth
	"arcanic", -- imbue:arcanicrunestone
	"delicate", -- imbue:delicate.scales
	"luminescent", -- imbue:luminescent fungi (lumber:rare)
	"abyssal", -- imbue:abyssal cloth
	"renewal", -- imbue:seedofrenewal
	"crushed", -- imbue:crushedglass
	"elven fletching", -- imbue:elven fletching
	"shards", -- imbue:crystalshards
	"tongue", -- imbue:slithtongue
	"void", -- imbue:voidorb
	"snake", -- imbue:silversnakeskin
	"reflective", -- imbue:reflectivewolfeye
	"chaga", -- imbue:chagamushroom
	"boura", -- imbue:bourapelt
	"ichor", -- imbue:bottleofichor
	
	--~ "unidentified",
}
for k,v in pairs(gLootPluginWantedWords) do gLootPluginWantedWords[k] = string.lower(v) end

gLootPluginWantedProps = {}
function LootPluginEval_AddProp (minvalue,name) gLootPluginWantedProps[string.lower(string.gsub(name,"_"," "))] = minvalue end
--~ LootPluginEval_AddProp(    5     ,"lower_reagent_cost")
--~ LootPluginEval_AddProp(    10     ,"lower_reagent_cost")
LootPluginEval_AddProp(    15     ,"lower_reagent_cost")
--~ LootPluginEval_AddProp(    15     ,"lower_reagent_cost")
LootPluginEval_AddProp(    10     ,"reflect_physical") -- cap 15 per item ?
LootPluginEval_AddProp(    8      ,"lower_mana_cost")
LootPluginEval_AddProp(    2      ,"mana_regeneration")
LootPluginEval_AddProp(    2      ,"faster_casting")
--~ LootPluginEval_AddProp(    2      ,"faster_casting")
--~ LootPluginEval_AddProp(    1      ,"faster_cast_recovery")
LootPluginEval_AddProp(    3      ,"faster_cast_recovery")
LootPluginEval_AddProp(    10     ,"hit_chance_increase")
LootPluginEval_AddProp(    10     ,"defense_chance_increase")
LootPluginEval_AddProp(    10     ,"enhance_potions")
--~ LootPluginEval_AddProp(    10     ,"swing_speed_increase")
--~ LootPluginEval_AddProp(    5      ,"strength_bonus")
LootPluginEval_AddProp(    90     ,"luck")
--~ LootPluginEval_AddProp(    50     ,"luck")
LootPluginEval_AddProp(    20     ,"mana_leech")

function LootEvaluateScavengeItem (item)
	local artid	= item.artid
	local hue	= item.hue
	if (artid == 0x26ac) then return true end -- bola
end

function LootEvaluateItem (item)
	if (MyLootEvaluateItem) then 
		local res = MyLootEvaluateItem(item)
		if (res ~= nil) then return res end 
	end
	local artid	= item.artid
	local hue	= item.hue
	--~ print("LootEvaluateItem",item,artid,hue)
	if (artid == 0x170b) then return true end -- kobold schuhe
	if (artid == 0x2da2) then return true end -- mysticism scroll
	if (artid == 5110 and hue == 2419) then return true end -- gargy knife
	if (artid == 3718 and hue == 2419) then return true end -- gargy pickaxe
	if (artid == 3909 and hue == 2419) then return true end -- gargy axe
	if (artid == 0xeb3) then return false end -- music instruments
	if (artid == 0xeb1) then return false end -- music instruments
	if (artid == 0xe9d) then return false end -- music instruments
	if (artid == 0xe9c) then return false end -- music instruments
	if (artid == 0x1bfb and item.amount >= 30) then return true end -- bolts
	if (artid == 0x0f3f and item.amount >= 30) then return true end -- arrows
	if (1 == 2) then -- jewels
		if (artid == 0xf21) then return true end -- star saphire
		if (artid == 0xf26) then return true end -- star diamond
		if (artid == 0xf13) then return true end -- ruby
		if (artid == 0xf19) then return true end -- saphire
		if (artid == 0xf16) then return true end -- amethy
		if (artid == 0xf10) then return true end -- emeral
		if (artid == 0xf15) then return true end -- citrin
		if (artid == 0xf2d) then return true end -- turmaline
	end
	if (artid == 0x1bd1) then return true end -- feathers
	if (artid == 0x26b7) then return true end -- fungus
	if (artid == 0x0e2e) then return true end -- petball
	--~ print("LootEvaluateItem2",item,artid,hue,artid == kLootArtID_Gold,item.amount,gLootPluginMinGoldAmount)
	--~ if (artid == 0x1079) then return true end -- raw leather
	if (artid == kLootArtID_Gold and item.amount >= gLootPluginMinGoldAmount) then return true end -- gold
	local tooltip = AosToolTip_GetText(item.serial,true) --- todo : GetItemTooltipOrLabel
	if (not tooltip) then return end
	tooltip = string.lower(tooltip)
	if (string.find(tooltip,"%d+ nox crystal")) then return false end
	for k,v in pairs(gLootPluginWantedWords) do 
		if string.find(tooltip,v) then print("LOOT : loot because",v) return true end 
	end
	
	if (string.find(tooltip,"mage weapon") and string.find(tooltip,"spellchannel")) then return true end
	
	local a,b,maxsocket = string.find(tooltip,"maximum sockets allowed is (%d+)")
	local a,b,cursocket = string.find(tooltip,"(%d+) sockets")
	local socket = max(maxsocket or 0,cursocket or 0)
	--~ print("lootplugin:sockets",socket,maxsocket,cursocket)
	if (socket >= 2) then print("LOOT : loot because",v) return true end
	
	for name,minvalue in pairs(gLootPluginWantedProps) do 
		local a,b,val = string.find(tooltip,name.."[^0-9\n]*[ ]+(%d+)")
		if (val and tonumber(val) >= minvalue) then print("looteval:found",name,val) return true end
	end
end

gLastLootLogTime = 0
function MyLootLog (...)
	--~ local t = Client_GetTicks()
	--~ local dt = t - gLastLootLogTime
	--~ gLastLootLogTime = t
	--~ print("lootlog",dt,...)
end
-- todo : detect empty corpses : Hook_OpenContainer starts timeout, if Hook_Container_Contents doesn't arrive in time, assume corpse is empty
--~ RegisterListener("Hook_Text",function (name,plaintext,serial,data) MyLootLog("Hook_Text",name,plaintext,serial,data.clilocid) end)
--~ RegisterListener("Hook_OpenContainer",function (dialog,serial,gumpid) MyLootLog("Hook_OpenContainer",serial) end)
--~ RegisterListener("Hook_Packet_Destroy",function (serial) if (gLootPluginMarkedItems[serial]) then MyLootLog("Hook_Packet_Destroy",serial) end end)
--~ RegisterListener("Hook_GetItemFailed",function (reason,reasontxt) MyLootLog("Hook_GetItemFailed",reason,reasontxt) end)

function ToggleAutoLoot ()
	gAutoLoot = not gAutoLoot
	gLootPlugin_LastContainerUpdateTime = {}
	SpellBarRiseTextOnMob(GetPlayerSerial(),0,1,0,"autoloot:"..(gAutoLoot and "ON" or "off"))
end

-- warning, might disrupt item listing, especially detection if an item is still inside a corpse
function LootPlugin_HideCorpse (dynamic)
	if (not dynamic) then return end
	--~ for k,item in pairs(dynamic:GetContent()) do 
		--~ if (LootEvaluateItem(item)) then LootPluginMarkItem(item,dynamic) end
	--~ end
	--~ if (LootPlugin_ContainerContainsInterestingThing(dynamic.serial)) then return end
	dynamic:Destroy()
	gLootPlugin_HiddenContainers[dynamic.serial] = gMyTicks
	--~ gCurrentRenderer:RemoveDynamicItem(dynamic) -- hide corpse... doesn't work, becomes visible again on update
end



function LootPluginNotifyContainerContentChange (serial,bIgnoreDuringCompleteContentUpdate) 
	if (not serial) then return end -- happens for empty container on Container_Contents packet. stupid uo protocol.
	local containeritem = GetDynamic(serial)
	if (containeritem and IsCorpseArtID(containeritem.artid_base)) then 
		gLootPlugin_LastContainerUpdateTime[serial] = gMyTicks
	end
	if (not gAutoLoot) then return end
	if (bIgnoreDuringCompleteContentUpdate and gContainerUpdateInProgress) then return end
	MyLootLog("Hook_Container_Contents",serial)
	if (not serial) then return end
	local container = GetContainer(serial)
	if (not container) then return end
	if (container.gumpid ~= kCorpseContainerGumpID) then return end -- only loot corpses (not backpack/bankbox...)
	
	for k,item in pairs(container:GetContent()) do 
		if (LootEvaluateItem(item)) then LootPluginMarkItem(item,container) end
	end
end

gLootPlugin_RecentlyDoubleClickedCorpses = {}
function LootPlugin_CorpseClickable (serial)
	local oldt = gLootPlugin_RecentlyDoubleClickedCorpses[serial]
	if (oldt and oldt > gMyTicks - kLootPlugin_RecentlyClickedInterval) then return false end
	return true
end
function LootPlugin_FindNearbyCorpses ()
	local res = {}
	local maxdist = 2
	local xloc,yloc = GetPlayerPos()
	local t = Client_GetTicks()
	for k,dynamic in pairs(GetDynamicList()) do 
		if (DynamicIsInWorld(dynamic) and IsCorpseArtID(dynamic.artid_base) and (not IsContainerAlreadyOpen(dynamic))) then 
			if (gLoot_TrashCorpseTypesByID[dynamic.amount] or gLootPlugin_HiddenContainers[dynamic.serial]) then
				LootPlugin_HideCorpse(dynamic)
			elseif (GetUODistToPlayer(dynamic.xloc,dynamic.yloc) <= maxdist) then
			--~ elseif (abs(dynamic.xloc-xloc) + abs(dynamic.yloc-yloc) <= maxdist) then
				if (LootPlugin_CorpseClickable(dynamic.serial)) then 
					table.insert(res,dynamic)
				end
			end
		end
	end
	return res
end

gLootPluginMarkedItems = {}
function LootPluginMarkItem (item,container) 
	gLootPluginMarkedItems[item.serial] = {t=Client_GetTicks(),containerserial=container.serial,xloc=container.xloc,yloc=container.yloc}
end

function LootPlugin_TakeItem (item) 
	local iContainerSerial = item.iContainerSerial
	job.create(function ()
		MyLootLog("Send_Take_Object",item.serial)
		Send_Take_Object(item.serial,item.amount)
		job.wait(math.random(200,300))
		MyLootLog("Send_Drop_Object_AutoStack",item.serial)
		Send_Drop_Object_AutoStack(item.serial,MyLootGetLootBag and MyLootGetLootBag(item) or GetPlayerBackPackSerial())
		
		local corpse = GetDynamic(iContainerSerial)
		--~ if (corpse) then LootPlugin_HideCorpse(corpse) end
	end)
end

gLootPluginNextStep = 0
gLootPluginCutCorpses = {}
gLootPluginCutBladeTypes = {0x13ff,0x0f52,0x13f6} -- 0x13ff=katana 0x0f52=dagger 0x13f6=gargyknife

function LootPluginUseItemOnTarget (itemserial,targetserial)
	Send_DoubleClick(itemserial)
	MacroCmd_QueueTargetSerial(targetserial,1000)
end

-- add debug info to tooltip
function LootPluginNotify_Tooltip_RefreshText (dataholder,serial)
	if (gLootPlugin_LastContainerUpdateTime[serial]) then
		dataholder.tooltiptext = dataholder.tooltiptext .. sprintf("\nlootplugin:lastupdatetime=%d",
			gMyTicks - gLootPlugin_LastContainerUpdateTime[serial]
			)
	end
	local dynamic = GetDynamic(serial)
	if (dynamic and IsContainerAlreadyOpen(dynamic)) then
		dataholder.tooltiptext = dataholder.tooltiptext .. sprintf("\nlootplugin:IsContainerAlreadyOpen=true")
	else 
		if (gLootPlugin_RecentlyDoubleClickedCorpses[serial]) then
			dataholder.tooltiptext = dataholder.tooltiptext .. sprintf("\nlootplugin:notopen,but clicked:=%d",
				gMyTicks - gLootPlugin_RecentlyDoubleClickedCorpses[serial]
				)
		end
	end
	local interesting = LootPlugin_ContainerContainsInterestingThing(serial)
	if (interesting) then
		local info = (AosToolTip_GetText(interesting) or "???")
		dataholder.tooltiptext = dataholder.tooltiptext .. sprintf("\nlootplugin:<b>CONTAINS STH INTERESTING : "..info.."</b>")
	end
end

-- only works on already open containers
function LootPlugin_ContainerContainsInterestingThing (serial) 
	for itemserial,lootinfo in pairs(gLootPluginMarkedItems) do 
		if (lootinfo.containerserial == serial) then return itemserial end 
	end 
end
	
function LootPluginStep ()
	local t = Client_GetTicks()
	if (t < gLootPluginNextStep) then return end
	
	if (not gAutoLoot) then return end
	
	-- hide corpses
	if (kLootPluginHideCorpseWithoutContentChangeTimeout) then
		local minupt = gMyTicks - kLootPluginHideCorpseWithoutContentChangeTimeout
		for k,dynamic in pairs(GetDynamicList()) do 
			if (DynamicIsInWorld(dynamic) and IsCorpseArtID(dynamic.artid_base) and (IsContainerAlreadyOpen(dynamic))) then 
				local corpse = dynamic
				local updatet = gLootPlugin_LastContainerUpdateTime[corpse.serial]
				if (not updatet) then 
					updatet = gMyTicks
					gLootPlugin_LastContainerUpdateTime[corpse.serial] = updatet
				end 
				if (updatet < minupt and IsContainerAlreadyOpen(corpse)) then 
					-- corpse didn't change for a long time, check to see if it's open and if there's anything interesting inside  
					if (not LootPlugin_ContainerContainsInterestingThing(corpse.serial)) then 
						-- nothing interesting left, and wasn't updated lately (loot-drag-fail causes update),
						-- so we can savely remove it
						LootPlugin_HideCorpse(corpse)
					end 
				end
			end
		end
	end
	
	-- scavenge items 
	local items = {}
    for k,item in pairs(GetDynamicList()) do 
        if (DynamicIsInWorld(item) and item:GetUODistToPlayer() <= 2 and LootEvaluateScavengeItem(item)) then
            table.insert(items,item)
        end
    end
	if (#items > 0) then
		local item = GetRandomArrayElement(items)
		LootPlugin_TakeItem(item)
		return 
	end
	
	
	
	-- take items
	local forgett = t - 30*1000 -- forget items after 30sek
	local items = {}
	for serial,lootinfo in pairs(gLootPluginMarkedItems) do 
		if (lootinfo.t < forgett) then 
			gLootPluginMarkedItems[serial] = nil 
		elseif (GetUODistToPlayer(lootinfo.xloc,lootinfo.yloc) <= 2) then 
			local item = GetDynamic(serial)
			if (item and item.iContainerSerial ~= GetPlayerBackPackSerial()) then
				local container = GetContainer(item.iContainerSerial)
				if (container and container.gumpid == kCorpseContainerGumpID) then -- in case item ends up in bankbox or so
					table.insert(items,item)
				end
			end
		end
	end
	if (#items > 0) then
		local item = GetRandomArrayElement(items)
		
		-- check weight
		local curw,maxw = GetPlayerWeight()
		local w = max(5,ceil(item.amount * kLoot_GoldWeight))
		if (curw and maxw and curw + w > maxw) then
			SpellBarRiseTextOnMob(GetPlayerSerial(),1,0.5,0,"backpack full!")
			if (gLootBPFullCallBack) then gLootBPFullCallBack() end
			gLootPluginNextStep = t + 2*1000
			return
		end
		
		-- take item
		local info = (AosToolTip_GetText(item.serial) or GetStaticTileTypeName(item.artid) or "???") .. ":" .. item.amount
		SpellBarRiseTextOnMob(GetPlayerSerial(),1,0.5,0,info)
		gLootPlugin_LastContainerUpdateTime[item.iContainerSerial] = gMyTicks -- in case take fails
		LootPlugin_TakeItem(item)
		gLootPluginLastLootT = gMyTicks
		return 
	end
	
	-- open nearby corpse
	local corpses = LootPlugin_FindNearbyCorpses()
	if (#corpses > 0 and (not IsTargetModeActive())) then
		local corpse = GetRandomArrayElement(corpses)
		MyLootLog("Send_DoubleClick",corpse.serial)
		Send_DoubleClick(corpse.serial)
		gLootPlugin_RecentlyDoubleClickedCorpses[corpse.serial] = t
		gLootPlugin_LastClickedCorpse = corpse.serial
		return
	end
	
	-- cut corpses (feathers, leather etc)
	if (gLootPluginCutCorspes) then
		local blade = MacroCmd_Item_FindFirstByArtID(gLootPluginCutBladeTypes)
		if (blade) then 
			local corpses = MacroCmd_Item_FindNearCorpses(2)
			for k,corpse in pairs(corpses) do 
				print("lootscript:cut,corpse=",k,corpse)
				if (not gLootPluginCutCorpses[corpse.serial]) then 
					gLootPluginCutCorpses[corpse.serial] = true
					MacroCmd_RiseText(1,1,1,"cut corpse")
					LootPluginUseItemOnTarget(blade.serial,corpse.serial) 
					return
				end 
			end
		end
	end
end



if (not gLootPluginHooksRegistered) then
	gLootPluginHooksRegistered = true -- only done once in case this file is reloaded
	RegisterIntervalStepper(gStepperInterval,function () LootPluginStep() end) 
	RegisterListener("Hook_Container_Contents",function (serial) LootPluginNotifyContainerContentChange(serial) end)
	RegisterListener("Hook_Dynamic_UpdateContent",function (serial) LootPluginNotifyContainerContentChange(serial,true) end)
	RegisterListener("Hook_Tooltip_RefreshText",function (...) LootPluginNotify_Tooltip_RefreshText(...) end)
end

function LootPluginNotify_NotifyText (name,plaintext,serial,data)
	if (data.clilocid == 1005035 and gLootPlugin_LastClickedCorpse) then  --~ HandleUOText    You did not earn the right to loot this creature!       1005035 0
		gLootPlugin_RecentlyDoubleClickedCorpses[gLootPlugin_LastClickedCorpse] = gMyTicks + 2*60*1000
		LootPlugin_HideCorpse(GetDynamic(gLootPlugin_LastClickedCorpse))
	end
end
RegisterListenerOnce("Hook_Text",function (...) LootPluginNotify_NotifyText(...) end,"LootPluginNotify_NotifyText")

function LootPluginNotify_NotifyDestroy (serial)
	gLootPluginMarkedItems[serial] = nil
end
RegisterListenerOnce("Hook_Packet_Destroy",function (...) LootPluginNotify_NotifyDestroy(...) end,"LootPluginNotify_NotifyDestroy")

--[[
function LootPluginNotify_Hook_ToolTipUpdate (serial,data)
	local tooltip = AosToolTip_GetText(serial,true)
	tooltip = string.gsub(tooltip,"\n","|")
	if (tooltip == "blood") then return end
	print("LootPluginNotify_Hook_ToolTipUpdate",SmartDump(serial),tooltip,SmartDump(data.unknown1),SmartDump(data.unknown2))
end
RegisterListenerOnce("Hook_ToolTipUpdate",function (...) LootPluginNotify_Hook_ToolTipUpdate(...) end,"LootPluginNotify_Hook_ToolTipUpdate")

function LootPluginNotify_Hook_Show_item (dynamic) end
RegisterListenerOnce("Hook_Show_item",function (...) LootPluginNotify_Hook_Show_item(...) end,"LootPluginNotify_Hook_Show_item")
]]--

end

--[[
notes for easyuo typcode transform...


gosub TypeTake		bomberoil      		OTK_     ; crimson dragon
gosub TypeTake		gold      		POF_
gosub TypeTake		fertiledirt   NZF_
gosub TypeTake		organicmat 		PLF_
gosub TypeTake		diamond       UVF
;gosub TypeTake		jewels    		HVF_UVF_FVF_EVF_OVF_VUF_GVF_RVF_BVF_VVF_NVF_ZVF_
gosub TypeIgnore	regsMage  		KUF_JUF_KZF_JZF_MZF_WZF_SZF_RZF_ ; perl,moss,garlic,ginseng,mandrake,night,sulfur,silk
gosub TypeIgnore	regsNecro 		IUF_TZF_YZF_DUF_UZF_ ; bat,dust,iron,demon,nox
gosub TypeIgnore	regsTamer 		WLF_IND_PLF_ ; springwater,petrawood,destroyingangel
gosub TypeIgnore	potion    		OUF_NUF_WUF_UUF_TUF_ ; gconfla/gmaskofdeath,gcure,emptybottle,gheal,explopot
gosub TypeIgnore	bandages  		AMF_ZLF_ ; bloody,normal
gosub TypeIgnore	scrolls   		AUL_BUL_CUL_DUL_EUL_FUL_GUL_HUL_IUL_JUL_KUL_LUL_MUL_NUL_OUL_PUL_QUL_RUL_SUL_TUL_UUL_VUL_WUL_XUL_YUL_ZUL_AVL_GVL_FVL_IVL_HVL_CVL_NTL_OTL_PTL_QTL_RTL_STL_TTL_UTL_VTL_WTL_XTL_YTL_ZTL_QXL_PXL_ZXL_NXL_WXL_VXL_YXL_XXL_ZFJ_BYL_CYL_DYL_EYL_FYL_GYL_HYL_IYL_JYL_KYL_KYM_PYM_SYM_TYM_WYM_UYM_GCR_ZBR_NCR_ACR_HCR_LCR_ICR_CCR_UCR_OCR_KCR_DCR_JCR_FCR_
gosub TypeTake   	arrowsbolts		RWF_LNK_FKF_
gosub TypeTake		biokrams      TDJ_WLF ; TDJ=vialset WLF=emptyvial
gosub TypeTake		solenloot 		GMF_OKF_TTO_  ; TTO:fungus GMF:petball IJG_ :bracelet
gosub TypeTake		jukaloot 		  JSL_USL_YWL_ ;JSL:arkane gem  WOH:bow
gosub TypeTake		paragonloot 	IIF_IKF_BUD_HIF_  ; BUD:parachest
gosub TypeTake		peerlesskeys 	QCK_FIL_XVK_OWK_MIG_YWK_ZFM_LZF_XOF_OXM_DXM_RBN_IXM_UBN_BXM_CGM
gosub TypeTake		questloot 		YJM_MSG_GHH_UVH_WLI_YWK_RY_QY_SY_PY_ ; _VRD : meat
gosub TypeTake    firehorn      ZWF
gosub TypeTake        keys           SEG_

; ?!?! (from badmaniacs) Book of Truth, Plate of Cookies, Tribal Mask,Mask of Orcish Kin, Evil Orc Helm, Fire Horn
;gosub TypeTake		unknownstuff	SLI_PZH_VSH_NWL_IWL_ZWF_FWL_NPF_FTK_  
;gosub TypeTake		jewelry    		CWL_LWL_UJG_IJG_ ; schmuck

gosub TypeTake	  leather			  EEG_GED_DEG_JJG_
gosub TypeIgnore	feather			  VLK_
gosub TypeIgnore	wool	        HFG_OFF_
gosub TypeIgnore	scale		      STO_ ; schuppen
gosub TypeIgnore	meat	        PUD_
gosub TypeIgnore	RawRibs			  VRD_
gosub TypeIgnore	bones		      OJK_XIK_SJK_IJK_TJK_BJK_UJK_DJK_MJK_AJK_LJK_FJK_RJK_EJK_ZIK_YIK_JJK_GJK_KJK_HJK_
gosub TypeIgnore	cutresources	JJG_GUF_ ;Itemtypes for bones and leather after cutting with scissor
gosub TypeIgnore	seed			    PDF_
;gosub TypeTake		tmap			    XVH_
gosub TypeTake		demonbone		  OZF_
gosub TypeTake		tribalberry		QQD_
gosub TypeTake		rare	        QIP_NWK_ ; Origami Paper, Healthy Gland
gosub TypeTake		sockelsteine  UZF_MCK_QWL_UVF ; UZF:kalcrystal MCK:skull QWL:mefrune UVF:leg.diamnond




]]--
