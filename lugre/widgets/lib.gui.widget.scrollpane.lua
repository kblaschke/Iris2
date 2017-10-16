-- makes contents scrollable
-- see also lib.gui.widget.lua
-- TODO : AutoScroll when adding childs ? EnsureVisible(x,y) (in child coords) ? left-top ?
-- TODO : auto show/hide scrollbars
-- TODO : drag mode when clicking background ? SetIgnoreBBoxHit(false) ?
-- TODO : scrollbar class

RegisterWidgetClass("ScrollPane")

-- params:panew/h,iScrollBarThickness
-- scrollx/y : initial scroll, defaults to 0
-- bAutoShowScrollBarH/V : automatically show/hide scrollbars as needed, defaults to true
function gWidgetPrototype.ScrollPane:Init (parentwidget, params)
	self.rendergroup2d = CreateRenderGroup2D(parentwidget:CastToRenderGroup2D())
	self:SetRenderGroup2D(self.rendergroup2d)
	self:AddToDestroyList(self.rendergroup2d)
	self:SetIgnoreBBoxHit(true)
	self.content = self:_CreateChild("Group")
	params.scrollx = params.scrollx or 0
	params.scrolly = params.scrolly or 0
	if (params.bAutoShowScrollBarH == nil) then params.bAutoShowScrollBarH = true end
	if (params.bAutoShowScrollBarV == nil) then params.bAutoShowScrollBarV = true end
	self.params = params
	self:UpdateContent()
end

gWidgetPrototype.ScrollPane.CreateChild = gWidgetPrototype.Base.CreateChildPrivateNotice
function gWidgetPrototype.ScrollPane:GetContent					() return self.content end

-- access to current scroll
function gWidgetPrototype.ScrollPane:GetScrollX			() return self.params.scrollx end
function gWidgetPrototype.ScrollPane:GetScrollY			() return self.params.scrolly end
function gWidgetPrototype.ScrollPane:SetScrollX			(newval,bFromScrollCallback) self:SetScroll(newval,self:GetScrollY(),bFromScrollCallback) end
function gWidgetPrototype.ScrollPane:SetScrollY			(newval,bFromScrollCallback) self:SetScroll(self:GetScrollX(),newval,bFromScrollCallback) end
function gWidgetPrototype.ScrollPane:SetScroll			(scrollx,scrolly,bFromScrollCallback) 
	self.params.scrollx = math.max(0,math.min(self.maxscrollx,scrollx))
	self.params.scrolly = math.max(0,math.min(self.maxscrolly,scrolly))
	self.content:SetLeftTop(	-self.params.scrollx,
								-self.params.scrolly)
	if (bFromScrollCallback) then return end
	if (self.scrollbar_h) then self.scrollbar_h:SetValue(self.params.scrollx) end
	if (self.scrollbar_v) then self.scrollbar_v:SetValue(self.params.scrolly) end
end

function gWidgetPrototype.ScrollPane:CreateScrollbar	(params) 
	local widget = self:_CreateChild("ScrollBar",params)
	widget.scrollpane = self
	if (params.bVertical) then
			widget.on_scroll = function (self,newval) self.scrollpane:SetScrollY(newval,true) end
	else	widget.on_scroll = function (self,newval) self.scrollpane:SetScrollX(newval,true) end  end
	return widget
end

function gWidgetPrototype.ScrollPane:CreateScrollBarsIfNeeded	(bScrollBarH,bScrollBarV) 
	local t = self.params.iScrollBarThickness
	local w = self.params.panew
	local h = self.params.paneh
	if (bScrollBarH and (not self.scrollbar_h)) then self.scrollbar_h = self:CreateScrollbar({ bVertical=false, x=0,   y=h-t, w=w-t, h=t   }) end
	if (bScrollBarV and (not self.scrollbar_v)) then self.scrollbar_v = self:CreateScrollbar({ bVertical=true,  x=w-t, y=0,   w=t,   h=h-t }) end
end

