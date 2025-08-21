WireToolSetup.setCategory("Visuals")
WireToolSetup.open("materializer", "Materializer", "gmod_wire_materializer", nil, "Materializers")

if CLIENT then
	language.Add("tool.wire_materializer.name", "Materializer Tool (Wire)")
	language.Add("tool.wire_materializer.desc", "Spawns a materializer for use with the wire system.")
	language.Add("tool.wire_materializer.maxrange", "Range:")
	TOOL.Information = { { name = "left", text = "Create/Update " .. TOOL.Name } }

	WireToolSetup.setToolMenuIcon("icon16/picture.png")
end

WireToolSetup.BaseLang()
WireToolSetup.SetupMax(20)

if SERVER then
	function TOOL:GetConVars()
		return self:GetClientInfo("material"), self:GetClientNumber("range"), self:GetClientInfo("model")
	end
end

TOOL.ClientConVar = {
	material = "debug/env_cubemap_model",
	model = "models/jaanus/wiretool/wiretool_siren.mdl",
	range = 2048
}

function TOOL.BuildCPanel(panel)
	WireToolHelpers.MakePresetControl(panel, "wire_materializer")
	WireDermaExts.ModelSelect(panel, "wire_materializer_model", list.Get("Wire_Laser_Tools_Models"), 1, true)

	panel:NumSlider("#tool.wire_materializer.maxrange", "wire_materializer_range", 1, 10000, 0)

	local filter = panel:TextEntry("#spawnmenu.quick_filter_tool")
	filter:SetUpdateOnType(true)

	local materials = {}

	for _, material in ipairs(list.Get("OverrideMaterials")) do
		if not materials[material] then
			materials[material] = material
		end
	end

	local matlist = panel:MatSelect("wire_materializer_material", materials, true, 0.25, 0.25)

	function filter:OnValueChange(value)
		for _, pnl in ipairs(matlist.Controls) do
			if string.find(string.lower(pnl.Value), string.lower(value), nil, true) then
				pnl:SetVisible(true)
			else
				pnl:SetVisible(false)
			end
		end

		matlist:InvalidateChildren()
		panel:InvalidateChildren()
	end
end
