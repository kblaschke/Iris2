--This Array holds a list with modifications: map ArtIDs to another ArtID, Ogre-Mesh, Orientation, Position
--later we can change Scaling, tiledata entry, add particles or skeletons too
gArtFilter = {}

-- adds all the skipped meshes to the skip art fallback file
function InitArtFilter	()
	for k,v in pairs(gArtFilter) do
		if v.skip then
			RegisterSkippedArtBillboardFallBack(k)
		end
	end
end

--FILTER: map Mesh to other Mesh
function FilterMesh(iTranslatedTileTypeID)
	local f = gArtFilter[iTranslatedTileTypeID]
	if (f) then
		if (f.maptoid) then
			return gArtFilter[iTranslatedTileTypeID].maptoid
		end
	end
	return iTranslatedTileTypeID
end
function FilterOrientation(iTranslatedTileTypeID)
	local f = gArtFilter[iTranslatedTileTypeID]
	if (f) then
		if (f.rotation) then
			return QuaternionFromString(f.rotation)
		end
	end
	return nil
end

function FilterPositionXYZ(iTranslatedTileTypeID)
	local x = gArtFilter[iTranslatedTileTypeID] 
	if x then
		return x.xadd or 0, x.yadd or 0, x.zadd or 0
	else
		return 0,0,0
	end
end

gFilterSkipStatic = {}
function FilterSkipStatic (iTileTypeID)
	return gFilterSkipStatic[iTileTypeID] ~= nil
end

-- checks if the given tiletype is a water tile
function FilterIsStaticWater(iTileTypeID)
	if (((iTileTypeID  >=  6038) and (iTileTypeID <=  6066)) or
		((iTileTypeID  >= 13422) and (iTileTypeID <= 13445)) or
		((iTileTypeID  >= 13460) and (iTileTypeID <= 13483)) or
		((iTileTypeID  >= 13493) and (iTileTypeID <= 13514))) then
		return true
	else
		return false
	end
end

----------------------------------------------------------------------

--armoire - left
--opened
gArtFilter[2636]={maptoid=2637}
--armoire - right
--opened
gArtFilter[2640]={maptoid=2637,rotation="x:0,y:0,z:90",xadd=0,yadd=1,zadd=0}
--closed
gArtFilter[2641]={maptoid=2637,rotation="x:0,y:0,z:90",xadd=0,yadd=1,zadd=0}

--armoire - left
--opened
gArtFilter[2638]={maptoid=2639}
--armoire - right
--opened
gArtFilter[2642]={maptoid=2639,rotation="x:0,y:0,z:90",xadd=0,yadd=1,zadd=0}
--closed
gArtFilter[2643]={maptoid=2639,rotation="x:0,y:0,z:90",xadd=0,yadd=1,zadd=0}


gArtFilter[3343]={maptoid=3340,rotation="x:0,y:0,z:90",xadd=0,yadd=1,zadd=0}
gArtFilter[3344]={maptoid=3342,rotation="x:0,y:0,z:90",xadd=0,yadd=1,zadd=0}
gArtFilter[3345]={maptoid=3341,rotation="x:0,y:0,z:90",xadd=0,yadd=1,zadd=0}

-- ceramic roof red
gArtFilter[9173]={maptoid=9172,rotation="x:0,y:0,z:90",xadd=0,yadd=1,zadd=0}

gArtFilter[9175]={maptoid=9174,rotation="x:0,y:0,z:90",xadd=0,yadd=1,zadd=0}
gArtFilter[9176]={maptoid=9174,rotation="x:0,y:0,z:180",xadd=1,yadd=1,zadd=0}
gArtFilter[9177]={maptoid=9174,rotation="x:0,y:0,z:-90",xadd=1,yadd=0,zadd=0}

gArtFilter[9180]={maptoid=9178,rotation="x:0,y:0,z:90",xadd=0,yadd=1,zadd=0}
gArtFilter[9181]={maptoid=9179,rotation="x:0,y:0,z:90",xadd=0,yadd=1,zadd=0}

gArtFilter[9182]={maptoid=9178,rotation="x:0,y:0,z:-90",xadd=1,yadd=0,zadd=0}
gArtFilter[9183]={maptoid=9179,rotation="x:0,y:0,z:-90",xadd=1,yadd=0,zadd=0}

gArtFilter[9184]={maptoid=9178,rotation="x:0,y:0,z:180",xadd=1,yadd=1,zadd=0}
gArtFilter[9185]={maptoid=9179,rotation="x:0,y:0,z:180",xadd=1,yadd=1,zadd=0}

gArtFilter[9186]={maptoid=9188,rotation="x:0,y:0,z:90",xadd=0,yadd=1,zadd=0}
gArtFilter[9190]={maptoid=9188,rotation="x:0,y:0,z:180",xadd=1,yadd=1,zadd=0}
gArtFilter[9192]={maptoid=9188,rotation="x:0,y:0,z:-90",xadd=1,yadd=0,zadd=0}

gArtFilter[9187]={maptoid=9189,rotation="x:0,y:0,z:90",xadd=0,yadd=1,zadd=0}
gArtFilter[9191]={maptoid=9189,rotation="x:0,y:0,z:180",xadd=1,yadd=1,zadd=0}
gArtFilter[9193]={maptoid=9189,rotation="x:0,y:0,z:-90",xadd=1,yadd=0,zadd=0}


-- wood
gArtFilter[7138]={maptoid=7135,rotation="x:0,y:0,z:-90",xadd=1,yadd=0,zadd=0}

-- ceramic roof blue
gArtFilter[9157]={maptoid=9155,rotation="x:0,y:0,z:-180",xadd=1,yadd=1,zadd=0}
gArtFilter[9153]={maptoid=9155,rotation="x:0,y:0,z:-90",xadd=1,yadd=0,zadd=0}
gArtFilter[9159]={maptoid=9155,rotation="x:0,y:0,z:90",xadd=0,yadd=1,zadd=0}

gArtFilter[9158]={maptoid=9156,rotation="x:0,y:0,z:-180",xadd=1,yadd=1,zadd=0}
gArtFilter[9154]={maptoid=9156,rotation="x:0,y:0,z:-90",xadd=1,yadd=0,zadd=0}
gArtFilter[9160]={maptoid=9156,rotation="x:0,y:0,z:90",xadd=0,yadd=1,zadd=0}

gArtFilter[9161]={maptoid=9163,rotation="x:0,y:0,z:90",xadd=0,yadd=1,zadd=0}
gArtFilter[9165]={maptoid=9163,rotation="x:0,y:0,z:-180",xadd=1,yadd=1,zadd=0}
gArtFilter[9167]={maptoid=9163,rotation="x:0,y:0,z:-90",xadd=1,yadd=0,zadd=0}

gArtFilter[9162]={maptoid=9164,rotation="x:0,y:0,z:90",xadd=0,yadd=1,zadd=0}
gArtFilter[9166]={maptoid=9164,rotation="x:0,y:0,z:180",xadd=1,yadd=1,zadd=0}
gArtFilter[9168]={maptoid=9164,rotation="x:0,y:0,z:-90",xadd=1,yadd=0,zadd=0}

gArtFilter[9171]={maptoid=9170,rotation="x:0,y:0,z:180",xadd=1,yadd=1,zadd=0}

gArtFilter[9152]={maptoid=9170,rotation="x:0,y:0,z:90",xadd=0,yadd=1,zadd=0}
gArtFilter[9151]={maptoid=9170,rotation="x:0,y:0,z:-90",xadd=1,yadd=0,zadd=0}
gArtFilter[9150]={maptoid=9169,rotation="x:0,y:0,z:90",xadd=0,yadd=1,zadd=0}

-- ceramic roof yellow
gArtFilter[10491]={maptoid=10489,rotation="x:0,y:0,z:-180",xadd=1,yadd=1,zadd=0}
gArtFilter[10487]={maptoid=10489,rotation="x:0,y:0,z:-90",xadd=1,yadd=0,zadd=0}
gArtFilter[10493]={maptoid=10489,rotation="x:0,y:0,z:90",xadd=0,yadd=1,zadd=0}

gArtFilter[10490]={maptoid=10488,rotation="x:0,y:0,z:-180",xadd=1,yadd=1,zadd=0}
gArtFilter[10486]={maptoid=10488,rotation="x:0,y:0,z:-90",xadd=1,yadd=0,zadd=0}
gArtFilter[10492]={maptoid=10488,rotation="x:0,y:0,z:90",xadd=0,yadd=1,zadd=0}

gArtFilter[10495]={maptoid=10497,rotation="x:0,y:0,z:90",xadd=0,yadd=1,zadd=0}
gArtFilter[10499]={maptoid=10497,rotation="x:0,y:0,z:180",xadd=1,yadd=1,zadd=0}
gArtFilter[10501]={maptoid=10497,rotation="x:0,y:0,z:-90",xadd=1,yadd=0,zadd=0}

gArtFilter[10494]={maptoid=10496,rotation="x:0,y:0,z:90",xadd=0,yadd=1,zadd=0}
gArtFilter[10498]={maptoid=10496,rotation="x:0,y:0,z:-180",xadd=1,yadd=1,zadd=0}
gArtFilter[10500]={maptoid=10496,rotation="x:0,y:0,z:-90",xadd=1,yadd=0,zadd=0}


-- stained glass windows brock wall stuff
gArtFilter[10660]={maptoid=10662}
gArtFilter[10661]={maptoid=10662}
gArtFilter[10663]={maptoid=10662}

gArtFilter[10664]={maptoid=10662,rotation="x:0,y:0,z:90",xadd=0,yadd=1,zadd=0}
gArtFilter[10665]={maptoid=10662,rotation="x:0,y:0,z:90",xadd=0,yadd=1,zadd=0}
gArtFilter[10666]={maptoid=10662,rotation="x:0,y:0,z:90",xadd=0,yadd=1,zadd=0}
gArtFilter[10667]={maptoid=10662,rotation="x:0,y:0,z:90",xadd=0,yadd=1,zadd=0}


gArtFilter[13941]={maptoid=13940,rotation="x:0,y:0,z:90",xadd=0,yadd=1,zadd=0}


