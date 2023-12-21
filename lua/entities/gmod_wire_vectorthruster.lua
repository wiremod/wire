AddCSLuaFile()
DEFINE_BASECLASS( "base_wire_entity" )
ENT.PrintName       = "Wire Vector Thruster"
ENT.RenderGroup 		= RENDERGROUP_BOTH -- TODO: this is only needed when they're active.
ENT.WireDebugName	= "Vector Thruster"

function ENT:SetEffect( name )
	self:SetNWString( "Effect", name )
	self.neteffect = WireLib.ThrusterNetEffects[ name ]
end
function ENT:GetEffect()
	return self:GetNWString( "Effect" )
end

function ENT:SetOn( boolon )
	if (self:IsOn() ~= boolon) then
		if (boolon) then
			if (self.soundname and self.soundname ~= "") then
				self:StopSound( self.soundname )
				self:EmitSound( self.soundname )
			end
		else
			if (self.soundname and self.soundname ~= "") then
				self:StopSound( self.soundname )
			end
		end
		self:SetNWBool( "vecon", boolon, true )
	end
end
function ENT:IsOn()
	return self:GetNWBool( "vecon" )
end

function ENT:SetMode( v )
	self:SetNWInt( "vecmode", v, true )
end
function ENT:GetMode()
	return self:GetNWInt( "vecmode" )
end

function ENT:SetOffset( v )
	self:SetNWVector( "Offset", v, true )
end
function ENT:GetOffset( name )
	return self:GetNWVector( "Offset" )
end

function ENT:SetNormal( v )
	self:SetNWVector( "vec", v )
end
function ENT:GetNormal()
	return self:GetNWVector( "vec" )
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
		return self:GetNormal()
	end

	return  -- No more client
end

-- Server

function ENT:Initialize()
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )

	self:DrawShadow( false )

	self.X = 0
	self.Y = 0
	self.Z = 0
	self.mode = 0
	self.yaw = 0
	self.pitch = 0
	self.mul = 0
	self.force = 0

	self.ForceLinear = vector_origin
	self.ForceAngular = vector_origin

	local max = self:OBBMaxs()
	self.ThrustOffset = Vector( 0, 0, max.z )

	local phys = self:GetPhysicsObject()
	if (phys:IsValid()) then
		local massCenter = phys:GetMassCenter()
		self.ThrustOffset.x = massCenter.x
		self.ThrustOffset.y = massCenter.y
		phys:Wake()
	end

	self.oweffect = "fire"
	self.uweffect = "same"

	self:SetOffset(self.ThrustOffset)
	self:SetNormal(Vector())

	self:StartMotionController()

	self.Inputs = Wire_CreateInputs(self, { "Mul" })

	self.soundname = Sound( "PhysicsCannister.ThrusterLoop" )
end

function ENT:OnRemove()
	BaseClass.OnRemove(self)

	if (self.soundname) then
		self:StopSound(self.soundname)
	end
end

function ENT:CalcForce(phys)
	if self.angleinputs then
		self.X = math.cos(self.pitch) * math.cos(self.yaw)
		self.Y = math.sin(self.pitch)
		self.Z = math.cos(self.pitch) * math.sin(self.yaw)
	end

	local ThrusterWorldForce = Vector( -self.X, -self.Y, -self.Z )

	if (self.mode == 0) then
		ThrusterWorldForce = phys:LocalToWorldVector( ThrusterWorldForce )
	elseif (self.mode == 2) then
		ThrusterWorldForce = phys:LocalToWorldVector( ThrusterWorldForce )
		ThrusterWorldForce.z = -self.Z
	end

	local ThrustLen = ThrusterWorldForce:Length()

	if self.lengthismul then
		self.mul = ThrustLen
	end

	local LinearForceLength
	if ThrustLen>0 then
		local ThrustNormal = ThrusterWorldForce/ThrustLen
		self:SetNormal( -ThrustNormal )
		self.ForceLinear, self.ForceAngular = phys:CalculateVelocityOffset( ThrustNormal * ( math.min( self.force * self.mul, self.force_max ) * 50 ), phys:LocalToWorld( self.ThrustOffset ) )

		self.ForceLinear = WireLib.clampForce(self.ForceLinear)
		self.ForceAngular = WireLib.clampForce(self.ForceAngular)

		LinearForceLength = self.ForceLinear:Length()
	else
		self:SetNormal( vector_origin )
		self.ForceLinear, self.ForceAngular = vector_origin, vector_origin
		LinearForceLength = 0
	end

	if self.neteffect then
		self:SetNWFloat("Thrust", LinearForceLength)
	end
