-- small performance measurment tool

gGlobalProfileStack = {{name="dummy0_StartGlobalProfiler",t=0},{name="dummy1_debug.sethook",t=0}}
gGlobalProfileStackData = {}

function StartGlobalProfiler () 
	debug.sethook(GlobalProfilerFun,"cr") -- only one hook possible
	--~ debug.sethook(GlobalProfilerFun_Call,"c") -- calls
	--~ debug.sethook(GlobalProfilerFun_Return,"r") -- returns
end

function StopGlobalProfiler ()
	debug.sethook(nil,"cr")
end

-- dumps every line of lua code that gets executed to stdout
function StartLinePrinter	()
	debug.sethook(
		function(typename,linenumber) 
			print("#LINE# " .. debug.getinfo(2,"Sl").short_src ..":" .. linenumber .. " @ fun", debug.getinfo(2,"n").name) 
		end
	, "l")
end

function StopLinePrinter	()
	debug.sethook(nil, "l")
end

function GlobalProfilerFun (typename)
	if (gGlobalProfileInternalCall) then return end
	gGlobalProfileInternalCall = true
	if (typename == "call") then GlobalProfilerFun_Call() else GlobalProfilerFun_Return() end
	gGlobalProfileInternalCall = false
end

function GlobalProfilerFun_Call ()
	local funname = debug.getinfo(3,"n").name -- doesn't work in tail-return
	--~ print("GlobalProfilerFun_Call  ",funname)
	table.insert(gGlobalProfileStack,{name=funname or "???",t=Client_GetTicks()})
end

function GlobalProfilerFun_Return ()
	local t = Client_GetTicks()
	local e = table.remove(gGlobalProfileStack) -- pops the last element from stack and returns it
	if e then
		--~ print("GlobalProfilerFun_Return calldur",e.name,t-e.t)
		local data = gGlobalProfileStackData[e.name]
		if (not data) then 
			data = { n=e.name, tsum=t-e.t, c=1 }
			gGlobalProfileStackData[e.name] = data 
		else
			data.tsum = data.tsum + t-e.t
			data.c = data.c + 1
		end 
	else
		print("GlobalProfilerFun_Return underflow")
	end
end

function GlobalProfilerClearData ()
	if gGlobalProfileStackData then gGlobalProfileStackData = {} end
end


-- field in {"avg","tsum","n","c"}
function GlobalProfilerOutput (limit,field)
	field = field or "tsum"
	limit = limit or 30
	print("GlobalProfilerOutput","order by",field)
	local t = {}
	for k,v in pairs(gGlobalProfileStackData) do v.avg = v.tsum/v.c table.insert(t,v) end
	table.sort(t,function (a,b) return a[field] > b[field] end) -- return true when a < b 
	for k,v in ipairs(t) do 
		print(v.tsum,v.n,v.c,v.avg)
		if (k > limit) then break end
	end
end

-- ***** ***** ***** ***** ***** section profiler

