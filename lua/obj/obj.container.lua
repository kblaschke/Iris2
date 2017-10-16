-- handles container stuff (used by both dynamic and mobile)
-- content of backpack, equipment of mobile/corpse (also player), spellbooks, secure trade, npc vendor shop, skills, paperdoll ....
-- TODO : later : paperdoll stuff, corpse... kPacket_Corpse_Equipment

gContainerPrototype = {}

gLastDebugContainer = nil

kUOToolTippOffX = -16
kUOToolTippOffY = 32

function GetContainer(container_or_serial) 
	if (not container_or_serial) then return nil end
	if (type(container_or_serial) == "table") then return container_or_serial end
	return gObjectList[container_or_serial] -- look up by serial
end

function gContainerPrototype:GetContent () return self.content end

function gContainerPrototype:DestroyContent ()
	for serial,object in pairs(self.content) do object:Destroy() end
	self.content = {}
	self:UpdateContent()
end

function gContainerPrototype:RemoveContentObject (object) -- object=dynamic
	self.content[object.serial] = nil
	object.container = nil
	self:UpdateContent()
end

function gContainerPrototype:AddContentObject (object) -- object=dynamic
	self.content[object.serial] = object
	object.container = self
	self:UpdateContent()
end



-- ----------------------------------------------- End of local functions -----------------------------

-- called from kPacket_Equip_Item
function HandleEquipItem (dynamicdata)
	local mobile = GetMobile(dynamicdata.iContainerSerial)
	if (not mobile) then 
		print("WARNING ! mobile update for unknown mobile received, update lost !")

		-- don't crash on UOX3, Lonewolf (this servers sends unknown Equip messages)
		if ((gServerType[gServerEmulator] ~= "Lonewolf") and (gServerType[gServerEmulator] ~= "SpherePolUox3")) then
			--print("Crash Client here!"..gServerType[gServerEmulator])
			--Crash()
		end
		
		-- the client state would loose sync with server, this is fatal, 
		-- but should never happen for correct server implementation ? (there are strange servers however...)
		-- an alternative would be to create the mobile if unknown , something like GetOrCreateMobile
		return
	end
	
	CreateOrUpdateDynamic(dynamicdata)
end

-- called from kPacket_Open_Container
function IsContainerAlreadyOpen (container_or_serial) 
	local container = GetContainer(container_or_serial)
	return container and (container.dialog or container.bIsOpen)
end

-- destroys old widgets and creates new ones from contents
function RefreshContainerItemWidgets (container) 
	if (container.dialog) then container.dialog:RefreshItems() end
end

gProfiler_OpenContainer = CreateRoughProfiler("OpenContainer")

-- called from kPacket_Open_Container
function HandleOpenContainer	(containerdata)
	if (not gGumpLoader) then 
		local container = GetOrCreateContainer(containerdata.serial)
		container.bIsOpen = true
		return 
	end
	--~ print("HandleOpenContainer",SmartDump(containerdata))
	
	--Ignore Shop container - created somewhere else
	if (containerdata.gumpid == kGumpIDShopContainer) then
		--AddFadeLines(sprintf("Open_ShopContainer id=0x%08x",containerdata.serial))
		return 
	end
	
	gProfiler_OpenContainer:Start(gEnableProfiler_OpenContainer)
	gProfiler_OpenContainer:Section("spellbook")
	
	--Old_Spellbook Container (Pol,Sphere,Lonewolf,RunUO1 etc.)
	if ((containerdata.gumpid == kGumpIDSpellbookContainer) and (not IsContainerAlreadyOpen(containerdata.serial))) then
		local spellbook = {}
		spellbook.old=true
		spellbook.serial = containerdata.serial
		spellbook.itemid = containerdata.gumpid
		-- container with spell is already created (invisible)
		printf("NET: Old_Spellbook: serial=0x%08x itemId=0x%04x offset=0x%04x\n",spellbook.serial or 0, spellbook.itemid or 0, spellbook.scrolloffset or 0)
		Open_Spellbook(spellbook)
		
		gProfiler_OpenContainer:End()
		return 
	end
	
	-- normal container
	gProfiler_OpenContainer:Section("GetOrCreateContainer")
	local container = GetOrCreateContainer(containerdata.serial)
	container.gumpid = containerdata.gumpid
	
	-- 0x003c = backpack
	-- 0x0030 = shopcontainer
	gProfiler_OpenContainer:Section("CreateUOContainerDialog")
	if (not container.dialog) then container.dialog = CreateUOContainerDialog(container) end
	container.bIsOpen = true
	gLastDebugContainer = container
	gProfiler_OpenContainer:Section("RefreshContainerItemWidgets")
	RefreshContainerItemWidgets(container)
	gProfiler_OpenContainer:Section("Hook_OpenContainer")
	NotifyListener("Hook_OpenContainer",container.dialog,container.serial,containerdata.gumpid)
	gProfiler_OpenContainer:End()
