
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "Wheel"
ENT.OverlayDelay = 0

--[[---------------------------------------------------------
   Name: Initialize
   Desc: First function called. Use to set up your entity
---------------------------------------------------------]]
function ENT:Initialize()

	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )
	self.Entity:SetUseType( SIMPLE_USE )

	self:SetToggle( false )

	self.ToggleState = false
	self.BaseTorque = 1
	self.TorqueScale = 1
	self.Breaking = 0
	self.SpeedMod = 0
	self.Go = 0

	self.Inputs = Wire_CreateInputs(self.Entity, { "A: Go", "B: Break", "C: SpeedMod" })

end

--[[---------------------------------------------------------
   Sets the base torque
---------------------------------------------------------]]
function ENT:SetBaseTorque( base )

	self.BaseTorque = base
	if ( self.BaseTorque == 0 ) then self.BaseTorque = 1 end
	self:UpdateOverlayText()

end

--[[---------------------------------------------------------
   Sets the base torque
---------------------------------------------------------]]
function ENT:UpdateOverlayText()

	txt = "Torque: " .. math.floor( self.TorqueScale * self.BaseTorque ) .. "\nSpeed: 0\nBreak: " .. self.Breaking .. "\nSpeedMod: " .. math.floor( self.SpeedMod * 100 ) .. "%"
	self:SetOverlayText( txt )

end

--[[---------------------------------------------------------
   Sets the axis (world space)
---------------------------------------------------------]]
function ENT:SetAxis( vec )

	self.Axis = self.Entity:GetPos() + vec * 512
	self.Axis = self.Entity:NearestPoint( self.Axis )
	self.Axis = self.Entity:WorldToLocal( self.Axis )

end


--[[---------------------------------------------------------
   Name: PhysicsCollide
   Desc: Called when physics collides. The table contains
			data on the collision
---------------------------------------------------------]]
function ENT:PhysicsCollide( data, physobj )
end


--[[---------------------------------------------------------
   Name: PhysicsUpdate
   Desc: Called to update the physics .. or something.
---------------------------------------------------------]]
function ENT:PhysicsUpdate( physobj )
end


--[[---------------------------------------------------------
   Name: KeyValue
   Desc: Called when a keyvalue is added to us (usually from the map)
---------------------------------------------------------]]
function ENT:KeyValue( key, value )
end


--[[---------------------------------------------------------
   Name: Think
   Desc: Entity's think function.
---------------------------------------------------------]]
function ENT:Think()
end


--[[---------------------------------------------------------
   Name: OnTakeDamage
   Desc: Entity takes damage
---------------------------------------------------------]]
function ENT:OnTakeDamage( dmginfo )

	self.Entity:TakePhysicsDamage( dmginfo )

end


function ENT:SetMotor( Motor )
	self.Motor = Motor
end

function ENT:GetMotor()

	if (!self.Motor) then
		self.Motor = constraint.FindConstraintEntity( self.Entity, "Motor" )
		if (!self.Motor or !self.Motor:IsValid()) then
			self.Motor = nil
		end
	end

	return self.Motor
end


function ENT:SetDirection( dir )
	self.Entity:SetNetworkedInt( 1, dir )
	self.Direction = dir
end

function ENT:SetToggle( bool )
	self.Toggle = bool
end

function ENT:GetToggle()
	return self.Toggle
end


function ENT:SetFwd( fwd )
	self.Fwd = fwd
end

function ENT:SetBck( bck )
	self.Bck = bck
end

function ENT:SetStop( stop )
	self.Stop = stop
end


--[[---------------------------------------------------------
   Forward
---------------------------------------------------------]]
function ENT:Forward( mul )

	-- Is this key invalid now? If so return false to remove it
	if ( !self.Entity:IsValid() ) then return false end
	local Motor = self:GetMotor()
	if ( Motor and !Motor:IsValid() ) then
		Msg("Wheel doesn't have a motor!\n");
		return false
	elseif ( !Motor ) then return false
	end

	mul = mul or 1
	local mdir = Motor.direction
	local Speed = mdir * mul * self.TorqueScale * (1 + self.SpeedMod)

	txt = "Torque: " .. math.floor( self.TorqueScale * self.BaseTorque ) .. "\nSpeed: " .. (mdir * mul * (1 + self.SpeedMod)) .. "\nBreak: " .. self.Breaking .. "\nSpeedMod: " .. math.floor( self.SpeedMod * 100 ) .. "%"
	--self.BaseClass.BaseClass.SetOverlayText(self, txt)
	self:SetOverlayText(txt)

	Motor:Fire( "Scale", Speed, 0 )
	Motor:GetTable().forcescale = Speed
	Motor:Fire( "Activate", "" , 0 )

	return true

end

--[[---------------------------------------------------------
   Reverse
---------------------------------------------------------]]
function ENT:Reverse( )
	return self:Forward( -1 )
end


