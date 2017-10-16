-- some material utils


function GetBillBoardMat (texpath,bAdditive) return GetTexturedMat(bAdditive and "billboard_add_base" or "billboard_base",texpath) end

gTexturedMatCache = {}
function GetTexturedMat (base,texpath) 
	local cachename = base.."#"..texpath
	local cache = gTexturedMatCache[cachename]
	if (cache) then return cache end
	cache = CloneMaterial(base)
	SetTexture(cache,texpath,0,0,0)
--~ 	SetTexture(cache,texpath,0,0,1)
--~ 	SetTexture(cache,texpath,0,0,2)
	gTexturedMatCache[cachename] = cache
	return cache
end


gPlainTextureMatCache = {}
function GetPlainTextureMat (texpath,bHasAlpha) 
	local cache = gPlainTextureMatCache[texpath]
	if (cache) then return cache end
	cache = CloneMaterial("plaincolor_base")
	SetTexture(cache,texpath)
	gPlainTextureMatCache[texpath] = cache
	if (bHasAlpha) then 
		SetSceneBlend(cache,0,0,1)
		SetDepthWriteEnabled(cache,0,0,1)
	end
	return cache
end

function GetPlainWhiteMat () return GetPlainColourMat(1,1,1) end
function GetPlainColourMat (r,g,b,a) return GetHuedMat("plaincolor_base",r,g,b,r,g,b,a) end

-- makes a copy of a material and changes color by setting ambient and diffuse colors
-- paramters : basematname, ambient-rgb, diffuse-rgba,
-- diffuse defaults to ambient if not given, diffuse-alpha defaults to 1
gHuedMatCache = {}
function GetHuedMat (basematname, ar,ag,ab, dr,dg,db,da, texpath)
	dr = dr or ar
	dg = dg or ag
	db = db or ab
	da = da or 1
	local name = sprintf("%s__%f_%f_%f__%f_%f_%f_%f_%s",basematname,ar,ag,ab, dr,dg,db,da,texpath and texpath or "")
	local cache = gHuedMatCache[name]
	if (cache) then return cache end
	cache = CloneMaterial(basematname)
	if (texpath) then SetTexture(cache,texpath,0,0,0) end
	SetAmbient(cache,0,0,ar,ag,ab)
	SetDiffuse(cache,0,0,dr,dg,db,da)
	if (da ~= 1) then SetSceneBlend(cache,0,0,1) end
	if (da ~= 1) then SetDepthWriteEnabled(cache,0,0,0) end
	gHuedMatCache[name] = cache
	return cache
end

-- todo : place me in meshutils or something like that ?
function HueMeshEntity (gfx, ar,ag,ab, dr,dg,db,da)
	local subcount = gfx:GetMeshSubEntityCount()
	for i = 0,subcount-1 do gfx:SetMeshSubEntityMaterial(i,GetHuedMat(gfx:GetMeshSubEntityMaterial(i), ar,ag,ab, dr,dg,db,da)) end
end

-- todo : generic guimat(bAlpha) from texture, 3dmat from texture