function MakeProfiler (name,startsectionname_or_nil,bProfileMemory) 
	name = name or "profile"
	local p = {
		bProfileMemory = bProfileMemory,
		name = name,
		totaltimesum = 0,
		totalmemsumL = 0,
		totalmemsumO = 0,
		totaltime = {},
		totalmemL = {},
		totalmemO = {},
		totalcount = {},
		StartSection = function (self,secname)
			self:Finish()
			self.secname = secname
		end,
		FinishAndPrint = function (self)  self:Finish() self:PrintTotalTime() end,
		FinishAndPrintIfOver = function (self,timesum,memsumL,memsumO)
			self:Finish()
			if (self.totaltimesum > (timesum or 0) or 
				self.totalmemsumL > (memsumL or 0) or 
				self.totalmemsumO > (memsumO or 0)) then
				self:PrintTotalTime()
			end
		end,
		FinishAndPrintSectionIfOverDefault = function (self,timesum,memsumL,memsumO)
			self:FinishAndPrintSectionIfOver(100,300*1024,300*1024)
		end,
		FinishAndPrintSectionIfOver = function (self,timesum,memsumL,memsumO)
			self:Finish()
			for secname,t in pairs(self.totaltime) do 
				if (self.totaltime[secname] > (timesum or 0) or 
					self.totalmemL[secname] > (memsumL or 0) or 
					self.totalmemO[secname] > (memsumO or 0)) then
					self:PrintSection(secname) 
				end
			end
		end,
		Finish = function (self) 
			local oldt = self.secstart
			local oldmemL = self.secstartmemL
			local oldmemO = self.secstartmemO
			self.secstart = Client_GetTicks()
			if (self.bProfileMemory) then 
				self.secstartmemL = Profile_GetQuickMemoryLua()
				self.secstartmemO = Profile_GetQuickMemoryOgre()
			end
			if (self.secname) then
				local dt = self.secstart - oldt
				self.totaltimesum	= self.totaltimesum + dt
				
		
				--~ printdebug("profile",sprintf("%5d msec : %s:%s",dt,self.name,self.secname))
				
				self.totalcount[self.secname]	= (self.totalcount[self.secname] or 0) + 1
				self.totaltime[self.secname]	= (self.totaltime[self.secname] or 0) + dt
				
				if (self.bProfileMemory) then
					local dML = self.secstartmemL - oldmemL
					local dMO = self.secstartmemO - oldmemO
					self.totalmemsumL	= self.totalmemsumL + dML
					self.totalmemsumO	= self.totalmemsumO + dMO
					self.totalmemL[self.secname]	= (self.totalmemL[self.secname] or 0) + dML
					self.totalmemO[self.secname]	= (self.totalmemO[self.secname] or 0) + dMO
				end
				self.secname = nil
			end
		end,
		PrintTotalTime = function (self)
			for secname,t in pairs(self.totaltime) do self:PrintSection(secname) end
		end,
		PrintSection = function (self,secname)
			local memtxt = self.bProfileMemory and sprintf("mem:L=%8dk O=%8dk",floor(self.totalmemL[secname]/1024),floor(self.totalmemO[secname]/1024)) or ""
			print(sprintf("%5d msec %s : %5d : %s:%s",self.totaltime[secname],memtxt,self.totalcount[secname],self.name,secname))
		end,
	}
	if (startsectionname_or_nil) then p:StartSection(startsectionname_or_nil) end
	return p
end


-- ***** ***** ***** ***** ***** RoughProfiler
-- used to profile the programs mainloop and important subfunctions for memory(ogre,lua) and time usage

gAllRoughProfilers = {}
function CreateRoughProfiler (name)
	local p = {
		name = name,
		sum = {},
		sum_memL = {},
		sum_memO = {},
		sum_tspike = {},
		sum_tspikeframe_total = {},
		sum_tspikeframe_cur = {},
		bOnlyOnceDone = {},
		Dummy = function () end,
		Start = function (self,bEnabled)
			self:FinishSection()
			if (not bEnabled) then
				self.Start		= self.Dummy
				self.Section	= self.Dummy
				self.End		= self.Dummy
				return
			end
			self.t = nil
		end,
		FinishSection = function (self,t,memL,memO,bOnlyOnce)
			if (not self.t) then return end
			local dt	= (t or Client_GetTicks())					- self.t
			local dmemL	= (memL or Profile_GetQuickMemoryLua())		- self.memL
			local dmemO	= (memO or Profile_GetQuickMemoryOgre())	- self.memO
			if (gEnableRoughProfileSum) then 
				local secname = self.secname 
				self.sum[secname] = (self.sum[secname] or 0) + dt 
				if (dt > 50) then self.sum_tspike[secname] = (self.sum_tspike[secname] or 0) + dt end
				self.sum_tspikeframe_cur[secname] = (self.sum_tspikeframe_cur[secname] or 0) + dt 
				self.sum_memL[secname] = (self.sum_memL[secname] or 0) + max(0,dmemL) 
				self.sum_memO[secname] = (self.sum_memO[secname] or 0) + max(0,dmemO)
			end
			if (self.bShowMe and (dt > 300 or dmemL > 1024*1024 or dmemO > 1024*1024)) then
				local bOnlyOnce = self.bCurOnlyOnce
				if (bOnlyOnce) then self.bOnlyOnceDone[self.secname] = true end
				print(sprintf("%5d msec mem:L=%8dk O=%8dk",dt,floor(dmemL/1024),floor(dmemO/1024)),self.name..":"..self.secname,bOnlyOnce and "(!#!ONLY LISTED ONCE!#!)" or "")
			end
			self.bShowMe = false
			self.t = nil
		end,
		SpikeFrame = function (self,bSum)
			if (bSum) then for secname,dt in pairs(self.sum_tspikeframe_cur) do 
				self.sum_tspikeframe_total[secname] = (self.sum_tspikeframe_total[secname] or 0) + dt 
			end end
			self.sum_tspikeframe_cur = {}
		end,
		SectionIfActive = function (self,name) if (self.t) then self:Section(name) end end,
		Section = function (self,name,bOnlyOnce)
			local t		= Client_GetTicks()
			local memL	= Profile_GetQuickMemoryLua()
			local memO	= Profile_GetQuickMemoryOgre()
			self:FinishSection(t,memL,memO)
			self.t		= t		
			self.memL	= memL
			self.memO	= memO
			self.secname = name
			self.bCurOnlyOnce = bOnlyOnce
			if (bOnlyOnce and self.bOnlyOnceDone[name]) then return end
			self.bShowMe = true
		end,
		End = function (self) self:FinishSection() end,
	}
	table.insert(gAllRoughProfilers,p)
	return p
