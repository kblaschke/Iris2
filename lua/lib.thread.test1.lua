function RunThreadTest () RunThreadTest_Main() end  --  -threadtest
-- idea hagish : helper-class to create message-handling thread that can be serialized as option for easier debugging (decide at create if a real thread is started or a thread-object that handles messages directly)
--[[
	notes : 
	<ghouly> hi all, question about threading,  is it technically possible to transfer data to vram in a threaded way ? 
	for example  HardwareVertexBuffer::writeData(...)  etc. looked in the ogre-opengl source and saw it calls glBufferDataARB(...) directly without using any thread mutex  etc.    i don't want to access the same buffer from different threads,  just wondering if threads other than the mainthread are allowed to call opengl functions
	http://www.ogre3d.org/forums/viewtopic.php?f=2&t=56421
	OGRE_THREAD_CREATE()  -- register with rendersystem
		Root::getSingleton().getRenderSystem()->postExtraThreadsStarted();
		workqueue : virtual void setWorkersCanAccessRenderSystem(bool access);      otherwise : response handler executed in mainthread transfers data to rendersystem
		Root::getWorkQueue
		set(OGRE_CONFIG_THREADS 2 CACHE STRING 
			"Enable Ogre thread support for background loading. Possible values:
			0 - Threading off.
			1 - Full background loading.
			2 - Background resource preparation."
		)
		
	/// bhit,fHitDist,iFaceNum = FIFO_RayPickTri_Ex(fifoVertexBuf,fifoIndexBuf,iNumFaces,iVertexPosOffset,iVertexStride,fBoundRad,rx,ry,rz, rvx,rvy,rvz, x,y,z, qw,qx,qy,qz, sx,sy,sz) -- mainly for mousepicking
]]--

function ack(n, m)
	--~ print("ack",n,m)
	while n ~= 0 do
		if m == 0 then
			m = 1
		else
			m = ack(n, m-1)
		end
		
		n = n - 1
	end
	
    return m + 1
end

function stupidCounter(count)
	print("CHILD stupidCounter", count)
	local x = 0
	for i=1,count do
		x = x + 1
		Thread_Sleep(1000)
	end
	return x
end

function ThreadChildMainLoop()
	-- from global scope: this_thread, this_fifo_send, this_fifo_recv
	
	local SendResult = function(id, ok, ret)
		this_thread:LockMutex()
		
		this_fifo_send:PushU(id)
		this_fifo_send:PushU(ok)
		FIFOPushNetSimpleTable(ret, this_fifo_send)
		
		this_thread:UnLockMutex()
	end
	
	local HandleCall = function(id, funName, params)
		print("HANDLECALL", id, funName, unpack(params))
		local fun = _G[funName]
		
		if fun then
			SendResult(id, 1, {fun(unpack(params))})
		else
			SendResult(id, 0, {})
		end
	end
	
	while true do
		this_thread:LockMutex()
		
		local id,funName,params = nil,nil,nil
		local len = this_fifo_recv:Size()
		
		if len > 0 then
			id = this_fifo_recv:PopU()
			funName = this_fifo_recv:PopS()
			params = FIFOPopNetSimpleTable(this_fifo_recv)
		end
		
		this_thread:UnLockMutex()
		
		if id then
			HandleCall(id, funName, params)
		else
			Thread_Sleep(1000)
		end
	end
end

