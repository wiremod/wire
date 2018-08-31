WireToolSetup.setCategory( "Visuals/Holographic" )
WireToolSetup.open( "hologrid", "HoloGrid", "gmod_wire_hologrid", nil, "HoloGrids" )

if CLIENT then
	language.Add( "tool.wire_hologrid.name", "Holographic Grid Tool (Wire)" )
	language.Add( "tool.wire_hologrid.desc", "The grid to aid in holographic projections" )
	TOOL.Information = {
		{ name = "left_0", stage = 0, text = "Create grid" },
		{ name = "right_0", stage = 0, text = "Link HoloGrid with HoloEmitter or reference entity" },
		{ name = "reload_0", stage = 0, text = "Unlink HoloEmitter or HoloGrid" },
		{ name = "right_1", stage = 1, text = "Select the HoloGrid to link to" },
	}
	language.Add( "Tool_wire_hologrid_usegps", "Use GPS coordinates" )
end
WireToolSetup.BaseLang()
WireToolSetup.SetupMax( 20 )

if SERVER then
	function TOOL:GetConVars()
		return self:GetClientNumber( "usegps" )~=0
	end

	-- Uses default WireToolObj:MakeEnt's WireLib.MakeWireEnt function
end

TOOL.ClientConVar = {
	model = "models/jaanus/wiretool/wiretool_siren.mdl",
	usegps = 0,
}

function TOOL:RightClick( trace )
	if CLIENT then return true end

	local ent = trace.Entity
	if (self:GetStage() == 0) then
		if (ent:GetClass() == "gmod_wire_holoemitter") then
			self.Target = ent
			self:SetStage(1)
		else
			self:GetOwner():ChatPrint("That's not a holoemitter.")
			return false
		end
	else
		if (self.Target == ent or ent:IsWorld()) then
			self:GetOwner():ChatPrint("Holoemitter unlinked.")
			self.Target:UnLink()
			self:SetStage(0)
			return true
		end
		self.Target:Link( ent )
		self:SetStage(0)
		self:GetOwner():ChatPrint( "Holoemitter linked to entity (".. tostring(ent)..")" )
	end

	return true
end

function TOOL.Reload(trace)
	self.Linked = nil
	self:SetStage(0)

	if IsValid(trace.Entity) and trace.Entity:GetClass() == "gmod_wire_hologrid" then
		self.Linked:TriggerInput("Reference", nil)
		return true
	end
end

function TOOL.BuildCPanel( panel )
	WireDermaExts.ModelSelect(panel, "wire_hologrid_model", list.Get( "Wire_Misc_Tools_Models" ), 1)
	panel:CheckBox("#Tool_wire_hologrid_usegps", "wire_hologrid_usegps")
end
