WireToolSetup.setCategory( "Visuals/Screens" )
WireToolSetup.open( "characterlcd", "Character LCD", "gmod_wire_characterlcd", nil, "Character LCDs" )

if CLIENT then
	language.Add( "tool.wire_characterlcd.name", "Character LCD Tool (Wire)" )
	language.Add( "tool.wire_characterlcd.desc", "Spawns a Character LCD, which can be used to display text" )
  language.Add( "tool.wire_characterlcd.bgcolor", "Background color:" )
  language.Add( "tool.wire_characterlcd.fgcolor", "Text color:" )
	TOOL.Information = { { name = "left", text = "Create/Update " .. TOOL.Name } }
end
WireToolSetup.BaseLang()
WireToolSetup.SetupMax( 20 )

if SERVER then
	function TOOL:GetConVars()
		return self:GetClientInfo("width"), self:GetClientInfo("height"),
        math.Clamp(self:GetClientNumber("bgred"), 0, 255),
				math.Clamp(self:GetClientNumber("bggreen"), 0, 255),
				math.Clamp(self:GetClientNumber("bgblue"), 0, 255),
        math.Clamp(self:GetClientNumber("fgred"), 0, 255),
				math.Clamp(self:GetClientNumber("fggreen"), 0, 255),
				math.Clamp(self:GetClientNumber("fgblue"), 0, 255)
	end
end

TOOL.ClientConVar = {
	model      = "models/props_lab/monitor01b.mdl",
	width      = 16,
	height     = 2,
	createflat = 0,
  bgred      = 148,
  bggreen    = 178,
  bgblue     = 15,
  fgred      = 45,
  fggreen    = 91,
  fgblue     = 45,

}

function TOOL.BuildCPanel(panel)
  WireToolHelpers.MakePresetControl(panel, "wire_characterlcd")
	WireDermaExts.ModelSelect(panel, "wire_characterlcd_model", list.Get( "WireScreenModels" ), 5)
  panel:AddControl("Color", {
		Label = "#tool.wire_characterlcd.bgcolor",
		Red = "wire_characterlcd_bgred",
		Green = "wire_characterlcd_bggreen",
		Blue = "wire_characterlcd_bgblue",
		ShowAlpha = "0",
		ShowHSV = "1",
		ShowRGB = "1",
		Multiplier = "255"
	})
  panel:AddControl("Color", {
		Label = "#tool.wire_characterlcd.fgcolor",
		Red = "wire_characterlcd_fgred",
		Green = "wire_characterlcd_fggreen",
		Blue = "wire_characterlcd_fgblue",
		ShowAlpha = "0",
		ShowHSV = "1",
		ShowRGB = "1",
		Multiplier = "255"
	})
	panel:NumSlider("Width", "wire_characterlcd_width", 1, 56, 0)
	panel:NumSlider("Height", "wire_characterlcd_height", 1, 16, 0)
	panel:CheckBox("#Create Flat to Surface", "wire_characterlcd_createflat")

end
