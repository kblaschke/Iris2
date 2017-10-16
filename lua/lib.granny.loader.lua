-- redesign of grannyloader in lua
-- start with -grannytest   ->StartGrannyTest()
--~ ./start.sh -sdg         (console output)
--~ ./start.sh -sdg -res 640x480 -maxfps 20
--~ lib.granny.debug.lua

--[[

ogre skeletal anim shader : hardware accelleration : 
/usr/src/ogre_branch_v16/Samples/Media/materials/scripts/Example.material:1519:material jaiqua
// Report whether hardware skinning is enabled or not
Technique* t = ent->getSubEntity(0)->getMaterial()->getBestTechnique();
Pass* p = t->getPass(0);
if (p->hasVertexProgram() && p->getVertexProgram()->isSkeletalAnimationIncluded())

src/grannydump.cpp
src/granny_L.cpp
src/grannyloader_i2.cpp
src/grannyogreloader.cpp
src/grannyparser.cpp
include/grannyloader_i2.h
include/grannyogreloader.h
include/grannyparser.h
]]--

cGrannyFile = cGrannyFile or CreateClass()

dofile(libpath .. "lib.granny.anim.lua")
dofile(libpath .. "lib.granny.types.lua")

function GrannyTest_PreOgreInit () 
	GrannyTest_PreOgreInit2()
	gDebugCategories["granny"] = true
	local folderpath = "/cavern/uoml/Models/Monsters/"
	local arr_dirs	= dirlist(folderpath,true,false)
	local arr_files	= dirlist(folderpath,false,true)
	table.sort(arr_dirs)
	table.sort(arr_files)
	for k,filename in pairs(arr_files) do
		cGrannyFile:LoadFile(folderpath..filename)
	end
	os.exit(0)
end
function StartGrannyTest () 
	
end

function cGrannyFile:_CreateAndLoadFIFO () 
	if (self.fifo) then return end -- still open
	local fifo = CreateFIFO()
	fifo:Clear()
	fifo:ReadFromFile(self.filepath)
	self.fifo = fifo
end
function cGrannyFile:_FreeFIFO () 
	if (self.fifo) then self.fifo:Destroy() self.fifo = nil end
end
function cGrannyFile:LoadFile (filepath) 
	print("cGrannyFile:LoadFile",filepath) -- print(GetStackTrace())
	self.filepath = filepath
	--~ local t1 = Client_GetTicks()
	self:_CreateAndLoadFIFO()
	--~ local t2 = Client_GetTicks()
	local bOK = self:Parse(self.fifo)
	--~ local t3 = Client_GetTicks()
	self:_FreeFIFO()
	--~ local t4 = Client_GetTicks()
	--~ print("cGrannyFile:LoadFile profile: total,fifo,parse,free=",t4-t1,t2-t1,t3-t2,t4-t3,filepath)
	return bOK
end

-- allow access like grn.pMainChunk.Object.mesh_list.mesh.point_block.point_container.points.list_points  
function cGrannyFile:MetaIndex (typename) 
	local typeid = cGrannyFile.kTypeByName[typename]
	--~ print("cGrannyFile:MetaIndex",self,typename,typeid) 
	if (typeid and self.childs) then for k,obj in ipairs(self.childs) do if (obj.iChunkType == typeid) then return obj end end end -- self is not a cGrannyFile here
end
cGrannyFile.pItemMetaTable = { __index = cGrannyFile.MetaIndex }

