-- high gfx-profile has medium settings with fixed function shadow technique

gConfig:Set("gAtlasRes","med")

gConfig:Set("gShadowTechnique","texture_additive")
gConfig:Set("gStaticsCastShadows",true)
gConfig:Set("gDynamicsCastShadows",true)
gConfig:Set("gMobileCastShadows",true)
