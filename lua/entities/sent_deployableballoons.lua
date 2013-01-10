AddCSLuaFile()
DEFINE_BASECLASS( "base_wire_entity" )
ENT.PrintName       = "Wire Balloon Deployer"
ENT.Author          = "LuaPinapple"
ENT.Contact         = "evilpineapple@cox.net"
ENT.Purpose         = "It Deploys Balloons."
ENT.Instructions    = "Use wire."
ENT.Category		= "Wiremod"

ENT.Spawnable       = true
ENT.AdminOnly 		= false

ENT.RenderGroup		= RENDERGROUP_BOTH
ENT.WireDebugName = "Balloon Deployer"
cleanup.Register("wire_deployers")

if CLIENT then
	language.Add( "Cleanup_wire_deployers", "Balloon Deployers" )
	language.Add( "Cleaned_wire_deployers", "Cleaned up Balloon Deployers" )
	language.Add( "SBoxLimit_wire_deployers", "You have hit the Balloon Deployers limit!" )
	return -- No more client
end

local material 	= "cable/rope"

CreateConVar('sbox_maxwire_deployers', 2)
local function MakeBalloonSpawner(pl, Data)
	if not pl:CheckLimit("wire_deployers") then return nil end

	local ent = ents.Create("sent_deployableballoons")
	if not ent:IsValid() then return end
	duplicator.DoGeneric(ent, Data)
	ent:SetPlayer(pl)
	ent:Spawn()
	ent:Activate()

	duplicator.DoGenericPhysics(ent, pl, Data)

	pl:AddCount("wire_deployers", ent)
	pl:AddCleanup("wire_deployers", ent)
	return ent
end

duplicator.RegisterEntityClass("sent_deployableballoons", MakeBalloonSpawner, "Data")

function ENT:ApplyDupeInfo(ply, ent, info, GetEntByID)
	--Moves old "Lenght" input to new "Length" input for older dupes
	if info.Wires and info.Wires.Lenght then
		info.Wires.Length = info.Wires.Lenght
		info.Wires.Lenght = nil
	end

	self.BaseClass.ApplyDupeInfo(self, ply, ent, info, GetEntByID)
end

function ENT:SpawnFunction( ply, tr )
	if (not tr.Hit) then return end
	local SpawnPos = tr.HitPos+tr.HitNormal*16
	local ent = MakeBalloonSpawner(ply, {Pos=SpawnPos})
	return ent
end

function ENT:Initialize()
	self:SetModel("models/props_junk/PropaneCanister001a.mdl")
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid(SOLID_VPHYSICS)
	self.Deployed = 0
	self.Balloon = nil
	self.Constraints = {}
	self.force = 500
	self.weld = false
	self.popable = true
	self.rl = 64
	if WireAddon then
		self.Inputs = Wire_CreateInputs(self,{ "Force", "Length", "Weld?", "Popable?", "Deploy" })
		self.Outputs = Wire_CreateOutputs(self,{ "Deployed" })
		Wire_TriggerOutput(self,"Deployed", self.Deployed)
		--Wire_TriggerOutput(self,"Force", self.force)
	end
	local phys = self:GetPhysicsObject()
	if(phys:IsValid()) then
		phys:SetMass(250)
		phys:Wake()
	end
	self:UpdateOverlay()
end

function ENT:TriggerInput(key,value)
	if (key == "Deploy") then
		if value ~= 0 then
			if self.Deployed == 0 then
				self:DeployBalloons()
				self.Deployed = 1
			end
			Wire_TriggerOutput(self, "Deployed", self.Deployed)
		else
			if self.Deployed ~= 0 then
				self:RetractBalloons()
				self.Deployed = 0
			end
			Wire_TriggerOutput(self, "Deployed", self.Deployed)
		end
	elseif (key == "Force") then
		self.force = value
		if self.Deployed ~= 0 then
			self.Balloon:SetForce(value)
		end
	elseif (key == "Length") then
		self.rl = value
	elseif (key == "Weld?") then
		self.weld = value ~= 0
	elseif (key == "Popable?") then
		//self.popable = value ~= 0 -- Invinsible balloons don't seem to exist anymore
	end
	self:UpdateOverlay()
end

local balloon_registry = {}

hook.Add("EntityRemoved", "balloon_deployer", function(ent)
	local deployer = balloon_registry[ent]
	if IsValid(deployer) and deployer.TriggerInput then
		deployer.Deployed = 0
		deployer:TriggerInput("Deploy", 0)
	end
end)

function ENT:DeployBalloons()
	local balloon
	if self.popable then
		balloon = ents.Create("gmod_balloon") --normal balloon
	else
		balloon = ents.Create("gmod_iballoon") --invincible balloon
	end
	balloon:SetModel("models/MaxOfS2D/balloon_classic.mdl")
	balloon:Spawn()
	balloon:SetRenderMode( RENDERMODE_TRANSALPHA )
	balloon:SetColor(Color(math.random(0,255), math.random(0,255), math.random(0,255), 255))
	balloon:SetForce(self.force)
	balloon:SetMaterial("models/balloon/balloon")
	balloon:SetPlayer(self:GetPlayer())
	duplicator.DoGeneric(balloon,{Pos = self:GetPos() + (self:GetUp()*25)})
	duplicator.DoGenericPhysics(balloon,pl,{Pos = Pos})
	local spawnervec = (self:GetPos()-balloon:GetPos()):GetNormalized()*250 --just to be sure
	local trace = util.QuickTrace(balloon:GetPos(),spawnervec,balloon)
	local Pos = self:GetPos()+(self:GetUp()*25)
	local LPos1 = balloon:WorldToLocal(Pos)
	local LPos2 = trace.Entity:WorldToLocal(trace.HitPos)
	local phys = trace.Entity:GetPhysicsObjectNum(trace.PhysicsBone)
	if phys and phys:IsValid() then
		LPos2 = phys:WorldToLocal(trace.HitPos)
	end
	if self.weld then
		local constraint = constraint.Weld( balloon, trace.Entity, 0, trace.PhysicsBone, 0)
		balloon:DeleteOnRemove(constraint)
	else
		local constraint, rope = constraint.Rope(balloon,trace.Entity,0,trace.PhysicsBone,LPos1,LPos2,0,self.rl,0,1.5,material,nil)
		if constraint then
			balloon:DeleteOnRemove(constraint)
			balloon:DeleteOnRemove(rope)
		end
	end
	self:DeleteOnRemove(balloon)
	self.Balloon = balloon

	balloon_registry[balloon] = self
end

function ENT:OnRemove()
	if self.Balloon then
		balloon_registry[self.Balloon] = nil
	end
	Wire_Remove(self)
end

function ENT:RetractBalloons()
	if self.Balloon:IsValid() then
		local c = self.Balloon:GetColor()
		local effectdata = EffectData()
		effectdata:SetOrigin( self.Balloon:GetPos() )
		effectdata:SetStart( Vector(c.r,c.g,c.b) )
		util.Effect( "balloon_pop", effectdata )
		self.Balloon:Remove()
	else
		self.Balloon = nil
	end
end

function ENT:UpdateOverlay()
	self:SetOverlayText( "Deployed = " .. ((self.Deployed ~= 0) and "yes" or "no") )
end
