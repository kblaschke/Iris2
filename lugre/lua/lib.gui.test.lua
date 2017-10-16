
--~ kGUITest_BorderTestTex = "scroll.png" 
--~ kGUITest_BorderTestTex = "guibordertest.png"
kGUITest_BorderTestTex = "simplebutton.png"
gLoremIpsum = "Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Vestibulum vehicula, diam placerat pellentesque viverra, ligula enim euismod ipsum, ut imperdiet justo dui vitae eros. Proin ut metus ac metus dapibus egestas. Mauris molestie aliquet turpis. Maecenas bibendum orci condimentum turpis. Integer faucibus lobortis tellus. Phasellus sed velit. Vivamus rhoncus. Etiam arcu mauris, congue eget, dapibus sit amet, pellentesque eget, velit. In mollis est sit amet risus. Integer ac tellus quis est pretium ultrices. Maecenas ac leo. Fusce bibendum volutpat enim. Nunc ullamcorper. Suspendisse nec magna ut urna convallis commodo. Sed odio libero, pellentesque sit amet, tempor sed, mattis eget, sapien. Ut sed dolor in pede lacinia porttitor. Ut rhoncus massa at lacus. Ut ligula. Donec a metus sit amet nisi sollicitudin mattis. Nulla odio magna, scelerisque at, semper quis, luctus in, odio."


-- a mini mainloop, this function doesn't exit
function GUITest ()
	Client_RenderOneFrame() -- first frame rendered with ogre, needed for init of viewport size
	GetMainViewport():SetBackCol(0.5,0.5,0.5)
	
	--~ print("fileopen",FileOpenDialog(".","*.mul","bla"))

	RadeonBugTestInit("a")
	--~ TestChatTabs()
	--~ TestIrisChatLine()
	--~ TestConfigDialog()
	--~ TestMapDialog()
	--~ UOBookTest()
	--~ GUITest_XML()
	--~ GUITest_SpriteList_Simple()
	--~ GUITest_SpritePanel_Simple()
	--~ GUITest_SpritePanel_Border()
	--~ GUITest_Widget_Text()
	--~ GUITest_Widget_Button()
	--~ GUITest_Widget_EditText()
	--~ GUITest_Widget_TabPane()
	--~ GUITest_Widget_ScrollBar()
	--~ GUITest_Widget_ScrollPane()
	--~ GUITest_Widget_Menu()
	--~ GUITest_Widget_EditText()
	--~ GUITest_Widget_Layout()
	
	GUITest_MainLoop()
	os.exit(0)
end


function RadeonBugTest ()
	

	local bAutoCreateWindow = false
	if (not InitOgre("Iris2",gOgrePluginPathOverride or lugre_detect_ogre_plugin_path(),gBinPath,bAutoCreateWindow)) then os.exit(0) end
	if (OgreCreateWindow and (not bAutoCreateWindow)) then -- new startup procedure with separate window creation to allow gfx-config
		GfxConfig_Apply()
		GfxConfig_PreWindowCreate()
		if (not OgreCreateWindow(false)) then os.exit(0) end
	end
	CollectOgreResLocs()
	GfxConfig_PostWindowCreate()
	print("initializing ogre done2")
	SetCursorBaseOffset(0,0)

	Client_RenderOneFrame() -- first frame rendered with ogre, needed for init of viewport size
	GetMainViewport():SetBackCol(0.5,0.5,0.5)
	
	RadeonBugTestInit(variant)
	
	GUITest_MainLoop()
	os.exit(0)
end

