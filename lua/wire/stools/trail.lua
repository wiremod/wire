WireToolSetup.setCategory( "Visuals" )
WireToolSetup.open( "trail", "Trail", "gmod_wire_trail", nil, "Trails" )

if CLIENT then
	language.Add( "tool.wire_trail.name", "Trail Tool (Wire)" )
	language.Add( "tool.wire_trail.desc", "Spawns a wired trail." )
	language.Add( "WireTrailTool_trail", "Trail:" )
	language.Add( "WireTrailTool_mat", "Material:" )
	TOOL.Information = { { name = "left", text = "Create/Update " .. TOOL.Name } }
end
WireToolSetup.BaseLang()
WireToolSetup.SetupMax( 20 )

TOOL.ClientConVar = {
	material = ""
}
TOOL.Model = "models/jaanus/wiretool/wiretool_range.mdl"

if SERVER then
	function TOOL:GetConVars() return { Material = self:GetClientInfo("material", "sprites/obsolete") } end
end

function TOOL.BuildCPanel(panel)
	WireToolHelpers.MakePresetControl(panel, "wire_trail")
	panel:AddControl( "MatSelect", { Height = "2", ConVar = "wire_trail_material", Options = list.Get( "trail_materials" ), ItemWidth = 64, ItemHeight = 64 } )
end
