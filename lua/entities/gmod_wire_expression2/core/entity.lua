/******************************************************************************\
  Entity support
\******************************************************************************/

registerType("entity", "e", nil,
	nil,
	function(self,output) return output or NULL end,
	function(retval)
		if IsValid(retval) then return end
		if retval == nil then return end
		if not retval.EntIndex then error("Return value is neither nil nor an Entity, but a "..type(retval).."!",0) end
	end,
	function(v)
		return not isentity(v) or not v:IsValid()
	end
)

/******************************************************************************/

-- import some e2lib functions
local validPhysics = E2Lib.validPhysics
local getOwner     = E2Lib.getOwner
local isOwner      = E2Lib.isOwner

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
local abs = math.abs
local atan2 = math.atan2
local sqrt = math.sqrt
local asin = math.asin
local Clamp = math.Clamp

local rad2deg = 180 / math.pi

/******************************************************************************/

local function checkOwner(self)
	return IsValid(self.player);
end

/******************************************************************************/
// Functions using operators

__e2setcost(5) -- temporary

registerOperator("ass", "e", "e", function(self, args)
	local op1, op2, scope = args[2], args[3], args[4]
	local      rv2 = op2[1](self, op2)
	self.Scopes[scope][op1] = rv2
	self.Scopes[scope].vclk[op1] = true
	return rv2
end)

/******************************************************************************/

e2function number operator_is(entity ent)
	if IsValid(ent) then return 1 else return 0 end
end

e2function number operator==(entity lhs, entity rhs)
	if lhs == rhs then return 1 else return 0 end
end

e2function number operator!=(entity lhs, entity rhs)
	if lhs ~= rhs then return 1 else return 0 end
end

/******************************************************************************/

e2function entity entity(id)
	local ent = ents.GetByIndex(id)
	if not IsValid(ent) then return nil end
	return ent
end

e2function number entity:id()
	if not IsValid(this) then return 0 end
	return this:EntIndex()
end

/******************************************************************************/
// Functions getting string

e2function entity noentity()
	return NULL
end

e2function entity world()
	return game.GetWorld()
end

e2function string entity:type()
	if not IsValid(this) then return "" end
	return this:GetClass()
end

e2function string entity:model()
	if not IsValid(this) then return "" end
	return this:GetModel() or ""
end

e2function entity entity:owner()
	if not IsValid(this) then return nil end
	return getOwner(self, this)
end

/******************************************************************************/
// Functions getting vector
e2function vector entity:pos()
	if not IsValid(this) then return {0,0,0} end
	return this:GetPos()
end

e2function vector entity:forward()
	if not IsValid(this) then return {0,0,0} end
	return this:GetForward()
end

e2function vector entity:right()
	if not IsValid(this) then return {0,0,0} end
	return this:GetRight()
end

e2function vector entity:up()
	if not IsValid(this) then return {0,0,0} end
	return this:GetUp()
end

e2function vector entity:vel()
	if not IsValid(this) then return {0,0,0} end
	return this:GetVelocity()
end

e2function vector entity:velL()
	if not IsValid(this) then return {0,0,0} end
	return this:WorldToLocal(this:GetVelocity() + this:GetPos())
end

e2function angle entity:angVel()
	if not validPhysics(this) then return {0,0,0} end
	local phys = this:GetPhysicsObject()
	local vec = phys:GetAngleVelocity()
	return { vec.y, vec.z, vec.x }
end

--- Returns a vector describing rotation axis, magnitude and sense given as the vector's direction, magnitude and orientation.
e2function vector entity:angVelVector()
	if not validPhysics(this) then return { 0, 0, 0 } end
	local phys = this:GetPhysicsObject()
	return phys:GetAngleVelocity()
end

/******************************************************************************/
// Functions  using vector getting vector

__e2setcost(15)

e2function vector entity:toWorld(vector localPosition)
	if not IsValid(this) then return {0,0,0} end
	return this:LocalToWorld(Vector(localPosition[1],localPosition[2],localPosition[3]))
end

e2function vector entity:toLocal(vector worldPosition)
	if not IsValid(this) then return {0,0,0} end
	return this:WorldToLocal(Vector(worldPosition[1],worldPosition[2],worldPosition[3]))
end

e2function vector entity:toWorldAxis(vector localAxis)
	if not IsValid(this) then return {0,0,0} end
	return this:LocalToWorld(Vector(localAxis[1],localAxis[2],localAxis[3]))-this:GetPos()
