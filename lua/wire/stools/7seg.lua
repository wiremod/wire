WireToolSetup.setCategory( "Visuals/Indicators" )
WireToolSetup.open( "7seg", "7 Segment Display", "gmod_wire_indicator", nil, "7 Segment Displays" )

TOOL.GhostAngle = Angle(90, 0, 0)
TOOL.GhostMin = "x"

if CLIENT then
	language.Add( "tool.wire_7seg.name", "7-Segment Display Tool" )
	language.Add( "tool.wire_7seg.desc", "Spawns 7 indicators for numeric display with the wire system." )
	language.Add( "ToolWire7Seg_a_colour", "Off Colour:" )
	language.Add( "ToolWire7Seg_b_colour", "On Colour:" )
	language.Add( "ToolWire7SegTool_worldweld", "Allow weld to world" )
	language.Add( "undone_wire7seg", "Undone 7-Segment Display" )
	TOOL.Information = { { name = "left", text = "Create/Update " .. TOOL.Name } }

	WireToolSetup.setToolMenuIcon( "icon16/lightbulb_add.png" )
end

WireToolSetup.BaseLang()

-- define MaxLimitName cause this tool just uses gmod_wire_indicators
TOOL.MaxLimitName = "wire_indicators"

if SERVER then
	function TOOL:GetConVars()
		return 0,
		math.Clamp(self:GetClientNumber("ar"),0,255),
		math.Clamp(self:GetClientNumber("ag"),0,255),
		math.Clamp(self:GetClientNumber("ab"),0,255),
		math.Clamp(self:GetClientNumber("aa"),0,255),
		1,
		math.Clamp(self:GetClientNumber("br"),0,255),
		math.Clamp(self:GetClientNumber("bg"),0,255),
		math.Clamp(self:GetClientNumber("bb"),0,255),
		math.Clamp(self:GetClientNumber("ba"),0,255)
	end

	function TOOL:MakeEnt( ply, model, Ang, trace )
		return MakeWire7Seg( ply, trace.HitPos, Ang, model, self:GetConVars() )
	end
end

TOOL.ClientConVar = {
	model     = "models/segment.mdl",
	ar        = 70, --default: dark grey off, full red on
	ag        = 70,
	ab        = 70,
	aa        = 255,
	br        = 255,
	bg        = 0,
	bb        = 0,
	ba        = 255,
	worldweld = 1,
}

function TOOL:PostMake_SetPos() end

function TOOL:LeftClick_PostMake( wire_indicators, ply, trace )
	if not istable(wire_indicators) then return end
	local worldweld = self:GetClientNumber("worldweld") == 1
	undo.Create("Wire7Seg")
		for x=1, 7 do
			--make welds
			local const = WireLib.Weld(wire_indicators[x], trace.Entity, trace.PhysicsBone, true, false, worldweld)
			undo.AddEntity( wire_indicators[x] )
			undo.AddEntity( const )
			ply:AddCleanup( "wire_indicators", wire_indicators[x] )
			ply:AddCleanup( "wire_indicators", const)
		end
		undo.SetPlayer( ply )
	undo.Finish()
	return true
end

function TOOL.BuildCPanel(panel)
	WireToolHelpers.MakePresetControl(panel, "wire_7seg")

	panel:AddControl("Color", {
		Label = "#ToolWire7Seg_a_colour",
		Red = "wire_7seg_ar",
		Green = "wire_7seg_ag",
		Blue = "wire_7seg_ab",
		Alpha = "wire_7seg_aa",
		ShowAlpha = "1",
		ShowHSV = "1",
		ShowRGB = "1",
		Multiplier = "255"
	})

	panel:AddControl("Color", {
		Label = "#ToolWire7Seg_b_colour",
		Red = "wire_7seg_br",
		Green = "wire_7seg_bg",
		Blue = "wire_7seg_bb",
		Alpha = "wire_7seg_ba",
		ShowAlpha = "1",
		ShowHSV = "1",
		ShowRGB = "1",
		Multiplier = "255"
	})

	panel:AddControl("ComboBox", {
		Label = "#wire_model",
		Options = {
			["Huge 7-seg bar"]	= { wire_7seg_model = "models/segment2.mdl" },
			["Normal 7-seg bar"]		= { wire_7seg_model = "models/segment.mdl" },
			["Small 7-seg bar"]		= { wire_7seg_model = "models/segment3.mdl" },
		}
	})

	panel:CheckBox("#ToolWire7SegTool_worldweld", "wire_7seg_worldweld")
end
