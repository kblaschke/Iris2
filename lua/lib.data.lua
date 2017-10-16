--[[ ***** see Iris2 COPYING for license info ***** ]]--
--[[ \brief
        handles tiledata and some other datafiles
        TODO: should be cleaned from obsolete functions !
]]--

-- nil if not wearable
function GetPaperdollLayerFromTileType (iTileTypeID)
    local t = GetStaticTileType(iTileTypeID)
    if (t and TestBit(t.miFlags,kTileDataFlag_Wearable)) then 
        return t.miQuality
    end
    return nil
end

function GetStaticTileTypeName (iTileTypeID) 
    local t = GetStaticTileType(iTileTypeID)
    return t and t.msName
end

function GetStaticTileTypeFlags (iTileTypeID) 
    local t = GetStaticTileType(iTileTypeID)
    return t and t.miFlags
end

-- many thanks to varan for his 2d renderer code for this =)
-- dynamic,nonmulti : +1     effect=8 mobile=7
function GetStaticFlagSortBonus2D (flags)
    local bBackGround   = TestBit(flags,kTileDataFlag_Background)
    local bSurface      = TestBit(flags,kTileDataFlag_Surface)
    if bBackGround and bSurface then return 2 end
    if bBackGround              then return 3 end
    if bSurface                 then return 4 end
    return 6
end

-- info on statics, dynamics, items in containers, wearables etc  (everything except terrain)
gStaticTileTypeCache = {}
function GetStaticTileType (iTileTypeID)
    if (not gTileTypeLoader) then return end
    local t = gStaticTileTypeCache[iTileTypeID] 
    if (t ~= nil) then return t end -- already in cache
    
    -- not yet in cache, readout
    t = {}
    t.miFlags,t.miWeight,t.miQuality,t.miUnknown,
    t.miUnknown1,t.miQuantity,t.miAnimID,t.miUnknown2,
    t.miHue,t.miUnknown3,t.miHeight,t.msName = 
        gTileTypeLoader:GetStaticTileType(iTileTypeID+32*512) -- add 0x00004000, below are groundtypes
    if (t.miFlags == nil) then 
        t = false 
    else
        -- precalc a bit for faster access (mainly for walk code performance)
        
        local flags = t.miFlags
        t.bBridge       = TestBit(flags,kTileDataFlag_Bridge)
        t.bBackGround   = TestBit(flags,kTileDataFlag_Background)
        t.bSurface      = TestBit(flags,kTileDataFlag_Surface)
        
        --~ RunUO1/src/TileData.cs:153: public int CalcHeight : 
        t.iCalcHeight = t.bBridge and math.floor(t.miHeight / 2) or t.miHeight
        
        t.iSortBonus2D = GetStaticFlagSortBonus2D(flags)
    end
    gStaticTileTypeCache[iTileTypeID] = t
    return t
end

gGroundTileTypeCache = {}
function GetGroundTileType (iTileTypeID)
    if (not gTileTypeLoader) then return end
    local t = gGroundTileTypeCache[iTileTypeID] 
    if (t ~= nil) then return t end -- already in cache
    
    -- not yet in cache, readout
    t = {}
    t.miFlags,t.miTexID,t.msName = gTileTypeLoader:GetGroundTileType(iTileTypeID) -- below 0x00004000
    if (t.miFlags == nil) then 
        t = false 
    else
        -- precalc a bit for faster access (mainly for walk code performance)
        
    end
    gGroundTileTypeCache[iTileTypeID] = t
    return t
end

-- art bitmask loader with caching
gArtBitMaskCache = {}
function GetArtBitMask (iArtID)
    local res = gArtBitMaskCache[iArtID]
    if (not res and gArtMapLoader) then
        res = gArtMapLoader:CreateBitMask(iArtID)
        gArtBitMaskCache[iArtID] = res
    end
    return res
end

