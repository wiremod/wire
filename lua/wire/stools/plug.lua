WireToolSetup.setCategory( "Input, Output/Data Transfer" )
WireToolSetup.open( "plug", "Plug", "gmod_wire_socket", nil, "Plugs" )

if SERVER then

	CreateConVar("sbox_maxwire_plugs",20)
	CreateConVar("sbox_maxwire_sockets",20)

	--resource.AddFile("models/bull/various/usb_socket.mdl")
	--resource.AddFile("materials/bull/various/usb_socket.vtf")

	--resource.AddFile("models/bull/various/usb_stick.mdl")
	--resource.AddFile("materials/bull/various/usb_stick.vtf")

else
	language.Add( "Tool.wire_plug.name", "Plug & Socket Tool (Wire)" )
	language.Add( "Tool.wire_plug.desc", "Spawns plugs and sockets for use with the wire system." )
	language.Add( "Tool.wire_plug.0", "Primary: Create/Update Socket, Secondary: Create/Update Plug" )
	language.Add( "sboxlimit_wire_plugs", "You've hit the Wire Plugs limit!" )
	language.Add( "sboxlimit_wire_sockets", "You've hit the Wire Sockets limit!" )
	language.Add( "undone_wireplug", "Undone Wire Plug" )
	language.Add( "undone_wiresocket", "Undone Wire Socket" )

	language.Add( "Tool_wire_plug_freeze", "Freeze the socket." )
	language.Add( "Tool_wire_plug_array", "Use array inputs/outputs instead." )
	language.Add( "Tool_wire_plug_weldforce", "Plug weld force:" )
	language.Add( "Tool_wire_plug_attachrange", "Plug attachment detection range:" )
	language.Add( "Tool_wire_plug_drawoutline", "Draw the white outline on plugs and sockets." )
	language.Add( "Tool_wire_plug_drawoutline_tooltip", "Disabling this helps you see inside the USB plug model when you set its material to wireframe." )
end

TOOL.ClientConVar["model"] = "models/props_lab/tpplugholder_single.mdl"
TOOL.ClientConVar["freeze"] = 1
TOOL.ClientConVar["array"] = 0
TOOL.ClientConVar["weldforce"] = 5000
TOOL.ClientConVar["attachrange"] = 5
TOOL.ClientConVar["drawoutline"] = 1

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

cleanup.Register( "wire_plugs" )

function TOOL:GetModel()
	local model = self:GetClientInfo( "model" )
	if not util.IsValidModel( model ) or not util.IsValidProp( model ) or not SocketModels[ model ] then return "models/props_lab/tpplugholder_single.mdl" end
	return model
end

function TOOL:GetAngle( trace )
	local Ang
	if math.abs(trace.HitNormal.x) < 0.001 and math.abs(trace.HitNormal.y) < 0.001 then 
		return Vector(0,0,trace.HitNormal.z):Angle() + (AngleOffset[self:GetModel()] or Angle(0,0,0))
	else
		return trace.HitNormal:Angle() + (AngleOffset[self:GetModel()] or Angle(0,0,0))
	end
end

if SERVER then
	function TOOL:GetConVars() 
		return self:GetClientNumber("array") ~= 0, self:GetClientNumber("weldforce"), math.Clamp(self:GetClientNumber("attachrange"), 1, 100)
	end
	
	-- Socket creation handled by WireToolObj
end

-- Create Plug
function TOOL:RightClick( trace )
	if not trace then return false end
	if trace.Entity then
		if trace.Entity:IsPlayer() then return false end
		if trace.Entity:GetClass() == "gmod_wire_plug" then
			if CLIENT then return true end
			trace.Entity:Setup( self:GetClientNumber( "array" ) ~= 0 )
			return true
		end
	end
	if CLIENT then return true end
	if not util.IsValidPhysicsObject( trace.Entity, trace.PhysicsBone ) then return false end

	local ply = self:GetOwner()
	local plugmodel = SocketModels[self:GetModel()]

	local plug = WireLib.MakeWireEnt(ply, {Class = "gmod_wire_plug", Pos=trace.HitPos, Angle=self:GetAngle(trace), Model=plugmodel}, self:GetClientNumber( "array" ) ~= 0)
	if not IsValid(plug) then return false end

	plug:SetPos( trace.HitPos - trace.HitNormal * plug:OBBMins().x )

	undo.Create("wireplug")
		undo.AddEntity( plug )
		undo.SetPlayer( ply )
	undo.Finish()

	ply:AddCleanup( "wire_plugs", plug )

	return true
end

function TOOL.BuildCPanel( panel )
	WireToolHelpers.MakePresetControl(panel, "wire_plug")
	ModelPlug_AddToCPanel(panel, "Socket", "wire_plug")
	panel:CheckBox("#Tool_wire_plug_freeze", "wire_plug_freeze")
	panel:CheckBox("#Tool_wire_plug_array", "wire_plug_array")
	panel:NumSlider("#Tool_wire_plug_weldforce", "wire_plug_weldforce", 0, 100000)
	panel:NumSlider("#Tool_wire_plug_attachrange", "wire_plug_attachrange", 1, 100)
	panel:CheckBox("#Tool_wire_plug_drawoutline", "wire_plug_drawoutline")
end
