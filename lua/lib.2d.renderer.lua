-- isometric view, 2d sprites, imitates original client
-- TODO : net.multi.lua has some Renderer3D specific entries

-- gCurrentRenderer
-- NotifyListener("Hook_Bla",param)
-- RegisterListener("Hook_Bla",function (param) end)

Renderer2D = {}

gRendererList[ "Renderer2D" ] = Renderer2D

Renderer2D.kSpriteBaseMaterial = "renderer2dbillboard"
kSq2					= math.sqrt(2)
k2D_ScaleH				= kSq2 / 44
k2D_ScaleW05			= 0.5 / 44 -- 0.5 : applied left and right
kRenderer2D_Inv44		= 1/44
kRenderer2D_Sin45		= 0.5*kSq2 -- sin(45)
kRenderer2D_ZScale		= 4 * kRenderer2D_Inv44 / kRenderer2D_Sin45 -- zloc=1 means 4 pixels 0.12856486930664
kRenderer2D_XPixelScale	= kRenderer2D_Inv44 
kRenderer2D_YPixelScale	= kRenderer2D_Inv44 / kRenderer2D_Sin45

dofile(libpath .. "lib.2d.cam.lua")
dofile(libpath .. "lib.2d.map.lua")
dofile(libpath .. "lib.2d.mousepick.lua")
dofile(libpath .. "lib.2d.mobile.lua")
dofile(libpath .. "lib.2d.dynamic.lua")
dofile(libpath .. "lib.2d.spriteblock.lua")
dofile(libpath .. "lib.2d.effect.lua")
dofile(libpath .. "lib.2d.hudfx.lua")

function Renderer2D:FirstInit ()
	if (self.bFirstInitDone) then return end
	self.bFirstInitDone = true
	RegisterListener("Hook_MainWindowResized",function () Renderer2D.gbNeedCorrectAspectRatio = true end)
end

function Renderer2D:Init ()
	self.bMinimalGfx = gCommandLineSwitches["-minimalgfx"]
	self:FirstInit()
	MultiTexTerrainInit()
	self:InitMap()
	self.gbActive = true
	
	self:StartWorld()
end

function Renderer2D:DeInit ()
	MultiTexTerrainDeInit()
	-- if 2d is stopped, stop also World
	self:StopWorld()
	self:DeInitMap()	
	self.gbActive = false
end

-- called by main.lua
function Renderer2D:StartWorld ()
	-- for 2D/3D renderer switching
	self:CamInit()
	
	Client_ClearLights()  -- this has to be verified, this causes a seg fault with caelum (sience)
	-- initialize Worldlight
	SetupWorldLight_Default()
	
	-- initialize Mapenvironment
	self:SetMapEnvironment()

	-- switch renderer : create all object visuals
	for k,dynamic in pairs(GetDynamicList()) do if (DynamicIsInWorld(dynamic)) then self:AddDynamicItem(dynamic) end end
	for k,mobile in pairs(GetMobileList()) do self:CreateMobileGfx(mobile) end
end

function Renderer2D:ClearDynamicsAndMobiles ()
	for k,dynamic in pairs(GetDynamicList()) do if (DynamicIsInWorld(dynamic)) then self:RemoveDynamicItem(dynamic) end end
	for k,mobile in pairs(GetMobileList()) do self:DestroyMobileGfx(mobile) end
end
function Renderer2D:StopWorld ()
	self:ClearDynamicsAndMobiles()
	Client_ClearLights()
	-- to handle dirty dynamic blocks
	self:MainStep()
end

-- local uodir,pixeldist = Get2DMouseDirAndDist()
function Get2DMouseDirAndDist ()
	local mx,my = GetMousePos()
	local vw,vh = GetViewportSize()
	local cx,cy = 0.5*vw,0.5*vh
	return DirWrap( floor(1.5+math.atan2(my-cy,mx-cx) * 8 / (2*kPi)) ),dist2(mx,my,cx,cy)
end

gProfiler_R2D_MainStep = CreateRoughProfiler(" 2D:MainStep")