gArtFilter[9533]={maptoid=9532}
gArtFilter[9534]={maptoid=9532}

gArtFilter[9940]={maptoid=9532,rotation="x:0,y:0,z:90",xadd=0,yadd=1,zadd=0}
gArtFilter[9941]={maptoid=9532,rotation="x:0,y:0,z:90",xadd=0,yadd=1,zadd=0}
gArtFilter[9942]={maptoid=9532,rotation="x:0,y:0,z:90",xadd=0,yadd=1,zadd=0}

gArtFilter[8661]={maptoid=167}
gArtFilter[8662]={maptoid=167}

gArtFilter[8663]={maptoid=167,rotation="x:0,y:0,z:90",xadd=0,yadd=2,zadd=0}
gArtFilter[8664]={maptoid=167,rotation="x:0,y:0,z:90",xadd=0,yadd=2,zadd=0}

-- roof tiles
gArtFilter[1372]={maptoid=1373,rotation="x:0,y:0,z:90",xadd=0,yadd=1,zadd=0}

-- sandstone
gArtFilter[387]={maptoid=386,rotation="x:0,y:0,z:-90",xadd=1,yadd=0,zadd=0}
gArtFilter[360]={maptoid=386,rotation="x:0,y:0,z:90",xadd=-0,yadd=1,zadd=0}
gArtFilter[372]={maptoid=386,rotation="x:0,y:0,z:180",xadd=1,yadd=1,zadd=0}

gArtFilter[389]={maptoid=388,rotation="x:0,y:0,z:-90",xadd=0.4,yadd=0,zadd=0}
gArtFilter[361]={maptoid=388,rotation="x:0,y:0,z:-90",xadd=1,yadd=0,zadd=0}
gArtFilter[362]={maptoid=388,rotation="x:0,y:0,z:0",xadd=0,yadd=0.6,zadd=0}

-- orc car
gArtFilter[6787]={maptoid=6792,rotation="x:0,y:0,z:-90",xadd=1,yadd=0,zadd=0}
gArtFilter[6786]={skip=true}
gArtFilter[6790]={skip=true}
gArtFilter[6791]={skip=true}

-- elvenchair
gArtFilter[11756]={maptoid=11755,rotation="x:0,y:0,z:180",xadd=1,yadd=1,zadd=0}
gArtFilter[11757]={maptoid=11755,rotation="x:0,y:0,z:270",xadd=1,yadd=0,zadd=0}
gArtFilter[11758]={maptoid=11755,rotation="x:0,y:0,z:90",xadd=0,yadd=1,zadd=0}

-- elventable
gArtFilter[11746]={maptoid=11745,rotation="x:0,y:0,z:90",xadd=0,yadd=-1,zadd=0}

-- lava
gArtFilter[6682]={maptoid=6681}
gArtFilter[6683]={maptoid=6681}
gArtFilter[6684]={maptoid=6681}
gArtFilter[6685]={maptoid=6681}

-- Blood
gArtFilter[4651]={maptoid=4650}
gArtFilter[4652]={maptoid=4650}
gArtFilter[4653]={maptoid=4650}
gArtFilter[4654]={maptoid=4650}
gArtFilter[4655]={maptoid=4650}

--Vegetation
-- hedge
gArtFilter[3218]={maptoid=3217}
gArtFilter[3216]={maptoid=3215}
gArtFilter[3513]={maptoid=3512}

-- grass
gArtFilter[3244]={maptoid=3253}
gArtFilter[3245]={maptoid=3253}
gArtFilter[3246]={maptoid=3253}
gArtFilter[3247]={maptoid=3253}
gArtFilter[3248]={maptoid=3253}
gArtFilter[3249]={maptoid=3253}
gArtFilter[3250]={maptoid=3253}
gArtFilter[3251]={maptoid=3253}
gArtFilter[3252]={maptoid=3253}
gArtFilter[3254]={maptoid=3253}
gArtFilter[3257]={maptoid=3253}
gArtFilter[3258]={maptoid=3253}
gArtFilter[3259]={maptoid=3253}
gArtFilter[3260]={maptoid=3253}
gArtFilter[3261]={maptoid=3253}
gArtFilter[3378]={maptoid=3253}
gArtFilter[3379]={maptoid=3253}
gArtFilter[3259]={maptoid=3253}
gArtFilter[3270]={maptoid=3253}
gArtFilter[3260]={maptoid=3253}
gArtFilter[3250]={maptoid=3253}
gArtFilter[3258]={maptoid=3253}
gArtFilter[3268]={maptoid=3253}
gArtFilter[3257]={maptoid=3253}
gArtFilter[3255]={maptoid=3253}
gArtFilter[3256]={maptoid=3253}
gArtFilter[3261]={maptoid=3253}

-- brambles
gArtFilter[3392]={maptoid=3391}

-- sandstone
gArtFilter[399]={maptoid=398,rotation="x:0,y:0,z:-90",xadd=-1.6,yadd=0,zadd=0}

-- fern / farne
gArtFilter[3233]={maptoid=3232}
gArtFilter[3234]={maptoid=3232}
gArtFilter[3235]={maptoid=3232}
gArtFilter[3236]={maptoid=3232}
gArtFilter[3231]={maptoid=3232}

-- barks
gArtFilter[3275]={maptoid=3274}
gArtFilter[3276]={maptoid=3274}
gArtFilter[3277]={maptoid=3274}
gArtFilter[3280]={maptoid=3274}
gArtFilter[3283]={maptoid=3274}
gArtFilter[3290]={maptoid=3274}
gArtFilter[3299]={maptoid=3274}
gArtFilter[3296]={maptoid=3274}
--gArtFilter[3297]={skip=true}	--leaves for 3296, just for testing caduntree

-- barks new
gArtFilter[3302]={maptoid=3274}
gArtFilter[3476]={maptoid=3274}
gArtFilter[3484]={maptoid=3274}
gArtFilter[3496]={maptoid=3274}
gArtFilter[3492]={maptoid=3274}
gArtFilter[3488]={maptoid=3274}
gArtFilter[3480]={maptoid=3274}
gArtFilter[3329]={maptoid=3274}
gArtFilter[3326]={maptoid=3274}
gArtFilter[3323]={maptoid=3274}
gArtFilter[3320]={maptoid=3274}

-- cedar tree
gArtFilter[3288]={maptoid=3286,xadd=0.8,yadd=-0.7,zadd=0}	-- cedarbark
gArtFilter[3289]={maptoid=3287,xadd=0.8,yadd=-0.7,zadd=0}	-- cedars

-- mushrooms
gArtFilter[3352]={maptoid=3351}
gArtFilter[3353]={maptoid=3351}
gArtFilter[3349]={maptoid=3350}

-- palm
gArtFilter[3222]={maptoid=3221}

--Rest
-- houseparts
gArtFilter[10761]={maptoid=10763}
gArtFilter[10759]={maptoid=10763,rotation="x:0,y:0,z:90",xadd=0,yadd=1.85,zadd=0}
gArtFilter[10757]={maptoid=10763,rotation="x:0,y:0,z:90",xadd=0,yadd=1.85,zadd=0}
gArtFilter[10760]={maptoid=10762,rotation="x:0,y:0,z:90",xadd=0,yadd=1.85,zadd=0}
gArtFilter[10758]={maptoid=10764,rotation="x:0,y:0,z:90",xadd=0,yadd=1.85,zadd=0}

gArtFilter[10013]={maptoid=10010,rotation="x:0,y:0,z:90",xadd=0,yadd=1.95,zadd=0}
gArtFilter[10014]={maptoid=10011,rotation="x:0,y:0,z:90",xadd=0,yadd=1.95,zadd=0}
gArtFilter[10015]={maptoid=10012,rotation="x:0,y:0,z:90",xadd=0,yadd=1.95,zadd=0}

gArtFilter[2242]={maptoid=2241,rotation="x:0,y:0,z:-90",xadd=1.9,yadd=0,zadd=0}
gArtFilter[2232]={maptoid=2237,rotation="x:0,y:0,z:0",xadd=1,yadd=0,zadd=0}
gArtFilter[2231]={maptoid=2237,rotation="x:0,y:0,z:90",xadd=0,yadd=0.9,zadd=0}
gArtFilter[2236]={maptoid=2237,rotation="x:0,y:0,z:90",xadd=0,yadd=0,zadd=0}
gArtFilter[2239]={maptoid=2238,rotation="x:0,y:0,z:0",xadd=0,yadd=0,zadd=0}
gArtFilter[2227]={maptoid=2228,rotation="x:0,y:0,z:-90",xadd=1,yadd=0,zadd=0}
gArtFilter[2226]={maptoid=2228,rotation="x:0,y:0,z:-90",xadd=0.1,yadd=0,zadd=0}
gArtFilter[2229]={maptoid=2228,rotation="x:0,y:0,z:0",xadd=0,yadd=0.9,zadd=0}

gArtFilter[2234]={maptoid=2238,rotation="x:0,y:0,z:0",xadd=0,yadd=0.9,zadd=0}
gArtFilter[2235]={maptoid=2238,rotation="x:0,y:0,z:-90",xadd=1,yadd=0,zadd=0}
gArtFilter[2233]={maptoid=2240,xadd=1,yadd=0.9,zadd=0}

gArtFilter[9345]={maptoid=9344,rotation="x:0,y:0,z:90",xadd=0,yadd=1.95,zadd=0}
gArtFilter[9348]={maptoid=9347,rotation="x:0,y:0,z:90",xadd=0,yadd=1.95,zadd=0}
gArtFilter[9351]={maptoid=9350,rotation="x:0,y:0,z:90",xadd=0,yadd=1.95,zadd=0}

-- boats
gArtFilter[16093]={xadd=  0,yadd=  0,zadd=-0.4}
gArtFilter[15962]={maptoid=16093,rotation="x:0,y:0,z:270",xadd=1.0,yadd=  0,zadd=-0.25}
gArtFilter[16098]={maptoid=16093,rotation="x:0,y:0,z:180",xadd=1.0,yadd=1.0,zadd=-0.25}
gArtFilter[15980]={maptoid=16093,rotation="x:0,y:0,z:90" ,xadd=  0,yadd=1.0,zadd=-0.25}

