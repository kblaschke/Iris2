--[[ ***** see Iris2 COPYING for license info ***** ]]--
--[[ \brief
		a group of uo tiles batched in one geometry + additional lights and stuff
]]--

cTileBatch = CreateClass()

-- forall entities fun(entity)
function cTileBatch:ForAllTiles (fun)
    if fun then
        for k,v in pairs(self.lStaticTiles or {}) do
            fun(v)
        end
    end
end

function cTileBatch:Init ()
    self.lStaticTiles = {}
    self.lToDestroy = {}
    self.mNextKey = 1
end

function cTileBatch:GetDisplayRange ()
    return self.fmin, self.fmax
end

function cTileBatch:SetDisplayRange (fmin, fmax)
    fmin = fmin or -10000
    fmax = fmax or 10000
    
    self.fmin = fmin
    self.fmax = fmax
    
    if self.gfx_static and self.gfx_static:IsAlive() then
        self.gfx_static:FastBatch_SetDisplayRange(fmin, fmax)
    end
    
    -- set billboard and other stuffs visibility
    self:ForAllTiles(function(t)
        if t.zloc then
            if t.gfx and t.gfx:IsAlive() then 
                t.gfx:SetVisible(fmin <= t.zloc and t.zloc <= fmax) 
            end
            if t.particle and t.particle:IsAlive() then 
                t.particle:SetVisible(fmin <= t.zloc and t.zloc <= fmax) 
            end
        end
    end)
end

function cTileBatch:Clear ()
    if (self.gfx_static) then self.gfx_static:Destroy() self.gfx_static = nil end
    if self.lStaticTiles then
        for k,v in pairs(self.lStaticTiles) do
            if v.gfx and v.gfx:IsAlive() then v.gfx:Destroy() v.gfx = nil end
            if v.particle and v.particle:IsAlive() then v.particle:Destroy() v.particle = nil end
            if v.lightname then Renderer3D:RemovePointLight(v.lightname) v.lightname = nil end          
            self.lStaticTiles[k] = nil
        end
    end
    
    self:DeleteQueuedStuff()
    
    self.mNextKey = 1
end

function cTileBatch:DeleteQueuedStuff   ()
    -- remove queued stuff
    for k,v in pairs(self.lToDestroy) do
        if v.gfx and v.gfx:IsAlive() then v.gfx:Destroy() end
        if v.lightname then Renderer3D:RemovePointLight(v.lightname) end
    end
end

function cTileBatch:RemoveTileByKey (k)
    local v = self.lStaticTiles[k]
    
    self.lStaticTiles[k] = nil
    
    -- queue stuff to delete at next build step
    if v.gfx then 
        table.insert(self.lToDestroy, {gfx=v.gfx})
    end
    if v.particle then 
        table.insert(self.lToDestroy, {gfx=v.particle})
    end
    if v.lightname then 
        table.insert(self.lToDestroy, {lightname=v.lightname})
    end
end

function cTileBatch:RemoveTile (iTileTypeID,iX,iY,iZ,iHue)
    for k,v in pairs(self.lStaticTiles) do
        local iTileTypeID2,iX2,iY2,iZ2,iHue2 = unpack(v.rawdata)
        if 
            iTileTypeID == iTileTypeID2 and
            iX2 == iX2 and
            iY2 == iY2 and
            iZ2 == iZ2 and
            iHue2 == iHue2
        then
            self:RemoveTileByKey(k)
        end
    end
end

function cTileBatch:PreloadTile (iTileTypeID,iX,iY,iZ,iHue)
    self:PreCreateStatic(iTileTypeID,iHue)
end

function cTileBatch:AddTile (iTileTypeID,iX,iY,iZ,iHue)
    local k = self.mNextKey
    self.mNextKey = self.mNextKey + 1
    
    self:PreCreateStatic(iTileTypeID,iHue)
    self.lStaticTiles[k] = {rawdata={iTileTypeID,iX,iY,iZ,iHue},bLoaded=false}
    
    return k
end

function cTileBatch:Build ()
    self:DeleteQueuedStuff()

    -- start fastbatch
    if not self.gfx_static then self.gfx_static = CreateRootGfx3D() end
    
    local gfx = self.gfx_static
    gfx:SetFastBatch()

    -- statics
    for k,v in pairs(self.lStaticTiles) do
        local iTileTypeID,iX,iY,iZ,iHue = unpack(v.rawdata)
        
        self:CreateStatic(v,gfx,iTileTypeID,iX,iY,iZ,iHue)
    end

    gfx:FastBatch_Build()
    gfx:SetCastShadows(gStaticsCastShadows)
    
    -- update display range
    if self.fmin and self.fmax then
        gfx:FastBatch_SetDisplayRange(self.fmin, self.fmax)
    end
end

