WireToolSetup.setCategory( "Display" )
WireToolSetup.open( "pixel", "Pixel", "gmod_wire_pixel", nil, "Pixels" )

if CLIENT then
	language.Add( "tool.wire_pixel.name", "Pixel Tool (Wire)" )
	language.Add( "tool.wire_pixel.desc", "Spawns a Pixel for use with the wire system." )
	language.Add( "tool.wire_pixel.0", "Primary: Create Pixel" )
end
WireToolSetup.BaseLang()

WireToolSetup.SetupMax( 20, "wire_pixels", "You've hit pixels limit!" )

if SERVER then
	ModelPlug_Register("pixel")

	function TOOL:GetConVars()
		return self:GetClientNumber( "noclip" ) == 1
	end

	function TOOL:MakeEnt( ply, model, Ang, trace )
		return MakeWirePixel( ply, trace.HitPos, Ang, model, self:GetConVars() )
	end
end

TOOL.NoLeftOnClass = true -- no update ent function needed
TOOL.ClientConVar = {
	model  = "models/jaanus/wiretool/wiretool_siren.mdl",
	noclip = 0,
	weld   = 1,
}

function TOOL.BuildCPanel(panel)
	WireDermaExts.ModelSelect(panel, "wire_pixel_model", list.Get("Wire_pixel_Models"), 3, true)
	panel:CheckBox("#WireGatesTool_noclip", "wire_pixel_noclip")
	panel:CheckBox("Weld", "wire_pixel_weld")
end
