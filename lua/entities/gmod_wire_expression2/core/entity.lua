local wire_expression2_entity_trails_max = CreateConVar("wire_expression2_entity_trails_max", 30, FCVAR_ARCHIVE, "Max amount of trails a player can make. 0 - to disable trails. (Limit is shared between E2s of a player)", 0)

registerType("entity", "e", nil,
	nil,
	function(self,output) return output or NULL end,
	nil,
	function(v)
		return not isentity(v)
	end
)

--[[******************************************************************************]]

-- import some e2lib functions
local validPhysics = E2Lib.validPhysics
local getOwner     = E2Lib.getOwner
local isOwner      = E2Lib.isOwner
local newE2Table   = E2Lib.newE2Table

local canProperty = WireLib.CanProperty
local canEditVariable = WireLib.CanEditVariable

local sun = ents.FindByClass("env_sun")[1] -- used for sunDirection()
local trailedEntsAmount = {};

hook.Add("InitPostEntity","sunent",function()
	sun = ents.FindByClass("env_sun")[1]
	timer.Simple(0,function() -- make sure we have a sun first
		hook.Remove("InitPostEntity","sunent")
	end ) -- then remove this. we don't need it anymore.
end)

registerCallback("e2lib_replace_function", function(funcname, func, oldfunc)
	if funcname == "isOwner" then
		isOwner = func
	elseif funcname == "getOwner" then
		getOwner = func
	elseif funcname == "IsValid" then
		IsValid = func
	elseif funcname == "validPhysics" then
		validPhysics = func
	end
end)

-- faster access to some math library functions
local atan2 = math.atan2
local asin = math.asin
local Clamp = math.Clamp

local rad2deg = 180 / math.pi

--[[******************************************************************************]]

local function checkOwner(self)
	return IsValid(self.player)
end

--[[******************************************************************************]]
-- Functions using operators

__e2setcost(5) -- temporary

--[[******************************************************************************]]

e2function number operator_is(entity this)
	return IsValid(this) and 1 or 0
end

--[[******************************************************************************]]

e2function entity entity(id)
	local ent = ents.GetByIndex(id)
	return IsValid(ent) and ent or nil
end

e2function number entity:id()
	if not IsValid(this) then return self:throw("Invalid entity!", 0) end
	return this:EntIndex()
end

e2function number entity:creationID()
	if not IsValid(this) then return self:throw("Invalid entity!", 0) end
	return this:GetCreationID()
end

e2function number entity:creationTime()
	if not IsValid(this) then return self:throw("Invalid entity!", 0) end
	return this:GetCreationTime()
end

--[[******************************************************************************]]
-- Functions getting string

e2function entity noentity()
	return NULL
end

e2function entity world()
	return game.GetWorld()
end

e2function string entity:name()
	if not IsValid(this) then return self:throw("Invalid entity!", "") end
	return this:GetName() or ""
end

e2function string entity:type()
	if not IsValid(this) then return self:throw("Invalid entity!", "") end
	return this:GetClass()
end

e2function string entity:model()
	if not IsValid(this) then return self:throw("Invalid entity!", "") end
	return this:GetModel() or ""
end

e2function entity entity:owner()
	if not IsValid(this) then return self:throw("Invalid entity!", nil) end
	return getOwner(self, this)
end

__e2setcost(20)

e2function table entity:keyvalues()
	local ret = newE2Table() -- default table
	if not IsValid(this) then return self:throw("Invalid entity!", ret) end
	local keyvalues = this:GetKeyValues()
	local size = 0
	for k,v in pairs( keyvalues ) do
		size = size + 1
		ret.s[k] = v
		ret.stypes[k] = string.lower(type(v)[1]) -- i swear there's a more elegant solution to this but whatever.
	end
	ret.size = size
	return ret
end

e2function number entity:setEditProperty(string key, string value)
	if not IsValid(this) then return self:throw("Invalid entity!", 0) end
	if not isOwner(self, this) then return self:throw("You do not own this entity!", 0) end
	if not this.Editable then return self:throw("Tried to edit non-editable entity!", 0) end
	if not canProperty(self.player, this, "editentity") then return self:throw("Gamemode disallowed editing this entity!", 0) end

	key = key:lower()
	local edit = this:GetEditingData()[key]
	if not edit then return self:throw("Property '" .. key .. "' does not exist on entity!", 0) end
	if not canEditVariable(this, self.player, key, value, edit) then return self:throw("Server disallowed editing this property!", 0) end

	return this:SetNetworkKeyValue(key, value) and 1 or 0
end

e2function string entity:getEditProperty(string key)
	if not IsValid(this) then return self:throw("Invalid entity!", "") end
	if not this.Editable then return self:throw("Tried to access non-editable entity!", "") end

	-- GetNetworkKeyValue lowercases the key for us
	return tostring(this:GetNetworkKeyValue(key) or "")
end

__e2setcost(30)

e2function table entity:getEditData()
	local ret = newE2Table()
	if not IsValid(this) then return self:throw("Invalid entity!", ret) end
	if not this.Editable then return self:throw("Tried to access non-editable entity!", ret) end

	local i = 0
	for k, v in pairs(this:GetEditingData()) do
		ret.s[k] = v.type -- Note that this is the DProperty rowType and not a valid E2 type
		ret.stypes[k] = "s"
		i = i + 1
	end
	ret.size = i

	return ret
end

__e2setcost(1)

e2function number entity:isEditable()
	return (IsValid(this) or self:throw("Invalid entity!")) and this.Editable and 1 or 0
end

__e2setcost(5) -- temporary

--[[******************************************************************************]]
-- Functions getting vector

