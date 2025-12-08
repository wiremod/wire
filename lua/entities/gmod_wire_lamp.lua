AddCSLuaFile()

DEFINE_BASECLASS("base_wire_entity")
ENT.PrintName = "Wire Lamp"
ENT.RenderGroup = RENDERGROUP_BOTH
ENT.WireDebugName = "Lamp"

function ENT:SetupDataTables()
	self:NetworkVar("Bool", "On")
	self:NetworkVar("Int", "FOV")
	self:NetworkVar("Int", "Red")
	self:NetworkVar("Int", "Green")
	self:NetworkVar("Int", "Blue")
	self:NetworkVar("Int", "Distance")
	self:NetworkVar("Int", "Brightness")
	self:NetworkVar("String", "Texture")

	self:NetworkVarNotify( "FOV", self.OnVarChanged )
	self:NetworkVarNotify( "Red", self.OnVarChanged )
	self:NetworkVarNotify( "Green", self.OnVarChanged )
	self:NetworkVarNotify( "Blue", self.OnVarChanged )
	self:NetworkVarNotify( "Distance", self.OnVarChanged )
	self:NetworkVarNotify( "Brightness", self.OnVarChanged )
	self:NetworkVarNotify( "Texture", self.OnVarChanged )
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

		local color = Color(self:GetRed(), self:GetGreen(), self:GetBlue())
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
		end

		local light_info = self:GetLightInfo()
		local lightpos = self:LocalToWorld(light_info.Offset or vector_offset)

		local lampMatrix = self:GetWorldTransformMatrix()
		local lastLampMatrix = self.LastLampMatrix or 0
		if lastLampMatrix ~= lampMatrix then
			local projtex = self.ProjTex
			projtex:SetTexture( self:GetTexture() )
			projtex:SetFOV( self:GetFOV() )
			projtex:SetFarZ( self:GetDistance() )
			projtex:SetBrightness( self:GetBrightness() / 255 )
			projtex:SetColor( Color( self:GetRed(), self:GetGreen(), self:GetBlue() ) )
			projtex:SetPos( lightpos )
			projtex:SetAngles( self:LocalToWorldAngles( light_info.Angle or angle_zero ) )
			projtex:SetEnableShadows( false )
			projtex:Update()
		end
		self.LastLampMatrix = lampMatrix
	end

	function ENT:OnRemove()
		if IsValid( self.ProjTex ) then
			self.ProjTex:Remove()
		end
	end

	function ENT:OnVarChanged( varname, oldvalue, newvalue )
		self.LastLampMatrix = nil
	end
end

function ENT:TriggerInput(name, value)
	if name == "Red" then
		self:SetRed(math.Clamp(value, 0, 255))
	elseif name == "Green" then
		self:SetGreen(math.Clamp(value, 0, 255))
	elseif name == "Blue" then
		self:SetBlue(math.Clamp(value, 0, 255))
	elseif name == "RGB" then
		self:SetRed(math.Clamp(value.r, 0, 255))
		self:SetGreen(math.Clamp(value.g, 0, 255))
		self:SetBlue(math.Clamp(value.b, 0, 255))
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
	self:SetRed(r)
	self:SetGreen(g)
	self:SetBlue(b)
	self:SetTexture(texture)
	self:SetFOV(fov)
	self:SetDistance(distance)
	self:SetBrightness(brightness)
	self:SetOn(on)
end

duplicator.RegisterEntityClass("gmod_wire_lamp", WireLib.MakeWireEnt, "Data", "r", "g", "b", "Texture", "FOV", "Dist", "Brightness", "on")
