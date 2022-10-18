AddCSLuaFile()
DEFINE_BASECLASS( "base_wire_entity" )
ENT.PrintName       = "Wire Laser Pointer Receiver"
ENT.WireDebugName 	= "Laser Receiver"

if CLIENT then return end

function ENT:Initialize()
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )
	self:SetUseType( SIMPLE_USE )
	self.Outputs = WireLib.CreateSpecialOutputs(self, {"X", "Y", "Z", "Active", "Pos", "RangerData"}, {"NORMAL", "NORMAL", "NORMAL", "NORMAL", "VECTOR", "RANGER"})
	self.VPos = Vector(0,0,0)

	self:SetOverlayText( "Laser Pointer Receiver" )
end

function ENT:GetBeaconPos(sensor)
	return self.VPos
end
function ENT:GetBeaconVelocity(sensor) return Vector() end

function ENT:Use( User, caller )
	if not hook.Run("PlayerGiveSWEP", User, "laserpointer", weapons.Get( "laserpointer" )) then return end
	User:PrintMessage(HUD_PRINTTALK, "Hold down your use key for 2 seconds to get and link a Laser Pointer.")
	timer.Create("las_receiver_use_"..User:EntIndex(), 2, 1, function()
		if not IsValid(User) or not User:IsPlayer() then return end
		if not User:KeyDown(IN_USE) then return end
		if not User:GetEyeTrace().Entity then return end

		if not IsValid(User:GetWeapon("laserpointer")) then
			if not hook.Run("PlayerGiveSWEP", User, "laserpointer", weapons.Get( "laserpointer" )) then return end
			User:Give("laserpointer")
		end

		User:GetWeapon("laserpointer").Receiver = self
		User:PrintMessage(HUD_PRINTTALK, "You are now linked!")
		User:SelectWeapon("laserpointer")
	end)
end

local function playerDeath( victim, weapon, killer)
	if(victim:HasWeapon("laserPointer"))then
		local pointer = victim:GetWeapon("laserPointer")
		if(pointer and pointer:IsValid())then
			victim.LasReceiver = pointer.Receiver
		end
	end
end
hook.Add( "PlayerDeath", "laserMemory", playerDeath)

duplicator.RegisterEntityClass("gmod_wire_las_receiver", WireLib.MakeWireEnt, "Data")
duplicator.RegisterEntityClass("gmod_wire_las_reciever", WireLib.MakeWireEnt, "Data") -- For old dupe support
