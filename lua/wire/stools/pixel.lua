WireToolSetup.setCategory( "Display" )
WireToolSetup.open( "pixel", "Pixel", "gmod_wire_pixel", nil, "Pixels" )

if CLIENT then
	language.Add( "tool.wire_pixel.name", "Pixel Tool (Wire)" )
	language.Add( "tool.wire_pixel.desc", "Spawns a Pixel for use with the wire system." )
	language.Add( "tool.wire_pixel.0", "Primary: Create Pixel" )
end
WireToolSetup.BaseLang()
WireToolSetup.SetupMax( 20 )

if SERVER then
	ModelPlug_Register("pixel")
end

TOOL.NoLeftOnClass = true -- no update ent function needed
TOOL.ClientConVar = {
	model  = "models/jaanus/wiretool/wiretool_siren.mdl",
}

function TOOL.BuildCPanel(panel)
	WireDermaExts.ModelSelect(panel, "wire_pixel_model", list.Get("Wire_pixel_Models"), 3, true)
end
