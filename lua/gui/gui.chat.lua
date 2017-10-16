cChatTabs = {}
cChatTabs.kOffset_Bottom	= 30
cChatTabs.kOffset_Left		= 30
cChatTabs.kOffset_Height	= 200
cChatTabs.kMaxLines			= 5000
cChatTabs.scroll			= 0

cChatTabs.channels = {
	{name="General",	filter=false,														},
	{name="Chat",		filter={"<.+>"}, class_ok={"uoam","party","guild","ally"}, bNormalChat=true	},
	{name="Party",		filter={"<Party>"}, class_ok={"uoam","party"}						},
	{name="Ally",		filter={"<Alliance>","<Guild>"}, class_ok={"guild","ally"}			},
	{name="Trades",		filter={"<Trades>"},												},
}
--~ <Public>,<Trades>,<Guild>,<Alliance>,<Newbies>,<PvP>
--~ system = "System:",


function GuiAddChatLine	(...) cChatTabs:AddLine(...) end
function GuiInitChat	()				cChatTabs:Init() end
function TestChatTabs () 
    Load_Font() -- iris specific
    Load_Hue() -- iris specific
	GuiInitChat() 
	local c = {1,1,1,1}
	--~ for i=0,15 do GuiAddChatLine("test"..i,c) end
	--~ for i=0,15 do print("linefromend",i,cChatTabs:ChannelGetLineFromEnd(cChatTabs.channels[1],i)) end
	
	GuiAddChatLine("<Alliance> Ghongolas: nabend",c)
	GuiAddChatLine("<Alliance> Ghongolas: blub",c)
	GuiAddChatLine("<Alliance> Ghongolas: boing1",c)
	GuiAddChatLine("<Alliance> Ghongolas: boing12",c)
	GuiAddChatLine("<Alliance> Ghongolas: boing13",c)
	GuiAddChatLine("you cannot cast this spell, it is too imber",c)
	GuiAddChatLine("you cannot cast this spell, it is too imber",c)
	GuiAddChatLine("you cannot cast this spell, it is too imber",c)
	GuiAddChatLine("you cannot cast this spell, it is too imber",c)
	GuiAddChatLine("you cannot cast this spell, it is too imber",c)
	GuiAddChatLine("you cannot cast this spell, it is too imber",c)
	GuiAddChatLine("you cannot cast this spell, it is too imber",c)
	GuiAddChatLine("<Public> Ghongolas: boing13",c)
	GuiAddChatLine("<Alliance> Ghongolas: boing14",c)
	GuiAddChatLine("<Alliance> Ghongolas: boing15",c)
	GuiAddChatLine("<Trades> Ghongolas: selling wood",c)
	GuiAddChatLine("<Trades> Ghongolas: selling iron",c)
	GuiAddChatLine("<Trades> Ghongolas: selling cloth",c)
	GuiAddChatLine("<Alliance> Ghongolas: boing16",c)
	GuiAddChatLine("you stumble over some wood",c)
	GuiAddChatLine("you stumble over some wood",c)
	GuiAddChatLine("you stumble over some wood",c)
	GuiAddChatLine("you stumble over some wood",c)
	GuiAddChatLine("you stumble over some wood",c)
	GuiAddChatLine("<Alliance> Ghongolas: boing17",c)
	GuiAddChatLine("some newbie is attacking you",c)
	GuiAddChatLine("you got 3 points for killing some newbie",c)
end


function cChatTabs:InitChannels()
	if (self.bChannelsInitialized) then return end
	self.bChannelsInitialized = true
	for k,channel in pairs(self.channels) do self:InitChannel(channel) end
end
function cChatTabs:InitChannel(channel)
	channel.lines_ringbuffer = {}
	channel.lines_ringbuffer_nextloc = 0
	channel.numberoflines = 0
end
function cChatTabs:ChannelGetLineFromEnd (channel,i)
	if (not channel) then return end
	if (i < 0 or i >= min(self.kMaxLines,channel.numberoflines or 0)) then return end
	return channel.lines_ringbuffer[ math.mod(channel.lines_ringbuffer_nextloc - i - 1 + 2*self.kMaxLines,self.kMaxLines) ]
