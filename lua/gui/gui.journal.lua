-- Created 09.03.2008 12:25:56, with GumpStudio & Iris2 Lua Export Plugin
-- Exported Iris2 GumpExporter ver 1.0.
local journalGump = {}
journalGump.dialogId = 3000001
journalGump.x = 10
journalGump.y = 50
journalGump.Data =
	 "{ page 0 }" ..
	 "{ gumppic 4 27 2080 xx1 }" ..
	 "{ gumppic 21 64 2081 xx2 }" ..
	 "{ gumppic 21 134 2082 xx3 }" ..
	 "{ gumppic 23 204 2083 xx4 }" ..
	 "{ gumppic 118 36 2090 xx5 }" ..
	 "{ gumppic 38 65 2091 xx6 }" ..
	 "{ gumppic 38 183 2091 xx7 }" ..
	 "{ button 139 4 2093 2093 1 0 0 journalminimize }" ..
	 "{ button 139 235 2094 2095 1 1 1 journalresize }" ..
	 "{ button 260 77 2088 2088 1 0 2 xx8 }" ..
	 "{ button 254 61 2084 2084 1 0 3 xx9 }" ..
	 "{ button 254 181 2085 2085 1 0 4 xx10 }" ..
	 "{ button 241 181 2092 2092 1 0 5 xx11 }"
journalGump.textline = {
}
journalGump.functions = {
 -- journalminimize
 [0]	= function (widget,mousebutton)
 			local pref = gJournalDialog_Pref
			pref.x,pref.y = gJournalDialog.rootwidget.gfx:GetPos()
			local left,top,w,h = gJournalDialog:GetLTWH()
			pref.dx,pref.dy = w,h
			if (mousebutton == 2) then widget.dialog:Close() end
			if (mousebutton == 1) then ToggleJournal_Small() end
		end,
 -- journalresize
 [1]	= function (widget,mousebutton) 
            if (mousebutton == 1) then
                widget.gfx:SetMaterial(widget.mat_pressed)
                gJournalResizeStartX,gJournalResizeStartY = GetMousePos()
                if (true) then
                    gui.bMouseBlocked = true
                    RegisterStepper(function ()
                        local x,y = GetMousePos()
                        local dx = 2.0*(x-gJournalResizeStartX)
                        --local dx = 0
                        gJournalDialog:ResizeDelta(dx,(y-gJournalResizeStartY))
                        gJournalResizeStartX,gJournalResizeStartY = x,y
                        JournalUpdateText()
                        
                        if (gKeyPressed[key_mouse1]) then
                            return false -- continue stepping
                        else
                            gui.bMouseBlocked = false
                            local left,top,w,h = gJournalDialog:GetLTWH()
                            local bx1,by1,bx2,by2 = JournalGetTextBorder()
                            local iw,ih = w-bx1-bx2	, h-by1-by2
							local pref = gJournalDialog_Pref
                            pref.dx,pref.dy = w,h
                            pref.x,pref.y = gJournalDialog.rootwidget.gfx:GetPos()
                            return true -- terminate
                        end
                    end)
                end 
            end -- if
        end,
 -- btn
 [2]	= function (widget,mousebutton) end,
 [3]	= function (widget,mousebutton) end,
 [4]	= function (widget,mousebutton) end,
 [5]	= function (widget,mousebutton) end,
}

kClientSideGump_Journal			= journalGump	-- a very simple message log in papyrus-scroll look

gJournalEntries = {}
gJournalExtendedEntries = {}
gJournalDialog = nil
gJournalDialog_Pref = {}
gJournalResizeStartX,gJournalResizeStartY = nil,nil
gJournalScrollStartX,gJournalScrollStartY = nil,nil
gJournalMaxIdx = nil
gJournalMaxVisIdx = nil
gJournalMinimized = false

local function RestoreLastState()
    -- restore last position if available
    local pref = gJournalDialog_Pref
    local dialog = gJournalDialog
    if (dialog and gJournalMinimized == false) then 
        dialog.rootwidget.gfx:SetPos((pref.x or 0),(pref.y or 0)) 

        --dialog:SetDimensions((pref.dx or dialog.resize_max_total_x),(pref.dy or dialog.resize_max_total_y))
        pref.dx = (pref.dx or dialog.resize_max_total_x) - dialog.rootwidget.gfx:GetWidth()
        pref.dy = (pref.dy or dialog.resize_max_total_y) - dialog.rootwidget.gfx:GetHeight()
        dialog:ResizeDelta(pref.dx,pref.dy)  -- 
        --dialog:ResizeMaximize()

        JournalUpdateText()
    end
end

