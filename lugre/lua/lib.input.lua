gBinds_Up = {}
gBinds_Down = {}
_GetKeyName = GetKeyName
function GetKeyName (keycode) 
	if keycode == 7 then return "wheelup" end
	if keycode == 6 then return "wheeldown" end
	return _GetKeyName(keycode)
end
function UnbindAll	()
	gBinds_Up = {}
	gBinds_Down = {}
end
function BindUp		(keyname,fun,arg)
	gBinds_Up[GetNamedKey(keyname)] = {fun,arg}
end
function BindDown	(keyname,fun,arg)
	gBinds_Down[GetNamedKey(keyname)] = {fun,arg}
end
function BindUpDown	(keyname,upfun,uparg,downfun,downarg)
	local key = GetNamedKey(keyname)
	gBinds_Up[key] = {upfun,uparg}
	gBinds_Down[key] = {downfun,downarg}
end
function BindUpDown	(keyname,downfun,downarg,upfun,uparg)
	local key = GetNamedKey(keyname)
	gBinds_Down[key] = {downfun,downarg}
	gBinds_Up[key] = {upfun,uparg}
end
function Bind	(keyname,fun)
	BindUpDown(keyname,fun,1,fun,0)
end
function UnBindArr	(arr) for k,v in pairs(arr) do UnBind(v) end end
function UnBind		(keyname)
	gBinds_Down[GetNamedKey(keyname)] = nil
	gBinds_Up[GetNamedKey(keyname)] = nil
end
function SaveBindSet	()
	return { downbinds=gBinds_Down, upbinds=gBinds_Up }
end
function LoadBindSet	(bindset) 
	gBinds_Down = bindset.downbinds
	gBinds_Up = bindset.upbinds
end

-- calls step_fun(...) until key[keywatch] is released or step_fun(...) returns something that evaluates to true
function WhileKeyDown	(keywatch,step_fun,...)
	local myargs = {...}
	RegisterStepper(function () return (not gKeyPressed[keywatch]) or step_fun(unpack(myargs)) end)
end


-- generate key-code constants, like key_mouse1 etc
gKeyNames = GetAllKeyNames()
for k,keyname in pairs(gKeyNames) do _G["key_"..keyname] = GetNamedKey(keyname) end
key_mouse_left		= key_mouse1 -- alias
key_mouse_right		= key_mouse2 -- alias
key_mouse_middle	= key_mouse3 -- alias
gKeyPressed		= {}

gKeyCodeFix = {}
gKeyCodeFix[key_np1] = string.byte("1")
gKeyCodeFix[key_np2] = string.byte("2")
gKeyCodeFix[key_np3] = string.byte("3")
gKeyCodeFix[key_np4] = string.byte("4")
gKeyCodeFix[key_np5] = string.byte("5")
gKeyCodeFix[key_np6] = string.byte("6")
gKeyCodeFix[key_np7] = string.byte("7")
gKeyCodeFix[key_np8] = string.byte("8")
gKeyCodeFix[key_np9] = string.byte("9")
gKeyCodeFix[key_np0] = string.byte("0")
gKeyCodeFix[key_npkomma] = string.byte(",")


gLastMouseDownX,gLastMouseDownY = 0,0
gLastMouseDownTime = 0 -- for click and doubleclick
gLastMouseClickTime = 0 -- for doubleclick detection
gLastMouseClickX = 0 -- for doubleclick detection
gLastMouseClickY = 0 -- for doubleclick detection
gbMouseDragging = false
gDoubleClickIntervall = 400
gMouseDragMinDist = 5
giWaitForSingleClick = nil

