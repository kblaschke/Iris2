-- see also lib.gui.widget.lua
-- see also lib.gui.widget.text.lua
-- see also lib.glyphlist.lua
-- TODO : font hueing needed ? so far rgb vertexcolor of the primary hue color seems to be enough

-- xmfhtmlgump	runebook	"rename book"			black,nonbold
-- htmlgump		runebook	[chargenum]				black,nonbold		{ htmlgump 220 40 30 18 0 0 0 }		-- scrollbar=0->black
-- htmlgump 	changelog	[maintext]				white,nonbold		{ htmlgump 30 81 290 162 2 0 1 }	-- scrollbar=1->white
-- text 		changelog	"Message of the Day"	white,bold			{ text 91 17 hue=2101 0 } hue-dependant !
-- text 		runebook	coords					black,nonbold		{ text 135 80 0 15 }
-- croppedtext 	changelog	"News"					white,bold	

RegisterWidgetClass("UOText","Text")

-- param : x,y,width,height,text/cliloc_id/textline_id,background=0/1=transparent?,scrollbar=0/1=displayed,hue,bold=false,crop=false,html=false,col={r=1,g=1,b=1}
-- bold=outlined_font: false for xmfhtmlgump,htmlgump, true for croppedtext, example : runebook gump : kGumpSample_RuneBook
-- crop : disables autowrap
-- html : parse uo html like <BASEFONT> <BIG>....
function gWidgetPrototype.UOText:Init (parentwidget, params, textlines)
	--~ print("TODO:widget.UOText  : height,w/h-clip,background,scrollbar",parentwidget:GetClassName(),parentwidget.pagenum)
	if (params.scrollbar == 0) then params.scrollbar = false end
	if (params.scrollbar) then params.default_black = false end -- when scrollbar is on, default to white (probably on dark background?)
	if ((not params.crop) and params.width) then params.autowrap_w = params.width + 10 end
	local bParseHTML = params.html
	local text = params.text
	params.text = nil
	
	self:SetIgnoreBBoxHit(true) -- default is true for every derivate class of group,
	-- but text in gumps is not allowed to be mousepickable (e.g. label is displayed above button but not child of button)
	--~ create uotext  {gumpcommand="htmlgump",textline_id=5,width=10=0x0a,y=328=0x0148,x=210=0xd2,default_black=true,height=16=0x10,background=0,scrollbar=0,html=true,}
	
	if (not text) then
		if (params.textline_id) then text = textlines[params.textline_id] 
		elseif (params.cliloc_id and gClilocLoader) then 
			if (params.args) then 
				text = ParameterizedClilocText(params.cliloc_id,params.args)
			else
				text = GetCliloc(params.cliloc_id)
			end
		end
	end
	text = text or ""
	
	if (gDumpLongUOTextToConsole) then 
		local dumptxt = text
		if (type(dumptxt) == "table") then dumptxt = UnicodeToPlainText_KeepLength(dumptxt) end
		if (dumptxt and type(dumptxt) == "string" and #dumptxt >= gDumpLongUOTextToConsole) then print("gDumpLongUOTextToConsole",dumptxt) end
	end
	
	self:SetUOHtml(text,bParseHTML)
	local xoff,yoff = -1,-2 -- ugly, but needed for serverside gump positions ? maybe find a better way, or offset via font or so...
	if (params.x) then self:SetPos(floor(params.x+xoff),floor(params.y+yoff)) end
	
	-- clip
	-- { checkertrans 30 81 290 162 }
	-- { htmlgump     30 81 290 162 2 0 1 }
	--~ if (params.width) then local l,t,r,b = self:GetRelBounds() self:SetClip(0,0,params.width,params.height) end
	
	local w,h = params.width,params.height
	if (w) then local l,t,r,b = self:GetRelBounds() self:SetClip(l,t,l+w,t+h) end
end

function gWidgetPrototype.UOText:SetText (text) self:SetUOHtml(text,false) end

function gWidgetPrototype.UOText:SetCol (r,g,b,a)
	self.params.col = {r=r,g=g,b=b,a=a}
end

function gWidgetPrototype.UOText:GetPlainText () 
	local uohtml = self.uohtml
	return (type(uohtml) == "table") and UnicodeToPlainText_KeepLength(uohtml) or uohtml 
end

-- TODO : uohtml might be an array of ints for unicode (textline) instead of text (no html then)
-- see also HtmlParser in lib.gumpparser.lua
function gWidgetPrototype.UOText:GetUOHtml () return self.uohtml end
function gWidgetPrototype.UOText:SetUOHtml (uohtml,bParseHTML)
	local bIsUniCode = type(uohtml) == "table"
	if (bIsUniCode) then uohtml = CopyArray(uohtml) end
	self.uohtml = uohtml
	local fontsize = nil
	local fontid = 1
	local bold = self.params.bold
	local col_white = {r=1,g=1,b=1}
	local col_black = {r=0,g=0,b=0}
	local col = self.params.default_black and col_black or col_white
	if (self.params.hue) then 
		local r,g,b
		if (self.params.hue >= 0x7fff) then 
			r,g,b = 1,1,1
		else 
			r,g,b = gHueLoader:GetColor(self.params.hue,31) 
		end
		col = {r=r,g=g,b=b} 
	end
	if (self.params.col) then col = self.params.col end
	if (self.params.fontid) then fontid = self.params.fontid end
	
	local glyphlist = self.glyphlist
	local plaintext = bIsUniCode and UnicodeToPlainText_KeepLength(uohtml) or uohtml
	
	glyphlist:Clear()
	
	-- parse uo html
	if (bParseHTML) then
		local readerpos = 1
		local statestack = {}
		table.insert(statestack,{fontid,bold,col})
		for textchunk,tag in string.gfind(plaintext, "([^<]*)(<?[^>]*>?)") do 
			local fontid,bold,col = unpack(statestack[#statestack])
			local font = GetUOFont(gUniFontLoaderList[fontid],bold)
			local fontsize = fontsize or (font and font:GetDefaultFontSize())
			if (textchunk ~= "" and font) then 
				-- text-chunk without tags
				if (bIsUniCode) then 
					local len = #textchunk
					local readerend = readerpos + len - 1
					for i = readerpos,readerend do
						glyphlist:AddFontGlyph(font,fontsize,uohtml[i],col)
					end
					readerpos = readerpos + len
				else
					glyphlist:AddText(font,fontsize,textchunk,col)
				end
			end
			if (tag ~= "" and font) then
				local taglow = string.lower(tag)
				readerpos = readerpos + #tag
					
				-- html-tag
				if (string.find(taglow,"</basefont")) then table.remove(statestack) end
				if (string.find(taglow,"<basefont")) then
					local a,b,colhex = string.find(taglow,"<basefont.*color=#([0-9a-fA-F]+)")
					if (colhex) then local r,g,b = ColFromHex(colhex) col = {r=r,g=g,b=b} end
					table.insert(statestack,{fontid,bold,col})
				end
				if (taglow ==  "<center>") then glyphlist:AddHAlign(kGlyphList_HAlign_Center) glyphlist:AddNewLine() end -- todo 
				if (taglow == "</center>") then glyphlist:AddHAlign(kGlyphList_HAlign_Left  ) glyphlist:AddNewLine() end -- todo 
				-- TODO : html-center : glyphlist : glyphs to change h-alignment during parsing ? needs line width.. and full text width (unless wrap specified !)

				if (taglow == "<big>") then table.insert(statestack,{0,bold,col}) end -- fontchange
				if (taglow == "</big>") then table.remove(statestack) end
				if (taglow == "<br>") then glyphlist:AddNewLine(font,fontsize) end
				
				--~ part = string.sub(part,2,-2) -- cut away one char from each side
				--~ for token in string.gfind(textstring, "%w+") do table.insert(bToken,token) end
				--~ local iStart,iEnd,a,b,c = string.match(part,"")
			end
		end
	else
		-- don't parse html
		local font = GetUOFont(gUniFontLoaderList[fontid],bold)
		local fontsize = fontsize or (font and font:GetDefaultFontSize())
		if (font) then
			if (bIsUniCode) then 
				for k,unicode_charcode in ipairs(uohtml) do glyphlist:AddFontGlyph(font,fontsize,unicode_charcode,col) end
			else
				glyphlist:AddText(font,fontsize,uohtml,col)
			end
		end
	end
	self:UpdateGeometry()
end
--[[
-- vetus-mundus changelog : big text = htmlgump.. todo : clip
<CENTER></CENTER>
<BIG></BIG>
<b></b>  // = big=bold
<BR>
?basefont color size
]]--

--[[
--xmfhtmlgump	<x> <y> <width> <height> <cliloc_id> <background> <scrollbar>
--HtmlGump		<x> <y> <width> <height> <textline_id> <background> <scrollbar>
--croppedtext	<x> <y> <width> <height> <color> <text-id>
gumpparser_d     xmfhtmlgump	140 40  80 18 1011296 0 0 } Charges:
gumpparser_d     htmlgump 		220 40  30 18 0 0 0 }  6
gumpparser_d     xmfhtmlgump	300 40 100 18 1011297 0 0 }        Max Charges:
gumpparser_d     htmlgump		400 40  30 18 1 0 0 }  10
gumpparser_d     xmfhtmlgump	158 22 100 18 1011299 0 0 }        Rename book
gumpparser_d     croppedtext	145 60 115 17 49 2 }       FFHQ
gumpparser_d     croppedtext	145 75 115 17 1153 3 }     TokunoTamer
]]--