end

function RoughProfileEndFrame(iTimeSinceLastFrame)
	local bSum = iTimeSinceLastFrame and iTimeSinceLastFrame > 50  -- 1000/30 = 33
	for k,profiler in pairs(gAllRoughProfilers) do profiler:SpikeFrame(bSum) end
end


-- ***** ***** ***** ***** ***** Selective Profiler

function Profile_GetQuickMemoryLua	() return (collectgarbage("count") or 0) * 1024 end -- in bytes
function Profile_GetQuickMemoryOgre	() return gNoOgre and 0 or OgreMemoryUsage("all") end -- in bytes
		 Profile_GetQuickTime			= Client_GetTicks

function GetCallStackDepth 			()  local res = 0 while (debug.getinfo(res,"")) do res = res + 1 end return res end

gLuaFunctionProfileHookData = {}
gLuaFunctionProfileHookActive = false
function LuaFunctionProfileHook  (sEvent)
	if (sEvent == "call") then
		local d = gLuaFunctionProfileHookDepth + 1
		gLuaFunctionProfileHookDepth = d

		local parent = gLuaFunctionProfileHookData[d-1]
		local started = gLuaFunctionProfileHookData[d]
		
		
		local myname = debug.getinfo(2,"n").name
		local calledfrom = debug.getinfo(3,"Sl")
		myname = calledfrom.short_src..":"..calledfrom.currentline..":"..(myname or "?")
		
		print(" "..d.." call",myname)
		
		--[[
		if (gLuaFunctionProfileHookDepth == gMyHookDepth_Watch or gLuaFunctionProfileHookDepth == gMyHookDepth_Watch2) then
			local myname = debug.getinfo(2,"n").name
			local calledfrom = debug.getinfo(3,"Sl")
			gMyHookCurrentName[d] = calledfrom.short_src..":"..calledfrom.currentline..":"..(myname or "?")
			gMyHookCurrentStartT[d] = Client_GetTicks()
			gMyHookCurrentOpen[d] = true
			--~ {source="=[C]",name="Client_RenderOneFrame",short_src="[C]",}
			--~ {source="@../lua/net/net.other.lua",name="PingStep",short_src="../lua/net/net.other.lua",}

			--~ print("MyLuaHook",gMyHookCurrentName[d])
		end
		]]--
	elseif (sEvent == "return" or sEvent == "tail return") then
		local d = gLuaFunctionProfileHookDepth
		local parent = gLuaFunctionProfileHookData[d-1]
		if (parent) then 
			-- monitored subcall ended
			print("ProfileSubCalls:sub:d="..d.."\n")
		end
		local ended = gLuaFunctionProfileHookData[d]
		if (ended) then 
			--~ local dt = Client_GetTicks() - gMyHookCurrentStartT[d]
			--~ if (dt > 60) then print(dt,d,gMyHookCurrentName[d]) end
			--~ gMyHookCurrentName[d] ~= "../lua/main.lua:469:Client_USleep"
			print("ProfileSubCalls:d="..d..":end",SmartDump(ended))
			gLuaFunctionProfileHookData[d] = nil
		end
		gLuaFunctionProfileHookDepth = d - 1
	else
		print("LuaFunctionProfileHook : unexpected event",sEvent)
	end
end



