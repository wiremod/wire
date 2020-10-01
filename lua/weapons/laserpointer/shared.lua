SWEP.Author = ""
SWEP.Contact = ""
SWEP.Purpose = ""
SWEP.Instructions = "Left Click to designate targets. Right click to select laser receiver."
SWEP.Category = "Wiremod"

SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.viewModel = "models/weapons/v_pistol.mdl";
SWEP.worldModel = "models/weapons/w_pistol.mdl";

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "none"

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"

function SWEP:UpdateHeldStatus()
	local owner = IsValid(self:GetOwner()) and self:GetOwner()
	local isValidOwner = owner ~= false

	self.IsHeld = isValidOwner
	self.Wielder = isValidOwner and owner or nil
end

function SWEP:OwnerChanged()
	timer.Simple(0, function() self:UpdateHeldStatus() end)
end

function SWEP:GetBarrelTip()
	return self:GetPos() + self:GetForward() * 2
end

function SWEP:GetBeamTrace(beamStart)
	if self.IsHeld then return self.Wielder:GetEyeTrace() end

	beamStart = beamStart or self:GetBarrelTip()

	return util.TraceLine({
		start = beamStart,
		endpos = beamStart + self:GetForward() * 1000,
		filter = self
	})
end