end
function cChatTabs:AddLineToChannel(channel,line,color)
	if (not channel) then return end
	self:InitChannels()
	-- print("cChatTabs:AddLineToChannel",channel.name,channel.lines_ringbuffer_nextloc,line)
	channel.lines_ringbuffer[channel.lines_ringbuffer_nextloc] = line
	channel.lines_ringbuffer_nextloc = math.mod(channel.lines_ringbuffer_nextloc + 1,self.kMaxLines)
	channel.numberoflines = min(channel.numberoflines + 1,self.kMaxLines)
	if (self.selected_channel == channel) then self:UpdateTextArea() end
end
function cChatTabs:UpdateTextArea ()
	if (not self.tabpane) then return end
	local channel = self.selected_channel
	local text = ""
	for i = 8,0,-1 do 
		local line = self:ChannelGetLineFromEnd(channel,i+self.scroll) or ""
		text = text .. line .. "\n"
	end
	self.tabpane_textarea_text:SetText(text)
end
function cChatTabs:Scroll(delta)
	self.scroll = max(0,min(self.scroll+delta,self.kMaxLines)) -- upper bound should be self.kMaxLines - lines_per_view or so 
	self:UpdateTextArea()
end
function cChatTabs:ShowChannel(channel)
	if (not channel) then return end
	self.scroll = 0
	self.selected_channel = channel
	self:UpdateTextArea()
end

function GuiChatNormal_CustomRejectFilter (line,color,src,name,serial,clilocid) end -- override and return true if text should not be in chat
function cChatTabs:AddLine (line,color,src,name,serial,clilocid) -- src:uoam,party,normal,system,emote,spell,guild,ally,prompt
	--~ print("######AddLine",line,color,src,name,serial,clilocid)
	local line2 = string.gsub(line,"^System: ","")
	for k2,channel in pairs(self.channels) do 
		local bMatch = false
		if (not channel.filter) then bMatch = true end
		if (channel.class_ok) then for k,v in pairs(channel.class_ok) do if (src == v) then bMatch = true break end end end
		if (channel.filter) then for k,v in pairs(channel.filter) do if (string.find(line2 ,"^"..v)) then bMatch = true break end end end
		if (channel.bNormalChat and 
			src == "normal" and 
			name ~= "script" and 
			name ~= "System" and 
			serial ~= 0xFFFFFFFF and 
			serial ~= 0 and 
			clilocid == nil and 
			(not GuiChatNormal_CustomRejectFilter(line,color,src,name,serial,clilocid))) then bMatch = true end
		if (bMatch) then self:AddLineToChannel(channel,line2,color) end
	end
	--~ print("cChatTabs:AddLine",SmartDump(color)) --~ cChatTabs:AddLine       {[1]=0.774194,[2]=0.774194,[3]=0.774194,[4]=1,}
	--~ if gGuiChatTabpane and (not gDisableChatTabPane) then
		--~ GuiChatDistributeLineToChannels(line)
	--~ end
	
	if (src == "skillupdate") then print(line) end
	-- TODO : temporary fix, replace this with a split by newline and add individual lines
	AddSingleFadeLine(string.gsub(line, "\n", ""),color)
end


