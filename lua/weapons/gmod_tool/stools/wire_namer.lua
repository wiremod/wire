TOOL.Name = "Namer"
TOOL.Category = "Tools"
TOOL.Tab = "Wire"

if CLIENT then
	language.Add("tool.wire_namer.name", "Namer")
	language.Add("tool.wire_namer.desc", "Names wire components.")
	language.Add("tool.wire_namer.left", "Set name")
	language.Add("tool.wire_namer.right", "Copy name")
	language.Add("tool.wire_namer.reload", "Reset name")
	TOOL.Information = { { name = "left" }, { name = "right" }, { name = "reload" } }

	WireToolSetup.setToolMenuIcon("icon16/tag_blue.png")
end

TOOL.ClientConVar["name"] = ""

local function SetName(ply, ent, data)
	if data and data.name then
		ent:SetNW2String("WireName", data.name)
		duplicator.StoreEntityModifier(ent, "WireName", data)
	else
		local name = ent:GetNW2String("WireName", false)

		if name then
			ent:SetNW2String("WireName", nil)
		end

		duplicator.ClearEntityModifier(ent, "WireName")
	end
end

duplicator.RegisterEntityModifier("WireName", SetName)

function TOOL:LeftClick(trace)
	local ent = trace.Entity
	if not ent:IsValid() or not ent.IsWire then return end
	if CLIENT then return true end

	local name = self:GetClientInfo("name")
	SetName(nil, ent, { name = name })

	return true
end

function TOOL:RightClick(trace)
	local ent = trace.Entity
	if not ent:IsValid() or not ent.IsWire then return end
	if CLIENT then return true end

	WireLib.SetConvar(self:GetOwner(), "wire_namer_name", ent:GetNW2String("WireName"))

	return true
end

function TOOL:Reload(trace)
	local ent = trace.Entity
	if not ent:IsValid() or not ent.IsWire then return end
	if CLIENT then return true end

	SetName(nil, ent, {})

	return true
end

function TOOL.BuildCPanel(panel)
	panel:TextEntry("Name", "wire_namer_name")
end
