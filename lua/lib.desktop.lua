--[[ ***** see Iris2 COPYING for license info ***** ]]--
--[[ \brief
        handles ingame desktop savings
]]--

gDesktop = {}
gDesktopPositions = {}
gDesktopFile = "test.lua"

gDesktopElementFactory = {}

-- ------------------------------------------------------------------------
-- paperdoll
-- ------------------------------------------------------------------------
gDesktopElementFactory.paperdoll = {
    open = function(x,y,param) OpenPaperdoll(x,y,param) end, 
    checkpos = function(e, widget) 
        local d = widget.dialog
        local p = gPaperdolls[e.param]
        if p and d and p.dialog == d then e.x,e.y = widget.gfx:GetPos() return true end
    end,
}
RegisterListener("Hook_ClosePaperdoll",function(p) RemoveDesktopElement("paperdoll",p.serial) SaveDesktop() end)
RegisterListener("Hook_RebuildPaperdoll",function(p) 
    if p.dialog and p.dialog.rootwidget and p.dialog.rootwidget.gfx then
        local x,y = p.dialog.rootwidget.gfx:GetPos()
        ReplaceDesktopElement("paperdoll",x,y,p.serial)     
        SaveDesktop()
    end
end)

-- ------------------------------------------------------------------------
-- weaponability
-- ------------------------------------------------------------------------
gDesktopElementFactory.weaponability = {
    open = function(x,y,param) CreateQuickCastButtonWeaponability(x,y,param) end, 
    checkpos = function(e, widget) 
        local d = widget.dialog
        local id = d and d.weaponabilityid or widget.weaponabilityid
        if id == e.param then
            e.x,e.y = widget:GetPos() 
            return true
        end
    end,
}
RegisterListener("Hook_CloseQuickCastButton",function(d) 
    if d.weaponabilityid then 
        RemoveDesktopElement("weaponability",d.weaponabilityid) 
        SaveDesktop() 
    end
end)
RegisterListener("Hook_CreateQuickWeaponAbility",function(d,x,y,weaponabilityid) 
    ReplaceDesktopElement("weaponability",x,y,weaponabilityid)  
    SaveDesktop()
end)

-- ------------------------------------------------------------------------
-- spell
-- ------------------------------------------------------------------------
gDesktopElementFactory.spell = {
    open = function(x,y,param) CreateQuickCastButtonSpell(x,y,param) end, 
    checkpos = function(e, widget) 
        local d = widget.dialog
        local id = d and d.spellid or widget.spellid
        if id == e.param then
            e.x,e.y = widget:GetPos() 
            return true
        end
    end,
}
RegisterListener("Hook_CloseQuickCastButton",function(d) 
    if d.spellid then 
        RemoveDesktopElement("spell",d.spellid) 
        SaveDesktop() 
    end
end)
RegisterListener("Hook_CreateQuickCastSpell",function(d,x,y,spellid) 
    ReplaceDesktopElement("spell",x,y,spellid)  
    SaveDesktop()
end)

-- ------------------------------------------------------------------------
-- skill
-- ------------------------------------------------------------------------
gDesktopElementFactory.skill = {
    open = function(x,y,param) CreateQuickCastButtonSkill(x,y,param) end, 
    checkpos = function(e, widget) 
        local d = widget.dialog
        local id = d and d.skillid or widget.skillid
        if id == e.param then
            e.x,e.y = widget.gfx:GetPos() 
            return true
        end
    end,
}
RegisterListener("Hook_CloseQuickCastButton",function(d) 
    if d.skillid then 
        RemoveDesktopElement("skill",d.skillid) 
        SaveDesktop() 
    end
end)
RegisterListener("Hook_CreateQuickCastSkill",function(d,x,y,skillid) 
    ReplaceDesktopElement("skill",x,y,skillid)  
    SaveDesktop()
end)

-- ------------------------------------------------------------------------
-- healthbar
-- ------------------------------------------------------------------------
gDesktopElementFactory.healthbar = {
    open = function(x,y,param) OpenHealthbar(GetMobile(param),x,y) end, 
    checkpos = function(e, widget) 
        local serial = (widget.mobile and widget.mobile.serial) or 0
        if e.param == serial then e.x,e.y = widget:GetPos() return true end
    end,
}
RegisterListener("Hook_CloseHealthbar",function(widget,serial) 
	if (serial == GetPlayerSerial()) then
		RemoveDesktopElement("healthbar",serial) 
		SaveDesktop() 
	end
end)
RegisterListener("Hook_OpenHealthbar",function(widget,serial) 
    local serial = widget.mobile.serial
    if widget and serial and serial == GetPlayerSerial() then
        local x,y = widget:GetPos()
        ReplaceDesktopElement("healthbar",x,y,serial)   
        SaveDesktop()
    end
end)

-- ------------------------------------------------------------------------
-- container
-- ------------------------------------------------------------------------
gDesktopElementFactory.container = {
    open = function(x,y,param) 
			-- OpenContainer(param,x,y)   disabled for now, doubleclicking more than one causes "you must wait" anyway
		end, 
    checkpos = function(e, widget) 
        local serial = (widget.uoContainer and widget.uoContainer.serial) or 0
        if e.param == serial then e.x,e.y = widget:GetPos() return true end
    end,
}

function Desktop_ShouldContainerBeSaved (widget) -- ignore corpses here (massive with autoloot)
	return widget and widget.uoContainer and widget.uoContainer.gumpid ~= kCorpseContainerGumpID 
end

