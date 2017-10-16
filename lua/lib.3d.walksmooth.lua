--[[ ***** see Iris2 COPYING for license info ***** ]]--
--[[ \brief
		handles walk smoothing
		(see also lib.granny.lua, lib.bodygfx.lua, lib.tilefreewalk.lua, net.walk.lua)
]]--

-- called from Renderer3D:UpdateMobile, not every frame
function Renderer3D:WalkSmoothUpdate (mobile)
    -- handles  walksmooth to detect run, turn etc efficiently
    
    -- walksmooth
    if (mobile.xloc ~= mobile.gfx3d_walksmooth_last_xloc or
        mobile.yloc ~= mobile.gfx3d_walksmooth_last_yloc or
        mobile.zloc ~= mobile.gfx3d_walksmooth_last_zloc or
        mobile.dir  ~= mobile.gfx3d_walksmooth_last_dir) then 
        
        mobile.gfx3d_walksmooth_prelast_xloc = mobile.gfx3d_walksmooth_last_xloc
        mobile.gfx3d_walksmooth_prelast_yloc = mobile.gfx3d_walksmooth_last_yloc
        mobile.gfx3d_walksmooth_prelast_zloc = mobile.gfx3d_walksmooth_last_zloc
        mobile.gfx3d_walksmooth_prelast_dir  = mobile.gfx3d_walksmooth_last_dir
        mobile.gfx3d_walksmooth_prelast_time = mobile.gfx3d_walksmooth_last_time
        
        mobile.gfx3d_walksmooth_last_xloc = mobile.xloc
        mobile.gfx3d_walksmooth_last_yloc = mobile.yloc
        mobile.gfx3d_walksmooth_last_zloc = mobile.zloc
        mobile.gfx3d_walksmooth_last_dir  = mobile.dir 
        mobile.gfx3d_walksmooth_last_time = gMyTicks
        local timediff = mobile.gfx3d_walksmooth_last_time - (mobile.gfx3d_walksmooth_prelast_time or 0)
        --GuiAddChatLine("walksmooth"..":"..timediff..","..mobile.xloc..","..mobile.yloc..","..sprintf("0x%02x",mobile.dir))
    end
    
end

function Renderer3D:WalkSmoothStep (mobile)
    if (IsPlayerMobile(mobile)) then return end
    mobile.walksmooth_moving = false
    mobile.walksmooth_turning = false
    if (not mobile.gfx3d_walksmooth_last_time) then return end
    if (not mobile.gfx3d_walksmooth_prelast_time) then self:SetSimpleMobilePos(mobile) return end
    if (gDisableSmoothWalk) then self:SetSimpleMobilePos(mobile) return end
    
    local xloc1 = mobile.gfx3d_walksmooth_prelast_xloc
    local yloc1 = mobile.gfx3d_walksmooth_prelast_yloc
    local zloc1 = mobile.gfx3d_walksmooth_prelast_zloc
    local dir1  = mobile.gfx3d_walksmooth_prelast_dir
    local xloc2 = mobile.gfx3d_walksmooth_last_xloc
    local yloc2 = mobile.gfx3d_walksmooth_last_yloc
    local zloc2 = mobile.gfx3d_walksmooth_last_zloc
    local dir2  = mobile.gfx3d_walksmooth_last_dir
    local bRunning = TestBit(dir2,kWalkFlag_Run)
    dir1 = BitwiseAND(dir1,hex2num("0x07"))
    dir2 = BitwiseAND(dir2,hex2num("0x07"))
    
    mobile.walksmooth_moving = (xloc1 ~= xloc2) or (yloc1 ~= yloc2) or (zloc1 ~= zloc2) 
    mobile.walksmooth_turning = (dir1 ~= dir2)

    -- optimal motiontime
    --local myturntime = gWalkTimeout_DirectionChange
    local myturntime = gWalkTimeout_MovingSpeed -- take slow turn
    local motiontime_opt = bRunning and gWalkTimeout_RunningSpeed or gWalkTimeout_MovingSpeed
    if (mobile.walksmooth_turning and (not mobile.walksmooth_moving)) then motiontime_opt = myturntime end
    
    -- last real motiontime
    local motiontime_last = mobile.gfx3d_walksmooth_last_time - mobile.gfx3d_walksmooth_prelast_time
    
    -- leave a little tolerance for last real motion time
    local tolerance = 30
    local motiontime = motiontime_last
    if (motiontime < motiontime_opt - tolerance) then motiontime = motiontime_opt - tolerance end
    if (motiontime > motiontime_opt + tolerance) then motiontime = motiontime_opt + tolerance end
    
    local factor = (gMyTicks - mobile.gfx3d_walksmooth_last_time) / motiontime
    if (factor > 1) then 
        factor = 1 
        -- move finished
        mobile.walksmooth_moving = false
        mobile.walksmooth_turning = false
    end
    local rfactor = 1.0 - factor
    
    --if (factor < 1) then print("WalkSmoothStep",mobile.walksmooth_turning,mobile.walksmooth_moving,motiontime,motiontime_last,motiontime_opt) end

    local dirdiff = dir2 - dir1
    while (dirdiff >= 4) do dirdiff = dirdiff - 8 end
    while (dirdiff <= -4) do dirdiff = dirdiff + 8 end
    
    local xloc = rfactor * xloc1 + factor * xloc2
    local yloc = rfactor * yloc1 + factor * yloc2
    local zloc = rfactor * zloc1 + factor * zloc2
    local dir  = dir1 + factor * dirdiff
    
    local x,y,z = Renderer3D:UOPosToLocal(xloc,yloc,zloc * 0.1)
    mobile.exactxloc = xloc
    mobile.exactyloc = yloc
    mobile.exactzloc = zloc
    local ang_in_degrees = (dir + 0) * 45.0
    local qw,qx,qy,qz = Quaternion.fromAngleAxis(- gfDeg2Rad * ang_in_degrees,0,0,1)
    Renderer3D:UpdateMobilePos(mobile,x,y,z,qw,qx,qy,qz)
end

function Renderer3D:NotifyPlayerTeleported ()
    local playermobile = GetPlayerMobile() 
    if (not playermobile) then return end
    gTileFreeWalk:NotifyPlayerMobileTeleport(playermobile)
    self:WalkSmoothReset(playermobile)
	self:BlendOutLayersAbovePlayer()
end

-- used when teleported
function Renderer3D:WalkSmoothReset (mobile)
    if (not mobile) then return end
    mobile.gfx3d_walksmooth_prelast_xloc = nil
    mobile.gfx3d_walksmooth_prelast_yloc = nil
    mobile.gfx3d_walksmooth_prelast_zloc = nil
    mobile.gfx3d_walksmooth_prelast_dir  = nil
    mobile.gfx3d_walksmooth_prelast_time = nil
    
    mobile.gfx3d_walksmooth_last_xloc = nil
    mobile.gfx3d_walksmooth_last_yloc = nil
    mobile.gfx3d_walksmooth_last_zloc = nil
    mobile.gfx3d_walksmooth_last_dir  = nil
    mobile.gfx3d_walksmooth_last_time = nil
end

function Renderer3D:SetSimpleMobilePos (mobile)
    local x,y,z = Renderer3D:UOPosToLocal(mobile.xloc,mobile.yloc,mobile.zloc * 0.1)
    local ang_in_degrees = (mobile.dir + 0) * 45.0
    local qw,qx,qy,qz = Quaternion.fromAngleAxis(- gfDeg2Rad * ang_in_degrees,0,0,1)
    Renderer3D:UpdateMobilePos(mobile,x,y,z,qw,qx,qy,qz)
end
