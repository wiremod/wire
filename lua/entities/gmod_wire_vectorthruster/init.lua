
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
	self.Mode = 0
	self.yaw = 0
	self.pitch = 0
	self.mul = 0

	self.ThrustOffset 	= Vector( 0, 0, 0 )
	self.ForceAngle		= self.ThrustOffset:GetNormalized() * -1

	self:SetForce( 2000 )

	self.OWEffect = "fire"
	self.UWEffect = "same"

	self:SetOffset( self.ThrustOffset )
	self:StartMotionController()

	self:Switch( false )

	self.Inputs = Wire_CreateInputs(self, { "Mul" })

	self.SoundName = Sound( "PhysicsCannister.ThrusterLoop" )
end

function ENT:OnRemove()
	self.BaseClass.OnRemove(self)

	if (self.SoundName) then
		self:StopSound(self.SoundName)
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
	if (self.Mode == 1) then
		ThrusterWorldPos = self:GetPos() + self.ThrustOffset
		ThrusterWorldForce = self.ThrustOffset * -1
	else
		ThrusterWorldPos = phys:LocalToWorld( self.ThrustOffset )
		ThrusterWorldForce = phys:LocalToWorldVector( self.ThrustOffset * -1 )
	end
	if (self.Mode == 2) then
		ThrusterWorldPos.z = ThrusterWorldPos.z + self.Z
		ThrusterWorldForce.z = ThrusterWorldForce.z - self.Z
	end

	// Calculate the velocity
	ThrusterWorldForce = ThrusterWorldForce * self.force * mul * 50
	self.ForceLinear, self.ForceAngle = phys:CalculateVelocityOffset( ThrusterWorldForce, ThrusterWorldPos );

	self.ForceLinear = phys:WorldToLocalVector( self.ForceLinear )
end

/*function ENT:Think()
	self.BaseClass.Think(self)

	if (self.Mode > 0 and self:IsOn()) then
		self:Switch( self:IsOn(), self.mul )

		local phys = self:GetPhysicsObject()
		if (!phys:IsValid()) then return end

		local ThrusterWorldPos
		local ThrusterWorldForce
		if (self.Mode == 1) then
			ThrusterWorldPos = self:GetPos() + self.ThrustOffset
			ThrusterWorldForce = (self.ThrustOffset * -1)
		elseif (self.Mode == 2) then
			ThrusterWorldPos = phys:LocalToWorld( self.ThrustOffset )
			ThrusterWorldForce = phys:LocalToWorldVector( self.ThrustOffset * -1 )
			ThrusterWorldPos.z = ThrusterWorldPos.z + self.Z
			ThrusterWorldForce.z = ThrusterWorldForce.z - self.Z
		end

		ThrusterWorldForce = ThrusterWorldForce * self.force * mul * 10
		self.ForceLinear, self.ForceAngle = phys:CalculateVelocityOffset( ThrusterWorldForce, ThrusterWorldPos );
		self.ForceLinear = phys:WorldToLocalVector( self.ForceLinear )

		self:NextThink(CurTime()+0.04)
		return true
	end
end*/

function ENT:Setup(force, force_min, force_max, oweffect, uweffect, owater, uwater, bidir, soundname, mode, angleinputs)
	self:SetForce(force)

	self.OWEffect = oweffect
	self.UWEffect = uweffect
	self.ForceMin = force_min
	self.ForceMax = force_max
	self.BiDir = bidir
	self.OWater = owater
	self.UWater = uwater
	
	-- Preventing client crashes
	local BlockedChars = '["?]'
	if ( string.find(soundname, BlockedChars) ) then
		self:StopSound( self.SoundName )
		soundname = ""
	end

	if (soundname and soundname == "" and self.SoundName and self.SoundName != "") then
		self:StopSound(self.SoundName)
	end

	if (soundname) then
		self.SoundName = Sound(soundname)
	end

	self.Mode = mode
	self:SetMode( self.Mode )

	if (angleinputs) then
		WireLib.AdjustInputs(self, {"Mul", "Pitch", "Yaw"})
	else
		WireLib.AdjustSpecialInputs(self, {"Mul", "X", "Y", "Z", "Vector"}, { "NORMAL", "NORMAL", "NORMAL", "NORMAL", "VECTOR"})
	end

	--self:ShowOutput( self.mul )
end

function ENT:TriggerInput(iname, value)
	if (iname == "Mul") then
		if (value == 0) or (self.ThrustOffset == Vector(0,0,0)) then
			self:Switch(false, math.min(value, self.ForceMax))
		elseif ( (self.BiDir) and (math.abs(value) > 0.01) and (math.abs(value) > self.ForceMin) ) or ( (value > 0.01) and (value > self.ForceMin) ) then
			self:Switch(true, math.Clamp(value, -self.ForceMax, self.ForceMax))
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
	if (self.Mode == 2) then
		self.ThrustOffset = Vector( self.X, self.Y, 0 ):GetNormalized()
	end

	if (self.ThrustOffset == Vector(0,0,0)) then self:SetOn( false ) elseif (self.mul != 0) then self:SetOn( true ) end
	self:Switch( self:IsOn(), self.mul )
end

function ENT:PhysicsSimulate( phys, deltatime )
	if (!self:IsOn()) then return SIM_NOTHING end
	if (self:IsPlayerHolding()) then return SIM_NOTHING end

	if (self:WaterLevel() > 0) then
		if (not self.UWater) then
			self:SetEffect("none")
			return SIM_NOTHING
		end

		if (self.UWEffect == "same") then
			self:SetEffect(self.OWEffect)
		else
			self:SetEffect(self.UWEffect)
		end
	else
		if (not self.OWater) then
			self:SetEffect("none")
			return SIM_NOTHING
		end

		self:SetEffect(self.OWEffect)
	end

	if (self.Mode > 0 and self:IsOn()) then
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
		if (changed) and (self.SoundName and self.SoundName != "") then
			self:StopSound( self.SoundName )
			self:EmitSound( self.SoundName )
		end

		self:NetSetMul( mul )

		if (mul ~= self.PrevOutput) then
			--self:SetOverlayText( "Thrust = " .. math.Round(self.force*mul*1000)/1000 .. "\nMul: " .. math.Round(self.force*1000)/1000 )
			--self:ShowOutput( true )
			self.PrevOutput = mul
		end

		self:SetForce( nil, mul )
	else
		if (self.SoundName and self.SoundName != "") then
			self:StopSound( self.SoundName )
		end

		if (self.PrevOutput) then
			--self:SetOverlayText( "Thrust = Off".."\nMul: "..math.Round(self.force*1000)/1000 )
			--self:ShowOutput( false )
			self.PrevOutput = nil
		end
	end

	local phys = self:GetPhysicsObject()
	if (phys:IsValid()) then
		phys:Wake()
	end

	return true
end

function ENT:ShowOutput( on )
	local mode = "XYZ Local"
	if (self.Mode == 1) then
		mode = "XYZ World"
	elseif (self.Mode == 2) then
		mode = "XY Local, Z World"
	end
	if ( on ) then
		self:SetOverlayText( "Thrust = " .. math.Round(self.force*self.mul*1000)/1000 .. "\nMul: " .. math.Round(self.force*1000)/1000 .. "\nMode: "..mode )
	else
		self:SetOverlayText( "Thrust = Off".."\nMul: "..math.Round(self.force*1000)/1000 .. "\nMode: "..mode )
	end
end

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
