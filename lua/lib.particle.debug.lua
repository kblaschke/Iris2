--~ ./start.sh -sdp -res 640x480 
-- debugging particle effects, see lib.particle.lua and lib.particle.effects.lua

cDebugParticleMenu = CreateClass(cDebugMode)

function StartDebugParticleMenu () cDebugParticleMenu:StartMenu() end

function cDebugParticleMenu:StartMenu ()
	gCurrentRenderer = Renderer3D   
	
	self:MakeGrid({0,0,0},{1,0,0},{0,1,0},5,5,true)
	
	self:StartMainLoop()
end

