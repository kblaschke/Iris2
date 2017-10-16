-- ***** ***** ***** ***** ***** offline mode

-- postxt is a string for the position, e.g. 5260,1333  , can be nil
function StartOfflineMode (postxt)
	print("##################################")
	print("StartOfflineMode",postxt)		
	MainMenuStopAllMenus() 
	
	if (gCommandLineSwitches["-som"]) then 
		local confname = gCommandLineArguments[gCommandLineSwitches["-som"]+1]
		print("StartOfflineMode config",confname)
		gMaps = gMaps or {}
		for k,v in pairs((gShardList[confname] or {}).gMaps or {}) do print("gMaps["..k.."] override") gMaps[k] = v end
	end
	if (gCommandLineSwitches["-so"]) then 
		gMapIndex = tonumber(gCommandLineArguments[gCommandLineSwitches["-so"]+2]) or gMapIndex
	end
	MapChangeRequest(gMapIndex or 0)
	
	if (gDialog_IrisLogo) then gDialog_IrisLogo:SetVisible(false) end

	gStartGameWithoutNetwork = true
	MultiTexTerrain_NotifyMapChange()
	
	local x,y,z = -1483,1527,2 -- osi-britannia map0.mul

	if (gMapIndex == 1) then
	elseif (gMapIndex == 2) then
		
	elseif (gMapIndex == 3) then
		
	elseif (gMapIndex == 4) then
		
	elseif (gMapIndex == 5) then
		x,y,z = -635,3037,4		
	end
	
	--if (gGroundBlockLoader) then x,y,z = -gGroundBlockLoader:GetMapW()*8/2,gGroundBlockLoader:GetMapH()*8/2,0 end
	if (gOfflineModeCamStart) then x,y,z = unpack(gOfflineModeCamStart) end
	
	if (postxt) then
		local t1,t2,t3 = unpack(strsplit(",",postxt))
		x,y,z = tonumber(t1) and -tonumber(t1) or x, tonumber(t2) or y, tonumber(t3) or z
		print("StartOfflineMode ",x,y,z,t1,t2,t3)
	end
		
	-- set z position to terrainheight at starting location
	local tt,zz = GetGroundAtAbsPos(-x,y)
	if zz then
		--~ print("#",x,y,tt,z,zz) 
		z = zz
	end

	gCurrentRenderer:InitLocalCam(x,y,z)

	-- Binds key and Inits all InGame-Data
	StartInGame() -- otherwise handled by the serverpacket (kPacket_Login_Complete)

	-- Create mobile and equipment data to create a mobile to use.
	local mobiledata = {}
	-- Serials used are in incrementing order until a good system of serializing
	--  mobiles and items offline is found
	-- TODO: Find/Learn way to generate serial numbers for mobiles and items
	mobiledata.serial	= 1
	mobiledata.artid	= 400 -- artid=400:human 987=gmrobe
	mobiledata.xloc	= x
	mobiledata.yloc	= y
	mobiledata.zloc	= z
	mobiledata.dir	= 0
	mobiledata.flag	= 0
	mobiledata.notoriety = GetNotorietyColor(kNotoriety_Orange)
	mobiledata.hue	= 33780 -- dye/skin color
	mobiledata.amount = 1
	mobiledata.dir2 = -1
	
	local equipmentdata = {}
	--Create each piece and add into appropriate equipment layer
	local mace = {}
	mace.serial = 2
	mace.artid_base = 3932
	mace.layer = kLayer_OneHanded
	mace.hue = 0
	equipmentdata[mace.layer] = mace
	local dragon_helm = {}
	dragon_helm.serial = 3
	dragon_helm.artid_base = 9797
	dragon_helm.layer = kLayer_Helm
	dragon_helm.hue = 0
	equipmentdata[dragon_helm.layer] = dragon_helm
	local kite_shield = {}
	kite_shield.serial = 4
	kite_shield.artid_base = 7028
	kite_shield.layer = kLayer_TwoHanded
	kite_shield.hue = 0
	equipmentdata[kite_shield.layer] = kite_shield
	local plate_chest = {}
	plate_chest.serial = 5
	plate_chest.artid_base = 5141
	plate_chest.layer = kLayer_TorsoInner
	plate_chest.hue = 0
	equipmentdata[plate_chest.layer] = plate_chest
	local plate_arms = {}
	plate_arms.serial = 6
	plate_arms.artid_base = 5136
	plate_arms.layer = kLayer_Arms
	plate_arms.hue = 0
	equipmentdata[plate_arms.layer] = plate_arms
	local plate_gloves = {}
	plate_gloves.serial = 7
	plate_gloves.artid_base = 5140
	plate_gloves.layer = kLayer_Gloves
	plate_gloves.hue = 0
	equipmentdata[plate_gloves.layer] = plate_gloves
	local plate_legs = {}
	plate_legs.serial = 8
	plate_legs.artid_base = 5137
	plate_legs.layer = kLayer_Pants
	plate_legs.hue = 0
	equipmentdata[plate_legs.layer] = plate_legs
	local offline_mount = {}
	offline_mount.serial = 9
	offline_mount.artid_base = 16034
	offline_mount.layer = kLayer_Mount
	offline_mount.hue = 0
	equipmentdata[offline_mount.layer] = offline_mount
	
	-- Following the example of Login_Confirm
	UpdatePlayerBodySerial(mobiledata.serial)
	CreateOrUpdateMobile(mobiledata,equipmentdata)
	
	local playermobile = GetPlayerMobile()
	playermobile:SetName("Iris2","Iris2") -- Any name will do

	gCurrentRenderer:SetOfflineStartPos(x,y,z)

	-- Unbind some keys only for offline mode (rest is the same as InGame)
	UnBindArr({"u","q","e","tab","r","t","k","j","b","p","g","h","y"})

	-- offline : tilefree walk teleport
	SetMacro("f6",function () gCurrentRenderer:OfflineTeleportToMouse() end)
end
