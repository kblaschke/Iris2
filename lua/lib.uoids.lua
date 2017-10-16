-- manages all UO id's
--								Right						Down						Left						Up
gDirection = {[0]="North",[1]="Northeast",[2]="East",[3]="Southeast", [4]="South",[5]="Southwest",[6]="West",[7]="Northwest"}
kWalkFlag_Run = hex2num("0x80")

gGender = { [0] = "Male", [1] = "Female" } 
gRace = { [1] = "Human", [2] = "Elf" }

gSeasonSetting = 0
gSeasonIDs = {[0]="Spring",[1]="Summer",[2]="Fall",[3]="Winter",[4]="Desolation"}

function ParseHex2HexArray (arr)
	local newarr = {}
	for k,v in pairs(arr) do if (type(k) == "string") then newarr[tonumber(k,16)] = tonumber(v,16) else newarr[k]=v end end  -- hex2num("0x123") is preferred to tonumber(123,16), it is better readable
	return newarr
end

-- base body gump ids
kGumpBaseId_Male	= 50000
kGumpBaseId_Female	= 60000

kGumpTypeVirtue = 0x000001CD -- 0x1CD = 461 RunUO-2.0-Final-MONO/src/Network/PacketHandlers.cs:1148:	public static void DisplayGumpResponse( NetState state, PacketReader pvSrc ) { ... 
kGumpClassName_VirtueGumpItem = "VirtueGumpItem"
kGumpClassName_VirtueGumpItem_HueMeaning = {} -- RunUO-2.0-Final-MONO/Scripts/Engines/Virtues/VirtueGump.cs
kVirtueRankName = { "Seeker", "Follower", "Knight",}
kVirtueData = { -- VirtueGump.cs
	{name="Humility"	,index=0,gump=108,hues={0x0481, 0x0963, 0x0965,},},
	{name="Sacrifice"	,index=1,gump=110,hues={0x060A, 0x060F, 0x002A,},}, -- 0x60f
	{name="Compassion"	,index=2,gump=105,hues={0x08A4, 0x08A7, 0x0034,},},
	{name="Spiritulaity",index=3,gump=111,hues={0x0965, 0x08FD, 0x0480,},},
	{name="Valor"		,index=4,gump=112,hues={0x00EA, 0x0845, 0x0020,},}, -- 0x20
	{name="Honor"		,index=5,gump=107,hues={0x0011, 0x0269, 0x013D,},},
	{name="Justice"		,index=6,gump=109,hues={0x08A1, 0x08A3, 0x0042,},}, -- 0x8a3
	{name="Honesty"		,index=7,gump=106,hues={0x0543, 0x0547, 0x0061,},},
}
function GetVirtueTitle (gump,hue)  -- hues:m_Table[(index * 3) + (int)(value/10000)]  (value max = 20000)
	hue = tonumber(hue) or 0
	for k1,vir in ipairs(kVirtueData) do if (gump == vir.gump) then
		for k2,vhue in ipairs(vir.hues) do if (hue == vhue) then return kVirtueRankName[k2].." of "..vir.name end end
		return vir.name -- hue=2402=gray/inactive
	end end
end	
assert(GetVirtueTitle(112,32) == "Knight of Valor") 
assert(GetVirtueTitle(110,1551) == "Follower of Sacrifice")
assert(GetVirtueTitle(109,2211) == "Follower of Justice")

gMaxHueValue = 2999 -- hues.mul has only 2999 values
gMaxArtValue = hex2num("0xbfff")

-- from this artid are starting Multis
gMulti_ID = hex2num("0x4000")

kMobileGhostArtIDs = {402,403,607,608,970}
kSparkleArtIDs = {0x373A,0x375a} -- dynamic-teleporters
kMoongateGateArtID = 3948 -- blue moongate, gate-travel-spell

-- the meaning of mobile.flag
kMobileFlag_Unknown1		= hex2num("0x01")
kMobileFlag_Unknown2		= hex2num("0x02") -- either CanAlterPaperdoll (necro) or Female (jerrit)
kMobileFlag_Poisoned		= hex2num("0x04")
kMobileFlag_GoldenHealth	= hex2num("0x08") -- = YellowHits , healthbar gets yellow (bleed attack, caused by troglodytes for example, can't healt then)
kMobileFlag_FactionShip		= hex2num("0x10") -- unsure why client needs to know
kMobileFlag_Movable			= hex2num("0x20") -- Movable if normally not
kMobileFlag_WarMode			= hex2num("0x40")
kMobileFlag_Hidden			= hex2num("0x80") -- probably self while hiding/stealth-walking, displayed as gray in original client

kHiddenMobileHue = 1104

gSkillNumber = 55		--RunUO-ML

gRequest_States		= hex2num("0x04") -- Basic Stats (Packet 0x11 Response)
gRequest_Skills		= hex2num("0x05") -- Request Skills (Packet 0x3A Response)

gWarmode_Normal	= 0	-- 0x00
gWarmode_Combat	= 1	-- 0x01

--Warmode Status_Bar GumpIDs
kHealthBarGump_Background_Normal	= 0x803
kHealthBarGump_Background_NameEntry	= 0x804 -- top:big text field, bottom : health, for npcs
kHealthBarGump_Bar_Red				= 0x805
kHealthBarGump_Bar_Blue				= 0x806
kHealthBarGump_Background_Warmode	= 0x807
kHealthBarGump_Bar_Green			= 0x808
kHealthBarGump_Bar_Golden			= 0x809
kHealthBarGump_FullWidth 			= 109

--Walk Limits
--gPersonHeight = 16
gMaxZ_Climb	= 7		--3 is to low for ladders
gMaxZ_Fall	= 12	-- TODO: char falls through hauslayers; 20 is maybe too much
gIllegalZ	= 127
gMaxZ_Blocks = 14

kAnimTypeID_Monster	= 0
kAnimTypeID_Sea		= 1
kAnimTypeID_Animal	= 2
kAnimTypeID_Human	= 3
kAnimTypeID_Other	= 4

-- EffectTypes
gEffectTypes = {}
gEffectTypes[hex2num("0x00")] = "Moving Effect"
gEffectTypes[hex2num("0x01")] = "Lightning Effect"
gEffectTypes[hex2num("0x02")] = "FixedXYZ Effect"
gEffectTypes[hex2num("0x03")] = "FixedFrom Effect"

--Text types
gTextNormal				= hex2num("0x00")
gTextBroadcast			= hex2num("0x01")
gTextEmote				= hex2num("0x02")
gTextSystem				= hex2num("0x06")
gTextMessageWithName	= hex2num("0x07")
gTextWhisper			= hex2num("0x08")
gTextYell				= hex2num("0x09")
gTextSpell				= hex2num("0x0A")
gTextGuildChat			= hex2num("0x0D")
gTextAllianceChat		= hex2num("0x0E")
gTextCommandPrompts		= hex2num("0x0F")
gTextEncodedCmd			= hex2num("0xC0")

gBoats = {}
--Small boat
gBoats[hex2num("0x4000")] = 16093	--Small Boat Facing North
gBoats[hex2num("0x4001")] = 15962	--Small Boat Facing East
gBoats[hex2num("0x4002")] = 16098	--Small Boat Facing South
gBoats[hex2num("0x4003")] = 15980	--Small Boat Facing West
--Small Dragon Boat
gBoats[hex2num("0x4004")] = 16093	--Small Dragon Boat Facing North
gBoats[hex2num("0x4005")] = 15962	--Small Dragon Boat Facing East
gBoats[hex2num("0x4006")] = 16098	--Small Dragon Boat Facing South
gBoats[hex2num("0x4007")] = 15980	--Small Dragon Boat Facing West
--Medium Boat
gBoats[hex2num("0x4008")] = 16093	--Medium Boat Facing North
gBoats[hex2num("0x4009")] = 15962	--Medium Boat Facing East
gBoats[hex2num("0x400A")] = 16098	--Medium Boat Facing South
gBoats[hex2num("0x400B")] = 15980	--Medium Boat Facing West
--Median Dragon Dragon Boat
gBoats[hex2num("0x400C")] = 16093	--Medium Dragon Boat Facing North
gBoats[hex2num("0x400D")] = 15962	--Medium Dragon Boat Facing East
gBoats[hex2num("0x400E")] = 16098	--Medium Dragon Boat Facing South
gBoats[hex2num("0x400F")] = 15980	--Medium Dragon Boat Facing West
--Large Boat
gBoats[hex2num("0x4010")] = 16093	--Long Boat Facing North
gBoats[hex2num("0x4011")] = 15962	--Long Boat Facing East
gBoats[hex2num("0x4012")] = 16098	--Long Boat Facing South
gBoats[hex2num("0x4013")] = 15980	--Long Boat Facing West
--Large Dragon Boat
gBoats[hex2num("0x4014")] = 16093	--Long Dragon Boat Facing North
gBoats[hex2num("0x4015")] = 15962	--Long Dragon Boat Facing East
gBoats[hex2num("0x4016")] = 16098	--Long Dragon Boat Facing South
gBoats[hex2num("0x4017")] = 15980	--Long Dragon Boat Facing West

-- Paperdoll Layer
gLayerType = {}
gLayerType.kLayer_OneHanded 		= 0x01 -- weapon
gLayerType.kLayer_TwoHanded 		= 0x02 -- weapon , shield, or misc.	
gLayerType.kLayer_Shoes				= 0x03
gLayerType.kLayer_Pants				= 0x04
gLayerType.kLayer_Shirt				= 0x05
gLayerType.kLayer_Helm				= 0x06 -- or Hat
gLayerType.kLayer_Gloves			= 0x07
gLayerType.kLayer_Ring				= 0x08
gLayerType.kLayer_Talisman			= 0x09 -- talismans, hangs above shield
gLayerType.kLayer_Neck				= 0x0A
gLayerType.kLayer_Hair				= 0x0B
gLayerType.kLayer_Waist 			= 0x0C -- (half apron)
gLayerType.kLayer_TorsoInner 		= 0x0D -- (inner) (chest armor)		
gLayerType.kLayer_Bracelet			= 0x0E
gLayerType.kLayer_Unused			= 0x0F --  (backpack, but backpacks go to 0x15)		
gLayerType.kLayer_FacialHair		= 0x10
gLayerType.kLayer_TorsoMiddle		= 0x11 --  (middle) (sircoat, tunic, full apron, sash)			
gLayerType.kLayer_Earrings			= 0x12
gLayerType.kLayer_Arms				= 0x13
gLayerType.kLayer_Back 				= 0x14 -- (cloak)
gLayerType.kLayer_Backpack			= 0x15
gLayerType.kLayer_TorsoOuter		= 0x16 -- (outer) (robe)
gLayerType.kLayer_LegsOuter			= 0x17 -- (outer) (skirt/kilt)
gLayerType.kLayer_LegsInner			= 0x18 -- (inner) (leg armor)
gLayerType.kLayer_Mount 			= 0x19 -- (horse, ostard, etc)	
gLayerType.kLayer_NPCBuyRestock 	= 0x1A -- container	
gLayerType.kLayer_NPCBuyNoRestock 	= 0x1B -- container	
gLayerType.kLayer_NPCSellContainer	= 0x1C
gLayerType.kLayer_PCBankBox 		= 0x1D
for k,v in pairs(gLayerType) do _G[k] = v end -- make names available as global constants
gLayerTypeName = {}
for k,v in pairs(gLayerType) do gLayerTypeName[v] = k end -- make names available as global constants

gPaperdollFallbackGfx = {}
gPaperdollFallbackGfx[kLayer_Back] = 0x1515 -- fallback : normal cloak for broken arcane cloak
kPaperdollFallbackLast = 0x1515 -- robe


gPaperdollBlockingLayers = {
	[kLayer_TorsoOuter] = {kLayer_Arms,kLayer_TorsoInner} -- kLayer_Helm, 
}

-- WARNING ! this is not a complete list (see gLayerType for that) , e.g. kLayer_Mound = 0x19 is not in here
gLayerOrder = {
	0x09,					   -- - N/A (not used)
    0x14,                       -- - Back (Cloak)
    0x10,                       -- - Facial Hair
    0x12,                       -- - Earrings
    0x04,                       -- - Leg Covering (including Pants"), Shorts"), Bone/Chain/Ring legs)
    0x0E,                       -- - Bracelet
    0x03,                       -- - Foot Covering/Armor
    0x08,                       -- - Ring
    0x18,                       -- - Legs (inner)(Leg Armor)
    0x05,                       -- - Chest Clothing/Female Chest Armor
    0x0D,                       -- - Torso (inner)(Chest Armor)
    0x11,                       -- - Torso (Middle)(Surcoat"), Tunic"), Full Apron"), Sash)
    0x0A,                       -- - Neck Covering/Armor
    0x13,                       -- - Arm Covering/Armor
    0x07,                       -- - Hand Covering/Armor
    0x17,                       -- - Legs (outer)(Skirt/Kilt)
    0x0B,                       -- - Hair
    0x06,                       -- - Head Covering/Armor
    0x16,                       -- - Torso (outer)(Robe) 
    0x0C,                       -- - Waist (Half-Apron)
    0x01,                       -- - Single-Hand item/weapon
    0x02,                       -- - Two-Hand item/weapon (including Shield)
    0x15,                       -- - BackPack
    0x0F
}


-- 2d mode ingame anims, from varan
gLayerOrderByDir = {}
function RevertArray (arr) local res = {} for k=#arr,1,-1 do table.insert(res,arr[k]) end return res end
gLayerOrderByDir[0] = RevertArray({ 21, 20, 02, 01, 06, 18, 16, 12, 22, 11, 10, 17, 23, 07, 19, 15, 14, 09, 08, 13, 24, 03, 04, 05 })
gLayerOrderByDir[1] = RevertArray({ 21, 02, 20, 01, 06, 18, 16, 12, 22, 11, 10, 17, 23, 07, 19, 15, 14, 09, 08, 13, 24, 03, 04, 05 })
gLayerOrderByDir[2] = RevertArray({ 21, 02, 20, 01, 06, 18, 16, 12, 22, 11, 10, 17, 23, 07, 19, 15, 14, 09, 08, 13, 24, 03, 04, 05 })
gLayerOrderByDir[3] = RevertArray({ 21, 02, 01, 06, 18, 16, 12, 22, 11, 10, 17, 23, 07, 19, 15, 14, 09, 08, 13, 24, 03, 04, 05, 20 })
gLayerOrderByDir[4] = RevertArray({ 21, 02, 20, 01, 06, 18, 16, 12, 22, 11, 10, 17, 23, 07, 19, 15, 14, 09, 08, 13, 24, 03, 04, 05 })
gLayerOrderByDir[5] = RevertArray({ 21, 02, 20, 01, 06, 18, 16, 12, 22, 11, 10, 17, 23, 07, 19, 15, 14, 09, 08, 13, 24, 03, 04, 05 })
gLayerOrderByDir[6] = RevertArray({ 21, 20, 02, 01, 06, 18, 16, 12, 22, 11, 10, 17, 23, 07, 19, 15, 14, 09, 08, 13, 24, 03, 04, 05 })
gLayerOrderByDir[7] = RevertArray({ 21, 20, 02, 01, 06, 18, 16, 12, 22, 11, 10, 17, 23, 07, 19, 15, 14, 09, 08, 13, 24, 03, 04, 05 })

-- you can add a paperdoll layer here with a position to overwrite the position in paperdoll (centered)
-- if you overwrite something the artid is used instead of the gumpid
-- this is used for brace/ring list ob the left side of the paperdoll
gLayerOrderPositionAndArtOverwrite = {
	[gLayerType.kLayer_Helm		] = {14,95 + 23*0},
	[gLayerType.kLayer_Earrings	] = {14,95 + 23*1},
	[gLayerType.kLayer_Neck		] = {14,95 + 23*2}, -- necklace,gorget
	[gLayerType.kLayer_Ring		] = {14,95 + 23*3},
	[gLayerType.kLayer_Bracelet	] = {14,95 + 23*4},
}

kMapIndex = {}
kMapIndex.Felucca	= 0
kMapIndex.Trammel	= 1
kMapIndex.Ilshenar	= 2
kMapIndex.Malas		= 3
kMapIndex.Tokuno	= 4
kMapNameByIndex = {} for k,v in pairs(kMapIndex) do kMapNameByIndex[v] = k end



-- Tiledata Flags
kTileDataFlag_Background		= hex2num("0x00000001")
kTileDataFlag_Weapon			= hex2num("0x00000002") -- set for weapons AND shields (7035)  (rather:can be equipped,also set for backpack etc)
kTileDataFlag_Transparent		= hex2num("0x00000004")
kTileDataFlag_Translucent		= hex2num("0x00000008")
kTileDataFlag_Wall				= hex2num("0x00000010")
kTileDataFlag_Damaging			= hex2num("0x00000020")
kTileDataFlag_Impassable		= hex2num("0x00000040")
kTileDataFlag_Wet				= hex2num("0x00000080")
kTileDataFlag_Unknown			= hex2num("0x00000100")
kTileDataFlag_Surface			= hex2num("0x00000200")	-- walkable
kTileDataFlag_Bridge			= hex2num("0x00000400")	-- walkable
kTileDataFlag_Generic_Stackable	= hex2num("0x00000800")
kTileDataFlag_Window			= hex2num("0x00001000")
kTileDataFlag_No_Shoot			= hex2num("0x00002000")
kTileDataFlag_Prefix_A			= hex2num("0x00004000")
kTileDataFlag_Prefix_An			= hex2num("0x00008000")
kTileDataFlag_Internal			= hex2num("0x00010000") --  (things like hair, beards, etc)
kTileDataFlag_Foliage			= hex2num("0x00020000")
kTileDataFlag_Partial_Hue		= hex2num("0x00040000")
kTileDataFlag_Unknown1			= hex2num("0x00080000")
kTileDataFlag_Map				= hex2num("0x00100000")
kTileDataFlag_Container			= hex2num("0x00200000")
kTileDataFlag_Wearable			= hex2num("0x00400000")
kTileDataFlag_LightSource		= hex2num("0x00800000")
kTileDataFlag_Animated			= hex2num("0x01000000")
kTileDataFlag_No_Diagonal		= hex2num("0x02000000")
kTileDataFlag_Unknown2			= hex2num("0x04000000")
kTileDataFlag_Armor				= hex2num("0x08000000")	--client
kTileDataFlag_Roof				= hex2num("0x10000000")
kTileDataFlag_Door				= hex2num("0x20000000")
kTileDataFlag_StairBack			= hex2num("0x40000000")	-- walkable
kTileDataFlag_StairRight		= hex2num("0x80000000")	-- walkable - stairback/stairright -> use 2 bits as stairs direction, N,S,W,E) (server)

