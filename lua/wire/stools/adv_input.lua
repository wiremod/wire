WireToolSetup.setCategory( "Input, Output/Keyboard Interaction" )
WireToolSetup.open( "adv_input", "Adv. Input", "gmod_wire_adv_input", nil, "Adv. Inputs" )

if CLIENT then
	language.Add( "tool.wire_adv_input.name", "Adv. Input Tool (Wire)" )
	language.Add( "tool.wire_adv_input.desc", "Spawns a adv. input for use with the wire system." )
	language.Add( "WireAdvInputTool_keymore", "Increase:" )
	language.Add( "WireAdvInputTool_keyless", "Decrease:" )
	language.Add( "WireAdvInputTool_toggle", "Toggle" )
	language.Add( "WireAdvInputTool_value_min", "Minimum:" )
	language.Add( "WireAdvInputTool_value_max", "Maximum:" )
	language.Add( "WireAdvInputTool_value_start", "Start at:" )
	language.Add( "WireAdvInputTool_speed", "Change per second:" )
	TOOL.Information = { { name = "left", text = "Create/Update " .. TOOL.Name } }
end
WireToolSetup.BaseLang()
WireToolSetup.SetupMax( 20 )

if SERVER then
	ModelPlug_Register("Numpad")

	function TOOL:GetConVars()
		return self:GetClientNumber( "keymore" ), self:GetClientNumber( "keyless" ), self:GetClientNumber( "toggle" ),
			self:GetClientNumber( "value_min" ), self:GetClientNumber( "value_max" ), self:GetClientNumber( "value_start" ),
			self:GetClientNumber( "speed" )
	end

	-- Uses default WireToolObj:MakeEnt's WireLib.MakeWireEnt function
end

TOOL.ClientConVar = {
	model = "models/beer/wiremod/numpad.mdl",
	modelsize = "",
	keymore = "3",
	keyless = "1",
	toggle = "0",
	value_min = "0",
	value_max = "10",
	value_start = "5",
	speed = "1",
}

function TOOL.BuildCPanel( panel )
	WireToolHelpers.MakeModelSizer(panel, "wire_adv_input_modelsize")
	ModelPlug_AddToCPanel(panel, "Numpad", "wire_adv_input", true)
	panel:AddControl( "Numpad", {Label = "#WireAdvInputTool_keymore", Command = "wire_adv_input_keymore"})
	panel:AddControl( "Numpad", {Label = "#WireAdvInputTool_keyless", Command = "wire_adv_input_keyless"})
	panel:CheckBox("#WireAdvInputTool_toggle", "wire_adv_input_toggle")
	panel:NumSlider("#WireAdvInputTool_value_min", "wire_adv_input_value_min", -50, 50, 0)
	panel:NumSlider("#WireAdvInputTool_value_max", "wire_adv_input_value_max", -50, 50, 0)
	panel:NumSlider("#WireAdvInputTool_value_start", "wire_adv_input_value_start", -50, 50, 0)
	panel:NumSlider("#WireAdvInputTool_speed", "wire_adv_input_speed", 0.1, 50, 1)
end
