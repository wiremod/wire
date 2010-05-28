AddCSLuaFile( "gates.lua" )


if CLIENT then
	language.Add( "Tool_wire_gate_arithmetic_name", "Arithmetic Gate Tool (Wire)" )
	language.Add( "Tool_wire_gate_arithmetic_desc", "Spawns an arithmetic gate for use with the wire system." )
	language.Add( "Tool_wire_gate_arithmetic_0", "Primary: Create/Update Arithmetic Gate, Reload: Unparent gate (if parented)" )

	language.Add( "Tool_wire_gate_rd_name", "Ranger Data Gate Tool (Wire)" )
	language.Add( "Tool_wire_gate_rd_desc", "Spawns a ranger data gate for use with the wire system." )
	language.Add( "Tool_wire_gate_rd_0", "Primary: Create/Update Ranger Data Gate, Reload: Unparent gate (if parented)" )

	language.Add( "Tool_wire_gate_vector_name", "Vector Gate Tool (Wire)" )
	language.Add( "Tool_wire_gate_vector_desc", "Spawns a vector gate for use with the wire system." )
	language.Add( "Tool_wire_gate_vector_0", "Primary: Create/Update Vector Gate, Reload: Unparent gate (if parented)" )

	language.Add( "Tool_wire_gate_angle_name", "Angle Gate Tool (Wire)" )
	language.Add( "Tool_wire_gate_angle_desc", "Spawns an angle gate for use with the wire system." )
	language.Add( "Tool_wire_gate_angle_0", "Primary: Create/Update Angle Gate, Reload: Unparent gate (if parented)" )

	language.Add( "Tool_wire_gate_string_name", "String Gate Tool (Wire)" )
	language.Add( "Tool_wire_gate_string_desc", "Spawns a string gate for use with the wire system." )
	language.Add( "Tool_wire_gate_string_0", "Primary: Create/Update String Gate, Reload: Unparent gate (if parented)" )

	language.Add( "Tool_wire_gate_entity_name", "Entity Gate Tool (Wire)" )
	language.Add( "Tool_wire_gate_entity_desc", "Spawns an entity gate for use with the wire system." )
	language.Add( "Tool_wire_gate_entity_0", "Primary: Create/Update Entity Gate, Reload: Unparent gate (if parented)" )

	language.Add( "Tool_wire_gate_comparison_name", "Comparison Gate Tool (Wire)" )
	language.Add( "Tool_wire_gate_comparison_desc", "Spawns a comparison gate for use with the wire system." )
	language.Add( "Tool_wire_gate_comparison_0", "Primary: Create/Update Comparison Gate, Reload: Unparent gate (if parented)" )

	language.Add( "Tool_wire_gate_duplexer_name", "Duplexer Chip Tool (Wire)" )
	language.Add( "Tool_wire_gate_duplexer_desc", "Spawns a duplexer chip for use with the wire system." )
	language.Add( "Tool_wire_gate_duplexer_0", "Primary: Create/Update Duplexer Chip, Reload: Unparent gate (if parented)" )

	language.Add( "Tool_wire_gate_logic_name", "Logic Gate Tool (Wire)" )
	language.Add( "Tool_wire_gate_logic_desc", "Spawns a logic gate for use with the wire system." )
	language.Add( "Tool_wire_gate_logic_0", "Primary: Create/Update Logic Gate, Reload: Unparent gate (if parented)" )

	language.Add( "Tool_wire_gate_bitwise_name", "Bitwise Gate Tool (Wire)" )
	language.Add( "Tool_wire_gate_bitwise_desc", "Spawns a bitwise gate for use with the wire system." )
	language.Add( "Tool_wire_gate_bitwise_0", "Primary: Create/Update Bitwise Gate, Reload: Unparent gate (if parented)" )

	language.Add( "Tool_wire_gate_memory_name", "Memory Chip Tool (Wire)" )
	language.Add( "Tool_wire_gate_memory_desc", "Spawns a memory chip for use with the wire system." )
	language.Add( "Tool_wire_gate_memory_0", "Primary: Create/Update Memory Chip, Reload: Unparent gate (if parented)" )

	language.Add( "Tool_wire_gate_selection_name", "Selection Chip Tool (Wire)" )
	language.Add( "Tool_wire_gate_selection_desc", "Spawns a selection chip for use with the wire system." )
	language.Add( "Tool_wire_gate_selection_0", "Primary: Create/Update Selection Chip, Reload: Unparent gate (if parented)" )

	language.Add( "Tool_wire_gate_time_name", "Time Chip Tool (Wire)" )
	language.Add( "Tool_wire_gate_time_desc", "Spawns a time chip for use with the wire system." )
	language.Add( "Tool_wire_gate_time_0", "Primary: Create/Update Time Chip, Reload: Unparent gate (if parented)" )

	language.Add( "Tool_wire_gate_trig_name", "Trig Gate Tool (Wire)" )
	language.Add( "Tool_wire_gate_trig_desc", "Spawns a trig gate for use with the wire system." )
	language.Add( "Tool_wire_gate_trig_0", "Primary: Create/Update Trig Gate, Reload: Unparent gate (if parented)" )

	language.Add( "Tool_wire_gates_name", "Gate Tool (Wire)" )
	language.Add( "Tool_wire_gates_desc", "Spawns a gate for use with the wire system." )
	language.Add( "Tool_wire_gates_0", "Primary: Create/Update Gate, Reload: Unparent gate (if parented)" )

	language.Add( "WireGatesTool_action", "Gate action" )
	language.Add( "WireGatesTool_noclip", "NoCollide" )
	language.Add( "WireGatesTool_weld", "Weld" )
	language.Add( "WireGatesTool_parent", "Parent" )
	language.Add( "sboxlimit_wire_gates", "You've hit your gates limit!" )
	language.Add( "undone_gmod_wire_gate", "Undone wire gate" )
	language.Add( "Cleanup_gmod_wire_gate", "Wire Gates" )
	language.Add( "Cleaned_gmod_wire_gate", "Cleaned up wire gates" )
