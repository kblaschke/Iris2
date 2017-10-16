-- see also lib.gui.widget.text.lua
-- see also lib.gui.flow.lua			(might be obsoleted by this)
-- see also lib.gui.font.lua			(loading ogre font)
-- see also iris/lua/lib.unifont.lua	(loading uo-unicode fonts)
-- autowrap : wraps whole words if possible, seperated by space

gGlyphListPrototype = {}
gGlyphListInstMetaTable = { __index=gGlyphListPrototype }

kCharCode_Space				= string.byte(" ",1)
kCharCode_Tab				= string.byte("\t",1)
kCharCode_Nl				= string.byte("\n",1) -- newline
kCharCode_Cr				= string.byte("\r",1) -- carriage return
kCharCode_SpaceWidthChar	= string.byte("0",1) -- this charcode is used to determine the width of "space"
kTabLen = 4

kGlyphList_HAlign_Left		= -1
kGlyphList_HAlign_Center	= 0
kGlyphList_HAlign_Right		= 1

kGlyphList_LineVAlign_Top		= -1
kGlyphList_LineVAlign_Center	= 0
kGlyphList_LineVAlign_Bottom	= 1

kGlyphType_FontChar			= 0
kGlyphType_Space			= 1
kGlyphType_Tab				= 2
kGlyphType_Newline			= 3
kGlyphType_Icon				= 4
kGlyphType_WordBreak		= 5 -- for wrapping icons 
kGlyphType_SetHAlign		= 6

-- param : user specified data, e.g. color or similar infos
function CreateGlyphList	(font,fontsize,text,param)
	local glyphlist = { glyphs={} }
	setmetatable(glyphlist,gGlyphListInstMetaTable)
	if (text) then glyphlist:AddText(font,fontsize,text,param) end
	return glyphlist
end

gProfiler_GlyphList = CreateRoughProfiler("  GlyphList")

function gGlyphListPrototype:Clear () self.glyphs = {} end
function gGlyphListPrototype:SetText (font,fontsize,text,param) self:Clear() self:AddText(font,fontsize,text,param) end
function gGlyphListPrototype:AddText (font,fontsize,text,param)
	if (not font) then return end
	gProfiler_GlyphList:Start(gEnableProfiler_GlyphList)
	gProfiler_GlyphList:Section("AddText:font:GetDefaultFontSize")
	fontsize = fontsize or font:GetDefaultFontSize()
	local textlen = string.len(text)
	gProfiler_GlyphList:Section("AddText:AddFontGlyph")
	for i=1,textlen do self:AddFontGlyph(font,fontsize,string.byte(text,i),param) end
	gProfiler_GlyphList:End()
end

-- returns the number of glyphs
function gGlyphListPrototype:GetGlyphCount () return #self.glyphs end

-- ugly hack, but garbage collection for tables seems a bit problematic for all the glyphs.. maybe we should code glyphlist in c?
function gGlyphListPrototype:ClearAndReleaseMemory () 
	for k1,glyph in pairs(self.glyphs) do 
		for k2,v in pairs(glyph) do glyph[k2] = nil end
		self.glyphs[k1] = nil
	end
	self.glyphs = {}
end

function gGlyphListPrototype:AddGlyph (glyph) 
	if (glyph.fontsize) then 
		glyph.lineh 	= glyph.font:GetLineHeight(glyph.fontsize) 
	end
	
	local glyphinfo = glyph.glyphinfo
	glyph.xmove		= glyphinfo and glyphinfo.xmove	or glyph.xmove or 0
	glyph.w			= glyphinfo and glyphinfo.w	or 0
	glyph.h			= glyphinfo and glyphinfo.h	or 0
	glyph.xoff		= glyphinfo and glyphinfo.xoff	or 0
	glyph.yoff		= glyphinfo and glyphinfo.yoff	or 0
	table.insert(self.glyphs,glyph) 
end
	
function gGlyphListPrototype:AddFontGlyph (font,fontsize,charcode,param)
	gProfiler_GlyphList:Start(gEnableProfiler_GlyphList)
	gProfiler_GlyphList:Section("AddFontGlyph:font:GetDefaultFontSize")
	fontsize = fontsize or font:GetDefaultFontSize()
	gProfiler_GlyphList:Section("AddFontGlyph:SpecialChars")
	--~ print("AddFontGlyph",sprintf("%c",charcode),charcode == kCharCode_Space)
	if (charcode == kCharCode_Space		) then self:AddSpace(	font,fontsize) gProfiler_GlyphList:End() return end
	if (charcode == kCharCode_Tab		) then self:AddTab(		font,fontsize) gProfiler_GlyphList:End() return end
	if (charcode == kCharCode_Nl		) then self:AddNewLine(	font,fontsize) gProfiler_GlyphList:End() return end
	if (charcode == kCharCode_Cr		) then gProfiler_GlyphList:End() return end -- ignore
	gProfiler_GlyphList:Section("AddFontGlyph:NormalChar:GlyphInfo:"..(font.sFontType or "??"))
	local glyphinfo = font:GetGlyphInfo(charcode,fontsize)
	gProfiler_GlyphList:Section("AddFontGlyph:NormalChar:DefaultParam")
	param = param or {}
	gProfiler_GlyphList:Section("AddFontGlyph:NormalChar:myglyph")
	local myglyph = {glyphtype=kGlyphType_FontChar,bIsWordBreak=false,font=font,fontsize=fontsize,charcode=charcode,param=param,glyphinfo=glyphinfo}
	gProfiler_GlyphList:Section("AddFontGlyph:NormalChar:AddGlyph")
	self:AddGlyph(myglyph)
	gProfiler_GlyphList:End()
