
-- paths

function GetConfigDirPath               () return gConfigPath end
function GetShardListDirPath            () return GetConfigDirPath().."shards/" end
function GetShardMemoryFilePath         () return GetConfigDirPath().."shardmemory.xml" end
function GetCharFilePath                (loginname,charid,subserverid) return GetConfigDirPath().."chars/"..table.concat({gLoginServerIP,gLoginServerPort,ShardListFileNamePartEncode(loginname or gLoginname),(subserverid or giGameServerID or 0),(charid or gCharID or 0)},".")..".xml" end
function GetShardConfigFilePath         (shardname) return GetShardListDirPath()..ShardListFileNamePartEncode(shardname)..".xml" end

function ShardListFileNamePartEncode    (x) return string.gsub(x,"[^0-9a-zA-Z_%-%(%) ]",".") end

function GetCharFileData 				(user,charid) 
	for i=0,5 do 
		local data = SimpleXMLLoad(GetCharFilePath(user,charid,i))
		print("GetCharFileData",user,charid,i,GetCharFilePath(user,charid,i))
		if (data) then return data end
	end
end

local gShardListCharInfoPlaces = { -- map,xloc,yloc,radius
	moonglow	={1,4470,1170,200},
	jhelom		={1,1410,3810,200},
	yew			={1,540,980,200},
	minoc		={1,2520,580,200},
	vesper		={1,2890,670,200},
	scarabrae	={1,600,2130,200},
	magincia	={1,3720,2160,200},
	haven		={1,3490,2560,200},
	trinsic		={1,1810,2820,200},
	brit		={1,1500,1620,200},
	nujelm		={1,3760,1300,200},
	cove		={1,2230,1210,200},
	serp		={1,2890,3470,200},
	bucs		={1,2700,2160,200},
	prison		={1,1715,1064,100},
}
function GetCharFileShortInfo(user,charid)
	local chardata = GetCharFileData(user,charid)
	print("GetCharFileShortInfo",user,charid,chardata)
	local charinfo = ""
	if (chardata) then
		local timediff = os.time() - (chardata.time or 0)
		charinfo = charinfo .. floor(timediff/3600/24).."d."
		
		local placename = "unknown"
		
		local mymap = chardata.map or 1
		if (mymap == kMapIndex.Felucca	) then placename = "felucca" end
		if (mymap == kMapIndex.Trammel	) then placename = "trammel" end
		if (mymap == kMapIndex.Ilshenar	) then placename = "ilshenar" end
		if (mymap == kMapIndex.Malas	) then placename = "malas" end
		if (mymap == kMapIndex.Tokuno	) then placename = "tokuno" end
		if (mymap == 0) then mymap = 1 end -- same places on fellu as on tram
		for k,v in pairs(gShardListCharInfoPlaces) do 
			local map,xloc,yloc,radius = unpack(v)
			if (mymap == map and GetUODistToPos(xloc,yloc,chardata.xloc or 0,chardata.yloc or 0) <= radius) then 
				placename = placename..":"..k 
				break 
			end
		end 
		if (placename) then charinfo = charinfo .. "["..placename.."]".."." end
			
		
		
		-- glSkillNamesShort
		
		local valname = {[1200]="leg",[1100]="elder",[1000]="gm"}
		local arr = {}
		for k,skill in pairs(chardata.skills) do skill.id = k end
		local skills2 = SortedArrayFromAssocTable(chardata.skills,function (a,b) return a.value > b.value end)
		for k,skill in ipairs(skills2) do  -- skill.value >= 50 -> 5.0 skillpoints
			assert(skill.value,"bad skillvalue")
			if (skill.value >= 50) then table.insert(arr,(glSkillNamesShort[skill.id] or ("s"..tostring(skill.id)))..":"..(valname[skill.value] or sprintf("%0.1f",skill.value/10))) end
			if (k >= 7) then break end
		end
		charinfo = charinfo .. table.concat(arr,",")
	end
	return charinfo
end



-- notes

function InitShardList () 
    LoadStoredPasswords()
    LoadShardMemory()
    LoadShardList()
    --~ for shardname,shard in pairs(gShardList) do
        --~ local filepath = GetShardConfigFilePath(shardname)
        --~ print("InitShardList",shardname,shard,filepath)
        --~ SimpleXMLSave(filepath,shard)
    --~ end
    --~ SimpleXML_Test()
    --~ os.exit(0)
end

-- ***** ***** ***** ***** ***** chars

RegisterListener("Hook_Packet_Character_List",function (charlist) 
    local plaincharlist = {serverid=giGameServerID}
    for k,v in pairs(charlist.chars) do plaincharlist[k] = v.name end
    plaincharlist.gLoginServerIP = gLoginServerIP
    plaincharlist.gLoginServerPort = gLoginServerPort
    plaincharlist.gLoginname = gLoginname
    plaincharlist.giGameServerID = giGameServerID
    ShardMemorySet("charlist",table.concat({gLoginServerIP,gLoginServerPort,ShardListFileNamePartEncode(gLoginname),giGameServerID},":"),plaincharlist)
end)

