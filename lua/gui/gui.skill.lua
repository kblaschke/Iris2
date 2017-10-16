-- Created 11.03.2008 16:09:57, with GumpStudio & Iris2 Lua Export Plugin
-- Exported Iris2 GumpExporter ver 1.0.
local skillGump = {}
skillGump.dialogId = 5000001
skillGump.x = 25
skillGump.y = 25
skillGump.Data =
	 "{ page 0 }" ..
	 "{ gumppic 23 311 2083 xx1 }" ..
	 "{ gumppic 21 241 2082 xx2 }" ..
	 "{ gumppic 42 273 2102 xx3 }" ..
	 "{ gumppictiled 21 64 263 177 2081 xx4 }" ..
	 "{ gumppic 4 27 2080 xx5 }" ..
	 "{ gumppic 120 37 2100 xx6 }" ..
	 "{ button 139 342 2094 2095 1 0 0 skillresize }" ..
	 "{ gumppic 44 62 2091 xx7 }" ..
	 "{ button 255 61 2084 2084 1 0 1 skillscrollup }" ..
	 "{ button 255 291 2085 2085 1 0 2 skillscrolldown }" ..
	 "{ button 139 4 2093 2093 1 0 3 skillclose }" ..
	 "{ button 259 76 2088 2088 1 0 4 skillscroll }" ..
	 "{ button 50 10 0x28DC 0x28DC 1 0 5 skillsort }"
skillGump.textline = {
}
skillGump.functions = {
 -- skillresize (not implemented yet)
 [0]	= function (widget,mousebutton) end,
 -- skillscrollup
 [1]	= function (widget,mousebutton) if (mousebutton == 1) then widget.dialog:Scroll(-3) end end,
 -- skillscrolldown
 [2]	= function (widget,mousebutton) if (mousebutton == 1) then widget.dialog:Scroll(3) end end,
 -- skillclose
 [3]	= function (widget,mousebutton)
 			if (mousebutton == 1) then 
				widget.gfx:SetMaterial(widget.mat_pressed)
				-- TODO: toggle to gump-id 0x839 on upper right corner (moveable) ... on doubleclick open skills again
				gSkillDialog:Close()
		 	end
		  end,
 -- skillscroll
 [4]	= function (widget,mousebutton)
			if (mousebutton == 1) then widget.dialog:BringToFront() gui.StartMoveDialog(widget) end
		  end,
 -- update skill sorting order
 [5]	= function (widget,mousebutton)
			if (mousebutton == 1) then widget.dialog:BringToFront() widget.dialog:NextOrder() end
		  end,
}

giNumberOfVisibleSkills = 12

-- -------------- compare functions for skill order ------
function SkillComp_Name	(a,b)
	return a.name < b.name
end

function SkillComp_Value	(a,b)
	local va = gPlayerSkills[a.skillid].value
	local vb = gPlayerSkills[b.skillid].value
	if va ~= vb then 
		return va > vb 
	else
		return SkillComp_Name	(a,b)
	end
end

function SkillComp_SkillId	(a,b)
	return a.skillid < b.skillid
end

function SkillComp_Active	(a,b)
	return glSkillActive[a.skillid] > glSkillActive[b.skillid]
end

function SkillComp_LockState	(a,b)
	return gPlayerSkills[a.skillid].lockstate < gPlayerSkills[b.skillid].lockstate 
end

glSkillCompList = {SkillComp_Value, SkillComp_Name, SkillComp_SkillId, SkillComp_Active, SkillComp_LockState}
---------------------------------------------------------------

-- Created 11.03.2008 15:41:19, with GumpStudio & Iris2 Lua Export Plugin
-- Exported Iris2 GumpExporter ver 1.0.
local quickskillGump = {}
gQuickskillGump = quickskillGump
quickskillGump.dialogId = 5000002
quickskillGump.x = 0
quickskillGump.y = 0
quickskillGump.Data =
	 "{ page 0 }" ..
	 "{ gumppic 0 0 2445 xx1 }" ..
	 "{ gumppic 5 5 2362 xx2 }"
quickskillGump.textline = {
}

