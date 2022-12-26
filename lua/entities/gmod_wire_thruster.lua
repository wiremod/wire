AddCSLuaFile()
DEFINE_BASECLASS( "base_wire_entity" )
ENT.PrintName       = "Wire Thruster"
ENT.RenderGroup 		= RENDERGROUP_BOTH -- TODO: this is only needed when they're active.
ENT.WireDebugName	= "Thruster"

WireLib.ThrusterNetEffects = {
	["fire_smoke"] = true
}

function ENT:SetEffect( name )
	self:SetNWString( "Effect", name )
	self.neteffect = WireLib.ThrusterNetEffects[ name ]
end
function ENT:GetEffect( name )
	return self:GetNWString( "Effect" )
end

function ENT:SetOn( boolon )
	self:SetNWBool( "On", boolon, true )
end
function ENT:IsOn( name )
	return self:GetNWBool( "On" )
end

function ENT:SetOffset( v )
	self:SetNWVector( "Offset", v, true )
end
function ENT:GetOffset( name )
	return self:GetNWVector( "Offset" )
end


if CLIENT then
	function ENT:Initialize()
		self.ShouldDraw = 1
		self.EffectAvg = 0

		local mx, mn = self:GetRenderBounds()
		self:SetRenderBounds(mn + Vector(0,0,128), mx, 0)
	end

	function ENT:DrawTranslucent()
		if self.ShouldDraw == 0 or not self:IsOn() then return end

		local EffectDraw = WireLib.ThrusterEffectDraw[self:GetEffect()]
		if EffectDraw then EffectDraw(self) end
	end

	function ENT:Think()
		BaseClass.Think(self)

		self.ShouldDraw = GetConVarNumber("cl_drawthrusterseffects")

		if self.ShouldDraw == 0 or not self:IsOn() then return end

		local EffectThink = WireLib.ThrusterEffectThink[self:GetEffect()]
		if EffectThink then EffectThink(self) end
	end

	function ENT:CalcNormal()
		return (self:LocalToWorld(self:GetOffset()) - self:GetPos()):GetNormalized()
	end

	return  -- No more client
end

-- Server

function ENT:Initialize()
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )

	self:DrawShadow( false )

	local phys = self:GetPhysicsObject()
	if (phys:IsValid()) then
		phys:Wake()
	end

	local max = self:OBBMaxs()
	local min = self:OBBMins()

	self.ThrustOffset 	= Vector( 0, 0, max.z )
	self.ThrustOffsetR 	= Vector( 0, 0, min.z )

	self:SetForce( 2000 )

	self.oweffect = "fire"
	self.uweffect = "same"

	self:SetOffset( self.ThrustOffset )
	self:StartMotionController()

	self:Switch( false )

	self.Inputs = Wire_CreateInputs(self, { "A" })

	self.soundname = Sound( "PhysicsCannister.ThrusterLoop" )
end

function ENT:OnRemove()
	BaseClass.OnRemove(self)

	if (self.soundname and self.soundname ~= "") then
		self:StopSound(self.soundname)
	end
end

function ENT:SetForce( force, mul )
	if (force) then
		self.force = force
		self:ShowOutput()
	end
	self.mul = mul or 1

	local phys = self:GetPhysicsObject()
	if (not phys:IsValid()) then
		Msg("Warning: [",self,"] Physics object isn't valid!\n")
		return
	end

	if self.neteffect then
		self.effectforce = self.ThrustOffset:Length() * self.force * self.mul * 50
		self.updateeffect = true
	end

	if ( self.mul > 0 ) then
		self:SetOffset( self.ThrustOffset )
	else
		self:SetOffset( self.ThrustOffsetR )
	end
end

function ENT:CalcForce(phys)
	local ThrusterWorldForce = phys:LocalToWorldVector( self.ThrustOffset ) * (self.force * self.mul * -50)

	-- Calculate the velocity
	local ForceLinear, ForceAngular = phys:CalculateVelocityOffset(ThrusterWorldForce, phys:LocalToWorld( self.ThrustOffset ))

	self.ForceLinear = phys:WorldToLocalVector(WireLib.clampForce(ForceLinear))
	self.ForceAngular = phys:WorldToLocalVector(WireLib.clampForce(ForceAngular))
end

