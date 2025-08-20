WireToolSetup.setCategory("Visuals")
WireToolSetup.open("painter", "Painter", "gmod_wire_painter", nil, "Painters")

if CLIENT then
	language.Add("tool.wire_painter.name", "Painter Tool (Wire)")
	language.Add("tool.wire_painter.desc", "Spawns a painter for use with the wire system.")
	language.Add("tool.wire_painter.maxrange", "Range:")
	TOOL.Information = { { name = "left", text = "Create/Update " .. TOOL.Name } }

	WireToolSetup.setToolMenuIcon("icon16/paintcan.png")
end

WireToolSetup.BaseLang()
WireToolSetup.SetupMax(20)

if SERVER then
	function TOOL:GetConVars()
		return self:GetClientInfo("decal"), self:GetClientNumber("range"), self:GetClientInfo("model")
	end
end

TOOL.ClientConVar = {
	decal	= "Blood",
	model	= "models/jaanus/wiretool/wiretool_siren.mdl",
	range	= 2048
}

function TOOL.BuildCPanel(panel)
	WireToolHelpers.MakePresetControl(panel, "wire_painter")
	WireDermaExts.ModelSelect(panel, "wire_painter_model", list.Get("Wire_Laser_Tools_Models"), 1, true)

	local options = {}

	for id, str in ipairs(list.Get("PaintMaterials")) do
		if not table.HasValue(options, str) then
			table.insert(options, str)
		end
	end

	table.sort(options)

	local listbox = vgui.Create("DListView")
	listbox:SetMultiSelect(false)
	listbox:AddColumn("#tool.paint.texture")
	listbox:SetTall(17 + #options * 17)
	listbox:SortByColumn(1, false)

	for _, decal in ipairs(options) do
		local line = listbox:AddLine(decal)
		line.decal = decal
	end

	function listbox:OnRowSelected(index, row)
		RunConsoleCommand("wire_painter_decal", row.decal)
	end

	local wire_painter_decal = GetConVar("wire_painter_decal")

	function listbox:Think()
		local value = wire_painter_decal:GetString()

		if listbox.m_strConVarValue ~= value then
			for _, line in ipairs(listbox:GetLines()) do
				if value == line.decal then
					line:SetSelected(true)
				else
					line:SetSelected(false)
				end
			end

			listbox.m_strConVarValue = value
		end
	end

	panel:AddItem(listbox)
	panel:NumSlider("#tool.wire_painter.maxrange", "wire_painter_range", 1, 10000, 0)
end
