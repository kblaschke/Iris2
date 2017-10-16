-- started but not yet finished walk-code : client-side collision, based on RunUO1 code (used by vetus-mundus for example)
-- TODO : walk2 : bridge = kTileDataFlag_StairBack or kTileDataFlag_StairRight or bridge ???
-- TODO : season translation


kImpassableSurface = kTileDataFlag_Impassable + kTileDataFlag_Surface

gMapsWithMobileMovementBlocking = { [0]=true } -- on felucca, you need full stamina to shove through other mobiles

gWalkMinDiagonalBlock = 1   -- 2 on some run shards (vm) but not all (uogamers:1) , 2 means you can move better through forests for example
		
kPersonHeight				= 16
kStepHeight					= 2
kAlwaysIgnoreDoors			= false
kIgnoreMovableImpassables	= false

gW3ItemTypeFlagsCache = {}

-- returns newZ or nil if (bMoveIsOk=bClientSidePassable) 
function GetNearestGroundLevel (xloc,yloc,iStartZ,iDir,bIgnoreDoors)
	local playermobile = GetPlayerMobile()
	local playerbodyid = playermobile and playermobile.artid or 400
	local bIsAlive = true
	if (playermobile and playermobile.bIsGhost) then bIsAlive = false end
	local mobile = {zloc=iStartZ,CanSwim=false,CantWalk=false,Alive=bIsAlive,bIgnoreDoors=bIgnoreDoors,Body={BodyID=playerbodyid},IsDeadBondedPet=false}
	mobile.mapindex			= MapGetMapIndex() -- TODO, needed for mobile blocking on felu ? wraith form etc ?
	mobile.bHasFullStamina	= true
	if (playermobile and playermobile.stats and (playermobile.stats.curStamina or 0) < (playermobile.stats.maxStamina or 0)) then mobile.bHasFullStamina = false end
	
	local posx,posy,posz,d = xloc,yloc,iStartZ,iDir
	
	local bMoveIsOk,newZ = W3_CheckMovement( mobile, posx,posy,posz, d)
	if ((not bMoveIsOk) and (gWalkDebugOverrideActive and gKeyPressed[key_lshift] and gKeyPressed[key_lalt])) then return gPlayerZLoc end
	--~ print("GetNearestGroundLevel",posx,posy,posz,"d"..d,bMoveIsOk and "ok" or "blocked",newZ)
	return bMoveIsOk and newZ or nil
end

RegisterListener("Hook_SetPlayerPos",function () W3TestUpdateGfx2() end)
RegisterListener("Hook_StartInGame"	,function () W3TestInit() end)

function W3TestStepForward ()
	local xloc,yloc,zloc,dir = gW3Test.xloc,gW3Test.yloc,gW3Test.zloc,gW3Test.dir
	local bIsWalkable,iNewZ = GetNearestGroundLevel(xloc,yloc,zloc,dir)
	print("W3TestStepForward",xloc,yloc,zloc,"d"..dir,bIsWalkable and "ok" or "blocked",iNewZ)
	if (not bIsWalkable) then return end
	gW3Test.zloc = iNewZ
	gW3Test.xloc,gW3Test.yloc = ApplyDir(dir,xloc,yloc)
	W3TestUpdateGfx()
end

function W3TestUpdateGfx2 ()
	if (not gW3Test) then return end
	-- get from network pos
	gW3Test.xloc,gW3Test.yloc,gW3Test.zloc = gPlayerXLoc,gPlayerYLoc,gPlayerZLoc
	--~ print("W3TestUpdateGfx2",gPlayerXLoc,gPlayerYLoc,gPlayerZLoc)
	W3TestUpdateGfx()
end

function W3TestUpdateGfx ()
	local x,y,z = Renderer3D:UOPosToLocal(gW3Test.xloc,gW3Test.yloc,gW3Test.zloc*0.1) 
	local qw,qx,qy,qz = Dir2Quaternion(gW3Test.dir)
	local bMoving,bTurning,bWarMode,bRunFlag = false,false,false,false
	gTileFreeWalk:SetPos_ClientSide(x-0.5,y+0.5,z)
end

