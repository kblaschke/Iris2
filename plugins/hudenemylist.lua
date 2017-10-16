-- displays the status of a list of enemys
-- USAGE
-- its possible to target an entry with the uo target cursor
-- rightclick open the mobile health bar

if (not gDisabledPlugins.hudenemylist) then 

-- position of the enemylist block (icon position)
kPlugin_HudEnemylist_X = -170	-- from the right border
kPlugin_HudEnemylist_Y = 230
-- delta position from icon to first min bar
kPlugin_HudEnemylist_IconToBar_X = 36
kPlugin_HudEnemylist_IconToBar_Y = 0
-- delta bar to bar position
kPlugin_HudEnemylist_Bar_DX = 26
kPlugin_HudEnemylist_Bar_DY = 14
-- number of bars in x dimension
kPlugin_HudEnemylist_Bar_CountX = 4
-- border from one block to another
kPlugin_HudEnemylist_BlockBorder = 4

-- icon size
kPlugin_HudEnemylist_Icon_W = 32
kPlugin_HudEnemylist_Icon_H = 32

-- is initialized?
gPlugin_HudEnemylist_Initialized = false
-- number of the displayed team
gPlugin_HudEnemylist_TeamId = 2

-- enemylist dialog
gPlugin_HudEnemylist_Dialog = nil

-- blocklist
gPlugin_HudEnemylist_Blocks = {}

function Plugin_HudEnemylist_GlobalInit ()
	if gPlugin_HudEnemylist_Initialized then return end
	
	gPlugin_HudEnemylist_Dialog = guimaker.MyCreateDialog()
	gPlugin_HudEnemylist_Dialog.panel = guimaker.MakeBorderPanel(gPlugin_HudEnemylist_Dialog,0,0,0,0,{0,0,0,0})
	gPlugin_HudEnemylist_Dialog.panel.mbClipChildsHitTest = false
	gPlugin_HudEnemylist_Dialog:BringToFront()
	
	gPlugin_HudEnemylist_Initialized = true
end



-- returns x,y of the relative bar position to use with insert
function Plugin_HudEnemylist_CalBarPos (index)
	local x = math.mod(index, kPlugin_HudEnemylist_Bar_CountX)
	local y = math.floor(index / kPlugin_HudEnemylist_Bar_CountX)

	return 	x * kPlugin_HudEnemylist_Bar_DX + kPlugin_HudEnemylist_IconToBar_X, 
			y * kPlugin_HudEnemylist_Bar_DY + kPlugin_HudEnemylist_IconToBar_Y
end


