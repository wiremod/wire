
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include('shared.lua')

ENT.WireDebugName = "Hoverball"
ENT.OnState = 0

function ENT:Initialize()
	// Don't use the model's physics object, create a perfect sphere
	self:PhysicsInitSphere( 8, "metal_bouncy" )

	// Wake up our physics object so we don't start asleep

	local phys = self:GetPhysicsObject()

	if ( phys:IsValid() ) then
		phys:SetMass( 100 )
		phys:EnableGravity( false )
		phys:Wake()
	end

	// Start the motion controller (so PhysicsSimulate gets called)
	self:StartMotionController()

	self.Fraction = 0

	self.ZVelocity = 0
	self:SetTargetZ( self:GetPos().z )
	self:SetSpeed( 1 )
	self:EnableHover()

	self.Inputs = Wire_CreateInputs(self, { "A: ZVelocity", "B: HoverMode", "C: SetZTarget" })
	self.Outputs = Wire_CreateOutputs(self, { "A: Zpos", "B: Xpos", "C: Ypos" })

end

function ENT:TriggerInput(iname, value)
	if (iname == "A: ZVelocity") then
		self:SetZVelocity( value )
	elseif (iname == "B: HoverMode") then
		if (value >= 1 && self.OnState==0) then
			self:EnableHover()
		else
			self:DisableHover()
		end
	elseif (iname == "C: SetZTarget") then
		self:SetTargetZ(value)
	end
end

function ENT:EnableHover()
	self.OnState = 1
	self:SetHoverMode( true )
	self:SetStrength( self.strength or 1 ) //reset weight so it will work
	self:SetTargetZ ( self:GetPos().z ) //set height to current
	local phys = self:GetPhysicsObject()
	if ( phys:IsValid() ) then
		phys:EnableGravity( false )
		phys:Wake()
	end
end

function ENT:DisableHover()
	self.OnState = 0
	self:SetHoverMode( false )
	self:SetStrength(0.1) //for less dead weight while off
	local phys = self:GetPhysicsObject()
	if ( phys:IsValid() ) then
		phys:EnableGravity( true ) //falls slowly otherwise
	end
end

function ENT:OnRestore()
	self.ZVelocity = 0

	self.BaseClass.OnRestore(self)
end

function ENT:Think()

	self.BaseClass.Think( self )

	self:NextThink( CurTime() + 0.25 )

	self:SetNetworkedInt( "TargetZ", self:GetTargetZ() )

	return true

end

function ENT:PhysicsSimulate( phys, deltatime )

	local Pos = phys:GetPos()
	local txt = string.format( "Speed: %i\nResistance: %.2f", self:GetSpeed(), self:GetAirResistance() )
	txt = txt.."\nZ pos: "..math.floor(Pos.z) //.."Target: "..math.floor(self:GetTargetZ())

	Wire_TriggerOutput(self, "A: Zpos", Pos.z)
	Wire_TriggerOutput(self, "B: Xpos", Pos.x)
	Wire_TriggerOutput(self, "C: Ypos", Pos.y)


	if (self:GetHoverMode()) then

		txt = txt.." (on)"
		self:SetOverlayText( txt )

		if ( self.ZVelocity != 0 ) then

			self:SetTargetZ( self:GetTargetZ() + (self.ZVelocity * deltatime * self:GetSpeed()) )
			self:GetPhysicsObject():Wake()

		end

		phys:Wake()

		local Vel = phys:GetVelocity()
		local Distance = self:GetTargetZ() - Pos.z
		local AirResistance = self:GetAirResistance()


		if ( Distance == 0 ) then return end

		local Exponent = Distance^2

		if ( Distance < 0 ) then
			Exponent = Exponent * -1
		end

		Exponent = Exponent * deltatime * 300

		local physVel = phys:GetVelocity()
		local zVel = physVel.z

		Exponent = Exponent - (zVel * deltatime * 600 * ( AirResistance + 1 ) )
		// The higher you make this 300 the less it will flop about
		// I'm thinking it should actually be relative to any objects we're connected to
		// Since it seems to flop more and more the heavier the object

		Exponent = math.Clamp( Exponent, -5000, 5000 )

		local Linear = Vector(0,0,0)
		local Angular = Vector(0,0,0)

		Linear.z = Exponent

		if ( AirResistance > 0 ) then

			Linear.y = physVel.y * -1 * AirResistance
			Linear.x = physVel.x * -1 * AirResistance

		end

		return Angular, Linear, SIM_GLOBAL_ACCELERATION
	else
		txt = txt.." (off)"
		self:SetOverlayText( txt )
		return SIM_GLOBAL_FORCE
	end

end

function ENT:SetZVelocity( z )

	if ( z != 0 ) then
		self:GetPhysicsObject():Wake()
	end

	self.ZVelocity = z * FrameTime() * 5000
end

function ENT:GetAirResistance( )
	return self:GetVar( "AirResistance", 0 )
end

function ENT:SetAirResistance( num )
	self:SetVar( "AirResistance", num )
end

function ENT:SetStrength( strength )

	local phys = self:GetPhysicsObject()
	if ( phys:IsValid() ) then
		phys:SetMass( 150 * strength )
	end
end

function ENT:BuildDupeInfo()
	local info = self.BaseClass.BuildDupeInfo(self) or {}
	info.OnState = self.OnState
	return info
end

function ENT:ApplyDupeInfo(ply, ent, info, GetEntByID)
	if(ply && ent && info && GetEntByID)then
		self.BaseClass.ApplyDupeInfo(self, ply, ent, info, GetEntByID)
	end
	if (info && info.OnState) then
	if(info.OnState==0)then
		self:DisableHover()
	else
		self:EnableHover()
	end
	end
end

function ENT:Setup(speed, resistance, strength, starton)
	self:SetSpeed( speed )
	self:SetAirResistance( resistance )
	self:SetStrength( strength )
	if not starton then self:DisableHover() else self:EnableHover() end
	self.speed = speed
	self.resistance = resistance
	self.strength = strength
	self.starton = starton
end

function MakeWireHoverBall( pl, Pos, Ang, model, speed, resistance, strength, starton, nocollide )
	if not pl:CheckLimit( "wire_hoverballs" ) then return nil end

	local wire_ball = ents.Create( "gmod_wire_hoverball" )
	if not wire_ball:IsValid() then return false end

	wire_ball:SetPos( Pos )
	wire_ball:SetAngles( Ang )
	wire_ball:SetModel( model )
	wire_ball:Spawn()
	wire_ball:SetPlayer( pl )
	wire_ball.pl = pl
	wire_ball.nocollide = nocollide
	
	wire_ball:Setup(speed, resistance, strength, starton)

	pl:AddCount( "wire_hoverballs", wire_ball )

	return wire_ball
end
duplicator.RegisterEntityClass("gmod_wire_hoverball", MakeWireHoverBall, "Pos", "Ang", "Model", "speed", "resistance", "strength", "starton", "nocollide")
