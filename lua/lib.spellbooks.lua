-- Spellbook definitions
-- TODO: update definition needed

kCastDelaySecondsPerTick = 0.25  -- RunUO-2.0-SVN/Scripts/Spells/Base/Spell.cs:639:	public virtual double CastDelaySecondsPerTick { get { return 0.25; } }

gSpellbookExpansion = {}
gSpellbookExpansion["AOS"]	= hex2num("0x00")		--Mage, Necromancer and Paladin spells
gSpellbookExpansion["SE"]	= hex2num("0x01")		--Samurai and Ninja Spells
gSpellbookExpansion["ML"]	= hex2num("0x02")		--Spellweaving Spells

gSpellNameAlias = {} -- spellbook(gui,spellid),spellinfo(runuo,powerwords/mantra,regs),razor-config-ids?
gSpellNameAlias["Feeblemind"		] = "FeebleMind"
gSpellNameAlias["Remove Trap"		] = "Magic Untrap"
gSpellNameAlias["Fireball"			] = "Fire Ball"
gSpellNameAlias["Unlock Spell"		] = "Unlock"
gSpellNameAlias["Blade Spirits"		] = "Blade Spirit"
gSpellNameAlias["Magic Reflection"	] = "Spell Reflection"
gSpellNameAlias["Summon Creature"	] = "Summ.Creature"
gSpellNameAlias["Flame Strike"		] = "FlameStrike"
gSpellNameAlias["Gate Travel"		] = "Gate"
gSpellNameAlias["Wraith Form"		] = "WraithForm"
gSpellNameAlias["Enemy of One"		] = "Enemy of one"
gSpellNameAlias["Gift of Renewal"	] = "Gift Of Renewal"
gSpellNameAlias["Nature's Fury"		] = "Nature Fury"
gSpellNameAlias["Essence of Wind"	] = "Essence Of Wind"
gSpellNameAlias["Word of Death"		] = "Word Of Death"
gSpellNameAlias["Gift of Life"		] = "Gift Of Life"
gSpellNameAlias["Attune Weapon"		] = "Attunement"

function SearchSpellIDByName (spellname)
	for spellbookid,spellbook in pairs(gSpellBooks) do
	local spellnumber = countarr(spellbook.spells[1])
	for kcircle,pagearr in ipairs(spellbook.spells) do 
	for kspell,spellname2 in ipairs(pagearr) do 
		if (spellname == spellname2) then return spellbook.startindex + kspell + (kcircle - 1) * spellnumber end
	end 
	end
	end
end



