-- contains all sorts of tests for checking the runtime environment and debugging

-- april 2007
function TestGuiSystem2_Step ()
	local widget = gui.GetWidgetUnderMouse()
	Client_SetBottomLine("TestGuiSystem2 WidgetUnderMouse : "..(widget and (widget.mytext or "unknown") or "NONE"))
end

function GrassTestStep()
	------------------------------------------ obsolete, just for testing -----------------------------------
	--[[	
	if gGrass and gStaticLoader then 
		gGrass:Update() 
	elseif GetMainCam() and gStaticBlockLoader then
		gGrass = CreatePagedGeometry(GetMainCam(), 50)
		gGrass:AddDetailLevel("batch",100,50)
		--gGrass:AddDetailLevel("impostor",500,50)

		local x,y,z = gCurrentRenderer:LocalToUOPos(GetMainCam():GetPos())
		gStaticLoader = CreatePagedGeometryStaticLoader(gGrass, gStaticBlockLoader, -1,1,10, x,y,z)
		gStaticLoader:AssignToPagedGeometry(gGrass)
		
		gGrassLoader = CreateGrassLoader(gGrass)
		gGrassLoader:AssignToPagedGeometry(gGrass)

		gGrassLoader:SetHeightFunction(function(x,z)
			return x+z
		end)

		local l = gGrassLoader:AddLayer("grass")

		l:SetMinimumSize(2.0, 2.0)
		l:SetMaximumSize(2.5, 2.5)
		l:SetAnimationEnabled(true)
		l:SetSwayDistribution(10.0)
		l:SetSwayLength(0.5)
		l:SetSwaySpeed(0.5)
		l:SetDensity(1.5)
		l:SetFadeTechnique(false,true)
		
		l:SetColorMapFileColor("terrain_texture.jpg")
		l:SetDensityMapFileAlpha("grass_density.png")
		l:SetMapBounds(-1500, -1500, 1500, 1500)
	end
	]]--
	----------------------------------------------------------------------------------------------------------
end

function FileWriteSpeedTest ()
	local function luadump	(name,data)
		local t = type(data)
		if t == "table" then
			local s = "["..name.."]".."={"
			for k,v in pairs(data) do
				s = s..luadump(k,v)..","
			end
			return s.."}"
		else
			return "["..name.."]".."="..tostring(data)..""
		end
	end
 
	local entry = {id=1,x=100,y=-200,z=4}

	local t = {}
	for i=0,100 do
		table.insert(t,entry)
	end
	
	local startt = Client_GetTicks()
	for i=0,1000 do
		local fp = io.open("test.txt","w")
		if (fp) then
			fp:write(luadump("data",t))
			fp:close()
		end
	end
	local endt = Client_GetTicks()
	print("dt text save=",(endt-startt)/1000)
	
	
	local f = CreateFIFO()
	local startt = Client_GetTicks()
	for i=0,1000 do
		f:Clear()
		
		for k,v in pairs(t) do
			f:PushU(v.id)
			f:PushU(v.x)
			f:PushU(v.y)
			f:PushU(v.z)
		end
		f:WriteToFile("test.bin")
		
	end
	f:Destroy()
	local endt = Client_GetTicks()
	print("dt bin save=",(endt-startt)/1000)
	
	
	local f = CreateFIFO()
	local startt = Client_GetTicks()
	for i=0,1000 do
		f:Clear()
		
		local quickfifo = f:GetQuickHandle()
		local myfun = FIFO_PushNetUint32
		for k,v in pairs(t) do
			myfun(quickfifo,v.id)
			myfun(quickfifo,v.x)
			myfun(quickfifo,v.y)
			myfun(quickfifo,v.z)
		end
		f:WriteToFile("test.bin")
	end
	f:Destroy()
	local endt = Client_GetTicks()
	print("dt bin2 save=",(endt-startt)/1000)

	--~ dt text save=   1.355
	--~ dt bin save=    0.552
	--~ dt bin2 save=    0.086

	os.exit(0) 
end


function TestZLib()
	local c = CreateFIFO()
	local u = CreateFIFO()
	local d = CreateFIFO()
	local s = "das ist ein toller teststring der so total toll ist und voll lange um die komprimierung zu testen"
	u:PushFilledString(s,string.len(s))
	print("u",u:Size())
	c:PushCompressFromFifo(u)
	print("c",c:Size())
	c:PeekDecompressIntoFifo(c:Size(),string.len(s),d)
	print("d",d:Size())
	local sd = d:PopFilledString(d:Size())
	
	print("s",s)
	print("sd",sd)
	
	Crash()