e2function vector entity:pos()
	if not IsValid(this) then return self:throw("Invalid entity!", Vector(0, 0, 0)) end
	return this:GetPos()
end

e2function vector entity:forward()
	if not IsValid(this) then return self:throw("Invalid entity!", Vector(0, 0, 0)) end
	return this:GetForward()
end

e2function vector entity:right()
	if not IsValid(this) then return self:throw("Invalid entity!", Vector(0, 0, 0)) end
	return this:GetRight()
end

e2function vector entity:up()
	if not IsValid(this) then return self:throw("Invalid entity!", Vector(0, 0, 0)) end
	return this:GetUp()
end

e2function vector entity:vel()
	if not IsValid(this) then return self:throw("Invalid entity!", Vector(0, 0, 0)) end
	return this:GetVelocity()
end

e2function vector entity:velL()
	if not IsValid(this) then return self:throw("Invalid entity!", Vector(0, 0, 0)) end
	return this:WorldToLocal(this:GetVelocity() + this:GetPos())
end

[nodiscard]
e2function vector entity:velAtPoint(vector worldPosition)
	local physobj = this:GetPhysicsObject()
	if not IsValid(this) or not IsValid(physobj) then return self:throw("Invalid entity!", Vector(0, 0, 0)) end
	return physobj:GetVelocityAtPoint(worldPosition)
end

e2function angle entity:angVel()
	if not validPhysics(this) then return self:throw("Invalid entity!", Angle(0, 0, 0)) end
	local phys = this:GetPhysicsObject()
	local vec = phys:GetAngleVelocity()
	return Angle(vec.y, vec.z, vec.x)
end

--- Returns a vector describing rotation axis, magnitude and sense given as the vector's direction, magnitude and orientation.
e2function vector entity:angVelVector()
	if not validPhysics(this) then return self:throw("Invalid entity!", Vector(0, 0, 0)) end
	local phys = this:GetPhysicsObject()
	return phys:GetAngleVelocity()
end

--- Specific to env_sun because Source is dum. Use this to trace towards the sun or something.
e2function vector sunDirection()
	if not IsValid(sun) then return Vector(0, 0, 0) end
	return sun:GetKeyValues().sun_dir
end

--[[******************************************************************************]]
-- Functions  using vector getting vector

__e2setcost(15)

e2function vector entity:toWorld(vector localPosition)
	if not IsValid(this) then return self:throw("Invalid entity!", Vector(0, 0, 0)) end
	return this:LocalToWorld(localPosition)
end

e2function vector entity:toLocal(vector worldPosition)
	if not IsValid(this) then return self:throw("Invalid entity!", Vector(0, 0, 0)) end
	return this:WorldToLocal(worldPosition)
end

e2function vector entity:toWorldAxis(vector localAxis)
	if not IsValid(this) then return self:throw("Invalid entity!", Vector(0, 0, 0)) end
	return this:LocalToWorld(localAxis)-this:GetPos()
end

e2function vector entity:toLocalAxis(vector worldAxis)
	if not IsValid(this) then return self:throw("Invalid entity!", Vector(0, 0, 0)) end
	return this:WorldToLocal(worldAxis+this:GetPos())
end

--- Transforms from an angle local to <this> to a world angle.
e2function angle entity:toWorld(angle localAngle)
	if not IsValid(this) then return self:throw("Invalid entity!", Angle(0, 0, 0)) end
	return this:LocalToWorldAngles(localAngle)
end

--- Transforms from a world angle to an angle local to <this>.
e2function angle entity:toLocal(angle worldAngle)
	if not IsValid(this) then return self:throw("Invalid entity!", Angle(0, 0, 0)) end
	return this:WorldToLocalAngles(worldAngle)
end

--[[******************************************************************************]]
-- Functions getting number

__e2setcost(5)

e2function number entity:health()
	if not IsValid(this) then return self:throw("Invalid entity!", 0) end
	return this:Health()
end

e2function number entity:maxHealth()
	if not IsValid(this) then return self:throw("Invalid entity!", 0) end
	return this:GetMaxHealth()
end

e2function number entity:radius()
	if not IsValid(this) then return self:throw("Invalid entity!", 0) end
	return this:BoundingRadius()
end

-- original bearing & elevation thanks to Gwahir
--- Returns the bearing (yaw) from <this> to <pos>

__e2setcost(15)

e2function number entity:bearing(vector pos)
	if not IsValid(this) then return self:throw("Invalid entity!", 0) end

	pos = this:WorldToLocal(pos)

	return rad2deg * -atan2(pos.y, pos.x)
end

--- Returns the elevation (pitch) from <this> to <pos>
e2function number entity:elevation(vector pos)
	if not IsValid(this) then return self:throw("Invalid entity!", 0) end

	pos = this:WorldToLocal(pos)

	local len = pos:Length()
	if len < 0 then return 0 end
	return rad2deg*asin(pos.z / len)
end

--- Returns the elevation (pitch) and bearing (yaw) from <this> to <pos>
e2function angle entity:heading(vector pos)
	if not IsValid(this) then return self:throw("Invalid entity!", Angle(0, 0, 0)) end

	pos = this:WorldToLocal(pos)

	-- bearing
	local bearing = rad2deg*-atan2(pos.y, pos.x)

	-- elevation
	local len = pos:Length()--sqrt(x*x + y*y + z*z)
	if len < 0 then return Angle(0, bearing, 0) end
	local elevation = rad2deg * asin(pos.z / len)

	return Angle(elevation, bearing, 0)
end

__e2setcost(10)

e2function number entity:mass()
	if not IsValid(this) then return self:throw("Invalid entity!", 0) end
	local phys = this:GetPhysicsObject()
	if not phys:IsValid() then return self:throw("Invalid physics object!", 0) end
	return phys:GetMass()
