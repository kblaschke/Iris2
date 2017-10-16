-- NEW DRAG & DROP SYSTEM
--[[
gDragDropItem = nil
gLeftDownItem = nil

function SetDragItem( item, offx, offy )
	if (item) then
		local material		= GetArtMat( item.artid + 0x4000, item.hue )
		local width, height	= GetArtSize( item.artid + 0x4000, item.hue )
		
		if (not offx) then offx = -math.floor( width/2 ) end
		if (not offy) then offy = -math.floor( height*3/5 ) end
		
		SetDragIcon( material, width, height, offx, offy )
		
		gDragDropItem = {}
		gDragDropItem.serial = item.serial
		gDragDropItem.artid = item.artid
		if (item.layer) then
			gDragDropItem.layer = item.layer
		else
			gDragDropItem.layer = GetStaticTileType( item.artid ).miQuality
		end
		gDragDropItem.offx = offx
		gDragDropItem.offy = offy
		gDragDropItem.onItemUpdate = function()
			CancelUODragDrop()
		end
		
		RegisterListener( "UpdateDynamic"..sprintf("%d",item.serial), gDragDropItem.onItemUpdate )
	else
		HideDragIcon()
		
		if (gDragDropItem) then
			UnregisterListener( "UpdateDynamic"..sprintf("%d",gDragDropItem.serial), gDragDropItem.onItemUpdate )
			gDragDropItem = nil
		end
	end
end

function CancelUODragDrop()
	SetDragItem( nil )
end

function DragDropStep()
	if (gLeftDownItem) then
		local iMouseX, iMouseY = GetMousePos()
		if (iMouseX ~= gLeftDownItem.iMouseX or iMouseY ~= gLeftDownItem.iMouseY) then
			gLeftDownItem.item:grab()
			gLeftDownItem = nil
		end
	end
end

function MouseDownUODragDrop()
	MainMousePick()
	if (gMousePickFoundHit and gMousePickFoundHit.hittype == kMousePickHitType_Dynamic) then
		gLeftDownItem = {}
		gLeftDownItem.item = gMousePickFoundHit.dynamic
		gLeftDownItem.iMouseX, gLeftDownItem.iMouseY = GetMousePos()
	else
		gLeftDownItem = nil
	end
end

-- better use listener for this
function MouseUpUODragDrop ()
	if (gLeftDownItem) then
		gLeftDownItem = nil
	end

	if (not gDragDropItem) then
		return
	else
		local Gump = gGumpmanager.GetSelectedGump()
		if (Gump) then
			if (Gump.name == "container") then
				if (gGumpmanager.CurrentMouseOverGumpObject.type == gGumpmanager.gumpObjectType_Item) then
					Send_Drop_Object( gDragDropItem.serial, hex2num("0xFFFF"), hex2num("0xFFFF"), 0, gGumpmanager.CurrentMouseOverGumpObject.serial )
				else
					local iMouseX, iMouseY = GetMousePos()
					Send_Drop_Object( gDragDropItem.serial, iMouseX-Gump.x+gDragDropItem.offx, iMouseY-Gump.y+gDragDropItem.offy, 0, Gump.contserial )
				end
			elseif (Gump.name == "paperdoll") then
				if (gGumpmanager.CurrentMouseOverGumpObject.type == gGumpmanager.gumpObjectType_GumpItem) then
					Send_Drop_Object( gDragDropItem.serial, hex2num("0xFFFF"), hex2num("0xFFFF"), 0, gGumpmanager.CurrentMouseOverGumpObject.serial )
				end
				
				Send_Equip_Item_Request( gDragDropItem.serial, gDragDropItem.layer, Gump.mobileserial )
			end
		else
			MainMousePick()
			
			if (gMousePickFoundHit) then
				if (gMousePickFoundHit.hittype == kMousePickHitType_Dynamic and TestBit(GetStaticTileTypeFlags( gDragDropItem.artid ) or 0,kTileDataFlag_Container)) then
					Send_Drop_Object( gDragDropItem.serial, hex2num("0xFFFF"), hex2num("0xFFFF"), 0, gMousePickFoundHit.dynamic.serial )
				elseif (gMousePickFoundHit.hittype == kMousePickHitType_Mobile) then					
					--Send_Equip_Item_Request( gDragDropItem.serial, gDragDropItem.layer, gMousePickFoundHit.mobile.serial )
					Send_Drop_Object( gDragDropItem.serial, hex2num("0xFFFF"), hex2num("0xFFFF"), 0, gMousePickFoundHit.mobile.serial )
				else
					local x, y, z = GetMouseHitTileCoords()
					Send_Drop_Object( gDragDropItem.serial, x, y, z, hex2num("0xFFFFFFFF") )
				end
			end
		end
	end
end
]]--

