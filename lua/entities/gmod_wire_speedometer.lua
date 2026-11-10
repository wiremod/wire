AddCSLuaFile()
DEFINE_BASECLASS("base_wire_entity")
ENT.PrintName = "Wire Speedometer"
ENT.WireDebugName = "Speedo"

if CLIENT then return end

function ENT:Initialize()
	self:SetModel("models/jaanus/wiretool/wiretool_speed.mdl")
	self:PhysicsInit(SOLID_VPHYSICS)
	WireLib.CreateOutputs(self, { "Out", "MPH", "KPH" })
end

function ENT:Setup(xyz_mode, ang_vel)
	self.z_only = xyz_mode -- Was renamed but kept for backwards compat
	self.XYZMode = xyz_mode
	self.AngVel = ang_vel

	local outputs = xyz_mode and { "X", "Y", "Z" } or { "Out", "MPH", "KPH" }
	if ang_vel then table.Add(outputs, { "AngVel_P", "AngVel_Y", "AngVel_R" } ) end

	WireLib.AdjustOutputs(self, outputs)
end

function ENT:Think()
	BaseClass.Think(self)

	local tab = self:GetTable()

	if tab.XYZMode then
		local velocity = self:GetVelocity()
		velocity:Add(self:GetPos())

		local x, y, z = self:WorldToLocal(velocity):Unpack()
		WireLib.TriggerOutput(self, "X", -y)
		WireLib.TriggerOutput(self, "Y", x)
		WireLib.TriggerOutput(self, "Z", z)
	else
		local velocity = self:GetVelocity():Length()
		WireLib.TriggerOutput(self, "Out", velocity) -- vel = Source Units / sec, Source Units = Inch * 0.75 , more info here: https://developer.valvesoftware.com/wiki/Dimensions#Map_Grid_Units:_quick_reference
		WireLib.TriggerOutput(self, "MPH", velocity * 3600 / 63360 * 0.75)
		WireLib.TriggerOutput(self, "KPH", velocity * 3600 * 0.0000254 * 0.75)
	end

	if tab.AngVel then
		-- These are incorrect values ​​for the outputs, but has it always been this way? Does this even work?
		local p, y, r = self:GetPhysicsObject():GetAngleVelocity():Unpack()
		WireLib.TriggerOutput(self, "AngVel_P", y)
		WireLib.TriggerOutput(self, "AngVel_Y", r)
		WireLib.TriggerOutput(self, "AngVel_R", p)
	end

	self:NextThink(CurTime() + 0.04)

	return true
end

function ENT:PrepareOverlayData()
	if self:GetXYZMode() then
		local velocity = self:GetVelocity()
		velocity:Add(self:GetPos())

		local x, y, z = self:WorldToLocal(velocity):Unpack()
		self:SetOverlayText(string.format("Velocity = %.3f,%.3f,%.3f", -y, x, z))
	else
		self:SetOverlayText("Speed = " .. math.Round(self:GetVelocity():Length(), 3))
	end
end

duplicator.RegisterEntityClass("gmod_wire_speedometer", WireLib.MakeWireEnt, "Data", "z_only", "AngVel")
