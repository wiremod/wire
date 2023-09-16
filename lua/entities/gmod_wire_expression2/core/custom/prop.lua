/******************************************************************************\
Prop Core by MrFaul started by ZeikJT
report any wishes, issues to Mr.Faul@gmx.de (GER or ENG pls)
\******************************************************************************/

E2Lib.RegisterExtension("propcore", false, "Allows E2 chips to create and manipulate props", "Can be used to teleport props to arbitrary locations, including other player's faces")
PropCore = {}
local sbox_E2_maxProps = CreateConVar( "sbox_E2_maxProps", "-1", FCVAR_ARCHIVE )
local sbox_E2_maxPropsPerSecond = CreateConVar( "sbox_E2_maxPropsPerSecond", "4", FCVAR_ARCHIVE )
local sbox_E2_PropCore = CreateConVar( "sbox_E2_PropCore", "2", FCVAR_ARCHIVE ) -- 2: Players can affect their own props, 1: Only admins, 0: Disabled
local sbox_E2_canMakeStatue = CreateConVar("sbox_E2_canMakeStatue", "1", FCVAR_ARCHIVE)

local isOwner = E2Lib.isOwner
local GetBones = E2Lib.GetBones
local isValidBone = E2Lib.isValidBone
local setPos = WireLib.setPos
local setAng = WireLib.setAng

local E2totalspawnedprops = 0
local E2tempSpawnedProps = 0
local TimeStamp = 0
local playerMeta = FindMetaTable("Player")

local function TempReset()
 if (CurTime()>= TimeStamp) then
	E2tempSpawnedProps = 0
	TimeStamp = CurTime()+1
 end
end
hook.Add("Think","TempReset",TempReset)

function PropCore.WithinPropcoreLimits()
	return (sbox_E2_maxProps:GetInt() <= 0 or E2totalspawnedprops<sbox_E2_maxProps:GetInt()) and E2tempSpawnedProps < sbox_E2_maxPropsPerSecond:GetInt()
end
local WithinPropcoreLimits = PropCore.WithinPropcoreLimits

function PropCore.ValidSpawn(ply, model, vehicleType)
	local ret -- DO NOT RETURN MID-FUNCTION OR 'LimitHit' WILL BREAK
	local limithit = playerMeta.LimitHit
	playerMeta.LimitHit = function() end

	if not PropCore.WithinPropcoreLimits() then
		ret = false
	elseif not (util.IsValidProp( model ) and WireLib.CanModel(ply, model)) then
		ret = false
	elseif vehicleType then
		ret = gamemode.Call( "PlayerSpawnVehicle", ply, model, vehicleType, list.Get( "Vehicles" )[vehicleType] ) ~= false
	else
		ret = gamemode.Call( "PlayerSpawnProp", ply, model ) ~= false
	end

	playerMeta.LimitHit = limithit
	return ret
end
local ValidSpawn = PropCore.ValidSpawn

local canHaveInvalidPhysics = {
	delete=true, parent=true, deparent=true, solid=true,
	shadow=true, draw=true, use=true, pos=true, ang=true,
	manipulate=true
}

function PropCore.ValidAction(self, entity, cmd, bone)
	if cmd == "spawn" or cmd == "Tdelete" then return true end
	if not IsValid(entity) then return self:throw("Invalid entity!", false) end
	if not isOwner(self, entity) then return self:throw("You do not own this entity!", false) end
	if entity:IsPlayer() then return self:throw("You cannot modify players", false) end

	-- For cases when we'd only want to check an entity
	if cmd then
		if not canHaveInvalidPhysics[cmd] and not validPhysics(entity) then return self:throw("Invalid physics object!", false) end
		if bone then
			if not entity["bone" .. bone] then
				entity["bone" .. bone] = {}
			end
			entity = entity["bone" .. bone]
		end

		-- make sure we can only perform the same action on this prop once per tick
		-- to prevent spam abuse
		if not entity.e2_propcore_last_action then
			entity.e2_propcore_last_action = {}
		end
		if 	entity.e2_propcore_last_action[cmd] and entity.e2_propcore_last_action[cmd] == CurTime() then
			return self:throw("You can only perform one type of action per tick!", false)
		end
		entity.e2_propcore_last_action[cmd] = CurTime()
	end

	return sbox_E2_PropCore:GetInt()==2 or (sbox_E2_PropCore:GetInt()==1 and self.player:IsAdmin())