function RadeonBugTestInit ()
	local variant	= gCommandLineArguments[(gCommandLineSwitches["-radeonbug"] or 0)+1] or "a"
	local param		= gCommandLineArguments[(gCommandLineSwitches["-radeonbug"] or 0)+2] or "/path/to/unifont.mul"
	print("#########################################")
	print("#### RadeonBugTestInit variant=",variant)
	if (variant == "a") then
		gUOPath = param
		Load_Font()
		print("a:textname",gUniFontLastTextureAtlas,gUniFontLastTextureAtlas and gUniFontLastTextureAtlas.texname)
		print("load1") CreateFont_UO(gUniFontLoaderList[0])	
		print("load2") CreateFont_UO(gUniFontLoaderList[0])	
	elseif (variant == "b") then 
        gUniFontLoaderList[0] = CreateUniFontLoaderIfFileExists(param) -- unifont.mul
		print("b:textname",gUniFontLastTextureAtlas,gUniFontLastTextureAtlas and gUniFontLastTextureAtlas.texname)
		print("load1") CreateFont_UO(gUniFontLoaderList[0])	
		print("load2") CreateFont_UO(gUniFontLoaderList[0])	
	elseif (variant == "c") then 
		local w = 512
		local atlas = CreateTexAtlas(w,w)
		atlas.texname = atlas:MakeTexture() -- generate new texture
		print("load1") atlas:LoadToTexture(atlas.texname) -- update existing texture
		print("load2") atlas:LoadToTexture(atlas.texname) -- update existing texture
	elseif (variant == "d") then 
		local w = 512
		local atlas = CreateTexAtlas(w,w)
		print("add1") local bSuccess,l,r,t,b =  atlas:AddImage(LoadImageFromFile(gMainWorkingDir.."/data/base/art_fallback.png"))
		print("add2") local bSuccess,l,r,t,b =  atlas:AddImage(LoadImageFromFile(gMainWorkingDir.."/data/base/art_fallback.png"))
		print("add3") local bSuccess,l,r,t,b =  atlas:AddImage(LoadImageFromFile(gMainWorkingDir.."/data/base/art_fallback.png"))
		print("add4") local bSuccess,l,r,t,b =  atlas:AddImage(LoadImageFromFile(gMainWorkingDir.."/data/base/art_fallback.png"))
		atlas.texname = atlas:MakeTexture() -- generate new texture
		print("load1") atlas:LoadToTexture(atlas.texname) -- update existing texture
		print("load2") atlas:LoadToTexture(atlas.texname) -- update existing texture
	end
	print("starting mainloop")
end

function GUITest_MainLoop ()
	local gLastFrameTime = 0
	local kMaxFPS = 20
	local kTicksBetweenFrames = 1000 / kMaxFPS
	local kMinFrameWait = 10
	-- mainloop
	while (Client_IsAlive()) do 
		LugreStep()
		--~ print("GUITest_MainLoop_avgfps",OgreAvgFPS())
		
		InputStep() -- generate mouse_left_drag_* and mouse_left_click_single events 
		GUIStep() -- generate mouse_enter, mouse_leave events (might adjust cursor -> before CursorStep)
		CursorStep()

		Client_RenderOneFrame()
		local t = Client_GetTicks()
		Client_USleep(math.max(kMinFrameWait,kTicksBetweenFrames - (t - gLastFrameTime))) -- gives other processes a chance to do something
		gLastFrameTime = t
		--~ print("gWidgetUnderMouse",gWidgetUnderMouse)
	end
end

function GUITest_SpriteList_Simple ()
	local spritelist = CreateSpriteList(GetGUILayer_Dialogs(),false,true)
	spritelist.asgroup = spritelist:CastToRenderGroup2D()
	--~ spritelist.asgroup:SetClip(24,4,122,22)
	--~ spritelist:SetMaterial(GetPlainTextureGUIMat("guibase.png"))
	spritelist:SetMaterial("guibasemat")
	--~ spritelist:SetMaterial("BaseWhiteNoLighting")
	spritelist:ResizeList(1)
	SpriteList_Open(spritelist)
	local iSpriteIndex, l,t,w,h, u0,v0, uvw, uvh, z, r,g,b,a = 0, 0,0,32*4,32*4, 0,0, 1,1, 0,  1,0,0,0
	--~ SpriteList_SetSprite(iSpriteIndex, l,t,w,h, u0,v0, uvw, uvh, z)
	SpriteList_SetSpriteEx(iSpriteIndex, l,t,w,h, u0,v0, uvw,0, 0,uvh, z, r,g,b,a)
	--~ SpriteList_SetSpriteEx(0, 200+0,0, 16,800, 0.1,0.1, 0.4,0.0, 0.0,0.4, 0, 1,1,1,1)
	SpriteList_Close()
end

