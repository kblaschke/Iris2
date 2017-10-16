--[[ ***** see Iris2 COPYING for license info ***** ]]--
--[[ \brief
		Cam around Player handling
]]--

-- default mouse button binding
if not gInput_CamMouseButton then gInput_CamMouseButton = GetNamedKey("mouse3") end

kFirstPersonZAdd_Mount = 1.8
kFirstPersonZAdd_NoMount = 1.4
    
Renderer3D.gCamKeyCode = {}
Renderer3D.gCamKeyCode.Left = GetNamedKey("a")
Renderer3D.gCamKeyCode.Right    = GetNamedKey("d")
Renderer3D.gCamKeyCode.Forward  = GetNamedKey("w")
Renderer3D.gCamKeyCode.Back = GetNamedKey("s")
Renderer3D.gCamKeyCode.Up       = GetNamedKey("r")
Renderer3D.gCamKeyCode.Down = GetNamedKey("f")
Renderer3D.gCamKeyCode.Slow = GetNamedKey("lshift")
Renderer3D.gCamKeyCode.Fast = GetNamedKey("lalt")

Renderer3D.gCamKeyCode.CamCenter        = GetNamedKey("np5")
Renderer3D.gCamKeyCode.CamRotateLeft    = GetNamedKey("np4")
Renderer3D.gCamKeyCode.CamRotateRight   = GetNamedKey("np6")
Renderer3D.gCamKeyCode.CamRotateUp      = GetNamedKey("np8")
Renderer3D.gCamKeyCode.CamRotateDown    = GetNamedKey("np2")

Renderer3D.gCamKeyName = {}
for k,v in pairs(Renderer3D.gCamKeyCode) do Renderer3D.gCamKeyName[v] = k end
Renderer3D.gCamKeyDown = {}
Renderer3D.gCamMoveWithMouse    = false
Renderer3D.gCamMoveWithMouse_OffX   = nil
Renderer3D.gCamMoveWithMouse_OffY   = nil
        
function Renderer3D:CamInit()
    --print("activating Renderer3D")
    local cam = GetMainCam()
    cam:SetFOVy(gfDeg2Rad*45)
    cam:SetNearClipDistance(0.5) -- old : 1
    cam:SetFarClipDistance(2000) -- ogre defaul : 100000
    cam:SetProjectionType(kCamera_PT_PERSPECTIVE) -- perspective
    self.gbCamRotChanged = true

    local vp = GetMainViewport()
    local viewport_w = vp:GetActualWidth()
    local viewport_h = vp:GetActualHeight()
    cam:SetAspectRatio( viewport_w / viewport_h )
end 


function Renderer3D:CamKeyUp(key)
    if (key == gInput_CamMouseButton and self.gCamMoveWithMouse) then 
        self.gCamMoveWithMouse = false 
        self.gCamMoveWithMouse_OffX = nil
        self.gCamMoveWithMouse_OffY = nil
    end
    local camkeyname = self.gCamKeyName[key]
    if (camkeyname) then self.gCamKeyDown[camkeyname] = false end
end
 
function Renderer3D:CamKeyDown(key) 
    if (not gActiveEditText) then 
        if (key == gInput_CamMouseButton and (not self.gCamMoveWithMouse) and (not gLastMouseDownWidget)) then 
            self.gCamMoveWithMouse = true 
            self.gCamMoveWithMouse_OffX,self.gCamMoveWithMouse_OffY = GetMousePos()
        end
        local camkeyname = self.gCamKeyName[key]
        if (camkeyname) then self.gCamKeyDown[camkeyname] = true end
        --printf("CamKeyDown(%s)\n",GetKeyName(key))
        -- key_mouse1
    end
    
    
    local lrd = 0.25*kPi
    local udd = 0.25*kPi/2
    -- 45 degree cam rotations
    if key == self.gCamKeyCode.CamCenter then
        self.gfCamAngH = -3*0.25*kPi  -- default to original iso angle
        self.gfCamAngV = -0.25*kPi
        self:CamApplyAngHV()
    end
    if key == self.gCamKeyCode.CamRotateLeft then
        self.gfCamAngH = self.gfCamAngH - lrd
        self:CamApplyAngHV()
    end
    if key == self.gCamKeyCode.CamRotateRight then
        self.gfCamAngH = self.gfCamAngH + lrd
        self:CamApplyAngHV()
    end
    if key == self.gCamKeyCode.CamRotateUp then
        self.gfCamAngV = self.gfCamAngV - udd
        self:CamApplyAngHV()
    end
    if key == self.gCamKeyCode.CamRotateDown then
        self.gfCamAngV = self.gfCamAngV + udd
        self:CamApplyAngHV()
    end
