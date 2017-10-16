--[[ ***** see Iris2 COPYING for license info ***** ]]--
--[[ \brief
		Dynamic Object Spawner
]]--

cDynamicSpawner = CreateClass(cMapBlockSpawner)
cDynamicSpawner.kStepInterval = 10

function CreateDynamicSpawner (pScheduler) local o = CreateClassInstance(cDynamicSpawner, cMapBlock_3D_Dynamics,pScheduler) return o end

function cDynamicSpawner:GetBlockByUOLocation   (xloc,yloc)
    local bx,by = math.floor(xloc/self.iBlockSize), math.floor(yloc/self.iBlockSize)
    return self:GetOrCreateMapBlock(bx,by)
end

function cDynamicSpawner:CreateMapBlock (bx,by)
    local b = cMapBlockSpawner.CreateMapBlock(self, bx,by)
    
    -- add already existing dynamics
    local d = self.iBlockSize
    local tbx = d * bx
    local tby = d * by
    for x = tbx,tbx+d-1 do
        for y = tby,tby+d-1 do
            for k,dynamic in pairs(GetDynamicsAtPosition(x,y)) do 
                b:AddDynamic(dynamic)
            end
        end
    end

    return b
end

function cDynamicSpawner:AddDynamic (item)
    local b = self:GetBlockByUOLocation(item.xloc,item.yloc)
    b:AddDynamic(item)
end

function cDynamicSpawner:RemoveDynamic  (item)
    -- remove in all blocks because the block could change
    self:ForAllBlocks(function(b)
        b:RemoveDynamic(item)
    end)
end
