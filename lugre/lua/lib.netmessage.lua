-- defines message types used for networking

--[[
	RecvNetMessages (fifo,callback)

	-- receive messages from clients
	RecvNetMessages(myplayer.netRecvFifo,function (msgtype,...) 
			local msgtypename = gNetMessageTypeName[msgtype]
			if (gMessageTypeHandler_Server[msgtypename]) then 
				gMessageTypeHandler_Server[msgtypename](myplayer,unpack(arg))
			end
			NotifyListener("Hook_Server_RecvNetMsg",myplayer,msgtype,unpack(arg))
		end)
		
	FPush(gSendFifo,gNetMessageParamFormat[msgtype],...)

	gMessageTypeHandler_Client.kNetMessage_Chat = function (iParam,iFlags,sChatText)  .. end
	
	RegisterNetMessageType("kNetMessage_Chat"						,"iis")			-- sent by server and client : param,flags,chattext (used for client and server, if from client then param = target else param = from)
			
	RegisterNetMessageFormatWrapper("o","i",function (obj) return obj and obj.id or 0 end,  -- obj2id  
											function (objid) return GetObject(objid) end)	-- id2obj

]]--



gSendFifo = CreateFIFO()
gUDPRecvFifo = CreateFIFO()
giNextNetMessageTypeID = 1
gNetMessageParamFormat = {}
gNetMessageTypeName = {}
gNetMessageFormatWrapper_ByCustom = {}

kNetFirstByte = 0x85 -- 7334 for GS, don't ask

function RegisterNetMessageType (name,paramformat,forcedid)
	if (giNextNetMessageTypeID == kNetFirstByte) then giNextNetMessageTypeID = giNextNetMessageTypeID + 1 end
	local msgtype = forcedid or giNextNetMessageTypeID
	if (not forcedid) then giNextNetMessageTypeID = giNextNetMessageTypeID + 1 end
	assert(not _G[name],"RegisterNetMessageType : type with this name already known ! "..name)
	_G[name] = msgtype
	gNetMessageTypeName[msgtype] = name
	gNetMessageParamFormat[msgtype] = paramformat
end

-- use FALSE instead of NIL here, nil in the middle confuses the variable argument syntax
function RegisterNetMessageFormatWrapper (letter_custom,letter_real,custom2real,real2custom)
	gNetMessageFormatWrapper_ByCustom[	letter_custom] = {	letter_custom	=letter_custom,
															letter_real		=letter_real,
															custom2real		=custom2real,
															real2custom		=real2custom }
end

--[[
unused so far...
kNetDataTypes = {}
kNetDataTypes["b"] = 1	-- b byte(uint8) 
kNetDataTypes["i"] = 2	-- i int(int32) 
kNetDataTypes["u"] = 2	-- i int(uint32) 
kNetDataTypes["f"] = 3	-- f float(4 byte) 
kNetDataTypes["s"] = 4	-- s string(len_uint32,text_ascii) 
kNetDataTypes["#"] = 5	-- # fifo(len_uint32,data_raw) 
kNetDataTypes["_"] = 6	-- _ variable argument count, each prefixed with 1 byte type
kNetDataTypes["t"] = 	-- t a simple table
]]--

-- formattet pop
-- paramformat is something like "iiifffffff"
-- extracts data from fifo, and returns it as an array
--  b byte(uint8) 
--  i int(int32) 
--  u int(uint32) 
--  f float(4 byte) 
--  s string(len_uint32,text_ascii) 
--  t simple table -- see lib.fifo.lua
function FPop (fifo,paramformat) 
	local res = {}
		
	--print("FPop",paramformat,fifo:Size()) 
	for c in string.gfind(paramformat,".") do
		
		local wrapper = gNetMessageFormatWrapper_ByCustom[c]
		local realc = wrapper and wrapper.letter_real or c
		local resultpart
		
			if (realc == "b") then resultpart = fifo:PopNetUint8() 	
		elseif (realc == "i") then resultpart = fifo:PopNetInt32()
		elseif (realc == "u") then resultpart = fifo:PopNetUint32()
		elseif (realc == "p") then resultpart = fifo:PopPointer()
		elseif (realc == "x") then resultpart = CreateFIFOFromCrossThreadHandle(fifo:PopPointer())
		elseif (realc == "f") then resultpart = fifo:PopF()
		elseif (realc == "s") then resultpart = fifo:PopS()	 	
		elseif (realc == "t") then 
			local datalen = fifo:PopNetUint32()
			resultpart = FIFOPopNetSimpleTable(fifo)
		elseif (realc == "#") then  -- fifo : datalen,data
			local datalen = fifo:PopNetUint32()
			resultpart = CreateFIFO()
			fifo:PopFIFO(resultpart,datalen)
		elseif (realc == ".") then -- variable argument count : datalen,fmtlen,fmtstring,data
			local datalen = fifo:PopNetUint32()
			local fmt = fifo:PopS()
			local data = CreateFIFO()
			fifo:PopFIFO(data,datalen)
			local varargs = {FPop(data,fmt)} -- only floats and strings
			data:Destroy()
			for k,v in pairs(varargs) do table.insert(res,v) end
		else assert(false,"illegal paramformat") end
		
		if (resultpart) then 
			if (wrapper) then resultpart = wrapper.real2custom(resultpart) end
			table.insert(res,resultpart) 
		end
		
	end
	return unpack(res)
