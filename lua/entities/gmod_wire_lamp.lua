AddCSLuaFile()

DEFINE_BASECLASS("base_wire_entity")
ENT.PrintName = "Wire Lamp"
ENT.RenderGroup = RENDERGROUP_BOTH
ENT.WireDebugName = "Lamp"

function ENT:SetupDataTables()
	self:NetworkVar("Bool", 0, "On")
	self:NetworkVar("Float", 0, "LightFOV")
	self:NetworkVar("Float", 1, "Distance")
	self:NetworkVar("Float", 2, "Brightness")
	self:NetworkVar("String", 0, "Texture")

	if CLIENT then
		self:NetworkVarNotify("LightFOV", self.OnValueChange)
		self:NetworkVarNotify("Distance", self.OnValueChange)
		self:NetworkVarNotify("Brightness", self.OnValueChange)
		self:NetworkVarNotify("Texture", self.OnValueChange)
	end
end

function ENT:GetEntityDriveMode()
	return "drive_noclip"
end

function ENT:Initialize()
	if SERVER then
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetSkin(self:GetLightInfo().Skin)
		self:DrawShadow(false)
		self:PhysWake()

		WireLib.CreateInputs(self, { "Red", "Green", "Blue", "RGB [VECTOR]", "FOV", "Distance", "Brightness", "On", "Texture [STRING]" })
	else
		self.PixVis = util.GetPixelVisibleHandle()
	end
end

local vector_offset = Vector(5, 0, 0)
local angle_default = Angle(0, 0, 0)

function ENT:GetLightInfo()
	local light_info = list.GetForEdit("LampModels")[self:GetModel()] or {}
	light_info.Offset = light_info.Offset or vector_offset
	light_info.Angle = light_info.Angle or angle_default
	light_info.NearZ = light_info.NearZ or 12
	light_info.Scale = light_info.Scale or 2
	light_info.Skin = light_info.Skin or 1

	return light_info
end

if CLIENT then
	local light = Material("sprites/light_ignorez")

	function ENT:DrawEffects()
		if not self:GetOn() then return end

		local light_info = self:GetLightInfo()
		local lightpos = self:LocalToWorld(light_info.Offset)

		local viewnormal = EyePos()
		viewnormal:Negate()
		viewnormal:Add(lightpos)

		local distance = viewnormal:Length()
		local viewdot = -viewnormal:Dot(self:LocalToWorldAngles(light_info.Angle):Forward()) / distance
		if viewdot < 0 then return end

		local visibile = util.PixelVisible(lightpos, 16, self.PixVis)
		local visdot = visibile * viewdot

		local size = math.Clamp(distance * visdot * light_info.Scale, 64, 512)
		distance = math.Clamp(distance, 32, 800)

		local alpha = math.Clamp((1000 - distance) * visdot, 0, 100)

		render.SetMaterial(light)

		local color = self:GetColor()
		color.a = alpha

		render.DrawSprite(lightpos, size, size, color)

		color.r, color.g, color.b = 255, 255, 255
		render.DrawSprite(lightpos, size * 0.4, size * 0.4, color)
	end

	function ENT:DrawTranslucent(flags)
		BaseClass.DrawTranslucent(self, flags)
		self:DrawEffects()
	end

	function ENT:Think()
		if not self:GetOn() then
			self:OnRemove()

			return
		end

		local tab = self:GetTable()
		local lightpos = self:GetPos()
		local flashlight = tab.flashlight

		if not flashlight then
			flashlight = ProjectedTexture()
			tab.flashlight = flashlight

			local light_info = self:GetLightInfo()
			local offset = light_info.Offset * -1
			offset.x = offset.x + 5

			tab.LightOffset = -offset
			tab.LightAngle = light_info.Angle

			local singleplayer = game.SinglePlayer()
			flashlight:SetFOV(singleplayer and self:GetLightFOV() or math.Clamp(self:GetLightFOV(), 10, 170))
			flashlight:SetFarZ(singleplayer and self:GetDistance() or math.Clamp(self:GetDistance(), 64, 2048))
			flashlight:SetBrightness(singleplayer and self:GetBrightness() or math.Clamp(self:GetBrightness(), 0, 8))
			flashlight:SetEnableShadows(true)
			flashlight:SetTexture(self:GetTexture())
			flashlight:SetNearZ(light_info.NearZ)
			flashlight:SetPos(lightpos + tab.LightOffset)
			flashlight:SetAngles(self:GetAngles() + tab.LightAngle)
			flashlight:SetColor(self:GetColor())
			flashlight:Update()
		end

		if lightpos ~= tab.LastUpdatePos then
			tab.LastUpdatePos = lightpos
			flashlight:SetPos(lightpos + tab.LightOffset)
			flashlight:SetAngles(self:GetAngles() + tab.LightAngle)
			flashlight:SetColor(self:GetColor())
			flashlight:Update()
		end
	end

	function ENT:OnValueChange(name, old, new)
		local flashlight = self.flashlight
		if not flashlight then return end

		if name == "Texture" then
			flashlight:SetTexture(new)
		elseif name == "LightFOV" then
			flashlight:SetFOV(game.SinglePlayer() and new or math.Clamp(new, 10, 170))
		elseif name == "Distance" then
			flashlight:SetFarZ(game.SinglePlayer() and new or math.Clamp(new, 64, 2048))
		elseif name == "Brightness" then
			flashlight:SetBrightness(game.SinglePlayer() and new or math.Clamp(new, 0, 8))
		end
	end

	function ENT:OnRemove()
		if self.flashlight then
			self.flashlight:Remove()
			self.flashlight = nil
		end
	end
