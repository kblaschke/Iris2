--[[ ***** see Iris2 COPYING for license info ***** ]]--
--[[ \brief
		3d effects
]]--

StandardEffect = 0
PoisonField         = hex2num("0x3914")
FlameStrike         = hex2num("0x3709")
Explosion           = hex2num("0x36bd")
ConsecrateWeapon1   = hex2num("0x3779")
MindRot             = hex2num("0x373A")
PainSpike           = hex2num("0x37C4") -- needs rework
PoisonStrike        = hex2num("0x36B0")
StranglePart1       = hex2num("0x36CB")
StranglePart2       = hex2num("0x374A")
ParalyzeField       = hex2num("0x0001") -- ???
FireField           = hex2num("0x0002") -- ???
ConsecrateWeapon2   = hex2num("0x251D") -- ???
Wither              = hex2num("0x37CC")
Teleport            = hex2num("0x3728")
Fizzels             = hex2num("0x3735") 
Fireball            = hex2num("0x36d4")
MagicArrow          = hex2num("0x36e4")
EBolt               = hex2num("0x379f")
Sparkle             = hex2num("0x376A") -- Third/Teleport,Spellweaving/GiftOfRenewal,Spellweaving/GiftOfLife,Ninjitsu/MirrorImage,Bushido/Evasion,Chivalry/NobleSacrifice,Chivalry/CloseWounds,Chivalry
SparkleCross        = hex2num("0x373a") -- Third/Bless,Fifth/Incognito,Bushido/HonorableExecution,Chivalry/CleanseByFire,Necromancy/VengefulSpirit,Necromancy/CorpseSkin,Necromancy/MindRot,Fourth
SparkleSpiral       = hex2num("0x375a") -- Fifth/MagicReflect,Fifth/MagicReflect,Fifth/MagicReflect,Bushido/Confidence,Chivalry/EnemyOfOne,Chivalry/NobleSacrifice,Chivalry/NobleSacrifice,Necromancy

-- effects can have a ttl (time-to-live, effect.ttl in milliseconds, default is gParticleEffectDefaultTTL in ms)
gParticleEffectDefaultTTL = 10 * 1000
-- time that an effect needs to move from source to destination inseconds
gParticleEffectDefaultMoveDuration = 0.5
gParticleEffects = {}
gParticleEffects[Fireball]      = { etype=0, name="Large Fireball"          , relx=0.5, rely=0.5, relz=1, scalex=1, scaley=1, scalez=1}
gParticleEffects[MagicArrow]    = { etype=2, name="Magic Arrow"             , relx=0.5, rely=0.5, relz=1, scalex=1, scaley=1, scalez=1}
gParticleEffects[EBolt]         = { etype=2, name="EBolt"                   , relx=0.5, rely=0.5, relz=1, scalex=1, scaley=1, scalez=1}
gParticleEffects[StandardEffect]= { etype=0, name="bluering"                , relx=0.5, rely=0.5, relz=0.1, scalex=1, scaley=1, scalez=1 }
gParticleEffects[ParalyzeField] = { etype=2, name="ParalyzeField"           , relx=0.5, rely=0.5, relz=1, scalex=0.2, scaley=0.2, scalez=0.2}
gParticleEffects[PoisonField]   = { etype=2, name="PoisonField"             , relx=0.5, rely=0.5, relz=1, scalex=0.2, scaley=0.2, scalez=0.2}
gParticleEffects[FireField]     = { etype=2, name="FireField"               , relx=0.5, rely=0.5, relz=0.5, scalex=0.4, scaley=0.4, scalez=0.1}
gParticleEffects[Teleport]      = { etype=2, name="Teleport"                , relx=0.5, rely=0.5, relz=1, scalex=0.2, scaley=0.2, scalez=0.2}
gParticleEffects[Explosion]     = { etype=0, name="Explosion"               , relx=0.5, rely=0.5, relz=1, scalex=0.2, scaley=0.2, scalez=0.2}
gParticleEffects[ConsecrateWeapon1]= { etype=3, name="ConsecrateWeapon1"    , relx=0.5, rely=0.5, relz=3, scalex=0.2, scaley=0.2, scalez=0.1}
gParticleEffects[ConsecrateWeapon2]= { etype=0, name="ConsecrateWeapon2"    , relx=0.5, rely=0.5, relz=3, scalex=0.2, scaley=0.2, scalez=0.1}
--~ gParticleEffects[FancySpiral]       = { etype=3, name="MindRot"                 , relx=0.5, rely=0.5, relz=3, scalex=1, scaley=1, scalez=1}
gParticleEffects[PainSpike]     = { etype=3, name="PainSpike"               , relx=0.5, rely=0.5, relz=3, scalex=1, scaley=1, scalez=1}
gParticleEffects[PoisonStrike]  = { etype=3, name="PoisonStrike"            , relx=0.5, rely=0.5, relz=3, scalex=1, scaley=1, scalez=1}
gParticleEffects[StranglePart1] = { etype=3, name="StranglePart1"           , relx=0.5, rely=0.5, relz=3, scalex=1, scaley=1, scalez=1}
gParticleEffects[StranglePart2] = { etype=3, name="StranglePart2"           , relx=0.5, rely=0.5, relz=3, scalex=1, scaley=1, scalez=1}
gParticleEffects[Wither]        = { etype=3, name="Wither"                  , relx=0.5, rely=0.5, relz=3, scalex=1, scaley=1, scalez=1}
gParticleEffects[FlameStrike]   = { etype=3, name="FlameStrike"             , relx=0.5, rely=0.5, relz=0.1, scalex=1, scaley=1, scalez=1}
gParticleEffects[Sparkle]       = { etype=3, name="Healing"                 , relx=0.5, rely=0.5, relz=0.1, scalex=1, scaley=1, scalez=1}
gParticleEffects[SparkleCross]  = { etype=3, name="Healing"                 , relx=0.5, rely=0.5, relz=0.1, scalex=1, scaley=1, scalez=1}
gParticleEffects[SparkleSpiral] = { etype=3, name="Healing"                 , relx=0.5, rely=0.5, relz=0.1, scalex=1, scaley=1, scalez=1}

