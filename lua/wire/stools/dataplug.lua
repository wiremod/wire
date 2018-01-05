WireToolSetup.setCategory( "Advanced" )
WireToolSetup.open( "dataplug", "Data - Plug/Socket", "gmod_wire_datasocket", nil, "Plugs and Sockets" )

if ( CLIENT ) then
	language.Add( "Tool.wire_dataplug.name", "Data Plug Tool (Wire)" )
	language.Add( "Tool.wire_dataplug.desc", "Spawns plugs and sockets for use with the hi-speed wire system." )
	language.Add( "sboxlimit_wire_dataplugs", "You've hit plugs limit!" )
	language.Add( "sboxlimit_wire_datasockets", "You've hit sockets limit!" )
	language.Add( "undone_wiredataplug", "Undone Wire Data Plug" )
	language.Add( "undone_wiredatasocket", "Undone Wire Data Socket" )

	language.Add( "Tool_wire_dataplug_weldforce", "Data plug weld force:" )
	language.Add( "Tool_wire_dataplug_attachrange", "Data plug attachment detection range:" )
	TOOL.Information = {
		{ name = "left", text = "Create/Update " .. TOOL.Name },
		{ name = "right", text = "Create/Update Plug" },
	}
end

WireToolSetup.BaseLang()



if (SERVER) then
	CreateConVar('sbox_maxwire_dataplugs', 20)
	CreateConVar('sbox_maxwire_datasockets', 20)
end

TOOL.ClientConVar["model"] = "models/hammy/pci_slot.mdl"
TOOL.ClientConVar["weldforce"] = 5000
TOOL.ClientConVar["attachrange"] = 5

local SocketModels = {
	["models/props_lab/tpplugholder_single.mdl"] = "models/props_lab/tpplug.mdl",
	["models/bull/various/usb_socket.mdl"] = "models/bull/various/usb_stick.mdl",
	["models/hammy/pci_slot.mdl"] = "models/hammy/pci_card.mdl",
	["models/wingf0x/isasocket.mdl"] = "models/wingf0x/isaplug.mdl",
	["models/wingf0x/altisasocket.mdl"] = "models/wingf0x/isaplug.mdl",
	["models/wingf0x/ethernetsocket.mdl"] = "models/wingf0x/ethernetplug.mdl",
	["models/wingf0x/hdmisocket.mdl"] = "models/wingf0x/hdmiplug.mdl"
}

local AngleOffset = {
	["models/props_lab/tpplugholder_single.mdl"] = Angle(0,0,0),
	["models/props_lab/tpplug.mdl"] = Angle(0,0,0),
	["models/bull/various/usb_socket.mdl"] = Angle(0,0,0),
	["models/bull/various/usb_stick.mdl"] = Angle(0,0,0),
	["models/hammy/pci_slot.mdl"] = Angle(90,0,0),
	["models/hammy/pci_card.mdl"] = Angle(90,0,0),
	["models/wingf0x/isasocket.mdl"] = Angle(90,0,0),
	["models/wingf0x/isaplug.mdl"] = Angle(90,0,0),
	["models/wingf0x/altisasocket.mdl"] = Angle(90,00,0),
	["models/wingf0x/ethernetsocket.mdl"] = Angle(90,0,0),
	["models/wingf0x/ethernetplug.mdl"] = Angle(90,0,0),
	["models/wingf0x/hdmisocket.mdl"] = Angle(90,0,0),
	["models/wingf0x/hdmiplug.mdl"] = Angle(90,0,0)
}

cleanup.Register( "wire_dataplugs" )

function TOOL:GetModel()
	local model = self:GetClientInfo( "model" )
	if not (util.IsValidModel( model ) and util.IsValidProp( model ) and SocketModels[ model ]) then
		return "models/props_lab/tpplugholder_single.mdl", "models/props_lab/tpplug.mdl"
	end
	return model, SocketModels[ model ]
end

if (SERVER) then
	function TOOL:GetConVars()
		return self:GetClientNumber("weldforce"), math.Clamp(self:GetClientNumber("attachrange"), 1, 100)
	end