function cGrannyFile:XMLDump (filepath) 
	local ignoredkeys = { childs=true,hexdump=true,iChunkType=true,childsleft=true,iChildren=true,iOffset=true }
	--~ function MyDumpObjList (node,k,v) for k2,obj in pairs(v) do XMLNodeAddChild(node,{name=k,attr={bla=SmartDump(obj)}}) end end
	function MyToString (v)
		if (type(v) == "table") then
			return SmartDump(v)
		else
			return tostring(v)
		end 
	end
	function MyObj2XMLAttri (obj) 
		local res = {}
		for k,v in pairs(obj) do res[tostring(k)] = MyToString(v) end 
		return res 
	end
	function MyDumpValueList (node,k,v) 
		local subnode = {name=k} XMLNodeAddChild(node,subnode)
		for k2,text in ipairs(v) do XMLNodeAddChild(subnode,{name="entry",n=1,[1]=MyToString(text)}) end 
	end
	function MyDumpObjList (node,k,v) 
		local subnode = {name=k} XMLNodeAddChild(node,subnode)
		for k2,obj in ipairs(v) do XMLNodeAddChild(subnode,{name="entry",attr=MyObj2XMLAttri(obj)}) end 
	end
	function MyDumpObj (node,k,obj) XMLNodeAddChild(node,{name=k,attr=MyObj2XMLAttri(obj)}) end
	local customs = {
		texts=MyDumpValueList,
		list_points		=MyDumpObjList,
		list_normals	=MyDumpObjList,
		list_polygons	=MyDumpObjList, 
		list_texcoords	=MyDumpObjList, 
		list_weights	=MyDumpObjList, 
		list_texpoly		=MyDumpObjList, 
		list_texpoly_small	=MyDumpObjList, 
		list_texpoly_normal	=MyDumpObjList, 
		list_texpoly_big	=MyDumpObjList, 
		pRest			=MyDumpValueList,
		pTranslateTime	=MyDumpValueList,
		pQuaternionTime	=MyDumpValueList,
		pScaleTime		=MyDumpValueList, 
		pTranslate		=MyDumpObjList, 
		pQuaternion		=MyDumpObjList, 
		pScale			=MyDumpObjList, 
	}
	self:_CreateAndLoadFIFO()
	local quickfifo = self.fifo and self.fifo:GetQuickHandle()
	function MyHexDumpNode (offset,len) 
		local node = {name="hexdump",attr={offset=offset,len=len}}
		local pos = 0
		if (quickfifo) then 
			while (len > 0) do 
				local partlen = min(len,16)
				local hex	= ""
				local asci	= ""
				for i=1,16 do 
					if (i <= partlen) then 
						local c = FIFO_PeekUint8(quickfifo,offset+pos+i)
						hex = hex .. sprintf("%02x ",c)
						asci = asci .. ((c >= 32 and c < 128) and sprintf("%c",c) or "?")
					else 
						hex = hex .. "   "
					end
					if (i == 8) then hex = hex .. " " end
				end
				XMLNodeAddChild(node,{name="hexline",attr={pos=sprintf("0x%04x",pos)},n=1,[1]=hex..asci})
				len = len - partlen
				pos = pos + partlen
			end
		end
		return node
	end
	function MyNode (tagname,obj)
		local attr = {}
		local node = {name=tagname,attr=attr}
		for k,v in pairs(obj) do 
			local custom = customs[k]
			if (custom) then 
				custom(node,k,v)
			elseif (not ignoredkeys[k]) then 
				if (type(v) == "table") then MyDumpObj(node,k,v) else attr[k] = tostring(v) end
			end
		end
		if (obj.childs) then 
			for k,v in ipairs(obj.childs) do 
				local chunktype = v.iChunkType
				local name = (chunktype and (self.kTypeNames[chunktype] or ("unknown_"..hex(chunktype)))) or "unknown"
				XMLNodeAddChild(node,MyNode(name,v))
			end
		end
		local hexdump = obj.hexdump
		if (hexdump) then XMLNodeAddChild(node,MyHexDumpNode(hexdump.offset,hexdump.len)) end
		return node
	end
	LuaXML_SaveFile(filepath,MyNode("MainChunk",self.pMainChunk))
	self:_FreeFIFO()
end

gGrannyLuaLoaderProfileCountStructRead = {}
function cGrannyFile:Read (offset,structname) 
	local quick = gGrannyLuaQuickLoadStruct[structname]
	if (quick) then return quick(self,offset) end
	gGrannyLuaLoaderProfileCountStructRead[structname] = (gGrannyLuaLoaderProfileCountStructRead[structname] or 0) + 1
	local quickfifo = self.quickfifo
	local structsize = self.size[structname] assert(structsize)
	assert(offset >= 0,"AssertSize : negative offset : "..offset)
	local missing = offset+structsize - self.miBufSize assert(missing <= 0,"AssertSize : buffer too small, expected "..missing.." more bytes miBufSize="..tostring(self.miBufSize).." structsize="..tostring(structsize))
	local res = setmetatable({},cGrannyFile.pItemMetaTable)
	local struct = self.structs[structname]
	for k,memberdef in ipairs(struct) do 
		local basetype,name,arraysize = unpack(memberdef)
		local basetypesize = basetype.size
		local peekfun = basetype.peekfun
		if (arraysize) then 
			local myarr = {}
			for i=0,arraysize-1 do myarr[i] = peekfun(quickfifo,offset) offset = offset + basetypesize end
			res[name] = myarr
		else
			res[name] = peekfun(quickfifo,offset)
			offset = offset + basetypesize 
		end
	end
	return res
