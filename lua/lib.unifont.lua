--[[ ***** see Iris2 COPYING for license info ***** ]]--
--[[ \brief
        handles uo unicode fonts textureatlas
        see also lugre/lib.gui.flow.lua
        todo : use lib.atlasgroup.lua here ?
]]--

gUniFontTexAtlasSize = 512
gUniFontLastTextureAtlas = nil

function UniFont_AtlasUpdate ()
	if (not gUniFontLastTextureAtlas.bDirty) then return end
	gUniFontLastTextureAtlas:LoadToTexture(gUniFontLastTextureAtlas.texname) -- update existing texture
	gUniFontLastTextureAtlas.bDirty = false
end
	
-- matname,u0,v0,u1,v1
function UniFont_AddImageToAtlas (glyphimg,bAvoidAtlasUpdate)
	local w = gUniFontTexAtlasSize
	if (gUniFontLastTextureAtlas == nil) then gUniFontLastTextureAtlas = CreateTexAtlas(w,w) end -- only first time
	
	-- add to exisiting texatlas or start a new one if it doesn't fit
	local bSuccess,l,r,t,b = gUniFontLastTextureAtlas:AddImage(glyphimg)
	if (not bSuccess) then 
		-- not more space in the old atlas, start a new one
		UniFont_AtlasUpdate()
		gUniFontLastTextureAtlas = CreateTexAtlas(w,w)
		bSuccess,l,r,t,b = gUniFontLastTextureAtlas:AddImage(glyphimg)
		if (not bSuccess) then print("warning, glyph too big for texatlas") return end
	end
	
	-- create or update texatlas
	if (gUniFontLastTextureAtlas.texname) then 
		gUniFontLastTextureAtlas.bDirty = true
		if (not bAvoidAtlasUpdate) then UniFont_AtlasUpdate() end
	else
		gUniFontLastTextureAtlas.texname = gUniFontLastTextureAtlas:MakeTexture() -- generate new texture
		gUniFontLastTextureAtlas.matname = GetPlainTextureGUIMat(gUniFontLastTextureAtlas.texname)
	end
	
	if (gUODumpFontImage) then local img = LoadImageFromTexture(GetTexture(gUniFontLastTextureAtlas.matname)) img:SaveAsFile("../font_"..gUniFontLastTextureAtlas.matname..".png") end
	
	-- return info about the allocated area for this glyph
	return gUniFontLastTextureAtlas.matname,l,t,r,b
end

-- texname,u0,v0,u1,v1,xoff,yoff,w,h
-- bold=outline for uo html
function GetUniFontGlyph (fontloader,iCharCode,bOutlined,bAvoidAtlasUpdate)
	if (not fontloader.glyphs) then fontloader.glyphs = {} end
	if (not fontloader.glyphs_outlined) then fontloader.glyphs_outlined = {} end
	local cachearr = bOutlined and fontloader.glyphs_outlined or fontloader.glyphs
	local glyphdata = cachearr[iCharCode]
	if (glyphdata) then return unpack(glyphdata) end
	if (glyphdata == false) then return false end -- not loadable, don't retry
	
	-- load glyph, add to texatlas
	glyphdata = false
	local img = CreateImage()
	local success = fontloader:WriteGlyphToImage(img,iCharCode,bOutlined)
	if (success) then
		local xoff,yoff,w,h = fontloader:GetGlyphInfo(iCharCode)
		local matname,u0,v0,u1,v1 = UniFont_AddImageToAtlas(img,bAvoidAtlasUpdate)
		if (matname) then glyphdata = {matname,u0,v0,u1,v1,xoff,yoff,w,h} end
	end
	img:Destroy()
	
	-- register in cache
	cachearr[iCharCode] = glyphdata
	if (not glyphdata) then return end
	return unpack(glyphdata)
end

function GetUOFont (loader,bOutlined) return CreateFont_UO(loader,bOutlined) end -- uses caching already

