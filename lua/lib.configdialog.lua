--[[ ***** see Iris2 COPYING for license info ***** ]]--
--[[ \brief
        manages the ingame config dialog
]]--

function TestConfigDialog()
    Load_Font() -- iris specific
    Load_Hue() -- iris specific
    Load_Gump() -- iris specific
    OpenConfigDialog()
end

function OpenConfigDialog ()
	--~ print("mesadebug:OpenConfigDialog 1")
	ConfigDialog_Close()
	--~ print("mesadebug:OpenConfigDialog 2")

	--~ print("mesadebug:OpenConfigDialog 3")
    local texname,w,h,xoff,yoff = "simplebutton.png",80,80,0,0
    local u0,v0,w0,w1,w2,h0,h1,h2, tcx,tcy = 0,0, 4,8,4, 4,8,4, 32,32
    local gfxparam_white = MakeSpritePanelParam_BorderPartMatrix(GetPlainTextureGUIMat(texname),w,h,xoff,yoff, u0,v0,w0,w1,w2,h0,h1,h2, tcx,tcy, 1,1, false, false)
    
	--~ print("mesadebug:OpenConfigDialog 4")
    -- sience_window.png 64x64      w=16,24,24 h=16,16,32
    local texname,w,h,xoff,yoff = "sience_window.png",80,80,0,0
    local u0,v0,w0,w1,w2,h0,h1,h2, tcx,tcy = 0,0, 16,24,24, 16,16,32, 64,64
    local gfxparam_window = MakeSpritePanelParam_BorderPartMatrix(GetPlainTextureGUIMat(texname),w,h,xoff,yoff, u0,v0,w0,w1,w2,h0,h1,h2, tcx,tcy, 1,1, false, false)
    
	--~ print("mesadebug:OpenConfigDialog 5")
    -- sience_button.png 128x128 128x25 w=6,116,6 h=6,13,6  (only one highlight state?)
    local texname,w,h,xoff,yoff = "sience_button.png",80,80,0,0
    local u0,v0,w0,w1,w2,h0,h1,h2, tcx,tcy = 0,0, 6,116,6, 6,13,6, 128,128
    local gfxparam_border = MakeSpritePanelParam_BorderPartMatrix(GetPlainTextureGUIMat(texname),w,h,xoff,yoff, u0,v0,w0,w1,w2,h0,h1,h2, tcx,tcy, 1,1, false, false)
    
    
	--~ print("mesadebug:OpenConfigDialog 6")
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
    GuiThemeSetDefaultParam("List",{    gfxparam_init       = gfxparam_border,
                                        margin_left= b,
                                        margin_top= b,
                                        margin_right= b,
                                        margin_bottom= b,
                                    })
    GuiThemeSetDefaultParam("Window",{  gfxparam_init       = gfxparam_window,
                                        margin_left= b,
                                        margin_top= b,
                                        margin_right= b,
                                        margin_bottom= b,
                                    })
    GuiThemeSetDefaultParam("Pane",{    gfxparam_init       = gfxparam_white,
                                    })
    
	--~ print("mesadebug:OpenConfigDialog 7")
    
    -- bla
    local kConfigDialogW = 400
    local kConfigDialogH = 300
    local dialog = GetDesktopWidget():CreateChild("Window",{w=kConfigDialogW,h=kConfigDialogH})
	--~ print("mesadebug:OpenConfigDialog 8")
    gConfigDialog = dialog
    dialog:SetPos(200,100)
	--~ print("mesadebug:OpenConfigDialog 9")
    --~ local btn = dialog:CreateContentChild("Button",{x=10,y=10,label="testbutton"})
    --~ local txt = dialog:CreateContentChild("UOText",{bold=true,text="bla",x=10,y=50})
    local list      = dialog:CreateContentChild("List",{x=10,y=10,w=100,h=280})
    local pagelist  = dialog:CreateContentChild("PageList",{x=120,y=10})
    
	--~ print("mesadebug:OpenConfigDialog 10")
    
    function MyAddPage (name) 
        local pagenum = dialog.nextpagenum or 1
        dialog.nextpagenum = pagenum + 1
        list:AddWidget(CreateWidget("UOText",nil,{bold=true,text=name,on_select_by_list=function() pagelist:ShowPage(pagenum) end}))
        return pagelist:GetOrCreatePage(pagenum):CreateContentChild("VBox")
    end
    
	--~ print("mesadebug:OpenConfigDialog 11")
    ConfigDialogPage_Config(        MyAddPage("Config"))
    ConfigDialogPage_HotKey(        MyAddPage("HotKey"))
    ConfigDialogPage_Graphics(      MyAddPage("Graphics"))
    --~ ConfigDialogPage_Macro(         MyAddPage("Macro"))
    ConfigDialogPage_UOAM(          MyAddPage("UOAM"))
    ConfigDialogPage_PacketVideo(   MyAddPage("PacketVideo"))
	--~ print("mesadebug:OpenConfigDialog 16")
    --~ ConfigDialogPage_Misc(          MyAddPage("Misc"))
    
    
    --[[
    page1:AddWidget(CreateWidget("UOText",nil,{bold=true,text="page1"}))
    page1:AddWidget(CreateWidget("UOText",nil,{bold=true,text="page1 line2"}))
    page1:AddWidget(CreateWidget("UOText",nil,{bold=true,text="page1 line3"}))
    page2:AddWidget(CreateWidget("UOText",nil,{bold=true,text="page2"}))
    page3:AddWidget(CreateWidget("UOText",nil,{bold=true,text="page3"}))
    
    local mygroup = page3:AddWidget(CreateWidgetFromXMLString(nil,
        "<HBox><Button name='btn1' label='testbutton' /><UOText name='txt1' bold=1 text='blub'></HBox>"))
    local b = mygroup:FindChildByName("btn1") 
    function b:on_mouse_left_click () 
        mygroup:FindChildByName("txt1"):SetText("baaaaaaaaaaaaaaaaah"..math.random(1,100)) 
    end
    ]]--
    
    --~ local widget = CreateWidgetFromXMLString(nil,"<Window x=100 y=100 w=300 h=200>"..
                                                                --~ "<Button x=10 y=10 label='testbutton' />"..
                                                                --~ "</Window>")    

																
	--~ print("mesadebug:OpenConfigDialog 17")
    local alignbox  = dialog:CreateContentChild("AlignBox",{x=120,y=10,w=kConfigDialogW-120-10,h=kConfigDialogH-10-10})
	--~ print("mesadebug:OpenConfigDialog 18")
    local hbox      = alignbox:AddChild("HBox",{halign="right",valign="bottom",spacer=10})
    hbox:AddChild("Button",{label="OK",     on_button_click=function () ConfigDialog_Close() end})
    alignbox:UpdateLayout()
    
	--~ print("mesadebug:OpenConfigDialog 19")
    list:SetSelectedIndex(1)
	--~ print("mesadebug:OpenConfigDialog 20")
