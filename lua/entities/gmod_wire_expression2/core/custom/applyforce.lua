hook.Add("ApplyForceValidAction", "E2.ApplyForce", function( self, ent )
     return E2Lib.GetExtensionStatus("applyforce") 
end)

function ApplyForceValidAction(self,this)
     return hook.Run( "ApplyForceValidAction", self, this )
end

E2Lib.RegisterExtension("applyforce", true, "Allows E2 chips to applyforce", "Allows E2 chips to applyforce" )

-------------------------------------------------------------------------------

__e2setcost(30) -- temporary

local check = WireLib.checkForce

e2function void applyForce(vector force)
       if not ApplyForceValidAction(self,this) then return nil end
       if not check(force) then return end
	local phys = self.entity:GetPhysicsObject()
	phys:ApplyForceCenter(Vector(force[1],force[2],force[3]))
end

e2function void applyOfhfsetForce(vector force, vector position)
       if not ApplyForceValidAction(self,this) then return end
	if not check(force) or not check(position) then return end
	local phys = self.entity:GetPhysicsObject()
	phys:ApplyForceOffset(Vector(force[1],force[2],force[3]), Vector(position[1],position[2],position[3]))
end

e2function void applyAngForce(angle angForce)
       if not ApplyForceValidAction(self,this) then return end
	if angForce[1] == 0 and angForce[2] == 0 and angForce[3] == 0 then return end
	if not check(angForce) then return end

	local ent = self.entity
	local phys = ent:GetPhysicsObject()

	-- assign vectors
	local up = ent:GetUp()
	local left = ent:GetRight() * -1
	local forward = ent:GetForward()

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
       if not ApplyForceValidAction(self,this) then return end
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
	

-------------------------------------------------------------------------------

e2function void entity:applyForce(vector force)
       if not ApplyForceValidAction(self,this) then return nil end
	if not validPhysics(this) then return nil end
	if not isOwner(self, this) then return nil end
	if check( force ) then
		local phys = this:GetPhysicsObject()
		phys:ApplyForceCenter(Vector(force[1],force[2],force[3]))
	end
end

e2function void entity:applyOffsetForce(vector force, vector position)
       if not ApplyForceValidAction(self,this) then return nil end
	if not validPhysics(this) then return nil end
	if not isOwner(self, this) then return nil end
	if check(force) and check(position) then
		local phys = this:GetPhysicsObject()
		phys:ApplyForceOffset(Vector(force[1],force[2],force[3]), Vector(position[1],position[2],position[3]))
	end
end

e2function void entity:applyAngForce(angle angForce)
       if not ApplyForceValidAction(self,this) then return nil end
	if not validPhysics(this) then return nil end
	if not isOwner(self, this) then return nil end
	if angForce[1] == 0 and angForce[2] == 0 and angForce[3] == 0 then return end
	if not check(angForce) then return end

	local phys = this:GetPhysicsObject()

	-- assign vectors
	local up = this:GetUp()
	local left = this:GetRight() * -1
	local forward = this:GetForward()

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

--- Applies torque according to a local torque vector, with magnitude and sense given by the vector's direction, magnitude and orientation.
e2function void entity:applyTorque(vector torque)
       if not ApplyForceValidAction(self,this) then return end
	if not IsValid(this) then return end
	if not isOwner(self, this) then return end

	if torque[1] == 0 and torque[2] == 0 and torque[3] == 0 then return end
	if not check( torque ) then return end

	local phys = this:GetPhysicsObject()

	local tq = Vector(torque[1], torque[2], torque[3])
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

	if not check( dir ) or not check( off ) then return end
	phys:ApplyForceOffset( dir, off )
	phys:ApplyForceOffset( dir * -1, off * -1 )
end

-------------------------------------------------------------------------------

--- Applies force to <this> according to <force>'s direction and magnitude
e2function void bone:applyForce(vector force)
       if not ApplyForceValidAction(self,this) then return end
	local ent = isValidBone(this)
	if not ent then return end
	if not isOwner(self, ent) then return end
	if not check(force) then return end
	this:ApplyForceCenter(Vector(force[1], force[2], force[3]))
end

--- Applies force to <this> according to <force> from the location of <pos>
e2function void bone:applyOffsetForce(vector force, vector pos)
       if not ApplyForceValidAction(self,this) then return end
	local ent = isValidBone(this)
	if not ent then return end
	if not isOwner(self, ent) then return end
	if not check(force) or not check(pos) then return end
	this:ApplyForceOffset(Vector(force[1], force[2], force[3]), Vector(pos[1], pos[2], pos[3]))
end

--- Applies torque to <this> according to <angForce>
e2function void bone:applyAngForce(angle angForce)
       if not ApplyForceValidAction(self,this) then return end
	local ent = isValidBone(this)
	if not ent then return end
	if not isOwner(self, ent) then return end

	if angForce[1] == 0 and angForce[2] == 0 and angForce[3] == 0 then return end
	if not check(angForce) then return end

	-- assign vectors
	local pos     = this:GetPos()
	local forward = this:LocalToWorld(Vector(1,0,0)) - pos
	local left    = this:LocalToWorld(Vector(0,1,0)) - pos -- the y coordinate in local coords is left, not right
	local up      = this:LocalToWorld(Vector(0,0,1)) - pos

	-- apply pitch force
	if angForce[1] ~= 0 then
		local pitch = up      * (angForce[1] * 0.5)
		this:ApplyForceOffset( forward, pitch )
		this:ApplyForceOffset( forward * -1, pitch * -1 )
	end

	-- apply yaw force
	if angForce[2] ~= 0 then
		local yaw   = forward * (angForce[2] * 0.5)
		this:ApplyForceOffset( left, yaw )
		this:ApplyForceOffset( left * -1, yaw * -1 )
	end

	-- apply roll force
	if angForce[3] ~= 0 then
		local roll  = left    * (angForce[3] * 0.5)
		this:ApplyForceOffset( up, roll )
		this:ApplyForceOffset( up * -1, roll * -1 )
	end
end

--- Applies torque according to the axis, magnitude and sense given by the vector's direction, magnitude and orientation.
e2function void bone:applyTorque(vector torque)
       if not ApplyForceValidAction(self,this) then return end
	local ent = isValidBone(this)
	if not ent then return end
	if not isOwner(self, ent) then return end
	local phys = this

	if torque[1] == 0 and torque[2] == 0 and torque[3] == 0 then return end
	if not check(torque) then return end

	local tq = Vector(torque[1], torque[2], torque[3])
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

	if not check( dir ) or not check( off ) then return end
	phys:ApplyForceOffset( dir, off )
	phys:ApplyForceOffset( dir * -1, off * -1 )
end