-- bones
gArtFilter[3792]={maptoid=3791,rotation="x:0,y:0,z:180",xadd=0,yadd=0,zadd=0}
gArtFilter[3794]={maptoid=3793,rotation="x:0,y:0,z:180",xadd=0,yadd=0,zadd=0}
gArtFilter[3789]={maptoid=3788,rotation="x:0,y:0,z:90",xadd=0,yadd=0,zadd=0}

-- bed
gArtFilter[4562]={xadd=-1.5,yadd=0,zadd=0}

--plate
gArtFilter[2519]={xadd=0,yadd=0,zadd=0.34}

-- flowers
gArtFilter[3239]={maptoid=3332}

--chimney
gArtFilter[2264]={maptoid=2269}
gArtFilter[2261]={maptoid=2269}
gArtFilter[2258]={maptoid=2269}
gArtFilter[2262]={skip=true}
gArtFilter[2257]={skip=true}
gArtFilter[2268]={skip=true}

-- portrait
gArtFilter[3784]={maptoid=3752}
gArtFilter[3785]={maptoid=3752}
gArtFilter[3749]={maptoid=3752}
gArtFilter[3750]={maptoid=3752,rotation="x:0,y:0,z:270",xadd=0,yadd=0,zadd=0}
gArtFilter[3743]={maptoid=3752,rotation="x:0,y:0,z:270",xadd=0,yadd=0,zadd=0}
gArtFilter[3744]={maptoid=3752,rotation="x:0,y:0,z:270",xadd=0,yadd=0,zadd=0}
gArtFilter[3756]={maptoid=3752,rotation="x:0,y:0,z:270",xadd=0,yadd=0,zadd=0}
gArtFilter[3757]={maptoid=3752,rotation="x:0,y:0,z:270",xadd=0,yadd=0,zadd=0}
gArtFilter[3751]={maptoid=3752,rotation="x:0,y:0,z:270",xadd=0,yadd=0,zadd=0}

-- lantern
gArtFilter[9412]={maptoid=9411}
gArtFilter[9409]={maptoid=9411,rotation="x:0,y:0,z:-90",xadd=-1,yadd=0,zadd=0}
gArtFilter[9410]={maptoid=9411,rotation="x:0,y:0,z:-90",xadd=-1,yadd=0,zadd=0}

gArtFilter[9414]={maptoid=9413}
gArtFilter[9415]={maptoid=9413,rotation="x:0,y:0,z:90",xadd=0,yadd=1,zadd=0}
gArtFilter[9416]={maptoid=9413,rotation="x:0,y:0,z:90",xadd=0,yadd=1,zadd=0}

-- gravestone & mud
gArtFilter[3799]={maptoid=3800,rotation="x:0,y:0,z:90",xadd=0,yadd=1,zadd=0}

gArtFilter[4463]={maptoid=4464,rotation="x:0,y:0,z:90",xadd=0,yadd=1,zadd=0}

gArtFilter[3806]={maptoid=3805,rotation="x:0,y:0,z:-90",xadd=1,yadd=0,zadd=0}

gArtFilter[3808]={skip=true}
gArtFilter[3809]={maptoid=3810,rotation="x:0,y:0,z:-90",xadd=1,yadd=0,zadd=0}
gArtFilter[3807]={skip=true}

-- flags
gArtFilter[5589]={maptoid=5588,rotation="x:0,y:0,z:90",xadd=0,yadd=0.9,zadd=0}

--hitching post
gArtFilter[5351]={rotation="x:0,y:0,z:90",xadd=0,yadd=1,zadd=0}
gArtFilter[5352]={maptoid=5351}

--wall
gArtFilter[670]={maptoid=671,rotation="x:0,y:0,z:90",xadd=0,yadd=1.85,zadd=0}

--zaun / fence
gArtFilter[2187]={maptoid=2186,rotation="x:0,y:0,z:90",xadd=0,yadd=1,zadd=0}


-- stone roof
gArtFilter[0x193c]={maptoid=0x5a3}
gArtFilter[0x193a]={maptoid=0x5a2}
gArtFilter[0x193b]={maptoid=0x597}
gArtFilter[0x1939]={maptoid=0x596}
gArtFilter[0x193d]={maptoid=0x5a1}
gArtFilter[0x193e]={maptoid=0x595}
                
