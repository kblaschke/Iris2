-- grannyogreloader.cpp ported to lua

--~ function	LoadGrannyAsOgreMesh	(pGrannyLoader,szMatName,szMeshName,szSkeletonName)
--~ function	LoadGrannyAsOgreAnim	(pGrannyLoader,szSkeletonName,szAnimName,lBodySamples)

function	QuatMult3		(a,b,c) return QuatMult(a,QuatMult(b,c)) end -- quaternion multiplication -- TODO : other order ? 
function	VectAdd			(a,b) return {a[1]+b[1],a[2]+b[2],a[3]+b[3]} end -- vector addition
function	VectScale		(s,v) return {s*v[1],s*v[2],s*v[3]} end -- vector scale

local myQMult = Quaternion.Mul
function	QuatMult		(a,b) -- quaternion multiplication
	local aw,ax,ay,az = unpack(a)
	local bw,bx,by,bz = unpack(b)
	return {myQMult(aw,ax,ay,az,bw,bx,by,bz)} 
end

local myQApply = Quaternion.ApplyToVector
function	QuadVectMult	(q,v)  -- apply quat to vector
	local qw,qx,qy,qz = unpack(q)
	local x,y,z = unpack(v)
	return {myQApply(x,y,z,qw,qx,qy,qz)} 
end

function	Quaternion_Inverse	(q) local w,x,y,z	= unpack(q) return {w,-x,-y,-z} end -- input must be unit length
function	Vector_Invert		(v) local x,y,z		= unpack(v) return {-x,-y,-z} end
function	Make_Ogre_Quaternion_IDENTITY	() return {1,0,0,0} end -- Ogre::Quaternion::IDENTITY
function	Make_Ogre_Vector3_ZERO			() return {0,0,0} end -- Ogre::Vector3::ZERO

function Ogre_Quaternion_Slerp (t,q1,q2,bShortestPath) -- Ogre::Quaternion::Slerp
	local qw,qx,qy,qz = unpack(q1)
	local pw,px,py,pz = unpack(q2)
	return {QuaternionSlerp(qw,qx,qy,qz, pw,px,py,pz, t, bShortestPath)}
end

function	GrannyToOgreQ	(qRot) return {qRot.w,qRot.x,qRot.y,qRot.z} end -- ogre:w,x,y,z  granny:x,y,z,w
function	GrannyToOgreV	(vPos) return {vPos.x,vPos.y,vPos.z} end

function	GetBoneTranslate	(pGrannyBone)
	return {	pGrannyBone and pGrannyBone.fTranslate[0] or 0,
				pGrannyBone and pGrannyBone.fTranslate[1] or 0,
				pGrannyBone and pGrannyBone.fTranslate[2] or 0}
end

function	GetBoneRotate		(pGrannyBone)
	return {	pGrannyBone and pGrannyBone.fQuaternion[3] or 1, -- ogre:w,x,y,z  granny:x,y,z,w
				pGrannyBone and pGrannyBone.fQuaternion[0] or 0,
				pGrannyBone and pGrannyBone.fQuaternion[1] or 0,
				pGrannyBone and pGrannyBone.fQuaternion[2] or 0 }
end

function	GetBoneDerivedRotation	(mpGrannyLoader,iBoneID)
	local pGrannyBone = mpGrannyLoader.mBones[iBoneID+1]
	if ((not pGrannyBone) or (pGrannyBone.iParent == iBoneID)) then return GetBoneRotate(pGrannyBone) end
	return QuatMult(GetBoneDerivedRotation(mpGrannyLoader,pGrannyBone.iParent),GetBoneRotate(pGrannyBone))
end

function	GetBoneDerivedTranslate	(mpGrannyLoader,iBoneID)
	local pGrannyBone = mpGrannyLoader.mBones[iBoneID+1]
	if ((not pGrannyBone) or (pGrannyBone.iParent == iBoneID)) then return GetBoneTranslate(pGrannyBone) end
	return VectAdd(GetBoneDerivedTranslate(mpGrannyLoader,pGrannyBone.iParent),QuadVectMult(GetBoneDerivedRotation(mpGrannyLoader,pGrannyBone.iParent),GetBoneTranslate(pGrannyBone)))
end


-- ***** ***** ***** ***** ***** cSubMeshConstructor

cSubMeshConstructor = CreateClass()
--~ int					miCurrentSubMesh
--~ int					miTargetSubMesh
--~ cGrannyLoader_i2*	mpGrannyLoader
--~ Ogre::MeshPtr&		mpMesh
--~ Ogre::SkeletonPtr&	mpSkeleton
--~ std::string			msMatName
--~ std::map<int,int>	mWeightBoneIndexMap ---< caches WeightBoneIndex2OgreBoneHandle results

