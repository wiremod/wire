AddCSLuaFile()
DEFINE_BASECLASS( "base_wire_entity" )
ENT.PrintName		= "Wire Hydraulic Controller"
ENT.WireDebugName 	= "Hydraulic"

if CLIENT then return end -- No more client

function ENT:Initialize()
	self.BaseClass.Initialize(self)
	self.Inputs = WireLib.CreateInputs( self, { "Length", "In", "Out", "Constant", "Damping" } )
	self.Outputs = WireLib.CreateOutputs( self, { "Length", "Target Length", "Constant", "Damping" } )
	self.TargetLength = 0
	self.current_constant = 0
	self.current_damping = 0
	self.direction = 0
	self.last_time = CurTime()
end

function ENT:GetWPos( ent, phys, lpos )
	if ent:EntIndex() == 0 then
		return lpos
	end

	if IsValid( phys ) then
		return phys:LocalToWorld( lpos )
	else
		return ent:LocalToWorld( lpos )
	end
end

function ENT:GetDistance()
	local CTable = self.constraint:GetTable()
	local p1 = self:GetWPos( CTable.Ent1, CTable.Phys1 or CTable.Ent1:GetPhysicsObject(), CTable.LPos1 )
	local p2 = self:GetWPos( CTable.Ent2, CTable.Phys2 or CTable.Ent2:GetPhysicsObject(), CTable.LPos2 )
	return p1:Distance(p2)
end

function ENT:Think()
	self.BaseClass.Think( self )
	if not IsValid(self.constraint) then return end

	local deltaTime = CurTime() - self.last_time
	self.last_time = CurTime()
	
	if self.direction ~= 0 then
		self:SetLength(math.max(self.TargetLength + (self.constraint:GetTable().speed * self.direction * deltaTime), 1))
	end
	
	self:UpdateOutputs( true )
	self:NextThink(CurTime()+0.05)
	return true
end

function ENT:UpdateOutputs( OnlyLength )
	local curLength = self:GetDistance()
	WireLib.TriggerOutput( self, "Length", curLength )
	WireLib.TriggerOutput( self, "Target Length", self.TargetLength )
	if not OnlyLength then
		WireLib.TriggerOutput( self, "Length", self.TargetLength )
		WireLib.TriggerOutput( self, "Constant", self.current_constant )
		WireLib.TriggerOutput( self, "Damping", self.current_damping )
	end

	self:SetOverlayText(string.format("%s length: %.2f\nConstant: %i\nDamping: %i", (self.constraint.stretchonly and "Winch" or "Hydraulic"), curLength, self.current_constant, self.current_damping))
end

function ENT:SetConstraint( c )
	self.constraint = c

	if self.current_constant ~= 0 or (self.Inputs and self.Inputs.Constant.Src) then
		self:TriggerInput("Constant", self.Inputs.Constant.Value)
	else
		self.current_constant = self.constraint:GetKeyValues().constant
	end

	if self.current_damping ~= 0 or (self.Inputs and self.Inputs.Damping.Src) then
		self:TriggerInput("Damping", self.Inputs.Damping.Value)
	else
		self.current_damping = self.constraint:GetKeyValues().damping
	end

	self:SetLength(self:GetDistance())

	self:UpdateOutputs()
end

function ENT:SetRope( r )
	self.rope = r
end

function ENT:SetLength(value)
	self.TargetLength = value
	self.constraint:Fire("SetSpringLength", value, 0)
	if IsValid(self.rope) then self.rope:Fire("SetLength", value, 0) end
end

function ENT:TriggerInput(iname, value)
	if not IsValid(self.constraint) then return end
	if iname == "Length" then
		self:SetLength(math.max(value,1))
	elseif iname == "In" then
		self.direction = -value
	elseif iname == "Out" then
		self.direction = value
	elseif iname == "Constant" then
		if value == 0 then 
			self.current_constant, _ = WireLib.CalcElasticConsts(self.constraint.Ent1, self.constraint.Ent2)
		else
			self.current_constant = value
		end
		self.constraint:Fire("SetSpringConstant",self.current_constant)
		timer.Simple( 0.1, function() if IsValid(self) then self:UpdateOutputs() end end) -- Needs to be delayed because ent:Fire doesn't update that fast.
	elseif iname == "Damping" then
		if value == 0 then 
			_, self.current_damping = WireLib.CalcElasticConsts(self.constraint.Ent1, self.constraint.Ent2)
		else
			self.current_damping = value
		end
		self.constraint:Fire("SetSpringDamping",self.current_damping)
		timer.Simple( 0.1, function() if IsValid(self) then self:UpdateOutputs() end end)
	end
