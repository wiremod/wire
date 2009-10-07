TOOL.Category		= "Wire - I/O"
TOOL.Name			= "Plug"
TOOL.Command		= nil
TOOL.ConfigName		= ""
TOOL.Tab			= "Wire"

if ( CLIENT ) then
    language.Add( "Tool_wire_plug_name", "Plug Tool (Wire)" )
    language.Add( "Tool_wire_plug_desc", "Spawns plugs and sockets for use with the wire system." )
    language.Add( "Tool_wire_plug_0", "Primary: Create/Update Socket    Secondary: Create/Update Plug" )
    language.Add( "WirePlugTool_colour", "Colour:" )
	language.Add( "sboxlimit_wire_plugs", "You've hit plugs limit!" )
	language.Add( "sboxlimit_wire_sockets", "You've hit sockets limit!" )
	language.Add( "undone_wireplug", "Undone Wire Plug" )
	language.Add( "undone_wiresocket", "Undone Wire Socket" )
end

if (SERVER) then
	CreateConVar('sbox_maxwire_plugs', 20)
	CreateConVar('sbox_maxwire_sockets', 20)
end

TOOL.ClientConVar[ "a" ] = "0"
TOOL.ClientConVar[ "ar" ] = "255"
TOOL.ClientConVar[ "ag" ] = "255"
TOOL.ClientConVar[ "ab" ] = "255"
TOOL.ClientConVar[ "aa" ] = "255"

TOOL.PlugModel = "models/props_lab/tpplug.mdl"
TOOL.SocketModel = "models/props_lab/tpplugholder_single.mdl"

cleanup.Register( "wire_plugs" )

