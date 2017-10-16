--[[ ***** see Iris2 COPYING for license info ***** ]]--
--[[ \brief
        exports Housesland
]]--

local img = CreateImage()
local facet		= math.floor(tonumber(gCommandLineArguments[2] or 1))  -- 1 = tram
gMaps = {}	ArrayOverwrite(gMaps,gDefaultMaps)
MapChangeRequest(facet)
local dbx = gGroundBlockLoader:GetMapW()
local dby = gGroundBlockLoader:GetMapH()
GenerateRadarImage(img,0,0,dbx,dby,gGroundBlockLoader,gStaticBlockLoader,gRadarColorLoader)

gHouseLandGroundType = {}

function ExportHouse_CheckNear (xloc,yloc) 
	local tiletype,zloc = GetGroundAtAbsPos(xloc,yloc)
	if (tiletype == 4) then return end
	--~ if (tiletype == 580) then return end
	--~ local name = GetStaticTileTypeName(4)
	--~ print("ExportHouse_CheckNear",tiletype)
	--~ local z = GetGroundZAtAbsPos(xloc,yloc)
	local minxloc,minyloc = xloc,yloc
	local w = 1
	local h = 1
	local d3 = 1
	local d4 = 1
	for a = 1,8 do if (zloc == GetGroundZAtAbsPos(xloc+a,yloc)) then w = w + 1 else break end end
	for a = 1,8 do if (zloc == GetGroundZAtAbsPos(xloc-a,yloc)) then w = w + 1 minxloc = xloc-a else break end end
	if (w < 7) then return end
	for a = 1,8 do if (zloc == GetGroundZAtAbsPos(xloc,yloc+a)) then h = h + 1 else break end end
	for a = 1,8 do if (zloc == GetGroundZAtAbsPos(xloc,yloc-a)) then h = h + 1 minyloc = yloc-a  else break end end
	if (h < 7) then return end
	for a = 1,8 do if (d3 < 8 and zloc == GetGroundZAtAbsPos(xloc+a,yloc+a)) then d3 = d3 + 1 else break end end
	for a = 1,8 do if (d3 < 8 and zloc == GetGroundZAtAbsPos(xloc-a,yloc-a)) then d3 = d3 + 1 else break end end
	if (d3 < 7) then return end
	for a = 1,8 do if (d4 < 8 and zloc == GetGroundZAtAbsPos(xloc+a,yloc-a)) then d4 = d4 + 1 else break end end
	for a = 1,8 do if (d4 < 8 and zloc == GetGroundZAtAbsPos(xloc-a,yloc+a)) then d4 = d4 + 1 else break end end
	if (d4 < 7) then return end
	
	local iDir = 3
	local d1 = 0
	local d2 = 0
	for a = 0,7 do if (GetNearestGroundLevel(xloc+a,yloc+a,zloc,3) and d1 < 7) then d1 = d1 + 1 else break end end
	for a = 0,7 do if (GetNearestGroundLevel(xloc-a,yloc-a,zloc,7) and d1 < 7) then d1 = d1 + 1 else break end end
	if (d1 < 6) then return end
	
	print("ExportHouse_MarkPos",xloc,yloc,w,h,tiletype,name)
	gHouseLandGroundType[tiletype] = (gHouseLandGroundType[tiletype] or 0) + 1
	return minxloc,minyloc,w,h
end


function ExportHouse_MarkPos (minx,miny,w,h,img,markimg) 
	local r,g,b,a = 0,1,0,1
	PrepareImage(w,h,r,g,b,a)
	markimg = CreatePreparedImage() 
	ImageBlit(markimg,img,minx,miny)
	markimg:Destroy()
end

for xloc = 0, dbx*8,4 do
for yloc = 0,dby*8,4 do
	local minx,miny,w,h = ExportHouse_CheckNear(xloc,yloc)
	if (minx) then
		ExportHouse_MarkPos(minx,miny,w,h,img,markimg)
	end
end
end

gHouseLandGroundTypeOrdered = {}
for tiletype,num in pairs(gHouseLandGroundType) do table.insert(gHouseLandGroundTypeOrdered,{tiletype=tiletype,num=num}) end
table.sort(gHouseLandGroundTypeOrdered,function (a,b) return a.num < b.num end)
for k,v in pairs(gHouseLandGroundTypeOrdered) do print("LandGroundTypeOrdered",v.num,v.tiletype) end

img:SaveAsFile("../mapexport.png")
img:Destroy()
os.exit(0)