kClientSideGump_Skill_Quick		= quickskillGump	-- ??? only two pictures, maybe the hot-button ?
kClientSideGump_Skill			= skillGump			-- the big skill list dialog with up/down/lock boxes, grab icons and scrollbar

-- global player skill stuff list, see SkillUpdate for details
gPlayerSkills = nil

-- sets a skill value and lock state
-- lockstate: (0=up, 1=down, 2=locked)
function SkillUpdate(skillid, value, base_value, lockstate, name,skill_cap)
	--~ print("#######SkillUpdate",skillid, value, base_value, lockstate, name)
	if not gPlayerSkills then
		gPlayerSkills = {}
	end
	
	-- add an empty entry if none present
	if not gPlayerSkills[skillid] then gPlayerSkills[skillid] = {} end
	
	-- is there and old entry?
	local last_value = gPlayerSkills and gPlayerSkills[skillid] and gPlayerSkills[skillid].value or nil
	local last_base_value = gPlayerSkills and gPlayerSkills[skillid] and gPlayerSkills[skillid].last_base_value or nil
	-- print("SKILL DEBUG",value,last_value,base_value,last_base_value)
	if value and last_value and (last_value ~= value) then
		-- display change
		GuiAddChatLine("Skill "..name.." is now "..sprintf("%3.1f",value / 10).." -> "..sprintf("%3.1f",(value-last_value) / 10),gStatsInfoFadeLineColor,"skillupdate")
	end
	
	-- update entry
	gPlayerSkills[skillid].value = value
	gPlayerSkills[skillid].base_value = base_value
	gPlayerSkills[skillid].lockstate = lockstate
	gPlayerSkills[skillid].skill_cap = skill_cap
	
	-- update skill dialog if present
	if gSkillDialog then
		for k,skill in pairs(gSkillDialog.lSkill) do
			if skill.skillid == skillid then
				-- print("skillupdate",k,skillid,skill.skillid,value,base_value,lockstate)
				-- skill found, so update
				skill.button_lock.gfx:SetVisible(lockstate == 2)
				skill.button_up.gfx:SetVisible(lockstate == 0)
				skill.button_down.gfx:SetVisible(lockstate == 1)
				skill.value.gfx:SetText(sprintf("%3.1f",value / 10))
			end
		end
	end
end


function CreateQuickCastButtonSkill(x,y,skillid)
	for dialog,v in pairs(glQuickCastDialog) do
       if dialog and dialog.skillid and dialog.skillid == skillid then
			if dialog and dialog.rootwidget and dialog.rootwidget.gfx and dialog.rootwidget.gfx:IsAlive() then
			--~ if dialog and dialog:IsAlive() then
				-- reuse existing one
				dialog.rootwidget.gfx:SetPos(x,y)
				return
			else
				-- there is a broken one left, so close it
				if dialog:IsAlive() then dialog:Close() end
				if dialog:IsAlive() then dialog:Destroy() end
				glQuickCastDialog[dialog] = nil
			end
		end
	end

	local d = CreateQuickCastButton(x,y,glSkillNames[skillid],function () 
		-- quick cast function
		Send_Request_SkillUse(skillid)
	end)
	d.skillid = skillid
	NotifyListener("Hook_CreateQuickCastSkill",d,x,y,skillid)
	return d
end









function CreateQuickCastButtonWeaponability(x,y,weaponabilityid)
	for dialog,v in pairs(glQuickCastDialog) do
		if dialog and dialog.weaponabilityid and dialog.weaponabilityid == weaponabilityid then
			if dialog and dialog:IsAlive() then
				-- reuse existing one
				dialog:SetPos(x,y)
				return
			else
				-- there is a broken one left, so close it
				if dialog:IsAlive() then v:Destroy() end
				glQuickCastDialog[dialog] = nil
			end
		end
	end
							
	local name = glWeaponAbilities[weaponabilityid] and glWeaponAbilities[weaponabilityid].name or "?"
	local iconid = glWeaponAbilities[weaponabilityid] and glWeaponAbilities[weaponabilityid].gumpicon or 0x5200
							
	local d = CreateQuickCastButton(x,y,name,function () ToggleWeaponAbility(weaponabilityid) end, iconid)
	gWeaponAbilityIcons[weaponabilityid] = d

	d.weaponabilityid = weaponabilityid
	NotifyListener("Hook_CreateQuickWeaponAbility",d,x,y,weaponabilityid)
	return d
