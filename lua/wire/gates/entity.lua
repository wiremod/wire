--[[
	Entity gates
]]

GateActions("Entity")

local function checkv( v )
	return 	-math.huge < v.x and v.x < math.huge and
			-math.huge < v.y and v.y < math.huge and
			-math.huge < v.z and v.z < math.huge
end

local function checka( v )
	return 	-math.huge < v.p and v.p < math.huge and
			-math.huge < v.y and v.y < math.huge and
			-math.huge < v.r and v.r < math.huge
end

GateActions["entity_applyf"] = {
	name = "Apply Force",
	inputs = { "Ent" , "Vec" },
	inputtypes = { "ENTITY" , "VECTOR" },
	timed = true,
	output = function(gate, Ent , Vec )
		if !Ent then return end
		if !Ent:IsValid() or !Ent:GetPhysicsObject():IsValid() then return end
		if not E2Lib.isOwner(gate, Ent) then return end
		if !isvector(Vec) then Vec = Vector(0, 0, 0) end
		if checkv(Vec) then
			Ent:GetPhysicsObject():ApplyForceCenter(Vec)
		end
	end,
	label = function()
		return ""
	end
}

GateActions["entity_applyof"] = {
	name = "Apply Offset Force",
	inputs = { "Ent" , "Vec" , "Offset" },
	inputtypes = { "ENTITY" , "VECTOR" , "VECTOR" },
	timed = true,
	output = function(gate, Ent , Vec , Offset )
		if !Ent then return end
		if !Ent:IsValid() or !Ent:GetPhysicsObject():IsValid() then return end
		if not E2Lib.isOwner(gate, Ent) then return end
		if !isvector(Vec) then Vec = Vector (0, 0, 0) end
		if !isvector(Offset) then Offset = Vector (0, 0, 0) end
		if checkv(Vec) and checkv(Offset) then
			Ent:GetPhysicsObject():ApplyForceOffset(Vec, Offset)
		end
	end,
	label = function()
		return ""
	end
}

-- Base code taken from Expression 2

GateActions["entity_applyaf"] = {
	name = "Apply Angular Force",
	inputs = { "Ent" , "Ang" },
	inputtypes = { "ENTITY" , "ANGLE" },
	timed = true,
	output = function(gate, Ent , angForce )
		if !Ent then return end
		if !Ent:IsValid() or !Ent:GetPhysicsObject():IsValid() then return end
		if not E2Lib.isOwner(gate, Ent) then return end

		if angForce.p == 0 and angForce.y == 0 and angForce.r == 0 then return end
		if not checka(angForce) then return end

		local phys = Ent:GetPhysicsObject()

		-- assign vectors
		local up = Ent:GetUp()
		local left = Ent:GetRight() * -1
		local forward = Ent:GetForward()

		-- apply pitch force
		if angForce.p ~= 0 then
			local pitch = up      * (angForce.p * 0.5)
			phys:ApplyForceOffset( forward, pitch )
			phys:ApplyForceOffset( forward * -1, pitch * -1 )
		end

		-- apply yaw force
		if angForce.y ~= 0 then
			local yaw   = forward * (angForce.y * 0.5)
			phys:ApplyForceOffset( left, yaw )
			phys:ApplyForceOffset( left * -1, yaw * -1 )
		end

		-- apply roll force
		if angForce.r ~= 0 then
			local roll  = left    * (angForce.r * 0.5)
			phys:ApplyForceOffset( up, roll )
			phys:ApplyForceOffset( up * -1, roll * -1 )
		end

	end,
	label = function()
		return ""
	end
}