RegisterListener("Hook_CloseContainer",function(widget) 
	if (Desktop_ShouldContainerBeSaved(widget)) then 
		local serial = widget.uoContainer.serial
		RemoveDesktopElement("container",serial) 
		SaveDesktop() 
	end
end)
RegisterListener("Hook_CreateContainerWidget",function(widget) 
    if Desktop_ShouldContainerBeSaved(widget) then
		local serial = widget.uoContainer.serial
        local x,y = widget:GetPos()
        ReplaceDesktopElement("container",x,y,serial)   
        SaveDesktop()
    end
end)
-- ------------------------------------------------------------------------
-- ------------------------------------------------------------------------

function GetDesktopElementPosition  (name,param)
    -- print("****** GetDesktopElementPosition",name,param)
    for k,v in pairs(gDesktop) do
        if v.param == param and v.name == name then
            -- print("******1 ->",v.x,v.y)
            return v.x,v.y          
        end
    end
    for k,v in pairs(gDesktopPositions) do
        if v.param == param and v.name == name then
            -- print("******2 ->",v.x,v.y)
            return v.x,v.y
        end
    end
end

function luadump    (name,data)
    if tonumber(name) ~= nil then
        name = "["..name.."]"
    elseif string.find(name," ") ~= nil then
        name = "['"..name.."']"
    end
    
    local t = type(data)
    if t == "table" then
        local s = name.."={"
        for k,v in pairs(data) do
            local ss = luadump(k,v,true)
            if ss ~= nil then
                s = s..ss..","
            end
        end
        s = s.."}"
        return s
    elseif t == "string" then
        return name.."='"..tostring(data).."'"
    elseif t == "number" then
        return name.."="..tostring(data)..""
    elseif t == "boolean" then
        return name.."="..tostring(data)..""
    end
    
    return nil
end

-- loads a given desktop
function LoadDesktop    (file)
    gDesktopFile = file
    gDesktop = {}
    gDesktopPositions = {}
    if file then
        local path = gDesktopDir..file
        if file_exists(path) then
            dofile(path)
            ReopenDesktop()
        end
    end
end

-- stores the current desktop into a file, if file is nil the current opened file will be used
function SaveDesktop    (file)
	--~ print("#####SaveDesktop",debug.traceback())
    file = file or gDesktopFile
    if file then
        local path = gDesktopDir..file
        -- write to file
        local fp = io.open(path,"w")
        if (fp) then
            fp:write(luadump("gDesktop",gDesktop).."\n")
            fp:write(luadump("gDesktopPositions",gDesktopPositions).."\n")
            fp:close()
        end
    end
end

-- create/open/reposition then given desktop element, like spell, backback...
function OpenDesktopElement(name,x,y,param)
    if gDesktopElementFactory[name] and gDesktopElementFactory[name].open then
        gDesktopElementFactory[name].open(x,y,param)
    end
end

-- create/open/reposition then current desktop, use this after teleport or similar events
function ReopenDesktop()
    if (gNoRender) then return end
    for k,v in pairs(gDesktop) do
        OpenDesktopElement(v.name,v.x,v.y,v.param)
    end
end

function RemoveDesktopElement(name,param)
    for k,v in pairs(gDesktop) do
        if v.name == name and v.param == param then
            gDesktop[k] = nil
        end
    end
end

function ReplaceDesktopElementIn(name,x,y,param,list)
    for k,v in pairs(list) do
        if v.name == name and v.param == param then
            v.x = x
            v.y = y
            return
        end
    end
    
    table.insert(list, {name=name,x=x,y=y,param=param})
end

function ReplaceDesktopElement(name,x,y,param)
    ReplaceDesktopElementIn(name,x,y,param,gDesktop)
    ReplaceDesktopElementIn(name,x,y,param,gDesktopPositions)
end

RegisterListener("Gui_StopMouseMoveWidget",function(widget,x,y) -- new gui system
    if (not widget:IsAlive()) then return end
    local nx,ny = widget:GetPos()
    print("Gui_StopMouseMoveWidget",widget,x,y,nx,ny)
	local bSaveNeeded = false
    for k,v in pairs(gDesktop) do
        if gDesktopElementFactory[v.name] and gDesktopElementFactory[v.name].checkpos then
			local oldx,oldy = v.x,v.y
            if gDesktopElementFactory[v.name].checkpos(v,widget) then 
                --~ print("REPLACE",nx,ny)
                ReplaceDesktopElementIn(v.name,nx,ny,v.param,gDesktopPositions)
				if (v.x ~= oldx or v.y ~= oldy) then bSaveNeeded = true end
            end
        end
    end
	if (bSaveNeeded) then SaveDesktop() end
end)

RegisterListener("Gui_StopMoveDialog",function(widget,x,y) -- old gui system
    for k,v in pairs(gDesktop) do
        if gDesktopElementFactory[v.name] and gDesktopElementFactory[v.name].checkpos then
            if gDesktopElementFactory[v.name].checkpos(v,widget) then 
                ReplaceDesktopElementIn(v.name,x,y,v.param,gDesktopPositions)
                SaveDesktop() 
            end
        end
    end
end)

RegisterListener("Hook_StartInGame",function() 
    gSelectedShardName = gSelectedShardName or (gLoginServerIP.."."..gLoginServerPort) -- "unknown"
    gSelectedCharName = gSelectedCharName or "unknown"
    local filename = gSelectedShardName.."-"..gSelectedCharName..".lua"
    LoadDesktop(filename) 
end)
