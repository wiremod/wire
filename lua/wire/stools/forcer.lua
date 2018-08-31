WireToolSetup.setCategory( "Physics/Force" )
WireToolSetup.open( "forcer", "Forcer", "gmod_wire_forcer", nil, "Forcers" )

if CLIENT then
	language.Add( "tool.wire_forcer.name", "Forcer Tool (Wire)" )
	language.Add( "tool.wire_forcer.desc", "Spawns a forcer prop for use with the wire system." )
	TOOL.Information = { { name = "left", text = "Create/Update " .. TOOL.Name } }
end
WireToolSetup.BaseLang()
WireToolSetup.SetupMax( 20 )

TOOL.ClientConVar = {
	multiplier	= 1,
	length		= 100,
	beam		= 1,
	reaction	= 0,
	model		= "models/jaanus/wiretool/wiretool_siren.mdl"
}

if SERVER then
	function TOOL:GetConVars()
		return self:GetClientNumber( "multiplier" ), self:GetClientNumber( "length" ), self:GetClientNumber( "beam" )==1, self:GetClientNumber( "reaction" )==1
	end

	-- Uses default WireToolObj:MakeEnt's WireLib.MakeWireEnt function
end

function TOOL:GetGhostMin( min, trace )
	if self:GetModel() == "models/jaanus/wiretool/wiretool_grabber_forcer.mdl" then
		return min.z + 20
	else
		return min.z
	end
end

function TOOL.BuildCPanel(panel)
	WireToolHelpers.MakePresetControl(panel, "wire_forcer")
	ModelPlug_AddToCPanel(panel, "Forcer", "wire_forcer", true, 1)
	panel:NumSlider("Force multiplier", "wire_forcer_multiplier", 1, 10000, 0)
	panel:NumSlider("Force distance", "wire_forcer_length", 1, 2048, 0)
	panel:CheckBox("Show beam", "wire_forcer_beam")
	panel:CheckBox("Apply reaction force", "wire_forcer_reaction")
end