end


function gGlyphListPrototype:AddSpace		(font,fontsize)		self:AddGlyph({glyphtype=kGlyphType_Space		,bIsWordBreak=true,font=font,fontsize=fontsize,xmove=font:GetSpaceWidth(fontsize),			}) end
function gGlyphListPrototype:AddTab			(font,fontsize)		self:AddGlyph({glyphtype=kGlyphType_Tab			,bIsWordBreak=true,font=font,fontsize=fontsize,xmove=font:GetSpaceWidth(fontsize)*kTabLen,	}) end
function gGlyphListPrototype:AddNewLine 	(font,fontsize)		self:AddGlyph({glyphtype=kGlyphType_Newline		,bLineEnd=true,bIsWordBreak=true,font=font,fontsize=fontsize,}) end
function gGlyphListPrototype:AddHAlign		(halign)			self:AddGlyph({glyphtype=kGlyphType_SetHAlign	,bLineEnd=true,halign=halign,bIsWordBreak=true}) end
function gGlyphListPrototype:AddWordBreak	()					self:AddGlyph({glyphtype=kGlyphType_WordBreak	,bIsWordBreak=true,}) end

--- AddIcon,font:GetGlyphInfo : glyphinfo = {matname, xmove, xoff,yoff,w,h, u0,v0, ux,vx, uy,vy}
function gGlyphListPrototype:AddIcon		(glyphinfo,param)	self:AddGlyph({glyphtype=kGlyphType_Icon		,bIsWordBreak=false,glyphinfo=glyphinfo,param=param}) end



-- iFirst = glyphindex (onebased) for first glyph in "word"
-- returns j= glyphindex (onebased) for last glyph in "word"
-- returns iFirst if iFirst isn't a word-char
function gGlyphListPrototype:GetWordEnd	(iFirst)
	if (self.glyphs[iFirst].bIsWordBreak) then return iFirst end
	local glyphcount = #self.glyphs
	for j=iFirst+1,glyphcount do if (self.glyphs[j].bIsWordBreak) then return j-1 end end -- wordbreak on controlchar
	return glyphcount
end

-- returns w,       if earlyout_w is set, then it returns as soon as this is exceeded
function gGlyphListPrototype:WidthSum(startindex,endindex,earlyout_w) 
	local x = 0
	local w = 0
	for i = startindex,endindex do
		local glyph = self.glyphs[i]
		w = math.max(w,x + glyph.w + glyph.xoff) 
		if (earlyout_w and w > earlyout_w) then return w end -- early out
		x = x + (glyph.xmove or 0)
	end
	return w
end

-- returns lineend(index,onebased),lineh,linew
-- autowrap tries to keep on words intact as long as possible
function gGlyphListPrototype:GetLineInfos(startindex,endindex,autowrap_w) 
	local lineh = 0
	local linew = 0
	local x = 0
	local bWrapWordCheck = autowrap_w ~= nil -- only disabled if a word is encountered that doesn't fit even if it's on a seperate line
	local next_word_wrap_check_index = startindex -- calc wordwrap only for first letter 
	for i = startindex,endindex do
		local glyph = self.glyphs[i]
		--~ print("glyphline",glyph.charcode and string.format("%c",glyph.charcode) or "?")
		
		-- stop if character wraps
		local r = x + glyph.w + glyph.xoff
		if (autowrap_w and r > autowrap_w) then return math.max(startindex,i-1),lineh,linew end
		
		-- stop if word wraps
		if (bWrapWordCheck and (not glyph.bIsWordBreak) and (i >= next_word_wrap_check_index)) then
			local wordend = self:GetWordEnd(i)
			local wordw = self:WidthSum(i,wordend,autowrap_w)
			
			if (wordw > autowrap_w) then 
				bWrapWordCheck = false -- can't keep word intact, wrap on characters
			elseif (x + wordw > autowrap_w)  then
				-- wrap word to next line
				return math.max(startindex,i-1),lineh,linew
			end
			next_word_wrap_check_index = wordend + 1 -- dont check this word again
		end
		
		-- apply character
		lineh = math.max(lineh,glyph.lineh or glyph.h or 0)
		linew = math.max(linew,r)
		x = x + (glyph.xmove or 0)
		
		-- stop if newline is reached, but still apply lineh from it (e.g. newline on a seperate line)
		if (glyph.bLineEnd) then return i,lineh,linew end
	end
	-- end of text reached
	return endindex,lineh,linew
