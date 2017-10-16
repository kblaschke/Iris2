-- handles dynamic items (lamps,doors,inventory,...)
-- see also obj.container.lua

-- NOTE : pre-knut old-trunk-dynamics were ONLY objects in world, 
-- new/post-knut dynamics are containers, items inside container and mobile equipment as well

--[[
dynamic.serial				
dynamic.artid	-- see ApplyArtidStackManipulation
dynamic.artid_base			
dynamic.artid_addstack		
dynamic.amount				
dynamic.layer	-- only if dynamic is mobile equipment from kPacket_Equipped_MOB	 or from kPacket_Equip_Item	
dynamic.xloc				
dynamic.yloc				
dynamic.zloc	-- only nonzero if in world : kPacket_Show_Item				
dynamic.dir		-- only nonzero if in world : kPacket_Show_Item				
dynamic.iContainerSerial 	
dynamic.hue 				
dynamic.flag	-- only nonzero if in world : kPacket_Show_Item -- some kind of status or flags, usage unknown	

CreateOrUpdateDynamic(dynamicdata)
]]--

gDynamicPrototype = {}


gDynamicAutoClickByArtID = {} -- for pre-aos tooltips/labels  (containers like keg:0x1940,runebook:0x0efa,... via gContainerArtIDs)
gDynamicAutoClickByArtID[0x0bd2] = true -- house sign
gItemAutoClickSent = {}
-- todo : hausschild

function GetDynamic (dynamic_or_serial) 
	if (not dynamic_or_serial) then return nil end
	if (type(dynamic_or_serial) == "table") then return dynamic_or_serial end
	return gDynamics[dynamic_or_serial] -- look up by serial
end


-- constructor, don't call directly, use CreateOrUpdateDynamic() instead
function InitializeDynamic	(serial)
	assert(serial ~= 0)
	
	-- create base object and register in mobile-list
	local dynamic = InitializeObject(serial)
	gDynamics[serial] = dynamic
	
	-- install methods
	ArrayOverwrite(dynamic,gContainerPrototype)
	ArrayOverwrite(dynamic,gDynamicPrototype)
	
	dynamic.content = {}
	dynamic.isdynamic = true -- needed to identify type in 2d renderer and for asserts
	dynamic.artid = 0		
	dynamic.artid_base = 0			
	dynamic.artid_addstack = 0		
	dynamic.amount = 0					
	dynamic.xloc = 0				
	dynamic.yloc = 0				
	dynamic.zloc = 0			
	dynamic.dir = 0				
	dynamic.iContainerSerial = 0 	
	dynamic.hue = 0 				
	dynamic.flag = 0
	
	return dynamic
end



-- called from kPacket_Show_Item,kPacket_Object_to_Object,kPacket_Container_Contents
-- mobile is only set if called from mobile:Update with equipmentdata , e.g. from kPacket_Equipped_MOB or kPacket_Equip_Item
function CreateOrUpdateDynamic	(dynamicdata,mobile)
	local dynamic = GetDynamic(dynamicdata.serial)
	if (not dynamic) then dynamic = InitializeDynamic(dynamicdata.serial) end
	dynamic:Update(dynamicdata,mobile)
	return dynamic
end