end

function ConfigDialog_Close () if (gConfigDialog) then HotKeys_SaveData() gConfigDialog:Destroy() gConfigDialog = nil end end


-- ***** ***** ***** ***** ***** xml


function ConfigDialog_ExecuteLoadedData    ()
	for k,v in pairs(gConfigDialogData.globals or {}) do _G[k] = v end
	
	if (gRazorConfigImportPath) then ImportRazorProfile(gRazorConfigImportPath) end
end
function ConfigDialog_LoadData    () gConfigDialogData =	SimpleXMLLoad(ConfigDialog_GetDataFilePath()) or {} ConfigDialog_ExecuteLoadedData() end
function ConfigDialog_SaveData    ()              			SimpleXMLSave(ConfigDialog_GetDataFilePath(),gConfigDialogData) end
function ConfigDialog_GetDataFilePath () return GetConfigDirPath().."config.xml" end


-- ***** ***** ***** ***** ***** pages


-- x,y : left-top/pos (-margin) of menu
--~ itemconstructor(itemdata) : returns string for item label  (or nil/false to skip)
--~ choicecallback(itemdata) : notify after an item was selected
function ConfigDialogShowMenu (x,y,itemlist,itemconstructor,choicecallback)
    local btnlist   = gRootWidget.tooltip:CreateChild("Window",{x=x,y=y,bCloseOnRightClick=true})
    local vbox      = btnlist:CreateContentChild("VBox")
    local bEmpty = true
    for k,itemdata in pairs(itemlist) do 
        local labeltext = itemconstructor(itemdata,k)
        if (labeltext) then 
            bEmpty = false
            vbox:AddChild("Button",{label=labeltext,on_button_click=function () btnlist:Destroy() choicecallback(itemdata) end})
        end
    end
    if (bEmpty) then btnlist:Destroy() return end
    btnlist:AutoSize()
end



function ConfigDialogPage_Macro(page)
    local group = page:AddWidget(CreateWidgetFromXMLString(nil,"<UOText bold=1 text='not yet implemented'>"))
    
    page:AddChild("Button",{label="Import Razor Hotkeys&Macros",on_button_click=function ()  
            ImportRazorProfileDialog()
        end})
end

