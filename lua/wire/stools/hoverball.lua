WireToolSetup.setCategory( "Physics" )
WireToolSetup.open( "hoverball", "Hoverball", "gmod_wire_hoverball", WireToolMakeHoverball, "Hoverballs" )

if CLIENT then
	language.Add( "tool.wire_hoverball.name", "Wired Hoverball Tool" )
	language.Add( "tool.wire_hoverball.desc", "Spawns a hoverball for use with the wire system." )
	language.Add( "tool.wire_hoverball.0", "Primary: Create/Update Hoverball" )
	language.Add( "WireHoverballTool_starton", "Create with hover mode on" )
end
WireToolSetup.BaseLang("Hoverballs")
WireToolSetup.SetupMax( 30, TOOL.Mode.."s" , "You've hit the Wire "..TOOL.PluralName.." limit!" )

TOOL.ClientConVar = {
	speed		= 1,
	resistance	= 0,
	strength	= 1,
	starton		= 1,
}

TOOL.Model		= "models/dav0r/hoverball.mdl"

function TOOL:GetGhostMin( min, trace )
	if trace.Entity:IsWorld() then
		return -8
	end
	return 0
end

function TOOL.BuildCPanel(panel)
	WireToolHelpers.MakePresetControl(panel, "wire_hoverball")
	panel:NumSlider("#Movement Speed", "wire_hoverball_speed", 1, 10, 0)
	panel:NumSlider("#Air Resistance", "wire_hoverball_resistance", 1, 10, 0)
	panel:NumSlider("#Strength", "wire_hoverball_strength", .1, 10, 2)
	panel:CheckBox("#WireHoverballTool_starton", "wire_hoverball_starton")
end
