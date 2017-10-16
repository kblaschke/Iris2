--[[ ***** see Iris2 COPYING for license info ***** ]]--
--[[ \brief
        pre game mode for testing various stuff, accessible via mainmenu
        can be used to view granny models without connecting to a server
        use "iris2 -sd" to start directly to this menu
]]--

kDebugMode_Granny = 0
kDebugMode_Static = 1
kDebugMode_Online = 2
kDebugMode_Particle = 2

gDebugModeTestSkeletalAnimShader = false

gCurDebugMode = kDebugMode_Granny
gDebugMenuRunning = false
--gDebugMenuEnableAnim = false
--gDebugMenuEnableAnim = true
gDebugMenuAnimIndex = -1 -- (-1) shows rest pos
gDebugMenuAnimIndex = 0
gDebugMenuModelIndex = 1    -- start with first model in gDebugMenuModelTable
gDebugMenuModelName = ""

gDebugMenuMainGfxPos = {-0.5,0.5,-0.15}

function RepairEquipIndex (arr) 
    for k,v in pairs(arr) do 
        local layer = v.layer or GetPaperdollLayerFromTileType(v.artid)
        if (not layer) then print("could't get layer for artid ",v.artid) end
        v.layer = layer or (1000 + k)
    end
end

--creatures
--used regular expression to make these "^(\d+)(.*?\s){8}(.*?)[\s]{0,}$" and replace with "{artid=$1 , content={}}, \t--$3" in PSpad
--removed duplicates by hand
--commented ones crashes (no shaders used)
gDebugMenuModelTable = {
    --~ {artid=257 , content={}}, -- dreadhorn (crash, modelinfo=nil)
    {artid=0x3b , content={}}, -- dragon
    {artid=0x3c , content={}}, -- drake
    {artid=0x114 , content={}}, -- chimera
    {artid=9 , content={}}, -- demon
    {artid=0x023e , content={}}, -- bladespirit , effect/animation not used (granny format)
    {artid=0x25d , content={}}, -- another human male           -- maybe samurai/elven scale ??
    {artid=0x25e , content={}}, -- another human female         -- maybe samurai/elven scale ??
    {artid=0x25f , content={}}, -- another human male           -- maybe samurai/elven scale ??
    {artid=0x260 , content={}}, -- another human male-taller    -- maybe samurai/elven scale ??
    {artid=0x2e8 , content={}}, -- another human male           -- maybe samurai/elven scale ??
    {artid=0x2e9 , content={}}, -- another human female         -- maybe samurai/elven scale ??
    {artid=0x2ee , content={}}, -- another human                -- maybe samurai/elven scale ??
    {artid=0x2ef , content={}}, -- another human                -- maybe samurai/elven scale ??
    {artid=0x3ca , content={}}, -- another human                -- maybe samurai/elven scale ??
    {artid=0x3db , content={}}, -- another human                -- maybe samurai/elven scale ??
    {artid=0x3df , content={}}, -- another human                -- maybe samurai/elven scale ??
    {artid=0x3e2 , content={}}, -- another human                -- maybe samurai/elven scale ??
    {artid=0x194 , content={}}, -- 0x194 and following : equipment and clothing
    {artid=0x57c , content={}}, -- 0x57c and following : equipment and clothing
    {artid=0x314 , content={}}, -- bad scale (too large)
    {artid=0x315 , content={}}, -- bad scale (too large)
    {artid=0x11c , content={}}, -- broken anim
    {artid=0x138 , content={}}, -- broken anim
    {artid=0x13a , content={}}, -- broken anim
    {artid=0x13b , content={}}, -- broken anim
    {artid=0x13c , content={}}, -- broken anim
    {artid=0x13f , content={}}, -- broken anim
    {artid=0x2ea , content={}}, -- broken anim
    {artid=0x2f0 , content={}}, -- broken anim
    {artid=0x307 , content={}}, -- broken anim
    {artid=0x309 , content={}}, -- broken anim
    {artid=0x311 , content={}}, -- broken anim
    {artid=0x317 , content={}}, -- broken anim
    {artid=0x31a , content={}}, -- broken anim
    {artid=0x31d , content={}}, -- broken anim
    {artid=0x31e , content={}}, -- broken anim
    {artid=0x31f , content={}}, -- broken anim
    {artid=170 , hue=16385, content={}}, -- eth llama original vm hue  16043   170     16385

    {artid=0xdad , content={}}, -- cloak anim frame a
    {artid=0xdac , content={}}, -- cloak anim frame b
    
    --female
    {artid=401, content={}},
    {artid=401, content=({{artid=5899,animid=477},{artid=5422,animid=430},{artid=5399,animid=434},{artid=5435,animid=466},{artid=8251,animid=700},{artid=3701,animid=422},})},
    -- male
    {artid=400, content={}},
    {artid=400, content=({{artid=5905,animid=476},{artid=5422,animid=430},{artid=7933,animid=435},{artid=5909,animid=406},{artid=5441,animid=490},{artid=3701,animid=422},{artid=8251,animid=700},})},

    
    {artid=153 , content={}},   --walking_dead_ghoul
    {artid=154 , content={}},   --walking_dead_mummy
    {artid=155 , content={}},   --walking_dead_rotting_corpse
    {artid=187 , content={}},   --ridgeback_ridgeback
    {artid=193 , content={}},   --ridgeback_ridgeback_ethereal
    {artid=188 , content={}},   --ridgeback_savage
    {artid=787 , content={}},   --ant_lion
    {artid=157 , content={}},   --arachnids_spider_black_widow
    {artid=173 , content={}},   --arachnids_spider_black_widow
    {artid=11 , content={}},    --arachnids_spider_dread
    {artid=19 , content={}},    --arachnids_spider_dread
    {artid=20 , content={}},    --arachnids_spider_frost
    {artid=28 , content={}},    --arachnids_spider_giant
    {artid=779 , content={}},   --bogling
    {artid=780 , content={}},   --bog_thing
    {artid=232 , content={}},   --bovines_bull_brown
    {artid=233 , content={}},   --bovines_bull_spotted
    {artid=216 , content={}},   --bovines_cow_brown
    {artid=231 , content={}},   --bovines_cow_spotted
    {artid=211 , content={}},   --bruins_bear_black
    {artid=167 , content={}},   --bruins_bear_brown
    {artid=212 , content={}},   --bruins_bear_grizzly
    {artid=213 , content={}},   --bruins_bear_polar
    {artid=217 , content={}},   --canines_dog_hound
    {artid=97 , content={}},    --canines_hell_hound
    {artid=98 , content={}},    --canines_hell_hound
    {artid=225 , content={}},   --canines_wolf_timber
    {artid=99 , content={}},    --canines_wolf_dark
    {artid=23 , content={}},    --canines_wolf_dire
    {artid=25 , content={}},    --canines_wolf_grey
    {artid=27 , content={}},    --canines_wolf_grey
    {artid=100 , content={}},   --canines_wolf_silver
    {artid=34 , content={}},    --canines_wolf_white
    {artid=37 , content={}},    --canines_wolf_white
    {artid=101 , content={}},   --centaurs_centaur
    {artid=792 , content={}},   --chaos_demon
    {artid=786 , content={}},   --chariot
    {artid=756 , content={}},   --clockwork_overseer
    {artid=757 , content={}},   --clockwork_minion
    {artid=763 , content={}},   --clockwork_minion
    {artid=75 , content={}},    --cyclops_cyclops
    {artid=9 , content={}},     --daemons_daemon
    {artid=10 , content={}},    --daemons_daemon
    {artid=38 , content={}},    --daemons_daemon_black_gate
    {artid=40 , content={}},    --daemons_daemon_elder
    {artid=102 , content={}},   --daemons_daemon_exodus
    {artid=43 , content={}},    --daemons_daemon_ice_fiend
--  {artid=774 , content={}},   --Dawn_Girl
    {artid=237 , content={}},   --deer_doe
    {artid=234 , content={}},   --deer_stag
    {artid=151 , content={}},   --dolphins_dolphin
    {artid=103 , content={}},   --dragons_dragon_asian
    {artid=12 , content={}},    --dragons_dragon_retro_grey
    {artid=172 , content={}},   --dragons_dragon_retro_red
    {artid=59 , content={}},    --dragons_dragon_retro_red
    {artid=49 , content={}},    --dragons_wyrm_retro_white
    {artid=180 , content={}},   --dragons_wyrm_retro_white
    {artid=60 , content={}},    --dragons_dragon_retro_grey
    {artid=61 , content={}},    --dragons_dragon_retro_red
--#This is here so the skeletal and ethereal can map animations to it
    {artid=105 , content={}},   --dragons_wyrm_ancient

    {artid=46 , content={}},    --Mf_Dragon_Rust
    {artid=106 , content={}},   --dragons_wyrm_shadow
    {artid=104 , content={}},   --dragons_dragon_skeletal
    {artid=62 , content={}},    --dragons_wyvern
    {artid=14 , content={}},    --elementals_earth_elemental
    {artid=107 , content={}},   --elementals_agapite_elemental
    {artid=108 , content={}},   --elementals_bronze_elemental
    {artid=109 , content={}},   --elementals_copper_elemental
    {artid=110 , content={}},   --elementals_copper_dull_elemental
    {artid=166 , content={}},   --elementals_gold_elemental
    {artid=111 , content={}},   --elementals_iron_elemental
    {artid=112 , content={}},   --elementals_valorite_elemental
    {artid=113 , content={}},   --elementals_verite_elemental
    {artid=158 , content={}},   --elementals_acid_elemental
    {artid=13 , content={}},    --elementals_air_elemental
    {artid=159 , content={}},   --elementals_blood_elemental
    {artid=160 , content={}},   --elementals_blood_elemental
    {artid=15 , content={}},    --elementals_fire_elemental
    {artid=161 , content={}},   --elementals_ice_elemental
    {artid=162 , content={}},   --elementals_poison_elemental
    {artid=163 , content={}},   --elementals_snow_elemental
    {artid=16 , content={}},    --elementals_water_elemental
    {artid=164 , content={}},   --ethereals_energy_vortex
    {artid=165 , content={}},   --ethereals_wisp
    {artid=58 , content={}},    --ethereals_wisp
    {artid=200 , content={}},   --equines_horse_dappled_brown
    {artid=190 , content={}},   --equines_horse_firesteed
    {artid=820 , content={}},   --equines_horse_dappled_brown
    {artid=291 , content={}},   --equines_horse_dappled_brown_pack
    {artid=226 , content={}},   --equines_horse_dappled_grey
    {artid=846 , content={}},   --equines_horse_dappled_grey
    {artid=204 , content={}},   --equines_horse_dark_brown
    {artid=824 , content={}},   --equines_horse_dark_brown
    {artid=228 , content={}},   --equines_horse_tan
    {artid=848 , content={}},   --equines_horse_tan
    {artid=114 , content={}},   --equines_horse_dark_steed
    {artid=115 , content={}},   --equines_horse_ethereal
    {artid=116 , content={}},   --equines_horse_nightmare
    {artid=177 , content={}},   --equines_horse_nightmare
    {artid=178 , content={}},   --equines_horse_nightmare
    {artid=179 , content={}},   --equines_horse_nightmare
    {artid=117 , content={}},   --equines_horse_silver_steed
    {artid=118 , content={}},   --equines_horse_war_brittanian
    {artid=119 , content={}},   --equines_horse_war_mage_council
    {artid=120 , content={}},   --equines_horse_war_minax
    {artid=121 , content={}},   --equines_horse_war_shadowlord
    {artid=122 , content={}},   --equines_unicorn
    {artid=192 , content={}},   --equines_unicorn_ethereal
    {artid=123 , content={}},   --ethereal_warriors_male
    {artid=175 , content={}},   --ethereal_warriors_male
    {artid=2 , content={}},     --ettins_ettin
    {artid=18 , content={}},    --ettins_ettin
    {artid=63 , content={}},    --felines_cougar
    {artid=64 , content={}},    --felines_leopard_snow
    {artid=65 , content={}},    --felines_leopard_snow
    {artid=214 , content={}},   --felines_panther
    {artid=127 , content={}},   --felines_predator_hellcat
    {artid=128 , content={}},   --fey_race_pixie
    {artid=176 , content={}},   --fey_race_pixie
    {artid=781 , content={}},   --fire_ant_worker
    {artid=782 , content={}},   --fire_ant_warrior
    {artid=783 , content={}},   --fire_ant_queen
    {artid=804 , content={}},   --fire_ant_matriarch
    {artid=805 , content={}},   --black_ant_worker
    {artid=806 , content={}},   --black_ant_warrior
    {artid=807 , content={}},   --black_ant_queen
    {artid=808 , content={}},   --black_ant_matriarch
    {artid=8 , content={}},     --flails_corpser
    {artid=47 , content={}},    --flails_reaper
    {artid=66 , content={}},    --flails_swamp_tentacles
    {artid=129 , content={}},   --flails_swamp_tentacles
    {artid=80 , content={}},    --frogs_frog_giant
    {artid=4 , content={}},     --gargoyles_gargoyle
    {artid=130 , content={}},   --gargoyles_gargoyle_blistering
    {artid=67 , content={}},    --gargoyles_gargoyle_stone
    {artid=753 , content={}},   --gargoyles_gargoyle_slave
    {artid=754 , content={}},   --gargoyles_gargoyle_enforcer
    {artid=755 , content={}},   --gargoyles_gargoyle_guard
    {artid=758 , content={}},   --gargoyles_gargoyle_shopkeeper
    {artid=22 , content={}},    --gazers_gazer
    {artid=68 , content={}},    --gazers_gazer_elder
    {artid=69 , content={}},    --gazers_gazer_elder
    {artid=131 , content={}},   --genies_efreet
    {artid=791 , content={}},   --giant_beetle
    {artid=195 , content={}},   --giant_beetle_ethereal
    {artid=752 , content={}},   --golem_iron
    {artid=29 , content={}},    --gorillas_silverback
    {artid=30 , content={}},    --harpies_harpy
    {artid=73 , content={}},    --harpies_harpy_stone
    {artid=31 , content={}},    --headless_headless
    {artid=776 , content={}},   --horde_demon
    {artid=795 , content={}},   --horde_demon
    {artid=796 , content={}},   --horde_demon
    {artid=74 , content={}},    --imps_imp
    {artid=168 , content={}},   --imps_shadow_fiend
    {artid=764 , content={}},   --Juka_Warrior
    {artid=765 , content={}},   --Juka_Mage
    {artid=768 , content={}},   --Juggernaut
    {artid=132 , content={}},   --kirin_kirin
    {artid=191 , content={}},   --kirin_kirin_ethereal
    {artid=998 , content={}},   --kirin_kirin
    {artid=77 , content={}},    --krakens_kraken
    {artid=24 , content={}},    --liche_liche_retro
    {artid=78 , content={}},    --liche_liche_lord_retro
    {artid=79 , content={}},    --liche_liche_lord_retro
    {artid=82 , content={}},    --liche_liche_lord_retro
    {artid=33 , content={}},    --lizard_race_lizardman
    {artid=35 , content={}},    --lizard_race_lizardman
    {artid=36 , content={}},    --lizard_race_lizardman
    {artid=202 , content={}},   --lizards_alligator_brown
    {artid=133 , content={}},   --lizards_alligator_small
    {artid=134 , content={}},   --lizards_komodo_dragon
    {artid=206 , content={}},   --lizards_lava_lizard
    {artid=220 , content={}},   --llamas_llama
    {artid=828 , content={}},   --llamas_llama
    {artid=170 , content={}},   --llamas_llama_ethereal
    {artid=292 , content={}},   --llamas_llama_pack
    {artid=124 , content={}},   --mages_evil_mage
    {artid=125 , content={}},   --mages_evil_mage_master
    {artid=126 , content={}},   --mages_evil_mage_master
    {artid=770 , content={}},   --Meer_Mage
--  {artid=771 , content={}},   --Meer_Warrior
    {artid=797 , content={}},   --mf_dragon_fire
    {artid=798 , content={}},   --mf_dragon_rust
    {artid=39 , content={}},    --mongbats_mongbat
    {artid=766 , content={}},   --NPC_Kabur
    {artid=767 , content={}},   --NPC_Blackthorn_Cohort
    {artid=769 , content={}},   --NPC_Blackthorn
    {artid=772 , content={}},   --NPC_Adranath
    {artid=773 , content={}},   --NPC_Cpt_Dasha
    {artid=1 , content={}},     --ogres_ogre
    {artid=83 , content={}},    --ogres_ogre_lord
    {artid=84 , content={}},    --ogres_ogre_lord
    {artid=135 , content={}},   --ogres_ogre_lord_arctic
    {artid=136 , content={}},   --ophidians_ophidian_archmage
    {artid=137 , content={}},   --ophidians_ophidian_knight
    {artid=85 , content={}},    --ophidians_ophidian_mage
    {artid=87 , content={}},    --ophidians_ophidian_queen
    {artid=86 , content={}},    --ophidians_ophidian_warrior
    {artid=17 , content={}},    --orcs_orc
    {artid=41 , content={}},    --orcs_orc
    {artid=7 , content={}},     --orcs_orc_captain
    {artid=138 , content={}},   --orcs_orc_lord
    {artid=139 , content={}},   --orcs_orc_lord
    {artid=140 , content={}},   --orcs_orc_shaman
    {artid=181 , content={}},   --orcs_orc_scout
    {artid=182 , content={}},   --orcs_orc_bomber
    {artid=189 , content={}},   --orcs_orc_lord
    {artid=210 , content={}},   --ostards_ostard_desert
    {artid=825 , content={}},   --ostards_ostard_desert
    {artid=218 , content={}},   --ostards_ostard_forest
    {artid=826 , content={}},   --ostards_ostard_forest
    {artid=219 , content={}},   --ostards_ostard_frenzied
    {artid=827 , content={}},   --ostards_ostard_frenzied
    {artid=171 , content={}},   --ostards_ostard_ethereal
    {artid=141 , content={}},   --paladins_paladin
    {artid=775 , content={}},   --plague_beast
    {artid=290 , content={}},   --porcines_boar
    {artid=203 , content={}},   --porcines_pig
    {artid=42 , content={}},    --rat_race_ratman
    {artid=44 , content={}},    --rat_race_ratman
    {artid=45 , content={}},    --rat_race_ratman
    {artid=142 , content={}},   --rat_race_ratman
    {artid=143 , content={}},   --rat_race_shaman
    {artid=215 , content={}},   --rodents_rat_giant
    {artid=839 , content={}},   --ridgeback_ridgeback
    {artid=840 , content={}},   --ridgeback_giant
    {artid=841 , content={}},   --ridgeback_flame
    {artid=842 , content={}},   --ridgeback_hatchling
    {artid=209 , content={}},   --ruminants_goat_billy
    {artid=88 , content={}},    --ruminants_goat_mountain
    {artid=207 , content={}},   --ruminants_sheep
    {artid=223 , content={}},   --ruminants_sheep_shorn
    {artid=790 , content={}},   --sand_vortex
    {artid=48 , content={}},    --scorpions_giant
    {artid=144 , content={}},   --sea_horse_sea_horse
    {artid=150 , content={}},   --sea_serpents_sea_serpent
    {artid=145 , content={}},   --sea_serpents_sea_serpent
    {artid=21 , content={}},    --serpents_snake_giant
    {artid=89 , content={}},    --serpents_snake_giant_ice
    {artid=90 , content={}},    --serpents_snake_giant_lava
    {artid=91 , content={}},    --serpents_snake_giant_silver
    {artid=92 , content={}},    --serpents_snake_giant_silver
    {artid=93 , content={}},    --serpents_snake_giant_silver
    {artid=146 , content={}},   --shadowlords_shadowlord
    {artid=793 , content={}},   --skeletal_mount
    {artid=50 , content={}},    --skeletons_skeleton
    {artid=56 , content={}},    --skeletons_skeleton
    {artid=57 , content={}},    --skeletons_skeleton
    {artid=147 , content={}},   --skeletons_skeleton_knight
    {artid=148 , content={}},   --skeletons_skeleton_mage
    {artid=51 , content={}},    --slimes_slime
    {artid=94 , content={}},    --slimes_slime_frost
    {artid=96 , content={}},    --slimes_slime_frost
    {artid=574 , content={}},   --spirits_blade_spirit
    {artid=26 , content={}},    --spirits_ghost
    {artid=149 , content={}},   --succubi_succubus
    {artid=174 , content={}},   --succubi_succubus
    {artid=794 , content={}},   --swamp_dragon
    {artid=194 , content={}},   --swamp_dragon_ethereal
    {artid=799 , content={}},   --swamp_dragon_armor
    {artid=778 , content={}},   --swarm
    {artid=152 , content={}},   --terathan_terathan_avenger
    {artid=71 , content={}},    --terathan_terathan_drone
    {artid=72 , content={}},    --terathan_terathan_queen
    {artid=70 , content={}},    --terathan_terathan_warrior
    {artid=76 , content={}},    --titans_titan
    {artid=53 , content={}},    --trolls_troll
    {artid=54 , content={}},    --trolls_troll
    {artid=55 , content={}},    --trolls_troll_frost
    {artid=3 , content={}},     --walking_dead_zombie
    {artid=221 , content={}},   --walrus_walrus_male
    
--## Age of Shadows Stuff                               

    {artid=300 , content={}},   --crystal_elemental
    {artid=301 , content={}},   --treefellow
    {artid=302 , content={}},   --skittering_hopper
    {artid=303 , content={}},   --devourer
    {artid=304 , content={}},   --flesh_golem
    {artid=305 , content={}},   --gore_fiend
    {artid=306 , content={}},   --impaler
    {artid=307 , content={}},   --gibberling
    {artid=308 , content={}},   --bonedemon
    {artid=309 , content={}},   --patchskeleton
    {artid=310 , content={}},   --wailingbanshee
--  {artid=311 , content={}},   --shadow_knight
    {artid=312 , content={}},   --abysmal_horror
    {artid=313 , content={}},   --Darknight_Creeper
    {artid=314 , content={}},   --ravager
    {artid=315 , content={}},   --flesh_renderer
    {artid=316 , content={}},   --wander
    {artid=317 , content={}},   --vampire_bat
    {artid=318 , content={}},   --demon_knight
    {artid=319 , content={}},   --mound_of_maggots

    {artid=777 , content={}},   --doppleganger
    {artid=784 , content={}},   --arcane_demon
    {artid=785 , content={}},   --four_armed_demon
    {artid=788 , content={}},   --sphinx
    {artid=789 , content={}},   --quagmire
    
--## Samurai Empire creatures                               
    {artid=240 , content={}},   --Kappa
    {artid=241 , content={}},   --Oni
    {artid=242 , content={}},   --Bimbobushi
    {artid=243 , content={}},   --Hai_Riyo
    {artid=244 , content={}},   --Rune_Beetle
    {artid=245 , content={}},   --Yomotsu_Warrior
    {artid=246 , content={}},   --Kitsun_Tsuki
    {artid=247 , content={}},   --Fan_Dancer
    {artid=248 , content={}},   --Wild_Guar
    {artid=249 , content={}},   --Yamandon
    {artid=250 , content={}},   --Tri_Wolf
    {artid=251 , content={}},   --Vampyric_Beast
    {artid=252 , content={}},   --Lady_of_the_Snow
    {artid=253 , content={}},   --Yomotsu_Priest
    {artid=254 , content={}},   --Crane
    {artid=255 , content={}},   --Yomotsu_Elder
    {artid=169 , content={}},   --Giant_Beetle_Fire
    {artid=196 , content={}},   --Denkou_Yajuu
    {artid=199 , content={}},   --Gouzen_Ha
    
--## ep1 creatures

    {artid=264 , content={}},   --Changling
--  {artid=257 , content={}},   --DreadHorn
    {artid=266 , content={}},   --Dryad
    {artid=265 , content={}},   --Hydra
    {artid=264 , content={}},   --Changling
    {artid=258 , content={}},   --LadyMelisande
    {artid=280 , content={}},   --MinotaurArmored
    {artid=281 , content={}},   --LeatherMinotaur
    {artid=263 , content={}},   --Minotaur
    {artid=259 , content={}},   --MonstrousInterredGrizzle
    {artid=272 , content={}},   --MonstrousInterredGrizzle      
    {artid=256 , content={}},   --Paroxysmus
    {artid=271 , content={}},   --Satyr
    {artid=262 , content={}},   --TormentedMinotaur
    {artid=267 , content={}},   --Troglodyte
    {artid=261 , content={}},   --Shimmering_Effusion
    {artid=273 , content={}},   --Fetid_Essence
    {artid=276 , content={}},   --Raptalon
    {artid=277 , content={}},   --CuShidhe
                                            
    {artid=278 , content={}},   --Squirrel
    {artid=279 , content={}},   --Ferret
    {artid=282 , content={}},   --Parrot
    {artid=283 , content={}},   --Crow
    {artid=284 , content={}},   --MondainSteed01
    {artid=285 , content={}},   --ReaperForm

--#Time Lord
    {artid=689 , content={}},   --shadowlords_shadowlord
    {artid=704 , content={}},   --shadowlords_shadowlord

    {artid=0x101 , content={}},     --client crash, see also gBrokenGrannyModelIdList
    {artid=0x306 , content={}},     --client crash, see also gBrokenGrannyModelIdList

--[[
--------------------------------------------------------------------------
--              custom assigned Models (only for testing)
--------------------------------------------------------------------------
    {artid= hex2num("5") , content={}},     --birds_eagle
    {artid= hex2num("39") , content={}},    --mongbats_mongbat
	{artid= hex2num("105") , content={}},	--dragons_wyrm_ancient

    -- llamas_llama_pack - broken (crash) -> mapped to id: 220 (grannyfilter)
    {artid= 292 , content={}},
    -- käfer - broken animation
    {artid= hex2num("0xA9") , content={}},
    --791 broken horse
    {artid= hex2num("0x317"), content={}},

    {artid= hex2num("0xB1") , content={}}, -- 177 broken
    {artid= hex2num("0x72") , content={}}, -- 114 broken 
    {artid= hex2num("0x73") , content={}},  -- 115 broken
    {artid= hex2num("0x75") , content={}}, -- 117 broken

    {artid= hex2num("0xD5") , content={}}, 
    {artid= hex2num("0xF1") , content={}}, 
    {artid= hex2num("0xF3") , content={}}, 
    {artid= hex2num("0xCC") , content={}}, -- 204, broken horse
    {artid= hex2num("0xC8") , content={}}, -- 200 : standard horse
    {artid= hex2num("0xE2") , content={}}, -- 226 broken
    {artid= hex2num("0xE4") , content={}}, -- 228 broken
    {artid= hex2num("0xFC"), content={}},
    {artid= hex2num("0xDC") , content={}}, 
    {artid= hex2num("0xD2") , content={}}, 
    {artid= hex2num("0xDA") , content={}}, 
    {artid= hex2num("0xDB") , content={}}, 
	{artid=	hex2num("0xD5") , content={}}, 
    {artid= hex2num("0x90") , content={}}, 
    {artid= hex2num("0x74") , content={}},  -- 116 broken
    {artid= hex2num("0xB2") , content={}},  -- 178 broken
    {artid= hex2num("0x84") , content={}}, 
    {artid= hex2num("0xB3") , content={}},  -- 179 broken
    {artid= hex2num("0xBB") , content={}}, 
    {artid= hex2num("0xBC") , content={}}, 
	{artid=	hex2num("0x317") , content={}}, -- brokenanim
	{artid=	hex2num("0x31A") , content={}}, -- brokenanim
	{artid=	hex2num("0x31F") , content={}}, -- brokenanim
    {artid= hex2num("0xBE") , content={}},  -- 190 broken
	{artid= hex2num("0x11C") , content={}}, -- 284 anim broken, scale broken..
    {artid= hex2num("0xFB") , content={}}, 

    {artid=400,hue=33780, content={[4]={artid=5422,hue=1728,animid=430},[26]={artid=3701,hue=0,animid=422},[16]={artid=8269,hue=1147,animid=906},[27]={artid=3701,hue=0,animid=422},[17]={artid=8059,hue=1652,animid=913},[11]={artid=8252,hue=1147,animid=701},[12]={artid=5435,hue=0,animid=466},[21]={artid=3701,hue=0,animid=422},}},
    {artid=400,hue=33780, content={[26]={artid=3701,hue=0,animid=422},[16]={artid=8269,hue=1147,animid=906},[27]={artid=3701,hue=0,animid=422},[17]={artid=8059,hue=1652,animid=913},[11]={artid=8252,hue=1147,animid=701},[12]={artid=5435,hue=0,animid=466},[21]={artid=3701,hue=0,animid=422},}},
    {artid=400,hue=33780, content={[27]={artid=3701,hue=0,animid=422},[17]={artid=8059,hue=1652,animid=913},[11]={artid=8252,hue=1147,animid=701},[12]={artid=5435,hue=0,animid=466},[21]={artid=3701,hue=0,animid=422},}},
    {artid=400,hue=33780, content={[11]={artid=8252,hue=1147,animid=701},[12]={artid=5435,hue=0,animid=466},[21]={artid=3701,hue=0,animid=422},}},

    {artid=400, content={}},
    {artid=400, content={[1]={artid=3932,animid=631},[2]={artid=7107,animid=993},[4]={artid=5137,animid=529},[6]={artid=9797,animid=682},[7]={artid=5140,animid=530},[19]={artid=5136,animid=528},[16]={artid=8256,animid=800},[21]={artid=3701,animid=422},[13]={artid=5141,animid=527},[29]={artid=3708,animid=0},[11]={artid=8266,animid=903},}},
    {artid=401, content={}},
    {artid=401, content={[1]={artid=3932,animid=631},[2]={artid=7107,animid=993},[4]={artid=5137,animid=529},[6]={artid=9797,animid=682},[7]={artid=5140,animid=530},[19]={artid=5136,animid=528},[16]={artid=8256,animid=800},[21]={artid=3701,animid=422},[13]={artid=5141,animid=527},[29]={artid=3708,animid=0},[11]={artid=8266,animid=903},}},
    {artid=014, content={}},
    {artid=778, content={}},
    {artid=401, content={[1]={artid=3932,animid=631},[2]={artid=7107,animid=993},[4]={artid=5137,animid=529},[6]={artid=9797,animid=682},[7]={artid=5140,animid=530},[19]={artid=5136,animid=528},[16]={artid=8256,animid=800},[21]={artid=3701,animid=422},[13]={artid=5141,animid=527},[29]={artid=3708,animid=0},[11]={artid=8266,animid=903},}},
    {artid=401, content={[1]={artid=3932,animid=631},[4]={artid=5137,animid=529},[6]={artid=9797,animid=682},[7]={artid=5140,animid=530},[19]={artid=5136,animid=528},[16]={artid=8256,animid=800},[21]={artid=3701,animid=422},[13]={artid=5141,animid=527},[29]={artid=3708,animid=0},[11]={artid=8266,animid=903},}},
    {artid=401, content=({{artid=3932,animid=631},{artid=7107,animid=993},{artid=5137,animid=529},{artid=9797,animid=682},{artid=5140,animid=530},{artid=5136,animid=528},{artid=8256,animid=800},{artid=3701,animid=422},{artid=5141,animid=527},{artid=3708,animid=0},{artid=8266,animid=903},})},

    {artid=400, content=({{artid=3519,animid=972},})},
    {artid=400, content=({{artid=3519,animid=972},{artid=5901,animid=479},{artid=5422,animid=430},{artid=5399,animid=434},{artid=5907,animid=404},{artid=3701,animid=422},{artid=8252,animid=701},})},
    {artid=987, content=({{artid=5182,animid=624},{artid=5903,animid=480},{artid=5399,animid=434},{artid=5130,animid=565},{artid=5397,animid=468},{artid=3701,animid=422},{artid=7939,animid=469},})},
    {artid=401, content=({{artid=2594,animid=500},{artid=5899,animid=477},{artid=7933,animid=435},{artid=5431,animid=455},{artid=5397,animid=468},{artid=5441,animid=490},{artid=8261,animid=710},{artid=3701,animid=422},})},
    {artid=401, content=({{artid=2594,animid=500},{artid=5905,animid=476},{artid=5399,animid=434},{artid=5431,animid=455},{artid=5441,animid=490},{artid=3701,animid=422},{artid=8262,animid=712},})},
    {artid=401, content=({{artid=5899,animid=477},{artid=5422,animid=430},{artid=5399,animid=434},{artid=5435,animid=466},{artid=8251,animid=700},{artid=3701,animid=422},})},
    {artid=400, content=({{artid=5905,animid=476},{artid=5422,animid=430},{artid=7933,animid=435},{artid=5909,animid=406},{artid=5441,animid=490},{artid=3701,animid=422},{artid=8251,animid=700},})},
    {artid=400, content=({{artid=5899,animid=477},{artid=5422,animid=430},{artid=7933,animid=435},{artid=8266,animid=903},{artid=3701,animid=422},})},
	
	-- meshes only crash when using vertex-shader
	{artid=040, content={}},
	{artid=	hex2num("0x76") , content={}},
	{artid=	hex2num("0x77") , content={}}, 
	{artid=	hex2num("0x78") , content={}},
	{artid=	hex2num("0x79") , content={}}, 
	{artid=	hex2num("0x3C") , content={}}, 
	{artid=	hex2num("0xC8") , content={}}, 
	{artid= hex2num("0x123") , content={}},
	{artid=199, content={}},
	{artid=225, content={}}, -- timberwolf
	{artid=256, content={}},
	{artid=	hex2num("0x319") , content={}},
	{artid=400,hue=33780, content={
		{artid=hex2num("0x3EA2"),layer=kLayer_Mount},
		[4]={artid=5422,hue=1728,animid=430},[26]={artid=3701,hue=0,animid=422},
		[16]={artid=8269,hue=1147,animid=906},[27]={artid=3701,hue=0,animid=422},
		[17]={artid=8059,hue=1652,animid=913},[11]={artid=8252,hue=1147,animid=701},
		[21]={artid=3701,hue=0,animid=422},}},   
	{artid=401, content=({{artid=hex2num("0x3EA2"),layer=kLayer_Mount},{artid=5899,animid=477},{artid=5422,animid=430},{artid=5399,animid=434},{artid=5435,animid=466},{artid=8251,animid=700},{artid=3701,animid=422},})},
	{artid=400, content=({{artid=hex2num("0x3EA2"),layer=kLayer_Mount},{artid=5899,animid=477},{artid=5422,animid=430},{artid=5399,animid=434},{artid=5435,animid=466},{artid=8251,animid=700},{artid=3701,animid=422},})},

	{artid=2011, content={{animid=2002}}}, -- 02:feet 11:ulegs
	{artid=1466, content={}}, -- flimmer, need culling? (fixed)
	{artid=1700, content={}}, -- hair, texcoords or normals broken ? (fixed)
	{artid=500, content={}}, -- lantern, texcoords broken ?! (fixed)
	{artid=468, content={}}, -- cape, texcoords broken ? culling? (fixed)
	{artid=1468, content={}}, -- cape, texcoords broken ? culling? (fixed)
	{artid=490, content={}}, -- sash, texcoords broken ? culling? (fixed)
	{artid=1490, content={}},  -- sash, texcoords broken ? culling? (fixed)

	{artid=1924, content={{animid=3012}}},
	{artid=3604, content={{animid=3012}}},
	{artid=1925, content={{animid=3012}}},
	{artid=3605, content={{animid=3012}}},

	{artid=3006, content={}}, -- female lower legs, sience was having problem with them, 2 submeshes !
	{artid=2013, content={}},
	{artid=2009, content={}},
	{artid=2012, content={}},
	{artid=3013, content={}},
	{artid=3009, content={}},
	{artid=3012, content={}},
	{artid=3009, content={}},
	{artid=3012, content={}},
	{artid=3009, content={}},
	{artid=3012, content={}},
	{artid=3009, content={}},
	{artid=3012, content={}},
]]--
}



