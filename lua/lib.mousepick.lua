kMousePickHitType_Static = 0
kMousePickHitType_Terrain = 1
kMousePickHitType_Dynamic = 2
kMousePickHitType_Mobile = 3
kMousePickHitType_ContainerItem = 4
kMousePickHitType_PaperdollItem = 5
kMousePickHitType_Container = 6
kMousePickHitType_Ground = 7

gMousePickFoundHit = false
giSelectedMobile = 0

--[[
-- OBSOLETED CODE ! don't use this, hasn't been adjusted to xmirror fix>f TerrainRayIntersect_Hit .lua
function TerrainRayIntersect_Hit(tx,ty,tiletype,hit_dist,minz,maxz)
	gCurrentRenderer:TerrainRayIntersect_Hit (tx,ty,tiletype,hit_dist,minz,maxz)
end
]]--

function MainMousePick ()
	gMousePickFoundHit = false
	Renderer3D.gMousePickFoundHit_ExactX = false
	
	local widget = MousePick_GUI()
	gMousePickFoundHitWidget = widget
	
	-- 3d mousepicking, only if no widget hit
	if (not widget) then gCurrentRenderer:MousePick_Scene() end
	
	gCurrentRenderer:MousePick_ShowHits()
end


-- returns xloc,yloc,zloc   (uocoordinates,directly used by  uodragdrop Send_Drop_Object)
function GetMouseHitTileCoords ()
	if (not gMousePickFoundHit) then return end
	if (gMousePickFoundHit.hit_xloc) then return	gMousePickFoundHit.hit_xloc,
													gMousePickFoundHit.hit_yloc,
													gMousePickFoundHit.hit_zloc end
	if (not Renderer3D.gMousePickFoundHit_ExactX) then return end
	local x,y = Renderer3D:LocalToUOPos(Renderer3D.gMousePickFoundHit_ExactX,Renderer3D.gMousePickFoundHit_ExactY)
	return math.floor(x),math.floor(y),math.floor(0.5 + (Renderer3D.gMousePickFoundHit_ExactZ)/0.1)
end

function MousePick_GUI ()
	-- 2d mousepicking
	local widget = GetWidgetUnderMouse()
	if (widget) then 
		--~ print("MousePick_GUI",widget,widget.uoContainer,widget.item,widget.GetClassName and widget:GetClassName())
		if (widget.item) then
			if (widget.uoPaperdoll) then
				gMousePickFoundHit = {}
				gMousePickFoundHit.hittype = kMousePickHitType_PaperdollItem
				gMousePickFoundHit.item = widget.item
				gMousePickFoundHit.is2DHit = true
			elseif (widget.uoContainer) then
				gMousePickFoundHit = {}
				gMousePickFoundHit.hittype = kMousePickHitType_ContainerItem
				gMousePickFoundHit.item = widget.item
				gMousePickFoundHit.is2DHit = true
			else -- for namegumps(ctrl+shift)
				gMousePickFoundHit = {}
				gMousePickFoundHit.hittype = kMousePickHitType_Dynamic
				gMousePickFoundHit.dynamic = widget.item
				gMousePickFoundHit.hit_xloc = widget.item.xloc
				gMousePickFoundHit.hit_yloc = widget.item.yloc
				gMousePickFoundHit.hit_zloc = widget.item.zloc
				gMousePickFoundHit.is2DHit = true
			end
		elseif widget.dialog and widget.dialog.uoContainer then
			gMousePickFoundHit = {}
			gMousePickFoundHit.hittype = kMousePickHitType_Container
			gMousePickFoundHit.container = widget.dialog.uoContainer
			gMousePickFoundHit.is2DHit = true
		elseif widget.uoContainer then
			gMousePickFoundHit = {}
			gMousePickFoundHit.hittype = kMousePickHitType_Container
			gMousePickFoundHit.container = widget.uoContainer
			gMousePickFoundHit.is2DHit = true
		elseif widget.mobile then
			local mobile = widget.mobile
			gMousePickFoundHit = {}
			gMousePickFoundHit.hittype = kMousePickHitType_Mobile
			gMousePickFoundHit.mobile = mobile
			gMousePickFoundHit.hit_xloc = mobile.xloc
			gMousePickFoundHit.hit_yloc = mobile.yloc
			gMousePickFoundHit.hit_zloc = mobile.zloc
			gMousePickFoundHit.is2DHit = true
		end
	end
	return widget
