local isOwner = E2Lib.isOwner
local IsValid = IsValid
registerCallback("e2lib_replace_function", function(funcname, func, oldfunc)
	if funcname == "isOwner" then
		isOwner = func
	elseif funcname == "IsValid" then
		IsValid = func
	end
end)

local entity2bone = {}

hook.Add("EntityRemoved", "wire_expression2_bone", function(ent)
	if entity2bone[ent] then
		entity2bone[ent] = nil
	end
end)

-- faster access to some math library functions
local abs = math.abs
local atan2 = math.atan2
local sqrt = math.sqrt
local asin = math.asin
local Clamp = math.Clamp

local rad2deg = 180 / math.pi

local function getBone(entity, index)
	if not entity2bone[entity] then entity2bone[entity] = {} end
	local bone = entity2bone[entity][index]
	if not bone then
		bone = entity:GetPhysicsObjectNum(index)
		if not bone then return nil end
		entity2bone[entity][index] = bone
	end

	return IsValid(bone) and bone or nil
end
E2Lib.getBone = getBone

local function GetBones(entity)
	local bone_count = entity:GetPhysicsObjectCount()
	for i = 0, bone_count - 1 do
		getBone(entity, i)
	end
	return entity2bone[entity] or {}
end
E2Lib.GetBones = GetBones

-- checks whether the bone is valid. if yes, returns the bone's entity; otherwise, returns nil.
local function isValidBone(b)
	if type(b) ~= "PhysObj" or not IsValid(b) then return nil, 0 end
	local ent = b:GetEntity()
	if not ent:IsValid() then
		return nil
	end
	return ent
end
E2Lib.isValidBone = isValidBone

--[[************************************************************************]]--

registerType("bone", "b", nil,
	nil,
	nil,
	nil,
	function(b)
		return not isValidBone(b)
	end
)

--[[************************************************************************]]--

__e2setcost(1)

--- if (B)
e2function number operator_is(bone this)
	return isValidBone(this) and 1 or 0
end

--[[************************************************************************]]--
__e2setcost(3)

--- Returns <this>'s <index>th bone.
e2function bone entity:bone(index)
	if not IsValid(this) then return self:throw("Invalid entity!", nil) end
	if index < 0 then return self:throw("Invalid bone index " .. index, nil) end
	if index >= this:GetPhysicsObjectCount() then return nil end
	return getBone(this, index)
end

--- Returns an array containing all of <this>'s bones. This array's first element has the index 0!
e2function array entity:bones()
	if not IsValid(this) then return { } end
	return table.Copy(GetBones(this))
end

--- Returns <this>'s number of bones.
e2function number entity:boneCount()
	if not IsValid(this) then return self:throw("Invalid entity!", 0) end
	return this:GetPhysicsObjectCount()
end

__e2setcost(1)

--- Returns an invalid bone.
e2function bone nobone()
	return nil
end

--- Returns the entity <this> belongs to
e2function entity bone:entity()
	return isValidBone(this)
end

--- Returns <this>'s index in the entity it belongs to. Returns -1 if the bone is invalid or an error occured.
e2function number bone:index()
	local ent = isValidBone(this)
	if not ent then return -1 end
	local n = ent:GetPhysicsObjectCount() - 1
	for i = 0, n do
		if this == ent:GetPhysicsObjectNum(i) then return i end
	end
	return -1
end

--[[************************************************************************]]--

--- Returns <this>'s position.
e2function vector bone:pos()
	if not isValidBone(this) then return self:throw("Invalid bone!", Vector(0, 0, 0)) end
	return this:GetPos()
end

do
	local fwd, right, up = Vector(1, 0, 0), Vector(0, -1, 0), Vector(0, 0, 1)

	--- Returns a vector describing <this>'s forward direction.
	e2function vector bone:forward()
		if not isValidBone(this) then return self:throw("Invalid bone!", Vector(0, 0, 0)) end
		return this:LocalToWorld(fwd)-this:GetPos()
	end

	--- Returns a vector describing <this>'s right direction.
	e2function vector bone:right()
		if not isValidBone(this) then return self:throw("Invalid bone!", Vector(0, 0, 0)) end
		return this:LocalToWorld(right)-this:GetPos() -- the y coordinate in local coords is left, not right. hence -1
	end

	--- Returns a vector describing <this>'s up direction.
	e2function vector bone:up()
		if not isValidBone(this) then return self:throw("Invalid bone!", Vector(0, 0, 0)) end
		return this:LocalToWorld(up)-this:GetPos()
	end
