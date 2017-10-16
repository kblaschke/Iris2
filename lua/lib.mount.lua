-- handles hardcoded mount id transforms
-- when riding a horse, the horse is not a mobile, but an equipment on a kLayer_Mount
-- sadly the animid for the tiledata associated with the artid of the mount is often 0
-- we couldn't find any "trick" to get the correct anim id, so it seems to be hardcoded


gStandardHorse = hex2num("0xC8")  -- 0x334(med-brown) 0x338(dark brown) 0x34e(dark-gray) 0x350(light brown)

--// List of all MountItems and their corresponding AnimationIDs
--// Format: <MountItemId=artid> <AnimationId>
--Version 1
gMountHueOverride = {}
gMountTranslate = {}
gMountTranslate[0x3EAA] = 0x73 --//=115, 0x20DD,  Ethereal Horse
gMountTranslate[0x3EAB] = 0xAA --//=170, 0x20F6,  Ethereal Llama			 
gMountTranslate[0x3EAC] = 0xAB --//=171, 0x2135,  Ethereal Ostard			 
gMountTranslate[0x3E9A] = 0xC1 --//=193, 0x2615,  Ethereal Ridgeback		 
gMountTranslate[0x3E9B] = 0xC0 --//=192, 0x25CE,  Ethereal Unicorn			 
gMountTranslate[0x3E97] = 0xC3 --//=195, 0x260F,  Ethereal Beetle			 
gMountTranslate[0x3E9C] = 0xBF --//=191, 0x25A0,  Ethereal Kirin			 
gMountTranslate[0x3E98] = 0xC2 --//=194, 0x2619,  Ethereal SwampDragon		

-- override eth hues to zero, to avoid errors
gMountHueOverride[0x3EAA] = 0 --Ethereal Horse
gMountHueOverride[0x3EAB] = 0 --Ethereal Llama		
gMountHueOverride[0x3EAC] = 0 --Ethereal Ostard		
gMountHueOverride[0x3E9A] = 0 --Ethereal Ridgeback	
gMountHueOverride[0x3E9B] = 0 --Ethereal Unicorn		
gMountHueOverride[0x3E97] = 0 --Ethereal Beetle		
gMountHueOverride[0x3E9C] = 0 --Ethereal Kirin		
gMountHueOverride[0x3E98] = 0 --Ethereal SwampDragon
  
gMountTranslate[0x3E90] = 0x114   -- chimera     wing broken in 3d, but these ids are needed for 2d as well, override 3d specific stuff below

gMountTranslate[0x3E91] = 0x115  -- cusidhe (correct model?)  0x7f 0x64 0x62 0x17
gMountTranslate[0x3E95] = 0x317  -- giantfirebeetle (temporary placeholder model)
					
					
gMountTranslate[0x3FFE] = 0xD5  --
gMountTranslate[0x3FFD] = 0xF1  --
gMountTranslate[0x3FFC] = 0xF3  --
gMountTranslate[0x3EB4] = 0x7A  --// unicorn (eth?)
gMountTranslate[0x3EA2] = 0xCC  --// dark brown horse
gMountTranslate[0x3E9F] = 0xC8  --// light brown horse
gMountTranslate[0x3EA0] = 0xE2  --// light grey horse
gMountTranslate[0x3EA1] = 0xE4  --// grey brown horse
gMountTranslate[0x3EA6] = 0xDC  --// Llama
gMountTranslate[0x3EA3] = 0xD2  --// desert ostard
gMountTranslate[0x3EA4] = 0xDA  --// frenzied ostard
gMountTranslate[0x3EA5] = 0xDB  --// forest ostard
gMountTranslate[0x3F14] = 0x3C  --// drake
gMountTranslate[0x3FFB] = 0xD5  --// unknown?
gMountTranslate[0x3EA7] = 0x74  --// nightmare 0xB1 ?
gMountTranslate[0x3EA8] = 0x75  --// silver steed
gMountTranslate[0x3EA9] = 0x72  --// nightmare
gMountTranslate[0x3E9F] = 0xC8  --// light brown horse
gMountTranslate[0x3EAF] = 0x78  --// war horse (blood red)
gMountTranslate[0x3EB0] = 0x79  --// war horse (light green)
gMountTranslate[0x3EB1] = 0x77  --// war horse (light blue)
gMountTranslate[0x3EB3] = 0x90  --// sea horse (medium blue)
gMountTranslate[0x3EB5] = 0x74  --// nightmare
gMountTranslate[0x3EB6] = 0xB2  --// nightmare 4
gMountTranslate[0x3EAD] = 0x84  --// kirin
gMountTranslate[0x3EB2] = 0x76  --// war horse (purple)
gMountTranslate[0x3EB7] = 0xB3  --// dark steed
gMountTranslate[0x3EB8] = 0xBB  --// ridgeback
gMountTranslate[0x3EBA] = 0xBC  --// savage ridgeback
gMountTranslate[0x3E9E] = 0xBE  --// firesteed
gMountTranslate[0x3E93] = 0xFB  --// test
gMountTranslate[0x3EBB] = 0x319 --// skeletal mount
gMountTranslate[0x3EBC] = 0x317 --// beetle
gMountTranslate[0x3EBD] = 0x31A --// swampdragon
gMountTranslate[0x3EBE] = 0x31F --// armored swamp dragon
gMountTranslate[0x3E92] = 0x11C --// mondain steed
gMountTranslate[0x3E94] = 0xF3  --// hiryu