-- handles the entity precalc
function cTileBatch:PreCreateStatic (iTileTypeID,iHue)
    local meshname = (not gForceFallBackBillboards_Statics) and GetMeshName(iTileTypeID,iHue)

    -- create Mesh
    if (meshname and meshname ~= false) then
        local meshbuffer = GetMeshBuffer(meshname) -- for mousepicking
    end
end

function cTileBatch:CalculateHash ()
    local s = ""
    for k,v in pairs(self.lStaticTiles) do
        s = s .. "-" .. v.rawdata[1] .. "-" .. v.rawdata[2] .. "-" .. v.rawdata[3] .. "-" .. v.rawdata[4] .. "-" .. v.rawdata[5]
    end
    if MD5FromString then return MD5FromString(s) else return "MD5FromString_missing" end
end

-- handles the entity creation
function cTileBatch:CreateStatic (entity,gfx,iTileTypeID,iXLoc,iYLoc,iZLoc,iHue)
    -- FILTER: correction
    entity.xadd,entity.yadd,entity.zadd = FilterPositionXYZ(iTileTypeID)

    entity.bLoaded = true
    entity.xloc = iXLoc + entity.xadd
    entity.yloc = iYLoc + entity.yadd
    entity.zloc = iZLoc + entity.zadd -- in tilecoords from uo

    entity.x,entity.y,entity.z = Renderer3D:UOPosToLocal(entity.xloc,entity.yloc,iZLoc * 0.1 + entity.zadd)
    
    entity.iBlockX = math.floor(entity.xloc / 8)
    entity.iBlockY = math.floor(entity.yloc / 8)

    entity.iTileTypeID = iTileTypeID
    entity.iHue = iHue
    
    local meshname = (not gForceFallBackBillboards_Statics) and GetMeshName(iTileTypeID,iHue)

    -- create Mesh
    if (meshname and meshname ~= false) then
        local qw,qx,qy,qz = GetStaticMeshOrientation(iTileTypeID)
        --~ mirroring now baked into meshes for shader compatibility -- local sx,sy,sz = -1,1,1 -- scale
        local sx,sy,sz = 1,1,1 -- scale
        entity.qw = qw
        entity.qx = qx
        entity.qy = qy
        entity.qz = qz
        entity.sx = sx
        entity.sy = sy
        entity.sz = sz

        local r,g,b,a = 1,1,1,1
        if (gHueLoader and entity.iHue > 0) then
            r,g,b = gHueLoader:GetColor(entity.iHue - 1,31) -- get first color
        end

        entity.meshbuffer = GetMeshBuffer(meshname) -- for mousepicking
        local orderval = entity.zloc -- used for blendout later (fastbatch feature)
        gfx:FastBatch_AddMeshBuffer(entity.meshbuffer, orderval ,entity.x,entity.y,entity.z, qw,qx,qy,qz, sx,sy,sz, r,g,b,a)

    -- if no *.mesh is available, a fallback billboard with original uo_art is generated
    -- What about caching here ??
    else
        local iTranslatedTileTypeID = SeasonalStaticTranslation(iTileTypeID, gSeasonSetting)
        if (
            (gEnableFallBackBillboards_Statics or 
            (gEnableFallBackGroundPlates and IsGroundPlate(iTranslatedTileTypeID))
            ) and not IsArtBillboardFallBackSkipped(iTranslatedTileTypeID)) 
        then
            entity.x,entity.y,entity.z = Renderer3D:UOPosToLocal(entity.xloc+0.5,entity.yloc+0.5,entity.zloc*0.1 + 0.5)
            entity.gfx = CreateRootGfx3D()
            entity.gfx:SetPosition(entity.x,entity.y,entity.z)
            -- we have to add 0x4000 for fallbacks
            Renderer3D:CreateArtBillBoard(entity.gfx,iTranslatedTileTypeID + 0x4000,entity.iHue)
            
            printdebug("missing",sprintf("Fallback: Static Billboard created : iTranslatedTileTypeID=%i\n", iTranslatedTileTypeID))
        end
    end

    -- generate Cadune Trees
    if gUseCaduneTree then
        Renderer3D:GenerateCaduneTree(entity)
    end
    
    -- adds a lightsource to Mesh-Tile
    -- note! lights don't cast shadows
    if (gLightsources) then
        local arrtiletype = GetStaticTileType(iTileTypeID)
        if( arrtiletype and TestBit(arrtiletype.miFlags or 0,kTileDataFlag_LightSource) ) then
            entity.lightname = Renderer3D:AddStandartUOPointLight(entity.x,entity.y,entity.z+arrtiletype.miHeight)
        end
    end

    -- adds particle Effect to Mesh-Tile
    entity.particle = Renderer3D:Hook_ItemAddParticle(iTileTypeID, entity.x,entity.y,entity.z)
end
