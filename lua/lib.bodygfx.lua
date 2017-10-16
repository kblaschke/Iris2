--[[ ***** see Iris2 COPYING for license info ***** ]]--
--[[ \brief
        manages the group of multiple bodyparts, mounts, equipment in hands etc
        also used to manage animation, triggers idle anims automatically;
        in uo humanoid bodies often consist of multiple granny parts, a bodygfx is used to group them together
        interesting mobile artid : 400 401 (admin robe ? or base human ?)
        (see also lib.3d.mobile.lua, lib.3d.walksmooth.lua)
        (see config.lua.dist for kMountZAdd)
]]--

gBodyGfxPrototype = {}

-- ##### ##### ##### ##### ##### construction,destruction

function CreateBodyGfx (...)
    local res = {}
    ArrayOverwrite(res,gBodyGfxPrototype)
    res:Init(...)
    return res
end

function gBodyGfxPrototype:Init (parentgfx)
    self.modelgfx = parentgfx and parentgfx:CreateChild() or CreateRootGfx3D() -- main
    self.groupgfx = self.modelgfx:CreateChild() -- seperate for mount-z-mod , contains only bodyparts
	gBodyGfxMainStepList[self] = true
end

gBodyGfxMainStepList = {}
RegisterListener("Hook_PreRenderOneFrame",function() BodyGfxMainStep() end)
function BodyGfxMainStep ()
	for body,v in pairs(gBodyGfxMainStepList) do 
		body:Step()
		if (body.bDead) then gBodyGfxMainStepList[body] = nil end
	end
end

function gBodyGfxPrototype:Destroy ()
    self.bDead = true
    self:Clear()
    if (self.modelgfx) then self.modelgfx:Destroy() self.modelgfx = nil end
    if (self.groupgfx) then self.groupgfx:Destroy() self.groupgfx = nil end
end


-- ##### ##### ##### ##### ##### utils


-- destroys gfx of all parts and of mount
function gBodyGfxPrototype:Clear ()
    if (self.modelparts)    then for k,partgfx in pairs(self.modelparts) do partgfx:Destroy() end self.modelparts = nil end
    if (self.modelmountgfx) then self.modelmountgfx:Destroy() self.modelmountgfx = nil end
end

function gBodyGfxPrototype:GetPartGfxList   () return self.modelparts or {} end

function gBodyGfxPrototype:GetEquipmentAtLayer (layer)      
    for k,dynamic in pairs(self.equipmentlist or {}) do 
        if ((dynamic.layer or GetPaperdollLayerFromTileType(dynamic.artid)) == layer) then return dynamic end 
    end
end 

function gBodyGfxPrototype:SetVisible       (bVisible)
    for k,partgfx in pairs(self:GetPartGfxList()) do 
        if (partgfx and partgfx.SetVisible) then partgfx:SetVisible(bVisible) end
    end 
end

function gBodyGfxPrototype:GetBodyID () return self.bodyid or GrannyOverride(self.artid) end

function gBodyGfxPrototype:CalcBodyHash ()
    -- self.equipmentlist
    local hash = self:GetBodyID()..","..(self.hue or 0)
    for k,layer in pairs(gLayerType) do 
        local dynamic = self:GetEquipmentAtLayer(layer) 
        local parthash = dynamic and ((dynamic.artid or -1).."_"..(dynamic.hue or -1)) or 0
        hash = hash..","..parthash
    end
    return hash
end

