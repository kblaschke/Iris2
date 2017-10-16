-- todo
-- see also lib.gui.widget.lua
-- tearoff, dragdrop rearrange

RegisterWidgetClass("Tabpane")

--~    +----------+  +-------+       -     -
--~  d1|tab_active|d2|tab    |       h1    h2
--~ +--+          +--+-------+--+    -     |
--~ |                           |          -
--~ |  pane                     |
--~ +---------------------------+
--~ 
--~ d1=margin_first_tab
--~ d2=margin_between_tab
--~ h2-h1=height_tab_overlapped
--~ 
--~ tabsize h1 is the maximum of all tab content heights + margin (margin_tab)
--~ margin_tab is the margin between tab content and tab border

--~ params={gfxparam_pane			=?,
--~ params={gfxparam_tab			=?,
--~ params={gfxparam_tab_active		=?,
--~ params={margin_first_tab		=?,
--~ params={margin_between_tab		=?,
--~ params={margin_tab				=?,
--~ params={margin_pane				=?,
--~ params={height_tab_overlapped	=?,


-- EXAMPLE ================================================
--[[
	local test_image = MakeSpritePanelParam_SingleSprite(GetPlainTextureGUIMat("art_fallback.png"),
		32,32,0,0,0,0,32,32,32,32)

	local params = {
		gfxparam_pane			= MakeSpritePanelParam_BorderPartMatrix(GetPlainTextureGUIMat("tabbed.png"),128,128, 0,0, 2,2, 12,1,12, 12,1,12, 128,128, 1,1, false, false),
		gfxparam_tab			= MakeSpritePanelParam_BorderPartMatrix(GetPlainTextureGUIMat("tabbed.png"),128,128, 0,0, 31,2, 12,1,12, 12,1,1, 128,128, 1,1, false, false),
		gfxparam_tab_active		= MakeSpritePanelParam_BorderPartMatrix(GetPlainTextureGUIMat("tabbed.png"),128,128, 0,0, 31,20, 12,1,12, 12,1,1, 128,128, 1,1, false, false),
		margin_first_tab		= 10,
		margin_between_tab		= 10,
		margin_tab				= 6,
		margin_pane				= 6,
		height_tab_overlapped	= 2,
	}
	
	local tabpane = GetDesktopWidget():CreateChild("Tabpane",params)
	tabpane:SetSize(400,400)
	tabpane:SetLeftTop(10,10)
	
	tabpane:AddTab("test1")
	tabpane:GetTabContentTab("test1"):CreateChild("Text",{text="test1",textparam={r=0,g=0,b=0},font=CreateFont_UO(gUniFontLoaderList[0])})
	tabpane:GetTabContentPane("test1"):CreateChild("Text",{text="this is the first tab pane with\na lot of funny text!",textparam={r=0,g=0,b=0},font=CreateFont_UO(gUniFontLoaderList[0])})
	tabpane:AddTab("test2")
	tabpane:GetTabContentTab("test2"):CreateChild("Text",{text="test2",textparam={r=0,g=0,b=0},font=CreateFont_UO(gUniFontLoaderList[0])})
	tabpane:GetTabContentPane("test2"):CreateChild("Image",{gfxparam_init=test_image})
	tabpane:AddTab("test3")
	tabpane:GetTabContentTab("test3"):CreateChild("Text",{text="test3",textparam={r=0,g=0,b=0},font=CreateFont_UO(gUniFontLoaderList[0])})

	tabpane:UpdateAll()
]]
-- =======================================================


-- see SpritePanel for gfxparam format
function gWidgetPrototype.Tabpane:Init 	(parentwidget, params)
	local bVertexBufferDynamic,bVertexCol = false,true
	
	self.rendergroup2d = CreateRenderGroup2D(parentwidget:CastToRenderGroup2D())
	self:SetRenderGroup2D(self.rendergroup2d)
	self:AddToDestroyList(self.rendergroup2d)
	
	self:SetIgnoreBBoxHit(true)
	
	self.params = params
	
	self.panebackground = self:CreateChild("Border",{gfxparam_init=params.gfxparam_pane})
	self.tabs = {}	-- {pane=..., tab=...}
	self.taborder = {}	-- a list of names, order of the list is order of x position
	
	self.activetab = nil
	self.tabbar_height = 0
	self.tabbar_width = 0
end

function gWidgetPrototype.Tabpane:HasTab			(name)
	return self.tabs[name] ~= nil
end

function gWidgetPrototype.Tabpane:GetTab			(name)
	return self.tabs[name]
end

function gWidgetPrototype.Tabpane:RemoveTab			(name)
	if self:HasTab(name) then
		local t = self.tabs[name]
		self.tabs[name] = nil
		
		local order = 1
		
		-- remove the element with value name from order list
		for k,v in pairs(self.taborder) do 
			if v == name then 
				order = k 
				table.remove(self.taborder, k)
				break 
			end 
		end
		
		self.taborder[name] = nil
		
		-- destroy widgets
		t.pane:Destroy()
		t.tab:Destroy()
		
		-- switch current active tab if the active gets removed
		if self.activetab == name and countarr(self.tabs) > 0 then
			order = math.max(1, order - 1)
			self:ActivateTab(self.taborder[order])
		end
		
		-- if there is no tab left, none is active
		if countarr(self.tabs) == 0 then self.activetab = nil end
		
		self:UpdateAll()
	end	
end

function gWidgetPrototype.Tabpane:AddTab			(name) 
	-- remove existing one if the name is already taken
	self:RemoveTab(name)
	
	local margin_tab = self.params.margin_tab or 0
	local height_tab_overlapped = self.params.height_tab_overlapped or 0
	
	local tab = self:CreateChild("Border",{gfxparam_init=self.params.gfxparam_tab, margin_left=margin_tab, margin_right=margin_tab, margin_top=margin_tab, margin_bottom=margin_tab+height_tab_overlapped})
	local pane = self:CreateChild("Group")
	-- initially hidden, ActivateTab shows the pane
	pane:SetVisible(false)
	
	local tabpane = self
	tab.on_button_click = function(self)
		tabpane:ActivateTab(name)
	end
	
	self.tabs[name] = {tab=tab, pane=pane}
	table.insert(self.taborder, name)
	
	-- if this is the first tab, make it the active one		
	if self.activetab == nil then self:ActivateTab(name) end
	
	self:UpdateAll()
end

function gWidgetPrototype.Tabpane:ActivateTab		(name)
	if self.activetab == name then return end
	self.activetab = name
	
	for k,v in pairs(self.tabs) do
		if k == name then
			v.pane:SetVisible(true)
			v.tab.params.gfxparam_init = self.params.gfxparam_tab_active
		else
			v.pane:SetVisible(false)
			v.tab.params.gfxparam_init = self.params.gfxparam_tab
		end
	end
	
	self:UpdateAll()
end

function gWidgetPrototype.Tabpane:GetActiveTabName	(name)
	return self.activetab
end

function gWidgetPrototype.Tabpane:GetTabContentPane	(name)
	if not self:HasTab(name) then return nil end
	
	return self.tabs[name].pane
end

function gWidgetPrototype.Tabpane:GetTabContentTab	(name)
	if not self:HasTab(name) then return nil end
	
	return self.tabs[name].tab:GetContent()
end

-- adjusts the size and position of the tabs according to the current tab content
-- call this if the tab content size changes
function gWidgetPrototype.Tabpane:UpdateTabs	()
	self.tabbar_height = 0
	
	local margin_pane = self.params.margin_pane or 0
	local margin_tab = self.params.margin_tab or 0
	local margin_first_tab = self.params.margin_first_tab or 0
	local margin_between_tab = self.params.margin_between_tab or 0
	local height_tab_overlapped = self.params.height_tab_overlapped or 0
	
	-- calculate max size
	local minw,minh = 44,16
	for k,v in pairs(self.tabs) do
		local w,h = 0,0
		v.tab:UpdateContent() -- call here so it behaves correctly even if childs where added with AddChild
		if v.tab:GetContent() then
			w,h = v.tab:GetContent():GetSize()
			w = max(w,minw)
			h = max(h,minh)
		end
		
		self.tabbar_height = math.max(self.tabbar_height, h + 2 * margin_tab)
	end
	
	local x = margin_first_tab
	
	-- adjust size and position
	for k,v in pairs(self.taborder) do
		local t = self.tabs[v]
		
		local w,h = 0,0
		if t.tab:GetContent() then
			w,h = t.tab:GetContent():GetSize()
			w = max(w,minw)
			h = max(h,minh)
		end
		
		w = w + 2 * margin_tab
		h = self.tabbar_height + height_tab_overlapped
		
		t.tab:SetSize(w, h)
		t.tab:SetLeftTop(x, 0)
		
		t.pane:SetLeftTop(margin_pane, margin_pane + self.tabbar_height)
		
		-- switch position to next tab
		x = x + w + margin_between_tab
	end
	
	self.tabbar_width = x
end

function gWidgetPrototype.Tabpane:UpdateAll	() 		 
	local w,h = self:GetSize()
	self:SetSize(w,h)
end

-- resize the complete tabpane, width is limited by tabbar width
function gWidgetPrototype.Tabpane:on_set_size	(w,h) 		 
	self:UpdateTabs()
	
	w = math.max(self.tabbar_width, w)
	
	self.panebackground:SetLeftTop(0, self.tabbar_height)
	self.panebackground:SetSize(w, h - self.tabbar_height)
end