-- 0:none 1:normal 2:invert 3:sample 4:sample-invert        -- bonestart
-- 0:nothin 1:q 2:q.Inverse()                           -- translationchange
-- 0:local 1:parent 2:world                             -- iTransformSpaceModeT default:1
-- 0:local 1:parent 2:world                             -- iTransformSpaceModeR default:0
-- 0:tr 1:rt                                            -- iRotateFirst
function GrannyBoneStart () return 3,0,1,0,0 end

-- 0:nothin 1:it 2:jt           -- inverting bonestart for anim
-- 0:nothin 1:q 2:q.Inverse()   -- translationchange
function AnimInvertMode () return 1,0 end

function DebugMenuShowModel ()
    local index = gDebugMenuModelIndex

    if (gDebugRootGfx) then gDebugRootGfx:Destroy() gDebugRootGfx = nil end
    if (gDebugRootGfx2) then gDebugRootGfx2:Destroy() gDebugRootGfx2 = nil end
    if (gDebugRootGfx3) then gDebugRootGfx3:Destroy() gDebugRootGfx3 = nil end
    gDebugRootGfx = CreateRootGfx3D()
    gDebugRootGfx2 = CreateRootGfx3D()
    gDebugRootGfx3 = CreateRootGfx3D()
    
    -- granny 
    if (gCurDebugMode == kDebugMode_Granny) then
        local mobile = gDebugMenuModelTable[index]
        if (not mobile) then return end
        RepairEquipIndex(mobile.content)
        GuiAddChatLine(sprintf("DebugMenuShowModel model=%04x(=%d) anim=%d[%s] %s",mobile.artid,mobile.artid,gDebugMenuAnimIndex,GetAnimName(mobile.artid,gDebugMenuAnimIndex) or "", gDebugMenuModelName or ""))

        gDebugBodyGfx = CreateBodyGfx(gDebugRootGfx)
        gDebugBodyGfx:MarkForUpdate(mobile.artid,mobile.hue,mobile.content)
        gDebugBodyGfx:Update()
        
        local bMoving,bTurning,bWarMode,bRunFlag = false,false,false,false
        if (gDebugMenuAnimIndex == -1) then bMoving                     = true,true,true end
        if (gDebugMenuAnimIndex == -2) then bMoving,bRunFlag            = true,true,true end
        if (gDebugMenuAnimIndex == -3) then bWarMode,bMoving            = true,true,true end
        if (gDebugMenuAnimIndex == -4) then bWarMode,bMoving,bRunFlag   = true,true,true end
        gDebugBodyGfx:SetState(bMoving,bTurning,bWarMode,bRunFlag)
        
        if (gDebugMenuAnimIndex >= 0) then gDebugBodyGfx:StartAnimLoop(gDebugMenuAnimIndex) end
    end
    
    local xadd,yadd,zadd = 0,0,0
    -- static 
    if (gCurDebugMode == kDebugMode_Static) then
        Client_SetAmbientLight(0,0,0,0)
        Client_ClearLights()
        --~ Client_AddPointLight(2.1836402416229      ,  -0.50490587949753    ,   1.208433508873)
        --~ Client_AddPointLight(0                    ,  -7.2237491607666     ,   -20)
        --~ Client_AddPointLight(7.8641700744629      ,  -7.2237491607666     ,   -20)
        Client_AddPointLight(7.8641700744629      ,  -7.2237491607666     ,   -5)
        --~ Client_AddPointLight(10,0,0)
        --~ Client_AddPointLight(-10,10,0)
        --~ Client_AddPointLight(-10,-10,0)
        gTileFreeWalk:SetPos_ClientSide(-1,1,0)
        
        local iTileType = tonumber(gDebugMenuModelIndex)
        local iHue = gDebugMenuAnimIndex
        local info = GetStaticTileType(iTileType)
        local meshname = GetMeshName(iTileType,iHue)
		if (gDebugModeTestSkeletalAnimShader) then meshname = "jaiqua.mesh" end
        --~ if (iTileType == 578) then meshname = "knot.mesh" end
        local submeshcount = GetMeshSubMeshCount(meshname)
        print("mesh for tiletype=",iTileType,sprintf("0x%04x",iTileType)," submeshcount=",submeshcount)
        for i = 0,submeshcount-1 do 
            print("submesh mat",i,GetMeshSubMaterial(meshname,i),iTileType)
            if (iTileType == 578) then SetMeshSubMaterial(meshname,i,"Examples/OffsetMapping/Specular") end
            --~ if (iTileType == 578) then SetMeshSubMaterial(meshname,i,"Examples/OffsetMapping/IntegratedShadows") end
        end
        MeshBuildTangentVectors(meshname)
        
        if gDebugLastMeshName then ReloadMesh(gDebugLastMeshName) end
        gDebugLastMeshName = meshname
        local tricount = meshname and CountMeshTriangles(meshname) or 0
        GuiAddChatLine(sprintf("static %04x(=%d) hue=%d tricount=%d %s",iTileType,iTileType,iHue,tricount,GetStaticTileTypeName(iTileType) or ""))
        if (meshname and meshname ~= false) then
            gDebugRootGfx:SetMesh(meshname)
			
			if (gDebugModeTestSkeletalAnimShader) then 
				local f = 1/34
				gDebugRootGfx:SetScale(f,f,f)
				gDebugRootGfx:SetAnim("Sneak",true)
				gDebugRootGfx.animtime = 0
				if (not  gDebugRootGfx.animfun_set) then
					 gDebugRootGfx.animfun_set = true 
					 RegisterStepper(function () 
						gDebugRootGfx:SetAnimTimePos(gDebugRootGfx.animtime)
						gDebugRootGfx.animtime = gDebugRootGfx.animtime + 1/30
						if (gDebugRootGfx.animtime > 3) then gDebugRootGfx.animtime = 0 end
					 end)
				end
				
					
				local x1,y1,z1, x2,y2,z2 = gDebugRootGfx:GetEntityBounds()
				print("##########################################")
				print("#######  mesh bounds :",x1,y1,z1, x2,y2,z2)
				print("##########################################")
				--~ #######  mesh bounds :  -24.264656066895        -1.6195520162582        -61.062599182129        14.574376106262 17.728036880493 34.605701446533
				--~ #######  mesh bounds :  -1.0015000104904        -0.0044999998062849     -0.012000000104308      -0.84850001335144       0.454499989748  1.2120000123978
			end
			
			
            --~ gDebugRootGfx:SetOrientation(GetStaticMeshOrientation(iTileType))
            --~ mirroring now baked into meshes for shader compatibility -- gDebugRootGfx:SetScale(-1,1,1)          -- (-1) thats because xmirror bug and wrong mirrored meshes
            --~ gDebugRootGfx:SetNormaliseNormals(true)
            --~ gDebugRootGfx:SetCastShadows(gDynamicsCastShadows)
            -- primary color hueing
            if gHueLoader and iHue > 0 then
                local r,g,b = gHueLoader:GetColor(iHue - 1,31) -- get first color
                --~ HueMeshEntity(gDebugRootGfx,r,g,b,r,g,b)
            end
            -- position adjustment for statics and dynamics
            xadd,yadd,zadd = FilterPositionXYZ(iTileType)
        end
        Renderer3D:CreateArtBillBoard(gDebugRootGfx2,iTileType+0x4000,iHue)
        
        Renderer3D:CreateArtBillBoard(gDebugRootGfx3,0,0,true)--0,0,true)
        gDebugRootGfx3:SetVisible(true)
        gDebugRootGfx3:SetPosition(3,0.5,-0.15)
    end
    
    gDebugRootGfx:SetVisible(true)
    local x,y,z = unpack(gDebugMenuMainGfxPos)
    gDebugRootGfx:SetPosition(x - xadd,y + yadd,z + zadd)
    
    gDebugRootGfx2:SetVisible(true)
    gDebugRootGfx2:SetPosition(3,0.5,-0.15)
