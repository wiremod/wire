AddCSLuaFile()
DEFINE_BASECLASS( "base_wire_entity" )
ENT.PrintName       = "Wire Lamp"
ENT.RenderGroup		= RENDERGROUP_BOTH
ENT.WireDebugName	= "Lamp"


-- Shared

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
		
		self.BaseClass.DrawTranslucent( self )
		
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
			
			if (!Visibile) then return end
			
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

function ENT:SetLightColor( r, g, b )
	-- for dupe
	self.r = r
	self.g = g
	self.b = b

	self:SetColor(Color(r, g, b, 255))
end

function ENT:OnTakeDamage( dmginfo )
	self:TakePhysicsDamage( dmginfo )
end

function ENT:TriggerInput(iname, value)
	if (iname == "Red") then
		self:SetLightColor( value, self.g, self.b )
	elseif (iname == "Green") then
		self:SetLightColor( self.r, value, self.b )
	elseif (iname == "Blue") then
		self:SetLightColor( self.r, self.g, value )
	elseif (iname == "RGB") then
		self:SetLightColor( value[1], value[2], value[3] )
	elseif (iname == "FOV") then
		self.FOV = value
	elseif (iname == "Distance") then
		self.Dist = value
	elseif (iname == "Brightness") then
		self.Brightness = value
	elseif (iname == "On") then
		if value > 0 then
			if !self.flashlight then self:TurnOn() end
		elseif self.flashlight then
			self:TurnOff()
		end
	elseif (iname == "Texture") then
		if value != "" then self.Texture = value else self.Texture = "effects/flashlight001" end
	end
	self:UpdateLight()
end

function ENT:TurnOn()
	self:SetOn(true)
	local angForward = self:GetAngles() + Angle( 90, 0, 0 )
	
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

function ENT:TurnOff()
	self:SetOn(false)
	SafeRemoveEntity( self.flashlight )
	self.flashlight = nil
end

function ENT:UpdateLight()
	if ( !IsValid( self.flashlight ) ) then return end

	self.flashlight:Input( "SpotlightTexture", NULL, NULL, self.Texture )
	self.flashlight:Input( "FOV", NULL, NULL, tostring( self.FOV ) )
	self.flashlight:SetKeyValue( "farz", self.Dist )

	local c = self:GetColor()
	local b = self.Brightness
	self.flashlight:SetKeyValue( "lightcolor", Format( "%i %i %i 255", c.r*b, c.g*b, c.b*b ) )
	
	self:SetOverlayText( "Red: " .. c.r .. " Green: " .. c.g .. " Blue: " .. c.b .. "\n" ..
						 "FoV: " .. self.FOV .. " Distance: " .. self.Dist .. " Brightness: " .. self.Brightness)
end

function ENT:Setup( r, g, b, Texture, fov, dist, brightness )
	self:SetLightColor( r or 255, g or 255, b or 255 )
	
	self.Texture = Texture or "effects/flashlight001"
	self.FOV = fov or 90
	self.Dist = dist or 1024
	self.Brightness = brightness or 8
	self:UpdateLight()
	self:TurnOn()
end

duplicator.RegisterEntityClass( "gmod_wire_lamp", MakeWireEnt, "Data", "r", "g", "b", "Texture", "FOV", "Dist", "Brightness" )
