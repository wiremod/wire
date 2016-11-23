WireToolSetup.setCategory( "Detection" )
WireToolSetup.open( "las_receiver", "Laser Pointer Receiver", "gmod_wire_las_receiver", nil, "Laser Pointer Receivers" )

if CLIENT then
	language.Add( "Tool.wire_las_receiver.name", "Laser Receiver Tool (Wire)" )
	language.Add( "Tool.wire_las_receiver.desc", "Spawns a constant laser receiver prop for use with the wire system." )
	TOOL.Information = { { name = "left", text = "Create/Update " .. TOOL.Name } }
end
WireToolSetup.BaseLang()
WireToolSetup.SetupMax( 20 )

TOOL.ClientConVar = {
	model = "models/jaanus/wiretool/wiretool_range.mdl",
}

function TOOL.BuildCPanel(panel)
	ModelPlug_AddToCPanel(panel, "Misc_Tools", "wire_las_receiver")
end