end

-- packet handlers for containers (chests, drawers, inventory..)
-- see also lib.packet.lua and lib.protocol.lua

-- pols sends kPacket_Open_Container first and then kPacket_Container_Contents , runuo the other way around
-- every container (data structure) can have zero-or-one associated dialog (graphical representation)
-- dialog is only created when it is displayed, on kPacket_Open_Container
-- TODO : check if iContainerSerial is secure trade serial
-- TODO : check if spellbook
-- destroys old widgets if neccessary

function CloseContainer (serial) 
	local container = GetContainer(serial)
	if (container) then
		container.bIsOpen = false
	end
	if (container and container.dialog) then
		NotifyListener("Hook_CloseContainer",container.dialog,serial)
		container.dialog:Destroy()
		container.dialog = nil
	end
end

-- creates if necessary
function GetOrCreateContainer (serial) 
	if (serial == 0 or (not serial)) then return end 
	local container = GetContainer(serial)
	if (not container) then 
		-- container didn't exist yet, create from scratch
		local dynamicdata = {} 
		dynamicdata.serial = serial
		container = CreateOrUpdateDynamic(dynamicdata)
	end
	return container
end

function OpenContainer	(serial, x,y)
	Send_DoubleClick(serial)
	local container = GetOrCreateContainer(serial) 
	if container.dialog then container.dialog:SetPos(x,y) end
end

