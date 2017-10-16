-- Todoooo dialog / fullscreen, leftright align... new window pos suggestion...
-- subclasses for messagebox
-- common : colour picker
-- common : file browser : load/save
-- see also lib.gui.widget.lua


cWidget_Window = RegisterWidgetClass("Window","SpritePanel")

function cWidget_Window:Init ()
	self.content = self:_CreateChild("Group") -- for sub-widgets like label,image...
	-- TODO : title?
end

cWidget_Window.CreateChild = gWidgetPrototype.Base.CreateChildPrivateNotice
function cWidget_Window:GetContent	() return self.content end
function cWidget_Window:GetDialog	() return self end -- override, normaly parent:GetDialog(), so this ends recursion

function cWidget_Window:on_mouse_left_down		() self:BringToFront() if (not self.params.bUnmovable) then self:StartMouseMove() end end
function cWidget_Window:on_mouse_right_down		() if (self.params.bCloseOnRightClick) then self:Destroy() end end

function cWidget_Window:AutoSize () self:SpritePanel_AutoSize() end
