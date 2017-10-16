-- code for generating some standard primitives
-- see also lib.prism.lua and lib.box.lua
-- geometry-sides are given as arrays of vertex coordinates, 3*3 coords mean a triangle, 4*3 mean a quad


kTexCoords_Box0 = ArrayRepeat({0,0, 0,1, 1,0, 1,1},6) -- simple box, all sides have the same texture

kGeomBox = {
	{0,0,0, 0,1,0, 0,0,1,  0,1,1,},  -- left
	{1,1,1, 1,1,0, 1,0,1,  1,0,0,},  -- right b
	{1,0,1, 1,0,0, 0,0,1,  0,0,0,},  -- top b
	{0,1,0, 1,1,0, 0,1,1,  1,1,1,},  -- bottom
	{0,0,0, 1,0,0, 0,1,0,  1,1,0,},  -- front
	{1,1,1, 1,0,1, 0,1,1,  0,0,1,},  -- back b
	}

kGeomRamp = {
	{0,0,0, 0,1,0, 0,0,1,}, 		 -- left  tri
	{1,0,0, 1,0,1, 1,1,0,},  		 -- right tri
	{0,1,0, 1,1,0, 0,0,1, 1,0,1,},	 -- window rect
	{1,0,1, 1,0,0, 0,0,1, 0,0,0,},	 -- long   rect
	{0,0,0, 1,0,0, 0,1,0, 1,1,0,},	 -- short  rect
	}

kGeomPyramid = {
	{0,0,0, 1,0,0, 0,1,0,}, -- base
	{0,0,0, 0,1,0, 0,0,1,},
	{0,0,0, 0,0,1, 1,0,0,},
	{0,0,1, 0,1,0, 1,0,0,},
	}
	
-- TODO kGeomQTAdapter : quadratic base to triangle top, one side cut, 1+2 quads, 1+3 tris

-- the facenum returned from gfx:RayPick,... is zero based, but can be used to determine the "side"
-- returns one-based index in geom
function GeomFaceNumToSideNum (geom,facenum)
	local ic = 0
	local startindex = facenum*3
	for k,arr in pairs(geom) do 
		ic = ic + GeomSideGetIndexCount(arr)
		if (startindex < ic) then return k end
	end
end	

-- returns array of vertices, sidenum is one-based index
function GeomGetSide (geom,sidenum) return geom[sidenum] end

-- geomside = geom[one_based_index]
function GeomSideIsQuad (geomside) return table.getn(geomside) == 4*3 end
function GeomSideGetIndexCount (geomside) return GeomSideIsQuad(geomside) and 6 or 3 end
function GeomSideGetVertexCount (geomside) return GeomSideIsQuad(geomside) and 4 or 3 end

-- returns nx,ny,nz
function GeomSideGetNormal (geomside)
	local x1,y1,z1, x2,y2,z2, x3,y3,z3 = unpack(geomside) -- works for tri and quad
	return Vector.normalise(Vector.cross(x3-x1,y3-y1,z3-z1,x2-x1,y2-y1,z2-z1))
end

-- checks if a side is parallel to a border of an axis aligned box
function GeomSideIsAxisAligned (geomside) return NormalIsAxisAligned(GeomSideGetNormal(geomside)) end

function GeomGetAxisAlignedSides (geom) 
	local res = {}
	for k,geomside in pairs(geom) do 
		if (GeomSideIsAxisAligned(geomside)) then table.insert(res,geomside) end
	end
	return res
end

-- returns w,h
function GeomSideCalcDim (geomside) 
	local x1,y1,z1, x2,y2,z2, x3,y3,z3, x4,y4,z4 = unpack(geomside)
	return Vector.len(x2-x1,y2-y1,z2-z2),Vector.len(x3-x1,y3-y1,z3-z3)
end

-- returns surface area
function GeomSideCalcArea (geomside) 
	local w,h = GeomSideCalcDim(geomside)
	return (GeomSideIsQuad(geomside) and 1 or 0.5) * w * h
end



-- changes the vertex order so that culling and normals are inverted 
function GeomInvert (geom)
	local res = {}
	for k,arr in pairs(geom) do 
		local x1,y1,z1, x2,y2,z2, x3,y3,z3, x4,y4,z4 = unpack(arr)
		res[k] = {x1,y1,z1, x3,y3,z3, x2,y2,z2, x4,y4,z4}  -- works for tri and quad
	end
	return res
end


