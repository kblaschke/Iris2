-- utils for mousepicking and mesh construction of prisms




-- segments=23,xrad=1,yrad=1,startang=0,endang=pi
-- returns zero-based table with segments+1 entries
function GenerateEllipse (segments,xrad,yrad,startang)
	local res = {}
	segments = segments or 23
	startang = startang or 0
	for i = 0,segments do
		local ang = startang + ((i < segments) and (2*kPi*i/segments) or 0)
		res[i] = {(xrad or 1)*math.sin(ang),(yrad or 1)*math.cos(ang)}
	end
	return res
end

-- for n<2 returns zero-based-array of points where element at index 0 is the middle
-- for n>=2 returns x1,y1,z1, x2,y2,z2, x3,y3,z3, x4,y4,z4
-- circledata is optional to increase performance by only generating it once
function GetNGonSideCoords (sidenum,n,h,rad1,rad2,circledata)
	circledata = circledata or GenerateEllipse(n)
	if (sidenum < 2) then
		local z = (sidenum == 0) and 0 or h
		local r = (sidenum == 0) and rad1 or rad2
		local res = {}
		res[0] = {0,0,z}
		for i=0,n do 
			local x,y = unpack(circledata[i])
			res[((sidenum == 0) and i or (n-i))+1] = {r*x,r*y,z}
		end
		return res
	end
	assert(sidenum < n+2," illegal sidenum "..sidenum.." < "..n.."+2 (sidenum 0 = bottom, sidenum 1 = top)")
	local i = sidenum - 2
	local xa,ya = unpack(circledata[i])
	local xb,yb = unpack(circledata[i+1])
	return rad2*xa,rad2*ya,h, rad1*xa,rad1*ya,0, rad2*xb,rad2*yb,h, rad1*xb,rad1*yb,0
end

-- returns nx,ny,nz
function GetNGonSideNormal (sidenum,n,h,rad1,rad2,circledata)
	if (sidenum == 0) then return 0,0,-1 end -- top
	if (sidenum == 1) then return 0,0,1 end -- bottom
	local x1,y1,z1, x2,y2,z2, x3,y3,z3, x4,y4,z4 = GetNGonSideCoords(sidenum,n,h,rad1,rad2,circledata)
	return Vector.normalise(Vector.cross(x3-x1,y3-y1,z3-z1,x2-x1,y2-y1,z2-z1)) -- todo : check if orientation is correct ?
end

function GetNGonSideMiddle (sidenum,n,h,rad1,rad2,circledata)
	if (sidenum == 0) then return 0,0,0 end -- top
	if (sidenum == 1) then return 0,0,h end -- bottom
	local x1,y1,z1, x2,y2,z2, x3,y3,z3, x4,y4,z4 = GetNGonSideCoords(sidenum,n,h,rad1,rad2,circledata)
	return 0.5*(x1+x4),0.5*(y1+y4),0.5*(z1+z4)
end

-- only works correctly for even n
function GetNGonOppositeSide (sidenum,n)
	if (sidenum == 0) then return 1 end
	if (sidenum == 1) then return 0 end
	local i = sidenum - 2 -- [0,n-1]
	return 2 + math.fmod(i+math.floor(n/2),n)
end

-- sides is an array containing sidenumbers to be drawn, defaults to all
-- params gfx,n,h=1,rad1=1,rad2=1
function GfxSetNGonPrism (gfx,n,h,rad1,rad2) 
	h = h or 1
	rad1 = rad1 or 1
	rad2 = rad2 or 1
	gfx:SetSimpleRenderable()
	gfx:RenderableBegin((2 + n)*2 + n*4,3*(n)*2 + 6*n,false,false,OT_TRIANGLE_LIST)
	
	local circledata = GenerateEllipse(n)
	local vc = 0 -- vertexcount
	
	-- bottom cap z=0 
	for sidenum = 0,1 do
		local nx,ny,nz	= GetNGonSideNormal(sidenum,n,h,rad1,rad2,circledata)
		local arr		= GetNGonSideCoords(sidenum,n,h,rad1,rad2,circledata)
		local x,y,z = unpack(arr[0])
		gfx:RenderableVertex(x,y,z, nx,ny,nz, 0.5,0.5)
		for i=0,n do 
			x,y,z = unpack(arr[i+1])
			gfx:RenderableVertex(x,y,z, nx,ny,nz, math.fmod(i,2),0)
			if (i<n) then gfx:RenderableIndex3(vc,vc + 1 + i,vc + 2 + i) end
		end
		vc = vc + n + 2
	end
	
	-- sides
	for sidenum = 2,n+2 - 1 do
		x1,y1,z1, x2,y2,z2, x3,y3,z3, x4,y4,z4 = GetNGonSideCoords(sidenum,n,h,rad1,rad2,circledata)
		DrawQuad(gfx,vc, x1,y1,z1, x2,y2,z2, x3,y3,z3, x4,y4,z4, 0,1, 0,0, 1,1, 1,0)
		vc = vc + 4
	end
	
	gfx:RenderableEnd()
end

-- returns dist, or nil if not hit
function RayPickFace4 (		x1,y1,z1, x2,y2,z2, x3,y3,z3, x4,y4,z4, x,y,z, rx,ry,rz, rvx,rvy,rvz) 
	return	TriangleRayPick(x1,y1,z1, x2,y2,z2, x3,y3,z3, 			rx-x,ry-y,rz-z,  rvx,rvy,rvz) or
			TriangleRayPick(x4,y4,z4, x2,y2,z2, x3,y3,z3, 			rx-x,ry-y,rz-z,  rvx,rvy,rvz)
end

function RayPickNGonSide (sidenum, n,h,rad1,rad2,  x,y,z, rx,ry,rz, rvx,rvy,rvz, circledata) 
	if (sidenum < 2) then
		local arr = GetNGonSideCoords(sidenum,n,h,rad1,rad2,circledata)
		local x3,y3,z3 = unpack(arr[0])
		local dist
		for i=0,n-1 do 
			x1,y1,z1 = unpack(arr[i+1])
			x2,y2,z2 = unpack(arr[i+2])
			dist = TriangleRayPick(x1,y1,z1, x2,y2,z2, x3,y3,z3, rx-x,ry-y,rz-z, rvx,rvy,rvz)
			if (dist) then return dist end
		end
		return
	end
	local 				x1,y1,z1, x2,y2,z2, x3,y3,z3, x4,y4,z4 = GetNGonSideCoords(sidenum,n,h,rad1,rad2,circledata)
	return RayPickFace4(x1,y1,z1, x2,y2,z2, x3,y3,z3, x4,y4,z4, x,y,z, rx,ry,rz, rvx,rvy,rvz)
end

-- 0,0,0 is top,left,front corner
-- returns minside,dist  , nil if not hit
function RayPickNGon (n,h,rad1,rad2, x,y,z, rx,ry,rz, rvx,rvy,rvz) 
	local mindist,minside,curdist
	local circledata = GenerateEllipse(n)
	for sidenum = 0,n+2 - 1 do 
		curdist = RayPickNGonSide(sidenum, n,h,rad1,rad2, x,y,z, rx,ry,rz, rvx,rvy,rvz, circledata)
		if (curdist and ((not mindist) or (curdist < mindist))) then
			mindist = curdist
			minside = sidenum
		end
	end
	return minside,mindist
end