-- ----------------------------------------------------------------------------------------------------
-- OLD DRAG & DROP SYSTEM !!!

-- TODO : generalise me ! (container,paperdoll,world)

--[[

TODO : mousedrag : snap dragged picture to tile centers (project 3d tile center to 2d hud pixel coords)


gPacketType.kPacket_Take_Object										= { id=hex2num("0x07") }	-- send by client
gPacketType.kPacket_Drop_Object										= { id=hex2num("0x08") }


gPacketType.kPacket_Object_to_Object								= { id=hex2num("0x25") }
gPacketType.kPacket_Get_Item_Failed									= { id=hex2num("0x27") }
gPacketType.kPacket_Drop_Item_Failed								= { id=hex2num("0x28") }
gPacketType.kPacket_Drop_Item_OK									= { id=hex2num("0x29") }

gPacketType.kPacket_Destroy											= { id=hex2num("0x1D") }	-- send by server
gPacketType.kPacket_Equip_Item_Request								= { id=hex2num("0x13") }
gPacketType.kPacket_Equip_Item										= { id=hex2num("0x2E") }

Pick up Item(s) [0x07]  sent by client
BYTE cmd
BYTE[4] item id
BYTE[2] # of items in stack

Drop Item(s) [0x08]   sent by client
BYTE cmd
BYTE[4] item id
BYTE[2] X Location
BYTE[2] Y Location
BYTE Z Location
BYTE[4] Move Into Container ID (FF FF FF FF if normal world)

0x23  	Drag Item ( send by server, displays animation ?)
0x24  	Open Container  �  0x003c = backpack 
0x25  	Object to Object     This is sent by the server to add a single item to a container.

0x08 	Packet   Drop Item(s) (14 bytes)
0x27  	Get Item Failed
0x28  	Drop Item Failed
0x29  	Drop Item OK ? Paperdoll Clothing Added ?

0x7C  	Object Picker ? some sort of menu
0x7D  	Picked Object ? some sort of menu, response


TODO : 
0x1D Packet   Delete object (5 bytes)   item/char id
0x07 Packet   Pick Up Item(s) (7 bytes)

]]--

gDragStartDist = 5 -- in pixels
gSquareDragStartDist = gDragStartDist * gDragStartDist

gDragDrop = false

function PrepareDragPaperdollItem (item) 
	if (item.layer == kLayer_Backpack) then return end
	local widget = item.widget
	local iArtID = item.artid + 0x4000
	local mat = GetArtMat(iArtID,item.hue)
	local w,h = GetArtSize(iArtID,item.hue)
	local offx,offy = -w/2,-h/2 
	
	-- used fields of gDragDrop.item : 	.artid .serial .amount 
	PrepareUODragDrop(item,widget,mat,w,h,offx,offy)
end

function PrepareDragContainerItem (item) 
	local widget = item.widget or item.secwidget
	if (not widget) then return end
	local iArtID = item.artid + 0x4000
	local mat = GetArtMat(iArtID,item.hue)
	local w,h = GetArtSize(iArtID,item.hue)
	local iMouseX,iMouseY = GetMousePos()
	local x,y = widget:GetDerivedPos()
	local offx = x - iMouseX 
	local offy = y - iMouseY
	
	-- used fields of gDragDrop.item : 	.artid .serial .amount 
	PrepareUODragDrop(item,widget,mat,w,h,offx,offy)
