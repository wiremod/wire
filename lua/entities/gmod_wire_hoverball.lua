AddCSLuaFile()
DEFINE_BASECLASS( "base_wire_entity" )
ENT.PrintName       = "Wire Hoverball"
ENT.RenderGroup		= RENDERGROUP_BOTH
ENT.WireDebugName	= "Hoverball"

-- Shared
function ENT:IsOn() return self:GetNWBool( "On", false ) end

if CLIENT then
	-- Clientside GetZTarget
	function ENT:GetZTarget() return self:GetNWFloat( "ZTarget", 0 ) end

	local drawhoverballs = CreateConVar( "cl_drawhoverballs", "1" )
	local glowmat = Material( "sprites/light_glow02_add" )

	function ENT:DrawTranslucent()
		if not drawhoverballs:GetBool() then return end

		if self:IsOn() then
			local Pos = self:GetPos()
			local vDiff = (Pos - LocalPlayer():EyePos()):GetNormalized()

			local color = Color( 70, 180, 255, 255 ) -- Color( 40, 50, 200, 255 )
			render.SetMaterial( glowmat )

			-- Draw central glow
			render.DrawSprite( Pos - vDiff * 2, 22, 22, color )

			-- Draw glow based on distance from target
			local Distance = math.Clamp( math.abs( ( self:GetZTarget() - Pos.z ) * math.sin( RealTime() * 20 )  ) * 0.05, 0, 1 )
			color.r = color.r * Distance
			color.g = color.g * Distance
			color.b = color.b * Distance

			render.DrawSprite( Pos + vDiff * 4, 48, 48, color )
			render.DrawSprite( Pos + vDiff * 4, 52, 52, color )
		end
	end

	return -- No more client
end

-- Getters/setters
function ENT:GetZTarget() return self.ztarget end
function ENT:SetZTarget( z )
	self.ztarget = z
	self:SetNWFloat( "ZTarget", z )
end
function ENT:GetZVelocity() return self.zvelocity end
function ENT:SetZVelocity( z )
	self.zvelocity = z * FrameTime() * 5000

	if z ~= 0 then
		local phys = self:GetPhysicsObject()
		if IsValid( phys ) then
			phys:Wake()
		end
	end
end
function ENT:GetSpeed() return self.speed end
function ENT:SetSpeed( s )
	if not game.SinglePlayer() then
		s = math.Clamp( s, 0, 10 )
	end

	self.speed = s
end
function ENT:SetOn( h ) self:SetNWBool( "On", h ) end

function ENT:GetAirResistance() return self.resistance end
function ENT:SetAirResistance( r ) self.resistance = r end
function ENT:GetSpeed() return self.speed end
function ENT:SetSpeed( s ) self.speed = s end
function ENT:SetStrength( s )
	self.strength = s
	local phys = self:GetPhysicsObject()
	if ( phys:IsValid() ) then
		phys:SetMass( 150 * s )
	end
end
function ENT:GetStrength() return self.strength end

-- Initialize
function ENT:Initialize()
	self:PhysicsInitSphere( 6, "metal_bouncy" )
	self:StartMotionController()

	self:SetZVelocity( 0 )
	self:SetZTarget( self:GetPos().z )

	self:SetSpeed( 1 )
	self:SetStrength( 1 )
	self:SetAirResistance( 1 )
	self:SetZTarget( self:GetPos().z ) -- reset target position

	self.Inputs = WireLib.CreateInputs( self, { "On",
		"ZVelocity (If non-zero, causes the hoverball to attempt to fly up, or down if the value is negative.\nThe speed is based on the magnitude of the number multiplied by the speed configured in the context menu.)",
		"ZTarget (Causes the hoverball to attempt to fly to the specified Z coordinate and stay there.)"
	} )
	self.Outputs = WireLib.CreateOutputs( self, { "Position [VECTOR]", "X", "Y", "Z", "Distance (How far away the hoverball's Z coordinate is from its target)" } )
end

