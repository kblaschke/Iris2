--[[ ***** see Iris2 COPYING for license info ***** ]]--
--[[ \brief
        this file handles loading and information related to (granny-)models used for mobiles
        most info files handled by this are found in uo/Models/ and subdirectories
        see also lib.stitchin.lua
        granny textures are in Models/Maps/
        also handles skeletal anim for granny models
]]--

-- Human.lst
-- # core animation set - 0-34  
-- 0    Walk_01

-- uo/Models/Humans/H_Male_Walk_01.grn
gBrokenGrannyModelIdList = {} -- TODO : those load to crash and are skipped
gBrokenGrannyModelIdList[0x101] = true -- client crash
gBrokenGrannyModelIdList[0x306] = true -- client crash

gGrannyTypeAnimListFiles = {[0]="Monster.lst",[1]="Sea.lst",[2]="Animal.lst",[3]="Human.lst"}
gSkeletons = {}
gAnimInfoLists = false

gGrannyModelsFemale1 = {401} -- filled during loading models.txt (all where anim=401) : 606,184,186,745,751,774,765,770,773
gGrannyModelsFemale2 = {} -- filled during loading models.txt (all where modelname contains female) (a lot)
gGrannyMaterialCache = {}
kGrannyEquipmentFemaleAdd = 1000
kGrannyModelPartAddMale = 2000
kGrannyModelPartAddFemale = 3000
kGrannyModelPartByNum = { -- see Models.txt 2001ff and 3001ff,  value=relevant partnames from stitchin.def
    [01]={EARS=true}, -- todo : elven ears ?
    [02]={FEET=true},  
    [03]={LOWER_ARMS_BOTTOM=true,LOWER_ARMS_TOP=true}, -- h_male_FArms_V2 
    [04]={HANDS=true},
    [05]={HEAD=true}, -- h_male_Head_V2
    [06]={LOWER_LEGS_BOTTOM=true,LOWER_LEGS_TOP=true},
    [07]={NECK=true},
    [08]={PELVIS=true},
    [09]={TORSO=true}, -- h_male_Torso_V2   -- complete torso, male and female
    [10]={UPPER_ARMS_TOP=true,UPPER_ARMS_BOTTOM=true},
    [11]={UPPER_LEGS_BOTTOM=true,UPPER_LEGS_TOP=true},
    --[12]={}, -- h_female_torso_PushUp_V2, female only  : complete torso for female, breasts a little higher than 09
    --[13]={} -- h_male_torso_upper_V2  -- just the shoulders
    -- 12 and 13 are special, they are generated from stitchin via replace of 09
}

-- Models.txt
-- #Body    Type    Anim    DefHue  Unused  Scale   Scale   Scale   3D Model
-- 400  3   0   FFFFFFFF    0   1.6 1.4 1.5 h_male
-- animationspeeds.txt : 401 127 0.9 // long distance wave    OBJECT_TYPE ANIM_NUM SPEED
gGrannyModelInfo = nil -- infos from Models.txt
gGrannyTypeDirs = {     [0]="Monsters/",
                        [1]="SeaCreatures/",
                        [2]="Animals/",
                        [3]="Humans/",
                        [4]="Others/", -- no .lst file with anims ?!?
    }
    
kGrannyModelPartFaceStart = 100 -- 100-131  +  kGrannyModelPartAddMale or kGrannyModelPartAddFemale  -- 100 115
-- "FACE" is missing above, there are many : 2100-2131   3100-3131
-- and a mysterious ./Others/H_Female_Face_V2_lod2.grn
-- todo : between female head and face

gGrannyScaleFactor = 0.65 --0.5

function CreateGrannyLoader(loadertype,base_file,localisation_file,bWarnOnMissingFile)
    if (loadertype == "OnDemand") then
        gAnimInfoLists = {}
        for k,filename in pairs(gGrannyTypeAnimListFiles) do 
            gAnimInfoLists[k] = LoadGrannyAnimInfo( CorrectPath(Addfilepath(gGrannyPath..filename)) )
        end 
        --~ GetOrCreateSkeleton(400) -- precache h_male
        --~ GetOrCreateSkeleton(401) -- precache h_female
        return true -- currently there is no real loader object as there is no single file to be loaded
    else    
        print("unknown/unsupported granny loader type",loadertype)
        return nil
    end
end


function GrannyTest3DData ()
    local bodyid = 400 -- human male
    local modelinfo = GetGrannyModelInfo(bodyid)
	if (not modelinfo) then 
		GrannyShowNo3DDataError(bodyid)
		gGrannyLoaderType = false
		gGrannyLoader = false
		print("GrannyTest3DData:fail")
	else
		print("GrannyTest3DData:ok",SmartDump(modelinfo))
	end
