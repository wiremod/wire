AddCSLuaFile()
DEFINE_BASECLASS( "base_wire_entity" )
ENT.PrintName       = "Wire Vehicle Controller"
ENT.WireDebugName = "Vehicle Controller"

if CLIENT then return end -- No more client

function ENT:Initialize()
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )

	self.Inputs = Wire_CreateInputs( self, { "Throttle", "Steering", "Handbrake", "Engine", "Lock" } )
end

function ENT:LinkEnt( pod )
	if not IsValid(pod) or not pod:IsVehicle() then return false, "Must link to a vehicle" end
	self.Vehicle = pod
	WireLib.SendMarks(self, {pod})
	return true
end
function ENT:UnlinkEnt()
	self.Vehicle = nil
	WireLib.SendMarks(self, {})
	return true
end

function ENT:TriggerInput(iname, value)
	if not IsValid(self.Vehicle) then return end
	if (iname == "Throttle") then
		self.Throttle = value
	elseif (iname == "Steering") then
		self.Steering = value
	elseif (iname == "Handbrake") then
		self.Vehicle:Fire("handbrake"..(value~=0 and "on" or "off"), 1, 0)
	elseif (iname == "Engine") then
		self.Vehicle:Fire("turn"..(value~=0 and "on" or "off"), 1, 0)
		if value~=0 then self.Vehicle:Fire("handbrakeoff", 1, 0) end
	elseif (iname == "Lock") then
		self.Vehicle:Fire((value~=0 and "" or "un").."lock", 1, 0)
	end
end

function ENT:Think()
	if IsValid(self.Vehicle) then
		local delta = CurTime()%1/1000 -- A miniscule constant change
		if self.Steering then self.Vehicle:Fire("steer",   self.Steering+delta, 0) end
		if self.Throttle then self.Vehicle:Fire("throttle",self.Throttle+delta, 0) end
	end
	self:NextThink(CurTime())
	return true
end

function ENT:BuildDupeInfo()
	local info = self.BaseClass.BuildDupeInfo(self) or {}

	if (self.Vehicle) and (self.Vehicle:IsValid()) then
	    info.Vehicle = self.Vehicle:EntIndex()
	end

	return info
end

function ENT:ApplyDupeInfo(ply, ent, info, GetEntByID)
	self.BaseClass.ApplyDupeInfo(self, ply, ent, info, GetEntByID)

	self.Vehicle = GetEntByID(info.Vehicle)
end

duplicator.RegisterEntityClass("gmod_wire_vehicle", WireLib.MakeWireEnt, "Data")
