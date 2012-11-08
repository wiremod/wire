AddCSLuaFile()
DEFINE_BASECLASS( "base_wire_entity" )

ENT.PrintName       = "Wire Laser Pointer Receiver"
ENT.WireDebugName = "Laser Receiver"

ENT.Spawnable       = false
ENT.AdminSpawnable  = false

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

local function playerDeath( victim, weapon, killer)
	if(victim:HasWeapon("laserPointer"))then
		local pointer = victim:GetWeapon("laserPointer")
		if(pointer && pointer:IsValid())then
			victim.LasReceiver = pointer.Receiver
		end
	end
end
hook.Add( "PlayerDeath", "laserMemory", playerDeath)

function MakeWireLaserReciever( pl, Pos, Ang, model )
	if ( !pl:CheckLimit( "wire_las_receivers" ) ) then return false end

	local wire_las_reciever = ents.Create( "gmod_wire_las_reciever" )
	if (!wire_las_reciever:IsValid()) then return false end

	wire_las_reciever:SetAngles( Ang )
	wire_las_reciever:SetPos( Pos )
	wire_las_reciever:SetModel( model or "models/jaanus/wiretool/wiretool_range.mdl" )
	wire_las_reciever:Spawn()

	wire_las_reciever:SetPlayer( pl )
	wire_las_reciever.pl = pl

	pl:AddCount( "wire_las_receivers", wire_las_reciever )

	return wire_las_reciever
end
duplicator.RegisterEntityClass("gmod_wire_las_reciever", MakeWireLaserReciever, "Pos", "Ang", "Model")
