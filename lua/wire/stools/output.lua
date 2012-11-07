WireToolSetup.setCategory( "I/O" )
WireToolSetup.open( "output", "Numpad Output", "gmod_wire_output", nil, "Numpad Outputs" )

if CLIENT then
	language.Add( "Tool.wire_output.name", "Output Tool (Wire)" )
	language.Add( "Tool.wire_output.desc", "Spawns an output for use with the wire system." )
	language.Add( "Tool.wire_output.0", "Primary: Create/Update Output" )
	language.Add( "Tool.wire_output.keygroup", "Key:" )
end
WireToolSetup.BaseLang()
WireToolSetup.SetupMax( 10, TOOL.Mode.."s" , "You've hit the Wire "..TOOL.PluralName.." limit!" )

if SERVER then
	ModelPlug_Register("Numpad")
	
	function TOOL:GetConVars() 
		return self:GetClientNumber( "keygroup" )
	end	
	function TOOL:MakeEnt( ply, model, Ang, trace )
		return MakeWireOutput( ply, trace.HitPos, Ang, model, self:GetConVars() )
	end
end

TOOL.ClientConVar = {
	model = "models/beer/wiremod/numpad.mdl",
	modelsize = "",
	keygroup = 1
}

function TOOL.BuildCPanel(panel)
	WireToolHelpers.MakePresetControl(panel, "wire_output")
	WireToolHelpers.MakeModelSizer(panel, "wire_output_modelsize")
	ModelPlug_AddToCPanel(panel, "Numpad", "wire_output", true)
	panel:AddControl("Numpad", {
		Label = "#Tool.wire_output.keygroup",
		Command = "wire_output_keygroup",
	})
end
