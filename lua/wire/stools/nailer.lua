WireToolSetup.setCategory( "Physics/Constraints" )
WireToolSetup.open( "nailer", "Nailer", "gmod_wire_nailer", nil, "Nailers" )

if ( CLIENT ) then
	language.Add( "Tool.wire_nailer.name", "Nailer Tool (Wire)" )
	language.Add( "Tool.wire_nailer.desc", "Spawns a constant nailer prop for use with the wire system." )
	TOOL.Information = { { name = "left", text = "Create/Update " .. TOOL.Name } }
end
WireToolSetup.BaseLang()
WireToolSetup.SetupMax( 20 )

if (SERVER) then
	function TOOL:GetConVars()
		return self:GetClientNumber( "forcelim" ), self:GetClientNumber( "range" ), self:GetClientNumber( "beam" )==1
	end
end

TOOL.ClientConVar = {
	model = "models/jaanus/wiretool/wiretool_siren.mdl",
	forcelim = "0",
	range = 100,
	beam = 1,
}

function TOOL.BuildCPanel(panel)
	WireToolHelpers.MakePresetControl(panel, "wire_nailer")
	ModelPlug_AddToCPanel(panel, "Laser_Tools", "wire_nailer", true)
	panel:NumSlider("#Force Limit", "wire_nailer_forcelim", 0, 10000, 0)
	panel:NumSlider("Range", "wire_nailer_range", 1, 2048, 0)
	panel:CheckBox("Show Beam", "wire_nailer_beam")
end
