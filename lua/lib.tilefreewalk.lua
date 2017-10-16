-- non-tilebased walking
-- see also net.walk.lua lib.walking2.lua
-- TODO : jump clientside ? auto-chat *jump* + recognized by other iris clients ?  hack anim by reverse die-backw ? blend sit ? ride ?


gTileFreeWalk = {}

kFreeWalkMouseSlowArea = 70
kFreeWalkOptimizeTimeout = 100
 
kTileFreeTestMobile = {artid=400,hue=33780, content={ -- artid=400:human 987=gmrobe
		{artid=3932,animid=631},{artid=7028},
		{artid=5137,animid=529},{artid=9797,animid=682},
		{artid=5140,animid=530},{artid=5136,animid=528},
		{artid=8256,animid=800},{artid=3701,animid=422},
		{artid=5141,animid=527},{artid=3708,animid=0},
		{artid=8266,animid=903},
		{artid=hex2num("0x3EA2"),layer=kLayer_Mount},
		
		
		--~ [4]={artid=5422,hue=1728,animid=430}, -- trousers
		--~ [26]={artid=3701,hue=0,animid=422},
		--~ [16]={artid=8269,hue=1147,animid=906},
		--~ [27]={artid=3701,hue=0,animid=422},
		--~ [17]={artid=8059,hue=0,animid=913},  -- shirt
		--~ [11]={artid=8252,hue=1147,animid=701},
		--~ [21]={artid=3701,hue=0,animid=422}
		}} 
		
gTileFreePlayerRad = 0.2 -- radius of player/human
gTileFreeDebugWallH = 0.7
kStuckCheckDuration = 4000

-- ##### ##### ##### ##### ##### init

function UpdateDebugTerrainGrid (rx,ry,rz)
	if (not gDebugTerrainGrid) then return end
	if (gDebugTerrainGridGfx) then  gDebugTerrainGridGfx:Destroy() end
	local gfx = CreateRootGfx3D()
	gDebugTerrainGridGfx = gfx
	gfx:SetSimpleRenderable()
	gfx:SetCastShadows(false)
	
	rx = rx + 0.5
	ry = ry + 0.5
	local h = 0.5
	local minx,maxx = -4,4
	local miny,maxy = -4,4
	local wallpieces = (maxx-minx+1) + (maxy-miny+1)
	local r,g,b,a = 0,1,0,0.5
	
	gfx:RenderableBegin(4*2*wallpieces,6*2*wallpieces,false,false,OT_TRIANGLE_LIST)
	local vc = 0
	for x = minx,maxx do
		local x1,y1,z1 = rx+x,ry+miny,rz
		local x2,y2,z2 = rx+x,ry+maxy,rz
		vc = DrawQuad(gfx,vc, x1,y1,z1, x2,y2,z2, x1,y1,z1+h, x2,y2,z2+h, 0,0, 1,0, 0,1, 1,1)
		vc = DrawQuad(gfx,vc, x1,y1,z1+h, x2,y2,z2+h, x1,y1,z1, x2,y2,z2, 0,0, 1,0, 0,1, 1,1)
	end
	for y = miny,maxy do
		local x1,y1,z1 = rx+minx,ry+y,rz
		local x2,y2,z2 = rx+maxx,ry+y,rz
		vc = DrawQuad(gfx,vc, x1,y1,z1, x2,y2,z2, x1,y1,z1+h, x2,y2,z2+h, 0,0, 1,0, 0,1, 1,1)
		vc = DrawQuad(gfx,vc, x1,y1,z1+h, x2,y2,z2+h, x1,y1,z1, x2,y2,z2, 0,0, 1,0, 0,1, 1,1)
	end
	gfx:RenderableEnd()
	gfx:SetMaterial(GetPlainColourMat(r,g,b,a))
end

-- ##### ##### ##### ##### ##### init


function gTileFreeWalk:DeInit ()
	-- TODO
	self.mbActive = false
end

function gTileFreeWalk:PreInit ()
	self.pathpoints = {}
	self.debugmarkers = {}
	self.debugmarkergroups = {}
	self.walls = {}
	self.iLastTimeNotStuck = 0
	self.movedirx = 0
	self.movediry = 1
	self.pos_clientside = {0,0,0}
	self.pos_lastconfirmed = {0,0,0}
	self.pos_lastrequested = {0,0,0}
end

function gTileFreeWalk:Init ()
	if (gCurrentRenderer ~= Renderer3D) then return end
	self:SetPos_All(self:LocalToUOPos(0,0,0))
	
	self.mbActive = true
	
	if (true) then
		self.sDebugMarkerMeshName_Big	= MakeSphereMesh(11,11,0.2,0.2,0.2)
		self.sDebugMarkerMeshName_Dir	= MakeSphereMesh(11,11,0.1,0.1,0.1)
	end

	gTileFreeWalk:OnStartInGame()
end

function gTileFreeWalk:OnStartInGame ()
	-- Offline Mode
	if (gStartGameWithoutNetwork) then
		Renderer3D:ChangeCamMode(Renderer3D.kCamMode_Third)
		--~ self:SetPos_All(self:LocalToUOPos(-1548.5, 326.5, 5.0)) --  iris online canyons
		--~ self:SetPos_All(self:LocalToUOPos(-1489.5, 402.5,-7.6))
		--~ self:SetPos_All(self:LocalToUOPos(-1482.5,1527.5, 2.0))  -- osi-britannia  -- set in startofflinemode in lib.mainmenu.lua
		--~ self:SetPos_All(self:LocalToUOPos(-1482.5,1527.5, 2.0))  -- osi-britannia  -- set in startofflinemode in lib.mainmenu.lua
	end
	-- Walking only in Online and Offline Mode
	if not(gStartInDebugMode) then
		RegisterStepper(function () if not self.mbActive then return true else gTileFreeWalk:Step() end end)
	end
