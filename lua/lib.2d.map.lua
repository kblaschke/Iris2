-- handles maploading and similar

Renderer2D.pMapBlocks = {}
Renderer2D.iNextMapStep = 0

Renderer2D.kGoodFPS = 25
Renderer2D.kGoodTicksBetweenFrames = 1000 / Renderer2D.kGoodFPS -- 1000=1sec
Renderer2D.kMapLoadAllowedTicksPerFrame = Renderer2D.kGoodTicksBetweenFrames 
Renderer2D.kMapLoadStaticLoadAllowedTicks = Renderer2D.kGoodTicksBetweenFrames 
--~ local bWeHaveSpareTime = gSecondsSinceLastFrame*1000 < Renderer2D.kGoodTicksBetweenFrames

kMapLoad_2D_Terrain_Rough		= {prio=0}
kMapLoad_2D_Water_Rough			= {prio=1} -- similar to rough terrain, just one poly per block
kMapLoad_2D_Statics_Rough		= {prio=2}
kMapLoad_2D_Multis_Rough		= {prio=3}
kMapLoad_2D_Terrain_Detail		= {prio=4}
kMapLoad_2D_Water_Detail		= {prio=5}
kMapLoad_2D_Statics_Detail		= {prio=6}
kMapLoad_2D_Multis_Detail		= {prio=7}
kMapLoad_2D_Dynamics			= {prio=8}

dofile(libpath .. "lib.mapblock.scheduler.lua")
dofile(libpath .. "lib.mapblock.spawner.lua")
dofile(libpath .. "lib.mapblock.base.lua")
dofile(libpath .. "lib.mapblock.grid.lua")
dofile(libpath .. "lib.mapblock.2d.statics.lua")
dofile(libpath .. "lib.mapblock.2d.terrain.lua")
--~ dofile(libpath .. "lib.mapblock.2d.water.lua")
cMapBlock_2D_Water		= CreateClass(cMapBlockGrid)



cMapBlock_2D_Terrain.kLOD_Detail		= kMapLoad_2D_Terrain_Detail
cMapBlock_2D_Terrain.kLOD_Rough			= kMapLoad_2D_Terrain_Rough
cMapBlock_2D_Statics.kLOD_Detail		= kMapLoad_2D_Statics_Detail
cMapBlock_2D_Statics.kLOD_Rough			= kMapLoad_2D_Statics_Rough

function Renderer2D:DeInitMap	()
	for k,v in pairs(self.map2d_spawners) do
		v:Destroy()
	end
	self.map2d_spawners = nil
	self.map2d_scheduler:Destroy()
	self.map2d_scheduler = nil
	self.bMapLoadSystemInitialized = false
end

function Renderer2D:InitMap	()
	if (not self.bMapLoadSystemInitialized) then
		self.bMapLoadSystemInitialized = true
		local scheduler = CreateScheduler()
		self.map2d_nextAreaCalc = 0
		self.map2d_scheduler = scheduler
		self.map2d_spawners = {}
		self.map2d_spawners.terrain		= CreateMapBlockSpawner2D(cMapBlock_2D_Terrain,scheduler)
		self.map2d_spawners.statics		= CreateMapBlockSpawner2D(cMapBlock_2D_Statics,scheduler)
		--~ self.map2d_spawners.water		= CreateMapBlockSpawner(cMapBlock_2D_Water,scheduler)
	end
end

function Renderer2D:BlendOutLayersAbovePlayer	()
	local x,y,z = GetPlayerPos()
	if (not z) then return end
	
	local myLayer = nil
	local bTerrainVisible = true
	
	--~ if (self:CamModeAllowsBlendout()) then ... end   -- don't blend out in freecam ?
	myLayer,bTerrainVisible = CalcBlendOutZ()
	
	gProfiler_Walk:Section("BlendOutLayersAbovePlayer:setvis")
	
	-- only update if changed
	if (self.giBlendOutCurZ ~= myLayer or self.gbBlendOutTerrainVisible ~= bTerrainVisible) then
		self.giBlendOutCurZ = myLayer
		--~ print("Renderer2D:BlendOutLayersAbovePlayer",myLayer,bTerrainVisible)
		
		if (self.gbBlendOutTerrainVisible ~= bTerrainVisible) then
			self.gbBlendOutTerrainVisible = bTerrainVisible
			self.map2d_spawners.terrain:ForAllBlocks(function(block) block:UpdateBlendOutVisibility() end)
		end
		
		local a,b = self:BlendoutGetVisibleRange()
		self:Dynamics_UpdateBlendOut()
		
		self.map2d_spawners.statics:ForAllBlocks(function(block) block:RebuildForBlendout() end)
	end
	--[[
	gCurrentRenderer:BlendoutGetVisibleRange()
	mapblock:SetDisplayRange
	Renderer2D:BlendOutLayersAbovePlayer
	]]--
