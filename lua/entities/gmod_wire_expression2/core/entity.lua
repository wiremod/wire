/******************************************************************************\
  Entity support
\******************************************************************************/

registerType("entity", "e", nil,
	nil,
	function(self,output) return output or NULL end,
	function(retval)
		if validEntity(retval) then return end
		if retval == nil then return end
		if not retval.EntIndex then error("Return value is neither nil nor an Entity, but a "..type(retval).."!",0) end
	end,
	function(v)
		return not validEntity(v)
	end
)

/******************************************************************************/

-- import some e2lib functions
local validEntity  = E2Lib.validEntity
local validPhysics = E2Lib.validPhysics
local getOwner     = E2Lib.getOwner
local isOwner      = E2Lib.isOwner

registerCallback("e2lib_replace_function", function(funcname, func, oldfunc)
	if funcname == "isOwner" then
		isOwner = func
	elseif funcname == "getOwner" then
		getOwner = func
	elseif funcname == "validEntity" then
		validEntity = func
	elseif funcname == "validPhysics" then
		validPhysics = func
	end
end)

-- faster access to some math library functions
local abs = math.abs
local atan2 = math.atan2
local sqrt = math.sqrt
local asin = math.asin
local Clamp = math.Clamp

local rad2deg = 180 / math.pi


/******************************************************************************/
// Functions using operators

__e2setcost(5) -- temporary

registerOperator("ass", "e", "e", function(self, args)
	local op1, op2 = args[2], args[3]
	rv2 = op2[1](self, op2)
	self.vars[op1] = rv2
	self.vclk[op1] = true
	return rv2
end)

/******************************************************************************/

registerOperator("is", "e", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if validEntity(rv1) then return 1 else return 0 end
end)

registerOperator("eq", "ee", "n", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	if rv1 == rv2 then return 1 else return 0 end
end)

registerOperator("neq", "ee", "n", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	if rv1 != rv2 then return 1 else return 0 end
end)

/******************************************************************************/

registerFunction("entity", "n", "e", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self,op1)
	local ent = ents.GetByIndex(rv1)
	if(!validEntity(ent)) then return nil end
	return ent
end)

registerFunction("id", "e:", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self,op1)
	if(!validEntity(rv1)) then return 0 end
	return rv1:EntIndex()
end)

/******************************************************************************/
// Functions getting string

registerFunction("noentity", "", "e", function(self, args)
	return nil
end)

registerFunction("type", "e:", "s", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if(!validEntity(rv1)) then return "" end
	return rv1:GetClass()
end)

registerFunction("model", "e:", "s", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if(!validEntity(rv1)) then return "" end
	return rv1:GetModel()
end)

registerFunction("owner", "e:", "e", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if(!validEntity(rv1)) then return nil end
	return getOwner(self, rv1)
end)

/******************************************************************************/
// Functions getting vector
registerFunction("pos", "e:", "v", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if(!validEntity(rv1)) then return {0,0,0} end
	return rv1:GetPos()
end)

registerFunction("forward", "e:", "v", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if(!validEntity(rv1)) then return {0,0,0} end
	return rv1:GetForward()
end)

registerFunction("right", "e:", "v", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if(!validEntity(rv1)) then return {0,0,0} end
	return rv1:GetRight()
end)

registerFunction("up", "e:", "v", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if(!validEntity(rv1)) then return {0,0,0} end
	return rv1:GetUp()
end)

registerFunction("vel", "e:", "v", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if(!validEntity(rv1)) then return {0,0,0} end
	return rv1:GetVelocity()
end)

registerFunction("velL", "e:", "v", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if(!validEntity(rv1)) then return {0,0,0} end
	return rv1:WorldToLocal(rv1:GetVelocity() + rv1:GetPos())
end)

registerFunction("angVel", "e:", "a", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if(!validPhysics(rv1)) then return {0,0,0} end
	local phys = rv1:GetPhysicsObject()
	local vec = phys:GetAngleVelocity()
	return { vec.y, vec.z, vec.x }
end)

--- Returns a vector describing rotation axis, magnitude and sense given as the vector's direction, magnitude and orientation.
e2function vector entity:angVelVector()
	if not validPhysics(this) then return { 0, 0, 0 } end
	local phys = this:GetPhysicsObject()
	return phys:GetAngleVelocity()
end

/******************************************************************************/
// Functions  using vector getting vector
registerFunction("toWorld", "e:v", "v", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	if(!validEntity(rv1)) then return {0,0,0} end
	return rv1:LocalToWorld(Vector(rv2[1],rv2[2],rv2[3]))
end)

