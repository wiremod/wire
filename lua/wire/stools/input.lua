WireToolSetup.setCategory( "Input, Output/Keyboard Interaction" )
WireToolSetup.open( "input", "Numpad Input", "gmod_wire_input", nil, "Numpad Inputs" )

if CLIENT then
	language.Add( "tool.wire_input.name", "Input Tool (Wire)" )
	language.Add( "tool.wire_input.desc", "Spawns a input for use with the wire system." )
	language.Add( "WireInputTool_keygroup", "Key:" )
	language.Add( "WireInputTool_toggle", "Toggle" )
	language.Add( "WireInputTool_value_on", "Value On:" )
	language.Add( "WireInputTool_value_off", "Value Off:" )
	TOOL.Information = { { name = "left", text = "Create/Update " .. TOOL.Name } }
end
WireToolSetup.BaseLang()
WireToolSetup.SetupMax( 20 )

if SERVER then
	ModelPlug_Register("Numpad")

	function TOOL:GetConVars()
		return self:GetClientNumber( "keygroup" ), self:GetClientNumber( "toggle" ), self:GetClientNumber( "value_off" ), self:GetClientNumber( "value_on" )
	end
end

TOOL.ClientConVar = {
	model = "models/beer/wiremod/numpad.mdl",
	modelsize = "",
	keygroup = 7,
	toggle = 0,
	value_off = 0,
	value_on = 1,
}

function TOOL.BuildCPanel(panel)
	WireToolHelpers.MakePresetControl(panel, "wire_input")
	WireToolHelpers.MakeModelSizer(panel, "wire_input_modelsize")
	ModelPlug_AddToCPanel(panel, "Numpad", "wire_input", true)
	panel:AddControl("Numpad", {
		Label = "#WireInputTool_keygroup",
		Command = "wire_input_keygroup"
	})
	panel:CheckBox("#WireInputTool_toggle", "wire_input_toggle")
	panel:NumSlider("#WireInputTool_value_on", "wire_input_value_on", -10, 10, 1)
	panel:NumSlider("#WireInputTool_value_off", "wire_input_value_off", -10, 10, 1)
end