end

-- see also FPop
function FPush (fifo,paramformat,...) 
	--~ print("FPush",fifo,">"..tostring(paramformat).."<",...)
	local arg = {...}
	local i = 1
	local flen = #paramformat
	for i = 1,flen do 
		local c = paramformat:sub(i,i)
		local x = arg[i]
		
		local wrapper = gNetMessageFormatWrapper_ByCustom[c]
		if (wrapper) then
			c = wrapper.letter_real
			x = wrapper.custom2real(x)
		end
		
		-- print("####",c,x,type(x))
		if (c ~= ".") then assert(x,"not enough params for format "..paramformat.." missing=#"..i) end
			if (c == "b") then assert(type(x) == "number","byte :number expected")	fifo:PushNetUint8(x)	
		elseif (c == "i") then assert(type(x) == "number","int  :number expected")	fifo:PushNetInt32(x)	
		elseif (c == "u") then assert(type(x) == "number","uint  :number expected")	fifo:PushNetUint32(x)	
		elseif (c == "f") then assert(type(x) == "number","float:number expected")	fifo:PushF(x)
		elseif (c == "s") then assert(type(x) == "string","string expected")		fifo:PushS(x)	
		elseif (c == "p") then assert(type(x) == "userdata","userdata expected")	fifo:PushPointer(x)	
		elseif (c == "x") then assert(type(x) == "table","fifo expected")			fifo:PushPointer(x:GetCrossThreadHandle())	
		elseif (c == "t") then 
			assert(type(x) == "table","table expected")		
			local f = CreateFIFO()
			FIFOPushNetSimpleTable(x,f)
			fifo:PushNetUint32(f:Size())
			fifo:PushFIFO(f)
			f:Destroy()
		elseif (c == "#") then assert(type(x) == "table","fifo expected")			fifo:PushNetUint32(x:Size()) fifo:PushFIFO(x)
		elseif (c == ".") then 
			local fmt = ""
			local data = CreateFIFO()
			while (x) do
					if (type(x) == "number") then fmt = fmt.."f" data:PushF(x) 
				elseif (type(x) == "string") then fmt = fmt.."s" data:PushS(x)	
				else assert(false,"illegal var-arg-paramformat") end
				i = i + 1
				x = arg[i]
			end
			fifo:PushNetUint32(data:Size()) 
			fifo:PushS(fmt) 
			fifo:PushFIFO(data)
		else assert(false,"illegal paramformat") end
		i = i + 1
	end
end

-- WARNING ! returns nil for variable message length, e.g. string..., see IsNetMessageComplete for those
function CalcNetMessageParamLength (paramformat) 
	local res = 0
	for c in string.gfind(paramformat,".") do
		local wrapper = gNetMessageFormatWrapper_ByCustom[c]
		if (wrapper) then c = wrapper.letter_real end
			if (c == "b") then res = res + 1
		elseif (c == "i") then res = res + 4
		elseif (c == "u") then res = res + 4
		elseif (c == "f") then res = res + 4
		elseif (c == "p") then res = res + GetPointerSize()
		elseif (c == "x") then res = res + GetPointerSize()
		elseif (c == "s") then return nil -- variable length not calculatable without peek
		elseif (c == "t") then return nil -- variable length not calculatable without peek
		elseif (c == "#") then return nil -- variable length not calculatable without peek
		elseif (c == ".") then return nil -- variable length not calculatable without peek
		else assert(false,"illegal paramformat") end
	end
	return res
