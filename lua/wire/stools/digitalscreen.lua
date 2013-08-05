WireToolSetup.setCategory( "Display" )
WireToolSetup.open( "digitalscreen", "Digital Screen", "gmod_wire_digitalscreen", nil, "Digital Screens" )

if CLIENT then
	language.Add( "tool.wire_digitalscreen.name", "Digital Screen Tool (Wire)" )
	language.Add( "tool.wire_digitalscreen.desc", "Spawns a digital screen, which can be used to draw pixel by pixel." )
	language.Add( "tool.wire_digitalscreen.0", "Primary: Create/Update screen" )
end
WireToolSetup.BaseLang()
WireToolSetup.SetupMax( 20 )

if SERVER then
	function TOOL:GetConVars()
		return self:GetClientInfo("width"), self:GetClientInfo("height")
	end

	function TOOL:MakeEnt( ply, model, Ang, trace )
		return MakeWireDigitalScreen( ply, trace.HitPos, Ang, model, self:GetConVars() )
	end
end

TOOL.ClientConVar = {
	model      = "models/props_lab/monitor01b.mdl",
	width      = 32,
	height     = 32,
	createflat = 0,
	weld       = 1,
}

function TOOL.BuildCPanel(panel)
	WireDermaExts.ModelSelect(panel, "wire_digitalscreen_model", list.Get( "WireScreenModels" ), 5)
	panel:NumSlider("Width", "wire_digitalscreen_width", 1, 512, 0)
	panel:NumSlider("Height", "wire_digitalscreen_height", 1, 512, 0)
	panel:CheckBox("#Create Flat to Surface", "wire_digitalscreen_createflat")
	panel:CheckBox("Weld", "wire_digitalscreen_weld")
end