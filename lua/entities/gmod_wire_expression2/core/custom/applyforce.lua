
__e2setcost(30) -- temporary

local check = WireLib.checkForce

e2function void applyForce(vector force)
if not check(force) then return end
	local phys = self.entity:GetPhysicsObject()
	phys:ApplyForceCenter(Vector(force[1],force[2],force[3]))
end

e2function void applyOffsetForce(vector force, vector position)
	if not check(force) or not check(position) then return end
	local phys = self.entity:GetPhysicsObject()
	phys:ApplyForceOffset(Vector(force[1],force[2],force[3]), Vector(position[1],position[2],position[3]))
end

e2function void applyAngForce(angle angForce)
	if angForce[1] == 0 and angForce[2] == 0 and angForce[3] == 0 then return end
	if not check(angForce) then return end

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
	if not check( torque ) then return end

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

	if not check( dir ) or not check( off ) then return end
	phys:ApplyForceOffset( dir, off )
	phys:ApplyForceOffset( dir * -1, off * -1 )
end
