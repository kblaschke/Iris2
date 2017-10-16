--  Client_GetTicks()
cRegistry = CreateClass()

cRegistry.kCommand_Set			= 1
cRegistry.kCommand_SetField		= 2
cRegistry.kMinChangesForRewrite = 100

function cRegistry:New (...) return CreateClassInstance(cRegistry,...) end

function cRegistry:Init (sFilePath)	
	self.fifo = CreateFIFO()
	self.linec = 0
	self.rewritelinec = cRegistry.kMinChangesForRewrite
	self.data = {}
	
	self.sFilePath = sFilePath
	self:_Load(sFilePath)
end

function cRegistry:Destroy () self.fifo:Destroy() end

function cRegistry:Get (name) return self.data[name] end

-- set value=nil to remove
function cRegistry:Set (name,value)	
	self.data[name] = value
	self.fifo:PushUint8(self.kCommand_Set)
	self:_Push(name)
	self:_Push(value)
	self:_MarkChange()
end

-- for advanced users only
-- set value=nil to remove
function cRegistry:SetField (name,fieldname,value)	
	local arr = self.data[name] if (not arr) then arr = {} self.data[name] = arr end
	arr[fieldname] = value
	self.fifo:PushUint8(self.kCommand_SetField)
	self:_Push(name)
	self:_Push(fieldname)
	self:_Push(value)
	self:_MarkChange()
end



-- ***** ***** ***** ***** ***** internal


-- internal
-- load from file
function cRegistry:_Load (sFilePath)
	local fifo = self.fifo
	fifo:Clear()
	fifo:ReadFromFile(sFilePath)
	self.data = {}
	local c = 0
	while fifo:Size() > 0 do
		c = c + 1
		local cmd = fifo:PopNetUint8(0)
		if (cmd == self.kCommand_Set) then 
			local name	= self:_Pop()
			local value	= self:_Pop()
			self.data[name] = value
		elseif (cmd == self.kCommand_SetField) then 
			local name		= self:_Pop()
			local fieldname	= self:_Pop()
			local value		= self:_Pop()
			local arr = self.data[name] if (not arr) then arr = {} self.data[name] = arr end
			arr[fieldname] = value
		end
	end
	self.linec = c
	self.rewritelinec = c * 2 + cRegistry.kMinChangesForRewrite
	fifo:Clear()
end




-- internal
function cRegistry:_Push	(data)		FIFOPushNetSimpleTable(data,self.fifo) end
function cRegistry:_Pop		()	return	FIFOPopNetSimpleTable(self.fifo) end
	-- hagish: FIFOPushNetSimpleTable: bFloat=floor(f)==f  .. warum string als type?

--~ local fifo = CreateFIFO()
--~ local v = 0x12345678 fifo:PushUint32(v) print("fifo pushpop32 test") assert(v==fifo:PopUint32()) 
--~ fifo:Destroy()
	

-- internal
-- register change, and check for rewrite
function cRegistry:_MarkChange ()
	self.linec = self.linec + 1
	if (self.linec > self.rewritelinec) then 
		-- too many changes, rebuild from scratch
		self.fifo:Clear()
		local datac = 0
		self.linec = 0
		for k,v in pairs(self.data) do
			datac = datac + 1
			self:Set(k,v)
		end
		self.rewritelinec = datac * 2 + cRegistry.kMinChangesForRewrite
		self.fifo:WriteToFile(self.sFilePath)
		self.fifo:Clear()
	else
		self.fifo:AppendToFile(self.sFilePath)
		self.fifo:Clear()
	end
end

function RegTest ()
	local myreg = cRegistry:New("../myreg.reg")
	if (not myreg:Get("init")) then
		print("NEED INIT")
		myreg:Set("init",true)
		myreg:Set("test","lalala")
		myreg:Set("bummm",123)
		myreg:Set("warum",{antwort=42,boing={bla={blub=3}}})
	else 
		for k,v in pairs(myreg.data) do 
			print(k,SmartDump(v))
		end
		print("warum",SmartDump(myreg:Get("warum").boing.bla))
	end
	os.exit(0)
end
--~ RegTest()
