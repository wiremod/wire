AddCSLuaFile()
DEFINE_BASECLASS( "base_wire_entity" )
ENT.PrintName       = "Wire Light"
ENT.RenderGroup		= RENDERGROUP_BOTH
ENT.WireDebugName	= "Light"

function ENT:SetupDataTables()
	self:NetworkVar( "Bool", 0, "Glow" )
	self:NetworkVar( "Float", 0, "Brightness" )
	self:NetworkVar( "Float", 1, "Decay" )
	self:NetworkVar( "Float", 2, "Size" )
end

if CLIENT then 
	local matLight 		= Material( "sprites/light_ignorez" )
	local matBeam		= Material( "effects/lamp_beam" )

	function ENT:Initialize()
		self.PixVis = util.GetPixelVisibleHandle()
	end

	function ENT:DrawTranslucent()
		local up = self:GetAngles():Up()
		
		local LightPos = self:GetPos()
		render.SetMaterial( matLight )
		
		local ViewNormal = self:GetPos() - EyePos()
		local Distance = ViewNormal:Length()
		ViewNormal:Normalize()
			
		local Visible	= util.PixelVisible( LightPos, 4, self.PixVis )	
		
		if ( !Visible || Visible < 0.1 ) then return end

		local c = self:GetColor()
		c.a = 255 * Visible
		
		if self:GetModel() == "models/maxofs2d/light_tubular.mdl" then
			render.DrawSprite( LightPos - up * 2, 8, 8, c, Visible )
			render.DrawSprite( LightPos - up * 4, 8, 8, c, Visible )
			render.DrawSprite( LightPos - up * 6, 8, 8, c, Visible )
			render.DrawSprite( LightPos - up * 5, 64, 64, c, Visible )
		else
			if self:GetModel() == "models/jaanus/wiretool/wiretool_siren.mdl" then c.a = 255 * -Visible end
			render.DrawSprite( LightPos + up * ( self:OBBMaxs() - self:OBBMins() ) / 2, 128, 128, c, Visible )
		end

	end

	local wire_light_block = CreateClientConVar("wire_light_block", 0, false, false)

	function ENT:Think()
		if self:GetGlow() and not wire_light_block:GetBool() then
			local dlight = DynamicLight(self:EntIndex())
			if dlight then
				dlight.Pos = self:GetPos()
				
				local c = self:GetColor()
				dlight.r = c.r
				dlight.g = c.g
				dlight.b = c.b
				
				dlight.Brightness = self:GetBrightness()
				dlight.Decay = self:GetDecay()
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
	
	local white = Color(255,255,255,255)
	local black = Color(0,0,0,255)
	
	local function drawColorBox( color, x, y )
		surface.SetDrawColor( color )
		surface.DrawRect( x, y, color_box_size, color_box_size )
	
		local size = color_box_size
	
		surface.SetDrawColor( black )
		surface.DrawLine( x, 		y, 			x + size, 	y )
		surface.DrawLine( x + size, y, 			x + size, 	y + size )
		surface.DrawLine( x + size, y + size, 	x, 			y + size )
		surface.DrawLine( x, 		y + size, 	x, 			y )
	end
	
	function ENT:DrawWorldTipBody( pos )
		-- get colors
		local data = self:GetOverlayData()
		local color = Color(data.r or 255,data.g or 255,data.b or 255,255)
				
		-- text
		local color_text = string.format("Color:\n%d,%d,%d",color.r,color.g,color.b)
		
		local w,h = surface.GetTextSize( color_text )
		draw.DrawText( color_text, "GModWorldtip", pos.center.x, pos.min.y + pos.edgesize, white, TEXT_ALIGN_CENTER )
		
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

	self.R, self.G, self.B = 0,0,0

	self.Inputs = WireLib.CreateInputs(self, {"Red", "Green", "Blue", "RGB [VECTOR]"})
end

function ENT:OnRemove()
	if not IsValid(self.RadiantComponent) then return end
	self.RadiantComponent:SetParent() //Bugfix by aVoN
	self.RadiantComponent:Fire("TurnOff","",0)
	self.RadiantComponent:Fire("kill","",1)
end

function ENT:DirectionalOn()
	if IsValid(self.DirectionalComponent) then
		self:DirectionalOff()
	end

	local flashlight = ents.Create( "env_projectedtexture" )
		flashlight:SetParent( self )

		// The local positions are the offsets from parent..
		flashlight:SetLocalPos( Vector( 0, 0, 0 ) )
		flashlight:SetAngles( self:GetAngles() + Angle( -90, 0, 0 ) )

		// Looks like only one flashlight can have shadows enabled!
		flashlight:SetKeyValue( "enableshadows", 1 )
		flashlight:SetKeyValue( "farz", 2048 )
		flashlight:SetKeyValue( "nearz", 8 )

		//Todo: Make this tweakable?
		flashlight:SetKeyValue( "lightfov", 50 )

		// Color.. Bright pink if none defined to alert us to error
		flashlight:SetKeyValue( "lightcolor", "255 0 255" )
	flashlight:Spawn()
	flashlight:Input( "SpotlightTexture", NULL, NULL, "effects/flashlight001" )

	self.DirectionalComponent = flashlight
