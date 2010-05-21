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
	if (self.constraint) then
		WireLib.TriggerOutput( self.Entity, "Constant", self.constraint:GetKeyValues().constant )
		WireLib.TriggerOutput( self.Entity, "Damping", self.constraint:GetKeyValues().damping )
	end
end

function ENT:Think()
	local c = self.constraint
	if(not (c and c:IsValid())) then return end;
	local p1 = self:GetWPos(c:GetTable().Ent1, c:GetTable().Phys1, c:GetTable().LPos1)
	local p2 = self:GetWPos(c:GetTable().Ent2, c:GetTable().Phys2, c:GetTable().LPos2)

	Wire_TriggerOutput(self.Entity, "Length", (p1 - p2):Length())
	self.Entity:NextThink(CurTime()+0.04)
end

function ENT:Setup()
	self.current_length = 0
	self.IsOn = true
end


function ENT:GetWPos( ent, phys, lpos )
	if (ent:EntIndex() == 0) then
		return lpos
	end

	if (phys) and (phys:IsValid()) then
		return phys:LocalToWorld( lpos )
	else
		return ent:LocalToWorld( lpos )
	end
end


function ENT:SetConstraint( c )
	self.constraint = c

	local p1 = self:GetWPos(c:GetTable().Ent1, c:GetTable().Phys1, c:GetTable().LPos1)
	local p2 = self:GetWPos(c:GetTable().Ent2, c:GetTable().Phys2, c:GetTable().LPos2)
	local dist = (p1 - p2)

	self:SetOverlayText( "Hydraulic length : " .. self.current_length .. "\nConstant: -\nDamping: -" )
	WireLib.TriggerOutput( self.Entity, "Constant", self.constraint:GetKeyValues().constant )
	WireLib.TriggerOutput( self.Entity, "Damping", self.constraint:GetKeyValues().damping )
	self.constraint:Fire("SetSpringLength", self.current_length, 0)
	if self.rope then self.rope:Fire("SetLength", self.current_length, 0) end
end


function ENT:SetRope( r )
	self.rope = r
end


function ENT:TriggerInput(iname, value)
	if (!self.constraint) then return end
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

--[[
function ENT:ShowOutput()

end
]]

/*function ENT:BuildDupeInfo()
	local info = self.BaseClass.BuildDupeInfo(self) or {}

	if (self.constraint) and (self.constraint:IsValid()) then
		info.constraint = self.constraint:EntIndex()
	end
	if (self.rope) and (self.rope:IsValid()) then
		info.rope = self.rope:EntIndex()
	end

	return info
end*/


function ENT:ApplyDupeInfo(ply, ent, info, GetEntByID, GetConstByID)
	self.BaseClass.ApplyDupeInfo(self, ply, ent, info, GetEntByID, GetConstByID)

	if (GetConstByID) then
		if (info.constraint) and (info.constraint > 0) then
			local const = GetConstByID(info.constraint)
			if (const) then
				self:SetConstraint(const)
			end
		end

		if (info.rope) and (info.rope > 0) then
			local rope = GetConstByTable(info.rope)
			if (rope) then
				self:SetConstraint(rope)
			end
		end
	end
end