function SaveUOModelImageToFile(rtt,texname)
    if (rtt) then rtt:WriteContentsToFile("t"..texname..".bmp") end
end

-- art material loader with caching
-- if someone what to view runned tiles (static tiles) he has to add (iArtID + 0x4000)
gArtMatCache = {}
-- New GetArtMat with RTT support
function GetArtMat (iArtID,iHue)
    if (not(iHue) or (tonumber(iHue) > gMaxHueValue)) then iHue=0 end

    local res = gArtMatCache[iArtID.."_"..iHue]
    if (not res) then
        res = {}
        local w,h = 32,32       -- initial fallback art image size

        -- check if RTT generated Art Tiles is enabled and try to generate a RTT Tile out of an *.mesh
        if (gEnableRTTModelImages) then
            printdebug("static","try to create RTT from MeshID (static iArtID - 0x4000): " .. iArtID - 0x4000)
            local meshname = GetMeshName(iArtID-0x4000,iHue,true)

            if (meshname) then
                local iMaxW=64  --48
                local iMaxH=64  --32
                
                local angh = (135)*gfDeg2Rad
                local angv = (-45)*gfDeg2Rad
                local qw,qx,qy,qz = Quaternion.fromAngleAxis(angv,1,0,0)
                qw,qx,qy,qz = Quaternion.Mul(qw,qx,qy,qz,Quaternion.fromAngleAxis(angh,0,0,1))
                local vCustomScale = {-1,1,1}
                local qCustomRotation = {qw,qx,qy,qz}
                local matname,rtt,name_texture = GetMeshPreview(meshname,iMaxW,nil,nil,nil,qCustomRotation,vCustomScale) -- (meshname,res,angh,angv,pixelformat)
                res.material = matname and CloneMaterial("rtt_base")
                SetTexture(res.material,matname)

                -- Saves the raw Texture as BMP or PNG
                --if (false) then SaveUOModelImageToFile(rtt,texname) end

                w = 64 / math.sqrt(2)
                h = 64 / math.sqrt(2)
                if (iMaxW) then w = math.min(iMaxW,w) end
                if (iMaxH) then h = math.min(iMaxH,h) end
            else
                printdebug("static","mesh not available", meshname)
            end
        end
        
        -- if no Art Tile is existent, load the Art Tile from Art.mul
        if (not res.material or res.material == "") then
            if (gArtMapLoader) then
                -- bPixelExact,bInvertY,bInvertX,bHasAlpha,bEnableLighting,bEnableDepthWrite,HueLoader,iHue
                res.material = gArtMapLoader:CreateMaterial(iArtID,true,false,false,true,false,false, gHueLoader, iHue)
                w,h = gArtMapLoader:GetSize()
            end
        end

        res.width = w
        res.height = h

        if (not res.material or res.material == "") then res.material= "art_fallback" end
        gArtMatCache[iArtID.."_"..iHue] = res
    end
    
    return res.material
end

-- art material loader with caching
gArtBillBoardMatCache = {}
function GetArtBillBoardMat (iArtID,iHue)
    if (not(iHue) or (iHue > gMaxHueValue)) then iHue=0 end
    local res = gArtBillBoardMatCache[iArtID.."_"..iHue]
    if (res) then return res end
    -- bPixelExact,bInvertY,bInvertX,bHasAlpha,bEnableLighting,bEnableDepthWrite,HueLoader,iHue
    res = gArtMapLoader and gArtMapLoader:CreateMaterial(iArtID,true,false,false,true,false,true, gHueLoader,iHue)
    if (not res or res == "") then res = "art_fallback" end
    gArtBillBoardMatCache[iArtID.."_"..iHue] = res
    return res
end

function BitMaskTestRow (bitmask,x1,x2,y) for x = x1,x2 do if bitmask:TestBit(x,y) then return true end end end
function BitMaskTestCol (bitmask,x,y1,y2) for y = y1,y2 do if bitmask:TestBit(x,y) then return true end end end

