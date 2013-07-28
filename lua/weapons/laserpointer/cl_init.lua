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
	if ply:IsValid() then
		local attachmentIndex = ply:LookupAttachment("anim_attachment_RH")
		if ply:GetAttachment(attachmentIndex) then
			self.WM = ply
			self.WAttach = attachmentIndex
		end
	end
end
function SWEP:Initialize()
	self:Setup(self:GetOwner())
end
function SWEP:Deploy(ply)
	self:Setup(self:GetOwner())
end

function SWEP:ViewModelDrawn()
	if self.Weapon:GetNWBool("Active") and self.VM then
        //Draw the laser beam.
        render.SetMaterial( LASER )
		render.DrawBeam(self.VM:GetAttachment(self.Attach).Pos, self:GetOwner():GetEyeTrace().HitPos, 2, 0, 12.5, Color(255, 0, 0, 255))
    end
end
function SWEP:DrawWorldModel()
	self.Weapon:DrawModel()
	if self.Weapon:GetNWBool("Active") and self.WM then
        //Draw the laser beam.
        render.SetMaterial( LASER )
		local posang = self.WM:GetAttachment(self.WAttach)
		if not posang then self.WM = nil ErrorNoHalt("Laserpointer CL: Attachment lost, did they change model or something?\n") return end
		render.DrawBeam(posang.Pos + posang.Ang:Forward()*10 + posang.Ang:Up()*4.4 + posang.Ang:Right(), self:GetOwner():GetEyeTrace().HitPos, 2, 0, 12.5, Color(255, 0, 0, 255))
    end
end
