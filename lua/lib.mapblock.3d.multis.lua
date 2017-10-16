-- todo

cMapBlock_3D_Multis	= CreateClass(cMapBlockAABB)
cMapBlock_3D_Multis.iLoadRadius				= 64 -- in tiles  -- TODO : all other mapblock loaders are in iBlockSize-blocks, is this here a bug ?
cMapBlock_3D_Multis.kMaxDist_Visible		= 32 -- camdist in tiles  see mapblock.base for default
cMapBlock_3D_Multis.kMaxDist_Detail			= 64 -- camdist in tiles

function cMapBlock_3D_Multis:Init (multi)
	local x,y,xx,yy
	
	-- calc aabb
	for k,v in pairs(multi.lparts) do
		local iTileTypeID,iX,iY,iZ,iHue = unpack(v)
		
		x = x and math.min(x, iX) or iX
		y = y and math.min(y, iY) or iY
		
		xx = xx and math.max(xx, iX) or iX
		yy = yy and math.max(yy, iY) or iY
	end

	cMapBlockAABB.Init(self, x,y,xx-x+1,yy-y+1)
	self.mMulti = multi
end

-- forall entities fun(entity)
function cMapBlock_3D_Multis:ForAllEntities (fun)
	if self.mTileBatch then self.mTileBatch:ForAllTiles(fun) end
end

function cMapBlock_3D_Multis:GetDisplayRange ()
	if self.mTileBatch then return self.mTileBatch:GetDisplayRange() end
end

function cMapBlock_3D_Multis:SetDisplayRange (fmin, fmax)
	if self.mTileBatch then self.mTileBatch:SetDisplayRange(fmin,fmax) end
end

function cMapBlock_3D_Multis:ClearRough   () end -- override me !
function cMapBlock_3D_Multis:WorkStep_LoadRough  () end -- override me !

function cMapBlock_3D_Multis:ClearDetail  () 
	if self.mTileBatch then self.mTileBatch:Clear() end
end

function cMapBlock_3D_Multis:WorkStep_LoadDetail ()
	if not self.mTileBatch then
		self.mTileBatch = CreateClassInstance(cTileBatch)
	end
		
	-- preload
	for k,v in pairs(self.mMulti.lparts) do
		local iTileTypeID,iX,iY,iZ,iHue = unpack(v)
		--~ self.mTileBatch:PreloadTile(iTileTypeID,iX,iY,iZ,iHue)
		--~ self:YieldIfOverTime()
		
		local meshname = GetMeshName(iTileTypeID,iHue)
		if meshname then
			local meshbuffer = GetMeshBuffer(meshname)

			local xadd,yadd,zadd = FilterPositionXYZ(iTileTypeID)
			local x,y,z = Renderer3D:UOPosToLocal(iX + xadd,iY + yadd,iZ * 0.1 + zadd) 
			local qw,qx,qy,qz = GetStaticMeshOrientation(iTileTypeID)

			--~ mirroring now baked into meshes for shader compatibility -- mousepick.sx=-1
			local mousepick = {
				xadd=xadd,yadd=yadd,zadd=zadd,qw=qw,qx=qx,qy=qy,qz=qz,
				sx=1,sy=1,sz=1,x=x,y=y,z=z,meshbuffer=meshbuffer,
				iTileTypeID = iTileTypeID,
				iHue = iHue,
				iBlockX = math.floor(x/8), iBlockY = math.floor(y/8),
			}
		
			v.multi_mousepick = mousepick
		end

		self:YieldIfOverTime()		
	end
		
	self:Yield()

	self.mTileBatch:Clear()

	-- add parts
	for k,v in pairs(self.mMulti.lparts) do
		self.mTileBatch:AddTile(unpack(v))
	end

	self.mTileBatch:Build()

	self:SetDisplayRange(gCurrentRenderer:BlendoutGetVisibleRange())
end
