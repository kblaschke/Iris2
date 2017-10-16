gShopBlendoutGroups = {}
gShopBlendoutGroupArtIds = {}
gShopBlendoutGroupArtIds.magescrolls = {
7982, --  Clumsy
7983, --  Create Food
7984, --  Feeblemind
7985, --  Heal
7986, --  Magic Arrow
7987, --  Night Sight
7981, --  Reactive Armor
7988, --  Weaken
7989, --  Agility
7990, --  Cunning
7991, --  Cure
7992, --  Harm
7993, --   Magic Trap
7994, --   Magic Untrap
7995, --   Protection
7996, --   Strength
7997, --   Bless
7998, --   Fireball
7999, --   Magic Lock
8000, --   Poison
8001, --   Telekinesis
8002, --   Teleport
8003, --   Unlock
8004, --   Wall of Stone
8005, --   Arch Cure
8006, --   Arch Protection
8007, --   Curse
8008, --   Fire Field
8009, --   Greater Heal
8010, --   Lightning
8011, --   Mana Drain
8012, --   Recall
8013, --   Blade Spirits
8014, --   Dispel Field
8015, --   Incognito
8016, --   Magic Reflection
8017, --   Mind Blast
8018, --   Paralyze
8019, --   Poison Field
8020, --   Summon Creature
8021, --   Dispel
8022, --   Energy Bolt
8023, --   Explosion
8024, --   Invisibility
8025, --   Mark
8026, --   Mass Curse
8027, --   Paralyze Field
8028, --   Reveal
8029, --   Chain Lightning
8030, --   Energy Field
8031, --   Flamestrike
8032, --   Gate Travel
8033, --   Mana Vampire
8034, --   Mass Dispel
8035, --   Meteor Swarm
8036, --   Polymorph
8037, --   Earthquake
8038, --   Energy Vortex
8039, --   Resurrection
8040, --   Summon Air Elemental
8041, -- Summon Daemon
8042, -- Summon Earth Elemental
8043, -- Summon Fire Elemental
8044, -- Summon Water Elemental
}



-- helper function
function GetShopMobileID (shop)
	if (shop.shopMobileID) then return shop.shopMobileID end -- only set for sell-shop
	local shopContainerItem = GetObjectBySerial(shop.shopContainerID)
	if (not shopContainerItem) then printf("FATAL : GetShopMobileID : shopContainerItem not found %08x\n",shop.shopContainerID) return end
	local shopmobile = shopContainerItem.mobile
	if (not shopmobile) then printf("FATAL : GetShopMobileID : shopmobile not found for container %08x\n",shop.shopContainerID) return end
	return shopmobile.serial
end


