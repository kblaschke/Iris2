--[[ ***** see Iris2 COPYING for license info ***** ]]--
--[[ \brief
		to be use with cadunetree to generate dynamically Tree
]]--

--gobal tree params
-- TODO: put them into an array
Renderer3D.gTreeParameters = nil
Renderer3D.gTreeStemParameters = nil
function Renderer3D:GenerateCaduneTree(entity)
	local iTileTypeID = entity.iTileTypeID
	-- just to test the cadunetree generation code
	if (not self.gTreeParameters) then
		self.gTreeParameters = CreateCaduneTreeParameters()
		self.gTreeStemParameters = CreateCaduneTreeStem(self.gTreeParameters)
		self.gTreeStemParameters:Grow()
	end
	if (iTileTypeID == 3296) then
		print("generate tree")
		entity.gfx = self.gTreeStemParameters:CreateGeometry()
		entity.x,entity.y,entity.z = self:UOPosToLocal(entity.xloc+1,entity.yloc+0.5,entity.zloc*0.1)
		entity.gfx:SetOrientation( QuaternionFromString("x:90,y:0,z:0") )
		entity.gfx:SetPosition(entity.x,entity.y,entity.z)
		entity.gfx:SetScale(0.4,0.4,0.5)
		entity.gfx:SetNormaliseNormals(true)
		-- disabled, just for testing
-- print("export tree bark")
-- ExportMesh(entity.gfx ,"tree_"..iTileTypeID..".mesh")
-- entity.gfx:Destroy()
-- entity.gfx = nil
	end
	if (iTileTypeID == 3297) then
		print("generate leaves")
		entity.gfx = self.gTreeStemParameters:CreateLeaves()
		entity.x,entity.y,entity.z = self:UOPosToLocal(entity.xloc+1,entity.yloc+0.5,entity.zloc*0.1)
		entity.gfx:SetOrientation( QuaternionFromString("x:90,y:0,z:0") )
		entity.gfx:SetPosition(entity.x,entity.y,entity.z)
		entity.gfx:SetScale(0.4,0.4,0.5)
		entity.gfx:SetNormaliseNormals(true)
	end
end
