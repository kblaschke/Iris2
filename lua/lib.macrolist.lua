--[[ ***** see Iris2 COPYING for license info ***** ]]--
--[[ \brief
        handles macro list
]]--

gMacroList = {}

gMacroOpenCommands = {}
gMacroOpenCommands.Status           = function()    ToggleStatusAos()           end
gMacroOpenCommands.Skill            = function()    ToggleSkill()               end
gMacroOpenCommands.Journal          = function()    ToggleJournal()             end
gMacroOpenCommands.Backpack         = function()    TogglePlayerBackpack()      end
gMacroOpenCommands.Paperdoll        = function()    TogglePlayerPaperdoll()     end
gMacroOpenCommands.Compass          = function()    ToggleCompass()             end
gMacroOpenCommands.Logo             = function()    ToggleLogo()                end
gMacroOpenCommands.PartyList        = function()    TogglePartyList()           end

gMacroItemSlots = {}
gMacroReadMobileStats = {}
gMacroReadMobileStats.curHits       = true
gMacroReadMobileStats.maxHits       = true
gMacroReadMobileStats.curMana       = true
gMacroReadMobileStats.maxMana       = true
gMacroReadMobileStats.curStamina    = true
gMacroReadMobileStats.maxStamina    = true
gMacroReadMobileStats.curWeight     = true
gMacroReadMobileStats.maxWeight     = true
gMacroReadMobileStats.maxPet		= true
gMacroReadMobileStats.curPet		= true
gMacroReadMobileStats.tithing		= true
gMacroReadMobileStats.str			= true
gMacroReadMobileStats.dex			= true
gMacroReadMobileStats.int			= true

function GetMobileStat(mobile,statname) return mobile and mobile.stats and mobile.stats[statname] or 0 end 
function GetMobileRelHP(serial) local mobile = GetMobile(serial) return mobile and mobile:GetRelHP() end 

function GetPlayerHitsRel() return GetMobileRelHP(GetPlayerSerial()) end 
function GetPlayerManaCur() return GetMobileStat(GetPlayerMobile(),"curMana") end 
function GetPlayerManaMax() return GetMobileStat(GetPlayerMobile(),"maxMana") end 
function GetPlayerStamCur() return GetMobileStat(GetPlayerMobile(),"curStamina") end 
function GetPlayerStamMax() return GetMobileStat(GetPlayerMobile(),"maxStamina") end 
function GetPlayerHitsCur() return GetMobileStat(GetPlayerMobile(),"curHits") end 
function GetPlayerHitsMax() return GetMobileStat(GetPlayerMobile(),"maxHits") end 
function GetPlayerPetsCur() return GetMobileStat(GetPlayerMobile(),"curPet") end  -- follower slots
function GetPlayerPetsMax() return GetMobileStat(GetPlayerMobile(),"maxPet") end
function GetPlayerStr() 	return GetMobileStat(GetPlayerMobile(),"str") end
function GetPlayerDex() 	return GetMobileStat(GetPlayerMobile(),"dex") end
function GetPlayerInt() 	return GetMobileStat(GetPlayerMobile(),"int") end
		
function GetPlayerTithingPoints() return GetMobileStat(GetPlayerMobile(),"tithing") end
function IsPlayerHidden() local mobile = GetPlayerMobile() return mobile and mobile.flag_hidden end

function MacroCmd_PlayerDead 	 () return MacroCmd_MobileDead(GetPlayerMobile()) end
function MacroCmd_PlayerPoisoned () return MacroCmd_MobilePoisoned(GetPlayerMobile()) end
function MacroCmd_PlayerMortaled () return MacroCmd_MobileMortaled(GetPlayerMobile()) end
function MacroCmd_MobileDead	 (mobile) return mobile and (mobile.artid == 402 or mobile.artid == 403) end -- ghost form
--~ function MacroCmd_MobileDead	 (mobile) return mobile and GetMobileRelHP(mobile.serial) == 0 end
function MacroCmd_MobilePoisoned (mobile) return mobile and IsMobilePoisoned(mobile) end
function MacroCmd_MobileMortaled (mobile) return mobile and IsMobileMortaled(mobile) end

function MacroCmd_MiniHealCureSelf () 
    if (not GetPlayerMobile()) then return end
    if (MacroCmd_MobilePoisoned(GetPlayerMobile())) then
        MacroCmd_Spell("Cure"   ,GetPlayerSerial())
    else
        MacroCmd_Spell("Heal"   ,GetPlayerSerial())
    end
end

kSmartSpellHealSmall    = 4
kSmartSpellHealBig      = 29
kSmartSpellCureSmall    = 11
kSmartSpellCureBig      = 25
-- returns serial,bIsFriendly
function MacroCmd_GetSmartTargetForLastSpell () -- smart targets for friendly spells (heal,cure)
    if (gSmartLastSpellID) then 
        if (gSmartLastSpellID == kSmartSpellHealSmall or gSmartLastSpellID == kSmartSpellHealBig) then
            local target = MobileList_GetWeakestFromList(MobileList_HealablePartyMembers(true))
            --~ print("healtarget",target)
            return target and target.serial or GetPlayerSerial(),true
        end
        if (gSmartLastSpellID == kSmartSpellCureSmall or gSmartLastSpellID == kSmartSpellCureBig) then
            local target = MobileList_GetWeakestFromList(MobileList_CurablePartyMembers(true))
            --~ print("curetarget",target)
            return target and target.serial or GetPlayerSerial(),true
        end
    end
    -- gLastSpellID
    return MobListGetMainTargetSerial()
end

function MobileList_GetWeakestFromList      (list) 
    local found
    local foundhp
    for k,mobile in pairs(list) do 
        local curhp = mobile:GetRelHP() or 1
        --~ print("MobileList_GetWeakestFromList",curhp)
        if ((not foundhp) or foundhp > curhp) then foundhp = curhp found = mobile end
    end
    return found 
end

-- checking if a mob has equip helps detecting humans/players
function MobileHasEquip   (mobile) 
	for index,layer in pairs(gLayerOrder) do
		-- slime has kLayer_Backpack , dog not
		if (layer ~= kLayer_Backpack and mobile:GetEquipmentAtLayer(layer)) then return true end
	end
	return false
end
function MobileIsHuman   (mobile) 
	return	mobile and
			mobile.artid == 400 or mobile.artid == 401 or
			mobile.artid == 744 or mobile.artid == 745 or MobileHasEquip(mobile) -- vampform wolfform ? 
end

function MobileList_GetByFilter (fun)
	local res = {}
	for k,mobile in pairs(GetMobileList()) do if (fun(mobile)) then table.insert(res,mobile) end end
	return res
end


function MobileList_HealablePartyMembers    (bFriendsAlso) 
	return MobileList_GetByFilter(function (mobile) return	GetUODistToPlayer(mobile.xloc,mobile.yloc) <= gSpellCastRange and 
															(not MacroCmd_MobilePoisoned(mobile)) and (not MacroCmd_MobileMortaled(mobile)) and 
															(IsMobileInParty(mobile.serial) or (bFriendsAlso and mobile.notoriety == kNotoriety_Friend and MobileIsHuman(mobile))) and
															(mobile:GetRelHP() or 0) < 1 and 
															(mobile:GetRelHP() or 0) > 0 end) -- not dead
end
function MobileList_CurablePartyMembers    (bFriendsAlso) 
	return MobileList_GetByFilter(function (mobile) return	GetUODistToPlayer(mobile.xloc,mobile.yloc) <= gSpellCastRange and 
															(MacroCmd_MobilePoisoned(mobile)) and 
															(IsMobileInParty(mobile.serial) or (bFriendsAlso and mobile.notoriety == kNotoriety_Friend and MobileIsHuman(mobile))) and
															(mobile:GetRelHP() or 0) < 1 end)
end

-- GetPlayerMobile
function MacroRead_PlayerStat           (statname) return MacroReadAux_MobileStat(GetPlayerMobile(),statname,"MacroRead_PlayerStat") end
function MacroRead_TargetStat           (statname) return MacroReadAux_MobileStat(GetMobile(giSelectedMobile),statname,"MacroRead_TargetStat") end

function MacroRead_SkillDataPart          	(skillname,partname) -- internal, used by the others
    for skillid,name in pairs(glSkillNames) do
        if skillname == name then return gPlayerSkills and gPlayerSkills[skillid] and gPlayerSkills[skillid][partname] end
    end
end
function MacroRead_SkillBaseSum () 
	local c = 0
	for skillid,name in pairs(glSkillNames) do c = c + MacroRead_SkillBase(name) end
	return c
end
function MacroRead_SkillBase			(skillname) return (MacroRead_SkillDataPart(skillname,"base_value") or -1)  * 0.1 end 
function MacroRead_SkillCap				(skillname) return (MacroRead_SkillDataPart(skillname,"skill_cap") or -1)  * 0.1 end 
function MacroRead_SkillValue			(skillname) return (MacroRead_SkillDataPart(skillname,"value") or -1)  * 0.1 end
function MacroRead_SkillLockState		(skillname) return MacroRead_SkillDataPart(skillname,"lockstate") end -- 0=up, 1=down, 2=lock
function MacroCmd_SetSkillLockState		(skillname,lockstate)
    for skillid,name in pairs(glSkillNames) do
        if skillname == name then Send_SkillLockState(skillid-1,tonumber(lockstate) or 0) return true end
    end