end

-- SiENcE: just skip Multis here
-- Todo: Multi support
function PrepareDragDynamic (dynamic)
	--~ if ItemIsMulti(dynamic) then dynamic.artid = 0xeef end -- vm hausklau bug
	if (not ItemIsMulti(dynamic)) then
		local iArtID = dynamic.artid + 0x4000
		local matname = GetArtMat(iArtID,dynamic.hue)
		local w,h = GetArtSize(iArtID,dynamic.hue)
		local offx,offy = -w/2,-h/2 
		-- TODO : correct offy would be : bottom of bitmask visible boundbox (NOT -h !), but center looks good enough for most items for now
		
		-- used fields of gDragDrop.item : 	.artid .serial .amount 
		-- set fields of dynamic : 			.artid .serial .amount .flag  
		-- local t = GetStaticTileType(dynamic.artid)
		PrepareUODragDrop(dynamic,nil,matname,w,h,offx,offy)
	end
end

function PrepareUODragDrop (item,widget,matname,w,h,offx,offy)
	--GuiAddChatLine("dragdrop : prepare")
	CancelUODragDrop() -- cancel last ? shouldn't happen
	gDragDrop = {}
	gDragDrop.item = item
	gDragDrop.widget = widget
	gDragDrop.matname = matname
	gDragDrop.w = w
	gDragDrop.h = h
	gDragDrop.offx = offx
	gDragDrop.offy = offy
	gDragDrop.iMouseX,gDragDrop.iMouseY = GetMousePos()
	gDragDrop.started = false
	gDragDrop.wait_for_dragmove = true
end

function StepUODragDrop () 
	-- start dragdrop if the mouse is dragged for a minimum distance
	if (gDragDrop and gDragDrop.wait_for_dragmove) then 
		local iMouseX,iMouseY = GetMousePos()
		local dx = gDragDrop.iMouseX - iMouseX
		local dy = gDragDrop.iMouseY - iMouseY
		local sqdist = dx*dx + dy*dy
		if (sqdist >= gSquareDragStartDist) then gDragDrop.wait_for_dragmove = false UODragDrop_TakeItem() end
	end
end

function MouseDownUODragDrop ()
	if (gDragDrop and gDragDrop.started) then -- when dragging with amount dialog
		CompleteUODragDrop()
	else 
		MainMousePick()
		gMouseDragMobile = nil
		if (gMousePickFoundHit) then
			if (gMousePickFoundHit.hittype == kMousePickHitType_ContainerItem)	then PrepareDragContainerItem(gMousePickFoundHit.item) end
			if (gMousePickFoundHit.hittype == kMousePickHitType_PaperdollItem)	then PrepareDragPaperdollItem(gMousePickFoundHit.item) end
			if (gMousePickFoundHit.hittype == kMousePickHitType_Dynamic)		then PrepareDragDynamic(gMousePickFoundHit.dynamic) end
			if (gMousePickFoundHit.hittype == kMousePickHitType_Mobile	)		then gMouseDragMobile = gMousePickFoundHit.mobile end
		end
	end
end

function MouseUpUODragDrop () 
	if (not gDragDrop) then return end
	if (gDragDrop.bWithAmountDialog) then return end
	if (gDragDrop.started) then
		CompleteUODragDrop()
	else
		CancelUODragDrop()
	end
end

function DestroyDragDropItemBySerial (serial)
	if (gDragDrop and gDragDrop.item.serial == serial) then
		gDragDrop.bItemDestroyed = true
		gDragDrop.widget = nil		
		-- item is kept "on the cursor" even if it was removed from inventory after Send_Take_Object()
	end
end

function StartUODragDrop (amount)
	if (not gDragDrop) then print("StartUODragDrop : error, gDragDrop already released") return end
	gDragDrop.started = true
	SetDragIcon(gDragDrop.matname,gDragDrop.w,gDragDrop.h,gDragDrop.offx,gDragDrop.offy)

	Send_Take_Object(gDragDrop.item.serial,amount) 
	gui.bMouseBlocked = true