end

function DebugMenuSetParam1 (value) 
    gDebugMenuModelIndex = value
    DebugMenuShowModel()
end

function DebugMenuChangeParam1  (delta) 
    local newval = gDebugMenuModelIndex
    if ((gKeyPressed[key_lshift]) and gCurDebugMode == kDebugMode_Static) then
        for i=1,math.abs(delta) do
            local tries = 400
            local add = (delta > 0) and 1 or -1
            newval = newval + add
            local meshname = GetMeshName(newval)
            while (tries > 0 and ((not meshname) or (CountMeshTriangles(meshname) > 6))) do
                newval = newval + add
                meshname = GetMeshName(newval)
                tries = tries - 1
            end 
        end
    else
        newval = newval + delta
    end
    DebugMenuSetParam1(newval)
end

function StartDebugMenu ()
    DestroyIfAlive(gMenuBgImage)
    gMenuBgImage = nil

    if (false) then
        gDebugMenuModelTable = {}
        kDebugMenuModelTable_EmptyContents = {}
        for i=0x000,0xFff do  -- max = 0x0f6b
            if (GetGrannyModelInfo(i)) then table.insert(gDebugMenuModelTable,{artid=i,content=kDebugMenuModelTable_EmptyContents}) end
        end
    end


    -- dont show fallback boxes in debug mode
    gUseWhiteBoxAsFallBack = false

    -- parse command line args
    if gCommandLineSwitches["-dparticle"] then
        gCurDebugMode = kDebugMode_Particle
        local data = gCommandLineArguments[gCommandLineSwitches["-dparticle"]+1]
        MyStartParticleDebugMode(data) -- -dparticle data
    end
    
    -- parse command line args
    if gCommandLineSwitches["-artid"] then
        local id = gCommandLineArguments[gCommandLineSwitches["-artid"]+1]
        gCurDebugMode = kDebugMode_Static
        if string.find(id,"x") then
            -- hex value given
            gDebugMenuModelIndex = hex2num(id)
        else
            -- decimal value given
            gDebugMenuModelIndex = id
        end
        
        if gCommandLineSwitches["-export"] then
            -- just export the current model and close the client
            DebugExportModel(gDebugMenuModelIndex)
            Terminate()
        end
    end

    --CrashSegFault() -- testing =D
    gStartInDebugMode = true
    gDebugMenuRunning = true
    gDialog_IrisLogo:SetVisible(false)

    gCurrentRenderer:Init()
    ActivateRenderer(Renderer3D)

    Client_SetSkybox("bluesky") -- cube skybox sunset darksun 
    Renderer3D:ChangeCamMode(Renderer3D.kCamMode_Third)
    Renderer3D.gfCamAngV = -0.5

    local cam = GetMainCam()
    --cam:SetFOVy(gfDeg2Rad*45)
    cam:SetNearClipDistance(0.01) -- old : 1
    --cam:SetFarClipDistance(2000) -- ogre defaul : 100000
    
    Renderer3D.gThirdPersonDist = 6.5
    
    -- grid
    if (true) then
        gDebugGridGfx = CreateRootGfx3D()
        local x,y,z = unpack(gDebugMenuMainGfxPos)
        gDebugGridGfx:SetPosition(x,y,z)
        local mygfx = gDebugGridGfx
        mygfx:SetSimpleRenderable()
        mygfx:SetMaterial("debug_grid_3D")
        mygfx:RenderableBegin(2 + 4*9 + 4 + 4 + 4,2 + 4*9 + 8 + 8 + 8 + 8,false,false,OT_LINE_LIST)
        local x,y,z = -1,1,2
        local g = 8
        mygfx:RenderableVertex(0,0,0, 1,1,1,1)
        mygfx:RenderableVertex(0,0,z, 1,1,1,1)
        mygfx:RenderableIndex2(0,1)
        for j=0,8 do 
            local i = j-4
            mygfx:RenderableVertex(i,-g,0, 1,1,1,1)
            mygfx:RenderableVertex(i, g,0, 1,1,1,1)
            mygfx:RenderableVertex(-g,i,0, 1,1,1,1)
            mygfx:RenderableVertex( g,i,0, 1,1,1,1)
            mygfx:RenderableIndex2(2 + 4*j + 0,2 + 4*j + 1)
            mygfx:RenderableIndex2(2 + 4*j + 2,2 + 4*j + 3)
        end

        local i = 38
        local h1 = 1
        local h2 = 2
        local d = 0.01
        -- red box
        
        mygfx:RenderableVertex(d,-d,d, 1,0,0,1) -- 0
        mygfx:RenderableVertex(-1-d,-d,d, 1,0,0,1)  -- 1
        mygfx:RenderableVertex(-1-d,1+d,d, 1,0,0,1) -- 2
        mygfx:RenderableVertex(d,1+d,d, 1,0,0,1)    -- 3

        mygfx:RenderableVertex(d,-d,d+h2, 1,0,0,1)  -- 4
        mygfx:RenderableVertex(-1-d,-d,d+h2, 1,0,0,1)   -- 5
        mygfx:RenderableVertex(-1-d,1+d,d+h2, 1,0,0,1)  -- 6
        mygfx:RenderableVertex(d,1+d,d+h2, 1,0,0,1) -- 7

        mygfx:RenderableVertex(d,-d,d+h1, 1,0,0,1)  -- 8
        mygfx:RenderableVertex(-1-d,-d,d+h1, 1,0,0,1)   -- 9
        mygfx:RenderableVertex(-1-d,1+d,d+h1, 1,0,0,1)  -- 10
        mygfx:RenderableVertex(d,1+d,d+h1, 1,0,0,1) -- 11

        mygfx:RenderableIndex2(i + 0, i + 1)
        mygfx:RenderableIndex2(i + 1, i + 2)
        mygfx:RenderableIndex2(i + 2, i + 3)
        mygfx:RenderableIndex2(i + 3, i + 0)

        mygfx:RenderableIndex2(i + 4+0, i + 4+1)
        mygfx:RenderableIndex2(i + 4+1, i + 4+2)
        mygfx:RenderableIndex2(i + 4+2, i + 4+3)
        mygfx:RenderableIndex2(i + 4+3, i + 4+0)

        mygfx:RenderableIndex2(i + 0, i + 4)
        mygfx:RenderableIndex2(i + 1, i + 5)
        mygfx:RenderableIndex2(i + 2, i + 6)
        mygfx:RenderableIndex2(i + 3, i + 7)

        mygfx:RenderableIndex2(i + 8, i + 9)
        mygfx:RenderableIndex2(i + 9, i + 10)
        mygfx:RenderableIndex2(i + 10, i + 11)
        mygfx:RenderableIndex2(i + 11, i + 8)

        mygfx:RenderableEnd()
    end
    
    DebugMenuShowModel()
    
    UnbindAll()
    ClearAllMacros()

    BindDown("escape",  function () Terminate() end)
    
    BindDown("v",       function() MacroCmd_Screenshot() end)
    BindDown("x",       function() print("campos:",GetMainCam():GetPos()) end)
    Bind("wheeldown",   function (state) if (not gActiveEditText) then if (state > 0) then gCurrentRenderer:CamChangeZoom( 0.3) end end end)
    Bind("wheelup",     function (state) if (not gActiveEditText) then if (state > 0) then gCurrentRenderer:CamChangeZoom(-0.3) end end end)
    Bind("f10",     function (state) if (not gActiveEditText) then if (state > 0 and gCurDebugMode == kDebugMode_Static) then 
        AdjustArtPositionControlDialog(gDebugMenuModelIndex) end end end)
    Bind("c",       function (state) if (not gActiveEditText) then if (state > 0) then gCurrentRenderer:ChangeCamMode() end end end)

    Bind("a", function (state) if (not gActiveEditText) then if (state > 0) then 
        gDebugMenuAnimIndex = 0 gDebugMenuModelIndex = 1 DebugMenuShowModel()
        end end end)

    Bind("f", function (state) if (not gActiveEditText) then if (state > 0) then 
        DebugMenuChangeParam1(-1)
        end end end)
    Bind("g", function (state) if (not gActiveEditText) then if (state > 0) then 
        DebugMenuChangeParam1( 1)
        end end end)
        
        
    Bind("j", function (state) if (not gActiveEditText) then if (state > 0) then 
        gDebugMenuAnimIndex = gDebugMenuAnimIndex - 1  DebugMenuShowModel()
        end end end)
    Bind("k", function (state) if (not gActiveEditText) then if (state > 0) then 
        gDebugMenuAnimIndex = gDebugMenuAnimIndex + 1  DebugMenuShowModel()
        end end end)
        
    Bind("f1", function (state) if (not gActiveEditText) then if (state > 0) then
        --TODO: close ShowDebugMenuArtList(0,kDebugMode_Static)
        gCurDebugMode = gCurDebugMode + 1
        if (gCurDebugMode > kDebugMode_Static) then gCurDebugMode = kDebugMode_Granny end
        gDebugMenuAnimIndex = 0 gDebugMenuModelIndex = 1
        DebugMenuShowModel()
        end end end)
        
    Bind("f2", function (state) if (not gActiveEditText) then if (state > 0) then 
        DebugMenuChangeParam1(-64)
        MyParticleDebugMode_Prev()
        end end end)
    Bind("f3", function (state) if (not gActiveEditText) then if (state > 0) then 
        DebugMenuChangeParam1( 64)
        MyParticleDebugMode_Next()
        end end end)
        
        
    Bind("f4", function (state) if (not gActiveEditText) then if (state > 0) then 
        DebugMenuChangeParam1(-4096)
        end end end)
    Bind("f5", function (state) if (not gActiveEditText) then if (state > 0) then 
        DebugMenuChangeParam1( 4096)
		MyReloadParticleDebugMode()
        end end end)
    Bind("f6", function (state) if (not gActiveEditText) then if (state > 0) then 
        if (gCurDebugMode == kDebugMode_Static) then ShowDebugMenuArtList(0,kDebugMode_Static) end
        end end end)
    Bind("f7", function (state) if (not gActiveEditText) then if (state > 0) then 
        ShowDebugMenuToolbox()
        end end end)
        