end
function GrannyShowNo3DDataError (bodyid)
	if (gGrannyNo3DDataErrorShown) then return end
	gGrannyNo3DDataErrorShown = true
	LugreMessageBox(kLugreMessageBoxType_Ok,	"No 3D Character Models found in UO-dir",
												"Iris couldn't find 3D Character Models in your UO folder (bodyid:"..(bodyid or "startup-check")..").\n"..
												"To fix this, you should install Ultima Online Mondains Legacy using one of the installers on the iris2.de website.\n"..
												"The installer on the original UO website will not work as the data was removed because the original 3D-Mode is no longer supported.\n"..
												"Patching the UO-Client up does not remove the 3D Character Models")
end

-- retrieves or creates a skeleton and fills it with bones from the first animation
-- local skeleton = GetOrCreateSkeleton(bodyid)
-- create the skeleton before creating any entities of this bodyid
function GetOrCreateSkeleton (bodyid) 
    -- Models.txt : 234 2   0   FFFFFFFF    0   1.3 1.3 1.3 deer_stag
    --if (bodyid == 400) then bodyid = 401 end
    --if (bodyid == 401) then bodyid = 400 end
	bodyid = GrannyOverride(bodyid)
    local modelinfo = GetGrannyModelInfo(bodyid)
	
	if (not modelinfo) then GrannyShowNo3DDataError(bodyid) return end
    assert(modelinfo,"ERROR bodyinfo for skeleton not found "..tostring(bodyid))

    while (modelinfo.animid ~= 0) do modelinfo = GetGrannyModelInfo(modelinfo.animid) end
    local skeletonname = modelinfo.modelname -- example: "deer_stag"
    local skeleton = gSkeletons[skeletonname]
    if ((not skeleton) and modelinfo.typeid ~= 4) then
        printdebug("granny","creating skeleton",bodyid,skeletonname)
        CreateSkeleton(skeletonname)
        skeleton = { name=skeletonname, anims={} }
        gSkeletons[skeletonname] = skeleton
        
        -- load sample bodyparts needed for animation (needed to assemble correct granny skeleton)
        local bodypartsamples = {}
        if (IsBodyIDHuman(bodyid)) then 
            if (IsBodyIDFemale(bodyid)) then
                -- human female body parts, often (bodyid == 401)
                for k,v in pairs(kGrannyModelPartByNum) do table.insert(bodypartsamples,GetGrannyModelLoader(k+kGrannyModelPartAddFemale)) end
            else
                -- human male body parts, often (bodyid == 400)
                for k,v in pairs(kGrannyModelPartByNum) do table.insert(bodypartsamples,GetGrannyModelLoader(k+kGrannyModelPartAddMale)) end
            end
        else
            -- non-human model has komplete skeleton
            table.insert(bodypartsamples,GetGrannyModelLoader(bodyid))
        end
        
        -- load all animations so all entities created afterwards have the full anim set
        for k,v in pairs(gAnimInfoLists[modelinfo.typeid]) do
            LoadGrannyAnim(bodyid,k,skeleton,bodypartsamples) 
        end
    end
    return skeleton
end

-- retrieves or creates a granny animation and loads it into the skeleton used for this bodytype
function LoadGrannyAnim (bodyid,animid,skeleton,bodypartsamples)
    -- load anim granny
    local animname = GetAnimName(bodyid,animid) 
    if (skeleton.anims[animname]) then return end -- already loaded
    local animpath = GetAnimPath(bodyid,animid)
    local mygrannyanim = LoadGranny(animpath)
    if (not mygrannyanim) then 
		print("ERROR LoadGrannyAnim",animpath,bodyid,animid,skeleton,bodypartsamples)
		return false
	end
    
    -- construct animation
    printdebug("granny","LoadGrannyAnim",bodyid,animid,skeleton.name,animname,animpath)
    mygrannyanim:AddAnimToSkeleton(skeleton.name,animname,bodypartsamples)
    skeleton.anims[animname] = true
end
    
