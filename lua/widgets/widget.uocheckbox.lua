-- see also lib.gui.widget.lua
-- see also lib.gui.widget.text.lua
-- see also lib.glyphlist.lua
-- see also widget.uobutton.lua

cUOCheckBox = RegisterWidgetClass("UOCheckBox","Group")

-- param : x,y,gump_id_normal,gump_id_pressed,status,return_value
function cUOCheckBox:Init (parentwidget, params)
	if (params.status == 0) then params.status = false end
	if (params.status == 1) then params.status = true end
	
	self.gfx_normal		= self:CreateChild("UOImage",{x=0,y=0,gump_id=params.gump_id_normal})
	self.gfx_pressed	= self:CreateChild("UOImage",{x=0,y=0,gump_id=params.gump_id_pressed})
	
	local dialog = parentwidget:GetDialog()
	if (dialog and dialog.uo_check) then table.insert(dialog.uo_check,self) end
	if (params.on_change) then self.on_change = params.on_change end
	self:SetState(params.status)
	self:UpdateGfx()
end

function cUOCheckBox:GetUOWidgetInfo	()
	local info = "[gumpid="..self.params.gump_id_normal..","..self.params.gump_id_pressed.."]"
	return info
end

function cUOCheckBox:on_change		(bState) end

function cUOCheckBox:on_mouse_left_down	() self.bMouseDown = true		end
function cUOCheckBox:on_mouse_left_up	() self.bMouseDown = false		end
function cUOCheckBox:on_mouse_enter		() self.bMouseInside = true		end
function cUOCheckBox:on_mouse_leave		() self.bMouseInside = false	end

function cUOCheckBox:on_button_click	() if (not self.params.bReadOnly) then self:SetState(not self:GetState()) end end

function cUOCheckBox:UpdateGfx	()
	self.gfx_normal:SetVisible(not self.state)
	self.gfx_pressed:SetVisible(self.state)
end

function cUOCheckBox:GetReturnVal	() return self.params.return_value end
function cUOCheckBox:GetState		() return self.state end
function cUOCheckBox:SetState		(bState)
	if (self.state == bState) then return end -- no change
	self:on_change(bState)
	self.state = bState
	self:UpdateGfx()
end

-- old : widget = MakeCheckBox(parent,param)
-- old : widget = MakeGumpCheckBox(parent, check_state > 0, check_norm, check_down, check_x, check_y)