-- creates scrollbar if needed
function gWidgetPrototype.ScrollPane:SetScrollBarHVisible		(bVisible) 
	self:CreateScrollBarsIfNeeded(bVisible,false)
	if (self.scrollbar_h) then self.scrollbar_h:SetVisible(bVisible) end
end

-- creates scrollbar if needed
function gWidgetPrototype.ScrollPane:SetScrollBarVVisible		(bVisible) 
	self:CreateScrollBarsIfNeeded(false,bVisible)
	if (self.scrollbar_v) then self.scrollbar_v:SetVisible(bVisible) end
end

-- call this when content size, own size or params change
function gWidgetPrototype.ScrollPane:UpdateContent				()
	-- calc content size and scroll params
	local w,h = self.content:GetSize() -- not clipped
	w,h = floor(w),floor(h)
	local t = self.params.iScrollBarThickness
	local areaw = self.params.panew
	local areah = self.params.paneh
	local bScrollH = false
	local bScrollV = false
	if (w > areaw) then bScrollH = true end
	if (h > areah) then bScrollV = true end
	
	
	self.maxscrollx = math.floor(math.max(0,w - self.params.panew))
	self.maxscrolly = math.floor(math.max(0,h - self.params.paneh))
	print("ScrollPane:UpdateContent cont",w,h,self.maxscrollx,self.maxscrolly)
	
	-- update scrollbars
	if (self.params.bAutoShowScrollBarH) then self:SetScrollBarHVisible(self.maxscrollx > 0) end
	if (self.params.bAutoShowScrollBarV) then self:SetScrollBarVVisible(self.maxscrolly > 0) end
	if (self.scrollbar_h) then self.scrollbar_h:SetMinMaxPageStep(0,self.maxscrollx,self.params.panew,self.params.panew*0.1) end
	if (self.scrollbar_v) then self.scrollbar_v:SetMinMaxPageStep(0,self.maxscrolly,self.params.paneh,self.params.paneh*0.1) end
	
	-- clamp/apply scroll
	self:SetClip(0,0,self.params.panew,self.params.paneh)
	self:SetScroll(self.params.scrollx,self.params.scrolly)
end


-- ***** ***** ***** ***** ***** ScrollPaneV (newer, less generic but working)
-- vertical only so far (2010.08.07)

cScrollPaneV		= RegisterWidgetClass("ScrollPaneV","Group")


	
function cScrollPaneV:Init (parentwidget, params)
	self:SetIgnoreBBoxHit(false)
	local w,h = params.w,params.h
	local e,b = 16,3
	self.clipped	= self:_CreateChild("Group")
	self.content	= self.clipped:_CreateChild("Group")
	self.frame		= self:_CreateChild("Image",{gfxparam_init=clonemod(params.img_init_frame ,{w=w-e,h=h})})
	self.frame:SetIgnoreBBoxHit(true) -- pass through to childs of content
	self.bar		= self:_CreateChild("Image",{gfxparam_init=clonemod(params.img_init_bar,{w=e,h=h,h=h-2*e+2*b})}) self.bar:SetPos(w-e,e-b)
	self.btn_up		= self:_CreateChild("Button",clonemod(params.param_btn_up		,{x=w-e,y=0,w=e,h=e}	))
	self.btn_dn		= self:_CreateChild("Button",clonemod(params.param_btn_down		,{x=w-e,y=h-e,w=e,h=e}	))
	self.btn_thumb	= self:_CreateChild("Button",clonemod(params.param_btn_thumb	,{x=w-e,y=e*3,w=e,h=e}	))
	local d,dt = 4,25
	self.scroll_x = 0
	self.scroll_y = 0
	self.step_dx = 0
	self.step_dy = 0
	self.w = w
	self.h = h
	self.btn_up.on_mouse_left_down		= function (btn) self:StartButtonScroll(0,-d,btn) end
	self.btn_dn.on_mouse_left_down		= function (btn) self:StartButtonScroll(0, d,btn) end
	self.btn_up.on_mouse_left_up		= function (btn) self:StopButtonScroll(btn) end
	self.btn_dn.on_mouse_left_up		= function (btn) self:StopButtonScroll(btn) end
	self.btn_thumb.on_mouse_left_down	= function (btn) btn:StartMouseMove(key_mouse_left,self.ThumbMoveStep,self) end
	self.clipped:SetClip(0,0,w-e,h)
	self:UpdateContent()
	self:UpdateScroll(0,0)
	RegisterIntervalStepper(dt,function () return self:ScrollStep() end)
