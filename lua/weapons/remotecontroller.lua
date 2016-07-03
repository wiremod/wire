AddCSLuaFile()

SWEP.Author = "Divran" -- Originally by ShaRose, rewritten by Divran at 2011-04-03
SWEP.Contact = ""
SWEP.Purpose = "Remote control for Pod Controllers in wire."
SWEP.Instructions = "Left Click on Pod Controller to link up, and use to start controlling."
SWEP.Category = "Wiremod"

SWEP.PrintName = "Remote Control"
SWEP.Slot = 0
SWEP.SlotPos = 4
SWEP.DrawAmmo = false

SWEP.Weight = 1
SWEP.Spawnable = true
SWEP.AdminOnly = false

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

if CLIENT then return end

function SWEP:PrimaryAttack()
	local trace = self:GetOwner():GetEyeTrace()
	if IsValid(trace.Entity) and trace.Entity:GetClass() == "gmod_wire_pod" and gamemode.Call("PlayerUse", self:GetOwner(), trace.Entity) then
		self.Linked = trace.Entity
		self:GetOwner():ChatPrint("Remote Controller linked.")
	end
end

function SWEP:Holster()
	if self.Linked then
		self:Off()
	end
	
	return true
end

function SWEP:Deploy()
	return true
end

function SWEP:OnDrop()
	if not self.Linked then return end
	
	self:Off()
	self.Linked = nil
end

function SWEP:On()
	self.Active = true
	self.OldMoveType = self:GetOwner():GetMoveType()
	self:GetOwner():SetMoveType(MOVETYPE_NONE)
	self:GetOwner():DrawViewModel(false)
	
	if IsValid(self.Linked) then
		self.Linked:PlayerEntered(self:GetOwner(), self)
	end
end

function SWEP:Off()
	if self.Active then
		self:GetOwner():SetMoveType(self.OldMoveType or MOVETYPE_WALK)
	end
	
	self.Active = nil
	self.OldMoveType = nil
	self:GetOwner():DrawViewModel(true)
	
	if IsValid(self.Linked) then
		self.Linked:PlayerExited(self:GetOwner())
	end
end

function SWEP:Think()
	if not self.Linked then return end
	
	if self:GetOwner():KeyPressed(IN_USE) then
		if not self.Active then
			self:On()
		else
			self:Off()
		end
	end
end
