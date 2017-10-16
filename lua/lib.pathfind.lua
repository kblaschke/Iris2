-- a star pathfinding

cPathFind2 = {}
kPathFind2_MaxSteps = 4000

function cPathFind2:CalcRouteFromPlayerToPos (xloc,yloc,tolerance,iJobWaitInterval,iTimeOut,bIgnoreDoors) 
	local xloc0,yloc0,zloc0 = GetPlayerPos()
	return self:CalcRouteFromPosToPos(xloc0,yloc0,zloc0,GetPlayerDir(),xloc,yloc,tolerance,WalkGetInterval(true),gWalkTimeout_DirectionChange,iJobWaitInterval,iTimeOut,bIgnoreDoors)
end

-- returns an array with {pos1,pos2,pos3,...} where each pos = {xloc,yloc,zloc,and,some,data,vars...}
function cPathFind2:CreateResult(pos,newxloc,newyloc,newzloc,newdir)
	local numstep = 0
	local curpos = pos  while curpos do curpos = curpos[7] numstep = numstep + 1 end -- iter #1 : count
	--~ print("numstep",numstep)
	local res = {}
	local curpos = pos  while curpos do 
		numstep = numstep - 1 
		if (numstep > 0) then res[numstep] = curpos end -- do not write the "first" entry, it's the position we started at
		curpos = curpos[7] 
	end -- #iter #2 : write
	table.insert(res,{newxloc,newyloc,newzloc,newdir})
	return res
end

function cPathFind2:CalcRouteFromPosToPos (xloc0,yloc0,zloc0,dir0,xloc1,yloc1,tolerance,walktime,turntime,iJobWaitInterval,iTimeOut,bIgnoreDoors)
	tolerance = tolerance or 0
	walktime = walktime or WalkGetInterval(true) -- defaults to current player run speed
	turntime = turntime or gWalkTimeout_DirectionChange
	self.reached_bypos = {}
	self.reached_byheuristic = {}
	self:PushPos(xloc0,yloc0,zloc0,DirWrap(dir0),0,GetUODistToPos(xloc0,yloc0,xloc1,yloc1))
	local isteps = 0
	local next_wait_t = iJobWaitInterval and (Client_GetTicks() + iJobWaitInterval)
	local endt = iTimeOut and (Client_GetTicks() + iTimeOut)
	while true do
		if (iTimeOut and Client_GetTicks() > endt) then return end
		if (next_wait_t) then
			local t = Client_GetTicks()
			if (t > next_wait_t) then next_wait_t = t + iJobWaitInterval job.wait(1) end
		end
		local pos = self:PopNextPos()
		if (not pos) then return end -- target not reachable
		local xloc,yloc,zloc,dir,t,heuristic,oldpos = unpack(pos)
		isteps = isteps + 1
		if (isteps > kPathFind2_MaxSteps) then print("cPathFind2:CalcRouteFromPosToPos : giving up after",isteps,"steps") return end -- give up
		--~ if (math.mod(isteps,100) == 0) then 
			--~ print("cPathFind2:CalcRouteFromPosToPos step","#"..isteps,xloc,yloc,zloc,dir,t)
		--~ end
		for newdir = 0,7 do 
			local newzloc = GetNearestGroundLevel(xloc,yloc,zloc,newdir,bIgnoreDoors)
			if (newzloc) then
				local newxloc = xloc + GetDirX(newdir)
				local newyloc = yloc + GetDirY(newdir)
				local dist = GetUODistToPos(newxloc,newyloc,xloc1,yloc1)
				if (dist <= tolerance) then return self:CreateResult(pos,newxloc,newyloc,newzloc,newdir) end -- target reached !
				local t2 = t + walktime + ((newdir ~= dir) and turntime or 0)
				local heuristic = dist + ((newdir ~= dir) and 0.1 or 0) -- + t2/1000    -- small malus for changing dir
				self:PushPos(newxloc,newyloc,newzloc,newdir,t2,heuristic,pos)
			end
		end
	end
	--~ iFullDir = BitwiseOR(iDir,bRunFlag and kWalkFlag_Run or 0) -- includes runflag