--RunUO1 old_spellbook Items
--[[
uogamers, open/doubleclick spellbook :
kPacket_Object_to_Object        {hue=0,iContainerSerial=0x409a8753,xloc=103=0x67,yloc=96=0x60,artid_base=3834=0x0efa,artid_addstack=0,zloc=0,amount=1=0x01,serial=0x409a8767,
HandleOpenContainer     {serial=0x409a8767,gumpid=0xffff,
NET: Old_Spellbook: serial=0x409a8767 itemId=0x0efa offset=0x0000
packet  typeid=0x3c,size=252,typename=kPacket_Container_Contents
	
Convert_Spellbookcontainer      table: 0xc635b90
+       {usegump=false,amount=1,		= 0+1,	iContainerSerial=0x409a8767,artid=0,serial=0x7fffffff,}  -7981   0
+       {usegump=false,amount=4,		= 0+4,	iContainerSerial=0x409a8767,artid=0,serial=0x7ffffffc,}  -7981   0
+       {usegump=false,amount=5,		= 0+5,	iContainerSerial=0x409a8767,artid=0,serial=0x7ffffffb,}  -7981   0
+       {usegump=false,amount=6,		= 0+6,	iContainerSerial=0x409a8767,artid=0,serial=0x7ffffffa,}  -7981   0

+       {usegump=false,amount=11=0x0b,	= 8+3,	iContainerSerial=0x409a8767,artid=0,serial=0x7ffffff5,}  -7981   0
+       {usegump=false,amount=12=0x0c	= 8+4,	iContainerSerial=0x409a8767,artid=0,serial=0x7ffffff4,}  -7981   0
+       {usegump=false,amount=16=0x10,	= 8+8,	iContainerSerial=0x409a8767,artid=0,serial=0x7ffffff0,}  -7981   0

+       {usegump=false,amount=18=0x12,	=16+2,	iContainerSerial=0x409a8767,artid=0,serial=0x7fffffee,}  -7981   0
+       {usegump=false,amount=20=0x14,	=16+4,	iContainerSerial=0x409a8767,artid=0,serial=0x7fffffec,}  -7981   0
+       {usegump=false,amount=22=0x16,	=16+6,	iContainerSerial=0x409a8767,artid=0,serial=0x7fffffea,}  -7981   0

+       {usegump=false,amount=28=0x1c,	=24+4,	iContainerSerial=0x409a8767,artid=0,serial=0x7fffffe4,}  -7981   0
+       {usegump=false,amount=29=0x1d,	=24+5,	iContainerSerial=0x409a8767,artid=0,serial=0x7fffffe3,}  -7981   0
+       {usegump=false,amount=30=0x1e	=24+6,	iContainerSerial=0x409a8767,artid=0,serial=0x7fffffe2,}  -7981   0
1st : clumsy,heal,magicarrow,nightsight                                 
2nd : cure,harm,strength
3rd : fireball,poison,teleport
4th : firefield,greaterheal,lightning

[1] = { [1] = "Clumsy", [4] = "Heal", [5] = "Magic Arrow", [6] = "Night Sight" },
[2] = { [3] = "Cure", [4] = "Harm",  [8] = "Strength" },
[3] = { [2] = "Fire Ball",[4] = "Poison", [6] = "Teleport" },
[4] = { [4] = "Fire Field", [5] = "Greater Heal", [6] = "Lightning"},

]]--
function Convert_Spellbookcontainer(matrix,container)
	print("Convert_Spellbookcontainer",container:GetContent())
	if (container:GetContent()) then
		for k,v in pairs(container:GetContent()) do
			local circle,spellpos = 0,0
			local artid = tonumber(v.artid)
			if (artid == 0) then
				circle   = floor((v.amount-1)/8)
				spellpos = mod(v.amount-1,8)
			else
				if     (artid >= 0x1F2D and artid < 0x1F35) then	circle=0
				elseif (artid >= 0x1F35 and artid < 0x1F3D) then	circle=1
				elseif (artid >= 0x1F3D and artid < 0x1F45) then	circle=2
				elseif (artid >= 0x1F45 and artid < 0x1F4D) then	circle=3
				elseif (artid >= 0x1F4D and artid < 0x1F55) then	circle=4
				elseif (artid >= 0x1F55 and artid < 0x1F5D) then	circle=5
				elseif (artid >= 0x1F5D and artid < 0x1F65) then	circle=6
				elseif (artid >= 0x1F65 and artid < 0x1F6D) then	circle=7
				end
				spellpos = v.artid - (0x1F2D + (circle * 8))
			end
			--~ print("+",SmartDump(v),spellpos,circle)
			matrix[circle+1] = BitwiseOR(matrix[circle+1], BitwiseSHL(1, spellpos))
		end
	end
	--for i=1, 8 do printf("Spell matrix[circle]=0x%02x\n",matrix[i]) end
	return matrix
end

--[[
Spell ID:	0x91 - 0x96 - Samurai Spells,
			0xF5 - 0xFC - Ninja Spells,
			0x59 - 0x68 - Spellweaving Spells
]]--

MageSpellbook			= hex2num("0x0EFA")
MageSpellbook2			= hex2num("0xFFFF") -- used by pol, mapped to MageSpellbook
NecroSpellbook			= hex2num("0x2253")
ChivalrySpellbook		= hex2num("0x2252") --dialog.gumpid = hex2num("0x2B01")
BushidoSpellbook		= hex2num("0x238C") --dialog.gumpid = hex2num("0x2B07")
NinjitsuSpellbook		= hex2num("0x23A0") --dialog.gumpid = hex2num("0x2B06")
SpellweavingSpellbook	= hex2num("0x2D50")	--dialog.gumpid = hex2num("0x2B2F")
--WeaponAbilityBook		= hex2num("0x2B02")

gSpellBooks = {}
gSpellBooks[MageSpellbook]	= {
	name		="Spellbook",
	gumpid		=hex2num("0x8AC"),
	minigumpid	=hex2num("0x8BA"),
	iconoffset = hex2num("0x8c0"),
	startindex  =0,
	circles	={[1]="First Circle",[2]="Second Circle",[3]="Third Circle",[4]="Fourth Circle",
			  [5]="Fifth Circle",[6]="Sixth Circle",[7]="Seventh Circle",[8]="Eighth Circle"},

	pages	={ [1]=1, [2]=1, [3]=2, [4]=2, [5]=3, [6]=3, [7]=4, [8]=4 },

	spells	={
		[1] = { [1] = "Clumsy", [2] = "Create Food", [3] = "FeebleMind", [4] = "Heal", [5] = "Magic Arrow", [6] = "Night Sight", [7] = "Reactive Armor", [8] = "Weaken" },
		[2] = { [1] = "Agility", [2] = "Cunning", [3] = "Cure", [4] = "Harm", [5] = "Magic Trap", [6] = "Magic Untrap", [7] = "Protection", [8] = "Strength" },
		[3] = { [1] = "Bless", [2] = "Fire Ball", [3] = "Magic Lock", [4] = "Poison", [5] = "Telekinesis", [6] = "Teleport", [7] = "Unlock", [8] = "Wall of Stone" },
		[4] = { [1] = "Arch Cure", [2] = "Arch Protection", [3] = "Curse", [4] = "Fire Field", [5] = "Greater Heal", [6] = "Lightning", [7] = "Mana Drain", [8] = "Recall"},
		[5] = { [1] = "Blade Spirit", [2] = "Dispel Field", [3] = "Incognito", [4] = "Spell Reflection", [5] = "Mind Blast", [6] = "Paralyze", [7] = "Poison Field", [8] = "Summ.Creature"},
		[6] = { [1] = "Dispel", [2] = "Energy Bolt", [3] = "Explosion", [4] = "Invisibility", [5] = "Mark", [6] = "Mass Curse", [7] = "Paralyze Field", [8] = "Reveal" },
		[7] = { [1] = "Chain Lightning", [2] = "Energy Field", [3] = "FlameStrike", [4] = "Gate", [5] = "Mana Vampire", [6] = "Mass Dispel", [7] = "Meteor Swarm", [8] = "Polymorph"},
		[8] = { [1] = "Earthquake", [2] = "Energy Vortex", [3] = "Resurrection", [4] = "Air Elemental", [5] = "Summon Daemon", [6] = "Earth Elemental", [7] = "Fire Elemental", [8] = "Water Elemental"}
	},

	reagenz = { [1]="Black Pearl", [2]="Blood Moss", [3]="Garlic", [4]="Ginseng", [5]="Mandrake", [6]="Nightshade", [7]="Spider Silk", [8]="Sulphurous Ash" },

	spell_reags = { 
		[1]	= { [1]={[1]=2,[2]=6}, [2]={[1]=3,[2]=4,[3]=5}, [3]={[1]=2,[2]=6}, [4]={[1]=3,[2]=4,[3]=7}, [5]={[1]=1,[2]=6}, [6]={[1]=7,[2]=8}, [7]={[1]=3,[2]=7,[3]=8}, [8]={[1]=3,[2]=6} },
		[2]	= { [1]={[1]=2,[2]=5}, [2]={[1]=5,[2]=6}, [3]={[1]=3,[2]=4}, [4]={[1]=6,[2]=7}, [5]={[1]=3,[2]=7,[3]=8}, [6]={[1]=2,[2]=8}, [7]={[1]=3,[2]=4,[3]=8}, [8]={[1]=5,[2]=6} },
		[3]	= { [1]={[1]=3,[2]=5}, [2]={[1]=1,[2]=8}, [3]={[1]=2,[2]=3,[3]=8}, [4]={[1]=6}, [5]={[1]=2,[2]=5}, [6]={[1]=2,[2]=5}, [7]={[1]=2,[2]=8}, [8]={[2]=3,[2]=3} },
		[4]	= { [1]={[1]=3,[2]=4,[3]=5}, [2]={[1]=3,[2]=4,[3]=5,[4]=8}, [3]={[1]=3,[2]=6,[3]=8}, [4]={[1]=1,[2]=7,[3]=8}, [5]={[1]=3,[2]=4,[3]=5,[4]=7}, [6]={[1]=1,[2]=5,[3]=8}, [7]={[1]=1,[2]=5,[3]=7}, [8]={[1]=1,[2]=2,[3]=5} },
		[5]	= { [1]={[1]=1,[2]=5,[3]=6}, [2]={[1]=1,[2]=3,[3]=7,[4]=8}, [3]={[1]=2,[2]=3,[3]=6}, [4]={[1]=3,[2]=5,[3]=7}, [5]={[1]=1,[2]=5,[3]=6,[4]=8}, [6]={[1]=3,[2]=5,[3]=7}, [7]={[1]=1,[2]=6,[3]=7}, [8]={[1]=2,[2]=5,[3]=7} },
		[6]	= { [1]={[1]=3,[2]=5,[3]=8}, [2]={[1]=1,[2]=6}, [3]={[1]=1,[2]=5,[3]=8}, [4]={[1]=2,[2]=6}, [5]={[1]=1,[2]=2,[3]=5}, [6]={[1]=3,[2]=5,[3]=6,[4]=8}, [7]={[1]=1,[2]=4,[3]=7}, [8]={[1]=2,[2]=8} },
		[7]	= { [1]={[1]=1,[2]=2,[3]=5,[4]=8}, [2]={[1]=1,[2]=5,[3]=7,[4]=8}, [3]={[1]=7,[2]=8}, [4]={[1]=1,[2]=5,[3]=8}, [5]={[1]=1,[2]=2,[3]=5,[4]=7}, [6]={[1]=1,[2]=3,[3]=5,[4]=8}, [7]={[1]=2,[2]=5,[3]=7,[4]=8}, [8]={[1]=2,[2]=5,[3]=7} },
		[8]	= { [1]={[1]=2,[2]=4,[3]=5,[4]=8}, [2]={[1]=1,[2]=2,[3]=5,[4]=6}, [3]={[1]=2,[2]=3,[3]=4}, [4]={[1]=2,[2]=5,[3]=7}, [5]={[1]=2,[2]=5,[3]=7,[4]=8}, [6]={[1]=2,[2]=5,[3]=7}, [7]={[1]=2,[2]=5,[3]=7,[4]=8}, [8]={[1]=2,[2]=5,[3]=7} }
	},
	
	ignore_available_flags = false
}
gSpellBooks[MageSpellbook2]	= gSpellBooks[MageSpellbook]

gSpellBooks[NecroSpellbook]	= {
	name		="Necromancer",
	gumpid		=hex2num("0x2B00"),
	minigumpid	=hex2num("0x2B03"),
	iconoffset = hex2num("0x5000"),
	startindex  =hex2num("0x64"),
	--~ circles	={[1]="First Circle",[2]="Second Circle"},
	circles	={[1]="First Circle",[2]="Second Circle",[3]="Third Circle",[4]="Fourth Circle"},

	--~ pages	={ [1]=1, [2]=1},
	pages	={ [1]=1, [2]=1, [3]=2, [4]=2 },

	spells	={
		[1] = { [1] = "Animate Dead", [2] = "Blood Oath", [3] = "Corpse Skin", [4] = "Curse Weapon", [5] = "Evil Omen", [6] = "Horrific Beast", [7] = "Lich Form", [8] = "Mind Rot" },
		[2] = { [1] = "Pain Spike", [2] = "Poison Strike", [3] = "Strangle", [4] = "Summon Familiar", [5] = "Vampiric Embrace", [6] = "Vengeful Spirit", [7] = "Wither", [8] = "WraithForm"},
		[3] = { [1] = "Exorcism" },
		[4] = { },
		},
		
	reagenz = { [1]="Bat Wing", [2]="Grave Dust", [3]="Daemon Blood", [4]="Nox Crystal", [5]="Pig Iron" },

	spell_reags = {
		[1]	= { [1]={[1]=2,[2]=3}, [2]={[1]=3}, [3]={[1]=1,[2]=2}, [4]={[1]=5}, [5]={[1]=1,[2]=4}, [6]={[1]=1,[2]=3}, [7]={[1]=2,[2]=3,[3]=4}, [8]={[1]=1,[2]=3,[3]=5} },
		[2]	= { [1]={[1]=2,[2]=5}, [2]={[1]=4}, [3]={[1]=3,[2]=4}, [4]={[1]=1,[2]=2,[3]=3}, [5]={[1]=1,[2]=4,[3]=5}, [6]={[1]=1,[2]=3,[3]=5}, [7]={[1]=2,[2]=4,[3]=5}, [8]={[1]=4,[2]=5} },
		[3]	= { [1]={[1]=4,[2]=2} },
		[4]	= {  },
	},
	
	ignore_available_flags = false
}

gSpellBooks[ChivalrySpellbook]	= {
	name		="Chivalry",
	gumpid		=hex2num("0x2B01"),
	minigumpid	=hex2num("0x2B04"),
	iconoffset = hex2num("0x5100"),
	startindex  =hex2num("0xC8"),
	circles	={[1]="First Circle",[2]="Second Circle"},

	pages	={ [1]=1, [2]=1 },

	spells	={
		[1] = { [1] = "Cleanse By Fire", [2] = "Close Wounds", [3] = "Consecrate Weapon", [4] = "Dispel Evil", [5] = "Divine Fury" },
		[2] = {	[1] = "Enemy of one", [2] = "Holy Light", [3] = "Noble Sacrifice", [4] = "Remove Curse", [5] = "Sacred Journey" }
		},

	reagenz = { [1]="Tithing Cost: 10", [2]="Tithing Cost: 30", [3]="Tithing Cost: 15", [4]="Mana Cost: 10", [5]="Mana Cost: 15", [6]="Mana Cost: 20",
				[7]="Min. Skill: 0", [8]="Min. Skill: 5", [9]="Min. Skill: 15", [10]="Min. Skill: 25", [11]="Min. Skill: 35", [12]="Min. Skill: 45",
				[13]="Min. Skill: 55", [14]="Min. Skill: 65" },

	spell_reags = {
		[1]	= { [1]={[1]=1,[2]=4,[3]=8}, [2]={[1]=1,[2]=4,[3]=7}, [3]={[1]=1,[2]=4,[3]=9}, [4]={[1]=1,[2]=4,[3]=11}, [5]={[1]=1,[2]=5,[3]=10} },
		[2] = {	[1]={[1]=1,[2]=6,[3]=12}, [2]={[1]=1,[2]=4,[3]=13}, [3]={[1]=2,[2]=6,[3]=14}, [4]={[1]=1,[2]=6,[3]=8}, [5]={[1]=3,[2]=4,[3]=9} }
	},

	ignore_available_flags = true
}

gSpellBooks[BushidoSpellbook] = {
	name		="Bushido",
	gumpid	=hex2num("0x2B07"),
	minigumpid	=hex2num("0x2B09"),
	iconoffset	=hex2num("0x5420"),
	startindex	=hex2num("0x190"),
	circles	={[1]="Bushido",[2]="Bushido"},

	pages	={ [1]=1, [2]=1 },

	spells     ={
			 [1] = { [1] = "Honorable Execution", [2] = "Confidence", [3] = "Evasion", [4] = "Counter Attack",
			 		 [5] = "Lightning Strike", [6] = "Momentum Strike"  },
			 [2] = {}		
		},

	reagenz = { [1]="Mana Cost: 0", [2]="Mana Cost: 5", [3]="Mana Cost: 10",
			[4]="Min. Skill: 25", [5]="Min. Skill: 40", [6]="Min. Skill: 50", [7]="Min. Skill: 60", [8]="Min. Skill: 70" },
				
	spell_reags = {
		[1]	= { [1]={[1]=1,[2]=4}, [2]={[1]=3,[2]=4}, [3]={[1]=3,[2]=7}, [4]={[1]=2,[2]=5}, [5]={[1]=2,[2]=6}, [6]={[1]=3,[2]=8}  },
		[2] = {},
	},

	ignore_available_flags = false
}

gSpellBooks[SpellweavingSpellbook] = {
	name		="Spellweaving",
	gumpid		=hex2num("0x2B2F"),
	minigumpid	=hex2num("0x2B2D"),
	iconoffset	=hex2num("0x59D8"),
	startindex	=hex2num("0x258"),
	circles	={[1]="First Circle",[2]="Second Circle"},

	pages	={ [1]=1, [2]=1 },

	spells	={
		[1] = { [1] = "Arcane Circle", [2] = "Gift Of Renewal", [3] = "Immolating Weapon", [4] = "Attunement", [5] = "Thunderstorm",[6] = "Nature Fury", [7] = "Summon Fey", [8] = "Summon Fiend" },
		[2] = {	[1] = "Reaper Form", [2] = "Wildfire",[3] = "Essence Of Wind", [4] = "Dryad Allure", [5] = "Ethereal Voyage", [6] = "Word Of Death", [7] = "Gift Of Life",[8] = "Arcane Empowerment" },
		},

	reagenz = { [1]="Mana Cost : 24", [2]="Mana Cost: 32", [3]="Mana Cost: 40", [4]="Mana Cost: 10", [5]="Mana Cost: 34", [6]="Mana Cost: 50",
				[7]="Min. Skill: 0", [8]="Skill Needed: 10", [9]="Skill Needed: 24", [10]="Skill Needed: 66", [11]="Skill Needed: 52", [12]="Skill Needed: 80",
				[13]="Min. Skill: 55", [14]="Min. Skill: 65",[14]="Mana Cost: 70", [15]="Skill Needed: 24" },

	spell_reags = {
		[1] = { [1]={[1]=1,[2]=7 }, [2]={[1]=1,[2]=7 }, [3]={[1]=2,[2]=8 }, [4]={[1]=1,[2]=7 }, [5]={[1]=2,[2]=8 }, [6]={[1]=1,[2]=7}, [7]={[1]=4,[2]=9}, [8]={[1]=4,[2]=15} },
		[2] = {	[1]={[1]=5,[2]=11 }, [2]={[1]=6,[2]=10}, [3]={[1]=3,[2]=11 }, [4]={[1]=3,[2]=12}, [5]={[1]=2,[2]=15}, [6]={[1]=6,[2]=12}, [7]={[1]=14,[2]=9}, [8]={[1]=6,[2]=9} }
	},

	ignore_available_flags = false
}

gSpellBooks[NinjitsuSpellbook]	= {
	name		="Ninjitsu",
	gumpid		=hex2num("0x2B06"),
	minigumpid	=hex2num("0x2B08"),
	iconoffset = hex2num("0x5320"),
	startindex  =hex2num("0x1F4"),
	circles	={[1]="First Circle",[2]="Second Circle"},

	pages	={ [1]=1, [2]=1 },

	spells	={
		[1] = { [1] = "Focus Attack", [2] = "Death Strike", [3] = "Animal Form", [4] = "Ki Attack"},
		[2] = {	[1] = "Suprise Attack", [2] = "Backstab", [3] = "Shadowjump", [4] = "Mirror Image" }
		},

	reagenz = { [1]="Mana Cost: 10", [2]="Mana Cost: 15", [3]="Mana Cost: 20", [4]="Mana Cost: 25", [5]="Mana Cost: 30",
				[6]="Min. Skill: 0", [7]="Min. Skill: 20", [6]="Min. Skill: 30", [9]="Min. Skill: 40", [10]="Min. Skill: 50", 
				[11]="Min. Skill: 60",[12]="Min. Skill: 80", [13]="Min. Skill: 85" },

	spell_reags = {
		[1]	= { [1]={[1]=1,[2]=6}, [2]={[1]=5,[2]=13}, [3]={[1]=1,[2]=6}, [4]={[1]=4,[2]=12}, },
		[2] = {	[1]={[1]=3,[2]=11}, [2]={[1]=5,[2]=9}, [3]={[1]=2,[2]=10}, [4]={[1]=1,[2]=7}, }
	},

	ignore_available_flags = true
}

function GetSpellIDByName(spellname)		return gSpellIDByName[spellname] end
function GetSpellNameByID(spellid)			return gSpellNameByID[spellid] end
function GetSpellCircleByID(spellid)		return gSpellCircleByID[spellid] end
function GetSpellBookIDBySpellID(spellid)	return gSpellBookIDBySpellID[spellid] end
function IsMageSpell(spellid)				return GetSpellBookIDBySpellID(spellid) == MageSpellbook end

gSpellBookNameByID = {}
gSpellBookNameByID[MageSpellbook			] = "Magery"
gSpellBookNameByID[NecroSpellbook			] = "Necromancy"
gSpellBookNameByID[ChivalrySpellbook		] = "Chivalry"
gSpellBookNameByID[BushidoSpellbook			] = "Bushido"
gSpellBookNameByID[NinjitsuSpellbook		] = "Ninjitsu"
gSpellBookNameByID[SpellweavingSpellbook	] = "Spellweaving"


gSpellIDByName = {}

-- mysticism
gSpellIDByName["Healing Stone"	] = 0x02A7 
gSpellIDByName["Enchant"		] = 0x02A9 

gSpellNameByID = {}
gSpellCircleByID = {}
gSpellBookIDBySpellID = {}
for spellbookid,spellbookdata in pairs(gSpellBooks) do
	if (spellbookid ~= MageSpellbook2) then 
		local startindex = spellbookdata.startindex
		local circlesize = table.getn(spellbookdata.spells[1])
		for circle,spelllist in pairs(spellbookdata.spells) do
			for spellindex,myspellname in pairs(spelllist) do
				local spellid					= spellindex + startindex + (circle-1)*circlesize
				gSpellIDByName[myspellname]		= spellid
				gSpellNameByID[spellid]			= myspellname
				gSpellCircleByID[spellid]		= circle
				gSpellBookIDBySpellID[spellid]	= spellbookid
				--~ local regs = spellbookdata.spell_reags[circle][spellindex]
				--~ local regtxt = ""
				--~ for k,v in pairs(regs) do regtxt = regtxt .. tostring(spellbookdata.reagenz[v]) .. "," end
				--~ print("spell",gSpellBookNameByID[spellbookid],spellid,myspellname,regtxt)
			end
		end
	end
end
--~ os.exit(0)


function GetSpell_CastDelayBase (spellid)
	local base = 3 --~ RunUO-2.0-SVN/Scripts/Spells/Base/Spell.cs:642:	//public virtual int CastDelayBase{ get{ return 3; } }
	if (IsMageSpell(spellid)) then -- RunUO-2.0-SVN/Scripts/Spells/Base/MagerySpell.cs:108:	public override TimeSpan CastDelayBase
		local circle = GetSpellCircleByID(spellid)
		base = (3 + circle) * kCastDelaySecondsPerTick
	end

	if (spellid == 606) then return 1.5  end	--~ RunUO-2.0-SVN/Scripts/Spells/Spellweaving/NatureFury.cs:15:			TimeSpan.FromSeconds( 1.5 ); } }
	if (spellid == 601) then return 0.5  end	--~ RunUO-2.0-SVN/Scripts/Spells/Spellweaving/ArcaneCircle.cs:14:		TimeSpan.FromSeconds( 0.5 ); } }
	if (spellid == 602) then return 3.0  end	--~ RunUO-2.0-SVN/Scripts/Spells/Spellweaving/GiftOfRenewal.cs:15:		TimeSpan.FromSeconds( 3.0 ); } }
	if (spellid == 607) then return 1.5  end	--~ RunUO-2.0-SVN/Scripts/Spells/Spellweaving/SummonFey.cs:13:			TimeSpan.FromSeconds( 1.5 ); } }
	if (spellid == 615) then return 4.0  end	--~ RunUO-2.0-SVN/Scripts/Spells/Spellweaving/GiftOfLife.cs:17:			TimeSpan.FromSeconds( 4.0 ); } }
	if (spellid == 614) then return 3.5  end	--~ RunUO-2.0-SVN/Scripts/Spells/Spellweaving/WordOfDeath.cs:14:		TimeSpan.FromSeconds( 3.5 ); } }
	if (spellid == 604) then return 1.0  end	--~ RunUO-2.0-SVN/Scripts/Spells/Spellweaving/AttuneWeapon.cs:14:		TimeSpan.FromSeconds( 1.0 ); } }  -- attunement ?
	if (spellid == 613) then return 3.5  end	--~ RunUO-2.0-SVN/Scripts/Spells/Spellweaving/EtherealVoyage.cs:12:		TimeSpan.FromSeconds( 3.5 ); } }
	if (spellid == 611) then return 3.0  end	--~ RunUO-2.0-SVN/Scripts/Spells/Spellweaving/EssenceOfWind.cs:14:		TimeSpan.FromSeconds( 3.0 ); } }
	if (spellid == 605) then return 1.5  end	--~ RunUO-2.0-SVN/Scripts/Spells/Spellweaving/Thunderstorm.cs:14:		TimeSpan.FromSeconds( 1.5 ); } }
	if (spellid == 608) then return 2.0  end	--~ RunUO-2.0-SVN/Scripts/Spells/Spellweaving/SummonFiend.cs:13:		TimeSpan.FromSeconds( 2.0 ); } }
	if (spellid == 609) then return 2.5  end	--~ RunUO-2.0-SVN/Scripts/Spells/Spellweaving/ReaperForm.cs:13:			TimeSpan.FromSeconds( 2.5 ); } }
	
	if (spellid == 507) then return 1.0  end	--~ RunUO-2.0-SVN/Scripts/Spells/Ninjitsu/ShadowJump.cs:18:				TimeSpan.FromSeconds( 1.0 ); } }
	if (spellid == 508) then return 1.5  end	--~ RunUO-2.0-SVN/Scripts/Spells/Ninjitsu/MirrorImage.cs:52:			TimeSpan.FromSeconds( 1.5 ); } }
	if (spellid == 503) then return 1.0  end	--~ RunUO-2.0-SVN/Scripts/Spells/Ninjitsu/AnimalForm.cs:34:				TimeSpan.FromSeconds( 1.0 ); } }
	
	if (spellid == 404) then return 0.25 end	--~ RunUO-2.0-SVN/Scripts/Spells/Bushido/CounterAttack.cs:18:			TimeSpan.FromSeconds( 0.25 ); } }
	if (spellid == 403) then return 0.25 end	--~ RunUO-2.0-SVN/Scripts/Spells/Bushido/Evasion.cs:18:					TimeSpan.FromSeconds( 0.25 ); } }
	if (spellid == 402) then return 0.25 end	--~ RunUO-2.0-SVN/Scripts/Spells/Bushido/Confidence.cs:17:				TimeSpan.FromSeconds( 0.25 ); } }

	if (spellid == 206) then return 0.5  end	--~ RunUO-2.0-SVN/Scripts/Spells/Chivalry/EnemyOfOne.cs:19:				TimeSpan.FromSeconds( 0.5 ); } }
	if (spellid == 208) then return 1.5  end	--~ RunUO-2.0-SVN/Scripts/Spells/Chivalry/NobleSacrifice.cs:23:			TimeSpan.FromSeconds( 1.5 ); } }
	if (spellid == 202) then return 1.5  end	--~ RunUO-2.0-SVN/Scripts/Spells/Chivalry/CloseWounds.cs:18:			TimeSpan.FromSeconds( 1.5 ); } }
	if (spellid == 204) then return 0.25 end	--~ RunUO-2.0-SVN/Scripts/Spells/Chivalry/DispelEvil.cs:19:				TimeSpan.FromSeconds( 0.25 ); } }
	if (spellid == 203) then return 0.5  end	--~ RunUO-2.0-SVN/Scripts/Spells/Chivalry/ConsecrateWeapon.cs:17:		TimeSpan.FromSeconds( 0.5 ); } }
	if (spellid == 207) then return 1.75 end	--~ RunUO-2.0-SVN/Scripts/Spells/Chivalry/HolyLight.cs:17:				TimeSpan.FromSeconds( 1.75 ); } }
	if (spellid == 201) then return 1.0  end	--~ RunUO-2.0-SVN/Scripts/Spells/Chivalry/CleanseByFire.cs:17:			TimeSpan.FromSeconds( 1.0 ); } }
	if (spellid == 209) then return 1.5  end	--~ RunUO-2.0-SVN/Scripts/Spells/Chivalry/RemoveCurse.cs:19:			TimeSpan.FromSeconds( 1.5 ); } }
	if (spellid == 210) then return 1.5  end	--~ RunUO-2.0-SVN/Scripts/Spells/Chivalry/SacredJourney.cs:19:			TimeSpan.FromSeconds( 1.5 ); } }
	if (spellid == 205) then return 1.0  end	--~ RunUO-2.0-SVN/Scripts/Spells/Chivalry/DivineFury.cs:17:				TimeSpan.FromSeconds( 1.0 ); } }
	
	if (spellid == 117) then return 2.0  end	--~ RunUO-2.0-SVN/Scripts/Spells/Necromancy/Exorcism.cs:23:				TimeSpan.FromSeconds( 2.0 ); } }
	if (spellid == 102) then return 1.5  end	--~ RunUO-2.0-SVN/Scripts/Spells/Necromancy/BloodOathSpell.cs:18:		TimeSpan.FromSeconds( 1.5 ); } }
	if (spellid == 115) then return 1.25 end	--~ RunUO-2.0-SVN/Scripts/Spells/Necromancy/Wither.cs:20:				TimeSpan.FromSeconds( 1.25 ); } }
	if (spellid == 104) then return 0.75 end	--~ RunUO-2.0-SVN/Scripts/Spells/Necromancy/CurseWeapon.cs:18:			TimeSpan.FromSeconds( 0.75 ); } }
	if (spellid == 106) then return 2.0  end	--~ RunUO-2.0-SVN/Scripts/Spells/Necromancy/HorrificBeast.cs:19:		TimeSpan.FromSeconds( 2.0 ); } }
	if (spellid == 109) then return 1.0  end	--~ RunUO-2.0-SVN/Scripts/Spells/Necromancy/PainSpike.cs:19:			TimeSpan.FromSeconds( 1.0 ); } }
	if (spellid == 114) then return 2.0  end	--~ RunUO-2.0-SVN/Scripts/Spells/Necromancy/VengefulSpirit.cs:21:		TimeSpan.FromSeconds( 2.0 ); } }
	if (spellid == 113) then return 2.0  end	--~ RunUO-2.0-SVN/Scripts/Spells/Necromancy/VampiricEmbrace.cs:20:		TimeSpan.FromSeconds( 2.0 ); } }
	if (spellid == 101) then return 1.5  end	--~ RunUO-2.0-SVN/Scripts/Spells/Necromancy/AnimateDeadSpell.cs:22:		TimeSpan.FromSeconds( 1.5 ); } }
	
	if (spellid == 105) then return 0.75 end	--~ RunUO-2.0-SVN/Scripts/Spells/Necromancy/EvilOmen.cs:20:				TimeSpan.FromSeconds( 0.75 ); } }
	if (spellid == 103) then return 1.5  end	--~ RunUO-2.0-SVN/Scripts/Spells/Necromancy/CorpseSkin.cs:19:			TimeSpan.FromSeconds( 1.5 ); } }
	if (spellid == 111) then return 2.0  end	--~ RunUO-2.0-SVN/Scripts/Spells/Necromancy/Strangle.cs:19:				TimeSpan.FromSeconds( 2.0 ); } }
	if (spellid == 112) then return 2.0  end	--~ RunUO-2.0-SVN/Scripts/Spells/Necromancy/SummonFamiliar.cs:22:		TimeSpan.FromSeconds( 2.0 ); } }
	if (spellid == 116) then return 2.0  end	--~ RunUO-2.0-SVN/Scripts/Spells/Necromancy/WraithForm.cs:19:			TimeSpan.FromSeconds( 2.0 ); } }
	if (spellid == 107) then return 2.0  end	--~ RunUO-2.0-SVN/Scripts/Spells/Necromancy/LichForm.cs:20:				TimeSpan.FromSeconds( 2.0 ); } }
	if (spellid == 110) then return 1.75 end	--~ RunUO-2.0-SVN/Scripts/Spells/Necromancy/PoisonStrike.cs:18:			TimeSpan.FromSeconds( (Core.ML ? 1.75 : 1.5) ); } }
	if (spellid == 108) then return 1.5  end	--~ RunUO-2.0-SVN/Scripts/Spells/Necromancy/MindRot.cs:20:				TimeSpan.FromSeconds( 1.5 ); } }

	
	if (spellid == 25) then return base-0.25 end	--~ RunUO-2.0-SVN/Scripts/Spells/Fourth/ArchCure.cs:32:					return base.CastDelayBase - TimeSpan.FromSeconds( 0.25 ); } }
												--~ RunUO-2.0-SVN/Scripts/Skills/SpiritSpeak.cs:88:						return TimeSpan.FromSeconds( 1.0 ); } }
	return base 								