end

function cScrollPaneV:ScrollStep				()
	if (not self:IsAlive()) then return true end
	if (self.step_dx ~= 0 or self.step_dy ~= 0) then self:ScrollDelta(self.step_dx,self.step_dy) end
end
function cScrollPaneV:StopButtonScroll			(btn)		self.step_dx = 0 self.step_dy = 0 end
function cScrollPaneV:StartButtonScroll			(dx,dy,btn)	self.step_dx = dx self.step_dy = dy end

function cScrollPaneV:ScrollDelta			(dx,dy)
	self:UpdateScroll(self.scroll_x + dx,self.scroll_y + dy)
end 
function cScrollPaneV:GetScrollContentWH	()
	local l,t,r,b = self.content:GetRelBounds()
	return r,b
end
function cScrollPaneV:ThumbMoveStep			(x,y) -- returns x,y 
	local max_x,max_y,thumb_x,thumb_yoff,thumb_maxmove = self:GetScrollParams()
	if (max_y > 0) then
		local newscrolly = floor(max_y * max(0,min(1,(y - thumb_yoff) / thumb_maxmove)))
		if (newscrolly ~= self.scroll_y) then self:UpdateScroll(0,newscrolly,true) end
		y = max(thumb_yoff,min(thumb_yoff+thumb_maxmove,y))
	else
		y = 0
	end
	return thumb_x,y
end

function cScrollPaneV:GetScrollParams				()
	local sw,sh = self:GetScrollContentWH()
	local w,h = self.w,self.h -- page
	local pagew = w -- minus scrollbar...
	local pageh = h
	local max_x = floor(max(0,sw-pagew))
	local max_y = floor(max(0,sh-pageh))
	local btn_h = 16
	local thumb_w = 16
	local thumb_area_h = self.h - 2*btn_h
	local thumb_h = floor(max(0,thumb_area_h * ((sh > pageh) and (pageh / sh) or 1)))
	local thumb_maxmove = thumb_area_h - thumb_h
	local thumb_yoff = btn_h
	local thumb_x = self.w - thumb_w
	return max_x,max_y,thumb_x,thumb_yoff,thumb_maxmove,thumb_w,thumb_h
end

function cScrollPaneV:UpdateScroll			(newx,newy,bDontChangeThumb)
	local max_x,max_y,thumb_x,thumb_yoff,thumb_maxmove,thumb_w,thumb_h = self:GetScrollParams()
	self.scroll_x = max(0,min(max_x,floor(newx)))
	self.scroll_y = max(0,min(max_y,floor(newy)))
	self.content:SetPos(-self.scroll_x,-self.scroll_y)
	if (not bDontChangeThumb) then 
		local x = thumb_x
		local y = thumb_yoff + ((max_y > 0) and floor(thumb_maxmove * self.scroll_y / max_y) or 0)
		self.btn_thumb:SetPos(x,y)
	end
end 
function cScrollPaneV:on_mouse_left_down	() end -- override so it isn't passed to parent

cScrollPaneV.CreateChild = gWidgetPrototype.Base.CreateChildPrivateNotice
function cScrollPaneV:GetContent () return self.content end

function cScrollPaneV:on_create_content_child () self:MarkForUpdateContent() end
function cScrollPaneV:UpdateContent ()
	--~ print("UpdateContent",self)
	local max_x,max_y,thumb_x,thumb_yoff,thumb_maxmove,thumb_w,thumb_h = self:GetScrollParams()
	self.btn_thumb:SetSize(thumb_w,thumb_h)
end

