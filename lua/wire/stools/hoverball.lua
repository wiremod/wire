WireToolSetup.setCategory( "Physics/Force" )
WireToolSetup.open( "hoverball", "Hoverball", "gmod_wire_hoverball", nil, "Hoverballs" )

if CLIENT then
	language.Add( "tool.wire_hoverball.name", "Wired Hoverball Tool" )
	language.Add( "tool.wire_hoverball.desc", "Spawns a hoverball for use with the wire system." )
	language.Add( "tool.wire_hoverball.starton", "Create with hover mode on" )
	TOOL.Information = { { name = "left", text = "Create/Update " .. TOOL.Name } }
end
WireToolSetup.BaseLang()
WireToolSetup.SetupMax( 30 )

TOOL.ClientConVar = {
	model		= "models/dav0r/hoverball.mdl",
	speed		= 1,
	resistance	= 0,
	strength	= 1,
	starton		= 1,
}

if SERVER then
	function TOOL:GetConVars()
		return self:GetClientNumber( "speed" ), math.Clamp(self:GetClientNumber( "resistance" ), 0, 20),
			math.Clamp(self:GetClientNumber( "strength" ), 0.1, 20), self:GetClientNumber( "starton" ) == 1
	end
end

function TOOL:GetAngle(trace)
	return Angle(0, 0, 0)
end

function TOOL:GetGhostMin( min, trace )
	if trace.Entity:IsWorld() then
		return -8
	end
	return 0
end

function TOOL.BuildCPanel(panel)
	WireToolHelpers.MakePresetControl(panel, "wire_hoverball")
	WireDermaExts.ModelSelect(panel, "wire_hoverball_model", list.Get("HoverballModels"), 2, true)
	panel:NumSlider("#Movement Speed", "wire_hoverball_speed", 1, 10, 0)
	panel:NumSlider("#Air Resistance", "wire_hoverball_resistance", 1, 20, 0)
	panel:NumSlider("#Strength", "wire_hoverball_strength", .1, 20, 2)
	panel:CheckBox("#tool.wire_hoverball.starton", "wire_hoverball_starton")
end
