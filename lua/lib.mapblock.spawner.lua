-- ***** ***** ***** ***** ***** cMapBlockSpawner

cMapBlockSpawner = CreateClass()
cMapBlockSpawner.kStepInterval = 200

function CreateMapBlockSpawner (pBlockClass,pScheduler) local o = CreateClassInstance(cMapBlockSpawner, pBlockClass,pScheduler) return o end

function cMapBlockSpawner:Init	(pBlockClass,pScheduler)
	self.pMapBlocks		= {} 
	self.iBlockSize		= pBlockClass.iBlockSize -- the size of a block in tiles
	self.iLoadRadius	= pBlockClass.iLoadRadius
	self.pBlockClass	= pBlockClass
	self.pScheduler		= pScheduler
	self.mlUnfinishedBlock = {}
	self.mlToBeDestroyedBlock = {}
end

-- calls fun(block) for all blocks
function cMapBlockSpawner:ForAllBlocks	(fun) for block,v in pairs(self.pMapBlocks) do fun(block) end end

-- creates new blocks in area near cam if needed, releases old blocks
-- params : time, focuspos
function cMapBlockSpawner:Step	(t,x,y) 
	if ((self.iNextStep or 0) > t) then return end
	self.iNextStep = t + self.kStepInterval
	
	local bx = floor(x/self.iBlockSize + 0.5)
	local by = floor(y/self.iBlockSize + 0.5)
	if (self.pMapFocusBlockX ~= bx or 
		self.pMapFocusBlockY ~= by) then 
		self.pMapFocusBlockX = bx
		self.pMapFocusBlockY = by
		local r = self.iLoadRadius
		
		-- destroy blocks outside radius
		for block,v in pairs(self.pMapBlocks) do 
			if (block.bx < bx-r or 
				block.bx > bx+r or 
				block.by < by-r or 
				block.by > by+r) then
				-- outside, destroyed
				self.mlToBeDestroyedBlock[block] = true
				--~ self:DestroyMapBlock(block)
			end
		end
		
		-- create blocks inside radius if needed
		for ay = -r,r do
		for ax = -r,r do
			self:GetOrCreateMapBlock(bx+ax,by+ay)
		end
		end
	end
	
	giShowLoadingUnfinished = countarr(self.mlUnfinishedBlock) + countarr(self.mlToBeDestroyedBlock)
	
	-- check unfinished jobs and remove them if finished
	for k,v in pairs(self.mlUnfinishedBlock) do
		if k:IsDead() then
			--~ print("REMOVE UNFINISHED JOB")
			self.pScheduler:RemoveProcess(k)
			self.mlUnfinishedBlock[k] = nil
		end
	end
	
	-- destroy blocks
	for k,v in pairs(self.mlToBeDestroyedBlock) do
		self.mlToBeDestroyedBlock[k] = nil
		self:DestroyMapBlock(k)
		if not TimeLeftInFrame() then break end
	end
end

-- creates new block if needed
function cMapBlockSpawner:GetOrCreateMapBlock	(bx,by) 
	return self:GetMapBlock(bx,by) or self:CreateMapBlock(bx,by) 
end

-- returns nil if block doesn't exist
function cMapBlockSpawner:GetMapBlock		(bx,by) 
	for block,v in pairs(self.pMapBlocks) do if (block.bx == bx and block.by == by) then return block end end 
end

function cMapBlockSpawner:CreateMapBlock	(bx,by)
	--~ print("cMapBlockSpawner:CreateMapBlock",bx,by)
	local block = CreateClassInstance(self.pBlockClass, bx,by)
	if (gDebugJobOrigin) then block.source = GetOneLineBackTrace(2) end
	self.pMapBlocks[block] = true 
	self.pScheduler:AddProcess(block)
	return block
end

function cMapBlockSpawner:DestroyMapBlock	(block)
	block:Destroy()
	self.pMapBlocks[block] = nil
	
	if block:IsDead() then
		self.pScheduler:RemoveProcess(block)
	else
		self.mlUnfinishedBlock[block] = true
		--~ print("UNFINISHED JOB")
	end
end

-- destroy all blocks
function cMapBlockSpawner:Clear	()
	for block,v in pairs(self.pMapBlocks) do self:DestroyMapBlock(block) end
	self.pMapBlocks = {}
end

function cMapBlockSpawner:Destroy () self:Clear() end
