-- handles the chatline, a area at the bottom of the screen where text can be input
gIrisChatLineHistoryIndex = 1
gIrisLastChatLine_plain = ""
gIrisLastChatLine_unicode = {}
gIrisChatLineHistory = {}
-- cloned from lugre/lib.chatline.lua and upgraded to new guisystem to support unicode

function TestIrisChatLine () 
    Load_Font() -- iris specific
    Load_Hue() -- iris specific
	IrisChatLine_Init() 
end

-- oldname : HistoryUpDown
function IrisChatLine_HistoryUpDown(x)
	if (gIrisChatLine) then 
		if (IsChatLineActive()) then
			local line = gIrisChatLineHistory[gIrisChatLineHistoryIndex]
			if (line ~= nil) then
				gIrisChatLine.edittext:SetText(CopyArray(line))
			end
			gIrisChatLineHistoryIndex = gIrisChatLineHistoryIndex + x
			local line = gIrisChatLineHistory[gIrisChatLineHistoryIndex]
			if (line == nil) then
				gIrisChatLineHistoryIndex = gIrisChatLineHistoryIndex - x
			end
		end
	end
end

-- oldname : RepeatLastChatLine
-- resend the last line, if its not empty
function IrisChatLine_RepeatLast ()
	if (gIrisLastChatLine_plain ~= "") then 
		SendChat(gIrisLastChatLine_plain,gIrisLastChatLine_unicode)
	end
end

-- oldname : ToggleChatLineActive
function IrisChatLine_ToggleActive ()
	print("IrisChatLine_ToggleActive")
	if (gIrisChatLine) then 
		gIrisChatLine.edittext:SetFocus()
		gIrisChatLineHistoryIndex = 1
	end
end

function IsChatLineActive () return gIrisChatLine and GetFocusWidget() == gIrisChatLine.edittext end 

-- to manually set the last line, for repeat
function IrisCharLine_SetLast	(line)
	gIrisLastChatLine_plain = line
	gIrisLastChatLine_unicode = false -- TODO : create unicode array from plaintext line ??
end

-- called on window resize
RegisterListener("Hook_Window_Resize",function () IrisChatLine_Reposition() end)
function IrisChatLine_Reposition ()
	if (not gIrisChatLine) then return end
	local vw,vh = GetViewportSize()
	local h = 18
	local yoff = 12
	local x,y,w,h = 0,vh-h-yoff, vw,h
	
	local widget = gIrisChatLine
	widget:SetPos(x,y)
	widget:SpritePanel_Resize(w,h)
end



-- oldname : ChatLine
function IrisChatLine_Init()
	if (gNoRender) then return end
	-- text-input-line at the bottom of screen
	local vw,vh = GetViewportSize()
	local h = 18
	local yoff = 12
	local x,y,w,h = 0,vh-h-yoff, vw,h
	
    local texname,w,h,xoff,yoff = "simplebutton.png",80,80,0,0
    local u0,v0,w0,w1,w2,h0,h1,h2, tcx,tcy = 0,0, 4,8,4, 4,8,4, 32,32
    local gfxparam_white = MakeSpritePanelParam_BorderPartMatrix(GetPlainTextureGUIMat(texname),w,h,xoff,yoff, u0,v0,w0,w1,w2,h0,h1,h2, tcx,tcy, 1,1, false, false)
    
    local b = 3
    GuiThemeSetDefaultParam("Window",{  gfxparam_init       = gfxparam_white,
                                        margin_left= b,
                                        margin_top= b,
                                        margin_right= b,
                                        margin_bottom= b,
                                    })
	
	gIrisChatLine = GetDesktopWidget():CreateChild("Window",{x=x,y=y,w=w,h=h,bUnmovable=true})
	function gIrisChatLine:on_mouse_left_down		() self:BringToFront() IrisChatLine_ToggleActive() end
	gIrisChatLine.edittext = gIrisChatLine:CreateContentChild("UOEditText",{x=2,y=0,width=800,height=20,text={},hue=0})
	
	local gfxparam_normal	= MakeSpritePanelParam_Mod_TexTransform(0.0,0.0,1,1,0)
	local gfxparam_high		= MakeSpritePanelParam_Mod_TexTransform(0.5,0.0,1,1,0)
	
	gIrisChatLine.edittext.on_focus_lost = function (self) gIrisChatLine.spritepanel:Update(gfxparam_normal) end
	gIrisChatLine.edittext.on_focus_gain = function (self) gIrisChatLine.spritepanel:Update(gfxparam_high) end 
	gIrisChatLine.edittext.on_return = function (self) 
		local text_plain = self:GetPlainText()
		local text_unicode = self:GetText()
		if (text_plain ~= "") then 
			--				Send_Speech(curtext)
			--	TODO : don't know where send_speech is used.
				
			-- store curret line for command repeat
			gIrisLastChatLine_plain = text_plain
			gIrisLastChatLine_unicode = text_unicode
				
			SendChat(text_plain,text_unicode)
			table.insert(gIrisChatLineHistory,1,text_unicode)
			self:SetText({})
		end
		self:RemoveFocus()
	end
	--~ for c=10,20 do gIrisChatLine.edittext:AppendChar(c) end
end