-- GetAnimPath(234,0) returns something like "uo/Models/Animals/Deer_Stag_Walk.grn"
-- Models.txt : 234 2   0   FFFFFFFF    0   1.3 1.3 1.3 deer_stag
-- Animal.lst : 0   Walk
gGetAnimPathCache = {}
function GetAnimPath (mobileartid,animid) 
	-- cache check
	local key = mobileartid.."_"..animid
	local e = gGetAnimPathCache[key]
	if e ~= nil then
		if e == false then
			return nil
		else
			return e
		end
	end

    local bodyid = GrannyOverride(mobileartid)
    local modelinfo = GetGrannyModelInfo(bodyid)
    if (not modelinfo) then 
		gGetAnimPathCache[key] = false
		return nil 
	end
	
    while (modelinfo.animid ~= 0) do modelinfo = GetGrannyModelInfo(modelinfo.animid) end
    local animname = GetAnimName(bodyid,animid)
    if (not animname) then 
		gGetAnimPathCache[key] = false
		return nil	
	end
	
	local p = CorrectPath( Addfilepath(gGrannyPath..gGrannyTypeDirs[modelinfo.typeid]..modelinfo.modelname.."_"..animname..".grn") )
	gGetAnimPathCache[key] = p
    --assert(animname,"GetAnimPath failed, name not found : "..tostring(bodyid)..","..tostring(animid))
    --print("anim",gGrannyTypeDirs[modelinfo.typeid] .. modelinfo.modelname .. "_" .. animname .. ".grn")
    return p
end

-- GetAnimName(400,23) looks in Human.lst for animid 23 and returns "Horse_Walk_01"
-- determines "type" (human,animal,monster,sea,other) from the second column in the Models.txt
-- Human.lst : 23   Horse_Walk_01
function GetAnimName (mobileartid,animid) 
    local bodyid = GrannyOverride(mobileartid)
    local modelinfo = GetGrannyModelInfo(bodyid)
    while (modelinfo and modelinfo.animid ~= 0) do modelinfo = GetGrannyModelInfo(modelinfo.animid) end
    return modelinfo and gAnimInfoLists and gAnimInfoLists[modelinfo.typeid] and gAnimInfoLists[modelinfo.typeid][animid]
end

-- loads an anim info file, like Monster.lst
function LoadGrannyAnimInfo (filepath) 
    local grannyaniminfo = {}
	if (not file_exists(filepath)) then return grannyaniminfo end
    for line in io.lines(filepath) do
        line = TrimNewLines(line)
        if (string.sub(line,1,1) ~= "#") then
            local tokens = strsplit("\t",line)
            if (table.getn(tokens) >= 2 and string.len(tokens[1]) > 0) then 
                grannyaniminfo[tonumber(tokens[1])] = tokens[2]
            end
        end
    end
    return grannyaniminfo
end

-- ##### ##### ##### ##### #####  rest 

-- returns true if female
function IsBodyIDFemale (bodyid) 
    return in_array(bodyid,gGrannyModelsFemale1) or in_array(bodyid,gGrannyModelsFemale2)
end

function IsBodyIDHuman (bodyid) 
    if (bodyid == 987) then return true end -- gm
    local modelinfo = GetGrannyModelInfo(bodyid)
    return modelinfo and modelinfo.typeid == kAnimTypeID_Human
end

function GrannyTextureHook (x) return x end

-- takes the result of GetGrannyTextureName as paramter
-- transforms Ut128_Hat_Wide_Brim.tga into Ut128_Hat_Wide_Brim_M.tga
-- assumes suffixlength = 4 (.tga)
function GetGrannyTextureMaskName (texname)
    -- todo : remove .tga and add _m.tga for hue mask things, not always available
    local maskname = string.sub(texname,1,-5) .. "_M" .. string.sub(texname,-4)
    return maskname
end