kPopupEntryFlag_Locked			= hex2num("0x01")
kPopupEntryFlag_Arrow			= hex2num("0x02")
kPopupEntryFlag_Color			= hex2num("0x20")

kPopupStyle_UO_DEFAULT			= hex2num("0x0a3c")
kPopupStyle_FRAMED_BLACK		= hex2num("0x2436")
kPopupStyle_FRAMED_GRAY			= hex2num("0x0e10")
kPopupStyle_FRAMED_DOUBLE		= hex2num("0x2422")
kPopupStyle_FANCY				= hex2num("0x0053")

gCharCreateSkillIDs = {}
gCharCreateSkillIDs["Alchemy"]					= 0
gCharCreateSkillIDs["Anatomy"]					= 1
gCharCreateSkillIDs["Animal Lore"]				= 2
gCharCreateSkillIDs["Item Identification"]		= 3
gCharCreateSkillIDs["Arms Lore"]				= 4
gCharCreateSkillIDs["Parrying"]					= 5
gCharCreateSkillIDs["Begging"]					= 6
gCharCreateSkillIDs["Blacksmithy"]				= 7
gCharCreateSkillIDs["Bowcraft/Fletching"]		= 8
gCharCreateSkillIDs["Peacemaking"]				= 9
gCharCreateSkillIDs["Camping"]					= 10
gCharCreateSkillIDs["Carpentry"]				= 11
gCharCreateSkillIDs["Cartography"]				= 12
gCharCreateSkillIDs["Cooking"]					= 13
gCharCreateSkillIDs["Detecting Hidden"]			= 14
gCharCreateSkillIDs["Discordance"]				= 15
gCharCreateSkillIDs["Evaluate Intelligence"]	= 16
gCharCreateSkillIDs["Healing"]					= 17
gCharCreateSkillIDs["Fishing"]					= 18
gCharCreateSkillIDs["Forensic Evaluation"]		= 19
gCharCreateSkillIDs["Herding"]					= 20
gCharCreateSkillIDs["Hiding"]					= 21
gCharCreateSkillIDs["Provocation"]				= 22
gCharCreateSkillIDs["Inscription"]				= 23
gCharCreateSkillIDs["Lockpicking"]				= 24
gCharCreateSkillIDs["Magery"]					= 25
gCharCreateSkillIDs["Resisting Spells"]			= 26
gCharCreateSkillIDs["Tactics"]					= 27
gCharCreateSkillIDs["Snooping"]					= 28
gCharCreateSkillIDs["Musicianship"]				= 29
gCharCreateSkillIDs["Poisoning"]				= 30
gCharCreateSkillIDs["Archery"]					= 31
gCharCreateSkillIDs["Spirit Speak"]				= 32
gCharCreateSkillIDs["Stealing"]					= 33
gCharCreateSkillIDs["Tailoring"]				= 34
gCharCreateSkillIDs["Animal Taming"]			= 35
gCharCreateSkillIDs["Taste Identification"]		= 36
gCharCreateSkillIDs["Tinkering"]				= 37
gCharCreateSkillIDs["Tracking"]					= 38
gCharCreateSkillIDs["Veterinary"]				= 39
gCharCreateSkillIDs["Swordsmanship"]			= 40
gCharCreateSkillIDs["Mace Fighting"]			= 41
gCharCreateSkillIDs["Fencing"]					= 42
gCharCreateSkillIDs["Wrestling"]				= 43
gCharCreateSkillIDs["Lumberjacking"]			= 44
gCharCreateSkillIDs["Mining"]					= 45
gCharCreateSkillIDs["Meditation"]				= 46
gCharCreateSkillIDs["Stealth"]					= 47 -- not possible to set > 0 at charcreate !!!!
gCharCreateSkillIDs["Remove Trap"]				= 48 -- not possible to set > 0 at charcreate !!!!
gCharCreateSkillIDs["Necromancy"]				= 49
gCharCreateSkillIDs["Focus"]					= 50
gCharCreateSkillIDs["Chivalry"]					= 51
gCharCreateSkillIDs["Bushido"]					= 52
gCharCreateSkillIDs["Ninjitsu"]					= 53
gCharCreateSkillIDs["Spellweaving"]				= 54 -- not possible to set > 0 at charcreate !!!!
gCharCreateSkillIDs["Mysticism"]				= 55
gCharCreateSkillIDs["Imbuing"]					= 56

