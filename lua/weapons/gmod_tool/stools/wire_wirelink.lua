TOOL.Category		= "Wire - Tools"
TOOL.Name			= "Wirelink (Deprecated)"
TOOL.Command		= nil
TOOL.ConfigName		= ""
TOOL.Tab			= "Wire"

if CLIENT then
    language.Add( "Tool.wire_wirelink.name", "Expression 2 Wirelink Tool (Wire)" )
    language.Add( "Tool.wire_wirelink.desc", "Adds a wirelink output to any wire compatible device, for use with Expression 2" )
    language.Add( "Tool.wire_wirelink.0", "Primary: Add wirelink, Secondary: Remove wirelink" )
end

function TOOL:LeftClick(trace)
	if !trace.HitPos then return false end
	if trace.Entity:IsPlayer() then return false end
	if CLIENT then return true end

	local ply = self:GetOwner()
	if ( trace.Entity:IsValid() && (trace.Entity.Base == "base_wire_entity" || trace.Entity.Inputs || trace.Entity.Outputs) && (trace.Entity.pl == ply || trace.Entity.pl == nil) ) then
		local ent = trace.Entity
		if ent.extended then return false end

		ent.extended = true
		RefreshSpecialOutputs(ent)
		
		WireLib.AddNotify(ply, "Deprecation Warning: Use Wire Advanced", NOTIFY_GENERIC, 4)

		return true
	end

	return false
end

function TOOL:RightClick(trace)
	if !trace.HitPos then return false end
	if trace.Entity:IsPlayer() then return false end
	if CLIENT then return true end

	local ply = self:GetOwner()
	if ( trace.Entity:IsValid() && (trace.Entity.pl == ply || trace.Entity.pl == nil) ) then
		local ent = trace.Entity
		if !ent.extended then return false end

		ent.extended = false
		RefreshSpecialOutputs(ent)

		return true
	end

	return false
end

function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool.wire_wirelink.name", Description = "#Tool.wire_wirelink.desc" })
	panel:Help("This tool is deprecated as its functionality is contained within Wire Advanced, and will be removed soon.")
end