--[[

-- example

local t = CreateExtendedLuaThread("bla.lua")
local id = t:queueCall("ack", 3,3)
local id,ok,ret = t:pickupResultEx(id)
id = t:queueCall("ack", 3,3)
local ret = t:pickupResult(id)
local id = t:queueCallWithCallback(function(ack_ret)
	print("RESULT", ack_ret)
end, "ack", 3,3)

]]
function CreateExtendedLuaThread(file)
	if (not CreateLuaThread) then return end
	local thread = CreateLuaThread(file)
	
	thread.fifo_send		= thread:CreateFifoParent2ChildHandle()
	thread.fifo_recv		= thread:CreateFifoChild2ParentHandle()
	thread.nextCallId		= 1
	thread.callsQueued 	= 0
	thread.callbackTable	= {}
	thread.resultTable		= {}
	
	thread.isIdValid = function(self, id)
		if self.resultTable[id] or self.callbackTable[id] then
			return true
		else
			return false
		end
	end
	
	thread.isResultAvailable = function(self, id)
		self:checkForResults()
		
		if self.resultTable[id] and type(self.resultTable[id]) == "table" then 
			return true 
		else 
			return false 
		end
	end
	
	thread.checkForResults = function(self)
		while true do
			local id,ok,ret = self:_getResult()
			
			if id then
				if self.callbackTable[id] then
					-- send result via callback
					self.callbackTable[id](id,ok,ret)
					self.callbackTable[id] = nil
					self.resultTable[id] = nil
				else
					-- store result for picking up later
					self.resultTable[id] = {ok, ret}
				end
			else
				return
			end
		end
	end
	
	thread._generateNextId = function(self)
		local id = self.nextCallId
		self.nextCallId = self.nextCallId + 1
		return id
	end
	
	-- callback_success : function(...), [callback_error : function()]
	thread.queueCallWithCallback = function(self, callback_success, callback_error, funName, ...)
		if type(callback_error) == "function" then
		
			-- normal call with error handler
			self:queueCallWithCallbackEx(function(id,ok,ret)
				if ok == 0 then
					if callback_error then callback_error() end
				else
					if callback_success then callback_success(unpack(ret)) end
				end
			end, funName, ...)
			
		else
		
			-- shortened call without error handler
			-- therefore funName is the first parameter
			self:queueCallWithCallbackEx(function(id,ok,ret)
				if ok == 1 then
					if callback_success then callback_success(unpack(ret)) end
				end
			end, callback_error, unpack({funName, ...}))
		
		end
	end
	
	-- callback : function(id,ok,ret)
	thread.queueCallWithCallbackEx = function(self, callback, funName, ...)
		if callback then
			local id = self:queueCall(funName, ...)
			self.callbackTable[id] = callback
		end
	end
	
	thread.blockingCall = function(self, funName, ...)
		return self:pickupResult(self:queueCall(funName, ...))
	end
	
	thread.queueCall = function(self, funName, ...)
		local id = self:_generateNextId()
		local fifo = self.fifo_send
		
		self:LockMutex()
		
		self.resultTable[id] = true
		
		fifo:PushU(id)
		fifo:PushS(funName)
		FIFOPushNetSimpleTable({...}, fifo)
	
		self.callsQueued = self.callsQueued + 1
	
		self:UnLockMutex()
		
		self:Interrupt()
		
		return id
	end
	
	thread.countQueuedCalls = function(self)
		return self.callsQueued
	end
	
	thread.waitForAllBlocking = function(self)
		while self.callsQueued > 0 do
			--~ print("still running", self.callsQueued)
			self:checkForResults()
			Client_USleep(1000 / 100)
		end
		--~ print("all finished")
	end
	
	thread.pickupResult = function(self, id)
		local ok, ret = self:pickupResultEx(id) 
		if ok == 0 then
			return nil
		else
			return unpack(ret)
		end
	end
	
	thread.pickupResultEx = function(self, id)
		if self:isIdValid(id) then
			while not self:isResultAvailable(id) do
				Client_USleep(1000 / 100)
			end
			
			local ok,ret = unpack(self.resultTable[id])
			return ok,ret
		end
		
		return 0,{}
	end
	
	thread._getResult = function(self)
		--~ print("------_getResult", self, self.fifo_recv)
		local fifo = self.fifo_recv
		
		local id,ok,ret = nil,nil,nil
	
		self:LockMutex()
		
		local len = fifo:Size()
		if len > 0 then
			id = fifo:PopU()
			ok = fifo:PopU()
			ret = FIFOPopNetSimpleTable(fifo)
			self.callsQueued = self.callsQueued - 1
		end
		
		self:UnLockMutex()
		
		return id,ok,ret
	end
	
	return thread
end

function RunThreadTest_Main ()
	
	print("main: Threads_GetHardwareConcurrency:", Threads_GetHardwareConcurrency())
	
	local t = CreateExtendedLuaThread("../mythread.lua")
	
	print("BLOCKING", t:blockingCall("stupidCounter", 2))
	
	t:queueCallWithCallback(
	function(ack) 
		print("CALLBACK ack", ack)
	end,
	"ack", 3,1)
		
	t:waitForAllBlocking()
	print("all finished")
	
	t:queueCall("ack", 3,3)
	t:queueCall("stupidCounter", 5)
	t:queueCall("ack", 2,2)
	t:queueCall("ack", 2,1)
	
	t:queueCallWithCallbackEx(
		function(id, ok, ret) 
			print("CALLBACK", id, ok, unpack(ret))
		end, 
		"ack", 3,1)
		
	t:queueCallWithCallback(
		function(ack) 
			print("CALLBACK ack", ack)
		end,
		"ack", 3,1)
	
	local ok,ret = t:pickupResultEx(1)
	print("RESULT",1,ok,unpack(ret))
	
	local ok,ret = t:pickupResultEx(2)
	print("RESULT",2,ok,unpack(ret))
	
	--~ print("RESULT",3,t:pickupResult(3))
	
	t:waitForAllBlocking()
	print("all finished")
	
	Client_Sleep(10)
	os.exit(1)
end

function RunThreadTest_Child () 
	print("child: hello world,this_thread=",this_thread)
	lugreluapath        = (file_exists(GetMainWorkingDir().."mylugre") and GetMainWorkingDir().."mylugre/lua/" or GetLugreLuaPath()) -- this is should also in USERHOME dir
	dofile(lugreluapath.."lib.util.lua") 
	dofile(lugreluapath.."lib.fifo.lua") 
	dofile(lugreluapath.."lib.netmessage.lua") 
	
	ThreadChildMainLoop()

	print("child: ended")
end




