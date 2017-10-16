RendererNull = {}

gRendererList[ "RendererNull" ] = RendererNull

function RendererNull_Print(...) --[[ print("<NULL>",...) ]] end
function RendererNull_PrintOften(...) --[[ print("<NULL>",...) ]] end

function RendererNull:DeInit () RendererNull_Print("DeInit") end
function RendererNull:Init () 
	RendererNull_Print("Init") 
	self.fCamPosXLoc = 0
	self.fCamPosYLoc = 0
	self.fCamPosZLoc = 0
end

function RendererNull:SetMapEnvironment () RendererNull_Print("SetMapEnvironment") end

function RendererNull:MousePick_ShowHits () RendererNull_Print("MousePick_ShowHits") end

function RendererNull:UpdateMobileModel (mobile) RendererNull_Print("UpdateMobileModel",mobile) end
function RendererNull:UpdateMobile (mobile) RendererNull_Print("UpdateMobile",mobile) end
function RendererNull:NotifyPlayerTeleported () RendererNull_Print("NotifyPlayerTeleported") end
--~ function RendererNull:StartWorld () RendererNull_Print("StartWorld") end
function RendererNull:UpdateMapEnvironment (hour,minute,second) RendererNull_Print("UpdateMapEnvironment",hour,minute,second) end

function RendererNull:AddDynamicItem (item) RendererNull_Print("AddDynamicItem",item) end
function RendererNull:RemoveDynamicItem (item) RendererNull_Print("RemoveDynamicItem",item) end
function RendererNull:UpdateDynamicItemPos (item) RendererNull_Print("UpdateDynamicItemPos",item) end
function RendererNull:MainStep () RendererNull_PrintOften("MainStep") end
function RendererNull:MobileStartServerSideAnim (animdata) RendererNull_Print("MobileStartServerSideAnim",animdata) end
function RendererNull:MousePick_Scene () RendererNull_Print("MousePick_Scene") end
function RendererNull:CamChangeZoom (f) RendererNull_Print("CamChangeZoom",f) end

function RendererNull:DestroyMobileGfx (mobile) RendererNull_Print("DestroyMobileGfx",mobile) end
function RendererNull:SelectMobile (serial) RendererNull_Print("SelectMobile",serial) end
function RendererNull:DeselectMobile () RendererNull_Print("DeselectMobile") end

function RendererNull:DestroyMousePickItemBySerial (serial) RendererNull_Print("DestroyMousePickItemBySerial",serial) end

-- sets the global sunlight level, intensity=0 -> dark, intensity=1 -> bright
function RendererNull:SetSunLight (intensity) RendererNull_Print("SetSunLight",intensity) end
-- sets the personal light level, intensity=0 -> dark, intensity=1 -> bright
function RendererNull:SetPersonalLight (mobile, intensity) RendererNull_Print("SetPersonalLight",mobile, intensity) end

function RendererNull:CamKeyDown (key) RendererNull_Print("CamKeyDown",key) end
function RendererNull:CamKeyUp (key) RendererNull_Print("CamKeyUp",key) end

-- returns ax,xloc,yloc  (ax = angle, constant for iso cam)
function RendererNull:GetCompassInfo				() 
	local ax = (180+45)*gfDeg2Rad
	local xloc,yloc = self:GetCamPos()
	RendererNull_PrintOften("GetCompassInfo",ax,xloc,yloc)
	return ax,xloc,yloc
end

-- returns xloc,yloc in uo coords
function RendererNull:GetCamPos () 
	RendererNull_PrintOften("GetCamPos") 
	return self.fCamPosXLoc, self.fCamPosYLoc, self.fCamPosZLoc 
end

function RendererNull:BlendOutLayersAbovePlayer () RendererNull_Print("BlendOutLayersAbovePlayer") end

function RendererNull:NotifyHPChange				(mobile, value) end
function RendererNull:NotifyManaChange				(mobile, value) end
function RendererNull:ClearMapCache					() end
function RendererNull:AddEffect						() end
function RendererNull:HUDFX_AddRisingTextOnMob		() end
function RendererNull:NotifyDamage		() end 
function RendererNull:SetLastRequestedUOPos		() end 
function RendererNull:SetLastConfirmedUOPos		() end 
