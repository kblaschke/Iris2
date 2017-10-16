--[[ ***** see Iris2 COPYING for license info ***** ]]--
--[[ \brief
		handles maploading and similar
]]--

dofile(libpath .. "lib.mapblock.scheduler.lua")
dofile(libpath .. "lib.mapblock.spawner.lua")
dofile(libpath .. "lib.mapblock.base.lua")
dofile(libpath .. "lib.mapblock.grid.lua")
dofile(libpath .. "lib.mapblock.aabb.lua")
dofile(libpath .. "lib.mapblock.3d.statics.lua")
dofile(libpath .. "lib.mapblock.3d.terrain.lua")
dofile(libpath .. "lib.mapblock.3d.water.lua")
dofile(libpath .. "lib.mapblock.3d.dynamics.lua")
dofile(libpath .. "lib.mapblock.3d.multis.lua")

Renderer3D.pMapBlocks = {}
Renderer3D.iNextMapStep = 0

Renderer3D.giMapOriginX = 0
Renderer3D.giMapOriginY = 0
Renderer3D.ROBMAP_CHUNK_SIZE = 2
Renderer3D.giBlendOutCurZ = nil

Renderer3D.kGoodFPS = 25
Renderer3D.kGoodTicksBetweenFrames = 1000 / Renderer3D.kGoodFPS -- 1000=1sec
Renderer3D.kMapLoadAllowedTicksPerFrame = Renderer3D.kGoodTicksBetweenFrames 
Renderer3D.kMapLoadStaticLoadAllowedTicks = Renderer3D.kGoodTicksBetweenFrames 
--~ local bWeHaveSpareTime = gSecondsSinceLastFrame*1000 < Renderer3D.kGoodTicksBetweenFrames

kMapLoad_3D_Terrain_Rough       = {prio=0}
kMapLoad_3D_Water_Rough         = {prio=1} -- similar to rough terrain, just one poly per block
kMapLoad_3D_Statics_Rough       = {prio=2}
kMapLoad_3D_Multis_Rough        = {prio=3}
kMapLoad_3D_Terrain_Detail      = {prio=4}
kMapLoad_3D_Statics_Detail      = {prio=5}
kMapLoad_3D_Multis_Detail       = {prio=6}
kMapLoad_3D_Water_Detail        = {prio=7}
kMapLoad_3D_Dynamics_AddRemove  = {prio=8}
kMapLoad_3D_Dynamics_Batch      = {prio=5}

cMapBlock_3D_Terrain.kLOD_Detail        = kMapLoad_3D_Terrain_Detail
cMapBlock_3D_Terrain.kLOD_Rough         = kMapLoad_3D_Terrain_Rough
cMapBlock_3D_Statics.kLOD_Detail        = kMapLoad_3D_Statics_Detail
cMapBlock_3D_Statics.kLOD_Rough         = kMapLoad_3D_Statics_Rough
cMapBlock_3D_Water.kLOD_Detail          = kMapLoad_3D_Water_Detail
cMapBlock_3D_Water.kLOD_Rough           = kMapLoad_3D_Water_Rough
cMapBlock_3D_Multis.kLOD_Detail         = kMapLoad_3D_Multis_Detail
cMapBlock_3D_Multis.kLOD_Rough          = kMapLoad_3D_Multis_Rough

function Renderer3D:DeInitMap   ()
    for k,v in pairs(self.map3d_spawners) do
        v:Destroy()
    end
    self.map3d_spawners = nil
    self.map3d_scheduler:Destroy()
    self.map3d_scheduler = nil
    self.bMapLoadSystemInitialized = false
    self:StopSpawner()
end

function Renderer3D:InitMap ()
    if (not self.bMapLoadSystemInitialized) then
        self.bMapLoadSystemInitialized = true
        local scheduler = CreateScheduler()
        self.map3d_scheduler = scheduler
        self.map3d_spawners = {}
        self.map3d_spawners.terrain     = CreateMapBlockSpawner(cMapBlock_3D_Terrain,scheduler)
        self.map3d_spawners.statics     = CreateMapBlockSpawner(cMapBlock_3D_Statics,scheduler)
        self.map3d_spawners.water       = CreateWaterSpawner(scheduler)
        self.map3d_spawners.dynamics    = CreateDynamicSpawner(scheduler)
        self.map3d_spawners.multis      = CreateMultiSpawner(scheduler)
    end
    self:StartSpawner()
end

function Renderer3D:StartSpawner        ()
    if self.mbSpawnerRunning then return end
    if self.mbSpawnerStopping then return end
    
    self.mbSpawnerRunning = true
    
    job.create(function()
        while(self.mbSpawnerRunning and self.map3d_spawners) do
            local l = self.map3d_spawners
            for k,spawner in pairs(l) do
                local t = Client_GetTicks()
                local xloc,yloc,zloc = self:GetCamPos()
                spawner:Step(t,xloc,yloc,zloc) 
                job.wait(10)
            end
        end
        self.mbSpawnerStopping = false
    end)
end

function Renderer3D:StopSpawner     ()
    self.mbSpawnerRunning = false
    self.mbSpawnerStopping = true
end

function Renderer3D:MapStep     ()
    -- block spawner runs in an extra thread -> StartSpawner
    local t = Client_GetTicks()
    local xloc,yloc,zloc = self:GetCamPos()
    self.map3d_scheduler:Step(xloc,yloc,zloc)
