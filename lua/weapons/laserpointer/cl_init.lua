include("shared.lua")

SWEP.PrintName = "Laser Pointer"
SWEP.Slot = 0
SWEP.SlotPos = 4
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = true

local color_red = Color(255, 0, 0)
local laser = Material("cable/redlaser")

-- Adapted from the example in https://wiki.facepunch.com/gmod/Entity:GetAttachment
local function formatViewModelAttachment(origin)
	local view = render.GetViewSetup()

	local eye_pos = view.origin
	local eye_ang = view.angles
	local offset = origin - eye_pos
	local forward = eye_ang:Forward()

	local view_x = math.tan(view.fovviewmodel_unscaled * math.pi / 360)

	if view_x == 0 then
		forward:Mul(forward:Dot(offset))
		eye_pos:Add(forward)

		return eye_pos
	end

	local world_x = math.tan(view.fov_unscaled * math.pi / 360)

	if world_x == 0 then
		forward:Mul(forward:Dot(offset))
		eye_pos:Add(forward)

		return eye_pos
	end

	local right = eye_ang:Right()
	local up = eye_ang:Up()

	local factor = view_x / world_x
	right:Mul(right:Dot(offset) * factor)
	up:Mul(up:Dot(offset) * factor)

	forward:Mul(forward:Dot(offset))

	eye_pos:Add(right)
	eye_pos:Add(up)
	eye_pos:Add(forward)

	return eye_pos
end

function SWEP:Setup(ply)
	if ply:IsValid() then
		local viewmodel = ply:GetViewModel()
		if not viewmodel:IsValid() then return end

		local attachment_index = viewmodel:LookupAttachment("muzzle")
		if attachment_index == 0 then attachment_index = viewmodel:LookupAttachment("1") end

		if LocalPlayer():GetAttachment(attachment_index) then
			self.VM = viewmodel
			self.Attach = attachment_index
		end
	end
end

function SWEP:Deploy()
	self:Setup(self:GetOwner())
end

function SWEP:ViewModelDrawn()
	local vm = self.VM

	if self:GetLaserEnabled() and vm then
		local startpos = vm:GetAttachment(self.Attach).Pos

		render.SetMaterial(laser)
		render.DrawBeam(formatViewModelAttachment(startpos), self:GetOwner():GetEyeTrace().HitPos, 2, 0, 12.5, color_red)
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