end

--~ RegisterListener("Hook_StartInGame",function () gTileFreeWalk:OnStartInGame() end)
--~ RegisterListener("Hook_PreLoad",function () gTileFreeWalk:Init() end)


-- ##### ##### ##### ##### ##### step

function InterpolateSquare (z00,z10,z01,z11,fx,fy) -- z00=left_top:fx=fy=0   z10=right_top:fx=1,fy=0
	local t = fx * z10 + (1.0 - fx) * z00
	local b = fx * z11 + (1.0 - fx) * z01
	return fy * b + (1.0 - fy) * t
end

local z00,z10,z01,z11 = 1,2,3,4
assert(InterpolateSquare(z00,z10,z01,z11, 0,0) == z00)
assert(InterpolateSquare(z00,z10,z01,z11, 1,0) == z10)
assert(InterpolateSquare(z00,z10,z01,z11, 0,1) == z01)
assert(InterpolateSquare(z00,z10,z01,z11, 1,1) == z11)




function gTileFreeWalk:Step	()
	if (gDisableTileFreeWalk) then return end
	if (gCurrentRenderer ~= Renderer3D) then return end
	local bWalkInMouseDir	= gKeyPressed[key_mouse2] and (not gLastMouseDownWidget)
	local bWalkForward		= (not gActiveEditText) and gKeyPressed[key_up]		
	local bWalkBackwards	= (not gActiveEditText) and gKeyPressed[key_down]	
	local bTurnLeft			= (not gActiveEditText) and gKeyPressed[key_left]	
	local bTurnRight		= (not gActiveEditText) and gKeyPressed[key_right]	
	local bSlowWalk			= gKeyPressed[key_lshift]
	local fRequestedSpeed = 0
	local bRunRequested = false
	
	-- should the wall collision be ignored? used for pathfinding
	local bIgnoreCollision = false
	
	-- hold rightmouse button to walk in mouse direction (depends on center of screen, works good for 3rd person cam)
	local bMoved = false
	local x,y,z = self:GetPos_ClientSide()
	local ox,oy = x,y
	
	-- cancel autowalk and attack if user interacts
	if bWalkInMouseDir or bWalkForward or bWalkBackwards or bTurnLeft or bTurnRight then
		gWalkPathToGo = nil
		StopAttack()
	end
	
	-- read input and calculate desired movement
	if (bWalkInMouseDir) then
		if (Renderer3D:IsFirstPersonCam()) then
			fRequestedSpeed = self:GetClientSideSpeed(self.movedirx,self.movediry,0)
		else
			local dx,dy,pixel_dist_from_center = self:GetCurrentMouseDir() 
			local slowarea_pixels = kFreeWalkMouseSlowArea
			bRunRequested = pixel_dist_from_center > slowarea_pixels
			local slowarea_factor = math.min(1.0,pixel_dist_from_center / slowarea_pixels) -- mouse near center : move slow
			self.movedirx = dx
			self.movediry = dy
			fRequestedSpeed = self:GetClientSideSpeed(self.movedirx,self.movediry,0) * slowarea_factor
		end

		local maxspeed = fRequestedSpeed * gSecondsSinceLastFrame
		if (bSlowWalk) then maxspeed = maxspeed * 0.5 end -- TODO : bSlowWalk-speed
		bRunRequested = not bSlowWalk

		x = x + self.movedirx * maxspeed
		y = y + self.movediry * maxspeed
		bMoved = true

	elseif gWalkPathToGo then
		-- stores the path for pathfinding
		-- the player runs along this path without user interaction
		
		-- bIgnoreCollision = true
		
		local onthemove = false
		
		for k,v in pairs(gWalkPathToGo) do
			local px,py = -v.x,v.y
			local len = len2(x-px,y-py)
			
			if len == 0 then 
				gWalkPathToGo[k] = nil
			elseif not onthemove then
				onthemove = true
				
				local dx,dy = px-x,py-y
				self.movedirx,self.movediry = norm2(dx,dy)
		
				fRequestedSpeed =  self:GetClientSideSpeed(self.movedirx,self.movediry,0)
				local maxspeed = fRequestedSpeed * gSecondsSinceLastFrame
				if (bSlowWalk) then maxspeed = maxspeed * 0.5 end -- TODO : bSlowWalk-speed
				bRunRequested = not (bSlowWalk or gWalkPathToGoSlow)
				bMoved = true
				
				maxspeed = math.min(maxspeed, len)
				
				x = x + self.movedirx * maxspeed
				y = y + self.movediry * maxspeed
			end
		end
		
		if countarr(gWalkPathToGo) == 0 then gWalkPathToGo = nil end
		
	else
		local angadd = 0
		if (bTurnLeft ) then  angadd = angadd + 240 * gfDeg2Rad * gSecondsSinceLastFrame end
		if (bTurnRight) then  angadd = angadd - 240 * gfDeg2Rad * gSecondsSinceLastFrame end
		if (angadd ~= 0) then 
			local dx,dy = self.movedirx,self.movediry
			self.movedirx = dx*cos(angadd) - dy*sin(angadd)
			self.movediry = dx*sin(angadd) + dy*cos(angadd)
			self.movedirx,self.movediry = norm2(self.movedirx,self.movediry)
			bMoved = true
		end
		if (bWalkForward or bWalkBackwards) then
			fRequestedSpeed =  self:GetClientSideSpeed(self.movedirx,self.movediry,0)
			local maxspeed = fRequestedSpeed * gSecondsSinceLastFrame
			if (bSlowWalk) then maxspeed = maxspeed * 0.5 end -- TODO : bSlowWalk-speed
			bRunRequested = not bSlowWalk
			bMoved = true
			
			if (bWalkForward) then
				x = x + self.movedirx * maxspeed
				y = y + self.movediry * maxspeed
			elseif (bWalkBackwards) then
				x = x - self.movedirx * maxspeed
				y = y - self.movediry * maxspeed
			end
		end
	end

	-- execute movement (and collision/block handling)
	if (bMoved) then	
		-- block movement here
		local rx,ry,rz = self:RoundPos(x,y,z)
		--self:DebugMarkerGroup_Clear("touchwalls")
		local vx,vy = sub2(x,y,ox,oy)
		local movedist = len2(vx,vy)
		local steps = math.ceil(movedist/(0.8*gTileFreePlayerRad)) 
		if (steps > 0) then
			local sx,sy = vx/steps,vy/steps
			x,y = ox,oy
			for i=1,steps do -- multisample movement
				x,y = x+sx,y+sy
				
				if not bIgnoreCollision then
					-- 1st collision : with wall center, to avoid speed bumps while walking along a wall
					x,y = self:CollideWithWallMid(x,y)
					-- 2nd collision : with wall edges, otherwise it would be possible to move into an edge between 2 non-parallel walls
					x,y = self:CollideWithWallEdge(x,y)
					-- 3rd collision : with wall center again, to avoid the edge collisions pushing the player slowly inside the walls
					x,y = self:CollideWithWallMid(x,y)
				end
				
				rx,ry,rz = self:RoundPos(x,y,z)
				self:PathPoint_Push(rx,ry,rz)
				local xloc,yloc,zloc = self:LocalToUOPos(rx,ry,rz)
				self:ScanGroundIfNeeded(xloc,yloc,zloc,rx,ry,rz)
				
				-- calc correct z here
				if (self.groundcache) then
					local fx = -x - floor(-x)
					local fy =  y - floor( y)
					
					local z00 = self:GroundCacheGetHeightForInterpolation(xloc  ,yloc  )
					local z10 = self:GroundCacheGetHeightForInterpolation(xloc+1,yloc  )
					local z01 = self:GroundCacheGetHeightForInterpolation(xloc  ,yloc+1)
					local z11 = self:GroundCacheGetHeightForInterpolation(xloc+1,yloc+1)
					local zr = z00 or z10 or z01 or z11
					if (zr) then
						z = InterpolateSquare(z00 or zr,z10 or zr,z01 or zr,z11 or zr,fx,fy) * 0.1 + Renderer3D.gZ_Factor
					end
				end
			end
		end

		if gTileFreeWalkDiagonalOptimization then 
			self:PathPoint_OptimizeForDiagonalMovement()
		end
		
		self:SetPos_ClientSide(x,y,z)
		self:UpdateClientPosMarker()
	end
	
	-- if the player does not move due to collision stop autowalk
	if gFreewalkLastX and gWalkPathToGo then
		local d = Vector.len(Vector.sub(x,y,z, gFreewalkLastX,gFreewalkLastY,gFreewalkLastZ))
		if d < 0.001 then
			gWalkPathToGo = nil
		end
	end
	-- store current position
	gFreewalkLastX,gFreewalkLastY,gFreewalkLastZ = x,y,z

	-- debug markers
	if (gShowTileFreeDebug) then
		local x,y,z = self:GetPos_LastConfirmed()
		self:SetDebugMarker("GetPos_LastConfirmed", x,y,z, 0,0,0, 0,1,0)
		local x,y,z = self:GetPos_LastRequested()
		self:SetDebugMarker("GetPos_LastRequested", x,y,z, 0,0,0, 0,0,1)
	end
	
	-- send walk requests to server if possible
	self:Impl_WalkRequestStep(bRunRequested)
	
	if (not gStartGameWithoutNetwork) then 
		if (gMyTicks - self.iLastTimeNotStuck > kStuckCheckDuration) then
			local lx,ly,lz = self:GetPos_LastRequested()
			local rx,ry,rz = self:RoundPos(self:GetPos_ClientSide())
			if (lx ~= rx or ly ~= ry) then self:StuckFix(lx,ly,lz) end
		end
	end
	
	self:Impl_StepPlayer(fRequestedSpeed,bRunRequested)
