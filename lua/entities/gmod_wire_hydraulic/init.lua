AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

ENT.WireDebugName = "Hydraulic"

include('shared.lua')

function ENT:Initialize()
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )

	self.Inputs = Wire_CreateInputs( self.Entity, { "Length", "Constant", "Damping" } )
	self.Outputs = Wire_CreateOutputs( self.Entity, { "Length", "Constant", "Damping" } )

	self.Trigger = 0
	if self.constraint then
		WireLib.TriggerOutput( self.Entity, "Constant", self.constraint:GetKeyValues().constant )
		WireLib.TriggerOutput( self.Entity, "Damping", self.constraint:GetKeyValues().damping )
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

	Wire_TriggerOutput( self.Entity, "Length", self.current_length)
	self.Entity:NextThink(CurTime()+0.04)
	self:SetOverlayText( "Hydraulic Length : " .. self.current_length .. "\nConstant: " .. (self.current_constant or "-") .. "\nDamping: " .. (self.current_damping or "-") )
end


function ENT:SetConstraint( c )
	self.constraint = c

	local CTable = c:GetTable()
	local p1 = self:GetWPos( CTable.Ent1, CTable.Phys1 or CTable.Ent1:GetPhysicsObject(), CTable.LPos1 )
	local p2 = self:GetWPos( CTable.Ent2, CTable.Phys2 or CTable.Ent2:GetPhysicsObject(), CTable.LPos2 )

	self.current_length = p1:Distance(p2)

	WireLib.TriggerOutput( self.Entity, "Constant", self.constraint:GetKeyValues().constant )
	WireLib.TriggerOutput( self.Entity, "Damping", self.constraint:GetKeyValues().damping )
	self.constraint:Fire( "SetSpringLength", self.current_length, 0 )
	if self.rope then self.rope:Fire( "SetLength", self.current_length, 0 ) end
	self:SetOverlayText( "Hydraulic length : " .. self.current_length .. "\nConstant: " .. (self.constraint:GetKeyValues().constant or "-") .. "\nDamping: " .. (self.constraint:GetKeyValues().damping or "-") )
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
		self.current_constant = math.max(value,1)--math.Clamp(value,1,50000)
		self.constraint:Fire("SetSpringConstant",self.current_constant)
		timer.Simple( 0.1, function(a) WireLib.TriggerOutput( a.Entity, "Constant", a.constraint:GetKeyValues().constant ) end, self ) -- Needs to be delayed because ent:Fire doesn't update that fast.

	elseif (iname == "Damping") then
		self.current_damping = math.max(value,1)--math.Clamp(value,1,10000)
		self.constraint:Fire("SetSpringDamping",self.current_damping)
		timer.Simple( 0.1, function(a) WireLib.TriggerOutput( a.Entity, "Damping", a.constraint:GetKeyValues().damping ) end, self )
	end

	self:SetOverlayText( "Hydraulic Length : " .. self.current_length .. "\nConstant: " .. (self.current_constant or "-") .. "\nDamping: " .. (self.current_damping or "-") )
end


// Duplication is handled in the toolgun

