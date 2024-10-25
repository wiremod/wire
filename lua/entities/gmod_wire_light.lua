AddCSLuaFile()
DEFINE_BASECLASS( "base_wire_entity" )
ENT.PrintName       = "Wire Light"
ENT.RenderGroup		= RENDERGROUP_BOTH
ENT.WireDebugName	= "Light"

function ENT:SetupDataTables()
	self:NetworkVar("Bool", 0, "On")
	self:NetworkVar( "Bool", 1, "Glow" )
	self:NetworkVar( "Float", 0, "Brightness" )
	self:NetworkVar( "Float", 1, "Size" )
	self:NetworkVar( "Float", 2, "SpriteSize" )
	self:NetworkVar( "Int", 0, "R" )
	self:NetworkVar( "Int", 1, "G" )
	self:NetworkVar( "Int", 2, "B" )
end

if CLIENT then
	local matLight 		= Material( "sprites/light_ignorez" )
	local matBeam		= Material( "effects/lamp_beam" )

	function ENT:Initialize()
		self.PixVis = util.GetPixelVisibleHandle()

		--[[
		This is some unused value which is used to activate the wire overlay.
		We're not using it because we are using NetworkVars instead, since wire
		overlays only update when you look at them, and we want to update the
		sprite colors whenever the wire input changes. ]]
		self:SetOverlayData({})
	end

	function ENT:GetMyColor()
		return Color( self:GetR(), self:GetG(), self:GetB(), 255 )
	end

	function ENT:DrawTranslucent()
		if not self:GetOn() then return end

		local LightPos = self:GetPos()
		render.SetMaterial( matLight )

		local ViewNormal = self:GetPos() - EyePos()
		local Distance = ViewNormal:Length()
		ViewNormal:Normalize()

		local Visible = util.PixelVisible( LightPos, 4, self.PixVis )

		if not Visible or Visible < 0.1 then return end

		local c = self:GetMyColor()
		if self:GetModel() == "models/maxofs2d/light_tubular.mdl" then
			local up = self:GetUp()
			render.DrawSprite( LightPos - up * 2, 8, 8, c, Visible )
			render.DrawSprite( LightPos - up * 4, 8, 8, c, Visible )
			render.DrawSprite( LightPos - up * 6, 8, 8, c, Visible )
			render.DrawSprite( LightPos - up * 5, self:GetSpriteSize(), self:GetSpriteSize(), c, Visible )
		else
			render.DrawSprite( self:LocalToWorld( self:OBBCenter() ), self:GetSpriteSize(), self:GetSpriteSize(), c, Visible )
		end
	end

	local wire_light_block = CreateClientConVar("wire_light_block", 0, false, false)

	function ENT:Think()
		if self:GetOn() and self:GetGlow() and not wire_light_block:GetBool() and self:GetSize() > 0 then -- if size is 0 then the light is invisible
			local dlight = DynamicLight(self:EntIndex())
			if dlight then
				dlight.Pos = self:GetPos()

				local c = self:GetMyColor()
				dlight.r = c.r
				dlight.g = c.g
				dlight.b = c.b

				dlight.Brightness = self:GetBrightness()
				dlight.Decay = self:GetSize() * 5
				dlight.Size = self:GetSize()
				dlight.DieTime = CurTime() + 1
			end
		end
	end

	local color_box_size = 64
	function ENT:GetWorldTipBodySize()
		-- text
		local w_total,h_total = surface.GetTextSize( "Color:\n255,255,255,255" )

		-- Color box width
		w_total = math.max(w_total,color_box_size)

		-- Color box height
		h_total = h_total + 18 + color_box_size + 18/2

		return w_total, h_total
	end
	
	local function drawColorBox( color, x, y )
		surface.SetDrawColor( color )
		surface.DrawRect( x, y, color_box_size, color_box_size )

		local size = color_box_size

		surface.SetDrawColor(0, 0, 0)
		surface.DrawLine( x, 		y, 			x + size, 	y )
		surface.DrawLine( x + size, y, 			x + size, 	y + size )
		surface.DrawLine( x + size, y + size, 	x, 			y + size )
		surface.DrawLine( x, 		y + size, 	x, 			y )
	end

	function ENT:DrawWorldTipBody( pos )
		-- get color
		local color = self:GetMyColor()

		-- text
		local color_text = string.format("Color:\n%d,%d,%d",color.r,color.g,color.b)

		local w,h = surface.GetTextSize( color_text )
		draw.DrawText( color_text, "GModWorldtip", pos.center.x, pos.min.y + pos.edgesize, color_white, TEXT_ALIGN_CENTER )

		-- color box
		drawColorBox( color, pos.center.x - color_box_size / 2, pos.min.y + pos.edgesize * 1.5 + h )
	end

	return  -- No more client
end

-- Server

function ENT:Initialize()
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )

	self.Inputs = WireLib.CreateInputs(self, {"Red", "Green", "Blue", "RGB [VECTOR]"})
end

