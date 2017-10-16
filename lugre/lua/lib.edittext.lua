-- this is for  edittext gui elements, where text can be enterred, also known as inputtext
-- see also lib.gui.lua lib.guimaker.lua lib.input.lua


gActiveEditText = false

function ActivateEditText	(widget)
	-- print("ActivateEditText",widget)
	if (gActiveEditText ~= widget) then
		-- deactivate old
		if (gActiveEditText and gActiveEditText.onDeactivate) then gActiveEditText:onDeactivate() end
		
		gActiveEditText = widget
		
		-- activate new
		if (gActiveEditText and gActiveEditText.onActivate) then gActiveEditText:onActivate() end
	end
end

function DeactivateEditText	(widget)
	if (gActiveEditText == widget) then ActivateEditText(nil) end
end

function DeactivateCurEditText	() ActivateEditText(nil) end

-- called by lib.gui.lua on keydown
-- returns true if the event was consumed/handled
function EditTextKeyDown (key,char)
	--if (char > 128) then print("WARNING ! skipped non asci char",char) return end
	if (gActiveEditText) then return gActiveEditText:onKeyDown(key,char) end	
	return false 
end


function CreatePlainEditText (parent,x,y,w,h,textcol,bPassWordStyle,stylesetname)
	local col_off = {1,1,1,0.3}
	local widget = guimaker.MakeBorderPanel(parent,x,y,w,h,col_off,stylesetname,"textedit")
	widget.col_on	= {1,1,1,0.8}
	widget.col_off	= col_off
	widget.plaintext	= ""
	widget.bPassWordStyle	= bPassWordStyle
	widget.textfield	= guimaker.MakeText( widget, 4, 4, widget.plaintext, 12, textcol)
	widget.GetText 			= function (widget) return widget.plaintext end
	widget.SetText 			= function (widget,text) widget.plaintext = text  widget:onUpdateText() end
	widget.onDestroy 		= DeactivateEditText
	widget.Deactivate		= DeactivateEditText
	widget.Activate			= ActivateEditText
	widget.onTab			= function (self) 
		local dialog = self.dialog
		if (not dialog) then return end
		local takenext = false
		local nextactive
		if (self.nextcontrolname) then nextactive = dialog.controls[self.nextcontrolname] end
		if (not nextactive) then
			for name,widget in pairs(dialog.controls or {}) do
				if (not nextactive) then
					if (takenext and widget.plaintext) then nextactive = widget end
					if (widget == self) then takenext = true end
				end
			end
			if (not nextactive) then nextactive = arrfirst(dialog.controls) end
		end
		if (nextactive) then ActivateEditText(nextactive) end
	end
	widget.onReturn			= function (widget) widget:Deactivate() end
	widget.onActivate		= function (widget) 
		if (widget and widget.gfx and widget.gfx:IsAlive()) then
			widget.gfx:SetColour(widget.col_on) 
		end
	end
	widget.onDeactivate		= function (widget) 
		if (widget and widget.gfx and widget.gfx:IsAlive()) then
			widget.gfx:SetColour(widget.col_off) 
		end
	end
	widget.onUpdateText 	= function (widget) 
		if (widget and widget.textfield and widget.textfield.gfx and widget.textfield.gfx:IsAlive()) then
			if (widget.bPassWordStyle) then
				-- password style stars
				widget.textfield.gfx:SetText(string.rep("*",string.len(widget.plaintext))) 
			else
				-- plaintext display
				widget.textfield.gfx:SetText(widget.plaintext) 
			end
		end
	end
	
	-- returns true if the event was consumed/handled
	widget.onKeyDown	 	= function (widget,key,char) 
		if (key == GetNamedKey("return")) then 
			widget:onReturn()
			return true
		end
		if (key == GetNamedKey("tab")) then 
			widget:onTab()
			return true
		end

		if (key == GetNamedKey("escape")) then
			-- deselect/defocus this edittext field
			DeactivateCurEditText()
			return true
		else
			-- printf("type %c [%d] KeyDown(%s) [%d]\n",char,char,GetKeyName(key),key)
			-- TODO : this is a hack to repair broken right-alt, wait for ogre-OIS for clean solution
			if (char) then char = sprintf("%c",char) end
			
			-- type characters
			if (key == GetNamedKey("backspace") or key == GetNamedKey("del")) then
				widget.plaintext = string.sub(widget.plaintext,1,string.len(widget.plaintext)-1)
				widget:onUpdateText()
				return true
			elseif (char) then
				widget.plaintext = widget.plaintext .. char
				widget:onUpdateText()
				return true
				-- TODO : this and arrowkeys and shift-arrowkeys currently ignored, no text cursor implemented yet
			end
			return false
		end
	end
	return widget
end

-- to lose focus if not clicked inside of the text edit
function EditTextCheckForFocusLoosing()
	if ( gActiveEditText and gActiveEditText ~= gWidgetUnderMouse ) then
		DeactivateCurEditText()
	end
end

RegisterListener("mouse_left_down",function ()
	if (gTestNoClick) then return end
	EditTextCheckForFocusLoosing()
end)
RegisterListener("mouse_right_down",function ()
	EditTextCheckForFocusLoosing()
end)
