-- see also lib.gui.flow.lua
-- extracts info of an ogre font to be usable by our guisystem

-- creates and returns a font object for an ogre font that can be used by the flow layouter to create text
-- call after ogre init
function CreateFont_Ogre (sFontName,iFontSize)
	local sMatName,tGlyphTable = ExportOgreFont(sFontName)
	--~ print("CreateFont_Ogre",sFontName,sMatName,tGlyphTable)
	--~ for k,glyph in pairs(tGlyphTable) do print("glyph",k,sprintf("%c",k),glyph.left,glyph.top) end
	
	sMatName = GetPlainTextureGUIMat(GetTexture(sMatName))
	
	local myfont = {}
	myfont.sFontType	= "OgreFont"
	myfont.sMatName		= sMatName
	--~ myfont.sTexName		= GetTexture(myfont.sMatName)
	
	--~ local img = LoadImageFromTexture(GetTexture(sMatName)) img:SaveAsFile("../font.png")
	
	myfont.tGlyphTable	= tGlyphTable
	myfont.zeroglyph	= myfont.tGlyphTable[kCharCode_SpaceWidthChar] -- take the width of the glyph 0 (zero) for space
	myfont.tSpaceAspect	= myfont.zeroglyph and myfont.zeroglyph.aspectRatio or 1
	
	iFontSize = iFontSize or 24
	
	myfont.GetDefaultFontSize	= function (self) return iFontSize end
	myfont.GetSpaceWidth		= function (self,fontsize) return self.tSpaceAspect * fontsize end
	myfont.GetLineHeight		= function (self,fontsize) return fontsize end
	myfont.GetGlyphInfo			= function (self,iCharCode,fontsize) 
		local glyph = self.tGlyphTable[iCharCode]
		if (not glyph) then return end
		local res	= {}
		res.u0		= glyph.left
		res.v0		= glyph.top
		res.ux		= glyph.right-res.u0
		res.vx		= 0
		res.uy		= 0
		res.vy		= glyph.bottom-res.v0
		res.h		= fontsize
		res.w		= res.h * glyph.aspectRatio
		res.xoff	= 0
		res.yoff	= 0
		res.xmove	= ceil(res.w)
		res.matname = self.sMatName
		
		--~ print("CreateFont_Ogre:GetGlyph:",sMatName,SmartDump(res))
		--~ print("CreateFont_Ogre:GetGlyph:",self,iCharCode,fontsize,res.matname, res.xmove, res.xoff,res.yoff,res.w,res.h, res.u0,res.v0)
		return res
	end
	return myfont
end
