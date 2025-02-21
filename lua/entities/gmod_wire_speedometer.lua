AddCSLuaFile()
DEFINE_BASECLASS("base_wire_entity")
ENT.PrintName = "Wire Speedometer"
ENT.WireDebugName = "Speedo"

function ENT:SetupDataTables()
	self:NetworkVar("Bool", 0, "XYZMode")
end

function ENT:SetModes(XYZMode)
	self:SetXYZMode(XYZMode)
end

if CLIENT then
	function ENT:Think()
		BaseClass.Think(self)

		local txt

		if self:GetXYZMode() then
			local vel = self:WorldToLocal(self:GetVelocity() + self:GetPos())
			txt = string.format("Velocity = %.3f,%.3f,%.3f", -vel.y, vel.x, vel.z)
		else
			txt = "Speed = " .. math.Round(self:GetVelocity():Length(), 3)
		end

		self:SetOverlayText(txt)
		self:NextThink(CurTime() + 0.04)

		return true
	end

	return  -- No more client
end

function ENT:Initialize()
	self:SetModel("models/jaanus/wiretool/wiretool_speed.mdl")
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)

	self.Outputs = Wire_CreateOutputs(self, { "Out", "MPH", "KPH" })
end

function ENT:Setup(xyz_mode, AngVel)
	self.z_only = xyz_mode --was renamed but kept for dupesaves
	self.XYZMode = xyz_mode
	self.AngVel = AngVel
	self:SetModes(xyz_mode)

	local outs = {}

	if (xyz_mode) then
		outs = { "X", "Y", "Z" }
	else
		outs = { "Out", "MPH", "KPH" }
	end

	if AngVel then
		table.Add(outs, {"AngVel_P", "AngVel_Y", "AngVel_R" } )
	end

	Wire_AdjustOutputs(self, outs)
end

function ENT:Think()
	BaseClass.Think(self)

	if self.XYZMode then
		local vel = self:WorldToLocal(self:GetVelocity() + self:GetPos())
		Wire_TriggerOutput(self, "X", -vel.y)
		Wire_TriggerOutput(self, "Y", vel.x)
		Wire_TriggerOutput(self, "Z", vel.z)
	else
		local vel = self:GetVelocity():Length()
		Wire_TriggerOutput(self, "Out", vel) -- vel = Source Units / sec, Source Units = Inch * 0.75 , more info here: https://developer.valvesoftware.com/wiki/Dimensions#Map_Grid_Units:_quick_reference
		Wire_TriggerOutput(self, "MPH", vel * 3600 / 63360 * 0.75)
		Wire_TriggerOutput(self, "KPH", vel * 3600 * 0.0000254 * 0.75)
	end

	if self.AngVel then
		local ang = self:GetPhysicsObject():GetAngleVelocity()
		Wire_TriggerOutput(self, "AngVel_P", ang.y)
		Wire_TriggerOutput(self, "AngVel_Y", ang.z)
		Wire_TriggerOutput(self, "AngVel_R", ang.x)
	end

	self:NextThink(CurTime() + 0.04)

	return true
end

duplicator.RegisterEntityClass("gmod_wire_speedometer", WireLib.MakeWireEnt, "Data", "z_only", "AngVel")
