-- ./start.sh -threadtest -> RunThreadTest
-- see lugre/lugre_thread_L.cpp (and fifo_L)
if (this_thread) then -- basic includes for threads
	lugreluapath        = (file_exists(GetMainWorkingDir().."mylugre") and GetMainWorkingDir().."mylugre/lua/" or GetLugreLuaPath()) -- this is should also in USERHOME dir
	dofile(lugreluapath.."lib.util.lua") 
	dofile(lugreluapath.."lib.fifo.lua") 
	dofile(lugreluapath.."lib.netmessage.lua") 
end

-- example :  groundblock,staticblock (complex due to clientside caching)
-- example :  animloader
-- problem : escalate/blocked-wait-for-result
	-- idea : request blocking : receive blocking response with mutex (locked until finished) : caller can call "lock", will wait until set.
	-- problem, how to wait for blocking response ? 
	-- thread : getlocked mutex ?  (releasen und sofort locken ist schlecht... locken währen busy?)

	
	
-- ***** ***** ***** ***** ***** thread messages (iris specific)

RegisterNetMessageFormatWrapper("m","p",function (mutex) return mutex:GetCrossThreadHandle() end,
										function (p) return CreateMutexFromCrossThreadHandle(p) end)

RegisterNetMessageType("kThreadMsg_TestPrint"	,"s")
RegisterNetMessageType("kThreadMsg_TestBlock"	,"m")
RegisterNetMessageType("kThreadMsg_Test0"		,"")

--~ RegisterNetMessageType("kThreadMsg_Test0"		,"")


-- ***** ***** ***** ***** ***** cThread (generic)
	
cThread = CreateClass()

function cThread:Init (filepath) 
	self.thread = CreateLuaThread(filepath)
	self.fifo_Parent2Child = self.thread:CreateFifoParent2ChildHandle()
	self.fifo_Child2Parent = self.thread:CreateFifoChild2ParentHandle()
end

function cThread:SendMessage (msgtype,...)
	self.thread:LockMutex()
	SendNetMessageFifo(self.fifo_Parent2Child,msgtype,...)
	self.thread:UnLockMutex()
	self.thread:Interrupt() -- tell a sleeping thread that it has a new message
end

function cThread:BlockingMessage (msgtype,...) -- only works if message takes mutex as first param after msgtype
	local blocker = CreateMutex()
	blocker:LockMutex() -- mutex starts locked, will be unlocked by thread when done
	self:SendMessage(msgtype,blocker,...)
	blocker:LockMutex() -- wait for thread to unlock mutex
	blocker:UnLockMutex() -- cleanup
	blocker:Destroy()
end
	
-- ***** ***** ***** ***** ***** test

function ThreadTest2 ()
	print("ThreadTest2..")
	local t = cThread:New(GetMainWorkingDir().."lua/lib.thread.test2.lua")
	print("ThreadTest2.. messages")
	t:SendMessage(kThreadMsg_Test0)
	t:SendMessage(kThreadMsg_TestPrint,"bla")
	t:SendMessage(kThreadMsg_TestPrint,"blub")
	print("ThreadTest2.. blocking start")
	t:BlockingMessage(kThreadMsg_TestBlock)
	print("ThreadTest2.. blocking end")
	t:SendMessage(kThreadMsg_TestPrint,"boing")
	print("ThreadTest2=done")
	Client_Sleep(5)
	os.exit(0)
end 
function RunThreadTest () ThreadTest2() end -- called from main on -threadtest
--~ RegisterListener("Hook_CommandLine",function () if (gCommandLineSwitches["-threadtest"]) then ThreadTest2() os.exit(0) end end)