end

--- Returns <this>'s velocity.
e2function vector bone:vel()
	if not isValidBone(this) then return self:throw("Invalid bone!", Vector(0, 0, 0)) end
	return this:GetVelocity()
end

--- Returns <this>'s velocity in local coordinates.
e2function vector bone:velL()
	if not isValidBone(this) then return self:throw("Invalid bone!", Vector(0, 0, 0)) end
	return this:WorldtoLocal(this:GetVelocity() + this:GetPos())
end

--[[************************************************************************]]--

--- Transforms <pos> from local coordinates (as seen from <this>) to world coordinates.
e2function vector bone:toWorld(vector pos)
	if not isValidBone(this) then return self:throw("Invalid bone!", Vector(0, 0, 0)) end
	return this:LocalToWorld(Vector(pos[1],pos[2],pos[3]))
end

--- Transforms <pos> from world coordinates to local coordinates (as seen from <this>).
e2function vector bone:toLocal(vector pos)
	if not isValidBone(this) then return self:throw("Invalid bone!", Vector(0, 0, 0)) end
	return this:WorldToLocal(Vector(pos[1],pos[2],pos[3]))
end

--[[************************************************************************]]--

--- Returns <this>'s angular velocity.
e2function angle bone:angVel()
	if not isValidBone(this) then return self:throw("Invalid bone!", Angle(0, 0, 0)) end
	local vec = this:GetAngleVelocity()
	return Angle(vec.y, vec.z, vec.x)
end

--- Returns a vector describing rotation axis, magnitude and sense given as the vector's direction, magnitude and orientation.
e2function vector bone:angVelVector()
	if not isValidBone(this) then return self:throw("Invalid bone!", Vector(0, 0, 0)) end
	return this:GetAngleVelocity()
end

--- Returns <this>'s pitch, yaw and roll angles.
e2function angle bone:angles()
	if not isValidBone(this) then return self:throw("Invalid bone!", Angle(0, 0, 0)) end
	local ang = this:GetAngles()
	return Angle(ang.p, ang.y, ang.r)
end

--[[************************************************************************]]--

--- Returns the bearing (yaw) from <this> to <pos>.
e2function number bone:bearing(vector pos)
	if not isValidBone(this) then return self:throw("Invalid bone!", 0) end

	pos = this:WorldToLocal(Vector(pos[1],pos[2],pos[3]))

	return rad2deg*-atan2(pos.y, pos.x)
end

--- Returns the elevation (pitch) from <this> to <pos>.
e2function number bone:elevation(vector pos)
	if not isValidBone(this) then return self:throw("Invalid bone!", 0) end
	pos = this:WorldToLocal(Vector(pos[1],pos[2],pos[3]))

	local len = pos:Length()
	if len < 0 then return 0 end
	return rad2deg*asin(pos.z / len)
end

--- Returns the elevation (pitch) and bearing (yaw) from <this> to <pos>
e2function angle bone:heading(vector pos)
	if not isValidBone(this) then return self:throw("Invalid bone!", Angle(0, 0, 0)) end

	pos = this:WorldToLocal(Vector(pos[1],pos[2],pos[3]))

	-- bearing
	local bearing = rad2deg*-atan2(pos.y, pos.x)

	-- elevation
	local len = pos:Length()--sqrt(x*x + y*y + z*z)
	if len < 0 then return Angle(0, bearing, 0) end
	local elevation = rad2deg*asin(pos.z / len)

	return Angle(elevation, bearing, 0)
end

--- Returns <this>'s mass.
e2function number bone:mass()
	if not isValidBone(this) then return self:throw("Invalid bone!", 0) end
	return this:GetMass()
end