-- creates a bar object
function Plugin_HudEnemylist_MakeBar (parent, index, body)
	local bar = {}

	local x,y = Plugin_HudEnemylist_CalBarPos(index)
	
	bar.last_typename = Plugin_GetMobileTypeName(body)
	bar.body = body
	bar.index = index
			
	-- bg image
	bar.widget_bg = guimaker.MakePlane(parent, GetPlainTextureMat("sd_pd_enemylist_bar_bg.png",true), x, y, 32, 16)
	bar.widget_bg.mbClipChildsHitTest = false
	bar.widget_bg.mbIgnoreMouseOver = false
	
	if body.notoriety then
		local r,g,b = GetNotorietyColor(body.notoriety)
		bar.widget_bg.gfx:SetColour(r,g,b,1)
	end
			
	bar.widget_bg.on_mouse_left_click		= function () 
		if not IsTargetModeActive() then 
			gCurrentRenderer:SelectMobile(body.serial) 
		end
	end
	bar.widget_bg.on_mouse_left_down		= function (widget) 
		if IsTargetModeActive() then 
			CompleteTargetModeWithTargetMobile(body) 
		end 
	end
	bar.widget_bg.on_mouse_right_down		= function (widget) 
		OpenHealthbarAtMouse(body)
	end
	bar.widget_bg.on_mouse_left_click_double = function ()
		if (IsWarModeActive()) then
			Send_AttackReq(body.serial)
		else
			Send_DoubleClick(body.serial)
		end
	end
	
	-- Mod für Tooltip Funktion	
	bar.widget_bg.tooltip_offx = kUOToolTippOffX -- Both defined at
	bar.widget_bg.tooltip_offy = kUOToolTippOffY -- obj.container.lua
	bar.widget_bg.stylesetname = gGuiDefaultStyleSet
	bar.widget_bg.mobile = body -- for mousepick
	
	bar.widget_bg.on_tooltip = function (self) return StartUOToolTipAtMouse_Serial(body.serial) end
	-- Ende Tooltip Mod

	local matname = GetPlainTextureMat("bar07.png",true)
	local col_back = {0,0,0,1}
	local col_hull = {1,0,0,1}
	local col_shield = {0,0,1,1}
	
	-- life bar
	bar.widget_hull = guimaker.MakePlane(bar.widget_bg, matname, 2, 2, 20, 4)
	bar.widget_hull.gfx:SetUV(0,0,1,1)
	bar.widget_hull.gfx:SetColour(unpack(col_hull))
	bar.widget_hull.mbIgnoreMouseOver = true
	bar.widget_hull.w = 20
	bar.widget_hull.h = 4
	
	-- engergy bar
	bar.widget_shield = guimaker.MakePlane(bar.widget_bg, matname, 2, 4 + 1 + 2, 20, 4)
	bar.widget_shield.gfx:SetUV(0,0,1,1)
	bar.widget_shield.gfx:SetColour(unpack(col_shield))
	bar.widget_shield.mbIgnoreMouseOver = true
	bar.widget_shield.w = 20
	bar.widget_shield.h = 4
	
	-- root widget in bar
	bar.root = bar.widget_bg
	
	-- kills the widget
	bar.Destroy = function (self)
		bar.widget_hull:Destroy()
		bar.widget_shield:Destroy()
		bar.widget_bg:Destroy()
		bar.widget_bg = nil
		bar.widget_hull = nil
		bar.widget_shield = nil
	end
	
	-- update the status bar
	bar.Update = function (self)
		local f_shield	= self.body and self.body.stats and self.body.stats.curMana and self.body.stats.maxMana and 
			self.body.stats.curMana / self.body.stats.maxMana or 0
		local f_hull	= self.body and self.body.stats and self.body.stats.curHits and self.body.stats.maxHits and
			self.body.stats.curHits / self.body.stats.maxHits or 0
		
		self.widget_hull.gfx:SetDimensions(self.widget_hull.w * f_hull, self.widget_hull.h)
		self.widget_shield.gfx:SetDimensions(self.widget_shield.w * f_shield, self.widget_shield.h)
		
		-- typename changed so reinsert this one
		if bar.last_typename ~= Plugin_GetMobileTypeName(bar.body) then table.insert(gPlugin_HudEnemylist_ReinsertBodys, bar.body) end
	end
	
	-- get current index
	bar.GetIndex = function (self)
		return self.index
	end
	
	-- changes the position
	bar.SetIndex = function (self, index)
		self.index = index
		local x,y = Plugin_HudEnemylist_CalBarPos(index)
		self.root.gfx:SetPos(x,y)
	end

	bar:Update()
	
	return bar
end