end

-- true if string or vararg or other data with not fixed length is contained
function IsNetMessageVariableLength (paramformat) return CalcNetMessageParamLength(paramformat) == nil end

function IsNetMessageComplete (fifo,paramformat,startoffset) 
	local len = CalcNetMessageParamLength(paramformat)  -- only works for fixed length messages
	if (len) then return fifo:Size() - startoffset >= len end
	
	-- variable length message
	local fifosize = fifo:Size()
	local curpos = startoffset
	local partsize
	for c in string.gfind(paramformat,".") do
		local wrapper = gNetMessageFormatWrapper_ByCustom[c]
		if (wrapper) then c = wrapper.letter_real end
		--print(" IsNetMessageComplete c=",c,"curpos=",curpos)
			if (c == "b") then partsize = 1
		elseif (c == "i") then partsize = 4
		elseif (c == "u") then partsize = 4
		elseif (c == "f") then partsize = 4
		elseif (c == "p") then partsize = GetPointerSize()
		elseif (c == "x") then partsize = GetPointerSize()
		elseif (c == "s") then partsize = 4 
			if (partsize > fifosize-curpos) then return false end
			--print(" stringlen=",fifo:PeekNetUint32(curpos),"atpos",curpos)
			partsize = partsize + fifo:PeekNetUint32(curpos) -- peek stringlength
		elseif (c == "#") or (c == "t") then partsize = 4 
			if (partsize > fifosize-curpos) then return false end
			--print(" stringlen=",fifo:PeekNetUint32(curpos),"atpos",curpos)
			partsize = partsize + fifo:PeekNetUint32(curpos) -- peek fifolength
		elseif (c == ".") then partsize = 8 
			if (partsize > fifosize-curpos) then return false end
			partsize = partsize + fifo:PeekNetUint32(curpos) + fifo:PeekNetUint32(curpos+4) -- peek fifolength + fmt-stringlen
		else assert(false,"illegal paramformat") end
		if (partsize > fifosize-curpos) then return false end
		curpos = curpos + partsize
	end
	return true
end

-- msgtype is an id like kNetMessage_Chat
function SendNetMessage (con,msgtype,...)
	if not con then return end
	gSendFifo:Clear()
	SendNetMessageFifo(gSendFifo,msgtype,...)
	--gSendFifo:HexDump()
	con:Push(gSendFifo)
end

function SendNetMessageFifo (fifo,msgtype,...)
	fifo:PushUint8(msgtype)
	FPush(fifo,gNetMessageParamFormat[msgtype],...)
end


-- pops all complete messages from the fifo and calls callback for each of them
-- fifo should be individual for this connection, in case half messages arrive
-- usually mycon:Pop(fifo) is called right before this
-- callback(msgtype,args...)
function RecvNetMessages (fifo,callback)
	while RecvOneNetMessage(fifo,callback) do end
end

-- reads on message if there is one and calls the handler
-- returns true if there are messages left
function RecvOneNetMessage (fifo,callback)
	if (fifo:Size() > 0) then
		local msgtype = fifo:PeekNetUint8(0)
		local paramformat = gNetMessageParamFormat[msgtype]
		local packetinfo = sprintf("RecvNetMessages %s[%d] format=%s fifosize=%d",gNetMessageTypeName[msgtype] or "unknown",msgtype,paramformat or "?",fifo:Size())
		if (not paramformat) then FatalErrorMessage("unknown netmessagetype "..packetinfo) end
		
		-- check if complete, and activate callback if it is
		if (IsNetMessageComplete(fifo,paramformat,1)) then
			fifo:PopRaw(1)
			local params = {FPop(fifo,paramformat)}
			
			-- log
			if gNoLogNetMessages then
				-- TODO this seems strange!!!!
				if (not in_array(msgtype,gNoLogNetMessages)) then
					printdebug("net",packetinfo.." : "..arrdump(params))
					--fifo:HexDump()
				end
			end
			
			local success,errormsg = lugrepcall(callback,msgtype,unpack(params))
			if (not success) then NotifyListener("lugre_error","error in RecvNetMessages",packetinfo,"\n",errormsg) end
		else
			--print("incomplete : ",packetinfo)
			return false
		end
	end
	
	return fifo:Size() > 0
end

