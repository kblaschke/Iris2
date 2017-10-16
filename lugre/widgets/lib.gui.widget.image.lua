-- todo  (tex ? anim ? )
-- see also lib.gui.widget.lua

RegisterWidgetClass("Image")

-- {gfxparam_init=?,bVertexBufferDynamic=?}
function gWidgetPrototype.Image:Init (parentwidget, params)
	local bVertexBufferDynamic,bVertexCol = params.bVertexBufferDynamic,true
	local spritepanel = CreateSpritePanel(parentwidget:CastToRenderGroup2D(),params.gfxparam_init,bVertexBufferDynamic,bVertexCol)
	self:SetRenderGroup2D(spritepanel:CastToRenderGroup2D())
	self:AddToDestroyList(spritepanel) -- don't add spritelist here, will be destroyed in spritepanel destructor
	self.spritepanel = spritepanel
	self.params = params
end

function gWidgetPrototype.Image:on_set_size			(w,h) 
	local gfxparam = self.params.gfxparam_init
	if (not gfxparam) then return end
	gfxparam.w = w
	gfxparam.h = h
	self.spritepanel:Update(gfxparam) -- adjust base geometry
end

function gWidgetPrototype.Image:SetGfxParam		(gfxparam) 
	self.params.gfxparam_init = gfxparam
	self.spritepanel:Update(gfxparam)
end