----------------------------------------------------------------------
----------------------------------------------------------------------
-- generated from remove_duplicate_models.php script
gArtFilter[2579]={maptoid=2580}
gArtFilter[2578]={maptoid=2580}
gArtFilter[8296]={maptoid=2420}
gArtFilter[2106]={maptoid=2119}
gArtFilter[2600]={maptoid=2577}
gArtFilter[2576]={maptoid=2577}
gArtFilter[2575]={maptoid=2577}
gArtFilter[4492]={maptoid=2960}
gArtFilter[4494]={maptoid=2960}
gArtFilter[7595]={maptoid=2960}
gArtFilter[4558]={maptoid=2672}
gArtFilter[2205]={maptoid=2203}
gArtFilter[2204]={maptoid=2203}
gArtFilter[2375]={maptoid=2374}
gArtFilter[2376]={maptoid=2374}
gArtFilter[2371]={maptoid=2374}
gArtFilter[2377]={maptoid=2374}
gArtFilter[2378]={maptoid=2374}
gArtFilter[2373]={maptoid=2374}
gArtFilter[2008]={maptoid=2298}
gArtFilter[2894]={maptoid=2898}
gArtFilter[2932]={maptoid=2931}
gArtFilter[2096]={maptoid=2089}
gArtFilter[2092]={maptoid=2089}
gArtFilter[2869]={maptoid=2870}
gArtFilter[2970]={maptoid=2968}
gArtFilter[2107]={maptoid=2118}
gArtFilter[2151]={maptoid=2153}
gArtFilter[2138]={maptoid=2125}
gArtFilter[2134]={maptoid=2125}
gArtFilter[2326]={maptoid=2325}
gArtFilter[2327]={maptoid=2325}
gArtFilter[2328]={maptoid=2325}
gArtFilter[2830]={maptoid=2825}
gArtFilter[8314]={maptoid=2421}
gArtFilter[2160]={maptoid=2164}
gArtFilter[2872]={maptoid=2873}
gArtFilter[2896]={maptoid=2900}
gArtFilter[2137]={maptoid=2126}
gArtFilter[2130]={maptoid=2126}
gArtFilter[2139]={maptoid=2126}
gArtFilter[2440]={maptoid=2442}
gArtFilter[2818]={maptoid=2816}
gArtFilter[2817]={maptoid=2816}
gArtFilter[2831]={maptoid=2816}
gArtFilter[2595]={maptoid=2596}
gArtFilter[2594]={maptoid=2596}
gArtFilter[2129]={maptoid=2136}
gArtFilter[2132]={maptoid=2136}
gArtFilter[2581]={maptoid=2582}
gArtFilter[2583]={maptoid=2582}
gArtFilter[2128]={maptoid=2135}
gArtFilter[2124]={maptoid=2135}
gArtFilter[2110]={maptoid=2117}
gArtFilter[2111]={maptoid=2120}
gArtFilter[2155]={maptoid=2162}
gArtFilter[2158]={maptoid=2162}
gArtFilter[2404]={maptoid=2406}
gArtFilter[2405]={maptoid=2406}
gArtFilter[2399]={maptoid=2406}
gArtFilter[2403]={maptoid=2406}
gArtFilter[2402]={maptoid=2406}
gArtFilter[2401]={maptoid=2406}
gArtFilter[2156]={maptoid=2163}
gArtFilter[2165]={maptoid=2163}
gArtFilter[2152]={maptoid=2163}
gArtFilter[2823]={maptoid=2824}
gArtFilter[2154]={maptoid=2161}
gArtFilter[2150]={maptoid=2161}
gArtFilter[2958]={maptoid=2957}
gArtFilter[4496]={maptoid=2957}
gArtFilter[2967]={maptoid=2969}
gArtFilter[2357]={maptoid=2360}
gArtFilter[2361]={maptoid=2360}
gArtFilter[2347]={maptoid=2360}
gArtFilter[2255]={maptoid=2360}
gArtFilter[2362]={maptoid=2360}
gArtFilter[2363]={maptoid=2360}
gArtFilter[2364]={maptoid=2360}
gArtFilter[2359]={maptoid=2360}
gArtFilter[2588]={maptoid=2586}
gArtFilter[2587]={maptoid=2586}
gArtFilter[2143]={maptoid=2149}
gArtFilter[2712]={maptoid=2715}
gArtFilter[2895]={maptoid=2899}
gArtFilter[2201]={maptoid=2202}
gArtFilter[2206]={maptoid=2202}
gArtFilter[2901]={maptoid=2897}
gArtFilter[2519]={maptoid=2522}
gArtFilter[2521]={maptoid=2522}
gArtFilter[2523]={maptoid=2522}
gArtFilter[2479]={maptoid=2522}
gArtFilter[2585]={maptoid=2522}
gArtFilter[2478]={maptoid=2522}
gArtFilter[2520]={maptoid=2522}
gArtFilter[2939]={maptoid=2938}
gArtFilter[2097]={maptoid=2090}
gArtFilter[2099]={maptoid=2090}
gArtFilter[2086]={maptoid=2090}
gArtFilter[2573]={maptoid=2572}
gArtFilter[2574]={maptoid=2572}
gArtFilter[2570]={maptoid=2572}
gArtFilter[2085]={maptoid=2098}
gArtFilter[2094]={maptoid=2098}
gArtFilter[2084]={maptoid=2088}
gArtFilter[2095]={maptoid=2088}
gArtFilter[2297]={maptoid=2007}
gArtFilter[2266]={maptoid=2391}
gArtFilter[2392]={maptoid=2391}
gArtFilter[2389]={maptoid=2391}
gArtFilter[2385]={maptoid=2391}
gArtFilter[2387]={maptoid=2391}
gArtFilter[2390]={maptoid=2391}
gArtFilter[2388]={maptoid=2391}
gArtFilter[2713]={maptoid=2716}
gArtFilter[2951]={maptoid=2950}
gArtFilter[2567]={maptoid=2569}
gArtFilter[2565]={maptoid=2569}
gArtFilter[2568]={maptoid=2569}
gArtFilter[16007]={maptoid=16005}
gArtFilter[16083]={maptoid=16084}
gArtFilter[16085]={maptoid=16084}
gArtFilter[16009]={maptoid=16006}
gArtFilter[16004]={maptoid=16006}
gArtFilter[8573]={maptoid=8572}
gArtFilter[8582]={maptoid=8583}
gArtFilter[8577]={maptoid=8576}
gArtFilter[8571]={maptoid=8570}
gArtFilter[8568]={maptoid=8569}
gArtFilter[8174]={maptoid=8187}
gArtFilter[8183]={maptoid=8187}
gArtFilter[8179]={maptoid=8175}
gArtFilter[8188]={maptoid=8175}
gArtFilter[8186]={maptoid=8175}
gArtFilter[8581]={maptoid=8580}
gArtFilter[8767]={maptoid=8765}
gArtFilter[8773]={maptoid=8765}
gArtFilter[8764]={maptoid=8765}
gArtFilter[8763]={maptoid=8765}
gArtFilter[8775]={maptoid=8765}
gArtFilter[8774]={maptoid=8765}
gArtFilter[8768]={maptoid=8765}
gArtFilter[8766]={maptoid=8765}
gArtFilter[8770]={maptoid=8765}
gArtFilter[8772]={maptoid=8765}
gArtFilter[8771]={maptoid=8765}
gArtFilter[8776]={maptoid=8765}
gArtFilter[8762]={maptoid=8765}
gArtFilter[8777]={maptoid=8765}
gArtFilter[8769]={maptoid=8765}
gArtFilter[8578]={maptoid=8579}
gArtFilter[8575]={maptoid=8574}
gArtFilter[8171]={maptoid=8170}
gArtFilter[4840]={maptoid=4844}
gArtFilter[4195]={maptoid=4191}
gArtFilter[4126]={maptoid=4125}
gArtFilter[4124]={maptoid=4125}
gArtFilter[4210]={maptoid=4208}
gArtFilter[4212]={maptoid=4214}
gArtFilter[4260]={maptoid=4261}
gArtFilter[4262]={maptoid=4261}
gArtFilter[4193]={maptoid=4197}
gArtFilter[4493]={maptoid=4491}
gArtFilter[7591]={maptoid=4491}
gArtFilter[4838]={maptoid=4842}
gArtFilter[4615]={maptoid=4618}
gArtFilter[4123]={maptoid=4121}
gArtFilter[4122]={maptoid=4121}
gArtFilter[4619]={maptoid=4616}
gArtFilter[4483]={maptoid=4484}
gArtFilter[4119]={maptoid=4118}
gArtFilter[4117]={maptoid=4118}
gArtFilter[4843]={maptoid=4839}
gArtFilter[77]={maptoid=52}
gArtFilter[532]={maptoid=527}
gArtFilter[155]={maptoid=158}
gArtFilter[2296]={maptoid=103}
gArtFilter[135]={maptoid=123}
gArtFilter[924]={maptoid=321}
gArtFilter[483]={maptoid=480}
gArtFilter[856]={maptoid=852}
gArtFilter[854]={maptoid=852}
gArtFilter[865]={maptoid=852}
gArtFilter[863]={maptoid=852}
gArtFilter[858]={maptoid=852}
gArtFilter[867]={maptoid=852}
gArtFilter[8650]={maptoid=148}
gArtFilter[8645]={maptoid=148}
gArtFilter[8646]={maptoid=148}
gArtFilter[8649]={maptoid=148}
gArtFilter[502]={maptoid=740}
gArtFilter[1107]={maptoid=696}
gArtFilter[492]={maptoid=433}
gArtFilter[126]={maptoid=138}
gArtFilter[817]={maptoid=808}
gArtFilter[815]={maptoid=808}
gArtFilter[806]={maptoid=808}
gArtFilter[804]={maptoid=808}
gArtFilter[819]={maptoid=808}
gArtFilter[810]={maptoid=808}
gArtFilter[505]={maptoid=743}
gArtFilter[227]={maptoid=214}
gArtFilter[224]={maptoid=213}
gArtFilter[850]={maptoid=844}
gArtFilter[167]={maptoid=844}
gArtFilter[837]={maptoid=844}
gArtFilter[848]={maptoid=844}
gArtFilter[846]={maptoid=844}
gArtFilter[841]={maptoid=844}
gArtFilter[1090]={maptoid=279}
gArtFilter[1057]={maptoid=545}
gArtFilter[911]={maptoid=916}
gArtFilter[918]={maptoid=916}
gArtFilter[8659]={maptoid=949}
gArtFilter[428]={maptoid=425}
gArtFilter[164]={maptoid=162}
gArtFilter[399]={maptoid=401}
gArtFilter[76]={maptoid=75}
gArtFilter[212]={maptoid=198}
gArtFilter[448]={maptoid=443}
gArtFilter[842]={maptoid=836}
gArtFilter[838]={maptoid=836}
gArtFilter[168]={maptoid=836}
gArtFilter[840]={maptoid=836}
gArtFilter[847]={maptoid=836}
gArtFilter[851]={maptoid=836}
gArtFilter[849]={maptoid=836}
gArtFilter[734]={maptoid=496}
gArtFilter[744]={maptoid=496}
gArtFilter[238]={maptoid=247}
gArtFilter[232]={maptoid=247}
gArtFilter[243]={maptoid=247}
gArtFilter[234]={maptoid=247}
gArtFilter[245]={maptoid=247}
gArtFilter[236]={maptoid=247}
gArtFilter[2295]={maptoid=104}
gArtFilter[677]={maptoid=694}
gArtFilter[1105]={maptoid=694}
gArtFilter[495]={maptoid=410}
gArtFilter[424]={maptoid=441}
gArtFilter[563]={maptoid=737}
gArtFilter[875]={maptoid=737}
gArtFilter[450]={maptoid=446}
gArtFilter[105]={maptoid=99}
gArtFilter[796]={maptoid=795}
gArtFilter[791]={maptoid=795}
gArtFilter[798]={maptoid=795}
gArtFilter[8647]={maptoid=149}
gArtFilter[8652]={maptoid=149}
gArtFilter[8651]={maptoid=149}
gArtFilter[8648]={maptoid=149}
gArtFilter[94]={maptoid=92}
gArtFilter[221]={maptoid=231}
gArtFilter[855]={maptoid=859}
gArtFilter[860]={maptoid=859}
gArtFilter[143]={maptoid=133}
gArtFilter[531]={maptoid=537}
gArtFilter[926]={maptoid=323}
gArtFilter[83]={maptoid=78}
gArtFilter[50]={maptoid=46}
gArtFilter[793]={maptoid=802}
gArtFilter[789]={maptoid=802}
gArtFilter[800]={maptoid=802}
gArtFilter[535]={maptoid=530}
gArtFilter[974]={maptoid=988}
gArtFilter[235]={maptoid=239}
gArtFilter[230]={maptoid=222}
gArtFilter[678]={maptoid=695}
gArtFilter[1106]={maptoid=695}
gArtFilter[129]={maptoid=132}
gArtFilter[130]={maptoid=132}
gArtFilter[128]={maptoid=132}
gArtFilter[853]={maptoid=862}
gArtFilter[857]={maptoid=862}
gArtFilter[866]={maptoid=862}
gArtFilter[864]={maptoid=862}
gArtFilter[127]={maptoid=139}
gArtFilter[843]={maptoid=839}
gArtFilter[108]={maptoid=102}
gArtFilter[1104]={maptoid=693}
gArtFilter[938]={maptoid=940}
gArtFilter[941]={maptoid=940}
gArtFilter[939]={maptoid=940}
gArtFilter[91]={maptoid=93}
gArtFilter[494]={maptoid=409}
gArtFilter[1073]={maptoid=546}
gArtFilter[1058]={maptoid=546}
gArtFilter[1072]={maptoid=546}
gArtFilter[81]={maptoid=79}
gArtFilter[9373]={maptoid=515}
gArtFilter[821]={maptoid=8}
gArtFilter[832]={maptoid=8}
gArtFilter[830]={maptoid=8}
gArtFilter[828]={maptoid=8}
gArtFilter[825]={maptoid=8}
gArtFilter[834]={maptoid=8}
gArtFilter[742]={maptoid=504}
gArtFilter[407]={maptoid=435}
gArtFilter[917]={maptoid=910}
gArtFilter[915]={maptoid=910}
gArtFilter[201]={maptoid=242}
gArtFilter[246]={maptoid=237}
gArtFilter[240]={maptoid=237}
gArtFilter[233]={maptoid=237}
gArtFilter[244]={maptoid=237}
gArtFilter[451]={maptoid=447}
gArtFilter[373]={maptoid=375}
gArtFilter[376]={maptoid=375}
gArtFilter[475]={maptoid=469}
gArtFilter[481]={maptoid=485}
gArtFilter[322]={maptoid=925}
gArtFilter[807]={maptoid=811}
gArtFilter[2104]={maptoid=950}
gArtFilter[100]={maptoid=106}
gArtFilter[636]={maptoid=106}
gArtFilter[497]={maptoid=745}
gArtFilter[735]={maptoid=745}
gArtFilter[994]={maptoid=984}
gArtFilter[812]={maptoid=809}
gArtFilter[818]={maptoid=809}
gArtFilter[814]={maptoid=809}
gArtFilter[805]={maptoid=809}
gArtFilter[816]={maptoid=809}
gArtFilter[790]={maptoid=803}
gArtFilter[799]={maptoid=803}
gArtFilter[797]={maptoid=803}
gArtFilter[792]={maptoid=803}
gArtFilter[577]={maptoid=803}
gArtFilter[788]={maptoid=803}
gArtFilter[794]={maptoid=803}
gArtFilter[801]={maptoid=803}
gArtFilter[1093]={maptoid=282}
gArtFilter[746]={maptoid=736}
gArtFilter[159]={maptoid=156}
gArtFilter[436]={maptoid=408}
gArtFilter[294]={maptoid=281}
gArtFilter[1092]={maptoid=281}
gArtFilter[12583]={maptoid=26}
gArtFilter[163]={maptoid=165}
gArtFilter[131]={maptoid=141}
gArtFilter[935]={maptoid=937}
gArtFilter[826]={maptoid=7}
gArtFilter[835]={maptoid=7}
gArtFilter[820]={maptoid=7}
gArtFilter[831]={maptoid=7}
gArtFilter[833]={maptoid=7}
gArtFilter[824]={maptoid=7}
gArtFilter[822]={maptoid=7}
gArtFilter[914]={maptoid=909}
gArtFilter[8658]={maptoid=948}
gArtFilter[47]={maptoid=49}
gArtFilter[943]={maptoid=942}
gArtFilter[944]={maptoid=942}
gArtFilter[280]={maptoid=293}
gArtFilter[1091]={maptoid=293}
gArtFilter[427]={maptoid=422}
gArtFilter[8745]={maptoid=730}
gArtFilter[8721]={maptoid=730}
gArtFilter[8732]={maptoid=730}
gArtFilter[8722]={maptoid=730}
gArtFilter[8733]={maptoid=730}
gArtFilter[8724]={maptoid=730}
gArtFilter[8735]={maptoid=730}
gArtFilter[8744]={maptoid=730}
gArtFilter[8736]={maptoid=730}
gArtFilter[8742]={maptoid=730}
gArtFilter[8710]={maptoid=730}
gArtFilter[8727]={maptoid=730}
gArtFilter[8740]={maptoid=730}
gArtFilter[8717]={maptoid=730}
gArtFilter[8720]={maptoid=730}
gArtFilter[8725]={maptoid=730}
gArtFilter[8743]={maptoid=730}
gArtFilter[8715]={maptoid=730}
gArtFilter[8711]={maptoid=730}
gArtFilter[8713]={maptoid=730}
gArtFilter[8738]={maptoid=730}
gArtFilter[8730]={maptoid=730}
gArtFilter[8723]={maptoid=730}
gArtFilter[8748]={maptoid=730}
gArtFilter[8726]={maptoid=730}
gArtFilter[8714]={maptoid=730}
gArtFilter[8712]={maptoid=730}
gArtFilter[8746]={maptoid=730}
gArtFilter[8741]={maptoid=730}
gArtFilter[8737]={maptoid=730}
gArtFilter[8716]={maptoid=730}
gArtFilter[8728]={maptoid=730}
gArtFilter[8734]={maptoid=730}
gArtFilter[8718]={maptoid=730}
gArtFilter[8747]={maptoid=730}
gArtFilter[8731]={maptoid=730}
gArtFilter[739]={maptoid=501}
gArtFilter[748]={maptoid=501}
gArtFilter[936]={maptoid=934}
gArtFilter[738]={maptoid=500}
gArtFilter[747]={maptoid=500}
gArtFilter[493]={maptoid=434}
gArtFilter[107]={maptoid=101}
gArtFilter[14013]={maptoid=14000}
gArtFilter[14039]={maptoid=14043}
gArtFilter[14051]={maptoid=14043}
gArtFilter[14045]={maptoid=14043}
gArtFilter[14047]={maptoid=14043}
gArtFilter[14041]={maptoid=14043}
gArtFilter[14037]={maptoid=14043}
gArtFilter[14049]={maptoid=14043}
gArtFilter[14036]={maptoid=14044}
gArtFilter[14048]={maptoid=14044}
gArtFilter[14040]={maptoid=14044}
gArtFilter[14046]={maptoid=14044}
gArtFilter[14038]={maptoid=14044}
gArtFilter[14050]={maptoid=14044}
gArtFilter[14042]={maptoid=14044}
gArtFilter[7848]={maptoid=7851}
gArtFilter[7850]={maptoid=7851}
gArtFilter[7849]={maptoid=7851}
gArtFilter[8978]={maptoid=7775}
gArtFilter[7037]={maptoid=7036}
gArtFilter[7634]={maptoid=7631}
gArtFilter[7852]={maptoid=7854}
gArtFilter[7853]={maptoid=7854}
gArtFilter[7855]={maptoid=7854}
gArtFilter[7039]={maptoid=7040}
gArtFilter[7965]={maptoid=7966}
gArtFilter[8977]={maptoid=7774}
gArtFilter[5476]={maptoid=5477}
gArtFilter[5478]={maptoid=5479}
gArtFilter[6044]={maptoid=5465}
gArtFilter[6040]={maptoid=5465}
gArtFilter[6042]={maptoid=5465}
gArtFilter[6039]={maptoid=5465}
gArtFilter[6041]={maptoid=5465}
gArtFilter[6043]={maptoid=5465}
gArtFilter[13551]={maptoid=13549}
gArtFilter[13554]={maptoid=13549}
gArtFilter[13550]={maptoid=13549}
gArtFilter[13553]={maptoid=13549}
gArtFilter[13552]={maptoid=13549}
gArtFilter[13639]={maptoid=13641}
gArtFilter[13644]={maptoid=13641}
gArtFilter[13642]={maptoid=13641}
gArtFilter[13643]={maptoid=13641}
gArtFilter[13640]={maptoid=13641}
gArtFilter[13575]={maptoid=13578}
gArtFilter[13574]={maptoid=13578}
gArtFilter[13573]={maptoid=13578}
gArtFilter[13577]={maptoid=13578}
gArtFilter[13576]={maptoid=13578}
gArtFilter[13572]={maptoid=13570}
gArtFilter[13568]={maptoid=13570}
gArtFilter[13567]={maptoid=13570}
gArtFilter[13569]={maptoid=13570}
gArtFilter[13571]={maptoid=13570}
gArtFilter[13595]={maptoid=13592}
gArtFilter[13593]={maptoid=13592}
gArtFilter[13591]={maptoid=13592}
gArtFilter[13594]={maptoid=13592}
gArtFilter[13596]={maptoid=13592}
gArtFilter[13564]={maptoid=13566}
gArtFilter[13561]={maptoid=13566}
gArtFilter[13565]={maptoid=13566}
gArtFilter[13563]={maptoid=13566}
gArtFilter[13562]={maptoid=13566}
gArtFilter[13555]={maptoid=13557}
gArtFilter[13556]={maptoid=13557}
gArtFilter[13559]={maptoid=13557}
gArtFilter[13560]={maptoid=13557}
gArtFilter[13558]={maptoid=13557}
gArtFilter[13588]={maptoid=13589}
gArtFilter[13585]={maptoid=13589}
gArtFilter[13590]={maptoid=13589}
gArtFilter[13587]={maptoid=13589}
gArtFilter[13586]={maptoid=13589}
gArtFilter[13437]={maptoid=13608}
gArtFilter[13525]={maptoid=13608}
gArtFilter[13512]={maptoid=13608}
gArtFilter[13423]={maptoid=13608}
gArtFilter[13462]={maptoid=13608}
gArtFilter[13469]={maptoid=13608}
gArtFilter[13443]={maptoid=13608}
gArtFilter[13430]={maptoid=13608}
gArtFilter[13434]={maptoid=13608}
gArtFilter[13508]={maptoid=13608}
gArtFilter[13599]={maptoid=13608}
gArtFilter[13498]={maptoid=13608}
gArtFilter[13501]={maptoid=13608}
gArtFilter[13598]={maptoid=13608}
gArtFilter[13422]={maptoid=13608}
gArtFilter[13463]={maptoid=13608}
gArtFilter[13440]={maptoid=13608}
gArtFilter[13432]={maptoid=13608}
gArtFilter[13471]={maptoid=13608}
gArtFilter[13503]={maptoid=13608}
gArtFilter[13523]={maptoid=13608}
gArtFilter[13473]={maptoid=13608}
gArtFilter[13431]={maptoid=13608}
gArtFilter[13606]={maptoid=13608}
gArtFilter[13478]={maptoid=13608}
gArtFilter[13513]={maptoid=13608}
gArtFilter[13428]={maptoid=13608}
gArtFilter[13429]={maptoid=13608}
gArtFilter[13438]={maptoid=13608}
gArtFilter[13480]={maptoid=13608}
gArtFilter[13456]={maptoid=13608}
gArtFilter[13499]={maptoid=13608}
gArtFilter[13424]={maptoid=13608}
gArtFilter[13524]={maptoid=13608}
gArtFilter[13433]={maptoid=13608}
gArtFilter[13425]={maptoid=13608}
gArtFilter[13457]={maptoid=13608}
gArtFilter[13514]={maptoid=13608}
gArtFilter[13602]={maptoid=13608}
gArtFilter[13605]={maptoid=13608}
gArtFilter[13509]={maptoid=13608}
gArtFilter[13472]={maptoid=13608}
gArtFilter[13496]={maptoid=13608}
gArtFilter[13507]={maptoid=13608}
gArtFilter[13604]={maptoid=13608}
gArtFilter[13483]={maptoid=13608}
gArtFilter[13477]={maptoid=13608}
gArtFilter[13445]={maptoid=13608}
gArtFilter[13522]={maptoid=13608}
gArtFilter[13461]={maptoid=13608}
gArtFilter[13475]={maptoid=13608}
gArtFilter[13470]={maptoid=13608}
gArtFilter[13481]={maptoid=13608}
gArtFilter[13442]={maptoid=13608}
gArtFilter[13459]={maptoid=13608}
gArtFilter[13494]={maptoid=13608}
gArtFilter[13465]={maptoid=13608}
gArtFilter[13607]={maptoid=13608}
gArtFilter[13482]={maptoid=13608}
gArtFilter[13444]={maptoid=13608}
gArtFilter[13502]={maptoid=13608}
gArtFilter[13466]={maptoid=13608}
gArtFilter[13479]={maptoid=13608}
gArtFilter[13426]={maptoid=13608}
gArtFilter[13441]={maptoid=13608}
gArtFilter[13468]={maptoid=13608}
gArtFilter[13511]={maptoid=13608}
gArtFilter[13458]={maptoid=13608}
gArtFilter[13497]={maptoid=13608}
gArtFilter[13467]={maptoid=13608}
gArtFilter[13597]={maptoid=13608}
gArtFilter[13603]={maptoid=13608}
gArtFilter[13436]={maptoid=13608}
gArtFilter[13435]={maptoid=13608}
gArtFilter[13476]={maptoid=13608}
gArtFilter[13521]={maptoid=13608}
gArtFilter[13474]={maptoid=13608}
gArtFilter[13600]={maptoid=13608}
gArtFilter[13464]={maptoid=13608}
gArtFilter[13427]={maptoid=13608}
gArtFilter[13460]={maptoid=13608}
gArtFilter[13493]={maptoid=13608}
gArtFilter[13601]={maptoid=13608}
gArtFilter[13506]={maptoid=13608}
gArtFilter[13439]={maptoid=13608}
gArtFilter[13504]={maptoid=13608}
gArtFilter[13582]={maptoid=13580}
gArtFilter[13583]={maptoid=13580}
gArtFilter[13581]={maptoid=13580}
gArtFilter[13584]={maptoid=13580}
gArtFilter[6544]={maptoid=6543}
gArtFilter[6545]={maptoid=6543}
gArtFilter[6542]={maptoid=6543}
gArtFilter[6013]={maptoid=6017}
gArtFilter[6429]={maptoid=6428}
gArtFilter[6658]={maptoid=6667}
gArtFilter[6659]={maptoid=6667}
gArtFilter[6424]={maptoid=6425}
gArtFilter[6568]={maptoid=6567}
gArtFilter[6569]={maptoid=6567}
gArtFilter[6566]={maptoid=6567}
gArtFilter[6532]={maptoid=6531}
gArtFilter[6533]={maptoid=6531}
gArtFilter[6530]={maptoid=6531}
gArtFilter[6561]={maptoid=6558}
gArtFilter[6559]={maptoid=6558}
gArtFilter[6560]={maptoid=6558}
gArtFilter[7979]={maptoid=6587}
gArtFilter[6549]={maptoid=6546}
gArtFilter[6548]={maptoid=6546}
gArtFilter[6547]={maptoid=6546}
gArtFilter[6430]={maptoid=6431}
gArtFilter[6660]={maptoid=6657}
gArtFilter[6668]={maptoid=6657}
gArtFilter[6556]={maptoid=6555}
gArtFilter[6557]={maptoid=6555}
gArtFilter[6554]={maptoid=6555}
gArtFilter[6426]={maptoid=6427}
gArtFilter[6525]={maptoid=6522}
gArtFilter[6524]={maptoid=6522}
gArtFilter[6523]={maptoid=6522}
gArtFilter[6536]={maptoid=6537}
gArtFilter[6534]={maptoid=6537}
gArtFilter[6535]={maptoid=6537}
gArtFilter[2628]={maptoid=11223}
gArtFilter[12911]={maptoid=12832}
gArtFilter[12833]={maptoid=12832}
gArtFilter[12909]={maptoid=12832}
gArtFilter[12835]={maptoid=12832}
gArtFilter[12813]={maptoid=12832}
gArtFilter[12839]={maptoid=12832}
gArtFilter[12865]={maptoid=12832}
gArtFilter[12814]={maptoid=12832}
gArtFilter[12826]={maptoid=12832}
gArtFilter[12838]={maptoid=12832}
gArtFilter[12841]={maptoid=12832}
gArtFilter[12840]={maptoid=12832}
gArtFilter[12836]={maptoid=12832}
gArtFilter[12842]={maptoid=12832}
gArtFilter[12834]={maptoid=12832}
gArtFilter[12854]={maptoid=12832}
gArtFilter[12910]={maptoid=12906}
gArtFilter[3445]={maptoid=3406}
gArtFilter[3469]={maptoid=3406}
gArtFilter[3399]={maptoid=3406}
gArtFilter[3464]={maptoid=3406}
gArtFilter[3324]={maptoid=3321}
gArtFilter[3494]={maptoid=3498}
gArtFilter[3644]={maptoid=3645}
gArtFilter[3734]={maptoid=3692}
gArtFilter[3179]={maptoid=3180}
gArtFilter[3178]={maptoid=3180}
gArtFilter[5108]={maptoid=3714}
gArtFilter[3814]={maptoid=3812}
gArtFilter[3993]={maptoid=3994}
gArtFilter[3697]={maptoid=3726}
gArtFilter[3499]={maptoid=3495}
gArtFilter[3746]={maptoid=3747}
gArtFilter[5453]={maptoid=3703}
gArtFilter[3311]={maptoid=3313}
gArtFilter[3693]={maptoid=3729}
gArtFilter[3045]={maptoid=3027}
gArtFilter[3046]={maptoid=3028}
gArtFilter[3811]={maptoid=3813}
gArtFilter[3309]={maptoid=3307}
gArtFilter[3635]={maptoid=3633}
gArtFilter[3634]={maptoid=3633}
gArtFilter[3429]={maptoid=3421}
gArtFilter[3748]={maptoid=3745}
gArtFilter[8149]={maptoid=3949}
gArtFilter[8151]={maptoid=3949}
gArtFilter[8152]={maptoid=3949}
gArtFilter[8150]={maptoid=3949}
gArtFilter[3098]={maptoid=3089}
gArtFilter[3724]={maptoid=3696}
gArtFilter[1458]={maptoid=9957}
gArtFilter[11359]={maptoid=9957}
gArtFilter[9988]={maptoid=9990}
gArtFilter[9991]={maptoid=9990}
gArtFilter[9989]={maptoid=9990}
gArtFilter[9983]={maptoid=9990}
gArtFilter[1481]={maptoid=9990}
gArtFilter[1479]={maptoid=9981}
gArtFilter[9995]={maptoid=9993}
gArtFilter[1487]={maptoid=9993}
gArtFilter[1483]={maptoid=9985}
gArtFilter[9963]={maptoid=9949}
gArtFilter[1447]={maptoid=9949}
gArtFilter[9977]={maptoid=9996}
gArtFilter[1475]={maptoid=9996}
gArtFilter[11316]={maptoid=9996}
gArtFilter[9953]={maptoid=9961}
gArtFilter[9960]={maptoid=9961}
gArtFilter[1454]={maptoid=9961}
gArtFilter[9952]={maptoid=9958}
gArtFilter[1453]={maptoid=9958}
gArtFilter[1486]={maptoid=9992}
gArtFilter[1476]={maptoid=9978}
gArtFilter[11317]={maptoid=9978}
gArtFilter[1482]={maptoid=9984}
gArtFilter[1449]={maptoid=9964}
gArtFilter[1484]={maptoid=9986}
gArtFilter[1485]={maptoid=9987}
gArtFilter[1474]={maptoid=9976}
gArtFilter[1457]={maptoid=9956}
gArtFilter[11358]={maptoid=9956}
gArtFilter[1455]={maptoid=9954}
gArtFilter[1480]={maptoid=9982}
gArtFilter[1456]={maptoid=9955}
gArtFilter[11357]={maptoid=9955}
gArtFilter[1477]={maptoid=9979}
gArtFilter[1445]={maptoid=9946}
gArtFilter[11346]={maptoid=9946}
gArtFilter[1478]={maptoid=9980}
gArtFilter[1446]={maptoid=9948}
gArtFilter[1488]={maptoid=9994}
gArtFilter[9947]={maptoid=9950}
gArtFilter[1444]={maptoid=9950}
gArtFilter[8524]={maptoid=9950}
gArtFilter[8525]={maptoid=9950}
gArtFilter[1448]={maptoid=9962}
gArtFilter[9959]={maptoid=9951}
gArtFilter[1452]={maptoid=9951}
gArtFilter[11305]={maptoid=1464}
gArtFilter[1620]={maptoid=1625}
gArtFilter[1318]={maptoid=1320}
gArtFilter[11341]={maptoid=1531}
gArtFilter[1727]={maptoid=1718}
gArtFilter[1731]={maptoid=1718}
gArtFilter[1713]={maptoid=1709}
gArtFilter[1706]={maptoid=1709}
gArtFilter[1635]={maptoid=1645}
gArtFilter[1767]={maptoid=1780}
gArtFilter[1771]={maptoid=1780}
gArtFilter[1778]={maptoid=1780}
gArtFilter[11311]={maptoid=1470}
gArtFilter[1990]={maptoid=1986}
gArtFilter[11306]={maptoid=1465}
gArtFilter[1176]={maptoid=1173}
gArtFilter[1175]={maptoid=1173}
gArtFilter[1174]={maptoid=1173}
gArtFilter[1721]={maptoid=1717}
gArtFilter[1728]={maptoid=1717}
gArtFilter[1987]={maptoid=1983}
gArtFilter[1562]={maptoid=1573}
gArtFilter[1747]={maptoid=1743}
gArtFilter[1734]={maptoid=1743}
gArtFilter[1183]={maptoid=1181}
gArtFilter[1332]={maptoid=1334}
gArtFilter[1769]={maptoid=1776}
gArtFilter[1765]={maptoid=1776}
gArtFilter[1643]={maptoid=1631}
gArtFilter[11331]={maptoid=1521}
gArtFilter[1638]={maptoid=1648}
gArtFilter[1147]={maptoid=1119}
gArtFilter[1148]={maptoid=1119}
gArtFilter[1151]={maptoid=1119}
gArtFilter[1149]={maptoid=1119}
gArtFilter[1150]={maptoid=1119}
gArtFilter[1152]={maptoid=1119}
gArtFilter[1624]={maptoid=1621}
gArtFilter[1705]={maptoid=1712}
gArtFilter[1701]={maptoid=1712}
gArtFilter[1666]={maptoid=1655}
gArtFilter[1668]={maptoid=1655}
gArtFilter[1659]={maptoid=1655}
gArtFilter[11336]={maptoid=1526}
gArtFilter[11332]={maptoid=1522}
gArtFilter[1700]={maptoid=1687}
gArtFilter[1698]={maptoid=1687}
gArtFilter[1691]={maptoid=1687}
gArtFilter[1234]={maptoid=1248}
gArtFilter[11313]={maptoid=1472}
gArtFilter[8685]={maptoid=1472}
gArtFilter[8686]={maptoid=1472}
gArtFilter[1554]={maptoid=1543}
gArtFilter[1319]={maptoid=1317}
gArtFilter[11304]={maptoid=1463}
gArtFilter[1412]={maptoid=1410}
gArtFilter[1276]={maptoid=1410}
gArtFilter[1246]={maptoid=1232}
gArtFilter[1661]={maptoid=1658}
gArtFilter[1665]={maptoid=1658}
gArtFilter[1647]={maptoid=1636}
gArtFilter[1677]={maptoid=1674}
gArtFilter[8181]={maptoid=1674}
gArtFilter[8185]={maptoid=1674}
gArtFilter[8178]={maptoid=1674}
gArtFilter[1750]={maptoid=1763}
gArtFilter[1642]={maptoid=1630}
gArtFilter[1186]={maptoid=1185}
gArtFilter[1409]={maptoid=1278}
gArtFilter[1413]={maptoid=1278}
gArtFilter[1411]={maptoid=1278}
gArtFilter[11309]={maptoid=1468}
gArtFilter[1256]={maptoid=1335}
gArtFilter[11334]={maptoid=1524}
gArtFilter[1244]={maptoid=1245}
gArtFilter[11312]={maptoid=1471}
gArtFilter[1324]={maptoid=1322}
gArtFilter[1760]={maptoid=1753}
gArtFilter[11300]={maptoid=1459}
gArtFilter[1241]={maptoid=1242}
gArtFilter[1226]={maptoid=1228}
gArtFilter[1218]={maptoid=1219}
gArtFilter[1217]={maptoid=1219}
gArtFilter[1239]={maptoid=1187}
gArtFilter[1577]={maptoid=1565}
gArtFilter[1729]={maptoid=1722}
gArtFilter[1725]={maptoid=1722}
gArtFilter[11343]={maptoid=1533}
gArtFilter[1364]={maptoid=1377}
gArtFilter[1380]={maptoid=1377}
gArtFilter[1365]={maptoid=1377}
gArtFilter[1379]={maptoid=1377}
gArtFilter[1378]={maptoid=1377}
gArtFilter[1366]={maptoid=1377}
gArtFilter[1328]={maptoid=1330}
gArtFilter[11339]={maptoid=1529}
gArtFilter[1509]={maptoid=1513}
gArtFilter[1748]={maptoid=1735}
gArtFilter[1746]={maptoid=1735}
gArtFilter[1739]={maptoid=1735}
gArtFilter[11308]={maptoid=1467}
gArtFilter[1561]={maptoid=1574}
gArtFilter[1981]={maptoid=1982}
gArtFilter[1685]={maptoid=1696}
gArtFilter[1689]={maptoid=1696}
gArtFilter[1764]={maptoid=1755}
gArtFilter[1581]={maptoid=1628}
gArtFilter[1629]={maptoid=1628}
gArtFilter[1575]={maptoid=1564}
gArtFilter[11337]={maptoid=1527}
gArtFilter[11301]={maptoid=1460}
gArtFilter[8681]={maptoid=1460}
gArtFilter[8682]={maptoid=1460}
gArtFilter[1737]={maptoid=1744}
gArtFilter[1733]={maptoid=1744}
gArtFilter[1742]={maptoid=1744}
gArtFilter[1669]={maptoid=1680}
gArtFilter[1673]={maptoid=1680}
gArtFilter[8177]={maptoid=1680}
gArtFilter[8173]={maptoid=1680}
gArtFilter[8184]={maptoid=1680}
gArtFilter[1711]={maptoid=1702}
gArtFilter[1715]={maptoid=1702}
gArtFilter[11335]={maptoid=1525}
gArtFilter[1723]={maptoid=1730}
gArtFilter[1732]={maptoid=1730}
gArtFilter[1719]={maptoid=1730}
gArtFilter[1578]={maptoid=1567}
gArtFilter[1657]={maptoid=1664}
gArtFilter[1653]={maptoid=1664}
gArtFilter[11330]={maptoid=1520}
gArtFilter[1389]={maptoid=1390}
gArtFilter[1644]={maptoid=1633}
gArtFilter[1770]={maptoid=1777}
gArtFilter[1773]={maptoid=1777}
gArtFilter[1751]={maptoid=1762}
gArtFilter[11302]={maptoid=1461}
gArtFilter[8684]={maptoid=1461}
gArtFilter[8683]={maptoid=1461}
gArtFilter[1549]={maptoid=1538}
gArtFilter[1279]={maptoid=1408}
gArtFilter[1512]={maptoid=1514}
gArtFilter[1508]={maptoid=1514}
gArtFilter[11303]={maptoid=1462}
gArtFilter[1384]={maptoid=1385}
gArtFilter[1766]={maptoid=1779}
gArtFilter[1775]={maptoid=1779}
gArtFilter[11314]={maptoid=1473}
gArtFilter[8687]={maptoid=1473}
gArtFilter[8688]={maptoid=1473}
gArtFilter[1329]={maptoid=1327}
gArtFilter[1572]={maptoid=1560}
gArtFilter[11344]={maptoid=1534}
gArtFilter[1654]={maptoid=1663}
gArtFilter[1667]={maptoid=1663}
gArtFilter[1814]={maptoid=1816}
gArtFilter[1233]={maptoid=1247}
gArtFilter[1402]={maptoid=1406}
gArtFilter[11333]={maptoid=1523}
gArtFilter[1679]={maptoid=1681}
gArtFilter[1683]={maptoid=1681}
gArtFilter[1670]={maptoid=1681}
gArtFilter[1754]={maptoid=1761}
gArtFilter[1738]={maptoid=1745}
gArtFilter[1741]={maptoid=1745}
gArtFilter[8176]={maptoid=1672}
gArtFilter[1393]={maptoid=1368}
gArtFilter[1399]={maptoid=1368}
gArtFilter[1370]={maptoid=1368}
gArtFilter[1394]={maptoid=1368}
gArtFilter[1395]={maptoid=1368}
gArtFilter[1371]={maptoid=1368}
gArtFilter[1392]={maptoid=1368}
gArtFilter[1576]={maptoid=1566}
gArtFilter[1985]={maptoid=1989}
gArtFilter[11310]={maptoid=1469}
gArtFilter[1388]={maptoid=1387}
gArtFilter[1249]={maptoid=1235}
gArtFilter[1243]={maptoid=1240}
gArtFilter[1646]={maptoid=1637}
gArtFilter[1323]={maptoid=1321}
gArtFilter[2077]={maptoid=1321}
gArtFilter[11307]={maptoid=1466}
gArtFilter[1697]={maptoid=1690}
gArtFilter[1693]={maptoid=1690}
gArtFilter[1145]={maptoid=1146}
gArtFilter[1143]={maptoid=1146}
gArtFilter[1144]={maptoid=1146}
gArtFilter[1142]={maptoid=1146}
gArtFilter[1396]={maptoid=1400}
gArtFilter[1405]={maptoid=1401}
gArtFilter[1988]={maptoid=1984}
gArtFilter[1559]={maptoid=1571}
gArtFilter[1286]={maptoid=1287}
gArtFilter[1284]={maptoid=1287}
gArtFilter[1277]={maptoid=1407}
gArtFilter[1382]={maptoid=1383}
gArtFilter[11340]={maptoid=1530}
gArtFilter[1686]={maptoid=1695}
gArtFilter[1699]={maptoid=1695}
gArtFilter[11342]={maptoid=1532}
gArtFilter[11338]={maptoid=1528}
gArtFilter[1611]={maptoid=1632}
gArtFilter[1184]={maptoid=1182}
gArtFilter[8180]={maptoid=1676}
gArtFilter[1707]={maptoid=1703}
gArtFilter[1714]={maptoid=1703}
gArtFilter[1716]={maptoid=1703}
gArtFilter[1684]={maptoid=1671}
gArtFilter[1682]={maptoid=1671}
gArtFilter[1675]={maptoid=1671}
gArtFilter[9003]={maptoid=9002}
----------------------------------------------------------------------
----------------------------------------------------------------------