function BodyGfxGetStateAnimID  (bodyid,bWalk,bRun,bIdle,bHasMount,bWarMode,bHasStaff,bIsCorpse)    
    if (not gGrannyLoaderType) then return 0 end
    local modelinfo = GetGrannyModelInfo(bodyid)
    local animtypeid = (modelinfo and modelinfo.typeid) or kAnimTypeID_Other
    if (animtypeid == kAnimTypeID_Monster) then -- monster
        if (bIsCorpse) then return 2    end -- 2:Die1,3:Die2
        if (bWalk) then return 0    end -- Walk
        if (bRun ) then return 1    end -- Walk/Run -- TODO : maybe fly here ? check zloc
        if (bIdle) then return 1    end -- Idle
    elseif (animtypeid == kAnimTypeID_Sea) then -- sea
        if (bIsCorpse) then return 8    end -- 8:Die1
        if (bWalk) then return 0    end -- Walk
        if (bRun ) then return 1    end -- Run 
        if (bIdle) then return 2    end -- Idle
    elseif (animtypeid == kAnimTypeID_Animal) then -- animal
        if (bIsCorpse) then return 8    end -- 8:Die1,12:Die2
        if (bWalk) then return 0    end -- Walk
        if (bRun ) then return 1    end -- Run 
        if (bIdle) then return 2    end -- Idle
    elseif (animtypeid == kAnimTypeID_Human) then -- human
        if (bIsCorpse) then return 21   end -- 21:Die_Hard_Fwd_01,22:Die_Hard_Back_01,129:die_slow_fire_01
        if (gDisableHumanClientSideAnim) then return 4 end -- force idle
        if (bHasMount) then 
            if (bWalk) then return 23   end -- Horse_Walk_01
            if (bRun ) then return 24   end -- Horse_Run_01
            if (bIdle) then return 25   end -- Horse_Idle_01
        else 
            if (bWarMode) then
                return bIdle and (bHasStaff and 7 or 8) or 15
                --7     -- CombatIdle1H_01
                --8     -- CombatIdle1H_01
                --15    -- CombatAdvance_1H_01
            else 
                if (bHasStaff) then
                        if (bWalk) then return 1    end -- WalkStaff_01
                        if (bRun ) then return 3    end -- RunStaff_01
                        if (bIdle) then return 5    end -- Idle_01
                else 
                        if (bWalk) then return 0    end -- Walk_01
                        if (bRun ) then return 2    end -- Run_01
                        if (bIdle) then return 4    end -- Idle_01
                end
            end
        end 
    end
    return 0 -- Idle_01
end


-- ##### ##### ##### ##### ##### update (model change)



function gBodyGfxPrototype:MarkForUpdate(artid,hue,equipmentlist)
    self.artid = artid
    self.hue = hue or 0
    self.equipmentlist = CopyArray(equipmentlist or {})
    self.bMarkedForUpdate = true -- summarize multiple updates during one frame
end

function gBodyGfxPrototype:Update()
    self.bMarkedForUpdate = false
    if (self.bDead) then return end
    
    -- calc hash to see if something changed, exit if not (nothing to do)
    local newbodyhash = self:CalcBodyHash()
    if (self.bodyhash == newbodyhash) then return end
    self.bodyhash = newbodyhash
    
    -- destroy old
    self:Clear()
    
    -- early out if no model visibile
    if (not gGrannyLoaderType) then return end
    if (not gAnimInfoLists) then return end
    if (self.artid == 0 and (not self.bodyid)) then return end
     
    -- create body parts
    local bodyid = self:GetBodyID()
    --~ print("gBodyGfxPrototype:Update bodyid=",bodyid)
    self.modelparts = {}
    
    local modelidarr,iPrimaryHandItem,iSecondaryHandItem = self:GetModelPartModelIDs()
	local t_start = Client_GetTicks()
    CreateBodyGfxPartsFromModelIDArray(bodyid,self.groupgfx,self.modelparts,modelidarr,iPrimaryHandItem,iSecondaryHandItem)
	local t_end = Client_GetTicks()
	print("gBodyGfxPrototype:Update createparts:",t_end-t_start)
		
    -- create mount gfx (todo : replace by CreateBodyGfx or update bodygfx for mount)
    local mount = self:GetEquipmentAtLayer(kLayer_Mount)
    if (mount) then
        local mountbodyid = gMountTranslate[mount.artid]
        --~ print("gBodyGfxPrototype:Update",mount.artid,mountbodyid,mount.hue)
        if ((not mountbodyid) or mountbodyid == 0) then mountbodyid = gStandardHorse end
        if (mountbodyid and mountbodyid ~= 0) then
            local mountskeleton = GetOrCreateSkeleton(mountbodyid) -- skeleton is determined by the bodyid, not possible from the wearables
			if (not mountskeleton) then return end
            local meshname = GetGrannyMeshName(mountbodyid,mountskeleton.name,mount.hue or 0)
            
            -- fallback to standard horse mount
            if (not meshname) then
                printdebug("granny","warning, broken mountid, falling back to horse ",mountbodyid)
                mountbodyid = gStandardHorse
            end
            
            if (not self.modelmountgfx) then 
				self.modelmountgfx = CreateBodyGfx(self.modelgfx) 
				self.modelmountgfx.iSlowAnimInterval = self.iSlowAnimInterval
			end
            self.modelmountgfx.artid = 0
            self.modelmountgfx.hue = gMountHueOverride[mount.artid] or mount.hue or 0
            self.modelmountgfx.equipmentlist = {}
            self.modelmountgfx.bodyid = mountbodyid
            self.modelmountgfx:SetState(self.bMoving,self.bTurning,self.bWarMode,self.bRunFlag)
            self.modelmountgfx:Update() -- instant update
        end
        printdebug("granny","MOUNT ",mountbodyid,mount.artid,gMountTranslate[mount.artid])
    else 
        if (self.modelmountgfx) then self.modelmountgfx:Destroy() self.modelmountgfx = nil end
    end
    self.groupgfx:SetPosition(0,0,mount and kMountZAdd[bodyid] or 0)
    
    self:PartsSetAnim() -- todo : update returned animlen ? self.bla_animlen = result ?
