-- Functions in this file are retained purely for backwards-compatibility. They should not be used in new code and might be removed at any time.

e2function string number:teamName()
	local str = team.GetName(this)
	if not str then return "" end
	return str
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
	self.entity:SetColor(math.Clamp(r, 0, 255), math.Clamp(g, 0, 255), math.Clamp(b, 0, 255), 255)
end

__e2setcost(30) -- temporary

e2function void applyForce(vector force)
	local phys = self.entity:GetPhysicsObject()
	phys:ApplyForceCenter(Vector(force[1],force[2],force[3]))
end

e2function void applyOffsetForce(vector force, vector position)
	local phys = self.entity:GetPhysicsObject()
	phys:ApplyForceOffset(Vector(force[1],force[2],force[3]), Vector(position[1],position[2],position[3]))
end

e2function void applyAngForce(angle angForce)

	local ent = self.entity
	local phys = ent:GetPhysicsObject()
	if not phys:IsValid() then return end

	-- assign vectors
	local pos = ent:LocalToWorld(phys:GetMassCenter())
	local up = ent:GetUp()
	local left = ent:GetRight() * -1
	local forward = ent:GetForward()

	local pitch = up      * (angForce[1]*0.5)
	local yaw   = forward * (angForce[2]*0.5)
	local roll  = left    * (angForce[3]*0.5)

	-- apply pitch force
	phys:ApplyForceOffset( forward, pos + pitch )
	phys:ApplyForceOffset( forward * -1, pos - pitch )

	-- apply yaw force
	phys:ApplyForceOffset( left, pos + yaw )
	phys:ApplyForceOffset( left * -1, pos - yaw )

	-- apply roll force
	phys:ApplyForceOffset( up, pos + roll )
	phys:ApplyForceOffset( up * -1, pos - roll )
end
