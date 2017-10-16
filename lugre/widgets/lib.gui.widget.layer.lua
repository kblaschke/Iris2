-- immediate child of root widget, servers for grouping, (dialogs,menus,tooltips..)
-- see also lib.gui.widget.lua

RegisterWidgetClass("Layer")

function gWidgetPrototype.Layer:Init (parentwidget,name)
	self.rendergroup2d = CreateRenderGroup2D(parentwidget:CastToRenderGroup2D())
	self:SetRenderGroup2D(self.rendergroup2d)
	self:AddToDestroyList(self.rendergroup2d)
	self:SetIgnoreBBoxHit(true)
end