end

function ENT:Setup(force, force_min, force_max, oweffect, uweffect, owater, uwater, bidir, soundname, mode, angleinputs, lengthismul)
	self.mul = 0
	self.force = force
	self.oweffect = oweffect
	self.uweffect = uweffect
	self.force_min = force_min
	self.force_max = force_max
	self.bidir = bidir
	self.owater = owater
	self.uwater = uwater
	self.angleinputs = angleinputs
	self.lengthismul = lengthismul

	-- Preventing client crashes
	local BlockedChars = "[\"?]"
	if ( string.find(soundname, BlockedChars) ) then
		soundname = ""
	end

	if (soundname and soundname == "" and self.soundname and self.soundname ~= "") then
		self:StopSound(self.soundname)
	end

	if (soundname) then
		self.soundname = Sound(soundname)
	end

	self.mode = mode or 0
	self:SetMode( self.mode )
	self:ShowOutput()

	if (angleinputs) then
		WireLib.AdjustInputs(self, {"Mul", "Pitch", "Yaw"})
	else
		WireLib.AdjustInputs(self, {"Mul", "X", "Y", "Z", "Vector [VECTOR]"})
	end
end

function ENT:TriggerInput(iname, value)
	if (iname == "Mul") then
		self.mul = value
	elseif (iname == "X") then
		self.X = value
	elseif (iname == "Y") then
		self.Y = value
	elseif (iname == "Z") then
		self.Z = value
	elseif (iname == "Vector") then
		self.X = value.x
		self.Y = value.y
		self.Z = value.z
	elseif (iname == "Yaw") then
		self.yaw = math.rad( value )
	elseif (iname == "Pitch") then
		self.pitch = math.rad( value )
	end

	local phys = self:GetPhysicsObject()
	if phys:IsValid() then
		if phys:IsMotionEnabled() then
			phys:Wake()
		else
			self:PhysicsSimulate(phys)
		end
	end

	if self.lengthismul then
		self:SetOn(true)
	else
		self:SetOn(self.mul ~= 0 and ( self.bidir and (math.abs(self.mul) > 0.01) and (math.abs(self.mul) > self.force_min) ) or ( (self.mul > 0.01) and (self.mul > self.force_min) ))
	end
		self:ShowOutput()
end

function ENT:PhysicsSimulate( phys, deltatime )
	if (not self:IsOn()) then return SIM_NOTHING end
	if (self:IsPlayerHolding()) then return SIM_NOTHING end

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

	return self.ForceAngular, self.ForceLinear, SIM_GLOBAL_ACCELERATION
end

function ENT:ShowOutput()
	local mode = self:GetMode()
	self:SetOverlayText(string.format("Force Mul: %.2f\nInput: %.2f\nForce Applied: %.2f\nMode: %s",
		self.force,
		self.mul,
		self:IsOn() and math.min( self.force * self.mul, self.force_max ) or 0,
		(mode == 0 and "XYZ Local") or (mode == 1 and "XYZ World") or (mode == 2 and "XY Local, Z World")
	))
end

duplicator.RegisterEntityClass("gmod_wire_vectorthruster", WireLib.MakeWireEnt, "Data", "force", "force_min", "force_max", "oweffect", "uweffect", "owater", "uwater", "bidir", "soundname", "mode", "angleinputs", "lengthismul")