end -- 0=up, 1=down, 2=lock



function MacroRead_BuffActive           (buffname)
    for id,v in pairs(gBuffIcons) do
        if buffname == v.name then
            return gBuffs[id] or false
        end
    end
    return false
end

function MacroCmd_Say                   (text,textmode)  if (gInGameStarted) then SendChat(text,nil,nil,textmode) end end
function MacroCmd_NextCamMode           ()      gCurrentRenderer:ChangeCamMode() end
function MacroCmd_BandageSelf           ()      SendBandageSelf() end
function MacroCmd_Quit                  ()      Terminate() end
function MacroCmd_RepeatLastChat        ()      if (gInGameStarted) then IrisChatLine_RepeatLast() end end
function MacroCmd_RepeatLastDoubleClick ()      if (gInGameStarted) then RepeatLastDoubleClick() end end
function MacroCmd_SelectNearestMobile   ()      if (gInGameStarted) then SelectNearestMobile() end end
function MacroCmd_SelectNextMobile      ()      if (gInGameStarted) then SelectNextMobile() end end
function MacroCmd_AttackSelectedMobile  ()      if (gInGameStarted) then if giSelectedMobile then AttackMobile(giSelectedMobile) end end end
function MacroCmd_ToggleWarmode         ()      if (gInGameStarted) then Send_CombatMode(IsWarModeActive() and gWarmode_Normal or gWarmode_Combat) end end
function MacroCmd_OpenDoors             ()      Send_OpenDoors() end
function MacroCmd_Open                  (dialogtype)
    if (not gInGameStarted) then return end
    local f = gMacroOpenCommands[dialogtype] 
    if (not f) then return MacroErrorNameMismatch("MacroCmd_Open",dialogtype,gMacroOpenCommands) end
    f() 
end

function MacroCmd_SmartSelectTarget 		(bPlayersOnly) MacroCmd_SelectRandomNonFriendly(bPlayersOnly) end
function MacroCmd_SelectRandomNonFriendly	(bPlayersOnly)
	local target = GetRandomTableElementValue(bPlayersOnly and MacroCmd_ListNonFriendlyPlayers() or MacroCmd_ListNonFriendlyMobiles())
	print("MacroCmd_SelectRandomNonFriendly",bPlayersOnly,target,target and target.serial)
	MobListSetMainTargetSerial(target and target.serial or 0) 
end

function MacroCmd_UseNearbyGate () local gate = MacroCmd_Item_FindFirstNearByArtID(kMoongateGateArtID,nil,1) MacroCmd_Item_Use(gate) return gate ~= nil end

function MacroCmd_ToggleHideGUI () GuiToggleHide() Client_RenderOneFrame() end


function MacroCmd_StartTargetModeClientSide () StartTargetMode_ClientSide() end
function MacroCmd_CancelTargetMode () return CancelTargetMode() end

function MacroCmd_JobGetTargetClientSide ()
	local jobid = job.running_id() assert(jobid)
	local res
	RegisterListener("Hook_TargetMode_Send",function (...) res = {...} job.wakeup(jobid) return true end)
	MacroCmd_StartTargetModeClientSide()
	job.wait(1000*3600*24)
	if (not res) then return end
	local bIsPos,flag,serial,x,y,z,model,bIsCancel = unpack(res)
	if (bIsCancel) then return false end
	return MacroCmd_StoreLastTarget()
end

function MacroCmd_StoreLastTarget () return CopyArray(gMacroLastTargetMemory) end
function MacroCmd_SendStoredTarget (t) return CompleteTargetMode(t) end
function MacroCmd_GetStoredTarget_Serial (t)
	if (not t) then return end
    if (t.hittype == kMousePickHitType_Mobile) then return t.mobile.serial end
    if (t.hittype == kMousePickHitType_Dynamic) then return t.dynamic.serial end
    if (t.hittype == kMousePickHitType_ContainerItem) then return t.item.serial end
    if (t.hittype == kMousePickHitType_PaperdollItem) then return t.item.serial end
end
function MacroCmd_GetStoredTarget_Pos (t)
	if (not t) then return end
    if (t.hittype == kMousePickHitType_Mobile) then return t.mobile.xloc,t.mobile.yloc,t.mobile.zloc end
    if (t.hittype == kMousePickHitType_Dynamic) then return t.dynamic.xloc,t.dynamic.yloc,t.dynamic.zloc end
    if (t.hittype == kMousePickHitType_Static) then return t.hit_xloc,t.hit_yloc,t.hit_zloc end
    if (t.hittype == kMousePickHitType_Ground) then return t.x,t.y,t.z end
    return t.hit_xloc,t.hit_yloc,t.hit_zloc
end
	
function MacroCmd_PopupCommandByTag (serial,tag,timeout)
    local timeout_endt = Client_GetTicks() + (timeout or 1000)
    Send_PopupRequest(serial)
    Send_PopupAnswer(serial,tag)
    RegisterListener("Hook_OpenPopupMenu",function (popupmenu)
        if (popupmenu.serial == serial or Client_GetTicks() < timeout_endt) then ClosePopUpMenu() end
        return true
    end)
end 

function MacroCmd_PopupCommandByName (serial,name,timeout)
	if (not serial) then return end
	if (type(serial) ~= "number") then return end
    local timeout_endt = Client_GetTicks() + (timeout or 1000)
	ClosePopUpMenu() -- close old
    Send_PopupRequest(serial)
    RegisterListener("Hook_OpenPopupMenu",function (popupmenu)
        if (popupmenu.serial == serial or Client_GetTicks() < timeout_endt) then 
            for k,entry in pairs(popupmenu.entries) do 
				print("MacroCmd_PopupCommandByName",">"..entry.text.."<",entry.tag)
                if (StringContains(entry.text,name)) then Send_PopupAnswer(popupmenu.serial,entry.tag) break end
            end
            ClosePopUpMenu()
        end 
        return true
    end)
end

function MacroCmd_SendTargetSerial  (serial,maxrange) 
    local mobile = GetMobile(serial)
    if mobile then return CompleteTargetMode({ hittype = kMousePickHitType_Mobile,  mobile = mobile },maxrange) end
    local dynamic = GetDynamic(serial)
    if dynamic then return CompleteTargetMode({ hittype = kMousePickHitType_Dynamic,  dynamic = dynamic },maxrange) end
end

-- timeout : in ms
-- bFailBySpellInterrupt : if true, then it will be aborted if a message indicating spell interruption is received
function MacroCmd_QueueTargetSerial     (serial,timeout,callback,bFailBySpellInterrupt)
    gMacroQueuedTarget_Serial = serial
    gMacroQueuedTarget_Timeout = Client_GetTicks() + timeout
    gMacroQueuedTarget_CallBack = callback
    gMacroQueuedTarget_FailBySpellInterrupt = bFailBySpellInterrupt
    if (IsTargetModeActive()) then
        MacroCmd_SendTargetSerial(serial)
        MacroCmd_QueuedTargetEnd(true)
    end
end
function MacroCmd_QueuedTargetEnd   (bSuccess,sFailureReason) 
    if (gMacroQueuedTarget_CallBack) then gMacroQueuedTarget_CallBack(bSuccess,sFailureReason) end
    gMacroQueuedTarget_CallBack = nil
    gMacroQueuedTarget_Serial = nil
    gMacroQueuedTarget_Timeout = nil
    gMacroQueuedTarget_FailBySpellInterrupt = nil
end

RegisterStepper(function () 
    local t = Client_GetTicks()
    if (gMacroQueuedTarget_Timeout and t > gMacroQueuedTarget_Timeout) then MacroCmd_QueuedTargetEnd(false,"timeout") end
    for data,v in pairs(gMacroGumpWaiters) do
        if (t > data.timeout) then data.callback() gMacroGumpWaiters[data] = nil end
    end
end)
RegisterListener("Hook_Spell_Interrupt",    function ()
    if (gMacroQueuedTarget_FailBySpellInterrupt) then MacroCmd_QueuedTargetEnd(false,"spell-interrupt") end
end)
gMacroJobsWaitingForTarget = {}
function MacroCmd_JobWaitForTarget(timeout) -- returns true if IsTargetModeActive
	if (IsTargetModeActive()) then return true end
    gMacroJobsWaitingForTarget[job.running_id()] = true
    job.wait(timeout or 30000)
    gMacroJobsWaitingForTarget[job.running_id()] = nil
    return IsTargetModeActive()
end
RegisterListener("Hook_TargetMode_Start",   function () 
    if (gMacroQueuedTarget_Serial) then MacroCmd_SendTargetSerial(gMacroQueuedTarget_Serial) MacroCmd_QueuedTargetEnd(true) end
    for jobid,v in pairs(gMacroJobsWaitingForTarget) do job.wakeup(jobid,true) end gMacroJobsWaitingForTarget = {}
end)
RegisterListener("Hook_TargetMode_Start",   function () 
    if (gMacroQueuedTarget_Serial) then MacroCmd_SendTargetSerial(gMacroQueuedTarget_Serial) MacroCmd_QueuedTargetEnd(true) end
end)

