WireToolSetup.setCategory( "Advanced" )
WireToolSetup.open( "datarate", "Data - Transfer Bus", "gmod_wire_datarate", nil, "Transfer Buses" )

if ( CLIENT ) then
	language.Add( "Tool.wire_datarate.name", "Data transfer bus tool (Wire)" )
	language.Add( "Tool.wire_datarate.desc", "Spawns a data transferrer. Data transferrer acts like identity gate for hi-speed and regular links" )
	language.Add( "Tool.wire_datarate.0", "Primary: Create/Update data trasnferrer" )
end
WireToolSetup.BaseLang()
WireToolSetup.SetupMax( 20, TOOL.Mode.."s" , "You've hit the Wire "..TOOL.PluralName.." limit!" )

TOOL.ClientConVar[ "model" ] = "models/jaanus/wiretool/wiretool_gate.mdl"

if SERVER then
	function TOOL:MakeEnt( ply, model, Ang, trace )
		return MakeWireDataRate( ply, trace.HitPos, Ang, model, self:GetConVars() )
	end
end

function TOOL.BuildCPanel(panel)
	ModelPlug_AddToCPanel(panel, "gate", "wire_datarate", nil, 4)
end


