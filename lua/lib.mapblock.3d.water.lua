-- todo

cMapBlock_3D_Water	= CreateClass(cMapBlockGrid)

cMapBlock_3D_Water.iBlockSize		= 8*2 -- in tiles
cMapBlock_3D_Water.iLoadRadius		= 2*4 -- in iBlockSize-blocks
cMapBlock_3D_Water.kMaxDist_Visible		= 2*cMapBlock_3D_Water.iBlockSize * 4 -- camdist in tiles  see mapblock.base for default
cMapBlock_3D_Water.kMaxDist_Detail		= 2*cMapBlock_3D_Water.iBlockSize * 2 -- camdist in tiles

local gWaterShaderRunning = false

local gMapBlockWaterZ = 0
local gMapBlockWaterZSum = 0
local gMapBlockWaterBlockCount = 0

local gMapBlockWaterGfxList	= {}	-- contains all gfx refs to hide and show all waters

local function UpdateReflectionPlaneZ()
	if gMapBlockWaterBlockCount > 0 then
		gMapBlockWaterZ = gMapBlockWaterZSum / gMapBlockWaterBlockCount
	end
end

-- blend out stuff ------------------------------------
function WaterBlendOutBelowZ	(z)
	for k,spawner in pairs(gCurrentRenderer.map3d_spawners) do
		if spawner.ForAllBlocks then
			spawner:ForAllBlocks(function(block)
				if block.GetDisplayRange and block.SetDisplayRange then
					block.water_cache_fmin, block.water_cache_fmax = block:GetDisplayRange()
					block:SetDisplayRange(z,10000)
				end
			end)
		end
	end

	--~ for k,mobile in pairs(GetMobileList()) do 
		--~ if mobile.bar then 
			--~ mobile.watercache_bar = mobile.bar:IsVisiblity()
			--~ mobile.bar:SetVisible(false)
		--~ end
		--~ 
		--~ if mobile.zloc < z then
			--~ self:DestroyMobileGfx(mobile) 
		--~ end
	--~ end
end

function WaterBlendOutAboveZ	(z)
	for k,spawner in pairs(gCurrentRenderer.map3d_spawners) do
		if spawner.ForAllBlocks then
			spawner:ForAllBlocks(function(block)
				if block.GetDisplayRange and block.SetDisplayRange then
					block.water_cache_fmin, block.water_cache_fmax = block:GetDisplayRange()
					block:SetDisplayRange(-10000,z)
				end
			end)
		end
	end
end

function WaterRestoreBlendOut	()
	for k,spawner in pairs(gCurrentRenderer.map3d_spawners) do
		if spawner.ForAllBlocks then
			spawner:ForAllBlocks(function(block)
				if block.GetDisplayRange and block.SetDisplayRange then
					block:SetDisplayRange(block.water_cache_fmin,block.water_cache_fmax)
				end
			end)
		end
	end
end

-- refraction -----------------------------------------
local function WaterPreRenderRefraction	()
	for k,v in pairs(gMapBlockWaterGfxList) do k:SetVisible(false) end
	
	WaterBlendOutAboveZ(gMapBlockWaterZ)
end

local function WaterPostRenderRefraction	()
	for k,v in pairs(gMapBlockWaterGfxList) do k:SetVisible(true) end

	WaterRestoreBlendOut()
end

-- reflection -----------------------------------------
local function WaterPreRenderReflection	()
	local cam = GetMainCam()
	gWaterReflectionCam:SetPos(cam:GetPos())
	gWaterReflectionCam:SetRot(cam:GetRot())

	for k,v in pairs(gMapBlockWaterGfxList) do k:SetVisible(false) end
	
	WaterBlendOutBelowZ(gMapBlockWaterZ)
	
	gWaterReflectionCam:EnableReflection(0,0,gMapBlockWaterZ, 0,0,1)
end

local function WaterPostRenderReflection	()
	for k,v in pairs(gMapBlockWaterGfxList) do k:SetVisible(true) end
	
	WaterRestoreBlendOut()

	gWaterReflectionCam:DisableReflection()	
end

-- setup ----------------------------------------------
function WaterTeardownReflection	()
	if gWaterShaderRunning then
		-- TODO kill rtt stuff
	end
end