end

Renderer3D.gfMaxCamAngVDelta = 0.5*kPi
Renderer3D.gfCamAngH = - 3*0.25*kPi  -- default to original iso angle
Renderer3D.gfCamAngV = -Renderer3D.gfMaxCamAngVDelta
Renderer3D.gfSensitivityMod = 0.02
Renderer3D.gCamRotW,Renderer3D.gCamRotX,Renderer3D.gCamRotY,Renderer3D.gCamRotZ = 1,0,0,0
Renderer3D.gfMouseSensitivity = 3.0 -- TODO : to config
Renderer3D.gbInvertMouseY = false -- TODO : to config
Renderer3D.gStartThirdPersonDist = 14 --32
Renderer3D.gThirdPersonDist = Renderer3D.gStartThirdPersonDist

Renderer3D.kCamMode_FreeMove = 0
Renderer3D.kCamMode_Ego = 1
Renderer3D.kCamMode_Third = 2
Renderer3D.kCamMode_Max = 2
Renderer3D.gCamMode = Renderer3D.kCamMode_Third -- TODO : to config, switch by key


Renderer3D.gCamLookAheadX = 0 -- used for map loading in lib.map.lua
Renderer3D.gCamLookAheadY = 0
Renderer3D.gCamLookAheadDistList =
               {
                [Renderer3D.kCamMode_FreeMove]  = 0.7*Renderer3D.gStartThirdPersonDist, 
                [Renderer3D.kCamMode_Ego]       = 0.5*Renderer3D.gStartThirdPersonDist, 
                [Renderer3D.kCamMode_Third]     = 1.0*Renderer3D.gStartThirdPersonDist,
               }
Renderer3D.gCamLookAheadDist = Renderer3D.gCamLookAheadDistList[Renderer3D.gCamMode]

if (Renderer3D.gCamMode == Renderer3D.kCamMode_Ego) then Renderer3D.gfCamAngV = 0.0    Renderer3D.gfCamAngH = kPi end
if (Renderer3D.gCamMode == Renderer3D.kCamMode_Third) then Renderer3D.gfCamAngV = -0.5*Renderer3D.gfMaxCamAngVDelta end

Renderer3D.gbCamRotChanged = true

function Renderer3D:InitLocalCam(x,y,z)
    self.gCamMode = self.kCamMode_FreeMove
    GetMainCam():Move(x,y,z)
end

function Renderer3D:IsFirstPersonCam () return self.gCamMode == self.kCamMode_Ego end

function Renderer3D:CamModeAllowsBlendout () 
    if (self.gCamMode == self.kCamMode_Ego) then return false end
    if (self.gCamMode == self.kCamMode_FreeMove) then return false end
    return true
end

function Renderer3D:CamChangeZoom (add) 
    if (self.gCamMode ~= self.kCamMode_Third) then return end
    local factor = 1
    local base = 1.5
    if (add > 0) then factor = base end
    if (add < 0) then factor = 1.0 / base end
    
    gMinZoom = gMinZoom or 1
    gMaxZoom = gMaxZoom or 40
    local factor = math.max(gMinZoom,math.min(gMaxZoom,self.gThirdPersonDist * factor)) / self.gThirdPersonDist 
    self.gThirdPersonDist = self.gThirdPersonDist * factor
    self.gCamLookAheadDist = self.gCamLookAheadDist * factor
    self.gbCamRotChanged = true