function ENT:SetDatEffect(uwater, owater, uweffect, oweffect)
	if self:WaterLevel() > 0 then
		if not uwater then
			self:SetEffect("none")
			return
		end

		if uweffect == "same" then
			self:SetEffect(oweffect)
			return
		else
			self:SetEffect(uweffect)
			return
		end
	else
		if not owater then
			self:SetEffect("none")
			return
		end
		self:SetEffect(oweffect)
		return
	end
end

function ENT:Setup(force, force_min, force_max, oweffect, uweffect, owater, uwater, bidir, soundname)
	self:SetForce(force)

	self:SetDatEffect(uwater, owater, uweffect, oweffect)

	self.oweffect = oweffect
	self.uweffect = uweffect
	self.force_min = force_min
	self.force_max = force_max
	self.bidir = bidir
	self.owater = owater
	self.uwater = uwater

	if (not soundname) then soundname = "" end

	-- Preventing client crashes
	local BlockedChars = '["?]'
	if ( string.find(soundname, BlockedChars) ) then
		self:StopSound( self.SoundName )
		soundname = ""
	end

	if (soundname == "") then
		self:StopSound( self.soundname )
	end

	self.soundname = Sound( soundname )

	--self:SetOverlayText( "Thrust = " .. 0 .. "\nMul: " .. math.Round(force*1000)/1000 )
end

function ENT:TriggerInput(iname, value)
	if (iname == "A") then
		if ( (self.bidir) and (math.abs(value) > 0.01) and (math.abs(value) > self.force_min) ) or ( (value > 0.01) and (value > self.force_min) ) then
			self:Switch(true, math.min(value, self.force_max))
		else
			self:Switch(false, 0)
		end
	end
end

function ENT:Think()
	if self.neteffect and self.updateeffect then
		self.updateeffect = false
		self:SetNWFloat("Thrust", self.effectforce)
	end
	self:NextThink(CurTime()+0.5)
end

function ENT:PhysicsSimulate( phys, deltatime )
	if (not self:IsOn()) then return SIM_NOTHING end

	if (self:WaterLevel() > 0) then
		if (not self.uwater) then
			self:SetEffect("none")
			return SIM_NOTHING
		end

		if (self.uweffect == "same") then
			self:SetEffect(self.oweffect)
		else
			self:SetEffect(self.uweffect)
		end
	else
		if (not self.owater) then
			self:SetEffect("none")
			return SIM_NOTHING
		end

		self:SetEffect(self.oweffect)
	end

	self:CalcForce(phys)

	return self.ForceAngular, self.ForceLinear, SIM_LOCAL_ACCELERATION
end

function ENT:Switch( on, mul )
	if (not self:IsValid()) then return false end

	local changed = (self:IsOn() ~= on)
	self:SetOn( on )


	if (on) then
		if (changed) and (self.soundname and self.soundname ~= "") then
			self:StopSound( self.soundname )
			self:EmitSound( self.soundname )
		end

		self.mul = mul

		self:SetForce( nil, mul )
	else
		if (self.soundname and self.soundname ~= "") then
			self:StopSound( self.soundname )
		end

		self.mul = 0
	end
	self:ShowOutput()

	local phys = self:GetPhysicsObject()
	if (phys:IsValid()) then
		phys:Wake()
	end

	return true
end

function ENT:ShowOutput()
	self:SetOverlayText(string.format("Force Mul: %.2f\nModel Mul: %.2f\nInput: %.2f\nForce Applied: %.2f",
		self.force or 0,
		self.ThrustOffset.z,
		self.mul or 0,
		(self.force or 0) * (self.mul or 0) * self.ThrustOffset.z
	))
end

function ENT:OnRestore()
	local phys = self:GetPhysicsObject()

	if (phys:IsValid()) then
		phys:Wake()
	end

	local max = self:OBBMaxs()
	local min = self:OBBMins()

	self.ThrustOffset 	= Vector( 0, 0, max.z )
	self.ThrustOffsetR 	= Vector( 0, 0, min.z )

	self:SetOffset( self.ThrustOffset )
	self:StartMotionController()

	BaseClass.OnRestore(self)
end

duplicator.RegisterEntityClass("gmod_wire_thruster", WireLib.MakeWireEnt, "Data", "force", "force_min", "force_max", "oweffect", "uweffect", "owater", "uwater", "bidir", "soundname")