local function CreateJournal_Small ()
	gJournalDialog = guimaker.MakeSortedDialog()
	local pref = gJournalDialog_Pref

	local dialog = gJournalDialog
	dialog.Close 		= function(dialog)
        	gJournalDialog:SetVisible(false)
        	gJournalDialog:Destroy()
        	gJournalDialog = nil
	end

	dialog.onMouseDown = function (widget,mousebutton)
			if (mousebutton == 2) then gJournalDialog:Close() end
			if (mousebutton == 1) then
				widget.dialog:BringToFront()
				gui.StartMoveDialog(widget.dialog.rootwidget)
            end
	end

	local root = dialog.rootwidget
	MakeBorderGumpPart( root, 2096, (pref.x or 0), (pref.y or 0))

	for k,widget in pairs(dialog.childs) do
            widget.mbIgnoreMouseOver = false
    end
end

-- ----------------------------------------------- End of local functions -----------------------------
function JournalGetTextBorder () return 40,80,40,50 end

function JournalUpdateText ()
	if (not gJournalDialog or not gJournalEntries) then return end
	local widget = gJournalDialog.maintext

	-- TODO: remove this hack here (its needed because of exception)
	if (widget) then
		local left,top,w,h = gJournalDialog:GetLTWH()
		local bx1,by1,bx2,by2 = JournalGetTextBorder()
		local iw,ih = w-bx1-bx2	, h-by1-by2
		-- max visible lines/chars
		local wraplen = math.floor(iw/7)
		local maxlines = math.max(1,math.floor(ih/gFontDefs["Gump"].size))
		-- final text
		local text = ""
		
		local prefix = "\t>> "
		local iNumLines = table.getn(gJournalEntries)
		
	    -- not used by now
		if iNumLines < 1 then 
			return 	
		elseif iNumLines < maxlines then 
			gJournalMaxIdx = iNumLines 
			gJournalMaxVisIdx = iNumLines
		end

		-- iterate over reverse of gJournalEntries
		-- thx to #lua on freenode :>
		local iter = function(t)
						local stack = {};
						for k,v in ipairs(t) do table.insert(stack, v); end
						return coroutine.wrap(function() local n = table.remove(stack); while n do coroutine.yield(n); n = table.remove(stack); end end)
					 end

		local lineidx = 1
		for jline in iter(gJournalEntries) do 
			local line = ""
			local linebuf = {}
			local t = true
			-- do the wordwrap
			for w in string.gfind(jline, "%S+") do
				local linelen = (string.len(line) + string.len(w) + 1)
				if (linelen <= wraplen) then
			   		line = line.." "..w
		       	else
		       		table.insert(linebuf,line)
		       		-- clear line/add ident prefix + last word
		       		line = prefix..w			
		     	end     	
	    	end
			table.insert(linebuf,line)		

			local linesperjentry = table.getn(linebuf)
			if (lineidx + linesperjentry) > maxlines then break end

			lineidx = lineidx + linesperjentry
		    text = table.concat(linebuf,"\n").."\n"..text.."\n"
		end	
		widget.gfx:SetText(text)
		widget:UpdateClip()
	end
end

function JournalAddText (name,message)
	local sys = "System"
	local mytext = message	
	-- strip "System:"
	local a,b = string.find(name, sys, 1, false)
	if not string.find(name, sys, 1, true) then 
		mytext = name.."> "..mytext
	end   	
	table.insert(gJournalEntries,mytext)
	
	-- add extendes journal entry for scripting
	local entry = {}
	entry.name = name
	entry.message = message
	entry.time = Client_GetTicks()
	entry.line = mytext
	table.insert(gJournalExtendedEntries,entry)
	
	JournalUpdateText()
end

-- produces a small journal scroll icon
function ToggleJournal_Small ()
	local pref = gJournalDialog_Pref
	if (gJournalDialog) then  
        pref.x, pref.y = gJournalDialog.rootwidget.gfx:GetPos()
		gJournalDialog:Close()
		
		-- create minimized journal button
		gJournalMinimized = true
		CreateJournal_Small()
	end
end

