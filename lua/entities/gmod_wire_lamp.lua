AddCSLuaFile()

DEFINE_BASECLASS("base_wire_entity")
ENT.PrintName = "Wire Lamp"
ENT.RenderGroup = RENDERGROUP_BOTH
ENT.WireDebugName = "Lamp"

function ENT:SetupDataTables()
	self:NetworkVar("Bool", 0, "On")
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
end

function ENT:Switch(on)
	if on and IsValid(self.flashlight) then return end

	self.on = on
	self:SetOn(on)

	if not on then
		SafeRemoveEntity(self.flashlight)
		self.flashlight = nil

		return
	end

	local flashlight = ents.Create("env_projectedtexture")
	self.flashlight = flashlight
	flashlight:SetParent(self)

	local light_info = self:GetLightInfo()
	local offset = light_info.Offset * -1
	offset.x = offset.x + 5

	flashlight:SetLocalPos(-offset)
	flashlight:SetLocalAngles(light_info.Angle)
	flashlight:SetKeyValue("enableshadows", 1)
	flashlight:SetKeyValue("nearz", light_info.NearZ)
	flashlight:SetKeyValue("farz", self.Dist)
	flashlight:SetKeyValue("lightfov", self.FOV)

	local color, brightness = self:GetColor(), self.Brightness
	flashlight:SetKeyValue("lightcolor", Format("%i %i %i 255", color.r * brightness, color.g * brightness, color.b * brightness))
	flashlight:Spawn()

	flashlight:Input("SpotlightTexture", NULL, NULL, self.Texture)
end

function ENT:UpdateLight()
	local color = Color(self.r, self.g, self.b, self:GetColor().a)
	self:SetColor(color)

	local flashlight = self.flashlight
	if not IsValid(flashlight) then return end

	flashlight:Input("SpotlightTexture", NULL, NULL, self.Texture)
	flashlight:Input("FOV", NULL, NULL, tostring(self.FOV))
	flashlight:SetKeyValue("farz", self.Dist)

	local brightness = self.Brightness
	flashlight:SetKeyValue("lightcolor", Format("%i %i %i 255", color.r * brightness, color.g * brightness, color.b * brightness))

	self:SetOverlayText(string.format("Red: %i Green: %i Blue: %i\nFOV: %i Distance: %i Brightness: %i", color.r, color.g, color.b, self.FOV, self.Dist, self.Brightness))
end

function ENT:TriggerInput(name, value)
	if name == "Red" then
		self.r = math.Clamp(value, 0, 255)
	elseif name == "Green" then
		self.g = math.Clamp(value, 0, 255)
	elseif name == "Blue" then
		self.b = math.Clamp(value, 0, 255)
	elseif name == "RGB" then
		self.r, self.g, self.b = math.Clamp(value.r, 0, 255), math.Clamp(value.g, 0, 255), math.Clamp(value.b, 0, 255)
	elseif name == "FOV" then
		self.FOV = game.SinglePlayer() and value or math.Clamp(fov, 10, 170)
	elseif name == "Distance" then
		self.Dist = game.SinglePlayer() and value or math.Clamp(value, 64, 2048)
	elseif name == "Brightness" then
		self.Brightness = game.SinglePlayer() and value or math.Clamp(value, 0, 8)
	elseif name == "On" then
		self:Switch(value ~= 0)
	elseif name == "Texture" then
		if value ~= "" then
			self.Texture = value
		else
			self.Texture = "effects/flashlight001"
		end
	end

	self:UpdateLight()
end

function ENT:Setup(r, g, b, texture, fov, distance, brightness, on)
	local singleplayer = game.SinglePlayer()
	self.Texture = texture or "effects/flashlight001"
	self.FOV = singleplayer and fov or math.Clamp(fov, 10, 170)
	self.Dist = singleplayer and distance or math.Clamp(distance, 64, 2048)
	self.Brightness = singleplayer and brightness or math.Clamp(brightness, 0, 8)
	self.r, self.g, self.b = math.Clamp(r, 0, 255), math.Clamp(g, 0, 255), math.Clamp(b, 0, 255)

	self.on = on and true or false
	self:Switch(self.on)
	self:UpdateLight()
end

duplicator.RegisterEntityClass("gmod_wire_lamp", WireLib.MakeWireEnt, "Data", "r", "g", "b", "Texture", "FOV", "Dist", "Brightness", "on")