end
local ValidAction = PropCore.ValidAction

local function MakePropNoEffect(...)
	local backup = DoPropSpawnedEffect
	DoPropSpawnedEffect = function() end
	local ret = MakeProp(...)
	DoPropSpawnedEffect = backup
	return ret
end

function PropCore.CreateProp(self, model, pos, angles, freeze, vehicleType)
	if not WithinPropcoreLimits() then return self:throw("Prop limit reached! (cooldown or max)", NULL) end
	if not ValidSpawn(self.player, model, vehicleType) then return NULL end

	pos = WireLib.clampPos( pos )

	local prop

	local cleanupCategory = "props"
	local undoCategory = "e2_spawned_prop"
	local undoName = "E2 Prop"

	if vehicleType then
		local entry = list.Get("Vehicles")[vehicleType]
		if not entry or entry.Class ~= "prop_vehicle_prisoner_pod" then
			return self:throw("Seat type '" .. vehicleType .. "' is invalid", NULL)
		end

		cleanupCategory = "vehicles"
		undoCategory = "e2_spawned_seat"
		undoName = "E2 Seat"

		prop = ents.Create("prop_vehicle_prisoner_pod")
		prop:SetModel(model)
		prop:SetPos(pos)
		prop:SetAngles(angles)
		prop:SetVehicleClass(vehicleType)

		if self.data.propSpawnEffect then DoPropSpawnedEffect( prop ) end

		prop:Spawn()
		prop:SetKeyValue( "limitview", 0 )

		gamemode.Call( "PlayerSpawnedVehicle", self.player, prop )
	else
		prop = self.data.propSpawnEffect and MakeProp( self.player, pos, angles, model, {}, {} ) or MakePropNoEffect( self.player, pos, angles, model, {}, {} )
	end

	if not IsValid( prop ) then return NULL end

	prop:Activate()

	local phys = prop:GetPhysicsObject()
	if IsValid( phys ) then
		if angles ~= nil then setAng( phys, angles ) end
		phys:Wake()
		if freeze > 0 then phys:EnableMotion( false ) end
	end

	self.player:AddCleanup( cleanupCategory, prop )

	if self.data.propSpawnUndo then
		undo.Create( undoCategory )
			undo.AddEntity( prop )
			undo.SetPlayer( self.player )
		undo.Finish( undoName .. " (" .. model .. ")" )
	end

	prop:CallOnRemove( "wire_expression2_propcore_remove",
		function( prop )
			self.data.spawnedProps[ prop ] = nil
			E2totalspawnedprops = E2totalspawnedprops - 1
		end
	)

	self.data.spawnedProps[ prop ] = self.data.propSpawnUndo
	E2totalspawnedprops = E2totalspawnedprops + 1
	E2tempSpawnedProps = E2tempSpawnedProps + 1

	return prop
end
local CreateProp = PropCore.CreateProp

function PropCore.PhysManipulate(this, pos, rot, freeze, gravity, notsolid)
	local phys = this:GetPhysicsObject()
	local physOrThis = IsValid(phys) and phys or this

	if pos ~= nil then setPos( physOrThis, pos ) end
	if rot ~= nil then setAng( physOrThis, rot ) end

	if IsValid( phys ) then
		if freeze ~= nil and this:GetUnFreezable() ~= true then phys:EnableMotion( freeze == 0 ) end
		if gravity ~= nil then phys:EnableGravity( gravity ~= 0 ) end
		if notsolid ~= nil then this:SetSolid( notsolid ~= 0 and SOLID_NONE or SOLID_VPHYSICS ) end
		phys:Wake()
	end
end
local PhysManipulate = PropCore.PhysManipulate

local function boneVerify(self, bone)
	local ent, index = isValidBone(bone)
	if not ent then return self:throw("Invalid bone!", nil) end
	return ent, index
end

--------------------------------------------------------------------------------

__e2setcost(40)
e2function entity propSpawn(string model, number frozen)
	if not ValidAction(self, nil, "spawn") then return NULL end
	return CreateProp(self,model,self.entity:GetPos()+self.entity:GetUp()*25,self.entity:GetAngles(),frozen)
