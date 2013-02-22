WireToolSetup.setCategory( "I/O" )
WireToolSetup.open( "relay", "Relay", "gmod_wire_relay", nil, "Relays" )

if ( CLIENT ) then
	language.Add( "Tool.wire_relay.name",      "Relay" )
	language.Add( "Tool.wire_relay.desc",      "Spawns a multi pole, multi throw relay switch." )
	language.Add( "Tool.wire_relay.0",         "Primary: Create/Update Relay" )
	language.Add( "WireRelayTool_keygroup1",   "Input 1 Key:" )
	language.Add( "WireRelayTool_keygroup2",   "Input 2 Key:" )
	language.Add( "WireRelayTool_keygroup3",   "Input 3 Key:" )
	language.Add( "WireRelayTool_keygroup4",   "Input 4 Key:" )
	language.Add( "WireRelayTool_keygroup5",   "Input 5 Key:" )
	language.Add( "WireRelayTool_keygroupoff", "Open (off) Key:" )
	language.Add( "WireRelayTool_nokey",       "No Key switching" )
	language.Add( "WireRelayTool_toggle",      "Toggle" )
	language.Add( "WireRelayTool_normclose",   "Normaly:" )
	language.Add( "WireRelayTool_poles",       "Number of poles:" )
	language.Add( "WireRelayTool_throws",      "Number of throws:" )
	language.Add( "sboxlimit_wire_relays",     "You've hit the wire relays limit!" )
	language.Add( "undone_wirerelay",          "Undone Wire Relay" )
end

if (SERVER) then
	CreateConVar('sbox_maxwire_relays', 20)
end
TOOL.ClientConVar = {
	keygroupoff = "0",
	keygroup1   = "1",
	keygroup2   = "2",
	keygroup3   = "3",
	keygroup4   = "4",
	keygroup5   = "5",
	nokey       = "0",
	toggle      = "1",
	normclose   = "0",
	poles       = "1",
	throws      = "2",
	model       = "models/kobilica/relay.mdl",
}

cleanup.Register( "wire_relays" )

