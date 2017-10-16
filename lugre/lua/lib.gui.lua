-- central gui code
-- see also lib.guimaker.lua
-- for includes see lugre.lua

gMouseCorrectionX = 5
gMouseCorrectionY = 5

function GetPlainTextureGUIMat		(texname) return GetTexturedMat("guibasemat",texname) end
function GetPlainTextureGUIMatCol	(texname,r,g,b) return GetHuedMat("guibasemat", r,g,b, r,g,b,1, texname) end

gFocusWidget = nil
function GetFocusWidget		() return gFocusWidget end
function ClearFocusWidget	() SetFocusWidget(nil) end
function SetFocusWidget		(widget) 
	if (widget == gFocusWidget) then return end
	if (gFocusWidget and gFocusWidget.on_focus_lost) then gFocusWidget:on_focus_lost() end
	gFocusWidget = widget
	if (gFocusWidget and gFocusWidget.on_focus_gain) then gFocusWidget:on_focus_gain() end
end


function GuiToggleHide ()	
	SetGuiHidden(not gGUIHidden)
end
function SetGuiHidden (bHidden)	
	if (gGUIHidden == bHidden) then return end
	gGUIHidden = bHidden
	gRootWidget:SetVisible(not gGUIHidden)
	NotifyListener("Hook_GUI_Hidden",gGUIHidden)
end

-- gui system
function GetGUIRootWidget ()
	if (gRootWidget) then return gRootWidget end
	if (gNoOgre) then return end
	gRenderMan2D = CreateRenderManager2D()
	gRenderMan2DAsGroup = gRenderMan2D.CastToRenderGroup2D and gRenderMan2D:CastToRenderGroup2D() or gRenderMan2D
	
	gRootWidget = CreateRootWidget(gRenderMan2DAsGroup) 
	gRootWidget.hudfx		= gRootWidget:CreateLayer("hudfx")
	gRootWidget.dialogs		= gRootWidget:CreateLayer("dialogs")
	gRootWidget.menus		= gRootWidget:CreateLayer("menus")
	gRootWidget.tooltip		= gRootWidget:CreateLayer("tooltip")
	return gRootWidget
end

function GetGUILayer_Dialogs	() return GetGUIRootWidget().dialogs end
function GetGUILayer_Menus		() return GetGUIRootWidget().menus end

-- returns x,y
function GetMousePos ()
	local mx,my = PollInput()
	return mx+gMouseCorrectionX,my+gMouseCorrectionY
end

function GetMouseRay() 
	local x,y = GetMousePos()
	local vw,vh = GetViewportSize()
	return GetScreenRay(x/vw,y/vh) 
end

gWidgetList = {} -- for finding widget via uid
gDialogList = {} -- for finding dialog via uid
gLastMouseDownWidget = nil
gLastMouseDownWidgetEx = {} -- distinguish between different mousebuttons
gLastLeftMouseDownWidget = nil
gWidgetUnderMouse = nil

function GUI_GetWidgetDebugInfo (w)
	if (not w) then return end
	if (not w.GetClassName) then return end -- old gui
	local classname = w:GetClassName()
	local parent = w:GetParent()
	local dialog = w:GetDialog()
	return sprintf("classname=%s parentclass=%s dialogname=%s",classname,parent and parent:GetClassName() or "none",dialog and dialog.sDebugName or "?")
end

function GUIStep ()
	-- detect mouse enter and mouse leave
	local widget = GetWidgetUnderMouse()
	if (gWidgetUnderMouse ~= widget) then
		local oldWidgetUnderMouse = gWidgetUnderMouse
		gWidgetUnderMouse = widget -- guisys2 : must be set before event is fired, for events redirected to parent (e.g. button with multiple childs)
		--~ local w = gWidgetUnderMouse print("widget_under_mouse",GUI_GetWidgetDebugInfo(w),w)
		if (oldWidgetUnderMouse) then GUIMouseEvent("mouse_leave",oldWidgetUnderMouse) end
		if (gWidgetUnderMouse  ) then GUIMouseEvent("mouse_enter",gWidgetUnderMouse  ) end
	end
end

function GUI_TriggerWidgetEventCallback (widget,sEventName)
	if (not widget) then return end
	local callback_name = "on_"..sEventName  -- e.g. widget.on_mouse_left_down
	local callback = widget[callback_name]
	if (callback) then 
		local success,errormsg_or_result = lugrepcall(callback,widget)
		if (not success) then NotifyListener("lugre_error","error in GUI_TriggerWidgetEventCallback",sEventName,"\n",errormsg_or_result) end
		return
	end
	
	if (widget.GetParent) then return GUI_TriggerWidgetEventCallback(widget:GetParent(),sEventName) end -- guisys2
	
	-- old iris gui
	local dialog = widget.dialog
	if (dialog and dialog:IsAlive() and dialog[callback_name]) then dialog[callback_name](dialog) end
end

function GUI_TriggerWidgetCallback_BackwardComp (widget,callback_name,dialogparam,...)
	local bConsumed = false -- the dialog callback is not called if the widget callback returns true
	if (widget[callback_name]) then 
		widget[callback_name](widget,...) 
	else 
		local dialog = widget.dialog
		if (dialog and dialog:IsAlive() and dialog[callback_name]) then dialog[callback_name](dialogparam,...) end
	end
