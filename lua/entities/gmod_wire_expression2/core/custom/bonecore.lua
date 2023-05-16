--Extension to bones, because they deserve it
E2Lib.RegisterExtension("bonecore", false, "Extensions to bones to achieve functional parity with propcore")

local isOwner = E2Lib.isOwner
local getBone = E2Lib.getBone
local isValidBone = E2Lib.isValidBone

local function boneVerify(self, bone)
	local ent, index = isValidBone(bone)
	if not ent then return self:throw("Invalid bone!", nil) end
	if not isOwner(self, ent) then return self:throw("You do not own this entity!", nil) end
	return ent, index
end

-- Leveraged from Propcore. Not implemented for testing.
--[[
local function validAction(self, bone, cmd)
	local ent = boneVerify(self, bone)

	-- make sure we can only perform the same action on this prop once per tick
	-- to prevent spam abuse
	if not bone.e2_bonecore_last_action then
		bone.e2_bonecore_last_action = {}
	end
	if 	bone.e2_bonecore_last_action[cmd] and
		bone.e2_bonecore_last_action[cmd] == CurTime() then return self:throw("You can only perform one type of action per tick!", false) end
	bone.e2_bonecore_last_action[cmd] = CurTime()
end
]]

-- Freezing, Pos, and Angle --

__e2setcost(20)

e2function void bone:boneFreeze(isFrozen)
	if not boneVerify(self, this) then return end
	this:EnableMotion( isFrozen == 0 )
	this:Wake()
end
	
e2function void bone:setPos(vector pos)
	if not boneVerify(self, this) then return end
	WireLib.setPos( this, pos )
end
	
e2function void bone:setAng(angle rot)
	if not boneVerify(self, this) then return end
	WireLib.setAng( this, rot )
end

e2function void entity:ragdollFreeze(isFrozen)
	if not IsValid(this) then return {} end
	local maxn = this:GetPhysicsObjectCount()-1
	
	for i = 0,maxn do
		bone = getBone(this, i)
		
		bone:EnableMotion( isFrozen == 0 )
		bone:Wake()
	end
end

-- Set Miscellaneous --

__e2setcost(10)

e2function void bone:setDrag( number drag )
	if not boneVerify(self, this) then return end
	this:EnableDrag( drag ~= 0 )
end

e2function void bone:setInertia( vector inertia )
	if not boneVerify(self, this) then return end
	if Vector( inertia[1], inertia[2], inertia[3] ):IsZero() then return end
	this:SetInertia(Vector(inertia[1], inertia[2], inertia[3]))
end

e2function void bone:setBuoyancy(number buoyancy)
	if not boneVerify(self, this) then return end
	this:SetBuoyancyRatio( math.Clamp(buoyancy, 0, 1) )
end

e2function void bone:setPhysicalMaterial(string material)
	if not boneVerify(self, this) then return end
	this:SetMaterial(material)
end

-- Set Velocity --

e2function void bone:setVelocity(vector velocity)
	ent = boneVerify(self, this)
	if not ent then return end
	ent:PhysWake()
	this:SetVelocity(Vector(velocity[1], velocity[2], velocity[3]))
	this:Wake()
end

e2function void bone:setVelocityInstant(vector velocity)
	ent = boneVerify(self, this)
	if not ent then return end
	this:SetVelocityInstantaneous(Vector(velocity[1], velocity[2], velocity[3]))
	ent:PhysWake()
	this:Wake()
end

e2function void bone:setAngVelocity(vector velocity)
	ent = boneVerify(self, this)
	if not ent then return end
	this:SetAngleVelocity(Vector(velocity[1], velocity[2], velocity[3]))
	ent:PhysWake()
	this:Wake()
end

e2function void bone:setAngVelocityInstant(vector velocity)
	ent = boneVerify(self, this)
	if not ent then return end
	this:SetAngleVelocityInstantaneous(Vector(velocity[1], velocity[2], velocity[3]))
	ent:PhysWake()
	this:Wake()
end

