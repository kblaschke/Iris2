-- root widget, starting point for mousepicking, immediate childs are layers (dialogs,menus,tooltips..)
-- see also lib.gui.widget.lua

RegisterWidgetClass("Root")

function CreateRootWidget (rendermanager2d) return CreateWidget("Root",nil,rendermanager2d) end
	
-- parentwidget_ignored : since this is a root widget, the parent widget will be nil
function gWidgetPrototype.Root:Init (parentwidget_ignored,rendermanager2d)
	self.rendergroup2d = CreateRenderGroup2D(rendermanager2d)
	self:SetRenderGroup2D(self.rendergroup2d)
	self:AddToDestroyList(self.rendergroup2d)
	self:SetIgnoreBBoxHit(true)
end

function gWidgetPrototype.Root:CreateLayer (name) return self:CreateChild("Layer",name) end
