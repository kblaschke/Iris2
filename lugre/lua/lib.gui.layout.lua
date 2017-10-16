-- lib.gui.layout.lua

--[[
used widget wi functions

w,h = wi:GetSize()
w,h = wi:GetPreferredSize()
wi:SetSize(w,h)
wi:SetLeftTop(l,t)
n = wi:GetChildCount()
widget = wi:GetChild(index)
v = wi:GetParam(name)
wi:SetParam(name,v)
]]

gLayoutPrototype = {}
-- --------------------------------------------------------
-- prototype
-- --------------------------------------------------------
-- aranges all childs (even if they are invsibile) in the given area (l=left,t=top,w=width,h=heigh)
function gLayoutPrototype:LayoutChilds	(parentwidget, l,t, w,h)
end

-- calculate prefered used area
-- returns w,h
function gLayoutPrototype:CalculatePreferredSize	(parentwidget)
	return 0,0
end

-- create layouter
function gLayoutPrototype:New	(...)
	return nil
end



-- --------------------------------------------------------
-- helper functions
-- --------------------------------------------------------
-- handles layout prefix in param space
function LayoutGetParam	(widget,name,default)
	if widget and widget.GetParam then
		return widget:GetParam("layout_"..name,default)
	else
		return default
	end
end

-- handles layout prefix in param space
function LayoutSetParam	(widget,name,value)
	if widget and widget.SetParam then
		return widget:SetParam("layout_"..name,value)
	end
end

function LayoutGetPreferredSize	(widget)
	if widget then
		local l,t,r,b = widget:GetRelBounds()
		return r-l, b-t
	else
		return 0,0
	end
end

function LayoutSetSize	(widget,w,h)
	if widget and widget.SetSize then
		return widget:SetSize(w,h)
	end
end

function LayoutSetPos	(widget,x,y)
	if widget and widget.SetLeftTop then
		return widget:SetLeftTop(x,y)
	end
end

-- call this only if the preferred size of the widget fits into the area
function LayoutPlaceInArea	(widget,l,t,w,h)
	if widget and widget.SetSize then
		local pw,ph = LayoutGetPreferredSize(widget)
		LayoutSetSize(widget,pw,ph)
		local dx = math.max(0, (w - pw) / 2)
		local dy = math.max(0, (h - ph) / 2)
		LayoutSetPos(widget,math.floor(l+dx),math.floor(t+dy))
	end
end

-- --------------------------------------------------------
-- vbox - vertical aligned boxes
-- --------------------------------------------------------
gLayoutVBoxPrototype = {}

function gLayoutVBoxPrototype:LayoutChilds(parentwidget, l,t, w,h)
	local count = parentwidget:GetChildCount()
	self.sx = 1
	self.sy = count
	return gLayoutGridPrototype.LayoutChilds(self, parentwidget, l,t, w,h)
end

function gLayoutVBoxPrototype:CalculatePreferredSize(parentwidget)
	local count = parentwidget:GetChildCount()
	self.sx = 1
	self.sy = count
	return gLayoutGridPrototype.CalculatePreferredSize(self, parentwidget)
end

function gLayoutVBoxPrototype:New()
	local o = CopyArray(gLayoutGridPrototype)
	ArrayOverwrite(o, gLayoutVBoxPrototype)
	return o
end

-- --------------------------------------------------------
-- hbox - horizontal aligned boxes
-- --------------------------------------------------------
gLayoutHBoxPrototype = {}

function gLayoutHBoxPrototype:LayoutChilds(parentwidget, l,t, w,h)
	local count = parentwidget:GetChildCount()
	self.sx = count
	self.sy = 1
	return gLayoutGridPrototype.LayoutChilds(self, parentwidget, l,t, w,h)
end

function gLayoutHBoxPrototype:CalculatePreferredSize(parentwidget)
	local count = parentwidget:GetChildCount()
	self.sx = count
	self.sy = 1
	return gLayoutGridPrototype.CalculatePreferredSize(self, parentwidget)
end

function gLayoutHBoxPrototype:New()
	local o = CopyArray(gLayoutGridPrototype)
	ArrayOverwrite(o, gLayoutHBoxPrototype)
	return o
end

-- --------------------------------------------------------
-- grid - n x m grid
-- --------------------------------------------------------
gLayoutGridPrototype = {}

function gLayoutGridPrototype:GetSlot(i)
	local x = math.mod(i-1,self.sx) + 1
	local y = math.floor((i-1) / self.sx) + 1
	return x,y
