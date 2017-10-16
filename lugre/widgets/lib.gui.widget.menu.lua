-- popup menus, dropdown menus,rightclick menus, menu-bar menus...   on a seperate layer
-- see also lib.gui.widget.lua

RegisterWidgetClass("Menu")

function CreateMenu (...) return CreateWidget("Menu",nil,...) end

-- parentwidget : usually menus are on a special layer, so this should be nil/GetGUILayer_Menus()
-- params
--  btn_params : passed to Button (button image,...)
--  label_params : passed to Button-Label (font,...)
--  entries={{label="bla",on_button_click=function (buttonwidget)...end},...}
--  x,y : requested start position, might be modified to keep the whole menu on screen
function gWidgetPrototype.Menu:Init (parentwidget,params)
	--~ parentwidget = parentwidget or GetGUILayer_Menus()
	parentwidget = parentwidget or GetDesktopWidget()
	self.rendergroup2d = CreateRenderGroup2D(parentwidget:CastToRenderGroup2D())
	self:SetRenderGroup2D(self.rendergroup2d)
	self:AddToDestroyList(self.rendergroup2d)
	self:SetIgnoreBBoxHit(true)
	self.params = params
	self.entries = {}
	self.nexty = 0
	if (params.entries) then self:AddEntryList(params.entries) end
	self:SetPos(params.x,params.y)
	self:AdjustPos()
end

function gWidgetPrototype.Menu:AddEntryList (entry_list) 
	for k,entryparam in pairs(entry_list) do self:AddEntry(entryparam) end 
	self:AdjustPos() 
end

function gWidgetPrototype.Menu:AdjustPos ()
	local vw,vh = GetViewportSize()
	local l,t,r,b = self:GetRelBounds()
	local minx = -l
	local miny = -t
	local maxx = vw-r
	local maxy = vh-b
	local x,y = self:GetPos()
	self:SetPos(max(minx,min(maxx,x)),max(miny,min(maxy,y)))
end

function gWidgetPrototype.Menu:AddEntry (entryparam)
	local label_params = TableMergeToNew(self.params.label_params,{text=entryparam.label})
	local button = self:CreateChild("Button",TableMergeToNew(self.params.btn_params,{x=0,y=self.nexty,label_params=label_params}))
	button.on_button_click = self.params.on_button_click
	local l,t,r,b = button:GetRelBounds()
	self.nexty = b
end
