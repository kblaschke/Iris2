-- utils for working with beam 

function MakeColourfulBeamCube (e,h)
	local gfx = CreateRootGfx3D()
	gfx:SetBeam(true)
	local iLine = gfx:BeamAddLine()
	--local u1,u2 = 0.5,0.5
	local u1,u2 = 0,1
	h = h or 5
	e = e or 100
	local r,g,b
	local a=1
	r,g,b = 1,0,0 BeamSingleLineStep(gfx,iLine, e, e, e,-h,h,u1,u1,0,1 , r,g,b,a, r,g,b,a) -- red 
	r,g,b = 1,1,0 BeamSingleLineStep(gfx,iLine,-e, e, e,-h,h,u2,u2,0,1 , r,g,b,a, r,g,b,a) -- yellow 
	r,g,b = 0,1,0 BeamSingleLineStep(gfx,iLine,-e,-e, e,-h,h,u1,u1,0,1 , r,g,b,a, r,g,b,a) -- green 
	r,g,b = 0,1,1 BeamSingleLineStep(gfx,iLine, e,-e, e,-h,h,u2,u2,0,1 , r,g,b,a, r,g,b,a) -- cyan 
	r,g,b = 1,0,0 BeamSingleLineStep(gfx,iLine, e, e, e,-h,h,u1,u1,0,1 , r,g,b,a, r,g,b,a) -- red 
	
	r,g,b = 0,0,1 BeamSingleLineStep(gfx,iLine, e, e,-e,-h,h,u2,u2,0,1 , r,g,b,a, r,g,b,a) -- blue
	r,g,b = 1,0,1 BeamSingleLineStep(gfx,iLine,-e, e,-e,-h,h,u1,u1,0,1 , r,g,b,a, r,g,b,a) -- magenta 
	r,g,b = 1,0,0 BeamSingleLineStep(gfx,iLine,-e,-e,-e,-h,h,u2,u2,0,1 , r,g,b,a, r,g,b,a) -- red 
	r,g,b = 1,1,0 BeamSingleLineStep(gfx,iLine, e,-e,-e,-h,h,u1,u1,0,1 , r,g,b,a, r,g,b,a) -- yellow 
	r,g,b = 0,0,1 BeamSingleLineStep(gfx,iLine, e, e,-e,-h,h,u2,u2,0,1 , r,g,b,a, r,g,b,a) -- blue 
	
	BeamSingleLine(gfx,-e, e, e,  -e, e,-e,  -h,h,-h,h,u1,u1,u2,u2,0,1,0,1, 1,1,0,1  ,1,0,1,1 )
	BeamSingleLine(gfx,-e,-e, e,  -e,-e,-e,  -h,h,-h,h,u1,u1,u2,u2,0,1,0,1, 0,1,0,1  ,1,0,0,1 )
	BeamSingleLine(gfx, e,-e, e,   e,-e,-e,  -h,h,-h,h,u1,u1,u2,u2,0,1,0,1, 0,1,1,1  ,1,1,0,1 )
	
	gfx:SetMaterial("beam")
	gfx:BeamUpdateBounds()
	return gfx
end

function SetBeamBox (gfx, h, cx,cy,cz, r,g,b,a) 
	local x,y,z = cx,cy,cz
	gfx:SetBeam(true)
	
	BeamSingleLine(gfx, 0,0,0, x,0,0, -h,h,-h,h, 0,0,1,1,0,1,0,1, r,g,b,a, r,g,b,a)
	BeamSingleLine(gfx, 0,0,0, 0,y,0, -h,h,-h,h, 0,0,1,1,0,1,0,1, r,g,b,a, r,g,b,a)
	BeamSingleLine(gfx, 0,0,0, 0,0,z, -h,h,-h,h, 0,0,1,1,0,1,0,1, r,g,b,a, r,g,b,a)
	
	BeamSingleLine(gfx, x,0,0, x,y,0, -h,h,-h,h, 0,0,1,1,0,1,0,1, r,g,b,a, r,g,b,a)
	BeamSingleLine(gfx, x,0,0, x,0,z, -h,h,-h,h, 0,0,1,1,0,1,0,1, r,g,b,a, r,g,b,a)
	
	BeamSingleLine(gfx, 0,y,0, x,y,0, -h,h,-h,h, 0,0,1,1,0,1,0,1, r,g,b,a, r,g,b,a)
	BeamSingleLine(gfx, 0,y,0, 0,y,z, -h,h,-h,h, 0,0,1,1,0,1,0,1, r,g,b,a, r,g,b,a)
	
	BeamSingleLine(gfx, 0,0,z, x,0,z, -h,h,-h,h, 0,0,1,1,0,1,0,1, r,g,b,a, r,g,b,a)
	BeamSingleLine(gfx, 0,0,z, 0,y,z, -h,h,-h,h, 0,0,1,1,0,1,0,1, r,g,b,a, r,g,b,a)
	
	BeamSingleLine(gfx, x,y,z, 0,y,z, -h,h,-h,h, 0,0,1,1,0,1,0,1, r,g,b,a, r,g,b,a)
	BeamSingleLine(gfx, x,y,z, x,0,z, -h,h,-h,h, 0,0,1,1,0,1,0,1, r,g,b,a, r,g,b,a)
	BeamSingleLine(gfx, x,y,z, x,y,0, -h,h,-h,h, 0,0,1,1,0,1,0,1, r,g,b,a, r,g,b,a)
	
	gfx:SetMaterial("beam")
	gfx:BeamUpdateBounds()
end

function BeamSingleLine (gfx,x1,y1,z1,x2,y2,z2,h1,h2,h3,h4,u1,u2,u3,u4,v1,v2,v3,v4,r1,g1,b1,a1,r2,g2,b2,a2)
	local iLine = gfx:BeamAddLine()
	gfx:BeamAddPoint(iLine,x1,y1,z1,h1,h2,u1,u2,v1,v2,r1,g1,b1,a1,r1,g1,b1,a1)
	gfx:BeamAddPoint(iLine,x2,y2,z2,h3,h4,u3,u4,v3,v4,r2,g2,b2,a2,r2,g2,b2,a2)
end

function BeamSingleLineStep (gfx,...)
	gfx:BeamAddPoint(...)
	local iLine = gfx:BeamAddLine()
	arg[0] = iLine
	gfx:BeamAddPoint(...)
end

