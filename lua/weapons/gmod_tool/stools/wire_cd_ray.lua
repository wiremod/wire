TOOL.Category		= "Wire - Data"
TOOL.Name		= "CD Ray"
TOOL.Command		= nil
TOOL.ConfigName		= ""
TOOL.Tab			= "Wire"

if ( CLIENT ) then
    language.Add( "Tool_wire_cd_ray_name", "CD Ray Tool (Wire)" )
    language.Add( "Tool_wire_cd_ray_desc", "Spawns a CD Ray." )
    language.Add( "Tool_wire_cd_ray_0", "Primary: Create/Update CD Ray Secondary: Create CD lock (to keep CD in same spot)" )
    language.Add( "WireCDRayTool_cd_ray", "CD Ray:" )
	language.Add( "sboxlimit_wire_cd_rays", "You've hit CD Rays limit!" )
	language.Add( "undone_Wire CDRay", "Undone Wire CD Ray" )
end

if (SERVER) then
	CreateConVar('sbox_maxwire_cd_rays', 20)
	CreateConVar('sbox_maxwire_cd_locks', 20)
end

TOOL.ClientConVar[ "model" ] = "models/jaanus/wiretool/wiretool_beamcaster.mdl"
TOOL.ClientConVar[ "lockmodel" ] = "models/venompapa/wirecdlock.mdl"
TOOL.ClientConVar[ "Range" ] = "64"
TOOL.ClientConVar[ "DefaultZero" ] = "0"

local transmodels = {
    ["models/jaanus/wiretool/wiretool_siren.mdl"] = {},
    ["models/jaanus/wiretool/wiretool_beamcaster.mdl"] = {}};

cleanup.Register("wire_cd_rays")

function TOOL:LeftClick(trace)
	if (!trace.HitPos) then return false end
	if (trace.Entity:IsPlayer()) then return false end
	if ( CLIENT ) then return true end
	if not util.IsValidPhysicsObject( trace.Entity, trace.PhysicsBone ) then return false end

	local ply = self:GetOwner()

	if ( trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_cd_ray" && trace.Entity.pl == ply ) then
		return true
	end

	if ( !self:GetSWEP():CheckLimit( "wire_cd_rays" ) ) then return false end

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90

	local range = self:GetClientNumber("Range")
	local defZero = (self:GetClientNumber("DefaultZero") ~= 0)
	local model = self:GetClientInfo("model")

	local wire_cd_ray = MakeWireCDRay( ply, trace.HitPos, Ang, model, range, defZero )

	local min = wire_cd_ray:OBBMins()
	wire_cd_ray:SetPos( trace.HitPos - trace.HitNormal * min.z )

	local const = WireLib.Weld(wire_cd_ray, trace.Entity, trace.PhysicsBone, true)

	undo.Create("Wire Data CD Ray")
		undo.AddEntity( wire_cd_ray )
		undo.AddEntity( const )
		undo.SetPlayer( ply )
	undo.Finish()

	ply:AddCleanup( "wire_cd_rays", wire_cd_ray )
	ply:AddCleanup( "wire_cd_rays", const )

	return true
end


function TOOL:RightClick(trace)
	if (!trace.HitPos) then return false end
	if (trace.Entity:IsPlayer()) then return false end
	if ( CLIENT ) then return true end

	local ply = self:GetOwner()

	if ( trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_cd_lock" && trace.Entity.pl == ply ) then
		return true
	end

	if ( !self:GetSWEP():CheckLimit( "wire_cd_locks" ) ) then return false end

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90

	local range = self:GetClientNumber("Range")
	local defZero = (self:GetClientNumber("DefaultZero") ~= 0)
	local model = self:GetClientInfo("lockmodel")

	local wire_cd_lock = MakeWireCDLock( ply, trace.HitPos, Ang, model )

	local min = wire_cd_lock:OBBMins()
	wire_cd_lock:SetPos( trace.HitPos - trace.HitNormal * min.z )

	local const = WireLib.Weld(wire_cd_lock, trace.Entity, trace.PhysicsBone, true)

	undo.Create("Wire Data CD Locky")
		undo.AddEntity( wire_cd_lock )
		undo.AddEntity( const )
		undo.SetPlayer( ply )
	undo.Finish()

	ply:AddCleanup( "wire_cd_locks", wire_cd_lock )
	ply:AddCleanup( "wire_cd_locks", const )

	return true
end

if (SERVER) then

	function MakeWireCDRay( pl, Pos, Ang, model, Range, DefaultZero)
		if ( !pl:CheckLimit( "wire_cd_rays" ) ) then return false end

		local wire_cd_ray = ents.Create( "gmod_wire_cd_ray" )
		if (!wire_cd_ray:IsValid()) then return false end

		wire_cd_ray:SetAngles( Ang )
		wire_cd_ray:SetPos( Pos )
		wire_cd_ray:SetModel( model )
		wire_cd_ray:Spawn()
		wire_cd_ray:Setup(Range,DefaultZero)

		wire_cd_ray:SetPlayer( pl )

		local ttable = {
		    Range = Range,
		    DefaultZero = DefaultZero,
			pl = pl
		}
		table.Merge(wire_cd_ray:GetTable(), ttable )

		pl:AddCount( "wire_cd_rays", wire_cd_ray )

		return wire_cd_ray
	end
	duplicator.RegisterEntityClass("gmod_wire_cd_ray", MakeWireCDRay, "Pos", "Ang", "Model", "Range", "DefaultZero")

	function MakeWireCDLock( pl, Pos, Ang, model )
		if ( !pl:CheckLimit( "wire_cd_locks" ) ) then return false end

		local wire_cd_lock = ents.Create( "gmod_wire_cd_lock" )
		if (!wire_cd_lock:IsValid()) then return false end

		wire_cd_lock:SetAngles( Ang )
		wire_cd_lock:SetPos( Pos )
		wire_cd_lock:SetModel( model )
		wire_cd_lock:Spawn()

		wire_cd_lock:SetPlayer( pl )

		local ttable = {
		    Range = Range,
		    DefaultZero = DefaultZero,
			pl = pl
		}
		table.Merge(wire_cd_lock:GetTable(), ttable )

		pl:AddCount( "wire_cd_locks", wire_cd_lock )

		return wire_cd_lock
	end
	duplicator.RegisterEntityClass("gmod_wire_cd_lock", MakeWireCDLock, "Pos", "Ang", "Model")

end

function TOOL:UpdateGhostWireCDRay( ent, player )
	if ( !ent || !ent:IsValid() ) then return end

	local trace = player:GetEyeTrace()

	if (!trace.Hit || trace.Entity:IsPlayer() || trace.Entity:GetClass() == "gmod_wire_cd_ray" ) then
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
	if (!self.GhostEntity || !self.GhostEntity:IsValid() || self.GhostEntity:GetModel() != self:GetClientInfo("Model") ) then
		self:MakeGhostEntity( self:GetClientInfo("Model"), Vector(0,0,0), Angle(0,0,0) )
	end

	self:UpdateGhostWireCDRay( self.GhostEntity, self:GetOwner() )
end

function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool_wire_cd_ray_name", Description = "#Tool_wire_cd_ray_desc" })


	panel:AddControl( "PropSelect", { Label = "#WireCDRayTool_Model",
									 ConVar = "wire_cd_ray_Model",
									 Category = "Wire Data CD Ray",
									 Models = transmodels } )

	panel:AddControl("Slider", {
		Label = "CD Ray range",
		Type = "Float",
		Min = "1",
		Max = "512",
		Command = "wire_cd_ray_Range"
	})
end

