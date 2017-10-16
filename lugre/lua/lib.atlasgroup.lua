-- for loading a bunch of non-power-of-two images into texture atlases

gAtlasGroupPrototype = {}

function CreateAtlasGroup (w,h,iBorderPixels,bWrap)
	local atlasgroup = CopyArray(gAtlasGroupPrototype)
	atlasgroup.bWrap = bWrap or false
	atlasgroup.iBorderPixels = iBorderPixels or 4
	atlasgroup.w = w
	atlasgroup.h = h
	atlasgroup.cache		= {}
	atlasgroup.matcache		= {}
	atlasgroup.atlas_list	= {}
	return atlasgroup
end

-- preload, doesn't create/update material
-- returns atlaspiece   
-- img_or_nil : only if the function is used to store data in the atlas without using the LoadImpl, img is destroyed automatically
function gAtlasGroupPrototype:LoadToAtlas (id,param,img_or_nil)
	local cachename = param and (id..","..param) or id
	local cache = self.cache[cachename]
	if (cache) then return cache end
	if (cache == false) then return end
	local img = img_or_nil or self:LoadImpl(id,param)
	local atlas,u0,v0,u1,v1,origw,origh = self:AddImageToAtlasGroup(img)
	if (img and (not img_or_nil)) then img:Destroy() end
	if (not atlas) then self.cache[cachename] = false return end
	local atlaspiece = {
		atlas	=atlas,
		u0		=u0,
		v0		=v0,
		u1		=u1,
		v1		=v1,
		uvw		=u1-u0,
		uvh		=v1-v0,
		origw	=origw,
		origh	=origh}
	self.cache[cachename] = atlaspiece
	return atlaspiece
end

-- returns atlas,u0,v0,u1,v1,origw,origh
function gAtlasGroupPrototype:AddImageToAtlasGroup (img)
	if (not img) then return end
	local b = self.iBorderPixels
	local origw,origh = img:GetWidth(),img:GetHeight()
	if b+origw+b > self.w or b+origh+b > self.h then print("AddImageToAtlasGroup failed,too big",origw,origh,b,self.w,self.h) return end
	
	-- try to add to all existing atlases, might fit in if it's a small image
	for k,atlas in ipairs(self.atlas_list) do
		local bSuccess,u0,u1,v0,v1 = atlas:AddImage(img,b,self.bWrap)
		if (bSuccess) then  atlas.bDirty = true  return atlas,u0,v0,u1,v1,origw,origh  end
	end
	
	-- create new atlas and try to add to that
	local atlas = CreateTexAtlas(self.w,self.h)
	atlas.atlasgroup = self
	table.insert(self.atlas_list,atlas)
	
	local bSuccess,u0,u1,v0,v1 = atlas:AddImage(img,b,self.bWrap)
	if (bSuccess) then  atlas.bDirty = true  return atlas,u0,v0,u1,v1,origw,origh  end
	-- if it still fails, we have to give up, probably image larger than atlas resolution
	print("AddImageToAtlasGroup failed",origw,origh)
end

-- returns origw,origh
function gAtlasGroupPrototype:GetSize (id,param)
	local atlaspiece = self:LoadToAtlas(id,param)
	if (not atlaspiece) then return end
	return atlaspiece.origw,atlaspiece.origh
end

gAtlasGroups_DelayedUpdateList = {}
function AtlasGroups_UpdateDelayed ()
	for atlas,v in pairs(gAtlasGroups_DelayedUpdateList) do 
		if (atlas.texname) then 
			atlas:LoadToTexture(atlas.texname) -- update existing texture
		else
			atlas.texname = atlas:MakeTexture() -- generate new texture
		end
		atlas.bDirty = false
		gAtlasGroups_DelayedUpdateList[atlas] = nil
	end
end
RegisterStepper(AtlasGroups_UpdateDelayed)

-- returns matname
function gAtlasGroupPrototype:LoadAtlasMat		(atlas,basemat) 
	if (not atlas) then return end
	if (not atlas.texname) then atlas.texname = atlas:MakeTexture() end
	
	if (atlas.bDirty) then gAtlasGroups_DelayedUpdateList[atlas] = true end
	--[[
	old : immediate update, now delayed in case the atlas is updated again before rendering the frame
	if (atlas.bDirty) then 
		if (atlas.texname) then 
			atlas:LoadToTexture(atlas.texname) -- update existing texture
		else
			atlas.texname = atlas:MakeTexture() -- generate new texture
		end
		atlas.bDirty = false
	end
	]]--
	local texname = atlas.texname
	local matcachename = basemat..","..texname
	local matname = self.matcache[matcachename]
	if (matname ~= nil) then return matname end
	matname = CloneMaterial(basemat)
	if (not matname) then print("gAtlasGroupPrototype:LoadAtlasMat failed to clone basemat",basemat) return end
	SetTexture(matname,texname,0,0,0)
	self.matcache[matcachename] = matname
	return matname
end



-- returns matname,u0,v0,uvw,uvh,origw,origh
function gAtlasGroupPrototype:LoadMat			(basemat,id,param)
	local p = self:LoadToAtlas(id,param)
	if (p) then
		local matname = self:LoadAtlasMat(p.atlas,basemat)
		if (matname) then return matname,p.u0,p.v0,p.uvw,p.uvh,p.origw,p.origh end
	end
end

--[[
	-- dump atlas image
	local img = CreateImage()
	atlas:MakeImage(img)
	gArtAtlasDebugDumpAtlasCount = (gArtAtlasDebugDumpAtlasCount or 0) + 1
	img:SaveAsFile("artatlas_"..gArtAtlasDebugDumpAtlasCount..".png")
	img:Destroy()
]]--