function ENT:Directional( On )
	if On then
		if IsValid( self.DirectionalComponent ) then return end

		local flashlight = ents.Create( "env_projectedtexture" )
		flashlight:SetParent( self )

		-- The local positions are the offsets from parent..
		flashlight:SetLocalPos( Vector( 0, 0, 0 ) )
		flashlight:SetLocalAngles( Angle( -90, 0, 0 ) )
		if self:GetModel() == "models/maxofs2d/light_tubular.mdl" then
			flashlight:SetLocalAngles( Angle( 90, 0, 0 ) )
		end

		-- Looks like only one flashlight can have shadows enabled!
		flashlight:SetKeyValue( "enableshadows", 1 )
		flashlight:SetKeyValue( "farz", 1024 )
		flashlight:SetKeyValue( "nearz", 12 )
		flashlight:SetKeyValue( "lightfov", 90 )

		local c = self:GetColor()
		local b = self.brightness
		flashlight:SetKeyValue( "lightcolor", Format( "%i %i %i 255", c.r * b, c.g * b, c.b * b ) )

		flashlight:Spawn()
		flashlight:Input( "SpotlightTexture", NULL, NULL, "effects/flashlight001" )

		self.DirectionalComponent = flashlight
	elseif IsValid( self.DirectionalComponent ) then
		self.DirectionalComponent:Remove()
		self.DirectionalComponent = nil
	end
end

function ENT:Radiant( On )
	if On then
		if IsValid( self.RadiantComponent ) then
			self.RadiantComponent:Fire( "TurnOn", "", "0" )
		else
			local dynlight = ents.Create( "light_dynamic" )
			dynlight:SetPos( self:GetPos() )
			local dynlightpos = dynlight:GetPos() + Vector( 0, 0, 10 )
			dynlight:SetPos( dynlightpos )
			dynlight:SetKeyValue( "_light", Format( "%i %i %i 255", self.R, self.G, self.B ) )
			dynlight:SetKeyValue( "style", 0 )
			dynlight:SetKeyValue( "distance", 255 )
			dynlight:SetKeyValue( "spotlight_radius", self.size )
			dynlight:SetKeyValue( "brightness", self.brightness )
			dynlight:SetParent( self )
			dynlight:Spawn()

			self.RadiantComponent = dynlight
		end
	elseif IsValid( self.RadiantComponent ) then
		self.RadiantComponent:Fire( "TurnOff", "", "0" )
	end
end

function ENT:UpdateLight()
	self:SetR( self.R )
	self:SetG( self.G )
	self:SetB( self.B )

	local onState = self:GetOn()
	if self.directional and onState then
		-- Creates the directional entity OR does nothing if it already exists
		self:Directional(true)
		self.DirectionalComponent:SetKeyValue("lightcolor", Format("%i %i %i 255", self.R * self.brightness, self.G * self.brightness, self.B * self.brightness))
	else
		-- Removes the directional entity, or does nothing if it doesn't exist
		self:Directional(false)
	end

	if self.radiant then
		-- Does nothing if radiant already exists, otherwise turns it off
		self:Radiant(onState)
		self.RadiantComponent:SetKeyValue("_light", Format("%i %i %i 255", self.R, self.G, self.B))
	end
end

function ENT:TriggerInput(iname, value)
	if iname == "On" then
		self:SetOn(value ~= 0)
	elseif (iname == "Red") then
		self.R = math.Clamp(value,0,255)
	elseif (iname == "Green") then
		self.G = math.Clamp(value,0,255)
	elseif (iname == "Blue") then
		self.B = math.Clamp(value,0,255)
	elseif (iname == "RGB") then
		self.R, self.G, self.B = math.Clamp(value[1],0,255), math.Clamp(value[2],0,255), math.Clamp(value[3],0,255)
	elseif (iname == "GlowBrightness") then
		if not game.SinglePlayer() then value = math.Clamp( value, 0, 10 ) end
		self.brightness = value
		self:SetBrightness( value )
	elseif (iname == "GlowSize") then
		if not game.SinglePlayer() then value = math.Clamp( value, 0, 1024 ) end
		self.size = value
		self:SetSize( value )
	elseif (iname == "SpriteSize") then
		if not game.SinglePlayer() then value = math.Clamp( value, 0, 256 ) end
		self:SetSpriteSize( value )
	end

	self:UpdateLight()
end

function ENT:Setup(directional, radiant, glow, brightness, size, r, g, b, spritesize, startOn)
	self.directional = directional or false
	self.radiant = radiant or false
	self.glow = glow or false
	self.brightness = brightness or 2
	self.size = size or 256
	self.spritesize = spritesize or 128
	self.R = r or 255
	self.G = g or 255
	self.B = b or 255

	if not game.SinglePlayer() then
		self.brightness = math.Clamp( self.brightness, 0, 10 )
		self.size = math.Clamp( self.size, 0, 1024 )
		self.spritesize = math.Clamp( self.spritesize, 0, 256 )
	end

	self:SetOn(startOn == nil or startOn)
	self:Directional( self.directional )
	self:Radiant( self.radiant )
	self:SetGlow( self.glow )
	self:SetBrightness( self.brightness )
	self:SetSize( self.size )
	self:SetSpriteSize( self.spritesize )

	local inputs = {"On", "Red", "Green", "Blue", "RGB [VECTOR]", "SpriteSize"}
	if self.glow then
		table.insert(inputs, 5, "GlowBrightness")
		table.insert(inputs, 6, "GlowSize")
	end

	WireLib.AdjustInputs(self, inputs)

	self:UpdateLight()
end

duplicator.RegisterEntityClass("gmod_wire_light", WireLib.MakeWireEnt, "Data", "directional", "radiant", "glow", "brightness", "size", "R", "G", "B", "spritesize", "startOn")
