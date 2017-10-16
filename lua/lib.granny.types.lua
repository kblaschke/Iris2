

function GrannyFile_Global_DefineTypes () 
	cGrannyFile.kChunkType_Main = 0xCA5E0000
	cGrannyFile:DefineStructs()
	cGrannyFile:DefineTypeNames()
end

function cGrannyFile:DefineStructs ()
	self.structs = {}
	self.basetypes = {}
	local uint8		= {name="uint8"	,size=1,peekfun=FIFO_PeekUint8}
	local uint32	= {name="uint32",size=4,peekfun=FIFO_PeekUint32}
	local float		= {name="float"	,size=4,peekfun=FIFO_PeekFloat}
	self.basetypes.uint8	= uint8
	self.basetypes.uint32	= uint32
	self.basetypes.float	= float
	
	self.structs.MainChunk = {
		{uint8	,"mHeader",0x40};	--/< unknown, Could be FileType magic
		{uint32	,"iChunkType"},		--/< kChunkType
		{uint32	,"miChildCount"},
		{uint32	,"miUnknown",6},	--/< CRC?
	}

	self.structs.ItemList = {
		{uint32	,"iChunkType"},
		{uint32	,"miUnknown1"},
		{uint32	,"miListOffset"},
		{uint32	,"miUnknown2",2},
	}

	self.structs.ItemList_Header = {
		{uint32	,"miChildCount"},
		{uint32	,"miUnknown",3},
	}

	self.structs.WeightPair = {
		{uint32	,"iWeightBoneIndex"},
		{float	,"fWeight"},
	}
	self.structs.Vector = {
		{float	,"x"},
		{float	,"y"},
		{float	,"z"},
	}

	self.structs.Quaternion = {
		{float ,"x"},
		{float ,"y"},
		{float ,"z"},
		{float ,"w"},
		--~ {float ,"data",4},
		--~ --float	x,y,z,w"}, --/< order unknown, might also be x,y,z,w  (0,0,0,1 occurred, w=1 rest=0 is identity)
	}

	self.structs.Polygon = {
		--~ {uint32	,"iVertex1"},
		--~ {uint32	,"iVertex2"},
		--~ {uint32	,"iVertex3"},
		--~ {uint32	,"iNormal1"},
		--~ {uint32	,"iNormal2"},
		--~ {uint32	,"iNormal3"},
		{uint32	,"iVertex",3},
		{uint32	,"iNormal",3},
	}

	self.structs.TexturePolySmall = {
		{uint32	,"iUnknown"}, -- rising int, like 0 1 2 ... 13
	}
	
	self.structs.TexturePoly = {
		{uint32	,"iUnknown"},
		{uint32	,"iTexCoord",3},
		-- 4 uint32 : ? a b c
	}

	self.structs.TexturePolyBig = {
		{uint32	,"iUnknown"},
		{uint32	,"iTexCoord",6},
		-- 7 uint32 : ? ? a ? b ? c     : probably  polyindex, rgbA, uvwA, rgbB, uvwB, rgbC, uvwC  
	}

	self.structs.Bone = {
		{uint32	,"iParent"},
		{float	,"fTranslate",3},
		{float	,"fQuaternion",4},
		{float	,"fMatrix",9}, -- scale ? local coordinate axes ?
	}

	self.structs.TexInfo = {
		{uint32	,"iWidth"},
		{uint32	,"iHeight"},
		{uint32	,"iDepth"},
	}

	self.structs.BoneTie = {
		{uint32	,"iBone"},
		--~ --/ this might be initial position, translate:3f quaternion:4f 
		--~ --/ but doesn't look like floats in uo/Models/Others/H_Female_LLegs_V2_LOD2.grn
		{float	,"iUnknown",7}, 
	}

	self.structs.Anim = {
		{uint32	,"iID"},
		{uint32	,"iUnknownA",5}, --/< global pos/scale ?
		{uint32	,"iNumTranslate"},
		{uint32	,"iNumQuaternion"},
		{uint32	,"iNumScale"}, --/< unknown if this is really scale...
		{uint32	,"iUnknownB",4}, --/< global rot ?
	}
	self.size = {}
	for name,data in pairs(self.basetypes) do self.size[name] = data.size end
	for structname,struct in pairs(self.structs) do 
		local size = 0
		for k,member in pairs(struct) do 
			local basetype,name,arraysize = unpack(member)
			size = size + basetype.size * (arraysize or 1)
		end
		self.size[structname] = size
	end
