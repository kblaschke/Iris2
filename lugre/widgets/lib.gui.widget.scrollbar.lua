-- scrollbar
-- see also lib.gui.widget.lua
-- see also lib.gui.widget.scrollpane.lua
-- TODO : thumb : constrained move, live update -> callback

RegisterWidgetClass("ScrollBar")


-- event : on_scroll(newval) : only called on change

-- params:bVertical,x,y,w,h,	min=0,max=10,page=2,step=1
--		btn_back,btn_thumb,btn_up,btn_down
function gWidgetPrototype.ScrollBar:Init (parentwidget, params)
	self.rendergroup2d = CreateRenderGroup2D(parentwidget:CastToRenderGroup2D())
	self:SetRenderGroup2D(self.rendergroup2d)
	self:AddToDestroyList(self.rendergroup2d)
	self:SetIgnoreBBoxHit(true)
	
	self:DefaultParams(params) -- add default values
	self.params = params
	
	self.back	= self:CreateChild("Button",params.btn_back)
	self.thumb	= self:CreateChild("Button",params.btn_thumb)
	self.up		= self:CreateChild("Button",params.btn_up)
	self.down	= self:CreateChild("Button",params.btn_down)
	self.value = params.value or params.min or 0
	self:SetMinMaxPageStep(	params.min  or 0,	
							params.max  or 10,
							params.page or 2,
							params.step or 1)	
	self:SetSize(params.w,params.h)	
	if (params.x) then self:SetPos(params.x,params.y) end
	
	self.back.scrollbar		= self
	self.thumb.scrollbar	= self
	self.up.scrollbar		= self
	self.down.scrollbar		= self
	self.thumb.on_mouse_left_down	= function () self.thumb:StartMouseMove(key_mouse_left,self.ThumbMoveFun,self) end
	self.up.on_mouse_left_down		= function () WhileKeyDown(key_mouse_left,self.AddScroll,self,-self.step) end
	self.down.on_mouse_left_down	= function () WhileKeyDown(key_mouse_left,self.AddScroll,self, self.step) end
end

function gWidgetPrototype.ScrollBar:UpdateThumbPos ()
	local w,h = self.params.w,self.params.h
	local thumbposfraction	= math.max(0,math.min(1,(self.value - self.min) / (self.max - self.min)  ))
	if (self.params.bVertical) then
		self.thumb:SetPos(0,w+math.floor((h - w - w - self.thumbsize) * thumbposfraction))
	else
		self.thumb:SetPos(h+math.floor((w - h - h - self.thumbsize) * thumbposfraction),0)
	end
end

function gWidgetPrototype.ScrollBar:on_set_size (w,h) 
	self.params.w,self.params.h = w,h
	local thumbfraction = math.max(0,math.min(1, self.page / ( (self.page + self.max) - self.min ) ))
	if (self.params.bVertical) then
		self.thumbsize = math.floor((h - w - w) * thumbfraction)
		self.thumb:SetSize(w,self.thumbsize)
		self.up:SetSize(w,w)
		self.up:SetPos(0,0)
		self.down:SetSize(w,w)
		self.down:SetPos(0,h-w)
		self.back:SetSize(w,h-w-w)
		self.back:SetPos(0,w)
	else
		self.thumbsize = math.floor((w - h - h) * thumbfraction)
		self.thumb:SetSize(self.thumbsize,h)
		self.up:SetSize(h,h)
		self.up:SetPos(0,0)
		self.down:SetSize(h,h)
		self.down:SetPos(w-h,0)
		self.back:SetSize(w-h-h,h)
		self.back:SetPos(h,0)
	end
	self:UpdateThumbPos()
end

function gWidgetPrototype.ScrollBar:DefaultParams (params) 
	local ystart = params.bVertical and 0 or 2
	local matname = GetPlainTextureGUIMat("scrollbar.png")
	function MyTile (x,y) 
		local e = 0.25
		return {	gfxparam_init		= MakeSpritePanelParam_SingleSprite(matname,0,0,0,0, x,y,1,1, 4,4),
					gfxparam_in_down	= MakeSpritePanelParam_Mod_TexTransform(0,e,1,1,0),
					gfxparam_in_up		= MakeSpritePanelParam_Mod_TexTransform(0,0,1,1,0),
					gfxparam_out_down	= MakeSpritePanelParam_Mod_TexTransform(0,0,1,1,0),
					gfxparam_out_up		= MakeSpritePanelParam_Mod_TexTransform(0,0,1,1,0),
				} 
	end
	params.btn_back		= MyTile(0,ystart)
	params.btn_thumb	= MyTile(1,ystart)
	params.btn_up		= MyTile(2,ystart)
	params.btn_down		= MyTile(3,ystart)
end

-- for use with StartMouseMove
-- constraint_fun : can be nil, if set,  x,y = constraint_fun(x,y)   for widget:SetPos()
function gWidgetPrototype.ScrollBar:ThumbMoveFun (x,y)
	local w,h = self.params.w,self.params.h
	local fraction = (self.params.bVertical) and max(0,min(1,(y-w)/(h-w-w-self.thumbsize))) or max(0,min(1,(x-h)/(w-h-h-self.thumbsize)))
	--~ print(fraction)
	self:SetValue(self.min + fraction*(self.max-self.min))
end

function gWidgetPrototype.ScrollBar:SetValue (x) 
	local oldval = self.value
	self.value = math.max(self.min,math.min(self.max,x))
	self:UpdateThumbPos()
	if (self.on_scroll and oldval ~= self.value) then self:on_scroll(self.value) end
end

function gWidgetPrototype.ScrollBar:AddScroll (add) self:SetValue(self.value+add) end

-- e.g. for scrolling a text :
-- min=0
-- pagesize=numer_of_lines_per_page
-- max+pagesize=total_number_of_lines_in_document
-- step=1 (line)
function gWidgetPrototype.ScrollBar:SetMinMaxPageStep (vmin,vmax,pagesize,step) 
	print("ScrollBar:SetMinMaxPageStep",vmin,vmax,pagesize,step)
	self.min,self.max,self.page,self.step = vmin,max(vmin,vmax),max(0,pagesize),max(0,step)
	self.value = max(self.min,min(self.max,self.value))
end
