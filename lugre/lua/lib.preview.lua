-- generate preview of meshes using rtt
-- todo : cache(resolution) ? store in tmp dir ?
-- TODO : (background options : starfield, black, certain color, some other material or texture)

-- res (res x res) is the resulting texture resolution, must be 2^n
-- angh,angv are the angles from which the preview is generated, defaults to 30°,45°
-- returns matname ? todo : better texturename ?
function GetMeshPreview	(meshname,res,angh,angv,pixelformat,qCustomRotation,vCustomScale) 
	res = res or 16
	angh = angh or 45*gfDeg2Rad
	angv = angv or 30*gfDeg2Rad
--~ 	local x1,y1,z1,x2,y2,z2 = MeshReadOutExactBounds(meshname)
--~ 	local boundrad = math.max(Vector.len(x1,y1,z1),Vector.len(x2,y2,z2))
--~ 	MeshSetBounds(meshname,x1,y1,z1,x2,y2,z2)
--~ 	MeshSetBoundRad(meshname,boundrad)
	local boundrad = MeshGetBoundRad(meshname)
	
	local name_scenemanager		= GetUniqueName()
	local name_texture			= GetUniqueName()
	
	-- prepare rtt
	CreateSceneManager(name_scenemanager)
	local cam = CreateCamera(name_scenemanager)
	local tex = CreateRenderTexture(name_texture,res,res,pixelformat or PF_A8R8G8B8)
	if (not tex:IsAlive()) then return end
	
	tex:SetAutoUpdated(false)
	local vp = CreateRTTViewport(tex,cam)
	cam:SetAspectRatio(vp:GetActualWidth()/vp:GetActualHeight())
	--print("GetMeshPreview rtt-viewport size:",vp:GetActualWidth(),vp:GetActualHeight()) -- = res,res
	vp:SetOverlaysEnabled(false)
	
--~ 		vp->setClearEveryFrame( true );
--~ 		vp->setBackgroundColour( ColourValue::Black );
	-- CreateTextureUnitState(mymatname,0,0,myrttname)
	
	--local dist = GetRenderingDistanceForPixelSize(boundrad,res*0.25,vp,cam)
	local visrad_pixels = res*0.5
	local vw,vh = res,res
	local dist = 2.0 * math.max( boundrad/(visrad_pixels/vw), boundrad/(visrad_pixels/vh) ) -- dirty hack, TODO : analyse projection matrix
	
	Client_AddDirectionalLight(-0.3,-0.5,-0.1,name_scenemanager)
	cam:SetNearClipDistance(1)
	cam:SetFarClipDistance(dist*2 + boundrad + 1000)
	
	--print("GetMeshPreview",boundrad,res,dist)
	local gfx = CreateRootGfx3D(name_scenemanager)
	gfx:SetMesh(meshname)
	gfx:SetPosition(0,0,-dist)
	if (vCustomScale) then gfx:SetScale(unpack(vCustomScale)) end
	if (qCustomRotation) then
		gfx:SetOrientation(unpack(qCustomRotation))
	else 
		local qw,qx,qy,qz = Quaternion.fromAngleAxis(angv,1,0,0)
		gfx:SetOrientation(Quaternion.Mul(qw,qx,qy,qz,Quaternion.fromAngleAxis(angh + 180*gfDeg2Rad,0,1,0)))
	end
	tex:Update()
	cam:Destroy()
	vp:Destroy()
	-- TODO : DestroySceneManager(name_scenemanager)
	return name_texture,tex,name_texture
end
