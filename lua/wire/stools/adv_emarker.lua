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
WireToolSetup.SetupMax( 3, TOOL.Mode.."s" , "You've hit the Wire "..TOOL.PluralName.." limit!" )

TOOL.ClientConVar = {
	model = "models/jaanus/wiretool/wiretool_siren.mdl",
}

if SERVER then
	function TOOL:GetConVars() end

	function TOOL:MakeEnt( ply, model, Ang, trace )
		return MakeWireAdvEMarker( ply, trace.HitPos, Ang, model, self:GetConVars() )
	end
end

function TOOL:RightClick(trace)
	if not trace.HitPos or not IsValid(trace.Entity) or trace.Entity:IsPlayer() then return false end
	if ( CLIENT ) then return true end

	local ent = trace.Entity
	if (self:GetStage() == 0 and ent:GetClass() == "gmod_wire_adv_emarker") then
		self.marker = ent
		self:SetStage(1)
	elseif (self:GetStage() == 1) then
		local ret = self.marker:AddEnt(ent)
		local ply = self:GetOwner()
		if (ret) then
			if (!ply:KeyDown(IN_SPEED)) then self:SetStage(0) end
			ply:ChatPrint("Added entity: " .. tostring(ent) .. " to the Adv Entity Marker.")
		else
			ply:ChatPrint("The Entity Marker is already linked to that entity.")
		end
	end
	return true
end

function TOOL:Reload(trace)
	if not trace.HitPos or trace.Entity:IsPlayer() then return false end
	if ( CLIENT ) then return true end

	local ent = trace.Entity
	if not IsValid(ent) then return false end
	if (self:GetStage() == 0 and ent:GetClass() == "gmod_wire_adv_emarker") then
		self.marker = ent
		self:SetStage(2)
	elseif (self:GetStage() == 2) then
		local ply = self:GetOwner()
		if (ent == self.marker) then
			ent:ClearEntities()
			ply:ChatPrint("Adv Entity Marker unlinked from all entities.")
			self:SetStage(0)
		else
			local ret = self.marker:CheckEnt(ent)
			if (ret) then
				if (!ply:KeyDown(IN_SPEED)) then self:SetStage(0) end
				self.marker:RemoveEnt( ent )
				ply:ChatPrint("Removed entity: " .. tostring(ent) .. " from the Adv Entity Marker.")
			else
				ply:ChatPrint("The Entity Marker is not linked to that entity.")
			end
		end
	end
end

if CLIENT then
	function TOOL:DrawHUD()
		local trace = self:GetOwner():GetEyeTrace()
		if IsValid(trace.Entity) and trace.Entity:GetClass() == "gmod_wire_adv_emarker" then
			local marks = trace.Entity.Marks
			if (marks and #marks > 0) then
				local markerpos = trace.Entity:GetPos():ToScreen()
				for _, ent in pairs( marks ) do
					if (ent:IsValid()) then
						local markpos = ent:GetPos():ToScreen()
						surface.SetDrawColor( 255,255,100,255 )
						surface.DrawLine( markerpos.x, markerpos.y, markpos.x, markpos.y )
					end
				end
			end
		end
	end
	usermessage.Hook("Wire_Adv_EMarker_Links", function(um)
		local Marker = Entity(um:ReadShort())
		if (Marker:IsValid()) then
			local nr = um:ReadShort()
			local marks = {}
			for i=1,nr do
				local en = Entity(um:ReadShort())
				if (en:IsValid()) then
					marks[#marks+1] = en
				end
			end
			Marker.Marks = marks
		end
	end)

	function TOOL.BuildCPanel(panel)
		ModelPlug_AddToCPanel(panel, "Misc_Tools", "wire_adv_emarker")
	end
end