end

e2function vector entity:toLocalAxis(vector worldAxis)
	if not IsValid(this) then return {0,0,0} end
	return this:WorldToLocal(Vector(worldAxis[1],worldAxis[2],worldAxis[3])+this:GetPos())
end

--- Transforms from an angle local to <this> to a world angle.
e2function angle entity:toWorld(angle localAngle)
	if not IsValid(this) then return { 0, 0, 0 } end
	local worldAngle = this:LocalToWorldAngles(Angle(localAngle[1],localAngle[2],localAngle[3]))
	return { worldAngle.p, worldAngle.y, worldAngle.r }
end

--- Transforms from a world angle to an angle local to <this>.
e2function angle entity:toLocal(angle worldAngle)
	if not IsValid(this) then return { 0, 0, 0 } end
	local localAngle = this:WorldToLocalAngles(Angle(worldAngle[1],worldAngle[2],worldAngle[3]))
	return { localAngle.p, localAngle.y, localAngle.r }
end

/******************************************************************************/
// Functions getting number

__e2setcost(5)

e2function number entity:health()
	if not IsValid(this) then return 0 end
	return this:Health()
end

e2function number entity:radius()
	if not IsValid(this) then return 0 end
	return this:BoundingRadius()
end

// original bearing & elevation thanks to Gwahir
--- Returns the bearing (yaw) from <this> to <pos>

__e2setcost(15)

e2function number entity:bearing(vector pos)
	if not IsValid(this) then return 0 end

	pos = this:WorldToLocal(Vector(pos[1],pos[2],pos[3]))

	return rad2deg*-atan2(pos.y, pos.x)
end

--- Returns the elevation (pitch) from <this> to <pos>
e2function number entity:elevation(vector pos)
	if not IsValid(this) then return 0 end

	pos = this:WorldToLocal(Vector(pos[1],pos[2],pos[3]))

	local len = pos:Length()
	if len < delta then return 0 end
	return rad2deg*asin(pos.z / len)
end

--- Returns the elevation (pitch) and bearing (yaw) from <this> to <pos>
e2function angle entity:heading(vector pos)
	if not IsValid(this) then return { 0, 0, 0 } end

	pos = this:WorldToLocal(Vector(pos[1],pos[2],pos[3]))

	-- bearing
	local bearing = rad2deg*-atan2(pos.y, pos.x)

	-- elevation
	local len = pos:Length()--sqrt(x*x + y*y + z*z)
	if len < delta then return { 0, bearing, 0 } end
	local elevation = rad2deg*asin(pos.z / len)

	return { elevation, bearing, 0 }
end

__e2setcost(10)

e2function number entity:mass()
	if not validPhysics(this) then return 0 end
	local phys = this:GetPhysicsObject()
	return phys:GetMass()
end

e2function vector entity:massCenter()
	if not validPhysics(this) then return {0,0,0} end
	local phys = this:GetPhysicsObject()
	return this:LocalToWorld(phys:GetMassCenter())
end

e2function vector entity:massCenterL()
	if not validPhysics(this) then return {0,0,0} end
	local phys = this:GetPhysicsObject()
	return phys:GetMassCenter()
end

e2function void setMass(mass)
	if not validPhysics(self.entity) then return end
	if E2Lib.isnan( mass ) then mass = 50000 end
	local mass = Clamp(mass, 0.001, 50000)
	local phys = self.entity:GetPhysicsObject()
	phys:SetMass(mass)
end

e2function void entity:setMass(mass)
	if not validPhysics(this) then return end
	if not isOwner(self, this) then return end
	if(this:IsPlayer()) then return end
	if E2Lib.isnan( mass ) then mass = 50000 end
	local mass = Clamp(mass, 0.001, 50000)
	local phys = this:GetPhysicsObject()
	phys:SetMass(mass)
end

e2function number entity:volume()
	if not validPhysics(this) then return 0 end
	local phys = this:GetPhysicsObject()
	return phys:GetVolume()
end

/******************************************************************************/
// Functions getting boolean/number
e2function number entity:isPlayer()
	if not IsValid(this) then return 0 end
	if this:IsPlayer() then return 1 else return 0 end
end

e2function number entity:isNPC()
	if not IsValid(this) then return 0 end
	if this:IsNPC() then return 1 else return 0 end
end

