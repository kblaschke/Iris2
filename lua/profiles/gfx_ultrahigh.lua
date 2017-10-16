-- ultrahigh gfx-profile uses no textureatlas
-- SSAO + Depthshadowmapping needs to be actived, otherwise you will see no shadows !!!

gConfig:Set("gAtlasRes","none")

gConfig:Set("gShadowTechnique","texture_additive_integrated")
gConfig:Set("gStaticsCastShadows",true)
gConfig:Set("gDynamicsCastShadows",true)
gConfig:Set("gMobileCastShadows",true)
	
gConfig:Set("gArtMapLoaderType","FullFile")