-- Taken from Expression 2
local abs = math.abs
GateActions["entity_applytorq"] = {
	name = "Apply Torque",
	inputs = { "Ent" , "Vec" },
	inputtypes = { "ENTITY" , "VECTOR" },
	timed = true,
	output = function(gate, Ent , Vec )
		if !Ent then return end
		if not Ent:IsValid() then return end
		if not E2Lib.isOwner(gate, Ent) then return end

		if Vec.x == 0 and Vec.y == 0 and Vec.z == 0 then return end
		if not checkv(Vec) then return end

		local phys = Ent:GetPhysicsObject()
		if not phys:IsValid() then return end

		local tq = Vec
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

		if not checkv( dir ) or not checkv( off ) then return end
		phys:ApplyForceOffset( dir, off )
		phys:ApplyForceOffset( dir * -1, off * -1 )
	end,
	label = function()
		return ""
	end
}



GateActions["entity_class"] = {
	name = "Class",
	inputs = { "Ent" },
	inputtypes = { "ENTITY" },
	outputtypes = { "STRING" },
	output = function(gate, Ent)
		if !Ent:IsValid() then return "" else return Ent:GetClass() end
	end,
	label = function(Out)
		return string.format ("Class = %q", Out)
	end
}

GateActions["entity_entid"] = {
	name = "Entity ID",
	inputs = { "A" },
	inputtypes = { "ENTITY" },
	output = function(gate, A)
		if (A and A:IsValid()) then return A:EntIndex() end
		return 0
	end,
	label = function(Out, A)
		return string.format ("entID(%s) = %d", A, Out)
	end
}

GateActions["entity_id2ent"] = {
	name = "ID to Entity",
	inputs = { "A" },
	outputtypes = { "ENTITY" },
	output = function(gate, A)
		local Ent = Entity(A)
		if !Ent:IsValid() then return NULL end
		return Ent
	end,
	label = function(Out, A)
		return string.format ("Entity(%s) = %s", A, tostring(Out))
	end
}


GateActions["entity_model"] = {
	name = "Model",
	inputs = { "Ent" },
	inputtypes = { "ENTITY" },
	outputtypes = { "STRING" },
	output = function(gate, Ent)
		if !Ent:IsValid() then return "" else return Ent:GetModel() end
	end,
	label = function(Out)
		return string.format ("Model = %q", Out)
	end
}

GateActions["entity_steamid"] = {
	name = "SteamID",
	inputs = { "Ent" },
	inputtypes = { "ENTITY" },
	outputtypes = { "STRING" },
	output = function(gate, Ent)
		if !Ent:IsValid() or !Ent:IsPlayer() then return "" else return Ent:SteamID() end
	end,
	label = function(Out)
		return string.format ("SteamID = %q", Out)
	end
}

