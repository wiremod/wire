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
	self:SetNWBool( "vecon", boolon, true )
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
	self:SetNWInt( "vecx", v.x * 100, true )
	self:SetNWInt( "vecy", v.y * 100, true )
	self:SetNWInt( "vecz", v.z * 100, true )
end
function ENT:GetNormal()
	return Vector(
				self:GetNWInt( "vecx" ) / 100,
				self:GetNWInt( "vecy" ) / 100,
				self:GetNWInt( "vecz" ) / 100
			)
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
		self.BaseClass.Think(self)

		self.ShouldDraw = GetConVarNumber("cl_drawthrusterseffects")

		if self.ShouldDraw == 0 or not self:IsOn() then return end

		local EffectThink = WireLib.ThrusterEffectThink[self:GetEffect()]
		if EffectThink then EffectThink(self) end
	end

	function ENT:CalcNormal()
		local mode = self:GetMode()
		if mode == 1 then
			return self:GetNormal()
		elseif mode == 2 then
			local v = self:GetNormal()
			local z = v.z
			v = self:LocalToWorld(Vector(v.x,v.y,0))
			v.z = v.z + z
			return (v - self:GetPos()):GetNormalized()
		else
			return (self:LocalToWorld(self:GetNormal()) - self:GetPos()):GetNormalized()
		end
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

	self.X = 0
	self.Y = 0
	self.Z = 0
	self.mode = 0
	self.yaw = 0
	self.pitch = 0
	self.mul = 0

	self.ThrustNormal	= Vector()
	self.ThrustOffset 	= Vector( 0, 0, max.z )
	self.ForceAngle		= Vector()

	self:SetForce( 2000 )

	self.oweffect = "fire"
	self.uweffect = "same"

	self:SetOffset(self.ThrustOffset)
	self:SetNormal(self.ThrustNormal)
	
	self:StartMotionController()

	self:Switch( false )

	self.Inputs = Wire_CreateInputs(self, { "Mul" })

	self.soundname = Sound( "PhysicsCannister.ThrusterLoop" )
end

function ENT:OnRemove()
	self.BaseClass.OnRemove(self)

	if (self.soundname) then
		self:StopSound(self.soundname)
	end
end

function ENT:SetForce( force, mul )
	if (force) then
		self.force = force
	end
	mul = mul or 1

	local phys = self:GetPhysicsObject()
	if (!phys:IsValid()) then
		Msg("Warning: [",self,"] Physics object isn't valid!\n")
		return
	end

	local ThrusterWorldPos
	local ThrusterWorldForce
	if (self.mode == 1) then
		ThrusterWorldPos = self:GetPos() + self.ThrustOffset
		ThrusterWorldForce = self.ThrustNormal * -1
	else
		ThrusterWorldPos = phys:LocalToWorld( self.ThrustOffset )
		ThrusterWorldForce = phys:LocalToWorldVector( self.ThrustNormal * -1 )
	end
	if (self.mode == 2) then
		ThrusterWorldPos.z = ThrusterWorldPos.z + self.Z
		ThrusterWorldForce.z = ThrusterWorldForce.z - self.Z
	end

	// Calculate the velocity
	ThrusterWorldForce = ThrusterWorldForce * self.force * mul * 50
	self.ForceLinear, self.ForceAngle = phys:CalculateVelocityOffset( ThrusterWorldForce, ThrusterWorldPos );

	self.ForceLinear = phys:WorldToLocalVector( self.ForceLinear )
	
	if self.neteffect then
		-- self.ForceLinear is 0 if the thruster is frozen
		self.effectforce = ThrusterWorldForce:Length()
		self.updateeffect = true
	end
end