-- creates a block + widget with icon and body bars at position x,y
function Plugin_HudEnemylist_MakeBlock (typename, index, icon_info, body_list)
	local parent = gPlugin_HudEnemylist_Dialog
	
	local x,y = 0,0
	
	local block = {}
	
	block.index = index
	
	block.icon_info = icon_info
	block.body_list = {}
	block.bar_list = {}
	
	block.typename = typename
		
	local mat_icon,u1,v1,u2,v2 = unpack(icon_info)
	if mat_icon == nil then
		-- unknown?
		mat_icon = GetPlainTextureMat("sd_pd_unknown.png",true)
		u1 = 0
		v1 = 0
		u2 = 1
		v2 = 1
	end
	
	-- bg image
	block.widget_icon_bg = guimaker.MakePlane(parent, GetPlainTextureMat("sd_pd_enemylist_icon_bg.png",true), x, y, 32, 32)
	block.widget_icon_bg.mbClipChildsHitTest = false
	block.widget_icon_bg.mbIgnoreMouseOver = true
	
	-- icon image
	local w,h = kPlugin_HudEnemylist_Icon_W, kPlugin_HudEnemylist_Icon_H
	local iw,ih = u2-u1, v2-v1
	local dx,dy = 0,0
		
	if iw > ih then
		-- landscape image ratio
		h = w*ih/iw
		dy = math.floor((kPlugin_HudEnemylist_Icon_H - h)/2)
	else
		-- portrait image ratio
		w = iw*h/ih
		dx = math.floor((kPlugin_HudEnemylist_Icon_W - w)/2)
	end
	
	block.widget_icon = guimaker.MakePlane(block.widget_icon_bg, mat_icon, 0, 0, w,h)
	block.widget_icon.gfx:SetUV(u1,v1,u2,v2)
	block.widget_icon.gfx:SetPos(dx,dy)
	block.widget_icon.mbIgnoreMouseOver = true
	
	-- root widget for later movement
	block.root = block.widget_icon_bg
	
	-- sets the block position
	block.SetBlockPosition = function (self, x, y)
		self.root.gfx:SetPos(x,y)
	end
	
	-- get highest index
	block.GetNextBarIndex = function (self)
		local index = -1
		for k,v in pairs(self.bar_list) do
			if v:GetIndex() > index then index = v:GetIndex() end
		end
		return index + 1
	end
	
	--- returns the block height
	block.GetHeight = function (self)
		local bx,by = Plugin_HudEnemylist_CalBarPos(self:GetNextBarIndex())
		by = by + kPlugin_HudEnemylist_Bar_DY
		
		return math.max(by,kPlugin_HudEnemylist_Icon_H + 2 + 2)
	end
	
	-- adds a body to monitor
	block.InsertBody = function (self, body)
		if not self.body_list[body] then
			local index = self:GetNextBarIndex()
			local x, y = Plugin_HudEnemylist_CalBarPos(index)
			self.body_list[body] = true
			local bar = Plugin_HudEnemylist_MakeBar(block.root, index, body)
			self.bar_list[body] = bar 
		end
	end
	
	-- contains body?
	block.ContaintsBody = function (self, body)
		if self.body_list[body] then
			return true
		else
			return false
		end
	end
	
	-- removes a body
	block.RemoveBody = function (self, body)
		if self.body_list[body] then
			self.body_list[body] = nil
			local bar = self.bar_list[body]
			local index = bar:GetIndex()
			
			-- remove bar and update position of others
			for k,v in pairs(self.bar_list) do
				local i = v:GetIndex()
				if i > index then
					-- move left
					v:SetIndex( i - 1)
				end
			end
			
			self.bar_list[body] = nil
			bar:Destroy()
		end
	end

	-- calls update on each bar and removes dead ones
	block.Update = function (self)
		for k,v in pairs(self.bar_list) do
			v:Update()
		end
	end
	
	-- destroys a block
	block.Destroy = function (self)
		for k,v in pairs(self.bar_list) do
			v:Destroy()
			self.bar_list[v] = nil
			self.body_list[v] = nil			
		end

		self.widget_icon:Destroy()
		self.widget_icon_bg:Destroy()
	end
	
	-- get current index
	block.GetIndex = function (self)
		return self.index
	end
	
	-- changes the position
	block.SetIndex = function (self, index)
		self.index = index

		-- local x,y = Plugin_HudEnemylist_CalblockPos(index)
		-- self.root.gfx:SetPos(x,y)
	end

	-- store all given bodys
	for k,v in pairs(body_list) do 
		local barx, bary = Plugin_HudEnemylist_CalBarPos(in_row)
		block:InsertBody( v)
	end
	
	return block
end


-- return the block with the given index
function  Plugin_HudEnemylist_GetBlock (index)
	if gPlugin_HudEnemylist_Blocks then
		for k,v in pairs(gPlugin_HudEnemylist_Blocks) do
			if v:GetIndex() == index then return v end
		end
	end
	
	return nil
end


-- return the index of the next block
function  Plugin_HudEnemylist_GetNextBlockIndex ()
	local index = -1
	
	-- search next free index
	if gPlugin_HudEnemylist_Blocks then
		for k,v in pairs(gPlugin_HudEnemylist_Blocks) do
			if v:GetIndex() > index then index = v:GetIndex() end
		end
	end

	return index + 1
end


-- updates the position of the blocks
function Plugin_HudEnemylist_RearangeBlocks ()
	local vw,vh = GetViewportSize()
	local x = kPlugin_HudEnemylist_X + vw
	local y = kPlugin_HudEnemylist_Y

	local nextid = Plugin_HudEnemylist_GetNextBlockIndex()
	
	for i = 1,nextid do
		local b = Plugin_HudEnemylist_GetBlock(i-1)

		b:SetBlockPosition(x,y)

		local h = b:GetHeight()

		y = y + h + kPlugin_HudEnemylist_BlockBorder
	end
end


-- gets a block for a given typename, creates if not there is no one for this type
function Plugin_HudEnemylist_GetBlockForTypeName (typename)
	local block

	if gPlugin_HudEnemylist_Blocks[typename] then
		block = gPlugin_HudEnemylist_Blocks[typename]
	else
		-- type not available so create a block
		local index = Plugin_HudEnemylist_GetNextBlockIndex()

		local image = gTypenameToIcon[typename]
		if not image then image = "sd_pd_unknown.png" end
		
		local sMatName,iWidth,iHeight,iCenterX,iCenterY,iFrames,u0,v0,u1,v1 = Anim2DAtlas_TranslateAndLoad(typename,2,0,0)
		local image_info = {sMatName,u0,v0,u1,v1}
		
		block = Plugin_HudEnemylist_MakeBlock(typename,index,image_info,{})
		gPlugin_HudEnemylist_Blocks[typename] = block
		
		-- update positions
		Plugin_HudEnemylist_RearangeBlocks()
	end
	
	return block
