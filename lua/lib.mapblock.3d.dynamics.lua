-- todo

cMapBlock_3D_Dynamics	= CreateClass(cMapBlockGrid)
cMapBlock_3D_Dynamics.iBlockSize		= 8*2 -- in tiles
cMapBlock_3D_Dynamics.iLoadRadius		= 4 -- in iBlockSize-blocks
cMapBlock_3D_Dynamics.kMaxDist_Visible		= cMapBlock_3D_Dynamics.iBlockSize * 4 -- camdist in tiles  see mapblock.base for default
cMapBlock_3D_Dynamics.kMaxDist_Detail		= cMapBlock_3D_Dynamics.iBlockSize * 2 -- camdist in tiles

function cMapBlock_3D_Dynamics:Init (bx,by)
	cMapBlockGrid.Init(self, bx,by)

	self.lDynamics = {}
end

-- forall entities fun(entity)
function cMapBlock_3D_Dynamics:ForAllEntities (fun)
	if self.mTileBatch then self.mTileBatch:ForAllTiles(fun) end
end

function cMapBlock_3D_Dynamics:GetDisplayRange ()
	if self.mTileBatch then return self.mTileBatch:GetDisplayRange() end
end

function cMapBlock_3D_Dynamics:SetDisplayRange (fmin, fmax)
	if self.mTileBatch then self.mTileBatch:SetDisplayRange(fmin,fmax) end
end

function cMapBlock_3D_Dynamics:Clear ()
	if self.mTileBatch then self.mTileBatch:Clear() end
end

function cMapBlock_3D_Dynamics:IsUOLocationInsideBlock	(xloc,yloc)
	return math.floor(xloc/8) == self.bx and math.floor(yloc/8) == self.by
end

-- returns {iTileTypeID,xloc,yloc,iZ,iHue} of the given dynamic
function cMapBlock_3D_Dynamics:GetRawDataFromDynamic (dynamic)
	-- iTileTypeID,xloc,yloc,iZ,iHue
	return dynamic.artid, dynamic.xloc, dynamic.yloc, dynamic.zloc, dynamic.hue
end

function cMapBlock_3D_Dynamics:AddDynamic (dynamic)
	local iTileTypeID,xloc,yloc,iZ,iHue = self:GetRawDataFromDynamic(dynamic)
	if iTileTypeID and xloc and yloc and iZ and (gConfig:Get("gWaterAsGroundTiles") or not FilterIsStaticWater(iTileTypeID)) then
		self.mUpdateNeeded = true

		self.lDynamics[dynamic.serial] = {
			serial=dynamic.serial, 
			--~ remove_me=false, preload_me=true, 
			dynamic=dynamic, rawdata={self:GetRawDataFromDynamic(dynamic)}
		}
		
		self.mLastChange = Client_GetTicks()
	end
end

function cMapBlock_3D_Dynamics:RemoveDynamic (dynamic)
	if self.lDynamics[dynamic.serial] then
		--~ print("REMOVE",self,dynamic.serial)
		self.mUpdateNeeded = true
		self.lDynamics[dynamic.serial] = nil
		
		self.mLastChange = Client_GetTicks()
	end
end

-- called every frame, instant actions (destroy gfx), evaluate priority 
function cMapBlock_3D_Dynamics:ShortStep (t,xloc,yloc,zloc)
	if self.mUpdateNeeded then
		local bx,by,w,h = self:GetAABB()
		
		local camdist = hypot(	(bx+w/2)-xloc,
								(by+h/2)-yloc)
		self.last_camdist = camdist

		-- big changes
		self:SetPriority(kMapLoad_3D_Dynamics_AddRemove.prio)
	--~ elseif self.mUnbatched > 0 and self.mLastChange < t - cMapBlock_3D_Dynamics.kBatchTimeout then
		--~ -- just 
		--~ self.mRebatchNeeded = true
		--~ self:SetPriority(kMapLoad_3D_Dynamics_Batch.prio)
	--~ else
		--~ self:SetPriority(kSchedulerIdlePriority)
	end
		
	--~ elseif ((self.iNextLODUpdate or 0) < t) then
		--~ -- normal lod updates
		--~ self.iNextLODUpdate = t + self.kLODUpdateInterval
		--~ 
		--~ local bx = floor(xloc/self.iBlockSize + 0.5)
		--~ local by = floor(yloc/self.iBlockSize + 0.5)
		--~ 
		--~ local camdist = hypot(	(self.bx + 0.5)*self.iBlockSize-xloc,
								--~ (self.by + 0.5)*self.iBlockSize-yloc)
		--~ local newlod
		--~ if (	camdist <  self.kMaxDist_Detail ) then newlod = self.kLOD_Detail 
		--~ elseif (camdist <  self.kMaxDist_Visible) then newlod = self.kLOD_Rough end
		--~ 
		--~ self:SetLOD(newlod)
	--~ end
end

-- a single step during the thread
function cMapBlock_3D_Dynamics:WorkStep ()
	local dt = Client_GetTicks() - (self.last_update_time or 0)
	
	if self.mUpdateNeeded and (dt > 500) then
		self.rebuild_count = (self.rebuild_count or 0) + 1
		self.last_update_time = Client_GetTicks()
		
		if not self.mTileBatch then
			self.mTileBatch = CreateClassInstance(cTileBatch)
		end
		
		-- preload
		for k,v in pairs(self.lDynamics) do
			self.mTileBatch:PreloadTile(unpack(v.rawdata))
			self:YieldIfOverTime()
		end
		
		self:Yield()

		-- clear
		self.mUpdateNeeded = nil

		self.mTileBatch:Clear()

		-- add existing ones
		for k,v in pairs(self.lDynamics) do
			self.mTileBatch:AddTile(unpack(v.rawdata))
		end

		self.mTileBatch:Build()
		
		--~ print("count",self,countarr(self.lDynamics))

		self:SetDisplayRange(gCurrentRenderer:BlendoutGetVisibleRange())

		self:SetPriority(kSchedulerIdlePriority)
	end
end