-- Manages particle effects, esp. huedfx, decide between effecttypes
function Renderer3D:AddEffect( effect )
    local workingeffect = nil

    if effect.effect_type == kEffectType_LightningStrikeAtSource then
        workingeffect = Renderer3D:AddLightningEffect( effect )
    elseif (gParticleEffects[effect.itemid]) then
        workingeffect = Renderer3D:AddParticleEffect( effect, gParticleEffects[effect.itemid].name,
                                gParticleEffects[effect.itemid].relx, gParticleEffects[effect.itemid].rely, gParticleEffects[effect.itemid].relz,
                                gParticleEffects[effect.itemid].scalex, gParticleEffects[effect.itemid].scaley, gParticleEffects[effect.itemid].scalez)
    elseif ( effect.huedeffect ) then
        workingeffect = Renderer3D:AddHuedMeshEffect( effect, 1, 0, 0 )
    end

    -- if it's no huedeffect or no particle effect is defined, use a standard particle effect
    if (workingeffect == nil) then
        Renderer3D:AddParticleEffect( effect, gParticleEffects[StandardEffect].name,
                                gParticleEffects[StandardEffect].relx, gParticleEffects[StandardEffect].rely, gParticleEffects[StandardEffect].relz,
                                gParticleEffects[StandardEffect].scalex, gParticleEffects[StandardEffect].scaley, gParticleEffects[StandardEffect].scalez)
    end
end

-- TODO
function Renderer3D:AddLightningEffect  (effect)
    return false
end

function Renderer3D:ParticleEffectHelper    (effect, relx, rely, relz)
    local effectdata = effect
    local mob_source = GetMobile(effectdata.sourceserial)
    if mob_source then effectdata.current_locx,effectdata.current_locy,effectdata.current_locz = mob_source.xloc,mob_source.yloc,mob_source.zloc end
    local mob_target = GetMobile(effectdata.targetserial)
    if mob_target then effectdata.target_locx,effectdata.target_locy,effectdata.target_locz = mob_target.xloc,mob_target.yloc,mob_target.zloc end
    
    local sx,sy,sz = self:UOPosToLocal(effect.current_locx + relx,effect.current_locy + rely,effect.current_locz * 0.1 + relz)
    local dx,dy,dz = self:UOPosToLocal(effect.target_locx + relx,effect.target_locy + rely,effect.target_locz * 0.1 + relz)

    effect.gfx:SetPosition(sx,sy,sz)

    InvokeLater(effect.ttl or gParticleEffectDefaultTTL, function ()
        -- destroy effect after timeout
        printdebug("effect","destroy effect")
        if effect and effect.gfx:IsAlive() then
            effect.gfx:Destroy()
            effect = nil
        end
    end)
    
    printdebug("effect",vardump(effect))

    if effect.effect_type == kEffectType_FromSourceToDest then
        local t = gParticleEffectDefaultMoveDuration
        local startt = gMyTicks
    
        --~ ...SetPath(totaltime,looped,linear,{t,{p={x,y,z},s={x,y,z},r={w,x,y,z}}, ...})   
        effect.gfx:SetPath(t,false,true,{0,{p={sx,sy,sz}},t,{p={dx,dy,dz}}})
        
        -- TODO : update target pos 
        -- add stepper to handle effect movement
        RegisterStepper(function()
            if not effect or not effect.gfx:IsAlive() then
                -- i am dead so stop this
                return true
            end
            
            effect.gfx:SetPathAnimTimePos((gMyTicks-startt) / 1000)
        end)
    elseif effect.effect_type == kEffectType_FollowSource then
        -- add stepper to handle effect movement
        
        local m = GetMobile(effect.sourceserial)
        if (m) then 
            local dx,dy,dz = self:UOPosToLocal(m.xloc + relx,m.yloc + rely,m.zloc * 0.1 + relz)
            local px,py,pz = self:UOPosToLocal(effect.current_locx + relx,effect.current_locy + rely,effect.current_locz * 0.1 + relz)
            
            RegisterStepper(function()
                if not effect or not effect.gfx:IsAlive() then
                    -- i am dead so stop this
                    return true
                end
                
                local m = GetMobile(effect.sourceserial)
                if m then
                    local dx,dy,dz = self:UOPosToLocal(m.xloc + relx,m.yloc + rely,m.zloc * 0.1 + relz)
                    effect.gfx:SetPosition(dx,dy,dz)
                end
            end)
        end
    end
    
    return true
