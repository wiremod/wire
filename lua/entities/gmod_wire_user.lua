AddCSLuaFile()
ENT.Base = "base_wire_entity"
ENT.PrintName = "Wire User"
ENT.WantsTranslucency = true
ENT.WireDebugName = "User"

function ENT:SetupDataTables()
	self:NetworkVar("Float", 0, "BeamLength")
end

if CLIENT then return end

function ENT:Initialize()
	self:PhysicsInit(SOLID_VPHYSICS)
	WireLib.CreateInputs(self, { "Fire" })
end

function ENT:Setup(range)
	if range then self:SetBeamLength(range) end
end

function ENT:TriggerInput(name, value)
	if name == "Fire" and value ~= 0 then
		local start = self:GetPos()

		local ent = util.TraceLine({
			start = start,
			endpos = start + self:GetUp() * self:GetBeamLength(),
			filter = self
		}).Entity

		if not ent:IsValid() then return end

		local ply = self:GetPlayer()
		if not ply:IsValid() then return end

		if hook.Run("PlayerUse", ply, ent) == false then return end
		if hook.Run("WireUse", ply, ent, self) == false then return end

		ent:Use(ply, self)
	end
end

duplicator.RegisterEntityClass("gmod_wire_user", WireLib.MakeWireEnt, "Data", "Range")
