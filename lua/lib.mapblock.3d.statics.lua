
--[[
	This table contains mappings from map tile types to
	static tile types. This is used for floor tiles on the
	map that have a uniform height.
]]
gMapToStaticTable = {
	-- maps ground tile id to static tile id
	[0x406] = 0x4a9, -- Wooden floor
	[0x407] = 0x4aa, -- Wooden floor
	[0x408] = 0x4ab, -- Wooden floor
	[0x409] = 0x4ac, -- Wooden floor
}


cMapBlock_3D_Statics	= CreateClass(cMapBlockGrid)
cMapBlock_3D_Statics.iBlockSize		= 8*2 -- in tiles
cMapBlock_3D_Statics.iLoadRadius	= 4 -- in iBlockSize-blocks
cMapBlock_3D_Statics.kMaxDist_Visible		= cMapBlock_3D_Statics.iBlockSize * 8 -- camdist in tiles  see mapblock.base for default
cMapBlock_3D_Statics.kMaxDist_Detail		= cMapBlock_3D_Statics.iBlockSize * 4 -- camdist in tiles

-- forall entities fun(entity)
function cMapBlock_3D_Statics:ForAllEntities (fun)
	if self.mTileBatch then self.mTileBatch:ForAllTiles(fun) end
end

function cMapBlock_3D_Statics:GetDisplayRange ()
	if self.mTileBatch then return self.mTileBatch:GetDisplayRange() end
end

function cMapBlock_3D_Statics:SetDisplayRange (fmin, fmax)
	if self.mTileBatch then self.mTileBatch:SetDisplayRange(fmin,fmax) end
end

function cMapBlock_3D_Statics:ClearDetail ()
	if self.mTileBatch then self.mTileBatch:Clear() end
end

function cMapBlock_3D_Statics:WorkStep_LoadDetail ()
	--~ print("cMapBlock_3D_Statics:WorkStep_LoadDetail",self.bx,self.by)
	
	if not self.mTileBatch then
		self.mTileBatch = CreateClassInstance(cTileBatch)
	else
		self.mTileBatch:Clear()
	end
	
	-- uo map block position
	local iBlockUO_X = math.floor(self.bx * self.iBlockSize / 8)
	local iBlockUO_Y = math.floor(self.by * self.iBlockSize / 8)

	-- preload models
	local iTileTypeID,iX,iY,iZ,iHue
	local xloc,yloc

	local blocks = math.floor((self.iBlockSize-1) / 8)+1

	local mygWaterAsGroundTiles = gConfig:Get("gWaterAsGroundTiles")
	for x = 0,blocks-1 do
		for y = 0,blocks-1 do
			local l = MapGetBlockStatics(iBlockUO_X+x,iBlockUO_Y+y)

			-- static tiles
			for k,s in pairs(l) do 
				iTileTypeID,iX,iY,iZ,iHue = s.artid, s.tx, s.ty, s.zloc, s.hue
				
				if (mygWaterAsGroundTiles or not FilterIsStaticWater(iTileTypeID)) and iTileTypeID and iX and iY and iZ and (not FilterSkipStatic(iTileTypeID)) then 
					-- uo tile pos
					local xloc,yloc = (iBlockUO_X+x)*8+iX,(iBlockUO_Y+y)*8+iY
					if 
						xloc >= self.bx * self.iBlockSize and 
						xloc < (self.bx+1) * self.iBlockSize and 
						yloc >= self.by * self.iBlockSize and 
						yloc < (self.by+1) * self.iBlockSize
					then 
						self.mTileBatch:AddTile(iTileTypeID,xloc,yloc,iZ,iHue)
						self:YieldIfOverTime()
					end
				end
			end 
			
			-- ground tiles
			for lx = 0, 7 do
				for ly = 0, 7 do
					local bx,by = iBlockUO_X+x, iBlockUO_Y+y
					local xloc = bx * 8 + lx
					local yloc = by * 8 + ly
					local o = MapGetGround(xloc,yloc)
					local staticType = gMapToStaticTable[o.iTileType]

					if staticType then
						--~ print("Creating static tile @ ",xloc,yloc,o.zloc)
						self.mTileBatch:AddTile(staticType,xloc,yloc,o.zloc,0)
						self:YieldIfOverTime()
					end
				end 
			end
	end end
	
	self:Yield()

	self.mTileBatch:Build()
	
	self:SetDisplayRange(gCurrentRenderer:BlendoutGetVisibleRange())
end