end

e2function entity propSpawn(entity template, number frozen)
	if not ValidAction(self, nil, "spawn") then return NULL end
	if not IsValid(template) then return NULL end
	return CreateProp(self,template:GetModel(),self.entity:GetPos()+self.entity:GetUp()*25,self.entity:GetAngles(),frozen)
end

e2function entity propSpawn(string model, vector pos, number frozen)
	if not ValidAction(self, nil, "spawn") then return NULL end
	return CreateProp(self,model,Vector(pos[1],pos[2],pos[3]),self.entity:GetAngles(),frozen)
end

e2function entity propSpawn(entity template, vector pos, number frozen)
	if not ValidAction(self, nil, "spawn") then return NULL end
	if not IsValid(template) then return NULL end
	return CreateProp(self,template:GetModel(),Vector(pos[1],pos[2],pos[3]),self.entity:GetAngles(),frozen)
end

e2function entity propSpawn(string model, angle rot, number frozen)
	if not ValidAction(self, nil, "spawn") then return NULL end
	return CreateProp(self,model,self.entity:GetPos()+self.entity:GetUp()*25,Angle(rot[1],rot[2],rot[3]),frozen)
end

e2function entity propSpawn(entity template, angle rot, number frozen)
	if not ValidAction(self, nil, "spawn") then return NULL end
	if not IsValid(template) then return NULL end
	return CreateProp(self,template:GetModel(),self.entity:GetPos()+self.entity:GetUp()*25,Angle(rot[1],rot[2],rot[3]),frozen)
end

e2function entity propSpawn(string model, vector pos, angle rot, number frozen)
	if not ValidAction(self, nil, "spawn") then return NULL end
	return CreateProp(self,model,Vector(pos[1],pos[2],pos[3]),Angle(rot[1],rot[2],rot[3]),frozen)
end

e2function entity propSpawn(entity template, vector pos, angle rot, number frozen)
	if not ValidAction(self, nil, "spawn") then return NULL end
	if not IsValid(template) then return NULL end
	return CreateProp(self,template:GetModel(),Vector(pos[1],pos[2],pos[3]),Angle(rot[1],rot[2],rot[3]),frozen)
end

--------------------------------------------------------------------------------

local offset = Vector(0, 0, 25)

__e2setcost(50)
e2function entity seatSpawn(string model, number frozen)
	if not ValidAction(self, nil, "spawn") then return NULL end
	if model == "" then model = "models/nova/airboat_seat.mdl" end
	return CreateProp(self, model, self.entity:LocalToWorld(offset), self.entity:GetAngles(), frozen, "Seat_Airboat")
end

e2function entity seatSpawn(string model, vector pos, angle rot, number frozen)
	if not ValidAction(self, nil, "spawn") then return NULL end
	if model == "" then model = "models/nova/airboat_seat.mdl" end
	return CreateProp(self, model, pos, rot, frozen, "Seat_Airboat")
end

e2function entity seatSpawn(string model, vector pos, angle rot, number frozen, string vehicleType)
	if not ValidAction(self, nil, "spawn") then return NULL end
	if model == "" then model = "models/nova/airboat_seat.mdl" end
	if vehicleType == "" then vehicleType = "Seat_Airboat" end
	return CreateProp(self, model, pos, rot, frozen, vehicleType)
end

--------------------------------------------------------------------------------

__e2setcost(10)
e2function void entity:propDelete()
	if not ValidAction(self, this, "delete") then return end
	this:Remove()
end

e2function void entity:propBreak()
	if not ValidAction(self, this, "break") then return end
	this:Fire("break",1,0)
end

e2function void entity:use()
	if not ValidAction(self, this, "use") then return end

	local ply = self.player
	if not IsValid(ply) then return end -- if the owner isn't connected to the server, do nothing

	if hook.Run( "PlayerUse", ply, this ) == false then return end
	if hook.Run( "WireUse", ply, this, self ) == false then return end

	if this.Use then
		this:Use(ply,ply,USE_ON,0)
	else
		this:Fire("use","1",0)
	end
end