end

e2function vector entity:massCenter()
	if not IsValid(this) then return self:throw("Invalid entity!", Vector(0, 0, 0)) end
	local phys = this:GetPhysicsObject()
	if not phys:IsValid() then return self:throw("Invalid physics object!", Vector(0, 0, 0)) end
	return this:LocalToWorld(phys:GetMassCenter())
end

e2function vector entity:massCenterL()
	if not IsValid(this) then return self:throw("Invalid entity!", Vector(0, 0, 0)) end
	local phys = this:GetPhysicsObject()
	if not phys:IsValid() then return self:throw("Invalid physics object!", Vector(0, 0, 0)) end
	return phys:GetMassCenter()
end

e2function void setMass(mass)
	if not validPhysics(self.entity) then return self:throw("Invalid entity!", nil) end
	if WireLib.isnan( mass ) then mass = 50000 end
	local mass = Clamp(mass, 0.001, 50000)
	local phys = self.entity:GetPhysicsObject()
	phys:SetMass(mass)
	duplicator.StoreEntityModifier(self.entity, "mass", { Mass = mass })
end

e2function void entity:setMass(mass)
	if not validPhysics(this) then return self:throw("Invalid physics object!", nil) end
	if not isOwner(self, this) then return self:throw("You do not own this prop!", nil) end
	if this:IsPlayer() then return self:throw("You cannot set the mass of a player") end
	if WireLib.isnan( mass ) then mass = 50000 end
	local mass = Clamp(mass, 0.001, 50000)
	local phys = this:GetPhysicsObject()
	phys:SetMass(mass)
	duplicator.StoreEntityModifier(this, "mass", { Mass = mass })
end

e2function number entity:volume()
	if not validPhysics(this) then return self:throw("Invalid physics object!", 0) end
	local phys = this:GetPhysicsObject()
	return phys:GetVolume() or 0
end

e2function number entity:surfaceArea()
	if not validPhysics(this) then return self:throw("Invalid physics object!", 0) end
	local phys = this:GetPhysicsObject()
	return phys:GetSurfaceArea()  or 0
end

e2function number entity:stress()
	if not validPhysics(this) then return self:throw("Invalid physics object!", 0) end
	local phys = this:GetPhysicsObject()
	return phys:GetStress() or 0
end

local ids = {
	["EnergyAbsorbed"] = "n",
	["FrictionCoefficient"] = "n",
	["NormalForce"] = "n",
	["Normal"] = "v",
	["ContactPoint"] = "v",
}

e2function table entity:frictionSnapshot()
	local ret = newE2Table() -- default table
	if not validPhysics(this) then return self:throw("Invalid physics object!", ret) end

	local events = this:GetPhysicsObject():GetFrictionSnapshot()
	for i, event in ipairs(events) do
		local data = newE2Table()
		local size = 0

		for k, v in pairs(event) do
			if ids[k] then
				data.s[k] = v
				data.stypes[k] = ids[k]
				size = size + 1
			end
		end

		data.size = size
		ret.n[i] = data
		ret.ntypes[i] = "t"
	end

	ret.size = #events
	self.prf = self.prf + ret.size * 50

	return ret
end

--[[******************************************************************************]]
-- Functions getting boolean/number
e2function number entity:isPlayer()
	if not IsValid(this) then return self:throw("Invalid entity!", 0) end
	if this:IsPlayer() then return 1 else return 0 end
end

e2function number entity:isNPC()
	if not IsValid(this) then return self:throw("Invalid entity!", 0) end
	if this:IsNPC() then return 1 else return 0 end
end

e2function number entity:isVehicle()
	if not IsValid(this) then return self:throw("Invalid entity!", 0) end
	if this:IsVehicle() then return 1 else return 0 end
end

e2function number entity:isWorld()
	if not isentity(this) then return self:throw("Invalid entity!", 0) end
	if this:IsWorld() then return 1 else return 0 end
end

e2function number entity:isOnGround()
	if not IsValid(this) then return self:throw("Invalid entity!", 0) end
	if this:IsOnGround() then return 1 else return 0 end
end

e2function number entity:isUnderWater()
	if not IsValid(this) then return self:throw("Invalid entity!", 0) end
	if this:WaterLevel() > 0 then return 1 else return 0 end
end

e2function number entity:isValid()
	if IsValid(this) then return 1 else return 0 end
end

--- Returns 1 if <this> has valid physics. Note: Players do not.
e2function number entity:isValidPhysics()
	if E2Lib.validPhysics(this) then return 1 else return 0 end
end

--[[******************************************************************************]]
-- Functions getting angles

e2function angle entity:angles()
	if not IsValid(this) then return self:throw("Invalid entity!", Angle(0, 0, 0)) end
	local ang = this:GetAngles()
	return Angle(ang.p, ang.y, ang.r)
end

--[[******************************************************************************]]

e2function string entity:getMaterial()
	if not IsValid(this) then return self:throw("Invalid entity!", "") end
	return this:GetMaterial() or ""
end

e2function string entity:getSubMaterial(index)
	if not IsValid(this) then return self:throw("Invalid entity!", "") end
	return this:GetSubMaterial(index-1) or ""
end

__e2setcost(20)

e2function array entity:getMaterials()
	if not IsValid(this) then return self:throw("Invalid entity!", {}) end
	return this:GetMaterials()
end

__e2setcost(10)

e2function void entity:setMaterial(string material)
	if not IsValid(this) then return self:throw("Invalid entity!", nil) end
	if not isOwner(self, this) then return self:throw("You do not own this entity!", nil) end
	E2Lib.setMaterial(this, material)
