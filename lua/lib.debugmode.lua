-- debugmode is a minimal 3d view with skybox and optional grid etc, for debugging 3d graphic stuff like granny

cDebugMode = CreateClass()


function cDebugMode:MainLoop () 
	local gLastFrameTime = 0
	local kMaxFPS = 90
	local kTicksBetweenFrames = 1000 / kMaxFPS
	local kMinFrameWait = 10
	-- mainloop
	while (Client_IsAlive()) do 
		LugreStep()
		
		InputStep() -- generate mouse_left_drag_* and mouse_left_click_single events 
		GUIStep() -- generate mouse_enter, mouse_leave events (might adjust cursor -> before CursorStep)
		CursorStep()

		NotifyListener("Hook_PreRenderOneFrame")
		Client_RenderOneFrame()
		local t = Client_GetTicks()
		Client_USleep(math.max(kMinFrameWait,kTicksBetweenFrames - (t - gLastFrameTime))) -- gives other processes a chance to do something
		gLastFrameTime = t
	end
end


function cDebugMode:Step () 
	local speedfactor = 0.01
	local ox,oy,oz = 0,0,1
	local cam = GetMainCam()
	StepTableCam(cam,gKeyPressed[key_mouse_left],speedfactor,true)
	StepThirdPersonCam(cam,self.camdist,ox,oy,oz)
end


function cDebugMode:MakeGrid (vo,vx,vy,w,h,bCenter) 
	local ox = vo[1] + (bCenter and (-0.5*w*vx[1] -0.5*h*vy[1]) or 0)
	local oy = vo[2] + (bCenter and (-0.5*w*vx[2] -0.5*h*vy[2]) or 0)
	local oz = vo[3] + (bCenter and (-0.5*w*vx[3] -0.5*h*vy[3]) or 0)
	function MyGetVertex (x,y) 	return	ox+x*vx[1]+y*vy[1],
										oy+x*vx[2]+y*vy[2],
										oz+x*vx[3]+y*vy[3] end
	local grid = CreateRootGfx3D()
	grid:SetSimpleRenderable()
	grid:RenderableBegin((w+1)*2+(h+1)*2,0,false,false,OT_LINE_LIST)
	for ax=0,w do
		grid:RenderableVertex(MyGetVertex(ax,0))
		grid:RenderableVertex(MyGetVertex(ax,h))
	end
	for ay=0,h do
		grid:RenderableVertex(MyGetVertex(0,ay))
		grid:RenderableVertex(MyGetVertex(w,ay))
	end
	grid:RenderableEnd()
end

function cDebugMode:StartMainLoop () 
	Client_RenderOneFrame() -- first frame rendered with ogre, needed for init of viewport size
    Client_SetSkybox("bluesky")
	gMaxFPS = 900
	self.camdist = 10
	RegisterStepper(function () self:Step() end)
	BindDown("escape", 		function () os.exit(0) end)
    BindDown("wheeldown",   function () self.camdist = self.camdist * 0.5 end)
    BindDown("wheelup",     function () self.camdist = self.camdist / 0.5 end)
	
	self:MainLoop()
	os.exit(0)
end

