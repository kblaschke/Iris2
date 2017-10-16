-- generates lua binding code for quickwrap/quickbind system
-- TODO: scenemanager : SceneManager : PushOGRE_MUTEX(sceneGraphMutex)String,			getName
-- TODO: ,(ParamLight::LightTypes(L,2),ParamInt(L,3))  Light::LightTypes   ParamLightTypes
-- TODO:LUABIND_PrefixConstant(Ogre::SceneManager,SCRQM_INCLUD)  -- E fehlt  SCRQM_INCLUDE,

gBoundPointerClasses = {}
function Main ()
	local basepath = "/usr/local/include/OGRE/"
	
	local classes = {		
							
							{basepath.."OgreMovableObject.h"		,"MovableObject"		,{}},
							{basepath.."OgreRenderable.h"			,"Renderable"			,{}},
							{basepath.."OgreResource.h"				,"Resource"				,{}},
							{basepath.."OgreNode.h"					,"Node"					,{"Renderable"}},
							
							{basepath.."OgreLight.h"				,"Light"				,{"MovableObject"}},	
							{basepath.."OgreSceneManager.h"			,"SceneManager"			,{}},
							{basepath.."OgreFrustum.h"				,"Frustum"				,{}},
							{basepath.."OgreCamera.h"				,"Camera"				,{"Frustum"}}, -- Renderable,MovableObject}
							{basepath.."OgreSceneNode.h"			,"SceneNode"			,{"Node","Renderable"}},
							{basepath.."OgreVertexIndexData.h"		,"VertexData"			,{}},
							{basepath.."OgreVertexIndexData.h"		,"IndexData"			,{}},
								
							{basepath.."OgreSkeleton.h"				,"Skeleton"				,{"Resource"}},
							{basepath.."OgreBone.h"					,"Bone"					,{"Node","Renderable"}},
							{basepath.."OgreAnimation.h"			,"Animation"			,{}},
							{basepath.."OgreMesh.h"					,"Mesh"					,{"Resource"}},
							{basepath.."OgreSubMesh.h"				,"SubMesh"				,{}},
										
							{basepath.."OgreSubEntity.h"			,"SubEntity"			,{"Renderable"}},
							{basepath.."OgreEntity.h"				,"Entity"				,{"MovableObject"}},
							{basepath.."OgreAnimationTrack.h"		,"AnimationTrack"		,{}},
							{basepath.."OgreAnimationTrack.h"		,"NodeAnimationTrack"	,{"AnimationTrack"}},
							{basepath.."OgreAnimationState.h"		,"AnimationState"		,{}},
							
							{basepath.."OgreKeyFrame.h"				,"KeyFrame"				,{}},
							{basepath.."OgreKeyFrame.h"				,"NumericKeyFrame"		,{"KeyFrame"}},
							{basepath.."OgreKeyFrame.h"				,"TransformKeyFrame"	,{"KeyFrame"}},
							{basepath.."OgreKeyFrame.h"				,"VertexMorphKeyFrame"	,{"KeyFrame"}},
							{basepath.."OgreKeyFrame.h"				,"VertexPoseKeyFrame"	,{"KeyFrame"}},
							
							{basepath.."OgreImage.h"				,"Image"				,{}},
							{basepath.."OgreTexture.h"				,"Texture"				,{"Resource"}},
							
							{basepath.."OgreMaterial.h"				,"Material"				,{}},
							{basepath.."OgreTechnique.h"			,"Technique"			,{}},
							{basepath.."OgrePass.h"					,"Pass"					,{}},
							{basepath.."OgreTextureUnitState.h"		,"TextureUnitState"		,{}},
							
							{basepath.."OgreRenderOperation.h"		,"RenderOperation"},	-- custom binding made, not good for auto-bind
							{basepath.."OgreHardwareVertexBuffer.h"	,"VertexDeclaration"},	-- custom binding made, not good for auto-bind
							--~ GenerateBinding(RobMovable,{MovableObject})
							--~ GenerateBinding(RobRenderable,{Renderable})
							
							{basepath.."OgreViewport.h"				,"Viewport"				,{}},
							
						}
						
	-- register types and prepare
	for k,arr in pairs(classes) do
		local filepath,classname,parentclassnames = unpack(arr)
		gBoundPointerClasses[classname] = true
	end
	RegisterVarTypes()
	
	for k,arr in pairs(classes) do
		local filepath,classname,parentclassnames = unpack(arr)
		local c = {}
		c.code = LoadHeader(filepath,classname)
		c.classname = classname
		_G[classname] = c
	end
	
	gOutLines = {}

	
	-- generate bindings here
	for k,arr in pairs(classes) do
		local filepath,classname,parentclassnames = unpack(arr)
		local parentclasses = {}
		for k,parentclassname in ipairs(parentclassnames or {}) do table.insert(parentclasses,_G[parentclassname]) end
		GenerateBinding(_G[classname],parentclasses)
	end
	
	-- output to file
	local outlines = {}
	
	-- lugre_luabind_ogrehelper.h :  ParamX PushX
	table.insert(outlines,"")
	table.insert(outlines,"/// mylugre/include/lugre_luabind_ogrehelper.h :")
	for k,arr in pairs(classes) do
		local name = arr[2]
		table.insert(outlines,"LUABIND_DIRECTWRAP_HELPER_OBJECT_PREFIX(Ogre		,"..name.."			)")
	end
	table.insert(outlines,"")
	table.insert(outlines,"")
	
	-- equalize tabs from binding to make the code look nice
	for k,line in pairs(MyEqualizeTabs(gOutLines)) do table.insert(outlines,line) end
	
	-- register classes in lua state
	table.insert(outlines,"/// lua binding")
	table.insert(outlines,"void	LuaRegister_LuaBinds_Ogre 	(lua_State *L) { PROFILE")
	table.insert(outlines,"	// needed first as baseclasses")
	for k,arr in pairs(classes) do
		local name = arr[2]
		table.insert(outlines,"	cLuaBindDirect<Ogre::"..name.."		>::GetSingletonPtr(new cLugreLuaBind_Ogre_"..name.."(		))->LuaRegister(L);")
	end
	table.insert(outlines,"	LUABIND_QUICKWRAP_STATIC(getMaximumDepthInputValue, { return PushNumber(L,Ogre::Root::getSingleton().getRenderSystem()->getMaximumDepthInputValue()); });")
	table.insert(outlines,"}")

	
	outlines = table.concat(outlines,"\n")
	print(outlines)
	local filepath = "luabindheader.out"
	FilePutContents(filepath,outlines)
	print("// output also written to ",filepath," to conserve tabs")