function cSubMeshConstructor:Init	(pGrannyLoader,mpMesh,mpSkeleton,szMatName,miTargetSubMesh)
	self.mpGrannyLoader			= pGrannyLoader
	self.mpMesh					= mpMesh
	self.mpSkeleton				= mpSkeleton
	self.msMatName				= szMatName
	self.miCurrentSubMesh		= 0
	self.miTargetSubMesh		= miTargetSubMesh
	self.mWeightBoneIndexMap	= {}
	assert(self.mpGrannyLoader.mBoneTies)
end
	
--- translate weightindex to bone index using info from 0xCA5E0c0a (only in models, not in anims)
function cSubMeshConstructor:WeightBoneIndex2GrannyBoneID		(iWeightBoneIndex) return self.mpGrannyLoader:WeightBoneIndex2GrannyBoneID(iWeightBoneIndex) end
	
--- converts a boneindex from the granny vertex weights to an ogre bone index in the skeleton
--- returns -1 if not found
function cSubMeshConstructor:WeightBoneIndex2OgreBoneHandle	(iWeightBoneIndex)
	local o = self.mWeightBoneIndexMap[iWeightBoneIndex]
	if (o) then return o end
	
	local iBoneID = self:WeightBoneIndex2GrannyBoneID(iWeightBoneIndex)
	
	-- retrieves bone from skeleton (search by name)
	local sName = (iBoneID >= 0) and self.mpGrannyLoader:GetBoneName(iBoneID)
	local pBone = sName and self.mpSkeleton:SearchBoneByName(sName)
	
	-- get ogre bone handle/index
	local res = pBone and pBone:getHandle() or -1
	--printf("  WeightBoneIndex2OgreBoneHandle(%2d[%2d]) = %2d [%s]\n",iWeightBoneIndex,iBoneID,res,sName)
	self.mWeightBoneIndexMap[iWeightBoneIndex] = res
	return res
end

--~ --- used for multi indexing : miPosition,miNormal,miColor,miTexCoord
--~ class cMultiIndex { public:
	--~ int	a,b,c,d
	--~ cMultiIndex (int a,int b,int c=0,int d=0) : a(a), b(b), c(c), d(d) {}
--~ }
--~ struct cMultiIndexCmp {
  --~ bool operator() (const cMultiIndex x, const cMultiIndex y) const {
	--~ -- bugfix thanks to XShocK
	--~ return 		(x.a < y.a) ||
				--~ (x.a == y.a && x.b < y.b) ||
				--~ (x.a == y.a && x.b == y.b && x.c < y.c) ||
				--~ (x.a == y.a && x.b == y.b && x.c == y.c && x.d < y.d)
  --~ }
--~ }
	
