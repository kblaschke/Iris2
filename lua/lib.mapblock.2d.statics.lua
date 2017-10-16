cMapBlock_2D_Statics	= CreateClass(cMapBlockGrid)
cMapBlock_2D_Statics.iBlockSize		= 8 -- in tiles
cMapBlock_2D_Statics.iLoadRadius	= 4 -- in iBlockSize-blocks

function cMapBlock_2D_Statics:ClearDetail ()
	if (self.spriteblock) then self.spriteblock:Destroy() self.spriteblock = nil self.bMyDetailLoaded = false end
end

-- returns dist,sprite   if hit, or nil if not hit.    sprite={artid=?,hue=?,static=?}
function cMapBlock_2D_Statics:RayPick (rx,ry,rz, rvx,rvy,rvz) 
	if (not self.spriteblock) then return end
	return self.spriteblock:RayPick(rx,ry,rz, rvx,rvy,rvz) 
end

function cMapBlock_2D_Statics:RecalcLOD () return self.kLOD_Detail end

function cMapBlock_2D_Statics:RebuildForBlendout ()
	if (not self.bMyDetailLoaded) then return end
	if (gDebug_DisableStatics) then return end
	
	local iBlendOutMinZ,iBlendOutMaxZ = gCurrentRenderer:BlendoutGetVisibleRange()
	if (self.iBlendOutMinZ == iBlendOutMinZ and
		self.iBlendOutMaxZ == iBlendOutMaxZ) then return end -- no change
	--~ print("cMapBlock_2D_Statics:RebuildForBlendout",iBlendOutMinZ,iBlendOutMaxZ)
	self.iBlendOutMinZ = iBlendOutMinZ
	self.iBlendOutMaxZ = iBlendOutMaxZ
	
	self:ClearDetail()
	self.statics = MapGetBlockStatics(self.bx,self.by)
	local spriteblock = cUOSpriteBlock:New()
	self.spriteblock = spriteblock
	for i,static in pairs(self.statics) do 
		if (static.zloc >= iBlendOutMinZ and static.zloc <= iBlendOutMaxZ) then spriteblock:AddStatic(static) end
	end
	spriteblock:Build(Renderer2D.kSpriteBaseMaterial)
	local x,y,z = gCurrentRenderer:UOPosToLocal(self.bx*8,self.by*8,0)
	spriteblock:SetPosition(x,y,z)
	self.bMyDetailLoaded = true
end

function cMapBlock_2D_Statics:WorkStep_LoadDetail ()
	if (Renderer2D.bMinimalGfx) then return end 
	if (gDebug_DisableStatics) then return end
	
	local iBlendOutMinZ,iBlendOutMaxZ = gCurrentRenderer:BlendoutGetVisibleRange()
	self.iBlendOutMinZ = iBlendOutMinZ
	self.iBlendOutMaxZ = iBlendOutMaxZ
		
	self:ClearDetail()
	
	-- statics : load infos from file
	self.statics = MapGetBlockStatics(self.bx,self.by)
	self:YieldIfOverTime()
	
	-- create spriteblock
	local spriteblock = cUOSpriteBlock:New()
	self.spriteblock = spriteblock
	
	local xloc = self.bx*8
	local yloc = self.by*8
	for tx = 0,7 do 
	for ty = 0,7 do 
		local tiletype,zloc = GetGroundAtAbsPos(xloc+tx,yloc+ty)
		if (gWaterGroundByTileTypes[tiletype]) then spriteblock:AddWaterTile(tx,ty,zloc,tiletype) end
	end
	end
	self:YieldIfOverTime()
	
	-- preload statics
	for i,static in pairs(self.statics) do 
		if (static.zloc >= iBlendOutMinZ and static.zloc <= iBlendOutMaxZ) then spriteblock:AddStatic(static) end
		self:YieldIfOverTime()
	end
	
	-- construct geometry
	self:Yield()
	spriteblock:Build(Renderer2D.kSpriteBaseMaterial)
	local x,y,z = gCurrentRenderer:UOPosToLocal(self.bx*8,self.by*8,0)
	spriteblock:SetPosition(x,y,z)
	self.bMyDetailLoaded = true
	self:RebuildForBlendout()
end
