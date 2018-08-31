WireToolSetup.setCategory( "Input, Output/Data Transfer" )
WireToolSetup.open( "radio", "Radio", "gmod_wire_radio", nil, "Radios" )

if ( CLIENT ) then
	language.Add( "Tool.wire_radio.name", "Radio Tool (Wire)" )
	language.Add( "Tool.wire_radio.desc", "Spawns a radio for use with the wire system." )
	language.Add( "WireRadioTool_channel", "Channel:" )
	language.Add( "WireRadioTool_values", "Values:" )
	language.Add( "WireRadioTool_secure", "Secure" )
	TOOL.Information = { { name = "left", text = "Create/Update " .. TOOL.Name } }
end
WireToolSetup.BaseLang()
WireToolSetup.SetupMax( 20 )

if (SERVER) then
	ModelPlug_Register("radio")
	function TOOL:GetConVars()
		return self:GetClientInfo("channel"), self:GetClientNumber("values"), self:GetClientNumber("secure") ~= 0
	end
end

TOOL.ClientConVar = {
	channel = 1,
	values  = 4,
	secure  = 0,
	model   = "models/props_lab/binderblue.mdl"
}

function TOOL.BuildCPanel(panel)
	WireToolHelpers.MakePresetControl(panel, "wire_radio")
	WireDermaExts.ModelSelect(panel, "wire_radio_model", list.Get( "Wire_radio_Models" ), 2, true)

	panel:NumSlider("#WireRadioTool_channel","wire_radio_channel",1,30,0)
	panel:NumSlider("#WireRadioTool_values","wire_radio_values",1,20,0)
	panel:CheckBox("#WireRadioTool_secure","wire_radio_secure")
end
