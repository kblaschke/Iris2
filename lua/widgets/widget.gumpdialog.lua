-- serverside or clientside gump
-- see also lib.gui.widget.lua

RegisterWidgetClass("GumpDialog")

-- old : guimaker.MakeSortedDialog()
-- old : guimaker.MakePage(pagenum)
	
function gWidgetPrototype.GumpDialog:Init (parentwidget, params)
	self.rendergroup2d = CreateRenderGroup2D(parentwidget:CastToRenderGroup2D())
	self:SetRenderGroup2D(self.rendergroup2d)
	self:AddToDestroyList(self.rendergroup2d)
	self:SetIgnoreBBoxHit(true)
	
	self.bClientSideMode	= params.bClientSideMode
	self.params		= params
	self.dialogId	= params.dialogId -- id/serial
	self.controls	= {} -- key=ctrlname value=widget
	self.uo_radio	= {} -- for return-message
	self.uo_check	= {} -- for return-message
	self.uo_text	= {} -- for return-message
	self.radiogroups = {} -- see widget.uoradiobutton.lua
	self.pages			= {}
	self.usedClilocs	= {}
	self.Gumpdata	= params.Gumpdata
	
	-- set gumpposition
	-- TODO : limit to screen in case of resolution change ?
	if (self.dialogId) then
		local gumpposition = gGumpPosition[self.dialogId]
		if (gumpposition) then
			self:SetPos(gumpposition.x or 0, gumpposition.y or 0)
		else
			self:SetPos(Gumpdata and Gumpdata.x or 0, Gumpdata and Gumpdata.y or 0)
		end
	end
end

-- returns the first artid found in the whole gump (useful for craft-menus, since dialog parts are usually gumpids rather than artids)
function gWidgetPrototype.GumpDialog:GetFirstArtID ()
	function fun (child) 
		if (not child._widgetbasedata.bVisibleCache) then return end -- invisible pages
		return child.params.art_id or child:ForAllChilds(fun)
	end
	return self:ForAllChilds(fun)
end

function gWidgetPrototype.GumpDialog:GetTextUnderPos (relx,rely)
	local dx,dy = self:GetPos()
	local x,y = relx+dx,rely+dy
	function fun (child) 
		if (not child._widgetbasedata.bVisibleCache) then return end -- invisible pages
		local l,t,r,b = child:GetAbsBounds()
		if (not PointInRect(l,t,r,b,x,y)) then return end
		if (child:GetClassName() == "UOText") then return child:GetPlainText() end
		return child:ForAllChilds(fun)
	end
	return self:ForAllChilds(fun)
end
	
	
function gWidgetPrototype.GumpDialog:SendClick		(relx,rely)
	if (not self:IsAlive()) then return end
	local x,y = self:GetPos()
	local widget = self:GetWidgetUnderPos(x+relx,y+rely) 
	if (not widget) then return end
	GUI_TriggerWidgetEventCallback(widget,"button_click") 
end
function gWidgetPrototype.GumpDialog:MarkUsedCliloc		(cliloc_id)
	if (cliloc_id) then self.usedClilocs[cliloc_id] = true end
end
function gWidgetPrototype.GumpDialog:Search		(search)
	local gumpdata = self.Gumpdata
	if (not gumpdata) then return end
	if (gumpdata.Data) then
		--~ print("GumpDialog:Search main",search,gumpdata.Data)
		if (StringContains(gumpdata.Data,search)) then return true end
	end
	if (gumpdata.textline) then 
		for k,line in pairs(gumpdata.textline) do 
			--~ print("GumpDialog:Search line",search,line) 
			if (StringContains(line,search)) then return true end 
		end
	end
	if (gClilocLoader) then
		for cliloc_id,v in pairs(self.usedClilocs) do
			if (StringContains(GetCliloc(cliloc_id),search)) then return true end
		end
	end
end

function gWidgetPrototype.GumpDialog:SearchI	(search)
	search = string.lower(search)
	for k,text in pairs(self:ListTexts()) do if (StringContains(string.lower(text),search)) then return text end end
end
function gWidgetPrototype.GumpDialog:ListTexts		(search)
	local res = {}
	local gumpdata = self.Gumpdata
	if (not gumpdata) then return end
	
	if (gumpdata.Data) then table.insert(res,gumpdata.Data) end 
	if (gumpdata.textline) then 
		for k,line in pairs(gumpdata.textline) do table.insert(res,line) end
	end
	if (gClilocLoader) then
		for cliloc_id,v in pairs(self.usedClilocs) do
			table.insert(res,GetCliloc(cliloc_id))
		end
	end
	return res
end

function gWidgetPrototype.GumpDialog:GetCtrlByName	(name) return self.controls[name] end -- see gumpparser

function gWidgetPrototype.GumpDialog:GetDialog	() return self end -- override, normaly parent:GetDialog(), so this ends recursion

function gWidgetPrototype.GumpDialog:on_destroy	()
	if (self.dialogId) then
		local x,y = self:GetPos()
		gGumpPosition[self.dialogId] = {x=x,y=y}
		gServerSideGump[self.dialogId] = nil
	end
end

-- shows pages 0 and pagenum
function gWidgetPrototype.GumpDialog:ShowPage	(pagenum) 
	self.page = pagenum
	for k,page in pairs(self.pages) do if (page:IsAlive()) then page:SetVisible(k == 0 or k == pagenum) end end
end

function gWidgetPrototype.GumpDialog:on_mouse_left_down		() self:BringToFront() self:StartMouseMove() end
function gWidgetPrototype.GumpDialog:on_mouse_right_down	() self:SendClose(0) end

function gWidgetPrototype.GumpDialog:SendClose	(return_value)
	if (self.bClientSideMode) then return end
	-- old : CloseServerSideGump(self.Gumpdata.playerid, self.dialogId,return_value)
	-- old : ServerSideGump_GetParams
	local params = {}
	params.switches = {}
	params.texts = {}
	for k,widget in pairs(self.uo_radio) do if (widget:GetState()) then table.insert(params.switches,widget:GetReturnVal()) end end
	for k,widget in pairs(self.uo_check) do if (widget:GetState()) then table.insert(params.switches,widget:GetReturnVal()) end end
	for k,widget in pairs(self.uo_text) do 
		table.insert(params.texts,{id=widget:GetReturnVal(),text=widget:GetPlainText()})
	end
	GumpReturnMsg(self.Gumpdata.playerid, self.Gumpdata.dialogId, return_value, params)
	self:Destroy()
end
	
function gWidgetPrototype.GumpDialog:GetPage	(pagenum) 
	local page = self.pages[pagenum]
	if (page) then return page end
	page = self:CreateChild("Group") -- for sub-widgets
	page.pagenum = pagenum
	self.pages[pagenum] = page
	return page
end