--- Returns <this>'s Center of Mass.
e2function vector bone:massCenter()
	if not isValidBone(this) then return self:throw("Invalid bone!", Vector(0, 0, 0)) end
	return this:LocalToWorld(this:GetMassCenter())
end

--- Returns <this>'s Center of Mass in local coordinates.
e2function vector bone:massCenterL()
	if not isValidBone(this) then return self:throw("Invalid bone!", Vector(0, 0, 0)) end
	return this:GetMassCenter()
end

--- Sets <this>'s mass (between 0.001 and 50,000)
e2function void bone:setMass(mass)
	local ent = isValidBone(this)
	if not ent then return self:throw("Invalid bone!", nil) end
	if not isOwner(self, ent) then return self:throw("You do not own this entity!", nil) end
	mass = Clamp(mass, 0.001, 50000)
	this:SetMass(mass)
end

--- Gets the principal components of <this>'s inertia tensor in the form vec(Ixx, Iyy, Izz)
e2function vector bone:inertia()
	if not isValidBone(this) then return self:throw("Invalid bone!", Vector(0, 0, 0)) end
	return this:GetInertia()
end

--[[************************************************************************]]--
__e2setcost(30)

local clamp = WireLib.clampForce

--- Applies force to <this> according to <force>'s direction and magnitude
e2function void bone:applyForce(vector force)
	local ent = isValidBone(this)
	if not ent then return self:throw("Invalid bone!", nil) end
	if not isOwner(self, ent) then return self:throw("You do not own this entity!", nil) end
	force = clamp(force)
	this:ApplyForceCenter(Vector(force[1], force[2], force[3]))
end

--- Applies force to <this> according to <force> from the location of <pos>
e2function void bone:applyOffsetForce(vector force, vector pos)
	local ent = isValidBone(this)
	if not ent then return self:throw("Invalid bone!", nil) end
	if not isOwner(self, ent) then return self:throw("You do not own this entity!", nil) end
	force 	= clamp(force)
	pos 	= clamp(pos)
	this:ApplyForceOffset(Vector(force[1], force[2], force[3]), Vector(pos[1], pos[2], pos[3]))
end

--- Applies torque to <this> according to <angForce>
e2function void bone:applyAngForce(angle angForce)
	local ent = isValidBone(this)
	if not ent then return self:throw("Invalid bone!", nil) end
	if not isOwner(self, ent) then return self:throw("You do not own this entity!", nil) end

	if angForce[1] == 0 and angForce[2] == 0 and angForce[3] == 0 then return end
	angForce = clamp(angForce)

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
	local ent = isValidBone(this)
	if not ent then return self:throw("Invalid bone!", nil) end
	if not isOwner(self, ent) then return self:throw("You do not own this entity!", nil) end
	local phys = this

	if torque[1] == 0 and torque[2] == 0 and torque[3] == 0 then return end
	torque = clamp(torque)

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

	dir = clamp(dir)
	off = clamp(off)

	phys:ApplyForceOffset( dir, off )
	phys:ApplyForceOffset( dir * -1, off * -1 )
end

--[[************************************************************************]]--
__e2setcost(2)
--- Returns 1 if <this> is frozen, 0 otherwise
e2function number bone:isFrozen()
	if not isValidBone(this) then return self:throw("Invalid bone!", 0) end
	return this:IsMoveable() and 0 or 1
end

--- Sets whether <gravity> is applied to <this> bone.
__e2setcost(10)
e2function void bone:boneGravity(gravity)
	local ent = isValidBone(this)
	if not ent then return self:throw("Invalid bone!", nil) end
	if not isOwner(self, ent) then return self:throw("You do not own this entity!", nil) end
	this:EnableGravity( gravity ~= 0 )
end

-- helper function for invert(T) in table.lua
function e2_tostring_bone(b)
	local ent = isValidBone(b)
	if not ent then return "(null bone)" end
	return string.format("bone [%s][Entity %d]", b:GetName(), ent:EntIndex())
end
local e2_tostring_bone = e2_tostring_bone

e2function string toString(bone b)
	return e2_tostring_bone(b)
end

WireLib.registerDebuggerFormat("BONE", e2_tostring_bone)