function GUITest_SpritePanel_Simple () 
	local texname,w,h,xoff,yoff, u0,v0,uvw,uvh, tcx,tcy = "art_fallback.png",64,64,0,0, 0,0,64,64, 64,64
	local gfxparam_init = MakeSpritePanelParam_SingleSprite(GetPlainTextureGUIMat(texname),w,h,xoff,yoff, u0,v0,uvw,uvh, tcx,tcy)
	local bVertexBufferDynamic,bVertexCol = false,false
	local parent_RenderGroup2D = GetGUILayer_Dialogs()
	local spritepanel = CreateSpritePanel(parent_RenderGroup2D,gfxparam_init,bVertexBufferDynamic,bVertexCol)
	gGUITest_SpritePanel_Simple_Ang = 0
	gGUITest_SpritePanel_Simple_AngSpeed = 0.02*math.pi
	RegisterListener("LugreStep",function () 
		gGUITest_SpritePanel_Simple_Ang = gGUITest_SpritePanel_Simple_Ang + gGUITest_SpritePanel_Simple_AngSpeed
		local x,y,sx,sy,angle = 0.5,0.5,0.5,0.5,gGUITest_SpritePanel_Simple_Ang
		spritepanel:Update(MakeSpritePanelParam_Mod_TexTransform(x,y,sx,sy,angle))
	end)
end

function GUITest_SpritePanel_Border () 
	local texname,w,h,xoff,yoff = kGUITest_BorderTestTex,200,200,0,0
	--~ local u0,v0,w0,w1,w2,h0,h1,h2, tcx,tcy = 0,0, 4,8,4, 4,8,4, 32,32
	local u0,v0,w0,w1,w2,h0,h1,h2, tcx,tcy = 0,0, 35,47,34, 35,80,35, 128,256
	local gfxparam_init = MakeSpritePanelParam_BorderPartMatrix(GetPlainTextureGUIMat(texname),w,h,xoff,yoff, u0,v0,w0,w1,w2,h0,h1,h2, tcx,tcy, 1,1, true, true)
	local bVertexBufferDynamic,bVertexCol = false,false
	local parent_RenderGroup2D = GetGUILayer_Dialogs()
	assert(parent_RenderGroup2D)
	local spritepanel = CreateSpritePanel(parent_RenderGroup2D,gfxparam_init,bVertexBufferDynamic,bVertexCol)
	
	RegisterListener("LugreStep",function () 
		-- resize to mouse
		local x,y = GetMousePos()
		gfxparam_init.w = x
		gfxparam_init.h = y
		spritepanel:Update(gfxparam_init)
		
		-- use different part of texture if clicked
		local e = 1/32
		local x,y,sx,sy,angle = 0,0,1,1,0
		if (gKeyPressed[key_mouse1]) then y = 0.5 end
		if (gKeyPressed[key_mouse2]) then x = 0.5 end
		spritepanel:Update(MakeSpritePanelParam_Mod_TexTransform(x,y,sx,sy,angle))
	end)
end


function GUITest_Widget_Layout ()
	Load_Font() -- iris specific

	local params = {
		gfxparam_init		= MakeSpritePanelParam_BorderPartMatrix(GetPlainTextureGUIMat("ray_border.png"),32,23,0,0, 0,0, 11,11, 10,10, 11,11, 32,32, 1,1, false, false),
		margin_left			= 4,
		margin_top			= 4,
		margin_right		= 4,
		margin_bottom		= 4,
	}

	local d = GetDesktopWidget():CreateChild("Border",params)
	
	local w = d:CreateContentChild("Border",params)
	w:SetLeftTop(0,0)
	w:SetSize(50,50)

	local w = d:CreateContentChild("Border",params)
	w:SetLeftTop(10,10)
	w:SetSize(100,50)

	local w = d:CreateContentChild("Border",params)
	w:SetLeftTop(50,10)
	w:SetSize(10,100)

	local w = d:CreateContentChild("Border",params)
	w:SetLeftTop(50,10)
	w:SetSize(10,100)

	local w = d:CreateContentChild("Border",params)
	w:SetLeftTop(50,10)
	w:SetSize(10,100)

	local w = d:CreateContentChild("Border",params)
	w:SetLeftTop(50,10)
	w:SetSize(10,100)

	d:SetSize(400,400)
	d:SetLeftTop(20,20)
	
	d:SetLayouter(gLayoutGridPrototype:New(4,4))
	d:DoLayout()
