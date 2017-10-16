-- see also lib.gui.widget.lua
-- displays uo tooltips, with html-like text formatting and coloring, ignores mouseover
-- see also UOContainerItemWidget:on_simple_tooltip

RegisterWidgetClass("UOToolTip")

gMyToolTipColors = {
	["Insured"]					="#00FF00",
	["blessed"]					="#00FF00",
	["slayer"]					="#00FF00",
	["hit harm"]				="#00FF00",
	["hit magic arrow"]			="#00FF00",
	["hit fireball"]			="#00FF00",
	["hit lightning"]			="#00FF00",
	["hit dispell"]				="#88FF88",
	["reflect physical damage"]	="#88FF88",
	["lower[^\n]+cost"]			="#88FF88",
	["hit[^\n]+leech"]			="#88FF88",
	["hit mana leech"]			="#88FF88",
	["[^\n]+increase"]			="#88FF88",
	["[^\n]+regeneration"]		="#88FF88",
	["[^\n]+%+[0-9]+"]			="#88FF88",
	["[^\n]+bonus"]				="#88FF88",
	["mana regeneration"]		="#88FF88",
	["spell channeling"]		="#88FF88",
	["swing speed increase"]	="#88FF88",
	["self repair"]				="#88FF88",
	["luck"]					="#88FF88",
	["faster casting"]			="#88FF88",
	["faster cast recovery"]	="#88FF88",
	["mage armor"]				="#88FF88",
	["spellchanneling"]			="#88FF88",
	["[^\n]+resist"]			="#8888FF",
	["exceptional"]				="#AAAAAA",
	["^physical damage"]		="#AAAAAA",
	["weapon damage"]			="#AAAAAA",
	["weapon speed"]			="#AAAAAA",
	["strength requirement"]	="#AAAAAA",
	["lower requirements"]		="#AAAAAA",
	["skill required:"]			="#AAAAAA",
	["range"]					="#AAAAAA",
	["one%-handed weapon"]		="#AAAAAA",
	["two%-handed weapon"]		="#AAAAAA",
	["Weight:[^\n]+"]			="#AAAAAA",
	["durability"]				="#AAAAAA",
	["uses remaining:[^\n]+"]	="#AAAAAA",
}

gUOToolTipWidgets = {}
RegisterListenerOnce("Hook_ToolTipUpdate",function (serial,data) 
	local w = gUOToolTipWidgets[serial]
	if (w) then
		if (not w:IsAlive()) then gUOToolTipWidgets[serial] = nil return end
		w:RefreshText()
	end
end,"UOToolTip_Hook_ToolTipUpdate")
	
-- params = {serial=serial/nil,text=text/nil,x=iMouseX,y=iMouseY}
function gWidgetPrototype.UOToolTip:Init (parentwidget, params)
	self.params	= params
	params.gfxparam_init		= params.gfxparam_init	or	MakeSpritePanelParam_BorderPartMatrix(GetPlainTextureGUIMat("sience_border.png")
																,320,320, 0,0, 0,0, 12,12, 8,8, 12,12, 32,32, 1,1, false, false)
	params.margin_left			= params.margin_left	or	4
	params.margin_top			= params.margin_top		or	4
	params.margin_right			= params.margin_right	or	4
	params.margin_bottom		= params.margin_bottom	or	4
	
	local bVertexBufferDynamic,bVertexCol = false,true
	local spritepanel = CreateSpritePanel(parentwidget:CastToRenderGroup2D(),params.gfxparam_init,bVertexBufferDynamic,bVertexCol)
	self:SetRenderGroup2D(spritepanel:CastToRenderGroup2D())
	self:AddToDestroyList(spritepanel) -- don't add spritelist here, will be destroyed in spritepanel destructor
	self.spritepanel = spritepanel
	self.params = params
	self:SetIgnoreBBoxHit(true)
	self:SetIgnoreChildHits(true)
	
	self.text = self:CreateChild("UOText",{x=0,y=0,text="???",html=true,bold=true})

	self:SetPos(params.x,params.y)
	gUOToolTipWidgets[self.params.serial or 0] = self
	self:RefreshText()
