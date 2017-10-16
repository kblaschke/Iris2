-- see also lib.gui.widget.lua


RegisterWidgetClass("List","SpritePanel")

function gWidgetPrototype.List:Init (parentwidget, params)
	self.scrollpane			= self:_CreateChild("Group")
	self.selecthighlight	= self.scrollpane:_CreateChild("Pane",{r=0,g=1,b=1})
	self.content			= self.scrollpane:_CreateChild("Group") -- for sub-widgets like label,image...
	self:SetConsumeChildHit(true)
end

gWidgetPrototype.List.CreateChild = gWidgetPrototype.Base.CreateChildPrivateNotice
function gWidgetPrototype.List:GetContent				() return self.content end

function gWidgetPrototype.List:on_change_selection		(iSelectedIndex) end -- dummy, override me

function gWidgetPrototype.List:on_mouse_left_down		() self:SelectByMouse() end

function gWidgetPrototype.List:SelectByMouse		()
	local mx,my = GetMousePos()
	local ax,ay = self:GetDerivedPos()
	self:SelectByPos(mx-ax,my-ay)
end

	
function gWidgetPrototype.List:SelectByPos				(sx,sy)
	for k,child in ipairs(self.content:_GetOrderedChildList()) do 
		local x,y		= child:GetPos()
		local l,t,r,b	= child:GetRelBounds()
		if (sy >= y+t and sy <= y+b) then self:SetSelectedIndex(k) return end
	end
	self:ClearSelection()
end

function gWidgetPrototype.List:GetSelectedIndex			() return self.iSelectedIndex end
function gWidgetPrototype.List:GetSelectedChild			() return self:GetChildByIndex(self.iSelectedIndex) end
function gWidgetPrototype.List:GetChildByIndex			(iIndex) return self.content:_GetOrderedChildList()[iIndex] end

function gWidgetPrototype.List:UpdateSelectHighlight	() 
	local iSelectedIndex = self.iSelectedIndex
	local child = self:GetSelectedChild()
	--~ print("UpdateSelectHighlight",iSelectedIndex,child)
	if (child) then 
		local x,y		= child:GetPos()
		local l,t,r,b	= child:GetRelBounds()
		local w = self.params.w - (self.params.margin_left or 0) - (self.params.margin_right or 0)
		self.selecthighlight:SetPos(x,y)
		self.selecthighlight:SetGeometry(0,t,w,b)
		self.selecthighlight:SetVisible(true)
	else
		self.selecthighlight:SetVisible(false)
	end
end

function gWidgetPrototype.List:ClearSelection	() self:SetSelectedIndex(0) end
function gWidgetPrototype.List:SetSelectedIndex	(iSelectedIndex) 
	if (self.iSelectedIndex == iSelectedIndex) then return end
	self.iSelectedIndex = iSelectedIndex
	self:UpdateSelectHighlight()
	local child = self:GetSelectedChild()
	self:on_change_selection(iSelectedIndex,child)
	local on_select_by_list = child and (child.on_select_by_list or child.params.on_select_by_list)
	if (on_select_by_list) then on_select_by_list(child) end
end
	
function gWidgetPrototype.List:AddWidget (widget) widget:SetParent(self.content) self:UpdateLayout() return widget end

function gWidgetPrototype.List:UpdateLayout () 
	local x = self.params.margin_left or 0
	local y = self.params.margin_top or 0
	for k,child in ipairs(self.content:_GetOrderedChildList()) do 
		local w,h = child:GetSize()
		child:SetLeftTop(x,y)
		y = y + h
	end
	self:UpdateSelectHighlight()
	self.contentheight = y
end

function gWidgetPrototype.List:AutoHeight () 
	self:UpdateLayout()
	self:SpritePanel_Resize(nil,
		(self.params.margin_top or 0) + (self.params.margin_bottom or 0) + (self.contentheight or 0)
		)
end