end

function cPathFind2:PopNextPos()
	local arr = self.reached_byheuristic
	local mint,minlist = next(arr)
	if (not mint) then return end
	for curt,curlist in pairs(arr) do -- iterate over all available "heuristics" and find the minimum
		if (curt < mint) then mint=curt minlist=curlist end
	end
	local pos,igno = next(minlist) -- get first/any entry from the list (they all have the same t so it doesn't matter which)
	minlist[pos] = nil -- pop:remove
	if (not next(minlist)) then arr[mint] = nil end -- if minlist table has been emptied, remove it from the reached_byheuristic-list
	return pos
end

function cPathFind2:PushPos(xloc,yloc,zloc,dir,t,heuristic,prepos)
	local r0 = self.reached_bypos
	local r1 = r0[xloc] if (not r1) then r1 = {} r0[xloc] = r1 end
	local oldpos = r1[ yloc]
	if (oldpos and oldpos[5] <= t) then return end -- old t is better
	local pos = {xloc,yloc,zloc,dir,t,heuristic,prepos}
	r1[ yloc] = pos
	local mylist = self.reached_byheuristic[heuristic]
	if (not mylist) then mylist = {} self.reached_byheuristic[heuristic] = mylist end
	mylist[pos] = true 
end

function Pathfinding_TriggeredByMouse	()
	MainMousePick()
	local x,y,z = GetMouseHitTileCoords()
	if (not z) then return end
	z = math.floor(z * 0.1)
	Pathfinding_TriggeredByDestination(x,y,z)
end

function GetPlayerTilePosition	()
	local mobile = GetPlayerMobile()
	local sx,sy,sz
	if mobile then
		sx,sy,sz = mobile.xloc,mobile.yloc,mobile.zloc
	else
		sx,sy,sz = gCurrentRenderer:GetExactLocalPos()
		sz = sz * 10
	end
	return math.floor(sx),math.floor(sy),math.floor(sz)
end

function Pathfinding_TriggeredByDestination	(dx,dy,dz)
	local sx,sy,sz = GetPlayerTilePosition()
	
	sz = math.floor(sz * 0.1)
	
	dx = math.floor(dx)
	dy = math.floor(dy)
	dz = math.floor(dz)
	
	-- print("PATHFIND","SRC",sx,sy,sz,"DST",dx,dy,dz)
	
	Pathfinding_FromTo(sx,sy,sz, dx,dy,dz)
end

function Pathfinding_Key	(x,y,z)
	return x.."_"..y.."_"..z
end

function Pathfinding_Pos	(key)
	local x,y,z = unpack(strsplit("_",key))
	return tonumber(x),tonumber(y),tonumber(z)
end

function Pathfinding_GetHeuristic	(srcx,srcy,srcz,dstx,dsty,dstz)
	local dx,dy,dz = srcx-dstx,srcy-dsty,srcz-dstz
	return math.sqrt(dx*dx+dy*dy)
end
	
function Pathfinding_GetNeighbours	(x,y,z,dstx,dsty,dstz,g)
	local list = {}
	local parent = Pathfinding_Key(x,y,z)
	
	for dir=0,7 do
		local dx = GetDirX(dir)
		local dy = GetDirY(dir)
		
		-- HACK ignore diagonal movements
		--if math.abs(dx)+math.abs(dy) == 1 then
		
		 	local iNewZ	= GetNearestGroundLevel(x,y,z * 10,dir)
		 	if iNewZ then
			 	iNewZ = math.floor(iNewZ / 10) 
				-- add neighbour
				local dz = (z-iNewZ)
				local d = math.sqrt(dx*dx + dy*dy) 
				list[Pathfinding_Key(x+dx,y+dy,iNewZ)] = {
					p=parent,g=(d+g),h=Pathfinding_GetHeuristic(x+dx,y+dy,iNewZ,dstx,dsty,dstz)
				}
			end
		
		--end
	end
	
	return list
end

function Pathfinding_GetDirection	(idfrom,idto)
	-- print("Pathfinding_GetDirection",idfrom,idto)
	local sx,sy,sz = Pathfinding_Pos(idfrom)
	local dx,dy,dz = Pathfinding_Pos(idto)
	
	return DirFromUODxDy(dx - sx,dy - sy)
end

function Pathfinding_ReconstructPath	(dstx,dsty,dstz,list)
	local path = {}
	local id = Pathfinding_Key(dstx,dsty,dstz)
	local current
	local dir

	repeat
		current = list[id]
		-- print("CURRENT",vardump(current))
		-- print("ID",id,current["p"])
		if current["p"] then
			local d = Pathfinding_GetDirection(id,current["p"])
			local x,y,z = Pathfinding_Pos(id)
			local o = {x=x,y=y,z=z,dir=d}
			id = current["p"]
			
			if dir == nil or math.abs(dir-d) > 1 then
				dir = d
				table.insert(path, o)
			end
		end
	until not current["p"]
	
	-- print("PATH",vardump(path))
	
	return path
end
	
function Pathfinding_FindBest	(list)
	local minfound = false
	local minf
	local minid
	for id,a in pairs(list) do
		local f = a["g"] + a["h"]
		if not minfound or f < minf then	
			minf = f
			minid = id
			minfound = true
		end
	end
		
	return minid
end
	
function Pathfinding_FromTo	(sx,sy,sz, dx,dy,dz)
	GuiAddChatLine("pathfinding...")
	sz = sz
	dz = dz
	job.create(function()
		local maxsteps = 512
		local lOpen = {}
		local lClose = {}
		
		-- init open list with fields around startingpoint
		lOpen = Pathfinding_GetNeighbours(sx,sy,sz,dx,dy,dz,0)
		lClose[Pathfinding_Key(sx,sy,sz)] = {p=nil,h=Pathfinding_GetHeuristic(sx,sy,sz,dx,dy,dz),g=0}
		
		local step = 0
		
		-- print("1OPEN",vardump(lOpen))
		-- print("1CLOSE",vardump(lClose))

		local finish = false

		local count = 10

		while not finish and countarr(lOpen) > 0 do
			-- print("OPEN",countarr(lOpen))
			-- print("CLOSE",countarr(lClose))
			--get best open point
			local bestid = Pathfinding_FindBest(lOpen)
			local best = lOpen[bestid]
			
			local x,y,z = Pathfinding_Pos(bestid)
			local len = Vector.len(Vector.sub(x,y,z,dx,dy,dz))
			
			-- print("BEST",bestid,len,best.g,best.h,best.g+best.h)
			
			if count > 0 then count = count - 1 end
			if count == 0 then
				job.yield()
				if OgreAvgFPS() > 15 then count = 15 else count = 1 end
			end

			--add new valid points around it to the open list and calc the costs of the new ones and add parent link
			local n = Pathfinding_GetNeighbours(x,y,z,dx,dy,dz,best["g"])
			
			for id,a in pairs(n) do
				if not lOpen[id] and not lClose[id] then
					lOpen[id] = a
				end
			end
				
			--remove the point from the openlist an add it to the close list
			lOpen[bestid] = nil
			lClose[bestid] = best

			if len == 0 then
				finish = true
			else
				step = step + 1
				
				if step > maxsteps then return {} end
			end
		end
		
		--move back the list and create a new list with the path
		local path = Pathfinding_ReconstructPath(dx,dy,dz,lClose)
		--reverse path
		local path2 = {}
		for k,v in pairs(path) do
			table.insert(path2,1,v)
		end
		
		return path2
		
	end,function(a,b) 
		-- print("FINISHED",a,b)
		if a and b and countarr(b) > 0 then 
			GuiAddChatLine("path found :)")
			gWalkPathToGo = b
		else
			GuiAddChatLine("no path found :(")
		end
	end)
end

