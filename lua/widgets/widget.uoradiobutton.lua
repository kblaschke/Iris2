-- see also lib.gui.widget.lua
-- see also lib.gui.widget.text.lua
-- see also lib.glyphlist.lua
-- see also widget.uobutton.lua

RegisterWidgetClass("UORadioButton")

-- param : x,y,gump_id_normal,gump_id_pressed,status,return_value
function gWidgetPrototype.UORadioButton:Init (parentwidget, params, groupnumber)
	if (params.status == 0) then params.status = false end
	if (params.status == 1) then params.status = true end
	self:InitAsGroup(parentwidget,params)
	
	self.groupnumber	= groupnumber
	self.gfx_normal		= self:CreateChild("UOImage",{x=0,y=0,gump_id=params.gump_id_normal})
	self.gfx_pressed	= self:CreateChild("UOImage",{x=0,y=0,gump_id=params.gump_id_pressed})
	
	local dialog = parentwidget:GetDialog()
	if (dialog) then table.insert(dialog.uo_radio,self) end
	
	self:SetState(params.status)
	self:UpdateGfx()
end

function gWidgetPrototype.UORadioButton:GetUOWidgetInfo	()
	local info = "[gumpid="..self.params.gump_id_normal..","..self.params.gump_id_pressed.."]"
	return info
end
function gWidgetPrototype.UORadioButton:on_mouse_left_down	() self.bMouseDown = true		end
function gWidgetPrototype.UORadioButton:on_mouse_left_up	() self.bMouseDown = false		end
function gWidgetPrototype.UORadioButton:on_mouse_enter		() self.bMouseInside = true		end
function gWidgetPrototype.UORadioButton:on_mouse_leave		() self.bMouseInside = false	end

function gWidgetPrototype.UORadioButton:on_button_click		() self:SetState(true) end

function gWidgetPrototype.UORadioButton:UpdateGfx	()
	self.gfx_normal:SetVisible(not self.state)
	self.gfx_pressed:SetVisible(self.state)
end

function gWidgetPrototype.UORadioButton:GetReturnVal	() return self.params.return_value end
function gWidgetPrototype.UORadioButton:GetState		() return self.state end
function gWidgetPrototype.UORadioButton:SetState		(bState)
	if (self.state == bState) then return end -- no change
	if (bState) then -- make sure only one of the radiobuttons in the group is selected
		local dialog = self:GetDialog()
		if (dialog) then 
			local old = dialog.radiogroups[self.groupnumber]
			if (old) then old:SetState(false) end
			dialog.radiogroups[self.groupnumber] = self 
		end
	end
	self.state = bState
	self:UpdateGfx()
end

--~ old : widget = MakeRadioButton(parent,param)
--~ old : printdebug("gump","RadioButton changed : id="..widget.returnmsg.." state="..widget.state)
