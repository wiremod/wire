/******************************************************************************\
Prop Core by MrFaul started by ZeikJT
report any wishes, issues to Mr.Faul@gmx.de (GER or ENG pls)
\******************************************************************************/

E2Lib.RegisterExtension("propcore", false, "Allows E2 chips to create and manipulate props", "Can be used to teleport props to arbitrary locations, including other player's faces")
PropCore = {}
local sbox_E2_maxProps = CreateConVar( "sbox_E2_maxProps", "-1", FCVAR_ARCHIVE )
local sbox_E2_maxPropsPerSecond = CreateConVar( "sbox_E2_maxPropsPerSecond", "4", FCVAR_ARCHIVE )
local sbox_E2_PropCore = CreateConVar( "sbox_E2_PropCore", "2", FCVAR_ARCHIVE ) -- 2: Players can affect their own props, 1: Only admins, 0: Disabled

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

function PropCore.ValidSpawn(ply, model, isVehicle)
	local ret -- DO NOT RETURN MID-FUNCTION OR 'LimitHit' WILL BREAK
	local limithit = playerMeta.LimitHit
	playerMeta.LimitHit = function() end

	if not PropCore.WithinPropcoreLimits() then
		ret = false
	elseif not (util.IsValidProp( model ) and WireLib.CanModel(ply, model)) then
		ret = false
	elseif isVehicle then
		ret = gamemode.Call( "PlayerSpawnVehicle", ply, model, "Seat_Airboat", list.Get( "Vehicles" ).Seat_Airboat ) ~= false
	else
		ret = gamemode.Call( "PlayerSpawnProp", ply, model ) ~= false
	end

	playerMeta.LimitHit = limithit
	return ret
end

local canHaveInvalidPhysics = {delete=true, parent=true, deparent=true, solid=true, shadow=true, draw=true, use=true}
function PropCore.ValidAction(self, entity, cmd)
	if(cmd=="spawn" or cmd=="Tdelete") then return true end
	if(!IsValid(entity)) then return false end
	if(!canHaveInvalidPhysics[cmd] and !validPhysics(entity)) then return false end
	if(!isOwner(self, entity)) then return false end
	if entity:IsPlayer() then return false end

	-- make sure we can only perform the same action on this prop once per tick
	-- to prevent spam abuse
	if not entity.e2_propcore_last_action then
		entity.e2_propcore_last_action = {}
	end
	if 	entity.e2_propcore_last_action[cmd] and
		entity.e2_propcore_last_action[cmd] == CurTime() then return false end
	entity.e2_propcore_last_action[cmd] = CurTime()

	local ply = self.player
	return sbox_E2_PropCore:GetInt()==2 or (sbox_E2_PropCore:GetInt()==1 and ply:IsAdmin())
end

local function MakePropNoEffect(...)
	local backup = DoPropSpawnedEffect
	DoPropSpawnedEffect = function() end
	local ret = MakeProp(...)
	DoPropSpawnedEffect = backup
	return ret
end

function PropCore.CreateProp(self,model,pos,angles,freeze,isVehicle)
	if not PropCore.ValidSpawn(self.player, model, isVehicle) then return NULL end

	pos = WireLib.clampPos( pos )

	local prop

	local cleanupCategory = "props"
	local undoCategory = "e2_spawned_prop"
	local undoName = "E2 Prop"

	if isVehicle then
		cleanupCategory = "vehicles"
		undoCategory = "e2_spawned_seat"
		undoName = "E2 Seat"

		prop = ents.Create("prop_vehicle_prisoner_pod")
		prop:SetModel(model)
		prop:SetPos(pos)
		prop:SetAngles(angles)

		if self.data.propSpawnEffect then DoPropSpawnedEffect( prop ) end

		prop:Spawn()
		prop:SetKeyValue( "limitview", 0 )

		table.Merge( prop, { HandleAnimation = function( _, ply ) return ply:SelectWeightedSequence( ACT_HL2MP_SIT ) end } )
		gamemode.Call( "PlayerSpawnedVehicle", self.player, prop )
	else
		prop = self.data.propSpawnEffect and MakeProp( self.player, pos, angles, model, {}, {} ) or MakePropNoEffect( self.player, pos, angles, model, {}, {} )
	end

	if not IsValid( prop ) then return NULL end

	prop:Activate()

	local phys = prop:GetPhysicsObject()
	if IsValid( phys ) then
		if angles ~= nil then WireLib.setAng( phys, angles ) end
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

function PropCore.PhysManipulate(this, pos, rot, freeze, gravity, notsolid)
	local phys = this:GetPhysicsObject()
	if IsValid( phys ) then
		if pos ~= nil then WireLib.setPos( phys, Vector( pos[1],pos[2],pos[3] ) ) end
		if rot ~= nil then WireLib.setAng( phys,  Angle( rot[1],rot[2],rot[3] ) ) end
		if freeze ~= nil and this:GetUnFreezable() ~= true then phys:EnableMotion( freeze == 0 ) end
		if gravity ~= nil then phys:EnableGravity( gravity ~= 0 ) end
		if notsolid ~= nil then this:SetSolid( notsolid ~= 0 and SOLID_NONE or SOLID_VPHYSICS ) end
		phys:Wake()
	end
