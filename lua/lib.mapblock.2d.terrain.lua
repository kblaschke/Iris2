cMapBlock_2D_Terrain	= CreateClass(cMapBlockGrid)
cMapBlock_2D_Terrain.iBlockSize				= 8*2 -- in tiles
cMapBlock_2D_Terrain.iLoadRadius			= 4 -- in iBlockSize-blocks
--~ cMapBlock_2D_Terrain.kMaxDist_Visible		= 8*4 -- camdist in tiles  see mapblock.base for default
--~ cMapBlock_2D_Terrain.kMaxDist_Detail		= 8*2 -- camdist in tiles

function cMapBlock_2D_Terrain:ClearDetail ()
	if (self.gfx_terrain) then self.gfx_terrain:Destroy() self.gfx_terrain = nil end
end

function cMapBlock_2D_Terrain:UpdateBlendOutVisibility ()
	if (self.gfx_terrain) then self.gfx_terrain:SetVisible(gCurrentRenderer.gbBlendOutTerrainVisible) end
end

function cMapBlock_2D_Terrain:RecalcLOD () return self.kLOD_Detail end

-- returns dist,xloc,yloc   if hit, or nil if not hit.    sprite={artid=?,hue=?,static=?}
function cMapBlock_2D_Terrain:RayPick (rx,ry,rz, rvx,rvy,rvz) 
	local gfx = self.gfx_terrain 
	if (not gfx) then return end
	local bx,by,bs = self.bx * 2, self.by * 2, 2
	local bHit,fHitDist,tx,ty = TerrainMultiTex_RayPick(gGroundBlockLoader,bx,by,bs,bs,kRenderer2D_ZScale, rx-gfx.x,ry-gfx.y,rz-gfx.z, rvx,rvy,rvz)
	if (not bHit) then return end
	return fHitDist,bx * 8 + tx,by*8 + ty
end

function cMapBlock_2D_Terrain:WorkStep_LoadDetail ()
	local bs = kMultiTexTerrainChunkSize
	self:ClearDetail()
	if (not Renderer2D.bMinimalGfx) then 
		self.gfx_terrain = MakeMultiTexTerrainGfx(self.bx * bs,self.by * bs,kRenderer2D_ZScale)
	end
	self:UpdateBlendOutVisibility()
end
