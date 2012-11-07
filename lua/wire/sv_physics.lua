


function WireToolMakeForcer( self, trace, ply )

	local showbeam		= self:GetClientNumber( "beam" ) == 1
	local reaction		= self:GetClientNumber( "reaction" ) == 1
	local multiplier	= self:GetClientNumber( "multiplier" )
	local length		= self:GetClientNumber( "length" )
	local model			= self:GetModel()

	if trace.Entity:IsValid() and trace.Entity:GetClass() == "gmod_wire_forcer" then
		trace.Entity:Setup(multiplier, length, showbeam, reaction)
		return true
	end

	if not self:GetSWEP():CheckLimit( "wire_forcers" ) then return false end
	if not util.IsValidModel( model ) or not util.IsValidProp( model ) then return false end

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90

	local wire_forcer = MakeWireForcer( ply, trace.HitPos, Ang, model, multiplier, length, showbeam, reaction )

	local min = wire_forcer:OBBMins()
	if model == "models/jaanus/wiretool/wiretool_grabber_forcer.mdl" then
	   wire_forcer:SetPos( trace.HitPos - trace.HitNormal * (min.z + 20) )
	else
	   wire_forcer:SetPos( trace.HitPos - trace.HitNormal * min.z )
	end

	return wire_forcer
end


function WireToolMakeDetonator( self, trace, ply )

	local damage = self:GetClientNumber("damage")
	local model = self:GetModel()

	if trace.Entity:IsValid() and trace.Entity:GetClass() == "gmod_wire_detonator" then
		trace.Entity:Setup(damage)
		trace.Entity.damage = damage
		return true
	end

	if not self:GetSWEP():CheckLimit( "wire_detonators" ) then return false end
	if not util.IsValidModel( model ) or not util.IsValidProp( model ) then return false end

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90

	local wire_detonator = MakeWireDetonator(ply, trace.HitPos, Ang, model, damage)
	wire_detonatortarget = trace.Entity

	local min = wire_detonator:OBBMins()
	wire_detonator:SetPos(trace.HitPos - trace.HitNormal * min.z)

	return wire_detonator
end


function WireToolMakeGrabber( self, trace, ply )

	local Range 	= self:GetClientNumber("Range")
	local Gravity	= self:GetClientNumber("Gravity") ~= 0
	local model		= self:GetModel()

	if trace.Entity:IsValid() and trace.Entity:GetClass() == "gmod_wire_grabber" then
		trace.Entity:Setup(Range, Gravity)
		return true
	end

	if not self:GetSWEP():CheckLimit( "wire_grabbers" ) then return false end
	if not util.IsValidModel( model ) or not util.IsValidProp( model ) then return false end

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90

	local wire_grabber = MakeWireGrabber( ply, trace.HitPos, Ang, model, Range, Gravity )

	local min = wire_grabber:OBBMins()
	if model == "models/jaanus/wiretool/wiretool_grabber_forcer.mdl" then
	   wire_grabber:SetPos( trace.HitPos - trace.HitNormal * (min.z + 20) )
	else
	   wire_grabber:SetPos( trace.HitPos - trace.HitNormal * min.z )
	end

	return wire_grabber
end

function WireToolMakeIgniter( self, trace, ply )

	local trgply	= self:GetClientNumber( "trgply" ) ~= 0
	local Range		= self:GetClientNumber("Range")
	local model		= self:GetModel()

	if trace.Entity:IsValid() and trace.Entity:GetClass() == "gmod_wire_igniter" then
		trace.Entity:Setup(trgply, Range)
		return true
	end

	if not self:GetSWEP():CheckLimit( "wire_igniters" ) then return false end
	if not util.IsValidModel( model ) or not util.IsValidProp( model ) then return false end

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90

	local wire_igniter = MakeWireIgniter( ply, trace.HitPos, Ang, model, trgply, Range )

	local min = wire_igniter:OBBMins()
	wire_igniter:SetPos( trace.HitPos - trace.HitNormal * min.z )

	return wire_igniter
end


function WireToolMakeTrail( self, trace, ply )

	local mat = self:GetClientInfo("material")

	if trace.Entity:IsValid() and trace.Entity:GetClass() == "gmod_wire_trail" then
	    trace.Entity.mat = mat
	    trace.Entity:Setup(mat)
		return true
	end

	if not self:GetSWEP():CheckLimit( "wire_trails" ) then return false end

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90

	local wire_trail = MakeWireTrail( ply, trace.HitPos, Ang, self.Model, mat )

	local min = wire_trail:OBBMins()
	wire_trail:SetPos( trace.HitPos - trace.HitNormal * min.z )

	return wire_trail
end


function WireToolMakeThruster( self, trace, ply )

	local force			= self:GetClientNumber( "force" )
	local force_min		= self:GetClientNumber( "force_min" )
	local force_max		= self:GetClientNumber( "force_max" )
	local model			= self:GetModel()
	local bidir			= self:GetClientNumber( "bidir" ) ~= 0
	local nocollide		= self:GetClientNumber( "collision" ) == 0
	local soundname		= self:GetClientInfo( "soundname" )
	local oweffect		= self:GetClientInfo( "oweffect" )
	local uweffect		= self:GetClientInfo( "uweffect" )
	local owater		= self:GetClientNumber( "owater" ) ~= 0
	local uwater		= self:GetClientNumber( "uwater" ) ~= 0

	if not trace.Entity:IsValid() then nocollide = false end

	-- If we shot a wire_thruster change its force
	if trace.Entity:IsValid() and trace.Entity:GetClass() == "gmod_wire_thruster" then
		trace.Entity:SetForce( force )

		trace.Entity:SetDatEffect(uwater, owater, uweffect, oweffect)


		trace.Entity:Setup(force, force_min, force_max, oweffect, uweffect, owater, uwater, bidir, soundname)

		trace.Entity.force		= force
		trace.Entity.force_min	= force_min
		trace.Entity.force_max	= force_max
		trace.Entity.bidir		= bidir
		trace.Entity.soundname	= soundname
		trace.Entity.oweffect	= oweffect
		trace.Entity.uweffect	= uweffect
		trace.Entity.owater		= owater
		trace.Entity.uwater		= uwater
		trace.Entity.nocollide	= nocollide

		if nocollide == true then trace.Entity:GetPhysicsObject():EnableCollisions( false ) end

		return true
	end

	if not self:GetSWEP():CheckLimit( "wire_thrusters" ) then return false end
	if not util.IsValidModel( model ) or not util.IsValidProp( model ) then return false end

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90

	local wire_thruster = MakeWireThruster( ply, trace.HitPos, Ang, model, force, force_min, force_max, oweffect, uweffect, owater, uwater, bidir, soundname, nocollide )

	local min = wire_thruster:OBBMins()
	wire_thruster:SetPos( trace.HitPos - trace.HitNormal * min.z )

	return wire_thruster
end