function GetGrannyMat (modelid,hue,mygranny) 
    if (not gEnableGrannyMaterials) then return "grannybase" end
    if (hue >= hex2num("0x8000")) then hue = hue - hex2num("0x8000") end
    local texname = GetGrannyTextureName(mygranny)
    local matname = gGrannyMaterialCache[texname.."_"..hue]
    if (not matname) then
        local texmaskname = GetGrannyTextureMaskName(texname)
        local texturepath = basename(CorrectGrannyPath("Maps/"..texname))
        local texturemaskpath = basename(CorrectGrannyPath("Maps/"..texmaskname))
        -- texturepath will usually be an absolute path such as "/cavern/uostuff/uo/Models/Maps/UT256_Armor_Ring_V2.tga"
        -- after basename it is reduced to the filename only, for ogre1.4.8 changes (not allowing absolute paths anymore)
        -- for that a ressource location to the uo dir was added in

        local modelinfo = GetGrannyModelInfo(modelid)
        if (modelinfo) then
            if (modelinfo.typeid==4) then
                if (string.find(string.lower(modelinfo.modelname),"armor")) or
                   (string.find(string.lower(modelinfo.modelname),"weapon")) or
                   (string.find(string.lower(modelinfo.modelname),"shield")) then
                    matname = CloneMaterial("grannybase_equipment")
                else
                    matname = CloneMaterial("grannybase")
                end
            else
                --use skinshader for characters male/female, all other stuff uses grannybase plain
                if (IsBodyIDHuman(modelid) and gUseHumanSkinShader) then
                    matname = CloneMaterial("grannybase_humanshader")
                else
                    matname = CloneMaterial("grannybase")
                end
            end
        end

        if (gGrannyUseCompleteHuePalette) then
            SetTexture(matname,CreateGrannyHuedTexture(GrannyTextureHook(texturepath),GrannyTextureHook(texturemaskpath),gHueLoader,hue))
        else
            -- ignore mask completely and only do a multiplicative coloring with the hue's primary color
            -- ignoring the rest of the hue template
            SetTexture(matname,GrannyTextureHook(texturepath))
            if (hue > 0) then 
                local r,g,b = gHueLoader:GetColor(hue - 1,31) -- get first color
                SetAmbient(matname,0,0,r,g,b)
                SetDiffuse(matname,0,0,r,g,b)
            end
        end
        
        -- uses defaulthue=defhue from models.txt (FFFFFFFF : alpha-r-g-b)
        if (hue == 0) then
            if (modelinfo) then
                local r = tonumber(string.sub(modelinfo.defhue,3,3 + 1),16) / 255.0
                local g = tonumber(string.sub(modelinfo.defhue,5,5 + 1),16) / 255.0
                local b = tonumber(string.sub(modelinfo.defhue,7,7 + 1),16) / 255.0
                SetAmbient(matname,0,0,r,g,b)
                SetDiffuse(matname,0,0,r,g,b)
            end
        end
        gGrannyMaterialCache[texname.."_"..hue] = matname
    end
    return matname
end

-- some tests if the granny model format is as expected (for models, not for anims)
function CheckGrannyModel   (granny) 
    if (granny:GetSubMeshCount() ~= 1) then
        printdebug("granny","WARNING ! unexpected sumeshcount ",granny:GetSubMeshCount())
    end
    assert(granny:GetSubMeshCount() >= 1,"GetSubMeshCount=="..tostring(granny:GetSubMeshCount()))
    assert(granny:GetTextureIDCount() >= 1,"GetTextureIDCount=="..tostring(granny:GetTextureIDCount()))
    if (granny:GetTextureIDCount() > 1) then
        local base = GetGrannyTextureName(granny,0)
        for i = 1,granny:GetTextureIDCount()-1 do 
            assert(base == GetGrannyTextureName(granny,i)," multiple different textures not yet supported")
        end
    end
end

function GetGrannyParamGroups (granny)
    if (granny.paramgroups) then return granny.paramgroups end
    
    -- textchunks
    local textchunks = {}
    local textchunkcount = granny:GetTextChunkCount()
    for i = 0,textchunkcount-1 do
        local chunksize = granny:GetTextChunkSize(i)
        local arr = {}
        for j = 0,chunksize-1 do arr[j] = granny:GetText(i,j) end
        textchunks[i] = arr
    end
    -- for i,arr in pairs(textchunks) do for j,s in pairs(arr) do print(i,j,s) end end
    
    -- paramgroups
    local maintextchunk = textchunks[1]
    local paramgroupcount = granny:GetParamGroupCount()
    local paramgroups = {}
    for i = 0,paramgroupcount-1 do
        local groupsize = granny:GetParamGroupSize(i)
        local arr = {}
        for j = 0,groupsize-1 do
            local key,value = granny:GetParam(i,j)
            --print(i,key,value,maintextchunk[key],maintextchunk[value])
            arr[maintextchunk[key]] = maintextchunk[value]
        end
        paramgroups[i] = arr
    end
    granny.paramgroups = paramgroups
    return paramgroups
end

-- index is 0 by default, more than one texture per granny is currently not supported
function GetGrannyTextureName (granny,index)
    index = index or 0
    local paramgroups = GetGrannyParamGroups(granny)
    local texid = granny:GetTextureID(index)
    local texpath = paramgroups[texid-1] and paramgroups[texid-1]["__FileName"]
    --~ print("texpath",texpath)
    if (texpath) then 
        if gbUseUoDdsMaps then
            return string.gsub(basename(texpath),"\\.tga","\\.dds")
        else
            return basename(texpath)
        end
    end
end

