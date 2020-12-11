include('shared.lua')
SWEP.PrintName = "Laser Pointer"
SWEP.Slot = 0
SWEP.SlotPos = 4
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = true

local LASER = Material('cable/redlaser')

function SWEP:Setup(ply)
	if ply.GetViewModel and ply:GetViewModel():IsValid() then
		local attachmentIndex = ply:GetViewModel():LookupAttachment("muzzle")
		if attachmentIndex == 0 then attachmentIndex = ply:GetViewModel():LookupAttachment("1") end
		if LocalPlayer():GetAttachment(attachmentIndex) then
			self.VM = ply:GetViewModel()
			self.Attach = attachmentIndex
		end
	end
	self.WAttach = self:LookupAttachment("muzzle")
end
function SWEP:Initialize()
	self:Setup(self:GetOwner())
end
function SWEP:Deploy(ply)
	self:Setup(self:GetOwner())
end

function SWEP:ViewModelDrawn()
	if self.Weapon:GetNWBool("Active") and self.VM then
		-- Draw the laser beam.
		render.SetMaterial( LASER )
		render.DrawBeam(self.VM:GetAttachment(self.Attach).Pos, self:GetOwner():GetEyeTrace().HitPos, 2, 0, 12.5, Color(255, 0, 0, 255))
	end
end
function SWEP:DrawWorldModel()
	self.Weapon:DrawModel()
	if self.Weapon:GetNWBool("Active") then
		local att = self:GetAttachment(self.WAttach)
		if not att then return end
		local owner = self:GetOwner()
		local startpos = att.Pos
		local endpos
		if IsValid(owner) then
			endpos = owner:GetEyeTrace().HitPos
		else
			local tr = util.TraceLine({start = att.Pos, endpos = att.Pos+att.Ang:Forward()*16384, filter = self})
			endpos = tr.HitPos
		end
		-- Draw the laser beam.
		render.SetMaterial( LASER )
		render.DrawBeam(startpos, endpos, 2, 0, 12.5, Color(255, 0, 0, 255))
	end
end
