-- handles context/right-click menus

--[[
	menudata = {
		{ "Label" },
		{ "ButtonText", function () ... end },
		{ "SubMenuTitle", { ... menudata ... } },
	}	
]]--

gSubMenuOffsetX =  0
gSubMenuOffsetY = -2

-- used as callback
function ContextMenuItemEnterButton	(widget)
	--print("ContextMenuItemEnter")
	-- close active submenus
	ContextMenu_CloseActiveSubmenu(widget.dialog)
	
	-- if this menu has a styleset use it
	local stylesetname
	if widget.style and widget.style.stylesetname then stylesetname = widget.style.stylesetname end
	
	-- open own submenu
	if (widget.submenu) then
		--print("open submenu")
		local x = widget.gfx:GetDerivedLeft() + widget.gfx:GetWidth() + gSubMenuOffsetX
		local y = widget.gfx:GetDerivedTop() + gSubMenuOffsetY
		widget.dialog.active_submenu = ShowContextMenu(widget.submenu,x,y,stylesetname)
		widget.dialog.active_submenu.parentmenu = widget.dialog
	end
	guimaker.Button_HilightOn(widget)
end

-- used as callback
function ContextMenuItemSelect	(widget)
	-- print("ContextMenuItemSelect")
	widget.callback()
	-- close parent and submenus as well in case of selection in sub-menu
	CloseContextMenu(ContextMenu_GetRoot(widget.dialog))
end

-- find the root menu if contextmenudialog is a submenu
function ContextMenu_GetRoot (contextmenudialog) 
	while contextmenudialog.parentmenu do contextmenudialog = contextmenudialog.parentmenu end
	return contextmenudialog
end

-- closes all submenus
function ContextMenu_CloseActiveSubmenu (contextmenudialog)
	if (contextmenudialog.active_submenu) then 
		CloseContextMenu(contextmenudialog.active_submenu) 
		contextmenudialog.active_submenu = nil
	end
end

-- closes the menu and all submenus
function CloseContextMenu (contextmenudialog) 
	if (not contextmenudialog:IsAlive()) then return end
	ContextMenu_CloseActiveSubmenu(contextmenudialog)
	contextmenudialog:Destroy()
end

-- creates a simple menu bar containing contextmenus (static or dynamic)
-- menubardata : { {label,menudata}, {label,menudata}, {label,function() returns menudata end, ...}
function ShowMenuBar			(menubardata,x,y,stylesetname)
	local menues = {}
	for k,menubaritem in pairs(menubardata) do
		local labeltext = menubaritem[1]
		local menudata = menubaritem[2]
		table.insert(menues, {type="Button",text=labeltext, 
			on_mouse_right_down=function(widget) MenuBarOpenMenu(widget,menudata,stylesetname) end,
			on_mouse_left_down= function(widget) MenuBarOpenMenu(widget,menudata,stylesetname) end} )
	end
	local menubardialog = guimaker.MakeTableDlg({ menues },x,y,false,true,stylesetname,"border")
	menubardialog.on_mouse_left_down	= function (dialog) end -- prevent default dialog behaviour : move
	menubardialog.on_mouse_right_down	= function (dialog) end -- prevent default dialog behaviour : close
	
	return menubardialog
end

-- opens a submenu in the menubar
function MenuBarOpenMenu(widget,menudata,stylesetname)
	local x = widget.gfx:GetDerivedLeft()
	local y = widget.gfx:GetDerivedTop() + widget.gfx:GetHeight()
	
	local data = nil
	if (type(menudata) == "function") then
		-- dynamic menu
		data = menudata()
	else
		-- static menu
		data = menudata
	end
	
	local contextmenudialog = ShowContextMenu(data,x - 2,y - 1,stylesetname)
	contextmenudialog.parentmenubarbuttonwidget = widget
end

--[[
*close-[down]->open
*open-[down/overbutton]->activate
*open-[down/!inside && !parentbutton]->close
*open-[up/overbutton]->activate
*open-[up/!inside && !parentbutton]->close

action: open,close,activate
condition: overbutton,inside


TODO keep mouse pressend and trigger button with release only works on rightclick-contextmenus not on menubar-contextmenus


]]--

function ContextMenu_CloseOnOutside	(contextmenudialog)
	-- print("ContextMenu_CloseOnOutside")
	if (not contextmenudialog:IsAlive() or not contextmenudialog) then
		return true
	end

	-- HACK: skip the first event, this event is the one that opens the dialog
	if not contextmenudialog.mouse_event_skipped then
		contextmenudialog.mouse_event_skipped = true
		return false
	end
	
	local widgetundermouse = GetWidgetUnderMouse()
	if widgetundermouse and contextmenudialog.parentmenubarbuttonwidget == widgetundermouse then
		-- dont close the menu if the parent menu bar button is under the mouse
		return false
	end
	
	local dialogundermouse = GetDialogUnderMouse()
	if (not dialogundermouse or ContextMenu_GetRoot(contextmenudialog) ~= ContextMenu_GetRoot(dialogundermouse)) then
		-- !inside
		-- close
		CloseContextMenu(ContextMenu_GetRoot(contextmenudialog))
		return true
	end
end

function ShowContextMenu		(menudata,x,y,stylesetname) 
	local rows = {}
	for k,itemdata in pairs(menudata) do
		local labeltext = itemdata[1]
		if (not itemdata[2]) then -- label
			table.insert(rows,{ {type="Label",text=labeltext} })
		elseif (type(itemdata[2]) == "function") then -- button 
			table.insert(rows,{ {type="Button",text=labeltext, 			callback=itemdata[2],	on_mouse_enter=ContextMenuItemEnterButton, on_mouse_right_up=ContextMenuItemSelect, on_mouse_left_up=ContextMenuItemSelect} })
		elseif (type(itemdata[2]) == "table") then -- submenu
			table.insert(rows,{ {type="Button",text=labeltext.."  >>",	submenu=itemdata[2],	on_mouse_enter=ContextMenuItemEnterButton} })
		else
			assert(false,"ShowContextMenu : unknown menudatatype "..tostring(type(itemdata[2]))..","..tostring(itemdata[2]))
		end
	end
	if (not x) then x,y = GetMousePos() end
	local contextmenudialog = guimaker.MakeTableDlg(rows,x,y,false,true,stylesetname)
	contextmenudialog.on_mouse_left_down	= function (dialog) end -- prevent default dialog behaviour : move
	contextmenudialog.on_mouse_right_down	= function (dialog) end -- prevent default dialog behaviour : close
	
	-- register listener for mouse events
	RegisterListener("mouse_left_down",function () return ContextMenu_CloseOnOutside(contextmenudialog) end)
	RegisterListener("mouse_left_up",function () return ContextMenu_CloseOnOutside(contextmenudialog) end)
	RegisterListener("mouse_right_down",function () return ContextMenu_CloseOnOutside(contextmenudialog) end)
	RegisterListener("mouse_right_up",function () return ContextMenu_CloseOnOutside(contextmenudialog) end)
	
	return contextmenudialog
end
