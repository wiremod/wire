AddCSLuaFile()
DEFINE_BASECLASS( "base_wire_entity" )
ENT.PrintName		= "Wire Gimbal"
ENT.WireDebugName 	= "Gimbal"

if CLIENT then return end -- No more client

function ENT:Initialize()
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )
	self:GetPhysicsObject():EnableGravity(false)

	self.Inputs = WireLib.CreateInputs(self,{"On", "X", "Y", "Z", "Target [VECTOR]", "Direction [VECTOR]", "Angle [ANGLE]"})

	self.XYZ = Vector()
end

function ENT:TriggerInput(name,value)
	if name == "On" then
		self.On = value ~= 0
	else
		self.TargetPos = nil
		self.TargetDir = nil
		self.TargetAng = nil

		if name == "X" then
			self.XYZ.x = value
			self.TargetPos = self.XYZ
		elseif name == "Y" then
			self.XYZ.y = value
			self.TargetPos = self.XYZ
		elseif name == "Z" then
			self.XYZ.z = value
			self.TargetPos = self.XYZ
		elseif name == "Target" then
			self.XYZ = Vector(value.x, value.y, value.z)
			self.TargetPos = self.XYZ
		elseif name == "Direction" then
			self.TargetDir = value
		elseif name == "Angle" then
			self.TargetAng = value
		end
	end
	self:ShowOutput()
	return true
end


function ENT:Think()
	if self.On then
		local ang
		if self.TargetPos then
			ang = (self.TargetPos - self:GetPos()):Angle()
		elseif self.TargetDir then
			ang = self.TargetDir:Angle()
		elseif self.TargetAng then
			ang = self.TargetAng
		end
		if ang then self:SetAngles(ang + Angle(90,0,0)) end
		-- TODO: Put an option in the CPanel for Angle(90,0,0), and other useful directions
		self:GetPhysicsObject():Wake()
	end
	self:NextThink(CurTime())
	return true
end

function ENT:ShowOutput()
	if not self.On then
		self:SetOverlayText("Off")
	elseif self.TargetPos then
		self:SetOverlayText(string.format("Aiming towards (%.2f, %.2f, %.2f)", self.XYZ.x, self.XYZ.y, self.XYZ.z))
	elseif self.TargetDir then
		self:SetOverlayText(string.format("Aiming (%.4f, %.4f, %.4f)", self.TargetDir.x, self.TargetDir.y, self.TargetDir.z))
	elseif self.TargetAng then
		self:SetOverlayText(string.format("Aiming (%.1f, %.1f, %.1f)", self.TargetAng.pitch, self.TargetAng.yaw, self.TargetAng.roll))
	end
end

duplicator.RegisterEntityClass("gmod_wire_gimbal", WireLib.MakeWireEnt, "Data")