end

e2function void entity:setSubMaterial(index, string material)
	if not IsValid(this) then return self:throw("Invalid entity!", nil) end
	if not isOwner(self, this) then return self:throw("You do not own this entity!", nil) end
	E2Lib.setSubMaterial(this, index-1, material)
end

--- Gets <this>'s current skin number.
e2function number entity:getSkin()
	if not IsValid(this) then return self:throw("Invalid entity!", 0) end
	return this:GetSkin()
end

--- Sets <this>'s skin number.
e2function void entity:setSkin(skinIndex)
	if not IsValid(this) then return self:throw("Invalid entity!", nil) end
	if not isOwner(self, this) then return self:throw("You do not own this entity!", nil) end
	this:SetSkin(skinIndex)
end

--- Gets <this>'s number of skins.
e2function number entity:getSkinCount()
	if not IsValid(this) then return self:throw("Invalid entity!", 0) end
	return this:SkinCount()
end

--- Sets <this>'s bodygroup.
e2function void entity:setBodygroup(bgrp_id, bgrp_subid)
	if not IsValid(this) then return self:throw("Invalid entity!", nil) end
	if not isOwner(self, this) then return self:throw("You do not own this entity!", nil) end
	this:SetBodygroup(bgrp_id, bgrp_subid)
end

--- Gets <this>'s bodygroup number.
e2function number entity:getBodygroup(bgrp_id)
	if not IsValid(this) then return self:throw("Invalid entity!", 0) end
	return this:GetBodygroup(bgrp_id)
end
--- Gets <this>'s bodygroup count.
e2function number entity:getBodygroups(bgrp_id)
	if not IsValid(this) then return self:throw("Invalid entity!", 0) end
	return this:GetBodygroupCount(bgrp_id)
end

--[[******************************************************************************]]

e2function number entity:isPlayerHolding()
	if not IsValid(this) then return self:throw("Invalid entity!", 0) end
	if this:IsPlayerHolding() then return 1 else return 0 end
end

e2function number entity:isOnFire()
	if not IsValid(this) then return self:throw("Invalid entity!", 0) end
	if this:IsOnFire() then return 1 else return 0 end
end

e2function number entity:isWeapon()
	if not IsValid(this) then return self:throw("Invalid entity!", 0) end
	if this:IsWeapon() then return 1 else return 0 end
end

e2function number entity:isFrozen()
	if not validPhysics(this) then return self:throw("Invalid entity!", 0) end
	local phys = this:GetPhysicsObject()
	if phys:IsMoveable() then return 0 else return 1 end
end

--[[******************************************************************************]]

__e2setcost(30) -- temporary

local clamp = WireLib.clampForce

e2function void entity:applyForce(vector force)
	if not validPhysics(this) then return self:throw("Invalid physics object!", nil) end
	if not isOwner(self, this) then return self:throw("You do not own this entity!", nil) end

	force = clamp(force)

	local phys = this:GetPhysicsObject()
	phys:ApplyForceCenter(force)
end

e2function void entity:applyOffsetForce(vector force, vector position)
	if not validPhysics(this) then return self:throw("Invalid physics object!", nil) end
	if not isOwner(self, this) then return self:throw("You do not own this entity!", nil) end

	force 		= clamp(force)
	position 	= clamp(position)

	local phys = this:GetPhysicsObject()
	phys:ApplyForceOffset(force, position)
end

e2function void entity:applyAngForce(angle angForce)
	if not validPhysics(this) then return self:throw("Invalid physics object!", nil) end
	if not isOwner(self, this) then return self:throw("You do not own this entity!", nil) end

	if angForce:IsZero() then return end
	angForce = clamp(angForce)

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
	if not validPhysics(this) then return self:throw("Invalid physics object!", nil) end
	if not isOwner(self, this) then return self:throw("You do not own this entity!", nil) end
	if torque:IsZero() then return end

	local phys = this:GetPhysicsObject()

	-- Convert torque from local to world axis
	torque = phys:LocalToWorldVector( clamp(torque) )
	-- Convert rad*in^2 to deg*m^2
	phys:ApplyTorqueCenter( torque * (180 / math.pi / 39.3701^2) )
end

e2function vector entity:inertia()
	if not validPhysics(this) then return self:throw("Invalid physics object!", Vector(0, 0, 0)) end
	return this:GetPhysicsObject():GetInertia()
end


--[[******************************************************************************]]

__e2setcost(10) -- temporary

e2function void entity:lockPod(lock)
	if not IsValid(this) or not this:IsVehicle() then return self:throw("Invalid vehicle!", nil) end
	if not isOwner(self, this) then return self:throw("You do not own this entity!", nil) end
	if lock ~= 0 then
		this:Fire("Lock", "", 0)
	else
		this:Fire("Unlock", "", 0)
	end
end

e2function void entity:killPod()
	if not IsValid(this) or not this:IsVehicle() then return self:throw("Invalid vehicle!", nil) end
	if not isOwner(self, this) then return self:throw("You do not own this entity!", nil) end
	local ply = this:GetDriver()
	if IsValid(ply) and ply:IsPlayer() and ply:Alive() then ply:Kill() end
end

e2function void entity:ejectPod()
	if not IsValid(this) or not this:IsVehicle() then return self:throw("Invalid vehicle!", nil) end
	if not isOwner(self, this) then return self:throw("You do not own this entity!", nil) end
	local ply = this:GetDriver()
	if IsValid(ply) then ply:ExitVehicle() end
end