end

-- targetmode can be nil, then the current mode is simply increased
function Renderer3D:ChangeCamMode (targetmode) 
    targetmode = targetmode or self.gCamMode + 1
    self.gCamMode = targetmode
    if (self.gCamMode > self.kCamMode_Max) then self.gCamMode = 0 end
    self.gThirdPersonDist = self.gStartThirdPersonDist
    self.gCamLookAheadDist = self.gCamLookAheadDistList[self.gCamMode]
    self.gbCamRotChanged = true
    if (self.gCamMode == self.kCamMode_Ego) then 
        GuiAddChatLine("CamMode:Ego") 
        self.gfCamAngV = 0.0 
        self.gfCamAngH = kPi - 0
    end
    if (self.gCamMode == self.kCamMode_Third) then 
        GuiAddChatLine("CamMode:ThirdPerson") 
        self.gfCamAngH = -3*0.25*kPi  -- default to original iso angle
        self.gfCamAngV = -0.25*kPi
        self:CamApplyAngHV()
    end
    if (self.gCamMode == self.kCamMode_FreeMove) then 
        GuiAddChatLine("CamMode:Free") 
    end
    
    self:BlendOutLayersAbovePlayer()
end

function Renderer3D:GetLookAheadCamPos ()
    local camx,camy,camz = GetMainCam():GetPos()
    camx = camx + self.gCamLookAheadX
    camy = camy + self.gCamLookAheadY
    return camx,camy,camz
end
        