end


-- ##### ##### ##### ##### ##### processing equipment list, stitching


-- returns array with granny-model ids for bodyparts and clothing
function gBodyGfxPrototype:GetModelPartModelIDs () 
    local iPrimaryHandItem = nil
    local iSecondaryHandItem = nil
    local modelidarr = {}
    
    local bodyid = self:GetBodyID()
    local bFemale = IsBodyIDFemale(bodyid)
    
    -- male/female
    local skinhue = self.hue or 0
    local bSingleModel = true
    if (IsBodyIDHuman(bodyid)) then 
        bSingleModel = false
        if (bFemale) then  -- often (bodyid == 401)
            -- human female body parts
            for k,v in pairs(kGrannyModelPartByNum) do table.insert(modelidarr,{hue=skinhue,modelid=k+kGrannyModelPartAddFemale}) end
            table.insert(modelidarr,{hue=skinhue,modelid=kGrannyModelPartFaceStart+kGrannyModelPartAddFemale}) -- todo : correct face
        else -- often (bodyid == 400)
            -- human male body parts
            for k,v in pairs(kGrannyModelPartByNum) do table.insert(modelidarr,{hue=skinhue,modelid=k+kGrannyModelPartAddMale}) end
            table.insert(modelidarr,{hue=skinhue,modelid=kGrannyModelPartFaceStart+kGrannyModelPartAddMale}) -- todo : correct face
        end
    end
    
    -- equipment, ORDER IS IMPORTANT FOR STITCHIN !!!
    if ((not bSingleModel) and self.equipmentlist) then 
        -- TODO : i assume the paperdoll layerorder is the same as the granny layeroder, check if this is correct
        for index,layer in pairs(gLayerOrder) do
            local item = self:GetEquipmentAtLayer(layer)
            if (item and layer ~= kLayer_Mount) then  -- ignore mounts here, handled seperately
                local tiledata = GetStaticTileType(item.artid or 0)
                --print("equip",item.artid,tiledata and tiledata.miAnimID or 0)
                local modelid = item.animid or (tiledata and tiledata.miAnimID)
                if (modelid) then 
                    if (bFemale and GetGrannyModelInfo(modelid + kGrannyEquipmentFemaleAdd)) then
                        -- use female variant if available
                        modelid = modelid + kGrannyEquipmentFemaleAdd 
                    end
                    local hue = item.hue or 0
                    table.insert(modelidarr,{hue=hue,modelid=modelid})
                    
                    local hand = GetGrannyHand(modelid)
                    if (hand == 1) then iPrimaryHandItem    = {hue=hue,modelid=modelid} end
                    if (hand == 2) then iSecondaryHandItem  = {hue=hue,modelid=modelid} end
                end -- TODO : tiledata.miHue
            end
        end
    end
    
    -- single model, overrides stuff below 
    if (bSingleModel) then
        local modelid = gMountGrannyOverride[bodyid] or bodyid
        table.insert(modelidarr,{hue=skinhue,modelid=modelid})
    end
    
    -- summon dark powers to get magic uo bugjuice to work as it is supposed to
    modelidarr = DoStitchin(gStitchinLoader,modelidarr)
    
    return modelidarr,iPrimaryHandItem,iSecondaryHandItem