e2function number entity:isVehicle()
	if not IsValid(this) then return 0 end
	if this:IsVehicle() then return 1 else return 0 end
end

e2function number entity:isWorld()
	if not IsValid(this) then return 0 end
	if this:IsWorld() then return 1 else return 0 end
end

e2function number entity:isOnGround()
	if not IsValid(this) then return 0 end
	if this:IsOnGround() then return 1 else return 0 end
end

e2function number entity:isUnderWater()
	if not IsValid(this) then return 0 end
	if this:WaterLevel() > 0 then return 1 else return 0 end
end

e2function number entity:isValid()
	return IsValid(this) and 1 or 0
end

--- Returns 1 if <this> has valid physics. Note: Players do not.
e2function number entity:isValidPhysics()
	return E2Lib.validPhysics(this) and 1 or 0
end

/******************************************************************************/
// Functions getting angles

e2function angle entity:angles()
	if not IsValid(this) then return {0,0,0} end
	local ang = this:GetAngles()
	return {ang.p,ang.y,ang.r}
end

/******************************************************************************/

e2function string entity:getMaterial()
	if not IsValid(this) then return "" end
	return this:GetMaterial() or ""
end

e2function string entity:getSubMaterial(index)
	if not IsValid(this) then return "" end
	return this:GetSubMaterial(index-1) or ""
end

__e2setcost(20)

e2function array entity:getMaterials()
	if not IsValid(this) then return {} end
	return this:GetMaterials()
end

__e2setcost(10)

e2function void entity:setMaterial(string material)
	if not IsValid(this) then return end
	if not isOwner(self, this) then return end
	if string.lower(material) == "pp/copy" then return end
	this:SetMaterial(material)
end

e2function void entity:setSubMaterial(index, string material)
	if not IsValid(this) then return end
	if not isOwner(self, this) then return end
	if string.lower(material) == "pp/copy" then return end
	this:SetSubMaterial(index-1,material)
end

--- Gets <this>'s current skin number.
e2function number entity:getSkin()
	if IsValid(this) then return this:GetSkin() end
	return 0
end

--- Sets <this>'s skin number.
e2function void entity:setSkin(skin)
	if IsValid(this) then this:SetSkin(skin) end
end

--- Gets <this>'s number of skins.
e2function number entity:getSkinCount()
	if IsValid(this) then return this:SkinCount() end
	return 0
end

--- Sets <this>'s bodygroup.
e2function void entity:setBodygroup(bgrp_id, bgrp_subid)
	if not IsValid(this) then return end
	if not isOwner(self, this) then return end
	this:SetBodygroup(bgrp_id, bgrp_subid)
end

--- Gets <this>'s bodygroup count.
e2function number entity:getBodygroups(bgrp_id)
	if IsValid(this) then return this:GetBodygroupCount(bgrp_id) end
	return 0
end

/******************************************************************************/

e2function number entity:isPlayerHolding()
	if not IsValid(this) then return 0 end
	if this:IsPlayerHolding() then return 1 else return 0 end
end

e2function number entity:isOnFire()
	if not IsValid(this) then return 0 end
	if this:IsOnFire() then return 1 else return 0 end
end

e2function number entity:isWeapon()
	if not IsValid(this) then return 0 end
	if this:IsWeapon() then return 1 else return 0 end
end

e2function number entity:isFrozen()
	if not validPhysics(this) then return 0 end
	local phys = this:GetPhysicsObject()
	if phys:IsMoveable() then return 0 else return 1 end
end

/******************************************************************************/

__e2setcost(30) -- temporary

local check = WireLib.checkForce

e2function void entity:applyForce(vector force)
	if not validPhysics(this) then return nil end
	if not isOwner(self, this) then return nil end

	if check( force ) then
		local phys = this:GetPhysicsObject()
		phys:ApplyForceCenter(Vector(force[1],force[2],force[3]))
	end
end

e2function void entity:applyOffsetForce(vector force, vector position)
	if not validPhysics(this) then return nil end
	if not isOwner(self, this) then return nil end

	if check(force) and check(position) then
		local phys = this:GetPhysicsObject()
		phys:ApplyForceOffset(Vector(force[1],force[2],force[3]), Vector(position[1],position[2],position[3]))
	end
end

e2function void entity:applyAngForce(angle angForce)
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

e2function vector entity:inertia()
	if not validPhysics(this) then return {0,0,0} end
	return this:GetPhysicsObject():GetInertia()
