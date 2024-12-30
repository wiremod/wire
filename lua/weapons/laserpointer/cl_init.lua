include("shared.lua")

SWEP.PrintName = "Laser Pointer"
SWEP.Slot = 0
SWEP.SlotPos = 4
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = true

local color_red = Color(255, 0, 0)
local laser = Material("cable/redlaser")

function SWEP:Setup(ply)
	if ply:IsValid() then
		local viewmodel = ply:GetViewModel()
		if not viewmodel:IsValid() then return end

		local attachmentIndex = viewmodel:LookupAttachment("muzzle")
		if attachmentIndex == 0 then attachmentIndex = viewmodel:LookupAttachment("1") end

		if LocalPlayer():GetAttachment(attachmentIndex) then
			self.VM = viewmodel
			self.Attach = attachmentIndex
		end
	end
end

function SWEP:Initialize()
	self:Setup(self:GetOwner())
end

function SWEP:Deploy()
	self:Setup(self:GetOwner())
end

function SWEP:ViewModelDrawn()
	if self:GetLaserEnabled() and self.VM then
		render.SetMaterial(laser)
		render.DrawBeam(self.VM:GetAttachment(self.Attach).Pos, self:GetOwner():GetEyeTrace().HitPos, 2, 0, 12.5, color_red)
	end
end

function SWEP:DrawWorldModel()
	self:DrawModel()

	if self:GetLaserEnabled() then
		local att = self:GetAttachment(self:LookupAttachment("muzzle") or 0)
		if not att then return end

		local owner = self:GetOwner()
		local startpos = att.Pos
		local endpos

		if IsValid(owner) then
			endpos = owner:GetEyeTrace().HitPos
		else
			local tr = util.TraceLine({ start = startpos, endpos = startpos + att.Ang:Forward() * 16384, filter = self })
			endpos = tr.HitPos
		end

		-- Draw the laser beam.
		render.SetMaterial(laser)
		render.DrawBeam(startpos, endpos, 2, 0, 12.5, color_red)
	end
end
