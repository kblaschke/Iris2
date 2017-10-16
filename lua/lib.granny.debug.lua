--~ ./start.sh -sdg -res 640x480
--~ ./start.sh -grannytest

cDebugGrannyMenu = CreateClass(cDebugMode)

local testdata = {
    --female
    --~ {artid=401, content={}},
    --~ {artid=401, content=({{artid=5899,animid=477},{artid=5422,animid=430},{artid=5399,animid=434},{artid=5435,animid=466},{artid=8251,animid=700},{artid=3701,animid=422},})},
    -- male
    --~ {artid=400, content={}},
    --~ {artid=400, content=({{artid=5905,animid=476},{artid=5422,animid=430},{artid=7933,animid=435},{artid=5909,animid=406},{artid=5441,animid=490},{artid=3701,animid=422},{artid=8251,animid=700},})},

	--~ PrintBrokenGrannyInfo   257                               DreadHorn     gBrokenGrannyModelIdList
	--~ PrintBrokenGrannyInfo   774                               Dawn_Girl     gBrokenGrannyModelIdList
	--~ PrintBrokenGrannyInfo   276                                Raptalon     gGrannyFilter   60      nil
	--~ PrintBrokenGrannyInfo   311                           shadow_knight     gGrannyFilter   310     nil
	--~ PrintBrokenGrannyInfo   257                               DreadHorn     gGrannyFilter   200     nil
	--~ PrintBrokenGrannyInfo   1987                    H_Female_Robe_GM_V2     gGrannyFilter   401     nil
	--~ PrintBrokenGrannyInfo   970                            player_ghost     gGrannyFilter   402     nil
	--~ PrintBrokenGrannyInfo   778                                   swarm     gGrannyFilter   16      nil
	--~ PrintBrokenGrannyInfo   780                               bog_thing     gGrannyFilter   779     nil
	--~ PrintBrokenGrannyInfo   292                       llamas_llama_pack     gGrannyFilter   220     nil
	--~ PrintBrokenGrannyInfo   114                equines_horse_dark_steed     gMountGrannyOverride    200
	--~ PrintBrokenGrannyInfo   116                 equines_horse_nightmare     gMountGrannyOverride    200
	--~ PrintBrokenGrannyInfo   178                 equines_horse_nightmare     gMountGrannyOverride    200
	--~ PrintBrokenGrannyInfo   190                 equines_horse_firesteed     gMountGrannyOverride    200
	--~ PrintBrokenGrannyInfo   791                            giant_beetle     gMountGrannyOverride    200
	--~ PrintBrokenGrannyInfo   257                               DreadHorn     gMountGrannyOverride    200
	--~ PrintBrokenGrannyInfo   794                            swamp_dragon     gMountGrannyOverride    200
	--~ PrintBrokenGrannyInfo   226              equines_horse_dappled_grey     gMountGrannyOverride    200
	--~ PrintBrokenGrannyInfo   117              equines_horse_silver_steed     gMountGrannyOverride    200
	--~ PrintBrokenGrannyInfo   284                          MondainSteed01     gMountGrannyOverride    200
	--~ PrintBrokenGrannyInfo   291        equines_horse_dappled_brown_pack     gMountGrannyOverride    118
	--~ PrintBrokenGrannyInfo   799                      swamp_dragon_armor     gMountGrannyOverride    200
	--~ PrintBrokenGrannyInfo   204                equines_horse_dark_brown     gMountGrannyOverride    200
	--~ PrintBrokenGrannyInfo   177                 equines_horse_nightmare     gMountGrannyOverride    200
	--~ PrintBrokenGrannyInfo   228                       equines_horse_tan     gMountGrannyOverride    200
	--~ PrintBrokenGrannyInfo   276                                Raptalon     gMountGrannyOverride    105
	--~ PrintBrokenGrannyInfo   179                 equines_horse_nightmare     gMountGrannyOverride    200
	--~ PrintBrokenGrannyInfo   115                  equines_horse_ethereal     gMountGrannyOverride    200
	--~ broken anim : 0x13a (boneties compare different, #texpoly <> #poly
}

function StartDebugGrannyMenu () cDebugGrannyMenu:StartMenu() end


function cDebugGrannyMenu:StartMenu ()
	gCurrentRenderer = Renderer3D   
	Load_Granny() -- needs Renderer3D
	Load_Stitchin()
	Load_TileType()
	
	--~ self:PrintBrokenGrannyInfos()
	--~ self:ClearGrannyOverrides()
	
	self:MakeGrid({0,0,0},{1,0,0},{0,1,0},5,5,true)
	
	--~ local modelid = 276 -- Raptalon
	--~ local modelid = 257 -- DreadHorn
	--~ local modelid = 791 -- giant_beetle
	local modelid = 200 -- standard horse
	print("============ loading platemail debug : broken texture or texcoords in offline mode")
	--~ local modelid = GetStaticTileType(5141).miAnimID -- platemail, broken in offline mode   lib.offlinemode.lua : equipmentdata[plate_chest.layer] = plate_chest
	--~ print("GetStaticTileType",SmartDump(GetStaticTileType(5141)))
	--~ assert(modelid)
	--~ local modelid = 0x101
	local animid = 1
	gGrannyAnimEnabled = true
	--~ self:MakeOldGranny(modelid,animid)
	self:MakeNewGranny(modelid,animid)
	
	DumpGrannyLuaProfileInfo()
	
	self:StartMainLoop()
end

function DumpGrannyLuaProfileInfo ()
	local arr = {}
	for k,v in pairs(gGrannyLuaLoaderProfileCountStructRead) do table.insert(arr,{name=k,count=v}) end
	print("gGrannyLuaLoaderProfileCountStructRead",#arr)
	table.sort(arr,function (a,b) return a.count < b.count end)
	for k,o in ipairs(arr) do print("grannyprofile",o.count,o.name) end
end
--~ InvokeLater(10000,function () DumpGrannyLuaProfileInfo() MyProfilerTop() os.exit(0) end)


	
function cDebugGrannyMenu:MakeOldGranny (artid,animid) 
	local mobile = {artid=artid}
	local gfx = CreateRootGfx3D()
	local body = CreateBodyGfx(gfx)
	body:MarkForUpdate(mobile.artid,mobile.hue,mobile.content)
	body:Update()
	
	local bMoving,bTurning,bWarMode,bRunFlag = false,false,false,false
	--~ bMoving = true
	--~ if (gDebugMenuAnimIndex == -1) then bMoving                     = true,true,true end
	--~ if (gDebugMenuAnimIndex == -2) then bMoving,bRunFlag            = true,true,true end
	--~ if (gDebugMenuAnimIndex == -3) then bWarMode,bMoving            = true,true,true end
	--~ if (gDebugMenuAnimIndex == -4) then bWarMode,bMoving,bRunFlag   = true,true,true end
	--~ body:SetState(bMoving,bTurning,bWarMode,bRunFlag)
	gfx:SetPosition(1,0,0)
	if (animid) then body:StartAnimLoop(animid) end
	
    local skeleton = GetOrCreateSkeleton(artid) -- skeleton is determined by the bodyid, not possible from the wearables
	assert(skeleton,"skeleton=nil -> cannot test wearables/armor here???")
	
	print("MakeOldGranny body.modelparts",SmartDump(body.modelparts))
	gsOldGrannyMeshName = body.modelparts[1] and body.modelparts[1]:GetEntity():getMesh():getName()
	
	--~ if (gDebugMenuAnimIndex >= 0) then body:StartAnimLoop(gDebugMenuAnimIndex) end
	--~ body:StartAnimLoop(1)
	
	-- notes :  
	-- CreateBodyGfxPartsFromModelIDArray
    --~ local skeleton = GetOrCreateSkeleton(bodyid) -- skeleton is determined by the bodyid, not possible from the wearables
    --~ local skeleton_name = skeleton and skeleton.name or "unknown_skeleton"
	--~ local meshname = GetGrannyMeshName(modelid,skeleton_name,element.hue or 0)
	--~ local mygranny = GetGrannyModelLoader(modelid)
    --~ local matname = GetGrannyMat(modelid,hue,mygranny)
    --~ local modelinfo = GetGrannyModelInfo(modelid)
    --~ local modelpath = CorrectGrannyPath(gGrannyTypeDirs[modelinfo.typeid] .. modelinfo.modelname .. "_LOD2.grn")
end

function cDebugGrannyMenu:PrintBrokenGrannyInfo_One (modelid,...) 
	local modelinfo = GetGrannyModelInfo(modelid,true)
	print("PrintBrokenGrannyInfo",modelid,modelinfo and sprintf("%35s",modelinfo.modelname),...)
end

function cDebugGrannyMenu:ClearGrannyOverrides ()
	gBrokenGrannyModelIdList = {}
	gGrannyFilter = {}
	gMountGrannyOverride = {}
end
function cDebugGrannyMenu:PrintBrokenGrannyInfos () 
	-- GetGrannyModelInfo : gBrokenGrannyModelIdList -> nil
	for modelid,v in pairs(gBrokenGrannyModelIdList) do self:PrintBrokenGrannyInfo_One(modelid,"gBrokenGrannyModelIdList") end
	
	-- GetGrannyMeshName : modelid = GrannyOverride(modelid)
	for modelid,filter in pairs(gGrannyFilter) do self:PrintBrokenGrannyInfo_One(modelid,"gGrannyFilter",filter.grannyid,filter.meshname) end
	
	--~ GrannyOverride(bodyid) 		: if (gGrannyFilter[bodyid]) then return gGrannyFilter[bodyid].grannyid
	--~ GrannyMeshOverride(bodyid)	: if (gGrannyFilter[bodyid]) then return gGrannyFilter[bodyid].meshname
	
	--~ gMountTranslate[0x3EAA] = 0x73 --//=115, 0x20DD,  Ethereal Horse          2D ??  equip-artid for mount-layer ?
	
	--~ gMountGrannyOverride[0x114] = 0x69 -- chimera : wing broken in 3d
	for modelid,newid in pairs(gMountGrannyOverride) do self:PrintBrokenGrannyInfo_One(modelid,"gMountGrannyOverride",newid) end
	
	-- todo : stitchin ? gStitchinLoader[oldelement.modelid] ..
end


gGrannyDebug_Anims_Horse = {			"Equines_Horse_Dappled_Brown_Attack1.grn",     
										"Equines_Horse_Dappled_Brown_Fidget.grn",      
										"Equines_Horse_Dappled_Brown_Lod2.grn",        
										"Equines_Horse_Dappled_Brown_Walk.grn",
										"Equines_Horse_Dappled_Brown_Die1.grn",        
										"Equines_Horse_Dappled_Brown_Gethit.grn",      
										"Equines_Horse_Dappled_Brown_Pack_Lod2.grn",
										"Equines_Horse_Dappled_Brown_Eat.grn",         
										"Equines_Horse_Dappled_Brown_Idle.grn",        
										"Equines_Horse_Dappled_Brown_Run.grn",
									}
gGrannyDebug_Anims_Beetle = {			"Giant_Beetle_Fire_LOD2.grn",                      
										"Giant_Beetle_Attack1.grn",                        
										"Giant_Beetle_Idle.grn",                           
										"Giant_Beetle_Fidget.grn",                         
										"Giant_Beetle_Fidget2.grn",                        
										"Giant_Beetle_Attack3.grn",                        
										"Giant_Beetle_ethereal_LOD2.grn",                  
										"Giant_Beetle_Lod2.grn",                           
										"Giant_Beetle_Walk.grn",                           
										"Giant_Beetle_Die1.grn",
										"Giant_Beetle_Attack2.grn",
										"Giant_Beetle_GetHit.grn",
										"Giant_Beetle_Run.grn",
									}


function MyIterGranny (node,callback,path) 
	path = (path or "root") .. "." .. tostring(cGrannyFile.kTypeNames[node.iChunkType or ""])
	local res = callback(node,path)
	if (res) then return res end
	for k,subnode in ipairs(node.childs or {}) do 
		local res = MyIterGranny(subnode,callback,path)
		if (res) then return res end
	end
end

function cDebugGrannyMenu:MakeNewGranny (artid,animid)
	local folder = "/cavern/uoml_freshinstall.4.x/Models/Animals/"
	local old_GetGrannyModelLoader = GetGrannyModelLoader(artid)
	local matname_old = old_GetGrannyModelLoader and GetGrannyMat(artid,0,old_GetGrannyModelLoader) or "grannybase"
	
	

	local pGrannyLoader = LoadGrannyLua(artid)
	
	local matname = matname_old
	local matname = old_GetGrannyModelLoader and GetGrannyMat(artid,0,pGrannyLoader) or "grannybase"
	print("granny_debug",">"..tostring(matname).."<",">"..tostring(matname_old).."<")
	assert(matname == matname_old) 
	
	
	--~ GrannyDebugCompareWithOldLoader(pGrannyLoader,old_GetGrannyModelLoader)
	
	
	local szMatName = matname
	local szMeshName = "MyGrannyTest_Mesh_123"
	--~ local szSkeletonName = "MyGrannyTest_Skel_123"
	--~ local szSkeletonName2 = CreateSkeleton(szSkeletonName)
	--~ assert(szSkeletonName == szSkeletonName2)
	
	
	
	local bodyid = artid
    local skeleton = MyGetOrCreateSkeleton(bodyid) -- skeleton is determined by the bodyid, not possible from the wearables
	if (not skeleton) then return end
    local skeleton_name = skeleton and skeleton.name or "unknown_skeleton"
	local szSkeletonName = skeleton_name
	
	
	
	assert(pGrannyLoader.mBoneTies)
	
	local res = LoadGrannyAsOgreMesh(pGrannyLoader,szMatName,szMeshName,szSkeletonName)
	
	-- create instance
	local sceneManager = GetSceneManager()
	local sMeshName = szMeshName
	local sEntityName = GetUniqueName()
	local entity = sceneManager:createEntity(sEntityName,sMeshName)
	local gfx = CreateRootGfx3D()
	local scenenode = gfx:GetSceneNode()
	scenenode:attachObject(entity)
	
	
	if (animid) then 
		--~ entity:setDisplaySkeleton(true)
		local animname = GetAnimName(bodyid,animid)
		local bLoop = true
		local mpAnimState
		if (animname) then
			assert(entity.getAnimationState,"getAnimationState luabind missing: recompile required (26.03.2010)")
			mpAnimState = entity:getAnimationState(animname)
			assert(mpAnimState)
			mpAnimState:setEnabled(true)
			mpAnimState:setLoop(bLoop)
		end
		
		-- debug compare
		if (1 == 2) then 
			local pMesh2 = gsOldGrannyMeshName and MeshManager_load(gsOldGrannyMeshName)
			local pMesh = entity:getMesh()
			local list = pMesh:enumBoneAssignment()
			print("enumBoneAssignment",list,list and #list,"#"..sMeshName.."#","#"..pMesh:getName().."#")
			for k,entry in ipairs(list) do print("boneAssignment",k,unpack(entry)) end
			local iNumSubMeshes = pMesh:getNumSubMeshes()
			local skel1 = pMesh:getSkeleton()
			local skel2 = pMesh2 and pMesh2:getSkeleton()
			for iSubMeshIdx = 0,iNumSubMeshes-1 do 
				local sub = pMesh:getSubMesh(iSubMeshIdx)
				local sub2 = pMesh2 and pMesh2:getSubMesh(iSubMeshIdx)
				local list = sub:enumBoneAssignment() -- key,vertexIndex,boneIndex,weight
				local list2 = sub2 and sub2:enumBoneAssignment()
				print("sub.enumBoneAssignment",list,list and #list)
				if (skel2) then 
				for k,e in ipairs(list) do 
					local f = list2 and list2[k] or {} 
					local keyA,vertexIndexA,boneIndexA,weightA = unpack(e) local pBone = skel1:getBone(boneIndexA) local boneName1 = pBone and pBone:getName() local bh1 = pBone and pBone:getHandle()
					local keyB,vertexIndexB,boneIndexB,weightB = unpack(f) local pBone = skel2:getBone(boneIndexB) local boneName2 = pBone and pBone:getName() local bh2 = pBone and pBone:getHandle()
					print("sub["..iSubMeshIdx.."].boneAssignmentA",k,keyA,vertexIndexA,boneIndexA,weightA,boneName1,bh1)
					print("sub["..iSubMeshIdx.."].boneAssignmentB",k,keyB,vertexIndexB,boneIndexB,weightB,boneName2,bh2)
					if (k>= 30) then break end
				end
				end
			end
			
			local oldgrn = GetGrannyModelLoader(bodyid)
			for iBoneID=0,40 do local a,b = pGrannyLoader:GetBoneName(iBoneID),oldgrn:GetBoneName(iBoneID)   print("iBoneID->name",iBoneID,a,b) assert_warn(a==b) end
			for iObjPtr=0,40 do local a,b = pGrannyLoader:GetBoneName2(iObjPtr),oldgrn:GetBoneName2(iObjPtr) print("iObjPtr->name",iObjPtr,a,b) assert_warn(a==b) end
			for wid=0,40 do local a,b = pGrannyLoader:WeightBoneIndex2GrannyBoneID(wid),oldgrn:WeightBoneIndex2GrannyBoneID(wid) print("wid->gbid",wid,a,hex(a),b,hex(b)) assert_warn(a==b) end
		end
		
	--~ /cavern/code/iris/mylugre/src/lugre_gfx3D.cpp:700:void	cGfx3D::SetAnim	(const char* szAnimName,const bool bLoop) {
	--~ /cavern/code/iris/mylugre/src/lugre_gfx3D.cpp:721:void	cGfx3D::SetAnimTimePos	(const Real fTimeInSeconds) { if (mpAnimState) mpAnimState->setTimePosition(fTimeInSeconds); }
		RegisterStepper(function () 
			local fTimeInSeconds = math.mod(gMyTicks/1000,10) 
			--~ print("debug.granny.animstep",animname,fTimeInSeconds)
			mpAnimState:setTimePosition(fTimeInSeconds)
		end)
	end
end

function cDebugGrannyMenu:MakeNewGranny_OldDump (artid)
	--~ artid = 791 -- beetle
	artid = 200 -- horse
	
	gDebugCategories.granny 	= true
	local folder = "/cavern/uoml_freshinstall.4.x/Models/Animals/"
	
	local matname = GetGrannyMat(artid,0,GetGrannyModelLoader(artid))
	print("================= MakeNewGranny")
	local filepath = GetGrannyFilePath(artid)
	--~ filepath = folder.."Giant_Beetle_Walk.grn"
	--~ filepath = folder.."Equines_Horse_Dappled_Brown_Walk.grn"    


	print("granny path for artid",artid,filepath)
	local grn = cGrannyFile:New()
	grn:LoadFile(filepath)
	
	if (1 == 2) then 
			for k,filename in pairs(gGrannyDebug_Anims_Horse) do 
				local grn2 = cGrannyFile:New()
				grn2:LoadFile(folder..filename)
				grn2:XMLDump("../mygranny/mygranny.horse."..filename..".xml") 
			end
			local folder = "/cavern/uoml_freshinstall.4.x/Models/Animals/"
			for k,filename in pairs(gGrannyDebug_Anims_Beetle) do 
				local grn2 = cGrannyFile:New()
				grn2:LoadFile(folder..filename)
				grn2:XMLDump("../mygranny/mygranny.beetle."..filename..".xml") 
			end
	end
	
	
	function MyGetChunkT (iChunkType) return iChunkType and grn.kTypeNames[iChunkType] or nil end
	function MyDump (obj) 
		print("dump:",obj,MyGetChunkT(obj and obj.iChunkType))
		for k,v in pairs(obj) do print(" ",k,v,MyGetChunkT(v and type(v) == "table" and v.iChunkType)) end
	end
	
	function MyFilterFields (arr) 
		if (type(arr) ~= "table") then return arr end
		local res = {}
		local blocked = {iChildren=true,childsleft=true,iChunkType=true,iOffset=true,} -- ,childs=table: 0x9532d20
		for k,v in pairs(arr) do if (not blocked[k]) then res[k] = v end end
		return res
	end
	function MyGrannyDump(arr,name,subfield,levels)
		if (not arr) then print(name,"!!NIL!!") return end
		if (#arr == 0) then print(name,"!!EMPTY!!",SmartDump(MyFilterFields(arr))) end
		for k,entry in ipairs(arr) do if (k<=11) then print(name,k.."/"..#arr,SmartDump(MyFilterFields(subfield and entry[subfield] or entry),levels or 2)) end end
	end
	--~ function MyGrannyDump() end -- block output
	
	local Object = grn.pMainChunk.Object
	MyGrannyDump(Object.textChunk.texts,"text")
	
	--~ MyDump(Object.mesh_list.mesh)
	local mesh = Object.mesh_list.mesh
	local point_container = mesh and mesh.point_block.point_container
	
	if (point_container) then
		MyGrannyDump(point_container.points.list_points,"point")
		MyGrannyDump(point_container.normals.list_normals,"normal")
		if (point_container.texture_container.texcoords) then
			print("texcoords:unknown:",	point_container.texture_container.texcoords.unknown)
			MyGrannyDump(point_container.texture_container.texcoords.list_texcoords,"texcoord")
		end
	end
	
	if (mesh) then 
		print("weights:",SmartDump(MyFilterFields(mesh.weights)))
		MyGrannyDump(mesh.weights.list_weightchunks,"weight",nil,3)
		MyGrannyDump(mesh.polygons.list_polygons,"polygon")
	end
	
	MyGrannyDump(Object.boneTies1.childs,"boneTies1:boneobject",nil,3)
	MyGrannyDump(Object.bones.skeleton.bonelist.childs,"bone","bone")
	local btcont = Object.boneTies2.boneties_container
	local a =	btcont.bone_objptrs_container.bone_objptr
	local b =	btcont.bonetie_container and 
				btcont.bonetie_container.bonetie_group and 
				btcont.bonetie_container.bonetie_group.bonetie_list
	--[[
        <boneTies2>
            <boneties_container>
                <bone_objptrs_container>
                    <bone_objptr iBoneTie2ID="1">
                        <bone_objptrs iNum="36">
                            <BoneTies2 35="9" 29="7" 1="24" 3="22" 2="23" 5="26" 4="27" 
	]]--
	print("iBoneTie2ID=",a.iBoneTie2ID,"bone_objptrs.iNum=",a.bone_objptrs.iNum)
	MyGrannyDump(a and a.bone_objptrs.BoneTies2,"bt2:bone_objptr")
	MyGrannyDump(b and b.childs,"bt2:bonetie","bonetie")
	function MyPrintField (obj,fieldname) print(fieldname,obj[fieldname]) end
	if (Object and Object.texture_list and Object.texture_list.texture) then
		MyPrintField(Object.texture_list.texture,"iTextureID")
		if (Object.texture_list.texture.texture_sublist) then
			MyPrintField(Object.texture_list.texture.texture_sublist.texture_poly.texture_poly_list,"iElementSize")
			MyPrintField(Object.texture_list.texture.texture_sublist.texture_poly.texture_poly_list,"iNum")
			MyGrannyDump(Object.texture_list.texture.texture_sublist.texture_poly.texture_poly_list.list_texpoly_normal,"list_texpoly_normal")
			--~ for k,entry in pairs(Object.texture_list.texture.texture_sublist.texture_poly.texture_poly_list.list_texpoly_normal) do assert(k-1 == entry.iUnknown) end -- todo : add as sanity check
		end
	end
	
	
	-- TODO : testrun for asserts on all granny files
	local objlist = {}
	for k,obj in ipairs(Object.object_list.childs) do
		local keys = {}
		assert(obj.unknown_a == 1)
		assert(obj.unknown_b == 1)
		local myobj = keys
		table.insert(objlist,myobj)
		for k2,key in ipairs(obj.object_key_list.childs) do
			local values = key.object_value_list.childs
			assert(#values == 1)
			assert(values[1].unknown_a == 0)
			keys[key.key] = values[1].unknown_b
		end
	end
	MyGrannyDump(objlist,"obj")
	
	function MyMakeGrannyGfx (mesh,texture_poly,pOgreMesh) 
		local bSkeletalAnimation = true
		local bVertexAnimation = false
		local vdecl = cVertexDecl:New()
		vdecl:addElement(0,VET_FLOAT3,VES_POSITION)
		vdecl:addElement(0,VET_FLOAT3,VES_NORMAL)
		vdecl:addElement(1,VET_FLOAT2,VES_TEXTURE_COORDINATES)
		--~ vdecl:PrintAutoOrganised(bSkeletalAnimation,bVertexAnimation)
		
		local polygons			= mesh.polygons.list_polygons
		local point_container 	= mesh.point_block.point_container
		local positions			= point_container.points.list_points
		local normals			= point_container.normals.list_normals
		local texcoords			= point_container.texture_container.texcoords and
								  point_container.texture_container.texcoords.list_texcoords
		local texpolys			= texture_poly.texture_poly_list.list_texpoly_normal
		
		-- sanity checks
		if (texpolys) then 
			assert(#polygons == #texpolys)
			for k,texpoly in ipairs(texpolys) do assert(texpoly.iUnknown == k-1) end
		end
		
		-- assembling vertex-buffer, this block doesn't need ogre
		--~ !!!!!! MOVED TO lib.granny.anim.lua cSubMeshConstructor::Execute !!!!!
		local fSquareRadius = rr
		--~ print("vb0.vc",vb0.vc,vb0.iFirstSize)
		--~ print("vb1.vc",vb1.vc,vb1.iFirstSize)
		--~ print("ib.ic",ib.ic)
		
		
		
		
		local msMatName = matname -- TODO!
		
		-- create submesh
		local sub = pOgreMesh:createSubMesh()
		sub:setMaterialName(msMatName)
		sub:setUseSharedVertices(false)
		
		sub:setOperationType(OT_TRIANGLE_LIST)
		--~ sub:setOperationType(OT_POINT_LIST)
		
		local vertexData = CreateVertexData()
		local indexData = CreateIndexData()
		sub:setVertexData(vertexData)
		sub:setIndexData(indexData)
		
		--~ now ogre stuff : vertexbuffer,renderop,renderable,movable
		--~ local robmovable = CreateRobMovable()
		--~ local robrenderable = CreateRobRenderable(robmovable)
		--~ robmovable:AddRenderable(robrenderable)
		
		--~ local e = 10
		--~ robmovable:SetBounds({-e,-e,-e},{e,e,e})
		--~ robmovable:ParentNeedsUpdate()
		--~ robrenderable:SetMaterial(matname)
		--~ robrenderable:SetMaterial("BaseWhiteNoLighting")
		
		-- Ogre::Renderable::getRenderOperation(RenderOperation &op) ? hard to luabind, also we'd get only a copy...
		--~ local renderop = robrenderable:GetRenderOperationPtr() -- Ogre::RenderOperation
		--~ renderop:setOperationType(OT_TRIANGLE_LIST)
		--~ local vertexData = renderop:getVertexData()
		--~ local indexData = renderop:getIndexData()
		
		vertexData:setVertexDecl(vdecl:GetOgreVertexDecl())
		--~ print("vb0:GetVertexSize()",vb0:GetVertexSize(),vb0:GetVertexNum())
		--~ print("vb1:GetVertexSize()",vb1:GetVertexSize(),vb1:GetVertexNum())
		vertexData:createAndBindVertexBuffer(vb0:GetVertexSize(),vb0:GetVertexNum(),HBU_DYNAMIC_WRITE_ONLY,false,0) -- (iVertexSize,iNumVerts,iUsage,bUseShadowBuffer=false,iBindIndex=0)
		vertexData:createAndBindVertexBuffer(vb1:GetVertexSize(),vb1:GetVertexNum(),HBU_DYNAMIC_WRITE_ONLY,false,1) -- (iVertexSize,iNumVerts,iUsage,bUseShadowBuffer=false,iBindIndex=0)
		indexData:createAndBindIndexBuffer(IT_32BIT,ib:GetIndexNum(),HBU_STATIC_WRITE_ONLY) -- (iIndexType,iNumIndexes,iUsage,bUseShadowBuffer=false)
		
		vertexData:setVertexStart(0)
		indexData:setIndexStart(0)
		vertexData:setVertexCount(vb0:GetVertexNum())
		indexData:setIndexCount(ib:GetIndexNum())
		
		vertexData:writeToVertexBuffer(vb0:GetFIFO(),0)
		vertexData:writeToVertexBuffer(vb1:GetFIFO(),1)
		indexData:writeToIndexBuffer(ib:GetFIFO()) 
		
		--~ local gfx = CreateRootGfx3D()
		--~ local scenenode = gfx:GetSceneNode()
		--~ scenenode:attachObject(robmovable)
		
		-- todo : mousepick
		
		--[[
		function LoadGrannyAsOgreAnim (...)
				local skeletonname = "blub"
				local skeleton = SkeletonManager_load(skeletonname)
				-- fTotalTime = cAnimationTotalTimeConstructor
				local anim = skeleton:createAnimation(szAnimName,fTotalTime) // in seconds	
				-- cAnimationConstructor anim lBodySamples:GetSampleBone      ... todo:bones indirekt verbunden über boneties ? 
		end
		]]--
		
		--~ calculate bounds,  todo : calc for whole mesh, not only for this submesh
		local r = math.sqrt(fSquareRadius)
		pOgreMesh:_setBounds({-r,-r,-r,r,r,r},false)
		pOgreMesh:_setBoundingSphereRadius(r)
	end
	
	
	local bIsEmptyMesh = true
	local bHasBoneWeights = false
	for k,submesh in ipairs(Object.mesh_list.childs or {}) do
		if (submesh.weights and submesh.weights.list_weightchunks and #submesh.weights.list_weightchunks > 0) then bHasBoneWeights = true end
		if (submesh.polygons and submesh.polygons.list_polygons and #submesh.polygons.list_polygons > 0) then bIsEmptyMesh = false end
	end
	if (bIsEmptyMesh) then return false end
	
	local pSkeleton
	if (bHasBoneWeights) then 
		--~ local szSkeletonName = GetUniqueName()
		--~ CreateSkeleton : pSkeleton = SkeletonManager_create(szSkeletonName,Ogre::ResourceGroupManager::DEFAULT_RESOURCE_GROUP_NAME,true);
		--~ local pSkeleton = SkeletonManager_load(szSkeletonName)
		--~ if (pSkeleton) then pMesh:setSkeletonName(pSkeleton:getName()) assert(szSkeletonName == pSkeleton:getName()) end  -- getname != name i think, there was something weird here
	end
	
	
	
	local sMeshName = GetUniqueName() or "MyGrannyMeshName01"
	local pOgreMesh = MeshManager_createManual(sMeshName)
	pOgreMesh:_setBounds({0,0,0,0,0,0}, true)
	pOgreMesh:_setBoundingSphereRadius(0)
	
	--~ local mesh			= Object.mesh_list.childs[1] -- .mesh*26
	--~ local texture_poly	= Object.texture_list.texture.texture_sublist.childs[1] -- .texture_poly -- *26
	if (Object.mesh_list) then 
		for k,submesh in ipairs(Object.mesh_list.childs or {}) do
			local texture_poly = Object.texture_list.texture.texture_sublist.childs[k]
			MyMakeGrannyGfx(submesh,texture_poly,pOgreMesh) 
		end
	end
	
	pOgreMesh:load(false)
	
	local sceneManager = GetSceneManager()
	local sEntityName = GetUniqueName()
	local entity = sceneManager:createEntity(sEntityName,sMeshName)
	
	local gfx = CreateRootGfx3D()
	local scenenode = gfx:GetSceneNode()
	scenenode:attachObject(entity)
	
	--~ os.exit(0)
end



--[[
  cGrannyFile:LoadFile    /cavern/uoml_freshinstall.4.x/Models/Animals/Equines_Horse_Dappled_Brown_Walk.grn        
bone    1/36    {fTranslate={[1]=0,[2]=0,[0]=0,},iParent=0,fMatrix={[1]=0,[2]=0,[3]=0,[4]=1,[5]=0,[6]=0,[7]=0,[8]=1,[0]=1,},fQuaternion={[1]=0,[2]=0,[3]=1,[0]=0,},}                                                                                                                                                        
bone    2/36    {fTranslate={[1]=-0.000461,[2]=0,[0]=0,},iParent=0,fMatrix={[1]=0,[2]=0,[3]=0,[4]=1,[5]=0,[6]=0,[7]=0,[8]=1,[0]=1,},fQuaternion={[1]=0,[2]=0,[3]=1,[0]=0,},}                                                                                                                                                
bone    3/36    {fTranslate={[1]=0.473461,[2]=1.085400,[0]=-0.008964,},iParent=1,fMatrix={[1]=0.000000,[2]=-0.000000,[3]=0.000000,[4]=1,[5]=0.000000,[6]=0.000000,[7]=0.000000,[8]=1,[0]=1,},fQuaternion={[1]=0.003099,[2]=-0.710178,[3]=0.704009,[0]=0.003072,},}                                                          
bone    4/36    {fTranslate={[1]=-0.000033,[2]=-0.003174,[0]=-0.003688,},iParent=2,fMatrix={[1]=-0.000000,[2]=0.000000,[3]=-0.000000,[4]=1,[5]=-0.000000,[6]=-0.000000,[7]=-0.000000,[8]=1,[0]=1,},fQuaternion={[1]=0.517145,[2]=0.482246,[3]=-0.482246,[0]=0.517144,},}                                                    
bone    5/36    {fTranslate={[1]=0.146758,[2]=-0.011366,[0]=0.162539,},iParent=3,fMatrix={[1]=-0.000000,[2]=-0.000000,[3]=0.000000,[4]=1.000000,[5]=-0.000000,[6]=-0.000000,[7]=-0.000000,[8]=1.000000,[0]=1,},fQuaternion={[1]=0.002761,[2]=0.789323,[3]=0.611798,[0]=0.051632,},}                                         
bone    6/36    {fTranslate={[1]=-0.000356,[2]=0.000014,[0]=0.383526,},iParent=4,fMatrix={[1]=0.000000,[2]=0.000000,[3]=0.000000,[4]=1,[5]=-0.000000,[6]=0.000000,[7]=0.000000,[8]=1,[0]=1,},fQuaternion={[1]=0.045910,[2]=-0.092244,[3]=0.994571,[0]=-0.014532,},}                                                         
bone    7/36    {fTranslate={[1]=-0.000114,[2]=-0.000003,[0]=0.455237,},iParent=5,fMatrix={[1]=-0.000000,[2]=0.000000,[3]=-0.000000,[4]=1.000000,[5]=0.000000,[6]=-0.000000,[7]=0.000000,[8]=1.000000,[0]=1.000000,},fQuaternion={[1]=-0.024543,[2]=-0.170306,[3]=0.985055,[0]=0.007792,},}                                 
bone    8/36    {fTranslate={[1]=-0.000084,[2]=0.000000,[0]=0.152219,},iParent=6,fMatrix={[1]=0.000000,[2]=0.000000,[3]=0.000000,[4]=1,[5]=-0.000000,[6]=0.000000,[7]=-0.000000,[8]=1.000000,[0]=1.000000,},fQuaternion={[1]=0.001701,[2]=-0.513025,[3]=0.858372,[0]=0.000739,},}
bone    9/36    {fTranslate={[1]=-0.000251,[2]=0.000001,[0]=0.223847,},iParent=7,fMatrix={[1]=-0.000000,[2]=0.000000,[3]=-0.000000,[4]=1,[5]=-0.000000,[6]=-0.000000,[7]=-0.000000,[8]=1.000000,[0]=1.000000,},fQuaternion={[1]=0.004809,[2]=0.141923,[3]=0.989864,[0]=-0.001989,},}
bone    10/36   {fTranslate={[1]=0.000000,[2]=-0.000000,[0]=0.329182,},iParent=8,fMatrix={[1]=0.000000,[2]=0.000000,[3]=0.000000,[4]=1,[5]=-0.000000,[6]=0.000000,[7]=-0.000000,[8]=1.000000,[0]=1.000000,},fQuaternion={[1]=-0.015708,[2]=-0.107925,[3]=0.993487,[0]=-0.032989,},}
bone    11/36   {fTranslate={[1]=0.007118,[2]=-0.078183,[0]=0.043131,},iParent=9=0x09,fMatrix={[1]=0.000000,[2]=-0.000000,[3]=-0.000000,[4]=1,[5]=-0.000000,[6]=-0.000000,[7]=-0.000000,[8]=1.000000,[0]=1,},fQuaternion={[1]=-0.004665,[2]=-0.190827,[3]=0.981608,[0]=-0.003001,},}

cGrannyFile:LoadFile    /home/ghoul/Desktop/cavern/uoml/Models/Animals/Equines_Horse_Dappled_Brown_Lod2.grn                                                                                                  
bone    1/37    {fTranslate={[1]=0,[2]=0,[0]=0,},iParent=0,fMatrix={[1]=0,[2]=0,[3]=0,[4]=1,[5]=0,[6]=0,[7]=0,[8]=1,[0]=1,},fQuaternion={[1]=0,[2]=0,[3]=1,[0]=0,},}                                                                                                                                                        
bone    2/37    {fTranslate={[1]=-0.000461,[2]=0,[0]=0,},iParent=0,fMatrix={[1]=0,[2]=0,[3]=0,[4]=1,[5]=0,[6]=0,[7]=0,[8]=1,[0]=1,},fQuaternion={[1]=0,[2]=0,[3]=1,[0]=0,},}                                                                                                                                                
bone    3/37    {fTranslate={[1]=0.473461,[2]=1.060614,[0]=-0.000000,},iParent=1,fMatrix={[1]=0.000000,[2]=0.000000,[3]=0.000000,[4]=1,[5]=0.000000,[6]=-0.000000,[7]=0.000000,[8]=1,[0]=1.000000,},fQuaternion={[1]=0.003085,[2]=-0.707100,[3]=0.707101,[0]=0.003085,},}                                                   
bone    4/37    {fTranslate={[1]=-0.000001,[2]=-0.003174,[0]=-0.003688,},iParent=2,fMatrix={[1]=-0.000000,[2]=0.000000,[3]=-0.000000,[4]=1,[5]=0.000000,[6]=0.000000,[7]=-0.000000,[8]=1,[0]=1,},fQuaternion={[1]=-0.500000,[2]=-0.500000,[3]=0.500001,[0]=-0.499999,},}                                                    
bone    5/37    {fTranslate={[1]=0.146738,[2]=-0.000000,[0]=0.162940,},iParent=3,fMatrix={[1]=-0.000000,[2]=0.000000,[3]=0.000000,[4]=1.000000,[5]=0.000000,[6]=0.000000,[7]=0.000000,[8]=1,[0]=1.000000,},fQuaternion={[1]=0.000102,[2]=0.769173,[3]=0.639041,[0]=-0.000088,},}                                            
bone    6/37    {fTranslate={[1]=0.187062,[2]=-0.188280,[0]=-0.114344,},iParent=4,fMatrix={[1]=0.000000,[2]=-0.000000,[3]=0.000000,[4]=1,[5]=0.000000,[6]=-0.000000,[7]=-0.000000,[8]=1,[0]=1,},fQuaternion={[1]=0.355465,[2]=-0.038615,[3]=-0.060378,[0]=0.931938,},}                                                      
bone    7/37    {fTranslate={[1]=-0.000359,[2]=-0.000000,[0]=0.383541,},iParent=4,fMatrix={[1]=0.000000,[2]=0.000000,[3]=-0.000000,[4]=1,[5]=0.000000,[6]=0.000000,[7]=0.000000,[8]=1,[0]=1,},fQuaternion={[1]=0.000000,[2]=-0.069757,[3]=0.997564,[0]=-0.000000,},}                                                        
bone    8/37    {fTranslate={[1]=-0.000077,[2]=0.000000,[0]=0.455183,},iParent=6,fMatrix={[1]=-0.000000,[2]=0.000000,[3]=0.000000,[4]=1,[5]=0.000000,[6]=0.000000,[7]=0.000000,[8]=1,[0]=1,},fQuaternion={[1]=-0.000001,[2]=-0.428783,[3]=0.903408,[0]=-0.000004,},}                                                        
bone    9/37    {fTranslate={[1]=-0.142090,[2]=-0.112536,[0]=-0.024633,},iParent=7,fMatrix={[1]=0.000000,[2]=0.000000,[3]=0.000000,[4]=1.000000,[5]=0.000000,[6]=0.000000,[7]=0.000000,[8]=1.000000,[0]=1.000000,},fQuaternion={[1]=0.536666,[2]=-0.535021,[3]=-0.426220,[0]=0.494044,},}                                   
bone    10/37   {fTranslate={[1]=-0.000000,[2]=0.000000,[0]=0.352391,},iParent=8,fMatrix={[1]=0.000000,[2]=-0.000000,[3]=0.000000,[4]=1,[5]=-0.000000,[6]=0.000000,[7]=-0.000000,[8]=1.000000,[0]=1.000000,},fQuaternion={[1]=-0.525638,[2]=0.472182,[3]=0.501046,[0]=0.499702,},}                                          
bone    11/37   {fTranslate={[1]=-0.000000,[2]=0.000000,[0]=0.261671,},iParent=9=0x09,fMatrix={[1]=0.000000,[2]=0.000000,[3]=-0.000000,[4]=1.000000,[5]=0.000000,[6]=0.000000,[7]=0.000000,[8]=1,[0]=1,},fQuaternion={[1]=-0.000000,[2]=-0.498851,[3]=0.866688,[0]=0.000000,},}                                             

-- beetle : walk hat eigenes mesh ?!? (MEHRERE SUBMESHES!)    /cavern/uoml_freshinstall.4.x/Models/Animals/Giant_Beetle_Walk.grn   ne, nur so hilfobjekte krams oder sowas...

-- comparison beetle vs horse 
beetle...meshlist.mesh	: <id iID="5" />
horse...meshlist.mesh	: <id iID="1" />
one anim per file!
]]--

function GrannyTest_PreOgreInit2 ()
    if (not gUOPath) then AutoDetectUOPath() end
	CheckUODir()
	cDebugGrannyMenu:MakeNewGranny(791)
	os.exit()
end

-- ***** ***** ***** end