gGrannyMeshCache = {}
function GetGrannyMeshName (modelid,skeletonname,hue)
	--~ print("GetGrannyMeshName",modelid,skeletonname,hue)
    modelid = GrannyOverride(modelid)
    local cachename = modelid.."_"..hue
    local cache = gGrannyMeshCache[cachename] 
    if (cache ~= nil) then return cache end
    
    -- not in cache, so create mesh
    local mygranny = GetGrannyModelLoader(modelid)
    if (not mygranny) then gGrannyMeshCache[modelid] = false return end
    --~ CheckGrannyModel(mygranny)
    local matname = GetGrannyMat(modelid,hue,mygranny)

    local meshname = mygranny:CreateOgreMesh(matname,skeletonname)
    gGrannyMeshCache[cachename] = meshname
    return meshname
end

gGrannyModelLoaderCache = {}
function GetGrannyModelLoader (modelid)
    local cache = gGrannyModelLoaderCache[modelid]
    if (cache ~= nil) then return cache end
    local modelinfo = GetGrannyModelInfo(modelid)
    if (not modelinfo) then gGrannyModelLoaderCache[modelid] = false return false end
    local modelpath = CorrectGrannyPath(gGrannyTypeDirs[modelinfo.typeid] .. modelinfo.modelname .. "_LOD2.grn")
    printdebug("granny","GetGrannyModelLoader",modelid,modelpath)
    local loader = LoadGranny(modelpath)
    gGrannyModelLoaderCache[modelid] = loader
    return loader
end

function LoadGrannyModelInfo (filepath) 
    local grannymodelinfo = {}
    local fieldnames = {"bodyid","typeid","animid","defhue","hand","scalex","scaley","scalez","modelname"}
	if (not file_exists(filepath)) then return grannymodelinfo end
    for line in io.lines(filepath) do
        line = TrimNewLines(line)
        if (string.sub(line,1,1) ~= "#") then
            local tokens = strsplit("[\t ]+",line)
            if (table.getn(tokens) >= table.getn(fieldnames)) then 
                local info = {}
                --print(line)
                --for k,v in pairs(tokens) do print(k,v) end
                --for k,v in pairs(fieldnames) do print(k,v,tokens[k]) end
                for index,fieldname in pairs(fieldnames) do 
                    local v = tokens[index]
                    local num = tonumber(v)
                    if (num and v == ""..num) then v = num end
                    info[fieldname] = v
                end
                if (info.animid == 401) then table.insert(gGrannyModelsFemale1,info.bodyid) end
                if (string.find(string.lower(info.modelname),"female")) then table.insert(gGrannyModelsFemale2,info.bodyid) end
                
                local oldinfo = grannymodelinfo[info.bodyid]
                if (oldinfo) then
                    local equal = true
                    for k,v in pairs(oldinfo) do if (v ~= info[k]) then equal = false end end
                    if (false and not equal) then
                        print("granny double definition")
                        print("  ",vardump(oldinfo))
                        print("  ",vardump(info))
                    end
                end
                if ((not oldinfo) or info.hand <= oldinfo.hand) then
                    grannymodelinfo[info.bodyid] = info 
                end
            end
        end
    end
    
    if (gDisableScale) then for bodyid,info in pairs(grannymodelinfo) do info.scalex,info.scaley,info.scalez = 1,1,1 end end
    --print("gGrannyModelsFemale1",strjoin(",",gGrannyModelsFemale1))
    --print("gGrannyModelsFemale2",strjoin(",",gGrannyModelsFemale2))
    return grannymodelinfo
end

function GetGrannyModelInfo (modelid,bAllowBroken) 
    if (not gGrannyModelInfo) then 
        gGrannyModelInfo = LoadGrannyModelInfo( CorrectGrannyPath(gGrannyConfigFile) ) 
        --~ local kmax = 0
        --~ for k,v in pairs(gGrannyModelInfo) do kmax = math.max(kmax,k) end
        --~ print("GetGrannyModelInfo : maxmodelid = ",kmax,sprintf("0x%04x",kmax))
    end
    
    if (gBrokenGrannyModelIdList[modelid] and (not bAllowBroken)) then return nil end
    return gGrannyModelInfo[modelid]
end

gGrannyFilePathCache = MakeCache(function (modelinfo) return CorrectGrannyPath(gGrannyTypeDirs[modelinfo.typeid] .. modelinfo.modelname .. "_LOD2.grn") end)
function GetGrannyFilePath (modelid,bAllowBroken) 
	local modelinfo = GetGrannyModelInfo(modelid,bAllowBroken)
	return modelinfo and gGrannyFilePathCache[modelinfo]
end

function TestGranny (modelid)
    local info = GetGrannyModelInfo(modelid)
    print(modelid,vardump2(info))
end
