WireToolSetup.setCategory("Detection")
WireToolSetup.open("adv_emarker", "Adv Entity Marker", "gmod_wire_adv_emarker", nil, "Adv Entity Markers")

if CLIENT then
	language.Add("tool.wire_adv_emarker.name", "Adv Entity Marker Tool (Wire)")
	language.Add("tool.wire_adv_emarker.desc", "Spawns an Adv Entity Marker for use with the wire system.")
end

WireToolSetup.BaseLang()
WireToolSetup.SetupMax(10)

TOOL.ClientConVar = {
	model = "models/jaanus/wiretool/wiretool_siren.mdl",
}

WireToolSetup.SetupLinking()

function TOOL.BuildCPanel(panel)
	WireDermaExts.ModelSelect(panel, "wire_adv_emarker_model", list.Get("Wire_Misc_Tools_Models"), nil, true)
end