e2function void entity:podStripWeapons()
	if not IsValid(this) or not this:IsVehicle() then return self:throw("Invalid vehicle!", nil) end
	if not isOwner(self, this) then return self:throw("You do not own this entity!", nil) end
	local ply = this:GetDriver()
	if IsValid(ply) and next(ply:GetWeapons()) ~= nil then
		ply:StripWeapons()
		ply:ChatPrint("Your weapons have been stripped!")
	end
end

--[[******************************************************************************]]

__e2setcost(10)

e2function vector entity:boxSize()
	if not IsValid(this) then return self:throw("Invalid entity!", Vector(0, 0, 0)) end
	return this:OBBMaxs() - this:OBBMins()
end

e2function vector entity:boxCenter()
	if not IsValid(this) then return self:throw("Invalid entity!", Vector(0, 0, 0)) end
	return this:OBBCenter()
end

-- Same as using E:toWorld(E:boxCenter()) in E2, but since Lua runs faster, this is more efficient.
e2function vector entity:boxCenterW()
	if not IsValid(this) then return self:throw("Invalid entity!", Vector(0, 0, 0)) end
	return this:LocalToWorld(this:OBBCenter())
end

e2function vector entity:boxMax()
	if not IsValid(this) then return self:throw("Invalid entity!", Vector(0, 0, 0)) end
	return this:OBBMaxs()
end

e2function vector entity:boxMin()
	if not IsValid(this) then return self:throw("Invalid entity!", Vector(0, 0, 0)) end
	return this:OBBMins()
end


--[[******************************************************************************]]

-- Returns the entity's (min) axis-aligned bounding box
e2function vector entity:aabbMin()
	if not IsValid(this) or not IsValid(this:GetPhysicsObject()) then return self:throw("Invalid physics object!", Vector(0, 0, 0)) end
	local ret, _ = this:GetPhysicsObject():GetAABB()
	return ret or Vector(0, 0, 0)
end

-- Returns the entity's (max) axis-aligned bounding box
e2function vector entity:aabbMax()
	if not IsValid(this) or not IsValid(this:GetPhysicsObject()) then return self:throw("Invalid physics object!", Vector(0, 0, 0)) end
	local _, ret = this:GetPhysicsObject():GetAABB()
	return ret or Vector(0, 0, 0)
end

-- Returns the entity's axis-aligned bounding box size
e2function vector entity:aabbSize()
	if not IsValid(this) or not IsValid(this:GetPhysicsObject()) then return self:throw("Invalid physics object!", Vector(0, 0, 0)) end
	local ret, ret2 = this:GetPhysicsObject():GetAABB()
	ret = ret or Vector(0,0,0)
	ret2 = ret2 or Vector(0,0,0)
	return ret2 - ret
end


--[[******************************************************************************]]

-- Returns the rotated entity's min world-axis-aligned bounding box corner
e2function vector entity:aabbWorldMin()
	if not IsValid(this) then return self:throw("Invalid entity!", Vector(0, 0, 0)) end
	local ret, _ = this:WorldSpaceAABB()
	return ret or Vector(0, 0, 0)
end

-- Returns the rotated entity's max world-axis-aligned bounding box corner
e2function vector entity:aabbWorldMax()
	if not IsValid(this) then return self:throw("Invalid entity!", Vector(0, 0, 0)) end
	local _, ret = this:WorldSpaceAABB()
	return ret or Vector(0, 0, 0)
end

-- Returns the rotated entity's world-axis-aligned bounding box size
e2function vector entity:aabbWorldSize()
	if not IsValid(this) then return self:throw("Invalid entity!", Vector(0, 0, 0)) end
	local ret, ret2 = this:WorldSpaceAABB()
	ret = ret or Vector(0,0,0)
	ret2 = ret2 or Vector(0,0,0)
	return ret2 - ret
end
--[[******************************************************************************]]

hook.Add("PlayerLeaveVehicle","Exp2RunOnLeaveVehicle",function(ply, vehicle)
	E2Lib.triggerEvent("playerLeftVehicle", { ply, vehicle } )
end)

hook.Add("PlayerEnteredVehicle","Exp2RunOnEnteredVehicle", function(ply, vehicle)
	E2Lib.triggerEvent("playerEnteredVehicle", { ply, vehicle })
end)

__e2setcost(5)

e2function entity entity:driver()
	if not IsValid(this) or not this:IsVehicle() then return self:throw("Invalid vehicle!", nil) end
	return this:GetDriver()
end

e2function entity entity:passenger()
	if not IsValid(this) or not this:IsVehicle() then return self:throw("Invalid vehicle!", nil) end
	return this:GetPassenger(0)
end

--- Returns <ent> formatted as a string. Returns "<code>(null)</code>" for invalid entities.
e2function string toString(entity ent)
	if not IsValid(ent) then return "(null)" end
	return tostring(ent)
end

e2function string entity:toString() = e2function string toString(entity ent)

E2Lib.registerEvent("playerLeftVehicle", {
	{ "Player", "e" },
	{ "Vehicle", "e" },
})
E2Lib.registerEvent("playerEnteredVehicle", {
	{ "Player", "e" },
	{ "Vehicle", "e" },
})

--[[******************************************************************************]]

local function composedata(startSize, endSize, length, material, color, alpha)
	if string.find(material, '"', 1, true) then return nil end

	endSize = math.Clamp( endSize, 0, 128 )
	startSize = math.Clamp( startSize, 0, 128 )

	return {
		Color = Color( color[1], color[2], color[3], alpha ),
		Length = length,
		StartSize = startSize,
		EndSize = endSize,
		Material = material,
	}
end

local function validateCanTrail(self, ent)
	if not checkOwner(self) then return end
	if not IsValid(ent) then return self:throw("Invalid entity!", nil) end
	if not isOwner(self, ent) then return self:throw("You do not own this entity!", nil) end