end

gProfiler_LuaGrannyParser = CreateRoughProfiler("LuaGrannyParser")
function cGrannyFile:Parse (fifo) 
	self.fifo = fifo
	self.miBufSize = fifo:Size()
	self.quickfifo = fifo:GetQuickHandle()
	if (self.miBufSize == 0) then return false end
	
    gProfiler_LuaGrannyParser:Start(gEnableProfiler_LuaGrannyParser)
    gProfiler_LuaGrannyParser:Section("read MainChunk")
	
	assert(self.miBufSize > 0,"cGrannyFile:Parse: empty file "..tostring(self.filepath))
	local pMainChunk = self:Read(0,"MainChunk")
	self.pMainChunk = pMainChunk
	pMainChunk.childs = {}
	
    gProfiler_LuaGrannyParser:Section("visit MainChunk")
	--~ print("cGrannyFile:Parse:pMainChunk",SmartDump(pMainChunk))
	assert(pMainChunk.iChunkType == self.kChunkType_Main,"unexpected chunktype:"..hex(pMainChunk.iChunkType))
	self:Visit("MainChunk",pMainChunk,0)
	
    gProfiler_LuaGrannyParser:Section("visit MainChunk childs")
	local p = self.size.MainChunk
	for i=0,pMainChunk.miChildCount-1 do 
		local pItemList = self:Read(p,"ItemList")
		table.insert(pMainChunk.childs,pItemList)
		p = p + self.size.ItemList
		local pChunkDataStart = pItemList.miListOffset
		
		-- calculate where this chunk ends, either at the end of the file or at the beginning of the next buffer
		local pFileEnd = self.miBufSize
		local pChunkDataEnd = pFileEnd
		if (i < pMainChunk.miChildCount - 1 and pFileEnd - p >= self.size.ItemList) then
			pChunkDataEnd = self:Read(p,"ItemList").miListOffset
		end
		assert(pChunkDataEnd <= pFileEnd,"ParseGranny : illegal offset")
		
		local t = pItemList.iChunkType
		if (t == 0xCA5E0100 or		-- SiENcE:  Chunk is new to ML/SE Models maybe Texture: case 0xca5e0100 
			t == 0xCA5E0101 or      -- Final Chunk (End-of-File?)	
			t == 0xCA5E0102 or      -- Copyright Chunk
			t == 0xCA5E0103) then   -- Object Chunk
			self:ParseItemListData(pItemList,pChunkDataStart,pChunkDataEnd-pChunkDataStart);
		else
			assert(false,"ParseGranny : unknown subchunktype : "..hex(pItemList.iChunkType))
		end
	end
    gProfiler_LuaGrannyParser:Section("visit EOF")
	self:Visit("EOF")
    gProfiler_LuaGrannyParser:End()
	return true
end

function cGrannyFile:ReadInt (iOffset) 
	assert(iOffset >= 0 and iOffset+4 <= self.miBufSize)
	return FIFO_PeekUint32(self.quickfifo,iOffset)
end
function cGrannyFile:ReadFloat (iOffset) 
	assert(iOffset >= 0 and iOffset+4 <= self.miBufSize)
	return FIFO_PeekFloat(self.quickfifo,iOffset)
end

