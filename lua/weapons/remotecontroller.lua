AddCSLuaFile()

SWEP.Author = "Divran" -- Originally by ShaRose, rewritten by Divran at 2011-04-03
SWEP.Contact = ""
SWEP.Purpose = "Remote control for Adv. Pods in wire."
SWEP.Instructions = "Left Click on Adv. Pod to link up, and use to start controlling."
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
	local trace = self.Owner:GetEyeTrace()
	if (trace.Entity and trace.Entity:IsValid() and trace.Entity:GetClass() == "gmod_wire_adv_pod") then
		self.Linked = trace.Entity
		self.Owner:ChatPrint("Remote Controller linked.")
	end
end

function SWEP:Holster()
	if (self.Linked) then
		self:Off()
	end
	return true
end

function SWEP:OnDrop()
	if (self.Linked) then
		self:Off()
		self.Linked = nil
	end
end

function SWEP:On()
	self.Active = true
	self.OldMoveType = self.Owner:GetMoveType()
	self.Owner:SetMoveType(MOVETYPE_NONE)
	self.Owner:DrawViewModel(false)
	if (self.Linked and self.Linked:IsValid()) then
		self.Linked:PlayerEntered( self.Owner, self )
	end
end
function SWEP:Off()
	if self.Active then
		if (self.OldMoveType) then
	    		self.Owner:SetMoveType(self.OldMoveType)
		else
	    		self.Owner:SetMoveType(MOVETYPE_WALK)
		end
	end
	self.Active = nil
	self.OldMoveType = nil
	self.Owner:DrawViewModel(true)
	if (self.Linked and self.Linked:IsValid()) then
		self.Linked:PlayerExited( self.Owner )
	end
end

function SWEP:Think()
	if (!self.Linked) then return end
	if (self.Owner:KeyPressed( IN_USE )) then
		if (!self.Active) then
			self:On()
		else
			self:Off()
		end
	end
end

function SWEP:Deploy()
	return true
end