-- produces a big journal scroll
function ToggleJournal ()
	local pref = gJournalDialog_Pref
	if (gJournalDialog and (gJournalMinimized==false)) then
		-- store current position
		pref.x,pref.y = gJournalDialog.rootwidget.gfx:GetPos()
		ToggleJournal_Small()
        
	elseif ((gJournalDialog == nil) or (gJournalMinimized == true)) then
        if (gJournalDialog) then 
            gJournalDialog:Close() 
        end
        gJournalMinimized = false
        
        local dialog = GumpParser( journalGump, true )

        -- save journaldialog as global Journal
        gJournalDialog = dialog

        -- overwrite the Close function from gumpparser
        dialog.Close = function (dialog) 
            pref.x,pref.y = gJournalDialog.rootwidget.gfx:GetPos()
		    local left,top,w,h = gJournalDialog:GetLTWH()
		    pref.dx,pref.dy = w,h

        	gJournalDialog:SetVisible(false)
            gJournalDialog:Destroy() 
            gJournalDialog = nil             
        end

        -- overwrite the onMouseDown function from gumpparser
        dialog.onMouseDown = function (widget,mousebutton)
            if (mousebutton == 2) then widget.dialog:Close() end
            if (mousebutton == 1) then widget.dialog:BringToFront() gui.StartMoveDialog(widget.dialog.rootwidget) end
        end

        -- create text
        local parent = gJournalDialog.rootwidget
--        local col = {1,1,1,1}
        local bx1,by1,bx2,by2 = JournalGetTextBorder()
        gJournalDialog.maintext = guimaker.MakeText(parent,bx1,by1,"", gFontDefs["Journal"].size, gFontDefs["Journal"].col, gFontDefs["Journal"].name)
        table.insert(gJournalDialog.clippedWidgets,gJournalDialog.maintext)
        gJournalDialog.maintext.UpdateClip = function (widget) 
            local left,top,w,h = gJournalDialog:GetLTWH()
            local bx1,by1,bx2,by2 = JournalGetTextBorder()
            local iw,ih = w-bx1-bx2	, h-by1-by2
            widget.gfx:SetClip(widget.gfx:GetDerivedLeft(),widget.gfx:GetDerivedTop(),iw,ih) 
        end
        -- see also MakeClippedText,SetAutoWrap

        printdebug("gump",(pref.dx or "dx=nil ").." -dxy- "..(pref.dy or "dy=nil"))
        printdebug("gump",(pref.x or "x=nil ").." -xy- "..(pref.y or "y=nil"))
            
        -- resize limits
        dialog.resize_min_total_x,dialog.resize_min_total_y = 0,-66	 -- -20,-66
        dialog.resize_max_total_x,dialog.resize_max_total_y = 0, 120 --  60,175

        -- xml attributes to resize params
        for k,widget in pairs(dialog.childs) do
            widget.mbIgnoreMouseOver = false
            widget.bResizeNoScaleX = (widget.node and widget.node.attr.bResizeNoScaleX == "true")
            widget.bResizeNoScaleY = (widget.node and widget.node.attr.bResizeNoScaleY == "true")
        end
--[[
		-- TODO: WRONG !!!! gives exceptions
        -- scrollbutton
		local widget = dialog.controls["journal_scroll"]
		widget.onMouseDown 	= function (widget,mousebutton) 
            if (mousebutton == 1) then 
                widget.gfx:SetMaterial(widget.mat_pressed)
                gui.bMouseBlocked = true
                RegisterStepper(function ()
                    local left,top,w,h = gJournalDialog:GetLTWH()
                    local bx1,by1,bx2,by2 = JournalGetTextBorder()
                    local iw,ih = w-bx1-bx2	, h-by1-by2
                    
                    local a,b = widget.gfx:GetPos()
                    local x,y = GetMousePos()
                    local dy = (y-gJournalScrollStartY)
                    b = b+dy
                    
                    -- exit if mouseup or borders reached
                    if ((b < 74) or (b > ih+15) or (not gKeyPressed[key_mouse1])) then 
                        gui.bMouseBlocked = false
                        return true -- terminate
                    end
                    widget.gfx:SetPos(a,b)
                    gJournalScrollStartX,gJournalScrollStartY = x,y
                    
                    return false -- continue stepping
                end)
                JournalUpdateText()
            end -- if
		end -- function
]]--    
        JournalUpdateText()
    else
        gJournalDialog:Close()
    end -- if

    -- restore last posion and dimension if available
    RestoreLastState()

end	-- function

--[[
function RegisterJournalEntryType (name) _G["kEntryType_"..name] = name end

-- TODO : maybe  gEntryTypeHandler.Chat = function (type,arr) return {r,g,b},sprintf("",arr[1],arr[2]) end
RegisterJournalEntryType("Chat")
RegisterJournalEntryType("TextMessage")
RegisterJournalEntryType("ServerMessage")
RegisterJournalEntryType("PickUpItem")
RegisterJournalEntryType("DropItem")
RegisterJournalEntryType("EquipItem")
RegisterJournalEntryType("UnequipItem")
RegisterJournalEntryType("Trade")
RegisterJournalEntryType("DoubleClick")
RegisterJournalEntryType("Use")
RegisterJournalEntryType("Death")
RegisterJournalEntryType("WarMode")

function JournalAddEntry (entrytype,...)
	-- TODO : vararg params
end
]]--
