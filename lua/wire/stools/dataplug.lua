WireToolSetup.setCategory( "Advanced" )
WireToolSetup.open( "dataplug", "Data - Plug/Socket", "gmod_wire_datasocket", nil, "Plugs and Sockets" )

if ( CLIENT ) then
    language.Add( "Tool.wire_dataplug.name", "Data Plug Tool (Wire)" )
    language.Add( "Tool.wire_dataplug.desc", "Spawns plugs and sockets for use with the hi-speed wire system." )
    language.Add( "Tool.wire_dataplug.0", "Primary: Create/Update Socket    Secondary: Create/Update Plug" )
    language.Add( "WirePlugTool_colour", "Colour:" )
	language.Add( "sboxlimit_wire_dataplugs", "You've hit plugs limit!" )
	language.Add( "sboxlimit_wire_datasockets", "You've hit sockets limit!" )
	language.Add( "undone_wiredataplug", "Undone Wire Data Plug" )
	language.Add( "undone_wiredatasocket", "Undone Wire Data Socket" )
end

if (SERVER) then
	CreateConVar('sbox_maxwire_dataplugs', 20)
	CreateConVar('sbox_maxwire_datasockets', 20)
end

TOOL.ClientConVar["a"] = "0"
TOOL.ClientConVar["ar"] = "255"
TOOL.ClientConVar["ag"] = "255"
TOOL.ClientConVar["ab"] = "255"
TOOL.ClientConVar["aa"] = "255"
TOOL.ClientConVar["model"] = "models/hammy/pci_slot.mdl"

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
	if (!util.IsValidModel( model ) or !util.IsValidProp( model ) or !SocketModels[ model ]) then return "models/props_lab/tpplugholder_single.mdl", "models/props_lab/tpplug.mdl" end
	return model, SocketModels[ model ]
end

