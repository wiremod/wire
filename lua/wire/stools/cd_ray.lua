WireToolSetup.setCategory( "Memory" )
WireToolSetup.open( "cd_ray", "CD Ray", "gmod_wire_cd_ray", nil, "CD Rays" )

if ( CLIENT ) then
	language.Add( "Tool.wire_cd_ray.name", "CD Ray Tool (Wire)" )
	language.Add( "Tool.wire_cd_ray.desc", "Spawns a CD Ray." )
	language.Add( "WireCDRayTool_cd_ray", "CD Ray:" )
	language.Add( "sboxlimit_wire_cd_rays", "You've hit CD Rays limit!" )
	TOOL.Information = {
		{ name = "left", text = "Create/Update " .. TOOL.Name },
		{ name = "right", text = "Create CD lock (to keep CD in same spot)" },
	}
end

WireToolSetup.BaseLang()

if (SERVER) then
	CreateConVar('sbox_maxwire_cd_rays', 20)
	CreateConVar('sbox_maxwire_cd_locks', 20)
end

TOOL.ClientConVar[ "model" ] = "models/jaanus/wiretool/wiretool_beamcaster.mdl"
TOOL.ClientConVar[ "lockmodel" ] = "models/venompapa/wirecdlock.mdl"
TOOL.ClientConVar[ "Range" ] = "64"
TOOL.ClientConVar[ "DefaultZero" ] = "0"

if SERVER then
	function TOOL:GetConVars()
		return self:GetClientNumber("Range"), self:GetClientNumber("DefaultZero") ~= 0
	end

	-- Uses default WireToolObj:MakeEnt's WireLib.MakeWireEnt function
end


function TOOL:RightClick(trace)
	if (not trace.HitPos) then return false end
	if (trace.Entity:IsPlayer()) then return false end
	if ( CLIENT ) then return true end

	local ply = self:GetOwner()

	if ( trace.Entity:IsValid() and trace.Entity:GetClass() == "gmod_wire_cd_lock" ) then
		return true
	end

	if ( not self:GetSWEP():CheckLimit( "wire_cd_locks" ) ) then return false end

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90

	local range = self:GetClientNumber("Range")
	local defZero = (self:GetClientNumber("DefaultZero") ~= 0)
	local model = self:GetClientInfo("lockmodel")

	if not util.IsValidModel( model ) or not util.IsValidProp( model ) then return end

	local wire_cd_lock = WireLib.MakeWireEnt(ply, {Class = "gmod_wire_cd_lock", Pos=trace.HitPos, Angle=Ang, Model=model})

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

function TOOL.BuildCPanel(panel)
	WireDermaExts.ModelSelect(panel, "wire_cd_ray_Model", list.Get( "Wire_Laser_Tools_Models" ), 1)
	panel:NumSlider("Range","wire_cd_ray_Range",1,512,2)
end