// Create socket
function TOOL:LeftClick( trace )
	if (!trace.HitPos) then return false end
	if (trace.Entity:IsPlayer()) then return false end
	if ( trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_plug") then
		return false
	end
	if ( CLIENT ) then return true end

	local ply = self:GetOwner()

	local a				= self:GetClientNumber("a")
	local ar			= math.min(self:GetClientNumber("ar"), 255)
	local ag			= math.min(self:GetClientNumber("ag"), 255)
	local ab			= math.min(self:GetClientNumber("ab"), 255)
	local aa			= math.min(self:GetClientNumber("aa"), 255)

	local ply = self:GetOwner()

	if ( trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_socket" && trace.Entity.pl == ply ) then
		trace.Entity:Setup(a,ar,ag,ab,aa)

		trace.Entity.a = a
		trace.Entity.ar = ar
		trace.Entity.ag = ag
		trace.Entity.ab = ab
		trace.Entity.aa = aa
		trace.Entity.ReceivedValue = 0
		return true
	end

	if ( !self:GetSWEP():CheckLimit( "wire_sockets" ) ) then return false end

	local Ang = trace.HitNormal:Angle()
	local Pos = trace.HitPos
	Pos = Pos + self:Offset( trace.HitNormal:Angle(), Vector(-12, 13, 0) )

	local wire_socket = MakeWireSocket( ply, Pos, Ang, self.SocketModel, a, ar, ag, ab, aa )

	local const = WireLib.Weld(wire_socket, trace.Entity, trace.PhysicsBone, true, false, true)

	undo.Create("WireSocket")
		undo.AddEntity( wire_socket )
		undo.AddEntity( const )
		undo.SetPlayer( ply )
	undo.Finish()

	ply:AddCleanup( "wire_sockets", wire_socket )

	return true
end

// Create plug
function TOOL:RightClick( trace )
	if (!trace.HitPos) then return false end
	if (trace.Entity:IsPlayer()) then return false end

	if ( CLIENT ) then return true end

	local ply = self:GetOwner()

	local a				= self:GetClientNumber("a")
	local ar			= math.min(self:GetClientNumber("ar"), 255)
	local ag			= math.min(self:GetClientNumber("ag"), 255)
	local ab			= math.min(self:GetClientNumber("ab"), 255)
	local aa			= math.min(self:GetClientNumber("aa"), 255)

	local ply = self:GetOwner()

	if ( trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_plug" && trace.Entity.pl == ply ) then
		trace.Entity:Setup(a,ar,ag,ab,aa)

		trace.Entity.a = a
		trace.Entity.ar = ar
		trace.Entity.ag = ag
		trace.Entity.ab = ab
		trace.Entity.aa = aa
		return true
	end

	if ( !self:GetSWEP():CheckLimit( "wire_plugs" ) ) then return false end

	local Ang = trace.HitNormal:Angle()

	local wire_plug = MakeWirePlug( ply, trace.HitPos, Ang, self.PlugModel, a, ar, ag, ab, aa )

	local min = wire_plug:OBBMins()
	wire_plug:SetPos( trace.HitPos - trace.HitNormal * min.z )

	undo.Create("WirePlug")
		undo.AddEntity( wire_plug )
		undo.SetPlayer( ply )
	undo.Finish()

	ply:AddCleanup( "wire_plugs", wire_plug )

	return true
end

if (SERVER) then

	function MakeWirePlug( pl, Pos, Ang, model, a, ar, ag, ab, aa )
		if ( !pl:CheckLimit( "wire_plugs" ) ) then return false end

		local wire_plug = ents.Create( "gmod_wire_plug" )
		if (!wire_plug:IsValid()) then return false end

		wire_plug:SetAngles( Ang )
		wire_plug:SetPos( Pos )
		wire_plug:SetModel( Model(model or "models/props_lab/tpplug.mdl") )
		wire_plug:Spawn()

		wire_plug:Setup( a, ar, ag, ab, aa)
		wire_plug:SetPlayer( pl )

		local ttable = {
			a				= a,
			ar				= ar,
			ag				= ag,
			ab				= ab,
			aa				= aa,
			pl              = pl,
			MySocket		= nil
		}
		table.Merge(wire_plug:GetTable(), ttable )

		pl:AddCount( "wire_plug", wire_plug )

		return wire_plug
	end

	duplicator.RegisterEntityClass("gmod_wire_plug", MakeWirePlug, "Pos", "Ang", "Model", "a", "ar", "ag", "ab", "aa")


	function MakeWireSocket( pl, Pos, Ang, model, a, ar, ag, ab, aa )
		if ( !pl:CheckLimit( "wire_sockets" ) ) then return false end

		local wire_socket = ents.Create( "gmod_wire_socket" )
		if (!wire_socket:IsValid()) then return false end

		wire_socket:SetAngles( Ang )
		wire_socket:SetPos( Pos )
		wire_socket:SetModel( Model(model or "models/props_lab/tpplugholder_single.mdl") )
		wire_socket:Spawn()

		wire_socket:Setup( a, ar, ag, ab, aa)
		wire_socket:SetPlayer( pl )

		local ttable = {
			a				= a,
			ar				= ar,
			ag				= ag,
			ab				= ab,
			aa				= aa,
			pl              = pl,
			ReceivedValue	= 0
		}
		table.Merge(wire_socket:GetTable(), ttable )

		pl:AddCount( "wire_socket", wire_socket )

		return wire_socket
	end

	duplicator.RegisterEntityClass("gmod_wire_socket", MakeWireSocket, "Pos", "Ang", "Model", "a", "ar", "ag", "ab", "aa")

end

function TOOL:UpdateGhostWireSocket( ent, player )
	if ( !ent || !ent:IsValid() ) then return end

	local tr 	= utilx.GetPlayerTrace( player, player:GetCursorAimVector() )
	local trace 	= util.TraceLine( tr )

	if (!trace.Hit || trace.Entity:IsPlayer() || trace.Entity:GetClass() == "gmod_wire_socket" ) then
		ent:SetNoDraw( true )
		return
	end

	local Ang = trace.HitNormal:Angle()

	local Pos = trace.HitPos

	Pos = Pos + self:Offset( trace.HitNormal:Angle(), Vector(-12, 13, 0) )

	ent:SetPos( Pos )
	ent:SetAngles( Ang )

	ent:SetNoDraw( false )
end

function TOOL:Offset( ang, offsetvec )
	local offset = offsetvec
	local stackdir = ang:Up()

	offset = ang:Up() * offset.X + ang:Forward() * -1 * offset.Z + ang:Right() * offset.Y

	return stackdir * 2 + offset
end

function TOOL:Think()
	if (!self.GhostEntity || !self.GhostEntity:IsValid() || self.GhostEntity:GetModel() != self.SocketModel ) then
		self:MakeGhostEntity( self.SocketModel, Vector(0,0,0), Angle(0,0,0) )
	end

	self:UpdateGhostWireSocket( self.GhostEntity, self:GetOwner() )
end

function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool_wire_plug_name", Description = "#Tool_wire_plug_desc" })

		panel:AddControl("ComboBox", {
		Label = "#Presets",
		MenuButton = "1",
		Folder = "wire_plug",

		Options = {
			["#Default"] = {
				wire_plug_a = "0",
				wire_plug_ar = "255",
				wire_plug_ag = "0",
				wire_plug_ab = "0",
				wire_plug_aa = "255",
			}
		},

		CVars = {
			[0] = "wire_plug_a",
			[1] = "wire_plug_ar",
			[2] = "wire_plug_ag",
			[3] = "wire_plug_ab",
			[4] = "wire_plug_aa",
		}
	})

	panel:AddControl("Color", {
		Label = "#WirePlugTool_colour",
		Red = "wire_plug_ar",
		Green = "wire_plug_ag",
		Blue = "wire_plug_ab",
		Alpha = "wire_plug_aa",
		ShowAlpha = "1",
		ShowHSV = "1",
		ShowRGB = "1",
		Multiplier = "255"
	})
end
