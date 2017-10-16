-- handles the chatline, a area at the bottom of the screen where text can be input
gChatLineHistoryIndex = 1
gLastChatLine = ""
gChatLineHistory = {}

-- oldname : HistoryUpDown
function ChatLine_HistoryUpDown(x)
	if (gChatLine) then 
		if (gChatLine.edittext == gActiveEditText) then
			local line = gChatLineHistory[gChatLineHistoryIndex]
			if (line ~= nil) then
				gChatLine.edittext:SetText(line)
			end
			gChatLineHistoryIndex = gChatLineHistoryIndex + x
			local line = gChatLineHistory[gChatLineHistoryIndex]
			if (line == nil) then
				gChatLineHistoryIndex = gChatLineHistoryIndex - x
			end
		end
	end
end

-- oldname : RepeatLastChatLine
-- resend the last line, if its not empty
function ChatLine_RepeatLast ()
	if (gLastChatLine ~= "") then 
		SendChat(gLastChatLine)
	end
end

-- oldname : ToggleChatLineActive
function ChatLine_ToggleActive ()
	if (gChatLine) then 
		gChatLine.edittext:Activate()
		gChatLineHistoryIndex = 1
	end
end

-- to manually set the last line, for repeat
function CharLine_SetLast	(line)
	gLastChatLine = line
end

-- called on window resize
RegisterListener("Hook_Window_Resize",function () ChatLine_Reposition() end)
function ChatLine_Reposition ()
	if (not gChatLine) then return end
	local vw,vh = GetViewportSize()
	local h = 18
	local yoff = 12
	local x,y,w,h = 0,vh-h-yoff, vw,h
	
	local widget = gChatLine.edittext
	widget.gfx:SetPos(x,y)
	widget.gfx:SetDimensions(w,h)
end



-- oldname : ChatLine
function ChatLine_Init()
	if (gNoRender) then return end
	-- text-input-line at the bottom of screen
	local vw,vh = GetViewportSize()
	local h = 18
	local yoff = 12
	local x,y,w,h = 0,vh-h-yoff, vw,h
	
	gChatLine = guimaker.MyCreateDialog()
	gChatLine.edittext = CreatePlainEditText(gChatLine,x,y,w,h,{0.0,0.0,0.0,1.0})
	gChatLine.edittext.onReturn = function (widget) 
		local curtext = widget:GetText()
		if (curtext ~= "") then 
			--				Send_Speech(curtext)
			--	TODO : don't know where send_speech is used.
				
			-- store curret line for command repeat
			gLastChatLine = curtext
				
			SendChat(curtext)
			table.insert(gChatLineHistory,1,curtext)
			widget:SetText("")
		end
		widget:Deactivate()
	end
end