end

if SERVER then
	CreateConVar('sbox_maxwire_gates', 30)
	CreateConVar('sbox_maxwire_gate_comparisons', 30)
	CreateConVar('sbox_maxwire_gate_duplexer', 16)
	CreateConVar('sbox_maxwire_gate_logics', 30)
	CreateConVar('sbox_maxwire_gate_bitwises', 30)
	CreateConVar('sbox_maxwire_gate_memorys', 30)
	CreateConVar('sbox_maxwire_gate_selections', 30)
	CreateConVar('sbox_maxwire_gate_times', 30)
	CreateConVar('sbox_maxwire_gate_trigs', 30)
	ModelPlug_Register("gate")
end

cleanup.Register("wire_gates")

local base_tool = {
	Category       = "Wire - Control",
	WireClass      = "gmod_wire_gate",
	LeftClick_Make = WireToolMakeGate,
	ClientConVar   = {
		noclip	= 1,
		model	= "models/jaanus/wiretool/wiretool_gate.mdl",
		weld	= 0,
		parent 	= 1,
	},
}

local function openTOOL()
	TOOL = WireToolObj:Create()
	table.Merge(TOOL, base_tool)
end

local function GateGetModel(self)
	return self:GetOwner():GetInfo( "wire_gates_model" )
end

local function buildTOOL( s_name, s_def )
	openTOOL()
	local s_mode             = "wire_gate_"..string.lower(s_name)
	TOOL.Mode                = s_mode
	TOOL.Name                = "Gate - "..s_name
	TOOL.ClientConVar.action = s_def
	TOOL.GetModel            = GateGetModel
	if CLIENT then
		TOOL.BuildCPanel = function(panel)
			local nocollidebox = panel:CheckBox("#WireGatesTool_noclip", s_mode.."_noclip")
			local weldbox = panel:CheckBox("#WireGatesTool_weld", s_mode.."_weld")
			local parentbox = panel:CheckBox("#WireGatesTool_parent",s_mode.."_parent")

			function weldbox.Button:DoClick() -- block the weld checkbox from being toggled while the parent box is checked
				if (parentbox:GetChecked() == false) then
					self:Toggle()
				end
			end

			function parentbox.Button:DoClick() -- when you check the parent box, uncheck the weld box and check the nocollide box
				self:Toggle()
				if (self:GetChecked() == true) then
					weldbox:SetValue(0)
					nocollidebox:SetValue(1)
				end
			end

			local Actions = {
				Label = "#WireGatesTool_action",
				MenuButton = "0",
				Height = 180,
				Options = {}
			}
			for k,v in pairs(GateActions) do
				if(v.group == s_name) then
					Actions.Options[v.name or "No Name"] = {}
					Actions.Options[v.name or "No Name"][s_mode.."_action"] = k
				end
			end
			panel:AddControl("ListBox", Actions)
			WireDermaExts.ModelSelect(panel, "wire_gates_model", list.Get("Wire_gate_Models"), 3, true)
		end
	end
	WireToolSetup.close()
end


buildTOOL( "Arithmetic", "+" )

buildTOOL( "Comparison", "<" )

buildTOOL( "Ranger", "trace" )

buildTOOL( "Vector", "addition" )

buildTOOL( "Angle", "addition" )

buildTOOL( "String", "index" )

buildTOOL( "Entity", "owner" )

buildTOOL( "Array", "table_8duplexer" )

buildTOOL( "Logic", "and" )

buildTOOL( "Bitwise", "and" )

buildTOOL( "Memory", "latch" )

buildTOOL( "Selection", "min" )

buildTOOL( "Time", "timer" )

buildTOOL( "Trig", "sin" )


openTOOL()
TOOL.Mode                = "wire_gates"
TOOL.Category            = "Wire - Tools"
TOOL.Name                = "Gate"
TOOL.ClientConVar.action = "+"

function TOOL.BuildCPanel(panel)
	WireDermaExts.ModelSelect(panel, "wire_gates_model", list.Get("Wire_gate_Models"), 3, true)

	panel:CheckBox("#WireGatesTool_noclip", "wire_gates_noclip")
	panel:CheckBox("#WireGatesTool_weld", "wire_gates_weld")

	local tree = vgui.Create( "DTree" )
	tree:SetTall( 400 )
	panel:AddPanel( tree )

	for gatetype, gatefuncs in pairs(WireGatesSorted) do
		local node = tree:AddNode( gatetype.." Gates" )
		table.SortByMember( gatefuncs, "name", true )
		for k,v in pairs(gatefuncs) do
			local cnode = node:AddNode( v.name or "No Name" )
			cnode.myname = v.name
			cnode.myaction = k
			function cnode:DoClick()
				RunConsoleCommand( "wire_gates_action", self.myaction )
			end
			cnode.Icon:SetImage( "gui/silkicons/newspaper" )
		end
		node.ChildNodes:SortByMember( "myname", false )
	end

end

WireToolSetup.close()

base_tool = nil
