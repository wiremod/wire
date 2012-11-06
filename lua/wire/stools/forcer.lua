WireToolSetup.setCategory( "Physics" )
WireToolSetup.open( "forcer", "Forcer", "gmod_wire_forcer", WireToolMakeForcer )

if CLIENT then
	language.Add( "tool.wire_forcer.name", "Forcer Tool (Wire)" )
	language.Add( "tool.wire_forcer.desc", "Spawns a forcer prop for use with the wire system." )
	language.Add( "tool.wire_forcer.0", "Primary: Create/Update Forcer" )
	language.Add( "sboxlimit_wire_forcers", "You've hit forcers limit!" )
end
WireToolSetup.BaseLang("Forcers")

if SERVER then
	CreateConVar('sbox_maxwire_forcers', 20)
end

TOOL.ClientConVar = {
	multiplier	= 1,
	length		= 100,
	beam		= 1,
	reaction	= 0,
	model		= "models/jaanus/wiretool/wiretool_siren.mdl"
}

local forcermodels = {
	["models/jaanus/wiretool/wiretool_grabber_forcer.mdl"] = {},
	["models/jaanus/wiretool/wiretool_siren.mdl"] = {}
}

function TOOL.BuildCPanel(panel)
	WireToolHelpers.MakePresetControl(panel, "wire_forcer")
	WireDermaExts.ModelSelect(panel, "wire_forcer_Model", forcermodels, 1, true)
	panel:NumSlider("Force multiplier", "wire_forcer_multiplier", 1, 10000, 0)
	panel:NumSlider("Force distance", "wire_forcer_length", 1, 10000, 0)
	panel:CheckBox("Show beam", "wire_forcer_beam")
	panel:CheckBox("Apply reaction force", "wire_forcer_reaction")
end