__e2setcost(30)
local function removeAllIn( self, tbl )
	local count = 0
	for k,v in pairs( tbl ) do
		if (IsValid(v) and isOwner(self,v) and !v:IsPlayer()) then
			count = count + 1
			v:Remove()
		end
	end
	return count
end

e2function number table:propDelete()
	if not ValidAction(self, nil, "Tdelete") then return 0 end

	local count = removeAllIn( self, this.s )
	count = count + removeAllIn( self, this.n )

	self.prf = self.prf + count

	return count
end

e2function number array:propDelete()
	if not ValidAction(self, nil, "Tdelete") then return 0 end

	local count = removeAllIn( self, this )

	self.prf = self.prf + count

	return count
end

e2function void propDeleteAll()
	for ent in pairs( self.data.spawnedProps ) do
		if IsValid( ent ) then
			ent:Remove()
		end
	end
	self.data.spawnedProps = {}
end


__e2setcost(10)

--------------------------------------------------------------------------------
e2function void entity:propManipulate(vector pos, angle rot, number freeze, number gravity, number notsolid)
	if not ValidAction(self, this, "manipulate") then return end
	PhysManipulate(this, pos, rot, freeze, gravity, notsolid)
end

e2function void entity:propFreeze(number freeze)
	if not ValidAction(self, this, "freeze") then return end
	PhysManipulate(this, nil, nil, freeze, nil, nil)
end

e2function void entity:propNotSolid(number notsolid)
	if not ValidAction(self, this, "solid") then return end
	PhysManipulate(this, nil, nil, nil, nil, notsolid)
end

--- Makes <this> not render at all
e2function void entity:propDraw(number drawEnable)
	if not ValidAction(self, this, "draw") then return end
	this:SetNoDraw( drawEnable == 0 )
end

--- Makes <this>'s shadow not render at all
e2function void entity:propShadow(number shadowEnable)
	if not ValidAction(self, this, "shadow") then return end
	this:DrawShadow( shadowEnable ~= 0 )
end

e2function void entity:propGravity(number gravity)
	if not ValidAction(self, this, "gravity") then return end
	local physCount = this:GetPhysicsObjectCount()
	if physCount > 1 then
		for physID = 0, physCount - 1 do
			local phys = this:GetPhysicsObjectNum(physID)
			if IsValid(phys) then phys:EnableGravity( gravity ~= 0 ) end
		end
	else
		PhysManipulate(this, nil, nil, nil, gravity, nil)
	end
end

e2function void entity:propDrag( number drag )
	if not PropCore.ValidAction(self, this, "drag") then return end
	local phys = this:GetPhysicsObject()
	if IsValid( phys ) then
		phys:EnableDrag( drag ~= 0 )
	end
end

e2function void entity:propInertia( vector inertia )
	if not PropCore.ValidAction(self, this, "inertia") then return end
	if inertia:IsZero() then return end
	local phys = this:GetPhysicsObject()
	if IsValid( phys ) then
		phys:SetInertia(inertia)
	end
end

e2function void entity:propSetBuoyancy(number buoyancy)
	if not ValidAction(self, this, "buoyancy") then return end
	local phys = this:GetPhysicsObject()
	if IsValid( phys ) then
		phys:SetBuoyancyRatio( math.Clamp(buoyancy, 0, 1) )
	end
end

e2function void entity:propSetFriction(number friction)
	if not ValidAction(self, this, "friction") then return end
	this:SetFriction( math.Clamp(friction, -1000, 1000) )
end

e2function number entity:propGetFriction()
	if not ValidAction(self, this, "friction") then return 0 end
	return this:GetFriction()
end

e2function void entity:propSetElasticity(number elasticity)
	if not ValidAction(self, this, "elasticity") then return end
	this:SetElasticity( math.Clamp(elasticity, -1000, 1000) )
end

e2function number entity:propGetElasticity()
	if not ValidAction(self, this, "elasticity") then return 0 end
	return this:GetElasticity()
end

e2function void entity:propMakePersistent(number persistent)
	if not ValidAction(self, this, "persist") then return end
	if GetConVarString("sbox_persist") == "0" then return end
	if not gamemode.Call("CanProperty", self.player, "persist", this) then return end
	this:SetPersistent(persistent ~= 0)