end

function gLayoutGridPrototype:GetSlotArea(i, sdw, sdh)
	local x,y = self:GetSlot(i)
	local px,py = 0,0
	for j=1,x-1 do px = px + sdw[j] end
	for j=1,y-1 do py = py + sdh[j] end
	return px,py,sdw[x],sdh[y]
end

function gLayoutGridPrototype:LayoutChilds(parentwidget, l,t, w,h)
	local pw,ph = self:CalculatePreferredSize(parentwidget)
	local rw, rh = math.max(0, w-pw), math.max(0, h-ph)
	
	local dw = rw / self.sx / 2
	local dh = rh / self.sy / 2
	
	--~ print("size",w,h)
	--~ print("p",pw,ph)
	--~ print("r",rw,rh)
	--~ print("d",dw,dh)
	
	local sdw = {}
	local sdh = {}
	
	local count = parentwidget:GetChildCount()
	for i = 1,count do
		local wi = parentwidget:GetChild(i)
		local cw,ch = LayoutGetPreferredSize(wi)

		cw = cw + 2 * dw
		ch = ch + 2 * dh
		
		local x,y = self:GetSlot(i)

		sdw[x] = math.max(sdw[x] or cw,cw)
		sdh[y] = math.max(sdh[y] or ch,ch)
	end
	
	local count = parentwidget:GetChildCount()
	for i = 1,count do
		local wi = parentwidget:GetChild(i)
		local cw,ch = LayoutGetPreferredSize(wi)
		
		local x,y,w,h = self:GetSlotArea(i,sdw,sdh)
		--~ print("layout#",i,x,y,w,h)
		LayoutPlaceInArea(wi, l+x,t+y,w,h)
	end
end

function gLayoutGridPrototype:CalculatePreferredSize(parentwidget)
	local sdw = {}
	local sdh = {}
	
	local count = parentwidget:GetChildCount()
	for i = 1,count do
		local wi = parentwidget:GetChild(i)
		local cw,ch = LayoutGetPreferredSize(wi)
		
		local x,y = self:GetSlot(i)
		sdw[x] = math.max(sdw[x] or cw,cw)
		sdh[y] = math.max(sdw[y] or ch,ch)
	end
	
	local pw = 0
	for k,v in pairs(sdw) do pw = pw + v end
	local ph = 0
	for k,v in pairs(sdh) do ph = ph + v end
		
	return pw,ph
end

-- create a grid layout with grid slots sx,sy
function gLayoutGridPrototype:New(sx,sy)
	local o = CopyArray(gLayoutGridPrototype)
	o.sx = sx
	o.sy = sy
	return o
end

-- --------------------------------------------------------
-- flow - places boxes in a flow (linewrapped)
-- --------------------------------------------------------

-- --------------------------------------------------------
-- stacked - free x y positions
-- --------------------------------------------------------
gLayoutStackedPrototype = {}

function gLayoutStackedPrototype:LayoutChilds(parentwidget, l,t, w,h)
	local pw,ph = gLayoutStackedPrototype:CalculatePreferredSize(parentwidget)
	
	-- preferred size would fit
	local count = parentwidget:GetChildCount()
	for i = 1,count do
		local wi = parentwidget:GetChild(i)
		local cw,ch = LayoutGetPreferredSize(wi)
		local x,y = LayoutGetParam(wi,"x",0), LayoutGetParam(wi,"y",0)
		LayoutSetPos(wi,l+x,t+y)
		LayoutSetSize(wi,cw,ch)
		
		--~ print("#layout",i,l+x,t+y,cw,ch)
	end

end

function gLayoutStackedPrototype:CalculatePreferredSize(parentwidget)
	local l,r,t,b = 0,0,0,0
	
	local count = parentwidget:GetChildCount()
	for i = 1,count do
		local wi = parentwidget:GetChild(i)
		local cw,ch = LayoutGetPreferredSize(wi)
		local x,y = LayoutGetParam(wi,"x",0), LayoutGetParam(wi,"y",0)
		
		if i == 1 then
			l = x
			t = y
			r = x + cw
			b = y + ch
		else
			l = math.min(l, x)
			t = math.min(t, y)
			r = math.max(r, x + cw)
			b = math.max(b, y + ch)
		end
		
	end
	
	return r-l, b-t
end

function gLayoutStackedPrototype:New()
	local o = CopyArray(gLayoutStackedPrototype)
	return o
end