kNotoriety_Invalid		= 0 -- invalid/across server line
kNotoriety_Blue			= 1 -- innocent (blue)
kNotoriety_Friend		= 2 -- guilded/ally (green)
kNotoriety_Neutral		= 3 -- attackable but not criminal (original : gray, animals etc)
kNotoriety_Crime		= 4 -- criminal (gray)
kNotoriety_Orange		= 5 -- enemy (orange)
kNotoriety_Red			= 6 -- murderer (red)
kNotoriety_Invul		= 7 -- unknown use (translucent (like 0x4000 hue)) 


kTextType_Normal			= 0x00
kTextType_System			= 0x01 -- Broadcast/System 
kTextType_Emote				= 0x02
kTextType_Label				= 0x06 -- after singleclick on mob
kTextType_Corner			= 0x07 -- Message/Corner With Name  (lower-left corner?) Focus?
kTextType_Whisper			= 0x08
kTextType_Yell				= 0x09 
kTextType_Spell				= 0x0A
kTextType_Guild				= 0x0D -- Guild Chat 
kTextType_Alliance			= 0x0E -- Alliance Chat 
kTextType_CommandPrompt		= 0x0F -- Command Prompts ???
kTextType_Encoded			= 0xC0 -- flag set if chat contains keywords from speech.mul ?

