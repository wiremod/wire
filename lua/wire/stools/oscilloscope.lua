WireToolSetup.setCategory( "Display" )
WireToolSetup.open( "oscilloscope", "Oscilloscope", "gmod_wire_oscilloscope", nil, "Oscilloscopes" )

if CLIENT then
	language.Add( "tool.wire_oscilloscope.name", "Oscilloscope Tool (Wire)" )
	language.Add( "tool.wire_oscilloscope.desc", "Spawns a oscilloscope what display line graphs." )
	language.Add( "tool.wire_oscilloscope.0", "Primary: Create/Update oscilloscope" )
end
WireToolSetup.BaseLang()

WireToolSetup.SetupMax( 20, "wire_oscilloscopes", "You've hit oscilloscopes limit!" )

if SERVER then
	function TOOL:GetConVars() end

	function TOOL:MakeEnt( ply, model, Ang, trace )
		return MakeWireOscilloscope( ply, trace.HitPos, Ang, model )
	end
end

TOOL.NoLeftOnClass = true -- no update ent function needed
TOOL.ClientConVar = {
	model      = "models/props_lab/monitor01b.mdl",
	createflat = 0,
	weld       = 1,
}


function TOOL.BuildCPanel(panel)
	WireDermaExts.ModelSelect(panel, "wire_oscilloscope_model", list.Get( "WireScreenModels" ), 5)
	panel:CheckBox("#Create Flat to Surface", "wire_oscilloscope_createflat")
	panel:CheckBox("Weld", "wire_oscilloscope_weld")
end
