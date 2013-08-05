AddCSLuaFile()
DEFINE_BASECLASS( "base_wire_entity" )
ENT.PrintName       = "Wire Gyroscope"
ENT.RenderGroup		= RENDERGROUP_OPAQUE
ENT.WireDebugName	= "Gyroscope"


-- Shared

function ENT:SetupDataTables()
	self:NetworkVar( "Bool", 0, "Out180" )
end

if CLIENT then 
	--handle overlay text client side instead (TAD2020)
	function ENT:Think()
		self.BaseClass.Think(self)

		if self:GetModel() == "models/bull/various/gyroscope.mdl" then

			local lineOfNodes = self:WorldToLocal( ( Vector(0,0,1):Cross( self:GetUp() ) ):GetNormal( ) + self:GetPos() )

			self:SetPoseParameter( "rot_yaw"  ,  math.deg( math.atan2( lineOfNodes[2] , lineOfNodes[1] ) ) )
			self:SetPoseParameter( "rot_roll" , -math.deg( math.acos( self:GetUp():DotProduct( Vector(0,0,1) ) )  or 0 ) )
		end

		local ang = self:GetAngles()
		if (ang.p < 0 && !self:GetOut180()) then ang.p = ang.p + 360 end
		if (ang.y < 0 && !self:GetOut180()) then ang.y = ang.y + 360 end
		if (ang.r < 0 && !self:GetOut180()) then ang.r = ang.r + 360
		elseif (ang.r > 180 && self:GetOut180()) then ang.r = ang.r - 360 end
		self:ShowOutput(ang.p, ang.y, ang.r)

		self:NextThink(CurTime()+0.04)
		return true
	end

	function ENT:ShowOutput(p, y, r)
		self:SetOverlayText( "Angles = " .. math.Round(p*1000)/1000 .. "," .. math.Round(y*1000)/1000 .. "," .. math.Round(r*1000)/1000 )
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
	self.BaseClass.Think(self)

    local ang = self:GetAngles()
	if (ang.p < 0 && !self.out180) then ang.p = ang.p + 360 end
	if (ang.y < 0 && !self.out180) then ang.y = ang.y + 360 end
	if (ang.r < 0 && !self.out180) then ang.r = ang.r + 360
	elseif (ang.r > 180 && self.out180) then ang.r = ang.r - 360 end
	Wire_TriggerOutput(self, "Pitch", ang.p)
	Wire_TriggerOutput(self, "Yaw", ang.y)
	Wire_TriggerOutput(self, "Roll", ang.r)
	Wire_TriggerOutput(self, "Angle", Angle( ang.p, ang.y, ang.r ))
	--now handled client side (TAD2020)
	--self:ShowOutput(ang.p, ang.y, ang.r)

	self:NextThink(CurTime()+0.04)
	return true
end

function MakeWireGyroscope( pl, Pos, Ang, model, out180, nocollide, Vel, aVel, frozen )
	if ( !pl:CheckLimit( "wire_gyroscopes" ) ) then return false end

	local wire_gyroscope = ents.Create( "gmod_wire_gyroscope" )
	if (!wire_gyroscope:IsValid()) then return false end

	wire_gyroscope:SetAngles(Ang)
	wire_gyroscope:SetPos(Pos)
	wire_gyroscope:SetModel( Model(model or "models/bull/various/gyroscope.mdl") )
	wire_gyroscope:Spawn()

	wire_gyroscope:Setup( out180 )
	wire_gyroscope:SetPlayer(pl)
	wire_gyroscope.pl = pl

	if ( nocollide == true ) then wire_gyroscope:GetPhysicsObject():EnableCollisions( false ) end

	pl:AddCount( "wire_gyroscopes", wire_gyroscope )

	return wire_gyroscope
end
duplicator.RegisterEntityClass("gmod_wire_gyroscope", MakeWireGyroscope, "Pos", "Ang", "Model", "out180")