-- lists all items that the player can sell to a specific vendor
-- similar to kPacket_Shop_Data = 0x74 , but there are some differences
-- triggered by "vendor sell" in chatline or contextmenu-buy
function gPacketHandler.kPacket_Shop_Sell() -- 0x9E
	local input 	= GetRecvFIFO()
	local id 		= input:PopNetUint8()
	local size 		= input:PopNetUint16()
	local shop = {}
	shop.isSellShop = true
	shop.shopMobileID 	= input:PopNetUint32()  -- unlike in kPacket_Shop_Data, this is the mobileid
	local oldshop = gShop[shop.shopMobileID]
	if (oldshop) then oldshop:Close() end -- TODO : cancel ?
	gShop[shop.shopMobileID] = shop
	shop.goodcount	= input:PopNetUint16() -- unlike in kPacket_Shop_Data, this has 2 bytes
	shop.goods = {}
	ShopCommonInit(shop)
	
	if (shop.goodcount > 0) then
		local playerBackpackContainer = GetPlayerBackPackContainer()
		local playerMobile = GetPlayerMobile()
		if (not playerBackpackContainer)	then
			print("FATAL : kPacket_Shop_Sell : playerBackpackContainer not found")
			print("FATAL ! kPacket_Shop_Sell -> forced Crash")
			NetCrash()
		end
		if (not playerMobile) then
			print("FATAL : kPacket_Shop_Sell : playerMobile not found")
			print("FATAL ! kPacket_Shop_Sell -> forced Crash")
			NetCrash()
		end

		if (1 == 1) then -- debug
			for k,item in pairs(GetContainerContentList(playerBackpackContainer)) do 
				print("item backpack",hex(item.serial),hex(item.artid))
			end
			for k,item in pairs(GetMobileEquipmentList(playerMobile)) do 
				print("item equipped",hex(item.serial),hex(item.artid))
			end
		end
	
		-- receive shop items
		for i = 1,shop.goodcount do 
			local good = {}
			good.itemserial	= input:PopNetUint32()
			good.itemartid	= input:PopNetUint16()
			good.itemhue	= input:PopNetUint16()
			good.itemamount	= input:PopNetUint16()
			good.price 		= input:PopNetUint16()
			good.namelen 	= input:PopNetUint16()
			good.name 		= input:PopFilledString(good.namelen)
			good.tradeamount= 0
			good.index 		= i
			good.item		= GetObjectBySerial(good.itemserial)
			good.bSellMode = true
			good.mode = "sell"
			--- old : see also get obj with good.itemserial from playerBackpackContainer
			
			--print("kPacket_Shop_Sell",hex(good.itemserial,8),hex(good.itemartid),hex(good.item.artid),good.price,good.name)
			if (good.item) then
				print("kPacket_Shop_Sell",hex(good.itemserial,8),hex(good.itemartid),hex(good.item.artid),good.price,good.name)
			else
				print("kPacket_Shop_Sell",hex(good.itemserial,8),hex(good.itemartid),"(nil)",good.price,good.name)
			end

			if (good.item) then -- item is not always available, especially if its in the backpack, and that has not been opened yet
				if (good.itemartid ~= good.item.artid)	then
					print("warning : kPacket_Shop_Sell : artid mismatch "..hex(good.itemartid).." != "..good.item.artid,good.name,"amt:",good.itemamount,good.item.amount)
					--~ print("FATAL ! kPacket_Shop_Sell -> forced Crash")
					--~ NetCrash()
				end
				if (good.itemamount ~= good.item.amount) then
					printf("FATAL : kPacket_Shop_Sell : amount mismatch 0x%04x != 0x%04x\n",good.itemamount,good.item.amount)
					print("FATAL ! kPacket_Shop_Sell -> forced Crash")
					NetCrash()
				end
			end
			
			local nameint = tonumber(good.name)
			if (nameint and good.name == ""..nameint) then good.name = GetCliloc(nameint) end
			shop.goods[i] = good
		end
		
		OpenShopDialog(shop)
	else
		-- often one of kLayer_NPCBuyRestock NPCBuyNoRestock is empty, and both are send on "vendor buy" on pol
		print("(empty sellshop)")
	end
	RememberShop(shop)
	if (shop.goodcount > 0) then NotifyListener("Hook_Open_Shop_Sell",shop) end
end

