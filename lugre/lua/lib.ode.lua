function InitOde (secondsByStep)
	print("InitOde")
	
	gOdeSecondsByStep = secondsByStep or 0.5
	
	gOdeWorld = OdeWorldCreate()
	gOdeSpace = OdeHashSpaceCreate(0)
	gOdeContactgroup = OdeJointGroupCreate(0)

	OdeWorldSetERP(gOdeWorld, 0.8)
	OdeWorldSetCFM(gOdeWorld, 1e-5)
	
	-- OdeWorldSetContactMaxCorrectingVel(gOdeWorld, 0.9)
	-- OdeWorldSetContactSurfaceLayer(gOdeWorld, 0.001)
		
	OdeWorldSetAutoDisableFlag(gOdeWorld,1)
	
	gOdeLastTimer = gMyTicks
end

-- fun : collision callback function
function StepOde ()
	local dt = gMyTicks - gOdeLastTimer
	local maxsteps = 1
	
	-- more than 1 step elapsed?
	if (dt > gOdeSecondsByStep) then
		-- how many steps?
		local steps = math.floor(dt / gOdeSecondsByStep)
		if steps > maxsteps then steps = maxsteps end
		
		-- calculate them
		for i = 1,steps do
			-- ode step
			-- Detect collision
			OdeSpaceCollide(gOdeSpace,function(o0,o1)
				-- gOdeWorld,gOdeContactgroup
				local b1 = OdeGeomGetBody(o0)
				local b2 = OdeGeomGetBody(o1)
			
				if b1 and b2 and OdeAreConnected(b1,b2) == 0 then
					local l = OdeCollide(o0, o1, 5)
					if l then 
						-- print("ODE COLLISION","b1",b1, "b2",b2, "o0",o0, "o1",o1)

						for k,v in pairs(l) do
							local posx,posy,posz,normalx,normaly,normalz,depth,g1,g2,side1,side2 = OdeGetContactGeom(v)
							
							MarkCollisionSpot(posx,posy,posz)
							
							local mode = OdeContactSlip1 + OdeContactSoftERP + OdeContactSoftCFM + OdeContactApprox1
							local mu = 0.5
							local mu2 = 0
							local bounce = 0
							local bounce_vel = 0
							local soft_erp = 0.3
							local soft_cfm = 0.1
							local motion1 = 0
							local motion2 = 0
							local slip1 = 0.1
							local slip2 = 0.1
							
							OdeSetContactSurface(v,mode,mu,mu2,bounce,bounce_vel,soft_erp,soft_cfm,motion1,motion2,slip1,slip2)
							-- print(v,":",OdeGetContactSurface(v))
							
							local c = OdeJointCreateContact(gOdeWorld, gOdeContactgroup, v)
							OdeJointAttach(c, b1, b2)
						end			
					end
				end
			end)
			
			-- Step world
			OdeWorldQuickStep(gOdeWorld, gOdeSecondsByStep)
			-- Remove all temporary collision joints now that the world has been stepped
			OdeJointGroupEmpty(gOdeContactgroup)
		end
		
		gOdeLastTimer = gOdeLastTimer + steps * gOdeSecondsByStep
	end
end

function DoneOde ()
	OdeSpaceDestroy(gOdeSpace)
	OdeWorldDestroy(gOdeWorld)
	OdeCloseODE()
end
