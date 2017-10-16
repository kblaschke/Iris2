--[[ ***** see Iris2 COPYING for license info ***** ]]--
--[[ \brief
        loads artid graphics to one or multiple texture-atlases
     	TODO : can also reorganizes atlases as needed with locking/unlocking system ?
     	... now just a wrapper for a call to the generic atlasgroup implementation
]]--

-- returns sMatName,iWidth,iHeight,iCenterX,iCenterY,u0,v0,u1,v1 = ArtAtlasLoadAndLockDirect(iTileTypeID,iHue,pLockKeeper,basematerial)
-- immediately load material, useful for dynamics
function ArtAtlasLoadAndLockDirect (iTileTypeID,iHue,pLockKeeper,basematerial)
    local o = ArtAtlasLoadAndLock(iTileTypeID,iHue,pLockKeeper)
    if (not o) then return end
    local sMatName = gAtlasGroup_Art:LoadAtlasMat(o.atlas,basematerial)
    local iCenterX,iCenterY = o.origw/2,o.origh-22
    return sMatName,o.origw,o.origh,iCenterX,iCenterY,o.u0,o.v0,o.u1,o.v1
end

-- material is not immediately loaded, useful for statics
-- returns pAtlasPiece = {atlas=?,u0=?,v0=?,u1=?,v1=?,origw=?,origh=?}
function ArtAtlasLoadAndLock (iTileTypeID,iHue,pLockKeeper)  return PreLoadArt(iTileTypeID,iHue) end

function ArtAtlasUnLock (pLockKeeper) end