end
 
function GetSpell_CastDelayMinimum (spellid)
	return 0.25 -- RunUO-2.0-SVN/Scripts/Spells/Base/Spell.cs:640:	public virtual TimeSpan CastDelayMinimum { get { return TimeSpan.FromSeconds( 0.25 ); } }
end

function GetSpell_CastDelayFastScalar (spellid)
	local spellbookid = GetSpellBookIDBySpellID(spellid)
	if (spellbookid == NinjitsuSpellbook	) then return 0 end		--~ RunUO-2.0-SVN/Scripts/Spells/Ninjitsu/NinjaSpell.cs:24:			public override double CastDelayFastScalar { get { return 0; } }
	if (spellbookid == BushidoSpellbook		) then return 0 end		--~ RunUO-2.0-SVN/Scripts/Spells/Bushido/SamuraiSpell.cs:22:		public override double CastDelayFastScalar{ get{ return 0; } }
	if (spellbookid == NecroSpellbook		) then return 0 end		--~ RunUO-2.0-SVN/Scripts/Spells/Necromancy/NecromancerSpell.cs:18:	public override double CastDelayFastScalar{ get{ return (Core.SE? base.CastDelayFastScalar : 0); } } // Necromancer spells are not affected by fast cast items, though they are by fast cast recovery
	--~ RunUO-2.0-SVN/Scripts/Skills/SpiritSpeak.cs:87:					public override double CastDelayFastScalar { get { return 0; } }
	--~ RunUO-2.0-SVN/Scripts/Mobiles/Animals/Mounts/Ethereals.cs:366:	public override double CastDelayFastScalar { get { return 0; } }
	--~ MageSpellbook
	--~ ChivalrySpellbook		
	--~ SpellweavingSpellbook	
	return 1 -- default 1
