-- decoration, visual grouping, no mousehit

RegisterWidgetClass("Border")

--~ params={gfxparam_init		=?,
--~ params={margin_left			=?,
--~ params={margin_top			=?,
--~ params={margin_right		=?,
--~ params={margin_bottom		=?,

-- see SpritePanel for gfxparam format
function gWidgetPrototype.Border:Init 	(parentwidget, params)
	local bVertexBufferDynamic,bVertexCol = false,true
	local spritepanel = CreateSpritePanel(parentwidget:CastToRenderGroup2D(),params.gfxparam_init,bVertexBufferDynamic,bVertexCol)
	self:SetRenderGroup2D(spritepanel:CastToRenderGroup2D())
	self:AddToDestroyList(spritepanel) -- don't add spritelist here, will be destroyed in spritepanel destructor
	self.spritepanel = spritepanel
	self.params = params
	
	self:SetIgnoreBBoxHit(true)
	
	self.content = self:_CreateChild("Group") -- for sub-widgets like label,image...
	self:UpdateContent()
	self.content:SetLeftTop(self.params.margin_left or 0, self.params.margin_top or 0)
end

gWidgetPrototype.Border.CreateChild = gWidgetPrototype.Base.CreateChildPrivateNotice
function gWidgetPrototype.Border:GetContent					() return self.content end

function gWidgetPrototype.Border:UpdateContent		() 
	local cont = self.content
	local w,h = cont:GetSize()
	local l = self.params.margin_left	or 0
	local t = self.params.margin_top	or 0
	local r = self.params.margin_right	or 0
	local b = self.params.margin_bottom	or 0
	cont:SetLeftTop(l,t)
	self:SetSize(l+w+r,t+h+b)
end

function gWidgetPrototype.Border:on_set_size			(w,h) 
	local gfxparam = self.params.gfxparam_init
	if (not gfxparam) then return end
	gfxparam.w = w
	gfxparam.h = h
	self.spritepanel:Update(gfxparam) -- adjust base geometry

	local l = self.params.margin_left	or 0
	local t = self.params.margin_top	or 0
	local r = self.params.margin_right	or 0
	local b = self.params.margin_bottom	or 0

	self.content:SetSize(w - l - r, h - t - b)
end
