TOOL.Category		= "Wire - I/O"
TOOL.Name			= "Two-way Radio"
TOOL.Command		= nil
TOOL.ConfigName		= ""
TOOL.Tab			= "Wire"

if ( CLIENT ) then
	language12.Add( "Tool_wire_twoway_radio_name", "Two-Way Radio Tool (Wire)" )
	language12.Add( "Tool_wire_twoway_radio_desc", "Spawns a two-way radio for use with the wire system." )
	language12.Add( "Tool_wire_twoway_radio_0", "Primary: Create/Update Two-way Radio\nSecondary: Select a two-way radio to pair up with another two-way radio." )
	language12.Add( "Tool_wire_twoway_radio_1", "Select the second two-way radio." );
	language12.Add( "WireRadioTwoWayTool_model", "Model:" );
	language12.Add( "sboxlimit_wire_twoway_radios", "You've hit the two-way radio limit!" )
	language12.Add( "undone_wiretwowayradio", "Undone Wire Two-way Radio" )
end

if (SERVER) then
  CreateConVar('sbox_maxwire_twoway_radioes',30)
	ModelPlug_Register("radio")
end

TOOL.ClientConVar[ "model" ] = "models/props_lab/bindergreen.mdl"

TOOL.FirstPeer = nil

cleanup.Register( "wire_twoway_radioes" )

function TOOL:LeftClick( trace )
	if (!trace.HitPos) then return false end
	if (trace.Entity:IsPlayer()) then return false end
	if ( CLIENT ) then return true end
	if not util.IsValidPhysicsObject( trace.Entity, trace.PhysicsBone ) then return false end

	local ply = self:GetOwner()
	local model = self:GetClientInfo( "model" )
	if not util.IsValidModel( model ) or not util.IsValidProp( model ) then return end

	if ( trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_twoway_radio" && trace.Entity.pl == ply ) then
		if (self.FirstPeer) and (self.FirstPeer:IsValid()) then
			local first = self.FirstPeer
			local second = trace.Entity

			-- Set the two entities to point to each other.
			local id = Radio_GetTwoWayID()
			first:RadioLink(second, id)
			second:RadioLink(first, id)

			WireLib.AddNotify(self:GetOwner(), "Radios paired up. Pair ID is " .. tostring(id) .. ".", NOTIFY_GENERIC, 7)

			self.FirstPeer = nil

			return true
		else
			trace.Entity:Setup( _channel )
			return true
		end
	else
		if self.FirstPeer then
			self.FirstPeer = nil
			return
		end
	end

	if (pl!=nil) then if ( !self:GetSWEP():CheckLimit( "wire_twoway_radioes" ) ) then return false end end

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90

	local wire_twoway_radio = MakeWireTwoWay_Radio( ply, trace.HitPos, Ang, model )

	local min = wire_twoway_radio:OBBMins()
	wire_twoway_radio:SetPos( trace.HitPos - trace.HitNormal * min.z )

	local const = WireLib.Weld(wire_twoway_radio, trace.Entity, trace.PhysicsBone, true)

	undo.Create("WireTwoWay_Radio")
		undo.AddEntity( wire_twoway_radio )
		undo.SetPlayer( ply )
		undo.AddEntity( const )
	undo.Finish()

	if (ply!=nil) then ply:AddCleanup( "wire_twoway_radioes", wire_twoway_radio ) end

	return true

end

function TOOL:RightClick( trace )
	if (self.FirstPeer) then return self:LeftClick( trace ) end

	if (!trace.HitPos) then return false end
	if (trace.Entity:IsPlayer()) then return false end
	if ( CLIENT ) then return true end

	local ply = self:GetOwner()

	if ( trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_twoway_radio" && trace.Entity.pl == ply ) then
		self.FirstPeer = trace.Entity

		return true
	end
end

if SERVER then

	// Having PeerID and Other in the duplicator was making it error out
	// by trying to reference a two-way radio that didn't exist yet
	// Build/ApplyDupeInfo now handle this (TheApathetic)
	function MakeWireTwoWay_Radio(pl, Pos, Ang, model)
		if (pl!=nil) then if ( !pl:CheckLimit( "wire_twoway_radioes" ) ) then return nil end end

		local wire_twoway_radio = ents.Create( "gmod_wire_twoway_radio" )
		wire_twoway_radio:SetPos( Pos )
		wire_twoway_radio:SetAngles( Ang )
		wire_twoway_radio:SetModel(model)
		wire_twoway_radio:Spawn()
		wire_twoway_radio:Activate()

		wire_twoway_radio:Setup( channel )
		wire_twoway_radio:SetPlayer( pl )

		local ttable = {
			pl = pl,
			nocollide = nocollide,
			description = description
		}

		table.Merge( wire_twoway_radio:GetTable(), ttable )

		if (pl!=nil) then pl:AddCount( "wire_twoway_radioes", wire_twoway_radio ) end

		return wire_twoway_radio
	end

	duplicator.RegisterEntityClass("gmod_wire_twoway_radio", MakeWireTwoWay_Radio, "Pos", "Ang", "Model")

end

function TOOL:UpdateGhostWireTwoWay_Radio( ent, player )

	if ( !ent || !ent:IsValid() ) then return end

	local trace = player:GetEyeTrace()

	if (!trace.Hit || trace.Entity:IsPlayer() || trace.Entity:GetClass() == "gmod_wire_twoway_radio" ) then
		ent:SetNoDraw( true )
		return
	end

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90
	ent:SetAngles( Ang )

	local min = ent:OBBMins()
	ent:SetPos( trace.HitPos - trace.HitNormal * min.z )

	ent:SetNoDraw( false )

end

function TOOL:Think()
	if (!self.GhostEntity || !self.GhostEntity:IsValid() || self.GhostEntity:GetModel() != self:GetClientInfo( "model" )) then
		self:MakeGhostEntity( self:GetClientInfo( "model" ), Vector(0,0,0), Angle(0,0,0) )
	end

	self:UpdateGhostWireTwoWay_Radio( self.GhostEntity, self:GetOwner() )
end

function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool_wire_twoway_radio_name", Description = "#Tool_wire_twoway_radio_desc" })

	ModelPlug_AddToCPanel(panel, "radio2", "wire_twoway_radio", "#WireRadioTwoWayTool_model", nil, "#WireRadioTwoWayTool_model")
end
