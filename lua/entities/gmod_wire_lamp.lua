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
		self:SetSkin(self:GetLightInfo().Skin or 1)
		self:DrawShadow(false)
		self:PhysWake()

		WireLib.CreateInputs(self, { "Red", "Green", "Blue", "RGB [VECTOR]", "FOV", "Distance", "Brightness", "On", "Texture [STRING]" })
	else
		self.PixVis = util.GetPixelVisibleHandle()
	end
end

-- Custom version to prevent excessive table re-creation
function ENT:GetLightInfo()
	return list.GetForEdit("LampModels")[self:GetModel()] or {}
end

local vector_offset = Vector(5, 0, 0)

if CLIENT then
	local light = Material("sprites/light_ignorez")

	function ENT:DrawEffects()
		if not self:GetOn() then return end

		local light_info = self:GetLightInfo()
		local lightpos = self:LocalToWorld(light_info.Offset or vector_offset)

		local viewnormal = EyePos()
		viewnormal:Negate()
		viewnormal:Add(lightpos)

		local distance = viewnormal:Length()
		viewnormal:Negate()

		local viewdot = viewnormal:Dot(self:LocalToWorldAngles(light_info.Angle or angle_zero):Forward()) / distance
		if viewdot < 0 then return end

		local visibile = util.PixelVisible(lightpos, 16, self.PixVis)
		local visdot = visibile * viewdot

		render.SetMaterial(light)

		local color = self:GetColor()
		color.a = math.Clamp((1000 - math.Clamp(distance, 32, 800)) * visdot, 0, 100)

		local size = math.Clamp(distance * visdot * (light_info.Scale or 2), 64, 512)
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
	if on == IsValid(self.flashlight) then return end

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

	local singleplayer = game.SinglePlayer()
	local light_info = self:GetLightInfo()
	local offset = (light_info.Offset or vector_offset) * -1
	offset.x = offset.x + 5

	flashlight:SetLocalPos(-offset)
	flashlight:SetLocalAngles(light_info.Angle or angle_zero)
	flashlight:SetKeyValue("enableshadows", 1)
	flashlight:SetKeyValue("nearz", light_info.NearZ or 12)
	flashlight:SetKeyValue("farz", singleplayer and self.Dist or math.Clamp(self.Dist, 64, 2048))
	flashlight:SetKeyValue("lightfov", singleplayer and self.FOV or math.Clamp(self.FOV, 10, 170))

	local color = self:GetColor()
	local brightness = singleplayer and self.Brightness or math.Clamp(self.Brightness, 0, 8)
	flashlight:SetKeyValue("lightcolor", Format("%i %i %i 255", color.r * brightness, color.g * brightness, color.b * brightness))
	flashlight:Spawn()

	flashlight:Input("SpotlightTexture", NULL, NULL, self.Texture)
end

function ENT:UpdateLight()
	local color = Color(self.r, self.g, self.b, self:GetColor().a)
	self:SetOverlayText(string.format("Red: %i Green: %i Blue: %i\nFOV: %i Distance: %i Brightness: %i", color.r, color.g, color.b, self.FOV, self.Dist, self.Brightness))
	self:SetColor(color)

	local flashlight = self.flashlight
	if not IsValid(flashlight) then return end

	local singleplayer = game.SinglePlayer()
	flashlight:Input("SpotlightTexture", NULL, NULL, self.Texture)
	flashlight:Input("FOV", NULL, NULL, tostring(singleplayer and self.FOV or math.Clamp(self.FOV, 10, 170)))
	flashlight:SetKeyValue("farz", singleplayer and self.Dist or math.Clamp(self.Dist, 64, 2048))

	local brightness = singleplayer and self.Brightness or math.Clamp(self.Brightness, 0, 8)
	flashlight:SetKeyValue("lightcolor", Format("%i %i %i 255", color.r * brightness, color.g * brightness, color.b * brightness))
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
		self.FOV = value
	elseif name == "Distance" then
		self.Dist = value
	elseif name == "Brightness" then
		self.Brightness = value
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
	self.Texture = texture or "effects/flashlight001"
	self.FOV = fov or 90
	self.Dist = distance or 1024
	self.Brightness = brightness or 8
	self.r, self.g, self.b = math.Clamp(r or 255, 0, 255), math.Clamp(g or 255, 0, 255), math.Clamp(b or 255, 0, 255)

	self.on = on and true or false
	self:Switch(self.on)
	self:UpdateLight()
end

duplicator.RegisterEntityClass("gmod_wire_lamp", WireLib.MakeWireEnt, "Data", "r", "g", "b", "Texture", "FOV", "Dist", "Brightness", "on")
