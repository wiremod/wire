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
	local ply = self:GetOwner()
	local trace = ply:GetEyeTrace()
	if IsValid(trace.Entity) and trace.Entity:GetClass() == "gmod_wire_pod" and gamemode.Call("PlayerUse", ply, trace.Entity) then
		self.Linked = trace.Entity
		ply:ChatPrint("Remote Controller linked.")
	end
end

function SWEP:Holster()
	local ply = self:GetOwner()
	if IsValid(ply) and self.Linked then
		self:Off(ply)
	end
	return true
end

function SWEP:OnDrop()
	local ply = self:GetOwner()
	if IsValid(ply) and self.Linked then
		self:Off(ply)
	end
	self.Linked = nil
end

function SWEP:On(ply)
	if IsValid(self.Linked) and self.Linked.HasPly and self.Linked:HasPly() then
		if WireLib.CanTool(ply, self.Linked, "remotecontroller") then
			if self.Linked.RC then
				self.Linked:RCEject(self.Linked:GetPly())
			else
				self.Linked:GetPly():ExitVehicle()
			end
		else
			ply:ChatPrint("Pod is in use.")
			return
		end
	end

	self.Active = true
	self.OldMoveType = not ply:InVehicle() and ply:GetMoveType() or MOVETYPE_WALK
	self.InitialAngle = ply:EyeAngles()
	ply:SetMoveType(MOVETYPE_NONE)
	ply:DrawViewModel(false)
	ply.using_wire_remote_control = true

	if IsValid(self.Linked) and self.Linked.PlayerEntered then
		self.Linked:PlayerEntered(ply, self)
	end
end

function SWEP:Off(ply)
	if self.Active then
		ply:SetMoveType(self.OldMoveType or MOVETYPE_WALK)
	end

	self.Active = nil
	self.OldMoveType = nil

	ply:DrawViewModel(true)
	ply.using_wire_remote_control = false

	if IsValid(self.Linked) and self.Linked:GetPly() == ply then
		self.Linked:PlayerExited()
	end
end

function SWEP:Think()
	if not self.Linked then return end
	local ply = self:GetOwner()
	if not IsValid(ply) then return end

	if ply:KeyPressed(IN_USE) then
		if not self.Active then
			self:On(ply)
		else
			self:Off(ply)
		end
	end
end

hook.Add("PlayerNoClip", "wire_remotecontroller_antinoclip", function(ply, cmd)
	if ply.using_wire_remote_control then return false end
end)

