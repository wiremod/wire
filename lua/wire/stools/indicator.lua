WireToolSetup.setCategory( "Visuals/Indicators" )
WireToolSetup.open( "indicator", "Indicator", "gmod_wire_indicator", nil, "Indicators" )

if CLIENT then
	language.Add( "tool.wire_indicator.name", "Indicator Tool (Wire)" )
	language.Add( "tool.wire_indicator.desc", "Spawns a indicator for use with the wire system." )
	language.Add( "ToolWireIndicator_a_value", "A Value:" )
	language.Add( "ToolWireIndicator_a_colour", "A Colour:" )
	language.Add( "ToolWireIndicator_b_value", "B Value:" )
	language.Add( "ToolWireIndicator_b_colour", "B Colour:" )
	language.Add( "ToolWireIndicator_Material", "Material:" )
	language.Add( "ToolWireIndicator_90", "Rotate segment 90" )
	TOOL.Information = { { name = "left", text = "Create/Update " .. TOOL.Name } }

	WireToolSetup.setToolMenuIcon( "icon16/lightbulb_add.png" )
end
WireToolSetup.BaseLang()

WireToolSetup.SetupMax( 21 )

if SERVER then
	ModelPlug_Register("indicator")

	function TOOL:GetConVars()
		return self:GetClientNumber("a"),
		math.Clamp(self:GetClientNumber("ar"),0,255),
		math.Clamp(self:GetClientNumber("ag"),0,255),
		math.Clamp(self:GetClientNumber("ab"),0,255),
		math.Clamp(self:GetClientNumber("aa"),0,255),
		self:GetClientNumber("b"),
		math.Clamp(self:GetClientNumber("br"),0,255),
		math.Clamp(self:GetClientNumber("bg"),0,255),
		math.Clamp(self:GetClientNumber("bb"),0,255),
		math.Clamp(self:GetClientNumber("ba"),0,255)
	end

	function TOOL:PostMake(ent)
		duplicator.StoreEntityModifier( ent, "material", { MaterialOverride = self:GetClientInfo("material") } )
	end
end

TOOL.ClientConVar = {
	model    = "models/jaanus/wiretool/wiretool_siren.mdl",
	a        = 0,
	ar       = 255,
	ag       = 0,
	ab       = 0,
	aa       = 255,
	b        = 1,
	br       = 0,
	bg       = 255,
	bb       = 0,
	ba       = 255,
	material = "models/debug/debugwhite",
	rotate90 = 0,
}

--function TOOL:GetGhostAngle( Ang )
function TOOL:GetAngle( trace )
	local Ang = trace.HitNormal:Angle()
	local Model = self:GetModel()
	--these models get mounted differently
	if Model == "models/props_borealis/bluebarrel001.mdl" or Model == "models/props_junk/PopCan01a.mdl" then
		return Ang + Angle(-90, 0, 0)
	elseif Model == "models/props_trainstation/trainstation_clock001.mdl" or Model == "models/segment.mdl" or Model == "models/segment2.mdl" then
		return Ang + Angle(0, 0, (self:GetClientNumber("rotate90") * 90))
	end
	Ang.pitch = Ang.pitch + 90
	return Ang
end

function TOOL:GetGhostMin( min )
	local Model = self:GetModel()
	--these models are different
	if Model == "models/props_trainstation/trainstation_clock001.mdl" or Model == "models/segment.mdl" or Model == "models/segment2.mdl" then
		return min.x
	end
	return min.z
end

function TOOL.BuildCPanel(panel)
	WireToolHelpers.MakePresetControl(panel, "wire_indicator")
	panel:NumSlider("#ToolWireIndicator_a_value", "wire_indicator_a", -10, 10, 1)

	panel:AddControl("Color", {
		Label = "#ToolWireIndicator_a_colour",
		Red = "wire_indicator_ar",
		Green = "wire_indicator_ag",
		Blue = "wire_indicator_ab",
		Alpha = "wire_indicator_aa",
		ShowAlpha = "1",
		ShowHSV = "1",
		ShowRGB = "1",
		Multiplier = "255"
	})

	panel:NumSlider("#ToolWireIndicator_b_value", "wire_indicator_b", -10, 10, 1)

	panel:AddControl("Color", {
		Label = "#ToolWireIndicator_b_colour",
		Red = "wire_indicator_br",
		Green = "wire_indicator_bg",
		Blue = "wire_indicator_bb",
		Alpha = "wire_indicator_ba",
		ShowAlpha = "1",
		ShowHSV = "1",
		ShowRGB = "1",
		Multiplier = "255"
	})

	ModelPlug_AddToCPanel(panel, "indicator", "wire_indicator", true)

	panel:AddControl("ComboBox", {
		Label = "#ToolWireIndicator_Material",
		Options = {
			["Matte"]	= { wire_indicator_material = "models/debug/debugwhite" },
			["Shiny"]	= { wire_indicator_material = "models/shiny" },
			["Metal"]	= { wire_indicator_material = "models/props_c17/metalladder003" }
		}
	})

	panel:CheckBox("#ToolWireIndicator_90", "wire_indicator_rotate90")
end
