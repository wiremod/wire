AddCSLuaFile()
DEFINE_BASECLASS( "base_wire_entity" )
ENT.PrintName       = "Wire Laser Pointer Receiver"
ENT.WireDebugName 	= "Laser Receiver"

if CLIENT then return end

function ENT:Initialize()
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )
	self.Outputs = WireLib.CreateSpecialOutputs(self, {"X", "Y", "Z", "Active", "Pos", "RangerData"}, {"NORMAL", "NORMAL", "NORMAL", "NORMAL", "VECTOR", "RANGER"})
	self.VPos = Vector(0,0,0)
end

function ENT:GetBeaconPos(sensor)
	return self.VPos
end
function ENT:GetBeaconVelocity(sensor) return Vector() end

local function playerDeath( victim, weapon, killer)
	if(victim:HasWeapon("laserPointer"))then
		local pointer = victim:GetWeapon("laserPointer")
		if(pointer && pointer:IsValid())then
			victim.LasReceiver = pointer.Receiver
		end
	end
end
hook.Add( "PlayerDeath", "laserMemory", playerDeath)

function MakeWireLaserReceiver( pl, Pos, Ang, model )
	if ( !pl:CheckLimit( "wire_las_receivers" ) ) then return false end

	local ent = ents.Create( "gmod_wire_las_receiver" )
	if not IsValid(ent) then return false end

	ent:SetAngles( Ang )
	ent:SetPos( Pos )
	ent:SetModel( model or "models/jaanus/wiretool/wiretool_range.mdl" )
	ent:Spawn()

	ent:SetPlayer( pl )
	ent.pl = pl

	pl:AddCount( "wire_las_receivers", ent )

	return ent
end
duplicator.RegisterEntityClass("gmod_wire_las_receiver", MakeWireLaserReceiver, "Pos", "Ang", "Model")
duplicator.RegisterEntityClass("gmod_wire_las_reciever", MakeWireLaserReceiver, "Pos", "Ang", "Model") -- For old dupe support