end



-- excecutes mousepick by default
function GetMouseHitSerial (bExecuteMousePick)
	local o = GetMouseHitObject(bExecuteMousePick)
	return o and o.serial or 0
end

-- excecutes mousepick by default
function GetMouseHitObject (bExecuteMousePick)
	if (bExecuteMousePick == nil) then bExecuteMousePick = true end
	if (bExecuteMousePick) then MainMousePick() end
	if (gMousePickFoundHit) then
		if (gMousePickFoundHit.hittype == kMousePickHitType_Static			) then return gMousePickFoundHit.entity end
		if (gMousePickFoundHit.hittype == kMousePickHitType_Dynamic			) then return gMousePickFoundHit.dynamic end
		if (gMousePickFoundHit.hittype == kMousePickHitType_Mobile			) then return gMousePickFoundHit.mobile end
		if (gMousePickFoundHit.hittype == kMousePickHitType_ContainerItem	) then return gMousePickFoundHit.item end
		if (gMousePickFoundHit.hittype == kMousePickHitType_PaperdollItem	) then return gMousePickFoundHit.item end
		if (gMousePickFoundHit.hittype == kMousePickHitType_Container		) then return gMousePickFoundHit.container end
	end
end


function IrisDoubleClick ()
	MainMousePick()
	ClosePopUpMenu()
	local iSerial = GetMouseHitSerial()
	if gKeyPressed[key_lcontrol] then
		-- open status window if control pressed and mobile targeted
		if (iSerial and iSerial ~= 0) then 
			local mobile = GetMobile(iSerial)
			local iMouseX,iMouseY = GetMousePos()
			-- -50,-30 to place the dialog beneath the mouse
			OpenHealthbar(mobile,iMouseX - 50,iMouseY - 30)
		end
	elseif gKeyPressed[key_lshift] then
		Pathfinding_TriggeredByMouse()
	else
		-- normal doubleclick handling
		local pm = GetPlayerMobile()
		local othermobile = gMobiles[iSerial]
		
		if ((not IsWarModeActive()) or (pm and iSerial == pm.serial) or not othermobile) then
			if (iSerial and iSerial ~= 0) then
				printdebug("net",sprintf("IrisDoubleClick: serial=0x%08x\n",iSerial))
				Send_DoubleClick(iSerial)
			end
		end
		if (IsWarModeActive()) then
			if (iSerial and iSerial ~= 0) then
				printdebug("net",sprintf("IrisDoubleClickAttack: serial=0x%08x\n",iSerial))
				Send_AttackReq(iSerial)
			end
		end
	end
end

-- currently sent on mousedown
gbMouseLastLeftDownWasTarget = false	-- used to handle target on mouse down but dont send context menu then
gbMouseLastLeftDownWasTargetPositionX = 0
gbMouseLastLeftDownWasTargetPositionY = 0
function IrisLeftClickDown ()
	ClosePopUpMenu()
	gbMouseLastLeftDownWasTarget = false
	gbMouseLastLeftDownWasTargetPositionX, gbMouseLastLeftDownWasTargetPositionY = GetMousePos()
	
	if (gTestNoClick) then return end
	if (IsTargetModeActive()) then 
		if (CompleteTargetMode()) then gbMouseLastLeftDownWasTarget = true end -- see net/net.cursor.lua
	else 
		if (MobListSetMainTargetSerial) then
			MobListSetMainTargetSerial(GetMouseHitSerial())
		end
	end
