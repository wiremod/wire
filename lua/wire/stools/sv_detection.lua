
function WireToolMakeSpeedometer( self, trace, ply )

	local xyz_mode = util.tobool(self:GetClientNumber("xyz_mode"))
	local AngVel = util.tobool(self:GetClientNumber("angvel"))

	if trace.Entity:IsValid() and trace.Entity:GetClass() == "gmod_wire_speedometer" then
		trace.Entity:Setup(xyz_mode, AngVel)
		return true
	end

	if not self:GetSWEP():CheckLimit("wire_speedometers") then return false end

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90

	local wire_speedometer = MakeWireSpeedometer(ply, trace.HitPos, Ang, self.Model, xyz_mode, AngVel)

	local min = wire_speedometer:OBBMins()
	wire_speedometer:SetPos(trace.HitPos - trace.HitNormal * min.z)

	return wire_speedometer
end