gMacroJobsWaitingForGump = {}
function MacroCmd_JobWaitForGump(callback,timeout) -- callback(dialog,playerid,dialogId) should return true for the gump that it waited for
    gMacroJobsWaitingForGump[job.running_id()] = callback
    job.wait(timeout or 30000)
    gMacroJobsWaitingForGump[job.running_id()] = nil
end
function MacroCmd_JobWaitForGumpWithKeyword(keyword,timeout) 
    local dialog = MacroCmd_FindGumpByKeyword(keyword)
    if (dialog) then return dialog end
    MacroCmd_JobWaitForGump(function(dialog) return dialog:Search(keyword) end,timeout) 
    return MacroCmd_FindGumpByKeyword(keyword)
end
function MacroCmd_FindGumpByKeyword(keyword)
    for k,dialog in pairs(gServerSideGump) do 
        if (dialog:Search(keyword)) then return dialog end
    end
end

RegisterListener("Hook_OpenServersideGump", function (dialog,playerid,dialogId,Length_Data) 
    for data,v in pairs(gMacroGumpWaiters) do
        if ((not data.search) or dialog:Search(data.search)) then data.callback(dialog) gMacroGumpWaiters[data] = nil end
    end
    
    for jobid,callback in pairs(gMacroJobsWaitingForGump) do 
        if ((not callback) or callback(dialog,playerid,dialogId)) then 
            job.wakeup(jobid,true) 
            gMacroJobsWaitingForGump[jobid] = nil 
        end
    end
end)

gMacroGumpWaiters = {} 
-- callback(dialog) or callback(nil) for timeout
function MacroCmd_NextGumpContaining (search,timeout,callback) 
    if (not callback) then return end
    gMacroGumpWaiters[{search=search,timeout=Client_GetTicks()+(timeout or 1000),callback=callback}] = true
end


gMacroJobsWaitingForShop = {}
function MacroCmd_JobWaitForShop(timeout)
    gMacroJobsWaitingForShop[job.running_id()] = true
    job.wait(timeout or 30000)
    gMacroJobsWaitingForShop[job.running_id()] = nil
end
RegisterListener("Hook_Open_Shop_Dialog", function (shop) 
    for jobid,callback in pairs(gMacroJobsWaitingForShop) do 
		gMacroJobsWaitingForShop[jobid] = nil
		job.wakeup(jobid,true) 
	end
	end)
	

-- method:  nil=recall "gate"=gate  "use"=runebookcharge
function MacroCmd_UseRuneBookPreAOS (runebookid,runeidx,method,timeout) -- for pre-aos (uogamers)   runeidx:0-15      
    Send_DoubleClick(runebookid)
    MacroCmd_NextGumpContaining("Charges",timeout or 1000,function (dialog) 
            if (dialog) then 
                dialog:ShowPage(floor(runeidx/2)+2)
                local side = (runeidx%2)
                if (method == "gate") then
                    dialog:SendClick((side == 0) and 230 or 390,160) -- gate travel
                elseif (method == "use") then
                    dialog:SendClick((side == 0) and 135 or 295,70) -- runebook charge
                else    
                    dialog:SendClick((side == 0) and 160 or 320,160) -- recall
                end
            end
        end) 
end

-- method:  nil=recall "gate"=gate "chivalry"=sacred-journey "use"=runebookcharge  "default":set as runebook default
function MacroCmd_UseRuneBookPostAOS (runebookid,runeidx,method,timeout,forcew,forceh) -- for post-aos (vetus-mundus)   runeidx:0-15      
    Send_DoubleClick(runebookid)
    MacroCmd_NextGumpContaining("Charges",timeout or 1000,function (dialog) 
            if (dialog) then 
                dialog:ShowPage(floor(runeidx/2)+2)
                local side = (runeidx%2)
				if (method == "use") then
                    dialog:SendClick((side == 0) and 135 or 295,70,forcew,forceh) -- runebook charge
                elseif (method == "gate") then
                    dialog:SendClick((side == 0) and 140 or 300,160,forcew,forceh) -- gate travel
                elseif (method == "chivalry") then
                    dialog:SendClick((side == 0) and 140 or 300,180,forcew,forceh) -- chivalry : sacred journey
                elseif (method == "default") then
                    dialog:SendClick((side == 0) and 165 or 305,25,forcew,forceh) -- recall
                else    
                    dialog:SendClick((side == 0) and 140 or 300,145,forcew,forceh) -- recall
                end
            end
        end) 
end

gMacroLastTargetMemory = nil
gMacroTargetLastRunning = false
function MacroRememberTarget (hitobject)
    gMacroLastTargetMemory = {}
    for k,v in pairs(hitobject) do gMacroLastTargetMemory[k] = v end
end
function MacroSetLastTarget (serial)
    local mobile = GetMobile(serial)
    if (mobile) then gMacroLastTargetMemory = { hittype=kMousePickHitType_Mobile, mobile=mobile } return end
    local dynamic = GetDynamic(serial)
    if (dynamic) then gMacroLastTargetMemory = { hittype=kMousePickHitType_Dynamic, dynamic=mobile } return end
end

function MacroGetLastTargetSerial ()
    if (not gMacroLastTargetMemory) then return 0 end
	return MacroCmd_GetStoredTarget_Serial(gMacroLastTargetMemory)
end

function MacroCmd_LastTargetVisible ()
    if (not gMacroLastTargetMemory) then return end
    if (gMacroLastTargetMemory.hittype == kMousePickHitType_Mobile) then
        local mobile = GetMobile(gMacroLastTargetMemory.mobile.serial)
        return mobile ~= nil
    end
    if (gMacroLastTargetMemory.hittype == kMousePickHitType_Dynamic) then
        local dynamic = GetDynamic(gMacroLastTargetMemory.dynamic.serial)
        return dynamic ~= nil
    end
end


function MacroCmd_TargetLastNow () if (gMacroLastTargetMemory) then CompleteTargetMode(gMacroLastTargetMemory) end end
function MacroCmd_TargetSelfNow () CompleteTargetModeWithTargetMobile(GetPlayerMobile()) end

function MacroCmd_WeaponAbilityPrimary      () local a,b = GetWeaponSpecialsForMobile(GetPlayerMobile()) Send_AOSCommand_WeaponAbility(a) end
function MacroCmd_WeaponAbilitySecondary    () local a,b = GetWeaponSpecialsForMobile(GetPlayerMobile()) Send_AOSCommand_WeaponAbility(b) end

-- timeout in ms, defaults to 30 seconds
gMacroTargetLastRunningNextIndex = 1
function MacroCmd_TargetLast    (completefun,timeout)       -- repeat the last target   
    timeout = timeout or 30000
    if (gMacroTargetLastRunning) then return end
    if (not gMacroLastTargetMemory) then return end
    
    if (IsTargetModeActive()) then
        MacroCmd_TargetLastNow()
        if (completefun) then completefun() end
        return 
    end
    
    local myindex = gMacroTargetLastRunningNextIndex
    gMacroTargetLastRunningNextIndex = gMacroTargetLastRunningNextIndex + 1
    gMacroTargetLastRunning = myindex
    local listener = RegisterListener("Hook_TargetMode_Start",function ()
            if (myindex ~= gMacroTargetLastRunning) then return true end -- timeout was reached, or other targetlast started
            MacroCmd_TargetLastNow()
            gMacroTargetLastRunning = false
            if (completefun) then completefun() end
            return true
        end)
    if (timeout) then 
        InvokeLater(timeout,function ()
                if (not gMacroTargetLastRunning) then return end
                UnregisterListener("Hook_TargetMode_Start",listener)
                gMacroTargetLastRunning = false
                print("MacroCmd_TargetLast timeout")
            end)
    end
end

function MacroCmd_TargetGround  (xloc,yloc,zloc_or_nil, completefun)
    if (gMacroWaitForTargetActive) then return end
    gMacroWaitForTargetActive = true
    RegisterListener("Hook_TargetMode_Start",function () 
            print("MacroCmd_TargetGround hook triggered")
            MacroCmd_TargetGroundNow(xloc,yloc,zloc_or_nil)
            gMacroWaitForTargetActive = false
            if (completefun) then completefun() end
            return true
        end)
end

-- zloc_or_nil : determined automatically if nil
function MacroCmd_TargetGroundNow (xloc,yloc,zloc_or_nil)
    if (xloc and yloc) then
        local zloc = zloc_or_nil or GetGroundZAtAbsPos(xloc,yloc) or 0
        CompleteTargetMode({hittype=kMousePickHitType_Ground,x=xloc,y=yloc,z=zloc}) 
    end
end

function MacroCmd_TargetSelf    (completefun)       -- target self
    if (gMacroWaitForTargetActive) then return end
    gMacroWaitForTargetActive = true
    RegisterListener("Hook_TargetMode_Start",function () 
            local playermobile = GetPlayerMobile()
            print("MacroCmd_TargetSelf hook triggered")
            if (playermobile) then 
                print("#",playermobile.serial)
                CompleteTargetMode({hittype=kMousePickHitType_Mobile,mobile=playermobile}) 
            end
            gMacroWaitForTargetActive = false
            if (completefun) then completefun() end
            return true
        end)
end

