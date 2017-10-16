--[[ ***** see Iris2 COPYING for license info ***** ]]--
--[[ \brief
		3d rendering
		(see also lib.3d.mobile.lua, lib.3d.dynamic.lua)
]]--

Renderer3D = {}

dofile(libpath .. "lib.3d.effect.lua")
dofile(libpath .. "lib.3d.mobile.lua")
dofile(libpath .. "lib.3d.dynamic.lua")
dofile(libpath .. "lib.3d.mousepick.lua")
dofile(libpath .. "lib.3d.map.lua")
dofile(libpath .. "lib.3d.combat.lua")
dofile(libpath .. "lib.3d.cam.lua")
dofile(libpath .. "lib.3d.walksmooth.lua")
dofile(libpath .. "lib.3d.tilebatch.lua")
dofile(libpath .. "lib.3d.dynamicspawner.lua")
dofile(libpath .. "lib.3d.multispawner.lua")
dofile(libpath .. "lib.3d.waterspawner.lua")
dofile(libpath .. "lib.3d.light.lua")
dofile(libpath .. "lib.3d.cadunetree.lua")
dofile(libpath .. "lib.3d.hudfx.lua")

gRendererList[ "Renderer3D" ] = Renderer3D

local gCaelumSystem = nil

-- static Factor to rise the Z-Level for statics+dynamics
Renderer3D.gZ_Factor = 0.01 --0.0090
Renderer3D.gbActive = false
Renderer3D.gbNeedCorrectAspectRatio = true
Renderer3D.gDynamicMaxRenderDist = 128 -- 0 means always rendered  -- TODO : make this dependant on bounding sphere size, e.g. in pixel size ?
Renderer3D.gDynamicZAdd = 0.2 -- add a bit to make sure all dynamics can be clicked and none are below the floor, todo : improve this by detecting floor height and model bbox

function Renderer3D:FirstInit ()
    if (self.bFirstInitDone) then return end
    self.bFirstInitDone = true
    RegisterListener("Hook_MainWindowResized",function () Renderer3D.gbNeedCorrectAspectRatio = true end)
end

function Renderer3D:Init ()
    self:FirstInit()
    MultiTexTerrainInit()
    self:InitMap()
    self:StartWorld()
    gTileFreeWalk:Init()
    self.gbActive = true
    self.mfPersonalLight = 0
    self.mfSunLight = 1
	GrannyTest3DData()
end

-- deactivating Renderer3D
-- todo: LoadTexAtlas()  deinit ?!?
function Renderer3D:DeInit ()
    MultiTexTerrainDeInit()
    gTileFreeWalk:DeInit()

    -- if 3d is stopped, stop also World
    self:StopWorld()
    self:DeInitMap()

    self.gbActive = false

    -- remove players personal light
    if self.mPersonalLightName then
        Client_RemoveLight(self.mPersonalLightName)
        self.mPersonalLightName = nil
    end
end

-- called by main.lua
function Renderer3D:StartWorld ()
    -- for 2D/3D renderer switching
    self:CamInit()

    -- clear all Lights 
    Client_ClearLights()
    -- initialize Worldlight for normal SkyBox´
    SetupWorldLight_Default()

    -- initialize Mapenvironment
    self:SetMapEnvironment()
    -- initialize Shadowsystem
    self:SetupShadows(gShadowTechnique)

    -- SiENcE: not needed anymore? bring up and assertion failure (it seems without, everything is correct)
    for k,dynamic in pairs(GetDynamicList()) do if (DynamicIsInWorld(dynamic)) then self:AddDynamicItem(dynamic) end end
    for k,mobile in pairs(GetMobileList()) do self:CreateMobileGfx(mobile) end
	
	self:BlendOutLayersAbovePlayer()
end

function Renderer3D:StopWorld ()
    for k,dynamic in pairs(GetDynamicList()) do if (DynamicIsInWorld(dynamic)) then self:RemoveDynamicItem(dynamic) end end
    for k,mobile in pairs(GetMobileList()) do self:DestroyMobileGfx(mobile) end
    self:DeactivateMousePick()
    Client_ClearLights()
    self:ClearMapCache()
    self:DeleteMapEnvironment()
end

function Renderer3D:SetOfflineStartPos (x,y,z)
    gTileFreeWalk:SetPos_All(self:LocalToUOPos(x+0.5,y+0.5,z)) -- + for both might be wrong..
end

gProfiler_R3D_MainStep = CreateRoughProfiler(" 3D:MainStep")

