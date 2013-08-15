AddCSLuaFile()
DEFINE_BASECLASS( "base_wire_entity" )
ENT.PrintName       = "Wire Light"
ENT.RenderGroup		= RENDERGROUP_TRANSLUCENT
ENT.WireDebugName	= "Light"

local wire_light_block = CreateClientConVar( "wire_light_block", 0, false, false )

function ENT:SetupDataTables()
	self:NetworkVar( "Float", 0, "LightSize" )
	self:NetworkVar( "Float", 1, "Brightness" )
	self:NetworkVar( "Bool", 0, "Glow" )
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

		self.Inputs = WireLib.CreateInputs( self, { "Red", "Green", "Blue", "RGB [VECTOR]" } )
	end
end

function ENT:Draw()
	BaseClass.Draw( self, true )
end

function ENT:Think()
	if CLIENT and self:GetGlow() and not wire_light_block:GetBool() then
		local dlight = DynamicLight( self:EntIndex() )
		if ( dlight ) then
			local c = self:GetColor()

			dlight.Pos = self:GetPos()
			dlight.r = c.r
			dlight.g = c.g
			dlight.b = c.b
			dlight.Brightness = self:GetBrightness()
			dlight.Decay = self:GetLightSize() * 5
			dlight.Size = self:GetLightSize()
			dlight.DieTime = CurTime() + 1
		end
	end
end

function ENT:DrawTranslucent()
	BaseClass.DrawTranslucent( self, true )

	local up = self:GetAngles():Up()
	local LightPos = self:GetPos()
	render.SetMaterial( Material( "sprites/light_ignorez" ) )
	
	local ViewNormal = self:GetPos() - EyePos()
	local Distance = ViewNormal:Length()
	ViewNormal:Normalize()
		
	local Visible = util.PixelVisible( LightPos, 4, self.PixVis )	
	
	if not Visible or Visible < 0.1 then return end
	
	local c = self:GetColor()
	c.a = 255 * Visible

	if self:GetModel() == "models/maxofs2d/light_tubular.mdl" then
		render.DrawSprite( LightPos - up * 2, 8, 8, Color(255, 255, 255, c.a), Visible )
		render.DrawSprite( LightPos - up * 4, 8, 8, Color(255, 255, 255, c.a), Visible )
		render.DrawSprite( LightPos - up * 6, 8, 8, Color(255, 255, 255, c.a), Visible )
		render.DrawSprite( LightPos - up * 5, 128, 128, c, Visible )
	else
		if self:GetModel() == "models/jaanus/wiretool/wiretool_siren.mdl" then c.a = 255 * -Visible end
		render.DrawSprite( LightPos + up * ( self:OBBMaxs() - self:OBBMins() ) / 2, 128, 128, c, Visible )
	end
end

function ENT:OnTakeDamage( dmginfo )
	self:TakePhysicsDamage( dmginfo )
end

function ENT:Directional( On )
	if IsValid( self.DirectionalComponent ) then self.DirectionalComponent:Remove() end 
	if On then
		local flashlight = ents.Create( "env_projectedtexture" )
		flashlight:SetParent( self )

		// The local positions are the offsets from parent..
		flashlight:SetLocalPos( Vector( 0, 0, 0 ) )
		flashlight:SetLocalAngles( Angle( -90, 0, 0 ) )
		if self:GetModel() == "models/maxofs2d/light_tubular.mdl" then
			flashlight:SetLocalAngles( Angle( 90, 0, 0 ) )
		end

		// Looks like only one flashlight can have shadows enabled!
		flashlight:SetKeyValue( "enableshadows", 1 )
		flashlight:SetKeyValue( "farz", 1024 )
		flashlight:SetKeyValue( "nearz", 12 )

		//Todo: Make this tweakable?
		flashlight:SetKeyValue( "lightfov", 90 )
			
		flashlight:SetKeyValue( "lightcolor", Format( "%i %i %i 255", self.R * 8, self.G * 8, self.B * 8 ) )
		flashlight:Spawn()
		flashlight:Input( "SpotlightTexture", NULL, NULL, "effects/flashlight001" )

		self.DirectionalComponent = flashlight
	end
end

function ENT:Radiant( On )
	if IsValid( self.RadiantComponent ) then self.RadiantComponent:Remove() end
	if On then
		local dynlight = ents.Create( "light_dynamic" )
		dynlight:SetPos( self:GetPos() )
		dynlight:SetKeyValue( "_light", Format( "%i %i %i 255", self.R, self.G, self.B ) )
		dynlight:SetKeyValue( "style", 0 )
		dynlight:SetKeyValue( "distance", 255 )
		dynlight:SetKeyValue( "brightness", 5 )
		dynlight:SetParent( self )
		dynlight:Spawn()
		self.RadiantComponent = dynlight
	end
end

function ENT:UpdateLight()
	self:SetColor( Color( self.R, self.G, self.B, self:GetColor().a ) )
	if IsValid( self.DirectionalComponent ) then self.DirectionalComponent:SetKeyValue( "lightcolor", Format( "%i %i %i 255", self.R * 8, self.G * 8, self.B * 8 ) ) end
	if IsValid( self.RadiantComponent ) then self.RadiantComponent:SetKeyValue( "_light", Format( "%i %i %i 255", self.R, self.G, self.B ) ) end
	
	if self:GetGlow() then
		self:SetOverlayText( "Red: " .. self.R .. ", Green: " .. self.G .. ", Blue: " .. self.B .. 
			"\nBrightness: " .. self:GetBrightness() .. ", Size: " .. self:GetLightSize() )
	else
		self:SetOverlayText( "Red: " .. self.R .. ", Green: " .. self.G .. ", Blue: " .. self.B )
	end
end

function ENT:TriggerInput(iname, value)
	if (iname == "Red") then
		self.R = value
	elseif (iname == "Green") then
		self.G = value
	elseif (iname == "Blue") then
		self.B = value
	elseif (iname == "RGB") then
		self.R, self.G, self.B = value[1], value[2], value[3]
	elseif (iname == "GlowBrightness") then
		self:SetBrightness( value )
	elseif (iname == "GlowSize") then
		self:SetLightSize( value )
	end
	self:UpdateLight()
end

function ENT:Setup(directional, radiant, glow, brightness, size, r, g, b)
	self.directional = directional or false
	self.radiant = radiant or false
	self.glow = glow or false
	self.brightness = brightness or 2
	self.size = size or 256
	self.R = r or 0
	self.G = g or 0
	self.B = b or 0
	
	self:Directional( self.directional ) 
	self:Radiant( self.radiant ) 
	self:SetGlow( self.glow )
	self:SetBrightness( self.brightness )
	self:SetLightSize( self.size )

	if self:GetGlow() then
		WireLib.AdjustInputs( self, { "Red", "Green", "Blue", "RGB [VECTOR]", "GlowBrightness", "GlowSize" } )
	else
		WireLib.AdjustInputs( self, { "Red", "Green", "Blue", "RGB [VECTOR]" } )
	end

	self:UpdateLight()
end

duplicator.RegisterEntityClass( "gmod_wire_light", WireLib.MakeWireEnt, "Data", "directional", "radiant", "glow", "brightness", "size", "R", "G", "B" )
