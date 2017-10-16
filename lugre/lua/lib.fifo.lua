-- some helper functions to work with fifos

-- returns a string like "ff aa 12 00 01 "
-- offset defaults to 0
-- len defaults to rest
function FIFOHexDump_Old (fifo,offset,len) 
	offset = offset or 0
	len = len or (fifo:Size() - offset)
	local hexdump = ""
	for i = offset,offset+len-1 do 
		hexdump = hexdump .. sprintf("%02x ",fifo:PeekNetUint8(i))
	end
	return hexdump
end

function FIFOPushByteArray (fifo,bytes)
	for k,v in pairs(bytes) do fifo:PushNetUint8(v) end
end
	

-- size : maximal allowed pop-len
-- returns plaintext,unicodebytearr,sizeleft
function FIFO_PopZeroTerminatedUnicode (fifo,size)
	local plaintext = ""
	local unicodebytearr = {}
	while size >= 2 do
		size = size - 2
		local digit = fifo:PopNetUint16()
		if (digit == 0x0000) then break end
		plaintext = plaintext..string.char(digit)
		table.insert(unicodebytearr,digit)
	end
	return plaintext,unicodebytearr,size
end

-- size : maximal allowed pop-len
-- returns plaintext,sizeleft
function FIFO_PopZeroTerminatedString (fifo,size)
	local text = ""
	while size >= 1 do
		size = size - 1
		local digit = fifo:PopNetUint8()
		if (digit == 0x00) then break end
		text = text..string.char(digit)
	end
	return text,size
end


-- returns a string like "ff aa 12 00 01 "  with an asci dump next to it
-- offset defaults to 0
-- len defaults to rest
function FIFOHexDump (fifo,offset,len) 
	offset = offset or 0
	len = len or (fifo:Size() - offset)
	local out = ""
	local hexdump = ""
	local ascidump = ""
	local sep = "  |"
	local lineend =  "|\n"
	local bytesperline = 16
	local lastbyte = 0
	for i = offset,offset+len-1 do 
		local c = fifo:PeekNetUint8(i)
		hexdump = hexdump .. sprintf("%02x ",c)
		
		local a = (c >= 32 and c < 127) and sprintf("%c",c) or "."
		ascidump = ascidump .. a
		if (math.mod(i + 1,bytesperline) == 0) then
			out = out..hexdump..sep..ascidump..lineend
			hexdump = ""
			ascidump = ""
		end
		lastbyte = i
	end
	if (string.len(hexdump) > 0) then 
		for i = math.mod(lastbyte,bytesperline) + 2 , bytesperline do
			hexdump = hexdump .. "   "
		end
		out = out..hexdump..sep..ascidump..lineend 
	end
	return out
end


kFIFONetSimpleTableType_Nil			= 0
kFIFONetSimpleTableType_Boolean		= 1
kFIFONetSimpleTableType_Int			= 2
kFIFONetSimpleTableType_Float		= 3
kFIFONetSimpleTableType_String		= 4
kFIFONetSimpleTableType_Table		= 5

-- pushes a simple table (network compatible) onto the fifo
-- a simple table consists of simple table and basic types
-- so userdata, functions and threads possible
-- table keys should be basic data types (number,string,boolean)
-- TODO currently floats are broken !!!!!!!!!!!!!!!!!!!!!  (representation might be broken on different processors)
function FIFOPushNetSimpleTable(tbl, fifo)
	local t = type(tbl)
	-- print("push",t,tbl)
	-- nil, boolean, number, string, function, userdata, thread
	if t == "nil" then
		fifo:PushNetUint8(kFIFONetSimpleTableType_Nil)
	elseif t == "boolean" then
		fifo:PushNetUint8(kFIFONetSimpleTableType_Boolean)
		fifo:PushNetUint8(tbl and 1 or 0)
	elseif t == "number" then
		if floor(tbl) == tbl then
			-- int number
			fifo:PushNetUint8(kFIFONetSimpleTableType_Int)
			fifo:PushNetInt32(tbl)
		else
			-- float number
			fifo:PushNetUint8(kFIFONetSimpleTableType_Float)
			fifo:PushNetF(tbl)
		end
	elseif t == "string" then
		fifo:PushNetUint8(kFIFONetSimpleTableType_String)
		fifo:PushS(tbl)
	elseif t == "table" then
		fifo:PushNetUint8(kFIFONetSimpleTableType_Table)
		local n = countarr(tbl)
		fifo:PushNetUint32(n)
		for k,v in pairs(tbl) do
			FIFOPushNetSimpleTable(k, fifo)
			FIFOPushNetSimpleTable(v, fifo)
		end
	else
		print("ERROR FIFOPushNetSimpleTable",t,"is not a simple type")
	end
end

-- popper for FIFOPushNetSimpleTable tables, returns the popped table
function FIFOPopNetSimpleTable(fifo)
	local t = fifo:PopNetUint8()
	-- print("pop",t)
	-- nil, boolean, number, string, function, userdata, thread
	if t == kFIFONetSimpleTableType_Nil then
		return nil
	elseif t == kFIFONetSimpleTableType_Boolean then
		local r = fifo:PopNetUint8()
		return r == 1
	elseif t == kFIFONetSimpleTableType_Int then
		return fifo:PopNetInt32()
	elseif t == kFIFONetSimpleTableType_Float then
		return fifo:PopNetF()
	elseif t == kFIFONetSimpleTableType_String then
		return fifo:PopS()
	elseif t == kFIFONetSimpleTableType_Table then
		local tbl = {}
		local n = fifo:PopNetUint32()
		for i=1,n do
			local k = FIFOPopNetSimpleTable(fifo)
			local v = FIFOPopNetSimpleTable(fifo)
			-- print("tbl elem",type(k),k,type(v),v)
			tbl[k] = v
		end
		return tbl
	else
		print("ERROR FIFOPopNetSimpleTable wrong format in fifo found",t)
	end	
end



	--[[	testcode
	local t = {sebi="lala", [2]=true, {1,2,3,4,5},1.2}
	--local t = 1
	print(vardump_rec(t))
	local f = CreateFIFO()
	FIFOPushNetSimpleTable(t,f)
	local r = FIFOPopNetSimpleTable(f)
	print(vardump_rec(r))
		
	Terminate()
	]]
