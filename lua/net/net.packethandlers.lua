kGumpIDShopContainer		= hex2num("0x0030")
kGumpIDSpellbookContainer	= hex2num("0xFFFF")

-- create and/or show graphical representation of container
function gPacketHandler.kPacket_Open_Container() -- 0x24
	local input = GetRecvFIFO()
	local id = input:PopNetUint8()
	local containerdata = {}
	containerdata.serial = input:PopNetUint32()
	containerdata.gumpid = input:PopNetUint16()
	HandleOpenContainer(containerdata)
end

function gPacketHandler.kPacket_Open_Paperdoll() -- 0x88
	local input = GetRecvFIFO()
	local id = input:PopNetUint8()
	local paperdoll = {}
	paperdoll.serial	= input:PopNetUint32()
	paperdoll.name		= input:PopFilledString(60)
	paperdoll.flag		= input:PopNetUint8()
	
	HandleOpenPaperdoll(paperdoll)
	
	if (gAltenatePostLoginHandling) then
		if (not gFirstPaperdollReceived) then
			gFirstPaperdollReceived = true
			InvokeLater(2000,function () 
				print("#######!!!!!!!!! postlogin open backpack?",gPlayerBackPack,gPlayerBackPack and gPlayerBackPack.serial)
				if (gPlayerBackPack) then Send_DoubleClick(gPlayerBackPack.serial) end
				end)
		end
	end
end

-- Request WarMode Change/Send War Mode Status
function gPacketHandler.kPacket_SetPlayerWarmode()
	local input = GetRecvFIFO()
	local id = input:PopNetUint8()
	local flag = input:PopNetUint8()
	local unknown1 = input:PopNetUint8()
	local unknown2 = input:PopNetUint16()
	NotifyWarmode(flag)
end

function gPacketHandler.kPacket_Group()
	local input = GetRecvFIFO()
	local id = input:PopNetUint8()
	local flag = input:PopNetUint8()
	print("EnDisableRedraw: " .. flag)
end
