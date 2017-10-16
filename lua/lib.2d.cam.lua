-- ortho cam


Renderer2D.fCamPosXLoc = 0
Renderer2D.fCamPosYLoc = 0
Renderer2D.fCamPosZLoc = 0
Renderer2D.fCamDistClipAdd = 300

function Renderer2D:CamTestTile ()
	-- create water
	local gfx = CreateRootGfx3D()
	local vc = 4
	local ic = 6 * 2

	gfx:SetSimpleRenderable()
	gfx:RenderableBegin(vc,ic,false,false,OT_TRIANGLE_LIST)

	-- print("DEBUG","WATERSTART",count,vc,ic)
	local x,y,z = 0,0,0
	
	local w,h = 3,4
	gfx:RenderableVertex(-x  ,y  ,z, 0,0,1, 0,0)
	gfx:RenderableVertex(-x-w,y  ,z, 0,0,1, w,0)
	gfx:RenderableVertex(-x  ,y+h,z, 0,0,1, 0,h)
	gfx:RenderableVertex(-x-w,y+h,z, 0,0,1, w,h)
	
	gfx:RenderableIndex3(0, 1, 2)
	gfx:RenderableIndex3(1, 3, 2)
	gfx:RenderableIndex3(0, 2, 1)
	gfx:RenderableIndex3(1, 2, 3)

	gfx:RenderableEnd()

	local mat = GetPlainTextureMat("terrain1_mosa02.png")
	--~ gfx:SetMaterial("BaseWhiteNoLighting")
	--~ gfx:SetMaterial("water")
	gfx:SetMaterial(mat)
end


-- updates aspect ratio, zoom etc
function Renderer2D:CamUpdateParams ()
	local cam = GetMainCam() 
	local vp = GetMainViewport()
	local viewport_w = vp:GetActualWidth()
	local viewport_h = vp:GetActualHeight()
	
	local yscale = 1.0 / math.sin(0.25*math.pi) -- uo tiles are quadratic in iso, but would be y~0.7~sin(45 deg)
	local tile_h = 44  -- 44x44 pixels on screen, but rotated by 45 degree (diag=44.. but worldunit rotated as well) -> 44
	local visible_h = viewport_h / tile_h -- coordinate system so that size of 1 tile = 1 world unit
	
	
	self.fNearClip = 0.5 * visible_h
	self.fCamDist = self.fNearClip + self.fCamDistClipAdd
	
	cam:SetNearClipDistance( self.fNearClip )
	cam:SetFarClipDistance( self.fNearClip + 500 )
	local aspectratio = yscale * viewport_w / viewport_h
	--~ local ortho_w = viewport_w
	--~ local ortho_h = viewport_h / yscale
	--~ local aspectratio = ortho_w / ortho_h
	local ortho_h = visible_h
	local ortho_w = aspectratio * ortho_h
	self.ortho_h = ortho_h 
	self.ortho_w = ortho_w
	
	cam:SetAspectRatio( aspectratio )
	--~ cam:SetOrthoWindow(viewport_w,viewport_h)
	local zoom = self.mfZoomFactor or 1
	cam:SetOrthoWindow(ortho_w * zoom,ortho_h * zoom)
	
	--[[
		void Frustum::setOrthoWindow(Real w, Real h)
			mOrthoHeight = h;
			mAspect = w / h;
			
		void Frustum::setOrthoWindowWidth(Real w)
			mOrthoHeight = w / mAspect;
			
		void Frustum::setAspectRatio(Real r)
			mAspect = r;
	]]--
	
	self:SetCamPos(self:GetCamPos()) -- nearclip changed
end

function Renderer2D:SetZoom (f)
	f = max(0.1,f)
	print("Renderer2D:SetZoom",f)
	self.mfZoomFactor = f
	self:CamUpdateParams()
end


function Renderer2D:CamChangeZoom				(f)
	self.zoomaddsum = (self.zoomaddsum or 0) + f/0.3
	--~ print("CamChangeZoom",f)
	self:SetZoom(math.pow(2,self.zoomaddsum/2))
end

function Renderer2D:CamInit ()
	--~ self:CamTestTile()
	
	-- cam params that don't change
	local cam = GetMainCam() 
	--~ cam:SetFarClipDistance( 100000.0 )
	cam:SetProjectionType(kCamera_PT_ORTHOGRAPHIC)
	--~ cam:SetFOVy( gfDeg2Rad*90 )
	
	
	-- cam rotation
	local xang = gfDeg2Rad * (45) 
	local zang = gfDeg2Rad * (45+180)
	local w1,x1,y1,z1 = Quaternion.fromAngleAxis(zang,0,0,1)	
	local w2,x2,y2,z2 = Quaternion.fromAngleAxis(xang,1,0,0)	
	local w,x,y,z = Quaternion.Mul(w1,x1,y1,z1, w2,x2,y2,z2)
	self.qCamRot = {w,x,y,z}
	cam:SetRot(w,x,y,z)
	
	-- main cam setup
	self:CamUpdateParams()
	self:SetZoom(1) -- default zoom factor = 1, pixel-exact
end

-- returns xloc,yloc in uo coords
function Renderer2D:GetCamPos () return self.fCamPosXLoc,self.fCamPosYLoc,self.fCamPosZLoc end

function Renderer2D:SetCamPos (xloc,yloc,zloc)
	if (not xloc) then return end
	self.fCamPosXLoc = xloc
	self.fCamPosYLoc = yloc
	self.fCamPosZLoc = zloc or 0
	local px,py,pz = Quaternion.ApplyToVector(0,0,self.fCamDist,unpack(self.qCamRot))
	local x,y,z = self:UOPosToLocal(xloc,yloc,zloc or 0)
	GetMainCam():SetPos(px+x,py+y,pz+z*kRenderer2D_ZScale)
end

function Renderer2D:CamStep						() 
	if (self.gbNeedCorrectAspectRatio) then
		self.gbNeedCorrectAspectRatio = false
		self:CamUpdateParams()
	end
end

