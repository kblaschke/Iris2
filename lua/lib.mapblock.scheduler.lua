-- ***** ***** ***** ***** ***** scheduler

cScheduler = CreateClass()
kSchedulerUnfinishedPriority = 9999
kSchedulerIdlePriority = 10000

function CreateScheduler	() local o = CreateClassInstance(cScheduler) return o end

function cScheduler:Init	()
	self.pProcessList = {}
	self.kGoodFPS = 50
	self.kGoodTicksBetweenFrames = 1000 / self.kGoodFPS -- 1000=1sec
	self.kAllowedTicksPerFrame = self.kGoodTicksBetweenFrames
	
	self.lastSort = nil
	self.sortTimeout = 1000 / 5
end

function cScheduler:AddProcess		(process) 
	if (gDebugJobOrigin) then process.source = process.source or GetOneLineBackTrace(2) end
	table.insert(self.pProcessList,process) 
end
function cScheduler:RemoveProcess	(process)
	local pos = self:_FindProcessPos(process)
	if (pos) then table.remove(self.pProcessList,pos) end
end

-- internal, search current index in list
function cScheduler:_FindProcessPos	(process) for k,process2 in ipairs(self.pProcessList) do if (process2 == process) then return k end end end 

gfScheduler_WorkTime = 0
gfScheduler_WorkCount = 0


-- x,y,z : cam/focus-pos
function cScheduler:Step		(x,y,z)
	local t = Client_GetTicks()
	local t_end = gMyTicks + self.kAllowedTicksPerFrame
	
	local active_blocks = {}
	
	-- shortsteps, re-evaluate prio, release gfx
	for k,process in ipairs(self.pProcessList) do 
		process:ShortStep(t,x,y,z) 
		if process.prio ~= kSchedulerIdlePriority then
			table.insert(active_blocks, process)
		end
	end 
	
	--~ if math.mod(gMyFrameCounter, 30) == 0 then
		--~ print("procs",table.getn(self.pProcessList), countarr(active_blocks))
	--~ end
	
	giShowLoading = countarr(active_blocks)
	if (gDebugJobOrigin and giShowLoading > 20) then 
		print("cScheduler:Step : MANY BLOCKS",giShowLoading) 
		local top = {}
		for k,process in pairs(active_blocks) do 
			local source = process.source or "???"
			top[source] = (top[source] or 0) + 1
		end
		for k,v in pairs(top) do top[k] = {name=k,v=v} end
		local top = SortedArrayFromAssocTable(top,function (a,b) return a.v < b.v end)
		for k,v in pairs(top) do print(" ",v.v,v.name) end
	end
	
	-- sort by priority
	if self.lastSort == nil or (t - self.lastSort > self.sortTimeout) then
		table.sort(active_blocks, self.CmpProcess)
		
		if self.lastSort == nil then 
			self.lastSort = t
		else
			self.lastSort = self.lastSort + self.sortTimeout
		end
	end
	
	-- work until no time left but to atleast a small number of blocks
	local avgdt = nil
	local done = 0
	local minDone = 3
	for k,process in ipairs(active_blocks) do 
		local t1 = Client_GetTicks()
		process:Work(t_end)
		local t2 = Client_GetTicks()

		done = done + 1

		avgdt = avgdt and (avgdt*0.5+(t2-t1)*0.5) or (t2-t1)
		
		--~ if (Client_GetTicks() >= t_end) then break end
		if (t2 + avgdt >= t_end and done >= minDone) then break end
	end
end

-- true when the first is less than the second       (NOT less-equal)
function cScheduler.CmpProcess	(a,b) 
	local da = math.floor((a.last_camdist or 1000)/8)
	local db = math.floor((b.last_camdist or 1000)/8)
	
	if da ~= db then 
		return da < db
	else 
		return a.prio < b.prio 
	end
end

function cScheduler:Destroy ()
	for k,v in pairs(self.pProcessList) do
		self:RemoveProcess(v)
	end
end