-- creates and returns a font object for one of the uo fonts that can be used by the flow layouter to create text
-- uofonts are pixelart and not scalable, so the size is fixed
-- bold=outline for uo html
function CreateFont_UO (loader,bOutlined)
	if (not loader) then return end
	if (bOutlined) then 
		if (loader.font_outlined) then return loader.font_outlined end -- caching font object, atlas is also be cached in loader
	else
		if (loader.font) then return loader.font end -- caching font object, atlas is also be cached in loader
	end
	local myfont = {}
	if (bOutlined) then loader.font_outlined = myfont else loader.font = myfont end
	local matname,u0,v0,u1,v1,xoff,yoff,w,h = GetUniFontGlyph(loader,kCharCode_SpaceWidthChar,bOutlined)
	myfont.sFontType	= "UOFont"
	myfont.glyphInfoCache = {}
	myfont.bOutlined = bOutlined
	myfont.spacewidth = w
	--~ myfont.defaultlineh = 1.5 * math.max(1,h)
	myfont.defaultlineh = 20
	myfont.GetDefaultFontSize	= function (self) return myfont.defaultlineh end
	myfont.GetSpaceWidth		= function (self,fontsize) return self.spacewidth end
	myfont.GetLineHeight		= function (self,fontsize) return self.defaultlineh end
	myfont.PreLoad				= function (self,preloadletters) 
		preloadletters = preloadletters or "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890:."
		local textlen = string.len(preloadletters)
		for i=1,textlen do GetUniFontGlyph(loader,string.byte(preloadletters,i),self.bOutlined,true) end -- bulkloading
		UniFont_AtlasUpdate()
	end
	myfont.GetGlyphInfo			= function (self,iCharCode,fontsize) 
		local cachebysize = myfont.glyphInfoCache[fontsize]
		if (not cachebysize) then cachebysize = {} myfont.glyphInfoCache[fontsize] = cachebysize end
		local cache = cachebysize[iCharCode]
		if (cache ~= nil) then return cache end
		local matname,u0,v0,u1,v1,xoff,yoff,w,h = GetUniFontGlyph(loader,iCharCode,self.bOutlined)
		if (not matname) then cachebysize[iCharCode] = false return end
		
		--~ local s = math.max(1,round(fontsize / myfont.defaultlineh)) -- pixelart is not freely scalable, but this would allow integer-multiples of the original size
		local s = 1
		local b = 2 -- border, the glyph image is actually bigger than the w,h returned by GetUniFontGlyph
		local overlapx = 3
		w,h = (b+w+b)*s,(b+h+b)*s
		
		local res	= {}
		local uvw, uvh = u1-u0,v1-v0
		res.iCharCode = iCharCode
		res.matname	= matname
		res.xmove	= ceil(w - overlapx*s + xoff*s)
		res.xoff	= floor(xoff)
		res.yoff	= floor(yoff - 1*self.defaultlineh)
		res.w	= floor(w) local a,b = floor(w),floor(uvw*gUniFontTexAtlasSize) if (a ~= b) then print("### unifont bad rounding w",a,b) end
		res.h	= floor(h) local a,b = floor(h),floor(uvh*gUniFontTexAtlasSize) if (a ~= b) then print("### unifont bad rounding h",a,b) end
		res.u0	= floor(u0*gUniFontTexAtlasSize) / gUniFontTexAtlasSize
		res.v0	= floor(v0*gUniFontTexAtlasSize) / gUniFontTexAtlasSize
		res.ux	= floor(uvw*gUniFontTexAtlasSize) / gUniFontTexAtlasSize
		res.vx	= 0
		res.uy	= 0
		res.vy	= floor(uvh*gUniFontTexAtlasSize) / gUniFontTexAtlasSize
		cachebysize[iCharCode] = res
		return res
	end
	return myfont
end

--~ gUniFontLoaderList[0] = unifont.mul
--~ gUniFontLoaderList[i] = unifont(1-6).mul

--[[
	-- texatlas
	local w = 1024
	local iArtMapIDList = {65,129,321,449,513}
	local sFilePath = "mytexatlas.png"
	local sFileNameOrPath = "art_fallback.png"
	local pTexAtlas = CreateTexAtlas(w,w)
	local img = CreateImage()
	for k,id in pairs(iArtMapIDList) do
		local iArtMapID = hex2num("0x00004000") + id
		if (gArtMapLoader:ExportToImage(img,iArtMapID)) then
			local b = 4
			local img2 = ImageScale(img,64-b-b,64-b-b)
			local bSuccess,l,r,t,b = pTexAtlas:AddImage(img2)
			img2:Destroy()
		end
	end
	--~ local sTexName =	pTexAtlas:MakeTexture()
	pTexAtlas:MakeImage(img)
	img:SaveAsFile(sFilePath)
	pTexAtlas:Destroy()
	img:Destroy()
	
	
	-- spritelist
	local spritelist = CreateSpriteList(GetGUILayer_Dialogs(),false,true)
	spritelist.asgroup = spritelist:CastToRenderGroup2D()
	spritelist.asgroup:SetClip(24,4,122,22)
	spritelist:SetMaterial(GetPlainTextureMat("guibase.png"))
	spritelist:ResizeList(1)
	print("--SpriteList_Open")
	SpriteList_Open(spritelist)
	local iSpriteIndex, l,t,w,h, u0,v0, uvw, uvh, z, r,g,b,a = 0, 0,0,32*4,32*4, 0,0, 1,1, 0,  1,0,0,0
	--~ SpriteList_SetSprite(iSpriteIndex, l,t,w,h, u0,v0, uvw, uvh, z)
	SpriteList_SetSpriteEx(iSpriteIndex, l,t,w,h, u0,v0, uvw,0, 0,uvh, z, r,g,b,a)
	SpriteList_Close()
]]--
