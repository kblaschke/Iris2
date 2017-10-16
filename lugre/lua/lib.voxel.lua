-- simple mesh voxel stuff

-- collects a list of intersections with the given triangles ltri and the ray from x,y,z with direction dx,dy,dz
-- return list element: {tri = {ax,ay,az, bx,by,bz, cx,cy,cz}, dist = dist}
-- ordered by distance from smallest to greatest
function VoxelMeshCalcTriIntersectList (ltri, x,y,z, dx,dy,dz)
	local l = {}
	
	for k,v in pairs(ltri) do
		local ax,ay,az, bx,by,bz, cx,cy,cz = unpack(v)
		
		dist = TriangleRayPick(ax,ay,az, bx,by,bz, cx,cy,cz, x,y,z, dx,dy,dz)
		
		if dist then
			table.insert(l,{tri = {ax,ay,az, bx,by,bz, cx,cy,cz}, dist = dist})
		end
	end
	
	table.sort(l, function(a,b)
		return a.dist < b.dist
	end)

	-- purge double/same distances
	local len = table.getn(l)
	local lastdist = nil
	for i = 1,len do
		if lastdist and l[i].dist - lastdist < 0.001 then
			l[i] = nil
		else
			lastdist = l[i].dist
		end
	end
	
	return l
end

function VoxelMeshKeyToPos(key)
	return unpack(strsplit("_",key))
end

function VoxelMeshKey (x,y,z)
	return x.."_"..y.."_"..z
end

-- dont call this directly
function VoxelMeshFromTo (grid, minx,miny,minz, maxx,maxy,maxz, cx,cy,cz, ax,ay,az, bx,by,bz, steps)
	-- print("VoxelMeshFromTo",grid, minx,miny,minz, maxx,maxy,maxz, cx,cy,cz, ax,ay,az, bx,by,bz, steps)
	local dx,dy,dz = Vector.sub(bx,by,bz, ax,ay,az)
	
	for i = 0,steps do
		-- calc relative position
		local rx,ry,rz = Vector.add(ax,ay,az, Vector.scalarmult(dx,dy,dz, i/steps))
		rx = (rx - minx) / (maxx-minx)
		ry = (ry - miny) / (maxy-miny)
		rz = (rz - minz) / (maxz-minz)
		
		if rx <= 1 and ry <= 1 and rz <= 1 and rx >= 0 and ry >= 0 and rz >= 0 then
			local vx,vy,vz = math.floor(rx * (cx-1)), math.floor(ry*(cy-1)), math.floor(rz*(cz-1))
			grid[VoxelMeshKey(vx,vy,vz)] = true
		end
	end
end

-- voxels along a given ray
-- dont call this directly
function VoxelMeshCalcRay (ltri, grid, minx,miny,minz, maxx,maxy,maxz, cx,cy,cz, x,y,z, dx,dy,dz, steps)
	-- print("VoxelMeshCalcRay",grid, cx,cy,cz, x,y,z, dx,dy,dz)
	local l = VoxelMeshCalcTriIntersectList(ltri, x,y,z, dx,dy,dz)
	
	local len = countarr(l)
	
	if math.fmod(len,2) == 0 and len > 1 then
		-- only voxel if hitcount is a multiple of 2
		
		local inside = false
		local last = nil
		
		if l then
			for k,v in pairs(l) do
				if inside == false then
					-- enter mesh
					inside = true
				elseif last then
					-- leave mesh to calc voxels
					-- enter pos
					local ax,ay,az = Vector.add(x,y,z, Vector.normalise_to_len(dx,dy,dz,last.dist))
					-- leave pos
					local bx,by,bz = Vector.add(x,y,z, Vector.normalise_to_len(dx,dy,dz,v.dist))
					
					VoxelMeshFromTo(grid, minx,miny,minz, maxx,maxy,maxz, cx,cy,cz, ax,ay,az, bx,by,bz, steps)
				end
				
				last = v
			end
		end
	
	end
end


-- voxels a mesh, cx,cy,cz is the voxel grid size
-- each mesh part must be closed
function VoxelMesh (meshname, cx,cy,cz)
	local ltri = {}
	
	-- voxel test
	local minx,miny,minz, maxx,maxy,maxz = IterateOverMeshTriangles(meshname, function(ax,ay,az, bx,by,bz, cx,cy,cz)
		table.insert(ltri, {ax,ay,az, bx,by,bz, cx,cy,cz})
	end)
	
	local grid = {}
	
	local steps = (math.max(cx,cy,cz) + 1)*3
	
	-- voxel in x direction
	local dx,dy,dz = 1,0,0

	for a = -1,steps+1 do
	for b = -1,steps+1 do
		local px = minx - 1
		local py = miny + (maxy-miny) * (a/steps)
		local pz = minz + (maxz-minz) * (b/steps)
		VoxelMeshCalcRay(ltri, grid, minx,miny,minz, maxx,maxy,maxz, cx,cy,cz, px,py,pz, dx,dy,dz, steps)
	end
	end
	
	--[[
	for k,v in pairs(grid) do
		print("GRID",k,v)
	end
	]]--

	return grid
end

-- obsolete, or at least unused
-- voxel-like mesh analysis, used for collision/interesection detection in shipeditor
-- fine grids generated from raw geometry
-- superseeded by shipvoxelgrid.lua

