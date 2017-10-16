-- used for grouping, e.g. the "contents" of a button or widget composite widget classes composed of multiple widgets
-- see also lib.gui.widget.lua

cWidget_SpritePanel = RegisterWidgetClass("SpritePanel")

function cWidget_SpritePanel:Init ()
	local p = self._widgetbasedata.init_params
	local bVertexBufferDynamic	= p.bVertexBufferDynamic
	local bVertexCol			= p.bVertexCol
	if (bVertexBufferDynamic	== nil) then bVertexBufferDynamic	= false end
	if (bVertexCol				== nil) then bVertexCol				= true end
	p.gfxparam_init = CopyArray(p.gfxparam_init) -- each instance should have it's own param copy, so setsize is possible
	if (p.w) then p.gfxparam_init.w = p.w end
	if (p.h) then p.gfxparam_init.h = p.h end
	self:InitAsSpritePanel(self._widgetbasedata.init_parentwidget,p,bVertexBufferDynamic,bVertexCol)
end

function cWidget_SpritePanel:SpritePanel_SetArea (l,t,r,b)
	local p = self.params.gfxparam_init
	p.xoff = l
	p.yoff = t
	p.w = r-l
	p.h = b-t
	self:SpritePanel_Update(p)
end
function cWidget_SpritePanel:SpritePanel_Resize (w,h)
	local p = self.params.gfxparam_init
	p.w = w or p.w
	p.h = h or p.h
	self:SpritePanel_Update(p)
end
function cWidget_SpritePanel:SpritePanel_Update (p)
	self.spritepanel:Update(p) -- adjust base geometry
end

-- resizes self to content
function cWidget_SpritePanel:SpritePanel_AutoSize () 
	local p = self.params
	self:SpritePanel_SetArea(0,0,0,0)
	local l,t,r,b = self:GetRelBounds()
	self:SpritePanel_SetArea(	l-(p.margin_left   or 0),
								t-(p.margin_top    or 0),
								r+(p.margin_right  or 0),
								b+(p.margin_bottom or 0))
end