-- This is used to send shop inventory information to the client.
-- triggered by "vendor buy" in chatline or contextmenu-buy
-- also known as "Open Buy Window"
--[[
NOTE: This packet is always preceded by a describe contents packet (0x3c, kPacket_Container_Contents),
and followed by a open container packet (0x24 kPacket_Open_Container) with the vendor-mobile-ID only and 
a model number of 0x0030 (probably the model # for the buy screen)

on some servers the container id is (vendorMobileID | 0x40000000)  (so far maybe on pol?, but NOT on runuo)
]]--
function gPacketHandler.kPacket_Shop_Data() -- 0x74
	local input 	= GetRecvFIFO()
	local id 		= input:PopNetUint8()
	local size 		= input:PopNetUint16()
	local shop = {}
	shop.shopContainerID 	= input:PopNetUint32() -- containerid ! (or vendorserial-1)
	
	print("######### kPacket_Shop_Data containerid:",shop.shopContainerID)
	
	local shopContainerItem = GetObjectBySerial(shop.shopContainerID)
	if (shopContainerItem and shopContainerItem.mobile) then shop.shopMobileID = shopContainerItem.mobile.serial end
	
	local oldshop = gShop[shop.shopContainerID]
	if (oldshop) then oldshop:Close() end -- TODO : cancel ?
	gShop[shop.shopContainerID] = shop
	shop.goodcount	= input:PopNetUint8()
	shop.goods = {}
	ShopCommonInit(shop)
	
	if (shop.goodcount > 0) then
		-- get associated container (probably on one of the special layers, kLayer_NPCBuyRestock or NPCBuyNoRestock)
		-- usually sent together with this packet as kPacket_Container_Contents
		local container = GetContainer(shop.shopContainerID)
		if (not container) then
			print("FATAL ! shop container not found",vardump(shop.shopContainerID))
			print("FATAL ! kPacket_Shop_Data -> forced Crash")
			NetCrash()
		end

		-- goods are associate with items in container sorted by serial, ascending or descending, depending on server Emu
		local sorteditems = {}
		local allbycontainer_content = true
		for k,v in pairs(container:GetContent()) do 
			table.insert(sorteditems,v)
			if (not v.container_content_order) then allbycontainer_content = false end
		end
		if (allbycontainer_content) then 
			print("##SHOP-Sort by content order")
			table.sort(sorteditems,CompareContainerContentOrderDesc) -- container_content_order
		elseif (gPolServer) then
			print("##SHOP-Sort asc (pol)")
			table.sort(sorteditems,CompareSerialAsc)
		else
			print("##SHOP-Sort desc (fallback)")
			table.sort(sorteditems,CompareSerialDesc)
		end
		
		-- check if the shop matches the container
		if (table.getn(sorteditems) ~= shop.goodcount) then print("WARNING : kPacket_Shop_Data : itemcount mismatch",table.getn(sorteditems),shop.goodcount) end
	
		local knownartids = {}
		-- receive shop items
		for i = 1,shop.goodcount do 
			local good = {}
			good.price 		= input:PopNetUint32()
			good.namelen 	= input:PopNetUint8()
			good.name 		= input:PopFilledString(good.namelen)
			good.tradeamount= 0
			good.index 		= i
			good.item 		= sorteditems[i] -- the uo protocol is just freaked
			
			
			good.itemserial	= good.item.serial
			good.itemartid	= good.item.artid
			good.itemhue	= good.item.hue
			good.itemamount	= good.item.amount
			good.bBuyMode = true
			good.mode = "buy"
			--~ good.bIsInPlayerBackpack = good.item.iContainerSerial == GetPlayerBackPackSerial()  not needed, see bSellMode above
			
			local nameint = tonumber(good.name)
			if (nameint and good.name == ""..nameint) then good.name = GetCliloc(nameint) end
			
			print("shopitem",hex(good.item.artid),hex(good.item.hue),good.price,"amt="..tostring(good.itemamount),good.name) 
			--~ if (not knownartids[good.item.artid]) then print("shopitem",good.item.artid,good.name) knownartids[good.item.artid] = true end
			local bBlendout = false 
			for k,v in pairs(gShopBlendoutGroups) do 
				local blendoutlist = (type(v) == "table") and v or gShopBlendoutGroupArtIds[k]
				if (good.item and in_array(good.item.artid,blendoutlist)) then bBlendout = true end 
			end			
			
			if (not bBlendout) then shop.goods[i] = good end
		end
		
		OpenShopDialog(shop)
	else
		-- often one of kLayer_NPCBuyRestock NPCBuyNoRestock is empty, and both are send on "vendor buy" on pol
		print("(empty shop)")
	end
	RememberShop(shop)
end

-- close the shopgump for buy and sellshop
-- same messagetype also used for SendBuyAccept
function gPacketHandler.kPacket_Accept_Offer() -- 0x3B
	local input = GetRecvFIFO()
	local id = input:PopNetUint8()
	local size = input:PopNetUint16()
	local shopMobileID = input:PopNetUint32()
	printdebug("net",sprintf("kPacket_Accept_Offer (close-shop): shopMobileID=0x%08x\n",shopMobileID))
	for k,shop in pairs(gShop) do  -- can be more than one on pol
		if (shopMobileID == GetShopMobileID(shop)) then shop:Close() end
	end
	input:PopRaw(size - (1 + 2 + 4)) -- drop the rest, usually just a byte with 0
end

--This is sent by the client to buy items from a vendor.
--TODO : This is sent by the server to remove the list.
-- see also old iris handler_buyaccept
-- the serial sent must be the serial of the mobile where the shop-container-item is equipped (usually on kLayer_NPCBuyRestock)
function SendBuyAccept (shop,goods) -- 0x3B kPacket_Accept_Offer
	local out = GetSendFIFO()
	local numitems = goods and table.getn(goods) or 0
	local shopMobileID = GetShopMobileID(shop)
	if (not shopMobileID) then return end
	printdebug("net",sprintf("SendBuyAccept : numitems=%d shopContainerID=0x%08x mobileserial=0x%08x\n",numitems,shop.shopContainerID,shopMobileID))
	local len = 8 + (numitems * 7)
	out:PushNetUint8(kPacket_Accept_Offer)
	out:PushNetUint16(len)
	out:PushNetUint32(shopMobileID) --MOBILEID !
	out:PushNetUint8(hex2num("0x02")) -- the packet description varies here...
	--out:PushNetUint8(numitems) -- the packet description varies here...
		-- a) flag ·  0x00 - no items following  · 0x02 - items following 
		-- b) The number of items in the list.  Setting this to zero will remove the gump. 
	
	if (goods) then for k,good in pairs(goods) do
		out:PushNetUint8(kLayer_NPCBuyRestock)	-- The shop layer that the item is in (usually 0x1A = kLayer_NPCBuyRestock).
        out:PushNetUint32(good.itemserial)	-- object serial form buy container
        out:PushNetUint16(good.tradeamount)	-- amount
		printdebug("net",sprintf("item : itemserial=0x%08x tradeamount=0x%04x\n",good.itemserial,good.tradeamount))
	end	end
	out:SendPacket()
