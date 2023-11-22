TOOL.Category	= "Tools"
TOOL.Name		= "Output Remover"
TOOL.Tab		= "Wire"

if CLIENT then
	language.Add("Tool.wire_outputremover.name", "Wire Output Remover")
	language.Add("Tool.wire_outputremover.desc", "Removes auto-generated entity or wirelink outputs.")
	language.Add("Tool.wire_outputremover.desc2", "Used to connect wirable props.")
	language.Add("Tool.wire_outputremover.left", "Remove entity output")
	language.Add("Tool.wire_outputremover.right","Remove wirelink output")
	language.Add("Tool.wire_outputremover.reload", "Remove both")
	TOOL.Information = { "left", "right", "reload" }

	TOOL.Wire_ToolMenuIcon = "icon16/disconnect.png"
end

if SERVER then
	local function removeWirelinkOutput(ent)
		if ent.EntityMods and ent.EntityMods.CreateWirelinkOutput and ent.Outputs and ent.Outputs.wirelink then
			WireLib.DisconnectOutput(ent, "wirelink")
			ent.Outputs.wirelink = nil
			WireLib.RemoveOutPort(ent, "wirelink")
			duplicator.ClearEntityModifier(ent, "CreateWirelinkOutput")
			WireLib._SetOutputs(ent)
		end
	end

	local function removeEntityOutput(ent)
		if ent.EntityMods and ent.EntityMods.CreateEntityOutput and ent.Outputs and ent.Outputs.entity then
			WireLib.DisconnectOutput(ent, "entity")
			ent.Outputs.entity = nil
			WireLib.RemoveOutPort(ent, "entity")
			duplicator.ClearEntityModifier(ent, "CreateEntityOutput")
			WireLib._SetOutputs(ent)
		end
	end

	function TOOL:LeftClick(trace)
		local ent = trace.Entity
		if ent:IsValid() then
			removeEntityOutput(ent)
			return true
		end
		return false
	end

	function TOOL:RightClick(trace)
		local ent = trace.Entity
		if ent:IsValid() then
			removeWirelinkOutput(ent)
			return true
		end
		return false
	end

	function TOOL:Reload(trace)
		local ent = trace.Entity
		if ent:IsValid() then
			removeEntityOutput(ent)
			removeWirelinkOutput(ent)
			return true
		end
		return false
	end
else
	function TOOL.BuildCPanel(panel)
		panel:AddControl("Header", { Text = "#Tool.wire_outputremover.name", Description = "#Tool.wire_outputremover.desc" })
	end
end
