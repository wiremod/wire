WireToolSetup.setCategory( "Advanced" )
WireToolSetup.open( "dataplug", "Data - Plug/Socket", "gmod_wire_datasocket", nil, "Plugs and Sockets" )

if ( CLIENT ) then
	language.Add( "Tool.wire_dataplug.name", "Data Plug Tool (Wire)" )
	language.Add( "Tool.wire_dataplug.desc", "Spawns plugs and sockets for use with the hi-speed wire system." )
	language.Add( "sboxlimit_wire_dataplugs", "You've hit plugs limit!" )
	language.Add( "sboxlimit_wire_datasockets", "You've hit sockets limit!" )
	language.Add( "undone_wiredataplug", "Undone Wire Data Plug" )
	language.Add( "undone_wiredatasocket", "Undone Wire Data Socket" )
	language.Add( "Tool_wire_dataplug_weldforce", "Plug weld force:" )
	language.Add( "Tool_wire_dataplug_attachrange", "Plug attachment detection range:" )
	TOOL.Information = {
		{ name = "left", text = "Create/Update " .. TOOL.Name },
		{ name = "right", text = "Create/Update Plug" },
	}
end

WireToolSetup.BaseLang()

if (SERVER) then
	CreateConVar("sbox_maxwire_dataplugs", 20)
	CreateConVar("sbox_maxwire_datasockets", 20)
end

TOOL.ClientConVar["model"] = "models/hammy/pci_slot.mdl"
TOOL.ClientConVar["weldforce"] = 5000
TOOL.ClientConVar["attachrange"] = 5

function TOOL:GetConVars()
	return self:GetClientNumber("weldforce"), math.Clamp(self:GetClientNumber("attachrange"), 1, 100)
end

local SocketData = list.Get("Wire_Socket_Models")

cleanup.Register( "wire_dataplugs" )

function TOOL:GetModel()
	local model = self:GetClientInfo( "model" )
	if (not util.IsValidModel( model ) or not util.IsValidProp( model ) or not SocketData[ model ]) then return "models/props_lab/tpplugholder_single.mdl", "models/props_lab/tpplug.mdl" end
	return model, SocketData[ model ].plug
end

-- Create socket
-- Handled by WireToolObj

-- Create plug
function TOOL:RightClick( trace )
	if (not trace) then return false end
	if (trace.Entity) then
		if (trace.Entity:IsPlayer()) then return false end
		if (trace.Entity:GetClass() == "gmod_wire_dataplug") then
			if (CLIENT) then return true end
			trace.Entity:Setup()
			return true
		end
	end
	if (CLIENT) then return true end
	if not util.IsValidPhysicsObject( trace.Entity, trace.PhysicsBone ) then return false end

	local ply = self:GetOwner()
	local _, plugmodel = self:GetModel()

	local plug = WireLib.MakeWireEnt(ply, {Class = "gmod_wire_dataplug", Pos=trace.HitPos, Angle=self:GetAngle(trace), Model=plugmodel})
	if not IsValid(plug) then return false end

	plug:SetPos( trace.HitPos - trace.HitNormal * plug:OBBMins().x )

	undo.Create("wiredataplug")
		undo.AddEntity( plug )
		undo.SetPlayer( ply )
	undo.Finish()

	ply:AddCleanup( "wire_dataplugs", plug )

	return true
end

function TOOL:GetGhostAngle(trace)
	local socketmodel = self:GetModel()
	return trace.HitNormal:Angle() + (SocketData[socketmodel].ang or Angle(0,0,0)) - Angle(90,0,0)
end

function TOOL.BuildCPanel(panel)
	WireToolHelpers.MakePresetControl(panel, "wire_dataplug")
	ModelPlug_AddToCPanel(panel, "Socket", "wire_dataplug")
	panel:NumSlider("#Tool_wire_dataplug_weldforce", "wire_dataplug_weldforce", 0, 100000)
	panel:NumSlider("#Tool_wire_dataplug_attachrange", "wire_dataplug_attachrange", 1, 100)
end
