WireToolSetup.setCategory( "Physics", "Detection" )
WireToolSetup.open( "weight", "Weight (Adjustable)", "gmod_wire_weight", nil, "Adjustable Weights" )

if CLIENT then
	language.Add( "tool.wire_weight.name", "Weight Tool (Wire)" )
	language.Add( "tool.wire_weight.desc", "Spawns a weight." )
	language.Add( "tool.wire_weight.0", "Primary: Create/Update weight, Reload: Copy model" )
end
WireToolSetup.BaseLang()
WireToolSetup.SetupMax( 20 )

if SERVER then
	ModelPlug_Register("weight")
	function TOOL:GetConVars() end
	
	-- Uses default WireToolObj:MakeEnt's WireLib.MakeWireEnt function
end

TOOL.ClientConVar = {
	model = "models/props_interiors/pot01a.mdl",
}
TOOL.ReloadSetsModel = true

function TOOL.BuildCPanel(panel)
	ModelPlug_AddToCPanel(panel, "weight", "wire_weight", true)
end