--[[    
    Bind("t", function (state) if (not gActiveEditText) then if (state > 0) then 
        if (gCurDebugMode == kDebugMode_Static) then
            if (gEnableSVNRemoveInStaticDebug) then -- BE CAREFUL WITH THAT !!!!  gEnableSVNRemoveInStaticDebug
                local i = gDebugMenuModelIndex
                os.execute("svn rm " .. GetModelPath(i))
                GuiAddChatLine(sprintf("SVN REMOVE 0x%04x(=%d) %s",i,i,GetModelPath(i)))
            end 
        end 
        end end end)
]]--    
    Bind("f11", function (state) 
        if (state > 0) and gKeyPressed[key_lcontrol] then
            local r = GetMainCam():GetPolygonMode()
            if r == kCamera_PM_POINTS then GetMainCam():SetPolygonMode(kCamera_PM_WIREFRAME)
            elseif r == kCamera_PM_WIREFRAME then GetMainCam():SetPolygonMode(kCamera_PM_SOLID)
            elseif r == kCamera_PM_SOLID then GetMainCam():SetPolygonMode(kCamera_PM_POINTS)
            end
        end
    end)

    Bind("b", function (state) if (not gActiveEditText) then if (state > 0) then 
        if (gCurDebugMode == kDebugMode_Static) then
            local i = gDebugMenuModelIndex
            local notepath = "debugstatic.txt"
            local text = sprintf("DebugStaticNOTE 0x%04x(=%d) %s %s",i,i,GetModelPath(i),GetStaticTileTypeName(i) or "")
            GuiAddChatLine(notepath..":"..text)
            local f = io.open(notepath,"a")
            f:write(text.."\n")
            f:close()
        end
        end end end)
    
    ShowDebugMenuToolbox()
    MyParticleDebugMode_Init2()