end

-- ##### ##### ##### ##### ##### groundcache

function gTileFreeWalk:GroundCacheGetHeightForInterpolation (xloc,yloc)
	return	self.groundcache[(xloc  )..","..(yloc  )] or
			self.groundcache[(xloc-1)..","..(yloc  )] or
			self.groundcache[(xloc  )..","..(yloc-1)] or
			self.groundcache[(xloc-1)..","..(yloc-1)]
end

-- ##### ##### ##### ##### ##### collision


function gTileFreeWalk:CollideWithWallMid (x,y)
	for k,wallarr in pairs(self.walls) do -- block straight
		local x1,y1,x2,y2,dx,dy,nx,ny,invsqlen = unpack(wallarr)
		local vx,vy = sub2(x,y,x1,y1)
		local pos = dot2(vx,vy,dx,dy) * invsqlen
		if (pos >= 0 and pos <= 1) then -- collide with wall itself
			local dist = dot2(vx,vy,nx,ny)
			local pushoutdist = gTileFreePlayerRad - dist
			if (dist > -gTileFreePlayerRad and pushoutdist > 0) then
				--self:DebugMarkerGroup_AddWall("touchwalls", 	x1,y1,z,   x2,y2,z, gTileFreeDebugWallH,	1,1,0)
				x,y = add2(x,y,nx*pushoutdist,ny*pushoutdist)
			end
		end
	end
	return x,y
