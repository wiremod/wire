WireToolSetup.setCategory( "Visuals/Holographic" )
WireToolSetup.open( "holoemitter", "HoloEmitter", "gmod_wire_holoemitter", nil, "HoloEmitters" )

if CLIENT then
	language.Add( "tool.wire_holoemitter.name", "Holographic Emitter Tool (Wire)" )
	language.Add( "tool.wire_holoemitter.desc", "The emitter required for holographic projections" )
	language.Add( "Tool.wire_holoemitter.fadetime", "Max fade time" )
	language.Add( "Tool.wire_holoemitter.fadetime.description", "Client side max fade time. Set to 0 to never fade (WARNING: May cause FPS issues if set to 0 or too high)." )
	language.Add( "Tool.wire_holoemitter.keeplatestdot", "Keep latest dot indefinitely (prevent fading)." )
	TOOL.Information = {
		{ name = "left_0", stage = 0, text = "Create emitter" },
		{ name = "right_0", stage = 0, text = "Link emitter to any entity (makes it draw local to that entity instead)" },
		{ name = "right_1", stage = 1, text = "Link to entity (click the same holoemitter again to unlink it)" },
		{ name = "reload", stage = 1, text = "Cancel linking" },
	}
end
WireToolSetup.BaseLang()
WireToolSetup.SetupMax( 10 )

TOOL.ClientConVar = {
	model = "models/jaanus/wiretool/wiretool_range.mdl",
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

function TOOL:Reload()
	if self:GetStage() == 1 then
		self:SetStage(0)
		self.Linked = nil
		return false
	end
end

function TOOL.BuildCPanel( panel )
	WireToolHelpers.MakePresetControl(panel, "wire_holoemitter")
	WireDermaExts.ModelSelect(panel, "wire_holoemitter_model", list.Get( "Wire_Misc_Tools_Models" ), 1)

	panel:NumSlider("#Tool.wire_holoemitter.fadetime", "cl_wire_holoemitter_maxfadetime", 0, 100, 1)
	panel:Help( "#Tool.wire_holoemitter.fadetime.description" )
	panel:CheckBox("#Tool.wire_holoemitter.keeplatestdot", "wire_holoemitter_keeplatestdot")
end