function cChatTabs:CreateTabPane	()
    local texname,w,h,xoff,yoff = "simplebutton.png",80,80,0,0
    local u0,v0,w0,w1,w2,h0,h1,h2, tcx,tcy = 0,0, 4,8,4, 4,8,4, 32,32
    local gfxparam_white = MakeSpritePanelParam_BorderPartMatrix(GetPlainTextureGUIMat(texname),w,h,xoff,yoff, u0,v0,w0,w1,w2,h0,h1,h2, tcx,tcy, 1,1, false, false)
    
    -- sience_window.png 64x64      w=16,24,24 h=16,16,32
    local texname,w,h,xoff,yoff = "sience_window.png",80,80,0,0
    local u0,v0,w0,w1,w2,h0,h1,h2, tcx,tcy = 0,0, 16,24,24, 16,16,32, 64,64
    local gfxparam_window = MakeSpritePanelParam_BorderPartMatrix(GetPlainTextureGUIMat(texname),w,h,xoff,yoff, u0,v0,w0,w1,w2,h0,h1,h2, tcx,tcy, 1,1, false, false)
    
    local b = 3
	
    GuiThemeSetDefaultParam("Button",{  gfxparam_init       = gfxparam_white,
                                        gfxparam_in_down    = MakeSpritePanelParam_Mod_TexTransform(0.0,0.5,1,1,0),
                                        gfxparam_in_up      = MakeSpritePanelParam_Mod_TexTransform(0.5,0.0,1,1,0),
                                        gfxparam_out_down   = MakeSpritePanelParam_Mod_TexTransform(0.0,0.0,1,1,0),
                                        gfxparam_out_up     = MakeSpritePanelParam_Mod_TexTransform(0.0,0.0,1,1,0),
                                        margin_left= b,
                                        margin_top= b,
                                        margin_right= b,
                                        margin_bottom= b,
                                        font=CreateFont_UO(gUniFontLoaderList[0]),
                                        textcol={r=0,g=0,b=0},
                                    })
    GuiThemeSetDefaultParam("Window",{  gfxparam_init       = gfxparam_window,
                                        margin_left= b,
                                        margin_top= b,
                                        margin_right= b,
                                        margin_bottom= b,
                                    })
	
	
	self.tabpane 			= GetDesktopWidget():CreateChild("VBox")
	self.tabpane.GetDialog = function (self) return self end
	local yoff = 20
	self.tabpane_textarea	= self.tabpane:CreateChild("Window",{x=0,y=yoff,w=100,h=self.kOffset_Height-yoff,bUnmovable=true})
	self.tabpane_buttons	= self.tabpane:CreateChild("HBox",{x=8,y=0})
	
	self.tabpane_textarea_text = self.tabpane_textarea:CreateContentChild("UOText",{x=6,y=8,default_black=true})
	
	for k,channel in pairs(self.channels) do
		self.tabpane_buttons:AddChild("Button",{label=channel.name,h=16, on_button_click=function () self:ShowChannel(channel) end})
	end
	self.tabpane_button_scrollup	= self.tabpane_textarea:CreateContentChild("Button",{label="/\\", on_button_click=function () self:Scroll( 1) end})
	self.tabpane_button_scrolldown	= self.tabpane_textarea:CreateContentChild("Button",{label="\\/", on_button_click=function () self:Scroll(-1) end})
	self:RepositionChatPane()
	self:ShowChannel(self.channels[1]) -- calls self:UpdateTextArea()
end
	
function cChatTabs:RepositionChatPane	()
	if (not self.tabpane) then return end
	local vw,vh = GetViewportSize()
	self.tabpane_textarea:SpritePanel_Resize(vw-self.kOffset_Left,self.kOffset_Height)
	local w,h = self.tabpane:GetSize()
	local x,y = self.kOffset_Left,vh-self.kOffset_Bottom-h
	self.tabpane:SetPos(x,y)
	self.tabpane_button_scrollup:SetPos(	vw-self.kOffset_Left-40,10)
	self.tabpane_button_scrolldown:SetPos(	vw-self.kOffset_Left-40,self.kOffset_Height-28)
end

function cChatTabs:ToggleChatPane	()
	if (self.tabpane) then self.tabpane:Destroy() self.tabpane = nil else self:CreateTabPane() end
end

RegisterListener("Hook_Window_Resize",function () cChatTabs:NotifyWindowResize() end)
function cChatTabs:NotifyWindowResize	()
	self:UpdateIcon()
	self:RepositionChatPane()
end

function cChatTabs:UpdateIcon	()
	if (self.icon) then self.icon:Destroy() end
	local vw,vh = GetViewportSize()
	local x,y = 4,vh-self.kOffset_Bottom-20
	self.icon = GetDesktopWidget():CreateChild("Image",{gfxparam_init=MakeSpritePanelParam_SingleSprite(GetPlainTextureGUIMat("tabbed.png"),
											20,20, 0,0, 61,2, 20,20, 128,128)})
	self.icon:SetPos(x,y)	
	self.icon.on_button_click = function() cChatTabs:ToggleChatPane() end
end

function cChatTabs:Init()
	if (gNoRender) then return end
	self:InitChannels()
	self:UpdateIcon()
end


RegisterListener("keydown",function (key,char,bConsumed)
	if (GetDialogUnderMouse() == cChatTabs.tabpane or GetDialogUnderMouse() == cChatTabs.tabpane_textarea) then 
		if (key == key_wheelup) then	cChatTabs:Scroll(1) end
		if (key == key_wheeldown) then	cChatTabs:Scroll(-1) end
	end
end)
