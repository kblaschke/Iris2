--[[ ***** see Iris2 COPYING for license info ***** ]]--
--[[ \brief
        blends out upper floors and items
]]--

kBlendOutPlayerHeight = 18  --eriminator: es galt grob, alles was 18z ueberm char war wuerd ausgeblendent

gProfiler_Blendout = CreateRoughProfiler("  Blendout") -- gEnableProfiler_Blendout

-- returns myLayer,bTerrainVisible
function CalcBlendOutZ ()
    gProfiler_Blendout:Start(gEnableProfiler_Blendout)
    gProfiler_Blendout:Section("start")
    local x,y,z = GetPlayerPos()
    
    local myLayer = nil
    local bTerrainVisible = true
    
    local playerIsInside = false
    local zloc_roof = nil -- becomes the minimum of the statics above the player
    local playerheadpos = z + kBlendOutPlayerHeight
    
    -- check ground
    gProfiler_Blendout:Section("ground")
    local iPlayerGroundZLoc = GetGroundZAtAbsPos(x,y) 
    if (iPlayerGroundZLoc and iPlayerGroundZLoc >= playerheadpos) then playerIsInside = true bTerrainVisible = false end
    
    -- check statics
    gProfiler_Blendout:Section("statics")
    if (not playerIsInside) then
        local l = MapGetStatics(x,y)
        
        for k,v in pairs(l) do
            if v.zloc >= playerheadpos then
                playerIsInside = true 
                if ((not zloc_roof) or (zloc_roof > v.zloc)) then zloc_roof = v.zloc end
            end
        end
    end

    -- check multis
    gProfiler_Blendout:Section("multis")
    if (not playerIsInside) then
        local xloc = x
        local yloc = y
        local n = xloc..","..yloc
        for multi,v in pairs(gMultis) do 
            local cache = multi.cache and multi.cache[n] -- see Multi_AddPartHelper 
            if (cache) then for k,item in pairs(cache) do 
                -- item = {iZ=zloc,iTileTypeID=iTileTypeID,xloc=xloc,yloc=yloc,zloc=zloc,artid=iTileTypeID,iHue=iHue}
                local iZ = item.zloc
                if iZ >= playerheadpos then
                    playerIsInside = true
                    if ((not zloc_roof) or (zloc_roof > iZ)) then zloc_roof = iZ end
                end
            end end
        end
    end

    -- check dynamics to detect dynamic houseroofs and other stuff above the head
    gProfiler_Blendout:Section("dynamics")
    if (not playerIsInside) then
        local iZ
        for k,dynamic in pairs(GetDynamicsAtPosition(x,y)) do
            if (dynamic.zloc >= playerheadpos) then
                playerIsInside = true
                iZ = dynamic.zloc
                if ((not zloc_roof) or (zloc_roof > iZ)) then zloc_roof = iZ end
            end
        end
    end
    gProfiler_Blendout:End()

    -- blend out layers above player head if inside
    --~ if (playerIsInside) then myLayer = zloc_roof or playerheadpos end
    if (playerIsInside) then 
        myLayer = playerheadpos 
        --~ if (zloc_roof) then myLayer = zloc_roof - 1 end
    end
    --~ print("blendout",playerIsInside,playerheadpos,zloc_roof)
    return myLayer,bTerrainVisible
end
