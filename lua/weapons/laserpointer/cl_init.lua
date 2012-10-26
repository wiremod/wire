include('shared.lua')
SWEP.PrintName = "Laser Pointer"
SWEP.Slot = 0
SWEP.SlotPos = 4
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = true

local LASER = Material('cable/redlaser')

function SWEP:SetVM(ply)
	if ply.GetViewModel and ply:GetViewModel():IsValid() then
		self.VM = ply:GetViewModel()
		local attachmentIndex = self.VM:LookupAttachment("muzzle")
		if attachmentIndex == 0 then attachmentIndex = self.VM:LookupAttachment("1") end
		self.Attach = attachmentIndex
	end
	if ply:IsValid() then
		local attachmentIndex = ply:LookupAttachment("anim_attachment_RH")
		if attachmentIndex == 0 then return end
		self.WM = ply
		self.WAttach = attachmentIndex
	end
end
function SWEP:Initialize()
	self:SetVM(self:GetOwner())
end
function SWEP:Equip(ply)
	self:SetVM(ply)
end

function SWEP:ViewModelDrawn()
	if self.Weapon:GetNWBool("Active") and self.VM then
        //Draw the laser beam.
        render.SetMaterial( LASER )
		render.DrawBeam(self.VM:GetAttachment(self.Attach).Pos, self.Owner:GetEyeTrace().HitPos, 2, 0, 12.5, Color(255, 0, 0, 255))
    end
end
function SWEP:DrawWorldModel()
	self.Weapon:DrawModel()
	if self.Weapon:GetNWBool("Active") and self.WM then
        //Draw the laser beam.
        render.SetMaterial( LASER )
		local posang = self.WM:GetAttachment(self.WAttach)
		render.DrawBeam(posang.Pos + posang.Ang:Forward()*10 + posang.Ang:Up()*4.4 + posang.Ang:Right(), self.Owner:GetEyeTrace().HitPos, 2, 0, 12.5, Color(255, 0, 0, 255))
    end
end