function WaterSetupReflection	()
	-- setup the rtt stuff
	if not gWaterShaderRunning then
		gWaterShaderRunning = true

		local mat = "Water/FresnelReflectionRefraction"

		local size = 512

		local cam = GetMainCam()
		
		
		gWaterReflectionCam = CreateCamera()
		gWaterReflectionCam:SetNearClipDistance(cam:GetNearClipDistance())
		gWaterReflectionCam:SetFarClipDistance(cam:GetFarClipDistance())
		
		gWaterReflectionTex = CreateRenderTexture("Reflection", size, size, PF_R8G8B8)
		--~ gWaterReflectionTex:SetAutoUpdated(true)
		local vp = CreateRTTViewport(gWaterReflectionTex,gWaterReflectionCam)
		vp:SetOverlaysEnabled(false)
		SetTexture(mat,"Reflection",0,0,1)
		gWaterReflectionTex:SetPrePostFunctions(WaterPreRenderReflection,WaterPostRenderReflection)


		gWaterRefractionTex = CreateRenderTexture("Refraction", size, size, PF_R8G8B8)
		--~ gWaterRefractionTex:SetAutoUpdated(true)
		local vp = CreateRTTViewport(gWaterRefractionTex,cam)
		vp:SetOverlaysEnabled(false)
		SetTexture(mat,"Refraction",0,0,2)
		gWaterRefractionTex:SetPrePostFunctions(WaterPreRenderRefraction,WaterPostRenderRefraction)
	end
end





-- forall entities fun(entity)
function cMapBlock_3D_Water:ForAllEntities (fun)
	--~ if self.mTileBatch then self.mTileBatch:ForAllTiles(fun) end
end

function cMapBlock_3D_Water:GetDisplayRange ()
	--~ if self.mTileBatch then return self.mTileBatch:GetDisplayRange() end
end

function cMapBlock_3D_Water:SetDisplayRange (fmin, fmax)
	--~ if self.gfx and self.gfx:IsAlive() then self.gfx:FastBatch_SetDisplayRange(fmin,fmax) end
end

function cMapBlock_3D_Water:ClearDetail ()
	self.mWaterZMap = {}
	if self.gfx and self.gfx:IsAlive() then 
		gMapBlockWaterGfxList[self.gfx] = nil 
		
		local x,y,z = self.gfx:GetPosition(x, y, z)
		
		gMapBlockWaterZSum = gMapBlockWaterZSum - z
		gMapBlockWaterBlockCount = gMapBlockWaterBlockCount - 1
		
		UpdateReflectionPlaneZ()
		
		self.gfx:Destroy() 
	end
end

function cMapBlock_3D_Water:SetWaterZWithoutBorder	(tx, ty, z)
	if not self.mWaterZMap then self.mWaterZMap = {} end
	
	if 
		tx >= 0 and 
		tx < self.iBlockSize and 
		ty >= 0 and 
		ty < self.iBlockSize
	then 
		--~ print("SetWaterZ",self.bx,self.by, tx, ty, z)
		Array2DSet(self.mWaterZMap, tx,ty, math.max(Array2DGet(self.mWaterZMap, tx,ty) or z, z))
	end
end

function cMapBlock_3D_Water:SetWaterZ	(tx, ty, z)
	self:SetWaterZWithoutBorder(tx,ty,z)

	-- set border of 1 tile
	-- this is slow
	--~ self:SetWaterZWithoutBorder(tx+1,ty+0,z)
	--~ self:SetWaterZWithoutBorder(tx-1,ty+0,z)
	--~ self:SetWaterZWithoutBorder(tx+0,ty+1,z)
	--~ self:SetWaterZWithoutBorder(tx+0,ty-1,z)
	--~ 
	--~ self:SetWaterZWithoutBorder(tx+1,ty+1,z)
	--~ self:SetWaterZWithoutBorder(tx-1,ty-1,z)
	--~ self:SetWaterZWithoutBorder(tx+1,ty-1,z)
	--~ self:SetWaterZWithoutBorder(tx-1,ty+1,z)
end

