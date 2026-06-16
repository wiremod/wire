AddCSLuaFile()

ENT.Base = "base_wire_entity"
ENT.PrintName = "Wire Painter"
ENT.WantsTranslucency = true
ENT.WireDebugName = "Painter"

function ENT:SetupDataTables()
	self:NetworkVar("Float", 0, "BeamLength")
end

if CLIENT then return end

function ENT:Initialize()
	self:PhysicsInit(SOLID_VPHYSICS)
	WireLib.CreateInputs(self, { "Paint", "Length", "Decal [STRING]" })
end

function ENT:Setup(decal, range)
	self.Decal = decal
	if range then self:SetBeamLength(range) end
	self:ShowOutput(self.Decal)
end

function ENT:TriggerInput(iname, value)
	if iname == "Paint" then
		if value ~= 0 then
			local pos = self:GetPos()
			util.Decal(self.Decal, pos, pos + self:GetUp() * self:GetBeamLength(), self)
		end
	elseif iname == "Length" then
		self:SetBeamLength(value)
	elseif iname == "Decal" then
		self.Decal = value
		self:ShowOutput(value)
	end
end

function ENT:ShowOutput(value)
	self:SetOverlayText("Decal: " .. value)
end

duplicator.RegisterEntityClass("gmod_wire_painter", WireLib.MakeWireEnt, "Data", "Decal", "Range")
