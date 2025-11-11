WireToolSetup.setCategory("Physics/Constraints")
WireToolSetup.open("freezer", "Freezer", "gmod_wire_freezer", nil, "Freezers")

if CLIENT then
	language.Add("tool.wire_freezer.name", "Freezer Tool (Wire)")
	language.Add("tool.wire_freezer.desc", "Spawns a Freezer Controller for use with the wire system.")
end

WireToolSetup.BaseLang()
WireToolSetup.SetupMax(10)

TOOL.ClientConVar = {
	model = "models/jaanus/wiretool/wiretool_siren.mdl",
}

WireToolSetup.SetupLinking()

function TOOL.BuildCPanel(panel)
	WireDermaExts.ModelSelect(panel, "wire_freezer_model", list.Get("Wire_Misc_Tools_Models"), nil, true)
end