end

// Create socket
function TOOL:LeftClick( trace )
	if (not trace.HitPos) then return false end
	if (trace.Entity:IsPlayer()) then return false end
	if ( trace.Entity:IsValid() and trace.Entity:GetClass() == "gmod_wire_dataplug") then
		return false
	end
	if ( CLIENT ) then return true end
	if not util.IsValidPhysicsObject( trace.Entity, trace.PhysicsBone ) then return false end

	local ply = self:GetOwner()

	local weldforce = self:GetClientNumber("weldforce")
	local attachrange = self:GetClientNumber("attachrange")
	if ( trace.Entity:IsValid() and trace.Entity:GetClass() == "gmod_wire_datasocket" ) then
		trace.Entity.ReceivedValue = 0
		trace.Entity:Setup(weldforce,attachrange)
		return true
	end

	if ( not self:GetSWEP():CheckLimit( "wire_datasockets" ) ) then return false end

	local socketmodel, plugmodel = self:GetModel()

	local wire_datasocket = WireLib.MakeWireEnt(ply, {Class = "gmod_wire_datasocket", Pos=trace.HitPos, Angle=trace.HitNormal:Angle() + (AngleOffset[plugmodel] or Angle()), Model=socketmodel})
	if not wire_datasocket then return end
	wire_datasocket:Setup(weldforce,attachrange)

	local const = nil
	if IsValid(trace.Entity) and IsValid(trace.Entity:GetPhysicsObject()) then
		const = WireLib.Weld(wire_datasocket, trace.Entity, trace.PhysicsBone, true, false, true)
	end
	undo.Create("WireSocket")
		undo.AddEntity( wire_datasocket )
		if IsValid(const) then
			undo.AddEntity( const )
		end
		undo.SetPlayer( ply )
	undo.Finish()

	ply:AddCleanup( "wire_datasockets", wire_datasocket )
	if IsValid(const) then
		ply:AddCleanup( "wire_datasockets", const )
	end
	return true
end

// Create plug
function TOOL:RightClick( trace )
	if (not trace.HitPos) then return false end
	if (trace.Entity:IsPlayer()) then return false end
	if ( CLIENT ) then return true end
	if not util.IsValidPhysicsObject( trace.Entity, trace.PhysicsBone ) then return false end

	local ply = self:GetOwner()

	if ( trace.Entity:IsValid() and trace.Entity:GetClass() == "gmod_wire_dataplug" ) then
		return true
	end

	if (not self:GetSWEP():CheckLimit( "wire_dataplugs" ) ) then return false end

	local socketmodel, plugmodel = self:GetModel()

	local wire_dataplug = WireLib.MakeWireEnt(ply, {Class = "gmod_wire_dataplug", Pos=trace.HitPos, Angle=trace.HitNormal:Angle() + (AngleOffset[plugmodel] or Angle()), Model=plugmodel})
	if not wire_dataplug then return end

	local min = wire_dataplug:OBBMins()
	wire_dataplug:SetPos( trace.HitPos - trace.HitNormal * min.z )

	undo.Create("WirePlug")
		undo.AddEntity( wire_dataplug )
		undo.SetPlayer( ply )
	undo.Finish()

	ply:AddCleanup( "wire_dataplugs", wire_dataplug )

	return true
end

function TOOL:GetGhostAngle(trace)
	local socketmodel = self:GetModel()
	return trace.HitNormal:Angle() + (AngleOffset[socketmodel] or Angle(0,0,0)) - Angle(90,0,0)
end

function TOOL.BuildCPanel(panel)
	WireToolHelpers.MakePresetControl(panel, "wire_dataplug")
	ModelPlug_AddToCPanel(panel, "Socket", "wire_dataplug")
	panel:NumSlider("#Tool_wire_dataplug_weldforce", "wire_dataplug_weldforce", 0, 100000)
	panel:NumSlider("#Tool_wire_dataplug_attachrange", "wire_dataplug_attachrange", 1, 100)
end
