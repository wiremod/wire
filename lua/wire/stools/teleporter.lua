WireToolSetup.setCategory( "Physics" )
WireToolSetup.open( "teleporter", "Teleporter", "gmod_wire_teleporter", nil, "Teleporters" )

if ( CLIENT ) then
	language.Add( "Tool.wire_teleporter.name", "Teleporter Tool" )
	language.Add( "Tool.wire_teleporter.desc", "Spawns a Wire Teleporter" )
	language.Add( "Tool.wire_teleporter.effects", "Toggle effects" )
	language.Add( "Tool.wire_teleporter.sounds", "Toggle sounds (Also has an input)" )
	TOOL.Information = {
		{ name = "left", text = "Create/Update " .. TOOL.Name },
		{ name = "reload", text = "Copy model" },
	}
end
WireToolSetup.BaseLang()
WireToolSetup.SetupMax(3)

TOOL.ClientConVar = {
	model = "models/props_c17/utilityconducter001.mdl",
	sounds = 1,
	effects = 1
}

if (SERVER) then
	function TOOL:GetConVars()
		return self:GetClientNumber("sounds") ~= 0, self:GetClientNumber("effects") ~= 0
	end
else
	function TOOL.BuildCPanel(panel)
		WireDermaExts.ModelSelect(panel, "wire_teleporter_model", list.Get( "WireTeleporterModels" ), 4)
		panel:CheckBox("#Tool.wire_teleporter.effects","wire_teleporter_effects")
		panel:CheckBox("#Tool.wire_teleporter.sounds","wire_teleporter_sounds")
	end
end

function TOOL:Reload( trace )
	if not IsValid(trace.Entity) then return end
	if CLIENT then
		RunConsoleCommand("wire_teleporter_model", trace.Entity:GetModel())
	else
		self:GetOwner():ChatPrint("Teleporter model set to: " .. trace.Entity:GetModel())
	end
	return true
end
