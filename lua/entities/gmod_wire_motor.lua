AddCSLuaFile()
DEFINE_BASECLASS( "base_wire_entity" )
ENT.PrintName = "Motor"
ENT.WireDebugName = "Motor"

if CLIENT then
	ENT.RenderGroup = RENDERGROUP_BOTH
	return
end

function ENT:Initialize()
	BaseClass.Initialize(self)
	self.Inputs = Wire_CreateInputs( self, { "Mul" } )
end

function ENT:SetConstraint( c )
	self.constraint = c
	self.Mul = 0
	self:ShowOutput()
end

function ENT:SetAxis( a )
	self.axis = a
end

function ENT:TriggerInput(iname, value)
	if iname == "Mul" then
		self.Mul = value
		self:ShowOutput()
		local Motor = self.constraint
		if not IsValid( Motor ) then
			return false
		end
		Motor:Fire( "Scale", value, 0 )
		Motor:Fire( "Activate", "" , 0 )
	end
end

function ENT:ShowOutput()
	if self.constraint and IsValid( self.constraint ) then

		local torque = self.constraint.torque
		local current_torque = torque * self.Mul
		local forcelimit = self.constraint.forcelimit
		local friction = self.constraint.friction

		self:SetOverlayText( string.format( "Current Torque: %s\nTorque: %s\nForce Limit: %s\nHinge Friction: %s", current_torque, torque, forcelimit, friction ) )
	end
end

--needed for the constraint to find the controller after being duplicator pasted
local WireMotorTracking = {}

function MakeWireMotorController( pl, Pos, Ang, MyEntId, model, const, axis )
	local controller = WireLib.MakeWireEnt(pl, {Class = "gmod_wire_motor", Pos=Pos, Angle=Ang, Model=model})
	if not IsValid(controller) then return end

	if not const then
		WireMotorTracking[ MyEntId ] = controller
	else
		controller.MyId = controller:EntIndex()
		const.MyCrtl = controller:EntIndex()
		controller:SetConstraint( const )
		controller:DeleteOnRemove( const )
	end

	if axis then
		controller:SetAxis( axis )
		controller:DeleteOnRemove( axis )
	end

	return controller
end
duplicator.RegisterEntityClass("gmod_wire_motor", MakeWireMotorController, "Pos", "Ang", "MyId", "model")

function MakeWireMotor( pl, Ent1, Ent2, Bone1, Bone2, LPos1, LPos2, friction, torque, nocollide, forcelimit, MyCrtl )
	if not constraint.CanConstrain( Ent1, Bone1 ) then return false end
	if not constraint.CanConstrain( Ent2, Bone2 ) then return false end

	local Phys1 = Ent1:GetPhysicsObjectNum( Bone1 )
	local Phys2 = Ent2:GetPhysicsObjectNum( Bone2 )
	local WPos1 = Phys1:LocalToWorld( LPos1 )
	local WPos2 = Phys2:LocalToWorld( LPos2 )

	if Phys1 == Phys2 then return false end

	local const, axis = constraint.Motor( Ent1, Ent2, Bone1, Bone2, LPos1, LPos2, friction, torque, 0, nocollide, 0, pl, forcelimit )

	if not const then return nil, axis end

	local ctable = {
		Type 		= "WireMotor",
		pl			= pl,
		Ent1		= Ent1,
		Ent2		= Ent2,
		Bone1		= Bone1,
		Bone2		= Bone2,
		LPos1		= LPos1,
		LPos2		= LPos2,
		friction	= friction,
		torque  	= torque,
		nocollide	= nocollide,
		forcelimit  = forcelimit
	}
	const:SetTable( ctable )

	if MyCrtl then
		local controller = WireMotorTracking[ MyCrtl ]

		const.MyCrtl = controller:EntIndex()
		controller.MyId = controller:EntIndex()

		controller:SetConstraint( const )
		controller:DeleteOnRemove( const )
		if axis then
			controller:SetAxis( axis )
			controller:DeleteOnRemove( axis )
		end

		Ent1:DeleteOnRemove( controller )
		Ent2:DeleteOnRemove( controller )
		const:DeleteOnRemove( controller )
	end

	return const, axis
end
duplicator.RegisterConstraint( "WireMotor", MakeWireMotor, "pl", "Ent1", "Ent2", "Bone1", "Bone2", "LPos1", "LPos2", "friction", "torque", "nocollide", "forcelimit", "MyCrtl" )
