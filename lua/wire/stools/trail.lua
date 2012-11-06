WireToolSetup.setCategory( "Physics" )
WireToolSetup.open( "trail", "Trail", "gmod_wire_trail", WireToolMakeTrail )

if CLIENT then
	language.Add( "tool.wire_trail.name", "Trail Tool (Wire)" )
	language.Add( "tool.wire_trail.desc", "Spawns a wired trail." )
	language.Add( "tool.wire_trail.0", "Primary: Create/Update trail" )
	language.Add( "WireTrailTool_trail", "Trail:" )
	language.Add( "WireTrailTool_mat", "Material:" )
	language.Add( "sboxlimit_wire_trails", "You've hit trails limit!" )
end
WireToolSetup.BaseLang("Trails")

if SERVER then
	CreateConVar('sbox_maxwire_trails', 20)
end

TOOL.ClientConVar = {
	material = ""
}

TOOL.Model = "models/jaanus/wiretool/wiretool_range.mdl"

function TOOL.BuildCPanel(panel)
	WireToolHelpers.MakePresetControl(panel, "wire_trail")
	panel:AddControl( "MatSelect", { Height = "2", Label = "#WireTrailTool_mat", ConVar = "wire_trail_material", Options = list.Get( "trail_materials" ), ItemWidth = 64, ItemHeight = 64 } )
end