function ProfileSubCalls (contextname) 
	if (not gLuaFunctionProfileHookActive) then 
		gLuaFunctionProfileHookActive = true 
		gLuaFunctionProfileHookDepth = GetCallStackDepth()
		debug.sethook(LuaFunctionProfileHook,"cr")
	end
	local d = gLuaFunctionProfileHookDepth - 1
	print("ProfileSubCalls:d="..d..":start\n")
	gLuaFunctionProfileHookData[d] = {contextname=contextname}
end
	
	
function PT_A1 () 
	--~ print("A1") 
end
function PT_A2 () 
	--~ print("A2") 
end
function PT_A3 () 
	--~ print("# A3 start") 
	ProfileSubCalls("A3") 
	PT_A31() 
	PT_A32() 
	PT_A33() 
	--~ print("# A3 end") 
end
function PT_A31 () 
	--~ print("A31") 
end
function PT_A32 () 
	--~ print("A32") 
end
function PT_A33 () 
	--~ print("A33") 
end
function PT_A4 () 
	--~ print("A4") 
end
function PT_A5 () 
	--~ print("A5") 
end
function PT_A ()
	--~ print("# A START")
	ProfileSubCalls("A")
	PT_A1()
	PT_A2()
	PT_A3()
	PT_A4()
	PT_A5()
	--~ print("# A END")
end
--~ print("#begin")
--~ PT_A()

--~ os.exit(0)








-- ***** ***** ***** ***** ***** Global Profiler
-- was meant to be used to profile the programs mainloop and important subfunctions for memory(ogre,lua) and time usage, with automatic naming
-- didn't work out that well yet, too much overhead caused.. see RoughProfiler above for a manual alternative

function StartGlobalProfiler2 () 
	gGlobalProfiler2Depth		= GetCallStackDepth()
	gGlobalProfiler2DepthMin	= gGlobalProfiler2Depth - 1
	gGlobalProfiler2DepthMax	= gGlobalProfiler2DepthMin + 8
	
	print("GlobalProfiler2 min,max=",gGlobalProfiler2DepthMin,gGlobalProfiler2DepthMax)
	debug.sethook(GlobalProfiler2Hook,"cr")
end

gGlobalProfiler2Data = {}
function GlobalProfiler2Hook (sEvent)
	if (sEvent == "call") then
		local d = gGlobalProfiler2Depth + 1
		gGlobalProfiler2Depth = d
		
					--~ local myname = debug.getinfo(2,"n").name
					--~ local calledfrom = debug.getinfo(3,"Sl")
					--~ myname = calledfrom.short_src..":"..calledfrom.currentline..":"..(myname or "?")
					--~ print("p2call",d,myname)
					

		if (d >= gGlobalProfiler2DepthMin and 
			d <= gGlobalProfiler2DepthMax) then
			gGlobalProfiler2Data[d] = {
				t = Client_GetTicks(),
				memL = Profile_GetQuickMemoryLua(),
				memO = Profile_GetQuickMemoryOgre(),
			}
		end
		
	elseif (sEvent == "return" or sEvent == "tail return") then
		local d = gGlobalProfiler2Depth
		--~ print("p2ret ",d)
		
		if (d >= gGlobalProfiler2DepthMin and 
			d <= gGlobalProfiler2DepthMax) then
			local o = gGlobalProfiler2Data[d]
			if (o) then
				local dt		= Client_GetTicks()				- o.t
				local dmemL		= Profile_GetQuickMemoryLua()	- o.memL
				local dmemO		= Profile_GetQuickMemoryOgre()	- o.memO
				if (dt > 150 or dmemL > 300*1024 or dmemO > 300*1024) then
					local myname = debug.getinfo(2,"n").name
					local calledfrom = debug.getinfo(3,"Sl")
					myname = calledfrom.short_src..":"..calledfrom.currentline..":"..(myname or "?")
					
					print(sprintf("%5d msec L=%8d O=%8d",dt,dmemL,dmemO),myname)
				end
			--~ else 
				--~ -- happens once on the return of StartGlobalProfiler2()
				--~ print("ERROR GlobalProfiler2Hook gGlobalProfiler2Data[d] not set for d=",d)
				--~ gBla = (gBla or 0) + 1  if (gBla > 10) then os.exit(0) end
			end
		end
		gGlobalProfiler2Depth = d - 1
	end
end

function Profiler2Test_T () Client_USleep(300) end
function Profiler2Test_MemL ()
	if (not gProfiler2Test_MemLData) then gProfiler2Test_MemLData = {} end
	local x = {}
	for i = 1,300*1024/4 do table.insert(x,i) end
	table.insert(gProfiler2Test_MemLData,x)
