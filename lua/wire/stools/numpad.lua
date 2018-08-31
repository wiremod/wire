WireToolSetup.setCategory( "Input, Output/Keyboard Interaction" )
WireToolSetup.open( "numpad", "Numpad", "gmod_wire_numpad", nil, "Numpads" )

if CLIENT then
	language.Add( "Tool.wire_numpad.name", "Wired Numpad Tool (Wire)" )
	language.Add( "Tool.wire_numpad.desc", "Spawns a numpad input for use with the wire system." )
	language.Add( "WireNumpadTool_toggle", "Toggle" )
	language.Add( "WireNumpadTool_value_on", "Value On:" )
	language.Add( "WireNumpadTool_value_off", "Value Off:" )
	TOOL.Information = { { name = "left", text = "Create/Update " .. TOOL.Name } }
end
WireToolSetup.BaseLang()
WireToolSetup.SetupMax( 20 )

if SERVER then
	ModelPlug_Register("Numpad")

	function TOOL:GetConVars()
		return self:GetClientNumber( "toggle" )==1, self:GetClientNumber( "value_off" ), self:GetClientNumber( "value_on" )
	end
end

TOOL.ClientConVar = {
	model = "models/beer/wiremod/numpad.mdl",
	modelsize = "",
	toggle = 0,
	value_off = 0,
	value_on = 0,
}

function TOOL.BuildCPanel(panel)
	WireToolHelpers.MakePresetControl(panel, "wire_numpad")
	WireToolHelpers.MakeModelSizer(panel, "wire_numpad_modelsize")
	ModelPlug_AddToCPanel(panel, "Numpad", "wire_numpad", true)
	panel:CheckBox("#WireNumpadTool_toggle","wire_numpad_toggle")
	panel:NumSlider("#WireNumpadTool_value_on","wire_numpad_value_on",-10,10,0)
	panel:NumSlider("#WireNumpadTool_value_off","wire_numpad_value_off",-10,10,0)
end
