--[[ ***** see Iris2 COPYING for license info ***** ]]--
--[[ \brief
        kPacket_Hue_Picker  = { id=0x95 }
        r,g,b = GetHueColor(data.hue-1)
        5er groups for brightness : 0x0002-0x0006,...
        1000/5 = 200 = 20*10 rows/columns
]]--

--[[
0x0002:00b,
0x0003:00e,
0x0004:33e,
0x0005:66f,
0x0006:99f,

0x0007:30b,
0x0008:40e,
0x0009:63e,
0x000a:96f,
0x000b:b9f,
]]--

kHuePickerFirst = 2
kHuePickerLast  = 1001
kHuePickerBrightnessList = {0,1,3} -- 0-4 = dark->light

RegisterWidgetClass("UOHuePicker")
RegisterWidgetClass("UOHuePickerButton")

function ShowHuePicker (data) GetDesktopWidget():CreateChild("UOHuePicker",data) end

-- ***** ***** ***** ***** ***** UOHuePicker widget
function gWidgetPrototype.UOHuePicker:Init (parentwidget,params)
    self:InitAsGroup(parentwidget,params)
    self.items = {}
    
    local bw,bh = 10,10
    local texname,w,h,xoff,yoff = "simplebutton.png",bw,bh,0,0
    local u0,v0,w0,w1,w2,h0,h1,h2, tcx,tcy = 0,0, 4,8,4, 4,8,4, 32,32
    local gfxparam_init = MakeSpritePanelParam_BorderPartMatrix(GetPlainTextureGUIMat(texname),w,h,xoff,yoff, u0,v0,w0,w1,w2,h0,h1,h2, tcx,tcy, 1,1, false, false)

    local tw,th = 8,8
    for bk,brightness in ipairs(kHuePickerBrightnessList) do
    for y=0,10-1 do 
    for x=0,20-1 do 
        local hue = kHuePickerFirst + (y*20 + x)*5 + brightness -- *5:brightness +2:middle brighness by default
        local r,g,b = GetHueColor(hue-1)
        gfxparam_init.r = r
        gfxparam_init.g = g
        gfxparam_init.b = b
        local btn = self:CreateChild("UOHuePickerButton",{x=x*tw,y=(bk*10+y)*th,hue=hue,gfxparam_init=gfxparam_init})
    end
    end
    end
    
    --~ self.gfx_maintarget = gRootWidget.tooltip:CreateChild("UOText",{x=0,y=0,text="",col={r=1,g=0,b=0},bold=true})
    --~ self.gfx_maintarget_line = gRootWidget.tooltip:CreateChild("LineList",{matname="BaseWhiteNoLighting",bDynamic=true,r=1,g=0,b=0})
    
    self:SetPos(200,100)
end

function gWidgetPrototype.UOHuePicker:ChooseHue (hue)
    local data = self.params
    print("UOHuePicker:ChooseHue",hue)
    SendHuePickerResponse(data.serial,data.unknown,hue)
    self:Destroy()
end
function gWidgetPrototype.UOHuePicker:on_mouse_right_down   () self:Destroy() end

function gWidgetPrototype.UOHuePickerButton:Init (parentwidget,params)
    local bVertexBufferDynamic,bVertexCol = false,true
    self:InitAsSpritePanel(parentwidget,params,bVertexBufferDynamic,bVertexCol)
    if (params.x) then self:SetLeftTop(params.x,params.y) end
end

function gWidgetPrototype.UOHuePickerButton:on_button_click () self:GetParent():ChooseHue(self.params.hue) end

--[[
function HueTest ()
    Load_Hue()
    ShowHuePicker({serial=0x1234,itemid=0x4567})
    --~ for hue = 1,102 do 
        --~ local r,g,b = GetHueColor(hue-1)
        --~ local txt = sprintf("0x%04x:%03x,",hue,floor(r*16)*16*16+floor(g*16)*16+floor(b*16))
        --~ print(txt)
    --~ end
    --~ os.exit(0)
end
]]--
       