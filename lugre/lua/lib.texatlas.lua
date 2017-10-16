-- texcoord transform for textureatlas and similar

gTexAtlas_MatTransform = {}
gTexAtlas_AdjustedMeshBuffers = {}

-- c GetMeshBuffer wrapper
_GetMeshBuffer = GetMeshBuffer
gGetMeshBufferCache = {}
function GetMeshBuffer(meshname)
	if gGetMeshBufferCache[meshname] then return gGetMeshBufferCache[meshname] end
	
	-- get mesh and patch uv if needed
	local meshbuffer = _GetMeshBuffer(meshname)
	TexAtlas_AdjustMeshBufferIfNeeded(meshname,meshbuffer)
	
	gGetMeshBufferCache[meshname] = meshbuffer
	
	return meshbuffer
end

-- only executed once per meshbuffer, adjust texturecoordinates and material for textureatlas
function TexAtlas_AdjustMeshBufferIfNeeded (meshname,meshbuffer)
	if (not gUseTexAtlas) then return end
	if (gTexAtlas_AdjustedMeshBuffers[meshname]) then return end
	gTexAtlas_AdjustedMeshBuffers[meshname] = true
	local iNumSubMeshes = meshbuffer:GetSubMeshCount()
	for iSubMeshIndex=0,iNumSubMeshes-1 do
		local matname = meshbuffer:GetSubMeshMatName(iSubMeshIndex)
		local transform = gTexAtlas_MatTransform[matname]
		if (transform) then
			local du = transform.u1,transform.u0
			local dv = transform.v1,transform.v0
			
			meshbuffer:SetSubMeshMatName(iSubMeshIndex,transform.sNewMatName)
			meshbuffer:TransformSubMeshTexCoords(iSubMeshIndex,transform.u0,transform.v0,transform.u1,transform.v1)
		end
	end
end

function TexAtlas_RegisterMatTransform (sOldMatName,sNewMatName,u0,v0,u1,v1)
	--~ print("TexAtlas_RegisterMatTransform",sOldMatName,sNewMatName,u0,v0,u1,v1)
	gTexAtlas_MatTransform[sOldMatName] = { sNewMatName=sNewMatName, u0=u0,v0=v0,u1=u1,v1=v1 }
end