function cGrannyFile:ParseItemListData (pItemList,p,iItemListSize)
	--~ print("cGrannyFile:ParseItemListData")
	local quickfifo = self.quickfifo
	self.lastitemlist = pItemList
	pItemList.childs = {} 
	
	self.mlParents = {}
	self:Visit("ItemList",p,iItemListSize)
	
	-- read header
	local pItemListHeader = self:Read(p,"ItemList_Header")
	p = p + self.size.ItemList_Header
	
	-- read all nodes in list
	local miBufSize = self.miBufSize
	local GRANNY_CHUNKTYPE_MAGIC = 0xCA5E0000
	local iEntryHeaderSize = 3*4
	for i=0,pItemListHeader.miChildCount-1 do
		assert(p+iEntryHeaderSize <= self.miBufSize)
		local iChunkType	= FIFO_PeekUint32(quickfifo,p+0)
		local iOffset		= FIFO_PeekUint32(quickfifo,p+4)
		local iChildren		= FIFO_PeekUint32(quickfifo,p+8)
		p = p + iEntryHeaderSize
		
		gProfiler_LuaGrannyParser:Section(self.kTypeNames[iChunkType] or ("iChunkType=?="..iChunkType))
		
		-- determine data size of this child by checking the offset of the next child, if any, and listdata-size
		local iChildSize = miBufSize - (pItemList.miListOffset + iOffset)
		if (iOffset <= iItemListSize) then
			local iChildSize2 = iItemListSize - iOffset
			if (iChildSize2 < iChildSize) then iChildSize = iChildSize2 end
		end
		if (i < pItemListHeader.miChildCount - 1 and miBufSize - p >= iEntryHeaderSize) then
			local iNextOff = FIFO_PeekUint32(quickfifo,p+4)
			if (iNextOff >= iOffset) then
				local iChildSize2 = iNextOff - iOffset
				if (iChildSize2 < iChildSize) then iChildSize = iChildSize2 end
			end
		end
		
		assert(BitwiseAND(iChunkType,GRANNY_CHUNKTYPE_MAGIC) == GRANNY_CHUNKTYPE_MAGIC,"ParseGranny : magic failed in subchunktype "..hex(iChunkType))
		assert(iOffset <= iItemListSize,"chunk-offset out of bounds: offset:"..hex(iOffset).."size:"..iItemListSize)
		
		local myoffset = pItemList.miListOffset+iOffset
		assert(myoffset <= miBufSize)
		
		local chunk = setmetatable({iChunkType=iChunkType,iOffset=iOffset,iChildren=iChildren},cGrannyFile.pItemMetaTable) -- ,iChildSize=iChildSize
		local handler = self.chunkHandlers[iChunkType]
		if (handler) then 
			handler(self,myoffset,iChildSize,chunk) 
		elseif (iChildSize > 0) then
			chunk.hexdump = {offset=myoffset,len=iChildSize}
			--~ chunk.hexdump = sprintf("hexdump("..myoffset..","..iChildSize..")")
			--~ chunk.xmlcontent = FIFOHexDump(self.fifo,myoffset,iChildSize).."\n"
		end
		local p = self:GetCurrentParent() or self.lastitemlist
		table.insert(p.childs,chunk)
		
		self:DecrementParents()
		if (chunk.iChildren > 0) then self:PushParent(chunk) end
	end
	gProfiler_LuaGrannyParser:Section("visit DecrementParents")
	self:DecrementParents()
end


