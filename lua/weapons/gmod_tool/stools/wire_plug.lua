TOOL.Category		= "Wire - I/O"
TOOL.Name			= "Plug"
TOOL.Command		= nil
TOOL.ConfigName		= ""
TOOL.Tab			= "Wire"

if (SERVER) then

	CreateConVar("sbox_maxwire_plugs",20)
	CreateConVar("sbox_maxwire_sockets",20)

	resource.AddFile("models/bull/various/usb_socket.mdl")
	resource.AddFile("materials/bull/various/usb_socket.vtf")

	resource.AddFile("models/bull/various/usb_stick.mdl")
	resource.AddFile("materials/bull/various/usb_stick.vtf")

else

	----------------------------------------------------------------------------------------------------
	-- Tool Info
	----------------------------------------------------------------------------------------------------

	language12.Add( "Tool_wire_plug_name", "Plug & Socket Tool (Wire)" )
	language12.Add( "Tool_wire_plug_desc", "Spawns plugs and sockets for use with the wire system." )
	language12.Add( "Tool_wire_plug_0", "Primary: Create/Update Socket, Secondary: Create/Update Plug" )
	language12.Add( "sboxlimit_wire_plugs", "You've hit the Wire Plugs limit!" )
	language12.Add( "sboxlimit_wire_sockets", "You've hit the Wire Sockets limit!" )
	language12.Add( "undone_wireplug", "Undone Wire Plug" )
	language12.Add( "undone_wiresocket", "Undone Wire Socket" )

	language12.Add( "Tool_wire_plug_weld", "Weld the socket." )
	language12.Add( "Tool_wire_plug_weldtoworld", "Weld the socket to the world." )
	language12.Add( "Tool_wire_plug_freeze", "Freeze the socket." )
	language12.Add( "Tool_wire_plug_array", "Use array inputs/outputs instead." )
	language12.Add( "Tool_wire_plug_weldforce", "Plug weld force:" )
	language12.Add( "Tool_wire_plug_attachrange", "Plug attachment detection range:" )
	language12.Add( "Tool_wire_plug_drawoutline", "Draw the white outline on plugs and sockets." )
	language12.Add( "Tool_wire_plug_drawoutline_tooltip", "Disabling this helps you see inside the USB plug model when you set its material to wireframe." )


	TOOL.ClientConVar["model"] = "models/props_lab/tpplugholder_single.mdl"
	TOOL.ClientConVar["weld"] = 1
	TOOL.ClientConVar["weldtoworld"] = 0
	TOOL.ClientConVar["freeze"] = 1
	TOOL.ClientConVar["array"] = 0
	TOOL.ClientConVar["weldforce"] = 5000
	TOOL.ClientConVar["attachrange"] = 5
	TOOL.ClientConVar["drawoutline"] = 1

	----------------------------------------------------------------------------------------------------
	-- BuildCPanel
	----------------------------------------------------------------------------------------------------

	list.Set( "wire_socket_models", "models/props_lab/tpplugholder_single.mdl", {} )
	list.Set( "wire_socket_models", "models/bull/various/usb_socket.mdl", {} )
	list.Set( "wire_socket_models", "models/hammy/pci_slot.mdl", {} )
	list.Set( "wire_socket_models", "models/wingf0x/isasocket.mdl", {} )
	list.Set( "wire_socket_models", "models/wingf0x/altisasocket.mdl", {} )
	list.Set( "wire_socket_models", "models/wingf0x/ethernetsocket.mdl", {} )
	list.Set( "wire_socket_models", "models/wingf0x/hdmisocket.mdl", {} )

	function TOOL.BuildCPanel( CPanel )
		CPanel:AddControl("Header", { Text = "#Tool_wire_plug_name", Description = "#Tool_wire_plug_desc" })

		local mdl = vgui.Create("DWireModelSelect",CPanel)
		mdl:SetModelList( list.Get( "wire_socket_models" ), "wire_plug_model" )
		mdl:SetHeight( 2 )
		CPanel:Add( mdl )

		local weld = vgui.Create("DCheckBoxLabel",CPanel)
		weld:SetText( "#Tool_wire_plug_weld" )
		weld:SizeToContents()
		weld:SetConVar( "wire_plug_weld" )
		CPanel:Add( weld )

		local toworld = vgui.Create("DCheckBoxLabel",CPanel)
		toworld:SetText( "#Tool_wire_plug_weldtoworld" )
		toworld:SizeToContents()
		toworld:SetConVar( "wire_plug_weldtoworld" )
		CPanel:Add( toworld )

		local freeze = vgui.Create("DCheckBoxLabel",CPanel)
		freeze:SetText( "#Tool_wire_plug_freeze" )
		freeze:SizeToContents()
		freeze:SetConVar( "wire_plug_freeze" )
		CPanel:Add( freeze )

		local array = vgui.Create("DCheckBoxLabel",CPanel)
		array:SetText( "#Tool_wire_plug_array" )
		array:SizeToContents()
		array:SetConVar( "wire_plug_array" )
		CPanel:Add( array )

		local weldforce = vgui.Create("DNumSlider",CPanel)
		weldforce:SetText( "#Tool_wire_plug_weldforce" )
		weldforce:SetConVar( "wire_plug_weldforce" )
		weldforce:SetMin( 0 )
		weldforce:SetMax( 100000 )
		weldforce:SetToolTip( "Default: 5000" )
		CPanel:Add( weldforce )

		local attachrange = vgui.Create("DNumSlider",CPanel)
		attachrange:SetText( "#Tool_wire_plug_attachrange" )
		attachrange:SetConVar( "wire_plug_attachrange" )
		attachrange:SetMin( 1 )
		attachrange:SetMax( 100 )
		attachrange:SetToolTip( "Default: 5" )
		CPanel:Add( attachrange )

		local drawoutline = vgui.Create("DCheckBoxLabel",CPanel)
		drawoutline:SetText( "#Tool_wire_plug_drawoutline" )
		drawoutline:SetToolTip( "#Tool_wire_plug_drawoutline_tooltip" )
		drawoutline:SizeToContents()
		drawoutline:SetConVar( "wire_plug_drawoutline" )
		CPanel:Add( drawoutline )
	end