end

--------------------------------------------------------------------------------

__e2setcost(40)
e2function entity propSpawn(string model, number frozen)
	if not PropCore.ValidAction(self, nil, "spawn") then return NULL end
	return PropCore.CreateProp(self,model,self.entity:GetPos()+self.entity:GetUp()*25,self.entity:GetAngles(),frozen)
end

e2function entity propSpawn(entity template, number frozen)
	if not PropCore.ValidAction(self, nil, "spawn") then return NULL end
	if not IsValid(template) then return NULL end
	return PropCore.CreateProp(self,template:GetModel(),self.entity:GetPos()+self.entity:GetUp()*25,self.entity:GetAngles(),frozen)
end

e2function entity propSpawn(string model, vector pos, number frozen)
	if not PropCore.ValidAction(self, nil, "spawn") then return NULL end
	return PropCore.CreateProp(self,model,Vector(pos[1],pos[2],pos[3]),self.entity:GetAngles(),frozen)
end

e2function entity propSpawn(entity template, vector pos, number frozen)
	if not PropCore.ValidAction(self, nil, "spawn") then return NULL end
	if not IsValid(template) then return NULL end
	return PropCore.CreateProp(self,template:GetModel(),Vector(pos[1],pos[2],pos[3]),self.entity:GetAngles(),frozen)
end

e2function entity propSpawn(string model, angle rot, number frozen)
	if not PropCore.ValidAction(self, nil, "spawn") then return NULL end
	return PropCore.CreateProp(self,model,self.entity:GetPos()+self.entity:GetUp()*25,Angle(rot[1],rot[2],rot[3]),frozen)
end

e2function entity propSpawn(entity template, angle rot, number frozen)
	if not PropCore.ValidAction(self, nil, "spawn") then return NULL end
	if not IsValid(template) then return NULL end
	return PropCore.CreateProp(self,template:GetModel(),self.entity:GetPos()+self.entity:GetUp()*25,Angle(rot[1],rot[2],rot[3]),frozen)
end

e2function entity propSpawn(string model, vector pos, angle rot, number frozen)
	if not PropCore.ValidAction(self, nil, "spawn") then return NULL end
	return PropCore.CreateProp(self,model,Vector(pos[1],pos[2],pos[3]),Angle(rot[1],rot[2],rot[3]),frozen)
end

e2function entity propSpawn(entity template, vector pos, angle rot, number frozen)
	if not PropCore.ValidAction(self, nil, "spawn") then return NULL end
	if not IsValid(template) then return NULL end
	return PropCore.CreateProp(self,template:GetModel(),Vector(pos[1],pos[2],pos[3]),Angle(rot[1],rot[2],rot[3]),frozen)
end

--------------------------------------------------------------------------------

__e2setcost(60)
e2function entity seatSpawn(string model, number frozen)
	if not PropCore.ValidAction(self, nil, "spawn") then return NULL end
	if model=="" then model = "models/nova/airboat_seat.mdl" end
	return PropCore.CreateProp(self,model,self.entity:GetPos()+self.entity:GetUp()*25,self.entity:GetAngles(),frozen,true)
end

e2function entity seatSpawn(string model, vector pos, angle rot, number frozen)
	if not PropCore.ValidAction(self, nil, "spawn") then return NULL end
	if model=="" then model = "models/nova/airboat_seat.mdl" end
	return PropCore.CreateProp(self,model,Vector(pos[1],pos[2],pos[3]),Angle(rot[1],rot[2],rot[3]),frozen,true)
end

--------------------------------------------------------------------------------

__e2setcost(10)
e2function void entity:propDelete()
	if not PropCore.ValidAction(self, this, "delete") then return end
	this:Remove()
end

e2function void entity:propBreak()
	if not PropCore.ValidAction(self, this, "break") then return end
	this:Fire("break",1,0)
end

e2function void entity:use()
	if not PropCore.ValidAction(self, this, "use") then return end

	local ply = self.player
	if not IsValid(ply) then return end -- if the owner isn't connected to the server, do nothing

	if not hook.Run( "PlayerUse", ply, this ) then return end
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
	if not PropCore.ValidAction(self, nil, "Tdelete") then return 0 end

	local count = removeAllIn( self, this.s )
	count = count + removeAllIn( self, this.n )

	self.prf = self.prf + count

	return count
end

e2function number array:propDelete()
	if not PropCore.ValidAction(self, nil, "Tdelete") then return 0 end

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
	if not PropCore.ValidAction(self, this, "manipulate") then return end
	PropCore.PhysManipulate(this, pos, rot, freeze, gravity, notsolid)
end

e2function void entity:propFreeze(number freeze)
	if not PropCore.ValidAction(self, this, "freeze") then return end
	PropCore.PhysManipulate(this, nil, nil, freeze, nil, nil)
end

e2function void entity:propNotSolid(number notsolid)
	if not PropCore.ValidAction(self, this, "solid") then return end
	PropCore.PhysManipulate(this, nil, nil, nil, nil, notsolid)
