WireToolSetup.setCategory( "Visuals/Screens" )
--Originally by http://forums.facepunchstudios.com/greenarrow
WireToolSetup.open( "textscreen", "Text Screen", "gmod_wire_textscreen", nil, "Text Screens" )

if CLIENT then
	language.Add("tool.wire_textscreen.name", "Text Screen Tool (Wire)" )
	language.Add("tool.wire_textscreen.desc", "Spawns a screen that displays text." )

	language.Add("Tool_wire_textscreen_tsize", "Text size:")
	language.Add("Tool_wire_textscreen_tjust", "Horizontal alignment:")
	language.Add("Tool_wire_textscreen_valign", "Vertical alignment:")
	language.Add("Tool_wire_textscreen_tfont", "Text font:")
	language.Add("Tool_wire_textscreen_colour", "Text colour:")
	language.Add("Tool_wire_textscreen_createflat", "Create flat to surface")
	language.Add("Tool_wire_textscreen_text", "Default text:")
	TOOL.Information = {
		{ name = "left", text = "Create/Update " .. TOOL.Name },
		{ name = "right", text = "Copy settings" },
	}

end
WireToolSetup.BaseLang()

WireToolSetup.SetupMax( 20 )

if SERVER then
	ModelPlug_Register("speaker")

	function TOOL:GetConVars()
		return
			self:GetClientInfo("text"),
			(16 - tonumber(self:GetClientInfo("tsize"))),
			self:GetClientNumber("tjust"),
			self:GetClientNumber("valign"),
			self:GetClientInfo("tfont"),
			Color(
				math.min(self:GetClientNumber("tred"), 255),
				math.min(self:GetClientNumber("tgreen"), 255),
				math.min(self:GetClientNumber("tblue"), 255)
			),
			Color(0,0,0)
	end

	-- Uses default WireToolObj:MakeEnt's WireLib.MakeWireEnt function
end

TOOL.ClientConVar = {
	model       = "models/kobilica/wiremonitorbig.mdl",
	tsize       = 10,
	tjust       = 1,
	valign      = 0,
	tfont       = "Arial",
	tred        = 255,
	tblue       = 255,
	tgreen      = 255,
	ninputs     = 3,
	createflat  = 1,
	text        = "",
}

function TOOL:RightClick( trace )
	if not trace.HitPos then return false end
	local ent = trace.Entity
	if ent:IsPlayer() then return false end
	if CLIENT then return true end

	local ply = self:GetOwner()

	if ent:IsValid() && ent:GetClass() == "gmod_wire_textscreen" then
		ply:ConCommand('wire_textscreen_text "'..ent.text..'"')
		return true
	end

end

function TOOL.BuildCPanel(panel)
	local Fonts = {
		"WireGPU_ConsoleFont",
		"Coolvetica",
		"Arial",
		"Lucida Console",
		"Trebuchet",
		"Courier New",
		"Times New Roman",
		"ChatFont",
		"Marlett",
		"Verdana",
		"Tahoma",
		"HalfLife2",
		"HL2cross",
		"Trebuchet MS",
		"HL2MP"
	}
	local Options = {}
	for k,v in ipairs(Fonts) do Options[v] = { wire_textscreen_tfont = v } end
	
	WireToolHelpers.MakePresetControl(panel, "wire_textscreen")
	panel:NumSlider("#Tool_wire_textscreen_tsize", "wire_textscreen_tsize", 1, 15, 0)
	panel:NumSlider("#Tool_wire_textscreen_tjust", "wire_textscreen_tjust", 0, 2, 0)
	panel:NumSlider("#Tool_wire_textscreen_valign", "wire_textscreen_valign", 0, 2, 0)
	panel:AddControl("ComboBox", {
		Label = "#Tool_wire_textscreen_tfont",
		Options = Options
	})
	panel:AddControl("Color", {
		Label = "#Tool_wire_textscreen_colour",
		Red = "wire_textscreen_tred",
		Green = "wire_textscreen_tgreen",
		Blue = "wire_textscreen_tblue",
		ShowAlpha = "0",
		ShowHSV = "1",
		ShowRGB = "1",
		Multiplier = "255"
	})
	WireDermaExts.ModelSelect(panel, "wire_textscreen_model", list.Get( "WireScreenModels" ), 5)
	panel:CheckBox("#Tool_wire_textscreen_createflat", "wire_textscreen_createflat")
	panel:TextEntry("#Tool_wire_textscreen_text", "wire_textscreen_text")
end
