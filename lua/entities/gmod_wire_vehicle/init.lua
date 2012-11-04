AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "Vehicle Controller"

-- Number of Vehicles (Used for creating an uniqe name)
-- wire_Vehicle_count = 0

function ENT:Initialize()
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )
	-- Create outputs
	self.Inputs = Wire_CreateInputs( self, { "Throttle", "Steering", "Handbrake", "Engine", "Lock" } )
	self.Steering = 0
end

-- Link to Vehicle
function ENT:Setup( Vehicle )
	self.Vehicle = Vehicle
end

-- Inputs
function ENT:TriggerInput(iname, value)
	-- ake sure we have a valid vehicle
	if not IsValid(self.Vehicle) then return end

	if (iname == "Throttle") then
		self.Vehicle:Fire("throttle", tostring(value), 0)
	elseif (iname == "Steering") then
		self.Steering = value
		self.Vehicle:Fire("steer", tostring(self.Steering), 0)
	elseif (iname == "Handbrake") then
		if value > 0 then
			self.Vehicle:Fire("handbrakeon", 1, 0)
			self.Vehicle:Fire("handbrakeon", 0, 0.1)
		else
			self.Vehicle:Fire("handbrakeoff", 1, 0)
			self.Vehicle:Fire("handbrakeoff", 0, 0.1)
		end
	elseif (iname == "Engine") then
		if value > 0 then
			self.Vehicle:Fire("turnon", 1, 0)
			self.Vehicle:Fire("turnon", 0, 0.1)
		else
			self.Vehicle:Fire("turnoff", 1, 0)
			self.Vehicle:Fire("turnoff", 0, 0.1)
		end
	elseif (iname == "Lock") then
		if value > 0 then
			self.Vehicle:Fire("lock", 1, 0)
			self.Vehicle:Fire("lock", 0, 0.1)
		else
			self.Vehicle:Fire("unlock", 1, 0)
			self.Vehicle:Fire("unlock", 0, 0.1)
		end
	end
end

function ENT:OnRestore()
    self.BaseClass.OnRestore(self)
end

function ENT:Think()
	if not IsValid(self.Vehicle) then return end
	self.Vehicle:Fire("steer", tostring(self.Steering), 0)
	self:NextThink(CurTime())
end


//Duplicator support to save Vehicle link (TAD2020)
function ENT:BuildDupeInfo()
	local info = self.BaseClass.BuildDupeInfo(self) or {}

	if (self.Vehicle) and (self.Vehicle:IsValid()) then
	    info.Vehicle = self.Vehicle:EntIndex()
	end

	return info
end

function ENT:ApplyDupeInfo(ply, ent, info, GetEntByID)
	self.BaseClass.ApplyDupeInfo(self, ply, ent, info, GetEntByID)

	if (info.Vehicle) then
		self.Vehicle = GetEntByID(info.Vehicle)
		if (!self.Vehicle) then
			self.Vehicle = ents.GetByIndex(info.Vehicle)
		end
	end
end
