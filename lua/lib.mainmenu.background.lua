--[[ ***** see Iris2 COPYING for license info ***** ]]--
--[[ \brief
        handles MainMenu Background
]]--

RegisterListener("Hook_StartInGame",function () MainMenu_Background_Stop() end)

function MainMenu_Background_Start ()
    if (gNoRender) then return end
    local vp = GetMainViewport()
    local w = vp:GetActualWidth()
    local h = vp:GetActualHeight()
    local gfxparam_init = MakeSpritePanelParam_SingleSpriteSimple(GetPlainTextureGUIMat("menu_bg.jpg"), 1024, 768)
    if (gMenuBgImage) then gMenuBgImage:Destroy() end
    gMenuBgImage = GetDesktopWidget():CreateChild("Image",{gfxparam_init=gfxparam_init})
    gMenuBgImage:SetPos(0,0)
    gMenuBgImage:SetSize(w,h)
    if (gDialog_IrisLogo) then gDialog_IrisLogo:SetVisible(false) end
    
    -- start menu sound
    SoundPlayMusicById(8)
end

function MainMenu_Background_Stop ()
    DestroyIfAlive(gMenuBgImage)
    gMenuBgImage = nil
end

--[[
-- old, wasn't used anymore
local function SetMainMenuCam (roth,rotv)
	local cam = GetMainCam()
	cam:SetFOVy(gfDeg2Rad*45)
	cam:SetNearClipDistance(0.5) -- old : 1
	cam:SetFarClipDistance(2000) -- ogre defaul : 100000
	cam:SetProjectionType(kCamera_PT_PERSPECTIVE) -- perspective
	local w1,x1,y1,z1 = Quaternion.fromAngleAxis(gfDeg2Rad * 90.0,1,0,0)
	local w2,x2,y2,z2 = Quaternion.fromAngleAxis(roth,0,1,0)	
	local w3,x3,y3,z3 = Quaternion.fromAngleAxis(rotv,1,0,0)
	local w4,x4,y4,z4 = Quaternion.Mul(w1,x1,y1,z1, w2,x2,y2,z2)
	
	local w,x,y,z = Quaternion.Mul(w4,x4,y4,z4, w3,x3,y3,z3)
	GetMainCam():SetRot(w,x,y,z)	
end
]]--