function ConfigDialogPage_UOAM(page)
    local ew,eh = 200,24
    local row = page:CreateContentChild("HBox")
        row:AddWidget(CreateWidgetFromXMLString(nil,"<UOText bold=1 text='Name:'>"))
        row:AddChild("UOEditText",{width=ew,height=eh,text=gUOAMName or "username",name="name",hue=0,bHasBackPane=true})
        
    local row = page:CreateContentChild("HBox")
        row:AddWidget(CreateWidgetFromXMLString(nil,"<UOText bold=1 text='Pass:'>"))
        row:AddChild("UOEditText",{width=ew,height=eh,text=gUOAMPass or "password",name="pass",hue=0,bHasBackPane=true})
        
    local row = page:CreateContentChild("HBox")
        row:AddWidget(CreateWidgetFromXMLString(nil,"<UOText bold=1 text='Server:'>"))
        row:AddChild("UOEditText",{width=ew,height=eh,text=gUOAMServer or "uoam.host.com",name="server",hue=0,bHasBackPane=true})
        
    local row = page:CreateContentChild("HBox")
        row:AddWidget(CreateWidgetFromXMLString(nil,"<UOText bold=1 text='Port:'>"))
        row:AddChild("UOEditText",{width=ew,height=eh,text=gUOAMPort or "2000",name="port",hue=0,bHasBackPane=true})
    
    local mypage = page
    page:AddChild("Button",{label="Connect",on_button_click=function (self)  
            local name      = mypage:FindChildByName("name"):GetPlainText()
            local pass      = mypage:FindChildByName("pass"):GetPlainText()
            local server    = mypage:FindChildByName("server"):GetPlainText()
            local port      = mypage:FindChildByName("port"):GetPlainText()
            print("Config:UOAM:Connect",name,pass,server,port)
            UOAM_Start(name,pass,server,port)
        end})
        
    page:AddChild("Button",{label="Disconnect",on_button_click=function () UOAM_Stop() end})
	
	                
	for name,pos in pairs(UOAM_GetOtherPositions()) do 
        page:AddChild("UOText",{bold=1,text=tostring(name).." : "..tostring(pos and pos.facetname)})
	end
end

function ConfigDialogPage_PacketVideo(page)
    page:AddChild("Button",{label="Play Iris PacketVideo (*.ipv)",on_button_click=function ()  
            if (PacketVideo_Load(FileOpenDialog(gPacketVideoFileName_folderpath,"*.ipv","select iris packetvideo"))) then PacketVideo_Playback() end
        end})
    page:AddChild("Button",{label="Play Razor PacketVideo (*.rpv)",on_button_click=function ()  
            if (PacketVideo_LoadRarzorPV(FileOpenDialog(".","*.rpv","select razor packetvideo"))) then PacketVideo_Playback() end
        end})
    local tstart,tstop = "Start Recording","Stop Recording"
    page:AddChild("Button",{label=gPacketVideoRecording and tstop or tstart,on_button_click=function (self)  
            PacketVideo_Recording_Toggle() self:SetText(gPacketVideoRecording and tstop or tstart)
        end})
    page:AddWidget(CreateWidgetFromXMLString(nil,"<UOText bold=1 text='will be saved as .ipv files in iris/videos/'>"))
end

function ConfigDialogPage_Misc(page)
    local group = page:AddWidget(CreateWidgetFromXMLString(nil,"<UOText bold=1 text='not yet implemented'>"))
end


kGumpID_checkbox_normal = 210 -- from moongate menu
kGumpID_checkbox_pressed = 211

function ConfigDialog_SetGlobalVal (name,val)
	print("ConfigDialog_SetGlobalVal",name,val)
	_G[name] = val
	gConfigDialogData.globals = gConfigDialogData.globals or {}
	gConfigDialogData.globals[name] = val
	ConfigDialog_SaveData()
end

