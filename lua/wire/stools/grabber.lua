WireToolSetup.setCategory( "Physics/Constraints" )
WireToolSetup.open( "grabber", "Grabber", "gmod_wire_grabber", nil, "Grabbers" )

if CLIENT then
	language.Add( "tool.wire_grabber.name", "Grabber Tool (Wire)" )
	language.Add( "tool.wire_grabber.desc", "Spawns a constant grabber prop for use with the wire system." )
	language.Add( "tool.wire_grabber.right_0", "Link grabber to a prop that'll also be welded for stability" )
	language.Add( "WireGrabberTool_Range", "Max Range:" )
	language.Add( "WireGrabberTool_Gravity", "Disable Gravity" )
end
WireToolSetup.BaseLang()
WireToolSetup.SetupMax( 20 )

if SERVER then
	function TOOL:GetConVars()
		return self:GetClientNumber("Range"), self:GetClientNumber("Gravity")~=0
	end

	-- Uses default WireToolObj:MakeEnt's WireLib.MakeWireEnt function
end

TOOL.ClientConVar = {
	model	= "models/jaanus/wiretool/wiretool_range.mdl",
	Range	= 100,
	Gravity	= 1,
}

WireToolSetup.SetupLinking(true, "prop")

function TOOL:GetGhostMin( min )
	if self:GetModel() == "models/jaanus/wiretool/wiretool_grabber_forcer.mdl" then
		return min.z + 20
	end
	return min.z
end

function TOOL.BuildCPanel(panel)
	WireToolHelpers.MakePresetControl(panel, "wire_grabber")
	ModelPlug_AddToCPanel(panel, "Forcer", "wire_grabber", true, 1)
	panel:CheckBox("#WireGrabberTool_Gravity", "wire_grabber_Gravity")
	panel:NumSlider("#WireGrabberTool_Range", "wire_grabber_Range", 1, 10000, 0)
end
