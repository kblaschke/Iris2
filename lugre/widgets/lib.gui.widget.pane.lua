-- see also lib.gui.widget.lua

RegisterWidgetClass("Pane")

function gWidgetPrototype.Pane:Init (parentwidget, params)
	local bVertexBufferDynamic,bVertexCol = false,true
	params.gfxparam_init = CopyArray(params.gfxparam_init) -- each instance should have it's own param copy, so setsize is possible
	if (params.r) then 
		params.gfxparam_init.r = params.r
		params.gfxparam_init.g = params.g
		params.gfxparam_init.b = params.b
	end
	if (params.w) then params.gfxparam_init.w = params.w end
	if (params.h) then params.gfxparam_init.h = params.h end
	self:InitAsSpritePanel(parentwidget,params,bVertexBufferDynamic,bVertexCol)
end

function gWidgetPrototype.Pane:SetGeometry(l,t,r,b)
	local p = self.params.gfxparam_init
	p.xoff = l
	p.yoff = t
	p.w = r-l
	p.h = b-t
	self:UpdateGeometry()
	--~ print("SetGeometry",l,t,r,b)
end

function gWidgetPrototype.Pane:UpdateGeometry ()
	self.spritepanel:UpdateGeometry(self.params.gfxparam_init)
end

function gWidgetPrototype.Pane:on_set_size			(w,h) 
	local gfxparam = self.params.gfxparam_init
	if (not gfxparam) then return end
	gfxparam.w = w
	gfxparam.h = h
	self.spritepanel:Update(gfxparam) -- adjust base geometry
end
