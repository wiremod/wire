WireToolSetup.setCategory( "Physics" )
WireToolSetup.open( "igniter", "Igniter", "gmod_wire_igniter", WireToolMakeIgniter, "Igniters" )

if CLIENT then
	language.Add( "tool.wire_igniter.name", "Igniter Tool (Wire)" )
	language.Add( "tool.wire_igniter.desc", "Spawns a constant igniter prop for use with the wire system." )
	language.Add( "tool.wire_igniter.0", "Primary: Create/Update Igniter" )
	language.Add( "WireIgniterTool_trgply", "Allow Player Igniting" )
	language.Add( "WireIgniterTool_Range", "Max Range:" )
end
WireToolSetup.BaseLang("Igniters")
WireToolSetup.SetupMax( 20, TOOL.Mode.."s" , "You've hit the Wire "..TOOL.PluralName.." limit!" )

if SERVER then
	CreateConVar('sbox_wire_igniters_maxlen', 30)
	CreateConVar('sbox_wire_igniters_allowtrgply',1)
end

TOOL.ClientConVar = {
	trgply	= 0,
	Range	= 2048,
	model	= "models/jaanus/wiretool/wiretool_siren.mdl",
}

local ignitermodels = {
	["models/jaanus/wiretool/wiretool_beamcaster.mdl"] = {},
	["models/jaanus/wiretool/wiretool_siren.mdl"] = {}
}

function TOOL.BuildCPanel(panel)
	WireToolHelpers.MakePresetControl(panel, "wire_igniter")
	WireDermaExts.ModelSelect(panel, "wire_igniter_Model", ignitermodels, 1, true)
	panel:CheckBox("#WireIgniterTool_trgply", "wire_igniter_trgply")
	panel:NumSlider("#WireIgniterTool_Range", "wire_igniter_Range", 1, 10000, 0)
end