GateActions["entity_pos"] = {
	name = "Position",
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

GateActions["entity_fruvecs"] = {
	name = "Direction - (forward, right, up)",
	inputs = { "Ent" },
	inputtypes = { "ENTITY" },
	outputs = { "Forward", "Right" , "Up" },
	outputtypes = { "VECTOR" , "VECTOR" , "VECTOR" },
	timed = true,
	output = function(gate, Ent)
		if !Ent:IsValid() then return Vector(0,0,0) , Vector(0,0,0) , Vector(0,0,0) else return Ent:GetForward() , Ent:GetRight() , Ent:GetUp() end
	end,
	label = function(Out)
		return string.format ("Forward = (%f , %f , %f)\nUp = (%f , %f , %f)\nRight = (%f , %f , %f)", Out.Forward.x , Out.Forward.y , Out.Forward.z, Out.Up.x , Out.Up.y , Out.Up.z, Out.Right.x , Out.Right.y , Out.Right.z)
	end
}

GateActions["entity_isvalid"] = {
	name = "Is Valid",
	inputs = { "A" },
	inputtypes = { "ENTITY" },
	timed = true,
	output = function(gate, A)
		if (A and IsEntity (A) and A:IsValid ()) then
			return 1
		end
		return 0
	end,
	label = function(Out, A)
		return string.format ("isValid(%s) = %s", A, Out)
	end
}

GateActions["entity_vell"] = {
	name = "Velocity (local)",
	inputs = { "Ent" },
	inputtypes = { "ENTITY" },
	outputtypes = { "VECTOR" },
	timed = true,
	output = function(gate, Ent)
		if !Ent:IsValid() then return Vector(0,0,0) else return Ent:WorldToLocal(Ent:GetVelocity() + Ent:GetPos()) end
	end,
	label = function(Out)
		return string.format ("Velocity (local) = (%f , %f , %f)", Out.x , Out.y , Out.z )
	end
}

GateActions["entity_vel"] = {
	name = "Velocity",
	inputs = { "Ent" },
	inputtypes = { "ENTITY" },
	outputtypes = { "VECTOR" },
	timed = true,
	output = function(gate, Ent)
		if !Ent:IsValid() then return Vector(0,0,0) else return Ent:GetVelocity() end
	end,
	label = function(Out)
		return string.format ("Velocity = (%f , %f , %f)", Out.x , Out.y , Out.z )
	end
}

GateActions["entity_angvel"] = {
	name = "Angular Velocity",
	inputs = { "Ent" },
	inputtypes = { "ENTITY" },
	outputtypes = { "ANGLE" },
	timed = true,
	output = function(gate, Ent)
		local Vec
		if !Ent:IsValid() or !Ent:GetPhysicsObject():IsValid() then Vec = Vector(0,0,0) else Vec = Ent:GetPhysicsObject():GetAngleVelocity() end
		return Angle(Vec.y, Vec.z, Vec.x)
	end,
	label = function(Out)
		return string.format ("Angular Velocity = (%f , %f , %f)", Out.p , Out.y , Out.r )
	end
}

GateActions["entity_angvelvec"] = {
	name = "Angular Velocity (vector)",
	inputs = { "Ent" },
	inputtypes = { "ENTITY" },
	outputtypes = { "VECTOR" },
	timed = true,
	output = function(gate, Ent)
		if not Ent:IsValid() then return Vector(0,0,0) end
		local phys = Ent:GetPhysicsObject()
		if not phys:IsValid() then return Vector( 0, 0, 0 ) end
		return phys:GetAngleVelocity()
	end,
	label = function(Out)
		return string.format ("Angular Velocity = (%f , %f , %f)", Out.x , Out.y , Out.z )
	end
}

GateActions["entity_wor2loc"] = {
	name = "World To Local (vector)",
	inputs = { "Ent" , "Vec" },
	inputtypes = { "ENTITY" , "VECTOR" },
	outputtypes = { "VECTOR" },
	timed = true,
	output = function(gate, Ent , Vec )
		if Ent:IsValid() and isvector(Vec) then return Ent:WorldToLocal(Vec) else return Vector(0,0,0) end
	end,
	label = function(Out)
		return string.format ("World To Local = (%f , %f , %f)", Out.x , Out.y , Out.z )
	end
}

GateActions["entity_loc2wor"] = {
	name = "Local To World (Vector)",
	inputs = { "Ent" , "Vec" },
	inputtypes = { "ENTITY" , "VECTOR" },
	outputtypes = { "VECTOR" },
	timed = true,
	output = function(gate, Ent , Vec )
		if Ent:IsValid() and isvector(Vec) then return Ent:LocalToWorld(Vec) else return Vector(0,0,0) end
	end,
	label = function(Out)
		return string.format ("Local To World Vector = (%f , %f , %f)", Out.x , Out.y , Out.z )
	end
}

GateActions["entity_wor2loc"] = {
	name = "World To Local (Vector)",
	inputs = { "Ent" , "Vec" },
	inputtypes = { "ENTITY" , "VECTOR" },
	outputtypes = { "VECTOR" },
	timed = true,
	output = function(gate, Ent , Vec )
		if Ent:IsValid() and isvector(Vec) then return Ent:WorldToLocal(Vec) else return Vector(0,0,0) end
	end,
	label = function(Out)
		return string.format ("World To Local Vector = (%f , %f , %f)", Out.x , Out.y , Out.z )
	end
}

GateActions["entity_loc2worang"] = {
	name = "Local To World (Angle)",
	inputs = { "Ent" , "Ang" },
	inputtypes = { "ENTITY" , "ANGLE" },
	outputtypes = { "ANGLE" },
	timed = true,
	output = function(gate, Ent , Ang )
		if Ent:IsValid() and Ang then return Ent:LocalToWorldAngles(Ang) else return Angle(0,0,0) end
	end,
	label = function(Out)
		return string.format ("Local To World Angles = (%d,%d,%d)", Out.p , Out.y , Out.r )
	end
}

GateActions["entity_wor2locang"] = {
	name = "World To Local (Angle)",
	inputs = { "Ent" , "Ang" },
	inputtypes = { "ENTITY" , "ANGLE" },
	outputtypes = { "ANGLE" },
	timed = true,
	output = function(gate, Ent , Ang )
		if Ent:IsValid() and Ang then return Ent:WorldToLocalAngles(Ang) else return Angle(0,0,0) end
	end,
	label = function(Out)
		return string.format ("World To Local Angles = (%d,%d,%d)", Out.p , Out.y , Out.r )
	end
}

GateActions["entity_health"] = {
	name = "Health",
	inputs = { "Ent" },
	inputtypes = { "ENTITY" },
	outputtypes = { "NORMAL" },
	timed = true,
	output = function(gate, Ent)
		if !Ent:IsValid() then return 0 else return Ent:Health() end
	end,
	label = function(Out)
		return string.format ("Health = %d", Out)
	end
}

GateActions["entity_radius"] = {
	name = "Radius",
	inputs = { "Ent" },
	inputtypes = { "ENTITY" },
	outputtypes = { "NORMAL" },
	timed = true,
	output = function(gate, Ent)
		if !Ent:IsValid() then return 0 else return Ent:BoundingRadius() end
	end,
	label = function(Out)
		return string.format ("Radius = %d", Out)
	end
}

GateActions["entity_mass"] = {
	name = "Mass",
	inputs = { "Ent" },
	inputtypes = { "ENTITY" },
	outputtypes = { "NORMAL" },
	timed = true,
	output = function(gate, Ent)
		if !Ent:IsValid() or !Ent:GetPhysicsObject():IsValid() then return 0 else return Ent:GetPhysicsObject():GetMass() end
	end,
	label = function(Out)
		return string.format ("Mass = %d", Out)
	end
}

GateActions["entity_masscenter"] = {
	name = "Mass Center",
	inputs = { "Ent" },
	inputtypes = { "ENTITY" },
	outputtypes = { "VECTOR" },
	timed = true,
	output = function(gate, Ent)
		if !Ent:IsValid() or !Ent:GetPhysicsObject():IsValid() then return Vector(0,0,0) else return Ent:LocalToWorld(Ent:GetPhysicsObject():GetMassCenter()) end
	end,
	label = function(Out)
		return string.format ("Mass Center = (%d,%d,%d)", Out.x , Out.y , Out.z)
	end
}

GateActions["entity_masscenterlocal"] = {
	name = "Mass Center (local)",
	inputs = { "Ent" },
	inputtypes = { "ENTITY" },
	outputtypes = { "VECTOR" },
	timed = true,
	output = function(gate, Ent)
		if !Ent:IsValid() or !Ent:GetPhysicsObject():IsValid() then return Vector(0,0,0) else return Ent:GetPhysicsObject():GetMassCenter() end
	end,
	label = function(Out)
		return string.format ("Mass Center (local) = (%d,%d,%d)", Out.x , Out.y , Out.z)
	end
}

GateActions["entity_isplayer"] = {
	name = "Is Player",
	inputs = { "Ent" },
	inputtypes = { "ENTITY" },
	outputtypes = { "NORMAL" },
	timed = true,
	output = function(gate, Ent)
		if !Ent:IsValid() then return 0 end
		if Ent:IsPlayer() then return 1 else return 0 end
	end,
	label = function(Out)
		return string.format ("Is Player = %d", Out)
	end
}

GateActions["entity_isnpc"] = {
	name = "Is NPC",
	inputs = { "Ent" },
	inputtypes = { "ENTITY" },
	outputtypes = { "NORMAL" },
	timed = true,
	output = function(gate, Ent)
		if !Ent:IsValid() then return 0 end
		if Ent:IsNPC() then return 1 else return 0 end
	end,
	label = function(Out)
		return string.format ("Is NPC = %d", Out)
	end
}

GateActions["entity_isvehicle"] = {
	name = "Is Vehicle",
	inputs = { "Ent" },
	inputtypes = { "ENTITY" },
	outputtypes = { "NORMAL" },
	timed = true,
	output = function(gate, Ent)
		if !Ent:IsValid() then return 0 end
		if Ent:IsVehicle() then return 1 else return 0 end
	end,
	label = function(Out)
		return string.format ("Is Vehicle = %d", Out)
	end
}

GateActions["entity_isworld"] = {
	name = "Is World",
	inputs = { "Ent" },
	inputtypes = { "ENTITY" },
	outputtypes = { "NORMAL" },
	timed = true,
	output = function(gate, Ent)
		if !Ent:IsValid() then return 0 end
		if Ent:IsWorld() then return 1 else return 0 end
	end,
	label = function(Out)
		return string.format ("Is World = %d", Out)
	end
}

GateActions["entity_isongrnd"] = {
	name = "Is On Ground",
	inputs = { "Ent" },
	inputtypes = { "ENTITY" },
	outputtypes = { "NORMAL" },
	timed = true,
	output = function(gate, Ent)
		if !Ent:IsValid() then return 0 end
		if Ent:IsOnGround() then return 1 else return 0 end
	end,
	label = function(Out)
		return string.format ("Is On Ground = %d", Out)
	end
}

GateActions["entity_isunderwater"] = {
	name = "Is Under Water",
	inputs = { "Ent" },
	inputtypes = { "ENTITY" },
	outputtypes = { "NORMAL" },
	timed = true,
	output = function(gate, Ent)
		if !Ent:IsValid() then return 0 end
		if Ent:WaterLevel() > 0 then return 1 else return 0 end
	end,
	label = function(Out)
		return string.format ("Is Under Water = %d", Out)
	end
}

GateActions["entity_angles"] = {
	name = "Angles",
	inputs = { "Ent" },
	inputtypes = { "ENTITY" },
	outputtypes = { "ANGLE" },
	timed = true,
	output = function(gate, Ent)
		if !Ent:IsValid() then return Angle(0,0,0) else return Ent:GetAngles() end
	end,
	label = function(Out)
		return string.format ("Angles = (%d,%d,%d)", Out.p , Out.y , Out.r)
	end
}

GateActions["entity_material"] = {
	name = "Material",
	inputs = { "Ent" },
	inputtypes = { "ENTITY" },
	outputtypes = { "STRING" },
	timed = true,
	output = function(gate, Ent)
		if !Ent:IsValid() then return "" else return Ent:GetMaterial() end
	end,
	label = function(Out)
		return string.format ("Material = %q", Out)
	end
}

GateActions["entity_owner"] = {
	name = "Owner",
	inputs = { "Ent" },
	inputtypes = { "ENTITY" },
	outputtypes = { "ENTITY" },
	timed = true,
	output = function(gate, Ent)
		if !Ent:IsValid() then return E2Lib.getOwner(gate,gate)	 end
		return E2Lib.getOwner(gate,Ent)
	end,
	label = function(Out,Ent)
		return string.format ("owner(%s) = %s", Ent, tostring(Out))
	end
}

GateActions["entity_isheld"] = {
	name = "Is Player Holding",
	inputs = { "Ent" },
	inputtypes = { "ENTITY" },
	outputtypes = { "NORMAL" },
	timed = true,
	output = function(gate, Ent)
		if !Ent:IsValid() then return 0 end
		if Ent:IsPlayerHolding() then return 1 else return 0 end
	end,
	label = function(Out)
		return string.format ("Is Player Holding = %d", Out)
	end
}

GateActions["entity_isonfire"] = {
	name = "Is On Fire",
	inputs = { "Ent" },
	inputtypes = { "ENTITY" },
	outputtypes = { "NORMAL" },
	timed = true,
	output = function(gate, Ent)
		if !Ent:IsValid() then return 0 end
		if Ent:IsOnFire()then return 1 else return 0 end
	end,
	label = function(Out)
		return string.format ("Is On Fire = %d", Out)
	end
}

GateActions["entity_isweapon"] = {
	name = "Is Weapon",
	inputs = { "Ent" },
	inputtypes = { "ENTITY" },
	outputtypes = { "NORMAL" },
	timed = true,
	output = function(gate, Ent)
		if !Ent:IsValid() then return 0 end
		if Ent:IsWeapon() then return 1 else return 0 end
	end,
	label = function(Out)
		return string.format ("Is Weapon = %d", Out)
	end
}

GateActions["player_invehicle"] = {
	name = "Is In Vehicle",
	inputs = { "Ent" },
	inputtypes = { "ENTITY" },
	outputtypes = { "NORMAL" },
	timed = true,
	output = function(gate, Ent)
		if !Ent:IsValid() then return 0 end
		if Ent:IsPlayer() and Ent:InVehicle() then return 1 else return 0 end
	end,
	label = function(Out)
		return string.format ("Is In Vehicle = %d", Out)
	end
}

GateActions["player_connected"] = {
	name = "Time Connected",
	inputs = { "Ent" },
	inputtypes = { "ENTITY" },
	outputtypes = { "NORMAL" },
	timed = true,
	output = function(gate, Ent)
		if !Ent:IsValid() then return 0 end
		if Ent:IsPlayer() then return Ent:TimeConnected() else return 0 end
	end,
	label = function(Out)
		return string.format ("Time Connected = %d", Out)
	end
}
GateActions["entity_aimentity"] = {
	name = "AimEntity",
	inputs = { "Ent" },
	inputtypes = { "ENTITY" },
	outputtypes = { "ENTITY" },
	timed = true,
	output = function(gate, Ent)
		if !Ent:IsValid() then return NULL end
		local EntR = Ent:GetEyeTraceNoCursor().Entity
		if !EntR:IsValid() then return NULL end
		return EntR
	end,
	label = function(Out)
		return string.format ("Aim Entity = %s", tostring(Out))
	end
}

GateActions["entity_aimenormal"] = {
	name = "AimNormal",
	inputs = { "Ent" },
	inputtypes = { "ENTITY" },
	outputtypes = { "VECTOR" },
	timed = true,
	output = function(gate, Ent)
		if !Ent:IsValid() then return Vector(0,0,0) end
		if (Ent:IsPlayer()) then
			return Ent:GetAimVector()
		else
			return Ent:GetForward()
		end
	end,
	label = function(Out, A)
		return string.format ("Aim Normal (%s) = (%d,%d,%d)", A, Out.x, Out.y, Out.z)
	end
}

GateActions["entity_aimedirection"] = {
	name = "AimDirection",
	inputs = { "Ent" },
	inputtypes = { "ENTITY" },
	outputtypes = { "VECTOR" },
	timed = true,
	output = function(gate, Ent)
		if !Ent:IsValid() or !Ent:IsPlayer() then return Vector(0,0,0) end
		return Ent:GetEyeTraceNoCursor().Normal
	end,
	label = function(Out, A)
		return string.format ("Aim Direction (%s) = (%d,%d,%d)", A, Out.x, Out.y, Out.z)
	end
}

GateActions["entity_inertia"] = {
	name = "Inertia",
	inputs = { "Ent" },
	inputtypes = { "ENTITY" },
	outputtypes = { "VECTOR" },
	timed = true,
	output = function(gate, Ent)
		if !Ent:IsValid() or !Ent:GetPhysicsObject():IsValid() then return Vector(0,0,0) end
		return Ent:GetPhysicsObject():GetInertia()
	end,
	label = function(Out, A)
		return string.format ("inertia(%s) = (%d,%d,%d)", Ent, Out.x, Out.y, Out.z)
	end
}

GateActions["entity_setmass"] = {
	name = "Set Mass",
	inputs = { "Ent" , "Val" },
	inputtypes = { "ENTITY" , "NORMAL" },
	timed = true,
	output = function(gate, Ent, Val )
		if !Ent:IsValid() then return end
		if !Ent:GetPhysicsObject():IsValid() then return end
		if !(E2Lib.getOwner(gate, gate) == E2Lib.getOwner(gate, Ent)) then return end
		if !Val then Val = Ent:GetPhysicsObject():GetMass() end
		Val = math.Clamp(Val, 0.001, 50000)
		Ent:GetPhysicsObject():SetMass(Val)
	end,
	label = function(Out, Ent , Val)
		return string.format ("setMass(%s , %s)", Ent, Val)
	end
}

GateActions["entity_equal"] = {
	name = "Equal",
	inputs = { "A" , "B" },
	inputtypes = { "ENTITY" , "ENTITY" },
	output = function(gate, A, B )
		if A == B then return 1 else return 0 end
	end,
	label = function(Out, A , B)
		return string.format ("(%s  = =  %s) = %d", A, B, Out)
	end
}

GateActions["entity_inequal"] = {
	name = "Inequal",
	inputs = { "A" , "B" },
	inputtypes = { "ENTITY" , "ENTITY" },
	output = function(gate, A, B )
		if A ~= B then return 1 else return 0 end
	end,
	label = function(Out, A , B)
		return string.format ("(%s  ! =  %s) = %d", A, B, Out)
	end
}

GateActions["entity_setcol"] = {
	name = "Set Color",
	inputs = { "Ent" , "Col" },
	inputtypes = { "ENTITY" , "VECTOR" },
	timed = true,
	output = function(gate, Ent, Col )
		if !Ent:IsValid() then return end
		if !(E2Lib.getOwner(gate, gate) == E2Lib.getOwner(gate, Ent)) then return end
		if !isvector(Col) then Col = Vector(255,255,255) end
		Ent:SetColor(Color(Col.x,Col.y,Col.z,255))
	end,
	label = function(Out, Ent , Col)
		if !isvector(Col) then Col = Vector(0,0,0) end
		return string.format ("setColor(%s ,(%d,%d,%d) )", Ent , Col.x, Col.y, Col.z)
	end
}

GateActions["entity_driver"] = {
	name = "Driver",
	inputs = { "Ent" },
	inputtypes = { "ENTITY" },
	outputtypes = { "ENTITY" },
	timed = true,
	output = function(gate, Ent)
		if !Ent:IsValid() or !Ent:IsVehicle() then return NULL end
		return Ent:GetDriver()
	end,
	label = function(Out, A)
		local Name = "NULL"
		if Out:IsValid() then Name = Out:Nick() end
		return string.format ("Driver: %s", Name)
	end
}


GateActions["entity_clr"] = {
	name = "Color",
	inputs = { "Ent" },
	inputtypes = { "ENTITY" },
	outputtypes = { "VECTOR" },
	timed = true,
	output = function(gate, Ent)
		if !Ent:IsValid() then return Vector(0,0,0) end
		local c = Ent:GetColor()
		return Vector(c.r,c.g,c.b)
	end,
	label = function(Out, Ent)
		return string.format ("color(%s) = (%d,%d,%d)", Ent , Out.x, Out.y, Out.z)
	end
}



GateActions["entity_name"] = {
	name = "Name",
	inputs = { "Ent" },
	inputtypes = { "ENTITY" },
	outputtypes = { "STRING" },
	timed = true,
	output = function(gate, Ent)
		if !Ent:IsValid() or !Ent:IsPlayer() then return "" else return Ent:Nick() end
	end,
	label = function(Out, Ent)
		return string.format ("name(%s) = %s", Ent, Out)
	end
}

GateActions["entity_aimpos"] = {
	name = "AimPosition",
	inputs = { "Ent" },
	inputtypes = { "ENTITY" },
	outputtypes = { "VECTOR" },
	timed = true,
	output = function(gate, Ent)
		if !Ent:IsValid() or !Ent:IsPlayer() then return Vector(0,0,0) else return Ent:GetEyeTraceNoCursor().HitPos end
	end,
	label = function(Out)
		return string.format ("Aim Position = (%f , %f , %f)", Out.x , Out.y , Out.z)
	end
}

GateActions["entity_select"] = {
	name = "Select",
	inputs = { "Choice", "A", "B", "C", "D", "E", "F", "G", "H" },
	inputtypes = { "NORMAL", "ENTITY", "ENTITY", "ENTITY", "ENTITY", "ENTITY", "ENTITY", "ENTITY", "ENTITY" },
	outputtypes = { "ENTITY" },
	output = function(gate, Choice, ...)
		math.Clamp(Choice,1,8)
		return ({...})[Choice]
	end,
	label = function(Out, Choice)
	    return string.format ("select(%s) = %s", Choice, Out)
	end
}

-- Bearing and Elevation, copied from E2

GateActions["entity_bearing"] = {
	name = "Bearing",
	inputs = { "Entity", "Position" },
	inputtypes = { "ENTITY", "VECTOR", "NORMAL" },
	outputtypes = { "NORMAL" },
	timed = true,
	output = function( gate, Entity, Position )
		if (!Entity:IsValid()) then return 0 end
		Position = Entity:WorldToLocal(Position)
		return 180 / math.pi * math.atan2( Position.y, Position.x )
	end,
	label = function( Out, Entity, Position )
		return Entity .. ":Bearing(" .. Position .. ") = " .. Out
	end
}

GateActions["entity_elevation"] = {
	name = "Elevation",
	inputs = { "Entity", "Position" },
	inputtypes = { "ENTITY", "VECTOR", "NORMAL" },
	outputtypes = { "NORMAL" },
	timed = true,
	output = function( gate, Entity, Position )
		if (!Entity:IsValid()) then return 0 end
		Position = Entity:WorldToLocal(Position)
		local len = Position:Length()
		return 180 / math.pi * math.asin(Position.z / len)
	end,
	label = function( Out, Entity, Position )
		return Entity .. ":Elevation(" .. Position .. ") = " .. Out
	end
}

GateActions["entity_heading"] = {
	name = "Heading",
	inputs = { "Entity", "Position" },
	inputtypes = { "ENTITY", "VECTOR", "NORMAL" },
	outputs = { "Bearing", "Elevation", "Heading" },
	outputtypes = { "NORMAL", "NORMAL", "ANGLE" },
	timed = true,
	output = function( gate, Entity, Position )
		if (!Entity:IsValid()) then return 0, 0, Angle(0,0,0) end
		Position = Entity:WorldToLocal(Position)

		-- Bearing
		local bearing = 180 / math.pi * math.atan2( Position.y, Position.x )

		-- Elevation
		local len = Position:Length()
		elevation = 180 / math.pi * math.asin( Position.z / len )

		return bearing, elevation, Angle(bearing,elevation,0)
	end,
	label = function( Out, Entity, Position )
		return Entity .. ":Heading(" .. Position .. ") = " .. tostring(Out.Heading)
	end
}

GateActions()
