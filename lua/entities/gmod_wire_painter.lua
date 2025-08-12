AddCSLuaFile()

ENT.Base = "base_wire_entity"
ENT.PrintName = "Wire Painter"
ENT.RenderGroup = RENDERGROUP_BOTH
ENT.WireDebugName = "Painter"

function ENT:SetupDataTables()
	self:NetworkVar("Int", 0, "BeamLength")
end

if CLIENT then return end

function ENT:Initialize()
	self:PhysicsInit(SOLID_VPHYSICS)
	WireLib.CreateInputs(self, { "Paint", "Length", "Decal [STRING]" })
end

local wire_painters_maxlen = CreateConVar("sbox_wire_painters_maxlen", "16384", nil, nil, 0, 16384)

function ENT:Setup(decal, range)
	self.Decal = list.Contains("PaintMaterials", decal) and tostring(decal) or "Blood"
	self:SetBeamLength(math.Clamp(tonumber(range) or 0, 0, wire_painters_maxlen:GetInt()))
	self:ShowOutput(self.Decal)
end

function ENT:TriggerInput(iname, value)
	if iname == "Paint" then
		if value ~= 0 then
			util.Decal(self.Decal, self:GetPos(), self:GetPos() + self:GetUp() * self:GetBeamLength(), self)
		end
	elseif iname == "Length" then
		self:SetBeamLength(math.Clamp(value, 0, wire_painters_maxlen:GetInt()))
	elseif iname == "Decal" then
		if list.Contains("PaintMaterials", value) then
			self.Decal = value
			self:ShowOutput(value)
		end
	end
end

function ENT:ShowOutput(value)
	self:SetOverlayText("Decal: " .. value)
end

duplicator.RegisterEntityClass("gmod_wire_painter", WireLib.MakeWireEnt, "Data", "Decal", "Range")
