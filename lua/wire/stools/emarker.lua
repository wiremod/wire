WireToolSetup.setCategory("Detection")
WireToolSetup.open("emarker", "Entity Marker", "gmod_wire_emarker", nil, "Entity Markers")

if CLIENT then
	language.Add("tool.wire_emarker.name", "Entity Marker Tool (Wire)")
	language.Add("tool.wire_emarker.desc", "Spawns an Entity Marker for use with the wire system.")
end

WireToolSetup.BaseLang()
WireToolSetup.SetupMax(30)

TOOL.ClientConVar = {
	model = "models/jaanus/wiretool/wiretool_siren.mdl",
}

WireToolSetup.SetupLinking()

function TOOL.BuildCPanel(panel)
	WireDermaExts.ModelSelect(panel, "wire_emaker_model", list.Get("Wire_Misc_Tools_Models"), nil, true)
end
