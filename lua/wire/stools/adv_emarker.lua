WireToolSetup.setCategory( "Detection" )
WireToolSetup.open( "adv_emarker", "Adv Entity Marker", "gmod_wire_adv_emarker", nil, "Adv Entity Markers" )

if CLIENT then
	language.Add( "Tool.wire_adv_emarker.name", "Adv Entity Marker Tool (Wire)" )
	language.Add( "Tool.wire_adv_emarker.desc", "Spawns an Adv Entity Marker for use with the wire system." )
	language.Add( "Tool.wire_adv_emarker.0", "Primary: Create Entity Marker, Secondary: Add a link, Reload: Remove a link" )
	language.Add( "Tool.wire_adv_emarker.1", "Now select the entity to link to (Tip: Hold down shift to link to more entities).")
	language.Add( "Tool.wire_adv_emarker.2", "Now select the entity to unlink (Tip: Hold down shift to unlink from more entities). Click Reload on the same entity marker again to clear all linked entities." )
end
WireToolSetup.BaseLang()
WireToolSetup.SetupMax( 10 )

TOOL.ClientConVar = {
	model = "models/jaanus/wiretool/wiretool_siren.mdl",
}

if SERVER then
	-- Uses default WireToolObj:MakeEnt's WireLib.MakeWireEnt function
end

function TOOL:RightClick(trace)
	if not trace.HitPos or not IsValid(trace.Entity) or trace.Entity:IsPlayer() then return false end
	if CLIENT then return true end

	local ent = trace.Entity
	if self:GetStage() == 0 and self:CheckHitOwnClass(trace) then
		self.Controller = ent
		self:SetStage(1)
	else
		local ply = self:GetOwner()
		if self.Controller:LinkEnt(ent) then
			if not ply:KeyDown(IN_SPEED) then self:SetStage(0) end
			WireLib.AddNotify(ply, "Linked entity: " .. tostring(ent) .. " to the "..self.Name, NOTIFY_GENERIC, 5)
		else
			WireLib.AddNotify(ply, "That entity is already linked to the "..self.Name, NOTIFY_ERROR, 5, NOTIFYSOUND_DRIP3)
		end
	end
	return true
end

function TOOL:Reload(trace)
	if not trace.HitPos or not IsValid(trace.Entity) or trace.Entity:IsPlayer() then 
		self:SetStage(0)
		return false 
	end
	if CLIENT then return true end

	local ent = trace.Entity
	if self:GetStage() == 0 and self:CheckHitOwnClass(trace) then
		self.Controller = ent
		self:SetStage(2)
	else
		local ply = self:GetOwner()
		if ent == self.Controller then
			if self:GetStage() == 1 then
				self:SetStage(2)
			else
				self.Controller:ClearEntities()
				WireLib.AddNotify(ply, "All entities unlinked from the "..self.Name, NOTIFY_GENERIC, 7)
				self:SetStage(0)
			end
		else
			if self.Controller:UnlinkEnt( ent ) then
				if not ply:KeyDown(IN_SPEED) then self:SetStage(0) end
				WireLib.AddNotify(ply, "Unlinked entity: " .. tostring(ent) .. " from the "..self.Name, NOTIFY_GENERIC, 5)
			else
				WireLib.AddNotify(ply, "That entity is not linked to the "..self.Name, NOTIFY_ERROR, 5, NOTIFYSOUND_DRIP3)
			end
		end
	end
end

if CLIENT then
	function TOOL:DrawHUD()
		local trace = self:GetOwner():GetEyeTrace()
		if self:CheckHitOwnClass(trace) and trace.Entity.Marks then
			local markerpos = trace.Entity:GetPos():ToScreen()
			for _, ent in pairs(trace.Entity.Marks) do
				if IsValid(ent) then
					local markpos = ent:GetPos():ToScreen()
					surface.SetDrawColor( 255,255,100,255 )
					surface.DrawLine( markerpos.x, markerpos.y, markpos.x, markpos.y )
				end
			end
		end
	end

	function TOOL.BuildCPanel(panel)
		ModelPlug_AddToCPanel(panel, "Misc_Tools", "wire_adv_emarker")
	end
end