end

function StepDebugMenu ()
    if (not gDebugMenuRunning) then return end
    -- camera
    Renderer3D:CamStep()
end

function DebugDeleteModel   (id)
    local base = id - math.mod(id,1000) + 1000
    local relpath  = sprintf("models/to_%06d/",base)
    local mdlname = GetModelName(id)
    local mdl = datapath.."models/"..relpath..mdlname
    
    print("removing model: "..mdl)
    
    os.execute("svn rm '"..mdl.."'")    
    os.execute("rm '"..mdl.."'")    
end

function DebugFlipModel (id)
    print("###############################")
    print("flip normals")
    if gArtFilter[id] and gArtFilter[id].maptoid then
        id = gArtFilter[id].maptoid
    end
    
    local base = id - math.mod(id,1000) + 1000
    local relpath  = sprintf("models/to_%06d/",base)
    local mdlname = GetModelName(id)
    local mdl = datapath.."models/"..relpath..mdlname
    
    if not file_exists(mdl) then
        print("model file not found")
        return
    end
    
    print("meshmagick transform -flip-normals '"..mdl.."'")
    os.execute("meshmagick transform -flip-normals '"..mdl.."'")
end

function DebugExportModel   (id)
    print("###############################")
    print("export model and textures",artid,"to data/export")

    local base = id - math.mod(id,1000) + 1000
    local relpath  = sprintf("models/to_%06d/",base)
    local mdlname = GetModelName(id)
    local mdl = datapath.."models/"..relpath..mdlname
    local export = datapath.."export/"
    
    local xmlfile = export..mdlname..".xml"

    if not file_exists(mdl) then
        print("model file not found")
        return
    end
    
    local expmdl = export..mdlname

    -- try to rotate and adjust blender like, only possible if meshmagick is installed (unix)
    os.execute("cp '"..mdl.."' '"..expmdl.."'")
    os.execute("meshmagick transform -rotate=90/1/0/0 '"..expmdl.."'")
    --~ os.execute("meshmagick transform -scale=1/-1/1 '"..expmdl.."'")
    os.execute("meshmagick transform -rotate=90/0/1/0 '"..expmdl.."'")

    -- create xml file
    print("OgreXMLConverter '"..expmdl.."' '"..xmlfile.."'")
    os.execute("OgreXMLConverter '"..expmdl.."' '"..xmlfile.."'")
    
    if not file_exists(xmlfile) then
        print("xml model file not found")
        return
    end

    -- copy material file
    os.execute("cp '"..datapath.."models/materials/textures.material' '"..datapath.."export'")

    -- try to find used textures
    if file_exists(xmlfile) then
        for line in io.lines(xmlfile) do
            for name in string.gmatch(line, 'material="([^"]+)"') do
                local texfile = datapath.."models/textures/"..name..".png"
                if file_exists(texfile) then
                    print("cp '"..texfile.."' '"..export.."'")
                    os.execute("cp '"..texfile.."' '"..export.."'")
                end
            end
        end
    end
    print("###############################")