--~ --- creates an Ogre::SubMesh and fills it with data
--~ void	operator ()	(cGrannyLoader_i2::cSubMesh& pLoaderSubMesh) {
function cSubMeshConstructor:Execute (pLoaderSubMesh)
	local i,j
	
	-- detect empty submesh
	if (#pLoaderSubMesh.mPolygons == 0) then return end
		
	self.miCurrentSubMesh = self.miCurrentSubMesh + 1
	if (self.miCurrentSubMesh - 1 ~= self.miTargetSubMesh) then return end -- multiple submeshes not yet supported
	
	--- if there was only one set of texcoord-or-color data, then it must have been texcoords
	if ((not pLoaderSubMesh.mTexCoords) and pLoaderSubMesh.mColors) then
		pLoaderSubMesh.mTexCoords = pLoaderSubMesh.mColors
		pLoaderSubMesh.mColors = nil
	end
	
	--[[
	printf("cSubMesh::ConstructSubMesh\n")
	printf("miID = %d\n",pLoaderSubMesh.miID)
	printf("miVertexDataCount = %d\n",pLoaderSubMesh.miVertexDataCount)
	printf("mPoints = %#08x %d\n",(int)pLoaderSubMesh.mPoints.first,pLoaderSubMesh.mPoints.second)
	printf("mNormals = %#08x %d\n",(int)pLoaderSubMesh.mNormals.first,pLoaderSubMesh.mNormals.second)
	printf("mColors = %#08x %d\n",(int)pLoaderSubMesh.mColors.first,pLoaderSubMesh.mColors.second)
	printf("mTexCoords = %#08x %d\n",(int)pLoaderSubMesh.mTexCoords.first,pLoaderSubMesh.mTexCoords.second)
	printf("mPolygons = %#08x %d\n",(int)pLoaderSubMesh.mPolygons.first,pLoaderSubMesh.mPolygons.second)
	]]--
	
	-- TODO : collect combos for single indices
	-- granny stores positions and normals seperately, ogre wants any combo of them as a single vertex
	-- so we have to search for all combos (pos,normal,color,texcoord)
	-- order for VertexDeclaration : position, blending weights, normals, diffuse colours, specular colours, texture coordinates
	
	
	local bUseSkeleton	= self.mpSkeleton and (pLoaderSubMesh.mWeights and #pLoaderSubMesh.mWeights > 0) -- (pLoaderSubMesh.mWeights).second > 0
	print("granny.anim: useskel,skel,weight,#weight",bUseSkeleton,self.mpSkeleton,pLoaderSubMesh.mWeights,pLoaderSubMesh.mWeights and #pLoaderSubMesh.mWeights)
	local bUseColors	= false and pLoaderSubMesh.mColors -- TODO_Get(pLoaderSubMesh.mColors).first -- not yet supported (see below)
	local bUseTexCoords	= pLoaderSubMesh.mTexCoords -- TODO_Get(pLoaderSubMesh.mTexCoords).first
	--~ typedef std::vector< std::pair<int,float> >		tMyBoneWeightList
	local myBoneWeights = {} -- std::vector<tMyBoneWeightList*>	myBoneWeights
	
	-- create submesh
	local sub = self.mpMesh:createSubMesh() -- Ogre::SubMesh*
	sub:setMaterialName(self.msMatName)
	sub:setUseSharedVertices(false)
	
	sub:setOperationType(OT_TRIANGLE_LIST)
	--~ sub:setOperationType(OT_POINT_LIST)
	
	-- prepare bone-weight data
	if (bUseSkeleton) then
		sub:clearBoneAssignments()
		-- WARNING ! buffersize not checked, but as long as the granny files are intakt thats ok
		-- foreach point : bonenum, index,weight, index,weight,... 
		for i,weightdata in ipairs(pLoaderSubMesh.mWeights) do 
			local iNumBones = weightdata.iNumBones
			
			local pBoneList = {} -- tMyBoneWeightList
			table.insert(myBoneWeights,pBoneList)
			
			for k,weight in ipairs(weightdata.list_pairs) do  -- iNumBones entries
				local		iWeightBoneIndex	= weight.iWeightBoneIndex	-- *(p++)	-- ::uint32        iWeightBoneIndex=22=0x16
				local		fWeight				= weight.fWeight			-- *(float*)(p++)	-- float        fWeight=1
				table.insert(pBoneList,{iWeightBoneIndex,fWeight})
			end
		end
	end
	
	local vb0 = cVertexBuffer:New()
	local vb1 = cVertexBuffer:New()
	local ib = cIndexBuffer:New()
	local combo_next_i = 0
	local combos = {}
	
	local polygons		= pLoaderSubMesh.mPolygons
	local texpolys		= pLoaderSubMesh.mTexturePolyLists -- wrong var ? recursive ?   mpGrannyLoader->GetTexIndex(i,j)
	local positions		= pLoaderSubMesh.mPoints
	local normals		= pLoaderSubMesh.mNormals
	local texcoords		= pLoaderSubMesh.mTexCoords
	-- assembling vertex-buffer, this block doesn't need ogre
	
	local rr = 0
	-- iterate over all polygon-vertices
	for k,poly in pairs(polygons) do 
		local texpoly = texpolys and texpolys[k] 
		--~ print("granny.anim.submesh texpolys texpoly",texpolys,texpoly,texpoly and texpoly.iTexCoord[0])
		for i=0,2 do 
			local pi = poly.iVertex[i] + 1
			local ni = poly.iNormal[i] + 1
			local ci = 0 --  = self.mpGrannyLoader:GetColorIndex(i,j) --- todo : for multiple submeshes add startoffset to i
			local ti = (texpoly and texpoly.iTexCoord[i] or 0) + 1 -- self.mpGrannyLoader:GetTexIndex(i,j)
			local comboname = pi..","..ni..","..ti
			local comboi = combos[comboname]
			if (not comboi) then 
				comboi = combo_next_i
				combo_next_i = combo_next_i + 1
				local p = positions[pi]	-- GrannyToOgreV(pLoaderSubMesh.mPoints.first[iP])
				local n = normals[ni]	-- GrannyToOgreV(pLoaderSubMesh.mNormals.first[iN])
				local x = p.x
				local y = p.y
				local z = p.z
				local dd = x*x + y*y + z*z
				if (dd > rr) then rr = dd end
				
				if (bUseSkeleton) then
					-- iterate over boneweights
					local myBoneWeightList = myBoneWeights[pi] -- tMyBoneWeightList
					if (myBoneWeightList) then
						for i,itor in ipairs(myBoneWeightList) do 
							local	iWeightBoneIndex 	= itor[1]
							local	w 					= itor[2]
							--~ local 	iGrannyBoneID 		= self:WeightBoneIndex2GrannyBoneID(iWeightBoneIndex)
							local	iOgreBoneHandle 	= self:WeightBoneIndex2OgreBoneHandle(iWeightBoneIndex)
							
							-- assign vertices to skeleton bones
							if (iOgreBoneHandle >= 0) then
								-- NOTE ! iOgreBoneHandle might refer to the animtrack handle instead of the bone handle, so best keep both equal
								sub:addBoneAssignment(comboi,iOgreBoneHandle,w)
							end
						end
					end
				end
				
				vb0:Vertex(	x,y,z, n.x,n.y,n.z)
				if (texcoords) then
					local t = texcoords[ti]
					vb1:Vertex(t.x,t.y)
				else
					vb1:Vertex(math.random(),math.random())
				end
				combos[comboname] = comboi
				--~ if (iComboVertexCount == 1) { vMin = pLoaderSubMesh.mPoints.first[iP] vMax = pLoaderSubMesh.mPoints.first[iP] }
				--~ vMin = mymin(vMin,p)
				--~ vMax = mymax(vMax,p)
			end
			ib:Index(comboi)
		end
	end
	vb0:CheckSize()
	vb1:CheckSize()
	local fSquareRadius = rr
	
	local vertexData = CreateVertexData()
	local indexData = CreateIndexData()
	sub:setVertexData(vertexData)
	sub:setIndexData(indexData)
	
	local vdecl = cVertexDecl:New()
	vdecl:addElement(0,VET_FLOAT3,VES_POSITION)
	vdecl:addElement(0,VET_FLOAT3,VES_NORMAL)
	vdecl:addElement(1,VET_FLOAT2,VES_TEXTURE_COORDINATES)
	--~  TODO : if (bUseColors)		offset += decl.addElement(0, offset, VET_COLOUR, VES_DIFFUSE).getSize()      autoorganize position!!!
	
	vertexData:setVertexDecl(vdecl:GetOgreVertexDecl())
	vertexData:createAndBindVertexBuffer(vb0:GetVertexSize(),vb0:GetVertexNum(),HBU_DYNAMIC_WRITE_ONLY,false,0) -- (iVertexSize,iNumVerts,iUsage,bUseShadowBuffer=false,iBindIndex=0)
	vertexData:createAndBindVertexBuffer(vb1:GetVertexSize(),vb1:GetVertexNum(),HBU_DYNAMIC_WRITE_ONLY,false,1) -- (iVertexSize,iNumVerts,iUsage,bUseShadowBuffer=false,iBindIndex=0)
	indexData:createAndBindIndexBuffer(IT_32BIT,ib:GetIndexNum(),HBU_STATIC_WRITE_ONLY) -- (iIndexType,iNumIndexes,iUsage,bUseShadowBuffer=false)
	-- old c++ grannyogreloader used IT_16BIT
	
	vertexData:setVertexStart(0)
	indexData:setIndexStart(0)
	vertexData:setVertexCount(vb0:GetVertexNum())
	indexData:setIndexCount(ib:GetIndexNum())
	
	vertexData:writeToVertexBuffer(vb0:GetFIFO(),0)
	vertexData:writeToVertexBuffer(vb1:GetFIFO(),1)
	indexData:writeToIndexBuffer(ib:GetFIFO()) 
	
	--~ calculate bounds,  todo : calc for whole mesh, not only for this submesh
	local r = math.sqrt(fSquareRadius)
	self.mpMesh:_setBounds({-r,-r,-r,r,r,r},false)
	self.mpMesh:_setBoundingSphereRadius(r)
	
	vb0:Destroy()
	vb1:Destroy()
	ib:Destroy()
end



-- ***** ***** ***** ***** ***** LoadGrannyAsOgreMesh


--~ function	LoadGrannyAsOgreMesh	(cGrannyLoader_i2* pGrannyLoader,const char* szMatName,const char* szMeshName,const char* szSkeletonName) {
function	LoadGrannyAsOgreMesh	(pGrannyLoader,szMatName,szMeshName,szSkeletonName)
	local bIsEmptyMesh = true
	local bHasBoneWeights = false
	for k,sub in ipairs(pGrannyLoader.mSubMeshes) do -- pGrannyLoader.mSubMeshes.size()
		if (sub.mWeights and #sub.mWeights > 0) then bHasBoneWeights = true end
		if (sub.mPolygons and #sub.mPolygons > 0) then bIsEmptyMesh = false end
	end
	
	--printf("LoadGrannyAsOgreMesh %s, submesh=%d\n",pGrannyLoader.mGranny.msFilePath,pGrannyLoader.mSubMeshes.size())
	
	-- don't construct empty meshes
	if (bIsEmptyMesh) then return false end
		
	-- get mesh
	local pMesh = MeshManager_createManual(szMeshName) -- 	Ogre::MeshPtr

	-- init in case there are no submeshes
	pMesh:_setBounds({0,0,0,0,0,0},true)
	pMesh:_setBoundingSphereRadius(0)

	
	print("granny.anim:LoadGrannyAsOgreMesh:bHasBoneWeights=",bHasBoneWeights,szSkeletonName)
	local pSkeleton -- Ogre::SkeletonPtr
	-- assign skeleton only if there are BoneWeights
	if (bHasBoneWeights) then
		-- get skeleton
		pSkeleton = SkeletonManager_load(szSkeletonName) -- todo : try catch ?
		
		-- assign skeleton to mesh
		if (pSkeleton) then pMesh:setSkeletonName(pSkeleton:getName()) end
	end
		
	--printf("cGrannyVisitor_OgreLoader::ConstructSubMeshes %d submeshes found\n",pGrannyLoader.mSubMeshes.size())
	local o = cSubMeshConstructor:New(pGrannyLoader,pMesh,pSkeleton,szMatName,0)
	for k,sub in ipairs(pGrannyLoader.mSubMeshes) do o:Execute(sub) end
	
	--Pose * 	Mesh::createPose (ushort target, const String &name=StringUtil::BLANK)
	--void 	Mesh::setSkeletonName (const String &skelName)
	--myVisitor.mpMesh._setBounds(mAABB)
	--myVisitor.mpMesh._setBoundingSphereRadius(mRadius)
	pMesh:load(false)
	return true
end

-- ***** ***** ***** ***** ***** cAnimationTotalTimeConstructor

--- searches for the maximum total time required for the animation
cAnimationTotalTimeConstructor = CreateClass()

function cAnimationTotalTimeConstructor:Init (mfTotalTime)
	self.mfTotalTime = mfTotalTime
end
function cAnimationTotalTimeConstructor:Execute (pAnim) -- cGrannyLoader_i2::cAnim
	if (self.mfTotalTime < pAnim.mfTotalTime) then
		self.mfTotalTime = pAnim.mfTotalTime
	end
end

-- ***** ***** ***** ***** ***** cAnimationConstructor

--- constructs the animation and the bones used by it
cAnimationConstructor = CreateClass()
--~ int					miCurrentSubMesh
--~ std::vector<cGrannyLoader_i2*>& mlBodySamples
--~ cGrannyLoader_i2*	mpGrannyLoader
--~ Ogre::SkeletonPtr&	mpSkeleton
--~ Ogre::Animation* 	mpAnim
--~ int					miAnimDataCounter

function cAnimationConstructor:Init (pGrannyLoader,mpSkeleton,mpAnim,mlBodySamples)
	self.mpGrannyLoader			= pGrannyLoader
	self.mpSkeleton				= mpSkeleton
	self.mpAnim					= mpAnim -- Ogre::Animation*
	self.mlBodySamples			= mlBodySamples
	self.miAnimDataCounter		= 0
	self.miCurrentSubMesh		= 0
end
	
	--- param must be lowercased
function cAnimationConstructor:GetSampleBone	(sBoneName) -- returns GrannyBone
	for k,sample in ipairs(self.mlBodySamples) do 
		local iBoneID = sample:FindBone(sBoneName)
		local bone = sample.mBones[iBoneID+1]
		if (bone) then return bone end
	end
end

--- recursive : creates parent hierarchy if needed
function cAnimationConstructor:GetOrCreateBone	(iBoneID) -- returns Ogre::Bone*
	if (iBoneID < 0 or iBoneID >= #self.mpGrannyLoader.mBones) then return 0 end  -- TODO:LUA SIZE WRONG ??? 
	local sName = self.mpGrannyLoader:GetBoneName(iBoneID)
	if (sName == "") then
		print("warning, unnamed bone id=%d\n",iBoneID)
		return 0
	end
	
	-- check if bone already exists
	local pBone = self.mpSkeleton:SearchBoneByName(sName) -- Ogre::Bone*
	if (pBone) then return pBone end
	
	-- create bone
	pBone = self.mpSkeleton:createBone3(sName)
	local pGrannyBone = self.mpGrannyLoader.mBones[iBoneID+1] -- const GrannyBone*
	
	-- child bone : attach to parent
	local iParent = pGrannyBone.iParent
	if (iParent ~= iBoneID) then
		local pParent = self:GetOrCreateBone(iParent) -- Ogre::Bone*
		if (not pParent) then print("cannot find parent bone %d\n",iParent) end
		if (pParent) then pParent:addChild(pBone) end
	end
	
	
	-- set translation and rotation
	local iBoneStartMode = 3 -- 0:none 1:normal 2:invert 3:sample 4:sample-invert
	local iRetranslateMode = 0 -- 0:nothin 1:R 2:L 3:-R 4:-L
	local iTransformSpaceModeT = 1
	local iTransformSpaceModeR = 0 
	local iRotateFirst = 0 
	--cScripting::GetSingletonPtr().LuaCall("GrannyBoneStart",">iiiii",&iBoneStartMode,&iRetranslateMode,&iTransformSpaceModeT,&iTransformSpaceModeR,&iRotateFirst)
	
	
	if (iBoneStartMode > 2) then
		local pSampleBone = self:GetSampleBone(sName) -- const GrannyBone*
		if (pSampleBone) then pGrannyBone = pSampleBone end
		iBoneStartMode = iBoneStartMode - 2
	end
	
	--Ogre::Vector3 v = GetBoneTranslate(pGrannyBone)
	--Ogre::Quaternion q = GetBoneRotate(pGrannyBone)
	local v = GetBoneTranslate(pGrannyBone) -- Ogre::Vector3
	local q = GetBoneRotate(pGrannyBone) -- Ogre::Quaternion
	
	if (iRetranslateMode == 1) then v = QuadVectMult(q,v) end
	if (iRetranslateMode == 2) then v = Quaternion_Inverse(q) * v end
	
	
	local iTransformSpaceT -- Ogre::Node::TransformSpace
	local iTransformSpaceR -- Ogre::Node::TransformSpace
	if (iTransformSpaceModeT == 0) then iTransformSpaceT = TS_LOCAL end -- Ogre::Node::
	if (iTransformSpaceModeT == 1) then iTransformSpaceT = TS_PARENT end -- default
	if (iTransformSpaceModeT == 2) then iTransformSpaceT = TS_WORLD end
	if (iTransformSpaceModeR == 0) then iTransformSpaceR = TS_LOCAL end -- default
	if (iTransformSpaceModeR == 1) then iTransformSpaceR = TS_PARENT end
	if (iTransformSpaceModeR == 2) then iTransformSpaceR = TS_WORLD end
	
	if (iBoneStartMode == 1) then
		if (iRotateFirst ~= 0) then pBone:rotate2(q,iTransformSpaceR) end
		pBone:translate(v,iTransformSpaceT)
		if (iRotateFirst == 0) then pBone:rotate2(q,iTransformSpaceR) end
	end
	if (iBoneStartMode == 2) then
		if (iRotateFirst ~= 0) then pBone:rotate2(Quaternion_Inverse(q),iTransformSpaceR) end
		pBone:translate(Vector_Invert(v),iTransformSpaceT)
		if (iRotateFirst == 0) then pBone:rotate2(Quaternion_Inverse(q),iTransformSpaceR) end
	end
	-- granny rotation is often (   0.000,   0.000,   0.000,   1.000) , so probably x,y,z,w
	-- void Ogre::Bone::setScale  	(   	const Vector3 &   	 scale  	 )
	
	return pBone
end
	
	--- constructs the animation
function cAnimationConstructor:Execute (pAnim) -- cGrannyLoader_i2::cAnim
	--printf("cAnimationConstructor::miCurrentSubMesh = %d\n",miCurrentSubMesh)
	self.miCurrentSubMesh = self.miCurrentSubMesh + 1
	
	local iCurAnimDataNum = self.miAnimDataCounter		self.miAnimDataCounter = self.miAnimDataCounter + 1
	local iCurBoneNum = self.mpGrannyLoader:FindBone(self.mpGrannyLoader:GetBoneName2(pAnim.mpAnim.iID-1))
	local pBone = self:GetOrCreateBone(iCurBoneNum) -- Ogre::Bone*
	if (not pBone) then print("WARNING : cannot find bone for animation %d\n",iCurBoneNum) return end
	
	local iOgreBoneHandle = pBone and pBone:getHandle() or 0 -- IMPORTANT !!!!! (this was THE big anim bug)
	if (self.mpAnim:hasNodeTrack(iOgreBoneHandle)) then
		--~ print("granny","granny:cAnimationConstructor : two anim tracks for the same bone ? %d %s\n",iCurBoneNum,self.mpGrannyLoader:GetBoneName2(pAnim.mpAnim.iID-1))
		return
	end
	
	local pTrack -- Ogre::NodeAnimationTrack*
	if (self.mpAnim:hasNodeTrack(iOgreBoneHandle)) then
		-- idea thanks to XShocK
		pTrack = self.mpAnim:getNodeTrack(iOgreBoneHandle)
		print("granny","warning, two anim-data nodes for the same bone : %s!\n",pBone:getName())
	else
		pTrack = self.mpAnim:createNodeTrack(iOgreBoneHandle,pBone)
	end
	
	local pGrannyBone = self.mpGrannyLoader.mBones[iCurBoneNum+1] -- const GrannyBone*
	assert(pGrannyBone)
	local pOrigGrannyBone = pGrannyBone -- const GrannyBone*
	local pSampleBone = self:GetSampleBone(pBone:getName()) -- const GrannyBone*
	--assert(pSampleBone)
	--printf("GetSampleBone(%s) = %#010x\n",pBone.getName(),pSampleBone)
	
	
	--[[
	Ogre::Bone* pParentBone = GetOrCreateBone(pGrannyBone.iParent)
	printf(" index:%2d bonehandle:%2d grannyid:%2d parent=%2d name=%23s parentname=%23s\n",
		iCurBoneNum,
		pBone.getHandle(),
		pAnim.mpAnim.iID,
		pGrannyBone.iParent,
		pBone.getName(),
		pParentBone ? pParentBone.getName() : ""
		)
	]]--
	
	-- TODO : UNKNOWN pAnim.mpAnim.iID usage !?! (maybe bone id ??)
	
	-- some assert to detect unusual values (and find out what they mean)
	-- unknownA:  0  1  2  2  1
	-- unknownB:  0  1  2  0
	--[[
	assert(pAnim.mpAnim.iUnknownA[0] == 0)
	assert(pAnim.mpAnim.iUnknownA[1] == 1)
	assert(pAnim.mpAnim.iUnknownA[2] == 2)
	assert(pAnim.mpAnim.iUnknownA[3] == 2)
	assert(pAnim.mpAnim.iUnknownA[4] == 1)
	assert(pAnim.mpAnim.iUnknownB[0] == 0)
	assert(pAnim.mpAnim.iUnknownB[1] == 1)
	assert(pAnim.mpAnim.iUnknownB[2] == 2)
	assert(pAnim.mpAnim.iUnknownB[3] == 0)
	]]--
	
	--printf(" bone=%02d t=%5.3f q=(x=%f y=%f z=%f w=%f)\n",iCurBoneNum,0.0,q0.x,q0.y,q0.z,q0.w)
	local q0i = Make_Ogre_Quaternion_IDENTITY()
	local q0j = Make_Ogre_Quaternion_IDENTITY()
	local t0i = Make_Ogre_Vector3_ZERO()	
	local iAnimInvertMode = 1 -- 0:nothin 1:it 2:jt
	local iRetranslateMode = 0 -- 0:nothin 1:R 2:L 3:-R 4:-L
	--cScripting::GetSingletonPtr().LuaCall("AnimInvertMode",">ii",&iAnimInvertMode,&iRetranslateMode)
	
	local t0 = GetBoneTranslate((pSampleBone and iAnimInvertMode < 5) and pSampleBone or pGrannyBone) -- Ogre::Vector3
	local q0 = GetBoneRotate((pSampleBone and iAnimInvertMode < 5) and pSampleBone or pGrannyBone) -- Ogre::Quaternion
	local t5 = GetBoneTranslate(pOrigGrannyBone) -- Ogre::Vector3
	local q5 = GetBoneRotate(pOrigGrannyBone) -- Ogre::Quaternion
	if (iAnimInvertMode >= 5) then iAnimInvertMode = iAnimInvertMode - 5 end
	
	if (iAnimInvertMode > 0) then t0i = Vector_Invert(t0) end
	if (iAnimInvertMode == 1) then q0i = Quaternion_Inverse(q0) end
	if (iAnimInvertMode == 2) then q0j = Quaternion_Inverse(q0) end
	if (iAnimInvertMode == 3) then q0i = q0 end
	if (iAnimInvertMode == 4) then q0j = q0 end
	
	-- convert multi-timeline granny animdata to single-timeline ogre animdata by linear interpolation
	local i
	local fTestTime,fBeforeTime,fNextTime
	local fCurTime = 0.0
	while (true) do
		local bDebugHack_OnlyFirst = false
		
		-- calc rotation at fCurTime
		local qo = Make_Ogre_Quaternion_IDENTITY() -- Ogre::Quaternion
		if (pAnim.mpAnim.iNumQuaternion > 0) then
			local i,fTestTime
			for k,t in ipairs(pAnim.mpQuaternionTime) do -- pAnim.mpAnim.iNumQuaternion
				i = k 
				fTestTime = t
				if (fTestTime >= fCurTime) then break end
				fBeforeTime = fTestTime
			end
			if (bDebugHack_OnlyFirst) then i = 1 end
			if (i > pAnim.mpAnim.iNumQuaternion) then
				-- after last frame
				qo = GrannyToOgreQ(pAnim.mpQuaternion[pAnim.mpAnim.iNumQuaternion])
			elseif (i == 1 or fTestTime == fCurTime) then
				-- before first frame or exact time-match frame
				qo = GrannyToOgreQ(pAnim.mpQuaternion[i])
				--printf(" bone=%02d t=%5.3f q=(x=%f y=%f z=%f w=%f)\n",iCurBoneNum,fCurTime,q.x,q.y,q.z,q.w)
			else
				-- interpolate between two frames
				local t = (fTestTime > fBeforeTime) and ((fCurTime - fBeforeTime) / (fTestTime - fBeforeTime)) or 0.0
				qo = Ogre_Quaternion_Slerp(t,GrannyToOgreQ(pAnim.mpQuaternion[i-1]),GrannyToOgreQ(pAnim.mpQuaternion[i]),true)
			end
		end
		
		-- calc translation at fCurTime
		local vt0 = Make_Ogre_Vector3_ZERO()
		if (pAnim.mpAnim.iNumTranslate > 0) then
			local i,fTestTime
			for k,t in ipairs(pAnim.mpTranslateTime) do -- pAnim.mpAnim.iNumTranslate
				i = k
				fTestTime = t
				if (fTestTime >= fCurTime) then break end
				fBeforeTime = fTestTime
			end
			if (bDebugHack_OnlyFirst) then i = 1 end
			if (i > pAnim.mpAnim.iNumTranslate) then
				-- after last frame
				vt0 = GrannyToOgreV(pAnim.mpTranslate[pAnim.mpAnim.iNumTranslate])
			elseif (i == 1 or fTestTime == fCurTime) then
				-- before first frame or exact time-match frame
				vt0 = GrannyToOgreV(pAnim.mpTranslate[i])
			else
				-- interpolate between two frames
				local t = (fTestTime > fBeforeTime) and ((fCurTime - fBeforeTime) / (fTestTime - fBeforeTime)) or 0.0
				vt0 = VectAdd( VectScale((1.0 - t) , GrannyToOgreV(pAnim.mpTranslate[i-1])) , VectScale(t , GrannyToOgreV(pAnim.mpTranslate[i])) )
			end
		end
		
		local q1i = Make_Ogre_Quaternion_IDENTITY()
		local q = QuatMult3(q0i , qo , q0j) -- Ogre::Quaternion
		-- int iRetranslateMode = 0 -- 0:nothin 1:q 2:q.Inverse()
		if (iRetranslateMode == 1) then q1i = q end
		if (iRetranslateMode == 2) then q1i = Quaternion_Inverse(q) end
		if (iRetranslateMode == 3) then q1i = qo end
		if (iRetranslateMode == 4) then q1i = Quaternion_Inverse(qo) end
		
		
		--q0i = q5 * q0i * q5.Inverse()
		--q0i = q5.Inverse() * q0i * q5
		-- create new keyframe
		--printf(" create new keyframe at time %f trans=%d quat=%d\n",fCurTime,pAnim.mpAnim.iNumTranslate,pAnim.mpAnim.iNumQuaternion)
		local pKeyFrame = pTrack:createNodeKeyFrame(fCurTime) -- Ogre::TransformKeyFrame*
		pKeyFrame:setRotation(QuatMult3(q0i , qo , q0j))
		pKeyFrame:setTranslate(VectAdd(t0i , QuadVectMult(q1i , vt0)))
		
		-- todo : scale currently ignored
		--pKeyFrame.setScale  	(   	const Vector3 &   	 scale  	 )
		-- GrannyVector* 	pAnim.mpScale   pAnim.mpAnim.iNumScale
		
		
		-- find minimal time bigger than fCurTime
		local bFound = false
		
		for k,fTestTime in ipairs(pAnim.mpTranslateTime) do -- pAnim.mpAnim.iNumTranslate
			--printf("  t-time:%f\n",fTestTime)
			if (fTestTime > fCurTime and ((not bFound) or fNextTime > fTestTime)) then fNextTime = fTestTime bFound = true end
		end
		for k,fTestTime in ipairs(pAnim.mpQuaternionTime) do -- pAnim.mpAnim.iNumQuaternion
			--printf("  q-time:%f\n",fTestTime)
			if (fTestTime > fCurTime and ((not bFound) or fNextTime > fTestTime)) then fNextTime = fTestTime bFound = true end
		end
		if (not bFound) then break end -- nothing found, end of anim
		fCurTime = fNextTime
		if (bDebugHack_OnlyFirst) then break end
	end
end

-- ***** ***** ***** ***** ***** cAnimationConstructor

--~ void	LoadGrannyAsOgreAnim	(cGrannyLoader_i2* pGrannyLoader, const char* szSkeletonName,const char* szAnimName,std::vector<cGrannyLoader_i2*> &lBodySamples) {
function	LoadGrannyAsOgreAnim	(pGrannyLoader,szSkeletonName,szAnimName,lBodySamples)
	
	--printf("LoadGrannyAsOgreAnim %s\n",pGrannyLoader.mGranny.msFilePath)
	
	local pSkeleton = SkeletonManager_load(szSkeletonName) -- Ogre::SkeletonPtr
	if (not pSkeleton) then return end
	
	-- calc total time
	local fTotalTime = 0
	local o = cAnimationTotalTimeConstructor:New(fTotalTime)
	for k,anim in ipairs(pGrannyLoader.mAnims) do o:Execute(anim) end
	fTotalTime = o.mfTotalTime
	--printf("LoadGrannyAsOgreAnim name=%s total_bone_anims=%d totaltime=%f samplebodyparts=%d\n",szAnimName,pGrannyLoader.mAnims.size(),fTotalTime,lBodySamples.size())
	local pOgreAnim = pSkeleton:createAnimation(szAnimName,fTotalTime) -- in seconds	    Ogre::Animation*
	
	-- construct anims
	local o = cAnimationConstructor:New(pGrannyLoader,pSkeleton,pOgreAnim,lBodySamples)
	for k,anim in ipairs(pGrannyLoader.mAnims) do o:Execute(anim) end
	--	pSkeleton.load()
	
	--Ogre::Skeleton::BoneIterator itor = pSkeleton.getBoneIterator()
	--while (itor.hasMoreElements()) printf(" + %s\n",itor.getNext().getName())
end


