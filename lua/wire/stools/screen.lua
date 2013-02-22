WireToolSetup.setCategory( "Display" )
WireToolSetup.open( "screen", "Screen", "gmod_wire_screen", nil, "Screens" )

if CLIENT then
	language.Add( "tool.wire_screen.name", "Screen Tool (Wire)" )
	language.Add( "tool.wire_screen.desc", "Spawns a screen that display values." )
	language.Add( "tool.wire_screen.0", "Primary: Create/Update screen" )
	language.Add("Tool_wire_screen_singlevalue", "Only one value")
	language.Add("Tool_wire_screen_singlebigfont", "Use bigger font for single-value screen")
	language.Add("Tool_wire_screen_texta", "Text A:")
	language.Add("Tool_wire_screen_textb", "Text B:")
	language.Add("Tool_wire_screen_leftalign", "Left alignment")
	language.Add("Tool_wire_screen_floor", "Floor screen value")
	language.Add("Tool_wire_screen_createflat", "Create flat to surface")
end
WireToolSetup.BaseLang()

WireToolSetup.SetupMax( 20, "wire_screens", "You've hit screens limit!" )

if SERVER then
	ModelPlug_Register("pixel")

	function TOOL:GetConVars()
		return self:GetClientNumber("singlevalue") == 1,
		self:GetClientNumber("singlebigfont") == 1,
		self:GetClientInfo("texta"),
		self:GetClientInfo("textb"),
		self:GetClientNumber("leftalign") == 1,
		self:GetClientNumber("floor") == 1
	end

	function TOOL:MakeEnt( ply, model, Ang, trace )
		return MakeWireScreen( ply, trace.HitPos, Ang, model, self:GetConVars() )
	end
end

TOOL.ClientConVar = {
	model         = "models/props_lab/monitor01b.mdl",
	singlevalue   = 0,
	singlebigfont = 1,
	texta         = "Value A",
	textb         = "Value B",
	createflat    = 1,
	leftalign     = 0,
	floor         = 0,
	weld          = 1,
}

function TOOL.BuildCPanel(panel)
	WireToolHelpers.MakePresetControl(panel, "wire_screen")
	WireDermaExts.ModelSelect(panel, "wire_screen_model", list.Get( "WireScreenModels" ), 5) -- screen with GPULib setup
	panel:CheckBox("#Tool_wire_screen_singlevalue", "wire_screen_singlevalue")
	panel:CheckBox("#Tool_wire_screen_singlebigfont", "wire_screen_singlebigfont")
	panel:CheckBox("#Tool_wire_screen_leftalign", "wire_screen_leftalign")
	panel:CheckBox("#Tool_wire_screen_floor", "wire_screen_floor")
	panel:TextEntry("#Tool_wire_screen_texta", "wire_screen_texta")
	panel:TextEntry("#Tool_wire_screen_textb", "wire_screen_textb")
	panel:CheckBox("#Tool_wire_screen_createflat", "wire_screen_createflat")
	panel:CheckBox("Weld", "wire_screen_weld")
end