end

function DebugMenuJumpToArtID (iArtID) 
    gCurDebugMode = kDebugMode_Static
    DebugMenuSetParam1(iArtID)
end

-- iMaxW,iMaxH : can be nil for unlimited size
function MakeUOArtImageForDialog (iTileTypeID, iHue, iMaxW, iMaxH) 
    iHue = iHue or 0
    -- we have to add 0x4000 for ArtImages
    iTileTypeID = iTileTypeID + 0x4000
    local matname = GetArtMat(iTileTypeID,iHue)
    local isotilew = 44 / math.sqrt(2)
    local w,h = GetArtSize(iTileTypeID,iHue)
    if (not w or w == 0) then w = isotilew end
    if (not h or h == 0) then h = isotilew end
    local tw,th = texsize(w),texsize(h)
    local fw,fh = w,h
    if (iMaxW) then w = math.min(iMaxW,w) end
    if (iMaxH) then h = math.min(iMaxH,h) end
    local offx,offy = (fw-w)*0.5,(fh-h)*0.5  -- this is 0,0 if the art is fully visible, centers art if not
    local u1,v1,u2,v2 = offx/tw,offy/th,(offx+w)/tw,(offy+h)/th
    matname = (string.len(matname) > 0) and matname or "BaseWhiteNoLighting"
    return {type="Img2",    w=w,h=h,matname=matname, u1=u1,v1=v1,u2=u2,v2=v2}