end

local function removeTrail(self, ent)
	local PlayerSteamID = self.player:SteamID()
	if not trailedEntsAmount[PlayerSteamID] then return end
	if not trailedEntsAmount[PlayerSteamID][ent] then return end

	trailedEntsAmount[PlayerSteamID][ent] = nil
	duplicator.EntityModifiers.trail(self.player, ent, nil)
end

local function setTrail(self, ent, Data)
	local PlayerSteamID = self.player:SteamID()
	if not trailedEntsAmount[PlayerSteamID] then trailedEntsAmount[PlayerSteamID] = {} end

	-- Removing a trail (just in case)
	if Data == nil then
		removeTrail(self, ent)
		return
	end

	-- Setting a trail
	if wire_expression2_entity_trails_max:GetInt() < table.Count(trailedEntsAmount[PlayerSteamID])+1 then return self:throw("Trails limit reached!", nil) end
	trailedEntsAmount[PlayerSteamID][ent] = true
	ent:CallOnRemove("wire_expression2_trail_remove", function(ent)
		trailedEntsAmount[PlayerSteamID][ent] = nil
	end)

	duplicator.EntityModifiers.trail(self.player, ent, Data)
end

__e2setcost(50)

--- Removes the trail from <this>.
e2function void entity:removeTrails()
	validateCanTrail(self, this)
	removeTrail(self, this)
end

__e2setcost(75)

--- StartSize, EndSize, Length, Material, Color (RGB), Alpha
--- Adds a trail to <this> with the specified attributes.
e2function void entity:setTrails(startSize, endSize, length, string material, vector color, alpha)
	validateCanTrail(self, this)

	local Data = composedata(startSize, endSize, length, material, color, alpha)
	if not Data then return end

	setTrail(self, this, Data)
end

e2function void entity:setTrails(startSize, endSize, length, string material, vector4 color)
	validateCanTrail(self, this)

	local Data = composedata(startSize, endSize, length, material, { color[1], color[2], color[3] }, color[4])
	if not Data then return end

	setTrail(self, this, Data)
end

e2function void entity:setTrails(startSize, endSize, length, string material)
	validateCanTrail(self, this)

	local Data = composedata(startSize, endSize, length, material, { 255, 255, 255 }, 255)
	if not Data then return end

	setTrail(self, this, Data)
end

-- + Attachments
e2function void entity:setTrails(startSize, endSize, length, string material, vector color, alpha, attachmentID, additive)
	validateCanTrail(self, this)

	local Data = composedata(startSize, endSize, length, material, color, alpha)
	if not Data then return end

	Data.AttachmentID = attachmentID
	Data.Additive = additive ~= 0

	setTrail(self, this, Data)
end

__e2setcost(2)

[nodiscard]
e2function number trailsLeft()
	return wire_expression2_entity_trails_max:GetInt() - table.Count(trailedEntsAmount[self.player:SteamID()] or {})
end

[nodiscard]
e2function number trailsCount()
	return table.Count(trailedEntsAmount[self.player:SteamID()] or {})
end

__e2setcost(1)

[nodiscard]
e2function number trailsMax()
	return wire_expression2_entity_trails_max:GetInt()
end

--[[******************************************************************************]]

__e2setcost( 15 )

--- Returns <this>'s attachment ID associated with <attachmentName>
e2function number entity:lookupAttachment(string attachmentName)
	if not IsValid(this) then return self:throw("Invalid entity!", 0) end
	return this:LookupAttachment(attachmentName)
end

--- Returns <this>'s attachment position associated with <attachmentID>
e2function vector entity:attachmentPos(attachmentID)
	if not IsValid(this) then return self:throw("Invalid entity!", Vector(0, 0, 0)) end
	local attachment = this:GetAttachment(attachmentID)
	if not attachment then return Vector(0, 0, 0) end
	return attachment.Pos
end

--- Returns <this>'s attachment angle associated with <attachmentID>
e2function angle entity:attachmentAng(attachmentID)
	if not IsValid(this) then return self:throw("Invalid entity!", Angle(0, 0, 0)) end
	local attachment = this:GetAttachment(attachmentID)
	if not attachment then return Angle(0, 0, 0) end
	local ang = attachment.Ang
	return Angle(ang.p, ang.y, ang.r)
end

--- Same as <this>:attachmentPos(entity:lookupAttachment(<attachmentName>))
e2function vector entity:attachmentPos(string attachmentName)
	if not IsValid(this) then return self:throw("Invalid entity!", Vector(0, 0, 0)) end
	local attachment = this:GetAttachment(this:LookupAttachment(attachmentName))
	if not attachment then return Vector(0, 0, 0) end
	return attachment.Pos
end

--- Same as <this>:attachmentAng(entity:lookupAttachment(<attachmentName>))
e2function angle entity:attachmentAng(string attachmentName)
	if not IsValid(this) then return self:throw("Invalid entity!", Angle(0, 0, 0)) end
	local attachment = this:GetAttachment(this:LookupAttachment(attachmentName))
	if not attachment then return Angle(0, 0, 0) end
	local ang = attachment.Ang
	return Angle(ang.p, ang.y, ang.r)
end

__e2setcost(20)

-- Returns a table containing all attachments for <this>
e2function array entity:attachments()
	if not IsValid(this) then return self:throw("Invalid entity!", {}) end
	local tmp = {}
	local atc = this:GetAttachments()
	for i=1, #atc do
		tmp[i] = atc[i].name
	end
	return tmp
end

--[[******************************************************************************]]

__e2setcost(15)