end

-- Hued Effect : to display Meshes as instant Effects
function Renderer3D:AddHuedMeshEffect( effect, relx, rely, relz )
    local meshname = GetMeshName(effect.itemid,effect.hue)

    printdebug("effect",sprintf("Create ParticleEffect with Meshname=%s ParticleID=0x%04x.\n",meshname or "false",effect.itemid) )

    if (meshname and meshname ~= false) then
        effect.gfx = CreateRootGfx3D()
        effect.gfx:SetMesh(meshname)
        effect.gfx:SetOrientation(GetStaticMeshOrientation(effect.itemid))
        effect.gfx:SetNormaliseNormals(true)
        effect.gfx:SetCastShadows(gDynamicsCastShadows)

        -- primary color hueing
        if gHueLoader and effect.hue > 0 then
            local r,g,b = gHueLoader:GetColor(effect.hue - 1,31) -- get first color
            HueMeshEntity(effect.gfx,r,g,b,r,g,b)
        end
        effect.gfx:SetRenderingDistance(self.gDynamicMaxRenderDist)

        -- position adjustment for statics and dynamics
        effect.xadd,effect.yadd,effect.zadd = FilterPositionXYZ(effect.itemid)

        return self:ParticleEffectHelper(effect, relx+effect.xadd, rely+effect.yadd, relz+effect.zadd)
    end
end

-- Particle Effect : to display Particles as instant Effects
function Renderer3D:AddParticleEffect( effect, particlename, relx, rely, relz, scalex, scaley, scalez)
    printdebug("effect",sprintf("Create ParticleEffect with Particlename=%s ParticleID=0x%04x.\n",particlename,effect.itemid) )

    effect.gfx=CreateRootGfx3D()
    effect.gfx:SetParticleSystem(particlename)
    effect.gfx:SetRenderingDistance(self.gDynamicMaxRenderDist)
    effect.gfx:SetScale( scalex or 1, scaley or 1, scalez or 1)
    effect.gfx:SetNormaliseNormals(true)

    return self:ParticleEffectHelper(effect, relx, rely, relz)
end

-- hook to add artid based particle effects
function Renderer3D:Hook_ItemAddParticle (artid, x, y, z)
    -- moongate
    if artid == 3948 or artid == 8148 then
        local gfx = CreateRootGfx3D()
        gfx:SetParticleSystem("Moongate")
        gfx:SetPosition(x-0.5,y+0.5,z+1.5)
        gfx:SetRenderingDistance(self.gDynamicMaxRenderDist)
        gfx:SetScale( 1, 1, 1)
        gfx:SetNormaliseNormals(true)
        return gfx
    end
    return nil
end

--###############################
--###       Tracking ARROW    ###
--###############################
Renderer3D.gTrackingArrow = nil
function Renderer3D:UpdateTrackingArrow( active, x, y )
    if (active==1) then
        if (not self.gTrackingArrow) then
            self.gTrackingArrow = CreateRootGfx3D()
            self.gTrackingArrow:SetSimpleRenderable()
            self.gTrackingArrow:SetMaterial("tracking_arrow")
        end

        local nx,ny,nz = 0,0,1
        local r,g,b = 1.0,1.0,0.0

        local iTileType,iZLoc = GetAbsTile(x,y)

        local a = 0.6
        local e = 0.3

        self.gTrackingArrow:RenderableBegin(4,6,false,false,OT_TRIANGLE_LIST)
        self.gTrackingArrow:RenderableVertex(-e,-e,0, nx,ny,nz, 0,0, r,g,b,a)
        self.gTrackingArrow:RenderableVertex( e,-e,0, nx,ny,nz, 1,0, r,g,b,a)
        self.gTrackingArrow:RenderableVertex(-e, e,0, nx,ny,nz, 0,1, r,g,b,a)
        self.gTrackingArrow:RenderableVertex( e, e,0, nx,ny,nz, 1,1, r,g,b,a)
        self.gTrackingArrow:RenderableIndex3(0,1,2)
        self.gTrackingArrow:RenderableIndex3(1,3,2)
        self.gTrackingArrow:RenderableEnd()
        self.gTrackingArrow:SetForceRotCam(GetMainCam())
        self.gTrackingArrow:SetPosition( self:UOPosToLocal(0.5 + x,0.5 + y,0.1 + ( iZLoc+30) * 0.1) )
    else
        if (self.gTrackingArrow) then
            self.gTrackingArrow:Destroy()
            self.gTrackingArrow=nil
        end
    end
end