registerFunction("toLocal", "e:v", "v", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	if(!validEntity(rv1)) then return {0,0,0} end
	return rv1:WorldToLocal(Vector(rv2[1],rv2[2],rv2[3]))
end)

--- Transforms from an angle local to <this> to a world angle.
e2function angle entity:toWorld(angle localAngle)
	if not validEntity(this) then return { 0, 0, 0 } end
	local worldAngle = this:LocalToWorldAngles(Angle(localAngle[1],localAngle[2],localAngle[3]))
	return { worldAngle.p, worldAngle.y, worldAngle.r }
end

--- Transforms from a world angle to an angle local to <this>.
e2function angle entity:toLocal(angle worldAngle)
	if not validEntity(this) then return { 0, 0, 0 } end
	local localAngle = this:WorldToLocalAngles(Angle(worldAngle[1],worldAngle[2],worldAngle[3]))
	return { localAngle.p, localAngle.y, localAngle.r }
end

/******************************************************************************/
// Functions getting number
registerFunction("health", "e:", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if(!validEntity(rv1)) then return 0 end
	return rv1:Health()
end)

registerFunction("radius", "e:", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if(!validEntity(rv1)) then return 0 end
	return rv1:BoundingRadius()
end)

// original bearing & elevation thanks to Gwahir
--- Returns the bearing (yaw) from <this> to <pos>
e2function number entity:bearing(vector pos)
	if not validEntity(this) then return 0 end

	pos = this:WorldToLocal(Vector(pos[1],pos[2],pos[3]))

	return rad2deg*-atan2(pos.y, pos.x)
end

--- Returns the elevation (pitch) from <this> to <pos>
e2function number entity:elevation(vector pos)
	if not validEntity(this) then return 0 end

	pos = this:WorldToLocal(Vector(pos[1],pos[2],pos[3]))

	local len = pos:Length()
	if len < delta then return 0 end
	return rad2deg*asin(pos.z / len)
end

--- Returns the elevation (pitch) and bearing (yaw) from <this> to <pos>
e2function angle entity:heading(vector pos)
	if not validEntity(this) then return { 0, 0, 0 } end

	pos = this:WorldToLocal(Vector(pos[1],pos[2],pos[3]))

	-- bearing
	local bearing = rad2deg*-atan2(pos.y, pos.x)

	-- elevation
	local len = pos:Length()--sqrt(x*x + y*y + z*z)
	if len < delta then return { 0, bearing, 0 } end
	local elevation = rad2deg*asin(pos.z / len)

	return { elevation, bearing, 0 }
end

registerFunction("mass", "e:", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if(!validPhysics(rv1)) then return 0 end
	local phys = rv1:GetPhysicsObject()
	return phys:GetMass()
end)

registerFunction("massCenter", "e:", "v", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if(!validPhysics(rv1)) then return {0,0,0} end
	local phys = rv1:GetPhysicsObject()
	return rv1:LocalToWorld(phys:GetMassCenter())
end)

registerFunction("massCenterL", "e:", "v", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if(!validPhysics(rv1)) then return {0,0,0} end
	local phys = rv1:GetPhysicsObject()
	return phys:GetMassCenter()
end)

registerFunction("setMass", "n", "", function(self,args)
	local op1 = args[2]
	local rv1 = op1[1](self,op1)
	if(!validPhysics(self.entity)) then return end
	local mass = Clamp(rv1, 0.001, 50000)
	local phys = self.entity:GetPhysicsObject()
	phys:SetMass(mass)
end)

registerFunction("setMass", "e:n", "", function(self,args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self,op1), op2[1](self,op2)
	if(!validPhysics(rv1)) then return end
	if(!isOwner(self, rv1)) then return end
	if(rv1:IsPlayer()) then return end
	local mass = Clamp(rv2, 0.001, 50000)
	local phys = rv1:GetPhysicsObject()
	phys:SetMass(mass)
end)

/******************************************************************************/
// Functions getting boolean/number
registerFunction("isPlayer", "e:", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if(!validEntity(rv1)) then return 0 end
	if rv1:IsPlayer() then return 1 else return 0 end
end)

registerFunction("isNPC", "e:", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if(!validEntity(rv1)) then return 0 end
	if rv1:IsNPC() then return 1 else return 0 end
end)

registerFunction("isVehicle", "e:", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if(!validEntity(rv1)) then return 0 end
	if rv1:IsVehicle() then return 1 else return 0 end
end)

