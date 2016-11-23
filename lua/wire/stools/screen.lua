WireToolSetup.setCategory( "Visuals/Screens" )
WireToolSetup.open( "screen", "Screen", "gmod_wire_screen", nil, "Screens" )

if CLIENT then
	language.Add( "tool.wire_screen.name", "Screen Tool (Wire)" )
	language.Add( "tool.wire_screen.desc", "Spawns a screen that display values." )
	language.Add("Tool_wire_screen_singlevalue", "Only one value")
	language.Add("Tool_wire_screen_singlebigfont", "Use bigger font for single-value screen")
	language.Add("Tool_wire_screen_texta", "Text A:")
	language.Add("Tool_wire_screen_textb", "Text B:")
	language.Add("Tool_wire_screen_leftalign", "Left alignment")
	language.Add("Tool_wire_screen_floor", "Floor screen value")
	language.Add("Tool_wire_screen_formatnumber", "Format the number into millions, billions, etc")
	language.Add("Tool_wire_screen_formattime", "Format the number as a duration, in seconds")
	language.Add("Tool_wire_screen_createflat", "Create flat to surface")
	TOOL.Information = { { name = "left", text = "Create/Update " .. TOOL.Name } }
end
WireToolSetup.BaseLang()
WireToolSetup.SetupMax( 20 )

if SERVER then
	ModelPlug_Register("pixel")

	function TOOL:GetDataTables()
		return {
			SingleValue = self:GetClientNumber("singlevalue") == 1,
			SingleBigFont = self:GetClientNumber("singlebigfont") == 1,
			TextA = self:GetClientInfo("texta"),
			TextB = self:GetClientInfo("textb"),
			LeftAlign = self:GetClientNumber("leftalign") == 1,
			Floor = self:GetClientNumber("floor") == 1,
			FormatNumber = self:GetClientNumber("formatnumber") == 1,
			FormatTime = self:GetClientNumber("formattime") == 1
		}
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
	formatnumber  = 0,
	formattime    = 0,
}

function TOOL.BuildCPanel(panel)
	WireToolHelpers.MakePresetControl(panel, "wire_screen")
	WireDermaExts.ModelSelect(panel, "wire_screen_model", list.Get( "WireScreenModels" ), 5) -- screen with GPULib setup
	panel:CheckBox("#Tool_wire_screen_singlevalue", "wire_screen_singlevalue")
	panel:CheckBox("#Tool_wire_screen_singlebigfont", "wire_screen_singlebigfont")
	panel:CheckBox("#Tool_wire_screen_leftalign", "wire_screen_leftalign")
	panel:CheckBox("#Tool_wire_screen_floor", "wire_screen_floor")
	panel:CheckBox("#Tool_wire_screen_formatnumber", "wire_screen_formatnumber")
	local p = panel:CheckBox("#Tool_wire_screen_formattime", "wire_screen_formattime")
	p:SetToolTip( "This overrides the two above settings" )
	panel:TextEntry("#Tool_wire_screen_texta", "wire_screen_texta")
	panel:TextEntry("#Tool_wire_screen_textb", "wire_screen_textb")
	panel:CheckBox("#Tool_wire_screen_createflat", "wire_screen_createflat")
end