function W3TestInit ()
	if (not gDisableTileFreeWalk) then return end
	--~ print("W3TestInit")
	gW3Test = {}
	local x,y,z = unpack(gOfflineModeCamStart)
	gW3Test.xloc,gW3Test.yloc,gW3Test.zloc = Renderer3D:LocalToUOPos(x,y,z * 10)
	gW3Test.zloc = round(gW3Test.zloc)
	print("W3TestInit",gW3Test.xloc,gW3Test.yloc,gW3Test.zloc)
	gW3Test.dir = 4
	local bOffline = false
	if (bOffline) then
		W3TestUpdateGfx()
		SetMacro("left",	function() gW3Test.dir = DirWrap(gW3Test.dir - 1) W3TestUpdateGfx() end)
		SetMacro("right",	function() gW3Test.dir = DirWrap(gW3Test.dir + 1) W3TestUpdateGfx() end)
		SetMacro("up",		function() W3TestStepForward() end)
		SetMacro("down",	function() 
			gW3Test.dir = DirWrap(gW3Test.dir + 4) 
			W3TestStepForward()  
			gW3Test.dir = DirWrap(gW3Test.dir + 4) 
			W3TestUpdateGfx()
			end)
	else
		W3TestUpdateGfx2()
		SetMacro("left",	function() gW3Test.dir = DirWrap(gW3Test.dir - 1) WalkStep_TurnToDir(gW3Test.dir) W3TestUpdateGfx2() end)
		SetMacro("right",	function() gW3Test.dir = DirWrap(gW3Test.dir + 1) WalkStep_TurnToDir(gW3Test.dir) W3TestUpdateGfx2() end)
		SetMacro("up",		function() 
			WalkStep_WalkInDir(gW3Test.dir,false,false) 
			W3TestUpdateGfx2() 
		end)
	end
end

-- old : Movable runuo:ImplFlag.Movable , probably true for dynamic, false for static    (door? probably for ghosts)
function W3_ItemIsMovable		(item)		return not item.bIsStatic end