registerFunction("isWorld", "e:", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if(!validEntity(rv1)) then return 0 end
	if rv1:IsWorld() then return 1 else return 0 end
end)

registerFunction("isOnGround", "e:", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if(!validEntity(rv1)) then return 0 end
	if rv1:IsOnGround() then return 1 else return 0 end
end)

registerFunction("isUnderWater", "e:", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if(!validEntity(rv1)) then return 0 end
	if rv1:WaterLevel() > 0 then return 1 else return 0 end
end)

/******************************************************************************/
// Functions getting angles

registerFunction("angles", "e:", "a", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if(!validEntity(rv1)) then return {0,0,0} end
	local ang = rv1:GetAngles()
	return {ang.p,ang.y,ang.r}
end)

/******************************************************************************/

registerFunction("getMaterial", "e:", "s", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if !validEntity(rv1) then return end
	return rv1:GetMaterial()
end)

registerFunction("setMaterial", "e:s", "", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	if !validEntity(rv1) then return end
	if !isOwner(self, rv1) then return end
	rv1:SetMaterial(rv2)
end)

--- Gets <this>'s current skin number.
e2function number entity:getSkin()
	if validEntity(this) then return this:GetSkin() end
	return 0
end

--- Sets <this>'s skin number.
e2function void entity:setSkin(skin)
	if validEntity(this) then this:SetSkin(skin) end
end

--- Gets <this>'s number of skins.
e2function number entity:getSkinCount()
	if validEntity(this) then return this:SkinCount() end
	return 0
end

/******************************************************************************/

registerFunction("isPlayerHolding", "e:", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if(!validEntity(rv1)) then return 0 end
	if rv1:IsPlayerHolding() then return 1 else return 0 end
end)

registerFunction("isOnFire", "e:", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if(!validEntity(rv1)) then return 0 end
	if rv1:IsOnFire() then return 1 else return 0 end
end)

registerFunction("isWeapon", "e:", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if(!validEntity(rv1)) then return 0 end
	if rv1:IsWeapon() then return 1 else return 0 end
end)

registerFunction("isFrozen", "e:", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if(!validPhysics(rv1)) then return 0 end
	local phys = rv1:GetPhysicsObject()
	if phys:IsMoveable() then return 0 else return 1 end
end)

registerFunction("inVehicle", "e:", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if(!validEntity(rv1)) then return 0 end
	if(rv1:IsPlayer() and rv1:InVehicle()) then return 1 else return 0 end
end)

registerFunction("timeConnected", "e:", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if(!validEntity(rv1)) then return 0 end
	if(rv1:IsPlayer()) then return rv1:TimeConnected() else return 0 end
end)

--- Returns 1 if the player <this> is in noclip mode, 0 if not.
e2function number entity:inNoclip()
	if not this or this:GetMoveType() ~= MOVETYPE_NOCLIP then return 0 end
	return 1
end

/******************************************************************************/

__e2setcost(30) -- temporary

registerFunction("applyForce", "v", "", function(self,args)
	local op1 = args[2]
	local rv1 = op1[1](self,op1)
	local phys = self.entity:GetPhysicsObject()
	phys:ApplyForceCenter(Vector(rv1[1],rv1[2],rv1[3]))
end)

registerFunction("applyOffsetForce", "vv", "", function(self,args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self,op1), op2[1](self,op2)
	local phys = self.entity:GetPhysicsObject()
	phys:ApplyForceOffset(Vector(rv1[1],rv1[2],rv1[3]), Vector(rv2[1],rv2[2],rv2[3]))
end)

/*registerFunction("applyAngVel", "a", "", function(self,args)
	local op1 = args[2]
	local rv1 = op1[1](self,op1)
	local phys = self.entity:GetPhysicsObject()
	phys:AddAngleVelocity(Angle(rv1[3],rv1[1],rv1[2]))
end)*/

registerFunction("applyForce", "e:v", "", function(self,args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self,op1), op2[1](self,op2)
	if(!validPhysics(rv1)) then return nil end
	if(!isOwner(self, rv1)) then return nil end
	local phys = rv1:GetPhysicsObject()
	phys:ApplyForceCenter(Vector(rv2[1],rv2[2],rv2[3]))
end)

