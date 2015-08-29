if !WireLib then return end

WireToolSetup.setCategory( "Detection" )
WireToolSetup.open( "col_detector", "Collision Detector", "gmod_wire_coldetector", nil, "Collision Detectors" )

if CLIENT then
	language.Add( "tool.wire_col_detector.name", "Collision Detector (Wire)" )
	language.Add( "tool.wire_col_detector.desc", "Spawns a Collision Detector" )
	language.Add( "tool.wire_col_detector.0", "Primary: Create/Update Collision Detector, Secondary: Link Detector" )
end
WireToolSetup.BaseLang()
WireToolSetup.SetupMax( 20 )

TOOL.ClientConVar = {
	constrained = 0,
	nophysics	= 0,
	model		= "models/jaanus/wiretool/wiretool_siren.mdl"
}

WireToolSetup.SetupLinking()

if SERVER then
	function TOOL:GetConVars() 
		return self:GetClientNumber( "constrained" ) !=0, self:GetClientNumber( "nophysics" ) !=0
	end
end

function TOOL:GetGhostMin( min, trace )
		return min.z
end

function TOOL.BuildCPanel(panel)
	panel:CheckBox("Output collisions with constrained entities","wire_col_detector_constrained")
	panel:CheckBox("Parent sticked entities","wire_col_detector_nophysics")
end