end

-- removes the given body from a blocklist
function Plugin_HudEnemylist_RemoveBodyFromBlocks (body)
	if gPlugin_HudEnemylist_Blocks then
		local block = nil
		
		for k,v in pairs(gPlugin_HudEnemylist_Blocks) do
			if v:ContaintsBody(body) then block = v end
		end
		
		if block then
			block:RemoveBody(body)
			
			if block:GetNextBarIndex() == 0 then
				local index = block:GetIndex()

				-- remove block and update position of others
				for kk,vv in pairs(gPlugin_HudEnemylist_Blocks) do
					local i = vv:GetIndex()
					if i > index then
						-- move left
						vv:SetIndex( i - 1)
					end
				end
				
				-- remove the block 
				block:Destroy()
				gPlugin_HudEnemylist_Blocks[block.typename] = nil
				
			else
				-- not removed
			end

			-- and rearange
			Plugin_HudEnemylist_RearangeBlocks()
		end
	end
end

RegisterListener("Hook_PostLoad",function () 
	Plugin_HudEnemylist_GlobalInit()

	local vw,vh = GetViewportSize()

end)


RegisterListener("Hook_HUDStep",function ()
	-- update all blocks
	gPlugin_HudEnemylist_ReinsertBodys = {}
	if gPlugin_HudEnemylist_Blocks then 
		for k,v in pairs(gPlugin_HudEnemylist_Blocks) do 
			v:Update() 
		end 
	end
	
	-- reinsert the listed bodys, for typechange
	for k,v in pairs(gPlugin_HudEnemylist_ReinsertBodys) do
		Plugin_HudEnemylist_RemoveBodyFromBlocks(v) 
		local typename = Plugin_GetMobileTypeName(v)
		local block = Plugin_HudEnemylist_GetBlockForTypeName(typename)
		block:InsertBody(v)
		-- print("TYPE",typename)
	end
end)

--[[
function GetNotorietyColor (n)
	if (n ==  0) then return 0.0 , 0.0 , 0.0 end -- 0.0 = invalid/across server line
	if (n ==  1) then return 0.1 , 0.1 , 1.0 end -- 1 = innocent (blue)
	if (n ==  2) then return 0.0 , 1.0 , 0.0 end -- 2 = guilded/ally (green)
	if (n ==  3) then return 1.0 , 1.0 , 0.3 end -- 3 = attackable but not criminal (original : gray, here : yellow)
	if (n ==  4) then return 0.5 , 0.5 , 0.5 end -- 4 = criminal (gray)
	if (n ==  5) then return 1.0 , 0.5 , 0.0 end -- 5 = enemy (orange)
	if (n ==  6) then return 1.0 , 0.0 , 0.0 end -- 6 = murderer (red)
	if (n ==  7) then return 1.0 , 0.0 , 1.0 end -- 7 = unknown use (translucent (like 0x4000 hue)) 
	return 0.5,0.5,0.5
]]

gNotorietyToTypename = {
	[1] = "good",
	[2] = "good",
	[3] = "neutral",
	[4] = "enemy",
	[5] = "enemy",
	[6] = "murderer",
}
	
gTypenameToIcon = {
	good = "sd_pd_good.png",
	neutral = "sd_pd_neutral.png",
	enemy = "sd_pd_enemy.png",
	murderer = "sd_pd_murderer.png",
}
	
function Plugin_GetMobileTypeName	(obj)
	return obj.artid
	--[[
	local n = obj.notoriety
	if n and gNotorietyToTypename[n] then return gNotorietyToTypename[n] end
	return "not_"..n
	]]
end

RegisterListener("Hook_Object_CreateMobile",function (obj)
	local typename = Plugin_GetMobileTypeName(obj)
	
	if true then --obj:GetTeamID() == gPlugin_HudEnemylist_TeamId then
		-- show in block
		local block = Plugin_HudEnemylist_GetBlockForTypeName(typename)
		block:InsertBody(obj)
	end
end)

RegisterListener("Hook_Object_DestroyMobile",function (obj)
	Plugin_HudEnemylist_RemoveBodyFromBlocks(obj) 
end)

end