end


function GUITest_XML()
	Load_Font() -- iris specific
	Load_Gump()	
	--~ local widget = CreateWidgetFromXMLString(GetDesktopWidget(),"<UOText x=20 y=20 text='abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890' />")
	--~ local widget = CreateWidgetFromXMLString(GetDesktopWidget(),"<UOButton x=20 y=50 gump_id_normal=2015 gump_id_pressed=2016 />")
	
	--~ local texname,w,h,xoff,yoff = kGUITest_BorderTestTex,80,80,0,0
	--~ local u0,v0,w0,w1,w2,h0,h1,h2, tcx,tcy = 0,0, 4,8,4, 4,8,4, 32,32
	
	GuiThemeSetDefaultParam("Button",{	gfxparam_init 		= MakeSpritePanelParam_BorderPartMatrix(GetPlainTextureGUIMat(texname),w,h,xoff,yoff, u0,v0,w0,w1,w2,h0,h1,h2, tcx,tcy, 1,1, false, false),
										gfxparam_in_down	= MakeSpritePanelParam_Mod_TexTransform(0.0,0.5,1,1,0),
										gfxparam_in_up		= MakeSpritePanelParam_Mod_TexTransform(0.5,0.0,1,1,0),
										gfxparam_out_down	= MakeSpritePanelParam_Mod_TexTransform(0.0,0.0,1,1,0),
										gfxparam_out_up		= MakeSpritePanelParam_Mod_TexTransform(0.0,0.0,1,1,0),
										margin_left= 10,
										margin_top= 10,
										margin_right= 10,
										margin_bottom= 10,
										font=CreateFont_UO(gUniFontLoaderList[0]),
										textcol={r=0,g=0,b=0},
									})
	
	GuiThemeSetDefaultParam("Window",{	gfxparam_init 		= MakeSpritePanelParam_BorderPartMatrix(GetPlainTextureGUIMat(texname),w,h,xoff,yoff, u0,v0,w0,w1,w2,h0,h1,h2, tcx,tcy, 1,1, false, false),
									})
								
	--~ local widget = CreateWidgetFromXMLString(GetDesktopWidget(),"<Window x=100 y=100 w=300 h=200>"..
																--~ "<Button x=10 y=10 label='testbutton' />"..
																--~ "</Window>")	
	
	
	
	
	--~ local widget = CreateWidgetFromXMLString(GetDesktopWidget(),"<Button x=110 y=20 label='ghouly on the run!' />")
	
	
	--~ local widget = CreateWidgetFromXMLString(GetDesktopWidget(),"<UOButton x=20 y=50 gump_id_normal=2015 gump_id_pressed=2016>"..
																--~ "<UOText x=10 y=5 text='hello world !!!11eins!elf!' /></UOButton>")
							
end

function GUITest_Widget_Text ()
	--~ Load_Font() -- iris specific
	--~ local text = GetDesktopWidget():CreateChild("Text",{text="bla",font=CreateFont_UO(gUniFontLoaderList[3])})
	local text = GetDesktopWidget():CreateChild("Text",{text="bla",font=CreateFont_Ogre("TrebuchetMSBold")})
	print("text relbounds",text:GetRelBounds())
	text:SetPos(20,20)
	--~ text:SetLeftTop(20,20)
end

function GUITest_Widget_EditText ()
	Load_Font() -- iris specific
	local text = GetDesktopWidget():CreateChild("EditText",{text="bla",font=CreateFont_UO(gUniFontLoaderList[3])})
	text:SetFocus()
	text:SetLeftTop(20,20)
end

function GUITest_Widget_ScrollBar () 
	GetDesktopWidget():CreateChild("ScrollBar",{bVertical=true,x=400,y=0,w=16,h=400})
	GetDesktopWidget():CreateChild("ScrollBar",{bVertical=false,x=0,y=400,w=400,h=16})
end
function GUITest_Widget_ScrollPane () 
	Load_Font() -- iris specific
	local t = 16
	local scrollpane = GetDesktopWidget():CreateChild("ScrollPane",{panew=200,paneh=200,iScrollBarThickness=t})
	local text = scrollpane:CreateContentChild("Text",{text=gLoremIpsum,autowrap_w=200-t,font=CreateFont_UO(gUniFontLoaderList[3])})
	scrollpane:UpdateContent()
