/******************************************************************************\
Prop Core by MrFaul started by ZeikJT
report any wishes, issues to Mr.Faul@gmx.de (GER or ENG pls)
\******************************************************************************/

E2Lib.RegisterExtension("propcore", false)
PropCore = {}
local sbox_E2_maxProps = CreateConVar( "sbox_E2_maxProps", "-1", FCVAR_ARCHIVE )
local sbox_E2_maxPropsPerSecond = CreateConVar( "sbox_E2_maxPropsPerSecond", "4", FCVAR_ARCHIVE )
local sbox_E2_PropCore = CreateConVar( "sbox_E2_PropCore", "2", FCVAR_ARCHIVE ) -- 2: Players can affect their own props, 1: Only admins, 0: Disabled

local E2totalspawnedprops = 0
local E2tempSpawnedProps = 0
local TimeStamp = 0

local function TempReset()
 if (CurTime()>= TimeStamp) then
	E2tempSpawnedProps = 0
	TimeStamp = CurTime()+1
 end
end
hook.Add("Think","TempReset",TempReset)

function PropCore.ValidSpawn()
	if E2tempSpawnedProps >= sbox_E2_maxPropsPerSecond:GetInt() then return false end
	if sbox_E2_maxProps:GetInt() <= -1 then
		return true
	elseif E2totalspawnedprops>=sbox_E2_maxProps:GetInt() then
		return false
	end
	return true
end

local canHaveInvalidPhysics = {delete=true, parent=true, deparent=true}
function PropCore.ValidAction(self, entity, cmd)
	if(cmd=="spawn" or cmd=="Tdelete") then return true end
	if(!IsValid(entity)) then return false end
	if(!canHaveInvalidPhysics[cmd] and !validPhysics(entity)) then return false end
	if(!isOwner(self, entity)) then return false end
	if entity:IsPlayer() then return false end
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

function PropCore.CreateProp(self,model,pos,angles,freeze)
	if(!util.IsValidModel(model) || !util.IsValidProp(model) || not PropCore.ValidSpawn() )then
		return nil
	end
	pos = E2Lib.clampPos( pos )
	local prop
	
	if self.data.propSpawnEffect then
		prop = MakeProp( self.player, pos, angles, model, {}, {} )
	else
		prop = MakePropNoEffect( self.player, pos, angles, model, {}, {} )
	end
	if not prop then return end
	
	prop:Activate()
	self.player:AddCleanup( "props", prop )
	if self.data.propSpawnPersist then
		undo.Create("e2_spawned_prop")
			undo.AddEntity( prop )
			undo.SetPlayer( self.player )
		undo.Finish()
	else
		table.insert( self.data.propSpawns, prop )
	end
	
	local phys = prop:GetPhysicsObject()
	if (phys:IsValid()) then
		if(angles!=nil) then E2Lib.setAng( phys, angles ) end
		phys:Wake()
		if(freeze>0) then phys:EnableMotion( false ) end
	end
	prop:CallOnRemove( "wire_expression2_propcore_remove", function( prop )
		E2totalspawnedprops = E2totalspawnedprops - 1
	end)
	E2totalspawnedprops = E2totalspawnedprops+1
	E2tempSpawnedProps = E2tempSpawnedProps+1
	return prop
end

function PropCore.PhysManipulate(this, pos, rot, freeze, gravity, notsolid)
	if(notsolid!=nil) then this:SetNotSolid(notsolid ~= 0) end
	local phys = this:GetPhysicsObject()
	if(pos!=nil) then E2Lib.setPos( phys, Vector(pos[1],pos[2],pos[3]) ) end
	if(rot!=nil) then E2Lib.setAng( phys,  Angle(rot[1],rot[2],rot[3]) ) end
	if(freeze!=nil) then phys:EnableMotion(freeze == 0) end
	if(gravity!=nil) then phys:EnableGravity(gravity~=0) end
	phys:Wake()
	if(!phys:IsMoveable())then
		phys:EnableMotion(true)
		phys:EnableMotion(false)
	end
end

--------------------------------------------------------------------------------
__e2setcost(30)
e2function entity propSpawn(string model, number frozen)
	if not PropCore.ValidAction(self, nil, "spawn") then return nil end
	return PropCore.CreateProp(self,model,self.entity:GetPos()+self.entity:GetUp()*25,self.entity:GetAngles(),frozen)
end