end


/******************************************************************************/

__e2setcost(10) -- temporary

e2function void entity:lockPod(lock)
	if not IsValid(this) or not this:IsVehicle() then return end
	if not isOwner(self, this) then return end
	if(lock ~= 0) then
		this:Fire("Lock", "", 0)
	else
		this:Fire("Unlock", "", 0)
	end
end

e2function void entity:killPod()
	if not IsValid(this) or not this:IsVehicle() then return end
	if not isOwner(self, this) then return end
	local ply = this:GetDriver()
	if(ply:IsValid()) then ply:Kill() end
end

e2function void entity:ejectPod()
	if not IsValid(this) or not this:IsVehicle() then return end
	if not isOwner(self, this) then return end
	local ply = this:GetDriver()
	if(ply:IsValid()) then ply:ExitVehicle() end
end

/******************************************************************************/

__e2setcost(10)

e2function vector entity:boxSize()
	if not IsValid(this) then return {0,0,0} end
	return this:OBBMaxs() - this:OBBMins()
end

e2function vector entity:boxCenter()
	if not IsValid(this) then return {0,0,0} end
	return this:OBBCenter()
end

-- Same as using E:toWorld(E:boxCenter()) in E2, but since Lua runs faster, this is more efficient.
e2function vector entity:boxCenterW()
	if not IsValid(this) then return {0,0,0} end
	return this:LocalToWorld(this:OBBCenter())
end

e2function vector entity:boxMax()
	if not IsValid(this) then return {0,0,0} end
	return this:OBBMaxs()
end

e2function vector entity:boxMin()
	if not IsValid(this) then return {0,0,0} end
	return this:OBBMins()
end


/******************************************************************************/

-- Returns the entity's (min) axis-aligned bounding box
e2function vector entity:aabbMin()
	if (!this or !this:IsValid() or !this:GetPhysicsObject() or !this:GetPhysicsObject():IsValid()) then return {0,0,0} end
	local ret, _ = this:GetPhysicsObject():GetAABB()
	return ret or {0,0,0}
end

-- Returns the entity's (max) axis-aligned bounding box
e2function vector entity:aabbMax()
	if (!this or !this:IsValid() or !this:GetPhysicsObject() or !this:GetPhysicsObject():IsValid()) then return {0,0,0} end
	local _, ret = this:GetPhysicsObject():GetAABB()
	return ret or {0,0,0}
end

-- Returns the entity's axis-aligned bounding box size
e2function vector entity:aabbSize()
	if (!this or !this:IsValid() or !this:GetPhysicsObject() or !this:GetPhysicsObject():IsValid()) then return {0,0,0} end
	local ret, ret2 = this:GetPhysicsObject():GetAABB()
	ret = ret or Vector(0,0,0)
	ret2 = ret2 or Vector(0,0,0)
	return ret2 - ret
end

/******************************************************************************/

__e2setcost(5)

e2function entity entity:driver()
	if not IsValid(this) or not this:IsVehicle() then return nil end
	return this:GetDriver()
end

e2function entity entity:passenger()
	if not IsValid(this) or not this:IsVehicle() then return nil end
	return this:GetPassenger(0)
end

--- Returns <ent> formatted as a string. Returns "<code>(null)</code>" for invalid entities.
e2function string toString(entity ent)
	if not IsValid(ent) then return "(null)" end
	return tostring(ent)
end

e2function string entity:toString() = e2function string toString(entity ent)

/******************************************************************************/

local SetTrails = duplicator.EntityModifiers.trail

--- Removes the trail from <this>.
e2function void entity:removeTrails()
	if (not checkOwner(self)) then return; end
	if not IsValid(this) then return end
	if not isOwner(self, this) then return end

	SetTrails(self.player, this, nil)
end

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

__e2setcost(30)

--- StartSize, EndSize, Length, Material, Color (RGB), Alpha
--- Adds a trail to <this> with the specified attributes.
e2function void entity:setTrails(startSize, endSize, length, string material, vector color, alpha)
	if (not checkOwner(self)) then return; end
	if not IsValid(this) then return end
	if not isOwner(self, this) then return end

	local Data = composedata(startSize, endSize, length, material, color, alpha)
	if not Data then return end

	SetTrails(self.player, this, Data)
end


