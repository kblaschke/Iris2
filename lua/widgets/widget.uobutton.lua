-- button
-- see also lib.gui.widget.lua

RegisterWidgetClass("UOButton")

-- param : x,y,gump_id_normal,gump_id_pressed,quit,page_id,return_value
-- optionally : art_id,hue,art_x,art_y    if an art-image is used as button label
function gWidgetPrototype.UOButton:Init 	(parentwidget, params)
	self.rendergroup2d = CreateRenderGroup2D(parentwidget:CastToRenderGroup2D())
	self:SetRenderGroup2D(self.rendergroup2d)
	self:AddToDestroyList(self.rendergroup2d)
	self:SetIgnoreBBoxHit(true)
	self:SetConsumeChildHit(true) -- count clicks on image/text childs as click on button ? testme
	
	self.params			= params
	if (params.uoclass) then -- from gumppic : params.uoclass params.uonum VirtueGumpItem
		--~ print("UOButton with uoclass,uonum",params.uoclass,params.uonum)
		params.gump_id_normal	= params.gump_id
		params.gump_id_pressed	= params.gump_id
		params.quit				= 0
		params.page_id			= 0
		params.return_value		= params.gump_id
	end
	self:SetButtonGumpIDs(params.gump_id_normal,params.gump_id_pressed,params.gump_id_pressed,params.hue)
	if (params.art_id) then
		self.gfx_icon = self:CreateChild("UOImage",{x=params.art_x,y=params.art_y,art_id=params.art_id,hue=params.hue})
	end
	self:SetPos(params.x,params.y)
	self:UpdateGfx()
end

function gWidgetPrototype.UOButton:SetButtonGumpIDs		(gump_id_normal,gump_id_pressed,gump_id_over,hue) 
	if (self.gfx_normal) then self.gfx_normal:Destroy() end
	if (self.gfx_pressed) then self.gfx_pressed:Destroy() end
	self.gfx_normal		= self:CreateChild("UOImage",{x=0,y=0,gump_id=gump_id_normal,hue=hue})
	self.gfx_pressed	= self:CreateChild("UOImage",{x=0,y=0,gump_id=gump_id_pressed,hue=hue})
	self:UpdateGfx()
end

function gWidgetPrototype.UOButton:on_mouse_left_down	() self.bMouseDown = true		self:UpdateGfx() end
function gWidgetPrototype.UOButton:on_mouse_left_up		() self.bMouseDown = false		self:UpdateGfx() end
function gWidgetPrototype.UOButton:on_mouse_enter		() self.bMouseInside = true		self:UpdateGfx() end

function gWidgetPrototype.UOButton:on_tooltip			() 
	if (self.params.uoclass == kGumpClassName_VirtueGumpItem) then 
		return StartUOToolTipAtMouse_Text(GetVirtueTitle(self.params.gump_id_normal,self.params.hue) or "???") 
	end
end
function gWidgetPrototype.UOButton:on_mouse_leave		() self.bMouseInside = false	self:UpdateGfx() end

function gWidgetPrototype.UOButton:UpdateGfx	()
	local bPressed = self.bMouseDown and self.bMouseInside
	self.gfx_normal:SetVisible(not bPressed)
	self.gfx_pressed:SetVisible(bPressed)
end

function gWidgetPrototype.UOButton:GetReturnVal	() return self.params.return_value end

function gWidgetPrototype.UOButton:GetUOWidgetInfo	()
	local info = "[gumpid="..self.params.gump_id_normal..","..self.params.gump_id_pressed.."]"
	if (self.params.uoclass == kGumpClassName_VirtueGumpItem) then return info.."virtue:"..self.params.return_value end
	local dialog = self:GetDialog()
	local page_id = self.params.page_id
	local return_value = self.params.return_value or 0
	if (page_id and page_id > 0 and dialog.pages[page_id]) then return info.."PageChange:"..page_id end
	if (dialog.bClientSideMode) then return info.."response(clientside):"..return_value end
	return info.."response:"..return_value
end
function gWidgetPrototype.UOButton:on_button_click	()
	if (self.params.fun) then return self.params.fun(self) end
	if (self.params.uoclass == kGumpClassName_VirtueGumpItem) then
		GumpReturnMsg(GetPlayerSerial(),kGumpTypeVirtue,self.params.return_value) -- send virtue request
		return 
	end
				
	local dialog = self:GetDialog()
	local page_id = self.params.page_id
	local return_value = self.params.return_value
	printdebug("gump","UOButton:on_button_click",page_id,return_value,dialog,dialog and dialog.bClientSideMode)
	if (page_id and page_id > 0 and dialog.pages[page_id]) then
		if (dialog) then dialog:ShowPage(page_id) end
	elseif (return_value) then
		if (dialog) then 
			if (dialog.bClientSideMode) then 
				if (dialog.gumpdata.functions) then
					local fun = dialog.gumpdata.functions[return_value] 
					if (fun) then fun(self,1) end -- 1:mousebutton
				end
			else
				dialog:SendClose(return_value) 
			end
		end
	end
end

