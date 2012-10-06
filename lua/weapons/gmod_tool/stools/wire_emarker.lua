TOOL.Category		= "Wire - Detection"
TOOL.Name			= "Entity Marker"
TOOL.Command		= nil
TOOL.ConfigName		= ""
TOOL.Tab			= "Wire"

if ( CLIENT ) then
    language12.Add( "Tool_wire_emarker_name", "Entity Marker Tool (Wire)" )
    language12.Add( "Tool_wire_emarker_desc", "Spawns an Entity Marker for use with the wire system." )
    language12.Add( "Tool_wire_emarker_0", "Primary: Create Entity Marker/Display Link Info, Secondary: Link Entity Marker, Reload: Unlink Entity Marker" )
	language12.Add( "Tool_wire_emarker_1", "Now select the entity to link to.")
	language12.Add( "sboxlimit_wire_emarker", "You've hit entity marker limit!" )
	language12.Add( "undone_wireemarker", "Undone Wire Entity Marker" )
elseif ( SERVER ) then
    CreateConVar('sbox_maxwire_emarkers',30)
end

TOOL.ClientConVar[ "model" ] = "models/jaanus/wiretool/wiretool_siren.mdl"

cleanup.Register( "wire_emarkers" )

// Variable "marker" refers to the entity marker
// Variable "mark" refers to the linked entity

local EntityMarkers = {}

function Add_EntityMarker( r )
	table.insert( EntityMarkers, r )
end

function EntityMarker_Removed(entity)
	for i, o in ipairs( EntityMarkers ) do
		if !IsEntity(o.Entity) then
			table.remove(EntityMarkers, i)
		elseif o.mark==entity then
			o:UnLinkEMarker()
		end
	end
end
hook.Add("EntityRemoved","EntityMarkerEntRemoved",EntityMarker_Removed)

function TOOL:LeftClick(trace)
	if (!trace.HitPos) then return false end
	if (trace.Entity:IsPlayer()) then return false end
	if ( CLIENT ) then return true end
	if not util.IsValidPhysicsObject( trace.Entity, trace.PhysicsBone ) then return false end

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
		return true
	else
		if (pl!=nil) then if ( !self:GetSWEP():CheckLimit( "wire_emarkers" ) ) then return false end end
		local Ang = trace.HitNormal:Angle()
		Ang.pitch = Ang.pitch + 90

		local wire_emarker = MakeWireEmarker( ply, trace.HitPos, Ang, self:GetModel() )

		local min = wire_emarker:OBBMins()
		wire_emarker:SetPos( trace.HitPos - trace.HitNormal * (min.z) )

		local const = WireLib.Weld( wire_emarker, trace.Entity, trace.PhysicsBone, true )
		undo.Create("WireEmarker")
			undo.AddEntity( wire_emarker )
			undo.AddEntity( const )
			undo.SetPlayer( ply )
		undo.Finish()

		if (ply!=nil) then ply:AddCleanup( "wire_emarkers", wire_emarker ) end

		return true
	end
end

function TOOL:RightClick(trace)
	if (!trace.HitPos) then return false end
	if (trace.Entity:IsPlayer()) then return false end
	if ( CLIENT ) then return true end

	if ( trace.Entity:IsValid() ) then
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
end

function TOOL:Reload(trace)
	if (!trace.HitPos) then return false end
	if (trace.Entity:IsPlayer()) then return false end
	if ( CLIENT ) then return true end

	self:SetStage(0)
	local marker = trace.Entity
	if (!marker || !marker:IsValid()) then return false end
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
	if ( !mark || !marker || !mark:IsValid() || !marker:IsValid() ) then return end

	local markerpos = marker:GetPos():ToScreen()
	local markpos = mark:GetPos():ToScreen()
	if ( markpos.x > 0 && markpos.y > 0 && markpos.x < ScrW() && markpos.y < ScrH( ) ) then
		surface.SetDrawColor( 255, 255, 100, 255 )
		surface.DrawLine(markerpos.x, markerpos.y, markpos.x, markpos.y)
	end
end

if SERVER then

	function MakeWireEmarker( pl, Pos, Ang, model, nocollide )
		if (pl!=nil) then if (!pl:CheckLimit("wire_emarkers")) then return false end end

		local wire_emarker = ents.Create("gmod_wire_emarker")
		wire_emarker:SetPos(Pos)
		wire_emarker:SetAngles(Ang)
		wire_emarker:SetModel( Model(model or "models/jaanus/wiretool/wiretool_siren.mdl") )
		wire_emarker:Spawn()
		wire_emarker:Activate()

		wire_emarker:SetPlayer(pl)

		if ( nocollide == true ) then wire_emarker:GetPhysicsObject():EnableCollisions( false ) end

		local ttable = {
			pl			= pl,
			nocollide	= nocollide,
		}
		table.Merge( wire_emarker:GetTable(), ttable )

		if (pl!=nil) then pl:AddCount( "wire_emarkers", wire_emarker ) end

		return wire_emarker
	end

	duplicator.RegisterEntityClass( "gmod_wire_emarker", MakeWireEmarker, "Pos", "Ang", "Model", "nocollide" )

end

function TOOL:UpdateGhostEmarker( ent, player )

	if ( !ent || !ent:IsValid() ) then return end

	local trace = player:GetEyeTrace()

	if (!trace.Hit || trace.Entity:IsPlayer() || trace.Entity:GetClass() == "gmod_wire_emarker" ) then
		ent:SetNoDraw( true )
		return
	end

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90

	local min = ent:OBBMins()
	ent:SetPos( trace.HitPos - trace.HitNormal * min.z )
	ent:SetAngles( Ang )

	ent:SetNoDraw( false )

end

function TOOL:Think()
	local model = self:GetModel()

	if (!self.GhostEntity || !self.GhostEntity:IsValid() || self.GhostEntity:GetModel() != model ) then
		self:MakeGhostEntity( Model(model), Vector(0,0,0), Angle(0,0,0) )
	end

	self:UpdateGhostEmarker( self.GhostEntity, self:GetOwner() )
end

function TOOL:GetModel()
	local model = "models/jaanus/wiretool/wiretool_siren.mdl"
	local modelcheck = self:GetClientInfo( "model" )

	if (util.IsValidModel(modelcheck) and util.IsValidProp(modelcheck)) then
		model = modelcheck
	end

	return model
end

if (CLIENT) then
	function TOOL.BuildCPanel(panel)
		panel:AddControl("Header", { Text = "#Tool_wire_emarker_name", Description = "#Tool_wire_emarker_desc" })
		WireDermaExts.ModelSelect(panel, "wire_emarker_model", list.Get( "Wire_Misc_Tools_Models" ), 1)
	end
end
