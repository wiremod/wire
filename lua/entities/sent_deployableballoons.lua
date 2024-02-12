AddCSLuaFile()
DEFINE_BASECLASS( "base_wire_entity" )
ENT.PrintName       = "Wire Balloon Deployer"
ENT.Author          = "LuaPinapple"
ENT.Contact         = "evilpineapple@cox.net"
ENT.Purpose         = "It Deploys Balloons."
ENT.Instructions    = "Use wire."
ENT.Category        = "Wiremod"

ENT.Spawnable       = true
ENT.AdminOnly       = false

ENT.WireDebugName = "Balloon Deployer"
cleanup.Register("wire_deployers")

if CLIENT then
	language.Add( "Cleanup_wire_deployers", "Balloon Deployers" )
	language.Add( "Cleaned_wire_deployers", "Cleaned up Balloon Deployers" )
	language.Add( "SBoxLimit_wire_deployers", "You have hit the Balloon Deployers limit!" )
	return -- No more client
end


local material 	= "cable/rope"
local BalloonTypes =
					{
					Model("models/MaxOfS2D/balloon_classic.mdl"),
					Model("models/balloons/balloon_classicheart.mdl"),
					Model("models/balloons/balloon_dog.mdl"),
					Model("models/balloons/balloon_star.mdl")
					}
CreateConVar( "sbox_maxwire_deployers", 2)

local DmgFilter

local function CreateDamageFilter()
	if IsValid(DmgFilter) then return end
	DmgFilter = ents.Create("filter_activator_name")
		DmgFilter:SetKeyValue("targetname", "DmgFilter")
		DmgFilter:SetKeyValue("negated", "1")
	DmgFilter:Spawn()
end
hook.Add("InitPostEntity", "CreateDamageFilter", CreateDamageFilter)

local function MakeBalloonSpawner(pl, Data)
	if IsValid(pl) and not pl:CheckLimit("wire_deployers") then return nil end
	if Data.Model and not WireLib.CanModel(pl, Data.Model, Data.Skin) then return false end

	local ent = ents.Create("sent_deployableballoons")
	if not ent:IsValid() then return end
	duplicator.DoGeneric(ent, Data)
	ent:SetPlayer(pl)
	ent:Spawn()
	ent:Activate()

	duplicator.DoGenericPhysics(ent, pl, Data)

	if IsValid(pl) then
		pl:AddCount("wire_deployers", ent)
		pl:AddCleanup("wire_deployers", ent)
	end

	return ent
end

duplicator.RegisterEntityClass("sent_deployableballoons", MakeBalloonSpawner, "Data")
scripted_ents.Alias("gmod_iballoon", "gmod_balloon")

--Moves old "Lenght" input to new "Length" input for older dupes
WireLib.AddInputAlias( "Lenght", "Length" )

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
		self.Inputs = Wire_CreateInputs(self,{ "Force", "Length", "Weld?", "Popable?", "BalloonType", "Deploy" })
		self.Outputs=WireLib.CreateSpecialOutputs(self, { "Deployed", "BalloonEntity" }, {"NORMAL","ENTITY" })
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
			if self.Deployed == 0 and ( self.nextDeploy or 0 ) < CurTime() then
                self.nextDeploy = CurTime() + 0.5
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
		self.force = math.Clamp(value, -1000000, 1000000)
		if self.Deployed ~= 0 then
			self.Balloon:SetForce(value)
		end
	elseif (key == "Length") then
		self.rl = value
	elseif (key == "Weld?") then
		self.weld = value ~= 0
	elseif (key == "Popable?") then
		self.popable = value ~= 0
		self:UpdatePopable()
	elseif (key == "BalloonType") then
		self.balloonType=value+1 --To correct for 1 based indexing
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
function ENT:UpdatePopable()
	local balloon = self.Balloon
	if balloon ~= nil and balloon:IsValid() then
		if not self.popable then
			balloon:Fire("setdamagefilter", "DmgFilter", 0);
		else
			balloon:Fire("setdamagefilter", "", 0);
		end
	end
end

function ENT:DeployBalloons()
	local balloon = ents.Create("gmod_balloon") --normal balloon

	local model = BalloonTypes[self.balloonType]
	if(model==nil) then
		model = BalloonTypes[1]
	end
	balloon:SetModel(model)
	balloon:Spawn()
	balloon:SetColor(Color(math.random(0,255), math.random(0,255), math.random(0,255), 255))
	balloon:SetForce(self.force)
	balloon:SetMaterial("models/balloon/balloon")
	balloon:SetPlayer(self:GetPlayer())
	duplicator.DoGeneric(balloon,{Pos = self:GetPos() + (self:GetUp()*25)})
	duplicator.DoGenericPhysics(balloon,pl,{Pos = Pos})

	local balloonPos = balloon:GetPos() -- the origin the balloon is at the bottom
	local hitEntity = self
	local hitPos = self:LocalToWorld(Vector(0, 0, self:OBBMaxs().z)) -- the top of the spawner

	-- We trace from the balloon to us, and if there's anything in the way, we
	-- attach a constraint to that instead - that way, the balloon spawner can
	-- be hidden underneath a plate which magically gets balloons attached to it.
	local balloonToSpawner = (hitPos - balloonPos):GetNormalized() * 250
	local trace = util.QuickTrace(balloon:GetPos(), balloonToSpawner, balloon)

	if constraint.CanConstrain(trace.Entity, trace.PhysicsBone) then
		local phys = trace.Entity:GetPhysicsObjectNum(trace.PhysicsBone)
		if IsValid(phys) then
			hitEntity = trace.Entity
			hitPos = trace.HitPos
		end
	end

	if self.weld then
		local constraint = constraint.Weld( balloon, hitEntity, 0, trace.PhysicsBone, 0)
		balloon:DeleteOnRemove(constraint)
	else
		balloonPos = balloon:WorldToLocal(balloonPos)
		hitPos = hitEntity:WorldToLocal(hitPos)

		local constraint, rope = constraint.Rope(
			balloon, hitEntity, 0, trace.PhysicsBone, balloonPos, hitPos,
			0, self.rl, 0, 1.5, material, false)
		if constraint then
			balloon:DeleteOnRemove(constraint)
			balloon:DeleteOnRemove(rope)
		end
	end
	self:DeleteOnRemove(balloon)
	self.Balloon = balloon
	self:UpdatePopable()
	balloon_registry[balloon] = self
	Wire_TriggerOutput(self, "BalloonEntity", self.Balloon)
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
