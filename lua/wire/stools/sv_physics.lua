
function WireToolMakeWeight( self, trace, ply )

	if trace.Entity:IsValid() and trace.Entity:GetClass() == "gmod_wire_weight" and trace.Entity.pl == ply then
		return true
	end

	local model = self:GetModel()

	if not self:GetSWEP():CheckLimit( "wire_weights" ) then return false end

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90

	local wire_weight = MakeWireWeight( ply, trace.HitPos, Ang, model )

	local min = wire_weight:OBBMins()
	wire_weight:SetPos( trace.HitPos - trace.HitNormal * min.z )

	return wire_weight
end


function WireToolMakeExplosivesSimple( self, trace, ply )
	if not self:GetSWEP():CheckLimit( "wire_simple_explosive" ) then return false end

	local _trigger			= self:GetClientNumber( "tirgger" )
	local _damage 			= math.Clamp( self:GetClientNumber( "damage" ), 0, 1500 )
	local _removeafter		= self:GetClientNumber( "removeafter" ) == 1
	local _doblastdamage	= self:GetClientNumber( "doblastdamage" ) == 1
	local _radius			= math.Clamp( self:GetClientNumber( "radius" ), 0, 10000 )
	local _freeze			= self:GetClientNumber( "freeze" ) == 1
	local _weld				= self:GetClientNumber( "weld" ) == 1
	local _noparentremove	= self:GetClientNumber( "noparentremove" ) == 1
	local _nocollide		= self:GetClientNumber( "nocollide" ) == 1
	local _weight			= math.Max(self:GetClientNumber( "weight" ), 1)

	--get & check selected model
	_model = self:GetSelModel( true )
	if not _model then return false end

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90

	local explosive = MakeWireSimpleExplosive( ply, trace.HitPos, Ang, _model, _trigger, _damage, _removeafter, _doblastdamage, _radius, _nocollide )

	local min = explosive:OBBMins()
	explosive:SetPos( trace.HitPos - trace.HitNormal * min.z )

	if _freeze then
		explosive:GetPhysicsObject():Sleep() --will freeze the explosive till something touches it
	end

	explosive.Entity:GetPhysicsObject():SetMass(_weight)
	-- Make sure the weight is duplicated as well (TheApathetic)
	duplicator.StoreEntityModifier( explosive, "MassMod", {Mass = _weight} )

	undo.Create("WireSimpleExplosive")
		undo.AddEntity( explosive )

	-- Don't weld to world
	if trace.Entity:IsValid() and _weld then
		if _noparentremove then
			local const, nocollide = constraint.Weld( explosive, trace.Entity, 0, trace.PhysicsBone, 0, collision == 0, false )
			undo.AddEntity( const )
		else
			local const, nocollide = constraint.Weld( explosive, trace.Entity, 0, trace.PhysicsBone, 0, collision == 0, true )
			undo.AddEntity( const )
		end
	end

		undo.SetPlayer( ply )
	undo.Finish()

	return true
end


function WireToolMakeWheel( self, trace, ply )
	if trace.Entity and trace.Entity:IsPlayer() then return false end
	if SERVER and not util.IsValidPhysicsObject( trace.Entity, trace.PhysicsBone ) then return false end
	if CLIENT then return true end

	if not self:GetSWEP():CheckLimit( "wire_wheels" ) then return false end

	local targetPhys = trace.Entity:GetPhysicsObjectNum( trace.PhysicsBone )

	-- Get client's CVars
	local torque		= self:GetClientNumber( "torque" )
	local friction 		= self:GetClientNumber( "friction" )
	local nocollide		= self:GetClientNumber( "nocollide" )
	local limit			= self:GetClientNumber( "forcelimit" )
	local model			= ply:GetInfo("wheel_model")

	local fwd			= self:GetClientNumber( "fwd" )
	local bck			= self:GetClientNumber( "bck" )
	local stop			= self:GetClientNumber( "stop" )

	if not util.IsValidModel( model ) or not util.IsValidProp( model ) then return false end

	if fwd == stop or bck == stop or fwd == bck then return false end

	-- Create the wheel
	local wheelEnt = MakeWireWheel( ply, trace.HitPos, Angle(0,0,0), model, nil, nil, nil, fwd, bck, stop, torque )

	-- Make sure we have our wheel angle
	self.wheelAngle = Angle( tonumber(ply:GetInfo( "wheel_rx" )), tonumber(ply:GetInfo( "wheel_ry" )), tonumber(ply:GetInfo( "wheel_rz" )) )

	local TargetAngle = trace.HitNormal:Angle() + self.wheelAngle
	wheelEnt:SetAngles( TargetAngle )

	local CurPos = wheelEnt:GetPos()
	local NearestPoint = wheelEnt:NearestPoint( CurPos - (trace.HitNormal * 512) )
	local wheelOffset = CurPos - NearestPoint

	wheelEnt:SetPos( trace.HitPos + wheelOffset + trace.HitNormal )

	-- Wake up the physics object so that the entity updates
	wheelEnt:GetPhysicsObject():Wake()

	local TargetPos = wheelEnt:GetPos()

	-- Set the hinge Axis perpendicular to the trace hit surface
	local LPos1 = wheelEnt:GetPhysicsObject():WorldToLocal( TargetPos + trace.HitNormal )
	local LPos2 = targetPhys:WorldToLocal( trace.HitPos )

	local constraint, axis = constraint.Motor( wheelEnt, trace.Entity, 0, trace.PhysicsBone, LPos1,	LPos2, friction, torque, 0, nocollide, false, ply, limit )

	undo.Create("WireWheel")
		undo.AddEntity( axis )
		undo.AddEntity( constraint )
		undo.AddEntity( wheelEnt )
		undo.SetPlayer( ply )
	undo.Finish()

	ply:AddCleanup( "wire_wheels", axis )
	ply:AddCleanup( "wire_wheels", constraint )
	ply:AddCleanup( "wire_wheels", wheelEnt )

	--BUGFIX:WIREMOD-11:Deleting prop did not deleting wheels
	wheelEnt:SetWheelBase(trace.Entity)

	wheelEnt:SetMotor( constraint )
	wheelEnt:SetDirection( constraint.direction )
	wheelEnt:SetAxis( trace.HitNormal )
	wheelEnt:SetToggle( toggle )
	wheelEnt:DoDirectionEffect()
	wheelEnt:SetBaseTorque( torque )

	return true
