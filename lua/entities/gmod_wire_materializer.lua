AddCSLuaFile()

ENT.Base = "base_wire_entity"
ENT.PrintName = "Wire Materializer"
ENT.WantsTranslucency = true
ENT.WireDebugName = "Materializer"

function ENT:SetupDataTables()
	self:NetworkVar("Float", 0, "BeamLength")
end

if CLIENT then return end

function ENT:Initialize()
	self:PhysicsInit(SOLID_VPHYSICS)
	WireLib.CreateInputs(self, { "Paint", "Length", "Material [STRING]" })
end

function ENT:Setup(material, range)
	self.Material = material

	if range then self:SetBeamLength(range) end
	self:ShowOutput(self.Material)
end

function ENT:TriggerInput(iname, value)
	if iname == "Paint" then
		if value ~= 0 then
			local pos = self:GetPos()

			local ent = util.TraceLine({
				start = pos,
				endpos = pos + self:GetUp() * self:GetBeamLength(),
				filter = self
			}).Entity

			if ent:IsValid() and WireLib.CanTool(self:GetPlayer(), ent, "material") then
				E2Lib.setMaterial(ent, self.Material)
			end
		end
	elseif iname == "Length" then
		self:SetBeamLength(value)
	elseif iname == "Material" then
		self.Material = value
		self:ShowOutput(value)
	end
end

function ENT:ShowOutput(value)
	self:SetOverlayText("Material: " .. value)
end

duplicator.RegisterEntityClass("gmod_wire_materializer", WireLib.MakeWireEnt, "Data", "Material", "Range")