end

function Renderer3D:MapClear    ()
    for k,spawner in pairs(self.map3d_spawners or {}) do spawner:Clear() end
end

-- water : block.terrain[10*ty+tx] = MapGetGround(block.bx*8+tx,block.by*8+ty)
-- water : analyze terrain infos and determine where water should be, FilterIsMapWater(tiletype) -- 3D: chunk:SetWaterZ(tx,ty,z) ??


-- returns xloc,yloc in uo coords
function Renderer3D:GetCamPos () 
    local x,y,z = Renderer3D:GetLookAheadCamPos()
    return -x,y,z
end

-- check if player entered or left a special map area, e.g. a dungeon. can be used to change things like skybox/lighting
function Renderer3D:MapAreaCheck ()
    local x,y,z = GetPlayerPos()
    if (not z) then return end
	local bx = floor(x/8)
	local by = floor(y/8)
	if (gLastMapAreaBlockX == bx and
		gLastMapAreaBlockY == by) then return end
	gLastMapAreaBlockX = bx
	gLastMapAreaBlockY = by
	local areas = gMaps[gMapIndex].mapareas
	local activearea = false -- shouldn't be nil so we at least get an initial set
	if (areas) then
		for k,area in pairs(areas) do 
			if (x >= area.minx and 
				y >= area.miny and
				x <= area.maxx and 
				y <= area.maxy) then 
				activearea = area
			end
		end
	end
	--~ print("Renderer3D:MapAreaCheck",x,y,activearea)
	if (gLastMapArea == activearea) then return end
	gLastMapArea = activearea
	self:SetMapAreaEnv(activearea or gMaps[gMapIndex])
end

-- TODO: blend out mounts
function Renderer3D:BlendOutLayersAbovePlayer ()
    local x,y,z = GetPlayerPos()
    if (not z) then return end
	
	-- BlendOutLayersAbovePlayer always called when pos is updated, so we'll just add the area check here for now
	self:MapAreaCheck()
    
    
    --[[
    osi = wenn dach min 18z h�her als char, dann alles von zdach aufw�rts ausblenden
    atm blendet iris statics aus, die 10 �ber dem char liegen
    man geht in eine halle die ne art tronsaal sein soll, und hat keine hohen w�nde, sondern ne sandkasten umrandung ^^
    ich  hab f�r iris h�her gebaut als normal uo etagen vorsah, bei osi war 20die h�he f�r ne wand, 
    ]]--
    
    local myLayer = nil
    local bTerrainVisible = true
    
    -- only blend out if not in first person mode or in freecam
    if (Renderer3D:CamModeAllowsBlendout()) then 
        myLayer,bTerrainVisible = CalcBlendOutZ()
    end
    
    -- a bit of tolerance to avoid rebatching all the time for uneven floors ... not needed anymore with fastbatch blendout
    --~ if (self.giBlendOutCurZ and myLayer and math.abs(self.giBlendOutCurZ-myLayer) <= 2) then myLayer = self.giBlendOutCurZ end

    -- only update if changed
    if (self.giBlendOutCurZ ~= myLayer or self.gbBlendOutTerrainVisible ~= bTerrainVisible) then
        self.giBlendOutCurZ = myLayer
    
        -- todo: caelum ? skybox not visible underground
        if (self.gbBlendOutTerrainVisible ~= bTerrainVisible) then
            self:SetMapEnvironment(not bTerrainVisible)
            self.gbBlendOutTerrainVisible = bTerrainVisible
            
            self.map3d_spawners.terrain:ForAllBlocks(function(block) block:UpdateBlendOutVisibility() end)
        end
        
        local a,b = self:BlendoutGetVisibleRange()
        
        if self.map3d_spawners then
            for k,v in pairs(self.map3d_spawners) do
                v:ForAllBlocks(function(block)
                    if block.SetDisplayRange then
                        block:SetDisplayRange(a,b)
                    end
                end)
            end
        end
        
		-- update dynamics 
		--~ for k,dynamic in pairs(GetDynamicList()) do if (DynamicIsInWorld(dynamic)) then self:UpdateDynamicVisibility(dynamic) end end
		
		--~ self:UpdateDynamicDisplayRange()
		
        -- update mobiles
        for k,mobile in pairs(GetMobileList()) do self:UpdateMobileVisibility(mobile) end
    end
end

-- returns fMinZ,fMaxZ
function Renderer3D:BlendoutGetVisibleRange ()
    local fMinZ = -1000
    local fMaxZ = (self.giBlendOutCurZ or 1000) -- inclusive
    return fMinZ,fMaxZ
end

-- NOTE: layerZ is a uo zloc not the layer index in pStaticGeometryLayers
function Renderer3D:IsZLayerVisible (layerZ)
    if (not self.giBlendOutCurZ) then return true end
    if (not layerZ) then return true end
    return (not self.giBlendOutCurZ) or layerZ <= self.giBlendOutCurZ
end

function Renderer3D:ClearMapCache () end


--[[
function Renderer3D:UpdateStaticVisibility	(entity) 
	if (entity and entity.gfx and entity.gfx.billboard) then
		entity.gfx.billboard:SetVisible(self:IsZLayerVisible(entity.zloc))
	end
end
]]--