// Create socket
function TOOL:LeftClick( trace )
	if (!trace.HitPos) then return false end
	if (trace.Entity:IsPlayer()) then return false end
	if ( trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_dataplug") then
		return false
	end
	if ( CLIENT ) then return true end
	if not util.IsValidPhysicsObject( trace.Entity, trace.PhysicsBone ) then return false end

	local ply = self:GetOwner()

	// Get client's CVars
	local a				= self:GetClientNumber("a")
	local ar			= math.min(self:GetClientNumber("ar"), 255)
	local ag			= math.min(self:GetClientNumber("ag"), 255)
	local ab			= math.min(self:GetClientNumber("ab"), 255)
	local aa			= math.min(self:GetClientNumber("aa"), 255)

	local ply = self:GetOwner()

	if ( trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_datasocket" ) then
		trace.Entity:Setup(a,ar,ag,ab,aa)

		trace.Entity.a = a
		trace.Entity.ar = ar
		trace.Entity.ag = ag
		trace.Entity.ab = ab
		trace.Entity.aa = aa
		trace.Entity.ReceivedValue = 0
		return true
	end

	if ( !self:GetSWEP():CheckLimit( "wire_datasockets" ) ) then return false end

	local socketmodel, plugmodel = self:GetModel()
	local Pos, Ang = trace.HitPos, trace.HitNormal:Angle() + (AngleOffset[plugmodel] or Angle())

	local wire_datasocket = MakeWireDataSocket( ply, Pos, Ang, socketmodel, a, ar, ag, ab, aa )

	local const = WireLib.Weld(wire_datasocket, trace.Entity, trace.PhysicsBone, true, false, true)

	undo.Create("WireSocket")
		undo.AddEntity( wire_datasocket )
		undo.AddEntity( const )
		undo.SetPlayer( ply )
	undo.Finish()

	ply:AddCleanup( "wire_datasockets", wire_datasocket )
	ply:AddCleanup( "wire_datasockets", const )

	return true
end

// Create plug
function TOOL:RightClick( trace )
	if (!trace.HitPos) then return false end
	if (trace.Entity:IsPlayer()) then return false end
	if ( CLIENT ) then return true end
	if not util.IsValidPhysicsObject( trace.Entity, trace.PhysicsBone ) then return false end

	local ply = self:GetOwner()

	// Get client's CVars
	local a				= self:GetClientNumber("a")
	local ar			= math.min(self:GetClientNumber("ar"), 255)
	local ag			= math.min(self:GetClientNumber("ag"), 255)
	local ab			= math.min(self:GetClientNumber("ab"), 255)
	local aa			= math.min(self:GetClientNumber("aa"), 255)

	local ply = self:GetOwner()

	if ( trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_dataplug" ) then
		trace.Entity:Setup(a,ar,ag,ab,aa)

		trace.Entity.a = a
		trace.Entity.ar = ar
		trace.Entity.ag = ag
		trace.Entity.ab = ab
		trace.Entity.aa = aa
		return true
	end

	if ( !self:GetSWEP():CheckLimit( "wire_dataplugs" ) ) then return false end

	local socketmodel, plugmodel = self:GetModel()
	local Pos, Ang = trace.HitPos, trace.HitNormal:Angle() + (AngleOffset[plugmodel] or Angle(0,0,0))

	local wire_dataplug = MakeWireDataPlug( ply, trace.HitPos, Ang, plugmodel, a, ar, ag, ab, aa )

	local min = wire_dataplug:OBBMins()
	wire_dataplug:SetPos( trace.HitPos - trace.HitNormal * min.z )

	undo.Create("WirePlug")
		undo.AddEntity( wire_dataplug )
		undo.SetPlayer( ply )
	undo.Finish()

	ply:AddCleanup( "wire_dataplugs", wire_dataplug )

	return true
end

if (SERVER) then

	function MakeWireDataPlug( pl, Pos, Ang, model, a, ar, ag, ab, aa )
		if ( !pl:CheckLimit( "wire_dataplugs" ) ) then return false end

		local wire_dataplug = ents.Create( "gmod_wire_dataplug" )
		if (!wire_dataplug:IsValid()) then return false end

		wire_dataplug:SetAngles( Ang )
		wire_dataplug:SetPos( Pos )
		wire_dataplug:SetModel( Model(model or "models/hammy/pci_card.mdl") )
		wire_dataplug:Spawn()

		wire_dataplug:Setup( a, ar, ag, ab, aa)
		wire_dataplug:SetPlayer( pl )

		local ttable = {
			a				= a,
			ar				= ar,
			ag				= ag,
			ab				= ab,
			aa				= aa,
			pl              = pl,
			MySocket		= nil
		}
		table.Merge(wire_dataplug:GetTable(), ttable )

		pl:AddCount( "wire_dataplugs", wire_dataplug )

		return wire_dataplug
	end
	duplicator.RegisterEntityClass("gmod_wire_dataplug", MakeWireDataPlug, "Pos", "Ang", "Model", "a", "ar", "ag", "ab", "aa")


	function MakeWireDataSocket( pl, Pos, Ang, model, a, ar, ag, ab, aa )
		if ( !pl:CheckLimit( "wire_datasockets" ) ) then return false end

		local wire_datasocket = ents.Create( "gmod_wire_datasocket" )
		if (!wire_datasocket:IsValid()) then return false end

		wire_datasocket:SetAngles( Ang )
		wire_datasocket:SetPos( Pos )
		wire_datasocket:SetModel( Model(model or "models/hammy/pci_slot.mdl") )
		wire_datasocket:Spawn()

		wire_datasocket:Setup( a, ar, ag, ab, aa)
		wire_datasocket:SetPlayer( pl )

		local ttable = {
			a				= a,
			ar				= ar,
			ag				= ag,
			ab				= ab,
			aa				= aa,
			pl              = pl,
			ReceivedValue	= 0
		}
		table.Merge(wire_datasocket:GetTable(), ttable )

		pl:AddCount( "wire_datasockets", wire_datasocket )

		return wire_datasocket
	end
	duplicator.RegisterEntityClass("gmod_wire_datasocket", MakeWireDataSocket, "Pos", "Ang", "Model", "a", "ar", "ag", "ab", "aa")
end

function TOOL:GetGhostAngle(trace)
	local socketmodel = self:GetModel()
	return trace.HitNormal:Angle() + (AngleOffset[socketmodel] or Angle(0,0,0)) - Angle(90,0,0)
end

function TOOL.BuildCPanel(panel)
	WireToolHelpers.MakePresetControl(panel, "wire_dataplug")
	ModelPlug_AddToCPanel(panel, "Socket", "wire_dataplug")

	panel:AddControl("Color", {
		Label = "#WirePlugTool_colour",
		Red = "wire_dataplug_ar",
		Green = "wire_dataplug_ag",
		Blue = "wire_dataplug_ab",
		Alpha = "wire_dataplug_aa",
		ShowAlpha = "1",
		ShowHSV = "1",
		ShowRGB = "1",
		Multiplier = "255"
	})
end