-- Seasonal Dynamic & Static Art Translation (run tiles)	-- eventuell (iTileTypeID + 0x4000)
function SeasonalStaticTranslation (iTileTypeID, iSeasonID, bUseFoliageSkip)
	local translator = gSeasonStaticTranslators[iSeasonID]
	-- foliage : zb. item 0x3e57 und folgende haben foliage an, wobei das aber ein schiffsmast ist und die anderen teile sind auch schiffsteile. (foliage skip nur bei statics?) 
	if (bUseFoliageSkip and iSeasonID == 4 and TestBit(GetStaticTileTypeFlags(iTileTypeID) or 0,kTileDataFlag_Foliage)) then return -1 end
	if (translator) then
		return translator[iTileTypeID] or iTileTypeID
	else
		return iTileTypeID
	end
end

-- FILTER : ArtID -> ArtID
-- StaticArt
gStaticTable_Winter = ParseHex2HexArray({
--Foliage
["cce"]=-1,
["cd1"]=-1,
["cd4"]=-1,
["cd7"]=-1,
["cd9"]=-1,
["cdb"]=-1,
["cde"]=-1,
["ce1"]=-1,
["ce4"]=-1,
["ce7"]=-1,
["cf9"]=-1,
["cfc"]=-1,
["cff"]=-1,
["d02"]=-1,
--Foliage multiple tiles
["d45"]=-1
})

