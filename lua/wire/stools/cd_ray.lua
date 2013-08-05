WireToolSetup.setCategory( "Data" )
WireToolSetup.open( "cd_ray", "CD Ray", "gmod_wire_cd_ray", nil, "CD Rays" )

if ( CLIENT ) then
    language.Add( "Tool.wire_cd_ray.name", "CD Ray Tool (Wire)" )
    language.Add( "Tool.wire_cd_ray.desc", "Spawns a CD Ray." )
    language.Add( "Tool.wire_cd_ray.0", "Primary: Create/Update CD Ray Secondary: Create CD lock (to keep CD in same spot)" )
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

cleanup.Register("wire_cd_rays")

if SERVER then
	function TOOL:GetConVars() 
		return self:GetClientNumber("Range"), self:GetClientNumber("DefaultZero") ~= 0
	end

	-- Uses default WireToolObj:MakeEnt's MakeWireEnt function
end


function TOOL:RightClick(trace)
	if (!trace.HitPos) then return false end
	if (trace.Entity:IsPlayer()) then return false end
	if ( CLIENT ) then return true end

	local ply = self:GetOwner()

	if ( trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_cd_lock" ) then
		return true
	end

	if ( !self:GetSWEP():CheckLimit( "wire_cd_locks" ) ) then return false end

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90

	local range = self:GetClientNumber("Range")
	local defZero = (self:GetClientNumber("DefaultZero") ~= 0)
	local model = self:GetClientInfo("lockmodel")

	if not util.IsValidModel( model ) or not util.IsValidProp( model ) then return end

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

	function MakeWireCDLock( pl, Pos, Ang, model )
		if ( !pl:CheckLimit( "wire_cd_locks" ) ) then return false end

		local wire_cd_lock = ents.Create( "gmod_wire_cd_lock" )
		if (!wire_cd_lock:IsValid()) then return false end

		wire_cd_lock:SetAngles( Ang )
		wire_cd_lock:SetPos( Pos )
		wire_cd_lock:SetModel( model )
		wire_cd_lock:Spawn()

		wire_cd_lock:SetPlayer( pl )

		pl:AddCount( "wire_cd_locks", wire_cd_lock )

		return wire_cd_lock
	end
	duplicator.RegisterEntityClass("gmod_wire_cd_lock", MakeWireCDLock, "Pos", "Ang", "Model")

end

function TOOL.BuildCPanel(panel)
	WireDermaExts.ModelSelect(panel, "wire_cd_ray_Model", list.Get( "Wire_Laser_Tools_Models" ), 1)
	panel:NumSlider("Range","wire_cd_ray_Range",1,512,2)
end
