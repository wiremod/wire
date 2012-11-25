AddCSLuaFile()
DEFINE_BASECLASS( "base_wire_entity" )
ENT.PrintName		= "Wire Hydraulic Controller"
ENT.WireDebugName 	= "Hydraulic"
ENT.RenderGroup		= RENDERGROUP_BOTH

if CLIENT then return end -- No more client

function ENT:Initialize()
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )

	self.Inputs = WireLib.CreateInputs( self, { "Length", "Constant", "Damping" } )
	self.Outputs = WireLib.CreateOutputs( self, { "Length", "Constant", "Damping" } )

	self.Trigger = 0
	if self.constraint then
		WireLib.TriggerOutput( self, "Constant", self.constraint:GetKeyValues().constant )
		WireLib.TriggerOutput( self, "Damping", self.constraint:GetKeyValues().damping )
	end
end


function ENT:Setup()
	self.current_length = 0
	self.IsOn = true
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


function ENT:Think()
	self.BaseClass.Think( self )

	local c = self.constraint
	if !IsValid( c ) then return end

	local CTable = c:GetTable()
	local p1 = self:GetWPos( CTable.Ent1, CTable.Phys1 or CTable.Ent1:GetPhysicsObject(), CTable.LPos1 )
	local p2 = self:GetWPos( CTable.Ent2, CTable.Phys2 or CTable.Ent2:GetPhysicsObject(), CTable.LPos2 )

	self.current_length = p1:Distance(p2)

	self:UpdateOutputs( true )

	self:NextThink(CurTime()+0.04)
end

local function updateOutput( a, what )
	if (a and a:IsValid()) then
		WireLib.TriggerOutput( a.Entity, what, a.constraint:GetKeyValues()[what:lower()] )
	end
end

function ENT:UpdateOutputs( OnlyLength )
	if (OnlyLength) then
		WireLib.TriggerOutput( self, "Length", self.current_length )
		self:SetOverlayText( "Hydraulic length: " .. self.current_length .. "\nConstant: " .. (self.current_constant or "-") .. "\nDamping: " .. (self.current_damping or "-") )
	else
		WireLib.TriggerOutput( self, "Length", self.current_length )
		WireLib.TriggerOutput( self, "Constant", self.current_constant )
		WireLib.TriggerOutput( self, "Damping", self.current_damping )
		self:SetOverlayText( "Hydraulic length: " .. self.current_length .. "\nConstant: " .. (self.current_constant or "-") .. "\nDamping: " .. (self.current_damping or "-") )
	end
end


function ENT:SetConstraint( c )
	self.constraint = c

	local CTable = c:GetTable()
	local p1 = self:GetWPos( CTable.Ent1, CTable.Phys1 or CTable.Ent1:GetPhysicsObject(), CTable.LPos1 )
	local p2 = self:GetWPos( CTable.Ent2, CTable.Phys2 or CTable.Ent2:GetPhysicsObject(), CTable.LPos2 )

	self.current_length = p1:Distance(p2)

	if (self.current_constant != nil or (self.Inputs and self.Inputs.Constant.Src != nil)) then
		self.constraint:Fire( "SetSpringConstant", self.current_constant or self.Inputs.Constant.Value, 0 )
		if (!self.current_constant) then self.current_constant = self.Inputs.Constant.Value end
	else
		self.current_constant = self.constraint:GetKeyValues().constant
	end

	if (self.current_damping != nil or (self.Inputs and self.Inputs.Damping.Src != nil)) then
		self.constraint:Fire( "SetSpringDamping", self.current_damping or self.Inputs.Damping.Value, 0 )
		if (!self.current_damping) then self.current_damping = self.Inputs.Damping.Value end
	else
		self.current_damping = self.constraint:GetKeyValues().damping
	end

	self.constraint:Fire( "SetSpringLength", self.current_length, 0 )
	if self.rope then self.rope:Fire( "SetLength", self.current_length, 0 ) end

	self:UpdateOutputs()
end


function ENT:SetRope( r )
	self.rope = r
end

function ENT:TriggerInput(iname, value)
	if !IsValid( self.constraint ) then return end
	if (iname == "Length") then
		self.current_length = math.max(value,1)
		self.constraint:Fire("SetSpringLength", self.current_length)
		if self.rope then self.rope:Fire("SetLength", self.current_length, 0) end

	elseif (iname == "Constant") then
		self.current_constant = math.max(value,1)
		self.constraint:Fire("SetSpringConstant",self.current_constant)
		timer.Simple( 0.1, function() if IsValid(self) then self:UpdateOutputs() end end) -- Needs to be delayed because ent:Fire doesn't update that fast.

	elseif (iname == "Damping") then
		self.current_damping = math.max(value,1)
		self.constraint:Fire("SetSpringDamping",self.current_damping)
		timer.Simple( 0.1, function() if IsValid(self) then self:UpdateOutputs() end end)
	end

	self:SetOverlayText( "Hydraulic Length : " .. self.current_length .. "\nConstant: " .. (self.current_constant or "-") .. "\nDamping: " .. (self.current_damping or "-") )
end


// Duplication is handled in the toolgun

