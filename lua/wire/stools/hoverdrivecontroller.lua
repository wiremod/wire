WireToolSetup.setCategory( "Physics" )
WireToolSetup.open( "hoverdrivecontroller", "Hoverdrive Controller", "gmod_wire_hoverdrivecontroller", nil, "Hoverdrive Controllers" )

if ( CLIENT ) then
	language.Add( "Tool.wire_hoverdrivecontroller.name", "Hoverdrive Controller Tool" )
	language.Add( "Tool.wire_hoverdrivecontroller.desc", "Spawns a Hoverdrive Controller." )
	language.Add( "Tool.wire_hoverdrivecontroller.0", "Primary: Create Hoverdrive Controller, Reload: Change Hoverdrive Controller Model" )
	language.Add( "Tool_wire_hoverdrivecontroller_effects", "Toggle effects" )
	language.Add( "Tool_wire_hoverdrivecontroller_sounds", "Toggle sounds (Also has an input)" )
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
		WireDermaExts.ModelSelect(panel, "wire_hoverdrivecontroller_model", list.Get( "WireHoverdriveModels" ), 4)
		panel:CheckBox("#Tool_wire_hoverdrivecontroller_effects","wire_hoverdrivecontroller_effects")
		panel:CheckBox("#Tool_wire_hoverdrivecontroller_sounds","wire_hoverdrivecontroller_sounds")
	end
end

function TOOL:Reload( trace )
	if not IsValid(trace.Entity) then return end
	if CLIENT then
		RunConsoleCommand("wire_hoverdrivecontroller_model", trace.Entity:GetModel())
	else
		self:GetOwner():ChatPrint("Hoverdrive Controller model set to: " .. trace.Entity:GetModel())
	end
	return true
end