end

function UODragDrop_AmountEntryCallback (chosen_amount)
	StartUODragDrop(chosen_amount)
end

function UODragDrop_TakeItem ()
	local bIsCorpse = IsCorpseArtID(gDragDrop.item.artid)
	--~ if () then return end
	local amount = gDragDrop.item.amount
	if (bIsCorpse) then amount = 1 end
	if (amount > 1 and (not gKeyPressed[key_lshift]) and (not bIsCorpse)) then 
		-- show amount bSendTakeMessage
		gDragDrop.bWithAmountDialog = true
		OpenAmountAtMouse(1,amount,amount,UODragDrop_AmountEntryCallback)
	else
		StartUODragDrop(amount)
	end
end

-- called in all cases at the end
function CleanUpUODragDrop ()
	if (not gDragDrop) then return end
	
	if (gDragDrop.started) then
		HideDragIcon()
		gui.bMouseBlocked = false
	end
	
	gDragDrop.item = nil
	gDragDrop.widget = nil
	gDragDrop = false
end

-- end A : nothing happened, client side cancel
function CancelUODragDrop ()
	if (not gDragDrop) then return end
	--GuiAddChatLine("dragdrop : cancel")
	if (gDragDrop.started) then UODragDropToOldPosition() end
	CleanUpUODragDrop()
end

-- drop onto old position and original container after take
function UODragDropToOldPosition ()
	local item = gDragDrop.item
	local containerserial = item.iContainerSerial or hex2num("0xFFFFFFFF") -- ffff... for drop world (dynamics)
	Send_Drop_Object(item.serial,item.xloc or 0,item.yloc or 0,item.zloc or 0,containerserial)
end

