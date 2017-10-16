--[[ ***** see Iris2 COPYING for license info ***** ]]--
--[[ \brief
		Combat
]]--

Renderer3D.gCombatFadeDamageText = {}
Renderer3D.gCombatFadeDamageTextQueue = {}
Renderer3D.gCombatFadeDamageTextQueueNextPopTime = nil
Renderer3D.gCombatFadeDamageTextQueueNextPopTimeout = 250

-- creates a moving and disapearing damage text at the given tile position (x,y,z) (lifetime in sec, speed in ?)
function Renderer3D:CombatCreateDamageText (text, x, y, z, r, g, b, a, size, speed, lifetime)
    local o = {text = text, x = x, y = y, z = z}

    r = r or 1.0
    g = g or 0.0
    b = b or 0.0
    a = a or 0.8
    size = size or 0.50
    lifetime = lifetime or 1.5
    
    o.lifetime = lifetime
    o.speed = speed
    
    -- tile -> realpos
    x,y,z = self:UOPosToLocal(0.5 + x,0.5 + y,2.0 + z * 0.1)
    
    o.x = x
    o.y = y
    o.z = z
    o.size = size
    o.r = r
    o.g = g
    o.b = b
    o.a = a
    o.text = text
    
    o.gfx = CreateRootGfx3D()
    o.gfx:SetTextFont(gFontDefs["Default"].name)
    o.gfx:SetForceRotCam(GetMainCam())
    o.gfx:SetText(text, size, r, g, b, a)
    o.gfx:SetPosition(x,y,z)
    o.gfx:SetCastShadows(false)
    o.gfx:SetVisible(false)
                         
    table.insert(self.gCombatFadeDamageTextQueue,o)
end

-- helper to plop damage
function Renderer3D:NotifyDamage (serial, damage)
    local mobile = GetMobile(serial)
    if mobile and damage then
        local r,g,b,a = 1.0, 1.0, 0.0, 0.8
        local size = 0.50
        local speed = 0.1
        local lifetime = 2.5
        Renderer3D:CombatCreateDamageText(damage, mobile.xloc, mobile.yloc, mobile.zloc, r, g, b, a, size, speed, lifetime)
    end
end

-- helper to plop hp adds
function Renderer3D:NotifyHPChange (mobile, value)
    if mobile and value then
        local old = value
        if mobile.old_value_hp_change then old = mobile.old_value_hp_change end
        
        local r,g,b,a = 0.0, 0.0, 0.0, 0.8
        local size = 0.25
        local speed = 0.1
        local lifetime = 1.5

        -- hp change, d<0 means damage, d>0 hp gain
        local d = value - old
        mobile.old_value_hp_change  = value

        if (d == 0.0) then return end
        if (d < 0.0) then r = 1.0 else g = 1.0 end

        Renderer3D:CombatCreateDamageText(math.abs(d), mobile.xloc, mobile.yloc, mobile.zloc, r, g, b, a, size, speed, lifetime)
    end
end

-- helper to plop mana changes
function Renderer3D:NotifyManaChange (mobile, value)
    if gShow3DManaChanges and mobile and value then
        local old = value
        if mobile.old_value_mana_change then old = mobile.old_value_mana_change end
        
        local r,g,b,a = 0.0, 0.0, 1.0, 0.8
        local size = 0.15
        local speed = 0.1
        local lifetime = 1.5
        local d = value - old

        mobile.old_value_mana_change = value

        if (d == 0.0) then return end

        Renderer3D:CombatCreateDamageText(d, mobile.xloc, mobile.yloc, mobile.zloc, r, g, b, a, size, speed, lifetime)
    end
end

function Renderer3D:CombatGuiStep ()
    -- is the delay between the last one big enough?
    if 
        countarr(Renderer3D.gCombatFadeDamageTextQueue) > 0 and
        (
            not Renderer3D.gCombatFadeDamageTextQueueNextPopTime or 
            Renderer3D.gCombatFadeDamageTextQueueNextPopTime <= gMyTicks
        )
    then
        local o = table.remove(Renderer3D.gCombatFadeDamageTextQueue)
        o.starttime = gMyTicks
        o.deathtime = o.starttime + o.lifetime * 1000
        
        table.insert(self.gCombatFadeDamageText,o)
        o.gfx:SetVisible(true)
        
        Renderer3D.gCombatFadeDamageTextQueueNextPopTime = gMyTicks + Renderer3D.gCombatFadeDamageTextQueueNextPopTimeout
    end
    
    for k,o in pairs(self.gCombatFadeDamageText) do 
        -- move the text towards the sky :)
        local p = (gMyTicks - o.starttime) / (o.deathtime - o.starttime)
        local z = o.z + math.sqrt(p) * 3.0
        local size = o.size + math.sin(math.pi * p)
        
        o.gfx:SetText(o.text, size, o.r, o.g, o.b, o.a)
        o.gfx:SetPosition(o.x,o.y,z)
        
        if (gMyTicks > o.deathtime) then
            -- remove the text
            o.gfx:Destroy()
            self.gCombatFadeDamageText[k] = nil
        end
    end
end
