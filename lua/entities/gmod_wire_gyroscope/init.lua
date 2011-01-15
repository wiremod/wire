AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "Gyro"

function ENT:Initialize()
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )

	self.Outputs = WireLib.CreateSpecialOutputs(self, { "Pitch", "Yaw", "Roll", "Angle" }, {"NORMAL", "NORMAL", "NORMAL", "ANGLE"})
end

function ENT:Setup( out180 )

	self.Out180 = out180 --wft is this used for
	self:SetOut180(out180)
	self.Value = 0
	self.PrevOutput = nil

	--self:ShowOutput(0, 0, 0)
	Wire_TriggerOutput(self, "Pitch", 0)
	Wire_TriggerOutput(self, "Yaw", 0)
	Wire_TriggerOutput(self, "Roll", 0)
	WireLib.TriggerOutput(self, "Angle", Angle( 0, 0, 0 ))
end

function ENT:Think()
	self.BaseClass.Think(self)

    local ang = self:GetAngles()
	if (ang.p < 0 && !self.Out180) then ang.p = ang.p + 360 end
	if (ang.y < 0 && !self.Out180) then ang.y = ang.y + 360 end
	if (ang.r < 0 && !self.Out180) then ang.r = ang.r + 360
	elseif (ang.r > 180 && self.Out180) then ang.r = ang.r - 360 end
	Wire_TriggerOutput(self, "Pitch", ang.p)
	Wire_TriggerOutput(self, "Yaw", ang.y)
	Wire_TriggerOutput(self, "Roll", ang.r)
	Wire_TriggerOutput(self, "Angle", Angle( ang.p, ang.y, ang.r ))
	--now handled client side (TAD2020)
	--self:ShowOutput(ang.p, ang.y, ang.r)

	self:NextThink(CurTime()+0.04)
	return true
end

function ENT:ShowOutput(p, y, r)
	self:SetOverlayText( "Angles = " .. math.Round(p*1000)/1000 .. "," .. math.Round(y*1000)/1000 .. "," .. math.Round(r*1000)/1000 )
end
