-- used by 2d and 3d renderer

gHUDFX_MainList = {}

function HUDFX_MainStep ()
	local t = Client_GetTicks()
	for hudfx,v in pairs(gHUDFX_MainList) do HUDFX_Step(hudfx,t) end
end 

function HUDFX_Destroy (hudfx)
	if (hudfx.gfx) then hudfx.gfx:Destroy() hudfx.gfx = nil end
	gHUDFX_MainList[hudfx] = nil
end



function HUDFX_Step (hudfx,t)
	if (t > hudfx.endt) then HUDFX_Destroy(hudfx) return end
	if (hudfx.gfx) then 
		local xloc,yloc,zloc
		if (hudfx.mob) then
			local mobile = hudfx.mob
			xloc,yloc,zloc = gCurrentRenderer:GetExactMobilePos(mobile)
		else
			xloc,yloc,zloc = hudfx.xloc,hudfx.yloc,hudfx.zloc
		end
		if (xloc) then 
			local px,py = gCurrentRenderer:UOPosToPixelPos(xloc,yloc,zloc+hudfx.zadd)
			if (px) then 
				local dur = hudfx.dur
				local ft = min(dur,t - hudfx.startt) / dur
				hudfx.gfx:SetPos(px + hudfx.offsetx,py - sqrt(ft)*hudfx.riseh)
			end
		end
	end
end


function HUDFX_AddRisingTextOnMob (mob,text,r,g,b,offsetx,risetime,riseh)
	if (not mob) then return end
	local hudfx = {}
	hudfx.dur = risetime or 1000
	hudfx.riseh = riseh or 64 -- in pixels

	local t = Client_GetTicks()
	hudfx.startt = t
	hudfx.endt = t + hudfx.dur
	hudfx.text = text
	hudfx.mob = mob
	hudfx.zadd = 10
	hudfx.offsetx = offsetx or 0
	
	local gfx = gRootWidget.hudfx:CreateChild("UOText",{x=0,y=0,text=text,col={r=r,g=g,b=b},bold=true})
	
	hudfx.gfx = gfx
	gHUDFX_MainList[hudfx] = true
end

