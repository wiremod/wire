AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "Vehicle Controller"

local MODEL = Model("models/jaanus/wiretool/wiretool_siren.mdl")

-- Number of Vehicles (Used for creating an uniqe name)
-- wire_Vehicle_count = 0

function ENT:Initialize()
	self.Entity:SetModel( MODEL )
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )
	-- Create outputs
	self.Inputs = Wire_CreateOutputs( self.Entity, { "Throttle", "Steering", "Handbrake", "Engine", "Lock" } )
	self:SetOverlayText( "Vehicle Controller" )
end

-- Link to Vehicle
function ENT:Setup( Vehicle )
	self.Vehicle = Vehicle
end

-- Inputs
function ENT:TriggerInput(iname, value)
	-- Check  that we have a vehicle and that the vehicle is valid
	if not (self.Vehicle and self.Vehicle:IsValid()) then return end

	if (iname == "Throttle") then
		self.Vehicle:Fire("throttle", tostring(value), 0)
	elseif (iname == "Steering") then
		self.Vehicle:Fire("steer", tostring(value), 0)
	elseif (iname == "Handbrake") then
		if value > 0 then self.Vehicle:Fire("handbrakeon", 1, 0)
		else self.Vehicle:Fire("handbrakeoff", 1, 0) end
	elseif (iname == "Engine") then
		if value > 0 then self.Vehicle:Fire("turnon", 1, 0)
		else self.Vehicle:Fire("turnoff", 1, 0) end
	elseif (iname == "Lock") then
		if value > 0 then self.Vehicle:Fire("lock", 1, 0)
		else self.Vehicle:Fire("unlock", 1, 0) end
	end
end

function ENT:ShowOutput(value)
	if (value ~= self.PrevOutput) then
		self:SetOverlayText( "Vehicle Controller" )
		self.PrevOutput = value
	end
end

function ENT:OnRestore()
    self.BaseClass.OnRestore(self)
end

function ENT:Think()

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