end

-- returns time in milliseconds, you should  add about 150 msec latency
-- bProtectionBuffActive : see IsBuffActive_Protection() IsBuffActive_EssenceOfWind()
-- see also RunUO-2.0-SVN/Scripts/Spells/Base/Spell.cs:647:	public virtual TimeSpan GetCastDelay()
function GetSpellCastTime (spellid,fc,bBuffActive_Protection,bBuffActive_EssenceOfWind)
	local spellbookid = GetSpellBookIDBySpellID(spellid)
	if (spellbookid == NinjitsuSpellbook) then return 0 end
	if (spellbookid == BushidoSpellbook) then return 0 end
	--~ TODO : fcmax = 2 ,   (castskill=chiv&&magery<70):fcmax=4
	--~ TODO : if( EssenceOfWindSpell.IsDebuffed( m_Caster ) ) fc -= EssenceOfWindSpell.GetFCMalus( m_Caster );
	fc = min(fc or 0,2)
	if (bBuffActive_Protection) then fc = fc - 2 end
	local castDelayBase			= GetSpell_CastDelayBase(spellid)
	local castDelayFastScalar	= GetSpell_CastDelayFastScalar(spellid)
	local castDelayMinimum		= GetSpell_CastDelayMinimum(spellid)
	local castDelay				= 1000 * max(castDelayBase - (castDelayFastScalar * fc * kCastDelaySecondsPerTick),castDelayMinimum)
	--~ print("GetSpellCastTime",spellid,fc,bBuffActive_Protection,castDelayBase,castDelayFastScalar,castDelayMinimum)
	if (spellid == 33) then return castDelay*3 end -- RunUO-2.0-SVN/Scripts/Spells/Fifth/BladeSpirits.cs:29:	return TimeSpan.FromTicks( base.GetCastDelay().Ticks * ((Core.SE) ? 3 : 5) );
	if (spellid == 40) then return castDelay*5 end -- RunUO-2.0-SVN/Scripts/Spells/Fifth/SummonCreature.cs:86:	return TimeSpan.FromTicks( base.GetCastDelay().Ticks * 5 );
	return castDelay