end

--TODO: add check for statics
function checkGlobals(debugmenumodelindex)
    if (debugmenumodelindex <= 1) then return 1 end

    -- if in grannymode, check if index is out of array
    if (gCurDebugMode == kDebugMode_Granny) then
        local maxmodelindex = table.getn(gDebugMenuModelTable)
        if (gDebugMenuModelIndex >= maxmodelindex) then return maxmodelindex end
    end

    return debugmenumodelindex
end

function ShowDebugMenuArtList (iStart, debugmode)
    local rows = { 
        { {type="Label",        text="ArtList"}, },
    }
    
    iStart = iStart or 0
    local iMax = gArtMapLoader:GetCount()
    local w,h = 12,6
    
    local pagerow = {}
    local iNext1 = math.max(0,math.min(iMax,iStart + w*h))
    local iPrev1 = math.max(0,math.min(iMax,iStart - w*h))
    local iNext2 = math.max(0,math.min(iMax,iStart + w*h*10))
    local iPrev2 = math.max(0,math.min(iMax,iStart - w*h*10))
    local myblank = {type="Label",      text=""}
    table.insert(pagerow,{type="Button",text=" <<< ",iNewStart=iPrev2,onMouseDown=function(widget) widget.dialog:Destroy() ShowDebugMenuArtList(widget.iNewStart, debugmode) end})
    table.insert(pagerow,{type="Button",text="  << ",iNewStart=iPrev1,onMouseDown=function(widget) widget.dialog:Destroy() ShowDebugMenuArtList(widget.iNewStart, debugmode) end})
    table.insert(pagerow,{type="Button",text="  >> ",iNewStart=iNext1,onMouseDown=function(widget) widget.dialog:Destroy() ShowDebugMenuArtList(widget.iNewStart, debugmode) end})
    table.insert(pagerow,{type="Button",text=" >>> ",iNewStart=iNext2,onMouseDown=function(widget) widget.dialog:Destroy() ShowDebugMenuArtList(widget.iNewStart, debugmode) end})
    for x = 5,w-1 do table.insert(pagerow,myblank) end
    table.insert(pagerow,{type="Button",text="close",onMouseDown=function(widget) widget.dialog:Destroy() end})
    table.insert(rows,pagerow)
    
    for y = 0,h-1 do
        local row1 = {}
        local row2 = {}
        for x = 0,w-1 do 
            local i = iStart + y*w + x
            if (i < iMax) then

                local dialog_arr = {}
                dialog_arr = MakeUOArtImageForDialog(i,0,48,32)

                if (dialog_arr) then
                    table.insert(row1, dialog_arr)
    
                    local name = GetStaticTileTypeName(i) or "unknown"
                    local label = sprintf("%s\n0x%04x",string.sub(name,1,6),i)

                    if (debugmode == kDebugMode_Static) then
                        table.insert(row2   ,{type="Button",iArtID=i,text=label,onMouseUp=function(widget) 
                            DebugMenuJumpToArtID(widget.iArtID) end})
                    elseif(debugmode == kDebugMode_Online) then
                        table.insert(row2   ,{type="Button",iArtID=i,text=label,onMouseUp=function(widget) 
                                     SendChat(gServerAddCmd.." "..widget.iArtID) end})
                    end
                end
            end
        end
        table.insert(rows,row1)
        table.insert(rows,row2)
    end

    guimaker.MakeTableDlg(rows,10,10,true,true,gGuiDefaultStyleSet,"window")