-- TODO : 2d voxel : 1,3, 1,5, 3,1, 3,7, 5,1, 5,7, 7,3, 7,5,  *e , e=1/8  -- a circle of points that is not hit by lines on a 1/2 grid

-- returns 3 dimensional array, zero based,  [xi][yi][zi] = 0 means outside, = 1 means inside
-- gfx must start at 0,0,0 and not go into negative coords
-- WARNING ! only works on simple (convex) forms
function CalcVoxelGrid (gfx,cx,cy,cz,gridsize)
	local g = gridsize or 1/4 -- gridsize
	local m = math.max(cx,cy,cz)
	local voxelgrid = {}
	for xi = 0,cx/g-1 do
		voxelgrid[xi] = {}
		for yi = 0,cy/g-1 do
			voxelgrid[xi][yi] = {}
			for zi = 0,cz/g-1 do
				-- ray-escape test along all axes
				-- if there one ray that does not hit any poly, the point must be outside
				local x,y,z = g/2 + g*xi,g/2 + g*yi,g/2 + g*zi
				voxelgrid[xi][yi][zi] = (	(not gfx:RayPick(x,y,z, m,0,0)) or 
											(not gfx:RayPick(x,y,z,-m,0,0)) or
											(not gfx:RayPick(x,y,z,0, m,0)) or
											(not gfx:RayPick(x,y,z,0,-m,0)) or
											(not gfx:RayPick(x,y,z,0,0, m)) or
											(not gfx:RayPick(x,y,z,0,0,-m)))  and  0  or   1
			end
		end
	end
	return voxelgrid
end

-- calls fun(voxelstate,x,y,z) with every voxel
-- the process is aborted and returns the first value of what fun returns if it is something other than nil
function ForEachVoxel (voxelgrid,fun)
	for xi,yarr in pairs(voxelgrid) do 
		for yi,zarr in pairs(yarr) do 
			for zi,state in pairs(zarr) do
				local res = fun(state,xi,yi,zi)
				if (res ~= nil) then return res end
			end
		end
	end
end

-- returns a new voxel grid
-- sx,sy,sz should be integers (e.g. mirrors, or scale by two)
-- qw,qx,qy,qz should be an orthogonal rotation (e.g. 90 degrees to the right,...)
function TransformVoxelGrid (voxelgrid, px,py,pz, qw,qx,qy,qz, sx,sy,sz, gridsize)
	local g = gridsize or 1/4 -- gridsize
	local res = {}
	ForEachVoxel(voxelgrid,function (state,x,y,z) 
			x,y,z = x*sx,y*sy,z*sz
			x,y,z = Quaternion.ApplyToVector(x,y,z,qw,qx,qy,qz) 
			x,y,z = px/g + x,py/g + y,pz/g + z
			res[x] = res[x] or {}
			res[x][y] = res[x][y] or {}
			res[x][y][z] = state
		end)
	return res	
end

-- compares two voxel grids and returns true if they intersect
function VoxelGridIntersection (voxelgrid1,voxelgrid2)
	return ForEachVoxel(voxelgrid1,function (state,x,y,z) 
		if (state == 1 and voxelgrid2[x] and voxelgrid2[x][y] and voxelgrid2[x][y][z] == 1) then return true end
	end)
end 

-- creates and returns returns array of (green) billboard gfx for every voxel "inside"
function DrawVoxelGrid (voxelgrid,parentgfx,gridsize)
	local g = gridsize or 1/4 -- gridsize
	local res = {}
	ForEachVoxel(voxelgrid,function (state,xi,yi,zi) 
		if (state == 1) then
			local gfx = parentgfx and parentgfx:CreateChild() or CreateRootGfx3D()
			local x,y,z = xi*g+g/2,yi*g+g/2,zi*g+g/2
			gfx:SetBillboard(x,y,z,g/4,GetPlainColourMat(0,1,0)) 
			table.insert(res,gfx)
		end
		end)
	return res
end


--[[
OBSOLETE, did not work correctly, to many rounding errors on RayPickList
-- ray must be padded with gridsize at the start and at the end to avoid rounding errors
-- returns voxel-cells along ray, arr[zi] (where 0 <= zi < numcells) (2 means border, 0 means outside, 1 means inside)
function GfxVoxelLine (gfx, gridsize,numcells, rx,ry,rz,rvx,rvy,rvz)
	local raylen = Vector.len(rvx,rvy,rvz)
	local hits = gfx:RayPickList(rx,ry,rz,rvx,rvy,rvz) -- table{facenum=dist,...}
	
	-- round hitlist to cells
	local cellhits = {}
	local mincell = 0
	local maxcell = numcells-1
	for facenum,dist in pairs(hits) do 
		local cell = math.floor((dist*raylen - gridsize) / gridsize)
		cellhits[cell] = (cellhits[cell] or 0) + 1
		if (cell < mincell) then mincell = cell end
		if (cell > maxcell) then maxcell = cell end
	end
	
	-- determine inside and outside
	local res = {}
	local outside = true
	for i = mincell,maxcell do
		local border = (cellhits[i] or 0) ~= 0
		if (math.fmod(cellhits[i] or 0,2) == 1) then outside = (not outside) end
		--print("cell",i,border,outside)
		if (i >= 0 and i < numcells) then res[i] = border and 2 or (outside and 0 or 1) end
	end
	
	return res
end
]]--
