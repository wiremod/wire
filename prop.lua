/******************************************************************************\
Prop Core by ZeikJT and MrFaul
\******************************************************************************/

E2Lib.RegisterExtension("propcore", false)

if(CLIENT)then
	language.Add("Undone_e2_spawned_prop", "E2 Spawned Prop")
else
	CreateConVar( "sbox_E2_maxProps", "-1", FCVAR_ARCHIVE )
	CreateConVar( "sbox_E2_maxPropsPerSecond", "4", FCVAR_ARCHIVE )
end

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

local function ValidSpawn()
	if ( E2tempSpawnedProps>=GetConVar("sbox_E2_maxPropsPerSecond"):GetInt())then return false end
	if ( GetConVar("sbox_E2_maxProps"):GetInt() <= -1 ) then
		return true
	elseif ( E2totalspawnedprops>=GetConVar("sbox_E2_maxProps"):GetInt()) then
		return false
	end
	return true
end

local function createpropsfromE2(self,model,pos,angles,freeze)
	if(!util.IsValidModel(model) || !util.IsValidProp(model) || not ValidSpawn() )then
		return nil
	end
	local prop = MakeProp( self.player, pos, angles, model, {}, {} )
	if not prop then return end
	prop:Activate()
	self.player:AddCleanup( "props", prop )
	undo.Create("e2_spawned_prop")
		undo.AddEntity( prop )
		undo.SetPlayer( self.player )
	undo.Finish()
	local phys = prop:GetPhysicsObject()
	if (phys:IsValid()) then
		phys:Wake()
		if(freeze>0)then phys:EnableMotion( false ) end
	end
	prop.OnDieFunctions.GetCountUpdate.Function2 = prop.OnDieFunctions.GetCountUpdate.Function
	prop.OnDieFunctions.GetCountUpdate.Function =  function(self,player,class)
		if CLIENT then return end
		E2totalspawnedprops=E2totalspawnedprops-1
		self.OnDieFunctions.GetCountUpdate.Function2(self,player,class)
	end
	E2totalspawnedprops = E2totalspawnedprops+1
	E2tempSpawnedProps = E2tempSpawnedProps+1
	return prop
end

--------------------------------------------------------------------------------------------------------

e2function entity propSpawn(string model, number frozen)
	return createpropsfromE2(self,model,self.entity:GetPos()+self.entity:GetUp()*25,self.entity:GetAngles(),frozen)
end

e2function entity propSpawn(entity template, number frozen)
	if not validEntity(template) then return end
	return createpropsfromE2(self,template:GetModel(),self.entity:GetPos()+self.entity:GetUp()*25,self.entity:GetAngles(),frozen)
end

e2function entity propSpawn(string model, vector pos, number frozen)
	return createpropsfromE2(self,model,Vector(pos[1],pos[2],pos[3]),self.entity:GetAngles(),frozen)
end

e2function entity propSpawn(entity template, vector pos, number frozen)
	if not validEntity(template) then return end
	return createpropsfromE2(self,template:GetModel(),Vector(pos[1],pos[2],pos[3]),self.entity:GetAngles(),frozen)
end

e2function entity propSpawn(string model, angle rot, number frozen)
	return createpropsfromE2(self,model,self.entity:GetPos()+self.entity:GetUp()*25,Angle(rot[1],rot[2],rot[3]),frozen)
end

e2function entity propSpawn(entity template, angle rot, number frozen)
	if not validEntity(template) then return end
	return createpropsfromE2(self,template:GetModel(),self.entity:GetPos()+self.entity:GetUp()*25,Angle(rot[1],rot[2],rot[3]),frozen)
end

e2function entity propSpawn(string model, vector pos, angle rot, number frozen)
	return createpropsfromE2(self,model,Vector(pos[1],pos[2],pos[3]),Angle(rot[1],rot[2],rot[3]),frozen)
end

e2function entity propSpawn(entity template, vector pos, angle rot, number frozen)
	if not validEntity(template) then return end
	return createpropsfromE2(self,template:GetModel(),Vector(pos[1],pos[2],pos[3]),Angle(rot[1],rot[2],rot[3]),frozen)
end

e2function void entity:propDelete()
	if not validEntity(this) then return end
	if(!isOwner(self, this)) then return end
	if(!this:IsWorld() and !this:IsPlayer()) then this:Remove() end
end

e2function number array:propDelete()
	local count = 0
	for _,ent in pairs(this) do
		if validEntity(ent) then
		if(!isOwner(self, ent)) then return end
		if(!ent:IsWorld() and !ent:IsPlayer()) then
			count=count+1
			ent:Remove()
		end
		end
	end
	return count
end

e2function number array:propDelete() = e2function number table:propDelete()

e2function void entity:propFreeze(number freeze)
	if not validEntity(this) then return end
	if(!isOwner(self, this)) then return end
	if(!this:IsWorld()) then
		local phys = this:GetPhysicsObject()
		if (phys:IsValid()) then
			phys:EnableMotion(freeze==0)
		end	
	else end
end

e2function void entity:propNotSolid(number notsolid)
	if not validEntity(this) then return end
	if(!isOwner(self, this)) then return end
	if(!this:IsWorld()) then
		this:SetNotSolid(notsolid ~= 0)
	else end
end

e2function void entity:propGravity(number grav)
	if not validEntity(this) then return end
	if(!isOwner(self, this)) then return end
	if(!this:IsWorld()) then
		local phys = this:GetPhysicsObject()
		if (phys:IsValid()) then
			if(grav>=1)then phys:EnableGravity( true ) end
			if(grav<=0)then phys:EnableGravity( false ) end
		end
	else end
end

e2function void entity:setPos(vector pos)
	if not validEntity(this) then return end
	if(!isOwner(self, this)) then return end
	if (!validPhysics(this)) then return end
	local phys = this:GetPhysicsObject()
	phys:SetPos(Vector(pos[1],pos[2],pos[3]))
	phys:Wake()
	if(!phys:IsMoveable())then
	phys:EnableMotion(true)
	phys:EnableMotion(false)
	end
end

e2function void entity:reposition(vector pos) = e2function void entity:setPos(vector pos)

e2function void entity:setAng(angle rot)
	if not validEntity(this) then return end
	if(!isOwner(self, this)) then return end
	if (!validPhysics(this)) then return end
	local phys = this:GetPhysicsObject()
	phys:SetAngle(Angle(rot[1],rot[2],rot[3]))
	phys:Wake()
	if(!phys:IsMoveable())then
	phys:EnableMotion(true)
	phys:EnableMotion(false)
	end
end

e2function void entity:rerotate(angle rot) = e2function void entity:setAng(angle rot)

e2function entity entity:parent()
	if not validEntity(this) then return nil end
	local parent = this:GetParent()
	if not validEntity(parent) then return nil end
	return parent
end

e2function void entity:parentTo(entity target)
	if not validEntity(this) then return nil end
	if not validEntity(target) then return nil end
	if(!validPhysics(this) || !validPhysics(target)) then return end
	if(!isOwner(self, this) || !isOwner(self, target)) then return end
	this:SetParent(target)
end

e2function void entity:deparent()
	if not validEntity(this) then return nil end
	if(!validPhysics(this)) then return end
	if(!isOwner(self, this)) then return end
	entity:SetParent( nil )
end