end


function gTileFreeWalk:CollideWithWallEdge (x,y)
	for k,wallarr in pairs(self.walls) do -- block edge
		local x1,y1,x2,y2,dx,dy,nx,ny,invsqlen = unpack(wallarr)
		local vx,vy = sub2(x,y,x1,y1)
		local pos = dot2(vx,vy,dx,dy) * invsqlen
		if (pos <= 0) then -- collide with edge : x1,y1
			local pushoutdist = gTileFreePlayerRad - len2(vx,vy)
			if (pushoutdist > 0) then x,y = add2(x,y,tolen2(vx,vy,pushoutdist)) end
		elseif (pos >= 1) then -- collide with edge : x2,y2
			vx,vy = sub2(x,y,x2,y2)
			local pushoutdist = gTileFreePlayerRad - len2(vx,vy)
			if (pushoutdist > 0) then x,y = add2(x,y,tolen2(vx,vy,pushoutdist)) end
		end
	end
	return x,y
end


function gTileFreeWalk:UpdateGroundCache (xloc,yloc,zloc)
	-- print("##### gTileFreeWalk:UpdateGroundCache",xloc,yloc,zloc)
	if (not gGroundBlockLoader) then print("gTileFreeWalk:UpdateGroundCache : warning, no maploader(yet)") return end
	xloc = floor(xloc)
	yloc = floor(yloc)
	zloc = floor(zloc)
	local groundcache = {}
	for iDir=0,7 do 
		groundcache[(xloc+GetDirX(iDir))..","..(yloc+GetDirY(iDir))] = GetNearestGroundLevel(xloc,yloc,zloc,iDir)
	end
	groundcache[xloc..","..yloc] = zloc
	self.groundcache = groundcache
end

-- triggers a rescan of the collision information around the given location
function gTileFreeWalk:IvalidateCacheAround(xloc,yloc,radius)
	radius = radius or 5
	local lsx = self.lastscanxloc
	local lsy = self.lastscanyloc
	if lsx and lsy then
		local d = dist2max(xloc,yloc,lsx,lsy)
		if d < radius then
			-- print("##### gTileFreeWalk:IvalidateCacheAround",lsx,lsy,":",xloc,yloc,radius,":",d)
			self.lastscanxloc = nil
			self.lastscanyloc = nil
		end
	end
end

-- scans the ground if clientpos entered a new tile, calculates walls
function gTileFreeWalk:ScanGroundIfNeeded (xloc,yloc,zloc,rx,ry,rz)
	if (self.lastscanxloc ~= xloc or self.lastscanyloc ~= yloc) then
		self.lastscanxloc = xloc
		self.lastscanyloc = yloc
	-- print("##### gTileFreeWalk:ScanGroundIfNeeded",xloc,yloc,zloc,rx,ry,rz)
		-- read surrounding height info
		if (self.groundcache) then
			local myzloc = self.groundcache[xloc..","..yloc] 
			if (myzloc) then zloc = myzloc self:UpdateGroundCache(xloc,yloc,zloc) end
			-- new xloc,zloc is not neccessarily valid, for example the rounded edge of a table
			-- check old groundcache andlisten to teleport/block notify
		end
		local groundcache = self.groundcache
		
		self.bSkipWalkStep = false
		UpdateDebugTerrainGrid(rx,ry,rz)
		
		self:DebugMarkerGroup_Clear("nearground")
		function GetGround (dx,dy) return groundcache[(xloc-dx)..","..(yloc+dy)] end --  print("GetGround",x,y,z,rx,ry)
		local walls = {}
		self.walls = walls
		
		for dx = -1,1 do 
		for dy = -1,1 do 
			local x,y,z = rx+dx,ry+dy,GetGround(dx,dy)
			if (z) then 
				local h = 0.5
				--self:DebugMarkerGroup_AddCylinder("nearground",	x,y,z, 0.01,h,	0,1,0)
				--self:DebugMarkerGroup_AddSphere("nearground", x,y,z, 0.1,		0,1,0)
			else	
				z = rz
				local e = 0.5
				
				local b00 = true
				local b01 = true
				local b10 = true
				local b11 = true
		
				if (not GetGround(dx,dy+1)) then -- vertical
					table.insert(walls,{	x-e,y,   x-e,y+e	})
					table.insert(walls,{	x+e,y+e, x+e,y		})
					b01 = false b11 = false
				end
				if (not GetGround(dx,dy-1)) then -- vertical
					table.insert(walls,{	x-e,y-e, x-e,y		})
					table.insert(walls,{	x+e,y,   x+e,y-e	})
					b00 = false b10 = false
				end
				
				if (not GetGround(dx+1,dy)) then -- horizontal
					table.insert(walls,{	x,y+e,   x+e,y+e	})
					table.insert(walls,{	x+e,y-e, x,y-e		})
					b10 = false b11 = false
				end                                                           
				if (not GetGround(dx-1,dy)) then -- horizontal       
					table.insert(walls,{	x-e,y+e, x,y+e		})     
					table.insert(walls,{	x,y-e,   x-e,y-e	})
					b00 = false b01 = false
				end
				
				if (b00) then table.insert(walls,{	x,y-e,   x-e,y	}) end
				if (b01) then table.insert(walls,{	x-e,y,   x,y+e	}) end
				if (b11) then table.insert(walls,{	x,y+e,   x+e,y	}) end
				if (b10) then table.insert(walls,{	x+e,y,   x,y-e	}) end
			end
		end
		end
		
		-- todo : add special walls to block diagonal movement, to avoid errors with rounding
		-- warning, the rounded position of the player can be blocked, due to diagonal movement
		
		-- precalc some vars for the walls
		local h = 1.5
		for k,wallarr in pairs(self.walls) do
			local x1,y1,x2,y2 = unpack(wallarr)
			local dx,dy = sub2(x2,y2,x1,y1)
			local nx,ny = norm2(-dy,dx)
			local invsqlen = 1.0/sqlen2(dx,dy)
			self.walls[k] = {x1,y1,x2,y2,dx,dy,nx,ny,invsqlen}
			if (gShowTileFreeDebugWalls) then
				self:DebugMarkerGroup_AddWall("nearground", 	x1,y1,rz,   x2,y2,rz, h,	1,0,0)
			end
		end
	end
