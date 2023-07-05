AddCSLuaFile()
DEFINE_BASECLASS( "base_wire_entity" )
ENT.PrintName       = "Wire Vehicle Controller"
ENT.WireDebugName = "Vehicle Controller"

if CLIENT then return end -- No more client

function ENT:Initialize()
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )

	self.Inputs = Wire_CreateInputs( self, { "Throttle", "Steering", "Handbrake", "Engine", "Lock", "Vehicle [ENTITY]" } )
	self.Outputs = Wire_CreateOutputs( self, { "Vehicle [ENTITY]" } )
end

function ENT:LinkEnt( pod )
	pod = WireLib.GetClosestRealVehicle(pod,self:GetPos(),self:GetPlayer())

	if not IsValid(pod) or not pod:IsVehicle() then return false, "Must link to a vehicle" end
	if not WireLib.CanTool(self:GetPlayer(), pod, "wire_vehicle") then return false, "You do not have permission to access this vehicle" end

	self.Vehicle = pod
	WireLib.SendMarks(self, {pod})
	WireLib.TriggerOutput(self, "Vehicle", pod)
	return true
end
function ENT:UnlinkEnt()
	self.Vehicle = nil
	WireLib.SendMarks(self, {})
	WireLib.TriggerOutput(self, "Vehicle", NULL)
	return true
end

function ENT:TriggerInput(iname, value)
	if (iname == "Throttle") then
		self.Throttle = value
	elseif (iname == "Steering") then
		self.Steering = value
	elseif (iname == "Vehicle") then
		self:LinkEnt(value)
	elseif not IsValid(self.Vehicle) then
		return
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
	local info = BaseClass.BuildDupeInfo(self) or {}

	if self.Vehicle and self.Vehicle:IsValid() then
	    info.Vehicle = self.Vehicle:EntIndex()
	end

	return info
end

function ENT:ApplyDupeInfo(ply, ent, info, GetEntByID)
	BaseClass.ApplyDupeInfo(self, ply, ent, info, GetEntByID)

	self.Vehicle = GetEntByID(info.Vehicle)
end

duplicator.RegisterEntityClass("gmod_wire_vehicle", WireLib.MakeWireEnt, "Data")