end

-- if the parameter widget is nil, the gLastMouseDownWidget is used
-- called from lib.input.lua, eventname is one of 
-- mouse_left_down,mouse_left_up
-- mouse_right_down,mouse_right_up
-- mouse_middle_down,mouse_middle_up
-- mouse_left_click,mouse_left_click_double,mouse_left_click_single,
-- mouse_left_drag_start,mouse_left_drag_step,mouse_left_drag_stop
-- called from GUIStep, eventname is one of
-- mouse_enter,mouse_leave
-- generates button_click event from mouse_left_click when the mouse is still inside gLastMouseDownWidget
function GUIMouseEvent (sEventName,widget)
	if (gTestNoClick) then return end
	local sInverseMouseEventName
	if (sEventName == "mouse_left_down"  ) then sInverseMouseEventName = "mouse_left_up"   end
	if (sEventName == "mouse_right_down" ) then sInverseMouseEventName = "mouse_right_up"  end
	if (sEventName == "mouse_middle_down") then sInverseMouseEventName = "mouse_middle_up" end

	if (sInverseMouseEventName) then
		gLastMouseDownWidget = GetWidgetUnderMouse() 
		gLastMouseDownWidgetEx[sInverseMouseEventName] = gLastMouseDownWidget
		if (sEventName == "mouse_left_down") then gLastLeftMouseDownWidget = gLastMouseDownWidget end
	end
	widget = widget or gLastMouseDownWidgetEx[sEventName] or gLastMouseDownWidget
	if (sEventName == "mouse_right_up") then widget = GetWidgetUnderMouse() end -- for context/right-click-menu
	
	if (widget and widget:IsAlive()) then
		GUI_TriggerWidgetEventCallback(widget,sEventName)
		
		-- backwards compatibility for iris
		if (true) then 
			local mousebutton
			if (sEventName == "mouse_left_down") then mousebutton = 1 end
			if (sEventName == "mouse_right_down") then mousebutton = 2 end
			if (sEventName == "mouse_middle_down") then mousebutton = 3 end
			if (mousebutton) then GUI_TriggerWidgetCallback_BackwardComp(widget,"onMouseDown",widget,mousebutton) end
			
			mousebutton = nil
			if (sEventName == "mouse_left_up") then mousebutton = 1 end
			if (sEventName == "mouse_right_up") then mousebutton = 2 end
			if (sEventName == "mouse_middle_up") then mousebutton = 3 end
			if (mousebutton) then GUI_TriggerWidgetCallback_BackwardComp(widget,"onMouseUp",widget,mousebutton) end
		end
	end
	
	if (sEventName == "mouse_left_click") then
		local widget = GetWidgetUnderMouse()
		if (widget and widget == gLastLeftMouseDownWidget) then
			GUIMouseEvent("button_click",widget) -- special event for gui stuff, only triggered if mouse is release on the same widget on which it was pressed
			GUI_TriggerWidgetCallback_BackwardComp(widget,"onLeftClick",widget)
		end
	end
end


-- returns true if the gui consumes all input events (ie. to skip keypressed state input handling)
function GuiConsumesInput()
	-- TODO probably remove the dependancy to lib.edittext.lua?
	if not gActiveEditText then
		return false
	else
		return true
	end
end

-- calls callback(key,char) on next keystroke, which is then marked as consumed
function PollNextKey	(callback) gPollNextKeyCallback = callback end

-- returns true if the event was consumed/handled
function GuiKeyDown(key,char)
	local bConsumed
	if (gPollNextKeyCallback) then gPollNextKeyCallback(key,char) gPollNextKeyCallback = nil bConsumed = true end
	if (not bConsumed) then bConsumed = EditTextKeyDown(key,char) end
	if ((not bConsumed) and gFocusWidget and gFocusWidget.on_focus_keydown) then bConsumed = gFocusWidget:on_focus_keydown(key,char) end
	-- todo : stuff like return to trigger default button in modal dialog, tab to change cycle input elements (edit-texts)
	return bConsumed
end

function GetLastMouseDownWidget()
	return gLastMouseDownWidget
end

-- a check to avoid breaking old stable-versions (iris) by lugre update without new binary
function GuiSystem2Ok ()
	if (gGuiSystem2Ok ~= nil) then return gGuiSystem2Ok end
	gGuiSystem2Ok = false
	if (CreateRenderGroup2D) then
		local o = CreateRenderGroup2D()
		gGuiSystem2Ok = (o.GetChildListRevision ~= nil) and (o.GetHandle ~= nil)
	end
	print("gGuiSystem2Ok",gGuiSystem2Ok)
	return gGuiSystem2Ok
end

function GetWidgetUnderMouse () 
	if (gNoRender) then return end
	local mx,my = GetMousePos()
	local id = GetWidgetUnderPos(mx,my)
	local widget = id and gWidgetList[id] 
	if widget then return widget end
	local widget = GuiSystem2Ok() and GetGUIRootWidget():GetWidgetUnderPos(mx,my)
	--~ print("GetWidgetUnderMouse",widget and widget:GetClassName(),widget)
	if (widget) then return widget end
end

function GetDialogUnderMouse () 
	local widget = GetWidgetUnderMouse()
	if (widget and widget.GetDialog) then return widget:GetDialog() end
	return widget and widget.dialog
end
