AddCSLuaFile()

DEFINE_BASECLASS("base_wire_entity")
ENT.PrintName = "Wire Lamp"
ENT.RenderGroup = RENDERGROUP_BOTH
ENT.WireDebugName = "Lamp"

function ENT:SetupDataTables()
	self:NetworkVar("Bool", "On")
	self:NetworkVar("Int", "FOV")
	self:NetworkVar("Int", "Distance")
	self:NetworkVar("Int", "Brightness")
	self:NetworkVar("String", "Texture")

	if CLIENT then
		local function callOnVarChanged( _, ... ) -- Fixes autorefresh
			self:OnVarChanged( ... )
		end
		self:NetworkVarNotify( "FOV", callOnVarChanged )
		self:NetworkVarNotify( "Distance", callOnVarChanged )
		self:NetworkVarNotify( "Brightness", callOnVarChanged )
		self:NetworkVarNotify( "Texture", callOnVarChanged )
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

	function ENT:UpdateProjTex()
		local projtex = self.ProjTex
		if not IsValid(projtex) then return end

		projtex:SetEnableShadows( false )
		projtex:SetTexture( self:GetTexture() )
		projtex:SetFOV( self:GetFOV() )
		projtex:SetFarZ( self:GetDistance() )
		projtex:SetBrightness( self:GetBrightness() / 255 )
		projtex:SetColor( self:GetColor() )
		projtex:Update()
	end

	function ENT:Think()
		if not self:GetOn() then
			if IsValid( self.ProjTex ) then
				self.ProjTex:Remove()
				self.ProjTex = nil
				self.LastLampMatrix = nil
			end
			return
		end

		-- Projected texture
		if not IsValid( self.ProjTex ) then
			self.ProjTex = ProjectedTexture()
			self:UpdateProjTex()
		end

		local light_info = self:GetLightInfo()
		local lightpos = self:LocalToWorld(light_info.Offset or vector_offset)

		local lampMatrix = self:GetWorldTransformMatrix()
		local lastLampMatrix = self.LastLampMatrix
		if lastLampMatrix ~= lampMatrix then
			local projtex = self.ProjTex
			projtex:SetPos( lightpos )
			projtex:SetAngles( self:LocalToWorldAngles( light_info.Angle or angle_zero ) )
			projtex:Update()

			self.LastLampMatrix = lampMatrix
		end

		local lastColor = self.LastColor
		local currentColor = self:GetColor()
		if lastColor ~= currentColor then
			self:UpdateProjTex()
			self.LastColor = currentColor
		end
	end

	function ENT:OnRemove()
		if IsValid( self.ProjTex ) then
			self.ProjTex:Remove()
		end
	end

	function ENT:OnVarChanged( varname, oldvalue, newvalue )
		timer.Simple( 0, function()
			if not IsValid( self ) then return end
			if not IsValid( self.ProjTex ) then return end
			self:UpdateProjTex()
		end )
	end
end

function ENT:TriggerInput(name, value)
	if name == "Red" then
		local currentColor = self:GetColor()
		currentColor.r = math.Clamp(value, 0, 255)
		self:SetColor(currentColor)
	elseif name == "Green" then
		local currentColor = self:GetColor()
		currentColor.g = math.Clamp(value, 0, 255)
		self:SetColor(currentColor)
	elseif name == "Blue" then
		local currentColor = self:GetColor()
		currentColor.b = math.Clamp(value, 0, 255)
		self:SetColor(currentColor)
	elseif name == "RGB" then
		local r = math.Clamp(value[1], 0, 255)
		local g = math.Clamp(value[2], 0, 255)
		local b = math.Clamp(value[3], 0, 255)
		self:SetColor(Color(r, g, b))
	elseif name == "FOV" then
		self:SetFOV(value)
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

function ENT:Setup(r, g, b, texture, fov, distance, brightness, on)
	r = math.Clamp(r or 255, 0, 255)
	g = math.Clamp(g or 255, 0, 255)
	b = math.Clamp(b or 255, 0, 255)

	self:SetColor(Color(r, g, b))
	self:SetTexture(texture or "effects/flashlight001")
	self:SetFOV(fov or 90)
	self:SetDistance(distance or 1024)
	self:SetBrightness(brightness or 8)
	self:SetOn(on and true or false)
end

duplicator.RegisterEntityClass("gmod_wire_lamp", WireLib.MakeWireEnt, "Data", "r", "g", "b", "Texture", "FOV", "Dist", "Brightness", "on")
