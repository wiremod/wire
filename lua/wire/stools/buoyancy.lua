WireToolSetup.setCategory("Physics/Force")
WireToolSetup.open("buoyancy", "Buoyancy", "gmod_wire_buoyancy", nil, "Buoyancys")

if CLIENT then
	language.Add("tool.wire_buoyancy.name", "Buoyancy Tool (Wire)")
	language.Add("tool.wire_buoyancy.desc", "Spawns a Buoyancy Controller for use with the wire system.")
end

WireToolSetup.BaseLang()
WireToolSetup.SetupMax(10)

if SERVER then
	function TOOL:GetConVars()
		return self:GetClientNumber("percent"), self:GetClientInfo("model")
	end
end

TOOL.ClientConVar = {
	percent = 1,
	model = "models/jaanus/wiretool/wiretool_siren.mdl"
}

WireToolSetup.SetupLinking()

function TOOL.BuildCPanel(panel)
	WireToolHelpers.MakePresetControl(panel, "wire_buoyancy")
	WireDermaExts.ModelSelect(panel, "wire_buoyancy_model", list.Get("Wire_Laser_Tools_Models"), 1, true)
	panel:NumSlider("Percent", "wire_buoyancy_percent", -10, 10)
end