end

gGrannyLuaQuickLoadStruct = {}
gGrannyLuaQuickLoadStruct_Array = {}

-- optimized function for often used types
function gGrannyLuaQuickLoadStruct_Array:Quaternion (offset,iArraySize)
	--~ print(_TRACEBACK())
	--~ os.exit(0)
	local quickfifo = self.quickfifo
	local res = {}
	local structsize = 16
	local num = floor(iArraySize/structsize)
	assert(offset >= 0,"AssertSize : negative offset : "..offset)
	assert(iArraySize == num*structsize) -- exact size check to detect parsing errors
	local missing = offset+structsize*num - self.miBufSize assert(missing <= 0,"AssertSize : buffer too small, expected "..missing.." more bytes miBufSize="..tostring(self.miBufSize).." structsize="..tostring(structsize))
	local peekfun = FIFO_PeekFloat
	for i=0,num-1 do
		table.insert(res,{
				x = peekfun(quickfifo,offset+0),
				y = peekfun(quickfifo,offset+4),
				z = peekfun(quickfifo,offset+8),
				w = peekfun(quickfifo,offset+12),
			})
		offset = offset + structsize
	end
	return res
end

-- optimized function for often used types
function gGrannyLuaQuickLoadStruct_Array:Vector (offset,iArraySize)
	local quickfifo = self.quickfifo
	local res = {}
	local structsize = 12
	local num = floor(iArraySize/structsize)
	assert(offset >= 0,"AssertSize : negative offset : "..offset)
	assert(iArraySize == num*structsize) -- exact size check to detect parsing errors
	local missing = offset+structsize*num - self.miBufSize assert(missing <= 0,"AssertSize : buffer too small, expected "..missing.." more bytes miBufSize="..tostring(self.miBufSize).." structsize="..tostring(structsize))
	local peekfun = FIFO_PeekFloat
	for i=0,num-1 do
		table.insert(res,{
				x = peekfun(quickfifo,offset+0),
				y = peekfun(quickfifo,offset+4),
				z = peekfun(quickfifo,offset+8),
			})
		offset = offset + structsize
	end
	return res
end

-- optimized function for often used types
function gGrannyLuaQuickLoadStruct:Quaternion (offset)
	assert(false,"SHOULDNT BE USED ANYMORE, USE gGrannyLuaQuickLoadStruct_Array:Quaternion INSTEAD!")
	local quickfifo = self.quickfifo
	local structsize = 16
	assert(offset >= 0,"AssertSize : negative offset : "..offset)
	local missing = offset+structsize - self.miBufSize assert(missing <= 0,"AssertSize : buffer too small, expected "..missing.." more bytes miBufSize="..tostring(self.miBufSize).." structsize="..tostring(structsize))
	local peekfun = FIFO_PeekFloat
	return {
		x = peekfun(quickfifo,offset+0),
		y = peekfun(quickfifo,offset+4),
		z = peekfun(quickfifo,offset+8),
		w = peekfun(quickfifo,offset+12),
	}
end

-- optimized function for often used types
function gGrannyLuaQuickLoadStruct:Vector (offset)
	local quickfifo = self.quickfifo
	local structsize = 12
	assert(offset >= 0,"AssertSize : negative offset : "..offset)
	local missing = offset+structsize - self.miBufSize assert(missing <= 0,"AssertSize : buffer too small, expected "..missing.." more bytes miBufSize="..tostring(self.miBufSize).." structsize="..tostring(structsize))
	local peekfun = FIFO_PeekFloat
	return {
		x = peekfun(quickfifo,offset+0),
		y = peekfun(quickfifo,offset+4),
		z = peekfun(quickfifo,offset+8),
	}