end

function Profiler2Test_All ()
	Profiler2Test_T()
	Profiler2Test_MemL()
end

--~ Profile_GetQuickMemoryOgre = function () return 0 end
--~ StartGlobalProfiler2()
--~ print("a1")
--~ Profiler2Test_T()
--~ print("a2")
--~ Profiler2Test_MemL()
--~ print("a3")
--~ os.exit(0)


-- ***** ***** ***** ***** ***** memory treesize

function MemTreeSizeStringEscape (s)
	return string.gsub(s,"[^a-zA-Z0-9]","_")
end

function MemTreeSize_DumpMemToFile (fp,obj,name,iAllowGlobals)
	local t = type(obj)
	if (t == "table") then 
		local l = 8
		if (obj == gMemTreeSize_AlreadyDumped) then return l end
		if (obj == gMemTreeSize_RemainingWeakLinks) then return l end
		if ((iAllowGlobals <= 0) and gMemTreeSize_GlobalsByValue[obj]) then return l end
		if (obj.debug_memtreesize_name) then name = name.."("..obj.debug_memtreesize_name..")" end
		--~ fp:write("(t")
		if (not gMemTreeSize_AlreadyDumped[obj]) then
			gMemTreeSize_AlreadyDumped[obj] = true
			gMemTreeSize_Level = gMemTreeSize_Level + 1
			for k,v in pairs(obj) do 
				local subname
				local bWeakLink = false
				if (type(k) == "string") then
					subname = name..":"..MemTreeSizeStringEscape(k)
					--~ fp:write(",\n"..string.rep(" ",gMemTreeSize_Level)..MemTreeSizeStringEscape(k).."=")
					if (k == "parentwidget" or
						k == "init_parentwidget" or
						k == "ordered_childlist" or -- if accessable by a global, will be listed there, otherwise retains path
						k == "child_handle_lookup" or
						false) then bWeakLink = true end
				else
					subname = name..":???"
					--~ fp:write(",")
				end
				l = l + MemTreeSize_DumpMemToFile(fp,k,subname,iAllowGlobals-1)
				if (bWeakLink) then
					l = l + 8
					local oldpath = gMemTreeSize_RemainingWeakLinks[v]
					if ((not oldpath) or string.len(oldpath) > string.len(subname)) then
						gMemTreeSize_RemainingWeakLinks[v] = subname
					end
				else
					l = l + MemTreeSize_DumpMemToFile(fp,v,subname,iAllowGlobals-1)
				end
			end
			gMemTreeSize_Level = gMemTreeSize_Level - 1
		end
		fp:write(string.rep(" ",gMemTreeSize_Level)..name..":"..l.."\n")
		--~ fp:write(":"..l..")")
		--~ fp:write(":"..l..")")
		return l
	elseif (t == "userdata") then 
		local l = 100 -- just a guess
		--~ fp:write("u")
		return 8+l
	elseif (t == "string") then 
		local l = string.len(obj)
		--~ fp:write("s"..l)
		return 8+l
	elseif (t == "number") then 
		--~ fp:write("n")
		return 8
	elseif (t == "boolean") then 
		--~ fp:write("b")
		return 8
	elseif (t == "function") then 
		local l = 100 -- just a guess
		--~ fp:write("f")
		return 8+l
	elseif (t == "thread") then 
		local l = 100 -- just a guess
		--~ fp:write("h")
		return 8+l
	end
end

function MemTreeSize_DumpCurrentGlobalMem (filepath)
	gMemTreeSize_RemainingWeakLinks = {}
	gMemTreeSize_AlreadyDumped = {}
	gMemTreeSize_GlobalsByValue = {}
	gMemTreeSize_Level = 0
    local fp = io.open(filepath,"w")
	local totalmem = 0
	for k,v in pairs(_G) do gMemTreeSize_GlobalsByValue[v] = true end
	totalmem = totalmem + MemTreeSize_DumpMemToFile(fp,_G,"_G",2)
	for parent,subname in pairs(gMemTreeSize_RemainingWeakLinks) do 
		if (not gMemTreeSize_AlreadyDumped[parent]) then totalmem = totalmem + MemTreeSize_DumpMemToFile(fp,parent,subname,9) end
	end
	fp:write("total mem detected = "..totalmem)
    fp:close()
end