end


-- TODO : see also SetSizeFromContentBounds : needed for text, e.g. in widget.uotooltip.lua
-- content bounds specified manually, content container not used
function gWidgetPrototype.UOToolTip:AdjustToContentBounds (l,t,r,b) 
	local params = self.params
	local gfxparams = params.gfxparam_init
	local borderl	= params.margin_left	or 0
	local bordert	= params.margin_top		or 0
	local borderr	= params.margin_right	or 0
	local borderb	= params.margin_bottom	or 0
	gfxparams.xoff = l-borderl
	gfxparams.yoff = t-bordert
	local w,h = r-l,b-t
	if (w < 0 or w > 1000) then print("uotooltip : w out of bounds",w) end
	if (h < 0 or h > 1000) then print("uotooltip : h out of bounds",h) end
	--~ w = min(500,max(0,w))
	--~ h = min(500,max(0,h))
	gfxparams.w = borderl+w+borderr
	gfxparams.h = bordert+h+borderb
	self.spritepanel:Update(gfxparams)
end

-- returns r,g,b  in [0;1]
function GetRedYellowGreen (f)
	return 1 - max(0,min(1, f*2 - 1)),max(0,min(1,f*2)),0
end

function ToolTipColDura (duracur,duramax) 
	duracur = tonumber(duracur)
	duramax = tonumber(duramax)
	local f = (duramax>0) and (duracur/duramax) or 0
	local r,g,b = GetRedYellowGreen(f)
	return sprintf("durability <BASEFONT COLOR=#%02X%02X%02X>%d / %d (%d%%)</BASEFONT>",r*255,g*255,b*255,duracur,duramax,f*100)
end

function gWidgetPrototype.UOToolTip:RefreshText ()
	local serial = self.params.serial
	local tooltiptext = self.params.text or GetToolTipTextForSerial(serial) or "???"
	
	local mobile = serial and GetMobile(serial)
	local r,g,b = 1,1,0
	if (mobile) then r,g,b = GetNotorietyColor(mobile.notoriety) end
	
	
	tooltiptext = sprintf("<BASEFONT COLOR=#%02X%02X%02X>",floor(r*255),floor(g*255),floor(b*255))..string.gsub(tooltiptext,"\n","</BASEFONT>\n",1)
	tooltiptext = string.gsub(tooltiptext,"durability (%d+) / (%d+)",ToolTipColDura)
	for keyword,color in pairs(gMyToolTipColors) do 
		tooltiptext = string.gsub(tooltiptext,keyword,"<BASEFONT COLOR="..color..">%0</BASEFONT>")
	end
	local dataholder = {}
	dataholder.tooltiptext = tooltiptext
	NotifyListener("Hook_Tooltip_RefreshText",dataholder,serial) 
	
	tooltiptext = dataholder.tooltiptext
	
	--~ print("tooltiptext",tooltiptext)
	self.text:SetUOHtml(tooltiptext,true)
	local w,h = self.text:GetSize()
	local vw,vh = GetViewportSize()
	local x,y = self:GetDerivedPos()
	local tx,ty = max(0-x,min(vw-w-x,-floor(0.5*w))),max(0-y,min(vh-h-20-y,0))
	self.text:SetPos(tx,ty) -- center text horizontally
	local l,t,r,b = self.text:GetRelBounds()
	self:AdjustToContentBounds(l+tx,t+ty,r+tx,b+ty)
end

function gWidgetPrototype.UOToolTip:GetDialog			() return self end -- override, normaly parent:GetDialog(), so this ends recursion

function gWidgetPrototype.UOToolTip:on_mouse_left_down	() self:Close() end -- probably not needed as mouse is ignored
function gWidgetPrototype.UOToolTip:on_mouse_right_down	() self:Close() end -- probably not needed as mouse is ignored
function gWidgetPrototype.UOToolTip:Close				() self:Destroy() end -- probably not needed as mouse is ignored




