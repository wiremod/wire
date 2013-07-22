
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "Thruster"

function ENT:Initialize()
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )

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

	self.ThrustOffset 	= Vector( 0, 0, 0 )
	self.ForceAngle		= self.ThrustOffset:GetNormalized() * -1

	self:SetForce( 2000 )

	self.oweffect = "fire"
	self.uweffect = "same"

	self:SetOffset( self.ThrustOffset )
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
		self:NetSetForce( force )
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
		ThrusterWorldForce = self.ThrustOffset * -1
	else
		ThrusterWorldPos = phys:LocalToWorld( self.ThrustOffset )
		ThrusterWorldForce = phys:LocalToWorldVector( self.ThrustOffset * -1 )
	end
	if (self.mode == 2) then
		ThrusterWorldPos.z = ThrusterWorldPos.z + self.Z
		ThrusterWorldForce.z = ThrusterWorldForce.z - self.Z
	end

	// Calculate the velocity
	ThrusterWorldForce = ThrusterWorldForce * self.force * mul * 50
	self.ForceLinear, self.ForceAngle = phys:CalculateVelocityOffset( ThrusterWorldForce, ThrusterWorldPos );

	self.ForceLinear = phys:WorldToLocalVector( self.ForceLinear )
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

	self.mode = mode
	self:SetMode( self.mode )

	if (angleinputs) then
		WireLib.AdjustInputs(self, {"Mul", "Pitch", "Yaw"})
	else
		WireLib.AdjustSpecialInputs(self, {"Mul", "X", "Y", "Z", "Vector"}, { "NORMAL", "NORMAL", "NORMAL", "NORMAL", "VECTOR"})
	end
end

function ENT:TriggerInput(iname, value)
	if (iname == "Mul") then
		if (value == 0) or (self.ThrustOffset == Vector(0,0,0)) then
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

	self.ThrustOffset = Vector( self.X, self.Y, self.Z ):GetNormalized()
	self:SetOffset( self.ThrustOffset )
	if (self.mode == 2) then
		self.ThrustOffset = Vector( self.X, self.Y, 0 ):GetNormalized()
	end

	if (self.ThrustOffset == Vector(0,0,0)) then self:SetOn( false ) elseif (self.mul != 0) then self:SetOn( true ) end
	self:Switch( self:IsOn(), self.mul )
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
	self.mul = mul

	local changed = (self:IsOn() ~= on)
	self:SetOn( on )

	if (on) then
		if (changed) and (self.soundname and self.soundname != "") then
			self:StopSound( self.soundname )
			self:EmitSound( self.soundname )
		end

		self:NetSetMul( mul )

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

	return true
end

function MakeWireVectorThruster( pl, Pos, Ang, model, force, force_min, force_max, oweffect, uweffect, owater, uwater, bidir, soundname, nocollide, mode, angleinputs)
	if ( !pl:CheckLimit( "wire_thrusters" ) ) then return false end
	mode = mode or 0

	local wire_thruster = ents.Create( "gmod_wire_vectorthruster" )
	if (!wire_thruster:IsValid()) then return false end
	wire_thruster:SetModel( model )

	wire_thruster:SetAngles( Ang )
	wire_thruster:SetPos( Pos )
	wire_thruster:Spawn()

	wire_thruster:Setup(force, force_min, force_max, oweffect, uweffect, owater, uwater, bidir, soundname, mode, angleinputs)
	wire_thruster:SetPlayer( pl )

	if ( nocollide == true ) then wire_thruster:GetPhysicsObject():EnableCollisions( false ) end

	pl:AddCount( "wire_thrusters", wire_thruster )

	return wire_thruster
end
duplicator.RegisterEntityClass("gmod_wire_vectorthruster", MakeWireVectorThruster, "Pos", "Ang", "Model", "force", "force_min", "force_max", "oweffect", "uweffect", "owater", "uwater", "bidir", "soundname", "nocollide", "mode", "angleinputs")

function ENT:OnRestore()
	local phys = self:GetPhysicsObject()

	if (phys:IsValid()) then
		phys:Wake()
	end

	local max = self:OBBMaxs()
	local min = self:OBBMins()

	self.ThrustOffset 	= Vector( 0, 0, 1)
	self.ForceAngle		= self.ThrustOffset:GetNormalized() * -1

	self:SetOffset( self.ThrustOffset )
	self:StartMotionController()

	if (self.PrevOutput) then
		self:Switch(true, self.PrevOutput)
	else
		self:Switch(false)
	end

	self.BaseClass.OnRestore(self)
end

function ENT:BuildDupeInfo()
	local info = self.BaseClass.BuildDupeInfo(self) or {}

	if (self.PrevOutput) and (self:IsOn()) then
		info.PrevOutput = self.PrevOutput
	end

	return info
end

function ENT:ApplyDupeInfo(ply, ent, info, GetEntByID)
	self.BaseClass.ApplyDupeInfo(self, ply, ent, info, GetEntByID)

	if (info.PrevOutput) then
		self:Switch(true, info.PrevOutput)
	end

end