end

e2function void entity:propPhysicalMaterial(string physprop)
	if not ValidAction(self, this, "physprop") then return end
	construct.SetPhysProp(self.player, this, 0, nil, {nil, Material = physprop})
end

e2function string entity:propPhysicalMaterial()
	if not ValidAction(self, this, "physprop") then return "" end
	local phys = this:GetPhysicsObject()
	if IsValid(phys) then return phys:GetMaterial() or "" end
	return ""
end

e2function void entity:propSetVelocity(vector velocity)
	if not ValidAction(self, this, "velocitynxt") then return end
	local phys = this:GetPhysicsObject()
	if IsValid( phys ) then
		phys:SetVelocity(velocity)
	end
end

e2function void entity:propSetVelocityInstant(vector velocity)
	if not ValidAction(self, this, "velocityins") then return end
	local phys = this:GetPhysicsObject()
	if IsValid( phys ) then
		phys:SetVelocityInstantaneous(velocity)
	end
end

e2function void entity:propSetAngVelocity(vector velocity)
	if not ValidAction(self, this, "angvel") then return end
	local phys = this:GetPhysicsObject()
	if IsValid( phys ) then
		phys:SetAngleVelocity(velocity)
	end
end

e2function void entity:propSetAngVelocityInstant(vector velocity)
	if not ValidAction(self, this, "angvelinst") then return end
	local phys = this:GetPhysicsObject()
	if IsValid( phys ) then
		phys:SetAngleVelocityInstantaneous(velocity)
	end
end

hook.Add( "CanDrive", "checkPropStaticE2", function( ply, ent ) if ent.propStaticE2 ~= nil then return false end end )
e2function void entity:propStatic( number static )
	if not ValidAction( self, this, "static" ) then return end
	if static ~= 0 and this.propStaticE2 == nil then
		local phys = this:GetPhysicsObject()
		this.propStaticE2 = phys:IsMotionEnabled()
		this.PhysgunDisabled = true
		this:SetUnFreezable( true )
		phys:EnableMotion( false )
	elseif this.propStaticE2 ~= nil then
		this.PhysgunDisabled = false
		this:SetUnFreezable( false )
		if this.propStaticE2 == true then
			local phys = this:GetPhysicsObject()
			phys:Wake()
			phys:EnableMotion( true )
		end
		this.propStaticE2 = nil
	end
end

--------------------------------------------------------------------------------

e2function void bone:boneManipulate(vector pos, angle rot, isFrozen, gravity, collision)
	local ent, index = boneVerify(self, this)
	if not ValidAction(self, ent, "manipulate", index) then return end

	setPos(this, pos)
	setAng(this, rot)

	this:EnableMotion(isFrozen == 0)
	this:EnableGravity(gravity ~= 0)
	this:EnableCollisions(collision ~= 0)

	ent:PhysWake()
end

e2function void bone:boneFreeze(isFrozen)
	if not boneVerify(self, this) then return end
	this:EnableMotion( isFrozen == 0 )
	this:Wake()
end

__e2setcost(30)

e2function void bone:setCollisions(enable)
	if not boneVerify(self, this) then return end
	this:EnableCollisions(enable ~= 0)
	this:Wake()
end

e2function void bone:setDrag( number drag )
	if not boneVerify(self, this) then return end
	this:EnableDrag( drag ~= 0 )
end

e2function void bone:setInertia( vector inertia )
	if not boneVerify(self, this) then return end
	if inertia:IsZero() then return end
	this:SetInertia(inertia)
end

e2function void bone:setBuoyancy(number buoyancy)
	if not boneVerify(self, this) then return end
	this:SetBuoyancyRatio( math.Clamp(buoyancy, 0, 1) )
end

e2function void bone:setPhysicalMaterial(string material)
	if not boneVerify(self, this) then return end
	if not ValidAction(self, this, "physmat") then return end
	this:SetMaterial(material)
end

e2function void bone:setVelocity(vector velocity)
	local ent, index = boneVerify(self, this)
	if not ValidAction(self, ent, "velocitynxt", index) then return end
	this:SetVelocity(velocity)
	ent:PhysWake()
end