e2function vector entity:nearestPoint( vector point )
	if not IsValid(this) then return self:throw("Invalid entity!", Vector(0, 0, 0)) end
	return this:NearestPoint(point)
end

--[[******************************************************************************]]

local Enabled = CreateConVar("wire_expression2_entity_ignite_enabled", 1, FCVAR_ARCHIVE, "Whether E2s can ignite people, given they have 'ignite' permissions.")
local MaxLength = CreateConVar("wire_expression2_entity_ignite_length_max", 60 * 60 * 100, FCVAR_ARCHIVE, "Max length an E2 can ignite someone for in seconds.", 0)
local MaxRadius = CreateConVar("wire_expression2_entity_ignite_radius_max", 500, FCVAR_ARCHIVE, "Max radius of ignition an E2 can create")

e2function void entity:ignite()
	if not IsValid(this) then return self:throw("Invalid entity!", nil) end
	if not Enabled:GetBool() then return self:throw("Igniting entities is disabled via wire_expression2_entity_ignite_enabled", nil) end
	if not canProperty(self.player, this, "ignite") then return self:throw("You cannot ignite this entity!", nil) end

	this:Ignite(360)
end

e2function void entity:ignite(number length)
	if not IsValid(this) then return self:throw("Invalid entity!", nil) end
	if not Enabled:GetBool() then return self:throw("Igniting entities is disabled via wire_expression2_entity_ignite_enabled", nil) end
	if not canProperty(self.player, this, "ignite") then return self:throw("You cannot ignite this entity!", nil) end

	this:Ignite( math.min(length, MaxLength:GetFloat()) )
end

e2function void entity:ignite(number length, number radius)
	if not IsValid(this) then return self:throw("Invalid entity!", nil) end
	if not Enabled:GetBool() then return self:throw("Igniting entities is disabled via wire_expression2_entity_ignite_enabled", nil) end
	if not canProperty(self.player, this, "ignite") then return self:throw("You cannot ignite this entity!", nil) end

	this:Ignite( math.min(length, MaxLength:GetFloat()), math.Clamp(radius, 0, MaxRadius:GetFloat()) )
end

e2function void entity:extinguish()
	if not IsValid(this) then return self:throw("Invalid entity!", nil) end
	if not canProperty(self.player, this, "extinguish") then return self:throw("You cannot extinguish this entity!", nil) end

	this:Extinguish()
end

E2Lib.registerConstant("COLLISION_GROUP_NONE", COLLISION_GROUP_NONE)
E2Lib.registerConstant("COLLISION_GROUP_DEBRIS", COLLISION_GROUP_DEBRIS)
E2Lib.registerConstant("COLLISION_GROUP_DEBRIS_TRIGGER", COLLISION_GROUP_DEBRIS_TRIGGER)
E2Lib.registerConstant("COLLISION_GROUP_INTERACTIVE_DEBRIS", COLLISION_GROUP_INTERACTIVE_DEBRIS)
E2Lib.registerConstant("COLLISION_GROUP_INTERACTIVE", COLLISION_GROUP_INTERACTIVE)
E2Lib.registerConstant("COLLISION_GROUP_PLAYER", COLLISION_GROUP_PLAYER)
E2Lib.registerConstant("COLLISION_GROUP_BREAKABLE_GLASS", COLLISION_GROUP_BREAKABLE_GLASS)
E2Lib.registerConstant("COLLISION_GROUP_VEHICLE", COLLISION_GROUP_VEHICLE)
E2Lib.registerConstant("COLLISION_GROUP_PLAYER_MOVEMENT", COLLISION_GROUP_PLAYER_MOVEMENT)
E2Lib.registerConstant("COLLISION_GROUP_NPC", COLLISION_GROUP_NPC)
E2Lib.registerConstant("COLLISION_GROUP_IN_VEHICLE", COLLISION_GROUP_IN_VEHICLE)
E2Lib.registerConstant("COLLISION_GROUP_WEAPON", COLLISION_GROUP_WEAPON)
E2Lib.registerConstant("COLLISION_GROUP_VEHICLE_CLIP", COLLISION_GROUP_VEHICLE_CLIP)
E2Lib.registerConstant("COLLISION_GROUP_PROJECTILE", COLLISION_GROUP_PROJECTILE)
E2Lib.registerConstant("COLLISION_GROUP_DOOR_BLOCKER", COLLISION_GROUP_DOOR_BLOCKER)
E2Lib.registerConstant("COLLISION_GROUP_PASSABLE_DOOR", COLLISION_GROUP_PASSABLE_DOOR)
E2Lib.registerConstant("COLLISION_GROUP_DISSOLVING", COLLISION_GROUP_DISSOLVING)
E2Lib.registerConstant("COLLISION_GROUP_PUSHAWAY", COLLISION_GROUP_PUSHAWAY)
E2Lib.registerConstant("COLLISION_GROUP_NPC_ACTOR", COLLISION_GROUP_NPC_ACTOR)
E2Lib.registerConstant("COLLISION_GROUP_NPC_SCRIPTED", COLLISION_GROUP_NPC_SCRIPTED)
E2Lib.registerConstant("COLLISION_GROUP_WORLD", COLLISION_GROUP_WORLD)

[nodiscard]
e2function number entity:getCollisionGroup()
	if not IsValid(this) then return self:throw("Invalid entity!", -1) end
	return this:GetCollisionGroup()
end

e2function void entity:setCollisionGroup(number group)
	if not IsValid(this) then return self:throw("Invalid entity!", nil) end
	if group < 0 or group > 20 then return self:throw("Invalid collision group", nil) end
	if not isOwner(self, this) then return self:throw("You do not own this entity!", nil) end
	if this:IsPlayer() then return self:throw("You cannot set the collision group of a player!", nil) end

	this:SetCollisionGroup(group)
