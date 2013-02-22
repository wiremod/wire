WireToolSetup.setCategory( "Beacon" )
WireToolSetup.open( "locator", "Locator", "gmod_wire_locator", nil, "Locators" )

if ( CLIENT ) then
    language.Add( "Tool.wire_locator.name", "Locator Beacon Tool (Wire)" )
    language.Add( "Tool.wire_locator.desc", "Spawns a locator beacon for use with the wire system." )
    language.Add( "Tool.wire_locator.0", "Primary: Create/Update Locator Beacon" )
	language.Add( "sboxlimit_wire_locators", "You've hit locator beacons limit!" )
	language.Add( "undone_wirelocator", "Undone Wire Locator Beacon" )
end

if (SERVER) then
  CreateConVar('sbox_maxwire_locators',30)
end

TOOL.Model = "models/props_lab/powerbox02d.mdl"

cleanup.Register( "wire_locators" )

function TOOL:LeftClick(trace)
	if (!trace.HitPos) then return false end
	if (trace.Entity:IsPlayer()) then return false end
	if ( CLIENT ) then return true end
	if not util.IsValidPhysicsObject( trace.Entity, trace.PhysicsBone ) then return false end

	local ply = self:GetOwner()

	if ( trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_locator" ) then
		trace.Entity:Setup()
		return true
	end

	if ( !self:GetSWEP():CheckLimit( "wire_locators" ) ) then return false end

	local Ang = trace.HitNormal:Angle()

	local wire_locator = MakeWireLocator( ply, trace.HitPos, Ang, self.Model )

	local min = wire_locator:OBBMins()
	wire_locator:SetPos( trace.HitPos - trace.HitNormal * (min.z) )

	undo.Create("WireLocator")
		undo.AddEntity( wire_locator )
		undo.SetPlayer( ply )
	undo.Finish()

	ply:AddCleanup( "wire_locators", wire_locator )

	return true

end

if SERVER then

	function MakeWireLocator(pl, Pos, Ang, model, nocollide )
		if (!pl:CheckLimit("wire_locators")) then return end

		local wire_locator = ents.Create("gmod_wire_locator")
		wire_locator:SetPos(Pos)
		wire_locator:SetAngles(Ang)
		wire_locator:SetModel( Model(model or "models/props_lab/powerbox02d.mdl") )
		wire_locator:Spawn()
		wire_locator:Activate()

		wire_locator:SetPlayer(pl)

		if ( nocollide == true ) then wire_light:GetPhysicsObject():EnableCollisions( false ) end

		local ttable = {
			pl			= pl,
			nocollide	= nocollide,
		}
		table.Merge( wire_locator:GetTable(), ttable )

		pl:AddCount( "wire_locators", wire_locator )

		return wire_locator
	end

	duplicator.RegisterEntityClass("gmod_wire_locator", MakeWireLocator, "Pos", "Ang", "Model", "nocollide")

end

function TOOL:UpdateGhostWireLocator( ent, player )

	if ( !ent || !ent:IsValid() ) then return end

	local trace = player:GetEyeTrace()

	if (!trace.Hit || trace.Entity:IsPlayer() || trace.Entity:GetClass() == "gmod_wire_locator" ) then
		ent:SetNoDraw( true )
		return
	end

	local Ang = trace.HitNormal:Angle()

	local min = ent:OBBMins()
	ent:SetPos( trace.HitPos - trace.HitNormal * min.z )
	ent:SetAngles( Ang )

	ent:SetNoDraw( false )

end

function TOOL:Think()

	if (!self.GhostEntity || !self.GhostEntity:IsValid() || self.GhostEntity:GetModel() != self.Model ) then
		self:MakeGhostEntity( self.Model, Vector(0,0,0), Angle(0,0,0) )
	end

	self:UpdateGhostWireLocator( self.GhostEntity, self:GetOwner() )

end

function TOOL.BuildCPanel(panel)
end