end



-- ##### ##### ##### ##### ##### generating gfx

-- helper function for CreateBodyGfxPartsFromModelIDArray
function MakeBodyPartGfx    (modelid,meshname,partgfx,forcescalex,forcescaley,forcescalez)
    -- Override default Granny-Mesh with custom defined Ogre-Mesh from filter.granny.lua
    local meshnameoverride = GrannyMeshOverride(modelid)
    if (meshnameoverride) then meshname = meshnameoverride end

    partgfx:SetMesh(GrannyMeshOverride(modelid) or meshname)
    partgfx:SetCastShadows(gMobileCastShadows)  
    
    local modelinfo = GetGrannyModelInfo(modelid)
    if (modelinfo) then
        local myscalex = forcescalex or modelinfo.scalex * gGrannyScaleFactor
        local myscaley = forcescaley or modelinfo.scaley * gGrannyScaleFactor
        local myscalez = forcescalez or modelinfo.scalez * gGrannyScaleFactor
		local filter = gGrannyFilter[modelid]
		if (filter and filter.scale) then 
			myscalex = myscalex * filter.scale.x
			myscaley = myscaley * filter.scale.y
			myscalez = myscalez * filter.scale.z
		end
		
        if (myscalex ~= 1 or myscaley ~= 1 or myscalez ~= 1) then
            partgfx:SetScale(myscalex,myscaley,myscalez)
            partgfx:SetNormaliseNormals(true)
        end
    end
    return partgfx
end

-- Add Granny Mobiles
-- creates childnodes of parentgfx and adds inserts them into the partsarr table
function CreateBodyGfxPartsFromModelIDArray (bodyid,parentgfx,partsarr,modelidarr,iPrimaryHandItem,iSecondaryHandItem)
    if (not gGrannyLoaderType) then return end
    local skeleton = GetOrCreateSkeleton(bodyid) -- skeleton is determined by the bodyid, not possible from the wearables
	if (not skeleton) then return end
    local skeleton_name = skeleton and skeleton.name or "unknown_skeleton"
    printdebug("granny","CreateBodyGfxPartsFromModelIDArray...",bodyid,bodyid,skeleton_name)
    local leftHandEntity1
    local leftHandEntity2
    local leftHandBoneName1
    local leftHandBoneName2
    local rightHandEntity1
    local rightHandEntity2
    local rightHandBoneName1
    local rightHandBoneName2
    local handname 

    local fsx,fsy,fsz -- force the scale  of the main body to all bodyparts
    local modelinfo = GetGrannyModelInfo(bodyid)
    if (IsBodyIDHuman(bodyid)) then 
        local s = gGrannyScaleFactor
        fsx,fsy,fsz = s*modelinfo.scalex,s*modelinfo.scaley,s*modelinfo.scalez
    end
        
    for k,element in pairs(modelidarr) do
        local modelid = element.modelid
        if (modelid ~= (iPrimaryHandItem and iPrimaryHandItem.modelid) and modelid ~= (iSecondaryHandItem and iSecondaryHandItem.modelid)) then
            -- HasBone
            local meshname = GetGrannyMeshName(modelid,skeleton_name,element.hue or 0)
            if (meshname) then 
                local partgfx = MakeBodyPartGfx(modelid,meshname,parentgfx:CreateChild(),fsx,fsy,fsz)
                handname = "cp_grasp_rhand" if (partgfx:HasBone(handname)) then rightHandEntity1 = partgfx rightHandBoneName1 = handname end
                handname = "cp_grasp_lhand" if (partgfx:HasBone(handname)) then  leftHandEntity1 = partgfx  leftHandBoneName1 = handname end
                handname = "bip01 r hand"   if (partgfx:HasBone(handname)) then rightHandEntity2 = partgfx rightHandBoneName2 = handname end
                handname = "bip01 l hand"   if (partgfx:HasBone(handname)) then  leftHandEntity2 = partgfx  leftHandBoneName2 = handname end
                table.insert(partsarr,partgfx)
            end
        end
    end

    -- prefer rightHandEntity1(grasp) over rightHandEntity2
    if (not rightHandEntity1) then rightHandEntity1 = rightHandEntity2 rightHandBoneName1 = rightHandBoneName2 end
    if (not  leftHandEntity1) then  leftHandEntity1 =  leftHandEntity2  leftHandBoneName1 =  leftHandBoneName2 end
    
    -- create right hand
    if (iPrimaryHandItem and rightHandBoneName1) then
        local modelid = iPrimaryHandItem.modelid
        local meshname = GetGrannyMeshName(modelid,skeleton_name,iPrimaryHandItem.hue or 0)
        if (meshname) then 
            table.insert(partsarr,MakeBodyPartGfx(modelid,meshname,rightHandEntity1:CreateTagPoint(rightHandBoneName1),fsx,fsy,fsz))
        end
    end
    
    -- create left hand
    if (iSecondaryHandItem and leftHandBoneName1) then
        local modelid = iSecondaryHandItem.modelid
        local meshname = GetGrannyMeshName(modelid,skeleton_name,iSecondaryHandItem.hue or 0)
        if (meshname) then 
            table.insert(partsarr,MakeBodyPartGfx(modelid,meshname,leftHandEntity1:CreateTagPoint(leftHandBoneName1),fsx,fsy,fsz))
        end
    end
