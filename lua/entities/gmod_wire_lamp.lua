AddCSLuaFile()

DEFINE_BASECLASS("base_wire_entity")
ENT.PrintName = "Wire Lamp"
ENT.WantsTranslucency = true
ENT.WireDebugName = "Lamp"

function ENT:SetupDataTables()
	self:NetworkVar("Bool", "On")
	self:NetworkVar("Int", "FOV")
	self:NetworkVar("Int", "Distance")
	self:NetworkVar("Int", "Brightness")
	self:NetworkVar("String", "Texture")

	if CLIENT then
		self:NetworkVarNotify("FOV", self.OnVarChanged)
		self:NetworkVarNotify("Distance", self.OnVarChanged)
		self:NetworkVarNotify("Brightness", self.OnVarChanged)
		self:NetworkVarNotify("Texture", self.OnVarChanged)
	end
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

	function ENT:DrawTranslucent(flags)
		BaseClass.DrawTranslucent(self, flags)

		if self:GetOn() then
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
	end

	function ENT:OnVarChanged(name, old, new)
		local flashlight = self.Flashlight
		if not flashlight then return end

		if name == "FOV" then
			flashlight:SetFOV(game.SinglePlayer() and new or math.Clamp(new, 0, 170))
		elseif name == "Distance" then
			flashlight:SetFarZ(game.SinglePlayer() and new or math.Clamp(new, 64, 2048))
		elseif name == "Brightness" then
			flashlight:SetBrightness(game.SinglePlayer() and new or math.Clamp(new, 0, 8))
		elseif name == "Texture" then
			flashlight:SetTexture(new)
		end

		self.LastLampMatrix = nil
		self.LastLampColor = nil
	end

	function ENT:Think()
		if not self:GetOn() then
			self:OnRemove()

			return
		end

		if not self.Flashlight then
			local light_info = self:GetLightInfo()
			local flashlight = ProjectedTexture()
			local singleplayer = game.SinglePlayer()

			flashlight:SetNearZ(light_info.NearZ or 12)
			flashlight:SetFarZ(singleplayer and self:GetDistance() or math.Clamp(self:GetDistance(), 64, 2048))
			flashlight:SetFOV(singleplayer and self:GetFOV() or math.Clamp(self:GetFOV(), 0, 170))
			flashlight:SetBrightness(singleplayer and self:GetBrightness() or math.Clamp(self:GetBrightness(), 0, 8))
			flashlight:SetTexture(self:GetTexture())

			self.Flashlight = flashlight
		end

		local matrix = self:GetWorldTransformMatrix()
		local color = self:GetColor()

		if self.LastLampMatrix ~= matrix or self.LastLampColor ~= color then
			local flashlight = self.Flashlight
			local light_info = self:GetLightInfo()
			local lightpos = self:LocalToWorld(light_info.Offset or vector_offset)

			flashlight:SetColor(color)
			flashlight:SetPos(lightpos)
			flashlight:SetAngles(self:LocalToWorldAngles(light_info.Angle or angle_zero))
			flashlight:Update()

			self.LastLampMatrix = matrix
			self.LastLampColor = color
		end
	end

	function ENT:OnRemove()
		if self.Flashlight then
			self.Flashlight:Remove()
			self.Flashlight = nil
			self.LastLampMatrix = nil
			self.LastLampColor = nil
		end
	end

	return
end

function ENT:TriggerInput(name, value)
	local color = self:GetColor()

	if name == "On" then
		self:SetOn(value ~= 0)
	elseif name == "FOV" then
		self:SetFOV(value)
	elseif name == "Red" then
		local color = self:GetColor()
		color.r = value
		self:SetColor(color)
	elseif name == "Green" then
		local color = self:GetColor()
		color.g = value
		self:SetColor(color)
	elseif name == "Blue" then
		local color = self:GetColor()
		color.b = value
		self:SetColor(color)
	elseif name == "RGB" then
		local color = self:GetColor()
		color.r = value.r
		color.g = value.g
		color.b = value.b
		self:SetColor(color)
	elseif name == "Distance" then
		self:SetDistance(value)
	elseif name == "Brightness" then
		self:SetBrightness(value)
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
	self:SetOverlayText(string.format("Red: %i Green: %i Blue: %i\nFOV: %i Distance: %i Brightness: %i", color.r, color.g, color.b, self:GetFOV(), self:GetDistance(), self:GetBrightness()))
end

function ENT:Setup(r, g, b, texture, fov, distance, brightness, on)
	self:SetOn(on and true or false)
	self:SetFOV(fov or 90)
	self:SetDistance(distance or 1024)
	self:SetBrightness(brightness or 8)
	self:SetTexture(texture or "effects/flashlight001")

	local color = self:GetColor()
	color.r, color.g, color.b = math.Clamp(r or 255, 0, 255), math.Clamp(g or 255, 0, 255), math.Clamp(b or 255, 0, 255)
	self:SetColor(color)
end

duplicator.RegisterEntityClass("gmod_wire_lamp", WireLib.MakeWireEnt, "Data", "r", "g", "b", "Texture", "FOV", "Dist", "Brightness", "on")