-- FILTER : ArtID -> ArtID
-- StaticArt
gStaticTable_Spring = ParseHex2HexArray({
})

-- FILTER : ArtID -> ArtID
-- StaticArt
gStaticTable_Fall = ParseHex2HexArray({
--Foliage
["cce"]="ccf",
["cd1"]="cd2",
["cd4"]="cd5",
["cdb"]="cdc",
["cde"]="cdf",
["ce1"]="ce2",
["ce4"]="ce5",
["ce7"]="ce8",
["cf9"]="cfa",
["cfc"]="cfd",
["cff"]="d00",
["d02"]="d03"
})

-- FILTER : ArtID -> ArtID
-- StaticArt
gStaticTable_Desolation = ParseHex2HexArray({
--Foliage
["cce"]=-1,
["cd1"]=-1,
["cd4"]=-1,
["cd7"]=-1,
["cd9"]=-1,
["cdb"]=-1,
["cde"]=-1,
["ce1"]=-1,
["ce4"]=-1,
["ce7"]=-1,
["cf9"]=-1,
["cfc"]=-1,
["cff"]=-1,
["d02"]=-1,
--Foliage multiple tiles
["d45"]=-1,

[0xc37]=	0x1bae,
[0xc38]=	0x1bae,
[0xc45]=	0x1b9c,
[0xc46]=	0x1b9d,
[0xc47]=	0x1bae,
[0xc48]=	0x1b9c,
[0xc49]=	0x1b9d,
[0xc4a]=	0x1bae,
[0xc4b]=	0x1bae,
[0xc4c]=	0x1b16,
[0xc4d]=	0x1bae,
[0xc4e]=	0x1b9c,
[0xc84]=	0x1b84,
[0xc85]=	0x1b9c,
[0xc8b]=	0x1b84,
[0xc8c]=	0x1bae,
[0xc8d]=	0x1bae,
[0xc8e]=	0x1b8d,
[0xc93]=	0x1bae,
[0xc94]=	0x1bae,
[0xc98]=	0x1bae,
[0xc99]=	0x1b8d,
[0xc9e]=	0x1182,
[0xc9f]=	0x1bae,
[0xca0]=	0x1bae,
[0xca1]=	0x1bae,
[0xca2]=	0x1bae,
[0xca3]=	0x1bae,
[0xca4]=	0x1bae,
[0xca7]=	0x1b9c,
[0xcac]=	0x1b8d,
[0xcad]=	0x1ae1,
[0xcae]=	0x1b9c,
[0xcaf]=	0x1b9c,
[0xcb0]=	0x1bae,
[0xcb1]=	0x1bae,
[0xcb2]=	0x1bae,
[0xcb3]=	0x1bae,
[0xcb4]=	0x1bae,
[0xcb5]=	0x1b9c,
[0xcb6]=	0x1b9d,
[0xcb7]=	0x1bae,
[0xcb8]=	0x1cea,
[0xcb9]=	0x1b8d,
[0xcba]=	0x1b8d,
[0xcbb]=	0x1b8d,
[0xcbc]=	0x1b8d,
[0xcbd]=	0x1b8d,
[0xcbe]=	0x1b8d,
[0xcc5]=	0x1bae,
[0xcc7]=	0x1b0d,
[0xce9]=	0xed7,
[0xcea]=	0xd3f,
[0xd0c]=	0x1bae,
[0xd0d]=	0x1bae,
[0xd0e]=	0x1bae,
[0xd0f]=	0x1b1c,
[0xd10]=	0x1bae,
[0xd11]=	0x122b,
[0xd12]=	0x1bae,
[0xd13]=	0x1bae,
[0xd14]=	0x122b,
[0xd15]=	0x1b9c,
[0xd16]=	0x1b8d,
[0xd17]=	0x122b,
[0xd18]=	0x1bae,
[0xd19]=	0x1bae,
[0xd29]=	0x1b9c,
[0xd2b]=	0x1b15,
[0xd2d]=	0x1bae,
[0xd2f]=	0x1bae,
[0x1b7e]=	0x1e34,

})


