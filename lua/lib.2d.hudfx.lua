--~ if (cam->getProjectionType() == Ogre::PT_ORTHOGRAPHIC) {  TODO : handle differently ?
Renderer2D.iNextHUDFXStepDebug = 0

-- 0=black,1=blue,4=lblue,10=whi/blue,22=pink,32=red,42=orange,
-- 52=yellow, 56=green-yellow, 62=green, 
-- 67=green, 72=dark-green  82=cyan,  86=lblue, 
-- 90 = white-blue?    150=white ?  153=yellow 
Renderer2D.kDamageTextCol_Self = {1,1,0} -- yellow
Renderer2D.kDamageTextCol_Other = {1,0,0} -- red

function Renderer2D:HUDFX_MainStep () HUDFX_MainStep() end
	




gLastDamageTime = 0
gLastDamageMana = 0
gLastDamageMana = 0
gLastDamageSeries = 0
gLastDamageSeriesManaStart = 0
gLastDamageSeriesDmgSum = 0
gLastDamageSeriesTimeStart = 0
gLastDamageSeriesTimeStart0 = 0
function Renderer2D:NotifyDamage( mobile_serial, damage) -- kPacket_Damage,0x0b
	local isOnSelf = GetPlayerSerial() == mobile_serial
	local col = isOnSelf and self.kDamageTextCol_Self or self.kDamageTextCol_Other
	local offsetx = isOnSelf and -32 or 0
	local r,g,b = unpack(col)
	self:HUDFX_AddRisingTextOnMob(GetMobile(mobile_serial),sprintf("%d",damage),r,g,b,offsetx)
	--~ print("2D:NotifyDamage ##################",Client_GetTicks(),damage,mobile_serial)
	
	if (not isOnSelf) then
		local t = Client_GetTicks()
		local dt = t - gLastDamageTime 
		local mana = GetPlayerManaCur()
		local dmana = gLastDamageMana - mana
		if (dt >= 2000) then
			gLastDamageSeries = 0
			gLastDamageSeriesManaStart = gLastDamageMana
			gLastDamageSeriesDmgSum = damage
			gLastDamageSeriesTimeStart = gLastDamageTime
			gLastDamageSeriesTimeStart0 = t
		else
			gLastDamageSeriesDmgSum = gLastDamageSeriesDmgSum + damage
		end
		if (damage > 30) then
			gLastDamageSeries = gLastDamageSeries + 1
		end
		gLastDamageTime = t
		gLastDamageMana = mana
		local seriesmana = mana - gLastDamageSeriesManaStart
		local seriesdt = t - gLastDamageSeriesTimeStart
		local seriesdt0 = t - gLastDamageSeriesTimeStart0
		--~ printf("### damage t=%d dt=%8d dmg=%3d dmana=%3d mana=%4d series=%d seriesmana=%3d seriesdmg=%4d seriesdt=%d seriesdt0=%d\n",t,dt,damage,dmana,mana,gLastDamageSeries,seriesmana,gLastDamageSeriesDmgSum,seriesdt,seriesdt0)
	end
end


function Renderer2D:HUDFX_AddRisingTextOnPos (xloc,yloc,zloc,text,r,g,b,offsetx,risetime,riseh)
	local hudfx = {}
	hudfx.dur = risetime or 1000
	hudfx.riseh = riseh or 64 -- in pixels

	local t = Client_GetTicks()
	hudfx.startt = t
	hudfx.endt = t + hudfx.dur
	hudfx.text = text
	hudfx.xloc = xloc
	hudfx.yloc = yloc
	hudfx.zloc = zloc
	hudfx.zadd = 10
	hudfx.offsetx = offsetx or 0
	
	local gfx = gRootWidget.hudfx:CreateChild("UOText",{x=0,y=0,text=text,col={r=r,g=g,b=b},bold=true})
	
	hudfx.gfx = gfx
	gHUDFX_MainList[hudfx] = true
end

function Renderer2D:HUDFX_AddRisingTextOnMob (mob,text,r,g,b,offsetx,risetime,riseh)
	HUDFX_AddRisingTextOnMob(mob,text,r,g,b,offsetx,risetime,riseh)
end

