WireToolSetup.setCategory( "Visuals" )
WireToolSetup.open( "fx_emitter", "FX Emitter", "gmod_wire_fx_emitter", nil, "FX Emitters" )

if ( CLIENT ) then
	language.Add( "Tool.wire_fx_emitter.name", "Wire FX Emitter" )
	language.Add( "Tool.wire_fx_emitter.desc", "Wire FX Emitter Emits effects eh?" )
	language.Add( "Tool.wire_fx_emitter.delay", "Delay between effect pulses" )
	TOOL.Information = { { name = "left", text = "Create/Update " .. TOOL.Name } }
end
WireToolSetup.BaseLang()
WireToolSetup.SetupMax( 20 )

TOOL.ClientConVar = {
	model = "models/props_lab/tpplug.mdl",
	Effect = "sparks",
	Delay = 0.07,
	weld = 1,
	createflat = 1, -- Needed for tpplug.mdl
}
TOOL.GhostMin = "y"

if SERVER then
	function TOOL:GetConVars()
		return math.Clamp(self:GetClientNumber( "Delay" ), 0.05, 20), ComboBox_Wire_FX_Emitter_Options[self:GetClientInfo( "Effect" )]
	end
end

function TOOL.BuildCPanel( CPanel )
	CPanel:AddControl( "Header", { Text = "#Tool.wire_fx_emitter.name", Description	= "#Tool.wire_fx_emitter.desc" }  )

	// Effect types
	local params = { Label = "#Effect", Height = "250", MenuButton="0", Options = {} }
		for k,_ in pairs(ComboBox_Wire_FX_Emitter_Options) do
			params.Options[ "#wire_fx_emitter_" .. k ] = { wire_fx_emitter_Effect = k }
		end
	CPanel:AddControl( "ListBox", params )

	CPanel:NumSlider("#Tool.wire_fx_emitter.delay", "wire_fx_emitter_Delay", 0.05, 5, 2)
end
