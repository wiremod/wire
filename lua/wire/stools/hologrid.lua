WireToolSetup.setCategory( "Render" )
WireToolSetup.open( "hologrid", "HoloGrid", "gmod_wire_hologrid", nil, "HoloGrids" )

if CLIENT then

	local stage0 = "Secondary: Link HoloGrid with HoloEmitter or reference entity, Reload: Unlink HoloEmitter or HoloGrid"
	local stage1 = "Select the HoloGrid to link to."
	local stage2 = "Select the Holo Emitter or reference entity to link to."

	language.Add( "tool.wire_hologrid.name", "Holographic Grid Tool (Wire)" )
	language.Add( "tool.wire_hologrid.desc", "The grid to aid in holographic projections" )
	language.Add( "tool.wire_hologrid.0", "Primary: Create grid, "..stage0 )
	language.Add( "tool.wire_hologrid.1", stage1 )
	language.Add( "tool.wire_hologrid.2", stage2 )
	language.Add( "Tool_wire_hologrid_usegps", "Use GPS coordinates" )
end
WireToolSetup.BaseLang()

WireToolSetup.SetupMax( 20, "wire_hologrids", "You've hit sound hologrids limit!" )

if SERVER then
	function TOOL:GetConVars()
		return util.tobool(self:GetClientNumber( "usegps" ))
	end

	function TOOL:MakeEnt( ply, model, Ang, trace )
		return MakeWireHologrid( ply, trace.HitPos, Ang, model, self:GetConVars() )
	end
end

TOOL.RightClick    = HoloRightClick
TOOL.Reload        = HoloReload
TOOL.NoGhostOn     = { "sbox_maxwire_holoemitters" }
TOOL.NoLeftOnClass = true
TOOL.ClientConVar  = {
	model = "models/jaanus/wiretool/wiretool_siren.mdl",
	usegps = 0,
	weld   = 1,
}

function TOOL.BuildCPanel( panel )
	WireDermaExts.ModelSelect(panel, "wire_hologrid_model", list.Get( "Wire_Misc_Tools_Models" ), 1)
	panel:CheckBox("#Tool_wire_hologrid_usegps", "wire_hologrid_usegps")
	panel:CheckBox("Weld", "wire_hologrid_weld")
end