-- ***** ***** ***** ***** ***** block baseclass
-- NOTE: block loading thread should check ShouldBlockTerminate after each yield
-- to interrupt the current loading process

cMapBlock = CreateClass()
cMapBlock.kLOD_Detail			= nil -- set to something with .prio = value
cMapBlock.kLOD_Rough			= nil
cMapBlock.kMaxDist_Destroy		= 8*9 -- camdist in tiles
cMapBlock.kMaxDist_Visible		= 8*6 -- camdist in tiles
cMapBlock.kMaxDist_Detail		= 8*3 -- camdist in tiles
cMapBlock.kLODUpdateInterval	= 500 -- msec

function cMapBlock:Init			()		
	self.prio = kSchedulerIdlePriority
	self.co = coroutine.create(self.WorkThread)
end

-- returns the bounding box of the map block (x,y,w,h) in tiles
function cMapBlock:GetAABB	() return 0,0,0,0 end	-- override me !

-- check if the given ray hits the bounding box of the block
-- returns hit and distance
function cMapBlock:BBRayPick	(rx, ry, rz, rvx, rvy, rvz)
	local x,y,w,h = self:GetAABB()
	--~ print("cMapBlock:BBRayPick",x,y,w,h)
	-- if 3d static mousepicking is strange, look here, xmirror maybe.. no longer used for terrain, only here
	local hit,dist = RayAABBQuery( rx, ry, rz, rvx, rvy, rvz, -x-w,y,-10000, w, h, 10000 )
	return hit,dist
end

function cMapBlock:GetPos	()
	local x,y,w,h = self:GetAABB()
	return x,y
end

function cMapBlock:GetSize	()
	local x,y,w,h = self:GetAABB()
	return w,h
end

function cMapBlock:SetPriority		(prio)	self.prio = prio end
function cMapBlock:Yield			()		
	--~ self.last_yield_stack = _TRACEBACK() -- used nowhere ? waste of performance
	coroutine.yield() 
end
function cMapBlock:YieldIfOverTime	()		if (Client_GetTicks() > self.t_end) then self:Yield() end end

function cMapBlock:Work			(t_end)	
	self.t_end = t_end 
	self:Resume()
end

function cMapBlock:Resume	()
	if coroutine.status(self.co) == "dead" then return true, "co is dead" end
	local status,r = coroutine.resume(self.co,self)
	self:CheckForResumeError(status,r)
end

function cMapBlock:CheckForResumeError	(status,r)
	if not status then
		print("ERROR: job terminated: ",r)
		print(SmartDump(self,3))
	end
end

function cMapBlock:WorkThread	()		-- executed as coroutine/thread
	while (not self.bWorkTerminated) do 
		self:WorkStep() 
		self:Yield() 
	end
end

-- internal function for the stepper to stop during building process
function cMapBlock:ShouldBlockTerminate ()
	return self.bWorkTerminated
end

-- the sheduler/spawner use this to check if the block is dead
-- this is used to keep destroyed but unfinished blocks alive until they
-- are dead
function cMapBlock:IsDead ()
	return (coroutine.status(self.co) == "dead")
end

-- executes coroutine until it terminates, cannot be restarted
-- if the coroutine is still running the sheduler will resume is later to finish the work
-- but the normal case should be that the thread checks with ShouldBlockTerminate()
-- and stopps
function cMapBlock:TerminateWork() 
	self.bWorkTerminated = true
	self:Resume()
	self:SetPriority(kSchedulerUnfinishedPriority)
end

function cMapBlock:Destroy () self:TerminateWork() self:Clear() end

function cMapBlock:Clear () self:ClearRough() self:ClearDetail() end -- remove all gfx

-- trigger block rebuild
function cMapBlock:Rebuild ()
	self:SetLOD(nil)
	self.lod_finished = nil
end

-- manually sets the lod level, scheduler can overwrite the lod level
function cMapBlock:SetLOD (newlod)
	if (newlod ~= self.lod) then 
		self:SetPriority(newlod and newlod.prio or kSchedulerIdlePriority)
		if (not newlod) then self:Clear() end
		self.lod = newlod
		self.iNextLODUpdate = 0
	end
end

-- called every frame, instant actions (destroy gfx), evaluate priority 
function cMapBlock:ShortStep (t,x,y,z)
	if ((self.iNextLODUpdate or 0) < t) then
		self.iNextLODUpdate = t + self.kLODUpdateInterval
		self:SetLOD(self:RecalcLOD(x,y,z))
	end
end
		
function cMapBlock:RecalcLOD (x,y,z)
	local bx,by,w,h = self:GetAABB()
	
	local camdist = hypot(	(bx+w/2)-x,
							(by+h/2)-y)
	self.last_camdist = camdist

	if (	camdist <  self.kMaxDist_Detail ) then return self.kLOD_Detail 
	elseif (camdist <  self.kMaxDist_Visible) then return self.kLOD_Rough end
end

-- a single step during the thread
function cMapBlock:WorkStep ()
	if (self.lod_finished == self.lod) then 
		-- sets priority to idle if the current lod level is the loaded one
		-- changing the lod should change the prio later
		self:SetPriority(kSchedulerIdlePriority)
		return -- nothing to do
	end
	
	if (self.lod == self.kLOD_Rough ) then 
		self:WorkStep_LoadRough()  
		self:ClearDetail() 
		self.lod_finished = self.lod 
		self:SetPriority(kSchedulerIdlePriority)
	elseif (self.lod == self.kLOD_Detail) then 
		self:WorkStep_LoadDetail() 
		self:ClearRough() 
		self.lod_finished = self.lod 
		self:SetPriority(kSchedulerIdlePriority)
	end
end

function cMapBlock:ClearRough   () end -- override me !
function cMapBlock:ClearDetail  () end -- override me !
function cMapBlock:WorkStep_LoadRough  () end -- override me !
function cMapBlock:WorkStep_LoadDetail () end -- override me !