gMountTranslate2D = {}
for k,v in pairs(gMountTranslate) do gMountTranslate2D[k] = v end -- a copy of the original data without granny overrides for varan

-- currently broken granny anims
gMountGrannyOverride = {}
gMountGrannyOverride[0x114] = 0x69 -- chimera : wing broken in 3d
gMountGrannyOverride[257] = gStandardHorse -- dread horn 
gMountGrannyOverride[0xCC] = gStandardHorse -- dark brown horse
gMountGrannyOverride[0xE2] = gStandardHorse -- light grey horse
gMountGrannyOverride[0xE4] = gStandardHorse -- grey brown horse
gMountGrannyOverride[0xB1] = gStandardHorse -- nightmare
gMountGrannyOverride[0x75] = gStandardHorse -- SilverSteed
gMountGrannyOverride[0x72] = gStandardHorse -- nightmare
gMountGrannyOverride[0x73] = gStandardHorse -- Ethereal Horse
gMountGrannyOverride[0x74] = gStandardHorse -- Nightmare
gMountGrannyOverride[0xB2] = gStandardHorse -- nightmare 4
gMountGrannyOverride[0xB3] = gStandardHorse -- dark steed
gMountGrannyOverride[0xBE] = gStandardHorse -- FireSteed
gMountGrannyOverride[0x123] = hex2num("0x76") -- packhorse, not C8 (standardhorse) 
gMountGrannyOverride[0x317] = gStandardHorse -- Beetle
gMountGrannyOverride[0x31A] = gStandardHorse -- SwampDragon
gMountGrannyOverride[0x31F] = gStandardHorse -- ScaledSwampDragon
gMountGrannyOverride[0x11C] = gStandardHorse -- mondain steed
for k,v in pairs(gMountTranslate) do if (gMountGrannyOverride[v]) then gMountTranslate[k] = gMountGrannyOverride[v] end end

--[[
(tipp from btbn from uox3 code)
skeletalmount			0x3EBB
darksteed				0x3EA9
etherealhorse			0x3EAA
nightmare				0x3EB5
silversteed				0x3EA8
britwarhorse			0x3EB2
comwarhorse				0x3EB1
minaxwarhorse			0x3EAF
slwarhorse				0x3EB0
unicorn					0x3EB4
kirin					0x3EAD
seahorse				0x3EB3
giantfirebeetle			0x3E95 TODO 
ethereal_llama			0x3EAB
etherealostard			0x3EAC
nightmare2				0x3EA7
nightmare3				0x3EA9
tdnightmare				0x3EB7
ridgeback				0x3EB8
firesteed				0x3E9E
etherealkirin			0x3E9C
horse1					0x3EA2
etherealunicorn			0x3EB4
etherealridgeback		0x3E9A
etherealswampdragon		0x3E98
etherealbeetle			0x3E97
horse2					0x3E9F
desertostard			0x3EA3
frenziedostard			0x3EA4
forestostard			0x3EA5
llama					0x3EA6
horse3					0x3EA0
horse4					0x3EA1
hiryu					0x3E94
chimera					0x3E90  TODO -- also known as reptalon/raptalon ?  
cusidhe					0x3E91  TODO
mondainsteed			0x3E92
giantbeetle				0x3EBC
swampdragon				0x3EBD
armorswampdragon		0x3EBE
kirin					0x3EAD


RunUO1.0/Scripts/Engines/Factions/Mobiles/FactionWarHorse.cs:8:	public class FactionWarHorse : BaseMount
RunUO1.0/Scripts/Mobiles/Animals/Mounts :  int bodyID, int itemID,

artid=8502	artid=0x2136	animid=0	animid=0x0000	frenzied ostard
artid=9652	artid=0x25b4	animid=0	animid=0x0000	Frenzied Ostard

FactionWarHorse			 0xE2	, 0x3EA0
RidableLlama			 0xDC	, 0x3EA6
Kirin					 0x84	, 0x3EAD
DesertOstard			 0xD2	, 0x3EA3
FireSteed				 0xBE	, 0x3E9E
FrenziedOstard			 0xDA	, 0x3EA4
SeaHorse				 0x90	, 0x3EB3
Nightmare				 0x74	, 0x3EA7
Ridgeback				 0xBB	, 0x3EBA
ScaledSwampDragon		 0x31F	, 0x3EBE
SilverSteed				 0x75	, 0x3EA8
Horse					 0xE2	, 0x3EA0
SwampDragon				 0x31A	, 0x3EBD
CoMWarHorse				 0x77	, 0x3EB1
MinaxWarHorse			 0x78	, 0x3EAF
TBWarHorse				 0x76	, 0x3EB2
SLWarHorse				 0x79	, 0x3EB0
SkeletalMount			 0x319	, 0x3EBB
HellSteed				 0x319	, 0x3EBB
ForestOstard			 0xDB	, 0x3EA5
Beetle					 0x317	, 0x3EBC
Unicorn					 0x7A	, 0x3EB4
SavageRidgeback			 0xBC	, 0x3EB8
                  	 

EtherealHorse			 0x20DD, 0x3EAA    EtherealMount( int itemID, int mountID )
EtherealLlama			 0x20F6, 0x3EAB 
EtherealOstard			 0x2135, 0x3EAC 
EtherealRidgeback		 0x2615, 0x3E9A 
EtherealUnicorn			 0x25CE, 0x3E9B 
EtherealBeetle			 0x260F, 0x3E97 
EtherealKirin			 0x25A0, 0x3E9C 
EtherealSwampDragon		 0x2619, 0x3E98 

]]--