end

function Test_ImageBlit ()
	local a = LoadImageFromFile("irislogo256x256bw.png")
	local b = LoadImageFromFile("art_fallback.png")
	ImageBlit(b,a,224,224)
	a:SaveAsFile("myimagetest2.png")
	os.exit(0)
end

function Test_GenerateRadarImage ()
	local a = CreateImage()
	local bx0,by0 = 160,160
	local bx1,by1 = bx0+16*5,by0+16*5
	GenerateRadarImage(a,bx0,by0,bx1,by1,gGroundBlockLoader,gStaticBlockLoader,gRadarColorLoader)
	a:SaveAsFile("myimagetest3.png")
	os.exit(0)
end

function TestSound()
	gSoundLoader = CreateSoundLoader(gSoundLoaderType,CorrectPath( Addfilepath(gSoundidxFile) ),CorrectPath( Addfilepath(gSoundFile) ))
	SoundInit("fmod",22050)

	gSoundSystem:SetDistanceFactor(0.1)

	--SoundSetListenerPosition(100,500,0)
	SoundSetListenerPosition(100,100,0)
	
	--SoundPlayEffect_UO(100,100,0,150)
	SoundPlayEffect_UO(50,100,0,20)
	
	while IsSoundEffectPlaying() do 
		SoundStep()
	end
	
	SoundDone()
	Crash()
end

-- count how often every type of static occurs on the map
function AnalyseStatics (index)
	gMapLoaded = true
	gMapIndex = index
	gCurrentRenderer:ClearMapCache()
	print("gMapIndex",gMapIndex)

	local name				= gMaps[index].name
	local mapheight			= gMaps[index].mapheight
	local staidxfilename	= gMaps[index].staidxfilename
	local staticfilename	= gMaps[index].staticfilename
	
	if (gTileTypeLoaderType) then
		LoadingProfile("init TileTypeLoader")
		gTileTypeLoader = CreateTileTypeLoader(gTileTypeLoaderType,CorrectPath( Addfilepath(gTiledataFile) ))
	end
	if (gStaticBlockLoaderType) then
		LoadingProfile("init StaticBlockLoader")
		gStaticBlockLoader = CreateStaticBlockLoader(gStaticBlockLoaderType,mapheight,CorrectPath( Addfilepath(staidxfilename) ),CorrectPath( Addfilepath(staticfilename) ))
	end

	local w,h = gStaticBlockLoader:GetMapW(),gStaticBlockLoader:GetMapH()
	print("static map size",w,h)
	local staticCounter = {}
	
	local total_static_count = 0
	local x,y,i
	local iTileTypeID,iX,iY,iZ,iHue
	local entity,meshname

	for y = 0,w-1 do
		if (math.mod(y,16) == 0) then print("#",y.."/"..h) end
		for x = 0,h-1 do
			gStaticBlockLoader:Load(x,y)
			local iStaticCount = gStaticBlockLoader:Count() -- operates on the block that was last loaded using :Load()
			for i = 0,iStaticCount-1 do
				iTileTypeID,iX,iY,iZ,iHue = gStaticBlockLoader:GetStatic(i) -- operates on the block that was last loaded using :Load()
				total_static_count = total_static_count + 1
				staticCounter[iTileTypeID] = (staticCounter[iTileTypeID] or 0) + 1
			end
		end
	end
	print("#",w.."/"..h)

	local staticAnalysis = {}
	for k,v in pairs(staticCounter) do 
		table.insert(staticAnalysis,{ typeid=k, amount=v, typeobj=GetStaticTileType(k) })
	end
	table.sort(staticAnalysis,function (a,b) return a.amount > b.amount end)

	local polycount = 0
	for k,obj in pairs(staticAnalysis) do
		print("obj.typeid: "..obj.typeid)
		local meshname = GetMeshName(obj.typeid)
		if (meshname and meshname ~= false) then polycount = CountMeshTriangles(meshname) end
		if (polycount < 1) then 
			print(obj.amount,sprintf("0x%04x",obj.typeid),obj.typeid,obj.typeobj.msName,polycount)
		end
	end

	print("total statics ",total_static_count)
	Crash()
end

