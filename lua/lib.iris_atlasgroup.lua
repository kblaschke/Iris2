--[[ ***** see Iris2 COPYING for license info ***** ]]--
--[[ \brief
        see also lib.atlasgroup.lua in lugre
        see also lib.artatlas.lua ... obsolete ?
        TODO : longterm . releasing parts of the atlas, keep a log which one belongs where... last recently/frequently used ?
        TODO : longterm . bulk loading ?   lib.artalas.lua
]]--

kIrisAtlasGroupSize = 512*2

gAtlasGroup_Gump	= CreateAtlasGroup(kIrisAtlasGroupSize,kIrisAtlasGroupSize)
gAtlasGroup_Art		= CreateAtlasGroup(kIrisAtlasGroupSize,kIrisAtlasGroupSize)

function PreLoadGump		(gump_id,hue)	if (gump_id) then return gAtlasGroup_Gump:LoadToAtlas(gump_id,hue) end end
function PreLoadArt			( art_id,hue)	if ( art_id) then return gAtlasGroup_Art:LoadToAtlas(art_id,hue) end end

function GetGumpSize	(gump_id,hue)	return gAtlasGroup_Gump:GetSize(gump_id,hue) end -- loads it and returns the size
function GetArtSize		(art_id,hue) 	return gAtlasGroup_Art:GetSize(art_id,hue) end


-- returns matname,u0,v0,uvw,uvh,origw,origh,bitmask
function LoadGump	(basemat,gump_id,hue) 
	--~ if (true) then return "BaseWhiteNoLighting",0,0,1,1,22,22,nil end -- TODO 
	local matname,u0,v0,uvw,uvh,origw,origh = gAtlasGroup_Gump:LoadMat(basemat,gump_id,hue)
	local bitmask = matname and gAtlasGroup_Gump.bitmasks and gAtlasGroup_Gump.bitmasks[gump_id]
	return matname,u0,v0,uvw,uvh,origw,origh,bitmask
end

-- returns matname,u0,v0,uvw,uvh,origw,origh,bitmask
function LoadArt	(basemat,art_id,hue)
	--~ if (true) then return "BaseWhiteNoLighting",0,0,1,1,22,22,nil end -- TODO 
	local matname,u0,v0,uvw,uvh,origw,origh = gAtlasGroup_Art:LoadMat(basemat,art_id,hue)
	local bitmask = gAtlasGroup_Art.bitmasks[art_id]
	return matname,u0,v0,uvw,uvh,origw,origh,bitmask
end

-- returns img
function gAtlasGroup_Gump:LoadImpl (gump_id,hue)
	if (not gGumpLoader) then return end
	local img = CreateImage()
	local bSuccess = gGumpLoader:ExportToImage(img,gump_id,gHueLoader,hue or 0)
	if (not self.bitmasks) then self.bitmasks = {} end
	if (not bSuccess) then img:Destroy() return end
	if (not self.bitmasks[gump_id]) then local bm = img:GenerateBitMask() bm:SetWrap(true) self.bitmasks[gump_id] = bm end
	return img
end

-- returns img
function gAtlasGroup_Art:LoadImpl (art_id,hue)
	local img = CreateImage()
	local bSuccess = gArtMapLoader:ExportToImage(img,art_id,gHueLoader,hue or 0)
	if (not self.bitmasks) then self.bitmasks = {} end
	if (not bSuccess) then img:Destroy() return end
	if (not self.bitmasks[art_id]) then local bm = img:GenerateBitMask() bm:SetWrap(true) self.bitmasks[art_id] = bm end
	return img
end