registerFunction("applyOffsetForce", "e:vv", "", function(self,args)
	local op1, op2, op3 = args[2], args[3], args[4]
	local rv1, rv2, rv3 = op1[1](self,op1), op2[1](self,op2), op3[1](self,op3)
	if(!validPhysics(rv1)) then return nil end
	if(!isOwner(self, rv1)) then return nil end
	local phys = rv1:GetPhysicsObject()
	phys:ApplyForceOffset(Vector(rv2[1],rv2[2],rv2[3]), Vector(rv3[1],rv3[2],rv3[3]))
end)

/*registerFunction("applyAngVel", "e:a", "", function(self,args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self,op1), op2[1](self,op2)
	if(!validPhysics(rv1)) then return end
	if(!isOwner(self, rv1)) then return nil end
	local phys = rv1:GetPhysicsObject()
	phys:AddAngleVelocity(Angle(rv2[3],rv2[1],rv2[2]))
end)*/

registerFunction("applyAngForce", "a", "", function(self,args)
	local op1 = args[2]
	local rv1 = op1[1](self,op1)

	local ent = self.entity
	local phys = ent:GetPhysicsObject()
	if not phys:IsValid() then return end

	-- assign vectors
	local pos = ent:LocalToWorld(phys:GetMassCenter())
	local up = ent:GetUp()
	local left = ent:GetRight() * -1
	local forward = ent:GetForward()

	local pitch = up      * (rv1[1]*0.5)
	local yaw   = forward * (rv1[2]*0.5)
	local roll  = left    * (rv1[3]*0.5)

	-- apply pitch force
	phys:ApplyForceOffset( forward, pos + pitch )
	phys:ApplyForceOffset( forward * -1, pos - pitch )

	-- apply yaw force
	phys:ApplyForceOffset( left, pos + yaw )
	phys:ApplyForceOffset( left * -1, pos - yaw )

	-- apply roll force
	phys:ApplyForceOffset( up, pos + roll )
	phys:ApplyForceOffset( up * -1, pos - roll )
end)

registerFunction("applyAngForce", "e:a", "", function(self,args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self,op1), op2[1](self,op2)
	if(!validPhysics(rv1)) then return nil end
	if(!isOwner(self, rv1)) then return nil end
	local phys = rv1:GetPhysicsObject()

	-- assign vectors
	local pos = rv1:LocalToWorld(phys:GetMassCenter())
	local up = rv1:GetUp()
	local left = rv1:GetRight()*-1
	local forward = rv1:GetForward()

	local pitch = up      * (rv2[1]*0.5)
	local yaw   = forward * (rv2[2]*0.5)
	local roll  = left    * (rv2[3]*0.5)

	-- apply pitch force
	phys:ApplyForceOffset( forward, pos + pitch )
	phys:ApplyForceOffset( forward * -1, pos - pitch )

	-- apply yaw force
	phys:ApplyForceOffset( left, pos + yaw )
	phys:ApplyForceOffset( left * -1, pos - yaw )

	-- apply roll force
	phys:ApplyForceOffset( up, pos + roll )
	phys:ApplyForceOffset( up * -1, pos - roll )
end)

--- Applies torque according to the axis, magnitude and sense given by the vector's direction, magnitude and orientation.
e2function void entity:applyTorque(vector torque)
	if not validEntity(this) then return end
	if not isOwner(self, this) then return end
	local phys = this:GetPhysicsObject()
	if not phys:IsValid() then return end

	local tq = Vector(torque[1], torque[2], torque[3])
	local torqueamount = tq:Length()
	local off
	if abs(torque[3]) > torqueamount*0.1 or abs(torque[1]) > torqueamount*0.1 then
		off = Vector(-torque[3], 0, torque[1])
	else
		off = Vector(-torque[2], torque[1], 0)
	end
	off:Normalize()
	local dir = tq:Cross(off)

	dir = phys:LocalToWorld(dir)-phys:GetPos()
	local masscenter = phys:GetMassCenter()
	phys:ApplyForceOffset( dir * 0.5, phys:LocalToWorld(masscenter+off) )
	phys:ApplyForceOffset( dir * -0.5, phys:LocalToWorld(masscenter-off) )
end

