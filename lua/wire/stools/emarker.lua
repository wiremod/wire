WireToolSetup.setCategory( "Detection" )
WireToolSetup.open( "emarker", "Entity Marker", "gmod_wire_emarker", nil, "Entity Markers" )

if CLIENT then
	language.Add( "Tool.wire_emarker.name", "Entity Marker Tool (Wire)" )
	language.Add( "Tool.wire_emarker.desc", "Spawns an Entity Marker for use with the wire system." )
	language.Add( "Tool.wire_emarker.0", "Primary: Create Entity Marker/Display Link Info, Secondary: Link Entity Marker, Reload: Unlink Entity Marker" )
	language.Add( "Tool.wire_emarker.1", "Now select the entity to link to.")
end
WireToolSetup.BaseLang()
WireToolSetup.SetupMax( 30 )

TOOL.ClientConVar = {
	model = "models/jaanus/wiretool/wiretool_siren.mdl",
}

if SERVER then
	-- Uses default WireToolObj:MakeEnt's WireLib.MakeWireEnt function
end
	
function TOOL:LeftClick(trace)
	if not trace.HitPos or trace.Entity:IsPlayer() then return false end
	if ( CLIENT ) then return true end
	if not util.IsValidPhysicsObject( trace.Entity, trace.PhysicsBone ) then return false end

	self:SetStage(0)
	local ply = self:GetOwner()

	if ( trace.Entity:GetClass() == "gmod_wire_emarker" ) then
		self.marker = trace.Entity

		if ( !self.marker.mark || !self.marker.mark:IsValid() ) then
			ply:PrintMessage(HUD_PRINTTALK, "Entity Marker not linked")
			return false
		end

		ply:PrintMessage( HUD_PRINTTALK, "Linked model: " .. self.marker.mark:GetModel() )
		self:GetWeapon():SetNetworkedEntity( "WireEntityMark", self.marker.mark )
		self:GetWeapon():SetNetworkedEntity( "WireEntityMarker", self.marker )
	else
		local ent = self:LeftClick_Make( trace, ply )
		return self:LeftClick_PostMake( ent, ply, trace )
	end
	return true
end

function TOOL:RightClick(trace)
	if not trace.HitPos or not IsValid(trace.Entity) or trace.Entity:IsPlayer() then return false end
	if ( CLIENT ) then return true end

	if ( self:GetStage() == 0 && trace.Entity:GetClass() == "gmod_wire_emarker" ) then
		self.marker = trace.Entity
		self:SetStage(1)
		return true
	elseif ( self:GetStage() == 1  ) then
		self.marker:LinkEMarker(trace.Entity)
		self:SetStage(0)
		self:GetOwner():PrintMessage( HUD_PRINTTALK,"Entity Marker linked" )
		self:GetWeapon():SetNetworkedEntity( "WireEntityMark", self.marker.mark )
		self:GetWeapon():SetNetworkedEntity( "WireEntityMarker", self.marker )
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
		self:GetWeapon():SetNetworkedEntity( "WireEntityMark", self.marker ) // Substitute for null, which won't set
		self:GetWeapon():SetNetworkedEntity( "WireEntityMarker", self.marker ) // Set same point so line won't draw
		return true
	end
end

function TOOL:DrawHUD()
	local mark = self:GetWeapon():GetNetworkedEntity( "WireEntityMark" )
	local marker = self:GetWeapon():GetNetworkedEntity( "WireEntityMarker" )
	if not IsValid(mark) or not IsValid(marker) then return end

	local markerpos = marker:GetPos():ToScreen()
	local markpos = mark:GetPos():ToScreen()
	if ( markpos.x > 0 && markpos.y > 0 && markpos.x < ScrW() && markpos.y < ScrH( ) ) then
		surface.SetDrawColor( 255, 255, 100, 255 )
		surface.DrawLine(markerpos.x, markerpos.y, markpos.x, markpos.y)
	end
end

function TOOL.BuildCPanel(panel)
	ModelPlug_AddToCPanel(panel, "Misc_Tools", "wire_emarker")
end