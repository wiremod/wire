WireToolSetup.setCategory( "Physics" )
WireToolSetup.open( "hoverball", "Hoverball", "gmod_wire_hoverball", nil, "Hoverballs" )

if CLIENT then
	language.Add( "tool.wire_hoverball.name", "Wired Hoverball Tool" )
	language.Add( "tool.wire_hoverball.desc", "Spawns a hoverball for use with the wire system." )
	language.Add( "tool.wire_hoverball.0", "Primary: Create/Update Hoverball" )
	language.Add( "tool.wire_hoverball.starton", "Create with hover mode on" )
end
WireToolSetup.BaseLang("Hoverballs")
WireToolSetup.SetupMax( 30, TOOL.Mode.."s" , "You've hit the Wire "..TOOL.PluralName.." limit!" )

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

	function TOOL:MakeEnt( ply, model, Ang, trace )
		return MakeWireHoverBall( ply, trace.HitPos, Ang, model, self:GetConVars() )
	end
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
	panel:NumSlider("#Air Resistance", "wire_hoverball_resistance", 1, 10, 0)
	panel:NumSlider("#Strength", "wire_hoverball_strength", .1, 10, 2)
	panel:CheckBox("#tool.wire_hoverball.starton", "wire_hoverball_starton")
end