end

-- send to finish the npc-sell shop
-- similar to SendBuyAccept, but there are a few differences
function SendSellAccept (shop,goods) -- 0x9F kPacket_Shop_Offer
	local out = GetSendFIFO()
	local numitems = goods and table.getn(goods) or 0
	local shopMobileID = GetShopMobileID(shop)
	if (not shopMobileID) then return end
	printdebug("net",sprintf("SendSellAccept : numitems=%d mobileserial=0x%08x\n",numitems,shopMobileID))
	local len = 9 + (numitems * 6)
	out:PushNetUint8(kPacket_Shop_Offer)
	out:PushNetUint16(len)
	out:PushNetUint32(shopMobileID) --MOBILEID !
	out:PushNetUint16(numitems)
	if (goods) then for k,good in pairs(goods) do
        out:PushNetUint32(good.itemserial)	-- object serial
        out:PushNetUint16(good.tradeamount)	-- amount
		printdebug("net",sprintf("item : itemserial=0x%08x tradeamount=0x%04x\n",good.itemserial,good.tradeamount))
	end	end
	out:SendPacket()
end

-- trading with npcs can be triggered by typing "vendor buy" for example
-- or by choosing buy from the contextmenu of the mobile (rightclick here, aos-feature, not supported by pol?)
-- see also net.other.lua (for context/popup-menu)
-- see also lib.uoids.lua for special layertypes (kLayer_NPCBuyRestock,NPCBuyNoRestock,NPCSellContainer)
-- see also net.container.lua for special containers 
-- see also net.securetrade.lua for secure trading between players

--[[ strange things :
	-- strange thing from runuo : base( 0x74 ) kPacket_Shop_Data :  m_Stream.Write( (int)(BuyPack == null ? Serial.MinusOne : BuyPack.Serial) );
	-- strange thing from runuo : base( 0x3c ) kPacket_Container_Contents : (x / y) : coordinates used for sorting ?
	
public VendorBuyContent( ArrayList list ) : base( 0x3c ) kPacket_Container_Contents
		{
			this.EnsureCapacity( list.Count*19 + 5 );

			m_Stream.Write( (short)list.Count );

			//The client sorts these by their X/Y value.
			//OSI sends these in wierd order.  X/Y highest to lowest and serial loest to highest
			//These are already sorted by serial (done by the vendor class) but we have to send them by x/y
			//(the x74 packet is sent in 'correct' order.)
			for ( int i = list.Count - 1; i >= 0; --i )
			{
				BuyItemState bis = (BuyItemState)list[i];
		
				m_Stream.Write( (int)bis.MySerial );
				m_Stream.Write( (ushort)(bis.ItemID & 0x3FFF) );
				m_Stream.Write( (byte)0 );//itemid offset
				m_Stream.Write( (ushort)bis.Amount );
				m_Stream.Write( (short)(i+1) );//x
				m_Stream.Write( (short)1 );//y
				m_Stream.Write( (int)bis.ContainerSerial );
				m_Stream.Write( (ushort)bis.Hue );
			}
		}
]]--
