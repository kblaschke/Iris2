-- shows small buttons for all items and mobs when ctrl+shift is pressed

gNameGumpsActive = false
gNameGumps = {}
gNameGumpsNextPosUpdate = 0

kNameGumpYOff = -10
kNameGumpPosUpdateInterval = 1000/25
RegisterWidgetClass("UONameGump")

gNameGumpSkippedTypes = {
	-- blood
	0x122a,0x122b,0x122c,0x122d,0x122e,0x1645,0x1cc7,0x1cc8,0x1cc9,0x1cca,0x1ccb,0x1ccc,0x1ccd,0x1cce,
	0x1ccf,0x1cd0,0x1cd1,0x1cd2,0x1cd3,0x1cd4,0x1cd5,0x1cd6,0x1cd7,0x1cd8,0x1cd9,0x1cda,0x1cdb,0x1cdc,
	0x1cf1,0x1cf2,0x1cf3,0x1cf4,0x1cf5,0x1cf6,0x1cf7,0x1cf8,0x1cf9,0x1cfa,0x1cfb,0x1cfc,0x1cfd,0x1cfe,
	0x1cff,0x1d00,0x1d01,0x1d02,0x1d03,0x1d04,0x1d05,0x1d06,0x1d07,0x1d08,0x1d09,0x1d0a,0x1d0b,0x1d0c,
	0x1d0d,0x1d0e,0x1d0f,0x1d10,0x1d11,0x1d12,0x1d92,0x1d93,0x1d94,0x1d95,0x1d96,
}

gNameGumpSkippedTypesByID = {}
for k,artid in ipairs(gNameGumpSkippedTypes) do gNameGumpSkippedTypesByID[artid] = true end

RegisterStepper(function () 
	local bActive = gKeyPressed[key_lshift] and gKeyPressed[key_lcontrol]
	if (bActive == gNameGumpsActive) then 
		if (gNameGumpsActive and Client_GetTicks() > gNameGumpsNextPosUpdate) then 
			gNameGumpsNextPosUpdate = Client_GetTicks() + kNameGumpPosUpdateInterval
			NameGumps_PosUpdate()
		end
		return 
	end
	local bOnlyCorpses = gKeyPressed[key_lalt]
	if (bActive) then NameGumps_Show(bOnlyCorpses) else NameGumps_Destroy() end
end)

function NameGumps_ShowDynamic (dynamic)
	table.insert(gNameGumps,GetDesktopWidget():CreateChild("UONameGump",dynamic))
end
function NameGumps_ShowMobile (mobile)
	table.insert(gNameGumps,GetDesktopWidget():CreateChild("UONameGump",mobile))
end
function NameGumps_Show (bOnlyCorpses)
	if (bOnlyCorpses) then 
		for k,dynamic in pairs(GetDynamicList()) do if (DynamicIsInWorld(dynamic) and IsCorpseArtID(dynamic.artid)) then NameGumps_ShowDynamic(dynamic) end end
	else
		for k,dynamic in pairs(GetDynamicList()) do if (DynamicIsInWorld(dynamic) and (not gNameGumpSkippedTypesByID[dynamic.artid])) then NameGumps_ShowDynamic(dynamic) end end
		for k,mobile in pairs(GetMobileList()) do if (not IsPlayerMobile(mobile)) then NameGumps_ShowMobile(mobile) end end
	end
	gNameGumpsActive = true
end
function NameGumps_Destroy ()
	for k,v in pairs(gNameGumps) do if (v:IsAlive()) then v:Destroy() end end
	gNameGumps = {}
	gNameGumpsActive = false
end
function NameGumps_PosUpdate ()
	for k,v in pairs(gNameGumps) do if (v:IsAlive()) then v:UpdatePos() end end
end

-- ***** ***** ***** ***** ***** UONameGump

							
function gWidgetPrototype.UONameGump:Init (parentwidget,params)
	local r,g,b = 1,1,1
	if (params.isdynamic) then 
		self.item = params -- for mousepick
	else 
		self.mobile = params -- for mousepick
		r,g,b = GetNotorietyColor(self.mobile.notoriety)
	end
	local plaintext = GetToolTipTextForSerial(params.serial) or "???"
	
	local bVertexBufferDynamic,bVertexCol = false,true
	
	local bw,bh = 200,100
	local texname,w,h,xoff,yoff = "simplebutton.png",bw,bh,0,0
	local u0,v0,w0,w1,w2,h0,h1,h2, tcx,tcy = 0,0, 4,8,4, 4,8,4, 32,32
	params.gfxparam_init = MakeSpritePanelParam_BorderPartMatrix(GetPlainTextureGUIMat(texname),w,h,xoff,yoff, u0,v0,w0,w1,w2,h0,h1,h2, tcx,tcy, 1,1, false, false)
	params.gfxparam_init.r = r
	params.gfxparam_init.g = g
	params.gfxparam_init.b = b
	self:InitAsSpritePanel(parentwidget,params,bVertexBufferDynamic,bVertexCol)
	
	--~ local txt = self:CreateChild("UOHuePickerButton",{x=x*10,y=y*10,hue=hue,gfxparam_init=gfxparam_init})
	
	self.maintext = self:CreateChild("UOText",{x=0,y=0,text=plaintext,col={r=0,g=0,b=0},html=true,bold=false})
	--~ self.gfx_maintarget_line = gRootWidget.tooltip:CreateChild("LineList",{matname="BaseWhiteNoLighting",bDynamic=true,r=1,g=0,b=0})
	
	local e = 2
	local l,t,r,b = self.maintext:GetRelBounds()
	params.gfxparam_init.w = e+e+r-l
	params.gfxparam_init.h = e+e+b-t
	params.gfxparam_init.xoff = l-e
	params.gfxparam_init.yoff = t-e
	self.spritepanel:Update(params.gfxparam_init) -- adjust base geometry
	self:UpdatePos()
end

function gWidgetPrototype.UONameGump:UpdatePos	()
	local xloc,yloc,zloc
	if (self.mobile) then xloc,yloc,zloc = gCurrentRenderer:GetExactMobilePos(self.mobile) end
	if (self.item  ) then xloc,yloc,zloc = self.item.xloc,self.item.yloc,self.item.zloc end
	local px,py = gCurrentRenderer:UOPosToPixelPos(xloc,yloc,zloc)
	if (px) then 
		local offx,offy = -0.5*self.params.gfxparam_init.w,kNameGumpYOff
		self:SetPos(px + offx,py + offy)
	end
end
function gWidgetPrototype.UONameGump:on_mouse_right_down		() self:Destroy() end
function gWidgetPrototype.UONameGump:on_mouse_left_click_double	() Send_DoubleClick(self.params.serial) end
function gWidgetPrototype.UONameGump:on_mouse_left_drag_start	() 
	if (self.mobile) then 
		local widget = OpenHealthbarAtMouse(self.mobile) 
		if (widget) then widget:BringToFront() widget:StartMouseMove() end
	end
end