-- see also CreateOrUpdateDynamic
function gDynamicPrototype:Update (dynamicdata,mobile)
	if (self.bDestructionInProgress) then return end -- avoid updates during destruction
	--print("gDynamicPrototype:Update",self,self.serial,_TRACEBACK())
	
	if (dynamicdata) then 
		assert(not dynamicdata.artid,"this shouldn't be set from dynamicdata, replaced by artid_base") -- bugcheck
		for k,v in pairs(dynamicdata) do self[k] = v end 
	end
	self:ApplyArtidStackManipulation()
	
	
	-- corspe   
	-- if (dynamicdata and dynamicdata.artid_base == kCorpseDynamicArtID) then ... end 
	-- nothing needs to be done for here, see gCurrentRenderer:AddDynamicItem
	
	-- self is mobile equipment
	local mobile = mobile or GetMobile(self.iContainerSerial)
	if (mobile and mobile.ismobile)  then
		-- kPacket_Equipped_MOB : 
		-- dynamicdata.serial 
		-- dynamicdata.artid
		-- dynamicdata.layer
		-- dynamicdata.hue
		
		-- kPacket_Equip_Item : 
		-- dynamicdata.serial  		
		-- dynamicdata.artid_base		
		-- dynamicdata.layer			
		-- dynamicdata.iContainerSerial -- mobile serial
		-- dynamicdata.hue 	
		
		self.iContainerSerial = mobile.serial
		
		self.mobile = mobile 				
		self.mobile_serial = mobile.serial	
		
		-- destroy old item on layer, if any
		if (self.layer) then 
			local old = mobile:GetEquipmentAtLayer(self.layer)
			if (old and old ~= self) then old:Destroy() end
		end
		-- self:SetContainer(self.iContainerSerial) is called later and tiggers mobile:Update()
	end
	
	local bIsInWorld = self.iContainerSerial == 0
	-- i think bIsInWorld is only true if the object was initially created using kPacket_Show_Item
	-- or is it possible for object_to_object/equip_item to set iContainerSerial to zero ?

	-- TODO : if (self.artid >= gMulti_ID +100) .. model is multi
	-- gMulti_ID = hex2num("0x4000")
	-- TODO : check self.artid for boat

	-- if (gTileTypeLoader) then self.z_typename=GetStaticTileTypeName(self.artid) end

	-- update container
	self:SetContainer(self.iContainerSerial)
	
	-- secure trade hook
	SecureTradeRebuildContainerHook(self)
	
	-- update stuff if self is container
	RefreshContainerItemWidgets(self)
	
	self:NotifyListener("Dynamic_Update")
	
	-- destroy old world gfx
	if (self.bWorldGfxInitialised) then 
		self.bWorldGfxInitialised = false
		gCurrentRenderer:RemoveDynamicItem(self) 
	end
	
	-- only create WorldGfx if item IS IN WORLD (and not in inside a container, or being a container itself like shop stuff)
	if (bIsInWorld) then 
		self.bWorldGfxInitialised = true
		UpdateMultiData(self)
		gCurrentRenderer:AddDynamicItem(self) -- create new gfx
		gCurrentRenderer:UpdateDynamicItemPos(self)
	end
	
	if (gbAutoClickItems and (not gItemAutoClickSent[self.serial])) then
		gItemAutoClickSent[self.serial] = true
		if ((not GetItemTooltipOrLabel(self.serial)) and (gDynamicAutoClickByArtID[self.artid] or gContainerArtIDs[self.artid])) then
			Send_SingleClick(self.serial,true)
		end
	end
		
	
	DynamicUpdatePosCache(self)
end

function gDynamicPrototype:UpdateContent () self:Update() NotifyListener("Hook_Dynamic_UpdateContent",self.serial) end

function gDynamicPrototype:GetUODistToPlayer () return GetUODistToPlayer(self.xloc,self.yloc) end 

function gDynamicPrototype:Destroy	()
	self.bDestructionInProgress = true
	--print("gDynamicPrototype:Destroy",self,self.serial,_TRACEBACK())
	if (self.bIsDead) then printdebug("net","warning, double free dyamic") return end -- already destroyed before (a must check because runuo1 sends this twice)
	self:NotifyListener("Dynamic_Destroy")
	self:SetContainer(nil) -- calls self.mobile:Update() if self is equipment item in mobile
	
	-- paperdoll widgets (and maybe container content things)
	if (self.widget) then self.widget:Destroy() self.widget = nil end
	if (self.widget2) then self.widget2:Destroy() self.widget2 = nil end
	
	-- destroy old world gfx
	if (self.bWorldGfxInitialised) then 
		self.bWorldGfxInitialised = false
		gCurrentRenderer:RemoveDynamicItem(self) 
	end
	
	gDynamics[self.serial] = nil
	DynamicRemoveFromPosCache(self)
	
	-- remove multi entry
	if (self.multi) then
		gMultis[self.multi] = nil 
	end
	
	CleanupObject(self)
end

-- updates widgets automatically through old,new:UpdateContent() message
function gDynamicPrototype:SetContainer	(newcontainer_or_serial)
	local newcontainer = GetOrCreateContainer(newcontainer_or_serial)
	if (self.container == newcontainer) then return end
	if (self.container) then self.container:RemoveContentObject(self) end -- remove from old
	if (newcontainer) then newcontainer:AddContentObject(self) end -- add to new (sets self.container)
end

function gDynamicPrototype:NotifyListener	(eventname)
	NotifyListener(eventname..self.serial,self)
	NotifyListener(eventname,self)
end