end

-- ##### ##### ##### ##### ##### gathering information, external walk parameters


function gTileFreeWalk:GetMaxAllowedSpeed		() return self:Impl_GetMaxAllowedSpeed() end
function gTileFreeWalk:GetMaxAllowedTurnRate	() return self:Impl_GetMaxAllowedTurnRate() end 

function gTileFreeWalk:GetWalkRequestInterval	() return 1000/self:GetMaxAllowedSpeed() end -- in milliseconds

function gTileFreeWalk:GetClientSideTurnRate	() return self:GetMaxAllowedTurnRate() end 

-- returns the movement speed, dx,dy,dz is the direction of the movement
-- the speed is dependant on the distance of the current pos to the last confirmed pos
-- and on the direction of the movement
function gTileFreeWalk:GetClientSideSpeed		(dx,dy,dz)
	local maxspeed			= self:GetMaxAllowedSpeed()
	
	dx,dy,dz = Vector.normalise(dx,dy,dz)
	local x,y,z = self:GetPos_ClientSide()
	local cx,cy,cz = self:GetPos_LastConfirmed()
	local vx,vy,vz = Vector.normalise(Vector.sub(cx,cy,cz, x,y,z)) -- vector from cur pos to last confirmed pos
	local dot = Vector.dot(dx,dy,dz, vx,vy,vz) -- +1.0 if walking back, -1.0 if walking away
	local slow_dir = math.max(0,math.min(1,1.0-dot))-- 0 = no slowdown => max speed : no slowdown when dot = 1
	
	local dist				= self:GetDistanceToLastConfirmedPos()
	local tolerated_dist	= 1
	local minspeed_dist		= 4 + tolerated_dist -- todo : currently slowdown is linear, make smoother spline here ?
	local slow_dist			= math.min(0.9,math.max(0,dist-tolerated_dist)/minspeed_dist) -- 0 = no slowdown => max speed
	
	return maxspeed * (1.0 - slow_dist * slow_dir)
end

-- returns dx,dy,pixel_dist_from_center in uo coordinate system, vector2d(dx,dy).length = 1
function gTileFreeWalk:GetCurrentMouseDir	()
	local mx, my = GetMousePos()
	local vw, vh = GetViewportSize()
	local ax,ay,az = GetMainCam():GetEulerAng()
	local mouseang = -math.atan2( my-vh/2.0, mx-vw/2.0 ) + ax -- in radians
	local pixel_dist_from_center = Vector.len( my-vh/2.0, mx-vw/2.0 , 0)
	return math.cos(mouseang),math.sin(mouseang),pixel_dist_from_center
end


-- ##### ##### ##### ##### ##### implementation (currently uo specific, will later be inserted from extern)

function gTileFreeWalk:NotifyPlayerMobileTeleport (mobile)
	self:Impl_SetToPlayerPos(mobile)
end

function gTileFreeWalk:NotifyPlayerMobileUpdate (mobile)	
	if (not self.bNetPosInit) then self.bNetPosInit = true self:Impl_SetToPlayerPos(mobile) end
end

function gTileFreeWalk:Impl_SetLastRequestedUOPos (xloc,yloc,zloc)
	--~ print("Impl_SetLastRequestedUOPos",xloc,yloc)
	local x,y,z = self:UOPosToLocal(xloc,yloc,zloc)
	self:SetPos_LastRequested(x,y,z)
	self:PathPoint_ReachPos(x,y,z)
end

function gTileFreeWalk:Impl_SetLastConfirmedUOPos (xloc,yloc,zloc)
	self:SetPos_LastConfirmed(self:UOPosToLocal(xloc,yloc,zloc))
end

function gTileFreeWalk:SetPosFromPacketVideo(xloc,yloc,zloc,fulldir)
	local dir = DirWrap(fulldir)
	self.movedirx,self.movediry = norm2(GetDirXLocal(dir),GetDirYLocal(dir))
	gTileFreeWalk:SetPos_All(xloc,yloc,zloc)
	gTileFreeWalk:UpdateClientPosMarker()
end

function gTileFreeWalk:Impl_SetToPlayerPos (mobile)
	self.movedirx,self.movediry = norm2(GetDirXLocal(gPlayerDir),GetDirYLocal(gPlayerDir))
	self:SetPos_All(mobile.xloc,mobile.yloc,mobile.zloc)
	self:UpdateClientPosMarker()
end

