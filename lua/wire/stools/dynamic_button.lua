WireToolSetup.setCategory( "I/O" )
WireToolSetup.open( "dynamic_button", "Dynamic Button", "gmod_wire_dynamic_button", nil, "Dynamic Buttons" )

if CLIENT then
	language.Add( "tool.wire_dynamic_button.name", "Dynamic Button Tool (Wire)" )
	language.Add( "tool.wire_dynamic_button.desc", "Spawns a dynamic button for use with the wire system." )
	language.Add( "tool.wire_dynamic_button.0", "Primary: Create/Update Dynamic Button" )
	language.Add( "WireDynamicButtonTool_toggle", "Toggle" )
	language.Add( "WireDynamicButtonTool_entityout", "Output Entity" )
	language.Add( "WireDynamicButtonTool_value_on", "Value On:" )
	language.Add( "WireDynamicButtonTool_value_off", "Value Off:" )
end
WireToolSetup.BaseLang("Dynamic Buttons")
WireToolSetup.SetupMax( 20, TOOL.Mode.."s" , "You've hit the Wire "..TOOL.PluralName.." limit!" )

if SERVER then
	function TOOL:GetConVars() 
		return self:GetClientNumber( "toggle" ) ~= 0, self:GetClientNumber( "value_off" ), self:GetClientNumber( "value_on" ), 
			self:GetClientInfo( "description" ), self:GetClientNumber( "entityout" ) ~= 0, self:GetClientInfo( "material_off" ), self:GetClientInfo( "material_on" ), 
			self:GetClientNumber( "on_r" ), self:GetClientNumber( "on_g" ), self:GetClientNumber( "on_b" ), 
			self:GetClientNumber( "off_r" ), self:GetClientNumber( "off_g" ), self:GetClientNumber( "off_b" )
	end

	function TOOL:MakeEnt( ply, model, Ang, trace )
		return MakeWireDynamicButton( ply, trace.HitPos, Ang, model, self:GetConVars() )
	end
end

TOOL.ClientConVar = {
	model = "models/bull/ranger.mdl",
	model_category = "dynamic_button",
	toggle = "0",
	value_off = "0",
	value_on = "1",
	description = "",
	entityout = "0",
	material_on  = "bull/dynamic_button_1",
	material_off = "bull/dynamic_button_0",
	on_r = 0,
	on_g = 255,
	on_b = 0,
	off_r = 255,
	off_g = 0,
	off_b = 0
}

function TOOL.BuildCPanel(panel)
	WireToolHelpers.MakePresetControl(panel, "wire_dynamic_button")

	ModelPlug_AddToCPanel_Multi(
		panel,
		{	dynamic_button = "Normal",
			dynamic_button_small = "Small"
		},
		"wire_dynamic_button", "#Dynamic_Button_Model", 1.1
	)

	panel:NumSlider("#WireDynamicButtonTool_value_on", "wire_dynamic_button_value_on", -10, 10, 1)
	panel:AddControl("ListBox", {
		Label = "WireDynamicButtonMaterialsOn",
		Options = list.Get( "WireDynamicButtonMaterialsOn" )
	} )

	panel:AddControl("Color", {
		Label = "#ToolWireDynamicButton_colour_on",
		Red = "wire_dynamic_button_on_r",
		Green = "wire_dynamic_button_on_g",
		Blue = "wire_dynamic_button_on_b",
	})

	panel:NumSlider("#WireDynamicButtonTool_value_off", "wire_dynamic_button_value_off", -10, 10, 1)
	panel:AddControl("ListBox", {
		Label = "#WireDynamicButtonTool_entityout",
		Options = list.Get( "WireDynamicButtonMaterialsOff" )
	} )

	panel:AddControl("Color", {
		Label = "#ToolWireDynamicButton_colour_off",
		Red = "wire_dynamic_button_off_r",
		Green = "wire_dynamic_button_off_g",
		Blue = "wire_dynamic_button_off_b",
	})

	panel:CheckBox("#WireDynamicButtonTool_toggle", "wire_dynamic_button_toggle")
	panel:CheckBox("#WireDynamicButtonTool_entityout", "wire_dynamic_button_entityout")
end