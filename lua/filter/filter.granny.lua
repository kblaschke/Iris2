-- ID Mapping (ArtID to GrannyID, or Ogre *.mesh + *.skeleton)
-- TODO: add individual Scaling for Grannys and Meshes

gGrannyFilter = {}

-- FILTER: Grannys
function GrannyOverride(bodyid)
	local o = gGrannyFilter[bodyid]
	return (o and o.grannyid) or gMountGrannyOverride[bodyid] or bodyid
end

function GrannyMeshOverride(bodyid)
	if (gGrannyFilter[bodyid]) then
		local meshname = gGrannyFilter[bodyid].meshname
		if (meshname) then
			--~ printdebug("granny","OverrideMesh: GrannyID to Mesh ",bodyid," -> ",meshname) -- might be executed very often here -> disabled for now
			return meshname
		end
	end
	return nil
end

-- custom models can be applyed instead to grannys, just tell the meshname
--for custom scaling use gGrannyFilter[400]	={scale={x=2,y=2,z=2}}

--gGrannyFilter[153]	={meshname="Lich.mesh"}
--gGrannyFilter[154]	={meshname="mummy.mesh"}
--gGrannyFilter[618]	={meshname="sword.mesh"}
--gGrannyFilter[577] = {meshname="shield.mesh"}

--gGrannyFilter[987]	={grannyid=400}
gGrannyFilter[257]	={grannyid=0xC8} -- dreadhorn ? replaced by standard horse
gGrannyFilter[0x114]	={grannyid=0x3c} -- chimera replaced by drake
gGrannyFilter[1987]	={grannyid=401}
gGrannyFilter[778]	={grannyid=16}
gGrannyFilter[292]	={grannyid=220}
gGrannyFilter[970]	={grannyid=402}
gGrannyFilter[780]	={grannyid=779}	-- a bog thing (too big scale)   (779=plantman)
gGrannyFilter[311]	={grannyid=310}	-- seg fault when loading (first on uodemise/trantor)   (310=witchwoman)

gGrannyCorpseFilter = {}
gGrannyCorpseFilter[39] = {newid=779} -- (779=plantman)
--[[
-- wrong animations - but raw model is displayed correct, so no animation should be played
gGrannyFilter[46]	={animbroken}	-- mf_dragon_rust ( Completely broken )
gGrannyFilter[122]	={animbroken}	-- equines_unicorn ( Completely broken )
gGrannyFilter[192]	={animbroken}	-- equines_unicorn_ethereal ( Completely broken )
gGrannyFilter[791]	={animbroken}	-- giant_beetle ( Completely broken )
gGrannyFilter[195]	={animbroken}	-- giant_beetle_ethereal ( Completely broken )
gGrannyFilter[30]	={animbroken}	-- harpies_harpy ( Completely broken )
gGrannyFilter[73]	={animbroken}	-- harpies_harpy_stone ( Completely broken )
gGrannyFilter[797]	={animbroken}	-- red dragon ( Completely broken )
gGrannyFilter[798]	={animbroken}	-- blue dragon ( Completely broken )
gGrannyFilter[39]	={animbroken}	-- ?? ( Completely broken )
gGrannyFilter[194]	={animbroken}	-- rideable dragon
gGrannyFilter[312]	={animbroken}	-- Completely broken
gGrannyFilter[313]	={animbroken}	-- Completely broken/Offset
gGrannyFilter[314]	={animbroken}	-- Completely broken
gGrannyFilter[315]	={animbroken}	-- Completely broken
gGrannyFilter[316]	={animbroken}	-- Completely broken
gGrannyFilter[789]	={animbroken}	-- size/wrong z
gGrannyFilter[169]	={animbroken}	-- Completely broken

-- nogfx
gGrannyFilter[786]	={animbroken}	-- chariot (no gfx)
gGrannyFilter[58]	={animbroken}	-- etherals_wisp (no gfx)
gGrannyFilter[164]	={animbroken}	-- etherals_energy_vortex (no gfx)
gGrannyFilter[165]	={animbroken}	-- etherals_wisp (no gfx)
]]--

--[[
ArtID:
221				
212
213
167
97
98
225
99
23
25
27
100
34
37
38 (invisible)
84
85
2
18
765
770
767 (wrong z)
769 (wrong z)
772 (wrong z)
773
17
41
181
182
775
840 (Invis/Missing)
841 (Invis/Missing)
842 (Invis/Missing)
790 (Invis/Missing)
152
70
71
72
319 
777
785 (upside down)
788 (size)
247
261 (Invis/Missing)
273 (Invis/Missing)
276
]]--
