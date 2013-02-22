WireToolSetup.setCategory( "Detection" )
WireToolSetup.open( "damage_detector", "Damage Detector", "gmod_wire_damage_detector", nil, "Damage Detectors" )

if CLIENT then
	language.Add( "Tool.wire_damage_detector.name", "Damage Detector Tool (Wire)" )
	language.Add( "Tool.wire_damage_detector.desc", "Spawns a damage detector for use with the wire system" )
	language.Add( "Tool.wire_damage_detector.0", "Primary: Create/Update Detector, Secondary: Link Detector to an entity, Reload: Unlink Detector" )
	language.Add( "Tool.wire_damage_detector.1", "Now select the entity to link to." )
	language.Add( "Tool.wire_damage_detector.includeconstrained", "Include Constrained Props" )
end
WireToolSetup.BaseLang()
WireToolSetup.SetupMax( 10, TOOL.Mode.."s" , "You've hit the Wire "..TOOL.PluralName.." limit!" )

TOOL.ClientConVar = {
	model = "models/jaanus/wiretool/wiretool_siren.mdl",
	includeconstrained = 0
}

if SERVER then
	function TOOL:GetConVars()
		return self:GetClientNumber( "includeconstrained" )
	end

	function TOOL:MakeEnt( ply, model, Ang, trace )
		return MakeWireDamageDetector( ply, trace.HitPos, Ang, model, self:GetConVars() )
	end
end
	
function TOOL:LeftClick(trace)
	if not trace.HitPos or trace.Entity:IsPlayer() then return false end
	if ( CLIENT ) then return true end
	if not util.IsValidPhysicsObject( trace.Entity, trace.PhysicsBone ) then return false end

	self:SetStage(0)
	local ply = self:GetOwner()

	if ( trace.Entity:GetClass() == "gmod_wire_damage_detector" ) then
		trace.Entity:Setup( self:GetConVars() )
		self:GetWeapon():SetNetworkedEntity( "WireDamageDetectorLink", Entity(trace.Entity.linked_entities[0]) )
		self:GetWeapon():SetNetworkedEntity( "WireDamageDetectorEnt", trace.Entity )
	else
		local ent = self:LeftClick_Make( trace, ply )
		return self:LeftClick_PostMake( ent, ply, trace )
	end
	return true
end

function TOOL:RightClick(trace)
	if not trace.HitPos or not IsValid(trace.Entity) or trace.Entity:IsPlayer() then return false end
	if ( CLIENT ) then return true end

	if self:GetStage() == 0 and trace.Entity:GetClass() == "gmod_wire_damage_detector" then
		self.detector = trace.Entity
		self:SetStage(1)
		return true
	elseif self:GetStage() == 1 then
		self.detector:LinkEntity( trace.Entity )
		self:SetStage(0)
		self:GetOwner():PrintMessage( HUD_PRINTTALK,"Damage Detector linked" )
		self:GetWeapon():SetNetworkedEntity( "WireDamageDetectorLink", trace.Entity )
		self:GetWeapon():SetNetworkedEntity( "WireDamageDetectorEnt", self.detector )
		return true
	else
		self:SetStage(0)
		self:GetOwner():PrintMessage( HUD_PRINTTALK,"Invalid Target" )
		return false
	end
end

function TOOL:Reload(trace)
	if not trace.HitPos or trace.Entity:IsPlayer() then return false end
	if ( CLIENT ) then return true end

	self:SetStage(0)
	local detector = trace.Entity
	if !IsValid(detector) then return false end
	if detector:GetClass() == "gmod_wire_damage_detector" then
		detector:Unlink()
		self:GetOwner():PrintMessage( HUD_PRINTTALK,"Damage Detector unlinked" )
		self:GetWeapon():SetNetworkedEntity( "WireDamageDetectorLink", detector )
		self:GetWeapon():SetNetworkedEntity( "WireDamageDetectorEnt", detector ) // Set same point so line won't draw
		return true
	end
end

function TOOL:DrawHUD()
	local link = self:GetWeapon():GetNetworkedEntity( "WireDamageDetectorLink" )
	local ent = self:GetWeapon():GetNetworkedEntity( "WireDamageDetectorEnt" )
	if !IsValid(link) or !IsValid(ent) then return end

	local linkpos = link:GetPos():ToScreen()
	local entpos = ent:GetPos():ToScreen()
	if linkpos.x > 0 and linkpos.y > 0 and linkpos.x < ScrW() and linkpos.y < ScrH( ) then
		surface.SetDrawColor( 255, 255, 100, 255 )
		surface.DrawLine(entpos.x, entpos.y, linkpos.x, linkpos.y)
	end
end

function TOOL.BuildCPanel(panel)
	ModelPlug_AddToCPanel(panel, "Misc_Tools", "wire_damage_detector")
	panel:CheckBox("#Tool.wire_damage_detector.includeconstrained","wire_damage_detector_includeconstrained")
end