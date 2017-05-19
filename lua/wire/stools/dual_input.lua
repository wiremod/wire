WireToolSetup.setCategory( "Input, Output/Keyboard Interaction" )
WireToolSetup.open( "dual_input", "Dual Input", "gmod_wire_dual_input", nil, "Dual Inputs" )

if CLIENT then
	language.Add( "tool.wire_dual_input.name", "Dual Input Tool (Wire)" )
	language.Add( "tool.wire_dual_input.desc", "Spawns a daul input for use with the wire system." )
	TOOL.Information = { { name = "left", text = "Create/Update " .. TOOL.Name } }
	language.Add( "WireDualInputTool_keygroup", "Key 1:" )
	language.Add( "WireDualInputTool_keygroup2", "Key 2:" )
	language.Add( "WireDualInputTool_toggle", "Toggle" )
	language.Add( "WireDualInputTool_value_on", "Value 1 On:" )
	language.Add( "WireDualInputTool_value_on2", "Value 2 On:" )
	language.Add( "WireDualInputTool_value_off", "Value Off:" )
end
WireToolSetup.BaseLang()
WireToolSetup.SetupMax( 20 )

if SERVER then
	ModelPlug_Register("Numpad")

	function TOOL:GetConVars()
		return self:GetClientNumber( "keygroup" ), self:GetClientNumber( "keygroup2" ), self:GetClientNumber( "toggle" ),
			self:GetClientNumber( "value_off" ), self:GetClientNumber( "value_on" ), self:GetClientNumber( "value_on2" )
	end

	-- Uses default WireToolObj:MakeEnt's WireLib.MakeWireEnt function
end

TOOL.ClientConVar = {
	model = "models/beer/wiremod/numpad.mdl",
	modelsize = "",
	keygroup = 7,
	keygroup2 = 4,
	toggle = 0,
	value_off = 0,
	value_on = 1,
	value_on2 = -1,
}

function TOOL.BuildCPanel(panel)
	WireToolHelpers.MakePresetControl(panel, "wire_dual_input")
	WireToolHelpers.MakeModelSizer(panel, "wire_dual_input_modelsize")
	ModelPlug_AddToCPanel(panel, "Numpad", "wire_dual_input", true)

	panel:AddControl("Numpad", {
		Label = "#WireDualInputTool_keygroup",
		Command = "wire_dual_input_keygroup"
	})

	panel:AddControl("Numpad", {
		Label = "#WireDualInputTool_keygroup2",
		Command = "wire_dual_input_keygroup2"
	})

	panel:CheckBox("#WireDualInputTool_toggle", "wire_dual_input_toggle")
	panel:NumSlider("#WireDualInputTool_value_on", "wire_dual_input_value_on", -10, 10, 1)
	panel:NumSlider("#WireDualInputTool_value_off", "wire_dual_input_value_off", -10, 10, 1)
	panel:NumSlider("#WireDualInputTool_value_on2", "wire_dual_input_value_on2", -10, 10, 1)
end
