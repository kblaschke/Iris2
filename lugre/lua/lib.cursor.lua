-- handles cursor images

gCursorOffsetX_Base = -7 -- fix mouse pos bug
gCursorOffsetY_Base = -7 -- fix mouse pos bug
gCursorOffsetX = gCursorOffsetX_Base
gCursorOffsetY = gCursorOffsetY_Base

function SetCursor (matname,w,h,offx,offy) 
	if (gNoRender) then return end
	GetCursorGfx2D()
	gCursorGfx:SetMaterial(matname)
	gCursorGfx:SetDimensions(w,h)
	SetCursorOffset(offx,offy)
end

function SetCursorBaseOffset (offx,offy)
	gCursorOffsetX_Base,gCursorOffsetY_Base = offx,offy
end

function SetCursorOffset (offx,offy)
	gCursorOffsetX = gCursorOffsetX_Base + (offx or 0)
	gCursorOffsetY = gCursorOffsetY_Base + (offy or 0)
end

function GetCursorGfx2D ()
	if (not gCursorGfx) then
		gCursorGfx = CreateCursorGfx2D()
		gCursorGfx:InitCCPO()
		gCursorGfx:SetPos(0,0)
	end
	return gCursorGfx
end

function CursorStep	()
	if (gCursorGfx) then 
		local mx,my = GetMousePos()
		gCursorGfx:SetPos(mx+gCursorOffsetX,my+gCursorOffsetY) 
	end
end