kPlayerVendorLabelHue = 53

	
-- skill ids and stuff
glSkillNames = {	
	[1] 	= "Alchemy",
	[2]		= "Anatomy",
	[3]		= "Animal Lore",
	[4]		= "Item Identification", -- (Appraise)
	[5]		= "Arms Lore",
	[6]		= "Parrying", -- (Battle Defense)
	[7]		= "Begging",
	[8]		= "Blacksmithy",
	[9]		= "Bowcraft/Fletching",
	[10]	= "Peacemaking", -- (Calming)
	[11]	= "Camping",
	[12]	= "Carpentry",
	[13]	= "Cartography",
	[14]	= "Cooking",
	[15]	= "Detecting Hidden",
	[16]	= "Discordance",
	[17]	= "Evaluate Intelligence",
	[18]	= "Healing",
	[19]	= "Fishing",
	[20]	= "Forensic Evaluation",
	[21]	= "Herding",
	[22]	= "Hiding",
	[23]	= "Provocation",
	[24]	= "Inscription",
	[25]	= "Lockpicking",
	[26]	= "Magery",
	[27]	= "Resisting Spells", -- Magic Resistance
	[28]	= "Tactics",
	[29]	= "Snooping",
	[30]	= "Musicianship",
	[31]	= "Poisoning",
	[32]	= "Archery",
	[33]	= "Spirit Speak",
	[34]	= "Stealing",
	[35]	= "Tailoring",
	[36]	= "Animal Taming",
	[37]	= "Taste Identification",
	[38]	= "Tinkering",
	[39]	= "Tracking",
	[40]	= "Veterinary",
	[41]	= "Swordsmanship",
	[42]	= "Mace Fighting",
	[43]	= "Fencing",
	[44]	= "Wrestling",
	[45]	= "Lumberjacking",
	[46]	= "Mining",
	[47]	= "Meditation",
	[48]	= "Stealth",
	[49]	= "Remove Trap",
	[50]	= "Necromancy",

	--new since UO:SE & UO:ML
	[51]	= "Focus",
	[52]	= "Chivalry",
	[53]	= "Bushido",
	[54]	= "Ninjitsu",
	[55]	= "Spellweaving",	-- ? correct?
	
	[56]	= "Mysticism",
	[57]	= "Imbuing",
}