--[[---------------------------------------------------------
   Name: TriggerInput
   Desc: the inputs
---------------------------------------------------------]]
function ENT:TriggerInput(iname, value)
	if (iname == "A: Go") then
		if ( value == self.Fwd ) then self.Go = 1
		elseif ( value == self.Bck ) then self.Go = -1
		elseif ( value == self.Stop ) then self.Go =0 end
	elseif (iname == "B: Break") then
		self.Breaking = value
	elseif (iname == "C: SpeedMod") then
		self.SpeedMod = (value / 100)
	end
	self:Forward( self.Go )
end



--[[---------------------------------------------------------
   Name: PhysicsUpdate
   Desc: happy fun time breaking function
---------------------------------------------------------]]
function ENT:PhysicsUpdate( physobj )
	local vel = physobj:GetVelocity()

	if (self.Breaking > 0) then -- to prevent badness
		if (self.Breaking >= 100) then --100% breaking!!!
			vel.x = 0 --full stop!
			vel.y = 0
		else
			vel.x = vel.x * ((100.0 - self.Breaking)/100.0)
			vel.y = vel.y * ((100.0 - self.Breaking)/100.0)
		end
	end

	physobj:SetVelocity(vel)
end



--[[---------------------------------------------------------
   Todo? Scale Motor:GetTable().direction?
---------------------------------------------------------]]
function ENT:SetTorque( torque )

	if ( self.BaseTorque == 0 ) then self.BaseTorque = 1 end

	self.TorqueScale = torque / self.BaseTorque

	local Motor = self:GetMotor()
	if (!Motor || !Motor:IsValid()) then return end
	Motor:Fire( "Scale", Motor:GetTable().direction * Motor:GetTable().forcescale * self.TorqueScale , 0 )

	txt = "Torque: " .. math.floor( self.TorqueScale * self.BaseTorque )
	--self.BaseClass.BaseClass.SetOverlayText(self, txt)
	self:SetOverlayText(txt)
end

--[[---------------------------------------------------------
   Creates the direction arrows on the wheel
---------------------------------------------------------]]
function ENT:DoDirectionEffect()

	local Motor = self:GetMotor()
	if (!Motor || !Motor:IsValid()) then return end

	local effectdata = EffectData()
		effectdata:SetOrigin( self.Axis )
		effectdata:SetEntity( self.Entity )
		effectdata:SetScale( Motor.direction )
	util.Effect( "wheel_indicator", effectdata, true, true )

end

--[[---------------------------------------------------------
   Reverse the wheel direction when a player uses the wheel
---------------------------------------------------------]]
function ENT:Use( activator, caller, type, value )

	local Motor = self:GetMotor()
	local Owner = self:GetPlayer()

	if (Motor and (Owner == nil or Owner == activator)) then

		if (Motor:GetTable().direction == 1) then
			Motor:GetTable().direction = -1
		else
			Motor:GetTable().direction = 1
		end

		Motor:Fire( "Scale", Motor:GetTable().direction * Motor:GetTable().forcescale * self.TorqueScale, 0 )
		self:SetDirection( Motor:GetTable().direction )

		self:DoDirectionEffect()

	end

end


function MakeWireWheel( pl, Pos, Ang, model, Vel, aVel, frozen, fwd, bck, stop, BaseTorque, direction, axis, Data )

	if ( !pl:CheckLimit( "wire_wheels" ) ) then return false end

	local wheel = ents.Create( "gmod_wire_wheel" )
	if ( !wheel:IsValid() ) then return end

	wheel:SetModel( model )
	wheel:SetPos( Pos )
	wheel:SetAngles( Ang )
	wheel:Spawn()

	wheel:SetPlayer( pl )

	duplicator.DoGenericPhysics( wheel, pl, Data )

	wheel.fwd = fwd
	wheel.bck = bck
	wheel.stop = stop

	wheel:SetFwd( fwd )
	wheel:SetBck( bck )
	wheel:SetStop( stop )

	if ( axis ) then
		wheel.Axis = axis
	end

	if ( direction ) then
		wheel:SetDirection( direction )
	end

	wheel:SetBaseTorque( BaseTorque )
	wheel:UpdateOverlayText()

	pl:AddCount( "wire_wheels", wheel )

	return wheel

end

duplicator.RegisterEntityClass( "gmod_wire_wheel", MakeWireWheel, "Pos", "Ang", "Model", "Vel", "aVel", "frozen", "fwd", "bck", "stop", "BaseTorque", "direction", "Axis", "Data" )

function ENT:SetWheelBase(Base)
	Base:DeleteOnRemove( self )
	self.Base = Base
end

function ENT:BuildDupeInfo()
	local info = self.BaseClass.BuildDupeInfo(self) or {}
	if ValidEntity(self.Base) then
		info.Base = self.Base:EntIndex()
	end
	return info
end

function ENT:ApplyDupeInfo(ply, ent, info, GetEntByID)
	self.BaseClass.ApplyDupeInfo(self, ply, ent, info, GetEntByID)
	local Base
	if info.Base then
		Base = GetEntByID(info.Base)
		if not Base then
			local Base = ents.GetByIndex(info.Base)
		end
	end
	if ValidEntity(Base) then
		self:SetWheelBase(Base)
	end
end