end

-- optimized function for often used types
function gGrannyLuaQuickLoadStruct:Bone (offset)
	local peekfunF = FIFO_PeekFloat
	local peekfunU = FIFO_PeekUint32
	local quickfifo = self.quickfifo
	local structsize = 68 -- = self.size.Bone
	assert(offset >= 0,"AssertSize : negative offset : "..offset)
	local missing = offset+structsize - self.miBufSize assert(missing <= 0,"AssertSize : buffer too small, expected "..missing.." more bytes miBufSize="..tostring(self.miBufSize).." structsize="..tostring(structsize))
	return {
		iParent = peekfunU(quickfifo,offset+4*0),
		fTranslate = {
			[0]=peekfunF(quickfifo,offset+4*1),
			[1]=peekfunF(quickfifo,offset+4*2),
			[2]=peekfunF(quickfifo,offset+4*3),
		},
		fQuaternion = {
			[0]=peekfunF(quickfifo,offset+4*4),
			[1]=peekfunF(quickfifo,offset+4*5),
			[2]=peekfunF(quickfifo,offset+4*6),
			[3]=peekfunF(quickfifo,offset+4*7),
		},
		fMatrix = {
			[0]=peekfunF(quickfifo,offset+4*8),
			[1]=peekfunF(quickfifo,offset+4*9),
			[2]=peekfunF(quickfifo,offset+4*10),
			
			[3]=peekfunF(quickfifo,offset+4*11),
			[4]=peekfunF(quickfifo,offset+4*12),
			[5]=peekfunF(quickfifo,offset+4*13),
			
			[6]=peekfunF(quickfifo,offset+4*14),
			[7]=peekfunF(quickfifo,offset+4*15),
			[8]=peekfunF(quickfifo,offset+4*16),
		},
	}
end

-- optimized function for often used types
function gGrannyLuaQuickLoadStruct:Anim (offset)
	local peekfun = FIFO_PeekUint32
	local quickfifo = self.quickfifo
	local structsize = 52 -- = self.size.Anim
	assert(offset >= 0,"AssertSize : negative offset : "..offset)
	local missing = offset+structsize - self.miBufSize assert(missing <= 0,"AssertSize : buffer too small, expected "..missing.." more bytes miBufSize="..tostring(self.miBufSize).." structsize="..tostring(structsize))
	return {
		iID = peekfun(quickfifo,offset+4*0),
		iUnknownA = {
			[0]=peekfun(quickfifo,offset+4*1),
			[1]=peekfun(quickfifo,offset+4*2),
			[2]=peekfun(quickfifo,offset+4*3),
			[3]=peekfun(quickfifo,offset+4*4),
			[4]=peekfun(quickfifo,offset+4*5),
		},
		iNumTranslate	= peekfun(quickfifo,offset+4*6),
		iNumQuaternion	= peekfun(quickfifo,offset+4*7),
		iNumScale		= peekfun(quickfifo,offset+4*8),
		iUnknownB = {
			[0]=peekfun(quickfifo,offset+4*9),
			[1]=peekfun(quickfifo,offset+4*10),
			[2]=peekfun(quickfifo,offset+4*11),
			[3]=peekfun(quickfifo,offset+4*12),
		},
	}