-- for mainmenu.accountlist infos
glSkillNamesShort = {	
	[1] 	= "Alch",
	[2]		= "Ana",
	[3]		= "AniLore",
	[4]		= "ItemId", -- (Appraise)
	[5]		= "ArmsLore",
	[6]		= "Parry", -- (Battle Defense)
	[7]		= "Beg",
	[8]		= "BSmith",
	[9]		= "Fletch",
	[10]	= "Peace", -- (Calming)
	[11]	= "Camp",
	[12]	= "Carp",
	[13]	= "Carto",
	[14]	= "Cook",
	[15]	= "Detect",
	[16]	= "Disco",
	[17]	= "EvalInt",
	[18]	= "Heal",
	[19]	= "Fish",
	[20]	= "Forensic",
	[21]	= "Herd",
	[22]	= "Hide",
	[23]	= "Provo",
	[24]	= "Inscri",
	[25]	= "Lockpick",
	[26]	= "Mage",
	[27]	= "SpellRes", -- Magic Resistance
	[28]	= "Tac",
	[29]	= "Snoop",
	[30]	= "Musi",
	[31]	= "Pois",
	[32]	= "Arch",
	[33]	= "Spirit",
	[34]	= "Steal",
	[35]	= "Tailor",
	[36]	= "Taming",
	[37]	= "TasteId",
	[38]	= "Tinker",
	[39]	= "Track",
	[40]	= "Vet",
	[41]	= "Sword",
	[42]	= "Mace",
	[43]	= "Fence",
	[44]	= "Wrestl",
	[45]	= "Lumber",
	[46]	= "Mining",
	[47]	= "Medi",
	[48]	= "Stealth",
	[49]	= "Disarm",
	[50]	= "Necro",

	--new since UO:SE & UO:ML
	[51]	= "Focus",
	[52]	= "Chiv",
	[53]	= "Bush",
	[54]	= "Ninj",
	[55]	= "Spellweaving",	-- ? correct?
	[56]	= "Myst",
	[57]	= "Imbu",
}

