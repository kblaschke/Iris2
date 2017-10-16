dofile(GetMainWorkingDir().."lua/lib.thread.lua")

print("thread.test2 start")

while (true) do 
	this_thread:LockMutex()
	
	local handlers = {}
	
	function handlers.kThreadMsg_Test0		()		print("thread.test2 test0") end
	function handlers.kThreadMsg_TestPrint	(txt)	print("thread.test2 testprint",txt) end
	function handlers.kThreadMsg_TestBlock	(m)
		print("thread.test2 TestBlock",m)
		for i=1,8 do Thread_Sleep(1000) print("thread.test2 calculating..",i) end
		m:UnLockMutex()
	end
	
	RecvNetMessages(this_fifo_recv,function (msgtype,...) 
		local msgtypename = gNetMessageTypeName[msgtype]
		local handler = handlers[msgtypename]
		if (handler) then handler(...) end
	end)
	this_thread:UnLockMutex()
	Thread_Sleep(8000)
end