function Renderer3D:CamStep()
    if (not self.gbActive) then return end
    
    if (Renderer3D.gbNeedCorrectAspectRatio) then self:CorrectAspectRatio() end
    
    local cam = GetMainCam()
    local iMouseX,iMouseY = GetMousePos()
    local vw,vh = GetViewportSize()
    local fPhysStepTime = Client_GetPhysStepTime()
    
    -- cam movement
    if (self.gCamMode == self.kCamMode_FreeMove) then
        -- free move by keys
        local speed = 20.0*fPhysStepTime
        local hispeed = 50*speed
        if (self.gCamKeyDown.Slow)      then speed = speed * 0.2 end
        if (self.gCamKeyDown.Fast)      then speed = speed * 10 end
        if (self.gCamKeyDown.Right)     then cam:Move(Quaternion.ApplyToVector( speed,0,0,self.gCamRotW,self.gCamRotX,self.gCamRotY,self.gCamRotZ)) end
        if (self.gCamKeyDown.Left)      then cam:Move(Quaternion.ApplyToVector(-speed,0,0,self.gCamRotW,self.gCamRotX,self.gCamRotY,self.gCamRotZ)) end
        if (self.gCamKeyDown.Back)      then cam:Move(Quaternion.ApplyToVector(0,0, speed,self.gCamRotW,self.gCamRotX,self.gCamRotY,self.gCamRotZ)) end
        if (self.gCamKeyDown.Forward)   then cam:Move(Quaternion.ApplyToVector(0,0,-speed,self.gCamRotW,self.gCamRotX,self.gCamRotY,self.gCamRotZ)) end
        if (self.gCamKeyDown.Up)        then cam:Move(Quaternion.ApplyToVector(0, speed,0,self.gCamRotW,self.gCamRotX,self.gCamRotY,self.gCamRotZ)) end
        if (self.gCamKeyDown.Down)      then cam:Move(Quaternion.ApplyToVector(0,-speed,0,self.gCamRotW,self.gCamRotX,self.gCamRotY,self.gCamRotZ)) end
            
        -- TODO : highspeed move : if (cInput::bKeys[cInput::kkey_l])   cam:Move( hispeed,0,0);
        -- TODO : highspeed move : if (cInput::bKeys[cInput::kkey_j])   cam:Move(-hispeed,0,0);
        -- TODO : highspeed move : if (cInput::bKeys[cInput::kkey_i])   cam:Move(0, hispeed,0);
        -- TODO : highspeed move : if (cInput::bKeys[cInput::kkey_k])   cam:Move(0,-hispeed,0);
    end
    
    
    local bMoveCamWithMouse = self.gCamMoveWithMouse or (gKeyPressed[key_mouse2] and self.gCamMode == self.kCamMode_Ego)
    
    -- cam mouse controll
    if (bMoveCamWithMouse and (not gui.bMouseBlocked)) then
        if (not self.gCamMoveWithMouse_OffX) then self.gCamMoveWithMouse_OffX,self.gCamMoveWithMouse_OffY = iMouseX,iMouseY end
        local relx = ((iMouseX - self.gCamMoveWithMouse_OffX) / (vw))*2.0
        local rely = ((iMouseY - self.gCamMoveWithMouse_OffY) / (vh))*2.0
        if (self.gbInvertMouseY) then rely = 1 - rely end
        local mspeed
        --constant or non-constant rotation for cam
        if (not gUseConstantCameraRotation) then
            self.gCamMoveWithMouse_OffX,self.gCamMoveWithMouse_OffY = iMouseX,iMouseY
            mspeed = self.gfMouseSensitivity
        else
            mspeed = self.gfMouseSensitivity*self.gfSensitivityMod
        end
        self.gfCamAngH = self.gfCamAngH - relx*mspeed
        self.gfCamAngV = self.gfCamAngV - rely*mspeed
        self.gbCamRotChanged = true
        if (self.gCamMode == self.kCamMode_Ego) then 
            gTileFreeWalk:SetViewDir(-math.sin(self.gfCamAngH),math.cos(self.gfCamAngH))
        end
    end 

    
    if (self.gCamMode == self.kCamMode_Ego) then
        -- ego view, cam in player, turning with him
        local x,y,z = gTileFreeWalk:GetExactLocalPos()
        if (x) then 
            cam:SetPos(x,y,z + (PlayerHasMount() and kFirstPersonZAdd_Mount or kFirstPersonZAdd_NoMount))
            --~ local curdir = GetPlayerDir()
            local dx,dy = gTileFreeWalk:GetViewDir()
            --~ local qw,qx,qy,qz = gTileFreeWalk:GetOrientation()
            
            -- turn cam with player
            self.gbCamRotChanged = true
            self.gfCamAngH = math.atan2(dy,dx) - math.pi*0.5
        end
    end
    
    -- cam rotate
    if (self.gbCamRotChanged) then
        self.gbCamRotChanged = false
        if (self.gfCamAngV < -self.gfMaxCamAngVDelta) then self.gfCamAngV = -self.gfMaxCamAngVDelta end
        if (self.gfCamAngV >  self.gfMaxCamAngVDelta) then self.gfCamAngV =  self.gfMaxCamAngVDelta end
        
        self:CamApplyAngHV()
    end
    
    local cam_zoff_3rdperson = 1.0
    
    -- cam movement dependant on cam rot
    if (self.gCamMode == self.kCamMode_Third) then
        -- cam centered around player
        local x,y,z = gTileFreeWalk:GetExactLocalPos()
        if (x) then 
            local ax,ay,az = Quaternion.ApplyToVector( 0,0,self.gThirdPersonDist,self.gCamRotW,self.gCamRotX,self.gCamRotY,self.gCamRotZ)
            cam:SetPos(ax+x,ay+y,az+z + cam_zoff_3rdperson)
        end
    end
    
    -- keep cam above ground
    local bKeepCamAboveGround = Renderer3D.gbBlendOutTerrainVisible
    if (bKeepCamAboveGround and not(gStartInDebugMode) and (self.gCamMode == self.kCamMode_Third)) then 
        local x,y,z = cam:GetPos()
        local xloc,yloc = Renderer3D:LocalToUOPos(x,y,z)
        local tiletype,ground_zloc = GetGroundAtAbsPos(xloc,yloc)
        if (ground_zloc) then
            local cam_minz = ground_zloc*0.1 + 0.3
            if (z <= cam_minz) then 
                cam:SetPos(x,y,cam_minz) 
                if (self.gCamMode == self.kCamMode_Third) then 
                    local lx,ly,lz = gTileFreeWalk:GetExactLocalPos()
                    if (lz) then
                        --~ local dx = hypot(x - lx,y - ly)
                        local dx = self.gThirdPersonDist
                        local dy = z - (lz + cam_zoff_3rdperson)
                        --~ print("3rdperson:",self.gfCamAngV,math.atan2(dy,dx),math.atan2(dx,dy),math.atan2(dy,dx) - math.pi*0.5,math.atan2(dx,dy) - math.pi*0.5)
                        self.gfCamAngV = math.atan2(dx,dy) - math.pi*0.5
                        self:CamApplyAngHV()
                        --~ > print(math.atan2(0,1)) 0
                        --~ > print(math.atan2(1,0)) 1.5707963267949
                    end
                end
            end
        end
    end