end

function GUITest_Widget_TabPane () 
	Load_Font() -- iris specific

	local test_image = MakeSpritePanelParam_SingleSprite(GetPlainTextureGUIMat("art_fallback.png"),
		32,32,0,0,0,0,32,32,32,32)

	local params = {
		gfxparam_pane			= MakeSpritePanelParam_BorderPartMatrix(GetPlainTextureGUIMat("tabbed.png"),128,128, 0,0, 2,2, 12,1,12, 12,1,12, 128,128, 1,1, false, false),
		gfxparam_tab			= MakeSpritePanelParam_BorderPartMatrix(GetPlainTextureGUIMat("tabbed.png"),128,128, 0,0, 31,2, 12,1,12, 12,1,1, 128,128, 1,1, false, false),
		gfxparam_tab_active		= MakeSpritePanelParam_BorderPartMatrix(GetPlainTextureGUIMat("tabbed.png"),128,128, 0,0, 31,20, 12,1,12, 12,1,1, 128,128, 1,1, false, false),
		margin_first_tab		= 10,
		margin_between_tab		= 10,
		margin_tab				= 6,
		margin_pane				= 6,
		height_tab_overlapped	= 2,
	}
	
	local tabpane = GetDesktopWidget():CreateChild("Tabpane",params)
	tabpane:SetSize(400,400)
	tabpane:SetLeftTop(10,10)
	
	tabpane:AddTab("test1")
	tabpane:GetTabContentTab("test1"):CreateChild("Text",{text="test1",textparam={r=0,g=0,b=0},font=CreateFont_UO(gUniFontLoaderList[0])})
	tabpane:GetTabContentPane("test1"):CreateChild("Text",{text="this is the first tab pane with\na lot of funny text!",textparam={r=0,g=0,b=0},font=CreateFont_UO(gUniFontLoaderList[0])})
	tabpane:AddTab("test2")
	tabpane:GetTabContentTab("test2"):CreateChild("Text",{text="test2",textparam={r=0,g=0,b=0},font=CreateFont_UO(gUniFontLoaderList[0])})
	tabpane:GetTabContentPane("test2"):CreateChild("Image",{gfxparam_init=test_image})
	tabpane:AddTab("test3")
	tabpane:GetTabContentTab("test3"):CreateChild("Text",{text="test3",textparam={r=0,g=0,b=0},font=CreateFont_UO(gUniFontLoaderList[0])})

	tabpane:UpdateAll()
end


