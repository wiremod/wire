SWEP.Author = ""
SWEP.Contact = ""
SWEP.Purpose = ""
SWEP.Instructions = "Left Click to designate targets. Right click to select laser receiver."
SWEP.Category = "Wiremod"

SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.viewModel = "models/weapons/v_pistol.mdl"
SWEP.worldModel = "models/weapons/w_pistol.mdl"

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "none"

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"

function SWEP:SetupDataTables()
    self:NetworkVar("Bool", 0, "LaserEnabled")
end