--- Applies torque according to the axis, magnitude and sense given by the vector's direction, magnitude and orientation.
e2function void entity:applyOffsetTorque(vector torque, vector offset)
	if not validEntity(this) then return end
	if not isOwner(self, this) then return end
	local phys = this:GetPhysicsObject()
	if not phys:IsValid() then return end

	offset = Vector(offset[1], offset[2], offset[3])

	local tq = Vector(torque[1], torque[2], torque[3])
	local torqueamount = tq:Length()
	local off
	if abs(torque[3]) > torqueamount*0.1 or abs(torque[1]) > torqueamount*0.1 then
		off = Vector(-torque[3], 0, torque[1])
	else
		off = Vector(-torque[2], torque[1], 0)
	end
	off:Normalize()
	local dir = tq:Cross(off)

	dir = phys:LocalToWorld(dir)-phys:GetPos()
	phys:ApplyForceOffset( dir * 0.5, phys:LocalToWorld(offset+off) )
	phys:ApplyForceOffset( dir * -0.5, phys:LocalToWorld(offset-off) )
end

registerFunction("inertia", "e:", "v", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if(!validPhysics(rv1)) then return {0,0,0} end
	return rv1:GetPhysicsObject():GetInertia()
end)


/******************************************************************************/

__e2setcost(5) -- temporary

registerFunction("lockPod", "e:n", "", function(self,args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self,op1), op2[1](self,op2)
	if(!validEntity(rv1) || !rv1:IsVehicle()) then return end
	if(!isOwner(self, rv1)) then return end
	if(rv2 != 0) then
		rv1:Fire("Lock", "", 0)
	else
		rv1:Fire("Unlock", "", 0)
	end
end)

registerFunction("killPod", "e:", "", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if(!validEntity(rv1) || !rv1:IsVehicle()) then return end
	if(!isOwner(self, rv1)) then return end
	local ply = rv1:GetDriver()
	if(ply:IsValid()) then ply:Kill() end
end)

registerFunction("ejectPod", "e:", "", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if(!validEntity(rv1) || !rv1:IsVehicle()) then return end
	if(!isOwner(self, rv1)) then return end
	local ply = rv1:GetDriver()
	if(ply:IsValid()) then ply:ExitVehicle() end
end)

/******************************************************************************/

registerFunction("aimEntity", "e:", "e", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if not validEntity(rv1) then return nil end
	if not rv1:IsPlayer() then return nil end

	local ent = rv1:GetEyeTraceNoCursor().Entity
	if not ent:IsValid() then return nil end
	return ent
end)

registerFunction("aimPos", "e:", "v", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if not validEntity(rv1) then return {0,0,0} end
	if not rv1:IsPlayer() then return {0,0,0} end

	return rv1:GetEyeTraceNoCursor().HitPos
end)

registerFunction("aimNormal", "e:", "v", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if not validEntity(rv1) then return {0,0,0} end
	if not rv1:IsPlayer() then return {0,0,0} end

	return rv1:GetEyeTraceNoCursor().HitNormal
end)

--- Returns the bone the player is currently aiming at.
e2function bone entity:aimBone()
	if not validEntity(this) then return nil end
	if not this:IsPlayer() then return nil end

	local trace = this:GetEyeTraceNoCursor()
	local ent = trace.Entity
	if not validEntity(ent) then return nil end
	return getBone(ent, trace.PhysicsBone)
end

--- Equivalent to rangerOffset(16384, <this>:shootPos(), <this>:eye()), but faster (causing less lag)
e2function ranger entity:eyeTrace()
	if not validEntity(this) then return nil end
	if not this:IsPlayer() then return nil end

	return this:GetEyeTraceNoCursor()
end

/******************************************************************************/

registerFunction("boxSize", "e:", "v", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if(!validEntity(rv1)) then return {0,0,0} end
	return rv1:OBBMaxs() - rv1:OBBMins()
end)

registerFunction("boxCenter", "e:", "v", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if(!validEntity(rv1)) then return {0,0,0} end
	return rv1:OBBCenter()
end)

registerFunction("boxMax", "e:", "v", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if(!validEntity(rv1)) then return {0,0,0} end
	return rv1:OBBMaxs()
end)

registerFunction("boxMin", "e:", "v", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if(!validEntity(rv1)) then return {0,0,0} end
	return rv1:OBBMins()
end)

/******************************************************************************/

registerFunction("driver", "e:", "e", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if(!validEntity(rv1) || !rv1:IsVehicle()) then return nil end
	return rv1:GetDriver()
end)

registerFunction("passenger", "e:", "e", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if(!validEntity(rv1) || !rv1:IsVehicle()) then return nil end
	return rv1:GetPassenger()
end)

--- Returns <ent> formatted as a string. Returns "<code>(null)</code>" for invalid entities.
e2function string toString(entity ent)
	if not validEntity(ent) then return "(null)" end
	return tostring(ent)
end

/******************************************************************************/