RegisterListener("Hook_Player_Full_equip",function (mobiledata,equipmentdata) 
    if (gShardListPlayerEquipAlreadySaved) then return end
    gShardListPlayerEquipAlreadySaved = true
    ShardListSavePlayerMobile()
    RegisterIntervalStepper(30*1000,ShardListSavePlayerMobile) 
end)

RegisterListener("Hook_Player_Skills",function (skills) 
    if (gShardListPlayerSkillAlreadySaved) then return end
    gShardListPlayerSkillAlreadySaved = true
    ShardListSavePlayerMobile()
end)

-- stores body,equip,mount       todo : skills, but change too often for xml
function ShardListSavePlayerMobile ()
    local mobile = GetPlayerMobile()
    print("###ShardListSavePlayerMobile",mobile,gPlayerSkills)
    if (not mobile) then return end
    if (not gPlayerSkills) then return end
    local charname = gCharName
    
    --[[
    -- calc and check has, no need to save if nothing changed
    local hash = {mobile.artid,mobile.hue}
    for k,layer in pairs(gLayerType) do 
        local item = mobile:GetEquipmentAtLayer(layer) 
        if (item) then table.insert(hash,item.serial) end
    end
    for skillid,skill in pairs(gPlayerSkills) do table.insert(hash,skill.base_value) end
    hash = table.concat(hash,"#")
    if (hash == gShardListSavePlayerMobile_LastHash) then return end
    gShardListSavePlayerMobile_LastHash = hash
    print("saving data...",hash)
    ]]--
    
    -- save the data
    local data = {  charname=charname, artid=mobile.artid, hue=mobile.hue, xloc=mobile.xloc, yloc=mobile.yloc, zloc=mobile.zloc, map=gMapIndex, equip={},skills={} }
    for k,layer in pairs(gLayerType) do 
        local item = mobile:GetEquipmentAtLayer(layer) 
        if (item) then data.equip[layer] = {artid=item.artid,hue=item.hue} end
    end
    for skillid,skill in pairs(gPlayerSkills) do 
        data.skills[skillid] = {value=skill.value,base_value=skill.base_value,lockstate=skill.lockstate,name=glSkillNames[skillid]} 
    end
    data.time = os.time()
    data.timetext = os.date("%d %b %Y %H:%M",data.time) -- 10 Feb 2009 16:14       %H:%M:%S
    SimpleXMLSave(GetCharFilePath(),data)
end

-- ***** ***** ***** ***** ***** shard list 

function LoadShardList () 
    local path_folder = GetShardListDirPath()
    local arr_files = dirlist(path_folder,false,true)
    for k,filename in pairs(arr_files) do
        local ext = string.lower(string.sub(filename,-4))
        local shardname = string.sub(filename,1,-5)
        local filepath = path_folder .. filename
        print("LoadShardList",shardname,filepath,ext) 
        if (ext == ".xml") then 
            gShardList[shardname] = SimpleXMLLoad(filepath)
        end
    end
end
 
-- ***** ***** ***** ***** ***** shard memory 

function LoadShardMemory    () gShardMemory =   SimpleXMLLoad(GetShardMemoryFilePath()) or {} end
function SaveShardMemory    ()                  SimpleXMLSave(GetShardMemoryFilePath(),gShardMemory) end

function ShardMemoryGetList (listname) return gShardMemory[listname] end
function ShardMemoryGet     (listname,key) 
    local list = gShardMemory[listname]
    return list and list[key]
end
function ShardMemorySet     (listname,key,value)
    local list = gShardMemory[listname]
    if (not list) then list = {} gShardMemory[listname] = list end
    list[key] = value
    SaveShardMemory()
end

-- ***** ***** ***** ***** ***** stored passwords

-- store password when login succeeds
RegisterListener("Hook_Packet_Server_List",function ()
    if (not gRememberPassword) then return end
    SetStoredPassword(gLoginServerIP,gLoginServerPort,gLoginname,gPassword)
end)
gStoredPasswords = {}
function GetStoredPasswordsFilePath () return GetConfigDirPath().."passwords.xml" end
function SaveStoredPasswords ()                     SimpleXMLSave(GetStoredPasswordsFilePath(),gStoredPasswords) end
function LoadStoredPasswords () gStoredPasswords =  SimpleXMLLoad(GetStoredPasswordsFilePath()) or {} end

function GetStoredPassword          (host,port,username) return gStoredPasswords[host..":"..port..":"..username] end
function SetStoredPassword          (host,port,username,password) gStoredPasswords[host..":"..port..":"..username] = password SaveStoredPasswords() end
function ClearStoredPassword        (host,port,username) gStoredPasswords[host..":"..port..":"..username] = nil SaveStoredPasswords() end
function ClearAllStoredPasswords    () gStoredPasswords = {} SaveStoredPasswords() end

function TestStoredPasswords ()
	local host,port = "example.org",2593
	local user1 = "weirdguy"
	local user2 = "somedude"
	LoadStoredPasswords()
	--~ SetStoredPassword(host,port,user1,"secret1234")
	--~ SetStoredPassword(host,port,user2,"secret5555")
	print(user1,GetStoredPassword(host,port,user1)) --~ weirdguy        secret1234
	print(user2,GetStoredPassword(host,port,user2)) --~ somedude        secret5555
	os.exit(0)
end