----------------------------------------------------------------------

-- display the following fallbacks as ground plates
gArtFallbackGroundPlateList = {
	2739, 2740, 2741, 2742, 2743, 
	2744, 2745, 2746, 2747, 4253, 
	2729, 2730, 2731, 2732, 2733, 
	2734, 2735, 2736, 2737, 4248, 
	4249, 4250, 4251, 4252, 4254, 
	4255, 4256, 4258, 4259, 13001,
	6951, 6952, 6953, 6954, 6959,
	6960, 6961, 6962, 10404, 10405,
	9257, 9258, 9259, 9260, 9261,
	9262, 9263, 9264, 9269, 9276, 
	9286, 7635, 7637, 7639, 7641, 
	7646, 7647, 7643, 7648, 7659,
	1037, 1040, 1036, 1041, 10054,
	10064, 10056, 10059, 10062, 10063,
	10065, 9281, 9182, 9284, 9293,
	9294, 10592, 10597, 11723, 11724, 
	11725, 11726, 9256, 9272, 
}

-- this line must be executed AFTER the definition of the translation tables
gSeasonStaticTranslators = {[0]=gStaticTable_Spring,[1]=nil,[2]=gStaticTable_Fall,[3]=gStaticTable_Winter,[4]=gStaticTable_Desolation}

