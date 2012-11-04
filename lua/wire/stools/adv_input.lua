WireToolSetup.setCategory( "I/O" )
WireToolSetup.open( "adv_input", "Adv. Input", "gmod_wire_adv_input", nil, "Adv Inputs" )

if CLIENT then
	language.Add( "tool.wire_adv_input.name", "Adv. Input Tool (Wire)" )
	language.Add( "tool.wire_adv_input.desc", "Spawns a adv. input for use with the wire system." )
	language.Add( "tool.wire_adv_input.0", "Primary: Create/Update Adv. Input" )
	language.Add( "WireAdvInputTool_keymore", "Increase:" )
	language.Add( "WireAdvInputTool_keyless", "Decrease:" )
	language.Add( "WireAdvInputTool_toggle", "Toggle" )
	language.Add( "WireAdvInputTool_value_min", "Minimum:" )
	language.Add( "WireAdvInputTool_value_max", "Maximum:" )
	language.Add( "WireAdvInputTool_value_start", "Start at:" )
	language.Add( "WireAdvInputTool_speed", "Change per second:" )
	language.Add( "sboxlimit_wire_adv_inputs", "You've hit wired adv input limit!" )
end
WireToolSetup.BaseLang("Adv. Inputs")
WireToolSetup.SetupMax( 20, TOOL.Mode.."s" , "You've hit the Wire "..TOOL.PluralName.." limit!" )

if SERVER then
	ModelPlug_Register("Numpad")
	
	function TOOL:GetConVars() 
		return self:GetClientNumber( "keymore" ), self:GetClientNumber( "keyless" ), self:GetClientNumber( "toggle" ),
			self:GetClientNumber( "value_min" ), self:GetClientNumber( "value_max" ), self:GetClientNumber( "value_start" ),
			self:GetClientNumber( "speed" )
	end

	function TOOL:MakeEnt( ply, model, Ang, trace )
		return MakeWireAdvInput( ply, trace.HitPos, Ang, model, self:GetConVars() )
	end
end

TOOL.Model = "models/beer/wiremod/numpad.mdl"
TOOL.ClientConVar = {
	model = TOOL.Model,
	modelsize = "",
	keymore = "3",
	keyless = "1",
	toggle = "0",
	value_min = "0",
	value_max = "10",
	value_start = "5",
	speed = "1",
}

function TOOL.BuildCPanel( CPanel )
	CPanel:AddControl("ListBox", {
		Label = "Model Size",
		Options = {
				["normal"] = { wire_adv_input_modelsize = "" },
				["mini"] = { wire_adv_input_modelsize = "_mini" },
				["nano"] = { wire_adv_input_modelsize = "_nano" }
			}
	})
	ModelPlug_AddToCPanel(CPanel, "Numpad", "wire_adv_input", "#ToolWireIndicator_Model")
	CPanel:AddControl( "Numpad", {Label = "#WireAdvInputTool_keymore", Command = "wire_adv_input_keymore"})
	CPanel:AddControl( "Numpad", {Label = "#WireAdvInputTool_keyless", Command = "wire_adv_input_keyless"})
	CPanel:CheckBox("#WireAdvInputTool_toggle", "wire_adv_input_toggle")
	CPanel:NumSlider("#WireAdvInputTool_value_min", "wire_adv_input_value_min", -50, 50, 0)
	CPanel:NumSlider("#WireAdvInputTool_value_max", "wire_adv_input_value_max", -50, 50, 0)
	CPanel:NumSlider("#WireAdvInputTool_value_start", "wire_adv_input_value_start", -50, 50, 0)
	CPanel:NumSlider("#WireAdvInputTool_speed", "wire_adv_input_speed", 0.1, 50, 1)
end