end

e2function void entity:noCollideAll(number state)
	if not IsValid(this) then return self:throw("Invalid entity!", nil) end
	if not isOwner(self, this) then return self:throw("You do not own this prop!", nil) end

	this:SetCollisionGroup(state == 0 and COLLISION_GROUP_NONE or COLLISION_GROUP_WORLD)
end

--[[******************************************************************************]]
-- Flexes

__e2setcost(5)

e2function array entity:getFlexBounds(number flex)
	if not IsValid(this) then return self:throw("Invalid entity!", {}) end
	return { this:GetFlexBounds(flex) }
end

e2function number entity:getFlexCount()
	if not IsValid(this) then return self:throw("Invalid entity!", 0) end
	return this:GetFlexNum()
end

e2function number entity:getFlexID(string flex)
	if not IsValid(this) then return self:throw("Invalid entity!", 0) end
	return this:GetFlexIDByName(flex) or -1
end

e2function number entity:getFlexScale()
	if not IsValid(this) then return self:throw("Invalid entity!", 0) end
	return this:GetFlexScale()
end

e2function string entity:getFlexName(number id)
	if not IsValid(this) then return self:throw("Invalid entity!", "") end
	return this:GetFlexName(id) or ""
end

e2function number entity:getFlexWeight(number flex)
	if not IsValid(this) then return self:throw("Invalid entity!", 0) end
	return this:GetFlexWeight(flex)
end

e2function number entity:hasFlexes()
	if not IsValid(this) then return self:throw("Invalid entity!", 0) end
	return this:HasFlexManipulator() and 1 or 0
end

__e2setcost(15)

e2function array entity:getFlexBounds(string flex)
	if not IsValid(this) then return self:throw("Invalid entity!", {}) end
	flex = this:GetFlexIDByName(flex)
	return flex and { this:GetFlexBounds(flex) } or {}
end

e2function number entity:getFlexWeight(string flex)
	if not IsValid(this) then return self:throw("Invalid entity!", 0) end
	flex = this:GetFlexIDByName(flex)
	return flex and this:GetFlexWeight(flex) or 0
end

__e2setcost(50)

e2function array entity:getFlexes()
	if not IsValid(this) then return self:throw("Invalid entity!", {}) end
	local ret = {}
	for i = 0, this:GetFlexNum() - 1 do
		ret[i] = this:GetFlexName(i)
	end
	self.prf = self.prf + (#ret + 1) * 5
	return ret
end

--[[******************************************************************************]]
-- Model bones

__e2setcost(5)

e2function number entity:getModelBoneCount()
	if not IsValid(this) then return self:throw("Invalid entity!", 0) end

	return this:GetBoneCount()
end

e2function number entity:getModelBoneIndex(string bone_name)
	if not IsValid(this) then return self:throw("Invalid entity!", 0) end

	return this:LookupBone(bone_name) or -1
end

e2function number entity:getModelBoneName(bone_index)
	if not IsValid(this) then return self:throw("Invalid entity!", "") end

	return this:GetBoneName(bone_index) or ""
end

__e2setcost(50)

e2function array entity:getModelBones()
	if not IsValid(this) then return self:throw("Invalid entity!", {}) end
	local ret = {}
	for i = 0, this:GetBoneCount() - 1 do
		ret[i] = this:GetBoneName(i)
	end
	self.prf = self.prf + (#ret + 1) * 5
	return ret
end

--[[******************************************************************************]]
-- End e2functions

hook.Add("OnEntityCreated", "E2_entityCreated", function(ent)
	if not IsValid(ent) then return end -- Engine is precaching a model or bad addon

	timer.Simple(0, function() -- Removing entities on the same execution they're created does bad things so add a delay to prevent malicious usage
		E2Lib.triggerEvent("entityCreated", { ent })
	end)
end)

E2Lib.registerEvent("entityCreated", {
	{ "Entity", "e" }
})

local function upperfirst( word )
	return word:Left(1):upper() .. word:Right(-2):lower()
end

local fixDefault = E2Lib.fixDefault

local non_allowed_types = {
	xgt = true,
}

local enttbls
local function createEntsTbls()
	enttbls = setmetatable({},{__index=function(t,k) local r=setmetatable({},{__index=function(t,k) local r={} t[k]=r return r end}) t[k]=r return r end})
end
createEntsTbls()
hook.Add("Wire_EmergencyRamClear","E2_ClearEntTbls",createEntsTbls)
local function cleanEntsTbls(ent)
	for k, v in pairs(enttbls) do
		v[ent] = nil
		if next(v)==nil then
			enttbls[k] = nil
		end
	end
end

registerCallback("postinit",function()
	for k, v in pairs( wire_expression_types ) do
		if not non_allowed_types[v[1]] then
			if k == "NORMAL" then k = "NUMBER" end
			k = upperfirst(k)

			__e2setcost(5)

			local function getf(self, ent, key)
				if IsValid(ent) and key and rawget(enttbls, self.uid) and rawget(enttbls[self.uid], ent) then
					return enttbls[self.uid][ent][key] or fixDefault( v[2] )
				end

				return fixDefault( v[2] )
			end

			local function setf(self, ent, key, value)
				if IsValid(ent) and key and value ~= nil then
					ent:CallOnRemove("E2_ClearEntTbls", cleanEntsTbls)
					enttbls[self.uid][ent][key] = value
				end
			end

			registerOperator("indexget", "es" .. v[1], v[1], getf)
			registerOperator("indexset", "es" .. v[1], v[1], setf)
		end -- allowed check
	end -- loop
end) -- postinit
