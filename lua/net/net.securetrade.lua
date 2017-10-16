-- sectrade start is triggered by dragdropping a item onto a player
function gPacketHandler.kPacket_SecureTrade() -- PCK_SecureTrade	 0x6f
	local input = GetRecvFIFO()
	local popped_start = input:GetTotalPopped()
	local id = input:PopNetUint8()
	local iPacketSize = input:PopNetUint16()
	
	local sectrade = {}
	sectrade.action = input:PopNetUint8() -- (0=start,1=cancel,2=change checkmarks) : see kSecTradeAction_ 
	sectrade.serial1 = (iPacketSize - (input:GetTotalPopped() - popped_start) >= 4) and input:PopNetUint32() or 0
	sectrade.serial2 = (iPacketSize - (input:GetTotalPopped() - popped_start) >= 4) and input:PopNetUint32() or 0
	sectrade.serial3 = (iPacketSize - (input:GetTotalPopped() - popped_start) >= 4) and input:PopNetUint32() or 0
	local namefollow = (iPacketSize - (input:GetTotalPopped() - popped_start) >= 1) and (input:PopNetUint8() ~= 0)
	local namesize = 	iPacketSize - (input:GetTotalPopped() - popped_start) -- assert(namesize <= 30) ?
	sectrade.name = namefollow and namesize > 0 and input:PopFilledString(namesize)
	
	RecvSecureTrade(sectrade)
end

-- if both players agree the trade is finished automatically
-- s1 : containerid , s2 : 0 for no, 1 for yes
function Send_SecureTrade_ChangeAgree (s1,s2)
	local out = GetSendFIFO()
	out:PushNetUint8(kPacket_SecureTrade)
	out:PushNetUint16(17)
	out:PushNetUint8(kSecTradeAction_ChangeCheck)
	out:PushNetUint32(s1)
	out:PushNetUint32(s2)
	out:PushNetUint32(0)
	out:PushNetUint8(0)
	out:SendPacket()
end

function Send_SecureTrade_Cancel (s1)
	local out = GetSendFIFO()
	out:PushNetUint8(kPacket_SecureTrade)
	out:PushNetUint16(8)
	out:PushNetUint8(kSecTradeAction_Cancel)
	out:PushNetUint32(s1)
	out:SendPacket()
end
