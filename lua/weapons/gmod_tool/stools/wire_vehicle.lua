TOOL.Category = "Wire - I/O"
TOOL.Name = "Vehicle Controller"
TOOL.Command = nil -- What is this for?
TOOL.ConfigName = ""
TOOL.Tab			= "Wire"

if CLIENT then
	language.Add("Tool_wire_vehicle_name", "Vehicle Controller Tool (Wire)")
	language.Add("Tool_wire_vehicle_desc", "Spawn/link a Wire Vehicle controller.")
	language.Add("Tool_wire_vehicle_0", "Primary: Create Vehicle controller. Secondary: Link controller.")
	language.Add("Tool_wire_vehicle_1", "Now select the Vehicle to link to.")
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

	if trace.Entity:IsValid() and trace.Entity:GetClass() == "gmod_wire_vehicle" and trace.Entity.pl == ply then
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

function TOOL:UpdateGhostWireVehicle(ent, player)
	if  not ent or not ent:IsValid() then return end

	local trace = player:GetEyeTrace()

	if not trace.Hit or trace.Entity:IsPlayer() or trace.Entity:GetClass() == "gmod_wire_vehicle" then
		ent:SetNoDraw(true)
		return
	end

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90

	ent:SetPos(trace.HitPos - trace.HitNormal * ent:OBBMins().z)
	ent:SetAngles(Ang)

	ent:SetNoDraw(false)
end

function TOOL:Think()
	local model = self:GetModel()

	if (!self.GhostEntity || !self.GhostEntity:IsValid() || self.GhostEntity:GetModel() != model ) then
		self:MakeGhostEntity( Model(model), Vector(0,0,0), Angle(0,0,0) )
	end

	self:UpdateGhostWireVehicle(self.GhostEntity, self:GetOwner())
end

function TOOL:GetModel()
	local model = "models/jaanus/wiretool/wiretool_siren.mdl"
	local modelcheck = self:GetClientInfo( "model" )

	if (util.IsValidModel(modelcheck) and util.IsValidProp(modelcheck)) then
		model = modelcheck
	end

	return model
end

function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool_wire_vehicle_name", Description = "#Tool_wire_vehicle_desc" })
	WireDermaExts.ModelSelect(panel, "wire_vehicle_model", list.Get( "Wire_Misc_Tools_Models" ), 1)
end
