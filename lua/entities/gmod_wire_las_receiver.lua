AddCSLuaFile()
DEFINE_BASECLASS("base_wire_entity")
ENT.PrintName = "Wire Laser Pointer Receiver"
ENT.WireDebugName = "Laser Receiver"

if CLIENT then return end

function ENT:Initialize()
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetUseType(SIMPLE_USE)
	WireLib.CreateOutputs(self, { "X", "Y", "Z", "Active", "Pos [VECTOR]", "RangerData [RANGER]" })
end

function ENT:GetBeaconPos()
	return Vector(0, 0, 0)
end

function ENT:GetBeaconVelocity()
	return Vector(0, 0, 0)
end

function ENT:Use(user)
	if not user:IsPlayer() then return end
	user:PrintMessage(HUD_PRINTTALK, "Hold down your use key for 2 seconds to get and link a Laser Pointer.")

	timer.Create("las_receiver_use_" .. user:EntIndex(), 2, 1, function()
		if not IsValid(user) or not user:KeyDown(IN_USE) or user:GetEyeTrace().Entity ~= self then return end

		if not IsValid(user:GetWeapon("laserpointer")) and hook.Run("PlayerGiveSWEP", user, "laserpointer", list.GetEntry("Weapon", "laserpointer")) then
			user:Give("laserpointer")
		end

		local pointer = user:GetWeapon("laserpointer")

		if pointer:IsValid() then
			pointer.Receiver = self
			user:PrintMessage(HUD_PRINTTALK, "You are now linked!")
			user:SelectWeapon("laserpointer")
		else
			user:PrintMessage(HUD_PRINTTALK, "Failed to link!")
		end
	end)
end

hook.Add("PostPlayerDeath", "Wire_LaserMemory", function(ply)
	if ply:HasWeapon("laserpointer") then
		local pointer = ply:GetWeapon("laserpointer")

		if pointer:IsValid() then
			ply.LasReceiver = pointer.Receiver
		end
	end
end)

duplicator.RegisterEntityClass("gmod_wire_las_receiver", WireLib.MakeWireEnt, "Data")
duplicator.RegisterEntityClass("gmod_wire_las_reciever", WireLib.MakeWireEnt, "Data")
scripted_ents.Alias("gmod_wire_las_reciever", "gmod_wire_las_receiver")
