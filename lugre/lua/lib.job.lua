-- some helper functions for easy coroutine handling

--[[
== usage examples ==

	job.create(function()
		local i
		for i = 1,5 do
			print("[A] i",i)
			job.wait(5000)
		end
		print("[A] LALA")
	end,function(r)
		print("JOB A finished",r)
	end)
	
	
	job.create(function()
		for i =1,100 do
			print("I",i)
			job.yield()
		end
		return "lala"
	end,function(status,r)
		print("finished",status,r)
	end)


]]--

gLugreJobs = {}
gLugreJobNextIndex = 1
gLugreJobCurrentRunningIndex = nil
gLugreJobGoodFPS = 15
gLugreJobGoodFrameTicks = 1000 / gLugreJobGoodFPS
gLugreJobPriorityTimeout = 1000
gLugreJobPriorityLastTime = 0

job = {}
function job.terminate (jobid)
	local v = gLugreJobs[job_id]
	if (not v) then return end
	print("job.terminate",jobid)
	v.dead = true
end

function job.step ()
	local priolist = {}

	-- iterate over all queued jobs
	for k,v in pairs(gLugreJobs) do
		-- check viability depenencies
		if v.bind_viability and not IsAlive(v.bind_viability) then
			-- remove job from list if dependency is dead
			gLugreJobs[k] = nil
		end
	
		local status = coroutine.status(v.co)
		-- print("status",v.co,k,status)
		if (not v.dead) and (coroutine.status(v.co) == "normal" or coroutine.status(v.co) == "suspended") then
			local status = nil
			local r = nil
			-- is the job in sleeping state?
			if v.wakeuptime then
				local t = Client_GetTicks()
				-- print("wakeup check",t,v.wakeuptime)
				if t >= v.wakeuptime then
					-- remove sleep timeout
					v.wakeuptime = nil
					-- oki timeout passed so wake the process up
					-- print("JOB wakeup job",v.co,coroutine.running())
					gLugreJobCurrentRunningIndex = k
					status,r = coroutine.resume(v.co)
					if not status then job.internal_handle_resume_error(v,status,r) end
					gLugreJobCurrentRunningIndex = nil
				end
			elseif v.priority == nil then
				-- runs the jobs if its a no prio job
				-- print("JOB resume job",v.co,coroutine.running())
				gLugreJobCurrentRunningIndex = k
				status,r = coroutine.resume(v.co)
				if not status then job.internal_handle_resume_error(v,status,r) end
				gLugreJobCurrentRunningIndex = nil
			else
				table.insert(priolist, v)
			end
		elseif coroutine.status(v.co) == "dead" or v.dead then
			-- coroutine finished, call registered callback
			if v.callback then v.callback(status,r) end
			
			-- remove job from list
			gLugreJobs[k] = nil
		end
	end
	
	
	-- handle prio jobs
	local priocount = countarr(priolist)

	if priocount > 0 then
		table.sort(priolist, job.prio_cmp)

		local nextForcedTime = gLugreJobPriorityLastTime + gLugreJobPriorityTimeout

		local ticksleft = gLugreJobGoodFrameTicks - (Client_GetTicks() - gFrameStartTicks)
			
		-- is the fps good enough for prio jobs?
		if ticksleft > 0 or Client_GetTicks() > nextForcedTime then
			-- do some work until we run out of time
			local iAllowedTimeEnd = Client_GetTicks() + ticksleft
			 
			-- run prio jobs if enough time left
			for k,v in pairs(priolist) do
				-- run highest job until finished or no time left
				while 
					(Client_GetTicks() <= iAllowedTimeEnd) and 
					(coroutine.status(v.co) ~= "dead") and
					(not v.wakeuptime) 
				do 
					-- print("# RUN PRIO JOB",v.id,v.priority)
					-- still time left so start the job
					gLugreJobCurrentRunningIndex = v.id
					local status,r = coroutine.resume(v.co)
					if not status then job.internal_handle_resume_error(v,status,r) end
					gLugreJobCurrentRunningIndex = nil
					
					gLugreJobPriorityLastTime = Client_GetTicks()
				end
				
				if Client_GetTicks() > iAllowedTimeEnd then
					-- we ran out of time
					return
				end
			end
		end
	end
end

function job.prio_cmp(a,b) return (a.priority or 0) < (b.priority or 0) end

-- status of the given job (see coroutine.status)
function job.status (job_id)
	local v = gLugreJobs[job_id]
	if v then
		return coroutine.status(v.co)
	else
		return "dead"
	end
end

function JobDebugDump ()
	for k,v in pairs(gLugreJobs) do
		print("JobDebugDump",k,v.source)
	end
end

-- creates and runs a function as a job and returns the job_id
-- higher priority == more important job
-- if priority == nil then the job runs every frame otherwise only if there is enough time left
-- in the current frame
function job.create (job_fun, callback_fun, priority )
	local v = {}
	
	local id = gLugreJobNextIndex

	v.callback = callback_fun
	v.co = coroutine.create(job_fun)
	v.priority = priority
	v.id = id
	v.bind_viability = nil
	
	--~ print("gDebugJobOrigin",gDebugJobOrigin)
	if (gDebugJobOrigin) then
		local i = debug.getinfo(2,"Sl")
		v.source = i.source..":"..i.currentline
		print("job started",v.source)
	end
	
	gLugreJobs[gLugreJobNextIndex] = v
	
	gLugreJobNextIndex = gLugreJobNextIndex + 1
	
	return id
end

-- this job is only executed if there is enough time left in the frame
function job.create_low_prio (priority, job_fun, callback_fun)
	job.create(job_fun, callback_fun, priority)
end

function job.internal_handle_resume_error (v,status,r)
	v.errormessage = r
	local id = v and v.id or "?"
	print("ERROR: job "..id.." terminated: ",r)
	print(debug.traceback(v.co))
end

-- returns the number of running jobs
function job.count ()
	local i = 0
	for k,v in pairs(gLugreJobs) do
		i = i + 1
	end
	
	return i
end

-- pauses the execution of the calling job
function job.yield ()
	if not coroutine.running() then return end 
	
	coroutine.yield()
end

-- returns the index/id of the calling job
function job.running_id ()
	return gLugreJobCurrentRunningIndex
end

-- pauses the execution of the calling job for timeout in ms
function job.exit ()
	local k = job.running_id()
	if (not k) then print("warning job.terminate job.running_id failed") return end
	local v = gLugreJobs[k]
	if (not v) then print("warning job.terminate job not found") return end
	v.dead = true
	coroutine.yield()
end
	
function job.wakeup (jobid) 
	local job = gLugreJobs[jobid]
	if (job) then job.wakeuptime = nil end
end

-- the job gets executed as long as the given object is alive
-- use this with jobs that depends on object and should 
-- get killed if object is not alive anymore
function job.bind_viability (jobid, object) 
	local job = gLugreJobs[jobid]
	if (job) then job.bind_viability = object end
end

function job.wait (timeout_in_ms)
	if not coroutine.running() then 
		print("WARNING, job.wait should only be used inside job function",_TRACEBACK()) 
		Client_USleep(timeout_in_ms) 
		return 
	end 

	-- print("job.wait",coroutine.running())
	local k = job.running_id()
	-- print("wait id",k)
	if k then
		local t = Client_GetTicks()
		-- print("awake",t,t + timeout_in_ms)
		local v = gLugreJobs[k]
		-- print("v",v)
		if not v then return end
		
		v.wakeuptime = Client_GetTicks() + timeout_in_ms
		job.yield()
	end
end

-- waits until every running job finishes
function job.waitforall ()
	repeat
		job.step()
	until job.count() == 0
end
