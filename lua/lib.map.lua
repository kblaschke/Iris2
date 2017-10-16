--[[ ***** see Iris2 COPYING for license info ***** ]]--
--[[ \brief
        caching and filters/season-trans for ground and static infos
        for walk,render,macro,...
]]--

gMapCacheBlocks = {}
kMapCacheBlocks_MaxSqDist = 16*16

-- returns tiletype,zloc
-- TODO : obsolete me ? use GetGroundAtAbsPos or MapGetGround instead ?
-- returns iTerrainTileType,iTerrainZ
function GetAbsTile (xloc,yloc) 
    --~ return gGroundBlockLoader:GetTile2(xloc,yloc)
    local o = MapGetGround(xloc,yloc)
    return o.iTileType, o.zloc
end

-- TODO : obsolete : lua/lib.3d.map.lua:432:    tiletype,z = gGroundBlockLoader:GetTile(iBlockUO_X+bx,iBlockUO_Y+by,lx,ly)
-- TODO : obsolete : lua/lib.walking2.lua:125:  local iMapTileType = gGroundBlockLoader:GetTile(bx,by,tx,ty)
-- TODO : obsolete : gStaticBlockLoader in lib.3d.map.lua  and lib.walking2.lua

-- {iTileType=?,zloc=?,bIgnoredByWalk=?,flags=?}
function MapGetGround       (xloc,yloc) return MapGetCacheBlock(math.floor(xloc/8),math.floor(yloc/8)).ground[       (math.floor(yloc) % 8)*10 + (math.floor(xloc) % 8)] end

-- {{zloc=?,artid=?,hue=?,xloc=?,yloc=?,tx=?,ty=?,bx=?,by=?,bIsStatic=true},...} -- xloc,yloc absolute
function MapGetStatics      (xloc,yloc) return MapGetCacheBlock(math.floor(xloc/8),math.floor(yloc/8)).statics_bypos[(math.floor(yloc) % 8)*10 + (math.floor(xloc) % 8)] end 
function MapGetBlockStatics (bx,by)     return MapGetCacheBlock(bx,by).statics_all end 

-- returns tiletype,z       xloc,yloc in absolute tilecoords
function GetGroundAtAbsPos (xloc,yloc) local g = MapGetGround(xloc,yloc) if (g) then return g.iTileType,g.zloc end end
function GetGroundZAtAbsPos (xloc,yloc) local g = MapGetGround(xloc,yloc) if (g) then return g.zloc end end

-- returns an array,  {{artid=?,zloc=?,hue=?},...}
function GetStaticsAtAbsPos (xloc,yloc) return MapGetStatics(xloc,yloc) end

function MapGetMapIndex     ()  return gMapIndex end
function MapGetWInBlocks    ()  return gGroundBlockLoader:GetMapW() end
function MapGetHInBlocks    ()  return gGroundBlockLoader:GetMapH() end
function MapGetWInTiles     ()  return gGroundBlockLoader:GetMapW() * 8 end
function MapGetHInTiles     ()  return gGroundBlockLoader:GetMapH() * 8 end

-- ***** ***** ***** ***** ***** caching

-- triggered on mapchange etc
function MapClearCache () gMapCacheBlocks = {} end

function MapGetCacheBlock (bx,by)
    local n = bx..","..by
    local b = gMapCacheBlocks[n]
    if (b) then return b end
    
    -- create new cacheblock
    b = { bx=bx,by=by }
    gMapCacheBlocks[n] = b
    
    -- erase blocks outside maxdist
    for k,v in pairs(gMapCacheBlocks) do
        if (sqdist2(v.bx,v.by,bx,by) > kMapCacheBlocks_MaxSqDist) then
            gMapCacheBlocks[k] = nil -- erase block from cache
        end
    end
    
    -- statics
    b.statics_all = {}
    b.statics_bypos = {}
    if (gStaticBlockLoader) then gStaticBlockLoader:Load(bx,by) end -- following gStaticBlockLoader commands operate on this loaded block
    local iStaticCount = gStaticBlockLoader and gStaticBlockLoader:Count() or 0
    for ty = 0,7 do
    for tx = 0,7 do
        b.statics_bypos[ty*10 + tx] = {}
    end
    end
    if (gStaticBlockLoader) then
        for i = 0,iStaticCount-1 do
            local iTileTypeID,tx,ty,iZ,iHue = gStaticBlockLoader:GetStatic(i) 
			--~ assert(tx >= 0 and tx < 8,"tx"..tostring(tx))
			--~ assert(ty >= 0 and ty < 8,"ty"..tostring(ty))
            local static = {zloc=iZ,artid=iTileTypeID,hue=iHue,tx=tx,ty=ty,xloc=tx+bx*8,yloc=ty+by*8,bx=bx,by=by,iBlockIndex=i,fBlockIndexRel=i/iStaticCount,bIsStatic=true}
            table.insert(b.statics_bypos[ty*10 + tx],static)
            table.insert(b.statics_all,static)
        end
    end
    
    -- ground
    b.ground = {}
    if (gGroundBlockLoader) then
    for ty = 0,7 do
    for tx = 0,7 do
        local iTileType,zloc = gGroundBlockLoader:GetTile(bx,by,tx,ty)  -- TODO : season translation ??? iTranstile 
        if (not iTileType) then iTileType,zloc = 0,0 end
        -- RunUO1.0/src/TileMatrix.cs:600: public bool Ignored
        local bIgnoredByWalk = iTileType == 2 or iTileType == 0x1DB or ( iTileType >= 0x1AE and iTileType <= 0x1B5 )
		local tt = GetGroundTileType(iTileType)
        b.ground[ty*10 + tx] = {iTileType=iTileType,zloc=zloc,bIgnoredByWalk=bIgnoredByWalk,flags=tt and tt.miFlags or 0}
    end
    end
    end
    
    return b
end
