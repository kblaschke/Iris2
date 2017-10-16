-- utils for custom geometry : vertex-decaration, vertexbuffer, indexbuffer...

-- ***** ***** ***** cVertexDecl

cVertexDecl = CreateClass()

kVertexDeclTypeName = {}
for k,name in ipairs({
	"VET_FLOAT1",
	"VET_FLOAT2",	
	"VET_FLOAT3",	
	"VET_FLOAT4",	
	"VET_COLOUR",		-- alias to more specific colour type - use the current rendersystem's colour packing
	"VET_SHORT1",	    
	"VET_SHORT2",	    
	"VET_SHORT3",	    
	"VET_SHORT4",	    
	"VET_UBYTE4",       
	"VET_COLOUR_ARGB",  -- 	D3D style compact colour.
	"VET_COLOUR_ABGR",  --	GL style compact colour. 
	}) do 
	kVertexDeclTypeName[_G[name] or ""] = name
end

kVertexDeclSemanticName = {}
for k,name in ipairs({
	"VES_POSITION",				-- 	Position, 3 reals per vertex.
	"VES_BLEND_WEIGHTS",        -- 	Blending weights.
	"VES_BLEND_INDICES",        -- 	Blending indices.
	"VES_NORMAL",               -- 	Normal, 3 reals per vertex.
	"VES_DIFFUSE",              -- 	Diffuse colours.
	"VES_SPECULAR",             -- 	Specular colours.
	"VES_TEXTURE_COORDINATES",  -- 	Texture coordinates.
	"VES_BINORMAL",             -- 	Binormal (Y axis if normal is Z).
	"VES_TANGENT",              -- 	Tangent (X axis if normal is Z). 
	}) do 
	kVertexDeclSemanticName[_G[name] or ""] = name
end

function cVertexDecl:Init		() self.offsets = {} self.decl = CreateVertexDeclaration() end

function cVertexDecl:Destroy	() if (self.decl) then self.decl:Destoy() self.decl = nil end end

function cVertexDecl:GetOgreVertexDecl	() return self.decl end

function cVertexDecl:addElement	(src,type,semantic,index) -- index : for multiple texcoords, defaults to 0
	local oldoff = self.offsets[src] or 0
	self.offsets[src] = oldoff + self.decl:addElement(src,oldoff,type,semantic,index)
end

function cVertexDecl:PrintAutoOrganised	(bSkeletalAnimation,bVertexAnimation) 
	local decl2 = self.decl:getAutoOrganisedDeclaration(bSkeletalAnimation,bVertexAnimation)
	for i = 0,decl2:getElementCount()-1 do 
		local src,offset,type,semantic,index = decl2:getElement(i)
		print("vdecl:addElement("..tostring(src)..","..(kVertexDeclTypeName[type] or "unknown")..","..(kVertexDeclSemanticName[semantic] or "unknown")..((index ~= 0) and (","..tostring(index)) or "")..")")
	end
	decl2:Destroy()
end




-- ***** ***** ***** cVertexBuffer

cVertexBuffer = CreateClass()
function cVertexBuffer:Init() 
	self.vc = 0
	self.fifo = CreateFIFO()
	self.quickfifo = self.fifo:GetQuickHandle()
	self.bGetFirstSize = true
	self.iFirstSize = 0
end
function cVertexBuffer:Destroy() 
	self.fifo:Destroy() self.fifo = nil
end

local function cVertexBuffer_AddFloat(quickfifo,f,...)
	if (not f) then return end
	FIFO_PushF(quickfifo,f)
	cVertexBuffer_AddFloat(quickfifo,...) -- recurse
end

function cVertexBuffer:Vertex(...)
	local quickfifo = self.quickfifo
	cVertexBuffer_AddFloat(quickfifo,...)
	self.vc = self.vc + 1
	if (self.bGetFirstSize) then 
		self.bGetFirstSize = false
		self.iFirstSize = self.fifo:Size()
	end
end

function cVertexBuffer:GetFIFO() return self.fifo end
function cVertexBuffer:GetVertexNum() return self.vc end
function cVertexBuffer:GetVertexSize() return self.iFirstSize end
function cVertexBuffer:CheckSize()
	local a = self.iFirstSize * self.vc
	local b = self.fifo:Size()
	assert(a == b,"size mismatch vc*first="..a.." real="..b)
end

-- ***** ***** ***** cIndexBuffer

cIndexBuffer = CreateClass()
function cIndexBuffer:Init() 
	self.ic = 0
	self.fifo = CreateFIFO()
	self.quickfifo = self.fifo:GetQuickHandle()
end
function cIndexBuffer:Destroy() 
	self.fifo:Destroy() self.fifo = nil
end
function cIndexBuffer:GetFIFO() return self.fifo end
function cIndexBuffer:GetIndexNum() return self.ic end
function cIndexBuffer:MultiIndex(i,j,...) self:Index(i) return j and self:MultiIndex(j,...) end
function cIndexBuffer:Index(i) 
	FIFO_PushUint32(self.quickfifo,i)
	self.ic = self.ic + 1
end

-- ***** ***** ***** end
