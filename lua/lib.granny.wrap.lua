
-- override of the c++ code active
if (1 == 2) then
	_Old_Cpp_LoadGranny = LoadGranny
	function LoadGranny (file) return LoadGrannyLua_ByFilePath(file) end
	--~ function LoadGranny (file) return LoadGrannyLua_ByFilePath_DebugCompareWithOldLoader(file) end
	
	function LoadGrannyLua_ByFilePath_DebugCompareWithOldLoader (file)
		local res = LoadGrannyLua_ByFilePath(file)
		GrannyDebugCompareWithOldLoader(res,_Old_Cpp_LoadGranny(file))
		return res
	end	
end

function LoadGrannyLua (artid) return LoadGrannyLua_ByFilePath(GetGrannyFilePath(artid)) end

function LoadGrannyLua_ByFilePath (filepath)
	local grn = cGrannyFile:New()
	if (grn:LoadFile(filepath)) then return WrapGrannyLoaderNew(grn) end
end



function GrannyDebugCompareWithOldLoader (grannyA,grannyB)
	-- test granny_L.cpp param api
	if (not grannyA) then return end
	assert(grannyA,"old granny loader failed")
	local MyTest = function (name,...)
		local resA = {grannyA[name](grannyA,...)}
		local resB = {grannyB[name](grannyB,...)}
		--~ for k,v in ipairs(resA) do print("MyTest",name,k,(resB[k] == v) and "--ok--" or "#FAIL#","A("..tostring(v)..")","B("..tostring(resB[k])..")") end
		for k,v in ipairs(resA) do print("MyTest",name,k,(resB[k] == v) and "--ok--" or "#FAIL#","A("..tostring(v)..")","B("..tostring(resB[k])..")") assert(resB[k] == v)  end
		return unpack(resA)
	end
	--~ granny:GetTextureID(index)
	
	local textchunkcount  = MyTest("GetTextChunkCount")
	for i = 0,textchunkcount-1 do
		local chunksize = MyTest("GetTextChunkSize",i)
		for j = 0,chunksize-1 do MyTest("GetText",i,j) end
	end
	
	local paramgroupcount = MyTest("GetParamGroupCount")
	for i = 0,paramgroupcount-1 do
		local groupsize = MyTest("GetParamGroupSize",i)
		for j = 0,groupsize-1 do
			local key,value = MyTest("GetParam",i,j)
		end
	end

	MyTest("GetSubMeshCount")
	local texidcount = MyTest("GetTextureIDCount")
	for i = 0,texidcount-1 do
		MyTest("GetTextureID",i)
	end
	
	print("================ granny_L param api test done")
end


function MyLoadGrannyAnim(bodyid,animid,skeleton,bodypartsamples)
	-- load anim granny
	local animname = GetAnimName(bodyid,animid) 
	if (skeleton.anims[animname]) then return end -- already loaded
	local animpath = GetAnimPath(bodyid,animid)
	local mygrannyanim = LoadGrannyLua_ByFilePath(animpath)
	if (not mygrannyanim) then 
		print("ERROR LoadGrannyAnim",animpath,bodyid,animid,skeleton,bodypartsamples)
		return false
	end
	
	-- construct animation
	printdebug("granny","LoadGrannyAnim",bodyid,animid,skeleton.name,animname,animpath)
	mygrannyanim:AddAnimToSkeleton(skeleton.name,animname,bodypartsamples)
	
	skeleton.anims[animname] = true
end