--[[
	events :
	mouse_left_down, mouse_left_up, 
	mouse_left_drag_start/step/end : gMouseDragMinDist (prevents mouseclick)
	mouse_left_click (immediately at mouseup, no double wait, triggered two times during doubleclick, not triggered during drag) : 
	mouse_left_click_single (avoid this!, only after doubleclick isn't possible anymore : not triggered at all during doubleclick)
	mouse_left_click_double 
	mouse_right_down,mouse_right_up
	(those should also be gui events sent to the widget under mouse)
	
	slow click should be possible for non-single click event : act as click as long as mouse is not dragged, independent from time
	
	
	hudnames clickable ? 
	no cam-move when click/drag was started on dialog : remember last mousepick on mousedown ?  (gbMouseDownWasOnDialog)
	do start cam-move when drag was started on hudname -> not normal mousepicking on hudnames
	no shipedit-module-placement-click if clicking on dialog
	no ingame target selection when choosing options from rightclick menu

	rightclick-menu : disappear/choose on right-mouse-up : button must get mouseup before dialog is closed :
	close command not as general mouseup binding, but rather as  button-mouseup + generic mouseup when not on any button
	trigger generic mouseup bind AFTER dialog mouseup events ?
	send all gui-events to last-clicked-widget and to dialog (who can then check if a widget was clicked if it wants)
	
	mousedown on button, move outside and back in, then mouseup, what should happen ?
	gbMouseHasBeenOutsideDuringPress = true : let widget decide. 
						
	keyboard input : escape should deaktivate edittext, tab should go to the next edit-text within the dialog

	rightclick menu : on rightmouseup : handle gui events before bind
]]--



function MouseEvent	(eventname)
	GUIMouseEvent(eventname) -- notify gui before general listeners
	NotifyListener(eventname)
end

-- called from c
function KeyDown (key,char)
	--~ print("KeyDown",key,GetKeyName(key),char,gKeyCodeFix[key])
	if (char == 0) then char = gKeyCodeFix[key] or char end -- workaround for broken numpad charcodes
	
	gKeyPressed[key] = true
	local bConsumed = GuiKeyDown(key,char)
	NotifyListener("keydown",key,char,bConsumed)
	
	-- trigger key bindings only if gui does not consume the event
	if (not bConsumed) then
		local bind = gBinds_Down[key]
		if (bind) then 
			local success,errormsg = lugrepcall(bind[1],bind[2])
			if (not success) then NotifyListener("lugre_error","error in KeyDown gBinds_Down",key,GetKeyName(key),"\n",errormsg) end
		end
	end
	
	-- click and doubleclick (left mouse)
	if (key == key_mouse1) then
		MouseEvent("mouse_left_down")
		gLastMouseDownX,gLastMouseDownY = GetMousePos()
		gLastMouseDownTime = Client_GetTicks()
	end

	-- handle right clickt stuff
	if (key == key_mouse2) then MouseEvent("mouse_right_down") end
end

--[[
RegisterListener("mouse_left_down",			function () print("mouse_left_down") end)
RegisterListener("mouse_left_up",			function () print("mouse_left_up") end)
RegisterListener("mouse_left_click",		function () print("mouse_left_click") end)
RegisterListener("mouse_left_click_single",	function () print("mouse_left_click_single") end)
RegisterListener("mouse_left_click_double",	function () print("mouse_left_click_double") end)
RegisterListener("mouse_left_drag_start",	function () print("mouse_left_drag_start") end)
RegisterListener("mouse_left_drag_stop",	function () print("mouse_left_drag_stop") end)
]]--


-- called from c
function KeyUp (key)
	gKeyPressed[key] = false
	NotifyListener("keyup",key)
	
	if (key == key_mouse2) then MouseEvent("mouse_right_up") end
	
	-- mouse_left_up
	if (key == key_mouse1) then 
		MouseEvent("mouse_left_up")
		
		if (gbMouseDragging) then
			-- finish dragging
			MouseEvent("mouse_left_drag_stop")
			gbMouseDragging = false
		else
			-- calculate pixeldistsance between last click and this one
			local x,y = GetMousePos()
			local dist = len2(gLastMouseClickX - x, gLastMouseClickY - y)

			-- detect single and double clicks
			MouseEvent("mouse_left_click")
			local curtime = Client_GetTicks()
			local time_since_last_click = curtime - gLastMouseClickTime
			gLastMouseClickTime = gLastMouseDownTime
			gLastMouseClickX = x
			gLastMouseClickY = y
			
			if (time_since_last_click < gDoubleClickIntervall and dist < 5) then
				MouseEvent("mouse_left_click_double")
				giWaitForSingleClick = nil
				gLastMouseClickTime = 0
			else
				-- not a double click so far, prepare for singleclick
				giWaitForSingleClick = curtime + gDoubleClickIntervall
			end
		end
	end
	
	-- trigger keybinds
	local bind = gBinds_Up[key]
	if bind then 
		local success,errormsg = lugrepcall(bind[1],bind[2])
		if (not success) then NotifyListener("lugre_error","error in KeyUp gBinds_Up",key,GetKeyName(key),"\n",errormsg) end
	end
end

-- called directly after keyboard and mouse events (all generated at the end of RenderOneFrame) have been processed
function InputStep()
	-- trigger delayed single click (only triggered after doubleclick isn't possible anymore)
	local curtime = Client_GetTicks()
	if (giWaitForSingleClick and curtime >= giWaitForSingleClick) then
		MouseEvent("mouse_left_click_single")
		giWaitForSingleClick = nil
	end
	
	-- detect drag
	if (gbMouseDragging) then
		MouseEvent("mouse_left_drag_step")
	elseif (gKeyPressed[key_mouse1] and (not gbMouseDragging)) then
		local mx,my = GetMousePos()
		if (math.max(math.abs(gLastMouseDownX-mx),math.abs(gLastMouseDownY-my)) > gMouseDragMinDist) then
			MouseEvent("mouse_left_drag_start")
			gbMouseDragging = true
		end
	end
end

-- for keybinds see data/lua/lib.keybinds.lua