-- called from mainstep while ingame
function Renderer2D:MainStep ()
	gProfiler_R2D_MainStep:Start(gEnableProfiler_R2D_MainStep)
	gProfiler_R2D_MainStep:Section("CamStep")
	self:CamStep()
	gProfiler_R2D_MainStep:Section("MobileAnimStep")
	self:MobileAnimStep()
	
	gProfiler_R2D_MainStep:Section("mouse")
	local uodir,pixeldist = Get2DMouseDirAndDist()
	
	local xloc,yloc,zloc = GetPlayerPos()
	local bOfflineMode = xloc == nil
	gProfiler_R2D_MainStep:Section("walk")
	if (not bOfflineMode) then
		if (gKeyPressed[key_mouse_right] and (not gLastMouseDownWidget)) then 
			local bRunFlag = pixeldist > 200
			if (gAlwaysRun) then bRunFlag = true end
			--~ print("Get2DMouseDirAndDist",uodir,pixeldist)
			WalkStep_WalkInDir(uodir,bRunFlag,true)
		end
		
		
		--[[
		local dx = 0
		local dy = 0
		if (gKeyPressed[key_left] ) then dx = dx + 1 end
		if (gKeyPressed[key_right]) then dx = dx - 1 end
		if (gKeyPressed[key_up   ]) then dy = dy - 1 end
		if (gKeyPressed[key_down ]) then dy = dy + 1 end
		local iDir = DirFromLocalDxDy(dx,dy) 
		if (iDir) then
			local bRunFlag = true
			WalkStep_WalkInDir(iDir,bRunFlag,true)
		end
		]]--
	end
	
	gProfiler_R2D_MainStep:Section("MobileStep")
	-- TODO : self:CombatGuiStep() ?
	self:MobileStep() -- bevore cam pos so cam is exactly on player
	
	gProfiler_R2D_MainStep:Section("SetCamPos")
	local xloc,yloc,zloc = GetPlayerPos()
	if (xloc and (not g2DCamMove)) then 
		self:SetCamPos(self:GetExactMobilePos(GetPlayerMobile())) -- after MobileStep so cam is exactly on player
	end
	
	-- keyboard move cam
	
	local bKeyBoardMoveCam = g2DCamMove or bOfflineMode
	if (bKeyBoardMoveCam) then
		if (bOfflineMode) then self.gbBlendOutTerrainVisible = true end
		local dt = math.min(Renderer2D.kGoodTicksBetweenFrames/1000,gSecondsSinceLastFrame)
		local curticks = Client_GetTicks()
		local xloc,yloc = self:GetCamPos()
		local move = 16 * dt  * (gKeyPressed[key_lshift] and 8*16 or 1)
		local dx = move * ((gKeyPressed[key_left] and -1 or 0) + (gKeyPressed[key_right] and 1 or 0))
		local dy = move * ((gKeyPressed[key_up] and -1 or 0) + (gKeyPressed[key_down] and 1 or 0))
		if (dx ~= 0 or dy ~= 0) then 
			local tt,zz = GetGroundAtAbsPos(math.floor(xloc+dx),math.floor(yloc+dy))
			self:SetCamPos(xloc+dx,yloc+dy,zz) 
		end
	end
	
	
	gProfiler_R2D_MainStep:Section("EffectAnimStep")			self:EffectAnimStep() -- should be after player pos is updated, for effects moving with player
	gProfiler_R2D_MainStep:Section("MapStep")					self:MapStep()
	gProfiler_R2D_MainStep:Section("HUDFX_MainStep")			self:HUDFX_MainStep()
	gProfiler_R2D_MainStep:Section("Dynamics_MainStep")			self:Dynamics_MainStep()
	gProfiler_R2D_MainStep:Section("Dynamics_MultiUpdateStep")	self:Dynamics_MultiUpdateStep()
	gProfiler_R2D_MainStep:Section("MousePickStep")				self:MousePickStep()
	gProfiler_R2D_MainStep:End()
end

function Renderer2D:CamKeyDown						(key) end
function Renderer2D:CamKeyUp						(key) end

-- returns ax,xloc,yloc  (ax = angle, constant for iso cam)
function Renderer2D:GetCompassInfo				() 
	local ax = (180+45)*gfDeg2Rad
	local xloc,yloc = self:GetCamPos()
	return ax,xloc,yloc
end

-- used by MacroRead_GetPlayerPosition when no playermobile found (yet)
function Renderer2D:GetExactLocalPos() return 0,0,0 end

function Renderer2D:SetOfflineStartPos			(x,y,z) self:SetCamPos(-x,y,z) end



-- skybox,fog etc for 3d
function Renderer2D:SetMapEnvironment () 
	GetMainViewport():SetBackCol(0,0,0)
	Client_SetFog(0)
end

function Renderer2D:UpdateMapEnvironment (hour,minute,second) end -- update time, lightscale and season

function Renderer2D:SetLastConfirmedUOPos(xloc,yloc,zloc) end -- walk
function Renderer2D:SetLastRequestedUOPos(xloc,yloc,zloc) end -- walk
function Renderer2D:SetViewDir(dx,dy)			end --- for AttackMobile macro
function Renderer2D:OfflineTeleportToMouse		() end


function Renderer2D:UOPosToLocal				(xloc,yloc,z) -- needed for multitex-terrain ?
	return	-(xloc),
			 (yloc),
			 (z or 0)
end


function Renderer2D:UOPosToLocal2 (xloc,yloc,zloc) return self:UOPosToLocal(xloc,yloc,zloc*kRenderer2D_ZScale) end

-- returns px,py,bIsInFront
function Renderer2D:UOPosToPixelPos (xloc,yloc,zloc)
	return self:LocalPosToPixelPos(self:UOPosToLocal(xloc,yloc,zloc*kRenderer2D_ZScale))
end

-- returns px,py,bIsInFront
function Renderer2D:LocalPosToPixelPos (x,y,z)
	local bIsInFront,px,py = ProjectPos(x,y,z)
	return floor((1+px)*gViewportW*0.5 + 0.5),floor((1-py)*gViewportH*0.5 + 0.5),bIsInFront
end

function Renderer2D:InitLocalCam				(x,y,z) end -- ??? offline mode ?
function Renderer2D:ChangeCamMode				() end
function Renderer2D:SelectMobile				() end
function Renderer2D:DeselectMobile				() end
function Renderer2D:UpdateTrackingArrow			(...) end -- tracking skill, not yet implemented
function Renderer2D:NotifyHPChange				(mobile, value) end
function Renderer2D:NotifyManaChange			(mobile, value) end
function Renderer2D:NotifyPlayerTeleported		() end
function Renderer2D:ClearMapCache				() self:MapClear() end

function Renderer2D:TerrainRayIntersect_Hit		(...) end -- ??? might not be needed


-- sets the global sunlight level, intensity=0 -> dark, intensity=1 -> bright
function Renderer2D:SetSunLight		(intensity) end
-- sets the personal light level, intensity=0 -> dark, intensity=1 -> bright
function Renderer2D:SetPersonalLight		(mobile, intensity) end