end



gSkillDialog_LastPositionX = nil
gSkillDialog_LastPositionY = nil
gSkillDialog_LastPositionScrollIndex = nil
function ToggleSkill ()
	--OSI does so; Request Skills and stats if gPlayerSkills is already nil
	if (gPlayerSkills==nil) then
		Send_ClientQuery(gRequest_Skills,GetPlayerSerial())
	end

	if (gSkillDialog) then
		-- store current position
		gSkillDialog_LastPositionX, gSkillDialog_LastPositionY = gSkillDialog.rootwidget.gfx:GetPos()
		-- and close
		gSkillDialog:Close()
	elseif (gPlayerSkills) then
		-- scrollbar middle part hardcoded positions
		local scrollbar_x = 256
		local scrollbar_y_start = 74
		local scrollbar_y_end = 231
		
		local scrollbar_h = scrollbar_y_end - scrollbar_y_start
	
		local dialog = GumpParser( skillGump, true )
		
		gSkillDialog = dialog
	
		-- restore last positoin if available
		if gSkillDialog_LastPositionX and gSkillDialog_LastPositionY then gSkillDialog.rootwidget.gfx:SetPos(gSkillDialog_LastPositionX, gSkillDialog_LastPositionY) end

		dialog.Close = function (dialog)
			gSkillDialog:Destroy()
			gSkillDialog = nil
		end

		-- overwrite the onMouseDown function from gumpparser
		dialog.onMouseDown = function (widget,mousebutton)
			if (mousebutton == 2) then widget.dialog:Close() end
			if (mousebutton == 1) then widget.dialog:BringToFront() gui.StartMoveDialog(widget.dialog.rootwidget) end
		end
	
		-- xml attributes to resize params
		for k,widget in pairs(dialog.childs) do
			widget.mbIgnoreMouseOver = false
			if (widget.node and widget.node.attr.bResizeNoScaleX == "true") then widget.bResizeNoScaleX = true end
			if (widget.node and widget.node.attr.bResizeNoScaleY == "true") then widget.bResizeNoScaleY = true end
		end

		-- scrollbar middle button
		local widget = dialog.controls["skillscroll"]
		-- custom move/drag setpos for handling middle part of the scrollbar
		widget.CustomMoveSetPos = function(widget,x,y)
			local ny = y
			
			-- y limits
			if ny < scrollbar_y_start then ny = scrollbar_y_start end
			if ny > scrollbar_y_end then ny = scrollbar_y_end end
			
			-- calc scroll list index
			local index = table.getn(dialog.lSkill) * ((y - scrollbar_y_start) / scrollbar_h)
			widget.dialog:ScrollToIndex(index)
			
			-- set position
			widget.gfx:SetPos(scrollbar_x,ny)
		end

		-- functions handling the up/down/lock switch
		-- state: (0=up, 1=down, 2=locked)
		dialog.SetSkillLevelState = function (dialog, skillid, lockstate)
			-- print("skillid",skillid,"state",state)
			for k,v in pairs(dialog.lSkill) do
				-- print("check",v.skillid,skillid)
				if v.skillid == skillid then
					-- print("found")
					-- skill found
					-- hide all buttons
					v.button_lock.gfx:SetVisible(lockstate == 2)
					v.button_up.gfx:SetVisible(lockstate == 0)
					v.button_down.gfx:SetVisible(lockstate == 1)
					Send_SkillLockState(skillid-1,lockstate)
					gPlayerSkills[skillid].lockstate = lockstate
				end
			end
		end
		
		-- scrolls the list relative, >0 up <0 down
		dialog.Scroll = function (dialog, d)
			dialog:ScrollToIndex(dialog.miScrollPosition + d)
		end
		
		-- order table
		dialog.Order = function (dialog, comp)
			table.sort(dialog.lSkill, comp or SkillComp_Value)
			local i = 0
			for k,v in pairs(dialog.lSkill) do
				v.index = i
				i = i + 1
			end
		end
		
		dialog.NextOrder = function (dialog)
			local len = #glSkillCompList
			local index = (dialog.current_order_function_index or 0) + 1
			dialog:Order(glSkillCompList[math.fmod(index - 1, len) + 1])
			dialog.current_order_function_index = index
			dialog:ScrollToIndex(0)
			dialog:ScrollToIndex(1)
			dialog:ScrollToIndex(0)
		end
		
		-- scroll the skilllist that index is at the top most position
		dialog.ScrollToIndex = function (dialog, index)
			if index ~= dialog.miScrollPosition then
				-- store scroll position for reopen skill dialog
				gSkillDialog_LastPositionScrollIndex = index
				
				-- startposition
				local x,y = 40,80
				-- number of visible skills
				local h = giNumberOfVisibleSkills

				-- scroll limit
				local maxindex = table.getn(dialog.lSkill) - h
				if index < 0 then index = 0 end
				if index > maxindex then index = maxindex end

				-- store current scroll position
				dialog.miScrollPosition = index
				
				-- position the scroll position thing
				dialog.controls["skillscroll"].gfx:SetPos(scrollbar_x,scrollbar_y_start + scrollbar_h*(index / maxindex))
				
				for k,skill in pairs(dialog.lSkill) do
					if (skill.index >= index) and (skill.index < index + h) then
						-- show skill entry at the correct position
						local localindex = skill.index - index
						
						-- show the skill entry
						if skill.button_use then skill.button_use.gfx:SetVisible(true) end
						if skill.button_use_drag then skill.button_use_drag.gfx:SetVisible(true) end
						skill.text.gfx:SetVisible(true)
						skill.value.gfx:SetVisible(true)
						skill.button_up.gfx:SetVisible(gPlayerSkills[skill.skillid].lockstate == 0)
						skill.button_down.gfx:SetVisible(gPlayerSkills[skill.skillid].lockstate == 1)
						skill.button_lock.gfx:SetVisible(gPlayerSkills[skill.skillid].lockstate == 2)
						
						-- and set the correct positoin
						if skill.button_use then skill.button_use.gfx:SetPos(x,y + localindex*15) end
						skill.text.gfx:SetPos(x+15, y + localindex*15)
						if skill.button_use_drag then skill.button_use_drag.gfx:SetPos(x+148,y + localindex*15) end
						skill.value.gfx:SetPos(x+165, y + localindex*15)
						skill.button_up.gfx:SetPos(x+200, y + localindex*15)
						skill.button_down.gfx:SetPos(x+200, y + localindex*15)
						skill.button_lock.gfx:SetPos(x+200-1, y-1 + localindex*15)
					else
						-- hide skill entry
						if skill.button_use then skill.button_use.gfx:SetVisible(false) end
						if skill.button_use_drag then skill.button_use_drag.gfx:SetVisible(false) end
						skill.text.gfx:SetVisible(false)
						skill.value.gfx:SetVisible(false)
						skill.button_up.gfx:SetVisible(false)
						skill.button_down.gfx:SetVisible(false)
						skill.button_lock.gfx:SetVisible(false)
					end
				end
			end
		end
		
		local curparent = dialog.rootwidget
		local x,y = 40,80
		
		dialog.lSkill = {}
		
		local listindex = 0
		for k,name in pairs(glSkillNames) do
			-- only handle and display available skills
			if gPlayerSkills[k] then
				local skill = {}
				skill.button_use = nil
				skill.button_use_drag = nil
				skill.skillid = k
				skill.name = name
				
				local sname = name				
				if string.len(sname) > 17 then
					sname = string.sub(sname,0,17)..".." 
				end
								
				skill.text = guimaker.MakeText (curparent, x, y, sname, gFontDefs["Gump"].size, gFontDefs["Gump"].col, gFontDefs["Gump"].name)
				--[[
				skill.text.onMouseDown 		= function (widget,mousebutton)
					if (mousebutton == 1) then 
						skill.text.mStartX,skill.text.mStartY = skill.text.gfx:GetPos()
						print("start",skill.text.mStartX,skill.text.mStartY)
						skill.text.dialog:BringToFront() 
						gui.StartMoveDialog(skill.text) 
					end
				end
				-- custom move/drag setpos for handling middle part of the scrollbar
				skill.text.CustomMoveStop = function(widget)
					
				end
				]]--

				skill.value = guimaker.MakeText (curparent, x, y,
													tostring(sprintf("%3.1f",gPlayerSkills[k].value / 10)),
														gFontDefs["Gump"].size, gFontDefs["Gump"].col, gFontDefs["Gump"].name)
				
				skill.button_up = MakeGumpButtonFunctionOnClick(curparent, hex2num("0x983"), hex2num("0x984"), hex2num("0x984"), x, y, 9, 11,
					function (widget,mousebutton) dialog:SetSkillLevelState(skill.skillid,1) end)
				skill.button_up.gfx:SetVisible(gPlayerSkills[k].lockstate == 0)
				
				skill.button_down = MakeGumpButtonFunctionOnClick(curparent, hex2num("0x985"), hex2num("0x986"), hex2num("0x986"), x, y, 9, 11,
					function (widget,mousebutton) dialog:SetSkillLevelState(skill.skillid,2) end)
				skill.button_down.gfx:SetVisible(gPlayerSkills[k].lockstate == 1)
				
				skill.button_lock = MakeGumpButtonFunctionOnClick(curparent, hex2num("0x82c"), hex2num("0x82c"), hex2num("0x82c"), x, y, 12, 15,
					function (widget,mousebutton) dialog:SetSkillLevelState(skill.skillid,0) end)
				skill.button_lock.gfx:SetVisible(gPlayerSkills[k].lockstate == 2)
				
				-- only button in active skills
				if glSkillActive[k] == 1 then
					skill.button_use = MakeGumpButtonFunctionOnClick(curparent, hex2num("0x837"), hex2num("0x838"), hex2num("0x838"), x, y, 11, 11,
						function (widget,mousebutton) Send_Request_SkillUse(skill.skillid) end)
					skill.button_use_drag = MakeGumpButtonFunctionOnClick(curparent, hex2num("0x93a"), hex2num("0x93a"), hex2num("0x93a"), x, y, 11, 11,
						function (widget,mousebutton) end)
					skill.button_use_drag.onMouseDown = function (widget,mousebutton)
						if (mousebutton == 1) then 
							skill.button_use_drag.mStartX,skill.button_use_drag.mStartY = skill.button_use_drag.gfx:GetPos()
							skill.button_use_drag.dialog:BringToFront() 
							gui.StartMoveDialog(skill.button_use_drag) 
						end
					end
					skill.button_use_drag.CustomMoveStop = function(widget)
						-- reset button to source and create quick use/cast button
						-- current position
						local x,y = GetMousePos()
						CreateQuickCastButtonSkill(x,y,skill.skillid)
						
						skill.button_use_drag.gfx:SetPos(skill.button_use_drag.mStartX,skill.button_use_drag.mStartY)
					end
				end
				
				skill.state = gPlayerSkills[k].lockstate
				skill.index = listindex	-- index in the skilllist
				listindex = listindex + 1
				
				printdebug("skill","Skill "..vardump(skill))
				table.insert(dialog.lSkill,skill)
			end
		end

		-- order the list with previous comp function
		if dialog.current_order_function_index and glSkillCompList[dialog.current_order_function_index] then
			dialog:Order(glSkillCompList[dialog.current_order_function_index])
		end
		
		-- scroll to last position if available
		if gSkillDialog_LastPositionScrollIndex then 
			dialog:ScrollToIndex(gSkillDialog_LastPositionScrollIndex)
		else
			dialog:ScrollToIndex(0)
		end

		-- resize limits
		dialog.resize_min_total_x,dialog.resize_min_total_y = -100,-66
		dialog.resize_max_total_x,dialog.resize_max_total_y = 334,212
		
		dialog:NextOrder()
	end
end