end



-- ##### ##### ##### ##### ##### anim,step


function gBodyGfxPrototype:SetCorpse ()
    self.bIsCorpse = true
end
function gBodyGfxPrototype:SetDying ()
    self.bIsDying = true
end


gProfiler_BodyGfxStep = CreateRoughProfiler("BodyGfxStep")
function gBodyGfxPrototype:Step     ()
	
    --~ gProfiler_MainStep:Start(gEnableProfiler_MainStep)
    --~ gProfiler_MainStep:Section("LugreStep")

    -- trigger update if marked
    if (self.bDead) then return end
	
    gProfiler_BodyGfxStep:Start(gEnableProfiler_BodyGfxStep)
    gProfiler_BodyGfxStep:Section("Update")
	
    if (self.bMarkedForUpdate) then self:Update() end
    
    gProfiler_BodyGfxStep:Section("sec1")
    -- check for anim end
    if (self.animend and self.animend <= gMyTicks) then self:StopAnim() end
    
    -- start state(walk,run,combat,idle..) anims if needed
    self:StartStateAnimIfNeeded()
    
    gProfiler_BodyGfxStep:Section("sec2")
    -- anim step
    if (self.curanimid) then -- add time and loop
        self.animtime = (self.animtime or 0) + gSecondsSinceLastFrame
        if (self.bIsDying and self.animtime > self.animlen) then self.bIsDying = false self:SetVisible(false) end
        while (self.animlen > 0 and self.animtime > self.animlen) do self.animtime = self.animtime - self.animlen end 
    end
    gProfiler_BodyGfxStep:Section("sec3")
	local bForceUpdateEvenIfAnimDisabled = false
    if (self.bIsCorpse) then 
		self.animtime = self.animlen 
		if (not self.bCorpseAnimSet) then
			self.bCorpseAnimSet = true
			bForceUpdateEvenIfAnimDisabled = true
		end
	end 
	
	if ((not gGrannyAnimEnabled) and ((self.last_anim_step or 0) < gMyTicks - (self.iSlowAnimInterval or (1000/5)))) then
		bForceUpdateEvenIfAnimDisabled = true
	end
	if (gGrannyAnimEnabled or bForceUpdateEvenIfAnimDisabled) then 
		for k,partgfx in pairs(self.modelparts or {}) do partgfx:SetAnimTimePos(self.animtime) end -- update parts
		self.last_anim_step = gMyTicks
	end
	
    gProfiler_BodyGfxStep:End()
end

function gBodyGfxPrototype:StopAnim ()
    self.curanimid = nil
    self.animend = nil
    self.bIsStateAnim = false
end


function gBodyGfxPrototype:StartAnimLoop (animid) self:StartAnim(animid,-1) end

