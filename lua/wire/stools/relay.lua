WireToolSetup.setCategory( "Input, Output/Data Transfer" )
WireToolSetup.open( "relay", "Relay", "gmod_wire_relay", nil, "Relays" )

if ( CLIENT ) then
	language.Add( "Tool.wire_relay.name",      "Relay" )
	language.Add( "Tool.wire_relay.desc",      "Spawns a multi pole, multi throw relay switch." )
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
	TOOL.Information = { { name = "left", text = "Create/Update " .. TOOL.Name } }
end
WireToolSetup.BaseLang()
WireToolSetup.SetupMax( 20 )

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

if SERVER then
	function TOOL:GetConVars()
		return self:GetClientNumber("keygroup1"), self:GetClientNumber("keygroup2"), self:GetClientNumber("keygroup3"), self:GetClientNumber("keygroup4"), self:GetClientNumber("keygroup5"),
			self:GetClientNumber("keygroupoff"), self:GetClientNumber("toggle") ~= 0, self:GetClientNumber("normclose"),
			self:GetClientNumber("poles"), self:GetClientNumber("throws"), self:GetClientNumber("nokey") ~= 0
	end
end

function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool.wire_relay.name", Description = "#Tool.wire_relay.desc" })
	WireToolHelpers.MakePresetControl(panel, "wire_relay")

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
