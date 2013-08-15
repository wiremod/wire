AddCSLuaFile()
DEFINE_BASECLASS( "base_wire_entity" )
ENT.PrintName       = "Wire Lamp"
ENT.RenderGroup		= RENDERGROUP_BOTH
ENT.WireDebugName	= "Lamp"

function ENT:GetEntityDriveMode()
	return "drive_noclip"
end

function ENT:Initialize()
	if CLIENT then
		self.PixVis = util.GetPixelVisibleHandle()
	else
		self:PhysicsInit( SOLID_VPHYSICS )
		self:SetMoveType( MOVETYPE_VPHYSICS )
		self:SetSolid( SOLID_VPHYSICS )
		self:DrawShadow( false )
	
		local phys = self:GetPhysicsObject()
	
		if IsValid( phys ) then
			phys:Wake()
		end
		
		self.Inputs = WireLib.CreateSpecialInputs( self, { "Red", "Green", "Blue", "RGB", "FOV", "Distance", "Brightness", "On", "Texture" }, { "NORMAL", "NORMAL", "NORMAL", "VECTOR", "NORMAL", "NORMAL", "NORMAL", "NORMAL", "STRING" } )
	end
end

function ENT:OnTakeDamage( dmginfo )
	self:TakePhysicsDamage( dmginfo )
end

function ENT:Switch( bOn )
	if IsValid( self.flashlight ) then
		if bOn then return end
		SafeRemoveEntity( self.flashlight )
		self.flashlight = nil
		return
	end
	if not bOn then return end

	local angForward = self:GetAngles()
	
	self.flashlight = ents.Create( "env_projectedtexture" )
	self.flashlight:SetParent( self )
		
	-- The local positions are the offsets from parent..
	self.flashlight:SetLocalPos( Vector( 0, 0, 0 ) )
	self.flashlight:SetLocalAngles( Angle( 0, 0, 0 ) )
		
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
	if not IsValid( self.flashlight ) then return end
	
	self:SetColor( Color( self.r, self.g, self.b, self:GetColor().a ) )
	self.flashlight:Input( "SpotlightTexture", NULL, NULL, self.Texture )
	self.flashlight:Input( "FOV", NULL, NULL, tostring( self.FOV ) )
	self.flashlight:SetKeyValue( "farz", self.Dist )

	local c = self:GetColor()
	local b = self.Brightness
	self.flashlight:SetKeyValue( "lightcolor", Format( "%i %i %i 255", c.r * b, c.g * b, c.b * b ) )

	self:SetOverlayText( "Red: " .. c.r .. " Green: " .. c.g .. " Blue: " .. c.b .. "\n" ..
						 "FoV: " .. self.FOV .. " Distance: " .. self.Dist .. " Brightness: " .. self.Brightness )
end

function ENT:Draw()
	BaseClass.Draw( self )
end

function ENT:DrawTranslucent()
	BaseClass.DrawTranslucent( self )
	
	-- No glow if we're not switched on!
	if not IsValid( self.flashlight ) then return end
	
	local LightNrm = self:GetAngles():Forward()
	local ViewNormal = self:GetPos() - EyePos()
	local Distance = ViewNormal:Length()
	ViewNormal:Normalize()
	local ViewDot = ViewNormal:Dot( LightNrm * -1 )
	local LightPos = self:GetPos() + LightNrm * 5

	if ViewDot >= 0 then
		render.SetMaterial( Material( "sprites/light_ignorez" ) )
		local Visible = util.PixelVisible( LightPos, 16, self.PixVis )	
		
		if not Visible then return end
		
		local Size = math.Clamp( Distance * Visible * ViewDot * 2, 64, 512 )
		
		Distance = math.Clamp( Distance, 32, 800 )
		local Alpha = math.Clamp( ( 1000 - Distance ) * Visible * ViewDot, 0, 100 )
		local Col = self:GetColor()
		Col.a = Alpha
		
		render.DrawSprite( LightPos, Size, Size, Col, Visible * ViewDot )
		render.DrawSprite( LightPos, Size * 0.4, Size * 0.4, Color( 255, 255, 255, Alpha ), Visible * ViewDot )
	end
end

function ENT:TriggerInput(iname, value)
	if (iname == "Red") then
		self.r = value
	elseif (iname == "Green") then
		self.g = value
	elseif (iname == "Blue") then
		self.b = value
	elseif (iname == "RGB") then
		self.r, self.g, self.b = value[1], value[2], value[3]
	elseif (iname == "FOV") then
		self.FOV = value
	elseif (iname == "Distance") then
		self.Dist = value
	elseif (iname == "Brightness") then
		self.Brightness = value
	elseif (iname == "On") then
		self:Switch( value ~= 0 )
	elseif (iname == "Texture") then
		if value ~= "" then self.Texture = value else self.Texture = "effects/flashlight001" end
	end
	self:UpdateLight()
end

function ENT:Setup( r, g, b, Texture, fov, dist, brightness )
	self.r = r or 255
	self.g = g or 255
	self.b = b or 255
	self.Texture = Texture or "effects/flashlight001"
	self.FOV = fov or 90
	self.Dist = dist or 1024
	self.Brightness = brightness or 8
	self:Switch( true )
	self:UpdateLight()
end

duplicator.RegisterEntityClass( "gmod_wire_lamp", WireLib.MakeWireEnt, "Data", "r", "g", "b", "Texture", "FOV", "Dist", "Brightness" )
