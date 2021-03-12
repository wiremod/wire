--[[
	Restricted	 gates
]]

GateActions("Restricted (Cant Be Used)")

local function isAllowed( gate, ent )
	if not IsValid(gate:GetPlayer()) then return false end
	return hook.Run( "PhysgunPickup", gate:GetPlayer(), ent ) ~= false
end

GateActions["entity_applyf"] = {
	name = "ENT:Apply Force",
	inputs = { "Ent" , "Vec" },
	inputtypes = { "ENTITY" , "VECTOR" },
	timed = true,
	output = function(gate, ent, vec )
		if not IsValid( ent ) then return end
		local phys = ent:GetPhysicsObject()
		if not IsValid( phys ) then return end
		if not isAllowed( gate, ent ) then return end
		if not hook.Run("PIXEL.Wiremod.CanUseGate", WireLib.GetOwner(gate), "entity_applyf") then return end 
		if !isvector(vec) then vec = Vector (0, 0, 0) end
		vec = clamp(vec)
		if vec.x == 0 and vec.y == 0 and vec.z == 0 then return end

		phys:ApplyForceCenter( vec )
	end,
	label = function(_,ent,vec)
		return string.format( "(%s):applyForce(%s)", ent, vec )
	end
}

GateActions["entity_applyof"] = {
	name = "ENT:Apply Offset Force",
	inputs = { "Ent" , "Vec" , "Offset" },
	inputtypes = { "ENTITY" , "VECTOR" , "VECTOR" },
	timed = true,
	output = function(gate, ent, vec, offset )
		if not IsValid( ent ) then return end
		local phys = ent:GetPhysicsObject()
		if not IsValid( phys ) then return end
		if not isAllowed( gate, ent ) then return end
		if not hook.Run("PIXEL.Wiremod.CanUseGate", WireLib.GetOwner(gate), "entity_applyof") then return end 
		if !isvector(vec) then vec = Vector (0, 0, 0) end
		if !isvector(offset) then offset = Vector (0, 0, 0) end
		vec = clamp(vec)
		offset = clamp(offset)
		if vec.x == 0 and vec.y == 0 and vec.z == 0 then return end

		phys:ApplyForceOffset(vec, offset)
	end,
	label = function(_,ent,vec,offset)
		return string.format( "(%s):applyForceOffset(%s,%s)", ent, vec, offset )
	end
}

GateActions["entity_applyaf"] = {
	name = "ENT:Apply Angular Force",
	inputs = { "Ent" , "Ang" },
	inputtypes = { "ENTITY" , "ANGLE" },
	timed = true,
	output = function(gate, ent, angForce )
		if not IsValid( ent ) then return end
		local phys = ent:GetPhysicsObject()
		if not IsValid( phys ) then return end
		if not isAllowed( gate, ent ) then return end
		if not hook.Run("PIXEL.Wiremod.CanUseGate", WireLib.GetOwner(gate), "entity_applyaf") then return end 
		local clampedForce = clamp(angForce)
		if clampedForce.x == 0 and clampedForce.y == 0 and clampedForce.z == 0 then return end

		-- assign vectors
		local up = ent:GetUp()
		local left = ent:GetRight() * -1
		local forward = ent:GetForward()

		-- apply pitch force
		if clampedForce.x ~= 0 then
			local pitch = up      * (clampedForce.x * 0.5)
			phys:ApplyForceOffset( forward, pitch )
			phys:ApplyForceOffset( forward * -1, pitch * -1 )
		end

		-- apply yaw force
		if clampedForce.y ~= 0 then
			local yaw   = forward * (clampedForce.y * 0.5)
			phys:ApplyForceOffset( left, yaw )
			phys:ApplyForceOffset( left * -1, yaw * -1 )
		end

		-- apply roll force
		if clampedForce.z ~= 0 then
			local roll  = left    * (clampedForce.z * 0.5)
			phys:ApplyForceOffset( up, roll )
			phys:ApplyForceOffset( up * -1, roll * -1 )
		end
	end,
	label = function(Out,ent,angForce)
		return string.format( "(%s):applyAngForce(%s)", ent, angForce )
	end
}