end

--- Makes <this> not render at all
e2function void entity:propDraw(number drawEnable)
	if not PropCore.ValidAction(self, this, "draw") then return end
	this:SetNoDraw( drawEnable == 0 )
end

--- Makes <this>'s shadow not render at all
e2function void entity:propShadow(number shadowEnable)
	if not PropCore.ValidAction(self, this, "shadow") then return end
	this:DrawShadow( shadowEnable ~= 0 )
end

e2function void entity:propGravity(number gravity)
	if not PropCore.ValidAction(self, this, "gravity") then return end
	PropCore.PhysManipulate(this, nil, nil, nil, gravity, nil)
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
	if Vector( inertia[1], inertia[2], inertia[3] ):IsZero() then return end
	local phys = this:GetPhysicsObject()
	if IsValid( phys ) then
		phys:SetInertia(Vector(inertia[1], inertia[2], inertia[3]))
	end
end

e2function void entity:propSetBuoyancy(number buoyancy)
	if not PropCore.ValidAction(self, this, "buoyancy") then return end
	local phys = this:GetPhysicsObject()
	if IsValid( phys ) then
		phys:SetBuoyancyRatio( math.Clamp(buoyancy, 0, 1) )
	end
end

e2function void entity:propSetFriction(number friction)
	if not PropCore.ValidAction(self, this, "friction") then return end
	this:SetFriction( math.Clamp(friction, -1000, 1000) )
end

e2function number entity:propGetFriction()
	if not PropCore.ValidAction(self, this, "friction") then return 0 end
	return this:GetFriction()
end

e2function void entity:propSetElasticity(number elasticity)
	if not PropCore.ValidAction(self, this, "elasticity") then return end
	this:SetElasticity( math.Clamp(elasticity, -1000, 1000) )
end

e2function number entity:propGetElasticity()
	if not PropCore.ValidAction(self, this, "elasticity") then return 0 end
	return this:GetElasticity()
end

e2function void entity:propMakePersistent(number persistent)
	if not PropCore.ValidAction(self, this, "persist") then return end
	if GetConVarString("sbox_persist") == "0" then return end
	if not gamemode.Call("CanProperty", self.player, "persist", this) then return end
	this:SetPersistent(persistent ~= 0)
end

e2function void entity:propPhysicalMaterial(string physprop)
	if not PropCore.ValidAction(self, this, "physprop") then return end
	construct.SetPhysProp(self.player, this, 0, nil, {nil, Material = physprop})
end

e2function string entity:propPhysicalMaterial()
	if not PropCore.ValidAction(self, this, "physprop") then return "" end
	local phys = this:GetPhysicsObject()
	if IsValid(phys) then return phys:GetMaterial() or "" end
	return ""
end

e2function void entity:propSetVelocity(vector velocity)
	if not PropCore.ValidAction(self, this, "velocitynxt") then return end
	local phys = this:GetPhysicsObject()
	if IsValid( phys ) then
		phys:SetVelocity(Vector(velocity[1], velocity[2], velocity[3]))
	end
end

e2function void entity:propSetVelocityInstant(vector velocity)
	if not PropCore.ValidAction(self, this, "velocityins") then return end
	local phys = this:GetPhysicsObject()
	if IsValid( phys ) then
		phys:SetVelocityInstantaneous(Vector(velocity[1], velocity[2], velocity[3]))
	end
end

hook.Add( "CanDrive", "checkPropStaticE2", function( ply, ent ) if ent.propStaticE2 ~= nil then return false end end )
e2function void entity:propStatic( number static )
	if not PropCore.ValidAction( self, this, "static" ) then return end
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

__e2setcost(20)
e2function void entity:setPos(vector pos)
	if not PropCore.ValidAction(self, this, "pos") then return end
	PropCore.PhysManipulate(this, pos, nil, nil, nil, nil)
end

e2function void entity:reposition(vector pos) = e2function void entity:setPos(vector pos)

e2function void entity:setAng(angle rot)
	if not PropCore.ValidAction(self, this, "ang") then return end
	PropCore.PhysManipulate(this, nil, rot, nil, nil, nil)
end

e2function void entity:rerotate(angle rot) = e2function void entity:setAng(angle rot)

--------------------------------------------------------------------------------

local function parent_check( child, parent )
	while IsValid( parent ) do
		if (child == parent) then
			return false
		end
		parent = parent:GetParent()
	end
	return true
end

local function parent_antispam( child )
	if (child.E2_propcore_antispam or 0) > CurTime() then
		return false
	end

	child.E2_propcore_antispam = CurTime() + 0.06
	return true
end

e2function void entity:parentTo(entity target)
	if not PropCore.ValidAction(self, this, "parent") then return end
	if not IsValid(target) then return nil end
	if(!isOwner(self, target)) then return end
	if not parent_antispam( this ) then return end
	if this == target then return end
	if (!parent_check( this, target )) then return end
	this:SetParent(target)
end

__e2setcost(5)
e2function void entity:deparent()
	if not PropCore.ValidAction(self, this, "deparent") then return end
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
	if PropCore.WithinPropcoreLimits() then return 1 end
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
