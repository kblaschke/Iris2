-- see also lib.gui.widget.lua
-- see also lib.gui.widget.text.lua
-- see also lib.glyphlist.lua
-- TODO : oneline, multiline/textarea
-- evtl : spin : edittext and +- buttons (or up/down)
-- access/hotkey chooser
-- focus system (tab)
-- todo : blinking caret, selection visuals, mousepicking..
-- todo : make lib.edittext.lua obsolete...
-- todo : spritepanel for own background and mouseover/focus visuals ?
-- todo : button-like decorator/framed-border ?
-- todo : onDestroy : DeactivateEditText

--[[
	widget.onDestroy 		= DeactivateEditText
	widget.onReturn			= function (widget) widget:Deactivate() end
]]--

-- see also lib.gui.widget.lua
-- todo : wrap, align:center/left 
-- autoscroll?(textarea-widget)

RegisterWidgetClass("EditText")


function gWidgetPrototype.EditText:Init (parentwidget, params)
	self.rendergroup2d = CreateRenderGroup2D(parentwidget:CastToRenderGroup2D())
	self:SetRenderGroup2D(self.rendergroup2d)
	self:AddToDestroyList(self.rendergroup2d)
	self.params = params
	self:InitTextWidget()
end
	
function gWidgetPrototype.EditText:InitTextWidget ()
	self.text = self.params.text
	self.textwidget = self:CreateChild("Text",self.params)
	self:UpdateTextDisplay()
end

function gWidgetPrototype.EditText:UpdateTextDisplay () 
	local displaytext = self.text
	local params = self.params
	if (params.bPassWordStyle) then displaytext = string.rep("*",string.len(displaytext)) end
	self.textwidget:SetText(params.font,params.fontsize,displaytext,params.textparam) 
	self:on_change_text()
end

function gWidgetPrototype.EditText:GetText ()		return self.text end
function gWidgetPrototype.EditText:SetText (text)	self.text = text self:UpdateTextDisplay() end

function gWidgetPrototype.EditText:on_mouse_left_down	() print("EditText SetFocus",self) self:SetFocus() end
function gWidgetPrototype.EditText:on_focus_lost		() end
function gWidgetPrototype.EditText:on_focus_gain		() end
function gWidgetPrototype.EditText:on_return			() self:RemoveFocus() end
function gWidgetPrototype.EditText:on_change_text		() end
function gWidgetPrototype.EditText:on_tab				() print("TODO:EditText:on_tab:self:FocusNext()") end -- TODO : move to generic focus system where on_focus_keydown is ? return 

function gWidgetPrototype.EditText:RemoveLastChar		() 
	local textlen = string.len(self.text)
	if (textlen > 0) then 
		self.text = string.sub(self.text,1,textlen-1)
		self:UpdateTextDisplay()
	end
end

function gWidgetPrototype.EditText:ClearText () self:SetText("") end

function gWidgetPrototype.EditText:AppendChar (char)
	if (not char) then return end
	self.text = self.text .. char
	self:UpdateTextDisplay()
end

function gWidgetPrototype.EditText:CheckClearOnFirstKeyDown	() 
	if (not self.params.bClearOnFirstKeyDown) then return end
	self.params.bClearOnFirstKeyDown = false
	self:ClearText()
end


function gWidgetPrototype.EditText:on_focus_keydown		(key,char)
	if (key == key_return) then 
		self:on_return()
		return true
	end

	if (key == key_escape) then
		-- deselect/defocus this edittext field
		self:RemoveFocus()
		return true
	else
		-- printf("type %c [%d] KeyDown(%s) [%d]\n",char,char,GetKeyName(key),key)
		-- TODO : this is a hack to repair broken right-alt, wait for ogre-OIS for clean solution
		local unicodechar = char
		char = (char and char >= 32 and char < 127) and sprintf("%c",char)
		
		-- type characters
		if (key == key_backspace or key == key_del) then
			self:CheckClearOnFirstKeyDown()
			self:RemoveLastChar()
			return true
		elseif (true) then
			if (type(char) == "boolean") then return true end
			if ( (not self.params.bNumbersOnly) or
				 (char and IsNumber(char)) ) then
				self:CheckClearOnFirstKeyDown()
				self:AppendChar(char,unicodechar)
			end
			return true
			-- TODO : this and arrowkeys and shift-arrowkeys currently ignored, no text cursor implemented yet
		end
		return false
	end
end
