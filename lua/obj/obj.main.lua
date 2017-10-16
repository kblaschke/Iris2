dofile(libpath .. "obj/obj.mobile.lua")
dofile(libpath .. "obj/obj.dynamic.lua")
dofile(libpath .. "obj/obj.player.lua")
dofile(libpath .. "obj/obj.container.lua")

gObjectList = {}
gDynamics = {}
gMobiles = {}

function GetMobileEquipmentItem (mobile,layer) return mobile:GetEquipmentAtLayer(layer) end
function GetMobileEquipmentList (mobile) return mobile:GetContent() end
function GetContainerContentList (container) return container:GetContent() end
function GetObjectBySerial (serial) return GetObject(serial) end
function GetObject (object_or_serial) 
	if (not object_or_serial) then return nil end
	if (type(object_or_serial) == "table") then return object_or_serial end
	return gObjectList[object_or_serial] -- look up by serial
end

function DynamicIsInWorld (dynamic) return not dynamic.container end  -- does not have parent container

function GetDynamicList	() return gDynamics end
function GetMobileList	() return gMobiles end


----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
gDynamicsInWorldByPosition = {}


-- returns a list of dynamics at the given uo position (only dynamics that are in the world)
function GetDynamicsAtPosition	(xloc, yloc)
	return gDynamicsInWorldByPosition[xloc.."_"..yloc] or {}
end

function DynamicRemoveFromPosCache	(dynamic)
	if dynamic.poscache_x and dynamic.poscache_y then
		local key = dynamic.poscache_x.."_"..dynamic.poscache_y
		for k,v in pairs(gDynamicsInWorldByPosition[key]) do
			if v == dynamic then
				gDynamicsInWorldByPosition[key][k] = nil
				dynamic.poscache_x = nil
				dynamic.poscache_y = nil
				return
			end
		end
	end
end

function DynamicAddToPosCache	(dynamic)
	if not DynamicIsInWorld(dynamic) then return end

	local key = dynamic.xloc.."_"..dynamic.yloc
	if not gDynamicsInWorldByPosition[key] then
		gDynamicsInWorldByPosition[key] = {}
	end
	
	table.insert(gDynamicsInWorldByPosition[key], dynamic)
	dynamic.poscache_x = dynamic.xloc
	dynamic.poscache_y = dynamic.yloc
end

function DynamicUpdatePosCache	(dynamic)
	if dynamic.poscache_x == dynamic.xloc and dynamic.poscache_y == dynamic.yloc then return end
	
	DynamicRemoveFromPosCache(dynamic)
	DynamicAddToPosCache(dynamic)
end
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------


function InitializeObject	(serial) 
	local object = {serial=serial} 
	gObjectList[serial] = object
	return object
end



-- don't call directly, called from object:Destroy()
function CleanupObject	(object)
	local serial = object.serial
	
	CloseContainer(serial)
	object:DestroyContent()
	
	DestroyPaperdollByMobileSerial(serial)
	DestroyDragDropItemBySerial(serial)
	gCurrentRenderer:DestroyMousePickItemBySerial(serial)
	
	gObjectList[object.serial] = nil 
	--object.serial = nil -- seems to cause a lot of trouble if set to nil, e.g. dragdrop
	object.bIsDead = true
end



function DestroyObjectBySerial (serial) 
	local object = GetObject(serial)
	if (object) then object:Destroy() end
end

-- needed for mapchange
function DestroyAllObjects (bDontClearPlayer) 
	CancelUODragDrop()
	local playerserial = GetPlayerSerial()
	local backpackserial = GetPlayerBackPackSerial()
	for k,object in pairs(gObjectList) do 
		local bDestroy = true
		if (bDontClearPlayer) then
			if (object.serial == playerserial or 
				object.iContainerSerial == playerserial or 
				(object.iContainerSerial == backpackserial and backpackserial)) then
				bDestroy = false
			end
		end
		if (bDestroy) then object:Destroy() end 
	end
	gMultis = {} -- clear multi-list, used by walk, compass etc...
end