function IsGroundPlate	(artid)
	artid = tonumber(artid)
	if artid >= 0x270 and artid <= 0x276 then return true end
	if artid >= 0x40b and artid <= 0x41e then return true end
	if artid >= 0x491 and artid <= 0x585 then return true end
	if artid >= 0x5e1 and artid <= 0x5eb then return true end
	if artid >= 0x62b and artid <= 0x632 then return true end
	if artid >= 0x637 and artid <= 0x63e then return true end
	if artid >= 0x81d and artid <= 0x81d then return true end
	if artid >= 0xaa9 and artid <= 0xafa then return true end
	if artid >= 0x1098 and artid <= 0x10a3 then return true end
	if artid >= 0x11c0 and artid <= 0x11c5 then return true end
	if artid >= 0x120e and artid <= 0x1216 then return true end
	if artid >= 0x1274 and artid <= 0x1275 then return true end
	if artid >= 0x1278 and artid <= 0x1279 then return true end
	if artid >= 0x1281 and artid <= 0x1285 then return true end
	if artid >= 0x1287 and artid <= 0x1291 then return true end
	if artid >= 0x1293 and artid <= 0x1295 then return true end
	if artid >= 0x12ee and artid <= 0x134d then return true end
	if artid >= 0x136e and artid <= 0x136e then return true end
	if artid >= 0x137e and artid <= 0x1386 then return true end
	if artid >= 0x149f and artid <= 0x14d6 then return true end
	if artid >= 0x150a and artid <= 0x1511 then return true end
	if artid >= 0x177d and artid <= 0x1781 then return true end
	if artid >= 0x1796 and artid <= 0x180d then return true end
	if artid >= 0x1b27 and artid <= 0x1b3e then return true end
	if artid >= 0x1b82 and artid <= 0x1b92 then return true end
	if artid >= 0x1cc7 and artid <= 0x1cdc then return true end
	if artid >= 0x1cf1 and artid <= 0x1d12 then return true end
	if artid >= 0x1dd3 and artid <= 0x1dfc then return true end
	if artid >= 0x1f24 and artid <= 0x1f27 then return true end
	if artid >= 0x213f and artid <= 0x2144 then return true end
	if artid >= 0x2425 and artid <= 0x2438 then return true end
	if artid >= 0x243b and artid <= 0x246b then return true end
	if artid >= 0x2720 and artid <= 0x2751 then return true end
	if artid >= 0x286e and artid <= 0x2885 then return true end
	if artid >= 0x28a4 and artid <= 0x28af then return true end
	if artid >= 0x2960 and artid <= 0x298f then return true end
	if artid >= 0x29c0 and artid <= 0x29cb then return true end
	if artid >= 0x29d6 and artid <= 0x29db then return true end
	if artid >= 0x2a1d and artid <= 0x2a29 then return true end
	if artid >= 0x2a3c and artid <= 0x2a44 then return true end
	if artid >= 0x2b3e and artid <= 0x2b65 then return true end
	if artid >= 0x2bb5 and artid <= 0x2bb8 then return true end
	if artid >= 0x2bcf and artid <= 0x2bcf then return true end
	if artid >= 0x2cec and artid <= 0x2cee then return true end
	if artid >= 0x2d38 and artid <= 0x2d3b then return true end
	if artid >= 0x2dcb and artid <= 0x2dce then return true end
	if artid >= 0x2e01 and artid <= 0x2e3b then return true end
	if artid >= 0x2e40 and artid <= 0x2e47 then return true end
	if artid >= 0x2e69 and artid <= 0x2f0e then return true end
	if artid >= 0x2f62 and artid <= 0x2fb5 then return true end
	if artid >= 0x3004 and artid <= 0x3007 then return true end
	if artid >= 0x30e7 and artid <= 0x3109 then return true end
	if artid >= 0x31f4 and artid <= 0x322a then return true end
	if artid >= 0x3236 and artid <= 0x32a5 then return true end
	if artid >= 0x32ac and artid <= 0x32ad then return true end
	if artid >= 0x32b0 and artid <= 0x32b1 then return true end
	if artid >= 0x32c9 and artid <= 0x32ca then return true end
	if artid >= 0x337a and artid <= 0x337a then return true end
	if artid >= 0x343b and artid <= 0x3457 then return true end
	if artid >= 0x3462 and artid <= 0x3485 then return true end
	if artid >= 0x3490 and artid <= 0x34ab then return true end
	if artid >= 0x34b5 and artid <= 0x34d5 then return true end
	if artid >= 0x3505 and artid <= 0x3504 then return true end
	if artid >= 0x3523 and artid <= 0x3530 then return true end
	if artid >= 0x3546 and artid <= 0x354e then return true end
	if artid >= 0x3551 and artid <= 0x3552 then return true end
	if artid >= 0x35b2 and artid <= 0x35bd then return true end
	if artid >= 0x361a and artid <= 0x3622 then return true end
	if artid >= 0x39d4 and artid <= 0x39e6 then return true end
	if artid >= 0x3a1f and artid <= 0x3a32 then return true end
	if artid >= 0x3a45 and artid <= 0x3a54 then return true end
	if artid >= 0x3af0 and artid <= 0x3af8 then return true end
	
	-- if in_array(artid, gArtFallbackGroundPlateList) then return true end
	
	return false
end
