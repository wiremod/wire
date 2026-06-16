SWEP.Author = ""
SWEP.Contact = ""
SWEP.Purpose = "Input source for Laser Pointer Receivers in Wiremod."
SWEP.Instructions = "Left click to designate targets. Right click to select laser receiver."
SWEP.Category = "Wiremod"

SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.UseHands = true
SWEP.ViewModel = "models/weapons/c_pistol.mdl"
SWEP.WorldModel = "models/weapons/w_pistol.mdl"

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "none"

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"

SWEP.Weight = 8
SWEP.AutoSwitchTo = false
SWEP.AutoSwitchFrom = false

SWEP.Receiver = nil
SWEP.Pointing = false

local singleplayer = game.SinglePlayer()

function SWEP:SetupDataTables()
	self:NetworkVar("Bool", 0, "LaserEnabled")
end

function SWEP:PrimaryAttack()
	self.Pointing = not self.Pointing
	self:SetLaserEnabled(self.Pointing)

	if CLIENT or singleplayer then
		local pitch = self.Pointing and 120 or 80
		self:EmitSound("ambient/energy/newspark03.wav", 100, pitch, 0.5)

		if CLIENT then return end
	end

	if self.Pointing and IsValid(self.Receiver) then
		WireLib.TriggerOutput(self.Receiver, "Active", 1)
	else
		WireLib.TriggerOutput(self.Receiver, "Active", 0)
	end
end

function SWEP:SecondaryAttack()
	local owner = self:GetOwner()
	if not IsValid(owner) then return end

	local trace = owner:GetEyeTrace()

	if IsValid(trace.Entity) and trace.Entity:GetClass() == "gmod_wire_las_receiver" and gamemode.Call("CanTool", owner, trace, "wire_las_receiver") then
		if SERVER then
			self.Receiver = trace.Entity
			owner:PrintMessage(HUD_PRINTTALK, "Linked Successfully!")
		end

		if CLIENT or singleplayer then
			self:EmitSound("buttons/bell1.wav")
		end

		return true
	elseif CLIENT or singleplayer then
		self:EmitSound("buttons/button16.wav", 100, 50, 0.5)
	end
end