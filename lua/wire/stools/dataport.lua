WireToolSetup.setCategory( "Advanced" )
WireToolSetup.open( "dataport", "Data - Port", "gmod_wire_dataport", nil, "Data Ports" )

if ( CLIENT ) then
	language.Add( "Tool.wire_dataport.name", "Data port tool (Wire)" )
	language.Add( "Tool.wire_dataport.desc", "Spawns data port consisting of 8 ports" )
	language.Add( "Tool.wire_dataport.0", "Primary: Create/Update data ports unit" )
end
WireToolSetup.BaseLang()
WireToolSetup.SetupMax( 20, TOOL.Mode.."s" , "You've hit the Wire "..TOOL.PluralName.." limit!" )

TOOL.ClientConVar[ "model" ] = "models/jaanus/wiretool/wiretool_gate.mdl"

if SERVER then
	function TOOL:MakeEnt( ply, model, Ang, trace )
		return MakeWireDataPort( ply, trace.HitPos, Ang, model, self:GetConVars() )
	end
end

function TOOL.BuildCPanel(panel)
	ModelPlug_AddToCPanel(panel, "gate", "wire_dataport", nil, 4)
end