function GUITest_Widget_Button () 
	Load_Font() -- iris specific

	local texname,w,h,xoff,yoff = kGUITest_BorderTestTex,80,80,0,0
	local u0,v0,w0,w1,w2,h0,h1,h2, tcx,tcy = 0,0, 4,8,4, 4,8,4, 32,32
	--~ local u0,v0,w0,w1,w2,h0,h1,h2, tcx,tcy = 0,0, 35,47,34, 35,80,35, 128,256
	
	local test_image = MakeSpritePanelParam_SingleSprite(GetPlainTextureGUIMat("art_fallback.png"),
		32,32,0,0,0,0,32,32,32,32)
		
	--~ local params = {
		--~ gfxparam_init		= MakeSpritePanelParam_BorderPartMatrix(GetPlainTextureGUIMat("ray_border.png"),32,23,0,0, 0,0, 11,11, 10,10, 11,11, tcx,tcy, 1,1, false, false),
		--~ margin_left			= 4,
		--~ margin_top			= 4,
		--~ margin_right		= 4,
		--~ margin_bottom		= 4,
	--~ }
	--~ local border = GetDesktopWidget():CreateChild("Border",params)
	
	local params = {
		gfxparam_init		= MakeSpritePanelParam_BorderPartMatrix(GetPlainTextureGUIMat(texname),w,h,xoff,yoff, u0,v0,w0,w1,w2,h0,h1,h2, tcx,tcy, 1,1, false, false),
		gfxparam_in_down	= MakeSpritePanelParam_Mod_TexTransform(0.0,0.5,1,1,0),
		gfxparam_in_up		= MakeSpritePanelParam_Mod_TexTransform(0.5,0.0,1,1,0),
		gfxparam_out_down	= MakeSpritePanelParam_Mod_TexTransform(0.0,0.0,1,1,0),
		gfxparam_out_up		= MakeSpritePanelParam_Mod_TexTransform(0.0,0.0,1,1,0),
		margin_left			= 10,
		margin_top			= 10,
		margin_right		= 10,
		margin_bottom		= 10,
		label_params		= {text="hagish on the run!",textparam={r=0,g=0,b=0},font=CreateFont_UO(gUniFontLoaderList[0])},
		--~ image_params		= {gfxparam_init=test_image},
		x = 100,
		y = 100,
	}
	local btn = GetDesktopWidget():CreateChild("Button",params)
		
	-- TODO : params : {src="guibase.png"}
	--~ local w,h,xoff,yoff, u0,v0,uvw,uvh, tcx,tcy = 32,32, 0,0, 0,0, 32,32, 32,32
	--~ btn:CreateChild("Text",{text="blablablaaaablub\nboing",font=CreateFont_UO(gUniFontLoaderList[3])})
	--~ btn:CreateChild("Image",{gfxparam_init=MakeSpritePanelParam_SingleSprite(GetPlainTextureGUIMat("art_fallback.png"),w,h,xoff,yoff, u0,v0,uvw,uvh, tcx,tcy)})
	--~ btn.on_button_click = function () print("on_button_click",Client_GetTicks()) end
	--~ btn.on_mouse_left_click_single = function () print("on_mouse_left_click_single",Client_GetTicks()) end
	--~ btn.on_mouse_left_click_double = function () print("on_mouse_left_click_double",Client_GetTicks()) end
end

function GUITest_Widget_Menu () 
	Load_Font() -- iris specific
	local texname,w,h,xoff,yoff = kGUITest_BorderTestTex,80,80,0,0
	local u0,v0,w0,w1,w2,h0,h1,h2, tcx,tcy = 0,0, 4,8,4, 4,8,4, 32,32
	--~ local u0,v0,w0,w1,w2,h0,h1,h2, tcx,tcy = 0,0, 35,47,34, 35,80,35, 128,256
	
	local label_params = {text="",textparam={r=0,g=0,b=0},font=CreateFont_UO(gUniFontLoaderList[0])}
	local btn_params = {
		gfxparam_init		= MakeSpritePanelParam_BorderPartMatrix(GetPlainTextureGUIMat(texname),w,h,xoff,yoff, u0,v0,w0,w1,w2,h0,h1,h2, tcx,tcy, 1,1, false, false),
		gfxparam_in_down	= MakeSpritePanelParam_Mod_TexTransform(0.0,0.5,1,1,0),
		gfxparam_in_up		= MakeSpritePanelParam_Mod_TexTransform(0.5,0.0,1,1,0),
		gfxparam_out_down	= MakeSpritePanelParam_Mod_TexTransform(0.0,0.0,1,1,0),
		gfxparam_out_up		= MakeSpritePanelParam_Mod_TexTransform(0.0,0.0,1,1,0),
		margin_left			= 10,
		margin_top			= 10,
		margin_right		= 10,
		margin_bottom		= 10,
	}
	local x,y = 100,100
	local entries={	{label="bla1",on_button_click=function () print(1) end},
					{label="bla2",on_button_click=function () print(2) end},}
	CreateMenu({x=x,y=y,btn_params=btn_params,label_params=label_params,entries=entries})
end

