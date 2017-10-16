-- utilities for cam handling

gCamThirdPersonDist = 100
gTableCamAngleH = 0
gTableCamAngleV = 0
gTableCamLastMouseX = nil
gTableCamLastMouseY = nil
gCamThirdPersonX,gCamThirdPersonY,gCamThirdPersonZ = 0,0,0


-- singleton pattern for maincam, wrap c function GetMainCam()
gMainCam = nil
_GetMainCam = GetMainCam 
function GetMainCam () 
	if (not gMainCam) then gMainCam = _GetMainCam() end
	return gMainCam
end

--- returns near,far
function Client_GetClipping 	()	
	local cam = GetMainCam()
	return cam:GetNearClipDistance(),cam:GetFarClipDistance() 
end

--- initialize ortho mode, useful for 2d rendering
function Client_SetPixelCoordSystem	()
	local cam = GetMainCam() 
	cam:SetFOVy( gfDeg2Rad*90 )
	cam:SetNearClipDistance( 0.5 * GetMainViewport():GetActualHeight() )
	cam:SetFarClipDistance( 100000.0 )
	cam:SetProjectionType(kCamera_PT_ORTHOGRAPHIC)
end 


function CamSetZoomLimit (minzoom,maxzoom) gCamMinZoom,gCamMaxZoom = minzoom,maxzoom end

function CamChangeZoom (add)
	-- todo : make this dependant on the magnitude of add
	local factor = 1
	local base = 1.5
	if (add > 0) then factor = base end
	if (add < 0) then factor = 1.0 / base end
	--print("gCamThirdPersonDist",gCamThirdPersonDist)
	gCamThirdPersonDist = gCamThirdPersonDist * factor
	if (gCamMinZoom) then gCamThirdPersonDist = math.max(gCamMinZoom,gCamThirdPersonDist) end
	if (gCamMaxZoom) then gCamThirdPersonDist = math.min(gCamMaxZoom,gCamThirdPersonDist) end
end


function TurnCam	(tw,tx,ty,tz)
	local cam = GetMainCam()
	local w,x,y,z = cam:GetRot()
	w,x,y,z = Quaternion.Mul(w,x,y,z,tw,tx,ty,tz)
	cam:SetRot(w,x,y,z)
end

-- get a normalizes vector with the view direction of the given camerea
-- return x,y,z
function CamViewDirection (cam)
	local qw,qx,qy,qz = cam:GetRot()
	local x,y,z = Quaternion.ApplyToVector(0,0,-1,qw,qx,qy,qz) 
	return x,y,z
end

-- return relx,rely
function GetMouseRel ()
	local mx,my = GetMousePos()
	local vp = GetMainViewport()
	local vw,vh = vp:GetActualWidth() , vp:GetActualHeight()
	local relx = -((mx/vw)*2 - 1)
	local rely = ((my/vh)*2 - 1)
	if (gbInvertMouse) then rely = -rely end
	return relx,rely
end

-- return turn quaternion : w,x,y,z
function CamGetMouseTurn (speedfactor)
	local relx,rely = GetMouseRel()
	local reldist = math.sqrt(relx*relx + rely*rely)
	local x,y,z = Vector.cross(0,0,1,relx,rely,0)
	x,y,z = Vector.normalise(x,y,z)
	local tw,tx,ty,tz = Quaternion.fromAngleAxis(reldist*speedfactor*gfMouseSensitivity,x,y,z)
	return tw,tx,ty,tz
end

-- +y is up ?
function CamSetFromTwoAngles (cam,roth,rotv,bFlipUpAxis)
	if (bFlipUpAxis) then
		local w1,x1,y1,z1 = Quaternion.fromAngleAxis(gfDeg2Rad * 90.0,1,0,0)    
		local w2,x2,y2,z2 = Quaternion.fromAngleAxis(roth,0,1,0)  
		local w3,x3,y3,z3 = Quaternion.fromAngleAxis(rotv,1,0,0)
		local w4,x4,y4,z4 = Quaternion.Mul(w1,x1,y1,z1, w2,x2,y2,z2)
		
		w3,x3,y3,z3 = Quaternion.Mul(w4,x4,y4,z4, w3,x3,y3,z3)
		cam:SetRot(w3,x3,y3,z3)
	else
		local w1,x1,y1,z1 = Quaternion.fromAngleAxis(roth,0,1,0)	
		local w2,x2,y2,z2 = Quaternion.fromAngleAxis(rotv,1,0,0)
		local w3,x3,y3,z3 = Quaternion.Mul(w1,x1,y1,z1, w2,x2,y2,z2)
		cam:SetRot(w3,x3,y3,z3)
	end
end

-- handles a turntable like camera that keeps upright
function StepTableCam (cam,bMoveCam,speedfactor,bFlipUpAxis)
	local mx,my = GetMousePos()
	if (bMoveCam) then
		gTableCamAngleV = gTableCamAngleV - speedfactor * (my-(gTableCamLastMouseY or my)) * (gbInvertMouse and -1 or 1)
		local hsign = (math.cos(gTableCamAngleV) < 0) and -1 or 1
		gTableCamAngleH = gTableCamAngleH - speedfactor * (mx-(gTableCamLastMouseX or mx)) * hsign
	end
	gTableCamLastMouseX = mx
	gTableCamLastMouseY = my
	CamSetFromTwoAngles(cam,gTableCamAngleH,gTableCamAngleV,bFlipUpAxis)
end

-- enables third person view by keeping the cam at a distance to origin
function StepThirdPersonCam (cam,dist,ox,oy,oz)
	local qw,qx,qy,qz = cam:GetRot()
	local x,y,z = Quaternion.ApplyToVector(0,0,dist,qw,qx,qy,qz) 
	cam:SetPos(ox+x,oy+y,oz+z)
end

--[[
--  h,v cam, todo : 2 variants
function SetMainMenuCam (roth,rotv)
	--gMainMenuCamAngHSpeed = - ((mx/vw)*2 - 1) * factor * gMainMenuCamMouseSpeedFactor
	--gMainMenuCamAngVSpeed = - ((my/vh)*2 - 1) * factor * gMainMenuCamMouseSpeedFactor
	--gMainMenuCamAngH = gMainMenuCamAngH + gMainMenuCamAngHSpeed * gSecondsSinceLastFrame
	--gMainMenuCamAngV = gMainMenuCamAngV + gMainMenuCamAngVSpeed * gSecondsSinceLastFrame
	--SetMainMenuCam(gMainMenuCamAngH,gMainMenuCamAngV)
	local w1,x1,y1,z1 = Quaternion.fromAngleAxis(gfDeg2Rad * 90.0,1,0,0)
	local w2,x2,y2,z2 = Quaternion.fromAngleAxis(roth,0,1,0)	
	local w3,x3,y3,z3 = Quaternion.fromAngleAxis(rotv,1,0,0)
	local w4,x4,y4,z4 = Quaternion.Mul(w1,x1,y1,z1, w2,x2,y2,z2)
	
	local w,x,y,z = Quaternion.Mul(w4,x4,y4,z4, w3,x3,y3,z3)
	GetMainCam():SetRot(w,x,y,z)
end
]]--