--[[
function ScanItemPropBoolean	(props,line,pattern,field) end
function ScanItemPropNumber		(props,line,pattern,field) end

gItemPropAOS = {
	{"^luck (%d+)"								,{0}		,"luck"				},	
	{"^lower reagent cost (%d+)%%"				,{0}		,"lrc"				},	
	{"^lower mana cost (%d+)%%"					,{0}		,"lmc"				},	
	{"^defense chance increase (%d+)%%"			,{0}		,"dci"				},	
	{"^hit chance increase (%d+)%%"				,{0}		,"hci"				},	
	{"^skillbonus_sum"							,0			,"skillbonus_sum"	},-- dummy entry, pattern will never match
	{"^faster cast recovery (%d+)"				,{0}		,"fastcastrecov"	},	
	{"^faster casting (%d+)"					,{0}		,"fastcast"			},	
	{"^mage armor"								,false		,"magearmor"		},	
	{"^\"Maximum sockets allowed is (%d+).\""	,{0}		,"maxsocket"		},	
	{"^mana regeneration (%d+)"					,{0}		,"manareg"			},	
	{"^mana increase (%d+)"						,{0}		,"manainc"			},	
	{"^damage increase (%d+)%%"					,{0}		,"dmginc"			},	
	{"^spell damage increase (%d+)%%"			,{0}		,"sdi"				},	
	{"^strength bonus (%d+)"					,{0}		,"bonusstr"			},	
	{"^dexterity bonus (%d+)"					,{0}		,"bonusdex"			},	
	{"^intelligence bonus (%d+)"				,{0}		,"bonusint"			},	
	{"^<b>Insured</b>"							,false		,"insured"			},	
	{"^self repair (%d+)%%"						,{0}		,"selfrepair"		},	
	{"^enhance potions (%d+)%%"					,{0}		,"enhancepotion"	},	
	{"^hit point regeneration (%d+)"			,{0}		,"hpreg"			},	
	{"^hit point increase (%d+)"				,{0}		,"hpinc"			},	
	{"^physical resist (%d+)%%"					,{0}		,"resistphysical"	},	
	{"^poison resist (%d+)%%"					,{0}		,"resistpoison"		},	
	{"^cold resist (%d+)%%"						,{0}		,"resistcold"		},	
	{"^fire resist (%d+)%%"						,{0}		,"resistfire"		},	
	{"^energy resist (%d+)%%"					,{0}		,"resistenergy"		},	
	{"^strength requirement (%d+)"				,{0}		,"strengthreq"		},
	{"^durability (%d+) / (%d+)"				,{0,0}		,"durability"		},
	{"^Weight: (%d+) stones"					,{0}		,"weight"			},	
	{"^night sight"								,false		,"nightsight"		},
}

local function countmatches (text,searchpattern)
	local counter = 0
	for w in string.gmatch(text,searchpattern) do counter = counter + 1 end
	return counter
end
		
local function DebugDumpContainerContentInfo ()
	print("DebugDumpContainerContentInfo")
	local container = gLastDebugContainer  
	if (not container) then return end
	local fp = io.open("myitems.csv","a")
	
	local csvout = "name;type"
	for k1,arr in pairs(gItemPropAOS) do 
		local infopattern,defaultval,propfield = unpack(arr)
		csvout = csvout..";"..propfield
	end
	csvout = csvout..";".."rest"
	fp:write(csvout.."\n")
	
	for k,item in pairs(container:GetContent()) do 
		local name = GetStaticTileTypeName(item.artid) or ""
		local tooltiptext = AosToolTip_GetText(item.serial) or ""
		local props = {rest="",skillbonus_sum=0,skillbonus={}}
		
		for k,line in pairs(strsplit("\n",tooltiptext)) do
			if (k == 1) then 
				props.name = line
			else
				-- try to match all known property format strings
				local found = false
				for k1,arr in pairs(gItemPropAOS) do 
					local infopattern,defaultval,propfield = unpack(arr)
					local p0,p1,a,b = string.find(line,infopattern)
					if (p0) then -- only happens for one of the patterns
						found = true
						props[propfield] = {a,b}
					end
				end
				
				-- check for skillbonus like "Peacemaking +7"
				local p0,p1,skillname,bonus = string.find(line,"^([%w ]+) %+(%d+)")
				if (skillname) then
					--found = true   -- just count, but also mention in "rest"
					props.skillbonus_sum = props.skillbonus_sum + tonumber(bonus)
					props.skillbonus[skillname] = bonus
					
				end
				
				-- if unknown prop, append to props.rest
				if (not found) then props.rest = props.rest .. line .. "," end
			end
		end
		
		local bInteresting = false
		if (tonumber(props.skillbonus["Animal Taming"] or 0) >= 10) then bInteresting = true end
		if (props.lrc and tonumber(props.lrc[1]) >= 14) then bInteresting = true end
		if (props.luck and tonumber(props.luck[1]) >= 85) then bInteresting = true end
		if (bInteresting) then 
			print("interesting item found, moving to backpack")
			local amount = 1
			local itemserial = item.serial
			local x,y,z = 0,0,0
			local containerserial = gPlayerBackPack and gPlayerBackPack.serial
			if (containerserial) then
				print("grab",itemserial,containerserial)
				Send_Take_Object(itemserial,amount)
				Client_USleep(500)
				Send_Drop_Object(itemserial,x,y,z,containerserial)
				Client_USleep(1000)
			else 	
				print("error, backpack not found")
			end
		end
		
		local layer = GetPaperdollLayerFromTileType(item.artid) or 0
		
		local csvout = props.name..";"..layer
		for k1,arr in pairs(gItemPropAOS) do 
			local infopattern,defaultval,propfield = unpack(arr)
			local val = props[propfield] or defaultval
			if (val and type(val) == "number") then  -- 0 : skillbonus sum
				val = val
			elseif (val and val[2]) then 
				val = val[1].."/"..val[2] 
			elseif (val and val[1]) then 
				val = val[1]
			elseif (val and type(val) == "table") then  -- {} : "yes", etc for nightsight,magearmor : match without params
				val = "ja"
			else
				val = "nein"
			end
			csvout = csvout..";"..val
		end
		csvout = csvout..";"..props.rest
		fp:write(csvout.."\n")
	end
	fp:close()
end
]]--
