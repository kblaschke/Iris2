--[[ ***** see Iris2 COPYING for license info ***** ]]--
--[[ \brief
		spawns multis (multiple dynamic objects)
]]--

cMultiSpawner = CreateClass(cMapBlockSpawner)
cMultiSpawner.kStepInterval = 10

function CreateMultiSpawner (pScheduler) local o = CreateClassInstance(cMultiSpawner, cMapBlock_3D_Multis, pScheduler) return o end

function cMultiSpawner:Init (pBlockClass,pScheduler)
    self.lMulti         = {} 
    self.iLoadRadius    = pBlockClass.iLoadRadius
    self.pBlockClass    = pBlockClass
    self.pScheduler     = pScheduler
end

function cMultiSpawner:ForAllBlocks (fun) for k,multi in pairs(self.lMulti) do if multi.block then fun(multi.block) end end end

function cMultiSpawner:Step (t,x,y) 
    if ((self.iNextStep or 0) > t) then return end
    self.iNextStep = t + self.kStepInterval
    
    for k,multi in pairs(self.lMulti) do
        local dx = multi.x-x
        local dy = multi.y-y
        local d = len2(dx,dy)

        if d <= self.iLoadRadius and not multi.block then
            --~ print("###create",d,self)
            -- create new block
            multi.block = self:CreateBlock(multi.multi)
        elseif d > self.iLoadRadius and multi.block then
            --~ print("###destroy",d,self)
            -- destroy existing block
            self:DestroyBlock(multi.block)
            multi.block = nil
        end
    end
end

function cMultiSpawner:CreateBlock  (multi)
    local block = CreateClassInstance(self.pBlockClass, multi)
    self.pScheduler:AddProcess(block)
    return block
end

function cMultiSpawner:DestroyBlock (block)
    block:Destroy()
    self.pScheduler:RemoveProcess(block)
end

function cMultiSpawner:AddMulti (serial,multi)
    local block = {}
    
    block.multi = multi
    block.x = 0
    block.y = 0
    
    local count = countarr(multi.lparts)
    for k,v in pairs(multi.lparts) do
        local iTileTypeID,iX,iY,iZ,iHue = unpack(v)
        block.x = block.x + iX
        block.y = block.y + iY
    end
    
    block.x = math.floor(block.x / count)
    block.y = math.floor(block.y / count)
    
    self.lMulti[serial] = block
end

function cMultiSpawner:RemoveMulti  (serial)
    local block = self.lMulti[serial]
    
    if block then
        if block.block then
            self:DestroyBlock(block.block)
        end
        
        self.lMulti[serial] = nil
    end
end

function cMultiSpawner:Destroy  ()
    for k,multi in pairs(self.lMulti) do
        self:RemoveMulti(k)
    end
end