end

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

----------------------------------------------------------------------------------------------------
-- GetMode
----------------------------------------------------------------------------------------------------

function TOOL:GetModel()
	local model = self:GetClientInfo( "model" )
	if (!util.IsValidModel( model ) or !util.IsValidProp( model ) or !SocketModels[ model ]) then return "models/props_lab/tpplugholder_single.mdl", "models/props_lab/tpplug.mdl" end
	return model, SocketModels[ model ]
end

----------------------------------------------------------------------------------------------------
-- SOCKET
----------------------------------------------------------------------------------------------------
--------------------
-- LeftClick
-- Create Socket
--------------------
function TOOL:LeftClick( trace )
	if (!trace) then return false end
	if (trace.Entity) then
		if (trace.Entity:IsPlayer()) then return false end
		if (trace.Entity:GetClass() == "gmod_wire_socket") then
			if (CLIENT) then return true end
			trace.Entity:SetUp( self:GetClientNumber( "array" ) != 0, self:GetClientNumber( "weldforce" ), math.Clamp( self:GetClientNumber( "attachrange" ), 1, 100 ) )
			return true
		end
	end
	if (CLIENT) then return true end
	if not util.IsValidPhysicsObject( trace.Entity, trace.PhysicsBone ) then return false end

	local ply = self:GetOwner()
	local socketmodel, plugmodel = self:GetModel()
	local Pos, Ang = trace.HitPos, trace.HitNormal:Angle() + (AngleOffset[socketmodel] or Angle(0,0,0))

	local socket = MakeWireSocket( ply, Pos, Ang, socketmodel, 	self:GetClientNumber( "array" ) != 0,
																self:GetClientNumber( "weldforce" ),
																math.Clamp( self:GetClientNumber( "attachrange" ), 1, 100 ) )

	if (!socket or !socket:IsValid()) then return false end

	local weld
	if (self:GetClientNumber( "weld" ) != 0) then
		weld = WireLib.Weld( socket, trace.Entity, trace.PhysicsBone, true, false, self:GetClientNumber( "weldtoworld" ) != 0 )
	end

	if (self:GetClientNumber( "freeze") != 0) then
		socket:GetPhysicsObject():EnableMotion( false )
	end

	undo.Create("wiresocket")
		undo.AddEntity( socket )
		if (weld) then undo.AddEntity( weld ) end
		undo.SetPlayer( ply )
	undo.Finish()

	ply:AddCleanup( "wire_sockets", socket )

	return true
end