end


function WireToolMakeForcer( self, trace, ply )

	local showbeam		= self:GetClientNumber( "beam" ) == 1
	local reaction		= self:GetClientNumber( "reaction" ) == 1
	local multiplier	= self:GetClientNumber( "multiplier" )
	local length		= self:GetClientNumber( "length" )
	local model			= self:GetModel()

	if trace.Entity:IsValid() and trace.Entity:GetClass() == "gmod_wire_forcer" and trace.Entity.pl == ply then
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

	if trace.Entity:IsValid() and trace.Entity:GetClass() == "gmod_wire_detonator" and trace.Entity.pl == ply then
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

	if trace.Entity:IsValid() and trace.Entity:GetClass() == "gmod_wire_grabber" and trace.Entity.pl == ply then
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


function WireToolMakeHoverball( self, trace, ply )

	local speed 		= self:GetClientNumber( "speed" )
	local resistance 	= self:GetClientNumber( "resistance" )
	local strength	 	= self:GetClientNumber( "strength" )
	local starton	 	= self:GetClientNumber( "starton" ) == 1

	resistance 	= math.Clamp( resistance, 0, 20 )
	strength	= math.Clamp( strength, 0.1, 20 )

	-- We shot an existing hoverball - just change its values
	if trace.Entity:IsValid() and trace.Entity:GetClass() == "gmod_wire_hoverball" and trace.Entity.pl == ply then

		trace.Entity:SetSpeed( speed )
		trace.Entity:SetAirResistance( resistance )
		trace.Entity:SetStrength( strength )

		trace.Entity.speed		= speed
		trace.Entity.strength	= strength
		trace.Entity.resistance	= resistance

		if not starton then trace.Entity:DisableHover() else trace.Entity:EnableHover() end

		return true
	end

	if not self:GetSWEP():CheckLimit( "wire_hoverballs" ) then return false end

	-- If we hit the world then offset the spawn position
	if trace.Entity:IsWorld() then
		trace.HitPos = trace.HitPos + trace.HitNormal * 8
	end

	local wire_ball = MakeWireHoverBall( ply, trace.HitPos, Angle(0,0,0), self.Model, speed, resistance, strength )

	if not starton then wire_ball:DisableHover() end

	return wire_ball
end


function WireToolMakeIgniter( self, trace, ply )

	local trgply	= self:GetClientNumber( "trgply" ) ~= 0
	local Range		= self:GetClientNumber("Range")
	local model		= self:GetModel()

	if trace.Entity:IsValid() and trace.Entity:GetClass() == "gmod_wire_igniter" and trace.Entity.pl == ply then
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

	if trace.Entity:IsValid() and trace.Entity:GetClass() == "gmod_wire_trail" and trace.Entity.pl == ply then
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
	local sound			= self:GetClientNumber( "sound" ) ~= 0
	local oweffect		= self:GetClientInfo( "oweffect" )
	local uweffect		= self:GetClientInfo( "uweffect" )
	local owater		= self:GetClientNumber( "owater" ) ~= 0
	local uwater		= self:GetClientNumber( "uwater" ) ~= 0

	if not trace.Entity:IsValid() then nocollide = false end

	-- If we shot a wire_thruster change its force
	if trace.Entity:IsValid() and trace.Entity:GetClass() == "gmod_wire_thruster" and trace.Entity.pl == ply then
		trace.Entity:SetForce( force )
		trace.Entity:SetEffect( effect )
		trace.Entity:Setup(force, force_min, force_max, oweffect, uweffect, owater, uwater, bidir, sound)

		trace.Entity.force		= force
		trace.Entity.force_min	= force_min
		trace.Entity.force_max	= force_max
		trace.Entity.bidir		= bidir
		trace.Entity.sound		= sound
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

	local wire_thruster = MakeWireThruster( ply, trace.HitPos, Ang, model, force, force_min, force_max, oweffect, uweffect, owater, uwater, bidir, sound, nocollide )

	local min = wire_thruster:OBBMins()
	wire_thruster:SetPos( trace.HitPos - trace.HitNormal * min.z )

	return wire_thruster
end