function MyGetOrCreateSkeleton(bodyid)
	--~ return GetOrCreateSkeleton(bodyid)
	local modelinfo = GetGrannyModelInfo(bodyid)
	
	if (not modelinfo) then GrannyShowNo3DDataError(bodyid) return end
	assert(modelinfo,"ERROR bodyinfo for skeleton not found "..tostring(bodyid))

	while (modelinfo.animid ~= 0) do modelinfo = GetGrannyModelInfo(modelinfo.animid) end
	local skeletonname = GetUniqueName() -- modelinfo.modelname -- example: "deer_stag"
	
	CreateSkeleton(skeletonname)
	local skeleton = { name=skeletonname, anims={} }
	
	-- load sample bodyparts needed for animation (needed to assemble correct granny skeleton)
	local bodypartsamples = {}
	if (IsBodyIDHuman(bodyid)) then 
		if (IsBodyIDFemale(bodyid)) then
			-- human female body parts, often (bodyid == 401)
			for k,v in pairs(kGrannyModelPartByNum) do table.insert(bodypartsamples,LoadGrannyLua(k+kGrannyModelPartAddFemale)) end -- GetGrannyModelLoader->LoadGrannyLua
		else
			-- human male body parts, often (bodyid == 400)
			for k,v in pairs(kGrannyModelPartByNum) do table.insert(bodypartsamples,LoadGrannyLua(k+kGrannyModelPartAddMale)) end -- GetGrannyModelLoader->LoadGrannyLua
		end
	else
		-- non-human model has komplete skeleton
		table.insert(bodypartsamples,LoadGrannyLua(bodyid)) -- GetGrannyModelLoader->LoadGrannyLua
	end
	
	-- load all animations so all entities created afterwards have the full anim set
	for k,v in pairs(gAnimInfoLists[modelinfo.typeid]) do
		MyLoadGrannyAnim(bodyid,k,skeleton,bodypartsamples) 
	end

	return skeleton
end




function assert_warn (cond,msg) if (not cond) then print("assert_warn",msg) end end
function assert_warn (cond,msg) assert(cond,msg) end


gProfiler_LuaGrannyWrapper = CreateRoughProfiler("LuaGrannyWrapper")

