AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include('shared.lua')

ENT.WireDebugName = "Wheel"
function ENT:Initialize()
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )
	self:SetUseType( SIMPLE_USE )

	self.BaseTorque = 1
	self.TorqueScale = 1
	self.Breaking = 0
	self.SpeedMod = 0
	self.Go = 0

	self.Inputs = Wire_CreateInputs(self, { "A: Go", "B: Break", "C: SpeedMod" })
end

function ENT:Setup(fwd, bck, stop, torque, direction)
	self.fwd = fwd
	self.bck = bck
	self.stop = stop
	if self.BaseTorque == 1 then self.BaseTorque = math.max(1, torque)
	else self:SetTorque(torque)
	end
	if direction then self:SetDirection( direction ) end
	
	self:UpdateOverlayText()
end

--[[---------------------------------------------------------
   Sets the base torque
---------------------------------------------------------]]
function ENT:UpdateOverlayText()
	self:SetOverlayText( "Torque: " .. math.floor( self.TorqueScale * self.BaseTorque ) .. "\nSpeed: 0\nBreak: " .. self.Breaking .. "\nSpeedMod: " .. math.floor( self.SpeedMod * 100 ) .. "%" )
end

--[[---------------------------------------------------------
   Sets the axis (world space)
---------------------------------------------------------]]
function ENT:SetAxis( vec )
	self.Axis = self:GetPos() + vec * 512
	self.Axis = self:NearestPoint( self.Axis )
	self.Axis = self:WorldToLocal( self.Axis )
end

function ENT:OnTakeDamage( dmginfo )
	self:TakePhysicsDamage( dmginfo )
end

function ENT:SetMotor( Motor )
	self.Motor = Motor
end

function ENT:GetMotor()
	if (!self.Motor) then
		self.Motor = constraint.FindConstraintEntity( self, "Motor" )
		if (!self.Motor or !self.Motor:IsValid()) then
			self.Motor = nil
		end
	end
	return self.Motor
end

function ENT:SetDirection( dir )
	self:SetNetworkedInt( 1, dir )
	self.direction = dir
end


--[[---------------------------------------------------------
   Forward
---------------------------------------------------------]]
function ENT:Forward( mul )
	if ( !self:IsValid() ) then return false end
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
   Name: TriggerInput
   Desc: the inputs
---------------------------------------------------------]]
function ENT:TriggerInput(iname, value)
	if (iname == "A: Go") then
		if ( value == self.fwd ) then self.Go = 1
		elseif ( value == self.bck ) then self.Go = -1
		elseif ( value == self.stop ) then self.Go =0 end
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
	else
		return -- physobj:SetVelocity(physobj:GetVelocity()) will create constant acceleration
	end

	physobj:SetVelocity(vel)
end



--[[---------------------------------------------------------
   Todo? Scale Motor:GetTable().direction?
---------------------------------------------------------]]
function ENT:SetTorque( torque )
	self.TorqueScale = torque / self.BaseTorque

	local Motor = self:GetMotor()
	if not IsValid(Motor) then return end
	Motor:Fire( "Scale", Motor:GetTable().direction * Motor:GetTable().forcescale * self.TorqueScale , 0 )

	self:UpdateOverlayText()
end

--[[---------------------------------------------------------
   Creates the direction arrows on the wheel
---------------------------------------------------------]]
function ENT:DoDirectionEffect()
	local Motor = self:GetMotor()
	if not IsValid(Motor) then return end

	local effectdata = EffectData()
		effectdata:SetOrigin( self.Axis )
		effectdata:SetEntity( self )
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
	wheel.pl = pl

	duplicator.DoGenericPhysics( wheel, pl, Data )

	if ( axis ) then
		wheel.Axis = axis
	end
	
	wheel:Setup(fwd,bck,stop, BaseTorque, direction)

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
	if IsValid(self.Base) then
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
	if IsValid(Base) then
		self:SetWheelBase(Base)
	end
end
