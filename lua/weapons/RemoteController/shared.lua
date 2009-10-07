SWEP.Author = "ShaRose"
SWEP.Contact = ""
SWEP.Purpose = "Remote control for Adv. Pods in wire."
SWEP.Instructions = "Left Click on Adv. Pod to link up, and use to start controlling."

SWEP.PrintName = "Remote Control"
SWEP.Slot = 0
SWEP.SlotPos = 4
SWEP.DrawAmmo = false

SWEP.Weight = 1
SWEP.Spawnable = true
SWEP.AdminSpawnable = true

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "none"

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"
SWEP.viewModel = "models/weapons/v_pistol.mdl"
SWEP.worldModel = "models/weapons/w_pistol.mdl"

function SWEP:PrimaryAttack()
	if !self.Owner.Active then
		local tracedata = {
		start = self.Owner:GetShootPos(),
		endpos = self.Owner:GetShootPos()+(self.Owner:GetAimVector()*250),
		filter = self.Owner
		}
		local trace = util.TraceLine(tracedata)
		if trace.HitNonWorld and trace.Entity:GetClass() == "gmod_wire_adv_pod" then
			if trace.Entity:Link(self.Owner,true) then
				self.Owner:PrintMessage(HUD_PRINTTALK,"You are now linked!")
				self.Owner.Linked = true
			else
				self.Owner:PrintMessage(HUD_PRINTTALK,"Link failed!")
			end
		end
	end
end

function SWEP:Reload()
	if !self.Owner.Active then
		self.Owner:PrintMessage(HUD_PRINTTALK,"Link reset!")
		self.Owner.Linked = false
	end
end

function SWEP:Holster()
	self.Owner.Active = false
	return true
end

function SWEP:OnDrop()
	self.Owner.Active = false
	self.Owner.Linked = false
	self.Owner:PrintMessage(HUD_PRINTTALK,"SWEP reset!")
end

function SWEP:Think()
	if CLIENT then return end
	if !self.Owner.Linked then return end
	if self.Owner:KeyPressed(IN_USE) then
		if self.Owner.Active then
			self.Owner.Active = false
			self.Owner:SetMoveType(2)
			self.Owner:DrawViewModel(true)
		else
			self.Owner.Active = true
			self.Owner:SetMoveType(0)
			self.Owner:DrawViewModel(false)
		end
	end
end

function SWEP:OnRestore()
end

function SWEP:Precache()
end

function SWEP:OwnerChanged()
end

function SWEP:SecondaryAttack()
end

function SWEP:Initialize()
end

function SWEP:Deploy()
	return true
end

