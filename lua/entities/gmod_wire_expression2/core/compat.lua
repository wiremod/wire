-- Functions in this file are retained purely for backwards-compatibility. They should not be used in new code and might be removed at any time.

e2function string number:teamName()
	return team.GetName(this) or ""
end

e2function number number:teamScore()
	return team.GetScore(this)
end

e2function number number:teamPlayers()
	return team.NumPlayers(this)
end

e2function number number:teamDeaths()
	return team.TotalDeaths(this)
end

e2function number number:teamFrags()
	return team.TotalFrags(this)
end

e2function void setColor(r, g, b)
	self.entity:SetColor(Color(math.Clamp(r, 0, 255), math.Clamp(g, 0, 255), math.Clamp(b, 0, 255), 255))
end

__e2setcost(30) -- temporary

local clamp = WireLib.clampForce

e2function void applyForce(vector force)
	force = clamp(force)
	local phys = self.entity:GetPhysicsObject()
	phys:ApplyForceCenter(force)
end

e2function void applyOffsetForce(vector force, vector position)
	force 		= clamp(force)
	position 	= clamp(position)
	local phys = self.entity:GetPhysicsObject()
	phys:ApplyForceOffset(Vector(force[1],force[2],force[3]), Vector(position[1],position[2],position[3]))
end

e2function void applyAngForce(angle angForce)
	if angForce[1] == 0 and angForce[2] == 0 and angForce[3] == 0 then return end
	angForce = clamp(angForce)

	local ent = self.entity
	local phys = ent:GetPhysicsObject()

	-- assign vectors
	local up = ent:GetUp()
	local left = ent:GetRight() * -1
	local forward = ent:GetForward()

	-- apply pitch force
	if angForce[1] ~= 0 then
		local pitch = up      * (angForce[1] * 0.5)
		phys:ApplyForceOffset( forward, pitch )
		phys:ApplyForceOffset( forward * -1, pitch * -1 )
	end

	-- apply yaw force
	if angForce[2] ~= 0 then
		local yaw   = forward * (angForce[2] * 0.5)
		phys:ApplyForceOffset( left, yaw )
		phys:ApplyForceOffset( left * -1, yaw * -1 )
	end

	-- apply roll force
	if angForce[3] ~= 0 then
		local roll  = left    * (angForce[3] * 0.5)
		phys:ApplyForceOffset( up, roll )
		phys:ApplyForceOffset( up * -1, roll * -1 )
	end
end

e2function void applyTorque(vector torque)
	if torque[1] == 0 and torque[2] == 0 and torque[3] == 0 then return end
	torque = clamp(torque)

	local phys = self.entity:GetPhysicsObject()

	local tq = Vector(torque[1], torque[2], torque[3])
	local torqueamount = tq:Length()

	-- Convert torque from local to world axis
	tq = phys:LocalToWorld( tq ) - phys:GetPos()

	-- Find two vectors perpendicular to the torque axis
	local off
	if math.abs(tq.x) > torqueamount * 0.1 or math.abs(tq.z) > torqueamount * 0.1 then
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
end

__e2setcost(10)

e2function number entity:height()
	--[[	Old code (UGLYYYY)
	if(!IsValid(this)) then return 0 end
	if(this:IsPlayer() or this:IsNPC()) then
		local pos = this:GetPos()
		local up = this:GetUp()
		return this:NearestPoint(Vector(pos.x+up.x*100,pos.y+up.y*100,pos.z+up.z*100)).z-this:NearestPoint(Vector(pos.x-up.x*100,pos.y-up.y*100,pos.z-up.z*100)).z
	else return 0 end
	]]

	-- New code (Same as E:boxSize():z())
	if not IsValid(this) then return self:throw("Invalid entity!", 0) end
	return (this:OBBMaxs() - this:OBBMins()).z
end