-- the list of skill activ(1)/passiv(0) flags
glSkillActive = {	
	[1] 	= 0,
	[2]		= 1,
	[3]		= 1,
	[4]		= 1,
	[5]		= 1,
	[6]		= 0,
	[7]		= 1,
	[8]		= 0,
	[9]		= 0,
	[10]	= 1,
	[11]	= 0,
	[12]	= 0,
	[13]	= 1,
	[14]	= 0,
	[15]	= 1,
	[16]	= 1,
	[17]	= 1,
	[18]	= 0,
	[19]	= 0,
	[20]	= 1,
	[21]	= 0,
	[22]	= 1,
	[23]	= 1,
	[24]	= 1,
	[25]	= 0,
	[26]	= 0,
	[27]	= 0,
	[28]	= 0,
	[29]	= 0,
	[30]	= 0,
	[31]	= 1,
	[32]	= 0,
	[33]	= 1,
	[34]	= 1,
	[35]	= 0,
	[36]	= 1,
	[37]	= 1,
	[38]	= 0,
	[39]	= 1,
	[40]	= 0,
	[41]	= 0,
	[42]	= 0,
	[43]	= 0,
	[44]	= 0,
	[45]	= 0,
	[46]	= 0,
	[47]	= 1,
	[48]	= 1,
	[49]	= 1,
	[50]	= 0,

	--new since UO:SE & UO:ML
	[51]	= 0,
	[52]	= 0,
	[53]	= 0,
	[54]	= 0,
	[55]	= 0,
	
	[56]	= 0, -- mysticism
	[57]	= 1, -- imbuing
}