end

function ENT:DirectionalOff()
	if not IsValid(self.DirectionalComponent) then return end

	self.DirectionalComponent:Remove()
	self.DirectionalComponent = nil
end

function ENT:RadiantOn()
	if IsValid(self.RadiantComponent) then
		self.RadiantComponent:Fire("TurnOn","","0")
	else
		local dynlight = ents.Create( "light_dynamic" )
		dynlight:SetPos( self:GetPos() )
		local dynlightpos = dynlight:GetPos()+Vector( 0, 0, 10 )
		dynlight:SetPos( dynlightpos )
		dynlight:SetKeyValue( "_light", self.R .. " " .. self.G .. " " .. self.B .. " " .. 255 )
		dynlight:SetKeyValue( "style", 0 )
		dynlight:SetKeyValue( "distance", 255 )
		dynlight:SetKeyValue( "brightness", 5 )
		dynlight:SetParent( self )
		dynlight:Spawn()
		self.RadiantComponent = dynlight
	end

	self.RadiantState = true
end

function ENT:RadiantOff()
	if not IsValid(self.RadiantComponent) then return end
	self.RadiantComponent:Fire("TurnOff","","0")

	self.RadiantState = false
	--self.RadiantComponent:Remove()
	--self.RadiantComponent = nil
end


function ENT:GlowOn()
	self:SetGlow(true)

	self.GlowState = true
	self.brightness = self:GetBrightness()
	self.decay = self:GetDecay()
	self.size = self:GetSize()
end

function ENT:GlowOff()
	self:SetGlow(false)

	self.GlowState = false
end

function ENT:TriggerInput(iname, value)
	local R,G,B = self.R, self.G, self.B
	if (iname == "Red") then
		R = value
	elseif (iname == "Green") then
		G = value
	elseif (iname == "Blue") then
		B = value
	elseif (iname == "RGB") then
		R,G,B = value[1], value[2], value[3]
	elseif (iname == "GlowBrightness") then
		if not game.SinglePlayer() then math.Clamp( value, 0, 10 ) end
		self:SetBrightness(value)
	elseif (iname == "GlowDecay") then
		if not game.SinglePlayer() then math.Clamp( value, 0, 5120 ) end
		self:SetDecay(value)
	elseif (iname == "GlowSize") then
		if not game.SinglePlayer() then math.Clamp( value, 0, 2048 ) end
		self:SetSize(value)
	end
	if ( R ~= self.R or G ~= self.G or B ~= self.B ) then
		self:SetRGB( R, G, B )
	end
end

function ENT:Setup(directional, radiant, glow, brightness, size, decay, r, g, b)
	if not game.SinglePlayer() then
		brightness = math.Clamp( brightness, 0, 10 )
		decay = math.Clamp( decay, 0, 5120 )
		size = math.Clamp( size, 0, 2048 )
	end
	self.directional = directional
	self.radiant = radiant
	self.glow = glow
	if (self.directional) then
		if not IsValid(self.DirectionalComponent) then
			self:DirectionalOn()
		end
	else
		if IsValid(self.DirectionalComponent) then
			self:DirectionalOff()
		end
	end
	if (self.radiant) then
		if not self.RadiantState then
			self:RadiantOn()
		end
	else
		if self.RadiantState then
			self:RadiantOff()
		end
	end
	if (self.glow) then
		WireLib.AdjustInputs(self, {"Red", "Green", "Blue", "RGB [VECTOR]", "GlowBrightness", "GlowDecay", "GlowSize"})
		if not self.GlowState then
			self:GlowOn()
		end
	else
		WireLib.AdjustInputs(self, {"Red", "Green", "Blue", "RGB [VECTOR]"})
		if self.GlowState then
			self:GlowOff()
		end
	end
	
	if brightness then self:SetBrightness( brightness ) end
	if size then self:SetSize( size ) end
	if decay then self:SetDecay( decay ) end
	self:SetRGB( r or 0, g or 0, b or 0 )
end

function ENT:SetRGB( R, G, B )
	if (((R + G) + B) != 0) then
		if (self.directional) then
			if (!self.DirectionalComponent) then
				self:DirectionalOn()
			end
			self.DirectionalComponent:SetKeyValue( "lightcolor", Format( "%i %i %i", R, G, B ) )
		end
		if (self.radiant) then
			if (!self.RadiantState) then
				self:RadiantOn()
			end
			self.RadiantComponent:SetColor(Color(R, G, B, 255))
		end
	else
		self:DirectionalOff()
		self:RadiantOff()
	end
	self:SetOverlayData( {r=R,g=G,b=B} )
	self.R, self.G, self.B = R, G, B
	self:SetColor(Color(R, G, B, self:GetColor().a))
end

duplicator.RegisterEntityClass("gmod_wire_light", WireLib.MakeWireEnt, "Data", "directional", "radiant", "glow", "brightness", "size", "decay", "R", "G", "B")
