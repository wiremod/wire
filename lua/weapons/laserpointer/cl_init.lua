include('shared.lua')
SWEP.PrintName = "Laser Pointer"
SWEP.Slot = 0
SWEP.SlotPos = 4
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = true
SWEP.Active = false
SWEP.BeamColor = Color(255, 0, 0, 255)
SWEP.BeamWidth = 2
SWEP.BeamMaterial = Material("cable/redlaser")

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

function SWEP:PrimaryAttack()
	self.Active = not self.Active
end

function SWEP:DrawBeamFrom(beamStart)
	local beamEnd = self:GetBeamTrace(beamStart).HitPos

	render.SetMaterial(self.BeamMaterial)
	render.DrawBeam(beamStart, beamEnd, self.BeamWidth, 0, 12.5, self.BeamColor)
end

function SWEP:ViewModelDrawn()
	if not self.Active and self.VM then return end

	local beamStart = self.VM:GetAttachment(self.Attach).Pos
	self:DrawBeamFrom(beamStart)
end

function SWEP:DrawWorldModel()
	self.Weapon:DrawModel()
	if not self.Active then return end

	local beamStart = self:GetPos() + self:GetForward() * 2

	if self.IsHeld then
		local posang = self.Wielder:GetAttachment(self.WAttach)

		if not posang then
			self.Wielder = nil
			ErrorNoHalt("Laserpointer CL: Attachment lost, did they change model or something?\n")

			return
		end

		beamStart = posang.Pos + posang.Ang:Forward() * 10 + posang.Ang:Up() * 4.4 + posang.Ang:Right()
	end

	self:DrawBeamFrom(beamStart)
end