-- weapon abilities (name + gumpicons)
-- id id packet id that should be send
glWeaponAbilities = {
	[1] = {name="Armor Ignore",gumpicon=0x51FF+1},
	[2] = {name="Bleed Attack",gumpicon=0x51FF+2},
	[3] = {name="Concussion Blow",gumpicon=0x51FF+3},
	[4] = {name="Crushing Blow",gumpicon=0x51FF+4},
	[5] = {name="Disarm",gumpicon=0x51FF+5},
	[6] = {name="Dismount",gumpicon=0x51FF+6},
	[7] = {name="Doublestrike",gumpicon=0x51FF+7},
	[8] = {name="Infecting",gumpicon=0x51FF+8},
	[9] = {name="Mortalstrike",gumpicon=0x51FF+9},
	[10] = {name="Moving Shot",gumpicon=0x51FF+10},
	[11] = {name="Paralyzing Blow",gumpicon=0x51FF+11},
	[12] = {name="Shadow Strike",gumpicon=0x51FF+12},
	[13] = {name="Whirlwind Strike",gumpicon=0x51FF+13},
	[14] = {name="Ridingwipe",gumpicon=0x51FF+14},
	[15] = {name="Frenziedwhirlwind",gumpicon=0x51FF+15},
	[16] = {name="Block",gumpicon=0x51FF+16},
	[17] = {name="Defensemastery",gumpicon=0x51FF+17},
	[18] = {name="Nervestrike",gumpicon=0x51FF+18},
	[19] = {name="Talonstrike",gumpicon=0x51FF+19},
	[20] = {name="Feint",gumpicon=0x51FF+20},
	[21] = {name="Dualwield",gumpicon=0x51FF+21},
	[22] = {name="Doubleshot",gumpicon=0x51FF+22},
	[23] = {name="Armorpierce",gumpicon=0x51FF+23},
	[24] = {name="Bladeweave",gumpicon=0x51FF+24},
	[25] = {name="Force Arrow",gumpicon=0x51FF+25},
	[26] = {name="Lightning Arrow",gumpicon=0x51FF+26},
	[27] = {name="Psychic Attack",gumpicon=0x51FF+27},
	[28] = {name="Serpent Arrow",gumpicon=0x51FF+28},
	[29] = {name="Force Of Nature",gumpicon=0x51FF+29},
}

-- weapons and they assigned weaponabilities
-- id is the weapon artid
glWeaponAbilitiesWeapons = {
	[0] = {first=5,second=11},
	[3568] = {first=13,second=11},
	[3569] = {first=13,second=11},
	[3570] = {first=6,second=5},
	[3571] = {first=6,second=5},
	[3572] = {first=6,second=5},
	[3573] = {first=6,second=5},
	[3713] = {first=4,second=5},
	[3714] = {first=4,second=5},
	[3717] = {first=7,second=5},
	[3718] = {first=7,second=5},
	[3719] = {first=2,second=6},
	[3720] = {first=2,second=6},
	[3721] = {first=7,second=3},
	[3722] = {first=7,second=3},
	[3778] = {first=2,second=8},
	[3779] = {first=2,second=8},
	[3780] = {first=12,second=5},
	[3781] = {first=12,second=5},
	[3907] = {first=1,second=5},
	[3908] = {first=1,second=5},
	[3909] = {first=2,second=9},
	[3910] = {first=2,second=9},
	[3911] = {first=2,second=3},
	[3912] = {first=2,second=3},
	[3913] = {first=4,second=6},
	[3914] = {first=4,second=6},
	[3915] = {first=7,second=13},
	[3916] = {first=7,second=13},
	[3917] = {first=11,second=6},
	[3918] = {first=11,second=6},
	[3919] = {first=3,second=9},
	[3920] = {first=3,second=9},
	[3921] = {first=8,second=12},
	[3922] = {first=8,second=12},
	[3932] = {first=3,second=5},
	[3933] = {first=3,second=5},
	[3934] = {first=4,second=1},
	[3935] = {first=4,second=1},
	[3936] = {first=1,second=3},
	[3937] = {first=1,second=3},
	[3938] = {first=1,second=11},
	[3939] = {first=1,second=11},
	[4020] = {first=4,second=12},
	[4021] = {first=4,second=12},
	[5039] = {first=1,second=2},
	[5040] = {first=1,second=2},
	[5041] = {first=11,second=9},
	[5042] = {first=11,second=9},
	[5043] = {first=12,second=6},
	[5044] = {first=12,second=6},
	[5045] = {first=7,second=11},
	[5046] = {first=7,second=11},
	[5047] = {first=1,second=3},
	[5048] = {first=1,second=3},
	[5049] = {first=4,second=11},
	[5050] = {first=4,second=11},
	[5091] = {first=4,second=12},
	[5092] = {first=4,second=12},
	[5108] = {first=4,second=5},
	[5109] = {first=4,second=5},
	[5110] = {first=8,second=5},
	[5111] = {first=8,second=5},
	[5112] = {first=3,second=11},
	[5113] = {first=3,second=11},
	[5114] = {first=13,second=2},
	[5115] = {first=13,second=2},
	[5116] = {first=10,second=6},
	[5117] = {first=10,second=6},
	[5118] = {first=7,second=1},
	[5119] = {first=7,second=1},
	[5120] = {first=1,second=8},
	[5121] = {first=1,second=8},
	[5122] = {first=12,second=9},
	[5123] = {first=12,second=9},
	[5124] = {first=2,second=5},
	[5125] = {first=2,second=5},
	[5126] = {first=4,second=2},
	[5127] = {first=4,second=2},
	[5176] = {first=13,second=4},
	[5177] = {first=13,second=4},
	[5178] = {first=4,second=3},
	[5179] = {first=4,second=3},
	[5180] = {first=1,second=9},
	[5181] = {first=1,second=9},
	[5182] = {first=13,second=3},
	[5183] = {first=13,second=3},
	[5184] = {first=2,second=12},
	[5185] = {first=2,second=12},
	[5186] = {first=7,second=12},
	[5187] = {first=7,second=12},
	[9914] = {first=2,second=11},
	[9915] = {first=11,second=9},
	[9916] = {first=4,second=9},
	[9917] = {first=1,second=6},
	[9918] = {first=11,second=8},
	[9919] = {first=7,second=8},
	[9920] = {first=6,second=3},
	[9921] = {first=7,second=9},
	[9922] = {first=1,second=10},
	[9923] = {first=7,second=10},
	[9924] = {first=2,second=11},
	[9925] = {first=11,second=9},
	[9926] = {first=4,second=9},
	[9927] = {first=1,second=6},
	[9928] = {first=11,second=8},
	[9929] = {first=7,second=8},
	[9930] = {first=6,second=3},
	[9931] = {first=7,second=9},
	[9932] = {first=1,second=10},
	[9933] = {first=7,second=10},
	[10146] = {first=4,second=14},
	[10147] = {first=20,second=16},
	[10148] = {first=15,second=7},
	[10149] = {first=23,second=22},
	[10150] = {first=15,second=4},
	[10151] = {first=17,second=15},
	[10152] = {first=20,second=18},
	[10153] = {first=20,second=7},
	[10155] = {first=21,second=19},
	[10157] = {first=13,second=17},
	[10158] = {first=16,second=20},
	[10159] = {first=16,second=23},
	[10221] = {first=4,second=14},
	[10222] = {first=20,second=16},
	[10223] = {first=15,second=7},
	[10224] = {first=23,second=22},
	[10225] = {first=15,second=4},
	[10226] = {first=17,second=15},
	[10227] = {first=20,second=18},
	[10228] = {first=20,second=7},
	[10230] = {first=21,second=19},
	[10232] = {first=13,second=17},
	[10233] = {first=16,second=20},
	[10234] = {first=16,second=23},
	[11550] = {first=25,second=28},
	[11551] = {first=26,second=27},
	[11552] = {first=27,second=2},
	[11553] = {first=8,second=12},
	[11554] = {first=20,second=1},
	[11555] = {first=5,second=24},
	[11556] = {first=3,second=4},
	[11557] = {first=16,second=29},
	[11558] = {first=5,second=24},
	[11559] = {first=13,second=24},
	[11560] = {first=5,second=4},
	[11561] = {first=17,second=24},
	[11562] = {first=25,second=28},
	[11563] = {first=26,second=27},
	[11564] = {first=27,second=2},
	[11565] = {first=8,second=12},
	[11566] = {first=20,second=1},
	[11567] = {first=5,second=24},
	[11568] = {first=3,second=4},
	[11569] = {first=16,second=29},
	[11570] = {first=5,second=24},
	[11571] = {first=13,second=24},
	[11572] = {first=5,second=4},
	[11573] = {first=17,second=24},
}