end

--debug tools window
--notes: works, but crashes if index is out of table range (mystiqq)
function ShowDebugMenuToolbox()
    --return if the dialog is already open
    if (gDebugMenuToolboxDialog) then return end

    --for updating edit boxes on the fly, "binds" control name to global variable. see UpdateEditText function
    local textControls = function()
            local debugmodelartid = 1
            local debugmodelname = ""
            if (gCurDebugMode == kDebugMode_Granny) then
                debugmodelartid = gDebugMenuModelTable[gDebugMenuModelIndex].artid
                local modelinfo = GetGrannyModelInfo(debugmodelartid)
                debugmodelname = modelinfo.modelname
            else
                debugmodelname = GetStaticTileTypeName(gDebugMenuModelIndex) or "unknown"
                debugmodelartid = gDebugMenuModelIndex
            end
            local tmp = {
                cModelArtID = debugmodelartid,
                cModelIdx   = gDebugMenuModelIndex,
                cModelName  = debugmodelname
            }
            return tmp
        end

    local rows = {
        {
            {type="Label",  text="            "},
            {type="Label",  text=""},
            {type="Label",  text="      "},
            {type="Label",  text=""},
            {type="Label",  text="      "},
            {type="Label",  text="   Info               "},
        },
        {
            {type="Label",  text="Art ID"},
            {type="Label",  text=""},
            {type="EditText",   w=40,h=16,text="",controlname="cModelArtID"},
            {type="Label",  text=""},
            {type="Label",  text=""},
            {type="EditText",   w=100,h=16,text="",controlname="cModelName"},
        },
        {
            {type="Label",  text="Table Index"},
            {type="Button",text="-",onMouseDown=function (widget)
                    --get the edit text field
                    gDebugMenuModelIndex=checkGlobals( tonumber(widget.dialog.controls["cModelIdx"].plaintext) - 1 )

                    --update edit field(s)
                    UpdateEditText(widget, textControls())
                    --show/update the model
                    DebugMenuShowModel()
                end
            }, 
            {type="EditText",   w=40,h=16,text="",controlname="cModelIdx"},
            {type="Button",text="+",onMouseDown=function (widget)
                    --get the edit text field
                    gDebugMenuModelIndex=checkGlobals( tonumber(widget.dialog.controls["cModelIdx"].plaintext) + 1 )

                    --update edit field(s)
                    UpdateEditText(widget, textControls())
                    --show/update the model
                    DebugMenuShowModel()
                end
            }, 
            {type="Button",text="Get",onMouseDown=function (widget)
                    --get the edit text field
                    gDebugMenuModelIndex=checkGlobals( tonumber(widget.dialog.controls["cModelIdx"].plaintext) )

                    --update edit field(s)
                    UpdateEditText(widget, textControls())
                    --show/update the model
                    DebugMenuShowModel()
                end
            },
        },
        {
            {type="Label",  text=""},   --separator
        },
        {
            {type="Button",text="Close",onMouseDown=function (widget)
                    --close the window
                    widget.dialog:Destroy()
                    --set the closed dialog to null
                    gDebugMenuToolboxDialog = nil
                end
            }, 
        },
        {
            {type="Button",text="Delete",onMouseDown=function (widget)
                    DebugDeleteModel(gDebugMenuModelIndex)
                end
            }, 
        },
        {
            {type="Button",text="Export",onMouseDown=function (widget)
                    DebugExportModel(gDebugMenuModelIndex)
                end
            }, 
        },
        {
            {type="Button",text="Flip",onMouseDown=function (widget)
                    DebugFlipModel(gDebugMenuModelIndex)
                    DebugMenuShowModel()
                end
            }, 
        },
    }   --end rows

--  local vw,vh = GetViewportSize()
--  local x,y = vw / 2, vh / 2

    gDebugMenuToolboxDialog = guimaker.MakeTableDlg(rows,10,10,true,true, gGuiDefaultStyleSet,"window")
    --fill the edit text boxes
    UpdateEditText(gDebugMenuToolboxDialog.rootwidget, textControls())
    -- center the window
--  x = x - (gDebugMenuToolboxDialog.rootwidget.gfx:GetWidth() / 2)
--  y = y - (gDebugMenuToolboxDialog.rootwidget.gfx:GetHeight() / 2)
--  gDebugMenuToolboxDialog.rootwidget.gfx:SetPos(10,10)
    gDebugMenuToolboxDialog.rootwidget:UpdateClip()
end

--Update edit text fields in 'widget' using table "controlname=value,..."
function UpdateEditText(widget,controls)
    if (type(controls) ~= "table") then return end
    local tmp
    for key,value in pairs(controls) do
        tmp = widget.dialog.controls[key]
        tmp:SetText(value)
        --print("Key:", key, "Value:", value)   --debug
    end
end

-- ***** ***** ***** ***** ***** particles
gMyDebugParticleData = {
    {"Large Fireball"       , "../data/particles/particles/fireballs.particle"},
    {"Magic Arrow"          , "../data/particles/particles/fireballs.particle"},
    {"EBolt"                , "../data/particles/particles/fireballs.particle"},
    {"ConsecrateWeapon1"    , "../data/particles/particles/ConsecrateWeapon.particle"},
    {"ConsecrateWeapon2"    , "../data/particles/particles/ConsecrateWeapon.particle"},
    {"StranglePart1"        , "../data/particles/particles/Strangle.particle"},
    {"StranglePart2"        , "../data/particles/particles/Strangle.particle"},
    {"Teleport"             , "../data/particles/particles/healing.particle"},
    {"FlameStrike"          , "../data/particles/particles/healing.particle"},
    {"Healing"              , "../data/particles/particles/healing.particle"},
    {"ParalyzeField"        , "../data/particles/particles/Fields.particle"},
    {"PoisonField"          , "../data/particles/particles/Fields.particle"},
    {"FireField"            , "../data/particles/particles/Fields.particle"},
    {"Moongate"             , "../data/particles/particles/Fields.particle"},
    {"bluering"             , "../data/particles/particles/rings.particle"},
    {"Wither"               , "../data/particles/particles/Wither.particle"},
    {"PainSpike"            , "../data/particles/particles/PainSpike.particle"},
    {"PoisonStrike"         , "../data/particles/particles/PoisonStrike.particle"},
    {"Explosion"            , "../data/particles/particles/explosions.particle"},
    {"MindRot"              , "../data/particles/particles/MindRot.particle"},
}

function MyStartParticleDebugMode (data) -- -dparticle data
    gParticleDebugModeStarted = true
    -- gCurDebugMode = kDebugMode_Particle
    MyParticleDebugMode_SetIndex(tonumber(data) or 1)
    GuiAddChatLine("particle debug, f5 to reload, f2,f3 to change system")
end

function MyParticleDebugMode_Init2 ()
    if (gParticleDebugModeStarted and gDebugMenuToolboxDialog) then gDebugMenuToolboxDialog:Destroy() gDebugMenuToolboxDialog = nil end
end

function MyParticleDebugMode_SetIndex (index)
    gMyDebugParticles_CurIndex = index
    gMyDebugParticles_CurName = (gMyDebugParticleData[gMyDebugParticles_CurIndex] or {})[1]
    gMyDebugParticles_CurPath = (gMyDebugParticleData[gMyDebugParticles_CurIndex] or {})[2]
    print("############ particle ",gMyDebugParticles_CurIndex,gMyDebugParticles_CurName)
    GuiAddChatLine(sprintf("particle %d %s %s",gMyDebugParticles_CurIndex or -1,gMyDebugParticles_CurName or "",gMyDebugParticles_CurPath or ""))
    MyReloadParticleDebugMode()
end

function MyParticleDebugMode_Prev() MyParticleDebugMode_SetIndex(gMyDebugParticles_CurIndex - 1) end -- f2
function MyParticleDebugMode_Next() MyParticleDebugMode_SetIndex(gMyDebugParticles_CurIndex + 1) end -- f3

function MyReloadParticleDebugMode ()  -- bound to f5
	if (not gParticleDebugModeStarted) then MyStartParticleDebugMode() end
    if (gMyParticleDebugGfx) then gMyParticleDebugGfx:Destroy() gMyParticleDebugGfx = nil end
    if (not gMyDebugParticles_CurName) then return end
    ReloadParticleTemplate(gMyDebugParticles_CurName,gMyDebugParticles_CurPath)
    local gfx = CreateRootGfx3D()
    gMyParticleDebugGfx = gfx
    gfx:SetParticleSystem(gMyDebugParticles_CurName)
    gfx:SetRenderingDistance(1000)
    gfx:SetScale(1,1,1)
    gfx:SetNormaliseNormals(true)
    gfx:SetPosition(-1,1,0)
end
-- ***** ***** ***** ***** ***** end