function LuaHuffmanTest ()
	local fifo_in = CreateFIFO()
	local fifo_cmp = CreateFIFO()
	local fifo_out = CreateFIFO()
	local cycles = 200
	for k = 0,cycles-1 do
		local len = 1000
		for i = 0,len-1 do fifo_in:PushNetUint8(math.floor(math.random()*255.0)) end
		HuffmanCompress(fifo_in,fifo_cmp)
		HuffmanDecompress(fifo_cmp,fifo_out)
		for i = 0,len-1 do 
			local a = fifo_in:PeekNetUint8(i)
			local b = fifo_out:PeekNetUint8(i)
			if (a ~= b) then printf("LuaHuffmanTest failed 0x%02x != 0x%02x\n",a,b) Crash() end
		end
		fifo_in:Clear()
		fifo_cmp:Clear()
		fifo_out:Clear()
	end
end

-- test if lua can perform bitwise operations correctly
function LuaBitwiseTest ()
	if ( TestBit(hex2num("0x4000250e"),hex2num("0x80000000"))) then print("we got bug") Crash() end
	local test = hex2num("0x4000250e")
	if ( TestBit(test,hex2num("0x80000000"))) then print("we got bug") Crash() end
	print(Hex2Num("0x70000020"),"=",hex2num("0x70000020"))
	print(Hex2Num("0x941c48bf"),"=",hex2num("0x941c48bf"))
	LuaBitwiseTest_Pair("0x941c48bf","0x0000000f")
	LuaBitwiseTest_Pair("0x80002600","0x00000200")
	LuaBitwiseTest_Pair("0x70000020","0x00000020")
	LuaBitwiseTest_Pair("0x80000001","0x00000001")
	LuaBitwiseTest_Pair("0xffffffff","0x00000001")
	LuaBitwiseTest_Hex2Num("0x7fffffff")
	LuaBitwiseTest_Hex2Num("0xffffffff")
	LuaBitwiseTest_Hex2Num("0x80000000")
	LuaBitwiseTest_Hex2Num("0x80000001")
	LuaBitwiseTest_Hex2Num("0x12345678")
	LuaBitwiseTest_Hex2Num("0x941c48bf")
	LuaBitwiseTest_FIFO("0x7fffffff")
	LuaBitwiseTest_FIFO("0xffffffff")
	LuaBitwiseTest_FIFO("0x80000001")
	LuaBitwiseTest_FIFO("0x80000000")
	LuaBitwiseTest_FIFO("0x12345678")
	LuaBitwiseTest_FIFO("0x941c48bf")
	for i = 1,23 do
		local a = GetRandomHexString()
		LuaBitwiseTest_Pair2(a,"0x00000001")
		LuaBitwiseTest_Hex2Num(a)
	end
	print("LuaBitwiseTest successfull")
end

function LuaBitwiseTest_FIFO (a)
	local fifo = CreateFIFO()
	fifo:PushNetUint32(hex2num(a))
	if (gEnableBitwiseHexDumpTest) then 
		--~ print("LuaBitwiseTest_FIFO : the following dump should contain "..a)
		--~ fifo:HexDump() -- no longer available, see FIFOHexDump
		local hexdump = FIFOHexDump(fifo) -- todo . format convert from "ff aa 12 00 01 " to 0x123
	end
	local b = fifo:PopNetUint32()
	if (sprintf("0x%08x",b) ~= a) then
		printf("LuaBitwiseTest_FIFO failed : %s != %s\n",a,b)
		Crash()
	end
end

function LuaBitwiseTest_Hex2Num (a)
	local c = sprintf("0x%08x",hex2num(a))
	if (c ~= a) then
		printf("LuaBitwiseTest failed : hex2num(%s) != %s\n",a,c)
		Crash()
	end
end

-- assert(a & b = b), pass arguments as strings
function LuaBitwiseTest_Pair (a,b)
	local c = BitwiseAND(hex2num(a),hex2num(b))
	printf("LuaBitwiseTest: %s & %s = 0x%08x\n",a,b,c)
	if (sprintf("0x%08x",c) ~= b) then
		printf("LuaBitwiseTest failed : %s & %s = 0x%08x\n",a,b,c)
		Crash()
	end
end

-- assert(a & b = b), pass arguments as strings
function LuaBitwiseTest_Pair2 (a,b)
	local c = BitwiseAND(BitwiseOR(hex2num(a),hex2num(b)),hex2num(b))
	if (sprintf("0x%08x",c) ~= b) then
		printf("LuaBitwiseTest failed : %s & %s = 0x%08x\n",a,b,c)
		Crash()
	end
end