WireLib.AddInputAlias( "A: ZVelocity", "ZVelocity" )
WireLib.AddInputAlias( "B: HoverMode", "On" )
WireLib.AddInputAlias( "C: SetZTarget", "ZTarget" )
WireLib.AddOutputAlias( "A: Zpos", "Z" )
WireLib.AddOutputAlias( "B: Xpos", "X" )
WireLib.AddOutputAlias( "C: Ypos", "Y" )

-- Setup
function ENT:Setup(speed, resistance, strength, starton)
	self:SetSpeed( speed )
	self:SetStrength( strength )
	self:SetAirResistance( resistance )

	if starton then self:Enable() else self:Disable() end
	self.starton = starton
end

-- TriggerInput
function ENT:TriggerInput( name, value )
	if name == "On" then
		value = value ~= 0
		if value ~= self:IsOn() then
			if value then self:Enable() else self:Disable() end
		end
	elseif name == "ZVelocity" then
		self:SetZVelocity( value )
	elseif name == "ZTarget" then
		self:SetZTarget( value )
	end
end

-- Enable/Disable
function ENT:Enable()
	self:SetOn( true )
	self:SetStrength( self.strength ) -- Reset weight to user specified value
	local phys = self:GetPhysicsObject()
	if IsValid( phys ) then
		phys:EnableGravity( false )
		phys:Wake()
	end
end

function ENT:Disable()
	self:SetOn( false )
	local phys = self:GetPhysicsObject()
	if IsValid( phys ) then
		phys:SetMass( 1 ) -- less dead weight when off
		phys:EnableGravity( true )
	end
end

function ENT:Think()
	BaseClass.Think( self )

	local on = self:IsOn() and "\nActivated" or "\nDeactivated"

	local pos = self:GetPos()
	local Distance = self:GetZTarget() - pos.z
	self:SetOverlayText( string.format( "Speed: %i\nResistance: %.2f\nStrength: %.2f\nDistance to ZTarget: %.2f%s", self:GetSpeed(), self:GetAirResistance(), self:GetStrength(), Distance, on ) )

	WireLib.TriggerOutput( self, "Position", pos )
	WireLib.TriggerOutput( self, "X", pos.x )
	WireLib.TriggerOutput( self, "Y", pos.y )
	WireLib.TriggerOutput( self, "Z", pos.z )
	WireLib.TriggerOutput( self, "Distance", Distance )
end

function ENT:PhysicsSimulate( phys, deltatime )
	if (self:IsOn()) then
		local Pos = phys:GetPos()

		if ( self:GetZVelocity() ~= 0 ) then
			self:SetZTarget( self:GetZTarget() + (self:GetZVelocity() * deltatime * self:GetSpeed()) )
		end

		phys:Wake()

		local Vel = phys:GetVelocity()
		local Distance = self:GetZTarget() - Pos.z
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
		-- The higher you make this 300 the less it will flop about
		-- I'm thinking it should actually be relative to any objects we're connected to
		-- Since it seems to flop more and more the heavier the object

		Exponent = math.Clamp( Exponent, -5000, 5000 )

		local Linear = Vector(0,0,0)
		local Angular = Vector(0,0,0)

		Linear.z = Exponent

		if AirResistance > 0 then
			Linear.y = physVel.y * -AirResistance
			Linear.x = physVel.x * -AirResistance
		end

		return Angular, Linear, SIM_GLOBAL_ACCELERATION
	else
		return SIM_GLOBAL_FORCE
	end
end

function ENT:BuildDupeInfo()
	local info = BaseClass.BuildDupeInfo(self) or {}
	info.OnState = self:IsOn() and 1 or 0 -- convert to 1/0 for simple old dupe compatibility
	return info
end

function ENT:ApplyDupeInfo(ply, ent, info, GetEntByID)
	BaseClass.ApplyDupeInfo(self, ply, ent, info, GetEntByID)

	if info and info.OnState and info.OnState == 1 then
		self:Enable()
	end
end

function ENT:OnRestore()
	self.ZVelocity = 0

	BaseClass.OnRestore(self)
end

duplicator.RegisterEntityClass("gmod_wire_hoverball", WireLib.MakeWireEnt, "Data", "speed", "resistance", "strength", "starton")
