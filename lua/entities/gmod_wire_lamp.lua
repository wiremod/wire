AddCSLuaFile()
DEFINE_BASECLASS( "base_wire_entity" )
ENT.PrintName       = "Wire Lamp"
ENT.RenderGroup		= RENDERGROUP_BOTH
ENT.WireDebugName	= "Lamp"

function ENT:SetupDataTables()
	self:NetworkVar( "Bool", 0, "On" )
end

if CLIENT then
	local matLight 		= Material( "sprites/light_ignorez" )
	local matBeam		= Material( "effects/lamp_beam" )

	function ENT:Initialize()
		self.PixVis = util.GetPixelVisibleHandle()
	end

	function ENT:DrawTranslucent()

		BaseClass.DrawTranslucent( self )

		-- No glow if we're not switched on!
		if not self:GetOn() then return end

		local LightNrm = self:GetAngles():Forward()
		local ViewNormal = self:GetPos() - EyePos()
		local Distance = ViewNormal:Length()
		ViewNormal:Normalize()
		local ViewDot = ViewNormal:Dot( LightNrm * -1 )
		local LightPos = self:GetPos() + LightNrm * 5

		-- glow sprite
		--[[
		render.SetMaterial( matBeam )

		local BeamDot = BeamDot = 0.25

		render.StartBeam( 3 )
			render.AddBeam( LightPos + LightNrm * 1, 128, 0.0, Color( r, g, b, 255 * BeamDot) )
			render.AddBeam( LightPos - LightNrm * 100, 128, 0.5, Color( r, g, b, 64 * BeamDot) )
			render.AddBeam( LightPos - LightNrm * 200, 128, 1, Color( r, g, b, 0) )
		render.EndBeam()
		--]]

		if ViewDot >= 0 then

			render.SetMaterial( matLight )
			local Visibile	= util.PixelVisible( LightPos, 16, self.PixVis )

			if (not Visibile) then return end

			local Size = math.Clamp( Distance * Visibile * ViewDot * 2, 64, 512 )

			Distance = math.Clamp( Distance, 32, 800 )
			local Alpha = math.Clamp( (1000 - Distance) * Visibile * ViewDot, 0, 100 )
			local Col = self:GetColor()
			Col.a = Alpha

			render.DrawSprite( LightPos, Size, Size, Col, Visibile * ViewDot )
			render.DrawSprite( LightPos, Size*0.4, Size*0.4, Color(255, 255, 255, Alpha), Visibile * ViewDot )

		end
	end

	return  -- No more client
end

-- Server

function ENT:Initialize()
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )

	local phys = self:GetPhysicsObject()

	if (phys:IsValid()) then
		phys:Wake()
	end

	self.Inputs = WireLib.CreateSpecialInputs(self, {"Red", "Green", "Blue", "RGB", "FOV", "Distance", "Brightness", "On", "Texture"}, {"NORMAL", "NORMAL", "NORMAL", "VECTOR", "NORMAL", "NORMAL", "NORMAL", "NORMAL", "STRING"})
end

function ENT:OnTakeDamage( dmginfo )
	self:TakePhysicsDamage( dmginfo )
end

function ENT:TriggerInput(iname, value)
	if (iname == "Red") then
		self.r = math.Clamp(value,0,255)
	elseif (iname == "Green") then
		self.g = math.Clamp(value,0,255)
	elseif (iname == "Blue") then
		self.b = math.Clamp(value,0,255)
	elseif (iname == "RGB") then
		self.r, self.g, self.b = math.Clamp(value[1],0,255), math.Clamp(value[2],0,255), math.Clamp(value[3],0,255)
	elseif (iname == "FOV") then
		self.FOV = value
	elseif (iname == "Distance") then
		self.Dist = value
	elseif (iname == "Brightness") then
		self.Brightness = math.Clamp(value,0,10)
	elseif (iname == "On") then
		self:Switch( value ~= 0 )
	elseif (iname == "Texture") then
		if value ~= "" then self.Texture = value else self.Texture = "effects/flashlight001" end
	end
	self:UpdateLight()
end

function ENT:Switch( on )
	if on ~= not self.flashlight then return end
	self.on = on

	if not on then
		SafeRemoveEntity( self.flashlight )
		self.flashlight = nil
		self:SetOn( false )
		return
	end

	self:SetOn( true )

	local angForward = self:GetAngles()

	self.flashlight = ents.Create( "env_projectedtexture" )

		self.flashlight:SetParent( self )

		-- The local positions are the offsets from parent..
		self.flashlight:SetLocalPos( Vector( 0, 0, 0 ) )
		self.flashlight:SetLocalAngles( Angle(0,0,0) )

		-- Looks like only one flashlight can have shadows enabled!
		self.flashlight:SetKeyValue( "enableshadows", 1 )

		self.flashlight:SetKeyValue( "farz", self.Dist )
		self.flashlight:SetKeyValue( "nearz", 12 )
		self.flashlight:SetKeyValue( "lightfov", self.FOV )

		local c = self:GetColor()
		local b = self.Brightness
		self.flashlight:SetKeyValue( "lightcolor", Format( "%i %i %i 255", c.r * b, c.g * b, c.b * b ) )

	self.flashlight:Spawn()

	self.flashlight:Input( "SpotlightTexture", NULL, NULL, self.Texture )
end

function ENT:UpdateLight()
	self:SetColor( Color( self.r, self.g, self.b, self:GetColor().a ) )
	if ( not IsValid( self.flashlight ) ) then return end

	self.flashlight:Input( "SpotlightTexture", NULL, NULL, self.Texture )
	self.flashlight:Input( "FOV", NULL, NULL, tostring( self.FOV ) )
	self.flashlight:SetKeyValue( "farz", self.Dist )

	local c = self:GetColor()
	local b = self.Brightness
	self.flashlight:SetKeyValue( "lightcolor", Format( "%i %i %i 255", c.r*b, c.g*b, c.b*b ) )

	self:SetOverlayText( "Red: " .. c.r .. " Green: " .. c.g .. " Blue: " .. c.b .. "\n" ..
						 "FoV: " .. self.FOV .. " Distance: " .. self.Dist .. " Brightness: " .. self.Brightness )
end

function ENT:Setup( r, g, b, Texture, fov, dist, brightness, on )
	self.r, self.g, self.b = math.Clamp(r or 255,0,255), math.Clamp(g or 255,0,255), math.Clamp(b or 255,0,255)

	self.Texture = Texture or "effects/flashlight001"
	self.FOV = fov or 90
	self.Dist = dist or 1024
	self.Brightness = math.Clamp(brightness or 8,0,10)
	self.on = on or false
	self:Switch( self.on )
	self:UpdateLight()
end

duplicator.RegisterEntityClass( "gmod_wire_lamp", WireLib.MakeWireEnt, "Data", "r", "g", "b", "Texture", "FOV", "Dist", "Brightness", "on" )
