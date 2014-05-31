WireToolSetup.setCategory( "Input, Output/Data Transfer" )
WireToolSetup.open( "twoway_radio", "Two-way Radio", "gmod_wire_twoway_radio", nil, "Two-way Radios" )

if ( CLIENT ) then
	language.Add( "Tool.wire_twoway_radio.name", "Two-Way Radio Tool (Wire)" )
	language.Add( "Tool.wire_twoway_radio.desc", "Spawns a two-way radio for use with the wire system." )
	language.Add( "Tool.wire_twoway_radio.0", "Primary: Create/Update Two-way Radio\nSecondary: Select a two-way radio to pair up with another two-way radio." )
	language.Add( "Tool.wire_twoway_radio.1", "Select the second two-way radio." );
end
WireToolSetup.BaseLang()
WireToolSetup.SetupMax( 20 )

if (SERVER) then
	ModelPlug_Register("radio")
end

TOOL.ClientConVar[ "model" ] = "models/props_lab/binderblue.mdl"

WireToolSetup.SetupLinking(true)

function TOOL.BuildCPanel(panel)
	WireDermaExts.ModelSelect(panel, "wire_twoway_radio_model", list.Get( "Wire_radio_Models" ), 2, true)
end
