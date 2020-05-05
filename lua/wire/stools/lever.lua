WireToolSetup.setCategory( "Input, Output" )
WireToolSetup.open( "lever", "Lever", "gmod_wire_lever", nil, "Levers" )

if CLIENT then
	language.Add( "tool.wire_lever.name", "Lever Tool (Wire)" )
	language.Add( "tool.wire_lever.desc", "Spawns a Lever for use with the wire system." )
	language.Add( "tool.wire_lever.minvalue", "Min Value:" )
	language.Add( "tool.wire_lever.maxvalue", "Max Value:" )
	TOOL.Information = { { name = "left", text = "Create/Update " .. TOOL.Name } }
end
WireToolSetup.BaseLang()
WireToolSetup.SetupMax( 10 )

if SERVER then
	function TOOL:GetConVars()
		return self:GetClientNumber( "min" ), self:GetClientNumber( "max" )
	end

	-- Uses default WireToolObj:MakeEnt's WireLib.MakeWireEnt function
end

function TOOL:GetModel()
	return "models/props_wasteland/tram_leverbase01.mdl"
end

TOOL.ClientConVar = {
	min = 0,
	max = 1
}

function TOOL.BuildCPanel(panel)
	panel:NumSlider("#Tool.wire_lever.minvalue", "wire_lever_min", -10, 10, 2 )
	panel:NumSlider("#Tool.wire_lever.maxvalue", "wire_lever_max", -10, 10, 2 )
end