-- end B : something happened
function CompleteUODragDrop () 
	if (not gDragDrop) then return end
	--GuiAddChatLine("dragdrop : complete")

	MainMousePick()
	
	local item = gDragDrop.item
	local dialog_under_mouse = GetDialogUnderMouse()
	local x,y,z = 0,0,0
	
	printdebug("dragdrop","MouseUpUODragDrop",dialog_under_mouse,dialog_under_mouse and dialog_under_mouse.debugname)
	
	if (dialog_under_mouse) then
		local iMouseX,iMouseY = GetMousePos()
		if (dialog_under_mouse.rootwidget) then
			x = iMouseX - dialog_under_mouse.rootwidget.gfx:GetDerivedLeft() + gDragDrop.offx
			y = iMouseY - dialog_under_mouse.rootwidget.gfx:GetDerivedTop() + gDragDrop.offy
		elseif (dialog_under_mouse.GetDerivedPos) then
			local dx,dy = dialog_under_mouse:GetDerivedPos()
			x = iMouseX - dx + gDragDrop.offx
			y = iMouseY - dy + gDragDrop.offy
		end
	end
	
	if (dialog_under_mouse and dialog_under_mouse.uoContainer) then
		-- drop on container
		local container = dialog_under_mouse.uoContainer
		printdebug("dragdrop","MouseUpUODragDrop: drop on container ",item.serial,item.amount,x,y,z,container.serial)
		
		-- default target is container
		local target = container.serial
		local bDropOnOtherItem = gMousePickFoundHit and gMousePickFoundHit.hittype == kMousePickHitType_ContainerItem
		if (gKeyPressed[key_lalt]) then bDropOnOtherItem = false end
		print("dragdrop:drop on container",container,target,bDropOnOtherItem)
		
		-- stack this item with the same beneath?
		if bDropOnOtherItem then
			-- read out item infos
			local arrtiletype = {}
			arrtiletype = GetStaticTileType(item.artid)

			local targettiletype = {}
			targettiletype = GetStaticTileType(gMousePickFoundHit.item.artid)

			local bOtherIsContainer = gMousePickFoundHit.item and TestMask(GetStaticTileTypeFlags(gMousePickFoundHit.item.artid),kTileDataFlag_Container)
			
			
			x = 0xffff
			y = 0xffff
			x = gMousePickFoundHit.item.xloc or 0xffff
			y = gMousePickFoundHit.item.yloc or 0xffff
			z = gMousePickFoundHit.item.zloc or 0
			
			if (bOtherIsContainer) then 
				x = 0xffff
				y = 0xffff
				z = 0
			end
			
			print("###############################")
			print("#### drop on other item in container : ",x,y,z)
			print("###############################")
			target = gMousePickFoundHit.item.serial 
			--[[
			-- if the item beneath has the same artid and stackable, try to stack them
			if (TestBit(arrtiletype.miFlags or 0,kTileDataFlag_Generic_Stackable)) and gMousePickFoundHit.item.artid == item.artid then
				target = gMousePickFoundHit.item.serial 
			elseif (TestBit(targettiletype.miFlags or 0,kTileDataFlag_Container)) then
				-- the item under the mouse is a container so put it into the container
				target = gMousePickFoundHit.item.serial
				-- TODO this position is hardcoded, is there a better way doing this? dynamic position? find free spot?
				x = 70
				y = 60
				z = 0
			end
			]]--
		end
		
		-- stack items of same type in the container if shift is pressed
		if (gShiftDragCombine and gKeyPressed[key_lshift] and container) then
			printdebug("dragdrop","stack same items")
			for k,i in pairs(container:GetContent()) do 
				if 
					i.serial ~= item.serial and 
					i.artid == item.artid and 
					(not item.hue or i.hue == item.hue) 
				then
					target = i.serial
				end
			end
		end
		
		Send_Drop_Object(item.serial,x,y,z,target)
	elseif (dialog_under_mouse and dialog_under_mouse.dropOnMobileSerial) then
		-- support drop of stuff onto dialogs
		local mobile = GetMobile(dialog_under_mouse.dropOnMobileSerial)
		if (mobile) then 
			x = 0xffff
			y = 0xffff
			z = 0
		end
		print("###############################")
		print("#### drop on mobile via dialog : ",x,y,z,mobile)
		print("###############################")
		Send_Drop_Object(item.serial,x,y,z,dialog_under_mouse.dropOnMobileSerial)
	elseif (dialog_under_mouse and dialog_under_mouse.uoSecureTrade) then
		-- drop on secure trade container
		local mysectrade = dialog_under_mouse.uoSecureTrade
		printdebug("dragdrop","#### MouseUpUODragDrop: drop on secure trade container ",item.serial,item.amount,x,y,z,mysectrade.myContainerID)
		
		-- default target is container
		local target = mysectrade.myContainerID
		
		-- todo : stack ?
		Send_Drop_Object(item.serial,x-kSecureTradeContainerPos_LeftX,y-kSecureTradeContainerPos_LeftY,z,target)
	elseif (gMousePickFoundHit and 
			gMousePickFoundHit.hittype == kMousePickHitType_PaperdollItem and 
			gMousePickFoundHit.item and gMousePickFoundHit.item.layer == kLayer_Backpack) then 
		-- drop on packpack in paperdoll
		Send_Drop_Object_AutoStack(item.serial,gMousePickFoundHit.item.serial)
	elseif (dialog_under_mouse and dialog_under_mouse.uoPaperdoll) then
		-- drop on paperdoll
		local paperdoll = dialog_under_mouse.uoPaperdoll
		local iTileTypeID = item.artid -- can come from paperdoll or container or dynamic
		local layer = GetPaperdollLayerFromTileType(iTileTypeID)
		if (iTileTypeID == 0x2f5b) then layer = layer or kLayer_Talisman end -- talisman
		local mobileserial = paperdoll.mobileserial
		local mobile = GetMobile(mobileserial)
		print("drop on paperdoll",gLayerTypeName[layer])
		printdebug("dragdrop","MouseUpUODragDrop: drop on paperdoll ",item.serial,item.amount,iTileTypeID,layer,paperdoll.mobileserial)
		if (not layer) then
			printdebug("dragdrop","CompleteUODragDrop : item is not wearable",vardump(item))
			CancelUODragDrop()
		elseif (not mobile) then
			printdebug("dragdrop","CompleteUODragDrop : paperdoll mobile not found",vardump(item))
			CancelUODragDrop()
		elseif (GetMobileEquipmentItem(mobile,layer)) then
			printdebug("dragdrop","CompleteUODragDrop : layer already full",vardump(item))
			-- TODO : if layer is not empty, drop dragged item to backpack, take item from layer to backpack, equip dragged item
			-- NOTE : if layer is not empty and it's not possible to put item to backpack -> check and solve this problem!
			--		  (for now i added "or 0" for x and y to function "UODragDropToOldPosition()" )
			GuiAddChatLine("you already have something equipped there !")
			CancelUODragDrop()
		else
			-- success ! (hopefully)
			Send_Equip_Item_Request(item.serial,layer,paperdoll.mobileserial)
		end
	elseif (gMousePickFoundHit) then
		print("dragdrop:drop on mousepickhit")
		x,y,z = GetMouseHitTileCoords()
		local iSerial = GetMouseHitSerial()
		
		--~ print("#####dragdrop,gMousePickFoundHit=",iSerial,SmartDump(gMousePickFoundHit))
		--~ #####dragdrop,gMousePickFoundHit=       {hit_zloc=35=0x23,dynamic=table: 0x9d50c38,hittype=2,hit_xloc=3443=0x0d73,hit_yloc=2659=0x0a63,}

		-- uo-hack : don't send drop-container on dynamic floor tiles (yard wand tool on vm), to allow puttin items on the floor (flags=0x201)
		local bOnContainer = false
		if (iSerial and iSerial ~= 0) then 
			local dynamic = GetDynamic(iSerial)
			if (dynamic) then
				local flags = GetStaticTileTypeFlags(dynamic.artid) or 0
				if (TestBit(flags,kTileDataFlag_Container)) then bOnContainer = true end
				--~ if (not bOnContainer) then iSerial = nil end  -- might be bad for potionkegs and similar non-container droptargets
				if (TestBit(flags,kTileDataFlag_Surface)) then iSerial = nil end   --  or kTileDataFlag_Background ?
				if (ItemIsMulti(dynamic)) then iSerial = nil end
				if (iSerial) then 
					-- pol fix?
					x = dynamic.xloc 
					y = dynamic.yloc 
					z = dynamic.zloc 
					print("###############################")
					print("#### drop on other item in world : ",x,y,z)
					print("###############################")
				end
			end
			local mobile = GetMobile(iSerial)
			if (mobile) then 
				x = 0xffff
				y = 0xffff
				z = 0
				print("###############################")
				print("#### drop on mobile in world : ",x,y,z,mobile)
				print("###############################")
			end
		end
		
		if (iSerial and iSerial ~= 0) then 
			-- drop on mobile,dynamic etc 
			print("drop on mobile,dynamic etc ")
			if (bOnContainer) then
				printdebug("dragdrop","MouseUpUODragDrop: drop on worldcontainer : ",item.serial,item.amount,iSerial)
				Send_Drop_Object_AutoStack(item.serial,iSerial)
			else
				printdebug("dragdrop","MouseUpUODragDrop: drop on worlobject : ",item.serial,item.amount,x,y,z,iSerial)
				Send_Drop_Object(item.serial,x,y,z,iSerial)
			end
		else
			-- drop on world
			printdebug("dragdrop","MouseUpUODragDrop: drop on world : ",item.serial,item.amount,x,y,z,hex2num("0xFFFFFFFF"))
			Send_Drop_Object(item.serial,x,y,z,0xFFFFFFFF)
		end
	else
		-- dragdrop to nowhere (sky?) : cancel
		CancelUODragDrop()
	end
	CleanUpUODragDrop()
end