function Renderer3D:MainStep    ()
	if (gEnableBloomShader) then
		if (not gRegisteredBloomCompositor) then
			gRegisteredBloomCompositor = true 
			OgreAddCompositor(GetMainViewport(),"Bloom")
		end
	end
    gProfiler_R3D_MainStep:Start(gEnableProfiler_R3D_MainStep)
    
    gProfiler_R3D_MainStep:Section("CombatGuiStep")     self:CombatGuiStep()
    gProfiler_R3D_MainStep:Section("MobileAnimStep")    self:MobileAnimStep()
    gProfiler_R3D_MainStep:Section("CamStep")           self:CamStep()
    --~ self:UpdateMap()
    gProfiler_R3D_MainStep:Section("MousePickStep")     self:MousePickStep()
    
    -- b&w effect on death
    local playermobile = GetPlayerMobile()
    if playermobile and playermobile.stats and playermobile.stats.curHits then
        if playermobile.stats.curHits == 0 and gGotDeath then
            -- dead
            -- alive
            if not gBWCompositor then
                OgreAddCompositor(GetMainViewport(),"B&W")
                gBWCompositor = true
            end
        else
            -- alive
            gGotDeath = false
            if gBWCompositor then
                OgreRemoveCompositor(GetMainViewport(),"B&W")
                gBWCompositor = false
            end
        end
    end

    gProfiler_R3D_MainStep:Section("MapStep")			self:MapStep()
    gProfiler_R3D_MainStep:Section("UpdateLight")		self:UpdateLight()
    gProfiler_R3D_MainStep:Section("HUDFX_MainStep")	self:HUDFX_MainStep()
    gProfiler_R3D_MainStep:End()
end

function Renderer3D:SetLastConfirmedUOPos(xloc,yloc,zloc) gTileFreeWalk:Impl_SetLastConfirmedUOPos(xloc,yloc,zloc) end -- walk
function Renderer3D:SetLastRequestedUOPos(xloc,yloc,zloc) gTileFreeWalk:Impl_SetLastRequestedUOPos(xloc,yloc,zloc) end -- walk

--- for AttackMobile macro
function Renderer3D:SetViewDir(dx,dy) gTileFreeWalk:SetViewDir(dx,dy) end

-- for hotkey
function Renderer3D:OfflineTeleportToMouse()
    local rx,ry,rz = gTileFreeWalk:RoundPos(gTileFreeWalk:MousePickPos())
    gTileFreeWalk:SetPos_All(self:LocalToUOPos(rx,ry,rz*10))
end

-- used by MacroRead_GetPlayerPosition when no playermobile found (yet)
function Renderer3D:GetExactLocalPos()
    local sx,sy,sz = gTileFreeWalk:GetExactLocalPos()
    return -sx,sy,sz
end


-- warning !you still have to do 0.1 z factor seperately
function Renderer3D:UOPosToLocal (xloc,yloc,z) 
    return  -xloc - 8*self.giMapOriginX * self.ROBMAP_CHUNK_SIZE,
            yloc - 8*self.giMapOriginY * self.ROBMAP_CHUNK_SIZE,
            (z or 0) + self.gZ_Factor
end

function Renderer3D:UOPosToLocal2 (xloc,yloc,zloc) return self:UOPosToLocal(xloc,yloc,zloc*0.1) end

-- warning ! you still have to do 0.1 z factor seperately
function Renderer3D:LocalToUOPos (xlocal,ylocal,zlocal) 
    return  -(xlocal + 8*self.giMapOriginX * self.ROBMAP_CHUNK_SIZE),
            ylocal + 8*self.giMapOriginY * self.ROBMAP_CHUNK_SIZE,
            (zlocal or 0) - self.gZ_Factor
end

-- returns px,py,bIsInFront
function Renderer3D:UOPosToPixelPos (xloc,yloc,zloc)
    return self:LocalPosToPixelPos(self:UOPosToLocal(xloc,yloc,zloc*0.1))
end

-- returns px,py,bIsInFront
function Renderer3D:LocalPosToPixelPos (x,y,z)
    local bIsInFront,px,py = ProjectPos(x,y,z)
    return floor((1+px)*gViewportW*0.5 + 0.5),floor((1-py)*gViewportH*0.5 + 0.5),bIsInFront
end

-- param and result in DEGREES
function Renderer3D:TranslateOsiWalkAngle (x)
    local ax,ay,az = GetMainCam():GetEulerAng()
    local camangdeg = ax / gfDeg2Rad
    --print("TranslateOsiWalkAngle",-x,camangdeg)
    --return -x + camangdeg - 3*45
    return x - camangdeg + 5*45