--[[
old flowtest
	
	local mytext = ...
	ToggleLogo()
	ToggleLogo()
	--~ gTestNoIrisLogo = true
	
	local myfont_ogre	= CreateFont_Ogre("TrebuchetMSBold") -- ogre font
	local myfont_uo0	= CreateFont_UO and CreateFont_UO(gUniFontLoaderList[0]) or myfont_ogre -- 0=medieval 
	local myfont_uo3	= CreateFont_UO and CreateFont_UO(gUniFontLoaderList[3]) or myfont_ogre -- 3=default-chat
	
	--~ local mytext = "Hallo, test 0123\nBlablubblub\nUnicode:äöüßÄÖÜ(german)\nTab\t1\tTabtest\nt\t1\n\t1\n\t\t2\n\t\t\t3\nFont1"
	local mytext = "Hello, test 0123\nUnicode:äöüßÄÖÜ(german)\nFont1"
	-- mytext:AddFontText(font,text,r,g,b,a,fontsize)
	mytext:AddFontText(myfont_uo0,mytext)
	mytext:AddFontText(myfont_ogre,",font2")
	mytext:AddFontText(myfont_uo3,",font3\n")
	
	local funchars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890"
	for y=0,0 do
		for i=0,20 do
			local cpos = math.random(string.len(funchars))
			local c = string.sub(funchars,cpos,cpos)
			local r,g,b,a = math.random(),math.random(),math.random(),1
			local r = math.random()
			local font = myfont_uo0
			if (math.random() < 0.5) then font = myfont_uo3 end
			--~ if (math.random() < 0.3) then font = myfont_ogre end
			mytext:AddFontText(font,c,r,g,b,a)
		end
		mytext:AddFontText(myfont_uo3,"\n")
	end
	mytext:AddFontText(myfont_uo0,"Fonts ")
	mytext:AddFontText(myfont_uo3,"and ")
	mytext:AddFontText(myfont_uo3,"C", 1,0,0)
	mytext:AddFontText(myfont_uo3,"o", 0,0,1)
	mytext:AddFontText(myfont_uo3,"l", 0,1,1)
	mytext:AddFontText(myfont_uo3,"o", 0,1,0)
	mytext:AddFontText(myfont_uo3,"r", 1,0,1)
	mytext:AddFontText(myfont_uo3,"s", 1,1,0)
	mytext:AddFontText(myfont_uo3," can be")
	mytext:AddFontText(myfont_uo0," mixed\n")
	
	mytext:AddFontText(myfont_uo3,"you can include images ")
	--~ mytext:AddSpace(2)
	--~ mytext:AddIcon("art_fallback.png",	18,18, 0, 0,0, 1,1)
	local e = 1/8
	mytext:AddIcon("compassframe_zoomin.png", 24,24, -2, e,e, 1-e,1-e)
	mytext:AddFontText(myfont_uo0,"12",0,1,0)
	mytext:AddFontText(myfont_uo3,",\nand even color them ")
	
	local texname, w,h, u0,v0, u1,v1, r,g,b,a = "guibase.png", 16,16, 0,0.5, 0.5,1
	mytext:AddIcon(texname, w,h, 2, u0,v0, u1,v1, 1,1,1,1) mytext:AddSpace(4)
	mytext:AddIcon(texname, w,h, 2, u0,v0, u1,v1, 1,0,0,1) mytext:AddSpace(4)
	mytext:AddIcon(texname, w,h, 2, u0,v0, u1,v1, 0,1,0,1)
	mytext:AddFontText(myfont_uo3," =)\n")
	mytext:AddFontText(myfont_uo3,"Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Vestibulum vehicula, diam placerat pellentesque viverra, ligula enim euismod ipsum, ut imperdiet justo dui vitae eros. Proin ut metus ac metus dapibus egestas. Mauris molestie aliquet turpis. Maecenas bibendum orci condimentum turpis. Integer faucibus lobortis tellus. Phasellus sed velit. Vivamus rhoncus. Etiam arcu mauris, congue eget, dapibus sit amet, pellentesque eget, velit. In mollis est sit amet risus. Integer ac tellus quis est pretium ultrices. Maecenas ac leo. Fusce bibendum volutpat enim. Nunc ullamcorper. Suspendisse nec magna ut urna convallis commodo. Sed odio libero, pellentesque sit amet, tempor sed, mattis eget, sapien. Ut sed dolor in pede lacinia porttitor. Ut rhoncus massa at lacus. Ut ligula. Donec a metus sit amet nisi sollicitudin mattis. Nulla odio magna, scelerisque at, semper quis, luctus in, odio.")
	mytext:SetPos(200,0,0)
	local wrap = 410
	--~ local wrap = 310
	mytext:SetAutoWrap(wrap)
	mytext:UpdateGeometry()
	--~ mytext:SetClip(0,0,390,900)
	
]]--
