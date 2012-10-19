
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "Thruster"

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
	self.ForceAngle		= self.ThrustOffset:GetNormalized() * -1

	self:SetForce( 2000 )

	self.OWEffect = "fire"
	self.UWEffect = "same"

	self:SetOffset( self.ThrustOffset )
	self:StartMotionController()

	self:Switch( false )

	self.Inputs = Wire_CreateInputs(self, { "A" })

	self.SoundName = Sound( "PhysicsCannister.ThrusterLoop" )
end

function ENT:OnRemove()
	self.BaseClass.OnRemove(self)

	if (self.SoundName and self.SoundName != "") then
		self:StopSound(self.SoundName)
	end
end

function ENT:SetForce( force, mul )
	if (force) then
		self.force = force
		self:ShowOutput()
	end
	mul = mul or 1

	local phys = self:GetPhysicsObject()
	if (!phys:IsValid()) then
		Msg("Warning: [",self,"] Physics object isn't valid!\n")
		return
	end

	// Get the data in worldspace
	local ThrusterWorldPos = phys:LocalToWorld( self.ThrustOffset )
	local ThrusterWorldForce = phys:LocalToWorldVector( self.ThrustOffset * -1 )

	// Calculate the velocity
	ThrusterWorldForce = ThrusterWorldForce * self.force * mul * 50
	self.ForceLinear, self.ForceAngle = phys:CalculateVelocityOffset( ThrusterWorldForce, ThrusterWorldPos );
	self.ForceLinear = phys:WorldToLocalVector( self.ForceLinear )

	if ( mul > 0 ) then
		self:SetOffset( self.ThrustOffset )
	else
		self:SetOffset( self.ThrustOffsetR )
	end

--	self:SetNetworkedVector( 1, self.ForceAngle )
--	self:SetNetworkedVector( 2, self.ForceLinear )
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

	self.OWEffect = oweffect
	self.UWEffect = uweffect
	self.ForceMin = force_min
	self.ForceMax = force_max
	self.BiDir = bidir
	self.OWater = owater
	self.UWater = uwater

	if (!soundname) then soundname = "" end
	
	-- Preventing client crashes
	local BlockedChars = '["?]'
	if ( string.find(soundname, BlockedChars) ) then
		self:StopSound( self.SoundName )
		soundname = ""
	end

	if (soundname == "") then
		self:StopSound( self.SoundName )
	end

	self.SoundName = Sound( soundname )

	--self:SetOverlayText( "Thrust = " .. 0 .. "\nMul: " .. math.Round(force*1000)/1000 )
end

function ENT:TriggerInput(iname, value)
	if (iname == "A") then
		if ( (self.BiDir) and (math.abs(value) > 0.01) and (math.abs(value) > self.ForceMin) ) or ( (value > 0.01) and (value > self.ForceMin) ) then
			self:Switch(true, math.min(value, self.ForceMax))
		else
			self:Switch(false, 0)
		end
	end
end

function ENT:PhysicsSimulate( phys, deltatime )
	if (!self:IsOn()) then return SIM_NOTHING end

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

	local ForceAngle, ForceLinear = self.ForceAngle, self.ForceLinear

	return ForceAngle, ForceLinear, SIM_LOCAL_ACCELERATION
end

function ENT:Switch( on, mul )
	if (!self:IsValid()) then return false end

	local changed = (self:IsOn() ~= on)
	self:SetOn( on )


	if (on) then
		if (changed) and (self.SoundName and self.SoundName != "") then
			self:StopSound( self.SoundName )
			self:EmitSound( self.SoundName )
		end
		
		self.mul = mul

		/*if (mul ~= self.PrevOutput) then
			self:SetOverlayText( "Thrust = " .. math.Round(self.force*mul*1000)/1000 .. "\nMul: " .. math.Round(self.force*1000)/1000 )
			self.PrevOutput = mul
		end*/

		self:SetForce( nil, mul )
	else
		if (self.SoundName and self.SoundName != "") then
			self:StopSound( self.SoundName )
		end
		
		self.mul = 0

		/*if (self.PrevOutput) then
			self:SetOverlayText( "Thrust = Off".."\nMul: "..math.Round(self.force*1000)/1000 )
			self.PrevOutput = nil
		end*/
	end
	self:ShowOutput()

	local phys = self:GetPhysicsObject()
	if (phys:IsValid()) then
		phys:Wake()
	end

	return true
end

function ENT:ShowOutput()
	self:SetOverlayText(string.format("Thrust: %s\nMul: %.2f",
		self:IsOn() and tostring(math.Round(self.force*self.mul,2)) or "off",
		self.mul or 0
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


function MakeWireThruster( pl, Pos, Ang, model, force, force_min, force_max, oweffect, uweffect, owater, uwater, bidir, soundname, nocollide )
	if not pl:CheckLimit( "wire_thrusters" ) then return false end

	local wire_thruster = ents.Create( "gmod_wire_thruster" )
	if not wire_thruster:IsValid() then return false end
	wire_thruster:SetModel( model )

	wire_thruster:SetAngles( Ang )
	wire_thruster:SetPos( Pos )
	wire_thruster:Spawn()

	wire_thruster:Setup(force, force_min, force_max, oweffect, uweffect, owater, uwater, bidir, soundname)
	wire_thruster:SetPlayer( pl )

	if nocollide == true then wire_thruster:GetPhysicsObject():EnableCollisions( false ) end

	local ttable = {
		force		= force,
		force_min	= force_min,
		force_max	= force_max,
		bidir       = bidir,
		soundname   = soundname,
		pl			= pl,
		oweffect	= oweffect,
		uweffect	= uweffect,
		owater		= owater,
		uwater		= uwater,
		nocollide	= nocollide
	}
	table.Merge(wire_thruster:GetTable(), ttable )

	pl:AddCount( "wire_thrusters", wire_thruster )

	return wire_thruster
end

duplicator.RegisterEntityClass("gmod_wire_thruster", MakeWireThruster, "Pos", "Ang", "Model", "force", "force_min", "force_max", "oweffect", "uweffect", "owater", "uwater", "bidir", "soundname", "nocollide")

