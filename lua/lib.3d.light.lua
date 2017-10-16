--[[ ***** see Iris2 COPYING for license info ***** ]]--
--[[ \brief
		light stuff
]]--

gMergePointLights = true
gMergePointLightBlockSize = 32
gLightBlocks = {}
-- returns the block for the given x,y,z location
function GetMergePointLightBlock(x,y,z)
    local bx = math.floor(x/gMergePointLightBlockSize)
    local by = math.floor(y/gMergePointLightBlockSize)
    local k = bx.."_"..by
    
    if not gLightBlocks[k] then gLightBlocks[k] = CreateClassInstance(cPointLightBlock) end
    
    return gLightBlocks[k]
end


-- to merge multiple pointlights into one "bigger"
cPointLightBlock = CreateClass()

function cPointLightBlock:Init ()
    self.mCX = nil
    self.mCY = nil
    self.mCZ = nil
    self.mR = nil
    self.mlLight = {}
    self.mLightName = nil
    self.mDirty = false -- this is true if the light positions need an update
end

function Renderer3D.CalculatePointLightAttenuation (radius)
	local r = radius
	local c = 1
	local l
	if r == 0 then l = 0 else l = 2/radius end
	local q = 0.0025
	return r*4, c, l, q
end

-- recalculate center and light parameter
-- on demand create and delete
function cPointLightBlock:UpdateLight ()
    local c = countarr(self.mlLight)
    
    if c == 0 and self.mLightName then
        -- destroy
        --~ print("REMOVE LIGHT",self)
        Client_RemoveLight(self.mLightName)
        self.mLightName = nil
    end
    
    if c > 0 and not self.mLightName then
        -- create
        --~ print("ADD LIGHT",self)
        self.mLightName = Client_AddPointLight(0,0,0, 1,1,1, 1,1,1, 1.0,0.5,0.5,0.0)
    end
    
    local minx,miny,minz,maxx,maxy,maxz
    
    if c > 0 and self.mLightName then
        local p = gCurrentRenderer:CalcPointLightValueDependingOnSun(1)
        Client_SetLightDiffuseColor(self.mLightName, p,p,p)
        Client_SetLightSpecularColor(self.mLightName, p,p,p)
        
        if self.mDirty then
            --~ print("UPDATE LIGHT",self,self.mLightName,c,p)
            -- recalc
            for k,v in pairs(self.mlLight) do
                minx = minx and math.min(minx,v.x) or v.x
                maxx = maxx and math.max(maxx,v.x) or v.x
                miny = miny and math.min(miny,v.y) or v.y
                maxy = maxy and math.max(maxy,v.y) or v.y
                minz = minz and math.min(minz,v.z) or v.z
                maxz = maxz and math.max(maxz,v.z) or v.z
            end
            local r = 0
            self.mCX = (maxx + minx) / 2
            self.mCY = (maxy + miny) / 2
            self.mCZ = (maxz + minz) / 2
            self.mR = math.max(maxx-minx,maxy-miny,maxz-minz)
            --~ print("cPointLightBlock:UpdateLight",self.mLightName,self.mCX,self.mCY,self.mCZ,self.mR,c)
            Client_SetLightPosition(self.mLightName, self.mCX, self.mCY, self.mCZ)  
            Client_SetLightAttenuation(self.mLightName, Renderer3D.CalculatePointLightAttenuation(self.mR))
            Light_SetCastShadows(self.mLightName, gLightsCastShadows)
            self.mDirty = false
        end
    end
end

function cPointLightBlock:AddLight (x,y,z)
    self.mlLight[x.."_"..y.."_"..z] =  {x=x,y=y,z=z}
    self.mDirty = true
    self:UpdateLight()
end

function cPointLightBlock:RemoveLight (x,y,z)
    self.mlLight[x.."_"..y.."_"..z] = nil
    self.mDirty = true
    self:UpdateLight()  
end

function cPointLightBlock:Destroy ()
    self.mDirty = true
    self:UpdateLight()
end

-- ------------Renderer3D Lightlevels -----------------------------------------------

-- sets the global sunlight level, intensity=0 -> dark, intensity=1 -> bright
function Renderer3D:SetSunLight		(intensity) 
	self.mfSunLight = intensity
	self:UpdateLight()
end

-- sets the personal light level, intensity=0 -> dark, intensity=1 -> bright
function Renderer3D:SetPersonalLight		(mobile, intensity) 
	self.mfPersonalLight = intensity
	self:UpdateLight()
