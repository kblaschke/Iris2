--[[ ***** see Iris2 COPYING for license info ***** ]]--
--[[ \brief
        boat functions
]]--

function CheckIfBoat(artid)
    if ( (artid >= hex2num("0x4000")) and (artid < hex2num("0x4022")) ) then
        return gBoats[artid]
    else
        return artid
    end
end

--[[
15946, 15947, 15948, 15949, 15950, 15951, 15952, 15953, 15954
15955, 15956, 15957 - tiller man

16004, 16005, 16006, 16007, 16009, 16050, 16083 - gang planks
16084, 16085

16010, 16049        - ship

16386           - multi ship

Fallback: Dynamic created : artID = 15947   - tiller man
Fallback: Dynamic created : artID = 16049   - ship
Fallback: Dynamic created : artID = 16050   - plank
Fallback: Dynamic created : artID = 16057   - hatch


Renderer3D:AddDynamicItem: multi id   2       parts   38
part    0       :       16098   365     1148    -120    0   - mast
part    1       :       15947   365     1144    -120    0   - tillerman
part    2       :       16057   365     1152    -120    0   - hatch
part    3       :       16049   363     1148    -120    0   - ship
part    4       :       16050   367     1148    -120    0   - plank
part    5       :       16044   366     1148    -120    1
part    6       :       16044   366     1147    -120    1
part    7       :       16044   366     1149    -120    1
part    8       :       16044   365     1149    -120    1
part    9       :       16044   365     1147    -120    1
part    10      :       16097   364     1149    -120    1
part    11      :       16033   364     1147    -120    1
part    12      :       16033   364     1148    -120    1
part    13      :       16033   364     1149    -120    1
part    14      :       16049   363     1149    -120    1   - ship
part    15      :       16049   363     1147    -120    1   - ship
part    16      :       16032   366     1146    -120    1
part    17      :       16031   364     1146    -120    1
part    18      :       16044   365     1146    -120    1
part    19      :       16099   367     1148    -120    1
part    20      :       16102   367     1147    -120    1
part    21      :       16050   367     1149    -120    1   - plank
part    22      :       16038   366     1150    -120    1
part    23      :       16044   365     1150    -120    1
part    24      :       16037   364     1150    -120    1
part    25      :       16045   365     1145    -120    1
part    26      :       16029   364     1145    -120    1
part    27      :       16030   366     1145    -120    1
part    28      :       16096   363     1150    -120    1
part    29      :       16040   366     1151    -120    1
part    30      :       16039   364     1151    -120    1
part    31      :       16044   365     1151    -120    1
part    32      :       16054   364     1152    -120    1
part    33      :       16053   366     1152    -120    1
part    34      :       16027   364     1144    -120    1
part    35      :       16028   366     1144    -120    1
part    36      :       16052   365     1153    -120    1
part    37      :       16068   365     1143    -120    1
]]--