local abs = math.abs
GateActions["entity_applytorq"] = {
	name = "ENT:Apply Torque",
	inputs = { "Ent" , "Vec" },
	inputtypes = { "ENTITY" , "VECTOR" },
	timed = true,
	output = function(gate, ent, vec )
		if not IsValid( ent ) then return end
		local phys = ent:GetPhysicsObject()
		if not IsValid( phys ) then return end
		if not isAllowed( gate, ent ) then return end
		if not hook.Run("PIXEL.Wiremod.CanUseGate", WireLib.GetOwner(gate), "entity_applytorq") then return end 
		if !isvector(vec) then vec = Vector (0, 0, 0) end
		if !isvector(offset) then offset = Vector (0, 0, 0) end
		vec 	= clamp(vec)
		offset 	= clamp(offset)
		if vec.x == 0 and vec.y == 0 and vec.z == 0 then return end

		local tq = vec
		local torqueamount = tq:Length()

		-- Convert torque from local to world axis
		tq = phys:LocalToWorld( tq ) - phys:GetPos()

		-- Find two vectors perpendicular to the torque axis
		local off
		if abs(tq.x) > torqueamount * 0.1 or abs(tq.z) > torqueamount * 0.1 then
			off = Vector(-tq.z, 0, tq.x)
		else
			off = Vector(-tq.y, tq.x, 0)
		end
		off = off:GetNormal() * torqueamount * 0.5

		local dir = ( tq:Cross(off) ):GetNormal()

		dir = clamp(dir)
		off = clamp(off)
		phys:ApplyForceOffset( dir, off )
		phys:ApplyForceOffset( dir * -1, off * -1 )
	end,
	label = function(_,ent,vec)
		return string.format( "(%s):applyTorque(%s)", ent, vec )
	end
}

GateActions["entity_setmass"] = {
	name = "ENT:Set Mass",
	inputs = { "Ent" , "Val" },
	inputtypes = { "ENTITY" , "NORMAL" },
	output = function(gate, Ent, Val )
		if !Ent:IsValid() then return end
		if !Ent:GetPhysicsObject():IsValid() then return end
		if not gamemode.Call("CanTool", WireLib.GetOwner(gate), WireLib.dummytrace(Ent), "weight") then return end
		if not hook.Run("PIXEL.Wiremod.CanUseGate", WireLib.GetOwner(gate), "entity_setmass") then return end 
		if !Val then Val = Ent:GetPhysicsObject():GetMass() end
		Val = math.Clamp(Val, 0.001, 50000)
		Ent:GetPhysicsObject():SetMass(Val)
	end,
	label = function(Out, Ent , Val)
		return string.format ("setMass(%s , %s)", Ent, Val)
	end
}

GateActions["entity_setcol"] = { -- Since this doesnt allow you to set opacity (and it doesnt allow you to change the color of your local player) this should be kept
	name = "ENT:Set Color",
	inputs = { "Ent" , "Col" },
	inputtypes = { "ENTITY" , "VECTOR" },
	output = function(gate, Ent, Col )
		if !Ent:IsValid() then return end
		if not gamemode.Call("CanTool", WireLib.GetOwner(gate), WireLib.dummytrace(Ent), "color") then return end
		if !isvector(Col) then Col = Vector(255,255,255) end
		Ent:SetColor(Color(Col.x,Col.y,Col.z,255))
	end,
	label = function(Out, Ent , Col)
		if !isvector(Col) then Col = Vector(0,0,0) end
		return string.format ("setColor(%s ,(%d,%d,%d) )", Ent , Col.x, Col.y, Col.z)
	end
}

GateActions["entity_pos"] = {
	name = "ENT:Position",
	inputs = { "Ent" },
	inputtypes = { "ENTITY" },
	outputtypes = { "VECTOR" },
	timed = true,
	output = function(gate, Ent)
		if !Ent:IsValid() then return Vector(0,0,0) else return Ent:GetPos() end
	end,
	label = function(Out)
		return string.format ("Position = (%d,%d,%d)", Out.x , Out.y , Out.z )
	end
}

GateActions()
