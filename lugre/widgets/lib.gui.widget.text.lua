-- see also lib.gui.widget.lua
-- see also lib.glyphlist.lua
-- todo : wrap, align:center/left 
-- autoscroll?(textarea-widget)

RegisterWidgetClass("Text")

-- params : text,font,fontsize,textparam,autowrap_w,halign,valign
-- params.text : initial text
-- params.textparam : fontcolor/alpha etc
function gWidgetPrototype.Text:Init (parentwidget, params)
	self.spritelists = {}
	self.glyphlist = CreateGlyphList()
	self:InitAsGroup(parentwidget,params)
	if (params.text) then self:AddText(params.font,params.fontsize,params.text,params.textparam) end
end

gProfiler_TextWidget = CreateRoughProfiler("  TextWidget")

-- returns the unwrapped size of the text based on the size of the glyphes
function gWidgetPrototype.Text:GetUnwrappedTextSize () return self.glyphlist:GetUnwrappedTextSize() end

function gWidgetPrototype.Text:on_destroy () self.glyphlist:ClearAndReleaseMemory() end
function gWidgetPrototype.Text:SetText (font,fontsize,text,textparam)
	gProfiler_TextWidget:Start(gEnableProfiler_TextWidget)
	gProfiler_TextWidget:Section("glyphlist:SetText")
	if (type(font) == "string") then  -- param overload :SetText(text)
		local text = font -- first and only param
		local params = self.params
		self.glyphlist:SetText(params.font,params.fontsize,text,params.textparam)
	else
		self.glyphlist:SetText(font,fontsize,text,textparam)
	end
	gProfiler_TextWidget:Section("UpdateGeometry")
	self:UpdateGeometry()
	gProfiler_TextWidget:End()
end

function gWidgetPrototype.Text:AddText (font,fontsize,text,textparam)
	self.glyphlist:AddText(font,fontsize,text,textparam)
	self:UpdateGeometry()
end

function gWidgetPrototype.Text:_ClearSpriteLists ()
	for k,spritelist in pairs(self.spritelists) do spritelist:Destroy() end
	self.spritelists = {}
end

function gWidgetPrototype.Text._UpdateGeometry_Visitor (x,y,glyph,glyphindex,self)
	local g = glyph.glyphinfo
	if (not g) then return end
	
	-- printable char or image
	if (not self._text_spritelist_end_index) then
		-- determine how many glyphs until matname-change
		local len = 1
		local spritecount = 1
		local matname = glyph.glyphinfo.matname
		local glyphcount = self.glyphlist:GetGlyphCount()
		for i=glyphindex+1,glyphcount do 
			local glyphinfo = self.glyphlist.glyphs[i].glyphinfo
			if (glyphinfo and matname ~= glyphinfo.matname) then break end 
			len = len + 1
			if (glyphinfo) then spritecount = spritecount + 1 end
		end
		self._text_spritelist_end_index = glyphindex + len
		
		-- close last spritelist
		if (self._text_lastspritelist) then 
			SpriteList_Close() 
			--~ print("widget.text:close",self._text_iSpriteIndex,self._text_iSpriteListLen)
			--~ if (self._text_iSpriteIndex < self._text_iSpriteListLen) then print("widget.text:len error",self._text_iSpriteIndex,self._text_iSpriteListLen) end
		end
		
		-- start new spritelist
		local spritelist = CreateSpriteList(self.rendergroup2d,false,true) 
		table.insert(self.spritelists,spritelist)
		spritelist:SetMaterial(matname)
		--~ print("widget.text spritelistlen",spritecount)
		spritelist:ResizeList(spritecount)
		SpriteList_Open(spritelist)
		self._text_lastspritelist = spritelist
		self._text_iSpriteIndex = 0
		self._text_iSpriteListLen = spritecount
	end
	
	-- add the sprite to the list
	
	local param = glyph.param
	
	--~ print("textglyph",glyphindex,sprintf("%c",g.iCharCode or 0),floor(x),floor(y),g.xoff,g.yoff,g.w,g.h, g.u0,g.v0, g.ux,g.vx, g.uy,g.vy)
	
	--~ print("widget.text ",self._text_iSpriteIndex, g.xoff+x,g.yoff+y,g.w,g.h, g.u0,g.v0, g.ux,g.vx, g.uy,g.vy)
	SpriteList_SetSpriteEx(self._text_iSpriteIndex, g.xoff+floor(x),g.yoff+floor(y),g.w,g.h, g.u0,g.v0, g.ux,g.vx, g.uy,g.vy, 
		param.z or 0, 
		param.r or 1,
		param.g or 1,
		param.b or 1,
		param.a or 1)
	self._text_iSpriteIndex = self._text_iSpriteIndex + 1
	if (self._text_spritelist_end_index == glyphindex) then
		self._text_spritelist_end_index = nil -- start new mat
	end
end

function gWidgetPrototype.Text:SetCol (r,g,b,a)
	--~ self.params.col = {r=r,g=g,b=b,a=a}
	local param = self.params.textparam
	param.r = r
	param.g = g
	param.b = b
	param.a = a
end

function gWidgetPrototype.Text:UpdateGeometry ()
	gProfiler_TextWidget:Start(gEnableProfiler_TextWidget)
	gProfiler_TextWidget:Section("UpdateGeometry:ClearSpriteLists")
	self:_ClearSpriteLists()
	self._text_spritelist_end_index = nil
	local p = self.params
	local startindex,endindex
	gProfiler_TextWidget:Section("UpdateGeometry:glyphlist:VisitGlyphs")
	self.glyphlist:VisitGlyphs(self._UpdateGeometry_Visitor,self,startindex,endindex,p.autowrap_w,p.halign,p.valign)
	gProfiler_TextWidget:Section("UpdateGeometry:SpriteList_Close")
	if (self._text_lastspritelist) then 
		SpriteList_Close() self._text_lastspritelist = nil 
		--~ print("widget.text:close2",self._text_iSpriteIndex,self._text_iSpriteListLen)
		--~ if (self._text_iSpriteIndex < self._text_iSpriteListLen) then print("widget.text-final:len error",self._text_iSpriteIndex,self._text_iSpriteListLen) end
	end
	gProfiler_TextWidget:End()
end