end

function Renderer3D:DeleteMapEnvironment ()
    -- DeInit Caelum here (doesn't seem to work)
    if (gCaelumSystem) then
        print("deinit caelum")
        gCaelumSystem:Shutdown(true)
        gCaelumSystem = nil
    end
end

function Renderer3D:SetMapAreaEnv (env)
	if (gUseCaelumSkysystem) then return end
	Client_SetSkybox(env.skybox) 
	if (gUseDistanceFog) then 
		local fogColorRed           = env.fog_r 
		local fogColorGreen         = env.fog_g 
		local fogColorBlue          = env.fog_b
		local radius = cMapBlock_3D_Terrain.iLoadRadius
		Client_SetFog(3, fogColorRed/255, fogColorGreen/255, fogColorBlue/255, 1.0, 0, 3*radius, 3*radius+gFogValue) 
	end
end

function Renderer3D:SetMapEnvironment (bUnderGround)
    if (not self.gbActive) then return end
    if (not gMapIndex) then return end

    -- black background when underground
    if (bUnderGround) then
        -- if Caelum deinit first
        if (gCaelumSystem) then
            print("deinit caelum")
            gCaelumSystem:Shutdown(true)
            gCaelumSystem = nil
        end
        GetMainViewport():SetBackCol(0,0,0)
        Client_SetSkybox()
    elseif (gUseCaelumSkysystem) then
        -- check if already a caelum skysystem is there
        if (gCaelumSystem) then print("caelum already initialized") return end
        print("init caelum")
        -- create a new Skysystem
        -- create with CG shaders
        gCaelumSystem = CreateCaelumCaelumSystem(
            CAELUM_COMPONENT_SUN + 
            CAELUM_COMPONENT_MOON +
            CAELUM_COMPONENT_SKY_DOME +
            CAELUM_COMPONENT_IMAGE_STARFIELD +
            CAELUM_COMPONENT_CLOUDS +
            CAELUM_COMPONENT_PRECIPITATION +
            --CAELUM_COMPONENT_SCREEN_SPACE_FOG +
            0 --CAELUM_COMPONENT_GROUND_FOG
        )
            
        gCaelumSystem:SetManageSceneFog(true)
        gCaelumSystem:SetSceneFogDensityMultiplier(0.0115)
        gCaelumSystem:SetManageAmbientLight(true)
        gCaelumSystem:SetUpdateTimeout(10)
            
        local sun = gCaelumSystem:GetSun()
        if sun then
            --~ print("SUN")
            sun:SetAmbientMultiplier(0.5, 0.5, 0.5, 1)
            sun:SetDiffuseMultiplier(3, 3, 2.7, 1)
            sun:SetSpecularMultiplier(5, 5, 5, 1)
            sun:SetAutoDisable(true)
            sun:SetAutoDisableThreshold(0.1)
        end

        local moon = gCaelumSystem:GetMoon()
        if moon then
            --~ print("MOON")
            moon:SetAutoDisable(true)
            moon:SetAutoDisableThreshold(0.1)
        end

        local clouds = gCaelumSystem:GetCloudSystem()
        if clouds then
            --~ print("CLOUDS")
            clouds:CreateLayerAtHeight(120)
            clouds:GetLayer(0):SetCloudSpeed(0.000005, -0.000009)
            clouds:GetLayer(1):SetCloudSpeed(0.0000045, -0.0000085)
        end

        local prec = gCaelumSystem:GetPrecipitationController()
        if prec then
            --~ print("PREC")
            --~ prec:SetCoverage(0)
        end
        
        -- Sunrise with visible moon.
        local cl = gCaelumSystem:GetUniversalClock()
        --number year, number month, number day, number hour, number minute, number second
        local t = os.date('*t')
        cl:SetGregorianDateTime(t.year, t.month, t.day, t.hour, t.min, t.sec)

        function rotate(gfx,w,x,y,z)
            local ww,xx,yy,zz = gfx:GetOrientation()
            gfx:SetOrientation(Quaternion.Mul(w,x,y,z, ww,xx,yy,zz))
        end
            
        local w,x,y,z = Quaternion.fromAngleAxis(90 * gfDeg2Rad, 1,0,0)
        rotate(gCaelumSystem:GetCaelumGroundNode(), w,x,y,z)
        rotate(gCaelumSystem:GetCaelumCameraNode(), w,x,y,z)
    else
        -- black background when underground 
		self:MapAreaCheck()
    end
end

function Renderer3D:UpdateMapEnvironment (hour,minute,second)
    if (gCaelumSystem) then
        -- Sunrise with visible moon.
        local cl = gCaelumSystem:GetUniversalClock()
        --number year, number month, number day, number hour, number minute, number second
       
        local t = os.date('*t')
        cl:SetGregorianDateTime(t.year, t.month, t.day, hour or t.hour, minute or t.min, second or t.sec)
    end
end

function Renderer3D:SetupShadows (strShadowTechnique)
    local shadowfardist=5*cMapBlock_3D_Terrain.iLoadRadius+gFogValue
    print("strShadowTechnique = " .. strShadowTechnique)
    print("setShadowFarDistance = " .. shadowfardist)
	
	local shadow_tex_size = 1024
	if (gCommandLineSwitches["-bigshadowtex"]) then shadow_tex_size = 4096 end

    if ((strShadowTechnique == "stencil_modulative") or (strShadowTechnique == "stencil_additive")) then
        ----- currently doesn't work with Fastbatch, works only for Granny's
        OgreSetShadowFarDistance(shadowfardist)
        OgreShadowTechnique(strShadowTechnique)
    elseif ((strShadowTechnique == "texture_modulative") or (strShadowTechnique == "texture_additive")) then
        OgreSetShadowTextureCount(8)                -- first mention the count (one texture for one lightsource)
        OgreSetShadowTextureSize(shadow_tex_size)              -- then the texsize
        OgreSetShadowFarDistance(shadowfardist)
        OgreSetShadowTextureFadeStart(0.6)
        OgreSetShadowTextureFadeEnd(0.9)
        OgreSetShadowCasterRenderBackFaces(false)
        OgreSetShadowTextureSelfShadow(false)       -- doesn't work when using the fixed function pipeline
        OgreShadowTechnique(strShadowTechnique)     -- last, the technique
    elseif ((strShadowTechnique == "texture_additive_integrated") or (strShadowTechnique == "texture_modulative_integrated")) then
        OgreSetShadowTextureSelfShadow(true)
		OgreSetShadowTextureCasterMaterial("shadow_caster")
        OgreSetShadowTextureCount(3)                -- first mention the count (one texture for one lightsource)
        OgreSetShadowTextureSize(shadow_tex_size)               -- then the texsize
        OgreSetShadowTexturePixelFormat(PF_FLOAT16_RGB)
        OgreSetShadowCasterRenderBackFaces(false)
--[[
    const unsigned numShadowRTTs = mgr.sceneMgr->getShadowTextureCount();
    for (unsigned i = 0; i < numShadowRTTs; ++i)
    {
        Ogre::TexturePtr tex = mgr.sceneMgr->getShadowTexture(i);
        Ogre::Viewport *vp = tex->getBuffer()->getRenderTarget()->getViewport(0);
        vp->setBackgroundColour(Ogre::ColourValue(1, 1, 1, 1));
        vp->setClearEveryFrame(true);
    }
]]--
		-- last, the technique
        OgreShadowTechnique(strShadowTechnique)

		-- and add the shader listener
		Client_SetShadowListener("main",0.01)
		OgreAddCompositor(GetMainViewport(),"ssao")
		OgreCompositor_AddListener_SSAO(GetMainViewport(),"ssao",GetMainCam():GetQuickHandle():getName(),"main",42)
    else
        -- any other is like setting No shadows
        OgreShadowTechnique(strShadowTechnique)
    end
end

function Renderer3D:CorrectAspectRatio ()
    if (not Renderer3D.gbNeedCorrectAspectRatio) then return end
    Renderer3D.gbNeedCorrectAspectRatio = false
    local vp = GetMainViewport()
    GetMainCam():SetAspectRatio(vp:GetActualWidth() / vp:GetActualHeight())
end

function Renderer3D:CheckForUpdateMapOrigin()
    if (self.giLastMapOriginX ~= self.giMapOriginX or
        self.giLastMapOriginY ~= self.giMapOriginY) then
        -- change detected, update all
        self.giLastMapOriginX = self.giMapOriginX
        self.giLastMapOriginY = self.giMapOriginY
        
        for k,mobile in pairs(GetMobileList()) do mobile:Update() end
        for k,dynamic in pairs(GetDynamicList()) do if (dynamic.gfx) then
            self:UpdateDynamicItemPos(dynamic)
        end end
    end
end