gNodrawArtIDs = {0x21a3,0x21a4,0x2199,0x21bc,0x5690}
gNodrawByArtID = {}
for k,artid in ipairs(gNodrawArtIDs) do gNodrawByArtID[artid] = true end

gBroken2DArtAnims = {0x154d}
gBroken2DArtAnimsByID = {}
for k,artid in ipairs(gBroken2DArtAnims) do gBroken2DArtAnimsByID[artid] = true end

gStaticWaterArtIDs = {0x1559,0x1796,0x1797,0x1798,0x1799,0x179a,0x179b,0x179c,0x179d,0x179e,0x179f,0x17a0,0x17a1,0x17a2,0x17a3,0x17a4,0x17a5,0x17a6,0x17a7,0x17a8,0x17a9,0x17aa,0x17ab,0x17ac,0x17ad,0x17ae,0x17af,0x17b0,0x17b1,0x17b2,0x346e,0x346f,0x3470,0x3471,0x3472,0x3473,0x3474,0x3475,0x3476,0x3477,0x3478,0x3479,0x347a,0x347b,0x347c,0x347d,0x347e,0x347f,0x3480,0x3481,0x3482,0x3483,0x3484,0x3485,0x3494,0x3495,0x3496,0x3497,0x3498,0x349a,0x349b,0x349c,0x349d,0x349e,0x34a0,0x34a1,0x34a2,0x34a3,0x34a4,0x34a6,0x34a7,0x34a8,0x34a9,0x34aa,0x34ab,0x34b8,0x34b9,0x34ba,0x34bb,0x34bd,0x34be,0x34bf,0x34c0,0x34c2,0x34c3,0x34c4,0x34c5,0x34c7,0x34c8,0x34c9,0x34ca}
gStaticWaterByArtIDs = {}
for k,artid in ipairs(gStaticWaterArtIDs) do gStaticWaterByArtIDs[artid] = true end

gWaterGroundTileTypes = {0x00a8,0x00a9,0x00aa,0x00ab,0x0136,0x0137}
gWaterGroundByTileTypes = {}
for k,tiletype in ipairs(gWaterGroundTileTypes) do gWaterGroundByTileTypes[tiletype] = true end