gArtMatVisibleAABBCache = {}
-- minx,miny,maxx,maxy = GetArtVisibleAABB(artid) : from gArtMatCache or calculateSize
function GetArtVisibleAABB (iArtID)
    local res = gArtMatVisibleAABBCache[iArtID]
    if (res) then return unpack(res) end
    if (not gArtMapLoader) then return 0,0,0,0 end
    
    local bitmask = GetArtBitMask(iArtID)
    local minx,miny,maxx,maxy
    local w,h = bitmask:GetSize()
    
    for y = 1,h-1 do
    for x = 1,w-1 do
        if bitmask:TestBit(x,y) then
            if minx == nil then
                minx = x
                miny = y
                maxx = x
                maxy = y
            else
                minx = math.min(minx,x)
                miny = math.min(miny,y)
                maxx = math.max(maxx,x)
                maxy = math.max(maxy,y)
            end
        end
    end
    end
    
    gArtMatVisibleAABBCache[iArtID] = {minx or 0,miny or 0,maxx or 0,maxy or 0}
    return minx,miny,maxx,maxy
end

-- GetArtSize from gArtMatCache or generateSize
function GetArtSize (iArtID,iHue)
    if (not(iHue) or (tonumber(iHue) > gMaxHueValue)) then iHue=0 end
    local res = gArtMatCache[iArtID.."_"..iHue]

    if (not res and gArtMapLoader) then
        gArtMapLoader:Load(iArtID)
        return gArtMapLoader:GetSize()
    end

    if (res) then
        return res.width, res.height
    end
    
    return 0, 0
end

-- gump bitmask loader with caching
gGumpBitMaskCache = {}
function GetGumpBitMask (iGumpID)
    local res = gGumpBitMaskCache[iGumpID]
    if (not res and gGumpLoader) then
        res = gGumpLoader:CreateBitMask(iGumpID)
        gGumpBitMaskCache[iGumpID] = res
    end
    return res
end

-- gump material loader with caching
gGumpMatCache = {}
function GetGumpMat (iGumpID,iHue)
    if (not(iHue) or (iHue > gMaxHueValue)) then iHue=0 end
    local res = gGumpMatCache[iGumpID.."_"..iHue]
    if (not res and gGumpLoader) then
        res = gGumpLoader:CreateMaterial(iGumpID,true,gHueLoader,iHue)
        
        if ((not res) or res == "") then
            print("WARNING ! MakeBorderGumpPart : material load failed for gumpid=", iGumpID)
            res = "hudUnknown"
        end
        
        gGumpMatCache[iGumpID.."_"..iHue] = res
    end
    return res
end

function GetGumpSize (iGumpID) 
    gGumpLoader:Load(iGumpID)
    return gGumpLoader:GetSize()
end

-- tex material loader with caching
gTexMapMatCache = {}
function GetTexMapMat (iTexMapID)
    local res = gTexMapMatCache[iTexMapID]
    if (not res and gTexMapLoader) then
        res = gTexMapLoader:CreateMaterial(iTexMapID, false, true, true, true)
        gTexMapMatCache[iTexMapID] = res
    end
    return res
    
--[[
    bool bHasAlpha=         (lua_gettop(L) >= ++i && !lua_isnil(L,i)) ? lua_toboolean(L,i) : true;
    bool bEnableLighting=   (lua_gettop(L) >= ++i && !lua_isnil(L,i)) ? lua_toboolean(L,i) : false;
    bool bEnableDepthWrite= (lua_gettop(L) >= ++i && !lua_isnil(L,i)) ? lua_toboolean(L,i) : true;
    bool bPixelExact=       (lua_gettop(L) >= ++i && !lua_isnil(L,i)) ? lua_toboolean(L,i) : true;
]]--    
end

function GetTexMapSize (iTexMapID) 
    gTexMapLoader:Load(iTexMapID)
    return gTexMapLoader:GetSize()
end