e2function entity propSpawn(entity template, number frozen)
	if not PropCore.ValidAction(self, nil, "spawn") then return nil end
	if not IsValid(template) then return nil end
	return PropCore.CreateProp(self,template:GetModel(),self.entity:GetPos()+self.entity:GetUp()*25,self.entity:GetAngles(),frozen)
end

e2function entity propSpawn(string model, vector pos, number frozen)
	if not PropCore.ValidAction(self, nil, "spawn") then return nil end
	return PropCore.CreateProp(self,model,Vector(pos[1],pos[2],pos[3]),self.entity:GetAngles(),frozen)
end

e2function entity propSpawn(entity template, vector pos, number frozen)
	if not PropCore.ValidAction(self, nil, "spawn") then return nil end
	if not IsValid(template) then return nil end
	return PropCore.CreateProp(self,template:GetModel(),Vector(pos[1],pos[2],pos[3]),self.entity:GetAngles(),frozen)
end

e2function entity propSpawn(string model, angle rot, number frozen)
	if not PropCore.ValidAction(self, nil, "spawn") then return nil end
	return PropCore.CreateProp(self,model,self.entity:GetPos()+self.entity:GetUp()*25,Angle(rot[1],rot[2],rot[3]),frozen)
end

e2function entity propSpawn(entity template, angle rot, number frozen)
	if not PropCore.ValidAction(self, nil, "spawn") then return nil end
	if not IsValid(template) then return nil end
	return PropCore.CreateProp(self,template:GetModel(),self.entity:GetPos()+self.entity:GetUp()*25,Angle(rot[1],rot[2],rot[3]),frozen)
end

e2function entity propSpawn(string model, vector pos, angle rot, number frozen)
	if not PropCore.ValidAction(self, nil, "spawn") then return nil end
	return PropCore.CreateProp(self,model,Vector(pos[1],pos[2],pos[3]),Angle(rot[1],rot[2],rot[3]),frozen)
end

e2function entity propSpawn(entity template, vector pos, angle rot, number frozen)
	if not PropCore.ValidAction(self, nil, "spawn") then return nil end
	if not IsValid(template) then return nil end
	return PropCore.CreateProp(self,template:GetModel(),Vector(pos[1],pos[2],pos[3]),Angle(rot[1],rot[2],rot[3]),frozen)
end

--------------------------------------------------------------------------------
__e2setcost(5)
e2function void entity:propDelete()
	if not PropCore.ValidAction(self, this, "delete") then return end
	this:Remove()
end

e2function void entity:propBreak()
	if not PropCore.ValidAction(self, this, "break") then return end
	this:Fire("break",1,0)
end

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
	if not PropCore.ValidAction(self, nil, "Tdelete") then return end

	local count = removeAllIn( self, this.s )
	count = count + removeAllIn( self, this.n )

	self.prf = self.prf + count

	return count
end

e2function number array:propDelete()
	if not PropCore.ValidAction(self, nil, "Tdelete") then return end

	local count = removeAllIn( self, this )

	self.prf = self.prf + count

	return count
end

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

e2function void entity:propSetBuoyancy(number bratio)
	if not PropCore.ValidAction(self, this, "buoy") then return end
	if E2Lib.isnan( bratio ) then bratio = 0 end
	local bratio = math.Clamp(bratio, 0, 1)
	local phys = this:GetPhysicsObject()
	if IsValid( phys ) then
		phys:SetBuoyancyRatio(bratio)
	end
end

--------------------------------------------------------------------------------

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

e2function void entity:parentTo(entity target)
	if not PropCore.ValidAction(self, this, "parent") then return end
	if not IsValid(target) then return nil end
	if(!isOwner(self, target)) then return end
	if this == target then return end
	if (!parent_check( this, target )) then return end
	this:SetParent(target)
end

e2function void entity:deparent()
	if not PropCore.ValidAction(self, this, "deparent") then return end
	this:SetParent( nil )
end
e2function void entity:parentTo() = e2function void entity:deparent()

__e2setcost(1)

e2function void propSpawnEffect(number on)
	self.data.propSpawnEffect = on ~= 0
end

e2function void enablePropSpawnUndo(number on)
	self.data.propSpawnPersist = on ~= 0
end

e2function number propCanCreate()
	if PropCore.ValidSpawn() then return 1 end
	return 0
end

registerCallback("construct", function(self)
	self.data.propSpawnEffect = true
	self.data.propSpawnPersist = true
	self.data.propSpawns = {}
end)
registerCallback("destruct", function(self)
	for _,ent in pairs(self.data.propSpawns) do
		if ent:IsValid() then ent:Remove() end
	end
end)
