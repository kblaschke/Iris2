-- bushido,ninjitsu : no powerwords
-- this info will probably only be used for translating powerwords to spellnames
-- TODO? bHasTarget, harmful/neutral/friendly , tithing/mana/minskill..
kSpellInfoAOS = true

Reagent = {}
Reagent.BlackPearl		= {}
Reagent.Bloodmoss		= {}
Reagent.Garlic			= {}
Reagent.Ginseng			= {}
Reagent.MandrakeRoot	= {}
Reagent.Nightshade		= {}
Reagent.SulfurousAsh	= {}
Reagent.SpidersSilk		= {}

Reagent.BatWing			= {}
Reagent.GraveDust		= {}
Reagent.DaemonBlood		= {}
Reagent.NoxCrystal		= {}
Reagent.PigIron			= {}

gSpellInfo = {}
gSpellInfoByMantra = {}

-- action = character anim ?
function RegisterSpell	(extra,name,mantra,action,effect,...)
	local regs = {...}
	local info = {regs=regs,name=name,mantra=mantra,action=action,effect=effect}
	for k,v in pairs(extra) do info[k] = v end
	info.regs = regs
	table.insert(gSpellInfo,info)
	gSpellInfoByMantra[mantra] = info
end

function GetSpellNameFromMantra (mantra) 
	local info = gSpellInfoByMantra[mantra] 
	return info and info.name
end

function RegisterSpell_Magery			(circle,...)	RegisterSpell({book="Magery",circle=circle},...) end
function RegisterSpell_Necro			(...)			RegisterSpell({book="Necro"},...) end
function RegisterSpell_Chivalry			(...)			RegisterSpell({book="Chiv"},...) end
function RegisterSpell_Spellweaving		(...)			RegisterSpell({book="Spellweaving"},...) end

-- Blade Spirits ... first reg = false -> allowTown
-- public SpellInfo( string name, string mantra, int action, int handEffect, bool allowTown, params Type[] regs )

