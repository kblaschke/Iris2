-- concrete particle effect definitions, see also lib.particle.lua for system

cParticleFX = CreateClass()
function cParticleFX:Init()
	self.t_birth = gMyTicks
	gParticleFXStepper[self] = true
end

-- ***** cParticleFX_Wither

cParticleFX_Wither = CreateClass(cParticleFX)

function cParticleFX_Wither:Init()
	self.wave = cParticleFX_Wave:New({	lifet=1000,
										rings=11,
										sections=11,
										GetPos=function (x,t)
											local w = t*5
											local h = 0.5*(1-x)*sin((x+t*2)*5*kPi)
											local r,g,b,a = 0,0,1,0.5
											return w,h,r,g,b,a
										end,
									})
end

-- ***** cParticleFX_Wave

cParticleFX_Wave = CreateClass(cParticleFX)

function cParticleFX_Wave:Init(params)
	self.params = params
end

function cParticleFX_Wave:Step()	
	local t = (gMyTicks - self.t_birth) / self.params.lifet
	local rings		= self.params.rings
	local sections	= self.params.sections
	local GetPos	= self.params.GetPos
	local secmult = 2*kPi/sections
	function MyVertex (x,y,z,r,g,b,a) end -- todo : write/update vertex data
	for ir=0,rings do
		local w,h,r,g,b,a = GetPos(ir / rings,t)
		for is=1,sections do
			local ang = is*secmult
			MyVertex(w*sin(ang),w*cos(ang),h,r,g,b,a)
		end
	end
end
