WireToolSetup.setCategory( "Detection" )
WireToolSetup.open( "ranger", "Ranger", "gmod_wire_ranger", nil, "Rangers" )

if CLIENT then
	language.Add( "Tool.wire_ranger.name", "Ranger Tool (Wire)" )
	language.Add( "Tool.wire_ranger.desc", "Spawns a ranger for use with the wire system." )
	language.Add( "Tool.wire_ranger.range", "Range:" )
	language.Add( "Tool.wire_ranger.default_zero", "Default to zero" )
	language.Add( "Tool.wire_ranger.show_beam", "Show Beam" )
	language.Add( "Tool.wire_ranger.ignore_world", "Ignore world" )
	language.Add( "Tool.wire_ranger.trace_water", "Hit water" )
	language.Add( "Tool.wire_ranger.out_dist", "Output Distance" )
	language.Add( "Tool.wire_ranger.out_pos", "Output Position" )
	language.Add( "Tool.wire_ranger.out_vel", "Output Velocity" )
	language.Add( "Tool.wire_ranger.out_ang", "Output Angle" )
	language.Add( "Tool.wire_ranger.out_col", "Output Color" )
	language.Add( "Tool.wire_ranger.out_val", "Output Value" )
	language.Add( "Tool.wire_ranger.out_sid", "Output SteamID(number)" )
	language.Add( "Tool.wire_ranger.out_uid", "Output UniqueID" )
	language.Add( "Tool.wire_ranger.out_eid", "Output Entity+EntID" )
	language.Add( "Tool.wire_ranger.out_hnrm", "Output HitNormal" )
	language.Add( "Tool.wire_ranger.hires", "High Resolution")
	TOOL.Information = { { name = "left", text = "Create/Update " .. TOOL.Name } }
end
WireToolSetup.BaseLang()
WireToolSetup.SetupMax( 10 )

if SERVER then
	function TOOL:GetConVars()
		return self:GetClientNumber("range"), self:GetClientNumber("default_zero")~=0, self:GetClientNumber("show_beam")~=0, self:GetClientNumber("ignore_world")~=0,
			self:GetClientNumber("trace_water")~=0, self:GetClientNumber("out_dist")~=0, self:GetClientNumber("out_pos")~=0, self:GetClientNumber("out_vel")~=0,
			self:GetClientNumber("out_ang")~=0, self:GetClientNumber("out_col")~=0, self:GetClientNumber("out_val")~=0, self:GetClientNumber("out_sid")~=0,
			self:GetClientNumber("out_uid")~=0, self:GetClientNumber("out_eid")~=0, self:GetClientNumber("out_hnrm")~=0, self:GetClientNumber("hires")~=0
	end
end

TOOL.ClientConVar = {
	model = "models/jaanus/wiretool/wiretool_range.mdl",
	range = 1500,
	default_zero = 1,
	show_beam = 1,
	ignore_world = 0,
	trace_water = 0,
	out_dist = 1,
	out_pos = 0,
	out_vel = 0,
	out_ang = 0,
	out_col = 0,
	out_val = 0,
	out_sid = 0,
	out_uid = 0,
	out_eid = 0,
	out_hnrm = 0,
	hires = 0,
}

function TOOL.BuildCPanel(panel)
	ModelPlug_AddToCPanel(panel, "Laser_Tools", "wire_ranger")
	panel:NumSlider("#Tool.wire_ranger.range", "wire_ranger_range", 1, 1000, 2 )
	panel:CheckBox("#Tool.wire_ranger.default_zero","wire_ranger_default_zero")
	panel:CheckBox("#Tool.wire_ranger.show_beam","wire_ranger_show_beam")
	panel:CheckBox("#Tool.wire_ranger.ignore_world","wire_ranger_ignore_world")
	panel:CheckBox("#Tool.wire_ranger.trace_water","wire_ranger_trace_water")
	panel:CheckBox("#Tool.wire_ranger.out_dist","wire_ranger_out_dist")
	panel:CheckBox("#Tool.wire_ranger.out_pos","wire_ranger_out_pos")
	panel:CheckBox("#Tool.wire_ranger.out_vel","wire_ranger_out_vel")
	panel:CheckBox("#Tool.wire_ranger.out_ang","wire_ranger_out_ang")
	panel:CheckBox("#Tool.wire_ranger.out_col","wire_ranger_out_col")
	panel:CheckBox("#Tool.wire_ranger.out_val","wire_ranger_out_val")
	panel:CheckBox("#Tool.wire_ranger.out_sid","wire_ranger_out_sid")
	panel:CheckBox("#Tool.wire_ranger.out_uid","wire_ranger_out_uid")
	panel:CheckBox("#Tool.wire_ranger.out_eid","wire_ranger_out_eid")
	panel:CheckBox("#Tool.wire_ranger.out_hnrm","wire_ranger_out_hnrm")
	panel:CheckBox("#Tool.wire_ranger.hires","wire_ranger_hires")
end