end

-- calculates the size of the box around the text (unwrapped)
-- returns w,h
function gGlyphListPrototype:GetUnwrappedTextSize() 
	local w = 0
	local h = 0
	
	self:VisitGlyphs(function(x,y,glyph,glyphindex,param)
		w = math.max(w, x + (glyph.w or 0))
		h = math.max(h, y + (glyph.h or 0))
	end)
	
	return w,h
end


--- halign : horizontal text alignment
--- valign : how to align bigger/smaller glyphs inside a line vertically
--- callbackfun(x,y,glyph,glyphindex,param),param,startindex=1,endindex=?,autowrap_w=nil,halign=kGlyphList_HAlign_Left,valign=kGlyphList_LineVAlign_Bottom
function gGlyphListPrototype:VisitGlyphs(callbackfun,param,startindex,endindex,autowrap_w,halign,valign) 
	local glyphcount = #self.glyphs
	startindex = startindex or 1
	endindex = endindex or glyphcount
	halign = halign or kGlyphList_HAlign_Left 
	valign = valign or kGlyphList_LineVAlign_Bottom
	local x,y = 0,0
	local lineend,lineh,linew
	
	--~ print("VisitGlyphs start")
	local totalw = autowrap_w or 0
	for i = startindex,endindex do
		if (not lineend) then
			-- start of line
			lineend,lineh,linew = self:GetLineInfos(i,endindex,autowrap_w)
			--~ printf("VisitGlyphs line lineend=%d lineh=%d linew=%d\n",lineend,lineh,linew)
			y = y + lineh
			-- center and right align : local 0 pos is middle/right of text, this way we avoid calculating the total width of the text
			x = math.floor( ((halign == kGlyphList_HAlign_Left  ) and (0					)) or	-- left
							((halign == kGlyphList_HAlign_Center) and ((totalw - linew)*0.5	)) or	-- center
																	  (totalw - linew    	) )		-- right
		end
		local glyph = self.glyphs[i]
		if (glyph.glyphtype == kGlyphType_SetHAlign) then halign = glyph.halign end
		--~ printf("VisitGlyphs glyph: i=%d x=%d y=%d c=%s\n",i,x,y,glyph.charcode and string.format("%c",glyph.charcode) or "?")
		
		-- valign
		local h = glyph.h + glyph.yoff
		local valignadd =	math.floor( ((valign == kGlyphList_LineVAlign_Top   ) and ((h-lineh)    )) or	-- top
										((valign == kGlyphList_LineVAlign_Center) and ((h-lineh)*0.5)) or	-- center
																					  (0)			  )		-- bottom
		
		-- visitor
		if (callbackfun(x,y+valignadd,glyph,i,param)) then return end
		x = x + (glyph.xmove or 0)
		if (i == lineend) then lineend = nil end -- start a new line
	end
end

--[[
todo : tab ?	
	if (charcode == kCharCode_Tab) then -- tab
		local tabmaxw = kTabLen * spacew
		x = math.ceil((x + spacew)/tabmaxw) * tabmaxw
	end


tab DOES NOT work in right-align, center align : round xpos to nearest multiple in text-bbox, 
	but need to know the width of the text to determine position due to alignmnet -> 4 spaces ?

-- valign=1  (top:-1,center=0,bottom=1)  (of glyphs in line)
-- halign=-1 (left:-1,center=0,right=1)  (of lines in block)
TODO : realize GetGlyphListSize as visitor over glyphlist ? 
	-- callback returns true -> iteration ends  (or value that evaluates to true, value returned ?)
-- ,autowrap_w=nil,halign=-1,valign=1 : as membervars instead of params ? no

two classes : 
	glyphlist : no graphical representation, just represents the "text" and provides construction/editing utils,  hittest ?   array with metatable, ipairs
	glyphlist_spritepanel ? glyhpflow ?   graphical representation of glyphlist ? better do this in text-widget-class...

TODO : kFlowEntry_ControlChar : spacer, horizontal and/or vertical(set-line-h,paragraph)
TODO : kFlowEntry_ControlChar : mark boxes independent from line, for text flowing around images..., box might be defined by a glyph itself (image with float attrib)
TODO : kFlowEntry_ControlChar : comments/userdata, e.g. for mousepicking of links and similar

TODO : spaces,etc DO play a role at the lineend before autowrap, just a bit different ?

]]--