end


//need for the const to find the controler after being duplicator pasted
local WireHydraulicTracking = {}

function MakeWireHydraulicController( pl, Pos, Ang, model, MyEntId, const, rope )
	local controller = WireLib.MakeWireEnt(pl, {Class = "gmod_wire_hydraulic", Pos=Pos, Angle=Ang, Model=model})
	if not IsValid(controller) then return end

	if not const then
		WireHydraulicTracking[ MyEntId ] = controller
	else
		controller.MyId = controller:EntIndex()
		const.MyCrtl = controller:EntIndex()
		controller:SetConstraint( const )
		controller:DeleteOnRemove( const )
	end

	if rope then
		controller:SetRope( rope )
		controller:DeleteOnRemove( rope )
	end

	return controller
end
duplicator.RegisterEntityClass("gmod_wire_hydraulic", MakeWireHydraulicController, "Pos", "Ang", "Model", "MyId" )
duplicator.RegisterEntityClass("gmod_wire_winch_controller", MakeWireHydraulicController, "Pos", "Ang", "Model", "MyId")
scripted_ents.Alias("gmod_wire_winch_controller", "gmod_wire_hydraulic")

function MakeWireHydraulic( pl, Ent1, Ent2, Bone1, Bone2, LPos1, LPos2, width, material, speed, fixed, stretchonly, MyCrtl )
	if not constraint.CanConstrain(Ent1, Bone1) then return false end
	if not constraint.CanConstrain(Ent2, Bone2) then return false end

	local Phys1 = Ent1:GetPhysicsObjectNum( Bone1 )
	local Phys2 = Ent2:GetPhysicsObjectNum( Bone2)
	local WPos1 = Phys1:LocalToWorld( LPos1 )
	local WPos2 = Phys2:LocalToWorld( LPos2 )

	if Phys1 == Phys2 then return false end

	local constant, dampen = WireLib.CalcElasticConsts(Ent1, Ent2)

	local const, rope = constraint.Elastic( Ent1, Ent2, Bone1, Bone2, LPos1, LPos2, constant, dampen, 0, material, width, stretchonly )
	if not const then return nil, rope end

	if fixed == 1 then
		local slider = constraint.Slider( Ent1, Ent2, Bone1, Bone2, LPos1, LPos2, 0 )
		slider:SetTable( {} )
		const:DeleteOnRemove( slider )
	end

	local ctable = {
		Type     = "WireHydraulic",
		pl       = pl,
		Ent1     = Ent1,
		Ent2     = Ent2,
		Bone1    = Bone1,
		Bone2    = Bone2,
		LPos1    = LPos1,
		LPos2    = LPos2,
		width    = width,
		material = material,
		speed    = speed,
		fixed    = fixed,
		stretchonly = stretchonly
	}
	const:SetTable( ctable )

	if MyCrtl then
		local controller = WireHydraulicTracking[ MyCrtl ]

		const.MyCrtl = controller:EntIndex()
		controller.MyId = controller:EntIndex()

		controller:SetConstraint( const )
		controller:DeleteOnRemove( const )
		if rope then
			controller:SetRope( rope )
			controller:DeleteOnRemove( rope )
		end

		Ent1:DeleteOnRemove( controller )
		Ent2:DeleteOnRemove( controller )
		const:DeleteOnRemove( controller )
	end

	return const, rope
end
duplicator.RegisterConstraint("WireHydraulic", MakeWireHydraulic, "pl", "Ent1", "Ent2", "Bone1", "Bone2", "LPos1", "LPos2", "width", "material", "speed", "fixed", "stretchonly", "MyCrtl")

-- Backwards compatibility with old dupes of Winches, which were just Hydraulics with strechonly = true
local function WinchToHydraulic(pl, Ent1, Ent2, Bone1, Bone2, LPos1, LPos2, width, fwd_speed, bwd_speed, material, MyCrtl)
	return MakeWireHydraulic(pl, Ent1, Ent2, Bone1, Bone2, LPos1, LPos2, width, material, fwd_speed, 0, true, MyCrtl)
end
duplicator.RegisterConstraint("WireWinch", WinchToHydraulic, "pl", "Ent1", "Ent2", "Bone1", "Bone2", "LPos1", "LPos2", "width", "fwd_speed", "bwd_speed", "material", "MyCrtl")
