-- see also lib.gui.widget.lua
-- see also lib.gui.widget.text.lua
-- see also lib.glyphlist.lua
-- see also widget.uotext.lua
-- see also lib.gui.widget.edittext.lua

RegisterWidgetClass("UOEditText","EditText")

-- param : x,y,width,height,hue,return_value,textline_id_default
function gWidgetPrototype.UOEditText:Init (parentwidget, params)
	local dialog = parentwidget:GetDialog()
	if (dialog and dialog.uo_text) then table.insert(dialog.uo_text,self) end
end
	
function gWidgetPrototype.UOEditText:InitTextWidget ()
	local p = self.params
	if (p.bHasBackPane) then
		local texname,w,h,xoff,yoff = "simplebutton.png",80,80,0,0
		local u0,v0,w0,w1,w2,h0,h1,h2, tcx,tcy = 0,0, 4,8,4, 4,8,4, 32,32
		local gfxparam_white = MakeSpritePanelParam_BorderPartMatrix(GetPlainTextureGUIMat(texname),w,h,xoff,yoff, u0,v0,w0,w1,w2,h0,h1,h2, tcx,tcy, 1,1, false, false)
		
		local x,y = 0,0
		local w,h = p.width,p.height
		local b = 3
		local backpane = self:CreateChild("SpritePanel",{x=x,y=y,w=w,h=h,gfxparam_init=gfxparam_white,
											margin_left= b,
											margin_top= b,
											margin_right= b,
											margin_bottom= b,
											})
		
		local edittext = self
		function backpane:on_mouse_left_down () print("mybackpane:on_mouse_left_down") edittext:SetFocus() end
	else 
		local w,h = p.width,p.height
		self:SetSize(w,h)
		--~ print("uo et",w,h)
		--~ os.exit(0)
	end
	
	local textlines = p.textlines
	--~ p.text = MainMenu_CharCreate_GetRandomName()
	self.textwidget = self:CreateChild("UOText",{x=0,y=0,width=p.width,height=p.height,text=p.text,textline_id=p.textline_id_default,hue=p.hue},textlines)
	self:SetSize(p.width,p.height)
	if (p.x) then self:SetPos(p.x,p.y) end
	local txt = self.textwidget:GetUOHtml()
	--~ if (#txt <= 0) then txt = "?" end
	self:SetText(txt)
end

function gWidgetPrototype.UOEditText:GetReturnVal	() return self.params.return_value end

function gWidgetPrototype.UOEditText:GetPlainText ()
	return (type(self.text) == "table") and UnicodeToPlainText_KeepLength(self.text) or self.text
end

function gWidgetPrototype.UOEditText:GetText ()		return self.text end -- warning ! might be an array of unicode charcodes (usually)
function gWidgetPrototype.UOEditText:SetText (text) self.text = text self:UpdateTextDisplay() end

function gWidgetPrototype.UOEditText:UpdateTextDisplay () 
	self.textwidget:SetUOHtml(self.text) 
	self:on_change_text(self.text)
end

function gWidgetPrototype.UOEditText:RemoveLastChar		()
	if (type(self.text) == "table") then
		if (#self.text == 0) then return end 
		table.remove(self.text)
	else
		local textlen = string.len(self.text)
		if (textlen == 0) then return end
		self.text = string.sub(self.text,1,textlen-1)
	end
	self:UpdateTextDisplay()
end

function gWidgetPrototype.UOEditText:AppendChar			(char,unicodechar) 
	if (unicodechar and unicodechar == 0) then return end
	--~ print("UOEditText:AppendChar",type(self.text) == "table",char)
	if (type(self.text) == "table") then
		--~ local c = string.byte(char,1)
		local c = unicodechar
		if (c) then table.insert(self.text,c) end
	else
		self.text = self.text .. char
	end
	self:UpdateTextDisplay()
end

-- old : widget = CreatePlainEditText (parent, x,y,width,height, {1.0,1.0,1.0,1.0})