--------------------
-- MakeWireSocket
-- Creation Function
--------------------
if (SERVER) then
	function MakeWireSocket( ply, Pos, Ang, model, ArrayInput, WeldForce, AttachRange, ArrayHiSpeed )
		if (!ply:CheckLimit( "wire_sockets" )) then return false end

		local socket = ents.Create( "gmod_wire_socket" )
		if (!socket:IsValid()) then return false end

		socket:SetAngles( Ang )
		socket:SetPos( Pos )
		socket:SetModel( model )
		socket:SetPlayer( ply )
		socket:Spawn()
		socket:SetUp( ArrayInput, WeldForce, AttachRange, ArrayHiSpeed )
		socket:Activate()

		ply:AddCount( "wire_socket", socket )

		return socket
	end
	duplicator.RegisterEntityClass( "gmod_wire_socket", MakeWireSocket, "Pos", "Ang", "model", "ArrayInput", "WeldForce", "AttachRange" )
end

----------------------------------------------------------------------------------------------------
-- PLUG
----------------------------------------------------------------------------------------------------
--------------------
-- RightClick
-- Create Plug
--------------------
function TOOL:RightClick( trace )
	if (!trace) then return false end
	if (trace.Entity) then
		if (trace.Entity:IsPlayer()) then return false end
		if (trace.Entity:GetClass() == "gmod_wire_plug") then
			if (CLIENT) then return true end
			trace.Entity:SetUp( self:GetClientNumber( "array" ) != 0 )
			return true
		end
	end
	if (CLIENT) then return true end
	if not util.IsValidPhysicsObject( trace.Entity, trace.PhysicsBone ) then return false end

	local ply = self:GetOwner()
	local socketmodel, plugmodel = self:GetModel()
	local Pos, Ang = trace.HitPos, trace.HitNormal:Angle() + (AngleOffset[plugmodel] or Angle(0,0,0))

	local plug = MakeWirePlug( ply, Pos, Ang, plugmodel, 	self:GetClientNumber( "array" ) != 0 )

	if (!plug or !plug:IsValid()) then return false end

	plug:SetPos( trace.HitPos - trace.HitNormal * plug:OBBMins().x )

	undo.Create("wireplug")
		undo.AddEntity( plug )
		undo.SetPlayer( ply )
	undo.Finish()

	ply:AddCleanup( "wire_plugs", plug )

	return true
end


--------------------
-- MakeWirePlug
-- Creation Function
--------------------
if (SERVER) then
	function MakeWirePlug( ply, Pos, Ang, model, ArrayInput, ArrayHiSpeed )
		if (!ply:CheckLimit( "wire_plugs" )) then return false end

		local plug = ents.Create( "gmod_wire_plug" )
		if (!plug:IsValid()) then return false end

		plug:SetAngles( Ang )
		plug:SetPos( Pos )
		plug:SetModel( model )
		plug:SetPlayer( ply )
		plug:Spawn()
		plug:SetUp( ArrayInput, ArrayHiSpeed )
		plug:Activate()


		ply:AddCount( "wire_plug", plug )

		return plug
	end
	duplicator.RegisterEntityClass( "gmod_wire_plug", MakeWirePlug, "Pos", "Ang", "model", "ArrayInput" )
end

----------------------------------------------------------------------------------------------------
-- GHOST
----------------------------------------------------------------------------------------------------

function TOOL:DrawGhost()
	local ent, ply = self.GhostEntity, self:GetOwner()
	if (!ent or !ent:IsValid()) then return end
	local trace = ply:GetEyeTrace()

	if (!trace.Hit or trace.Entity:IsPlayer() or trace.Entity:GetClass() == "gmod_wire_socket" or trace.Entity:GetClass() == "gmod_wire_plug") then
		ent:SetNoDraw( true )
		return
	end

	local Pos, Ang = trace.HitPos, trace.HitNormal:Angle()
	ent:SetPos( Pos )
	ent:SetAngles( Ang + (AngleOffset[self.GhostEntity:GetModel()] or Angle(0,0,0)) )

	ent:SetNoDraw( false )
end

function TOOL:Think()
	local model, _ = self:GetModel()
	if (!self.GhostEntity or !self.GhostEntity:IsValid() or self.GhostEntity:GetModel() != model) then
		self:MakeGhostEntity( model, Vector(0,0,0), Angle(0,0,0) )
	end

	self:DrawGhost()
end