--- StartSize, EndSize, Length, Material, Color (RGB), Alpha, AttachmentID, Additive
--- Adds a trail to <this> with the specified attributes.
e2function void entity:setTrails(startSize, endSize, length, string material, vector color, alpha, attachmentID, additive)
	if (not checkOwner(self)) then return; end
	if not IsValid(this) then return end
	if not isOwner(self, this) then return end

	local Data = composedata(startSize, endSize, length, material, color, alpha)
	if not Data then return end

	Data.AttachmentID = attachmentID
	Data.Additive = additive ~= 0

	SetTrails(self.player, this, Data)
end

/******************************************************************************/

__e2setcost( 15 )

--- Returns <this>'s attachment ID associated with <attachmentName>
e2function number entity:lookupAttachment(string attachmentName)
	if not IsValid(this) then return 0 end
	return this:LookupAttachment(attachmentName)
end

--- Returns <this>'s attachment position associated with <attachmentID>
e2function vector entity:attachmentPos(attachmentID)
	if not IsValid(this) then return { 0, 0, 0 } end
	local attachment = this:GetAttachment(attachmentID)
	if not attachment then return { 0, 0, 0 } end
	return attachment.Pos
end

--- Returns <this>'s attachment angle associated with <attachmentID>
e2function angle entity:attachmentAng(attachmentID)
	if not IsValid(this) then return { 0, 0, 0 } end
	local attachment = this:GetAttachment(attachmentID)
	if not attachment then return { 0, 0, 0 } end
	local ang = attachment.Ang
	return { ang.p, ang.y, ang.r }
end

--- Same as <this>:attachmentPos(entity:lookupAttachment(<attachmentName>))
e2function vector entity:attachmentPos(string attachmentName)
	if not IsValid(this) then return { 0, 0, 0 } end
	local attachment = this:GetAttachment(this:LookupAttachment(attachmentName))
	if not attachment then return { 0, 0, 0 } end
	return attachment.Pos
end

--- Same as <this>:attachmentAng(entity:lookupAttachment(<attachmentName>))
e2function angle entity:attachmentAng(string attachmentName)
	if not IsValid(this) then return { 0, 0, 0 } end
	local attachment = this:GetAttachment(this:LookupAttachment(attachmentName))
	if not attachment then return { 0, 0, 0 } end
	local ang = attachment.Ang
	return { ang.p, ang.y, ang.r }
end

__e2setcost(20)

-- Returns a table containing all attachments for <this>
e2function array entity:attachments()
	if not IsValid(this) then return {} end
	local tmp = {}
	local atc = this:GetAttachments()
	for i=1, #atc do
		tmp[i] = atc[i].name
	end
	return tmp
end

/******************************************************************************/

__e2setcost(15)

e2function vector entity:nearestPoint( vector point )
	if (!IsValid(this)) then return {0,0,0} end
	return this:NearestPoint( Vector(point[1],point[2],point[3]) )
end

/******************************************************************************/

local function upperfirst( word )
	return word:Left(1):upper() .. word:Right(-2):lower()
end

local function fixdef( def )
	return istable(def) and table.Copy(def) or def
end

local non_allowed_types = {
	xgt = true,
	t = true,
	r = true,
	}

registerCallback("postinit",function()
	for k,v in pairs( wire_expression_types ) do
		if (!non_allowed_types[v[1]]) then
			if (k == "NORMAL") then k = "NUMBER" end
			k = upperfirst(k)

			__e2setcost(5)

			local function getf( self, args )
				local op1, op2 = args[2], args[3]
				local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
				if (!rv1 or !rv1:IsValid() or !rv2) then return fixdef( v[2] ) end
				local id = self.uid
				if (!rv1["EVar_"..id]) then return fixdef( v[2] ) end
				return rv1["EVar_"..id][rv2] or fixdef( v[2] )
			end

			local function setf( self, args )
				local op1, op2, op3 = args[2], args[3], args[4]
				local rv1, rv2, rv3 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3)
				local id = self.uid
				if (!rv1 or !rv1:IsValid() or !rv2 or !rv3) then return end
				if (!rv1["EVar_"..id]) then
					rv1["EVar_"..id] = {}
				end
				rv1["EVar_"..id][rv2] = rv3
				return rv3
			end

			registerOperator("idx", v[1].."=es", v[1], getf)
			registerOperator("idx", v[1].."=es"..v[1], v[1], setf)
		end -- allowed check
	end -- loop
end) -- postinit