function gTileFreeWalk:UOPosToLocal (xloc,yloc,zloc)
	local x,y,z = Renderer3D:UOPosToLocal(xloc,yloc,zloc*0.1) -- inverts x
	return x-0.5, y+0.5, z
end

function gTileFreeWalk:LocalToUOPos (x,y,z)
	local xloc,yloc,zloc = Renderer3D:LocalToUOPos(x,y,z*10)  -- inverts x
	return math.floor(xloc),math.floor(yloc),math.floor(zloc)
end

function gTileFreeWalk:Impl_CanSendWalkRequest ()
	return true -- TODO : check if fastwalkstack non empty
end

function WalkLog2 (...) if (gKeyPressed[key_f]) then print("walklog2",...) end end

function gTileFreeWalk:Impl_WalkRequestStep (bRunRequested)
	if gTileFreeWalkDiagonalOptimization then
		local x,y,z,t = self:PathPoint_GetNext()
		if 
			self:PathPoint_Count() <= 3 and 
			t and Client_GetTicks() - t <  kFreeWalkOptimizeTimeout
		then return end
	end
	
	if (self.bSkipWalkStep) then return end -- skip this step if movement has finished
	
	-- self confirm here if there is no server, debug/offline mode only
	if (gStartGameWithoutNetwork) then 
		local rx,ry,rz = self:RoundPos(self:GetPos_ClientSide())
		self:PathPoint_ReachPos(rx,ry,rz)
		self:SetPos_LastConfirmed(rx,ry,rz) 
		self:SetPos_LastRequested(rx,ry,rz) 
		return 
	end
	
	if (not Walk_RequestTimeOk()) then return end
	
	local nx,ny,nz = self:PathPoint_GetNext()
	if (not nx) then nx,ny,nz = self:RoundPos(self:GetPos_ClientSide()) end
	local lx,ly,lz = self:GetPos_LastRequested()
	local dx,dy = nx-lx,ny-ly
	if (dx == 0 and dy == 0) then self.bSkipWalkStep = true return end
	
	local iDir = DirFromLocalDxDy(dx,dy)
	if (not iDir) then self.bSkipWalkStep = true return end
	
	if (WalkStep_WalkInDir(iDir,bRunRequested,true)) then self.iLastTimeNotStuck = gMyTicks end
end

function gTileFreeWalk:StuckFix (lx,ly,lz)
	print("gTileFreeWalk:StuckFix")
	self.iLastTimeNotStuck = gMyTicks
	self:SetPos_All(self:LocalToUOPos(lx,ly,lz))
	self:UpdateClientPosMarker()
end

-- dx,dy,dz = gTileFreeWalk:GetViewDir() , dz is always zero
function gTileFreeWalk:GetViewDir ()		return self.movedirx or 0,self.movediry or -1,0 end
function gTileFreeWalk:SetViewDir (dx,dy)	self.movedirx,self.movediry = dx,dy end

-- qw,qx,qy,qz = gTileFreeWalk:GetOrientation()
function gTileFreeWalk:GetOrientation ()	return Quaternion.getRotation(0,-1,0,self:GetViewDir()) end

-- fRequestedSpeed is the speed requested by the mousepos/keyboard, might not be reached, e.g. when walking against a wall
function gTileFreeWalk:Impl_StepPlayer (fRequestedSpeed,bRunRequested)

	local bMoving,bTurning,bWarMode,bRunFlag = false,false,false,false
	bMoving = fRequestedSpeed > 0
	bRunFlag = bRunRequested
	self.bRunRequested = bRunRequested
	
	local x,y,z = self:GetPos_ClientSide()
	local qw,qx,qy,qz = self:GetOrientation()
	
	local mobile = GetPlayerMobile()
	if (mobile) then 
		Renderer3D:UpdateMobilePos(mobile,x+0.5,y-0.5,z,qw,qx,qy,qz)
		------ --- TODO : SetState(bMoving,bTurning,bWarMode,bRunFlag)
		
		bWarMode 	= TestBit(mobile.flag,kMobileFlag_WarMode) -- combat
		--~ bRunFlag 	= TestBit(mobile.dir,kWalkFlag_Run)
		if (mobile.bodygfx) then mobile.bodygfx:SetState(bMoving,bTurning,bWarMode,bRunFlag) end
		
		if (gStartGameWithoutNetwork) then
			-- Do the following if offline.  These things are done elsewhere if online.
			gCurrentRenderer:BlendOutLayersAbovePlayer()
			
			gPlayerXLoc,gPlayerYLoc,gPlayerZLoc = Renderer3D:LocalToUOPos(x,y,z * 10)
			gPlayerXLoc = math.floor(gPlayerXLoc)
			gPlayerYLoc = math.floor(gPlayerYLoc)
			gPlayerZLoc = math.floor(gPlayerZLoc)
		end
	end
end

-- returns x,y,z
function gTileFreeWalk:Impl_MousePickPos ()
	gMousePickFoundHit = false
	Renderer3D:MousePick_Scene()
	local x = Renderer3D.gMousePickFoundHit_ExactX
	local y = Renderer3D.gMousePickFoundHit_ExactY
	local z = Renderer3D.gMousePickFoundHit_ExactZ
	return x,y,z
end

-- world-units (tiles for uo) per second
-- todo : depends on conditions(stamina,spells,buffs,debuffs...) and on mount/horse ?
function gTileFreeWalk:Impl_GetMaxAllowedSpeed		() 
	return 1000 / (gStartGameWithoutNetwork and gWalkTimeout_MountRunningSpeed or WalkGetInterval(true))
end
function gTileFreeWalk:Impl_GetMaxAllowedTurnRate	() return 45*gfDeg2Rad end

