-- hotkey config dialog

gHotKeyData = gHotKeyData or {}
gHotKeyDialog_CurrentKeyIdx = 1

-- ***** ***** ***** ***** ***** load save

function HotKeys_LoadData    		() gHotKeyData =	SimpleXMLLoad(HotKeys_GetDataFilePath()) or {} end
function HotKeys_SaveData    		()              	SimpleXMLSave(HotKeys_GetDataFilePath(),gHotKeyData) end
function HotKeys_GetDataFilePath	() return GetConfigDirPath().."hotkeys.xml" end


-- ***** ***** ***** ***** ***** ConfigDialogPage_HotKey  (main)

function ConfigDialogPage_HotKey(page)
    --~ page:AddWidget(CreateWidgetFromXMLString(nil,"<UOText bold=1 text='not yet implemented'>"))
    
    local hbox = page:AddChild("HBox",{spacer=3})
    hbox:AddChild("Button",{label="Prev",on_button_click=function () print("show prev key") HotKeyDialog_ShowKeyIdx(gHotKeyDialog_CurrentKeyIdx - 1) end})
    hbox:AddChild("Button",{label="Next",on_button_click=function () print("show next key") HotKeyDialog_ShowKeyIdx(gHotKeyDialog_CurrentKeyIdx + 1) end})
    hbox:AddChild("Button",{label="Add" ,on_button_click=function () print("add key") table.insert(gHotKeyData,{}) HotKeyDialog_ShowKeyIdx(#gHotKeyData) end})
    hbox:AddChild("Button",{label="Del" ,on_button_click=function () print("del key") 
		if (gHotKeyDialog_CurrentKeyIdx <= #gHotKeyData) then
			table.remove(gHotKeyData,gHotKeyDialog_CurrentKeyIdx) 
			HotKeyDialog_ShowKeyIdx(gHotKeyDialog_CurrentKeyIdx) 
			HotKeys_SaveData()
		end
		end})
	
    -- GetMacroKeyComboName (keycode,char,bCtrl,bAlt,bShift) 
    
	
    local hbox = page:AddChild("HBox",{spacer=3})
    page.key = hbox:AddChild("Button",{label="???",w=260,on_button_click=function () 
		PollNextKey(function(keycode,char) HotKeyDialog_SetKey(ConfigHotKey_GetKeyName(keycode,char)) end) end})
		
    local hbox = page:AddChild("HBox",{spacer=3})
        
    hbox:AddWidget(CreateWidgetFromXMLString(nil,"<UOText bold=1 text='shift'>"))
    page.bShift     = hbox:AddChild("UOCheckBox",{gump_id_normal=210,gump_id_pressed=211,on_change=function (self,bState) HotKeyDialog_SetFlag("bShift",bState) end})
    
    hbox:AddWidget(CreateWidgetFromXMLString(nil,"<UOText bold=1 text='alt'>"))
    page.bAlt       = hbox:AddChild("UOCheckBox",{gump_id_normal=210,gump_id_pressed=211,on_change=function (self,bState) HotKeyDialog_SetFlag("bAlt",bState) end})
    
    hbox:AddWidget(CreateWidgetFromXMLString(nil,"<UOText bold=1 text='ctrl'>"))
    page.bCtrl      = hbox:AddChild("UOCheckBox",{gump_id_normal=210,gump_id_pressed=211,on_change=function (self,bState) HotKeyDialog_SetFlag("bCtrl",bState) end})
    
	
    gConfigDialogPage_HotKeys = page
    local hbox = page:AddChild("HBox",{spacer=3})
    gConfigDialogPage_HotKeys.btn_action = hbox:AddChild("Button",{label="???",w=260,on_button_click=function (widget)  
            local x,y = widget:GetDerivedLeftTop()
            ConfigDialogShowMenu(x,y,gConfigDialogHotkeyActionGroups,
                function (group) return group.name end,
                function (group) 
                    ConfigDialogShowMenu(x,y,group.list,
                        function (actiondata) return actiondata.callback and actiondata.name end,
                        function (actiondata) HotKeyDialog_SetAction(actiondata and actiondata.actionid) end)
                end)
        end})
		
		
    local ew,eh = 200,24
	
	-- param:text
    local row = page:AddChild("HBox")
    row:AddWidget(CreateWidgetFromXMLString(nil,"<UOText bold=1 text='Text:'>"))
	page.box_hotkey_param_text_row = row
    page.box_hotkey_param_text = row:AddChild("UOEditText",{width=ew,height=eh,text="",name="hotkey_param_text",hue=0,bHasBackPane=true})
	page.box_hotkey_param_text.on_change_text = function (self,text) HotKeyDialog_SetParamText(text) end
    page.box_hotkey_param_text_row:SetVisible(false)
	
	-- param:object
    local row = page:AddChild("HBox")
    row:AddWidget(CreateWidgetFromXMLString(nil,"<UOText bold=1 text='Object:'>"))
	page.box_hotkey_param_object_row = row
    page.box_hotkey_param_object = row:AddChild("Button",{label="???",w=260,on_button_click=function () 
		job.create(function ()
			local t = MacroCmd_JobGetTargetClientSide()
			if (not t) then return end
			local obj = GetDynamic(MacroCmd_GetStoredTarget_Serial(t) or 0)
			print("######################################################")
			print("hotkey:objpick:",SmartDump(t),MacroCmd_GetStoredTarget_Serial(t),obj)
			if (not obj) then return end
			HotKeyDialog_SetObject(obj.serial,obj.artid,obj.hue)
		end)
		end})
    page.box_hotkey_param_object_row:SetVisible(false)
	
	HotKeyDialog_ShowKeyIdx(1)
end


-- ***** ***** ***** ***** ***** HotKeyDialog_ShowKeyIdx

function HotKeyDialog_ShowKeyIdx (idx) 
	if (#gHotKeyData == 0) then table.insert(gHotKeyData,{}) end
	gHotKeyDialog_CurrentKeyIdx = max(1,min(#gHotKeyData,idx))
	print("HotKeyDialog_ShowKeyIdx",gHotKeyDialog_CurrentKeyIdx)
	
	local cur = HotKeyDialog_GetCur()
	
	HotKeyDialog_SetKey(cur.keyname)
	HotKeyDialog_SetAction(cur.actionid)
	HotKeyDialog_SetFlag("bShift"	,cur.bShift	,true)
	HotKeyDialog_SetFlag("bAlt"		,cur.bAlt	,true)
	HotKeyDialog_SetFlag("bCtrl"	,cur.bCtrl	,true)
	HotKeyDialog_SetParamText(cur.param_text,true)
	HotKeyDialog_SetObject(cur.param_obj_serial,cur.param_obj_artid,cur.param_obj_hue)
end

function HotKeyDialog_GetCur () return gHotKeyData[gHotKeyDialog_CurrentKeyIdx] end

function HotKeyDialog_SetData(fieldname,value)
	print("HotKeyDialog_SetData",fieldname,value)
	local cur = HotKeyDialog_GetCur()
	if (cur[fieldname] == value) then return end -- no change
	cur[fieldname] = value
	HotKeys_SaveData()
end

-- ***** ***** ***** ***** ***** data update

function HotKeyDialog_SetKey(keyname)
	HotKeyDialog_SetData("keyname",keyname)
	gConfigDialogPage_HotKeys.key:SetText(keyname or "-- select key --")
end
function ConfigHotKey_GetKeyName (keycode,char) return (keycode > 0) and GetKeyName(keycode) or ("0"..char) end

function HotKeyDialog_SetFlag (flagname,bState,bUpdateControl)
	HotKeyDialog_SetData(flagname,bState)
	if (bUpdateControl) then gConfigDialogPage_HotKeys[flagname]:SetState(bState) end
end

function HotKeyDialog_SetAction(actionid)
	local actiondata = GetHotKeyActionDataByID(actionid)
	HotKeyDialog_SetData("actionid",actionid)
    print("action",actiondata and actiondata.name)
    local group = actiondata and actiondata.group
    gConfigDialogPage_HotKeys.btn_action:SetText(actiondata and (group.name..":"..actiondata.name) or "--select action--")
    gConfigDialogPage_HotKeys.box_hotkey_param_text_row:SetVisible(actiondata and actiondata.bHasTextParam)
    gConfigDialogPage_HotKeys.box_hotkey_param_object_row:SetVisible(actiondata and (actiondata.bHasObjectParam))
end

function HotKeyDialog_SetParamText(param_text,bUpdateControl)
	HotKeyDialog_SetData("param_text",param_text)
	if (bUpdateControl) then gConfigDialogPage_HotKeys.box_hotkey_param_text:SetText(param_text or "") end
end

function HotKeyDialog_SetObject(param_obj_serial,param_obj_artid,param_obj_hue)
	HotKeyDialog_SetData("param_obj_serial",param_obj_serial)
	HotKeyDialog_SetData("param_obj_artid",param_obj_artid)
	HotKeyDialog_SetData("param_obj_hue",param_obj_hue)
	gConfigDialogPage_HotKeys.box_hotkey_param_object:SetText(
		param_obj_serial and 
		("serial:"..hex(param_obj_serial or 0)..",artid:"..hex(param_obj_artid or 0)..",hue:"..tostring(param_obj_hue)) or 
		"-- select object --")
end


-- ***** ***** ***** ***** ***** TriggerConfigHotkey

-- called from listener:keydown via lib.macrolist.lua:TriggerMacros()
function TriggerConfigHotkey (keycode,char,bCtrl,bAlt,bShift)
	local keyname = ConfigHotKey_GetKeyName(keycode,char)
	bCtrl = not not bCtrl
	bAlt = not not bAlt
	bShift = not not bShift
	--~ print("TriggerConfigHotkey1",keyname,bCtrl,bAlt,bShift)
	for k,hotkey in ipairs(gHotKeyData) do 
		if (hotkey.keyname == keyname and (not not keyname.bCtrl) == bCtrl and (not not keyname.bAlt) == bAlt and (not not keyname.bShift) == bShift) then
			local actiondata = GetHotKeyActionDataByID(hotkey.actionid)
			print("TriggerConfigHotkey2",keyname,bCtrl,bAlt,bShift,"action:",actiondata)
			if (actiondata and actiondata.callback) then 
				local a,b,c
				if (actiondata.bHasTextParam	) then a = hotkey.param_text end
				if (actiondata.bHasObjectParam	) then a,b,c = hotkey.param_obj_serial,hotkey.param_obj_artid,hotkey.param_obj_hue end
				job.create(function () actiondata:callback(a,b,c) end) 
			end
			return true
		end
	end
end

-- ***** ***** ***** ***** ***** hotkey actions

function HotkeyAction_Spell (actiondata)
	print("HotkeyAction_Spell",actiondata.spellid)
	if (actiondata.spellid) then MacroCmd_Spell(actiondata.spellid) end
end
function HotkeyAction_Skill (actiondata)
	print("HotkeyAction_Skill",actiondata.skillid_onebased)
	local skillname = actiondata.skillid_onebased and glSkillNames[actiondata.skillid_onebased]
	if (skillname) then MacroCmd_Skill(skillname) end
end
function HotkeyAction_Chat (actiondata,text)
	print("HotkeyAction_Chat",text,actiondata.texttype)
	if (text) then 
		if (actiondata.bIsPartChat) then text = "/"..text end 
		MacroCmd_Say(text,actiondata.texttype) -- see SendChat
	end
end

gHotKeyActionDataByID = gHotKeyActionDataByID or {}
function GetHotKeyActionDataByID(actionid) return gHotKeyActionDataByID[actionid] end -- returns actiondata

function InitConfigDialogHotkeyActions ()
	gHotKeyActionDataByID = {}
    gConfigDialogHotkeyActionGroups         = {}
    gConfigDialogHotkeyActionGroupsByName   = {}
    function MyAddHotkeyAction (groupname,actiondata)
        local group = gConfigDialogHotkeyActionGroupsByName[groupname]
        if (not group) then 
            group = { name=groupname, bIsGroup=true, list={} }
            gConfigDialogHotkeyActionGroupsByName[groupname] = group
            table.insert(gConfigDialogHotkeyActionGroups,group)
            --~ print("group:",groupname)
        end
        actiondata.group = group
		actiondata.actionid = (groupname or "???")..":"..(actiondata.name or "???")
        table.insert(group.list,actiondata)
		gHotKeyActionDataByID[actiondata.actionid] = actiondata
        --~ print(" +",actiondata.skillid_onebased or actiondata.spellid,actiondata.name)
    end
    
    -- add spell utils
    function MyAddSpell (bookname,spellname) 
        spellname = gSpellNameAlias[spellname] or spellname
        local spellid = SearchSpellIDByName(spellname)
        MyAddHotkeyAction(bookname,{name=spellname,callback=HotkeyAction_Spell,spellid=spellid,bHasTargetOption=true}) 
    end
    function MyAddSpellByInfo (bookname,spellinfo) 
        MyAddSpell(bookname,spellinfo.name)
    end
    function AddSpellsFromSpellbook (bookname,spellbookid)
        for pagenum,pagearr in ipairs(gSpellBooks[spellbookid].spells) do for k,spellname in ipairs(pagearr) do 
            MyAddSpell(bookname,spellname)
        end end
    end
    
    -- add all spells
    for i=1,8 do for k,info in pairs(gSpellInfo) do if (info.book == "Magery" and info.circle == i) then MyAddSpellByInfo("Magery"..i,info) end end end
    for k,info in pairs(gSpellInfo) do if (info.book == "Necro"         ) then MyAddSpellByInfo("Necromancy"    ,info) end end
    for k,info in pairs(gSpellInfo) do if (info.book == "Chiv"          ) then MyAddSpellByInfo("Chivalry"      ,info) end end
    for k,info in pairs(gSpellInfo) do if (info.book == "Spellweaving"  ) then MyAddSpellByInfo("Spellweaving"  ,info) end end
    AddSpellsFromSpellbook("Bushido",BushidoSpellbook)
    AddSpellsFromSpellbook("Ninjitsu",NinjitsuSpellbook)
    
    -- skills
    for id_onebased,skillname in ipairs(glSkillNames) do 
        if (glSkillActive[id_onebased] == 1) then
            MyAddHotkeyAction("skill",{name=skillname,callback=HotkeyAction_Skill,skillid_onebased=id_onebased,bHasTargetOption=true})
        end
    end
    
    local groupname = "interface"
    MyAddHotkeyAction(groupname,{name="ToggleBackpack"				,callback=function () MacroCmd_Open("Backpack") end})
    MyAddHotkeyAction(groupname,{name="ToggleJournal"				,callback=function () MacroCmd_Open("Journal") end})
    MyAddHotkeyAction(groupname,{name="ToggleSkills"				,callback=function () MacroCmd_Open("Skill") end})
    MyAddHotkeyAction(groupname,{name="TogglePaperdoll"				,callback=function () MacroCmd_Open("Paperdoll") end})
    MyAddHotkeyAction(groupname,{name="ToggleStatus"				,callback=function () MacroCmd_Open("Status") end})
    MyAddHotkeyAction(groupname,{name="ToggleCompass"				,callback=function () MacroCmd_Open("Compass") end})
    MyAddHotkeyAction(groupname,{name="ToggleMap"					,callback=function () GUI_ToggleMap() end})
    MyAddHotkeyAction(groupname,{name="CompassZoomOut"				,callback=function () MacroCmd_ZoomCompass(1*1.5) end})
    MyAddHotkeyAction(groupname,{name="CompassZoomIn"				,callback=function () MacroCmd_ZoomCompass(1/1.5) end})
    MyAddHotkeyAction(groupname,{name="CamZoomOut"					,callback=function () MacroCmd_CamChangeZoom( 0.3) end})
    MyAddHotkeyAction(groupname,{name="CamZoomIn"					,callback=function () MacroCmd_CamChangeZoom(-0.3) end})
    MyAddHotkeyAction(groupname,{name="Screenshot"					,callback=function () MacroCmd_Screenshot() end})
    MyAddHotkeyAction(groupname,{name="PacketVideo:ToggleRecording"	,callback=function () MacroCmd_TogglePacketVideoRecording() end})
    MyAddHotkeyAction(groupname,{name="NextCamMode"					,callback=function () MacroCmd_NextCamMode() end})
    MyAddHotkeyAction(groupname,{name="Toggle2D/3D"					,callback=function () MacroCmd_ActivateNextRenderer() end})
    MyAddHotkeyAction(groupname,{name="CycleMaxFPS"					,callback=function () MacroCmd_CycleMaxFPS() end})
    MyAddHotkeyAction(groupname,{name="Quit"						,callback=function () MacroCmd_Quit() end})
	
	
	function MyHotKeyToggleGlobalRiseText (varname,risetext,onvalue)
		if (_G[varname]) then 
			_G[varname] = nil 
			MacroCmd_RiseText(1,0,0,risetext..":-off-")
		else
			_G[varname] = onvalue or true 
			MacroCmd_RiseText(0,1,0,risetext..": ON ")
		end 
	end
	
    -- actions
    local groupname = "misc"
    MyAddHotkeyAction(groupname,{name="UseObjectByType"        	,callback=function (actiondata,serial,artid,hue) print("hotkey:UseObjectByType",serial,hex(artid),hue) MacroCmd_Item_Use(GetDynamic(serial or 0)) end,bHasObjectParam=true}) -- {potions,fukija,shuriken,bandage(old)}
    MyAddHotkeyAction(groupname,{name="UseObjectByID"          	,callback=function (actiondata,serial,artid,hue) if (artid) then MacroCmd_Item_UseByArtID(artid,hue) end end,bHasObjectParam=true})
    MyAddHotkeyAction(groupname,{name="UseNearbyByType"        	,callback=function (actiondata,serial,artid,hue) MacroCmd_Item_Use(GetRandomArrayElement(MacroCmd_Item_FindNearByArtList(artid and {artid},2))) end,bHasObjectParam=true})
    MyAddHotkeyAction(groupname,{name="LastSpell"              	,callback=function () MacroCmd_RepeatLastSpell() end}) -- todo : targetlast option ?
    MyAddHotkeyAction(groupname,{name="LastObject"             	,callback=function () MacroCmd_RepeatLastDoubleClick() end})
    MyAddHotkeyAction(groupname,{name="LastChat"               	,callback=function () MacroCmd_RepeatLastChat() end})
    MyAddHotkeyAction(groupname,{name="LastSkill"               ,callback=function () MacroCmd_RepeatLastSkill() end})
    MyAddHotkeyAction(groupname,{name="ToggleWarmode"          	,callback=function () MacroCmd_ToggleWarmode() end})
    MyAddHotkeyAction(groupname,{name="OpenDoor"       		   	,callback=function () MacroCmd_OpenDoors() end})
    MyAddHotkeyAction(groupname,{name="SpamLastSpell"			,callback=function () MacroCmd_TargetLastNow() MacroCmd_RepeatLastSpell() end},"repeat last spell on last target")
    MyAddHotkeyAction(groupname,{name="TargetSelf"				,callback=function () MacroCmd_TargetSelfNow() end})
    MyAddHotkeyAction(groupname,{name="TargetLast(dumb)"		,callback=function () MacroCmd_TargetLastNow() end})
    MyAddHotkeyAction(groupname,{name="TargetLast(smart)"		,callback=function () MacroCmd_SendTargetSerial(MacroCmd_GetSmartTargetForLastSpell(),gSpellCastRange) end})
    MyAddHotkeyAction(groupname,{name="TargetWeaponInHand"		,callback=function () MacroCmd_TargetWeaponInHand() end},"useful for poisoning")
    MyAddHotkeyAction(groupname,{name="WeaponSkill:Primary"    	,callback=function () MacroCmd_WeaponAbilityPrimary() end})
    MyAddHotkeyAction(groupname,{name="WeaponSkill:Secondary"  	,callback=function () MacroCmd_WeaponAbilitySecondary() end})
    MyAddHotkeyAction(groupname,{name="WeaponSkill:ToggleAuto"	,callback=function () 
		MyHotKeyToggleGlobalRiseText("gReActivateWeaponAbilityInterval","WeaponSkillAutoReactivate",3100)
		end},"auto-reactivate weapon ability after 3 seconds")
    MyAddHotkeyAction(groupname,{name="Dismount"               	,callback=function () MacroCmd_Dismount() end})
    MyAddHotkeyAction(groupname,{name="MountNearby"            	,callback=function () MacroCmd_MountNearby() end})
    MyAddHotkeyAction(groupname,{name="SelfInterrupt(hat)"     	,callback=function () InterruptOwnSpell(MacroCmd_GetPlayerEquipment(kLayer_Helm)) end},"interrupt self when casting spell")
    MyAddHotkeyAction(groupname,{name="SelfInterrupt(robe)"    	,callback=function () InterruptOwnSpell(MacroCmd_GetPlayerEquipment(kLayer_TorsoOuter)) end},"interrupt self when casting spell")
    MyAddHotkeyAction(groupname,{name="UseNearestGate"         	,callback=function () MacroCmd_UseNearbyGate() end})
    MyAddHotkeyAction(groupname,{name="MiniHealCureSelf"		,callback=function () MacroCmd_MiniHealCureSelf() end})
    MyAddHotkeyAction(groupname,{name="BandageSelf(builtin)"	,callback=function () MacroCmd_BandageSelf() end})
    MyAddHotkeyAction(groupname,{name="BandageSelf(use+target)"	,callback=function () MacroCmd_Item_UseByArtID(0xe21) MacroCmd_QueueTargetSerial(GetPlayerSerial(),1000) end})
    --~ MyAddHotkeyAction(groupname,{name="BandageNearbyParty"		,callback=function () MacroCmd_Item_UseByArtID(0xe21) MacroCmd_QueueTargetSerial(GetNearbyHealCurePartyMember(),1000) end})  -- pet,gray,nonparty..
    MyAddHotkeyAction(groupname,{name="SelectNearest"			,callback=function () local m=MacroCmd_FindNearestMob() MobListSetMainTargetSerial(m and m.serial or 0) end})
    MyAddHotkeyAction(groupname,{name="SelectRandomNonFriendly"			,callback=function () MacroCmd_SelectRandomNonFriendly() end})		-- all, random    -- target with TargetLast(Smart)
    MyAddHotkeyAction(groupname,{name="SelectRandomNonFriendlyPlayer"	,callback=function () MacroCmd_SelectRandomNonFriendly(true) end})	-- pvp, random..    -- target with TargetLast(Smart)
    MyAddHotkeyAction(groupname,{name="AttackSelected"			,callback=function () MacroCmd_AttackSelectedMobile() end},"meelee")
    MyAddHotkeyAction(groupname,{name="HideAllCorpses"			,callback=function () MacroCmd_HideAllCorpses() end})
    MyAddHotkeyAction(groupname,{name="ToggleHouseBlendout"		,callback=function () ToggleMultiOnlyShowFloor()  end})
    MyAddHotkeyAction(groupname,{name="ResyncRequest"			,callback=function () Send_Movement_Resync_Request() end},"ask server to resync player position and objects")
    MyAddHotkeyAction(groupname,{name="ToggleAlwaysRun"			,callback=function () MyHotKeyToggleGlobalRiseText("gAlwaysRun","AlwaysRun") end})
    MyAddHotkeyAction(groupname,{name="TargetRandomNearGround"	,callback=function () MacroCmd_TargetGroundNow(gPlayerXLoc+math.random(3)-2,gPlayerYLoc+math.random(3)-2) end})
    MyAddHotkeyAction(groupname,{name="TargetNearestTree"		,callback=function () local tree = GetRandomArrayElement(MacroCmd_FindNearbyTrees(2))  if (tree) then CompleteTargetModeWithTargetStatic(tree) end end})
    MyAddHotkeyAction(groupname,{name="WalkToRandomTree"		,callback=function () local tree = GetRandomArrayElement(MacroCmd_FindNearbyTrees(20)) if (tree) then MacroCmd_PathFindTo(tree.xloc,tree.yloc,2) end end})
    MyAddHotkeyAction(groupname,{name="SimpleLoot"				,callback=function () MacroCmd_SimpleLootStep() end},"loot a random item from nearby corpses")
    MyAddHotkeyAction(groupname,{name="ToggleAutoLoot"			,callback=function () ToggleAutoLoot() end})
    MyAddHotkeyAction(groupname,{name="ScavengeNearby"			,callback=function () MacroCmd_Scavenge(nil,2) end},"picks up nearby items")
    MyAddHotkeyAction(groupname,{name="CutNearbyCorpse"			,callback=function () MacroCmd_CutNearbyCorpse() end},"uses dagger or skinning knife to cut a nearby corpse")
    MyAddHotkeyAction(groupname,{name="ToggleTextEntryRepeat"	,callback=function () MacroCmd_ToggleTextEntryRepeatLastChat() end},"uses last chatline as text for all text-entry prompts, useful for filling vendors")
	
    local groupname = "walk"
    MyAddHotkeyAction(groupname,{name="WalkToMousePos"			,callback=function () MacroCmd_WalkToMouse() end})
    MyAddHotkeyAction(groupname,{name="Walk_North"				,callback=function () MacroCmd_WalkInDir(0) end})
    MyAddHotkeyAction(groupname,{name="Walk_NorthEast"			,callback=function () MacroCmd_WalkInDir(1) end})
    MyAddHotkeyAction(groupname,{name="Walk_East"				,callback=function () MacroCmd_WalkInDir(2) end})
    MyAddHotkeyAction(groupname,{name="Walk_SouthEast"			,callback=function () MacroCmd_WalkInDir(3) end})
    MyAddHotkeyAction(groupname,{name="Walk_South"				,callback=function () MacroCmd_WalkInDir(4) end})
    MyAddHotkeyAction(groupname,{name="Walk_SouthWest"			,callback=function () MacroCmd_WalkInDir(5) end})
    MyAddHotkeyAction(groupname,{name="Walk_West"				,callback=function () MacroCmd_WalkInDir(6) end})
    MyAddHotkeyAction(groupname,{name="Walk_NorthWest"			,callback=function () MacroCmd_WalkInDir(7) end})
	
	--[[
	-- mine and lumber : 
	MiniHealCureParty
	TargetrandomNearbyCorpse (necro animate? cut?)
	MountNearby (warmode off)
	BandageNearby
	BandageNearbyParty
	BandageNearbyFriendly
	BandageNearbyNonHostile
	BandageNearbySmart  (preference, self if low, party/guild,blue,pets...)
	RazorActions ...
	doubleclick nearby objtype (harvest)
	
	targetlast+castspell x (chooser, not last here)
	
	ToggleMinerGrid
	target nearest revenant.  (dispel)    local target = MacroCmd_FindNearestMobByName("revenant") or MacroCmd_FindNearestMobByName("blade spirit")
	necro-familiar-menu
	
	]]--
	-- mount nearest horse
	-- MacroCmd_UseRuneBookPreAOS , MacroCmd_UseRuneBookPostAOS  (method,idx)
    --~ MyAddHotkeyAction(groupname,{name="UseItemInHand(Wands)"   })
    --~ MyAddHotkeyAction(groupname,{name="OpenDoor(old/preaos)"   })
    --~ MyAddHotkeyAction(groupname,{name="Select"                 ,bHasTargetOption=true})
    --~ MyAddHotkeyAction(groupname,{name="Attack"                 ,bHasTargetOption=true})
    --~ MyAddHotkeyAction(groupname,{name="Target"                 ,bHasTargetOption=true})
    --~ MyAddHotkeyAction(groupname,{name="Mini Heal/Cure"         ,bHasTargetOption=true})
    --~ MyAddHotkeyAction(groupname,{name="Big Heal/Cure"          ,bHasTargetOption=true})
    --~ MyAddHotkeyAction(groupname,{name="Bandage"                ,bHasTargetOption=true})
    --~ MyAddHotkeyAction(groupname,{name="ReloadFukija"})
    --~ MyAddHotkeyAction(groupname,{name="ReloadShuriken"})
    --~ MyAddHotkeyAction(groupname,{name="CutCorpse"})
    --~ MyAddHotkeyAction(groupname,{name="CutLeather"}) -- scissor
    --~ MyAddHotkeyAction(groupname,{name="LeatherStep(lootleather,scissor leather,cut corpse,opencorpse)"})
    --~ MyAddHotkeyAction(groupname,{name="Harvester(cotton,flax,sheep)"})
    --~ MyAddHotkeyAction(groupname,{name="Restock(regs,pots,pouches,clothes)"})
    --~ MyAddHotkeyAction(groupname,{name="BuyAgent"})
    --~ MyAddHotkeyAction(groupname,{name="SellAgent"})
    --~ MyAddHotkeyAction(groupname,{name="Mover/Organizer(items)"})  -- move between containers, or to grid positions
    --~ MyAddHotkeyAction(groupname,{name="UseOnce(Pouches)"}) -- saves a list, when an item is used, it is removed from list, when list is empty, it is refilled ?
    -- (razor:add/remove friend (targetting))
	-- todo: screenshot/vid
    
    
    -- chat
    local groupname = "chat"
    MyAddHotkeyAction(groupname,{name="Say",        bHasTextParam=true, callback=HotkeyAction_Chat})  
    MyAddHotkeyAction(groupname,{name="Yell",       bHasTextParam=true, callback=HotkeyAction_Chat, texttype=kTextType_Yell})  
    MyAddHotkeyAction(groupname,{name="Wisper",     bHasTextParam=true, callback=HotkeyAction_Chat, texttype=kTextType_Whisper})  
    MyAddHotkeyAction(groupname,{name="Emote",      bHasTextParam=true, callback=HotkeyAction_Chat, texttype=kTextType_Emote})  
    MyAddHotkeyAction(groupname,{name="Guild",      bHasTextParam=true, callback=HotkeyAction_Chat, texttype=kTextType_Guild})  
    MyAddHotkeyAction(groupname,{name="Alliance",   bHasTextParam=true, callback=HotkeyAction_Chat, texttype=kTextType_Alliance})  
    MyAddHotkeyAction(groupname,{name="Party",      bHasTextParam=true, callback=HotkeyAction_Chat, bIsPartChat=true})  
    
    -- macros
    --~ local groupname = "macros"
    -- todo 
    
    -- dress
    --~ local groupname = "dress"
    --~ MyAddHotkeyAction(groupname,{name="Toggle Left-Hand"})
    --~ MyAddHotkeyAction(groupname,{name="Toggle Right-Hand"})
    --~ MyAddHotkeyAction(groupname,{name="Redress(after death)"})
    -- todo 
    
    --~ todo : party/guild : treat as friend : options
    --~ todo : target specific ids (for runebooks or curepet)
    --~ todo : target : instant(nodelay:only works when targetcursor is already there),auto,specified
    --  spellparam : target + target-delay (delay/timeout : auto? hardcode?)
end
InitConfigDialogHotkeyActions()

--[[
--~ gCharCreateSkillIDs["Anatomy"]                  = 1
--~ glSkillNames = {    [2]     = "Anatomy",    1-55
for id_onebased = 1,55 do 
    local name = glSkillNames[id_onebased]
    local name2
    for k,id_zerobased in pairs(gCharCreateSkillIDs) do 
        if (id_zerobased + 1 == id_onebased) then name2 = k end
    end
    local id_zerobased = gCharCreateSkillIDs[name]
    if (name ~= name2) then 
        print("skillname mismatch : id_onebased,name(glSkillNames),name2(gCharCreateSkillIDs)",id_onebased,name,name2)
    end
end
--~ skillname mismatch : id_onebased,name(glSkillNames),name2(gCharCreateSkillIDs)  4       Item ID (Appraise)              Item Identification
--~ skillname mismatch : id_onebased,name(glSkillNames),name2(gCharCreateSkillIDs)  6       Parrying (Battle Defense)       Parrying
--~ skillname mismatch : id_onebased,name(glSkillNames),name2(gCharCreateSkillIDs)  8       Blacksmithing                   Blacksmith
--~ skillname mismatch : id_onebased,name(glSkillNames),name2(gCharCreateSkillIDs)  9       Bowcraft                        Bowcraft/Fletching
--~ skillname mismatch : id_onebased,name(glSkillNames),name2(gCharCreateSkillIDs)  10      Peacemaking (Calming)           Peacemaking
--~ skillname mismatch : id_onebased,name(glSkillNames),name2(gCharCreateSkillIDs)  15      Detect Hidden                   Detecting Hidden
--~ skillname mismatch : id_onebased,name(glSkillNames),name2(gCharCreateSkillIDs)  27      Magic Resistance                Resisting Spells
--~ skillname mismatch : id_onebased,name(glSkillNames),name2(gCharCreateSkillIDs)  36      Animal Taming (Taming)          Animal Taming
skillname mismatch : id_onebased,name(glSkillNames),name2(gCharCreateSkillIDs)  27      Magic Resistance        Resisting Spells
skillname mismatch : id_onebased,name(glSkillNames),name2(gCharCreateSkillIDs)  36      Animal Taming (Taming)  Animal Taming
]]--