function cGrannyFile:GetCurrentParent () return self.mlParents[#self.mlParents] end
function cGrannyFile:GetRootParentType () local p = self.mlParents[1] return p and p.iChunkType end
function cGrannyFile:DecrementParents () 
	local res = {}
	for k,chunk in ipairs(self.mlParents) do
		chunk.childsleft = chunk.childsleft - 1 
		if (chunk.childsleft > 0) then table.insert(res,chunk) end 
	end
	self.mlParents = res
end
function cGrannyFile:GetParentDepth() return #self.mlParents end
function cGrannyFile:PushParent(chunk) chunk.childs = {} chunk.childsleft = chunk.iChildren table.insert(self.mlParents,chunk) end




function cGrannyFile:HexDump(iOffset,iSize)
	print("hexdump",iOffset,iSize)
	for i=0,iSize-1 do 
		local b = FIFO_PeekUint8(self.quickfifo,iOffset+i)
		local txt = sprintf(" 0x%04x:  b:0x%02x=%3d",i,b,b)
		if (i+4 <= iSize) then 
			local x = FIFO_PeekUint32(		self.quickfifo,iOffset+i)
			local y = FIFO_PeekNetUint32(	self.quickfifo,iOffset+i)
			local f = FIFO_PeekFloat(		self.quickfifo,iOffset+i)
			txt = txt .. sprintf(" i:0x%08x=%10d i2:0x%08x=%10d f:%f",x,x,y,y,f)
		end
		print(txt)
	end
end 




cGrannyFile.chunkHandlers = {}

cGrannyFile.chunkHandlers[0xCA5E0200] = function (self,iOffset,iSize,chunk) 
	assert(iSize >= 8) 
	local iNumEntries	= self:ReadInt(iOffset)
	local iTextLen		= self:ReadInt(iOffset+4)
	local p				= iOffset + 8
	local iMaxLen		= iSize-8
	assert(iTextLen <= iMaxLen)
	chunk.iNumEntries = iNumEntries
	chunk.iTextLen = iTextLen
	chunk.texts = {}
	local quickfifo = self.quickfifo
	local txt = {}
	for i=1,iTextLen do 
		local c = FIFO_PeekUint8(quickfifo,p+i-1) -- -1: offset is zero-based i=1 should be first byte. first string often empty (copyright)
		if (c == 0 or i == iTextLen) then 
			table.insert(chunk.texts,string.char(unpack(txt))) txt = {}
		else
			table.insert(txt,c)
		end
	end                                     
	--~ cGrannyFile:VisitTextChunk      6       iTextLen=111     252     iSize=112                                              
	--~ cGrannyFile:VisitTextChunk      66      iTextLen=596     28232   iSize=596     
end


cGrannyFile.chunkHandlers[0xCA5E0f04] = function (self,iOffset,iSize,chunk)
	assert(iSize == 4)
	chunk.iID = self:ReadInt(iOffset)
	--~ if (self:GetRootParentType() == 0XCA5E0602) then assert(iSize == 4) return self:VisitMeshID(self:ReadInt(iOffset)) end
	--~ if (self:GetRootParentType() == 0XCA5E0B01) then assert(iSize == 4) return self:VisitBoneTieID(self:ReadInt(iOffset)) end
	--~ if (self:GetRootParentType() == 0XCA5E0304) then assert(iSize == 4) return self:VisitTexInfoID(self:ReadInt(iOffset)) end
end

cGrannyFile.chunkHandlers[0XCA5E0F00] = function (self,iOffset,iSize,chunk) 
	assert(self:GetRootParentType() == 0XCA5E0F03)
	assert(iSize == 8,"size-mismatch:"..iSize)
	chunk.unknown_a = self:ReadInt(iOffset)
	chunk.unknown_b = self:ReadInt(iOffset+4)
	assert(chunk.unknown_a == 1 and chunk.unknown_b == 1) -- true for AbysmalHorror_Attack1.grn
	-- self:VisitObj(a,b)
end

cGrannyFile.chunkHandlers[0XCA5E0F01] = function (self,iOffset,iSize,chunk) 
	assert(self:GetRootParentType() == 0XCA5E0F03)
	assert(iSize == 4)
	chunk.key = self:ReadInt(iOffset) -- VisitObjKey      miLastKey
end

cGrannyFile.chunkHandlers[0XCA5E0F02] = function (self,iOffset,iSize,chunk) 
	assert(self:GetRootParentType() == 0XCA5E0F03)
	assert(iSize == 8,"size-mismatch:"..iSize)
	chunk.unknown_a = self:ReadInt(iOffset)
	chunk.unknown_b = self:ReadInt(iOffset+4) -- VisitObjValue   : push miLastKey,iUnknown2
	assert(chunk.unknown_a == 0) -- true for AbysmalHorror_Attack1.grn
end

function cGrannyFile:ReadArray (sStructName,iOffset,iArraySize) 
	assert(not structname,structname)
	local quick = gGrannyLuaQuickLoadStruct_Array[sStructName]
	if (quick) then return quick(self,iOffset,iArraySize) end
	local res = {}
	local iStructSize = self.size[sStructName]
	local num = floor(iArraySize/iStructSize)
	gGrannyLuaLoaderProfileCountStructRead[sStructName.."Arr"] = (gGrannyLuaLoaderProfileCountStructRead[sStructName.."Arr"] or 0) + num
	assert(iArraySize == num*iStructSize) -- exact size check to detect parsing errors
	for i=0,num-1 do table.insert(res,self:Read(iOffset+i*iStructSize,sStructName)) end
	return res
end

cGrannyFile.chunkHandlers[0XCA5E0801] = function (self,iOffset,iSize,chunk) assert(self:GetRootParentType() == 0XCA5E0602) chunk.list_points = self:ReadArray("Vector",iOffset,iSize) end -- VisitPoints
cGrannyFile.chunkHandlers[0XCA5E0802] = function (self,iOffset,iSize,chunk) assert(self:GetRootParentType() == 0XCA5E0602) chunk.list_normals = self:ReadArray("Vector",iOffset,iSize) end -- VisitNormals
cGrannyFile.chunkHandlers[0XCA5E0901] = function (self,iOffset,iSize,chunk) assert(self:GetRootParentType() == 0XCA5E0602) chunk.list_polygons = self:ReadArray("Polygon",iOffset,iSize) end -- VisitPolygons

cGrannyFile.chunkHandlers[0XCA5E0803] = function (self,iOffset,iSize,chunk) 
	assert(self:GetRootParentType() == 0XCA5E0602)
	assert(iSize >= 4) 
	chunk.unknown = self:ReadInt(iOffset)
	chunk.list_texcoords = self:ReadArray("Vector",iOffset+4,iSize-4) -- VisitTexCoords
end

cGrannyFile.chunkHandlers[0XCA5E0702] = function (self,iOffset,iSize,chunk)  -- structure is wnum*{ iNumBones, iNumBones*{iWeightBoneIndex,fWeight} }
	assert(self:GetRootParentType() == 0XCA5E0602)
	assert(iSize >= 3*4) 
	chunk.wnum		= self:ReadInt(iOffset)
	chunk.unknown_a	= self:ReadInt(iOffset+4)
	chunk.unknown_b	= self:ReadInt(iOffset+8)
	local iWeightPairSize = self.size.WeightPair
	iSize = iSize - 12
	iOffset = iOffset + 12
	local list_weightchunks = {}
	chunk.list_weightchunks = list_weightchunks
	for i=1,chunk.wnum do
		assert(iSize > 4)
		local iNumBones = self:ReadInt(iOffset)
		assert(iSize-4 >= iNumBones*iWeightPairSize)
		local iPairListSize = min(iSize-4,iNumBones*iWeightPairSize)
		local list_pairs = self:ReadArray("WeightPair",iOffset+4,iPairListSize)
		table.insert(list_weightchunks,{iNumBones=iNumBones,list_pairs=list_pairs})
		iOffset = iOffset + 4 + iPairListSize
		iSize = iSize - 4 - iPairListSize
	end
	assert(iSize==0)
end

cGrannyFile.chunkHandlers[0xCA5E0e06] = function (self,iOffset,iSize,chunk) 
	assert(self:GetRootParentType() == 0XCA5E0E01)
	assert(iSize >= 4) 
	local iNum = self:ReadInt(iOffset)			chunk.iNum = iNum
	local iElementSize = floor((iSize-4)/iNum)	chunk.iElementSize = iElementSize
	if (iSize-4 ~= iNum*iElementSize) then
		printdebug("granny","cGrannyVisitor::VisitChunk 0xCA5E0e06 unexpected size (num=%d,elsize=%d): %d/%d",iNum,iElementSize,iSize-4,iNum*iElementSize)
		assert(false,"should not happen")
	end
	
	
		if (iElementSize == self.size.TexturePolySmall)	then chunk.list_texpoly_small	= self:ReadArray("TexturePolySmall",iOffset+4,iSize-4)  -- VisitTexPolygonsSmall
	elseif (iElementSize == self.size.TexturePoly)		then chunk.list_texpoly_normal	= self:ReadArray("TexturePoly",		iOffset+4,iSize-4)  -- VisitTexPolygons
	elseif (iElementSize == self.size.TexturePolyBig)	then chunk.list_texpoly_big		= self:ReadArray("TexturePolyBig",	iOffset+4,iSize-4)  -- VisitTexPolygonsBig
	else
		printdebug("granny","cGrannyVisitor::VisitChunk 0xCA5E0e06 unexpected element-size : %d",iElementSize) 
		assert(false,"should not happen")
		self:HexDump(iOffset,iSize) 
	end
end

cGrannyFile.chunkHandlers[0XCA5E0506] = function (self,iOffset,iSize,chunk) 
	assert(self:GetRootParentType() == 0XCA5E0507) 
	assert(iSize == self.size.Bone) 
	chunk.bone = self:Read(iOffset,"Bone") -- VisitBone
end


cGrannyFile.chunkHandlers[0xCA5E0303] = function (self,iOffset,iSize,chunk) 
	assert(self:GetRootParentType() == 0XCA5E0304) 
	if (iSize ~= self.size.TexInfo) then printdebug("granny","WARNING ! granny 0xCA5E0303 : size1=%d size2=%d",iSize,self.size.TexInfo) end
	--~ assert(iSize == self.size.TexInfo) 
	assert(iSize >= self.size.TexInfo)
	chunk.texinfo = self:Read(iOffset,"TexInfo") -- VisitTexInfo
end

cGrannyFile.chunkHandlers[0XCA5E0C08] = function (self,iOffset,iSize,chunk) assert(self:GetRootParentType() == 0XCA5E0C01) assert(iSize == 4) chunk.iBoneTie2ID = self:ReadInt(iOffset) end -- VisitBoneTie2ID
cGrannyFile.chunkHandlers[0XCA5E0C03] = function (self,iOffset,iSize,chunk) assert(self:GetRootParentType() == 0XCA5E0C01) assert(iSize == 4) chunk.iBoneTie2GroupID = self:ReadInt(iOffset) end -- VisitBoneTie2GroupID

cGrannyFile.chunkHandlers[0XCA5E0C02] = function (self,iOffset,iSize,chunk) 
	assert(self:GetRootParentType() == 0XCA5E0C01) 
	chunk.iNum = floor(iSize/4)
	assert(iSize == chunk.iNum * 4) 
	local list = {}
	for i=0,chunk.iNum-1 do table.insert(list,self:ReadInt(iOffset+i*4)) end 
	chunk.BoneTies2 = list -- VisitBoneTies2
end
cGrannyFile.chunkHandlers[0xCA5E0c0a] = function (self,iOffset,iSize,chunk) assert(self:GetRootParentType() == 0XCA5E0C01) assert(iSize == self.size.BoneTie) chunk.bonetie = self:Read(iOffset,"BoneTie") end -- VisitBoneTie

cGrannyFile.chunkHandlers[0XCA5E0E00] = function (self,iOffset,iSize,chunk) assert(self:GetRootParentType() == 0XCA5E0E01) assert(iSize == 4) chunk.iTextureID = self:ReadInt(iOffset) end -- VisitTextureID
cGrannyFile.chunkHandlers[0XCA5E0E02] = function (self,iOffset,iSize,chunk) assert(self:GetRootParentType() == 0XCA5E0E01) assert(iSize == 8) chunk.iTexturePoly = {a=self:ReadInt(iOffset),b=self:ReadInt(iOffset+4)} end -- VisitTexturePoly
cGrannyFile.chunkHandlers[0XCA5E0E04] = function (self,iOffset,iSize,chunk) assert(self:GetRootParentType() == 0XCA5E0E01) assert(iSize == 4) chunk.iTexturePolyData = self:ReadInt(iOffset) end -- VisitTexturePolyData


function cGrannyFile:ReadFloatArray(iOffset,num)
	local res = {}
	assert(iOffset >= 0 and iOffset+num*4 <= self.miBufSize) -- bounds-checking
	local quickfifo = self.quickfifo
	local peekfun = FIFO_PeekFloat
	for i=0,num-1 do table.insert(res,peekfun(quickfifo,iOffset+i*4)) end
	return res 
end


cGrannyFile.chunkHandlers[0XCA5E1204] = function (self,iOffset,iSize,chunk) 
	assert(self:GetRootParentType() == 0XCA5E1205)
	assert(iSize >= self.size.Anim)
	
    gProfiler_LuaGrannyParser:Section("animdata read Anim")
	
	local p = iOffset
	local pAnim = self:Read(iOffset,"Anim")		chunk.pAnim = pAnim			p = p + self.size.Anim
	
    gProfiler_LuaGrannyParser:Section("animdata read floats")
	local s,n = self.size.float			,pAnim.iNumTranslate	chunk.pTranslateTime	= self:ReadFloatArray(p,n)					p = p + s * n
	local s,n = self.size.float			,pAnim.iNumQuaternion	chunk.pQuaternionTime	= self:ReadFloatArray(p,n)					p = p + s * n
	local s,n = self.size.float			,pAnim.iNumScale		chunk.pScaleTime		= self:ReadFloatArray(p,n)					p = p + s * n
	
    gProfiler_LuaGrannyParser:Section("animdata read vec+quat")
	local s,n = self.size.Vector		,pAnim.iNumTranslate	chunk.pTranslate		= self:ReadArray("Vector"		,p,s * n)	p = p + s * n
	local s,n = self.size.Quaternion	,pAnim.iNumQuaternion	chunk.pQuaternion		= self:ReadArray("Quaternion"	,p,s * n)	p = p + s * n
	local s,n = self.size.Vector		,pAnim.iNumScale		chunk.pScale			= self:ReadArray("Vector"		,p,s * n)	p = p + s * n
	
    gProfiler_LuaGrannyParser:Section("animdata rest")
	local iRestSize = iSize - (p-iOffset)	-- assert(pRestSize == 0,"anim:iRestSize="..iRestSize..",iUnknownB="..pAnim.iUnknownB[1])
	local pRest		= p
	local iUsedSize = p - iOffset
	if (iRestSize > 0) then 
		chunk.hexdump = {offset=pRest,len=iRestSize} 
		local n = floor(iRestSize/self.size.float)
		assert(iRestSize == n*self.size.float)
		chunk.pRest = self:ReadFloatArray(pRest,n)
	end
	
	local MAX_PARTNUM_0XCA5E1204 = 0x0000ffff
	local bBroken =		iUsedSize 				< 0 or iSize < iUsedSize or 
						pAnim.iNumTranslate 	< 0 or pAnim.iNumTranslate		>= MAX_PARTNUM_0XCA5E1204 or 
						pAnim.iNumQuaternion 	< 0 or pAnim.iNumQuaternion		>= MAX_PARTNUM_0XCA5E1204 or 
						pAnim.iNumScale 		< 0 or pAnim.iNumScale			>= MAX_PARTNUM_0XCA5E1204
	if (bBroken) then
		printdebug("granny","0XCA5E1204 broken : %08x %08x",iOffset,p);
		printdebug("granny","0XCA5E1204 broken : iNumTranslate=%d",pAnim.iNumTranslate);
		printdebug("granny","0XCA5E1204 broken : iNumQuaternion=%d",pAnim.iNumQuaternion);
		printdebug("granny","0XCA5E1204 broken : iNumScale=%d",pAnim.iNumScale);
		printdebug("granny","0XCA5E1204 broken : iSize=%d iUsedSize=%d",iSize,iUsedSize);
		assert(false,"shouldn't happen")
	end
	local fTotalTime = 0
	if (not bBroken) then
		local fTotalTimeT = (pAnim.iNumTranslate	> 0) and chunk.pTranslateTime[pAnim.iNumTranslate] or 0
		local fTotalTimeQ = (pAnim.iNumQuaternion	> 0) and chunk.pQuaternionTime[pAnim.iNumQuaternion] or 0
		local fTotalTimeS = (pAnim.iNumScale		> 0) and chunk.pScaleTime[pAnim.iNumScale] or 0
		fTotalTime = max(max(fTotalTimeT,fTotalTimeQ),fTotalTimeS)
		chunk.fTotalTime = fTotalTime
	end
	
	--[[
	VisitGrannyAnim(pAnim,
		bBroken?0:pTranslateTime,
		bBroken?0:pQuaternionTime,
		bBroken?0:pScaleTime,
		
		bBroken?0:pTranslate,
		bBroken?0:pQuaternion,
		bBroken?0:pScale,
		
		bBroken?0:pRest,
		bBroken?0:fTotalTime,
		bBroken?0:iUsedSize,iSize); ]]--
end



function cGrannyFile:Visit (name,...) 
	--~ if (self.visit_last_name == name) then
		--~ if (self.visit_last_count == 11) then print("...") end
		--~ if (self.visit_last_count  > 11) then return end
			--~ self.visit_last_count = self.visit_last_count + 1
	--~ else
		--~ self.visit_last_name = name
		--~ self.visit_last_count = 1
	--~ end
	--~ print("cGrannyFile:Visit",name,...) 
end 

--[[
		--~ case 0XCA5E0601: StartSubMesh(); break;
	
	VisitTextChunk:mTextChunks
	VisitObj:mParamGroups start
	VisitObjKey:miLastKey
	VisitObjValue:mParamGroups (miLastKey,val)
	
	// main params are in mParamGroups and mTextChunks[1]
	if (mTextChunks.size() >= 2) {
		for (int i=0;i<mParamGroups.size();++i) {
			for (int j=0;j<mParamGroups[i].size();++j) {
				uint32 key		= mParamGroups[i][j].first;
				uint32 value	= mParamGroups[i][j].second;
				if (key < mTextChunks[1].size() && value < mTextChunks[1].size()) {
					mMainParams[i][mTextChunks[1][key] ] = strtolower(mTextChunks[1][value]);
				}
			}
		}
	}
]]--	
		
		
--~ cGrannyFile:LoadFile    /cavern/uoml/Models/Monsters/Changling_idle.grn",			DEBUG[granny]   WARNING ! granny 0xCA5E0303 : size1=%d size2=%d 22428   12 
--~ cGrannyFile:LoadFile    /cavern/uoml/Models/Monsters/Denkou_Yajuu_Pillage.grn",	DEBUG[granny]   WARNING ! granny 0xCA5E0303 : size1=%d size2=%d 6244    12                       
--~ cGrannyFile:LoadFile    /cavern/uoml/Models/Monsters/Devourer_Attack2.grn",		DEBUG[granny]   WARNING ! granny 0xCA5E0303 : size1=%d size2=%d 264     12 
