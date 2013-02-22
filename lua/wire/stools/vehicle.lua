WireToolSetup.setCategory( "I/O" )
WireToolSetup.open( "vehicle", "Vehicle Controller", "gmod_wire_vehicle", nil, "Vehicle Controllers" )

if CLIENT then
	language.Add("Tool.wire_vehicle.name", "Vehicle Controller Tool (Wire)")
	language.Add("Tool.wire_vehicle.desc", "Spawn/link a Wire Vehicle controller.")
	language.Add("Tool.wire_vehicle.0", "Primary: Create Vehicle controller. Secondary: Link controller.")
	language.Add("Tool.wire_vehicle.1", "Now select the Vehicle to link to.")
	language.Add("WireVehicleTool_Vehicle", "Vehicle:")
	language.Add("sboxlimit_wire_vehicles", "You've hit your Vehicle Controller limit!")
	language.Add("Undone_Wire Vehicle", "Undone Wire Vehicle Controller")
end

if SERVER then
	CreateConVar('sbox_maxwire_vehicles', 20)
end

TOOL.ClientConVar[ "model" ] = "models/jaanus/wiretool/wiretool_siren.mdl"

cleanup.Register("wire_vehicles")

function TOOL:LeftClick(trace)
	if not trace.HitPos then return false end
	if trace.Entity:IsPlayer() then return false end
	if CLIENT then return true end
	if not util.IsValidPhysicsObject( trace.Entity, trace.PhysicsBone ) then return false end

	local ply = self:GetOwner()

	if trace.Entity:IsValid() and trace.Entity:GetClass() == "gmod_wire_vehicle" then
		return true
	end

	if not self:GetSWEP():CheckLimit("wire_vehicles") then return false end

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90

	local wire_vehicle = MakeWireVehicle(ply, trace.HitPos, Ang, self:GetModel())

	wire_vehicle:SetPos(trace.HitPos - trace.HitNormal * wire_vehicle:OBBMins().z)

	local const = WireLib.Weld(wire_vehicle, trace.Entity, trace.PhysicsBone, true)

	undo.Create("Wire Vehicle")
		undo.AddEntity(wire_vehicle)
		undo.AddEntity(const)
		undo.SetPlayer(ply)
	undo.Finish()

	ply:AddCleanup("wire_vehicles", wire_vehicle)

	return true
end

function TOOL:RightClick(trace)
	if (self:GetStage() == 0) and trace.Entity:GetClass() == "gmod_wire_vehicle" then
		self.VehicleCont = trace.Entity
		self:SetStage(1)
		return true
	elseif self:GetStage() == 1 and trace.Entity.GetPassenger then
		self.VehicleCont:Setup(trace.Entity)
		self:SetStage(0)
		self.VehicleCont = nil
		return true
	else
		return false
	end
end

function TOOL:Reload(trace)
	self:SetStage(0)
	self.VehicleCont = nil
end

if SERVER then

	function MakeWireVehicle(pl, Pos, Ang, model)
		if not pl:CheckLimit("wire_vehicles") then return false end

		local wire_vehicle = ents.Create("gmod_wire_vehicle")
		if not wire_vehicle:IsValid() then return false end

		wire_vehicle:SetAngles(Ang)
		wire_vehicle:SetPos(Pos)
		wire_vehicle:SetModel(Model(model or "models/jaanus/wiretool/wiretool_siren.mdl"))
		wire_vehicle:Spawn()
		wire_vehicle:SetPlayer(pl)
		wire_vehicle.pl = pl

		pl:AddCount("wire_vehicles", wire_vehicle)

		return wire_vehicle
	end
	duplicator.RegisterEntityClass("gmod_wire_vehicle", MakeWireVehicle, "Pos", "Ang", "Model")
end

function TOOL.BuildCPanel(panel)
	WireDermaExts.ModelSelect(panel, "wire_vehicle_model", list.Get( "Wire_Misc_Tools_Models" ), 1)
end