e2function void bone:setVelocityInstant(vector velocity)
	local ent, index = boneVerify(self, this)
	if not ValidAction(self, ent, "velocityins", index) then return end
	this:SetVelocityInstantaneous(velocity)
	ent:PhysWake()
end

e2function void bone:setAngVelocity(vector velocity)
	local ent, index = boneVerify(self, this)
	if not ValidAction(self, ent, "angvelnxt", index) then return end
	this:SetAngleVelocity(velocity)
	ent:PhysWake()
end

e2function void bone:setAngVelocityInstant(vector velocity)
	local ent, index = boneVerify(self, this)
	if not ValidAction(self, this, "angvelinst", index) then return end
	this:SetAngleVelocityInstantaneous(velocity)
	ent:PhysWake()
end

__e2setcost(5000)

-- This code was leveraged from Garry's Mod. Perhaps it would be a bit cleaner with a slight rewrite.
e2function void entity:makeStatue(enable)
	if sbox_E2_canMakeStatue:GetInt() == 0 then return end
	if not ValidAction(self, this, "statue") then return end
	if (enable ~= 0) == this:GetNWBool("IsStatue") then return end

	local bones = this:GetPhysicsObjectCount()
	if bones < 2 then return self:throw("You can only makeStatue on ragdolls!", nil) end

	if enable ~= 0 then
		if this.StatueInfo then return end
		local ply = self.player

		this.StatueInfo = {}

		for bone = 1, bones - 1 do
			local constraint = constraint.Weld(this, this, 0, bone, 0)

			if constraint then
				this.StatueInfo[bone] = constraint
				ply:AddCleanup("constraints", constraint)
			end
		end

		this:SetNWBool("IsStatue", true)

	else
		if not this.StatueInfo then return end

		for _, v in ipairs(this.StatueInfo) do

			if IsValid(v) then
				v:Remove()
			end

		end

		this:SetNWBool("IsStatue", false)
		this.StatueInfo = nil

	end
end

--------------------------------------------------------------------------------

__e2setcost(20)
e2function void entity:setPos(vector pos)
	if not ValidAction(self, this, "pos") then return end
	PhysManipulate(this, pos, nil, nil, nil, nil)
end

e2function void entity:setLocalPos(vector pos)
	if not ValidAction(self, this, "pos") then return end
	WireLib.setLocalPos(this, pos)
end

[deprecated]
e2function void entity:reposition(vector pos) = e2function void entity:setPos(vector pos)

e2function void entity:setAng(angle rot)
	if not ValidAction(self, this, "ang") then return end
	PhysManipulate(this, nil, rot, nil, nil, nil)
end

e2function void entity:setLocalAng(angle rot)
	if not ValidAction(self, this, "ang") then return end
	WireLib.setLocalAng(this, rot)
end

[deprecated]
e2function void entity:rerotate(angle rot) = e2function void entity:setAng(angle rot)

e2function void bone:setPos(vector pos)
	local ent, index = boneVerify(self, this)
	if not ValidAction(self, ent, "pos", index) then return end
	setPos(this, pos)
	ent:PhysWake()
end

e2function void bone:setAng(angle rot)
	local ent, index = boneVerify(self, this)
	if not ValidAction(self, ent, "ang", index) then return end
	setAng(this, rot)
	ent:PhysWake()
end

__e2setcost(60)

e2function void entity:ragdollFreeze(isFrozen)
	if not ValidAction(self, this, "freeze") then return end

	for _, bone in pairs(GetBones(this)) do
		bone:EnableMotion(isFrozen == 0)
		bone:Wake()
	end


end

__e2setcost(150)

e2function void entity:ragdollSetPos(vector pos)
	if not ValidAction(self, this, "pos") then return end

	for _, bone in pairs(GetBones(this)) do
		setPos(bone, this:WorldToLocal(bone:GetPos()) + pos)
	end

	this:PhysWake()
end

e2function void entity:ragdollSetAng(angle rot)
	if not ValidAction(self, this, "rot") then return end

	for _, bone in pairs(GetBones(this)) do
		setAng(bone, bone:AlignAngles(this:GetForward():Angle(), rot))
	end

	this:PhysWake()
end

