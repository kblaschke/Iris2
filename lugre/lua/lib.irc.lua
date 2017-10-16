
-- function FIFO_PushPlainText (fifo,s) fifo:PushFilledString(s,string.len(s)+1) end

kIRC_DefaultPort = 6667

-- irc connection prototype (class)
gIRCConnectionPrototype = {}
-- current connection state
gIRCConnectionPrototype.IsConnected = function(self)
	return self.con and self.con:IsConnected()
end
-- joins a channel (this will NOT add # to the channel name)
gIRCConnectionPrototype.JoinChannel = function(self,channel,pass)
	self:SendLine("JOIN " .. channel .. (pass and (" "..pass) or ""))
end
--sends a message to a channel if target is channel or to a user if target is username
gIRCConnectionPrototype.SendMessage = function(self,target,message)
	self:SendLine("PRIVMSG " .. target .. " :" .. message)
end
-- destory
gIRCConnectionPrototype.Destroy = function(self,quitmsg)
	if self.fifo_in then self.fifo_in:Destroy() end
	
	if self.con then 
		self:SendLine(quitmsg or "QUIT")
		self.con:Destroy()
	end
end
-- sends a line (adds \n)
gIRCConnectionPrototype.SendLine = function(self,line)
	if not self:IsConnected() then return end
	
	print("DEBUG:IRC:send",">"..tostring(line).."<")
	
	local fifo = CreateFIFO()
	FIFO_PushPlainText(fifo,line .. "\r\n")
	self.con:Push(fifo)
	NetReadAndWrite()
	fifo:Clear()
	fifo:Destroy()
end
-- update net stuff and recieve messages
gIRCConnectionPrototype.Step = function(self)
	NetReadAndWrite()
	if (not self.con:IsConnected()) then return 0 end

	self.con:Pop(self.fifo_in)
	
	-- read messages
	local line = self.fifo_in:PopTerminatedString("\r\n")
	local lines = 0
	while line do
		lines = lines + 1
		-- parse message
		
		local pos = 0
		local sender = ""
		local command = ""
		local param = ""
		local message = ""
		
		
		if string.find(line," ",pos) then
			sender = trim(string.sub(line,pos,string.find(line," ",pos)))
			pos = string.find(line," ",pos) + 1
		end
		
		if string.find(line," ",pos) then
			command = trim(string.sub(line,pos,string.find(line," ",pos)))
			pos = string.find(line," ",pos) + 1
		end
		
		if string.find(line," ",pos) then
			param = trim(string.sub(line,pos,string.find(line," ",pos)))
			pos = string.find(line," ",pos) + 1
		end
		
		if string.find(line,"\r\n",pos) then
			message = trim(string.sub(line,pos,string.find(line,"\r\n",pos)))
			message = trim(message,":")
		end
		
		
		local nick = trim(sender,":")
		if string.find(nick,"!",0) then
			nick = string.sub(nick,0,string.find(nick,"!",0))
			nick = trim(nick,"!")
		end

		-- notify message recieved
		-- o.OnMessage = function (self,sender,channel,message)
		if command == "PRIVMSG" and self.OnMessage then
			-- :hagish!~hagish@p57AE5E57.dip.t-dialin.net PRIVMSG #zocken :fdgdfgsdfgdfg	
			
			job.create(function () 
				local success,errormsg_or_result = lugrepcall(function () self:OnMessage(nick,param,message) end)
				if (not success) then print("irc:error in message callback",errormsg_or_result) end
			end)
		end
		
		
		local a,b
		local msg_prefix
		local msg_command
		local msg_params
		if (string.find(line,"^:")) then 
			a,b,msg_prefix,msg_command,msg_params = string.find(line,"^:([^ ]+) ([^ ]+) (.*)\r\n$")
		else 
			a,b,msg_command,msg_params = string.find(line,"([^ ]+) (.*)\r\n$")
		end
		
		local RPL_MOTD = "372"
		local RPL_UMODEIS = "221"

			
		--~ print("DEBUG",tostring(sender) .. "|" .. tostring(command) .. "|" .. tostring(param) .. "|" .. tostring(message))
		if (msg_command ~= RPL_MOTD) then 
			--~ print("DEBUG:IRC",">"..tostring(msg_command).."<",">"..tostring(msg_params).."<",">"..tostring(string.gsub(line,"\r\n$","")).."<")
			print("DEBUG:IRC:recv",">"..tostring(string.gsub(line,"\r\n$","")).."<")
		end
		
		if (msg_command == RPL_UMODEIS) then -- final login message on quakenet 
			if (self.on_login_complete) then self:on_login_complete() end
		end
		if (msg_command == "PING") then
			local a,b,daemon = string.find(msg_params,"^:(.*)")
			if (not daemon) then daemon = tostring(msg_params) end
			-- quakenet sends  >PING :424867537<  so we just remove the :
			-- zw sends        >PING :zwischenwelt.org< 
			print("IRC: got ping, sending pong.. daemon="..daemon)
			self:SendLine("PONG "..daemon)
		end
		-- DEBUG   PING|||zwischenwelt.org

		-- read out next line
		line = self.fifo_in:PopTerminatedString("\r\n")
	end
	
	return lines
end

-- opens a connection to an irc server and returns the object handling this connection
function CreateIRCConnection(host,port,nick,password)
	local con = NetConnect(host,port or kIRC_DefaultPort)
	
	-- return nil on error
	if (not con or not con:IsConnected()) then return nil end
	
	local o = {}
	ArrayOverwrite(o,gIRCConnectionPrototype)
	o.con = con
	o.fifo_in = CreateFIFO()
	
	repeat until o:Step() > 0

	if pass then o:SendLine("PASS " .. pass) end
	o:SendLine("NICK " .. nick)
	o:SendLine("USER " .. nick .. " " .. nick .. " " .. host .. " :" .. nick)
	
	return o
end

--[[
-- http://tools.ietf.org/html/rfc1945
function HTTPGetEx (host,port,file)
	local fifo = CreateFIFO()
	local con = NetConnect(host,port)
	fifo:Clear()
	local s = "GET " .. file .. " HTTP/1.0\r\n"
		s = s.."Host: "..host.."\r\n"
		s = s.."\r\n"
	FIFO_PushPlainText(fifo,s)
	con:Push(fifo)
	fifo:Clear()
	NetReadAndWrite()
	while true do
		NetReadAndWrite()
		con:Pop(fifo)
		if (not con:IsConnected()) then break end
	end
	local len = fifo:Size()
	local res = fifo:PopFilledString(len)
	fifo:Destroy()
	con:Destroy()
	return res
end
]]--