end

gMagerySpellMana = { 4, 6, 9, 11, 14, 20, 40, 50 }

-- uses GetEquipProps() for player
-- you should add kSpellTimeLatency for network
function GetSpellCastTimeForPlayer (spellid)
	local equipprop = GetEquipProps()
	return GetSpellCastTime(spellid,equipprop.fc,IsBuffActive_Protection(),IsBuffActive_EssenceOfWind())
end

gSpellInterruptMessages = {}
gSpellInterruptMessages[500946 ] = true -- You cannot cast this in town!							
gSpellInterruptMessages[502632 ] = true -- The spell fizzles.										
gSpellInterruptMessages[500641 ] = true -- Your concentration is disturbed, thus ruining thy spell.	
gSpellInterruptMessages[502625 ] = true -- Insufficient mana for this spell.						
gSpellInterruptMessages[1049645] = true -- You have too many followers to summon that creature.  	   
gSpellInterruptMessages[500015 ] = true -- You do not have that spell!
gSpellInterruptMessages[502630 ] = true -- More reagents are needed for this spell.
gSpellInterruptMessages[502644 ] = true -- You have not yet recovered from casting a spell.
gSpellInterruptMessages[1061091] = true -- You cannot cast that spell in this form.    

RegisterListener("Hook_Packet_Localized_Text",function (serial,plaintext,text_messagenum) 
	if (gSpellInterruptMessages[text_messagenum]) then gSmartLastSpellID = nil NotifyListener("Hook_Spell_Interrupt",serial,plaintext,text_messagenum) end
end)