e2function table entity:ragdollGetPose()
	if not ValidAction(self, this) then return end
	local pose = E2Lib.newE2Table()
	local bones = GetBones(this)
	local originPos, originAng = bones[0]:GetPos(), bones[0]:GetAngles()

	-- We want to skip bone 0 as that will be the reference point
	for k, bone in pairs(bones) do
		local value = E2Lib.newE2Table()
		local pos, ang = WorldToLocal(bone:GetPos(), bone:GetAngles(), originPos, originAng)

		value.n[1] = pos
		value.n[2] = ang
		value.ntypes[1] = "v"
		value.ntypes[2] = "a"
		value.size = 2

		pose.n[k] = value
		pose.ntypes[k] = "t"
	end

	pose.size = #pose.n
	return pose
end

e2function void entity:ragdollSetPose(table pose, rotate)
	if not ValidAction(self, this, "pose") then return end
	if pose.size == 0 then return end
	local bones = GetBones(this)
	local originPos, originAng = bones[0]:GetPos()
	if rotate ~= 0 then
		originAng = bones[0]:GetAngles()
	else
		originAng = this:GetForward():Angle()
	end

	for k, v in pairs(pose.n) do
		local pos, ang = LocalToWorld(v.n[1], v.n[2], originPos, originAng)
		setAng(bones[k], ang)
		setPos(bones[k], pos)
	end

	this:PhysWake()

end

e2function void entity:ragdollSetPose(table pose)
	if not ValidAction(self, this, "pose") then return end
	if pose.size == 0 then return end
	local bones = GetBones(this)
	local originPos, originAng = bones[0]:GetPos(), bones[0]:GetAngles() -- Rotate by default.

	for k, v in pairs(pose.n) do
		local pos, ang = LocalToWorld(v.n[1], v.n[2], originPos, originAng)
		setAng(bones[k], ang)
		setPos(bones[k], pos)
	end

	this:PhysWake()

end


__e2setcost(20)
--------------------------------------------------------------------------------

local function getChildLength(curchild, count)
	local max = 0
	for _, v in pairs(curchild:GetChildren()) do
		max = math.max(max, getChildLength(v, count + 1))
	end
	return math.max(max, count)
end

-- Checks if there is recursive parenting, if so then returns false
-- Also checks if parent/child chain length is > 16, and if so, hard errors.
local function parent_check( self, child, parent )
	local parents = 0
	while parent:IsValid() do
		parents = parents + 1
		parent = parent:GetParent()
	end

	return ( parents + getChildLength(child, 1) ) <= 16
end

local function parent_antispam( child )
	if (child.E2_propcore_antispam or 0) > CurTime() then
		return false
	end

	child.E2_propcore_antispam = CurTime() + 0.06
	return true
end

e2function void entity:parentTo(entity target)
	if not ValidAction(self, this, "parent") then return self:throw("You do not have permission to parent to this prop!", nil) end
	if not IsValid(target) then return self:throw("Target prop is invalid.", nil) end
	if not isOwner(self, target) then return self:throw("You do not own the target prop!", nil) end
	if not parent_antispam( this ) then return self:throw("You are parenting too fast!", nil) end
	if this == target then return self:throw("You cannot parent a prop to itself") end
	if not parent_check( self, this, target ) then return self:throw("Parenting chain of entities can't exceed 16 or crash may occur", nil) end

	this:SetParent(target)
end

__e2setcost(5)
e2function void entity:deparent()
	if not ValidAction(self, this, "deparent") then return end
	this:SetParent( nil )
end
e2function void entity:parentTo() = e2function void entity:deparent()

__e2setcost(1)

e2function void propSpawnEffect(number on)
	self.data.propSpawnEffect = on ~= 0
end

e2function void propSpawnUndo(number on)
	self.data.propSpawnUndo = on ~= 0
end

e2function number propCanCreate()
	if WithinPropcoreLimits() then return 1 end
	return 0
end

registerCallback("construct",
	function(self)
		self.data.propSpawnEffect = true
		self.data.propSpawnUndo = true
		self.data.spawnedProps = {}
	end
)

registerCallback("destruct",
	function(self)
		for ent, undo in pairs( self.data.spawnedProps ) do
			if undo == false and IsValid( ent ) then
				ent:Remove()
			end
		end
	end
)