-- currently broken
--~ function MacroCmd_ShowFallBackTool      ()              if (gInGameStarted) then ShowFallBackTool() end end
function MacroCmd_ShowDevTool           ()              if (gInGameStarted) then ShowDevTool() end end 
function MacroCmd_ZoomCompass           (zoomfactor)    if (gInGameStarted) then ZoomCompass(zoomfactor) end end
function MacroCmd_ActivateNextRenderer  ()              if (gInGameStarted) then ActivateNextRenderer() end end
function MacroCmd_CamChangeZoom         (zoomadd)       if (gInGameStarted) then gCurrentRenderer:CamChangeZoom(zoomadd) end end
function MacroCmd_Screenshot            ()              Client_TakeScreenshot(gScreenshotDir) end
function MacroCmd_GridScreenshot        ()          
    if (not gInGameStarted) then return end
    ToggleCompass()
    Client_TakeGridScreenshot(gScreenshotDir)
    ToggleCompass()
end

function MacroCmd_ReloadMap     ()          
    if (not gInGameStarted) then return end
    local mapindex = gMapIndex
    UnloadOldMap(true) -- do not clear objects
    LoadMap(gMapIndex)
end

function MacroCmd_Dress (dresslist)
    for k,serial in pairs(dresslist) do 
        if (MacroCmd_EquipItem(serial)) then return true end 
	end
end

function MacroCmd_EquipItem (serial,bOkIfNotInBackPack)
    if (type(serial) == "table") then 
        local cmd,param = unpack(serial)
        if (cmd == "use") then Send_DoubleClick(param) end 
        return
    end
    local item = GetDynamic(serial)
    if (not item) then item = MacroCmd_Item_FindFirstByArtID(serial) end
    if (not item) then return end
    if (item.iContainerSerial == GetPlayerSerial()) then return end -- already equipped
    if (item.iContainerSerial ~= GetPlayerBackPackSerial() and (not bOkIfNotInBackPack)) then return end -- not in backpack, other char?
    local layer = GetPaperdollLayerFromTileType(item.artid)
	if (not layer) then return end -- unknown layer
	if (MacroCmd_GetPlayerEquipment(layer)) then return end -- something else already equipped there
    print("MacroCmd_EquipItem",serial,item.amount,layer)
    Send_Take_Object(item.serial,item.amount)
    Send_Equip_Item_Request(item.serial,layer,GetPlayerSerial())
    return true
end

    

function MacroCmd_RiseText (r,g,b,text,serial)
	text = tostring(text)
	print("MacroCmd_RiseText",text)
    serial = serial or GetPlayerSerial()
    if (SpellBarRiseTextOnMob) then SpellBarRiseTextOnMob(serial,r,g,b,text) end
	GuiAddChatLine(text,{r,g,b,1},"normal","script")
end

function MacroCmd_Item_Use  (item) if (item) then Send_DoubleClick(item.serial) return item end end

function MacroCmd_Item_UseByName    (itemnamepart)  return MacroCmd_Item_Use(MacroCmd_Item_FindFirstByName(itemnamepart)) end
function MacroCmd_Item_UseByArtID   (artid,hue)     return MacroCmd_Item_Use(MacroCmd_Item_FindFirstByArtID(artid,hue)) end

function MacroCmd_Item_FindFirstByName  (itemnamepart,container) local list = MacroCmd_Item_FindByName(itemnamepart,container) return list[1] end
function MacroCmd_Item_FindFirstByArtID (artid,hue,container) local list = MacroCmd_Item_FindByArtID(artid,hue,container) return list[1] end
function MacroCmd_Item_FindFirstNearByArtID (artid,hue,dist) local list = MacroCmd_Item_FindNearByArtID(artid,hue,dist) return list[1] end

function MacroCmd_GetPlayerEquipment (layer) 
    local playermobile = GetPlayerMobile()
    return playermobile and GetMobileEquipmentItem(playermobile,layer)
end
function MacroCmd_GetItemInHand () return MacroCmd_GetPlayerEquipment(kLayer_OneHanded) end
function MacroCmd_IsMounted () return MacroCmd_GetPlayerEquipment(kLayer_Mount) ~= nil end
function MacroCmd_MountNearby ()
	if (MacroCmd_IsMounted()) then return end
	if (IsWarModeActive()) then MacroCmd_ToggleWarmode() return end
	local mount = GetRandomArrayElement(MobileList_GetByFilter(function (mobile) return GetUODistToPlayer(mobile.xloc,mobile.yloc) <= 2 and (not MobileIsHuman(mobile)) end))
	if (mount) then Send_DoubleClick(mount.serial) end
end
function MacroCmd_Dismount ()
    if (MacroCmd_IsMounted()) then Send_DoubleClick(GetPlayerSerial()) return true end -- todo : check if mounted
end

function MacroCmd_DragAndEquip (takeserial,mobileserial)
    local item = GetDynamic(takeserial)
    local layer = item and GetPaperdollLayerFromTileType(item.artid)
    if (not layer) then print("MacroCmd_DragEquip not wearable or item not found, artid=",item.artid) return end
    Send_Take_Object(takeserial,1)
    Send_Equip_Item_Request(takeserial,layer,mobileserial or GetPlayerSerial())
end 
function MacroCmd_DragDrop (takeserial,amount,dropcontainerserial) 
    Send_Take_Object(takeserial,amount)
    Send_Drop_Object_AutoStack(takeserial,dropcontainerserial or GetPlayerBackPackSerial())
end

function MacroCmd_DragDropToGround (takeserial,amount,xloc,yloc,zloc) 
	if (not takeserial) then print("MacroCmd_DragDropToGround:no takeserial") return end
	local o = GetDynamic(takeserial)
	amount = amount or (o and o.amount)
	if (not amount) then print("MacroCmd_DragDropToGround:no amount") return end
    xloc = xloc or gPlayerXLoc
    yloc = yloc or gPlayerYLoc
    zloc = zloc or gPlayerZLoc
	job.create(function ()
		Send_Take_Object(takeserial,amount)
		job.wait(math.random(200,300))
		Send_Drop_Object(takeserial,xloc,yloc,zloc,0xFFFFFFFF)
	end)
end


function MacroCmd_TogglePacketVideoRecording() PacketVideo_Recording_Toggle() MacroCmd_RiseText(1,0,0,"packetvideo:rec:"..(gPacketVideoRecording and "start" or "stop")) end

function MacroCmd_CycleMaxFPS()
	local fps = {5,10,15,20,40}
	local found
	for k,v in pairs(fps) do if (gMaxFPS == v) then gMaxFPS = fps[k+1] found = true break end end 
	if ((not gMaxFPS) or (not found)) then gMaxFPS = fps[1] end
	MacroCmd_RiseText(1,0,0,"maxfps:"..gMaxFPS) 
end

function MacroCmd_GetOpenBankBoxSerial ()  -- search for bankbox in currently open containers
	for k,dynamic in pairs(GetDynamicList()) do 
		if (dynamic.artid == 0xe7c and dynamic.hue == 0 and (not DynamicIsInWorld(dynamic))) then 
			print("bankbox: open",IsContainerAlreadyOpen(dynamic)) -- always false in norender, HandleOpenContainer: no gumploader
			return dynamic.serial
		end 
	end
end

function MacroCmd_LootItem (item,containerserial,amount) 
	if (not item) then return end
	job.create(function () 
		Send_Take_Object(item.serial,min(item.amount,amount or item.amount))
		job.wait(math.random(200,300))
		Send_Drop_Object_AutoStack(item.serial,containerserial or GetPlayerBackPackSerial())
		end)
end

function MacroCmd_ToggleTextEntryRepeatLastChat() gMacroCmd_OnTextEntryRepeat = not gMacroCmd_OnTextEntryRepeat MacroCmd_RiseText(1,1,0,"entry:repeat:"..(gMacroCmd_OnTextEntryRepeat and "on" or "off")) end
RegisterListenerOnce("Hook_Unicode_Text_Entry",function () if (gMacroCmd_OnTextEntryRepeat) then MacroCmd_RiseText(1,1,0,"entry:repeat") MacroCmd_RepeatLastChat() end end,"MacroCmd_Hook_Unicode_Text_Entry")

function MacroCmd_TargetWeaponInHand () -- useful for poisoning
	local weapon = MacroCmd_GetPlayerEquipment(kLayer_OneHanded) or MacroCmd_GetPlayerEquipment(kLayer_TwoHanded) 
	if (weapon) then MacroCmd_QueueTargetSerial(weapon.serial,1000) end
end 

function MacroCmd_Scavenge (artlist,dist) MacroCmd_LootItem(GetRandomArrayElement(MacroCmd_Item_FindNearByArtList(artlist,dist,true))) end -- try to pickup nearby items

function MacroCmd_CutNearbyCorpse ()
	local corpse = GetRandomArrayElement(MacroCmd_Item_FindNearCorpses(2))
	local blade = MacroCmd_Item_FindFirstByArtID({0x0f52,0x13f6,0xec4,0x13b6,0xf51}) -- 0x0f52=knife 0x13f6=gargyknife 0xec4:skinningknife
	if (corpse and blade) then Send_DoubleClick(blade.serial) MacroCmd_QueueTargetSerial(corpse.serial,1000) end
end