-- only called from dynamic:Update
-- TODO : Add sepearate FILTER : for several Clientside GFX manipulation (Game Pieces & Gold,Silver,...)
-- calculates artid from artid_base,artid_addstack and several special cases (coins,chess pieces..)
-- chess pieces etc have an y offset : self.yloc = self.yloc+self.gumpyoffset, but don't change the original y here, 
-- as this method is called for every update. also DON'T DO THIS FOR DYNAMICS IN WORLD ! (offset 20 tiles is deadly)
function gDynamicPrototype:ApplyArtidStackManipulation ()
	local custom_artid = false
	self.artid = self.artid_base
	self.usegump = false
	self.gumpyoffset = 0
	
	-- from varan
	-- gold
	if (self.artid_base == hex2num("0xEED") and self.amount >= 2) then self.artid = hex2num("0xEEE") custom_artid = true end
	if (self.artid_base == hex2num("0xEED") and self.amount >= 6) then self.artid = hex2num("0xEEF") custom_artid = true end
	-- gold
	if (self.artid_base == hex2num("0xEEA") and self.amount >= 2) then self.artid = hex2num("0xEEB") custom_artid = true end
	if (self.artid_base == hex2num("0xEEA") and self.amount >= 6) then self.artid = hex2num("0xEEC") custom_artid = true end
	-- Silver
	if (self.artid_base == hex2num("0xEF0") and self.amount >= 2) then self.artid = hex2num("0xEF1") custom_artid = true end
	if (self.artid_base == hex2num("0xEF0") and self.amount >= 6) then self.artid = hex2num("0xEF2") custom_artid = true end
	-- cannonball
	if (self.artid_base == hex2num("0xE73") and self.amount >= 4) then self.artid = hex2num("0xE74") custom_artid = true end

	--TODO : if not in this list, and amount > 0 : draw the graphic 2 times
	--for example: if (self.artid_base == hex2num("0xE73") and self.amount > 0) then self.artid = hex2num("0xE74") self.drawcount=2 end

	-- ART -> GUMP
	-- white backgammon game piece
	if (self.artid_base == hex2num("0x3584")) then self.artid = hex2num("0x91B") self.usegump=true custom_artid = true end
	-- brown backgammon game piece
	if (self.artid_base == hex2num("0x358b")) then self.artid = hex2num("0x922") self.usegump=true custom_artid = true end
	-- brown chess pieces
	if (self.artid_base == hex2num("0x3590")) then self.artid = hex2num("0x927") self.gumpyoffset = -20 self.usegump=true custom_artid = true end
	if (self.artid_base == hex2num("0x358d")) then self.artid = hex2num("0x924") self.gumpyoffset = -20 self.usegump=true custom_artid = true end
	if (self.artid_base == hex2num("0x358f")) then self.artid = hex2num("0x926") self.gumpyoffset = -20 self.usegump=true custom_artid = true end
	if (self.artid_base == hex2num("0x358c")) then self.artid = hex2num("0x923") self.gumpyoffset = -20 self.usegump=true custom_artid = true end
	if (self.artid_base == hex2num("0x3591")) then self.artid = hex2num("0x928") self.gumpyoffset = -20 self.usegump=true custom_artid = true end
	if (self.artid_base == hex2num("0x358e")) then self.artid = hex2num("0x925") self.gumpyoffset = -20 self.usegump=true custom_artid = true end
	-- white chess pieces
	if (self.artid_base == hex2num("0x3589")) then self.artid = hex2num("0x920") self.gumpyoffset = -20 self.usegump=true custom_artid = true end
	if (self.artid_base == hex2num("0x3586")) then self.artid = hex2num("0x91D") self.gumpyoffset = -20 self.usegump=true custom_artid = true end
	if (self.artid_base == hex2num("0x3588")) then self.artid = hex2num("0x91F") self.gumpyoffset = -20 self.usegump=true custom_artid = true end
	if (self.artid_base == hex2num("0x3585")) then self.artid = hex2num("0x91C") self.gumpyoffset = -20 self.usegump=true custom_artid = true end
	if (self.artid_base == hex2num("0x358a")) then self.artid = hex2num("0x921") self.gumpyoffset = -20 self.usegump=true custom_artid = true end
	if (self.artid_base == hex2num("0x3587")) then self.artid = hex2num("0x91E") self.gumpyoffset = -20 self.usegump=true custom_artid = true end

	-- self.yloc = self.yloc+self.gumpyoffset 
	if ((not custom_artid) and self.artid_addstack and self.amount > 1) then 
		self.artid = self.artid + self.artid_addstack 
	end
end