-- returns a meshname, cached
gMakeSphereMeshCache = {}
function MakeSphereMesh (steps_h,steps_v,cx,cy,cz,r,g,b) 
	cy = cy or cx
	cz = cz or cx
	r = r or 1
	g = g or 1
	b = b or 1
	local cachename = steps_h..","..steps_v..","..cx..","..cy..","..cz..","..r..","..g..","..b
	local cache = gMakeSphereMeshCache[cachename] 
	if (cache) then return cache end
	local meshgengfx = CreateGfx3D()
	GfxSetSphere(meshgengfx,cx,cy or cx,cz or cx,steps_h,steps_v)
	meshgengfx:SetMaterial(GetPlainColourMat(r,g,b))
	local res = meshgengfx:RenderableConvertToMesh()
	meshgengfx:Destroy()
	return WriteToCache(gMakeSphereMeshCache,cachename,res)
end
		
-- creates a SimpleRenderable , a cylinder arount the z axis from 0,0,0 to 0,0,h with radius r
function GfxSetCylinderZ (gfx,r,h,steps)
	steps = steps or 11

	gfx:SetSimpleRenderable()
	local vc = (steps+1)*2
	local ic = (steps)*6
	gfx:RenderableBegin(vc,ic,false,false,OT_TRIANGLE_LIST)
	
	for v = 0,steps do
		local t = v/steps
		local x = math.cos(t*math.pi*2)
		local y = math.sin(t*math.pi*2)
		gfx:RenderableVertex(x*r,y*r,0, x,y,0, t,0)
		gfx:RenderableVertex(x*r,y*r,h, x,y,0, t,1)
	end
	for v = 0,steps-1 do
		local i = v*2
		gfx:RenderableIndex3(i+0,i+2,i+1)
		gfx:RenderableIndex3(i+3,i+1,i+2)
	end
	gfx:RenderableEnd()
end
 
-- creates a SimpleRenderable
function GfxSetSphere (gfx,cx,cy,cz,steps_h,steps_v) 
	cy = cy or cx
	cz = cz or cx
	steps_h = steps_h or 23
	steps_v = steps_v or 11
	
	gfx:SetSimpleRenderable()
	local vc = (steps_v+1)*(steps_h+1)
	local ic = (steps_v)*(steps_h)*6
	gfx:RenderableBegin(vc,ic,bDynamic or false,false,OT_TRIANGLE_LIST)
	
	for v = 0,steps_v do
		local vt = v/steps_v
		local y = math.cos(vt*math.pi*1)
		local r = math.sin(vt*math.pi*1)
		for h = 0,steps_h do
			local ht = h/steps_h
			local x = math.sin(ht*math.pi*2) * r
			local z = math.cos(ht*math.pi*2) * r
			gfx:RenderableVertex(x*cx,y*cy,z*cz,x,y,z,ht,vt)
		end
	end
	
	local h = (steps_h+1) -- vc_per_row
	local a0 = 0
	local a1 = 1
	local a2 = 0+h
	local a3 = 1+h
	
	for v = 0,steps_v-1 do
		local vc = v * h
		for h = 0,steps_h-1 do
			gfx:RenderableIndex3(vc+a0,vc+a2,vc+a1)
			gfx:RenderableIndex3(vc+a1,vc+a2,vc+a3)
			vc = vc + 1
		end
	end
	gfx:RenderableEnd()
end

-- creates a SimpleRenderable
function GfxSetGeom (gfx,geom,texcoords,cx,cy,cz,bDynamic) 
	gfx:SetSimpleRenderable()
	local vc,ic = 0,0
	for k,arr in pairs(geom) do 
		vc = vc + GeomSideGetVertexCount(arr)
		ic = ic + GeomSideGetIndexCount(arr)
	end
	gfx:RenderableBegin(vc,ic,bDynamic or false,false,OT_TRIANGLE_LIST)
	vc = 0
	for k,arr in pairs(geom) do 
		local x1,y1,z1, x2,y2,z2, x3,y3,z3, x4,y4,z4 = unpack(arr)
		if (GeomSideIsQuad(arr)) then 
			vc = DrawQuad(gfx,vc, x1*cx,y1*cy,z1*cz, x2*cx,y2*cy,z2*cz, x3*cx,y3*cy,z3*cz, x4*cx,y4*cy,z4*cz, unpack(texcoords[k]))
		else 
			vc = DrawTri(gfx,vc,  x1*cx,y1*cy,z1*cz, x2*cx,y2*cy,z2*cz, x3*cx,y3*cy,z3*cz, unpack(texcoords[k]))
		end
	end
	gfx:RenderableEnd()
end