function MacroCmd_SimpleLootStep ()
	local corpses = MacroCmd_Item_FindNearCorpses(2)
	local items = {}
	
	for k,corpse in pairs(corpses) do 
		if (IsContainerAlreadyOpen(corpse)) then 
			for k2,item in pairs(corpse:GetContent()) do table.insert(items,item) end
		end 
	end
	local backpack	= GetPlayerBackPackSerial()
	local bankbox	= MacroCmd_GetOpenBankBoxSerial()
	for serial,container in pairs(gObjectList) do
		if (IsContainerAlreadyOpen(container) and serial ~= backpack and serial ~= bankbox) then 
			for k2,item in pairs(container:GetContent()) do table.insert(items,item) end
		end 
	end
	
	local item = GetRandomArrayElement(items)
	if (item) then MacroCmd_LootItem(item) return end
	local unopened_corpses = {}
	for k,corpse in pairs(corpses) do 
		if (not IsContainerAlreadyOpen(corpse)) then 
			table.insert(unopened_corpses,corpse)
		end 
	end
	local openme = GetRandomArrayElement(unopened_corpses)
	if (openme) then Send_DoubleClick(openme.serial) return end
end


-- 0x0c9e : ohii tree not hackable
function MacroCmd_IsHackableTrees (artid) return 0x0c9e ~= artid and StringContains(string.lower(GetStaticTileTypeName(artid)),"tree") end
function MacroCmd_FindNearbyTrees (r) return MacroCmd_FindNearbyStatics(r,"tree",{0x0c9e}) end -- ohii tree not hackable
function MacroCmd_FindNearbyStatics (r,namepart,skipartidlist)
    local res = {}
    r = r or 2
    for ax = -r,r do
    for ay = -r,r do
        for k,item in pairs(MapGetStatics(gPlayerXLoc+ax,gPlayerYLoc+ay)) do
            --~ print("MacroCmd_FindNearbyStatics",GetStaticTileTypeName(item.artid))
            if (StringContains(string.lower(GetStaticTileTypeName(item.artid)),namepart) and
                ((not skipartidlist) or (not in_array(item.artid,skipartidlist)))) then 
                table.insert(res,item) 
            end
        end 
    end
    end
    return res
end

-- doesn't sum stack-amount
function MacroCmd_Item_CountByArtID (artid,hue,container) local list = MacroCmd_Item_FindByArtID(artid,hue,container) return list and #list or 0 end
function MacroCmd_Item_SumByArtID   (artid,hue,container) -- does sum stack
    local list = MacroCmd_Item_FindByArtID(artid,hue,container) 
    if (not list) then return 0 end
    local c = 0
    for k,item in pairs(list) do c = c + item.amount end
    return c
end

-- container defaults to player-backpack
function MacroCmd_Item_FindByName   (itemnamepart,container)
    container = container or GetPlayerBackPackContainer()
    if (not container) then return end
    local res = {}
    for k,item in pairs(container:GetContent()) do 
        local name = GetItemTooltipOrLabel(item.serial) or GetStaticTileTypeName(item.artid)
        if (name and string.find(name,itemnamepart)) then
            table.insert(res,item)
        end
    end
    return res
end

function MacroCmd_HideAllCorpses    ()
    for k,item in pairs(GetDynamicList()) do 
        if (item.artid_base == kCorpseDynamicArtID and (not Renderer2D:MobileHasVisibleEquip(item.amount))) then item:Destroy() end
    end
end         
        
function MacroCmd_AutoClickItems    ()
    for k,item in pairs(GetDynamicList()) do 
        if (DynamicIsInWorld(item) and (not gItemAutoClickSent[item.serial])) then
            gItemAutoClickSent[item.serial] = true
            if ((not GetItemTooltipOrLabel(item.serial)) and (gDynamicAutoClickByArtID[item.artid] or gContainerArtIDs[item.artid])) then
                Send_SingleClick(item.serial,true)
            end
        end
    end
end

function MacroCmd_Item_FindNearByArtList    (artlist,dist,bSkipCorpses)
    local res = {}
    for k,item in pairs(GetDynamicList()) do 
        if (DynamicIsInWorld(item) and 
			((not bSkipCorpses) or (not IsCorpseArtID(item.artid))) and
            (dist == nil or item:GetUODistToPlayer() <= (dist or 2)) and ((not artlist) or in_array(item.artid,artlist))) then
            table.insert(res,item)
        end
    end
    return res
end

function MacroCmd_Item_FindNearByArtID  (artid,hue,dist) -- equals easyuo type
    local res = {}
    local artidlist = (type(artid) == "number") and {artid} or artid
    for k,item in pairs(GetDynamicList()) do 
        if (in_array(item.artid,artidlist) and (hue == nil or hue == item.hue) and DynamicIsInWorld(item) and 
            (dist == nil or item:GetUODistToPlayer() <= dist) ) then
            table.insert(res,item)
        end
    end
    return res
end 

function MacroCmd_Item_FindNearCorpses  (dist,corpsetype)
    local res = {}
    for k,item in pairs(GetDynamicList()) do 
        if (DynamicIsInWorld(item) and IsCorpseArtID(item.artid) and ((not corpsetype) or (item.amount == corpsetype)) and
            (dist == nil or item:GetUODistToPlayer() <= dist) ) then
            table.insert(res,item)
        end
    end
    return res
end 

function MacroCmd_IsItemInContainer (serial,container)
    if (type(container) == "number") then container = GetContainer(container) end -- resolve serial
    container = container or GetPlayerBackPackContainer()
    return container and serial and container.content[serial]
end

-- container defaults to player-backpack
-- hue can be nil for any
function MacroCmd_Item_FindByArtID  (artid,hue,container) -- equals easyuo type
    if (type(container) == "number") then container = GetContainer(container) end -- resolve serial
    container = container or GetPlayerBackPackContainer()
    if (not container) then return end
    local res = {}
    local artidlist = (type(artid) == "number") and {artid} or artid
    for k,item in pairs(container:GetContent()) do 
        if (in_array(item.artid,artidlist) and (hue == nil or hue == item.hue)) then
            table.insert(res,item)
        end
    end
    return res
end

function MacroCmd_FindNearestMobByName (namepart)
    local founddist,foundmob
    local xloc,yloc = GetPlayerPos()
    for k,mobile in pairs(GetMobileList()) do 
        local dist = dist2(xloc,yloc,mobile.xloc,mobile.yloc)
        if (((not founddist) or dist < founddist) and (not IsPlayerMobile(mobile))) then 
            if ((not namepart) or StringContains(AosToolTip_GetText(mobile.serial) or mobile.name or "",namepart)) then
                founddist = dist
                foundmob = mobile
            end
        end
    end
    return foundmob
end

function MacroCmd_FindNearestMobByArtID (artid)
    local founddist,foundmob
    local xloc,yloc = GetPlayerPos()
    for k,mobile in pairs(GetMobileList()) do 
        local dist = dist2(xloc,yloc,mobile.xloc,mobile.yloc)
        if (((not founddist) or dist < founddist) and (not IsPlayerMobile(mobile))) then 
            if ((not artid) or mobile.artid == artid) then
                founddist = dist
                foundmob = mobile
            end
        end
    end
    return foundmob
end

function MacroCmd_GetNearestMobFromList (list)
    local founddist,foundmob
    local xloc,yloc = GetPlayerPos()
    for k,mobile in pairs(list) do 
        local dist = dist2(xloc,yloc,mobile.xloc,mobile.yloc)
        if ((not founddist) or dist < founddist) then 
            founddist = dist
            foundmob = mobile
        end
    end
    return foundmob
end

