include("shared.lua")

SWEP.PrintName = "Laser Pointer"
SWEP.Slot = 0
SWEP.SlotPos = 4
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = true

local color_red = Color(255, 0, 0)
local laser = Material("cable/redlaser")

-- Scale screen coords by linear proportion of viewmodel and world fov
local function WorldToViewModel(point)
	local view = render.GetViewSetup()
	local factor = math.tan(math.rad(view.fovviewmodel_unscaled) * 0.5) / math.tan(math.rad(view.fov_unscaled) * 0.5)
	point = WorldToLocal(point, angle_zero, view.origin, view.angles)
	point:Mul(Vector(1, factor, factor))
	point = LocalToWorld(point, angle_zero, view.origin, view.angles)
	return point
end

function SWEP:PostDrawViewModel(vm, wep, ply)
	if self:GetLaserEnabled() then
		local att = vm:GetAttachment(vm:LookupAttachment("muzzle") or 0)
		if not att then return end

		local startpos = WorldToViewModel(att.Pos)
		local endpos = ply:GetEyeTrace().HitPos

		render.SetMaterial(laser)
		render.DrawBeam(startpos, endpos, 2, 0, 12.5, color_red)
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