end

function ENT:TriggerInput(name, value)
	local color = self:GetColor()

	if name == "Red" then
		color.r = math.Clamp(value, 0, 255)
		self:SetColor(color)
	elseif name == "Green" then
		color.g = math.Clamp(value, 0, 255)
		self:SetColor(color)
	elseif name == "Blue" then
		color.b = math.Clamp(value, 0, 255)
		self:SetColor(color)
	elseif name == "RGB" then
		color.r, color.g, color.b = math.Clamp(value.r, 0, 255), math.Clamp(value.g, 0, 255), math.Clamp(value.b, 0, 255)
		self:SetColor(color)
	elseif name == "FOV" then
		self:SetLightFOV(value)
	elseif name == "Distance" then
		self:SetDistance(value)
	elseif name == "Brightness" then
		self:SetBrightness(value)
	elseif name == "On" then
		self:SetOn(value ~= 0)
	elseif name == "Texture" then
		if value ~= "" then
			self:SetTexture(value)
		else
			self:SetTexture("effects/flashlight001")
		end
	end
end

function ENT:PrepareOverlayData()
	local color = self:GetColor()
	self:SetOverlayText(string.format("Red: %i Green: %i Blue: %i\nFOV: %i Distance: %i Brightness: %i", color.r, color.g, color.b, self:GetLightFOV(), self:GetDistance(), self:GetBrightness()))
end

function ENT:Setup(r, g, b, texture, fov, distance, brightness, on)
	local color = self:GetColor()
	self:SetColor(Color(r and math.Clamp(r, 0, 255) or color.r, g and math.Clamp(g, 0, 255) or color.g, b and math.Clamp(b, 0, 255) or color.b))

	if texture then
		self:SetTexture(texture)
	end

	if fov then
		self:SetLightFOV(fov)
	end

	if distance then
		self:SetDistance(distance)
	end

	if brightness then
		self:SetBrightness(brightness)
	end

	if on then
		self:SetOn(on)
	end
end

duplicator.RegisterEntityClass("gmod_wire_lamp", WireLib.MakeWireEnt, "Data", "r", "g", "b", "Texture", "FOV", "Dist", "Brightness", "on")