end

function Renderer3D:CamApplyAngHV()
    local w1,x1,y1,z1 = Quaternion.fromAngleAxis(gfDeg2Rad * 90.0,1,0,0)    
    local w2,x2,y2,z2 = Quaternion.fromAngleAxis(self.gfCamAngH,0,1,0)  
    local w3,x3,y3,z3 = Quaternion.fromAngleAxis(self.gfCamAngV,1,0,0)
    local w4,x4,y4,z4 = Quaternion.Mul(w1,x1,y1,z1, w2,x2,y2,z2)
    
    self.gCamRotW,self.gCamRotX,self.gCamRotY,self.gCamRotZ = Quaternion.Mul(w4,x4,y4,z4, w3,x3,y3,z3)
    GetMainCam():SetRot(self.gCamRotW,self.gCamRotX,self.gCamRotY,self.gCamRotZ)
    self.gCamLookAheadX,self.gCamLookAheadY = Quaternion.ApplyToVector( 0,0,-self.gCamLookAheadDist,self.gCamRotW,self.gCamRotX,self.gCamRotY,self.gCamRotZ)
end

-- can return floating point block position
function Renderer3D:GetCompassInfo()
    local ax,ay,az = GetMainCam():GetEulerAng()
    
    -- if in third person, center compass on player instead of on cam
    if (Renderer3D.gCamMode == Renderer3D.kCamMode_Third) then
        local x,y,z = gTileFreeWalk:GetExactLocalPos()
        local xloc,yloc,zloc = self:LocalToUOPos(x,y,z*10)
        --~ local xloc,yloc,zloc = GetPlayerPos()
        if (xloc) then return ax, xloc, yloc end
    end
        
    local camx,camy,camz = GetMainCam():GetPos()
    local iCamOverLocX = self.giMapOriginX*self.ROBMAP_CHUNK_SIZE*8 + camx
    local iCamOverLocY = self.giMapOriginY*self.ROBMAP_CHUNK_SIZE*8 + camy
    
    return ax, -iCamOverLocX, iCamOverLocY
end

--[[
	GetMainCam():SetPos(x,y,z)
	GetMainCam():SetRot(w,x,y,z)
		q(angle,axis)	Quaternion.fromAngleAxis(ang,x,y,z)    
		q*v				Quaternion.ApplyToVector (x,y,z,qw,qx,qy,qz)
		q*q				Quaternion.Mul (aw,ax,ay,az,bw,bx,by,bz) 
]]--