end

function IrisDragStart ()
	local mobile = gMouseDragMobile -- from MouseDownUODragDrop kMousePickHitType_Mobile
	if (not mobile) then return end
	local iMouseX,iMouseY = GetMousePos()
	-- -50,-30 to place the dialog beneath the mouse
	local widget = OpenHealthbar(mobile,iMouseX - 50,iMouseY - 30)
	if (widget) then widget:BringToFront() widget:StartMouseMove() end
end
function IrisSingleClick ()
	ClosePopUpMenu()
	if (gTestNoClick) then return end

	local x, y = GetMousePos()

	if 	
		not gbMouseLastLeftDownWasTarget and 
		len2(sub2(x,y,gbMouseLastLeftDownWasTargetPositionX, gbMouseLastLeftDownWasTargetPositionY)) <= 2
	then 
		local iSerial = GetMouseHitSerial()
		gLastRightClickSerial = nil
		if (iSerial and iSerial ~= 0) then 
			printdebug("net",sprintf("IrisContextMenuClick: serial=0x%08x\n",iSerial))
			Send_PopupRequest(iSerial) 
			gLastRightClickSerial = iSerial
			
			Send_SingleClick(iSerial) -- needs to be sent for pre-aos shard, triggers description sent, as there's no tooltip there
			ClearToolTipAndLabelCache(iSerial)
		end

		--~ local iSerial = GetMouseHitSerial()
		--~ if (iSerial and iSerial ~= 0) then 
			--~ printdebug("net",sprintf("IrisSingleClick: serial=0x%08x\n",iSerial))
			--~ Send_SingleClick(iSerial)
			--~ gCurrentRenderer:SelectMobile(iSerial)
		--~ else
			--~ -- TODO is this too removey?
			--~ -- gCurrentRenderer:DeselectMobile()
			--~ 
			--~ if gEnableGotoOnClick and not GetWidgetUnderMouse() then
				--~ local x,y = GetMouseHitTileCoords()
				--~ SetAutoWalkTo(x,y)
			--~ end
		--~ end
	end
end

function IrisRightClick ()
	
end

-- find mobile with the minimum distance to player (x,y 2d based)
function SelectNearestMobile ()
	gCurrentRenderer:DeselectMobile()
	
	local mindist = -1
	local minserial = 0
	local playermobile = GetMobile(gPlayerBodySerial)
	if (playermobile) then
		for k,mobile in pairs(GetMobileList()) do 
			if (k ~= gPlayerBodySerial) then
				-- calculate distance to player
				local dx = (mobile.xloc - playermobile.xloc)
				local dy = (mobile.yloc - playermobile.yloc)
				local d = math.sqrt(dx*dx + dy*dy)
				if (mindist < 0 or d < mindist) then
					-- new min found
					minserial = k
					mindist = d
				end
			end
		end
	end
	-- select the nearest if found
	if (minserial ~= 0) then
		SelectMobile(minserial)
	end
end

function SelectMobile(serial)
	gCurrentRenderer:SelectMobile(serial)
	NotifyListener("Hook_SelectMobile",serial)
end

-- selects the next mobile cycling through all mobiles
function SelectNextMobile ()
	local current = giSelectedMobile
	local minserial = -1
	local nextminserial = -1
	-- print ("current", current)

	for k,mobile in pairs(GetMobileList()) do
		if (current < k and (k < nextminserial or nextminserial < 0)) then
			-- small serial (bigger than current found)
			nextminserial = k
			-- print ("nextminserial",nextminserial)
		end
		if (minserial < 0 or k < minserial) then
			-- searches for the absolute min serial, cycle start
			minserial = k
			-- print ("minserial",minserial)
		end
	end
	
	-- select the next if found
	if (nextminserial > 0) then
		SelectMobile(nextminserial)
	else
		-- or the start if no next found
		if (minserial > 0) then
			SelectMobile(minserial)
		end
	end
end
