-- helper to handle simple network broadcast

-- ###################################################################

gBroadcastSenderPrototype = {}

-- call this to create a new broadcast sender
-- NewBroadcastSender(port)
function NewBroadcastSender( ... )
	local o = {}
	ArrayOverwrite( o, gBroadcastSenderPrototype )
	o:init(...)
	return o
end

-- constructor
function gBroadcastSenderPrototype:init	(port)
	self.miPort = port
	
	self.miUpdateInterval = 1000

	self.mSocket = Create_UDP_SendSocket()
	self.mSocket:SetBroadcast(1)

	self.mFIFO = CreateFIFO()

	self.mbJobRunning = true

	self.mbBroadcasting = false

	self.mData = {}
	
	-- broadcast thread
	job.create(function()
		while self.mbJobRunning do
			if self.mbBroadcasting and self.mFIFO and self.mSocket then
				local addr = AtoN("255.255.255.255")
				self.mSocket:Send(addr,self.miPort,self.mFIFO)
			end
			
			job.wait(self.miUpdateInterval)
		end
	end)
end

-- this sets the broadcasted data
-- data is a key=value table
-- value must be a primitive type (number,string,boolean)
-- data must not exceed udp packet size!!!
function gBroadcastSenderPrototype:SetData	(data)
	self.mData = data
	
	self.mFIFO:Clear()
	local f = self.mFIFO
	
	for k,v in pairs(data) do
		-- 0:bool 1:number 2:string
		local t = type(v)
		if t == "string" then
			f:PushS(k)
			f:PushNetUint8(2)
			f:PushS(v)
		elseif t == "number" then
			f:PushS(k)
			f:PushNetUint8(1)
			f:PushF(v)
		elseif t == "boolean" then
			f:PushS(k)
			f:PushNetUint8(0)
			if v then f:PushNetUint8(1) else f:PushNetUint8(0) end
		else
			print("gBroadcastSenderPrototype:SetData ignoring entry",k,tostring(v))
		end
	end
end

-- starts the broadcasting
-- after the given update interval the server sends the current data
function gBroadcastSenderPrototype:Start	()
	self.mbBroadcasting = true
end

-- stop the current broadcasting process
-- this does not destroy the socket
-- you can safely call Start to resume broadcasting after this
function gBroadcastSenderPrototype:Stop	()
	self.mbBroadcasting = false
end

-- call this to destroy the object
function gBroadcastSenderPrototype:Destroy	()
	self:Stop()
	
	self.mSocket:Destroy()
	self.mSocket = nil
	
	self.mFIFO:Destroy()
	self.mFIFO = nil
	
	self.mData = nil
	
	self.mbJobRunning = false
end

-- milliseconds between each server broadcast
function gBroadcastSenderPrototype:SetUpdateInterval	(milliseconds)
	self.miUpdateInterval = milliseconds
end


-- ###################################################################

gBroadcastReceiverPrototype = {}

-- call this to create a new broadcast Receiver
-- NewBroadcastReceiver(port)
function NewBroadcastReceiver( ... )
	local o = {}
	ArrayOverwrite( o, gBroadcastReceiverPrototype )
	o:init(...)
	return o
end

-- constructor
function gBroadcastReceiverPrototype:init	(port)
	self.miPort = port
	
	self.mSocket = Create_UDP_ReceiveSocket(port)

	self.mFIFO = CreateFIFO()
	
	self.miCheckInterval = 100
	
	self.mUpdateCallback = nil
	self.mlServer = {}
	
	self.mbJobRunning = true

	-- receive thread
	job.create(function()
		while self.mbJobRunning do
			if self.mFIFO and self.mSocket then
				self.mFIFO:Clear()
				
				local resultcode,remoteaddr = self.mSocket:Receive(self.mFIFO) 
				if (self.mFIFO:Size() > 0) then 
					self:ParseInput(resultcode,remoteaddr)
				end
			end
			
			job.wait(self.miCheckInterval)
		end
	end)
end

-- internal: parses the recieved data and calls the callback
function gBroadcastReceiverPrototype:ParseInput	(resultcode,remoteaddr)
	-- print("parse input",remoteaddr)
	-- print("from",NtoA(remoteaddr))
	local f = self.mFIFO
	local data = {}
	
	-- parse input fifo
	while f:Size() > 0 do
		-- 0:bool 1:number 2:string
		local k = f:PopS()
		local t = f:PopNetUint8()
		local v = nil
		-- print("k,t",k,t)
		if t == 2 then
			-- print("4.1")
			data[k] = f:PopS()
		elseif t == 1 then
			-- print("4.2")
			data[k] = f:PopF()
		elseif t == 0 then
			-- print("4.3")
			local b = f:PopNetUint8()
			if b > 0 then data[k] = true else data[k] = false end
		end
	end
	
	-- store data in server list
	self.mlServer[remoteaddr] = {address=NtoA(remoteaddr), last_received_time = Client_GetTicks(), data=data}
	
	if self.mUpdateCallback then self.mUpdateCallback(self, self.mlServer[remoteaddr]) end
end

-- sets the callback function fun(self,server)
-- server : {address="123.2.2.2", last_received_time = 23476, data={...}}
function gBroadcastReceiverPrototype:SetOnUpdate	(fun)
	self.mUpdateCallback = fun
end

-- milliseconds between each check
function gBroadcastSenderPrototype:SetCheckInterval	(milliseconds)
	self.miCheckInterval = milliseconds
end

-- call this to destroy the object
function gBroadcastReceiverPrototype:Destroy	()
	self.mSocket:Destroy()
	self.mSocket = nil
	
	self.mFIFO:Destroy()
	self.mFIFO = nil

	self.mlServer = nil
	self.mUpdateCallback = nil
	
	self.mbJobRunning = false
end

