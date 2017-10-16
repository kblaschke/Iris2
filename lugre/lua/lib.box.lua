-- utils for mousepicking and mesh construction of axis aligned boxes

-- local rx,ry,rz,rvx,rvy,rvz = GetMouseRay()
-- dist = TriangleRayPick(ax,ay,az, bx,by,bz, cx,cy,cz, rx,ry,rz, rvx,rvy,rvz)   nil if not hit

--[[
	sidenum == 0 -- left
	sidenum == 1 -- right
	sidenum == 2 -- top
	sidenum == 3 -- bottom
	sidenum == 4 -- front
	sidenum == 5 -- back
	
	faces=sides : 6
	triangles : 2 per face = 12
	edges : 8   (but 4*4 vertices due to face normals)
]]--

-- returns x1,y1,z1, x2,y2,z2, x3,y3,z3, x4,y4,z4
function GetBoxSideCoords (sidenum,cx,cy,cz, tx, ty, tz) 
	tx = tx or 0
	ty = ty or 0
	tz = tz or 0
		if (sidenum == 0) then return  0+tx, 0+ty, 0+tz,   0+tx,cy+ty, 0+tz,   0+tx, 0+ty,cz+tz,   0+tx,cy+ty,cz+tz -- left
	elseif (sidenum == 1) then return cx+tx,cy+ty,cz+tz,  cx+tx,cy+ty, 0+tz,  cx+tx, 0+ty,cz+tz,  cx+tx, 0+ty, 0+tz -- right b
	elseif (sidenum == 2) then return cx+tx, 0+ty,cz+tz,  cx+tx, 0+ty, 0+tz,   0+tx, 0+ty,cz+tz,   0+tx, 0+ty, 0+tz -- top b
	elseif (sidenum == 3) then return  0+tx,cy+ty, 0+tz,  cx+tx,cy+ty, 0+tz,   0+tx,cy+ty,cz+tz,  cx+tx,cy+ty,cz+tz -- bottom
	elseif (sidenum == 4) then return  0+tx, 0+ty, 0+tz,  cx+tx, 0+ty, 0+tz,   0+tx,cy+ty, 0+tz,  cx+tx,cy+ty, 0+tz -- front
	elseif (sidenum == 5) then return cx+tx,cy+ty,cz+tz,  cx+tx, 0+ty,cz+tz,   0+tx,cy+ty,cz+tz,   0+tx, 0+ty,cz+tz -- back b
	end
end

-- returns nx,ny,nz
function GetBoxSideNormal (sidenum)
		if (sidenum == 0) then return -1, 0, 0 -- left
	elseif (sidenum == 1) then return  1, 0, 0 -- right
	elseif (sidenum == 2) then return  0,-1, 0 -- top
	elseif (sidenum == 3) then return  0, 1, 0 -- bottom
	elseif (sidenum == 4) then return  0, 0,-1 -- front
	elseif (sidenum == 5) then return  0, 0, 1 -- back
	end
end

function DrawBoxSide (sidenum,gfx, cx,cy,cz, vc, texcoords, tx, ty, tz)	
	tx = tx or 0
	ty = ty or 0
	tz = tz or 0
	local nx,ny,nz = GetBoxSideNormal(sidenum)
	local x1,y1,z1, x2,y2,z2, x3,y3,z3, x4,y4,z4 = GetBoxSideCoords(sidenum,cx,cy,cz, tx, ty, tz)
	gfx:RenderableVertex(x1,y1,z1,nx,ny,nz,texcoords[1],texcoords[2])
	gfx:RenderableVertex(x2,y2,z2,nx,ny,nz,texcoords[3],texcoords[4])
	gfx:RenderableVertex(x3,y3,z3,nx,ny,nz,texcoords[5],texcoords[6])
	gfx:RenderableVertex(x4,y4,z4,nx,ny,nz,texcoords[7],texcoords[8])
	gfx:RenderableIndex3(vc+2,vc+1,vc+0)
	gfx:RenderableIndex3(vc+3,vc+1,vc+2)
end

-- sides is an array containing sidenumbers to be drawn, defaults to all
-- param sides defaults to {0,1,2,3,4,5} = all sides
-- param texcoords defaults to { {0,0, 0,1, 1,0, 1,1} repeated 6 times }
-- param texcoords is one based
-- translates the box along tx,ty,tz
function GfxSetBox (gfx,cx,cy,cz,sides, texcoords, tx, ty, tz) 
	gfx:SetSimpleRenderable()
	sides = sides or {0,1,2,3,4,5}
	tx = tx or 0
	ty = ty or 0
	tz = tz or 0
	texcoords = texcoords or ArrayRepeat({0,0, 0,1, 1,0, 1,1},6)
	local sidecount = table.getn(sides)
	gfx:RenderableBegin(4*sidecount,6*sidecount,false,false,OT_TRIANGLE_LIST)
	local vc = 0
	for k,sidenum in pairs(sides) do DrawBoxSide(sidenum,gfx, cx,cy,cz, vc, texcoords[sidenum+1], tx, ty, tz) vc = vc+4 end
	gfx:RenderableEnd()
end


-- 0,0,0 is top,left,front corner
function RayPickAABoxSide (sidenum, x,y,z, cx,cy,cz, rx,ry,rz, rvx,rvy,rvz) 
	local x1,y1,z1, x2,y2,z2, x3,y3,z3, x4,y4,z4 = GetBoxSideCoords(sidenum,cx,cy,cz)
	return	TriangleRayPick(x1,y1,z1, x2,y2,z2, x3,y3,z3, rx-x,ry-y,rz-z, rvx,rvy,rvz) or
			TriangleRayPick(x4,y4,z4, x2,y2,z2, x3,y3,z3, rx-x,ry-y,rz-z, rvx,rvy,rvz)
end

-- 0,0,0 is top,left,front corner
-- returns minside,dist  , nil if not hit
function RayPickAABox (x,y,z, cx,cy,cz, rx,ry,rz, rvx,rvy,rvz) 
	local mindist,minside,curdist
	for sidenum = 0,5 do 
		curdist = RayPickAABoxSide(sidenum, x,y,z, cx,cy,cz, rx,ry,rz, rvx,rvy,rvz)
		if (curdist and ((not mindist) or (curdist < mindist))) then
			mindist = curdist
			minside = sidenum
		end
	end
	return minside,mindist
end
