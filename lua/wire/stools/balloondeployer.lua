WireToolSetup.setCategory("Physics")
WireToolSetup.open("balloondeployer", "Balloon Deployer", "gmod_wire_balloondeployer", nil, "Balloon Deployers")

if CLIENT then
	language.Add("tool.wire_balloondeployer.name", "Balloon Deployer Tool (Wire)")
	language.Add("tool.wire_balloondeployer.desc", "Spawns a balloon deployer for use with the wire system.")
	TOOL.Information = { { name = "left", text = "Create/Update " .. TOOL.Name } }
end

WireToolSetup.BaseLang()
WireToolSetup.SetupMax(5)

if SERVER then
	function TOOL:GetConVars()
		return self:GetClientNumber("force"), self:GetClientNumber("length"), self:GetClientBool("weld"), self:GetClientBool("popable"), self:GetClientNumber("ballontype"), self:GetClientInfo("model")
	end
end

TOOL.ClientConVar = {
	force = 500,
	length = 64,
	weld = 0,
	popable = 1,
	ballontype = 1,
	model = "models/props_junk/propanecanister001a.mdl"
}

function TOOL.BuildCPanel(panel)
	WireToolHelpers.MakePresetControl(panel, "wire_balloondeployer")

	panel:NumSlider("Force:", "wire_balloondeployer_force", 1, 10000, 0)
	panel:NumSlider("Length:", "wire_balloondeployer_length", 1, 10000, 0)
	panel:NumSlider("Ballon Type:", "wire_balloondeployer_ballontype", 1, 6, 0)
	panel:CheckBox("Weld", "wire_balloondeployer_weld")
	panel:CheckBox("Popable", "wire_balloondeployer_popable")
end