function ENT:Setup(force, force_min, force_max, oweffect, uweffect, owater, uwater, bidir, soundname, mode, angleinputs)
	self:SetForce(force)

	self.oweffect = oweffect
	self.uweffect = uweffect
	self.force_min = force_min
	self.force_max = force_max
	self.bidir = bidir
	self.owater = owater
	self.uwater = uwater
	self.angleinputs = angleinputs
	
	-- Preventing client crashes
	local BlockedChars = '["?]'
	if ( string.find(soundname, BlockedChars) ) then
		soundname = ""
	end

	if (soundname and soundname == "" and self.soundname and self.soundname != "") then
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
		if (value == 0) or (self:GetNormal() == Vector(0,0,0)) then
			self:Switch(false, math.min(value, self.force_max))
		elseif ( (self.bidir) and (math.abs(value) > 0.01) and (math.abs(value) > self.force_min) ) or ( (value > 0.01) and (value > self.force_min) ) then
			self:Switch(true, math.Clamp(value, -self.force_max, self.force_max))
		else
			self:Switch(false, 0)
		end
		return
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
	elseif (iname == "Yaw") or (iname == "Pitch") then
		value = math.rad( value )
		if (iname == "Yaw") then self.yaw = value else self.pitch = value end
		self.X = math.cos(self.pitch) * math.cos(self.yaw)
		self.Y = math.sin(self.pitch)
		self.Z = math.cos(self.pitch) * math.sin(self.yaw)
	end

	self.ThrustNormal = Vector( self.X, self.Y, self.Z ):GetNormalized()
	self:SetNormal( self.ThrustNormal ) -- Tell the client the unadulterated vector
	
	if self.mode == 2 then
		self.ThrustNormal = Vector( self.X, self.Y, 0 ):GetNormalized()
	end
	self.ThrustOffset = self.ThrustNormal + self:GetOffset()
	if (self.ThrustNormal == Vector(0,0,0)) then self:SetOn( false ) elseif (self.mul != 0) then self:SetOn( true ) end
	self:Switch( self:IsOn(), self.mul )
end

function ENT:Think()
	if self.neteffect and self.updateeffect then
		self.updateeffect = false
		self:SetNWFloat("Thrust", self.effectforce)
	end
	self:NextThink(CurTime()+0.5)
end

function ENT:PhysicsSimulate( phys, deltatime )
	if (!self:IsOn()) then return SIM_NOTHING end
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

	if (self.mode > 0 and self:IsOn()) then
		self:Switch( self:IsOn(), self.mul )
	end

	local ForceAngle, ForceLinear = self.ForceAngle, self.ForceLinear

	return ForceAngle, ForceLinear, SIM_LOCAL_ACCELERATION
end

function ENT:Switch( on, mul )
	if (!self:IsValid()) then return false end
	self.mul = mul or 0

	local changed = (self:IsOn() ~= on)
	self:SetOn( on )

	if (on) then
		if (changed) and (self.soundname and self.soundname != "") then
			self:StopSound( self.soundname )
			self:EmitSound( self.soundname )
		end

		if (mul ~= self.PrevOutput) then
			self.PrevOutput = mul
		end

		self:SetForce( nil, mul )
	else
		if (self.soundname and self.soundname != "") then
			self:StopSound( self.soundname )
		end

		if (self.PrevOutput) then
			self.PrevOutput = nil
		end
	end

	local phys = self:GetPhysicsObject()
	if (phys:IsValid()) then
		phys:Wake()
	end

	self:ShowOutput()

	return true
end

function ENT:ShowOutput()
	local mode = self:GetMode()
	self:SetOverlayText(string.format("Force Mul: %.2f\nInput: %.2f\nForce Applied: %.2f\nMode: %s",
		self.force,
		self.mul,
		self.force * self.mul,
		(mode == 0 and "XYZ Local") or (mode == 1 and "XYZ World") or (mode == 2 and "XY Local, Z World")
	))
end

duplicator.RegisterEntityClass("gmod_wire_vectorthruster", WireLib.MakeWireEnt, "Data", "force", "force_min", "force_max", "oweffect", "uweffect", "owater", "uwater", "bidir", "soundname", "mode", "angleinputs")

function ENT:OnRestore()
	local phys = self:GetPhysicsObject()

	if (phys:IsValid()) then
		phys:Wake()
	end

	local max = self:OBBMaxs()
	local min = self:OBBMins()

	self.ThrustNormal	= Vector()
	self.ThrustOffset 	= Vector(0, 0, max.z)
	self.ForceAngle		= Vector()

	self:SetOffset(self.ThrustOffset)
	self:SetNormal(self.ThrustNormal)

	self:StartMotionController()

	if (self.PrevOutput) then
		self:Switch(true, self.PrevOutput)
	else
		self:Switch(false)
	end

	self.BaseClass.OnRestore(self)
end
