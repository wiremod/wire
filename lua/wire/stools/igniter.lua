WireToolSetup.setCategory( "Physics" )
WireToolSetup.open( "igniter", "Igniter", "gmod_wire_igniter", nil, "Igniters" )

if CLIENT then
	language.Add( "tool.wire_igniter.name", "Igniter Tool (Wire)" )
	language.Add( "tool.wire_igniter.desc", "Spawns a constant igniter prop for use with the wire system." )
	language.Add( "WireIgniterTool_trgply", "Allow Player Igniting" )
	language.Add( "WireIgniterTool_Range", "Max Range:" )
	TOOL.Information = { { name = "left", text = "Create/Update " .. TOOL.Name } }
end
WireToolSetup.BaseLang()
WireToolSetup.SetupMax( 20 )

if SERVER then
	CreateConVar('sbox_wire_igniters_maxlen', 30)
	CreateConVar('sbox_wire_igniters_allowtrgply',1)

	function TOOL:GetConVars()
		return self:GetClientNumber( "trgply" )~=0, self:GetClientNumber("range")
	end
end

TOOL.ClientConVar = {
	trgply	= 0,
	range	= 2048,
	model	= "models/jaanus/wiretool/wiretool_siren.mdl",
}

function TOOL.BuildCPanel(panel)
	WireToolHelpers.MakePresetControl(panel, "wire_igniter")
	WireDermaExts.ModelSelect(panel, "wire_igniter_Model", list.Get( "Wire_Laser_Tools_Models" ), 1, true)
	panel:CheckBox("#WireIgniterTool_trgply", "wire_igniter_trgply")
	panel:NumSlider("#WireIgniterTool_Range", "wire_igniter_range", 1, 10000, 0)
end