-- ***** ***** ***** ***** ***** magery : circle 1
RegisterSpell_Magery(1, "Clumsy",	"Uus Jux", 212, 9031, Reagent.Bloodmoss, Reagent.Nightshade)
RegisterSpell_Magery(1, "Create Food", "In Mani Ylem", 224, 9011, Reagent.Garlic, Reagent.Ginseng, Reagent.MandrakeRoot)
RegisterSpell_Magery(1, "Feeblemind", "Rel Wis", 212, 9031, Reagent.Ginseng, Reagent.Nightshade)
RegisterSpell_Magery(1, "Heal", "In Mani", 224, 9061, Reagent.Garlic, Reagent.Ginseng, Reagent.SpidersSilk)
RegisterSpell_Magery(1, "Magic Arrow", "In Por Ylem", 212, 9041, Reagent.SulfurousAsh)
RegisterSpell_Magery(1, "Night Sight", "In Lor", 236, 9031, Reagent.SulfurousAsh, Reagent.SpidersSilk)
RegisterSpell_Magery(1, "Reactive Armor", "Flam Sanct", 236, 9011, Reagent.Garlic, Reagent.SpidersSilk, Reagent.SulfurousAsh)
RegisterSpell_Magery(1, "Weaken", "Des Mani", 212, 9031, Reagent.Garlic, Reagent.Nightshade)
-- ***** ***** ***** ***** ***** magery : circle 2
RegisterSpell_Magery(2, "Agility", "Ex Uus", 212, 9061, Reagent.Bloodmoss, Reagent.MandrakeRoot)
RegisterSpell_Magery(2, "Cunning", "Uus Wis", 212, 9061, Reagent.MandrakeRoot, Reagent.Nightshade)
RegisterSpell_Magery(2, "Cure", "An Nox", 212, 9061, Reagent.Garlic, Reagent.Ginseng)
RegisterSpell_Magery(2, "Harm", "An Mani", 212, kSpellInfoAOS and 9001 or 9041, Reagent.Nightshade, Reagent.SpidersSilk)
RegisterSpell_Magery(2, "Magic Trap", "In Jux", 212, 9001, Reagent.Garlic, Reagent.SpidersSilk, Reagent.SulfurousAsh)
RegisterSpell_Magery(2, "Protection", "Uus Sanct", 236, 9011, Reagent.Garlic, Reagent.Ginseng, Reagent.SulfurousAsh)
RegisterSpell_Magery(2, "Remove Trap", "An Jux", 212, 9001, Reagent.Bloodmoss, Reagent.SulfurousAsh)
RegisterSpell_Magery(2, "Strength", "Uus Mani", 212, 9061, Reagent.MandrakeRoot, Reagent.Nightshade)
-- ***** ***** ***** ***** ***** magery : circle 3
RegisterSpell_Magery(3, "Bless", "Rel Sanct", 203, 9061, Reagent.Garlic, Reagent.MandrakeRoot)
RegisterSpell_Magery(3, "Fireball", "Vas Flam", 203, 9041, Reagent.BlackPearl)
RegisterSpell_Magery(3, "Magic Lock", "An Por", 215, 9001, Reagent.Garlic, Reagent.Bloodmoss, Reagent.SulfurousAsh)
RegisterSpell_Magery(3, "Poison", "In Nox", 203, 9051, Reagent.Nightshade)
RegisterSpell_Magery(3, "Telekinesis", "Ort Por Ylem", 203, 9031, Reagent.Bloodmoss, Reagent.MandrakeRoot)
RegisterSpell_Magery(3, "Teleport", "Rel Por", 215, 9031, Reagent.Bloodmoss, Reagent.MandrakeRoot)
RegisterSpell_Magery(3, "Unlock Spell", "Ex Por", 215, 9001, Reagent.Bloodmoss, Reagent.SulfurousAsh)
RegisterSpell_Magery(3, "Wall of Stone", "In Sanct Ylem", 227, 9011, false, Reagent.Bloodmoss, Reagent.Garlic)
-- ***** ***** ***** ***** ***** magery : circle 4
RegisterSpell_Magery(4, "Arch Cure", "Vas An Nox", 215, 9061, Reagent.Garlic, Reagent.Ginseng, Reagent.MandrakeRoot)
RegisterSpell_Magery(4, "Arch Protection", "Vas Uus Sanct", kSpellInfoAOS and 239 or 215, 9011, Reagent.Garlic, Reagent.Ginseng, Reagent.MandrakeRoot, Reagent.SulfurousAsh)
RegisterSpell_Magery(4, "Curse", "Des Sanct", 227, 9031, Reagent.Nightshade, Reagent.Garlic, Reagent.SulfurousAsh)
RegisterSpell_Magery(4, "Fire Field", "In Flam Grav", 215, 9041, false, Reagent.BlackPearl, Reagent.SpidersSilk, Reagent.SulfurousAsh)
RegisterSpell_Magery(4, "Greater Heal", "In Vas Mani", 204, 9061, Reagent.Garlic, Reagent.Ginseng, Reagent.MandrakeRoot, Reagent.SpidersSilk)
RegisterSpell_Magery(4, "Lightning", "Por Ort Grav", 239, 9021, Reagent.MandrakeRoot, Reagent.SulfurousAsh)
RegisterSpell_Magery(4, "Mana Drain", "Ort Rel", 215, 9031, Reagent.BlackPearl, Reagent.MandrakeRoot, Reagent.SpidersSilk)
RegisterSpell_Magery(4, "Recall", "Kal Ort Por", 239, 9031, Reagent.BlackPearl, Reagent.Bloodmoss, Reagent.MandrakeRoot)
-- ***** ***** ***** ***** ***** magery : circle 5
RegisterSpell_Magery(5, "Blade Spirits", "In Jux Hur Ylem",266, 9040, false, Reagent.BlackPearl, Reagent.MandrakeRoot, Reagent.Nightshade)
RegisterSpell_Magery(5, "Dispel Field", "An Grav", 206, 9002, Reagent.BlackPearl, Reagent.SpidersSilk, Reagent.SulfurousAsh, Reagent.Garlic)
RegisterSpell_Magery(5, "Incognito", "Kal In Ex", 206, 9002, Reagent.Bloodmoss, Reagent.Garlic, Reagent.Nightshade)
RegisterSpell_Magery(5, "Magic Reflection", "In Jux Sanct", 242, 9012, Reagent.Garlic, Reagent.MandrakeRoot, Reagent.SpidersSilk)
RegisterSpell_Magery(5, "Mind Blast", "Por Corp Wis", 218, kSpellInfoAOS and 9002 or 9032, Reagent.BlackPearl, Reagent.MandrakeRoot, Reagent.Nightshade, Reagent.SulfurousAsh)
RegisterSpell_Magery(5, "Paralyze", "An Ex Por", 218, 9012, Reagent.Garlic, Reagent.MandrakeRoot, Reagent.SpidersSilk)
RegisterSpell_Magery(5, "Poison Field", "In Nox Grav", 230, 9052, false, Reagent.BlackPearl, Reagent.Nightshade, Reagent.SpidersSilk)
RegisterSpell_Magery(5, "Summon Creature", "Kal Xen", 266, 9040, Reagent.Bloodmoss, Reagent.MandrakeRoot, Reagent.SpidersSilk)
-- ***** ***** ***** ***** ***** magery : circle 6
RegisterSpell_Magery(6, "Dispel", "An Ort", 218, 9002, Reagent.Garlic, Reagent.MandrakeRoot, Reagent.SulfurousAsh)
RegisterSpell_Magery(6, "Energy Bolt", "Corp Por", 230, 9022, Reagent.BlackPearl, Reagent.Nightshade)
RegisterSpell_Magery(6, "Explosion", "Vas Ort Flam", 230, 9041, Reagent.Bloodmoss, Reagent.MandrakeRoot)
RegisterSpell_Magery(6, "Invisibility", "An Lor Xen", 206, 9002, Reagent.Bloodmoss, Reagent.Nightshade)
RegisterSpell_Magery(6, "Mark", "Kal Por Ylem", 218, 9002, Reagent.BlackPearl, Reagent.Bloodmoss, Reagent.MandrakeRoot)
RegisterSpell_Magery(6, "Mass Curse", "Vas Des Sanct", 218, 9031, false, Reagent.Garlic, Reagent.Nightshade, Reagent.MandrakeRoot, Reagent.SulfurousAsh)
RegisterSpell_Magery(6, "Paralyze Field", "In Ex Grav", 230, 9012, false, Reagent.BlackPearl, Reagent.Ginseng, Reagent.SpidersSilk)
RegisterSpell_Magery(6, "Reveal", "Wis Quas", 206, 9002, Reagent.Bloodmoss, Reagent.SulfurousAsh)
-- ***** ***** ***** ***** ***** magery : circle 7
RegisterSpell_Magery(7, "Chain Lightning", "Vas Ort Grav", 209, 9022, false, Reagent.BlackPearl, Reagent.Bloodmoss, Reagent.MandrakeRoot, Reagent.SulfurousAsh)
RegisterSpell_Magery(7, "Energy Field", "In Sanct Grav", 221, 9022, false, Reagent.BlackPearl, Reagent.MandrakeRoot, Reagent.SpidersSilk, Reagent.SulfurousAsh)
RegisterSpell_Magery(7, "Flame Strike", "Kal Vas Flam", 245, 9042, Reagent.SpidersSilk, Reagent.SulfurousAsh)
RegisterSpell_Magery(7, "Gate Travel", "Vas Rel Por", 263, 9032, Reagent.BlackPearl, Reagent.MandrakeRoot, Reagent.SulfurousAsh)
RegisterSpell_Magery(7, "Mana Vampire", "Ort Sanct", 221, 9032, Reagent.BlackPearl, Reagent.Bloodmoss, Reagent.MandrakeRoot, Reagent.SpidersSilk)
RegisterSpell_Magery(7, "Mass Dispel", "Vas An Ort", 263, 9002, Reagent.Garlic, Reagent.MandrakeRoot, Reagent.BlackPearl, Reagent.SulfurousAsh)
RegisterSpell_Magery(7, "Meteor Swarm", "Flam Kal Des Ylem", 233, 9042, false, Reagent.Bloodmoss, Reagent.MandrakeRoot, Reagent.SulfurousAsh, Reagent.SpidersSilk)
RegisterSpell_Magery(7, "Polymorph", "Vas Ylem Rel", 221, 9002, Reagent.Bloodmoss, Reagent.SpidersSilk, Reagent.MandrakeRoot)
-- ***** ***** ***** ***** ***** magery : circle 8
RegisterSpell_Magery(8, "Air Elemental", "Kal Vas Xen Hur", 269, 9010, false, Reagent.Bloodmoss, Reagent.MandrakeRoot, Reagent.SpidersSilk)
RegisterSpell_Magery(8, "Earth Elemental", "Kal Vas Xen Ylem", 269, 9020, false, Reagent.Bloodmoss, Reagent.MandrakeRoot, Reagent.SpidersSilk)
RegisterSpell_Magery(8, "Earthquake", "In Vas Por", 233, 9012, false, Reagent.Bloodmoss, Reagent.Ginseng, Reagent.MandrakeRoot, Reagent.SulfurousAsh)
RegisterSpell_Magery(8, "Energy Vortex", "Vas Corp Por", 260, 9032, false, Reagent.Bloodmoss, Reagent.BlackPearl, Reagent.MandrakeRoot, Reagent.Nightshade)
RegisterSpell_Magery(8, "Fire Elemental", "Kal Vas Xen Flam", 269, 9050, false, Reagent.Bloodmoss, Reagent.MandrakeRoot, Reagent.SpidersSilk, Reagent.SulfurousAsh)
RegisterSpell_Magery(8, "Resurrection", "An Corp", 245, 9062, Reagent.Bloodmoss, Reagent.Garlic, Reagent.Ginseng)
RegisterSpell_Magery(8, "Summon Daemon", "Kal Vas Xen Corp", 269, 9050, false, Reagent.Bloodmoss, Reagent.MandrakeRoot, Reagent.SpidersSilk, Reagent.SulfurousAsh)
RegisterSpell_Magery(8, "Water Elemental", "Kal Vas Xen An Flam", 269, 9070, false, Reagent.Bloodmoss, Reagent.MandrakeRoot, Reagent.SpidersSilk)
-- ***** ***** ***** ***** ***** necromancy
RegisterSpell_Necro( "Animate Dead", "Uus Corp", 203, 9031, Reagent.GraveDust, Reagent.DaemonBlood)
RegisterSpell_Necro( "Blood Oath", "In Jux Mani Xen", 203, 9031, Reagent.DaemonBlood)
RegisterSpell_Necro( "Corpse Skin", "In Agle Corp Ylem", 203, 9051, Reagent.BatWing, Reagent.GraveDust)
RegisterSpell_Necro( "Curse Weapon", "An Sanct Gra Char", 203, 9031, Reagent.PigIron)
RegisterSpell_Necro( "Evil Omen", "Pas Tym An Sanct", 203, 9031, Reagent.BatWing, Reagent.NoxCrystal)
RegisterSpell_Necro( "Exorcism", "Ort Corp Grav", 203, 9031, Reagent.NoxCrystal, Reagent.GraveDust)
RegisterSpell_Necro( "Horrific Beast", "Rel Xen Vas Bal", 203, 9031, Reagent.BatWing, Reagent.DaemonBlood)
RegisterSpell_Necro( "Lich Form", "Rel Xen Corp Ort", 203, 9031, Reagent.GraveDust, Reagent.DaemonBlood, Reagent.NoxCrystal)
RegisterSpell_Necro( "Mind Rot", "Wis An Ben", 203, 9031, Reagent.BatWing, Reagent.PigIron, Reagent.DaemonBlood)
RegisterSpell_Necro( "Pain Spike", "In Sar", 203, 9031, Reagent.GraveDust, Reagent.PigIron)
RegisterSpell_Necro( "Poison Strike", "In Vas Nox", 203, 9031, Reagent.NoxCrystal)
RegisterSpell_Necro( "Strangle", "In Bal Nox", 209, 9031, Reagent.DaemonBlood, Reagent.NoxCrystal)
RegisterSpell_Necro( "Summon Familiar", "Kal Xen Bal", 203, 9031, Reagent.BatWing, Reagent.GraveDust, Reagent.DaemonBlood)
RegisterSpell_Necro( "Vampiric Embrace", "Rel Xen An Sanct", 203, 9031, Reagent.BatWing, Reagent.NoxCrystal, Reagent.PigIron)
RegisterSpell_Necro( "Vengeful Spirit", "Kal Xen Bal Beh", 203, 9031, Reagent.BatWing, Reagent.GraveDust, Reagent.PigIron)
RegisterSpell_Necro( "Wither", "Kal Vas An Flam", 203, 9031, Reagent.NoxCrystal, Reagent.GraveDust, Reagent.PigIron)
RegisterSpell_Necro( "Wraith Form", "Rel Xen Um", 203, 9031, Reagent.NoxCrystal, Reagent.PigIron)
-- ***** ***** ***** ***** ***** chivalry
RegisterSpell_Chivalry( "Cleanse By Fire", "Expor Flamus", -1, 9002)
RegisterSpell_Chivalry( "Close Wounds", "Obsu Vulni", -1, 9002)
RegisterSpell_Chivalry( "Consecrate Weapon", "Consecrus Arma", -1, 9002)
RegisterSpell_Chivalry( "Dispel Evil", "Dispiro Malas", -1, 9002)
RegisterSpell_Chivalry( "Divine Fury", "Divinum Furis", -1, 9002)
RegisterSpell_Chivalry( "Enemy of One", "Forul Solum", -1, 9002)
RegisterSpell_Chivalry( "Holy Light", "Augus Luminos", -1, 9002)
RegisterSpell_Chivalry( "Noble Sacrifice", "Dium Prostra", -1, 9002)
RegisterSpell_Chivalry( "Remove Curse", "Extermo Vomica", -1, 9002)
RegisterSpell_Chivalry( "Sacred Journey", "Sanctum Viatas", -1, 9002)
-- ***** ***** ***** ***** ***** spellweaving
RegisterSpell_Spellweaving( "Arcane Circle", "Myrshalee", -1)
RegisterSpell_Spellweaving( "Gift of Renewal", "Olorisstra", -1)
RegisterSpell_Spellweaving( "Immolating Weapon", "Thalshara", -1) -- vm, not in runuo?
RegisterSpell_Spellweaving( "Attune Weapon", "Haeldril", -1)  -- attunement ?
RegisterSpell_Spellweaving( "Thunderstorm", "Erelonia", -1)
RegisterSpell_Spellweaving( "Nature's Fury", "Rauvvrae", -1, false) -- not in town
RegisterSpell_Spellweaving( "Summon Fey", "Alalithra", -1)
RegisterSpell_Spellweaving( "Summon Fiend", "Nylisstra", -1)
RegisterSpell_Spellweaving( "Reaper Form", "Tarisstree", -1)
RegisterSpell_Spellweaving( "Wildfire", "Haelyn", -1) -- vm, not in runuo?
RegisterSpell_Spellweaving( "Essence of Wind", "Anathrae", -1)
RegisterSpell_Spellweaving( "Dryad Allure", "Rathril", -1) -- vm, not in runuo?
RegisterSpell_Spellweaving( "Ethereal Voyage", "Orlavdra", -1)
RegisterSpell_Spellweaving( "Word of Death", "Nyraxle", -1)
RegisterSpell_Spellweaving( "Gift of Life", "Illorae", -1)
RegisterSpell_Spellweaving( "Arcane Empowerment", "Aslavdra", -1) -- vm, not in runuo?

--[[
TODO:mysticism: (see http://www.uoguide.com/Mysticism)
nether bolt : in corp ylem  4 mana, 0skill, black perl, sulf ash
healing stone: kal in mani  4 mana, 0skill, bone,garlic,ginseng,spidersilk
purge magic: an ort sanct	6 mana, 8skill, fertiledirt,garlic,mandrake,sulfurash
enchant: in ort ylem		6 mana, 8skill, spidersilk,mandrake,sulfurash
sleep: in zu				9 mana,20skill,	nightshade,spidersilk,blackperl
eagle strike:kal por xen	9 mana,20skill, bloodmoss,bone,spidersilk,mandrake
...

]]--

