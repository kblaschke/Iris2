
function URLEncodeChar(c)
	return sprintf("%%%02x",string.byte(c))
end

function URLEncode(s)
	return string.gsub(s,"[^%w]",URLEncodeChar)	
end

function FIFO_PushPlainText (fifo,s) fifo:PushFilledString(s,string.len(s)) end

function URLEncodeArr(arr) 
	local res = ""
	for k,v in pairs(arr) do 
		if (res ~= "") then res = res .. "&" end
		res = res..URLEncode(k).."="..URLEncode(v) 
	end
	return res
end

-- search first double-newline and return everything after that
function HTTP_GetResponseContent (response)
	local sepstart,sepend = string.find(response,"\r\n\r\n")
	if (not sepstart) then return response end
	return string.sub(response,sepend+1)
end

function HTTP_MakeRequest (sHost,sPath)
	return "GET " .. sPath .. " HTTP/1.0\r\n"
			.."Host: "..sHost.."\r\n"
			.."\r\n"
end

-- http://tools.ietf.org/html/rfc1945
-- if bIgnoreReturnForSpeed is true, then it returns without waiting for an answer
-- this version is blocking, see also Threaded_HTTPRequest in lib.thread.lua for an asynchronous version
function HTTPGetEx (sHost,iPort,sPath,bIgnoreReturnForSpeed)
	local fifo = CreateFIFO()
	local con = NetConnect(sHost,iPort)
	if (not con) then return end 
	FIFO_PushPlainText(fifo,HTTP_MakeRequest(sHost,sPath))
	con:Push(fifo)
	local res = nil
	if (bIgnoreReturnForSpeed) then 
		NetReadAndWrite()
	else
		fifo:Clear()
		while true do
			NetReadAndWrite()
			con:Pop(fifo)
			if (not con:IsConnected()) then break end
		end
		res = fifo:PopFilledString(fifo:Size())
	end
	fifo:Destroy()
	con:Destroy()
	return res and HTTP_GetResponseContent(res)
end