function WrapGrannyLoaderNew (grn)

    gProfiler_LuaGrannyWrapper:Start(gEnableProfiler_LuaGrannyWrapper)
    gProfiler_LuaGrannyWrapper:Section("submeshes")
	
	local pGrannyLoader = {}
	-- wrap grn into pGrannyLoader
	local Object = grn.pMainChunk.Object
	local mSubMeshes = {}
	pGrannyLoader.mSubMeshes = mSubMeshes
	local bHasBoneWeights
	for kMeshIndex,mesh in ipairs(Object.mesh_list.childs or {}) do
		local pLoaderSubMesh = {}
		table.insert(mSubMeshes,pLoaderSubMesh)
		
		--~ local weightdata = {}
		--~ table.insert(pLoaderSubMesh.mWeights,weightdata)
		
		--~ weightdata.iNumBones = 0
		--~ weightdata.pWeights = {}
		--~ local weight = {}
		--~ table.insert(weightdata.pWeights,weight)
		--~ weight.iWeightBoneIndex = 0
		--~ weight.fWeight = 0
		
		--~ if (mesh.weights and mesh.weights.list_weightchunks and #mesh.weights.list_weightchunks > 0) then bHasBoneWeights = true end
		--~ if (mesh.polygons and mesh.polygons.list_polygons and #mesh.polygons.list_polygons > 0) then bIsEmptyMesh = false end
		
		local polygons			= mesh.polygons.list_polygons
		local point_container 	= mesh.point_block.point_container
		local positions			= point_container.points.list_points
		local normals			= point_container.normals.list_normals
		local texcoords			= point_container.texture_container.texcoords and
								  point_container.texture_container.texcoords.list_texcoords
		
		local texture_poly 		= Object.texture_list.texture.texture_sublist.childs[kMeshIndex]
		local texpolys			= texture_poly.texture_poly_list.list_texpoly_normal
		local list_weightchunks	= mesh.weights.list_weightchunks
		
		-- sanity checks
		if (texpolys) then 
			assert_warn(#polygons == #texpolys,"poly:texpoly:"..#polygons.."<>"..#texpolys)
			for k,texpoly in ipairs(texpolys) do assert(texpoly.iUnknown == k-1) end
		end

		pLoaderSubMesh.mPolygons = polygons
		pLoaderSubMesh.mTexturePolyLists = texpolys
		pLoaderSubMesh.mTexCoords = texcoords
		pLoaderSubMesh.mPoints = positions
		pLoaderSubMesh.mNormals = normals
		pLoaderSubMesh.mWeights = list_weightchunks -- 0XCA5E0702:VisitWeights lib.granny.loader.lua:417:cGrannyFile.chunkHandlers[0XCA5E0702]
		
		if (pLoaderSubMesh.mWeights and #pLoaderSubMesh.mWeights > 0) then bHasBoneWeights = true end
	end
	
    gProfiler_LuaGrannyWrapper:Section("rest1")
	-- granny wide bone infos
	if (true) then 
		pGrannyLoader.mBoneNameCache = {}
		function pGrannyLoader:WeightBoneIndex2GrannyBoneID (iWeightBoneIndex)
			local o = self.mBoneTies[iWeightBoneIndex+1]
			return o and o.iBone or -1
		end
		function pGrannyLoader:FindBone (sName)
			local sSearchName = self:IsMasterBoneName(sName) and self:GetUnifiedMasterBoneName() or sName
			local imax = #self.mBoneTies2+1
			for i = 0,imax do if (self:GetBoneName(i) == sSearchName) then return i end end
			return -1
		end
		function pGrannyLoader:GetBoneName (iBoneID) -- used when creating bone weights
			local cache = self.mBoneNameCache[iBoneID]
			if (cache ~= nil) then return cache end
			local iObjPtr = self.mBoneTies2[iBoneID+1]
			cache = iObjPtr and self:GetBoneName2(iObjPtr - 1) or ""
			self.mBoneNameCache[iBoneID] = cache
			return cache
		end
		function pGrannyLoader:GetBoneName2 (iObjPtr) -- used by GetBoneName() and when creating anim    (pAnim.mpAnim.iID-1)
			local iObj = self.mBoneTies1[iObjPtr+1] if (not iObj) then return "" end
			iObj = iObj - 1 
			local mainparam = self.mMainParams[iObj] if (not mainparam) then return "" end
			local sName = mainparam["__ObjectName"] or ""
			if (self:IsMasterBoneName(sName)) then return self:GetUnifiedMasterBoneName() end
			return sName
		end
		function pGrannyLoader:GetUnifiedMasterBoneName () return "unified_granny_master_bone_name" end
		function pGrannyLoader:IsMasterBoneName (sName) return string.find(sName,"master") or string.find(sName,"mesh") end
		
		

		--~ function MyZeroBased (arr) local res = {} for k,v in ipairs(arr) do res[k-1] = v end return res end
		local Copyright = grn.pMainChunk.Copyright
		local text1 = Copyright and Copyright.textChunk.texts
		pGrannyLoader.mTextChunks = {text1,Object.textChunk.texts}  -- first : probaly copyright text chunk in other header
		
		
		local mTextureIDs = {}
		pGrannyLoader.mTextureIDs = mTextureIDs
		if (Object.texture_info_list and Object.texture_info_list.childs) then 
		for k,texture_info in ipairs(Object.texture_info_list.childs) do 
			--~ print("texinfo",SmartDump(texture_info.id))
			table.insert(mTextureIDs,texture_info.id.iID)
		end
		end
		--~ os.exit(0)
		
		-- Object.textChunk.texts
		--~ print("textChunk:",SmartDump(Object.textChunk))    -- 0xca5e0200
		--~ for k,text in pairs(Object.textChunk.texts) do print(" text:",k,SmartDump(text)) end
		
		local objlist = {}
		for k,obj in ipairs(Object.object_list.childs) do
			local keys = {}
			assert(obj.unknown_a == 1)
			assert(obj.unknown_b == 1)
			local myobj = keys
			table.insert(objlist,myobj)
			local list = {}
			for k2,key in ipairs(obj.object_key_list.childs) do
				local values = key.object_value_list.childs
				assert(#values == 1)
				assert(values[1].unknown_a == 0)
				keys[key.key] = values[1].unknown_b
				assert(not values[2])
				table.insert(list,{first=key.key,second=values[1].unknown_b})
				--~ for k3,value in ipairs(values) do
					--~ print("key:",k,key.key,value.unknown_b,Object.textChunk.texts[value.unknown_b])
				--~ end
			end
			myobj.list = list
			--~ print("----")
		end
		pGrannyLoader.mParamGroups = objlist
			
			
		-- main params are in mParamGroups and mTextChunks[2]
		assert(pGrannyLoader.mTextChunks) -- std::vector<std::vector<std::string> >	0xCA5E0200	VisitTextChunk
		assert(pGrannyLoader.mParamGroups) -- vector<vector<pair<uint32,uint32> > >	0XCA5E0F00.0XCA5E0F01.0XCA5E0F02
		local self = pGrannyLoader
		local mParamGroups = pGrannyLoader.mParamGroups
		local mMainParams = {}
		local mTextChunks = self.mTextChunks
		local mTextChunksB = mTextChunks[2]
		self.mMainParams = mMainParams
		if (mTextChunksB) then
			for objidx,keys in ipairs(mParamGroups) do 
				mMainParams[objidx-1] = {}
				for i_key,i_val in pairs(keys) do 
					if (i_key ~= "list") then
						local key		= mTextChunksB[i_key+1]
						local val		= mTextChunksB[i_val+1]
						if (key and val) then 
							mMainParams[objidx-1][key] = string.lower(val) 
						end
					end
					--~ print("mMainParams["..(objidx-1).."]:"..i_key.."="..tostring(key).."="..i_val.."="..tostring(val))
				end
			end
		end
			
		--~ 0xca5e0c02	MyIterGranny    root.Object.boneTies2.boneties_container.bone_objptrs_container.bone_objptr.bone_objptrs        {iChildren=0,iNum=37=0x25,BoneTies2=table: 0x9bab008,iChunkType=0xca5e0c02,iOffset=34572=0x870c,}
		--~ 0xca5e0f04	MyIterGranny    Object.boneTies1.boneobject.id    {iChildren=0,iID=6,iChunkType=0xca5e0f04,iOffset=9992=0x2708,}
		--~ 0xca5e0f04	MyIterGranny    Object.boneTies1.boneobject.id    {iChildren=0,iID=2,iChunkType=0xca5e0f04,iOffset=9996=0x270c,}
		--~ 0xca5e0c0a	MyIterGranny    root.Object.boneTies2.boneties_container.bonetie_container.bonetie_group.bonetie_list.bonetie   {iChildren=0,bonetie=table: 0xa0f98a0,iChunkType=0xca5e0c0a,iOffset=34724=0x87a4,}
		--~ 0xca5e0c0a	MyIterGranny    root.Object.boneTies2.boneties_container.bonetie_container.bonetie_group.bonetie_list.bonetie   {iChildren=0,bonetie=table: 0xa3bb478,iChunkType=0xca5e0c0a,iOffset=34756=0x87c4,}
		--~ MyIterGranny(Object,function (node,path) if (node.iChunkType == 0XCA5E1204) then print("MyIterGranny",path,SmartDump(node)) end end)
	
		pGrannyLoader.mBoneTies2 = Object.boneTies2.boneties_container.bone_objptrs_container.bone_objptr.bone_objptrs.BoneTies2 -- 0xca5e0c02  only one hit
		local mBoneTies1 = {}
		pGrannyLoader.mBoneTies1 = mBoneTies1
		for k,child in ipairs(Object.boneTies1.childs) do 
			assert(#child.childs == 1)
			assert(child.childs[1].iID)
			--~ print("0xca5e0f04",SmartDump())      
			local id = child.childs[1].iID
			table.insert(mBoneTies1,id)
		end 
		local bonetie_group = Object.boneTies2.boneties_container.bonetie_container.bonetie_group
		local mBoneTies = {}
		pGrannyLoader.mBoneTies = mBoneTies
		if (bonetie_group) then 
			local bone_tie_list = bonetie_group.bonetie_list.childs
			for k,child in ipairs(bone_tie_list) do 
				assert(child.bonetie)
				assert(child.bonetie.iBone)
				table.insert(mBoneTies,child.bonetie)
			end
		end
		
		assert(pGrannyLoader.mBoneTies1)		-- std::vector<uint32>								mBoneTies1; // 0xCA5E0f04 && bRootParent_BoneTies	VisitBoneTieID	"id", parent=[0xCA5E0b01] = "boneTies1" -- bone_name_list ?
		assert(pGrannyLoader.mBoneTies2)		-- std::vector<uint32>								mBoneTies2; // 0XCA5E0C02 && bRootParent_BoneTies2	VisitBoneTies2 (boneObjPtrs?)	"bone_objptrs" parent=0XCA5E0C01=boneTies2
		assert(pGrannyLoader.mBoneTies)		-- std::vector<const GrannyBoneTie*>				mBoneTies;  // 0xCA5E0c0a && bRootParent_BoneTies2	VisitBoneTie							"bonetie"
		assert(pGrannyLoader.mMainParams)		-- std::map<int,std::map<std::string,std::string> >	VisitEOF
		--~ print("checkpoint one reached")
	end
	
	--~ local animbase = Object.animation_list.animation_sublist.animation        
	--~ MyIterGranny    root.Object.animation_list.animation_sublist.animation.animdata {fTotalTime=0.616667,pScaleTime=table: 0x9e42720,pQuaternionTime=table: 0x9e42080,hexdump=table: 0x9e44af0,iOffset=29560=0x7378,iChildren=0,pQuaternion=table: 0x9e42bf8,pAnim=table: 0x9e421a8,pRest=table: 0x9e44b18,pTranslateTime=table: 0x9e42450,pScale=table: 0x9e43990,iChunkType=0xca5e1204,pTranslate=table: 0x9e42748,}

    gProfiler_LuaGrannyWrapper:Section("animdata")
	
	if (Object.animation_list.animation_sublist.animation.animdata) then -- granny with animation tracks         
		--~ pGrannyLoader.mAnims = {} -- VisitGrannyAnim 0XCA5E1204
		local mAnims = {}
		pGrannyLoader.mAnims = mAnims
		for k,grnanim in ipairs(Object.animation_list.animation_sublist.animation.childs) do 
			local pAnim = {}
			table.insert(mAnims,pAnim)
			pAnim.mfTotalTime	= grnanim.fTotalTime
			pAnim.mpAnim		= grnanim.pAnim
			pAnim.mpQuaternionTime	= grnanim.pQuaternionTime
			pAnim.mpQuaternion		= grnanim.pQuaternion
			pAnim.mpTranslateTime	= grnanim.pTranslateTime
			pAnim.mpTranslate		= grnanim.pTranslate
			
			--~ assert(pAnim.mpAnim.iNumTranslate)
			--~ assert(pAnim.mpAnim.iNumQuaternion)
			--~ assert(pAnim.mpAnim.iID)
			--~ assert(ipairs(pAnim.mpQuaternionTime))
			--~ assert(ipairs(pAnim.mpTranslateTime))
			--~ assert(pAnim.mpQuaternion)
			--~ assert(pAnim.mpTranslate)
			--~ assert(pAnim.mfTotalTime)
			-- TODO : pScaleTime pScale pRest ? 
		end
		--~ MyIterGranny(Object,function (node,path) if (node.iChunkType == 0XCA5E1204) then print("MyIterGranny",path,SmartDump(node)) end end)
		--~ assert(pGrannyLoader.mAnims) -- GrannyAnim*
		--~ assert(pGrannyLoader.mBones) -- GrannyBone*
	end
	
    gProfiler_LuaGrannyWrapper:Section("rest2")
	if (Object.bones.skeleton.bonelist) then	   
		local mBones = {}
		pGrannyLoader.mBones = mBones
		for k,grnbone in ipairs(Object.bones.skeleton.bonelist.childs) do
			-- grnbone {iChildren=0,bone=table: 0x8fc8830,iChunkType=0xca5e0506,iOffset=32020=0x7d14,}
			local bone = grnbone.bone
			table.insert(mBones,bone)    
			--~ print("pGrannyBone",SmartDump(grnbone.bone,2)) -- {fTranslate=table: 0x9f664a0,fQuaternion=table: 0x9f66568,fMatrix=table: 0x9f65358,iParent=0,}
		end
		--~ MyIterGranny(Object,function (node,path) if (node.iChunkType == 0XCA5E0506) then print("MyIterGranny",path,SmartDump(node)) end end)
		
		assert(pGrannyLoader.mBones) -- VisitBone 0XCA5E0506 && bRootParent_SkeletonList
		--~ local pGrannyBone = mpGrannyLoader.mBones[iBoneID]       pGrannyBone.iParent  GetBoneRotate(pGrannyBone) pGrannyBone.fTranslate[0]   pGrannyBone.fQuaternion[3]
	end
	
	--- total number of different textchunk-blocks
	function pGrannyLoader:GetTextChunkCount	() return #self.mTextChunks end
	
	--- number of strings in one textchunk-block
	function pGrannyLoader:GetTextChunkSize		(chunkid) local chunk = self.mTextChunks[chunkid+1] return chunk and #chunk end
		
	-- retrieve a string from a textchunk-block
	function pGrannyLoader:GetText	(chunkid,stringid)
		local chunk = self.mTextChunks[chunkid+1]
		return chunk and chunk[stringid+1]
	end
	
	--- total number of different paramgroups
	function pGrannyLoader:GetParamGroupCount	() return #self.mParamGroups end
	
	--- number of pairs in one paramgroup
	function pGrannyLoader:GetParamGroupSize	(groupid)
		local group = self.mParamGroups[groupid+1]
		return group and #group.list
	end
	
	--- returns iKey,iValue
	--- retrieve a string from a textchunk-block
	function pGrannyLoader:GetParam				(groupid,paramid)
		local group = self.mParamGroups[groupid+1]	if (not group) then return end
		local param = group.list[paramid+1]			if (not param) then return end
		return param.first,param.second    
	end
	function pGrannyLoader:GetSubMeshCount		()		return #self.mSubMeshes end --- total number of different submeshes (usually 1)
	function pGrannyLoader:GetTextureIDCount	()		return #self.mTextureIDs end --~ 0xCA5E0f04		mTextureIDs
	function pGrannyLoader:GetTextureID			(index)	return self.mTextureIDs[index and (index+1) or 0] end
	
	
	
	-- returns sMeshName  (defaults to GetUniqueName())
	function pGrannyLoader:CreateOgreMesh (sMatName,sSkeletonName,sMeshName)
		sMeshName = sMeshName or GetUniqueName()
		if (LoadGrannyAsOgreMesh(self,sMatName,sMeshName,sSkeletonName)) then return sMeshName end
	end
		
	function pGrannyLoader:AddAnimToSkeleton (sSkeletonName,sAnimName,bodypartsamples)
		LoadGrannyAsOgreAnim(self,sSkeletonName,sAnimName,bodypartsamples)
	end
	
    gProfiler_LuaGrannyWrapper:End()
	return pGrannyLoader
end

