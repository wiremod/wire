WireToolSetup.setCategory( "Detection" )
WireToolSetup.open( "damage_detector", "Damage Detector", "gmod_wire_damage_detector", nil, "Damage Detectors" )

if CLIENT then
	language.Add( "Tool.wire_damage_detector.name", "Damage Detector Tool (Wire)" )
	language.Add( "Tool.wire_damage_detector.desc", "Spawns a damage detector for use with the wire system" )
	language.Add( "Tool.wire_damage_detector.includeconstrained", "Include Constrained Props" )
end
WireToolSetup.BaseLang()
WireToolSetup.SetupMax( 10 )

TOOL.ClientConVar = {
	model = "models/jaanus/wiretool/wiretool_siren.mdl",
	includeconstrained = 0
}

if SERVER then
	function TOOL:GetConVars()
		return self:GetClientNumber( "includeconstrained" )
	end

	-- Uses default WireToolObj:MakeEnt's WireLib.MakeWireEnt function
end

WireToolSetup.SetupLinking()

function TOOL.BuildCPanel(panel)
	ModelPlug_AddToCPanel(panel, "Misc_Tools", "wire_damage_detector")
	panel:CheckBox("#Tool.wire_damage_detector.includeconstrained","wire_damage_detector_includeconstrained")
end