-- feedback for thirdpersoncam
function gTileFreeWalk:GetExactLocalPos	() return self:GetPos_ClientSide() end

--[[
-- 27.09.2007 : the code that triggers this event has been deactivated, so this should no longer be neccessary
RegisterListener("Hook_RecenterWorld",function (difx,dify)
	print("ERROR, TileFreeWalk : Hook_RecenterWorld not yet implemented")
	-- todo : move all positons...
	Crash()
end)
]]--

-- ##### ##### ##### ##### ##### pathpoints

-- the system remembers which path was walked clientside, and approximates it for sending to the walk requests
-- note : pathpoints can be impassable, happens during diagonal walk, don't send walk requests to those

	
-- mark position as "reached", consuming neighboring pathpoints
function gTileFreeWalk:PathPoint_ReachPos (x,y,z)
	local maxreached = 0
	local c = self:PathPoint_Count()
	for i = 1,c do 
		local px,py,pz = self:PathPoint_GetNth(i)
		if (abs(px-x) <= 1 and abs(py-y) <= 1) then maxreached = i end
	end
	if (maxreached == 0) then return end
	for i = 1,maxreached do self:PathPoint_Pop() end
end

function gTileFreeWalk:PathPoint_Count		() 			return table.getn(self.pathpoints) end
function gTileFreeWalk:PathPoint_GetNext	() return self:PathPoint_GetNth(1) end

-- n=1 for first = next
function gTileFreeWalk:PathPoint_GetNth		(n) 
	if (not self.pathpoints[n]) then return end
	return unpack(self.pathpoints[n])
end
function gTileFreeWalk:PathPoint_HasNext	() return self:PathPoint_Has(1) end
function gTileFreeWalk:PathPoint_Has		(n) return table.getn(self.pathpoints) >= n end
function gTileFreeWalk:PathPoint_RemoveNth	(n)
	if (self:PathPoint_Has(n)) then 
		local x,y,z = self:PathPoint_GetNth(n)
		if (gShowTileFreeDebug) then self:DelDebugMarker("path"..x..","..y..","..z) end
		table.remove(self.pathpoints,n) 
	end 
end 
function gTileFreeWalk:PathPoint_Pop		() 
	self:PathPoint_RemoveNth(1)
end
function gTileFreeWalk:PathPoint_Push		(x,y,z)
	local c = self:PathPoint_Count()
	if (c > 0) then 
		local lx,ly,lz = unpack(self.pathpoints[c])
		if (lx == x and ly == y) then return end
	end
	local lx,ly,lz = self:GetPos_LastRequested()
	if (abs(lx-x) <= 1 and abs(ly-y) <= 1) then return end
	table.insert(self.pathpoints,{x,y,z,Client_GetTicks()})
	if (gShowTileFreeDebug) then self:SetDebugMarker("path"..x..","..y..","..z, x,y,z, 0,0,0, 0.5,0.5,0.5) end
end

-- checks if p1 p2 p3 build a stair
function gTileFreeWalk:PathPoint_IsStairPoint	(x1,y1,x2,y2,x3,y3)
	return
		(abs(x1-x3) == 1 and abs(y1-y3) == 1) and
		(abs(x1-x2) == 1 or abs(y1-y2) == 1) and
		(abs(x3-x2) == 1 or abs(y3-y2) == 1)
end

-- converts all edges to diagonals (stair effect)
function gTileFreeWalk:PathPoint_OptimizeForDiagonalMovement	()
	local l = self:PathPoint_Count()
	if l >= 3 then
		-- check for optimizations
		local k = 1
		repeat
			local x1,y1,z1 = self:PathPoint_GetNth(k)
			local x2,y2,z2 = self:PathPoint_GetNth(k+1)
			local x3,y3,z3 = self:PathPoint_GetNth(k+2)
			
			-- only try to remove points on the same z level
			if z1 == z2 and z2 == z3 then
				if self:PathPoint_IsStairPoint(x1,y1,x2,y2,x3,y3) then
					-- print("##### brotkrummen optimization -> remove",x1,y1,":",x2,y2,":",x3,y3)
					self:PathPoint_RemoveNth(k+1)
					l = l - 1
				end
			end
			
			k = k + 1
		until (l - k) < 2	-- no triple remaining
	end
end

-- ##### ##### ##### ##### ##### position and coordinate system conversions



function gTileFreeWalk:GetDistanceToLastConfirmedPos () 
	local x,y,z = self:GetPos_LastConfirmed()
	return Vector.len(Vector.sub(x,y,z,self:GetPos_ClientSide()))
end

-- returns x,y,z
function gTileFreeWalk:MousePickPos 		() 			return self:Impl_MousePickPos() end


function gTileFreeWalk:RoundPos	(x,y,z)
	local e,f,zscale = 0,0.5,10
	return math.floor(x+e)+f,math.floor(y+e)+f,math.floor(z*zscale)/zscale
end
function gTileFreeWalk:GetPos_ClientSide	()			return unpack(self.pos_clientside) end
function gTileFreeWalk:SetPos_ClientSide	(x,y,z)		self.pos_clientside = {x,y,z} end

function gTileFreeWalk:GetPos_LastConfirmed ()			return unpack(self.pos_lastconfirmed) end
function gTileFreeWalk:SetPos_LastConfirmed (x,y,z)		self.pos_lastconfirmed = {x,y,z} end

function gTileFreeWalk:GetPos_LastRequested ()			return unpack(self.pos_lastrequested) end
function gTileFreeWalk:SetPos_LastRequested (x,y,z)		self.pos_lastrequested = {x,y,z} end