-- stops the previous anim and starts playing this one
-- iRepeatCount = -1 : loop infinitely
-- iRepeatCount = 0 : play anim once (default)
-- iRepeatCount = 1 : play anim twice ....
function gBodyGfxPrototype:StartAnim (animid,iRepeatCount)
    iRepeatCount = iRepeatCount or 0
    self:Update() -- make sure model parts are loaded
    self.curanimid = animid
    self.iRepeatCount = iRepeatCount
    local animlen = self:PartsSetAnim() or 1
    self.bIsStateAnim = false
    self.animtime = 0
    self.animlen = animlen
    self.animend = (iRepeatCount >= 0) and (gMyTicks + 1000*animlen*(1+iRepeatCount)) or false
end 



-- returns max animlen
function gBodyGfxPrototype:PartsSetAnim ()
    if (gDisableModelAnim) then return end
    if (not gAnimInfoLists) then return end
    if (not gGrannyLoaderType) then return end
    local bodyid = self:GetBodyID()
    local animname = GetAnimName(bodyid,self.curanimid)
    if ((not animname) or (not GetAnimPath(bodyid,self.curanimid))) then return end -- anim not found
    local animlen = 0
    --~ print("PartsSetAnim",bodyid,self.curanimid)
    for k,v in pairs(self.modelparts or {}) do 
        if (v:HasSkeleton()) then
            local bLoop = self.iRepeatCount ~= 0
            if (self.bIsCorpse) then bLoop = false end
            v:SetAnim(animname,bLoop) -- always manual abort using animend
            animlen = math.max(animlen,v:GetAnimLength(animname))
            --~ print(k,animname,v:GetAnimLength(animname))
        end
    end
    
    -- horse-run anim length correction hack (model anim is too long, looks rather ugly)
    if (bodyid == 401 and self.curanimid == 24) then animlen = 0.61666667461395 end
    if (bodyid == 400 and self.curanimid == 24) then animlen = 0.61666667461395 end
    
    return animlen
end



-- ##### ##### ##### ##### ##### state (run,walk,idle,combat...)



-- interrupt serverside anim on movement, and init anim if not set
function gBodyGfxPrototype:SetState (bMoving,bTurning,bWarMode,bRunFlag)
    self.bMoving = bMoving
    self.bTurning = bTurning
    self.bWarMode = bWarMode
    self.bRunFlag = bRunFlag
    if (self.modelmountgfx) then self.modelmountgfx:SetState(bMoving,bTurning,bWarMode,bRunFlag) end
end

function gBodyGfxPrototype:StartStateAnimIfNeeded   ()
    local animid = self:CalcStateAnim()
    if (self.curanimid == animid) then return end -- already running
    
    -- move interrupts other anims, otherwise wait until other anim has finished
    if ((not self.curanimid) or self.bIsStateAnim or self.bMoving) then 
        self:StartAnimLoop(animid) 
        self.bIsStateAnim = true 
    end
end

-- 1 for primary, 2 for secondary, 0 otherwise
function GetGrannyHand (modelid)
    local modelinfo = GetGrannyModelInfo(modelid)
    return modelinfo and modelinfo.hand or 0
end

function gBodyGfxPrototype:CalcStateAnim    ()
    local bodyid = self:GetBodyID()
    
    -- detect animation modifiers : staff, mount=horse, combat, run
    local mount     = self:GetEquipmentAtLayer(kLayer_Mount)
    
    local twohand   = self:GetEquipmentAtLayer(kLayer_TwoHanded) -- staff or shield/staff...
    local bHasStaff = false
    if (twohand) then
        local tiledata = GetStaticTileType(twohand.artid or 0)
        local modelid = twohand.animid or (tiledata and tiledata.miAnimID)
        if (GetGrannyHand(modelid) == 2) then bHasStaff = true end
    end
    
    
    local bIdle = (not self.bTurning) and (not self.bMoving)
    local bRun  = (not bIdle) and (self.bRunFlag and self.bMoving)
    local bWalk = (not bIdle) and (not bRun)
    --~ if (self.bWarMode) then print("gBodyGfxPrototype:CalcStateAnim war",self:GetBodyID()) end
    local bIsGhost = IsGhostBodyID(self:GetBodyID())
    
    return BodyGfxGetStateAnimID(bodyid,bWalk,bRun,bIdle,mount,self.bWarMode and (not bIsGhost),bHasStaff,self.bIsCorpse)
end