function cMapBlock_3D_Water:WorkStep_LoadDetail ()
	self.mWaterZMap = {}

	--~ print("cMapBlock_3D_Water:WorkStep_LoadDetail",self.bx,self.by)
	
	-- uo map block position
	local iBlockUO_X = math.floor(self.bx * self.iBlockSize / 8)
	local iBlockUO_Y = math.floor(self.by * self.iBlockSize / 8)

	-- calculate water height
	local iTileTypeID,iX,iY,iZ,iHue
	local xloc,yloc

	local blocks = math.floor((self.iBlockSize-1) / 8)+1

	local basex,basey,w,h = self:GetAABB()

	for x = 0,blocks-1 do
		for y = 0,blocks-1 do
			-- check static block
			local l = MapGetBlockStatics(iBlockUO_X+x,iBlockUO_Y+y)

			for k,s in pairs(l) do 
				iTileTypeID,iX,iY,iZ,iHue = s.artid, s.tx, s.ty, s.zloc, s.hue
				
				if not gConfig:Get("gWaterAsGroundTiles") and iTileTypeID and FilterIsStaticWater(iTileTypeID) and iX and iY and iZ then 
					-- uo tile pos
					local xloc,yloc = (iBlockUO_X+x)*8+iX,(iBlockUO_Y+y)*8+iY
					--~ print("DEBUG","water",x,y,basex,basey,xloc,yloc,iZ)
					self:SetWaterZ(xloc-basex,yloc-basey,iZ)					
					self:YieldIfOverTime()
				end
			end 
			
			-- check ground block
			for lx = 0,7 do
				for ly = 0,7 do
					local xloc,yloc = (iBlockUO_X+x)*8+lx,(iBlockUO_Y+y)*8+ly
					local o = MapGetGround(xloc,yloc)
					
					if not gConfig:Get("gWaterAsGroundTiles") and o.iTileType and FilterIsMapWater(o.iTileType) then
						self:SetWaterZ(xloc-basex,yloc-basey,o.zloc)					
						self:YieldIfOverTime()
					end
				end
			end
	end end
	
	self:Yield()
	
	-- check dynamics
	if not gConfig:Get("gWaterAsGroundTiles") then
		local d = self.iBlockSize
		local tbx = d * self.bx
		local tby = d * self.by
		for x = tbx,tbx+d-1 do
		for y = tby,tby+d-1 do
		for k,dynamic in pairs(GetDynamicsAtPosition(x,y)) do 
			if dynamic.artid and FilterIsStaticWater(dynamic.artid) then
				self:SetWaterZ(dynamic.xloc-basex,dynamic.yloc-basey,dynamic.zloc)					
			end
		end
		end
		end
	end
	
	-- WATER
	local count = Array2DGetElementCount(self.mWaterZMap) -- might be slow
	
	self:Yield()
	
	local tiles = self.iBlockSize
	
	--~ print("DEBUG",count)
	if (count and count > 0) then
		
		-- create water
		
		if not self.gfx or not self.gfx:IsAlive() then self.gfx = CreateRootGfx3D() end
		
		local gfx = self.gfx
		local vc = 4 * count
		local ic = 6 * count
		
		gfx:SetSimpleRenderable()
		
		gfx:RenderableBegin(vc,ic,false,false,OT_TRIANGLE_LIST)
		
		--~ print("DEBUG","WATERSTART",count,vc,ic)
		local index = 0
		local x,y,z

		Array2DForAll(self.mWaterZMap, function(z, x,y)
			z = z * 0.1

			--~ print("DEBUG","water tile",x,y,z)
			gfx:RenderableVertex(-x,y,z, 0,0,1, (x)/tiles, y/tiles)
			gfx:RenderableVertex(-x-1,y,z, 0,0,1, ((x+1))/tiles, y/tiles)
			gfx:RenderableVertex(-x,y+1,z, 0,0,1, (x)/tiles, (y+1)/tiles)
			gfx:RenderableVertex(-x-1,y+1,z, 0,0,1, ((x+1))/tiles, (y+1)/tiles)
			
			gfx:RenderableIndex3(index+0, index+2, index+1)
			gfx:RenderableIndex3(index+1, index+2, index+3)
			
			index = index + 4
		end)

		gfx:RenderableEnd()

		gMapBlockWaterGfxList[gfx] = true

		gfx:SetCastShadows(false)
		
		x,y,z = Renderer3D:UOPosToLocal(basex, basey, 0.1)

		gfx:SetPosition(x, y, z)

		gMapBlockWaterZSum = gMapBlockWaterZSum + z
		gMapBlockWaterBlockCount = gMapBlockWaterBlockCount + 1
		
		if gUseWaterShader then
			gfx:SetMaterial("Water/FresnelReflectionRefraction")
			WaterSetupReflection()
			UpdateReflectionPlaneZ()
		else
			gfx:SetMaterial("water")
		end
	end
end