end

-- returns fMinZ,fMaxZ
function Renderer2D:BlendoutGetVisibleRange ()
	local fMinZ = -1000
	local fMaxZ = (self.giBlendOutCurZ or 1000) -- inclusive
	return fMinZ,fMaxZ
end


-- local l,t,r,b = Renderer2D:GetScreenAreaInTileCoords ()  (relative coords, add xloc,yloc of cam center)
function Renderer2D:GetScreenAreaInTileCoords () return unpack(self.screenAreaInTileCoords) end

function Renderer2D:MapRecalcScreenArea		(x,y)
	-- calc view area for current window size
	local vw,vh = GetViewportSize()
	local x0,y0 = PixelOffsetToTileOffset(-vw/2,-vh/2)
	local x1,y1 = PixelOffsetToTileOffset( vw/2,-vh/2)
	local x2,y2 = PixelOffsetToTileOffset(-vw/2, vh/2)
	local x3,y3 = PixelOffsetToTileOffset( vw/2, vh/2)
	local e = 3 -- should cope with different zlevels
	local l = floor(min(x0,x1,x2,x3))-e
	local t = floor(min(y0,y1,y2,y3))-e
	local r = ceil(max(x0,x1,x2,x3))+e
	local b = ceil(max(y0,y1,y2,y3))+e
	--~ print("Renderer2D:MapStep : dx,dy=",dx,dy,"x,y=",floor(xloc),floor(yloc),"l,t:",l,t,"r,b:",r,b)
	self.screenAreaInTileCoords = {l,t,r,b}
end

function Renderer2D:MapStep		()
	local t = Client_GetTicks()
	local x,y,z = self:GetCamPos()
	
	if (self.map2d_nextAreaCalc < t) then 
		self.map2d_nextAreaCalc = t + 1000
		self:MapRecalcScreenArea(x,y)
	end
	
	for k,spawner in pairs(self.map2d_spawners) do spawner:Step(t,x,y,z) end
	self.map2d_scheduler:Step(x,y,z)
end

function Renderer2D:MapClear	()
	for k,spawner in pairs(self.map2d_spawners or {}) do spawner:Clear() end
end

-- water : block.terrain[10*ty+tx] = MapGetGround(block.bx*8+tx,block.by*8+ty)
-- water : analyze terrain infos and determine where water should be, FilterIsMapWater(tiletype) -- 3D: chunk:SetWaterZ(tx,ty,z) ??


-- ***** ***** ***** cMapBlockSpawner2D

cMapBlockSpawner2D = CreateClass(cMapBlockSpawner)
cMapBlockSpawner2D.kStepInterval = 100
function CreateMapBlockSpawner2D (pBlockClass,pScheduler) local o = CreateClassInstance(cMapBlockSpawner2D, pBlockClass,pScheduler) return o end


function cMapBlockSpawner2D:Step	(t,x,y) 
	if ((self.iNextStep or 0) > t) then return end
	self.iNextStep = t + self.kStepInterval
	
	local xloc,yloc = x,y
	local l,t,r,b = Renderer2D:GetScreenAreaInTileCoords()
	local minx = floor((xloc+l)/self.iBlockSize)
	local miny = floor((yloc+t)/self.iBlockSize)
	local maxx = floor((xloc+r)/self.iBlockSize)
	local maxy = floor((yloc+b)/self.iBlockSize)
	
	-- destroy blocks outside radius
	for block,v in pairs(self.pMapBlocks) do 
		if (block.bx < minx or 
			block.by < miny or 
			block.bx > maxx or 
			block.by > maxy) then
			-- outside, destroyed
			self.mlToBeDestroyedBlock[block] = true
			--~ self:DestroyMapBlock(block)
		end
	end
	
	-- create blocks inside radius if needed
	for by = miny,maxy do
	for bx = minx,maxx do
		self:GetOrCreateMapBlock(bx,by)
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

