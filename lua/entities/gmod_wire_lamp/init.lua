AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "Lamp"

function ENT:Initialize()
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )

	local phys = self:GetPhysicsObject()

	if (phys:IsValid()) then
		phys:Wake()
	end

	self.Inputs = WireLib.CreateSpecialInputs(self, {"Red", "Green", "Blue", "RGB", "FOV", "Distance", "Brightness", "On", "Texture"}, {"NORMAL", "NORMAL", "NORMAL", "VECTOR", "NORMAL", "NORMAL", "NORMAL", "NORMAL", "STRING"})
	self:TurnOn()
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
	self:SetLightColor( r, g, b )
	
	self.Texture = Texture
	self.FOV = fov
	self.Dist = dist
	self.Brightness = brightness
end

include('shared.lua')

function MakeWireLamp( pl, r, g, b, Texture, fov, dist, brightness, model, Data )

	if ( !pl:CheckLimit( "wire_lamps" ) ) then return false end

	local wire_lamp = ents.Create( "gmod_wire_lamp" )
	if (!wire_lamp:IsValid()) then return end
		duplicator.DoGeneric( wire_lamp, Data )
		wire_lamp:Setup( r or 255, g or 255, b or 255, Texture or "effects/flashlight001", fov or 90, dist or 1024, brightness or 8 )
	wire_lamp:SetModel( model or "models/MaxOfS2D/lamp_projector.mdl" )
	wire_lamp:Spawn()
	wire_lamp:UpdateLight()
	
	duplicator.DoGenericPhysics( wire_lamp, pl, Data )

	wire_lamp:SetPlayer( pl )
	wire_lamp.pl = pl

	pl:AddCount( "wire_lamps", wire_lamp )
	pl:AddCleanup( "wire_lamp", wire_lamp )

	return wire_lamp
end

duplicator.RegisterEntityClass( "gmod_wire_lamp", MakeWireLamp, "r", "g", "b", "Texture", "FOV", "Dist", "Brightness", "model", "Data" )
