WireToolSetup.setCategory( "Display" )
WireToolSetup.open( "panel", "Control Panel", "gmod_wire_panel", nil, "Control Panels" )

if CLIENT then
	language.Add( "tool.wire_panel.name", "Control Panel Tool (Wire)" )
	language.Add( "tool.wire_panel.desc", "Spawns a panel what display values." )
	language.Add( "tool.wire_panel.0", "Primary: Create/Update panel" )
	language.Add( "Tool_wire_panel_createflat", "Create flat to surface" )
end
WireToolSetup.BaseLang()

WireToolSetup.SetupMax( 20, "wire_panels", "You've hit panels limit!" )

if SERVER then
	function TOOL:GetConVars() end

	function TOOL:MakeEnt( ply, model, Ang, trace )
		return MakeWirePanel( ply, trace.HitPos, Ang, model )
	end
end

TOOL.NoLeftOnClass = true -- no update ent function needed
TOOL.ClientConVar = {
	model      = "models/props_lab/monitor01b.mdl",
	createflat = 1,
	weld       = 1,
}

function TOOL.BuildCPanel(panel)
	WireDermaExts.ModelSelect(panel, "wire_panel_model", list.Get( "WireScreenModels" ), 2) -- screen witha GPULib setup
	panel:CheckBox("#Tool_wire_panel_createflat", "wire_panel_createflat")
	panel:CheckBox("Weld", "wire_panel_weld")
end