WireToolSetup.setCategory( "Detection" )
WireToolSetup.open( "emarker", "Entity Marker", "gmod_wire_emarker", nil, "Entity Markers" )

if CLIENT then
	language.Add( "Tool.wire_emarker.name", "Entity Marker Tool (Wire)" )
	language.Add( "Tool.wire_emarker.desc", "Spawns an Entity Marker for use with the wire system." )
	TOOL.Information = {
		{ name = "left_0", stage = 0, text = "Create Entity Marker/Display Link Info" },
		{ name = "right_0", stage = 0, text = "Link Entity Marker" },
		{ name = "reload_0", stage = 0, text = "Unlink Entity Marker" },
		{ name = "right_1", stage = 1, text = "Now select the entity to link to" },
	}
end
WireToolSetup.BaseLang()
WireToolSetup.SetupMax( 30 )

TOOL.ClientConVar = {
	model = "models/jaanus/wiretool/wiretool_siren.mdl",
}

function TOOL:LeftClick(trace)
	if not trace.HitPos or trace.Entity:IsPlayer() then return false end
	if ( CLIENT ) then return true end
	if not util.IsValidPhysicsObject( trace.Entity, trace.PhysicsBone ) then return false end

	self:SetStage(0)
	local ply = self:GetOwner()

	if ( trace.Entity:GetClass() == "gmod_wire_emarker" ) then
		self.marker = trace.Entity

		if ( not self.marker.mark or not self.marker.mark:IsValid() ) then
			ply:PrintMessage(HUD_PRINTTALK, "Entity Marker not linked")
			return false
		end

		ply:PrintMessage( HUD_PRINTTALK, "Linked model: " .. self.marker.mark:GetModel() )
		self:GetWeapon():SetNWEntity( "WireEntityMark", self.marker.mark )
		self:GetWeapon():SetNWEntity( "WireEntityMarker", self.marker )
	else
		local ent = self:LeftClick_Make( trace, ply )
		return self:LeftClick_PostMake( ent, ply, trace )
	end
	return true
end

function TOOL:RightClick(trace)
	if not trace.HitPos or not IsValid(trace.Entity) or trace.Entity:IsPlayer() then return false end
	if ( CLIENT ) then return true end

	if ( self:GetStage() == 0 and trace.Entity:GetClass() == "gmod_wire_emarker" ) then
		self.marker = trace.Entity
		self:SetStage(1)
		return true
	elseif ( self:GetStage() == 1  ) then
		self.marker:LinkEMarker(trace.Entity)
		self:SetStage(0)
		self:GetOwner():PrintMessage( HUD_PRINTTALK,"Entity Marker linked" )
		self:GetWeapon():SetNWEntity( "WireEntityMark", self.marker.mark )
		self:GetWeapon():SetNWEntity( "WireEntityMarker", self.marker )
		return true
	else
		return false
	end
end

function TOOL:Reload(trace)
	if not trace.HitPos or trace.Entity:IsPlayer() then return false end
	if ( CLIENT ) then return true end

	self:SetStage(0)
	local marker = trace.Entity
	if not IsValid(marker) then return false end
	if (marker:GetClass() == "gmod_wire_emarker") then
		marker:UnLinkEMarker()
		self:GetOwner():PrintMessage( HUD_PRINTTALK,"Entity Marker unlinked" )
		self:GetWeapon():SetNWEntity( "WireEntityMark", self.marker ) -- Substitute for null, which won't set
		self:GetWeapon():SetNWEntity( "WireEntityMarker", self.marker ) -- Set same point so line won't draw
		return true
	end
end

function TOOL:DrawHUD()
	local mark = self:GetWeapon():GetNWEntity( "WireEntityMark" )
	local marker = self:GetWeapon():GetNWEntity( "WireEntityMarker" )
	if not IsValid(mark) or not IsValid(marker) then return end

	local markerpos = marker:GetPos():ToScreen()
	local markpos = mark:GetPos():ToScreen()
	if ( markpos.x > 0 and markpos.y > 0 and markpos.x < ScrW() and markpos.y < ScrH() ) then
		surface.SetDrawColor( 255, 255, 100, 255 )
		surface.DrawLine(markerpos.x, markerpos.y, markpos.x, markpos.y)
	end
end

function TOOL.BuildCPanel(panel)
	ModelPlug_AddToCPanel(panel, "Misc_Tools", "wire_emarker")
end
