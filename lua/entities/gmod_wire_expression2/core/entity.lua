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

e2function entity operator=(entity lhs, entity rhs)
	self.vars[lhs] = rhs
	self.vclk[lhs] = true
	return rhs
end

/******************************************************************************/

e2function number operator_is(entity ent)
	if validEntity(ent) then return 1 else return 0 end
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
	if not validEntity(ent) then return nil end
	return ent
end

e2function number entity:id()
	if not validEntity(this) then return 0 end
	return this:EntIndex()
end

/******************************************************************************/
// Functions getting string

e2function entity noentity()
	return nil
end

e2function string entity:type()
	if not validEntity(this) then return "" end
	return this:GetClass()
end

e2function string entity:model()
	if not validEntity(this) then return "" end
	return this:GetModel()
end

e2function entity entity:owner()
	if not validEntity(this) then return nil end
	return getOwner(self, this)
end

/******************************************************************************/
// Functions getting vector
e2function vector entity:pos()
	if not validEntity(this) then return {0,0,0} end
	return this:GetPos()
end

e2function vector entity:forward()
	if not validEntity(this) then return {0,0,0} end
	return this:GetForward()
end

e2function vector entity:right()
	if not validEntity(this) then return {0,0,0} end
	return this:GetRight()
end

e2function vector entity:up()
	if not validEntity(this) then return {0,0,0} end
	return this:GetUp()
end

e2function vector entity:vel()
	if not validEntity(this) then return {0,0,0} end
	return this:GetVelocity()
end

e2function vector entity:velL()
	if not validEntity(this) then return {0,0,0} end
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
e2function vector entity:toWorld(vector localPosition)
	if not validEntity(this) then return {0,0,0} end
	return this:LocalToWorld(Vector(localPosition[1],localPosition[2],localPosition[3]))
end

e2function vector entity:toLocal(vector worldPosition)
	if not validEntity(this) then return {0,0,0} end
	return this:WorldToLocal(Vector(worldPosition[1],worldPosition[2],worldPosition[3]))
end

e2function vector entity:toWorldAxis(vector localAxis)
	if not validEntity(this) then return {0,0,0} end
	return this:LocalToWorld(Vector(localAxis[1],localAxis[2],localAxis[3]))-this:GetPos()
end

e2function vector entity:toLocalAxis(vector worldAxis)
	if not validEntity(this) then return {0,0,0} end
	return this:WorldToLocal(Vector(worldAxis[1],worldAxis[2],worldAxis[3])+this:GetPos())
end

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
e2function number entity:health()
	if not validEntity(this) then return 0 end
	return this:Health()
end

e2function number entity:radius()
	if not validEntity(this) then return 0 end
	return this:BoundingRadius()
end

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
	local mass = Clamp(mass, 0.001, 50000)
	local phys = self.entity:GetPhysicsObject()
	phys:SetMass(mass)
end

e2function void entity:setMass(mass)
	if not validPhysics(this) then return end
	if not isOwner(self, this) then return end
	if(this:IsPlayer()) then return end
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
	if not validEntity(this) then return 0 end
	if this:IsPlayer() then return 1 else return 0 end
end

e2function number entity:isNPC()
	if not validEntity(this) then return 0 end
	if this:IsNPC() then return 1 else return 0 end
end

e2function number entity:isVehicle()
	if not validEntity(this) then return 0 end
	if this:IsVehicle() then return 1 else return 0 end
end

e2function number entity:isWorld()
	if not validEntity(this) then return 0 end
	if this:IsWorld() then return 1 else return 0 end
end

e2function number entity:isOnGround()
	if not validEntity(this) then return 0 end
	if this:IsOnGround() then return 1 else return 0 end
end

e2function number entity:isUnderWater()
	if not validEntity(this) then return 0 end
	if this:WaterLevel() > 0 then return 1 else return 0 end
end

/******************************************************************************/
// Functions getting angles

e2function angle entity:angles()
	if not validEntity(this) then return {0,0,0} end
	local ang = this:GetAngles()
	return {ang.p,ang.y,ang.r}
end

/******************************************************************************/

e2function string entity:getMaterial()
	if not validEntity(this) then return end
	return this:GetMaterial()
end

e2function void entity:setMaterial(string material)
	if not validEntity(this) then return end
	if not isOwner(self, this) then return end
	this:SetMaterial(material)
end

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

e2function number entity:isPlayerHolding()
	if not validEntity(this) then return 0 end
	if this:IsPlayerHolding() then return 1 else return 0 end
end

e2function number entity:isOnFire()
	if not validEntity(this) then return 0 end
	if this:IsOnFire() then return 1 else return 0 end
end

e2function number entity:isWeapon()
	if not validEntity(this) then return 0 end
	if this:IsWeapon() then return 1 else return 0 end
end

e2function number entity:isFrozen()
	if not validPhysics(this) then return 0 end
	local phys = this:GetPhysicsObject()
	if phys:IsMoveable() then return 0 else return 1 end
end

e2function number entity:inVehicle()
	if not validEntity(this) then return 0 end
	if(this:IsPlayer() and this:InVehicle()) then return 1 else return 0 end
end

e2function number entity:timeConnected()
	if not validEntity(this) then return 0 end
	if(this:IsPlayer()) then return this:TimeConnected() else return 0 end
end

--- Returns 1 if the player <this> is in noclip mode, 0 if not.
e2function number entity:inNoclip()
	if not this or this:GetMoveType() ~= MOVETYPE_NOCLIP then return 0 end
	return 1
end

/******************************************************************************/

__e2setcost(30) -- temporary

