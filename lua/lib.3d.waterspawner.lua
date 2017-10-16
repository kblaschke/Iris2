--[[ ***** see Iris2 COPYING for license info ***** ]]--
--[[ \brief
		handles water
]]--

cWaterSpawner = CreateClass(cMapBlockSpawner)

function CreateWaterSpawner (pScheduler) local o = CreateClassInstance(cWaterSpawner, cMapBlock_3D_Water,pScheduler) return o end

function cWaterSpawner:GetBlockByUOLocation (xloc,yloc)
    local bx,by = math.floor(xloc/self.iBlockSize), math.floor(yloc/self.iBlockSize)
    return self:GetOrCreateMapBlock(bx,by)
end

function cWaterSpawner:TriggerUpdate    (item)
    if item.artid and FilterIsStaticWater(item.artid) and not gConfig:Get("gWaterAsGroundTiles") then
        local b = self:GetBlockByUOLocation(item.xloc,item.yloc)
        b:Rebuild()
    end
end

function cWaterSpawner:AddDynamic   (item)
    self:TriggerUpdate(item)
end

function cWaterSpawner:RemoveDynamic    (item)
    self:TriggerUpdate(item)
end