end

	
function cGrannyFile:DefineTypeNames ()
	self.kTypeNames = {}
	self.kTypeNames[0xCA5E0100] = "ML_SE_Texture" -- SiENcE:  Chunk is new to ML/SE Models maybe Texture: case 0xca5e0100
	self.kTypeNames[0xCA5E0101] = "final" -- Final Chunk (End-of-File?)	
	self.kTypeNames[0xCA5E0102] = "Copyright"
	self.kTypeNames[0xCA5E0103] = "Object"
	self.kTypeNames[0xCA5E0200] = "textChunk"
	self.kTypeNames[0xCA5E0304] = "texture_info_list"
	self.kTypeNames[0xCA5E0303] = "texinfo"
	self.kTypeNames[0xCA5E0301] = "texture_info"
	self.kTypeNames[0xCA5E0507] = "bones" -- SkeletonList?
	self.kTypeNames[0xCA5E0601] = "mesh"
	self.kTypeNames[0xCA5E0602] = "mesh_list"
	self.kTypeNames[0xCA5E0603] = "point_container"
	self.kTypeNames[0xCA5E0604] = "point_block"
	self.kTypeNames[0xCA5E0702] = "weights"

	self.kTypeNames[0xCA5E0801] = "points"
	self.kTypeNames[0xCA5E0802] = "normals"
	self.kTypeNames[0xCA5E0803] = "texcoords"
	self.kTypeNames[0xCA5E0804] = "texture_container"
	self.kTypeNames[0xCA5E0901] = "polygons"
	self.kTypeNames[0xCA5E0f04] = "id" -- depends on parent structure

	self.kTypeNames[0xCA5E0b00] = "boneobject" -- bone-name ??
	self.kTypeNames[0xCA5E0c00] = "boneties_container"
	self.kTypeNames[0xCA5E0c02] = "bone_objptrs"
	self.kTypeNames[0xCA5E0c03] = "bonetie_group"
	self.kTypeNames[0xCA5E0c04] = "bonetie_data"
	self.kTypeNames[0xCA5E0c05] = "end_bone_objptrs"
	self.kTypeNames[0xCA5E0c06] = "bonetie_container"
	self.kTypeNames[0xCA5E0c07] = "bone_objptrs_container"
	self.kTypeNames[0xCA5E0c08] = "bone_objptr"
	self.kTypeNames[0xCA5E0c09] = "bonetie_list"
	self.kTypeNames[0xCA5E0c0a] = "bonetie"
	self.kTypeNames[0xCA5E0505] = "skeleton"
	self.kTypeNames[0xCA5E0506] = "bone"
	self.kTypeNames[0xCA5E0508] = "bonelist"

	self.kTypeNames[0xCA5E0a01] = "unhandled_0a01"
	self.kTypeNames[0xCA5E0b01] = "boneTies1" -- bone_name_list ?
	self.kTypeNames[0xCA5E0c01] = "boneTies2"
	self.kTypeNames[0xCA5E0d01] = "unhandled_0d01"
	self.kTypeNames[0xCA5E0e00] = "texture"
	self.kTypeNames[0xCA5E0e01] = "texture_list"

	self.kTypeNames[0xCA5E0e02] = "texture_poly"
	self.kTypeNames[0xCA5E0e03] = "texture_poly_datalist"
	self.kTypeNames[0xCA5E0e04] = "texture_poly_data1"
	self.kTypeNames[0xCA5E0e05] = "texture_poly_data2"
	self.kTypeNames[0xCA5E0e06] = "texture_poly_list"
	self.kTypeNames[0xCA5E0e07] = "texture_sublist"

	self.kTypeNames[0xCA5E0f00] = "object"
	self.kTypeNames[0xCA5E0f01] = "object_key"
	self.kTypeNames[0xCA5E0f02] = "object_value"
	self.kTypeNames[0xCA5E0f03] = "object_list"
	self.kTypeNames[0xCA5E0f05] = "object_key_list"
	self.kTypeNames[0xCA5E0f06] = "object_value_list"
	self.kTypeNames[0xCA5E1003] = "unhandled_1003"

	self.kTypeNames[0xCA5E1200] = "animation_sublist"
	self.kTypeNames[0xCA5E1201] = "animation_data"
	self.kTypeNames[0xCA5E1203] = "animation"
	self.kTypeNames[0xCA5E1204] = "animdata"
	self.kTypeNames[0xCA5E1205] = "animation_list"

	self.kTypeNames[0xCA5Effff] = "end" 
	self.kTypeByName = FlipTable(self.kTypeNames)
end

GrannyFile_Global_DefineTypes()
