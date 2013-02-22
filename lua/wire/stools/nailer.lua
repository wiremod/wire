WireToolSetup.setCategory( "Physics" )
WireToolSetup.open( "nailer", "Nailer", "gmod_wire_nailer", nil, "Nailers" )

if ( CLIENT ) then
	language.Add( "Tool.wire_nailer.name", "Nailer Tool (Wire)" )
	language.Add( "Tool.wire_nailer.desc", "Spawns a constant nailer prop for use with the wire system." )
	language.Add( "Tool.wire_nailer.0", "Primary: Create/Update Nailer" )
end
WireToolSetup.BaseLang()
WireToolSetup.SetupMax( 20, TOOL.Mode.."s" , "You've hit the Wire "..TOOL.PluralName.." limit!" )

if (SERVER) then
	function TOOL:GetConVars() 
		return self:GetClientNumber( "forcelim" )
	end	
	function TOOL:MakeEnt( ply, model, Ang, trace )
		return MakeWireNailer( ply, trace.HitPos, Ang, model, self:GetConVars() )
	end
end

TOOL.ClientConVar = {
	model = "models/jaanus/wiretool/wiretool_siren.mdl",
	forcelim = "0"
}

function TOOL.BuildCPanel(panel)
	WireToolHelpers.MakePresetControl(panel, "wire_nailer")
	ModelPlug_AddToCPanel(panel, "Laser_Tools", "wire_nailer", true)
	panel:NumSlider("#Force Limit", "wire_nailer_forcelim", 0, 10000, 0)
end
