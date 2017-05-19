WireToolSetup.setCategory( "Input, Output" )
WireToolSetup.open( "button", "Button", "gmod_wire_button", nil, "Buttons" )

if CLIENT then
	language.Add( "tool.wire_button.name", "Button Tool (Wire)" )
	language.Add( "tool.wire_button.desc", "Spawns a button for use with the wire system." )
	language.Add( "WireButtonTool_toggle", "Toggle" )
	language.Add( "WireButtonTool_entityout", "Output Entity" )
	language.Add( "WireButtonTool_value_on", "Value On:" )
	language.Add( "WireButtonTool_value_off", "Value Off:" )
	TOOL.Information = { { name = "left", text = "Create/Update " .. TOOL.Name } }
end
WireToolSetup.BaseLang()
WireToolSetup.SetupMax( 20 )

if SERVER then
	ModelPlug_Register("button")

	function TOOL:GetConVars()
		return self:GetClientNumber( "toggle" ) ~= 0, self:GetClientNumber( "value_off" ), self:GetClientNumber( "value_on" ),
			self:GetClientInfo( "description" ), self:GetClientNumber( "entityout" ) ~= 0
	end

	-- Uses default WireToolObj:MakeEnt's WireLib.MakeWireEnt function
end

TOOL.ClientConVar = {
	model = "models/props_c17/clock01.mdl",
	model_category = "button",
	toggle = "0",
	value_off = "0",
	value_on = "1",
	description = "",
	entityout = "0"
}

function TOOL.BuildCPanel(panel)
	WireToolHelpers.MakePresetControl(panel, "wire_button")

	ModelPlug_AddToCPanel_Multi(
		panel,
		{	button = "Normal",
			button_small = "Small"
		},
		"wire_button", "#Button_Model", 6
	)
	panel:CheckBox("#WireButtonTool_toggle", "wire_button_toggle")
	panel:CheckBox("#WireButtonTool_entityout", "wire_button_entityout")
	panel:NumSlider("#WireButtonTool_value_on", "wire_button_value_on", -10, 10, 1)
	panel:NumSlider("#WireButtonTool_value_off", "wire_button_value_off", -10, 10, 1)
end