function TOOL:LeftClick( trace )

	if (!trace.HitPos) then return false end
	if (trace.Entity:IsPlayer()) then return false end
	if ( CLIENT ) then return true end
	if not util.IsValidPhysicsObject( trace.Entity, trace.PhysicsBone ) then return false end

	local ply = self:GetOwner()

	local _keygroup1   = self:GetClientNumber( "keygroup1" )
	local _keygroup2   = self:GetClientNumber( "keygroup2" )
	local _keygroup3   = self:GetClientNumber( "keygroup3" )
	local _keygroup4   = self:GetClientNumber( "keygroup4" )
	local _keygroup5   = self:GetClientNumber( "keygroup5" )
	local _keygroupoff = self:GetClientNumber( "keygroupoff" )
	local _nokey       = self:GetClientNumber( "nokey" ) == 1
	local _toggle      = self:GetClientNumber( "toggle" ) == 1
	local _normclose   = self:GetClientNumber( "normclose" )
	local _value_off   = self:GetClientNumber( "value_off" )
	local _poles       = self:GetClientNumber( "poles" )
	local _throws      = self:GetClientNumber( "throws" )
	local _model       = self:GetClientInfo( "model" )
	if not util.IsValidModel( _model ) or not util.IsValidProp( _model ) then return end

	if ( trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_relay" ) then
		trace.Entity:Setup( _keygroup1, _keygroup2, _keygroup3, _keygroup4, _keygroup5, _keygroupoff, _toggle, _normclose, _poles, _throws, _nokey )
		return true
	end

	if ( !self:GetSWEP():CheckLimit( "wire_relays" ) ) then return false end

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90

	local wire_relay = MakeWireRelay( ply, trace.HitPos, Ang, _model, _keygroup1, _keygroup2, _keygroup3, _keygroup4, _keygroup5, _keygroupoff, _toggle, _normclose, _poles, _throws, _nokey )

	local min = wire_relay:OBBMins()
	wire_relay:SetPos( trace.HitPos - trace.HitNormal * min.z )

	local const = WireLib.Weld(wire_relay, trace.Entity, trace.PhysicsBone, true)

	undo.Create("WireRelay")
		undo.AddEntity( wire_relay )
		undo.AddEntity( const )
		undo.SetPlayer( ply )
	undo.Finish()

	ply:AddCleanup( "wire_relays", wire_relay )

	return true
end

if (SERVER) then

	function MakeWireRelay( pl, Pos, Ang, model, keygroup1, keygroup2, keygroup3, keygroup4, keygroup5, keygroupoff, toggle, normclose, poles, throws, nokey)
		--print(model)
		if ( !pl:CheckLimit( "wire_relays" ) ) then return false end

		local wire_relay = ents.Create( "gmod_wire_relay" )
		if (!wire_relay:IsValid()) then return false end

		wire_relay:SetAngles( Ang )
		wire_relay:SetPos( Pos )
		wire_relay:SetModel( Model(model) )
		wire_relay:Spawn()

		wire_relay:Setup( keygroup1, keygroup2, keygroup3, keygroup4, keygroup5, keygroupoff, toggle, normclose, poles, throws )
		wire_relay:SetPlayer( pl )

		if (!nokey) then
			if (keygroupoff) then
				numpad.OnDown( pl, keygroupoff, "WireRelay_On", wire_relay, 0 )
				numpad.OnUp( pl, keygroupoff, "WireRelay_Off", wire_relay, 0 )
			end
			if (keygroup1) then
				numpad.OnDown( pl, keygroup1, "WireRelay_On", wire_relay, 1 )
				numpad.OnUp( pl, keygroup1, "WireRelay_Off", wire_relay, 1 )
			end
			if (keygroup2) then
				numpad.OnDown( pl, keygroup2, "WireRelay_On", wire_relay, 2 )
				numpad.OnUp( pl, keygroup2, "WireRelay_Off", wire_relay, 2 )
			end
			if (keygroup3) then
				numpad.OnDown( pl, keygroup3, "WireRelay_On", wire_relay, 3 )
				numpad.OnUp( pl, keygroup3, "WireRelay_Off", wire_relay, 3 )
			end
			if (keygroup4) then
				numpad.OnDown( pl, keygroup4, "WireRelay_On", wire_relay, 4 )
				numpad.OnUp( pl, keygroup4, "WireRelay_Off", wire_relay, 4 )
			end
			if (keygroup5) then
				numpad.OnDown( pl, keygroup5, "WireRelay_On", wire_relay, 5 )
				numpad.OnUp( pl, keygroup5, "WireRelay_Off", wire_relay, 5 )
			end
		end

		local ttable = {
			keygroup1   = keygroup1,
			keygroup2   = keygroup2,
			keygroup3   = keygroup3,
			keygroup4   = keygroup4,
			keygroup5   = keygroup5,
			keygroupoff = keygroupoff,
			toggle      = toggle,
			normclose   = normclose,
			poles       = poles,
			throws      = throws,
			nokey       = nokey,
			pl          = pl
		}
		table.Merge(wire_relay, ttable )

		pl:AddCount( "wire_relays", wire_relay )

		return wire_relay
	end
	duplicator.RegisterEntityClass("gmod_wire_relay", MakeWireRelay, "Pos", "Ang", "Model", "keygroup1", "keygroup2", "keygroup3", "keygroup4", "keygroup5", "keygroupoff", "toggle", "normclose", "poles", "throws", "nokey")
end

function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool.wire_relay.name", Description = "#Tool.wire_relay.desc" })
	WireToolHelpers.MakePresetControl(panel, "wire_radio")

	panel:AddControl("Slider", {
		Label = "#WireRelayTool_poles",
		Type = "Integer",
		Min = "1",
		Max = "8",
		Command = "wire_relay_poles"
	})

	panel:AddControl("Slider", {
		Label = "#WireRelayTool_throws",
		Type = "Integer",
		Min = "1",
		Max = "10",
		Command = "wire_relay_throws"
	})


	panel:AddControl("CheckBox", {
		Label = "#WireRelayTool_toggle",
		Command = "wire_relay_toggle"
	})

	panel:AddControl("ComboBox", {
		Label = "#WireRelayTool_normclose",
		Options = {
			["Open"]        = { wire_relay_normclose = "0" },
			["Closed to 1"] = { wire_relay_normclose = "1" },
			["Closed to 2"] = { wire_relay_normclose = "2" },
			["Closed to 3"] = { wire_relay_normclose = "3" },
			["Closed to 4"] = { wire_relay_normclose = "4" },
			["Closed to 5"] = { wire_relay_normclose = "5" }
		}
	})

	panel:AddControl("CheckBox", {
		Label = "#WireRelayTool_nokey",
		Command = "wire_relay_nokey"
	})

	panel:AddControl("Numpad", {
		Label = "#WireRelayTool_keygroupoff", Label2 = "#WireRelayTool_keygroup1",
		Command = "wire_relay_keygroupoff", Command2 = "wire_relay_keygroup1",
		ButtonSize = "22"
	})
	panel:AddControl("Numpad", {
		Label = "#WireRelayTool_keygroup2", Label2 = "#WireRelayTool_keygroup3",
		Command = "wire_relay_keygroup2", Command2 = "wire_relay_keygroup3",
		ButtonSize = "22"
	})
	panel:AddControl("Numpad", {
		Label = "#WireRelayTool_keygroup4", Label2 = "#WireRelayTool_keygroup5",
		Command = "wire_relay_keygroup4", Command2 = "wire_relay_keygroup5",
		ButtonSize = "22"
	})

end