local function SetTrails(Player, Entity, Data)
	if Entity.SToolTrail then
		Entity.SToolTrail:Remove()
		Entity.SToolTrail = nil
	end

	if not Data then
		duplicator.ClearEntityModifier(Entity, "trail")
		return
	end

	if Data.StartSize <= 0 then Data.StartSize = 0.0001 end

	local trail_entity = util.SpriteTrail(
		Entity,  //Entity
		Data.AttachmentID or 0,  //iAttachmentID
		Data.Color,  //Color
		Data.Additive or false, // bAdditive
		Data.StartSize, //fStartWidth
		Data.EndSize, //fEndWidth
		Data.Length, //fLifetime
		2 / (Data.StartSize+Data.EndSize), //fTextureRes
		Data.Material .. ".vmt"
	) //strTexture

	Entity.SToolTrail = trail_entity
	Player:AddCleanup( "trails", trail_entity )

	duplicator.StoreEntityModifier( Entity, "trail", Data )

	return trail_entity
end

hook.Add("InitPostEntity", "trails", function()
	duplicator.RegisterEntityModifier( "trail", SetTrails )
end)

--- Removes the trail from <this>.
e2function void entity:removeTrails()
	if not validEntity(this) then return end
	if not isOwner(self, this) then return end

	SetTrails(self.player, this, nil)
end

local function composedata(startSize, endSize, length, material, color, alpha)
	if string.find(material, '"', 1, true) then return nil end
	if not file.Exists("../materials/"..material..".vmt") then return nil end -- check for non-existant materials.

	return {
		Color = Color( color[1], color[2], color[3], alpha ),
		Length = length,
		StartSize = startSize,
		EndSize = endSize,
		Material = material,
	}
end

--- StartSize, EndSize, Length, Material, Color (RGB), Alpha
--- Adds a trail to <this> with the specified attributes.
e2function void entity:setTrails(startSize, endSize, length, string material, vector color, alpha)
	if not validEntity(this) then return end
	if not isOwner(self, this) then return end

	local Data = composedata(startSize, endSize, length, material, color, alpha)
	if not Data then return end

	SetTrails(self.player, this, Data)
end

--- StartSize, EndSize, Length, Material, Color (RGB), Alpha, AttachmentID, Additive
--- Adds a trail to <this> with the specified attributes.
e2function void entity:setTrails(startSize, endSize, length, string material, vector color, alpha, attachmentID, additive)
	if not validEntity(this) then return end
	if not isOwner(self, this) then return end

	local Data = composedata(startSize, endSize, length, material, color, alpha)
	if not Data then return end

	Data.AttachmentID = attachmentID
	Data.Additive = additive ~= 0

	SetTrails(self.player, this, Data)
end

/******************************************************************************/

--- Returns <this>'s attachment ID associated with <attachmentName>
e2function number entity:lookupAttachment(string attachmentName)
	if not validEntity(this) then return 0 end
	return this:LookupAttachment(attachmentName)
end

--- Returns <this>'s attachment position associated with <attachmentID>
e2function vector entity:attachmentPos(attachmentID)
	if not validEntity(this) then return { 0, 0, 0 } end
	local attachment = this:GetAttachment(attachmentID)
	if not attachment then return { 0, 0, 0 } end
	return attachment.Pos
end

--- Returns <this>'s attachment angle associated with <attachmentID>
e2function angle entity:attachmentAng(attachmentID)
	if not validEntity(this) then return { 0, 0, 0 } end
	local attachment = this:GetAttachment(attachmentID)
	if not attachment then return { 0, 0, 0 } end
	local ang = attachment.Ang
	return { ang.p, ang.y, ang.r }
end

--- Same as <this>:attachmentPos(entity:lookupAttachment(<attachmentName>))
e2function vector entity:attachmentPos(string attachmentName)
	if not validEntity(this) then return { 0, 0, 0 } end
	local attachment = this:GetAttachment(this:LookupAttachment(attachmentName))
	if not attachment then return { 0, 0, 0 } end
	return attachment.Pos
end

--- Same as <this>:attachmentAng(entity:lookupAttachment(<attachmentName>))
e2function angle entity:attachmentAng(string attachmentName)
	if not validEntity(this) then return { 0, 0, 0 } end
	local attachment = this:GetAttachment(this:LookupAttachment(attachmentName))
	if not attachment then return { 0, 0, 0 } end
	local ang = attachment.Ang
	return { ang.p, ang.y, ang.r }
end

__e2setcost(nil)