function ExpressionTest ()
	-- expression test
	function TestExpr (code) 
		local myfun,myerr = loadstring("gTest = "..code)
		myfun()
		if (gTest) then 
				print("'"..code.."' evaluates to TRUE")
		else	print("'"..code.."' evaluates to FALSE") end
	end
	
	--[[
	TestExpr("nil")
	TestExpr("false")
	TestExpr("\"\"")
	TestExpr("\"aaa\"")
	TestExpr("0")
	TestExpr("nil == true")
	TestExpr("false == true")
	TestExpr("\"\" == true")
	TestExpr("\"aaa\" == true")
	TestExpr("0 == true")

	TestExpr("\"\" ~= nil")
	TestExpr("\"\" == nil")
	TestExpr("0 ~= nil")
	TestExpr("0 == nil")
	TestExpr("true ~= nil")
	TestExpr("true == nil")
	TestExpr("false ~= nil")
	TestExpr("false == nil")
	TestExpr("nil ~= nil")
	TestExpr("nil == nil")
	
	'nil' 			evaluates to FALSE
	'false' 		evaluates to FALSE
	'""' 			evaluates to TRUE
	'"aaa"' 		evaluates to TRUE
	'0' 			evaluates to TRUE
	'nil == true' 	evaluates to FALSE
	'false == true' evaluates to FALSE
	'"" == true' 	evaluates to FALSE
	'"aaa" == true' evaluates to FALSE
	'0 == true' 	evaluates to FALSE
	'"" ~= nil' 	evaluates to TRUE
	'"" == nil' 	evaluates to FALSE
	'0 ~= nil' 		evaluates to TRUE
	'0 == nil' 		evaluates to FALSE
	'true ~= nil' 	evaluates to TRUE
	'true == nil' 	evaluates to FALSE
	'false ~= nil' 	evaluates to TRUE
	'false == nil' 	evaluates to FALSE
	'nil ~= nil' 	evaluates to FALSE
	'nil == nil' 	evaluates to TRUE
	]]--
end

--[[
-- debug to dump staticid, name
if (false) then
	local i = 0
	while true do
		local name = GetStaticTileTypeName(i)
		if (not name) then Crash() end
		print (i,name)
		i = i + 1
	end
end
]]--

function TestDefFileParser ()
	local t = ParseDefFile(CorrectPath( Addfilepath(gEquipconvFile) ))
	local a,b,c,d,e = GetListFromDefTable(t,605,997)
	print(a,b,c,d,e)
	Crash()
end

function TestMultiLoader()
	l = CreateMultiLoader("FullFile",CorrectPath( Addfilepath(gMultiidxFile) ),CorrectPath( Addfilepath(gMultiFile) ))
	print(l)
	for id = 0, 10 do
		local parts = l:CountMultiParts(id)
		print("multi id",id,"parts",parts)
		for p = 0, parts-1 do
			local blocknum,x,y,z,flags
			blocknum,x,y,z,flags = l:GetMultiParts(id,p)
			print("  part",p,":",blocknum,x,y,z,flags)
		end
	end
	Crash()
end

--[[
--deprecated, old guisystem, doesn't support unicode well, see lib.unifont.lua for an alternative
function TestUniFontLoader()
	print(CreateUniFontLoader)
	l = CreateUniFontLoader(CorrectPath( Addfilepath(gUnifonts.."2.mul") ))

	l:CreateOgreFont("font_unifont2")

	l:Destroy()
	Crash()
end
]]--

function StartMeshLoaderTest ()
	if (gDialog_IrisLogo) then gDialog_IrisLogo:SetVisible(false) end
	local mymeshbuffer = LoadMeshBufferFromFile("../data/models/models/to_002000/mdl_001909.mesh") -- load directly
	--~ local mymeshbuffer = GetMeshBuffer("../data/models/models/to_002000/mdl_001909.mesh") -- load to vram and read back to ram
	local fastbatch = CreateRootGfx3D()
	fastbatch:SetFastBatch()
	local x,y,z = 0,2,40-0.5 -- +x=right,+y=depth,+z :top (camz=40)
	local qw,qx,qy,qz = 1,0,0,0
	local sx,sy,sz = 1,1,1
	local r,g,b,a = 1,1,1,1
	local orderval = 0 -- not used here
	fastbatch:FastBatch_AddMeshBuffer(mymeshbuffer, orderval, x,y,z, qw,qx,qy,qz, sx,sy,sz, r,g,b,a)
	fastbatch:FastBatch_Build()
end