--[[
		public virtual TimeSpan GetCastDelay()
		{
			TimeSpan baseDelay = CastDelayBase;
			TimeSpan fcDelay = TimeSpan.FromSeconds( -(CastDelayFastScalar * fc * CastDelaySecondsPerTick) );
			return min(baseDelay + fcDelay,CastDelayMinimum);
		}
		public override TimeSpan CastDelayBase return TimeSpan.FromSeconds( (3 + (int)Circle) * CastDelaySecondsPerTick );
		
		
	"Clumsy", "Uus Jux",			212,9031,Reagent.Bloodmoss,Reagent.Nightshade
	"Create Food", "In Mani Ylem",	224,9011,Reagent.Garlic,Reagent.Ginseng,Reagent.MandrakeRoot
	"Feeblemind", "Rel Wis",		212,9031,Reagent.Ginseng,Reagent.Nightshade
	"Heal", "In Mani",				224,9061,Reagent.Garlic,Reagent.Ginseng,Reagent.SpidersSilk
	"Magic Arrow", "In Por Ylem",	212,9041,Reagent.SulfurousAsh
	"Night Sight", "In Lor",		236,9031,Reagent.SulfurousAsh,Reagent.SpidersSilk
	"Reactive Armor", "Flam Sanct",	236,9011,Reagent.Garlic,Reagent.SpidersSilk,Reagent.SulfurousAsh
	"Weaken", "Des Mani",			212,9031,Reagent.Garlic,Reagent.Nightshade
	
	{"Focus Attack",	10,30,"Increases both your damage and the percentage chance for \"hit\" properties on your weapon for one attack"},
	{"Death Strike",	30,85,"After receiving a Death Strike, if the opponent moves more than five steps or five seconds elapses, they will suffer direct damage determined by the attacker's ninjitsu."},
	{"Animal Form",		10,0,"Allows you to transform into an animal, gaining special bonuses..."},
	{"Ki Attack",		25,80,"An attack that does greater damage based on how far you travel to your opponent ..."},
	
	{"Suprise Attack",	20,60,"An attack from stealth that inflicts a defence penalty..."},
	{"Backstab",		30,40,"An attack from stealth with a damage bonus ..."},
	{"Shadowjump",		15,50,"Allows you to teleport while maintaining stealth..."},
	{"Mirror Image",	10,20,"Creates a mirror image..."},
]]--