-- handles clientside and serverside multis (no difference for us, just the way they are loaded)
-- calls fun(item,param)
-- item : used by filterItemFun, expected : (item.artid item.bIsStatic(ghost-doors,set to false/nil), inserts item into table)
-- item : used by W3_Check etc..  probably needs .xloc .yloc .zloc .artid
function W3_ForAllMultiPartsAtPos	(xloc,yloc,fun,param)
	local n = xloc..","..yloc
	for multi,v in pairs(gMultis) do 
		--~ print("W3_ForAllMultiPartsAtPos",multi,multi.lparts,#multi.lparts,multi.cache)
		local cache = multi.cache and multi.cache[n] -- see Multi_AddPartHelper 
		if (cache) then for k,item in pairs(cache) do fun(item,param) end end
	end
end

-- considers statics, dynamics and multis
function W3_ForAllItemsAtPos	(xloc,yloc,fun,param)
	W3_ForAllMultiPartsAtPos(xloc,yloc,fun,param)
	for k,static in pairs(MapGetStatics(xloc,yloc)) do fun(static,param) end
	for k,dynamic in pairs(GetDynamicsAtPosition(xloc,yloc)) do
		if dynamic.artid and (not ItemIsMulti(dynamic)) then -- non-multi
			fun(dynamic,param)
		end
	end
end



-- returns min,avg,max of 4 vertices
function W3_GetAverageZ			(xloc,yloc)			
	-- /cavern/RunUO1.0/src/Map.cs:173:        public void GetAverageZ
	local zTop		= MapGetGround(xloc  ,yloc  ).zloc
	local zLeft		= MapGetGround(xloc  ,yloc+1).zloc
	local zRight	= MapGetGround(xloc+1,yloc  ).zloc
	local zBottom	= MapGetGround(xloc+1,yloc+1).zloc

	local z,top,avg = zTop,zTop
	if ( zLeft   < z ) then z = zLeft	end
	if ( zRight  < z ) then z = zRight	end
	if ( zBottom < z ) then z = zBottom	end

	if ( zLeft   > top ) then top = zLeft	end
	if ( zRight  > top ) then top = zRight	end
	if ( zBottom > top ) then top = zBottom	end

	if ( math.abs( zTop - zBottom ) > math.abs( zLeft - zRight) ) then
		avg = math.floor( (zLeft + zRight) / 2.0 )
	else
		avg = math.floor( (zTop + zBottom) / 2.0 )
	end
	return z,avg,top
end

function W3_CheckMobileOnPosition (xloc,yloc,zloc)
	for k,mobile in pairs(GetMobileList()) do
		if (mobile.xloc == xloc and mobile.yloc == yloc and mobile.zloc >= zloc-15 and mobile.zloc <= zloc+15) then return true end
	end
end 
function W3_MobileBlockCheckNeeded (mobile) 
	return mobile.Alive and gMapsWithMobileMovementBlocking[mobile.mapindex] and (not mobile.bHasFullStamina)
end

--- bMoveIsOk,newZ = CheckMovement( Mobile mobile, Point3D loc, Direction d, out int newZ )
-- see also RunUO1.0/Scripts/Engines/Pathing/Movement.cs : CheckMovement and Check  and  RunUO1.0/src/Mobile.cs
function W3_CheckMovement( mobile, posx,posy,posz, d)
	d = DirWrap(d) -- alsor removes runflag
	local moveIsOk,newZ = false,0

	local xStart = posx -- ints
	local yStart = posy
	local xForward	, yForward	= ApplyDir( d    , xStart	,yStart	)
	local xLeft		, yLeft		= ApplyDir( d - 1, xStart	,yStart	)
	local xRight	, yRight	= ApplyDir( d + 1, xStart	,yStart	)

	if ( xForward < 0 or yForward < 0 or xForward >= MapGetWInTiles() or yForward >= MapGetHInTiles() ) then return false,newZ end
	
	if (W3_MobileBlockCheckNeeded(mobile) and W3_CheckMobileOnPosition(xForward,yForward,mobile.zloc)) then return false,newZ end
	
	local checkDiagonals = DirIsDiagonal(d)

	local ignoreMovableImpassables = kIgnoreMovableImpassables or (not mobile.Alive)  -- bool
	local reqFlags = kImpassableSurface -- TileFlag

	if ( mobile.CanSwim ) then reqFlags = BitwiseOR(reqFlags,kTileDataFlag_Wet) end

	local filterItemFun = function (item,param)
		local flags = GetStaticTileTypeFlags(item.artid)
		if (ignoreMovableImpassables and W3_ItemIsMovable(item) and TestMask(flags,kTileDataFlag_Impassable)) then return end
		if (BitwiseAND(flags,reqFlags) == 0) then return end
		if (item.artid < 0x4000) then table.insert(param,item) end
	end
	
	local itemsStart	= {} W3_ForAllItemsAtPos(xStart		,yStart		,filterItemFun	,itemsStart)
	local itemsForward	= {} W3_ForAllItemsAtPos(xForward	,yForward	,filterItemFun	,itemsForward)
	local items
	
	local startZ,startTop = W3_GetStartZ( mobile, posx,posy,posz, itemsStart)

	moveIsOk,newZ = W3_Check( mobile, itemsForward, xForward, yForward, startTop, startZ, mobile.CanSwim, mobile.CantWalk)
	--~ print("W3_CheckMovement startZ,startTop  check_forward=",startZ,startTop,moveIsOk,newZ)

	if ( moveIsOk and checkDiagonals ) then
		local itemsLeft		= {} W3_ForAllItemsAtPos(xLeft	,yLeft	,filterItemFun	,itemsLeft)
		local itemsRight	= {} W3_ForAllItemsAtPos(xRight	,yRight	,filterItemFun	,itemsRight)
		local myok1,ignored_z = W3_Check( mobile, itemsLeft , xLeft , yLeft , startTop, startZ, mobile.CanSwim, mobile.CantWalk)
		local myok2,ignored_z = W3_Check( mobile, itemsRight, xRight, yRight, startTop, startZ, mobile.CanSwim, mobile.CantWalk)
		local blockd = 0
		if (not myok1) then blockd = blockd + 1 end
		if (not myok2) then blockd = blockd + 1 end
		if (blockd >= gWalkMinDiagonalBlock) then moveIsOk = false end
	end

	if ( not moveIsOk ) then newZ = startZ end
	return moveIsOk,newZ
end


function W3_IsOK_Fun (item,param)
	local itemtype = GetStaticTileType(BitwiseAND(item.artid,0x3FFF))
	if ( TestMask(itemtype.miFlags,kImpassableSurface) ) then -- Impassable or Surface
		if ( item.zloc + itemtype.iCalcHeight > param.ourZ and param.ourTop > item.zloc ) then param.bFailed = true end -- intersection 
	end
end

function W3_IsDoor (flags,iTileTypeID) return TestMask(flags,kTileDataFlag_Door) or 
					iTileTypeID == 0x692 or 
					iTileTypeID == 0x846 or 
					iTileTypeID == 0x873 or 
					(iTileTypeID >= 0x6F5 and iTileTypeID <= 0x6F6) end
				

--~ private bool IsOk( bool ignoreDoors, int ourZ, int ourTop, Tile[] tiles, ArrayList items )
function W3_IsOK(  ignoreDoors,  ourZ, ourTop, x,y, items )
	-- statics and multis
	local param = {ourZ=ourZ,ourTop=ourTop}
	for k,item in pairs(MapGetStatics(x,y)) do W3_IsOK_Fun(item,param) end
	W3_ForAllMultiPartsAtPos(x,y,W3_IsOK_Fun,param)
	if param.bFailed then return false end
	
	-- items passed in
	for i,item in pairs(items) do -- Item
		local iTileTypeID = BitwiseAND(item.artid,0x3FFF) -- int
		local itemtype = GetStaticTileType(iTileTypeID) -- ItemData
		local flags = itemtype.miFlags -- TileFlag

		if (TestMask(flags,kImpassableSurface)) then -- Impassable or Surface
			if (ignoreDoors and W3_IsDoor(flags,iTileTypeID) ) then -- doors
				--continue
			else
				local checkZ = item.zloc -- int
				local checkTop = checkZ + itemtype.iCalcHeight -- int

				if ( checkTop > ourZ and ourTop > checkZ ) then return false end
			end
		end
	end

	return true
end

function W3_Check_Fun(item,param)
	local itemtype = GetStaticTileType(BitwiseAND(item.artid,0x3FFF)) -- ItemData
	local flags = itemtype.miFlags -- TileFlag

	if ( BitwiseAND(flags,kImpassableSurface) == kTileDataFlag_Surface or 
		(param.canSwim and TestMask(flags , kTileDataFlag_Wet)) ) then -- Surface and (not Impassable)
		if (param.cantWalk and BitwiseAND(flags , kTileDataFlag_Wet) == 0 ) then return end -- continue
		
		local itemZ = item.zloc
		local itemTop = itemZ
		local ourZ = itemZ + itemtype.iCalcHeight
		local ourTop = ourZ + kPersonHeight
		local testTop = param.checkTop

		if ( param.moveIsOk ) then
			local cmp = math.abs( ourZ - param.mobilezloc ) - math.abs( param.newZ - param.mobilezloc )
			if ( cmp > 0 or (cmp == 0 and ourZ > param.newZ) ) then return end -- continue
		end

		if ( ourZ + kPersonHeight > testTop ) then testTop = ourZ + kPersonHeight end

		if ( not itemtype.bBridge ) then itemTop = itemTop + itemtype.miHeight end

		if ( param.stepTop >= itemTop ) then
			local landCheck = itemZ

			if ( itemtype.miHeight >= kStepHeight ) then
				landCheck = landCheck + kStepHeight
			else
				landCheck = landCheck + itemtype.miHeight
			end

			if ( param.considerLand and landCheck < param.landCenter and param.landCenter > ourZ and testTop > param.landZ ) then
				--continue
			else
				if (W3_IsOK( param.ignoreDoors, ourZ, testTop, param.x, param.y, param.items ) ) then
					param.newZ = ourZ
					param.moveIsOk = true
				end
			end
		end
	end
end

--~ private bool Check( Map map, Mobile mobile, ArrayList items, int x, int y, int startTop, int startZ, bool canSwim, bool cantWalk, out int newZ )
-- returns moveIsOk,newZ
function W3_Check(  mobile,  items,  x,  y,  startTop,  startZ,  canSwim,  cantWalk )
	local param = {}

	local landTile		 = MapGetGround( x, y ) -- Tile
	local landTileFlags  = landTile.flags
	local landTileIsWet	 = TestMask(landTileFlags,kTileDataFlag_Wet)

	local landBlocks = TestMask(landTileFlags,kTileDataFlag_Impassable) -- bool
	param.considerLand = not landTile.bIgnoredByWalk -- bool

	if ( landBlocks and canSwim and landTileIsWet ) then
		landBlocks = false
	elseif ( cantWalk and (not landTileIsWet) ) then
		landBlocks = true
	end

	param.items = items
	param.x = x
	param.y = y
	param.newZ = 0
	param.landZ,param.landCenter,param.landTop = W3_GetAverageZ(x, y)
	param.moveIsOk = false
	param.stepTop = startTop + kStepHeight
	param.checkTop = startZ + kPersonHeight
	param.ignoreDoors = ( kAlwaysIgnoreDoors or (not mobile.Alive) or mobile.Body.BodyID == 0x3DB or mobile.IsDeadBondedPet or mobile.bIgnoreDoors )

	param.mobilezloc = mobile.zloc 
	param.canSwim = canSwim 
	param.cantWalk = cantWalk
	
	-- statics,multis and the items passed in
	for k,item in pairs(MapGetStatics(x,y)) do W3_Check_Fun(item,param) end
	W3_ForAllMultiPartsAtPos(x,y,W3_Check_Fun,param)
	for i,item in pairs(items) do W3_Check_Fun(item,param) end
	
	if ( param.considerLand and (not landBlocks) and param.stepTop >= param.landZ ) then
		local ourZ = param.landCenter
		local ourTop = ourZ + kPersonHeight
		local testTop = param.checkTop

		if ( ourZ + kPersonHeight > testTop ) then testTop = ourZ + kPersonHeight end

		local shouldCheck = true

		if ( moveIsOk ) then
			local cmp = math.abs( ourZ - param.mobilezloc ) - math.abs( param.newZ - param.mobilezloc ) -- int
			if ( cmp > 0 or (cmp == 0 and ourZ > param.newZ) ) then shouldCheck = false end
		end

		if ( shouldCheck and W3_IsOK( param.ignoreDoors, ourZ, testTop, x,y, items ) ) then
			param.newZ = ourZ
			param.moveIsOk = true
		end
	end

	return param.moveIsOk,param.newZ
end

function W3_GetStartZ_Fun	(item,param)
	local itemtype = GetStaticTileType(BitwiseAND(item.artid , 0x3FFF)) -- ItemData
	local calcTop = item.zloc + itemtype.iCalcHeight
	local flags = itemtype.miFlags

	if (	((not param.isSet) or calcTop >= param.zCenter) and 
			(	TestMask(flags , kTileDataFlag_Surface) or 
				( param.CanSwim and TestMask(flags,kTileDataFlag_Wet) ) ) and 
			param.posz >= calcTop )
	then
		if ( param.CantWalk and BitwiseAND(flags , kTileDataFlag_Wet) == 0 ) then
			--continue
		else 
			param.zLow = item.zloc
			param.zCenter = calcTop

			local top = item.zloc + itemtype.miHeight

			if ( (not param.isSet) or top > param.zTop ) then param.zTop = top end

			param.isSet = true
		end
	end
end

--~ private void GetStartZ( Mobile mobile, Map map, Point3D loc, ArrayList itemList, out int zLow, out int zTop )
-- returns zLow,zTop
function W3_GetStartZ(  mobile,  posx,posy,posz,  itemList )
	local landTile 		= MapGetGround( posx, posy ) -- Tile
	local landTileFlags	= landTile.flags
	local landBlocks	= TestMask(landTileFlags, kTileDataFlag_Impassable)
	local bWet			= TestMask(landTileFlags, kTileDataFlag_Wet)

	if ( landBlocks and mobile.CanSwim and bWet ) then
		landBlocks = false
	elseif ( mobile.CantWalk and (not bWet) ) then
		landBlocks = true
	end

	local landZ,landCenter,landTop = W3_GetAverageZ(posx, posy)

	local considerLand = not landTile.bIgnoredByWalk

	local param = {}
	param.posz = posz
	param.zCenter = 0
	param.zLow = 0
	param.zTop = 0
	param.isSet = false
	param.CanSwim = mobile.CanSwim
	param.CantWalk = mobile.CantWalk

	if ( considerLand and (not landBlocks) and posz >= landCenter ) then
		param.zLow = landZ
		param.zCenter = landCenter
		if ( (not param.isSet) or landTop > zTop ) then param.zTop = landTop end
		param.isSet = true
	end
	
	-- statics, multis, and the items
	for k,item in pairs(MapGetStatics(posx,posy)) do W3_GetStartZ_Fun(item,param) end
	W3_ForAllMultiPartsAtPos(posx,posy,W3_GetStartZ_Fun,param)
	for k,item in pairs(itemList) do W3_GetStartZ_Fun(item,param) end
	
	if ( not param.isSet ) then
		param.zLow = posz
		param.zTop = posz
	elseif ( posz > param.zTop ) then
		param.zTop = posz
	end
	
	return param.zLow,param.zTop
end