function ConfigDialogPage_Graphics(page)
	function MyAddConfig_GlobalEnum (label,globalname,valuelist,fun) 
		local curVal = _G[globalname]
		local myrow		= page:AddChild("HBox",{valign="bottom",spacer=3})
	
		function MyValueText (val) 
			val = tostring(val) 
			local maxlen = 12
			if (#val <= maxlen) then return val end
			return string.sub(val,1,maxlen-3)..".." 
		end
		myrow:AddChild("Button",{label=MyValueText(curVal),w=120,h=12,on_button_click=function (widget)  
			local x,y = widget:GetDerivedLeftTop()
            ConfigDialogShowMenu(x,y,valuelist,
                function (value) return value end,
                function (newval) 
					widget:SetText(MyValueText(newval))
					ConfigDialog_SetGlobalVal(globalname,newval)
                end)
			end})
		myrow:AddWidget(CreateWidgetFromXMLString(nil,"<UOText bold=1 text='"..tostring(label).."'>"))
			
	end
	function MyAddConfig_GlobalBool (label,globalname,fun) 
		local bCurVal = _G[globalname]
		local myrow		= page:AddChild("HBox",{valign="bottom",spacer=3})
		local checkbox	= myrow:AddChild("UOCheckBox",{status=bCurVal and 1 or 0,
									gump_id_normal=kGumpID_checkbox_normal,
									gump_id_pressed=kGumpID_checkbox_pressed,})
		myrow:AddWidget(CreateWidgetFromXMLString(nil,"<UOText bold=1 text='"..label.."'>"))
		checkbox.on_change = function (self,bNewState) 
			ConfigDialog_SetGlobalVal(globalname,bNewState)
			if (fun) then fun(bNewState) end
		end
		--~ print("##############\n### MyAddConfig_Bool=",name,bNewState)
	end
	
	MyAddConfig_GlobalBool("Fullscreen","gGfxConfig_Fullscreen",function (bNewState) GfxConfig_SetFullScreen(bNewState) end)
	MyAddConfig_GlobalEnum("Resolution","gGfxConfig_Resolution",GfxConfig_ListPossibleResolutions())
	MyAddConfig_GlobalEnum("RenderSystem","gGfxConfig_RenderSystem",GfxConfig_ListPossibleRenderSystems())
	
	MyAddConfig_GlobalEnum("AntiAliasing","gGfxConfig_AntiAliasing",{"0","2","4"})
	
	local gfx_profile_list = {"none", "ultralow", "low", "med", "high", "ultrahigh"}
	MyAddConfig_GlobalEnum("Quality","gGraphicProfile",gfx_profile_list)
	
	MyAddConfig_GlobalBool("(3D) Bloom Shader","gEnableBloomShader")
	MyAddConfig_GlobalBool("(3D) Water Shader","gUseWaterShader")
	MyAddConfig_GlobalBool("(3D) Dynamic Sky","gUseCaelumSkysystem")
	MyAddConfig_GlobalBool("(3D) animated Characters","gGrannyAnimEnabled")
	MyAddConfig_GlobalBool("(3D) distance Fog","gUseDistanceFog")
	MyAddConfig_GlobalBool("(3D) static 2D fallback","gUseStaticFallbacks")
	
	page:AddWidget(CreateWidgetFromXMLString(nil,"<UOText bold=1 text='".."changes require restart".."'>"))
end


function ConfigDialogPage_Config(page)
    --~ local group = page:AddWidget(CreateWidgetFromXMLString(nil,"<UOText bold=1 text='not yet implemented'>"))
	
	
	function MyAddConfig_GlobalBool (label,globalname,fun) 
		local bCurVal = _G[globalname]
		local myrow		= page:AddChild("HBox",{valign="bottom",spacer=3})
		local checkbox	= myrow:AddChild("UOCheckBox",{status=bCurVal and 1 or 0,
									gump_id_normal=kGumpID_checkbox_normal,
									gump_id_pressed=kGumpID_checkbox_pressed,})
		myrow:AddWidget(CreateWidgetFromXMLString(nil,"<UOText bold=1 text='"..label.."'>"))
		checkbox.on_change = function (self,bNewState) 
			ConfigDialog_SetGlobalVal(globalname,bNewState)
			if (fun) then fun(bNewState) end
		end
		--~ print("##############\n### MyAddConfig_Bool=",name,bNewState)
	end
	
	MyAddConfig_GlobalBool("music",			"gUseMusic",function (bNewState) if (not bNewState) then SoundStopMusic() end end)
	MyAddConfig_GlobalBool("sound effects",	"gUseEffect",function (bNewState) if (not bNewState) then FlushSoundEffects() end end)
	
	MyAddConfig_GlobalBool("always run","gAlwaysRun")
	MyAddConfig_GlobalBool("* hide system cursor (needs grab also)","gbHideMouse")
	MyAddConfig_GlobalBool("* grab system cursor","gbGrabInput")
	MyAddConfig_GlobalBool("preload 3D-Data","gPreloadStaticMesh")
	
	
	MyAddConfig_GlobalBool("hide memory infos","gHideMemoryUsage")
	
	if (1==1) then
		function MyValueText (val) 
			val = tostring(val) 
			local maxlen = 20
			if (#val <= maxlen) then return val end
			return string.sub(val,1,maxlen-3)..".." 
		end
		local myrow		= page:AddChild("HBox",{valign="bottom",spacer=3})
		local label = gRazorConfigImportPath or ""
		myrow:AddWidget(CreateWidgetFromXMLString(nil,"<UOText bold=1 text='".."RazorConfig".."'>"))
		myrow:AddChild("Button",{label=MyValueText(label),w=180,h=12,on_button_click=function (widget)  
				local newval = FileOpenDialog_RazorProfile()
				ConfigDialog_SetGlobalVal("gRazorConfigImportPath",newval)
				widget:SetText(MyValueText(gRazorConfigImportPath or ""))
				if (gRazorConfigImportPath) then ImportRazorProfile(gRazorConfigImportPath) end
			end})
	end
	
	--~ automatically open doors 
	--~ fps bar
	
	
	page:AddWidget(CreateWidgetFromXMLString(nil,"<UOText bold=1 text='".."*:requires restart".."'>"))
end

