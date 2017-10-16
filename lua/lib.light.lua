--[[ ***** see Iris2 COPYING for license info ***** ]]--
--[[ \brief
        light utils shared between renderers
        see also lib.3d.light.lua
]]--

function SetupWorldLight_Default ()
	if not(gUseCaelumSkysystem) then
		-- setup directional Sun Light
		if gSunLightDirection then
	        local xyz = gSunLightDirection      
	        gDirectionalLightSun = Client_AddDirectionalLight(xyz.x,xyz.y,xyz.z)
		        
	        local rgb = gSunLightDiffuse        
	        Client_SetLightDiffuseColor(gDirectionalLightSun,rgb.r,rgb.g,rgb.b)
		        
	        local rgb = gSunLightSpecular       
	        Client_SetLightSpecularColor(gDirectionalLightSun,rgb.r,rgb.g,rgb.b)
	    end

		-- setup ambient light
	    if gAmbientLight then
		    Client_SetAmbientLight(gAmbientLight.r, gAmbientLight.g, gAmbientLight.b, 1)
		end
	end
end
