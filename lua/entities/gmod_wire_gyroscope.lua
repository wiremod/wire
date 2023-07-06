AddCSLuaFile()
DEFINE_BASECLASS( "base_wire_entity" )
ENT.PrintName       = "Wire Gyroscope"
ENT.WireDebugName	= "Gyroscope"

function ENT:SetupDataTables()
	self:NetworkVar( "Bool", 0, "Out180" )
end

if CLIENT then
	--handle overlay text client side instead (TAD2020)
	function ENT:Think()
		BaseClass.Think(self)

		if self:GetModel() == "models/bull/various/gyroscope.mdl" then

			local lineOfNodes = self:WorldToLocal( ( Vector(0,0,1):Cross( self:GetUp() ) ):GetNormal() + self:GetPos() )

			self:SetPoseParameter( "rot_yaw"  ,  math.deg( math.atan2( lineOfNodes[2] , lineOfNodes[1] ) ) )
			self:SetPoseParameter( "rot_roll" , -math.deg( math.acos( self:GetUp():DotProduct( Vector(0,0,1) ) )  or 0 ) )
		end

		local ang = self:GetAngles()
		if (ang.p < 0 and not self:GetOut180()) then ang.p = ang.p + 360 end
		if (ang.y < 0 and not self:GetOut180()) then ang.y = ang.y + 360 end
		if (ang.r < 0 and not self:GetOut180()) then ang.r = ang.r + 360
		elseif (ang.r > 180 and self:GetOut180()) then ang.r = ang.r - 360 end
		self:ShowOutput(ang.p, ang.y, ang.r)

		self:NextThink(CurTime()+0.04)
		return true
	end

	function ENT:ShowOutput(p, y, r)
		self:SetOverlayText(string.format("Angles = %.3f, %.3f, %.3f", p, y, r))
	end

	return  -- No more client
end

-- Server

function ENT:Initialize()
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )

	self.Outputs = WireLib.CreateSpecialOutputs(self, { "Pitch", "Yaw", "Roll", "Angle" }, {"NORMAL", "NORMAL", "NORMAL", "ANGLE"})
end

function ENT:Setup( out180 )
	if out180 ~= nil then self:SetOut180(out180) end

	Wire_TriggerOutput(self, "Pitch", 0)
	Wire_TriggerOutput(self, "Yaw", 0)
	Wire_TriggerOutput(self, "Roll", 0)
	WireLib.TriggerOutput(self, "Angle", Angle( 0, 0, 0 ))
end

function ENT:Think()
	BaseClass.Think(self)

    local ang = self:GetAngles()
	if (ang.p < 0 and not self:GetOut180()) then ang.p = ang.p + 360 end
	if (ang.y < 0 and not self:GetOut180()) then ang.y = ang.y + 360 end
	if (ang.r < 0 and not self:GetOut180()) then ang.r = ang.r + 360
	elseif (ang.r > 180 and self:GetOut180()) then ang.r = ang.r - 360 end
	Wire_TriggerOutput(self, "Pitch", ang.p)
	Wire_TriggerOutput(self, "Yaw", ang.y)
	Wire_TriggerOutput(self, "Roll", ang.r)
	Wire_TriggerOutput(self, "Angle", Angle( ang.p, ang.y, ang.r ))
	--now handled client side (TAD2020)
	--self:ShowOutput(ang.p, ang.y, ang.r)

	self:NextThink(CurTime()+0.04)
	return true
end

duplicator.RegisterEntityClass("gmod_wire_gyroscope", WireLib.MakeWireEnt, "Data", "out180")