end


function LoadHeader (filepath,classname)
	local txt = FileGetContents(filepath)
	assert(txt and #txt > 0,"failed to load "..filepath)
	
	-- class _OgreExport MovableObject : public ShadowCaster, public AnimableObject, public MovableAlloc {
	local a,b,code = string.find(txt,"class[^{;:]+"..classname.."[^{;]*(%b{})")  assert(code)  -- firstspaces: : to avoid inheritance, problems with namespaces, subclasses etc ?
	code = "private: "..string.sub(code,2,-2) -- default visibility is private, so append it at the beginning, will be removed accordingly by ParseAndNormalize() . also remove {}
	--~ print("##########\n"..table.concat(ParseAndNormalize(code),"\n").."\n##########")
	--~ os.exit(0)
	return code
end 

function FileGetContents (filepath) -- returns the contents as one big string
	local fp = io.open(filepath,"rb")
	if (not fp) then return end
	local res = fp:read("*a")
	fp:close()
	return res
end


function RegisterVarTypes ()
	gPusher = {}
	gPusher.float				="PushNumber"
	gPusher.Real				="PushNumber"
	gPusher.bool				="PushBool"

	gReader = {}
	gReader.float				="ParamNumber"
	gReader.Real				="ParamNumber"
	gReader.bool				="ParamBool"
	
	-- ParamTypename and PushTypename directly available
	gDirectWrappedTypes = {} 
	gDirectWrappedTypes.String			= true
	gDirectWrappedTypes.Quaternion		= true
	gDirectWrappedTypes.Vector2			= true
	gDirectWrappedTypes.Vector3			= true
	gDirectWrappedTypes.Vector4			= true
	gDirectWrappedTypes.Matrix4			= true
	gDirectWrappedTypes.AxisAlignedBox	= true
	gDirectWrappedTypes.Radian			= true
	gDirectWrappedTypes.ColourValue		= true
	for k,v in pairs(gDirectWrappedTypes) do 
		gPusher[k] = "Push"..k
		gReader[k] = "Param"..k
	end
	
	gCopyConstructed = {}
	gCopyConstructed.Image = true
	for k,v in pairs(gCopyConstructed) do 
		gPusher[k] = "PushCopy"..k
	end

	-- gBoundPointerClasses
	gBoundPointerClasses.RenderQueue		= true
	gBoundPointerClasses.RenderOperation	= true
	gBoundPointerClasses.Viewport			= true
	for k,v in pairs(gBoundPointerClasses) do 
		gPusher[k.."*"] = "Push"..k
		gReader[k.."*"] = "Param"..k
		gReader[k]		= "ParamByRef"..k
	end
	

	-- inttypes 
	gIntTypes = {}
	gIntTypes.int				=true
	gIntTypes.uint8				=true
	gIntTypes.uint32			=true
	gIntTypes.size_t			=true
	gIntTypes.long				=true
	gIntTypes.ulong				=true
	gIntTypes.short				=true
	gIntTypes.uchar				=true
	gIntTypes.uint				=true
	gIntTypes.ushort			=true
	for k,v in pairs(gIntTypes) do 
		gPusher[k] = "PushNumber"
		gReader[k] = "ParamInt"
	end
	
	-- enum types
	gEnumTypes = {}
	gEnumTypes.TransformSpace					=true
	gEnumTypes.ProjectionType					=true
	gEnumTypes.PolygonMode						=true
	gEnumTypes.FogMode							=true
	gEnumTypes.ShadowTechnique					=true
	gEnumTypes.PixelFormat						=true
	gEnumTypes.LightTypes						=true
	gEnumTypes.SpecialCaseRenderQueueMode		=true
	gEnumTypes.TextureType						=true
	for k,v in pairs(gEnumTypes) do 
		gPusher[k] = "PushNumber"
		gReader[k] = "Param"..k
	end
end



function GenerateBinding (classData,parentlist) 
	local sBindingName = classData.classname
	local code,enums = ParseAndNormalize(classData.code)
	
	print("#############")
	local outlines = gOutLines
	sBindingName = sBindingName or "UnnamedBinding"
	table.insert(outlines,{"class cLugreLuaBind_Ogre_"..sBindingName.." : public cLuaBindDirect<Ogre::"..sBindingName..">, public cLuaBindDirectOgreHelper { public:"})
	table.insert(outlines,{"\tvirtual void RegisterMethods	(lua_State *L) { PROFILE"})
	
	-- baseclass
	local parentlines = {}
	for k1,parentClassData in pairs(parentlist or {}) do 
		table.insert(outlines,{"\t\tLUABIND_DIRECTWRAP_BASECLASS(Ogre::"..parentClassData.classname..");"})
		table.insert(outlines,{"\t\t"})
		for k2,parentline in pairs(ParseAndNormalize(parentClassData.code)) do 
			table.insert(parentlines,parentline)
		end
	end
	
	-- methods
	gMethodNameOverloadCounter = {}
	for k,line in pairs(code) do 
		if (line == "") then 
		elseif (line == ";") then 
		elseif (in_array(line,parentlines)) then 
			local text = "\t\t// in parent: " .. line
			table.insert(outlines,{text})
		else 
			table.insert(outlines,LineToLuaBind(line,"\t\t"))
		end
	end
	
	-- enums
	table.insert(outlines,{"\t\t"})
	for enumname,values in pairs(enums) do 
		for k,valuename in pairs(values) do 
			table.insert(outlines,{"\t\tLUABIND_PrefixConstant(Ogre::"..sBindingName..","..valuename..")"})
		end 
	end
	
	
	table.insert(outlines,{"\t}"})
	table.insert(outlines,{'\tvirtual const char* GetLuaTypeName () { return "lugre.ogre.'..sBindingName..'"; }'})
	table.insert(outlines,{"};"})
	table.insert(outlines,{""})
	--~ print("############# types:")
	--~ print(table.concat(gTypes,"\n"))
	--~ print(table.concat(code,"\n"))
end


-- Split text into a list consisting of the strings in text,
-- separated by strings matching delimiter (which may be a pattern). 
-- example: strsplit(",%s*", "Anna, Bob, Charlie,Dolores")
function strsplit(delimiter, text)
  local list = {}
  local pos = 1
  if string.find("", delimiter, 1) then -- this would result in endless loops
    error("delimiter matches empty string!")
  end
  while 1 do
    local first, last = string.find(text, delimiter, pos)
    if first then -- found?
      table.insert(list, string.sub(text, pos, first-1))
      pos = last+1
    else
      table.insert(list, string.sub(text, pos))
      break
    end
  end
  return list
end

function in_array (needle,haystack) 
	assert(type(haystack) == "table")
	for k,v in pairs(haystack) do if (v == needle) then return true end end
	return false
end




gTypes = {}
function RegisterType (s) s = NormalizeType(s) if (not in_array(s,gTypes)) then table.insert(gTypes,s) end end 

function NormalizeType (s) return string.gsub(s,"&","") end
function LineToLuaBind (line,prefix)
	local a,b,ret,name,params = string.find(line,"(.+) ([^ %(]+)%((.*)%)")
	if (not a) then return {prefix.."// unknown syntax:"..line} end
	RegisterType(ret)
	local retpush = gPusher[NormalizeType(ret)]
	local bReturnVoid = ret == "void"
	local bCommentedOut = false
	if ((not retpush) and (not bReturnVoid)) then 
		retpush = "Push"..ret
		bCommentedOut = true
		--~ bCommentedOut = NormalizeType(ret)
	end
	
	local paramtext = {}
	if (params ~= "void") then
		params = strsplit(",",params)
		for k,param in pairs(params) do 
			param = string.gsub(param," [^ ]+","") -- remove name
			local reader = gReader[NormalizeType(string.gsub(param,"^.+::",""))]
			if (reader) then 
				param = reader.."(L,"..(k+1)..")"
			elseif (param ~= "") then
				bCommentedOut = true
				--~ bCommentedOut = NormalizeType(string.gsub(param,"^.+::",""))
				param = "Param"..param.."(L,"..(k+1)..")"
			end
			table.insert(paramtext,param)
		end
	end
	paramtext = table.concat(paramtext,",")
	
	-- name-overloading : count the number of times a methodname occurs, and append number to name to avoid overloading (performance problems?)
	local namec = (gMethodNameOverloadCounter[name] or 0) + 1
	gMethodNameOverloadCounter[name] = namec
	local nameadd = ""
	if (namec > 1) then nameadd = namec end
	
	local prefix2 = bCommentedOut and "//~ " or ""
	--~ local prefix2 = bCommentedOut and ("//~ ("..tostring(bCommentedOut)..")") or ""
	
	if (bReturnVoid) then
		return {prefix..prefix2.."LUABIND_DIRECTWRAP_RETURN_VOID_NAMEADD(",	"",					""..name..","..nameadd,		",("..paramtext..")\t);"}
	else                                                                   
		return {prefix..prefix2.."LUABIND_DIRECTWRAP_RETURN_ONE_NAMEADD(",	""..retpush..",",	""..name..","..nameadd,		",("..paramtext..")\t);"}
	end
end

function MyEqualizeTabs (linelist) 
	local tablen = 4
	local cols = {}
	for k,line in ipairs(linelist) do 
		for k2,col in ipairs(line) do 
			if (#line ~= 1) then 
				cols[k2] = math.max(cols[k2] or 0, math.ceil(string.len(col)/tablen)+2 )
			end
		end
	end
	
	local res = {}
	for k,line in ipairs(linelist) do 
		local outline = {}
		for k2,col in ipairs(line) do 
			local addtabs = cols[k2] - math.floor(string.len(col)/tablen)
			if (k2 == #line) then addtabs = 0 end
			--~ table.insert(outline,col.."<"..cols[k2]..">") 
			table.insert(outline,col.. string.rep("\t",addtabs)) 
		end
		table.insert(res,table.concat(outline,""))
	end
	return res
end

function FilePutContents (filepath,data) -- writes the file contents from one big string
	local fp = io.open(filepath,"wb")
	fp:write(data)
	fp:close()
end

function RemoveAll (txt,pat_start,list_pat_end) 
	local startpos
	while true do 
		local a,b = string.find(txt,pat_start,startpos)
		if (not a) then return txt end -- end
		startpos = a
		local c,d
		for k,pat_end in ipairs(list_pat_end) do 
			local e,f = string.find(txt,pat_end,b+1)
			if (e and ((not c) or e < c)) then c,d = e,f end -- take earliest
		end
		--~ print("RemoveAll:found",pat_start,a,b,"end:",c)
		if (c) then
			txt = string.sub(txt,1,a-1) .. string.sub(txt,c)
		else -- end reached
			txt = string.sub(txt,1,a-1)
		end
	end
	return txt
end
--~ local test = "private:PrivA;protected:Prot1;public:PubA;public:PubA;protected:Prot2;private:PrivB;protected:Prot3;"
--~ test = RemoveAll(test,access[2],access)
--~ test = RemoveAll(test,access[3],access)
--~ print(test)
--~ os.exit(0)

function ParseAndNormalize (code) 
	local access = {"public%s*:","private%s*:","protected%s*:"} -- access/visibility
	
	-- remove comments
	code = string.gsub(code,"//[^\n]*","") 
	code = string.gsub(code,"#","") 
	code = string.gsub(code,"/%*","#")  -- remove block comments
	code = string.gsub(code,"%*/","#") 
	code = string.gsub(code,"%b##","") 
	
	local enums = {}
	for enumname,subcode in string.gmatch(code,"enum%s+([^%s;{]+)[^;]*(%b{})") do
		--~ print("enum",enumname)
		local enum = {}
		enums[enumname] = enum
		--~ print("==========\n"..subcode.."\n==============")
		for valuename in string.gmatch(string.sub(subcode,2,-2),"([^%s=,]+)[^,]*") do 
			--~ print(" ",valuename) 
			table.insert(enum,valuename)
		end
	end

	-- enum LightTypes { LT_POINT = 0, };
	
	code = string.gsub(code,"%b{}",";") -- balanced : remove code (avoid interferance with private: ...
	code = RemoveAll(code,access[2],access) -- private should be filtered out
	code = RemoveAll(code,access[3],access) -- protected should be filtered out
	
	code = string.gsub(code,"public:","")
	code = string.gsub(code,"private:","")
	code = string.gsub(code,"protected:","")
	code = string.gsub(code,"virtual","")
	code = string.gsub(code,"const","")
	code = string.gsub(code,"static","")
	code = string.gsub(code,"unsigned","")
	code = string.gsub(code,"&","")
	code = string.gsub(code,"Ogre::","")
	code = string.gsub(code,"OGRE_MUTEX%b()","")
	
	
	code = string.gsub(code,"%*","* ") -- paramname workaround : add whitespace
	code = string.gsub(code,"%&","& ") -- paramname workaround : add whitespace
	
	code = string.gsub(code,"%b{}",";") -- balanced : remove code
	code = string.gsub(code,'%b""',"0") -- balanced : remove strings
	code = string.gsub(code,"=[^,);]+","") -- remove default values and abstract  =0;
	code = string.gsub(code,"[ \t\n\r]+"," ") -- summarize whitespaces and remove newlines
	code = string.gsub(code,"^ ","") -- 
	code = string.gsub(code," *([,%)%(]) *","%1") -- remove whitespace doublesided 
	code = string.gsub(code," *([&%*])","%1") -- remove whitespace before 
	code = string.gsub(code," *; *",";\n")
	return strsplit("\n",code),enums
end


Main()
