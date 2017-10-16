cMapBlock_3D_Terrain	= CreateClass(cMapBlockGrid)
cMapBlock_3D_Terrain.iBlockSize		= 8*2 -- in tiles
cMapBlock_3D_Terrain.iLoadRadius	= 4 -- in iBlockSize-blocks
cMapBlock_3D_Terrain.kMaxDist_Visible		= cMapBlock_3D_Terrain.iBlockSize * 8 -- camdist in tiles  see mapblock.base for default
cMapBlock_3D_Terrain.kMaxDist_Detail		= cMapBlock_3D_Terrain.iBlockSize * 4 -- camdist in tiles

function cMapBlock_3D_Terrain:ClearDetail ()
	--~ print("cMapBlock_3D_Terrain:ClearDetail")
	if (self.gfx_terrain) then self.gfx_terrain:Destroy() self.gfx_terrain = nil end
end

function cMapBlock_3D_Terrain:WorkStep_LoadDetail ()
	--~ print("cMapBlock_3D_Terrain:WorkStep_LoadDetail",self.bx,self.by)
	local bs = kMultiTexTerrainChunkSize
	self.gfx_terrain = MakeMultiTexTerrainGfx(self.bx * bs,self.by * bs)
	self:UpdateBlendOutVisibility()
end


function cMapBlock_3D_Terrain:UpdateBlendOutVisibility ()
	--~ print("terrain:UpdateBlendOutVisibility",Renderer3D.gbBlendOutTerrainVisible)
	if (self.gfx_terrain) then self.gfx_terrain:SetVisible(Renderer3D.gbBlendOutTerrainVisible) end
end