function MacroCmd_ListNonFriendlyPlayers () return MacroCmd_ListNonFriendlyMobiles(true) end 
function MacroCmd_ListNonFriendlyMobiles (bPlayersOnly)
    local res = {}
    for k,mobile in pairs(GetMobileList()) do 
        if (((not bPlayersOnly) or MobileIsHuman(mobile)) and 
            (not IsMobileInParty(mobile.serial)) and
            (not IsPlayerMobile(mobile))) then 
            
            local labelhue = GetItemLabelHue(mobile.serial)
            if (labelhue ~= kPlayerVendorLabelHue) then res[mobile.serial] = mobile end 
        end
    end
	print("MacroCmd_ListNonFriendlyMobiles res",bPlayersOnly,#res)
    return res
end

function MacroCmd_FindNearestNonFriendlyPlayer () return MacroCmd_GetNearestMobFromList(MacroCmd_ListNonFriendlyPlayers()) end

function MacroCmd_ListMobilesInRange (filterfun,maxdist)
    local res = {}
    for k,mobile in pairs(GetMobileList()) do 
        if (GetUODistToPlayer(mobile.xloc,mobile.yloc) <= maxdist and filterfun(mobile)) then table.insert(res,mobile) end 
    end 
    return res
end

function MacroCmd_ListMobiles (filterfun)
    local res = {}
    for k,mobile in pairs(GetMobileList()) do if (filterfun(mobile)) then table.insert(res,mobile) end end 
    return res
end

function MacroCmd_FindNearestMob () return MacroCmd_FindNearestMobByName() end

-- set itemserial = 0 to clear
-- itemserial defaults to the serial of the item currently under the mouse
function MacroCmd_ItemSlot_Set  (slotnumber,itemserial)     
    if (not gInGameStarted) then return end
    if (not itemserial) then itemserial = GetMouseHitSerial() end -- itemserial_under_mouse
    if (itemserial == 0) then itemserial = nil end -- set 0 to clear
    print("MacroCmd_ItemSlot_Set",slotnumber,itemserial)
    local item = itemserial and GetObjectBySerial(itemserial)
    local itemname = item and GetStaticTileTypeName(item.artid) or "empty"
    GuiAddChatLine("ItemSlot "..tostring(slotnumber).." set to "..tostring(itemname))
    gMacroItemSlots[slotnumber] = itemserial
end

function MacroCmd_ItemSlot_Use  (slotnumber)
    local itemserial = gMacroItemSlots[slotnumber]
    if (not itemserial) then return MacroError("MacroCmd_ItemSlot_Use : no item in slot "..tostring(slotnumber)) end
    print("MacroCmd_ItemSlot_Use",slotnumber,itemserial)
    Send_DoubleClick(itemserial)
end

function MacroCmd_Skill                 (skillname)
    if (not gInGameStarted) then return end
    local skillid = gCharCreateSkillIDs[skillname] -- zero based
    if (not skillid) then return MacroErrorNameMismatch("MacroCmd_Skill",skillname,gCharCreateSkillIDs) end
    skillid = skillid + 1 -- one based needed below
    if (glSkillActive[skillid] ~= 1) then return MacroError("MacroCmd_Skill : skill is passive : "..tostring(skillname)) end
    Send_Request_SkillUse(skillid)
end

function MacroCmd_RepeatLastSkill ()
	if (gLastUsedSkillID) then Send_Request_SkillUse(gLastUsedSkillID) end
end
function MacroCmd_RepeatLastSpell ()
    if (gLastSpellID) then Send_Spell(gLastSpellID) end
end
function MacroCmd_Spell                 (spellname,targetserial,targetcallback,targetwaitadd)
    if (not gInGameStarted) then return end
    local spellid = (type(spellname) == "number") and spellname or GetSpellIDByName(spellname)
    if (not spellid) then return MacroErrorNameMismatch("MacroCmd_Spell",spellname,gSpellIDByName) end
    Send_Spell(spellid)
    
    if (targetserial) then 
        local timeout = GetSpellCastTimeForPlayer(spellid) + kSpellTimeLatency + (targetwaitadd or 1000)
        MacroCmd_QueueTargetSerial(targetserial,timeout,targetcallback,true) 
    end
end


-- searches the journal for text
-- if timestamp is not nil, only entries since timestamp are searched
-- if the text is found it returns the complete line otherwise nil
function MacroJournal_FindLineContainingSince   (text, timestamp)
    for k,v in pairs(gJournalExtendedEntries) do
        if timestamp == nil or v.time >= timestamp then
            if string.find(v.line, text) then
                return v.line
            end
        end
    end
    
    return nil
end

-- call from a job! (see job.create)
-- returns key(from textlist),plaintext,textdata      or nil if timeout
function MacroCmd_WaitForText (textlist,timeout_delay) 
	return MacroCmd_WaitForListener("Hook_Text",function (name,plaintext,serial,data)  
			for k,text in pairs(textlist) do if (string.find(plaintext,text)) then return k,plaintext,data end end 
		end,timeout_delay or 9000) 
end


function MacroCmd_JobWaitAndPickObject (index,timeout_delay) 
	assert(index) 
	return MacroCmd_WaitForListener("Hook_ObjectPicker",function (data) data.SendPickedObject(index) return true end,timeout_delay or 500) 
end

function MacroCmd_JobWaitAndStringQueryResponse (response,timeout_delay)
	assert(response) 
	return MacroCmd_WaitForListener("Hook_StringQuery",function (data) data.SendText(response) return true end,timeout_delay or 500)
end

function MacroCmd_QueuePickObject			(index,timeout_delay)		job.create(function () MacroCmd_JobWaitAndPickObject(index,timeout_delay) end) end
function MacroCmd_QueueStringQueryResponse	(response,timeout_delay)	job.create(function () MacroCmd_JobWaitAndStringQueryResponse(response,timeout_delay) end) end

function MacroCmd_RegisterTimeoutListener (listenername,fun,timeout_delay)
	timeout_delay = timeout_delay or 1000
	local timeout = gMyTicks+timeout_delay
	RegisterListener(listenername,function (...) 
		if (gMyTicks > timeout) then return true end
		return fun(...)
		end)
end

-- call from a job! (see job.create)
-- pauses the current job until a listener with listenername is notified and fun returns true for the listener, or until a timeout
-- returns the complete resultset from fun, or nil if timeout
function MacroCmd_WaitForListener (listenername,fun,timeout_delay)
	timeout_delay = timeout_delay or 9000
	local timeout = gMyTicks+timeout_delay
	local jobid = job.running_id() assert(jobid)
	local done = false
	local res
	RegisterListener(listenername,function (...) 
		if (done or gMyTicks > timeout) then return true end
		res = {fun(...)}
		if (res[1]) then done = true job.wakeup(jobid) return true end
		end)
	job.wait(timeout_delay)
	done = true
	if (res) then return unpack(res) end
end


-- waits until a given text appears, list = {text=returnvalue, text=returnvalue, ...} .... see also MacroCmd_WaitForText (might be better/faster)
function MacroJournal_WaitForText   (list,timeout)
    if not list then return end
    
    local lastcheck = Client_GetTicks()
    local endtime = timeout and lastcheck+timeout or nil
    
    while true do
        for k,v in pairs(list) do
            if MacroJournal_FindLineContainingSince(k, lastcheck) then
                return v
            end
        end
        lastcheck = Client_GetTicks()
        
        -- timeout check
        if endtime and lastcheck > endtime then
            print("TIMEOUT")
            return nil
        end

        job.wait(100)
    end
end

function MacroRead_GetPlayerPosition    ()
    local sx,sy,sz
    local mobile = GetPlayerMobile()
    if mobile then
        sx,sy,sz = mobile.xloc,mobile.yloc,mobile.zloc * 0.1
    else
        sx,sy,sz = gCurrentRenderer:GetExactLocalPos()
    end 
    return sx,sy,sz
end


function MacroReadAux_MobileStat            (mobile,statname,errormsg_funname)
    if (not gInGameStarted) then return 0 end
    if (not gMacroReadMobileStats[statname]) then 
        return MacroErrorNameMismatch("MacroRead_PlayerStat",statname,gMacroReadMobileStats) 
    end
    local mobile = GetPlayerMobile()
    return mobile and mobile.stats and mobile.stats[statname] or 0
end

function MacroErrorNameMismatch (cmd,name,list_by_key) 
    local infotext = cmd.." : unknown name "..tostring(name).." available names:\n"
    for k,v in pairs(list_by_key) do infotext = infotext..k.."\n" end
    MacroError(infotext)
end

function MacroError (infotext) 
    print(infotext)
    PlainMessageBox(infotext,gGuiDefaultStyleSet,gGuiDefaultStyleSet)
end

function GetMacroKeyComboName (keycode,char,bCtrl,bAlt,bShift) 
    local text = (keycode > 0) and GetKeyName(keycode) or ("0"..char)
    if (bCtrl   ) then text = "ctrl+"..text end
    if (bAlt    ) then text = "alt+"..text end
    if (bShift  ) then text = "shift+"..text end
    return text
end

function ClearAllMacros () gMacroList = {} end

function SetMacro (keycomboname,fun) gMacroList[string.gsub(string.lower(keycomboname)," ","")] = fun end

function TriggerMacros (keycode,char) 
    local bCtrl     = gKeyPressed[key_lcontrol] or gKeyPressed[key_rcontrol]
    local bAlt      = gKeyPressed[key_lalt]     or gKeyPressed[key_ralt]    
    local bShift    = gKeyPressed[key_lshift]   or gKeyPressed[key_rshift]
    local name = GetMacroKeyComboName(keycode,char,bCtrl,bAlt,bShift)
	if (TriggerConfigHotkey(keycode,char,bCtrl,bAlt,bShift)) then return end
    local macrofun = gMacroList[name]
    if (gMacroPrintAllKeyCombos) then print('to use this macro keycombo : SetMacro("'..name..'",function() MacroCmd_Say("test") end)') end
    if (not macrofun) then return end -- no macro mapped to this keycode
    
    -- protected macro call
    local success,errormsg_or_result = lugrepcall(function () job.create(macrofun) end)
    if (not success) then
        local myErrorText = "ERROR executing MACRO for keycombo "..name.." :\n"..tostring(errormsg_or_result)
        print(myErrorText)
        PlainMessageBox(myErrorText,gGuiDefaultStyleSet,gGuiDefaultStyleSet)
    end
end

RegisterListener("keydown",function (keycode,char,bConsumed) 
    if (not bConsumed) then TriggerMacros(keycode,char) end
end)

--[[
gMacroActionDescriptions = {}
gMacroActionDescriptions.Say                        = "Open a text window where you can enter a line of dialog that your character will speak when the Macro is used."
gMacroActionDescriptions.Emote                      = "As Say, but may be a different text color than normal speech (see \"Change Emote Color\" above). Also, any Emote text will be placed between two asterisks, for example *grin* or *Broods darkly*. The traditional function of emote text is to convey actions, attitudes, or emotions rather than simple speech."
gMacroActionDescriptions.Whisper                    = "As Say, but whispered text (e.g., \"Psst, wanna buy a chicken?\") can only be \"heard\" by characters immediately adjacent to you."
gMacroActionDescriptions.Yell                       = "As Say, but yelled text (e.g., \"HELP!\") can be \"heard\" by any character up to a screen and a half away."
gMacroActionDescriptions.Walk                       = "Opens a menu of compass directions from which you choose one. Using this menu causes your character to face and take a step in the selected direction."
gMacroActionDescriptions.War_Peace                  = "Toggles you between War mode and Peace mode."
gMacroActionDescriptions.Paste                      = "Pastes text from your Windows clipboard into a book or speech. Text length is limited. Speech can be only a few words, while books can receive a few sentences."
gMacroActionDescriptions.Open                       = "Opens one of your informational windows. Selecting this option will present you with a list of windows from which to select. Your Character Window is listed as \"Paperdoll\" and your Options screen as \"Configuration\"."
gMacroActionDescriptions.Close                      = "Closes the window you specify."
gMacroActionDescriptions.Minimize                   = "Minimizes all open windows."
gMacroActionDescriptions.Maximize                   = "Fully opens all minimized windows on screen."
gMacroActionDescriptions.Open_Door                  = "Opens any door within reach."
gMacroActionDescriptions.Use_Skill                  = "Presents you with a list of all applicable skills, from which to select the specific skill you want to try to Use when you trigger this Macro. This command can only be used to initiate those skills which are normally begun from the skill list in your Character Window. It does not apply to skills initiated by using a specific item or taking a certain action."
gMacroActionDescriptions.Last_Skill                 = "Attempts to again Use the last skill you Used."
gMacroActionDescriptions.Cast_Spell                 = "Presents you with a list of all the spells in the game, from which you must select the specific spell you want to cast. It's up to you to ensure the spell you select is, in fact, one that you actually know how to cast."
gMacroActionDescriptions.Last_Spell                 = "Attempts to recast the last spell you cast."
gMacroActionDescriptions.Last_Object                = "Attempt to again use the last item you Used."
gMacroActionDescriptions.Bow                        = "Your character will bow from the waist."
gMacroActionDescriptions.Salute                     = "Your character will perform a military salute."
gMacroActionDescriptions.Quit_Game                  = "Disconnects you and closes the game."
gMacroActionDescriptions.Allnames                   = "Displays the names of every creature and character currently on screen."
gMacroActionDescriptions.LastTarget                 = "Automatically target the last object, creature, or player that you clicked on with the targeting cursor."
gMacroActionDescriptions.TargetSelf                 = "Targets you. Used in conjunction with other macros."
gMacroActionDescriptions.Arm_Disarm                 = "Arms or Disarms your current or chosen weapon. You must specify an arm (right or left)."
gMacroActionDescriptions.Wait_for_Target            = "Waits for the target cursor to become available."
gMacroActionDescriptions.Target_Next                = "Moves your target cursor to the next available target."
gMacroActionDescriptions.Attack_Last                = "Attacks the creature or player your last targeted."
gMacroActionDescriptions.Delay                      = "Allows you to set a \"wait\" delay with a complex macro."
gMacroActionDescriptions.CircleTrans                = "Allows you to toggle Circle Transparency with a macro."
gMacroActionDescriptions.CloseGumps                 = "Closes all open pop-up messages."
gMacroActionDescriptions.AlwaysRun                  = "Toggles the Always Run setting, which makes you always run whenever you move."
gMacroActionDescriptions.SaveDesktop                = ""
gMacroActionDescriptions.KillGumpOpen               = ""
gMacroActionDescriptions.PrimaryAbility             = "Activates your weapon's primary special ability."
gMacroActionDescriptions.SecondaryAbility           = "Activates your weapon's secondary special ability."
gMacroActionDescriptions.EquipLastWeapon            = "Allows you to quickly switch between two weapons. Click here for more information."
gMacroActionDescriptions.SetUpdateRange             = ""
gMacroActionDescriptions.ModifyUpdateRange          = ""
gMacroActionDescriptions.IncreaseUpdateRange        = ""
gMacroActionDescriptions.DecreaseUpdateRange        = ""
gMacroActionDescriptions.MaxUpdateRange             = ""
gMacroActionDescriptions.MinUpdateRange             = ""
gMacroActionDescriptions.DefaultUpdateRange         = ""
gMacroActionDescriptions.UpdateRangeInfo            = ""
gMacroActionDescriptions.EnableRangeColor           = ""
gMacroActionDescriptions.DisableRangeColor          = ""
gMacroActionDescriptions.ToggleRangeColor           = ""
gMacroActionDescriptions.InvokeVirtue               = "Allows you to specify a virtue to be activated."
]]--


-- obsolete...
gMacroListDialog = nil
function ToggleMacroList () end
function ToggleMacroList_OLD () 
    if (gMacroListDialog) then CloseMacroListDialog() return end
    
    local rows = {
        {   {"MacroList"} },
        {   {type="EditText",controlname="note",w=400,h=24} },
        {   {"Apply",function () 
            local mytext = gMacroListDialog.controls["note"]:GetText() or ""
            -- todo....
            end},
            {"Close",function () CloseMacroListDialog() end},
        },
    }
    gMacroListDialog = guimaker.MakeTableDlg(rows,100,100,false,true)
end

-- obsolete...
function CloseMacroListDialog_OLD () 
    if (gMacroListDialog) then gMacroListDialog:Destroy() gMacroListDialog = nil end
end

function MacroCmd_WalkInDir     (iDir,bRunFlag,bTrySides) WalkStep_WalkInDir(iDir,bRunFlag,bTrySides) end

-- run from a job (uses wait) !!!! 
-- timeout : stop walking if the target wasn't reached after this time.  0 to walk until target is reached

gMacroCmdMarkerList = {}
function MacroCmd_ClearMarkers	() 
	for marker,v in pairs(gMacroCmdMarkerList) do 
		marker:Destroy()
	end 
	gMacroCmdMarkerList = {}
end
function MacroCmd_Marker		(xloc,yloc,zloc) 
	if (gCurrentRenderer == Renderer2D) then
		zloc = zloc or gPlayerZLoc
		local spriteblock = cUOSpriteBlock:New()
		local artid = 0xf0e
		local bx = floor(xloc/8)
		local by = floor(yloc/8)
		local sorttx = xloc - floor(xloc/8)
		local sortty = yloc - floor(yloc/8)
		local sorttz = zloc
		local fIndexRel = 1
		spriteblock:AddArtSprite(xloc-bx*8,yloc-by*8,zloc,artid,nil,CalcSortBonus(artid,sorttx,sortty,sorttz,fIndexRel,1))
		spriteblock:Build(Renderer2D.kSpriteBaseMaterial)
		spriteblock:SetPosition(gCurrentRenderer:UOPosToLocal2(bx*8,by*8,0))
		gMacroCmdMarkerList[spriteblock] = true
		return spriteblock
	end
end

-- bMarkOnly : for debugging, creates markers on route
function MacroCmd_PathFindTo	(xloc,yloc,tolerance,timeout,bNoLog,bAutoOpenDoors,bShowMarkers,step_callback)
	tolerance = tolerance or 0
	local bLog = not bNoLog
	if (bLog) then print("MacroCmd_PathFindTo : start",xloc,yloc,tolerance,timeout) end
	local iJobWaitInterval = 50
	timeout = timeout or 0
	local endt = (timeout > 0) and (Client_GetTicks() + timeout)
	function pos2str (xloc,yloc,zloc) return table.concat({xloc,yloc,zloc},",") end
	repeat -- repeat the pathfinding calc every few seconds in case dynamics show up
		if (GetUODistToPlayer(xloc,yloc) <= tolerance) then 
			if (bLog) then print("MacroCmd_PathFindTo : success, arrived") end
			return true 
		end
		local t = Client_GetTicks()
		local res = cPathFind2:CalcRouteFromPlayerToPos(xloc,yloc,tolerance,iJobWaitInterval,endt and (endt-t),bAutoOpenDoors) 
		local t2 = Client_GetTicks()
		local nextstept = t2 + 1000
		local dt = t2-t
		if (bLog) then print("MacroCmd_PathFindTo: calc took ",dt,"ms",res and ("numsteps:"..#res) or "failed","curpos:"..pos2str(GetPlayerPos()),"nextpos:"..pos2str(unpack(res and res[1] or {}))) end
		if ((not res) or #res == 0) then if (bLog) then print("MacroCmd_PathFindTo : failed, no path") end return end
		local bRunFlag = true
		local bTrySides = true
		if (bShowMarkers) then 
			MacroCmd_ClearMarkers()
			for k,pos in ipairs(res) do MacroCmd_Marker(unpack(pos)) end
		end
		for k,pos in ipairs(res) do 
			local wp_xloc,wp_yloc,wp_zloc = unpack(pos)
			repeat
				job.wait(max(10,Walk_GetTimeUntilNextStep()))
				WalkStep_WalkToPosSimple(wp_xloc,wp_yloc,bRunFlag,bTrySides,bAutoOpenDoors) 
				if (endt and gMyTicks > endt) then 
					if (bLog) then print("MacroCmd_PathFindTo : failed, timeout") end
					return
				end
				if (step_callback and step_callback()) then return end -- cancel if step_callback returns true 
				if (gMyTicks > nextstept) then break end
			until GetUODistToPlayer(wp_xloc,wp_yloc) <= 0 -- repeat (turn,walk) until this next tile reached
			if (gMyTicks > nextstept) then break end
		end
		--~ if (gMyTicks <= nextstept) then  
			--~ if (bLog) then print("MacroCmd_PathFindTo : success, finished") end
			--~ return true -- final destination reached
		--~ end
	until false
end

function MacroCmd_WalkToMouse   ()
    MainMousePick()
    local x,y,z = GetMouseHitTileCoords()
    SetAutoWalkTo(x,y)
end


gAttackRunning = false
function StopAttack ()
    gAttackRunning = false
end

gAttackMobile = nil
function AttackMobile   (mobileserial)
    gAttackMobile = mobileserial
    if gAttackRunning then return end
    gAttackRunning = true
    
    job.create(function()
        --~ print("START ATTACK")
        local reqsend = false
        while gAttackRunning and gAttackMobile do
            local mobile = gMobiles[gAttackMobile]
            if not mobile then 
                gAttackRunning = false
            else
                local tx,ty,tz = mobile.xloc,mobile.yloc,mobile.zloc
                local px,py,pz = GetPlayerTilePosition()
                local dx,dy,dz = Vector.sub(px,py,pz, tx,ty,tz)
                dx,dy,dz = Vector.normalise_to_len(dx,dy,dz, 1)
                gCurrentRenderer:SetViewDir(dx,dy)
                
                --[[
                autowalk is not good here, because of distance attacks
                dx,dy,dz = Vector.add(tx,ty,tz, dx,dy,dz)
                dx = round(dx)
                dy = round(dy)
                SetAutoWalkTo(dx,dy)
                ]]
                
                if (IsWarModeActive()) then
                    if not reqsend then
                        --~ print("REQUEST SEND")
                        Send_AttackReq(gAttackMobile)
                        reqsend = true
                    end
                else 
                    reqsend = false
                end
                
                job.wait(500)
            end
        end
        --~ print("STOP ATTACK")
    end)
end

function MacroGoto(x,y,slow)
    SetAutoWalkTo(x,y,slow)
    while gWalkPathToGo do
        job.wait(500)
    end
end

function MacroGetItemFromBackpackByName(itemnamepart)
    local backpack_container = GetPlayerBackPackContainer()
    if backpack_container then return MacroGetItemFromContainerByName(itemnamepart, backpack_container.serial) end
    return nil
end

function MacroGetItemFromContainerByArtidHue(artid, hue, container_serial)
    MacroEnsureContainerIsOpen(container_serial)
    
    local container = GetContainer(container_serial)
    if (not container) then return nil end
    for k,item in pairs(container:GetContent()) do 
        if item.artid == artid and (not hue or item.hue == hue) then
            return item
        end
    end

    return nil
end

function MacroGetItemFromContainerByName(itemnamepart, container_serial)
    MacroEnsureContainerIsOpen(container_serial)
    
    local container = GetContainer(container_serial)
    if (not container) then return nil end
    for k,item in pairs(container:GetContent()) do 
        local name = GetStaticTileTypeName(item.artid)
        if (name and string.find(name,itemnamepart)) then
            return item
        end
    end

    return nil
end

function MacroDropItemIntoContainer(dropitem, container_serial, x,y)
    x = x or 50
    y = y or 50

    MacroEnsureContainerIsOpen(container_serial)
    
    local amount = dropitem.amount or 1
    local target = container_serial
    
    local container = GetContainer(container_serial)
    if (not container) then return nil end
    for k,item in pairs(container:GetContent()) do 
        if item.serial ~= dropitem.serial and item.artid == dropitem.artid and (not dropitem.hue or item.hue == dropitem.hue) then
            target = item.serial
        end
    end

    Send_Take_Object(dropitem.serial,amount)
    job.wait(400)
    Send_Drop_Object(dropitem.serial,x,y,0,target)
    job.wait(400)
end

function MacroDropAllIntoContainer(itemnamepart, container_serial, x,y)
    MacroEnsureContainerIsOpen(container_serial)
    
    x = x or 50
    y = y or 50
    local item = MacroGetItemFromBackpackByName(itemnamepart)
    local lastserial = nil
    while item do
        MacroDropItemIntoContainer(item, container_serial, x,y)
        lastserial = item.serial
        item = MacroGetItemFromBackpackByName(itemnamepart)
        -- something went wrong so stop
        if item and lastserial and item.serial == lastserial then return end
    end
end

function MacroEnsureContainerIsOpen (container_serial)
    if not IsContainerAlreadyOpen(container_serial) then
        Send_DoubleClick(container_serial)
    end
    while not IsContainerAlreadyOpen(container_serial) do
        job.wait(100)
    end
end

function MacroStackEverytingInContainer (container_serial)
    MacroEnsureContainerIsOpen(container_serial)

    local sx = 20
    local sy = 20
    local dx = 2
    local dy = 2
    local x = sx
    local y = sy
    local limit = 150
    
    local rowh = 0
    
    local container = GetContainer(container_serial)
    if (not container) then return nil end

    
    local l = {}
    
    -- sort content by height
    for k,v in pairs(container:GetContent()) do table.insert(l,v) end
    table.sort(l, function(a,b)
        local minx,miny,maxx,maxy = GetArtVisibleAABB(a.artid + 0x4000)
        local ha = maxy-miny
        minx,miny,maxx,maxy = GetArtVisibleAABB(b.artid + 0x4000)
        local hb = maxy-miny
        return ha < hb
    end)
    
    for k,item in ipairs(l) do 
        -- print("DROP AT",x,y)
        
        local minx,miny,maxx,maxy = GetArtVisibleAABB(item.artid + 0x4000)
        -- print("AABB",minx,miny,maxx,maxy)
        --local w,h = GetArtSize(item.artid + 0x4000)
        local w,h = maxx-minx,maxy-miny
        
        rowh = math.max(h, rowh)
        
        -- print("w,h,rowh",w,h,rowh,x,y)
        
        MacroDropItemIntoContainer(item, container_serial, x-minx,y-miny)
        
        -- goto next position
        x = x + w + dx
        if x > limit then
            x = sx
            y = y + rowh + dy
        end
    end
end

function MacroGetSerialUnderMouse   ()
    return GetMouseHitSerial(true)
end


-- color is #000000 format, timeout in ms
function Macro_ShowTimeout (x,y,w,h,text,color,timeout)
    if timeout > 0 then
        local params = {
            gfxparam_bar = MakeSpritePanelParam_BorderPartMatrix(GetPlainTextureGUIMat("ray_border.png"),32,32, 0,0, 0,0, 1,30,1, 1,30,1, 32,32, 1,1, false, false),
            gfxparam_background = MakeSpritePanelParam_BorderPartMatrix(GetPlainTextureGUIMat("ray_border_black.png"),32,32, 0,0, 0,0, 1,30,1, 1,30,1, 32,32, 1,1, false, false),
        }
        
        local progress = GetDesktopWidget():CreateChild("Bar",params)
        progress:SetLeftTop(x,y)
        progress:SetSize(w,h)
        progress:SetProgress(0)
        progress:CreateContentChild("UOText",{text="<BASEFONT COLOR="..color..">"..text.."</BASEFONT>",x=5,y=-2,width=w,height=h,background=0,scrollbar=0,bold=false,crop=false,html=true})
        
        local startt = Client_GetTicks()
        
        job.create(function()
            local p = 0
            repeat
                p = Clamp((Client_GetTicks() - startt) / timeout, 0, 1)
                progress:SetProgress(p)
                job.wait(10)
            until p == 1
            progress:Destroy()
        end)
    end
end


-- disconnect from server + login with a different char/acc   (experimental, no error handling)
function MacroCmd_ReLogin (shardname,user,pass,charidx) -- charidx in 0-4
	print("MacroCmd_Relog",shardname,user,charidx)
	NetDisconnect()
    gHuffmanDecode = false
    gInGameStarted = false
	
	-- close healthbars
	for serial,dialog in pairs(gHealthbarDialogs) do dialog:Destroy() end gHealthbarDialogs = {}
	
	for k,dynamic in pairs(GetDynamicList()) do if (DynamicIsInWorld(dynamic)) then dynamic:Destroy() end end
	for k,mobile in pairs(GetMobileList()) do mobile:Destroy() end
	
	-- ClearDynamicsAndMobiles : not really needed since dynamics and mobiles are destroyed above
	if (gCurrentRenderer.ClearDynamicsAndMobiles) then
		gCurrentRenderer:ClearDynamicsAndMobiles()
	else
		gCurrentRenderer:DeInit()
	end
	
	local shard = gShardList[shardname]  assert(shard)
	gShardName = shardname
    LoadShardfilter(shard.gCustomArtFilterFile) -- todo : revert on error or back-button ?
	
    -- load global config from shard
    for k,v in pairs(shard) do _G[k] = v end
	
	gLoginname = user
	gPassword = pass -- MainMenu_GetStoredPassword(shard.gLoginServerIP,shard.gLoginServerPort,gLoginname)
	
    -- init net
    gNet_State = NetConnectWithKey(gLoginServerIP,gLoginServerPort,gServerSeed)
	assert(gNet_State)
    
	gAutoLoginCharID = nil
	gAutoLoginCharName = nil
	gAutoLoginCharID = charidx
    Send_Account_Login_Request(user,pass) -- 0x80 kPacket_Account_Login_Request
end