e2function void entity:applyForce(vector force)
	if not validPhysics(this) then return nil end
	if not isOwner(self, this) then return nil end
	local phys = this:GetPhysicsObject()
	phys:ApplyForceCenter(Vector(force[1],force[2],force[3]))
end

e2function void entity:applyOffsetForce(vector force, vector position)
	if not validPhysics(this) then return nil end
	if not isOwner(self, this) then return nil end
	local phys = this:GetPhysicsObject()
	phys:ApplyForceOffset(Vector(force[1],force[2],force[3]), Vector(position[1],position[2],position[3]))
end

e2function void entity:applyAngForce(angle angForce)
	if not validPhysics(this) then return nil end
	if not isOwner(self, this) then return nil end
	local phys = this:GetPhysicsObject()

	-- assign vectors
	local pos = this:LocalToWorld(phys:GetMassCenter())
	local up = this:GetUp()
	local left = this:GetRight()*-1
	local forward = this:GetForward()

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

	off = off * dir:Length() * 0.5
	dir:Normalize()

	dir = phys:LocalToWorld(dir)-phys:GetPos()
	local masscenter = phys:GetMassCenter()
	phys:ApplyForceOffset( dir     , phys:LocalToWorld(masscenter+off) )
	phys:ApplyForceOffset( dir * -1, phys:LocalToWorld(masscenter-off) )
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

	off = off * dir:Length() * 0.5
	dir:Normalize()

	dir = phys:LocalToWorld(dir)-phys:GetPos()
	phys:ApplyForceOffset( dir     , phys:LocalToWorld(offset+off) )
	phys:ApplyForceOffset( dir * -1, phys:LocalToWorld(offset-off) )
end

e2function vector entity:inertia()
	if not validPhysics(this) then return {0,0,0} end
	return this:GetPhysicsObject():GetInertia()
end


/******************************************************************************/

__e2setcost(5) -- temporary

e2function void entity:lockPod(lock)
	if not validEntity(this) or not this:IsVehicle() then return end
	if not isOwner(self, this) then return end
	if(lock ~= 0) then
		this:Fire("Lock", "", 0)
	else
		this:Fire("Unlock", "", 0)
	end
end

e2function void entity:killPod()
	if not validEntity(this) or not this:IsVehicle() then return end
	if not isOwner(self, this) then return end
	local ply = this:GetDriver()
	if(ply:IsValid()) then ply:Kill() end
end

e2function void entity:ejectPod()
	if not validEntity(this) or not this:IsVehicle() then return end
	if not isOwner(self, this) then return end
	local ply = this:GetDriver()
	if(ply:IsValid()) then ply:ExitVehicle() end
end

/******************************************************************************/

e2function entity entity:aimEntity()
	if not validEntity(this) then return nil end
	if not this:IsPlayer() then return nil end

	local ent = this:GetEyeTraceNoCursor().Entity
	if not ent:IsValid() then return nil end
	return ent
end

e2function vector entity:aimPos()
	if not validEntity(this) then return {0,0,0} end
	if not this:IsPlayer() then return {0,0,0} end

	return this:GetEyeTraceNoCursor().HitPos
end

e2function vector entity:aimNormal()
	if not validEntity(this) then return {0,0,0} end
	if not this:IsPlayer() then return {0,0,0} end

	return this:GetEyeTraceNoCursor().HitNormal
end

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

e2function vector entity:boxSize()
	if not validEntity(this) then return {0,0,0} end
	return this:OBBMaxs() - this:OBBMins()
end

e2function vector entity:boxCenter()
	if not validEntity(this) then return {0,0,0} end
	return this:OBBCenter()
end

e2function vector entity:boxMax()
	if not validEntity(this) then return {0,0,0} end
	return this:OBBMaxs()
end

e2function vector entity:boxMin()
	if not validEntity(this) then return {0,0,0} end
	return this:OBBMins()
end

/******************************************************************************/

e2function entity entity:driver()
	if not validEntity(this) or not this:IsVehicle() then return nil end
	return this:GetDriver()
end

e2function entity entity:passenger()
	if not validEntity(this) or not this:IsVehicle() then return nil end
	return this:GetPassenger()
end

--- Returns <ent> formatted as a string. Returns "<code>(null)</code>" for invalid entities.
e2function string toString(entity ent)
	if not validEntity(ent) then return "(null)" end
	return tostring(ent)
end

e2function string entity:toString() = e2function string toString(entity ent)

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

local function upperfirst( word )
	return word:Left(1):upper() .. word:Right(-2):lower()
end

local function fixdef( def )
	if (type(def) == "table") then return table.Copy(def) else return def end
end

/******************************************************************************/

local non_allowed_types = { "xgt", "t", "r" } -- If anyone can think of any other types that should never be allowed, enter them here.

registerCallback("postinit",function()
	for k,v in pairs( wire_expression_types ) do
		if (!table.HasValue(non_allowed_types,v[1])) then
			if (k == "NORMAL") then k = "NUMBER" end
			k = upperfirst(k)

			__e2setcost(5)

			local function getf( self, args )
				local op1, op2 = args[2], args[3]
				local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
				if (!rv1 or !rv1:IsValid() or !rv2) then return fixdef( v[2] ) end
				local id = self.player:UniqueID()
				if (!rv1["EVar_"..id]) then return fixdef( v[2] ) end
				return rv1["EVar_"..id][rv2] or fixdef( v[2] )
			end

			local function setf( self, args )
				local op1, op2, op3 = args[2], args[3], args[4]
				local rv1, rv2, rv3 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3)
				local id = self.player:UniqueID()
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

__e2setcost(nil)