-- used for teleport and init
function gTileFreeWalk:SetPos_All (xloc,yloc,zloc)	
	local x,y,z = self:UOPosToLocal(xloc,yloc,zloc)
	self:SetPos_ClientSide(		x,y,z)
	self:SetPos_LastConfirmed(	x,y,z)
	self:SetPos_LastRequested(	x,y,z)
	while (self:PathPoint_Count() > 0) do self:PathPoint_Pop() end
	self.pathpoints = {}
	self:UpdateGroundCache(xloc,yloc,zloc)   
end



-- ##### ##### ##### ##### ##### debug markers


		
function gTileFreeWalk:UpdateClientPosMarker ()
	local x,y,z = self:GetPos_ClientSide()
	if (gShowTileFreeDebug) then self:SetDebugMarker("GetPos_ClientSide", x,y,z, self.movedirx,self.movediry,0, 1,1,0) end
end

function gTileFreeWalk:DebugMarkerGroup_Clear (groupname)
	local myarr = self.debugmarkergroups[groupname]
	if (myarr) then for k,v in pairs(myarr) do v:Destroy() end self.debugmarkergroups[groupname] = nil end
end

function gTileFreeWalk:DebugMarkerGroup_AddGfx (groupname,gfx)
	local myarr = self.debugmarkergroups[groupname]
	if (not myarr) then myarr = {} self.debugmarkergroups[groupname] = myarr end
	table.insert(myarr,gfx)
end

function gTileFreeWalk:DebugMarkerGroup_AddSphere (groupname,x,y,z,fRad,r,g,b)
	local gfx = CreateRootGfx3D()
	gfx:SetMesh(MakeSphereMesh(11,11,fRad,fRad,fRad,r,g,b))	
	gfx:SetCastShadows(false)
	gfx:SetPosition(x,y,z)
	self:DebugMarkerGroup_AddGfx(groupname,gfx)
end

function gTileFreeWalk:DebugMarkerGroup_AddCylinder (groupname,x,y,z,fRad,fHeight,r,g,b)
	local gfx = CreateRootGfx3D()
	GfxSetCylinderZ(gfx,fRad,fHeight)
	gfx:SetMaterial(GetPlainColourMat(r,g,b))
	gfx:SetCastShadows(false)
	gfx:SetPosition(x,y,z)
	self:DebugMarkerGroup_AddGfx(groupname,gfx)
end

-- up=+z
function gTileFreeWalk:DebugMarkerGroup_AddWall (groupname,x1,y1,z1,x2,y2,z2,h,r,g,b)
	local gfx = CreateRootGfx3D()
	gfx:SetSimpleRenderable()
	gfx:RenderableBegin(4*2,6*2,false,false,OT_TRIANGLE_LIST)
	local vc = 0
	vc = DrawQuad(gfx,vc, x1,y1,z1, x2,y2,z2, x1,y1,z1+h, x2,y2,z2+h, 0,0, 1,0, 0,1, 1,1)
	vc = DrawQuad(gfx,vc, x1,y1,z1+h, x2,y2,z2+h, x1,y1,z1, x2,y2,z2, 0,0, 1,0, 0,1, 1,1)
	gfx:RenderableEnd()
	gfx:SetMaterial(GetPlainColourMat(r,g,b))
	gfx:SetCastShadows(false)
	self:DebugMarkerGroup_AddGfx(groupname,gfx)
end

function gTileFreeWalk:DelDebugMarker (markername)
	local mymarker = self.debugmarkers[markername]
	if (not mymarker) then return end
	self.debugmarkers[markername] = nil
	mymarker.gfx_big:Destroy()
	mymarker.gfx_dir:Destroy()
end

function gTileFreeWalk:SetDebugMarker (markername, x,y,z, dx,dy,dz, r,g,b)
	local mymarker = self.debugmarkers[markername]
	if (not mymarker) then mymarker = {} self.debugmarkers[markername] = mymarker end
	mymarker.data = {x,y,z, dx,dy,dz, r,g,b}
	self:UpdateDebugMarker(mymarker)
end

function gTileFreeWalk:UpdateDebugMarker (mymarker,matname)
	local x,y,z, dx,dy,dz, r,g,b = unpack(mymarker.data)
	if (not mymarker.gfx_big) then
		mymarker.gfx_big	= CreateRootGfx3D()
		mymarker.gfx_dir	= CreateRootGfx3D()
		mymarker.gfx_big:SetMesh(self.sDebugMarkerMeshName_Big)	
		mymarker.gfx_dir:SetMesh(self.sDebugMarkerMeshName_Dir)	
		mymarker.gfx_big:SetMeshSubEntityMaterial(0,GetPlainColourMat(r or 1,g or 1,b or 0))	
		mymarker.gfx_dir:SetMeshSubEntityMaterial(0,GetPlainColourMat(r or 1,g or 1,b or 0))	
		-- GetHuedMat("tilefreewalk_markerbase",r or 1,g or 1,b or 0)
	end
	if (dx ~= 0 or dy ~= 0 or dz ~= 0) then dx,dy,dz = Vector.normalise_to_len(dx,dy,dz,0.6) end
	mymarker.gfx_big:SetPosition(x,y,z)
	mymarker.gfx_dir:SetPosition(x+dx,y+dy,z+dz)
end

function SetAutoWalkTo (x, y, slow)
	slow = slow or false
	gWalkPathToGo = {{x=x,y=y,z=0}}
	gWalkPathToGoSlow = slow
end

gTileFreeWalk:PreInit()