end

-- if ambient light is very intensitive reduce point light effect
function Renderer3D:CalcPointLightValueDependingOnSun	(p)
	local a = self.mfSunLight or 0
	return Clamp(p - a, 0, 1)
end

function Renderer3D:UpdateLight	()
	local a = self.mfSunLight or 0
	local p = self.mfPersonalLight or 0
	
	local x,y,z = gTileFreeWalk:GetExactLocalPos()
	
	-- create personal light on demand
	if not self.mPersonalLightName then
		self.mPersonalLightName = Client_AddPointLight(
			x-0.5,y+0.5,z+1, 	-- pos
			1,1,1, 				-- diffuse
			1,1,1, 				-- specular
			5.0,0.5,0.5,0.0)		-- attenuation
	end

	--~ print("LIGHT1","a",a,"p",p)
	-- calc light values
	a = Clamp(a,0,1)
	p = self:CalcPointLightValueDependingOnSun(p)
	--~ print("LIGHT2","a",a,"p",p)

	-- update personal light
	Client_SetLightPosition(self.mPersonalLightName, x,y,z+2)
	Client_SetLightDiffuseColor(self.mPersonalLightName, p,p,p)
	Client_SetLightSpecularColor(self.mPersonalLightName, p,p,p)
	Client_SetLightAttenuation(self.mPersonalLightName, Renderer3D.CalculatePointLightAttenuation(5))
	Light_SetCastShadows(self.mPersonalLightName, false)
	
	-- look at lib.light.lua for SetupWorldLight_Default ()
	if not(gUseCaelumSkysystem) then
		-- update directional Sun Light
		if gDirectionalLightSun and gSunLightDirection then
			local xyz = gSunLightDirection		
			
			local rgb = gSunLightDiffuse		
			Client_SetLightDiffuseColor(gDirectionalLightSun,rgb.r*a,rgb.g*a,rgb.b*a)
			
			local rgb = gSunLightSpecular		
			Client_SetLightSpecularColor(gDirectionalLightSun,rgb.r*a,rgb.g*a,rgb.b*a)
		end

		-- update ambient light
		if gAmbientLight then
			Client_SetAmbientLight(gAmbientLight.r*a, gAmbientLight.g*a, gAmbientLight.b*a,1)
		end
	end
end

-- ------------------- PointLight ----------------------------------------------
function Renderer3D:AddStandartUOPointLight	(x,y,z,r)
	r = r or 5
	local zd = 0 -- 16
	return self:AddPointLight(
		x-0.5,y+0.5,z+1+zd, 	-- pos
		1,1,1, 			-- diffuse
		1,1,1, 			-- specular
		Renderer3D.CalculatePointLightAttenuation(r))		-- attenuation
end

-- adds a point light source
-- Diffuse dr,dg,db
-- Specular sr,sg,sb
-- Attenuation ar,ag,ab,aa
function Renderer3D:AddPointLight	(x,y,z, dr,dg,db, sr,sg,sb, ar,ag,ab,aa)
	local name
	if gMergePointLights then
		name = x.."_"..y.."_"..z
		GetMergePointLightBlock(x,y,z):AddLight(x,y,z)
	else
		name = Client_AddPointLight(x,y,z, dr,dg,db, sr,sg,sb, ar,ag,ab,aa)
		Light_SetCastShadows(name, gLightsCastShadows)
	end
	
	if gShowLightDebug then
		-- create mesh and debug marker list
		if not gLightDebugMesh then
			local r = 0.25
			gLightDebugMesh = MakeSphereMesh(7,7,r,r,r)
			gLightDebugMeshList = {}
		end
		
		local gfx = CreateRootGfx3D()
		gfx:SetMesh(gLightDebugMesh)	
		gfx:SetMeshSubEntityMaterial(0,GetPlainColourMat(dr or 1,dg or 1,db or 0))	
		gfx:SetPosition(x, y, z)
		gLightDebugMeshList[name] = gfx
	end
	return name
end

function Renderer3D:RemovePointLight	(name)
	if gMergePointLights then
		local x,y,z = unpack(strsplit("_",name))
		GetMergePointLightBlock(x,y,z):RemoveLight(x,y,z)
	else
		Client_RemoveLight(name)
	end
	DestroyIfAlive(gLightDebugMeshList and gLightDebugMeshList[name])
end
