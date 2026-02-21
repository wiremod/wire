AddCSLuaFile()

ENT.Base = "base_wire_entity"
ENT.PrintName = "Wire Balloon Deployer"
ENT.WireDebugName = "Balloon Deployer"

if CLIENT then return end

function ENT:Initialize()
	self:PhysicsInit(SOLID_VPHYSICS)
	WireLib.CreateInputs(self, { "Force", "Length", "Weld?", "Popable?", "BalloonType", "Deploy" })
	WireLib.CreateOutputs(self, { "Deployed", "BalloonEntity [ENTITY]" })
end

function ENT:Setup(force, length, weld, popable, balloontype)
	self.Force = force and math.Clamp(force, -1E34, 1E34) or 500
	self.Length = length or 64
	self.Weld = weld
	self.Popable = popable
	self.BalloonType = balloontype
	WireLib.TriggerOutput(self, "Deployed", 0)
end

WireLib.AddInputAlias("Lenght", "Length")

function ENT:TriggerInput(iname, value)
	if iname == "Deploy" then
		if value ~= 0 then
			if not self.Deployed and (self.NextDeploy or 0) <= CurTime() then
				self:DeployBalloon()
				self.NextDeploy = CurTime() + 0.5
				self.Deployed = true
			end

			WireLib.TriggerOutput(self, "Deployed", 1)
		else
			if self.Deployed then
				self:RetractBalloon()
				self.Deployed = false
			end

			WireLib.TriggerOutput(self, "Deployed", 0)
		end
	elseif iname == "Force" then
		self.Force = math.Clamp(value, -1E34, 1E34)

		if IsValid(self.Balloon) then
			self.Balloon:SetForce(self.Force)
		end
	elseif iname == "Length" then
		self.Length = value
	elseif iname == "Weld?" then
		self.Weld = value ~= 0
	elseif iname == "Popable?" then
		self.Popable = value ~= 0

		if IsValid(self.Balloon) then
			self.Balloon.Indestructible = not self.Popable
		end
	elseif iname == "BalloonType" then
		self.BalloonType = value + 1
	end
end

local balloon_types = {
	"models/maxofs2d/balloon_classic.mdl",
	"models/balloons/balloon_classicheart.mdl",
	"models/balloons/balloon_dog.mdl",
	"models/balloons/balloon_star.mdl",
	"models/maxofs2d/balloon_gman.mdl",
	"models/maxofs2d/balloon_mossman.mdl"
}

function ENT:DeployBalloon()
	local balloon = ents.Create("gmod_balloon")

	local model = balloon_types[self.BalloonType] or balloon_types[1]
	balloon:SetModel(model)
	balloon:Spawn()

	local pos = self:GetPos() + self:GetUp() * 25
	balloon:SetPos(pos)

	balloon:SetPlayer(self:GetPlayer())
	balloon:SetColor(ColorRand())
	balloon:SetForce(self.Force)
	balloon.Indestructible = not self.Popable

	local hit_entity = self
	local hit_pos  = self:LocalToWorld(Vector(0, 0, self:OBBMaxs().z))

	local trace = util.TraceLine({
		start = hit_pos,
		endpos = pos,
		filter = balloon
	})

	if constraint.CanConstrain(trace.Entity, trace.PhysicsBone) then
		local phys = trace.Entity:GetPhysicsObjectNum(trace.PhysicsBone)

		if phys:IsValid() then
			hit_entity = trace.Entity
			hit_pos = trace.HitPos
		end
	end

	if self.Weld then
		local const = constraint.Weld(balloon, hit_entity, 0, trace.PhysicsBone, 0)

		if const then
			balloon:DeleteOnRemove(const)
		end
	else
		local const, rope = constraint.Rope(balloon, hit_entity, 0, trace.PhysicsBone, balloon:WorldToLocal(pos), hit_entity:WorldToLocal(hit_pos), 0, math.Clamp(self.Length, 0, 1024), 0, 1.5, "cable/rope")

		if const then
			balloon:DeleteOnRemove(const)
			balloon:DeleteOnRemove(rope)
		end
	end

	self:DeleteOnRemove(balloon)
	self.Balloon = balloon

	WireLib.TriggerOutput(self, "BalloonEntity", balloon)
end

function ENT:RetractBalloon()
	if self.Balloon:IsValid() then
		local effectdata = EffectData()
		effectdata:SetOrigin(self.Balloon:GetPos())

		local color = self.Balloon:GetColor()
		effectdata:SetStart(Vector(color.r, color.g, color.b))
		util.Effect("balloon_pop", effectdata)

		self.Balloon:Remove()
	else
		self.Balloon = nil
	end
end

function ENT:PrepareOverlayData()
	self:SetOverlayText("Deployed = " .. (self.Deployed and "yes" or "no"))
end

duplicator.RegisterEntityClass("gmod_wire_balloondeployer", WireLib.MakeWireEnt, "Data", "Force", "Length", "Weld", "Popable", "BallonType")
scripted_ents.Alias("sent_deployableballoons", "gmod_wire_balloondeployer")
