
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "Lamp"

--local MODEL = Model( "models/props_wasteland/prison_lamp001c.mdl" )
local MODEL = Model( "models/maxofs2d/lamp_flashlight.mdl" )

AccessorFunc( ENT, "Texture", "FlashlightTexture" )

ENT:SetFlashlightTexture( "effects/flashlight001" )

local Parameters = {}

/*---------------------------------------------------------
   Name: Initialize
---------------------------------------------------------*/
function ENT:Initialize()
	
	self:SetModel( MODEL )
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )

	local phys = self:GetPhysicsObject()

	if (phys:IsValid()) then
		phys:Wake()
	end

	self.lightr = 255
	self.lightg = 255
	self.lightb = 255

	self.Inputs = WireLib.CreateSpecialInputs(self, {"Red", "Green", "Blue", "RGB", "FOV", "Distance", "Brightness", "On", "Texture"}, {"NORMAL", "NORMAL", "NORMAL", "VECTOR", "NORMAL", "NORMAL", "NORMAL", "NORMAL", "STRING"})
	self:TurnOn()
	
end

/*---------------------------------------------------------
   Name: Sets the color of the light
---------------------------------------------------------*/
function ENT:SetLightColor( r, g, b )
	-- for dupe
	self.r = r
	self.g = g
	self.b = b

	self.lightr = r
	self.lightg = g
	self.lightb = b

	self:SetVar( "lightr", r )
	self:SetVar( "lightg", g )
	self:SetVar( "lightb", b )

	self:SetColor(Color(r, g, b, 255))

	self.m_strLightColor = Format( "%i %i %i", r, g, b )

	if ( self.flashlight ) then
		self.flashlight:SetKeyValue( "lightcolor", self.m_strLightColor )
	end

	self:SetOverlayText( "Red: " .. r .. " Green: " .. g .. " Blue: " .. b )
	
end

/*---------------------------------------------------------
   Name: Sets the texture
---------------------------------------------------------*/
function ENT:SetFlashlightTexture( tex )
	-- for dupe
	self.Texture = tex

	if ( self.flashlight ) then
		self.flashlight:Input( "SpotlightTexture", NULL, NULL, self:GetFlashlightTexture() )
	end

end

/*---------------------------------------------------------
   Name: OnTakeDamage
---------------------------------------------------------*/
function ENT:OnTakeDamage( dmginfo )
	self:TakePhysicsDamage( dmginfo )
end

/*---------------------------------------------------------
   Name: TriggerInput
   Desc: the inputs
---------------------------------------------------------*/
function ENT:TriggerInput(iname, value)
	if (iname == "Red") then
		self:SetLightColor( value, self.lightg, self.lightb )
	elseif (iname == "Green") then
		self:SetLightColor( self.lightr, value, self.lightb )
	elseif (iname == "Blue") then
		self:SetLightColor( self.lightr, self.lightg, value )
	elseif (iname == "RGB") then
		self:SetLightColor( value[1], value[2], value[3] )
	elseif (iname == "FOV") then
		Parameters.FOV = value
	elseif (iname == "Distance") then
		Parameters.Distance = value
	elseif (iname == "Brightness") then
		Parameters.Brightness = value
	elseif (iname == "On") then
		if value > 0 then
			if !self.flashlight then self:TurnOn() end
		elseif self.flashlight then
			self:TurnOff()
		end
	elseif (iname == "Texture") then
		self:SetFlashlightTexture( value )
	end
	self:UpdateLight( Parameters.FOV, Parameters.Distance, Parameters.Brightness )

end

function ENT:TurnOn()
	self:SetOn(true)
	local angForward = self:GetAngles() + Angle( 90, 0, 0 )
	
	self.flashlight = ents.Create( "env_projectedtexture" )
	
		self.flashlight:SetParent( self.Entity )
		
		-- The local positions are the offsets from parent..
		self.flashlight:SetLocalPos( Vector( 0, 0, 0 ) )
		self.flashlight:SetLocalAngles( Angle(0,0,0) )
		
		-- Looks like only one flashlight can have shadows enabled!
		self.flashlight:SetKeyValue( "enableshadows", 1 )
		self.flashlight:SetKeyValue( "farz", Parameters.Distance )
		self.flashlight:SetKeyValue( "nearz", 12 )
		self.flashlight:SetKeyValue( "lightfov", Parameters.FOV )
		
		local c = self:GetColor()
		local b = Parameters.Brightness
		self.flashlight:SetKeyValue( "lightcolor", Format( "%i %i %i 255", c.r * b, c.g * b, c.b * b ) )
		
	self.flashlight:Spawn()
	
	self.flashlight:Input( "SpotlightTexture", NULL, NULL, self:GetFlashlightTexture() )

end

function ENT:TurnOff()
	self:SetOn(false)
	SafeRemoveEntity( self.flashlight )
	self.flashlight = nil
end

function ENT:UpdateLight( fov, dist, bright )

	if ( !IsValid( self.flashlight ) ) then return end

	self.flashlight:Input( "SpotlightTexture", NULL, NULL, self:GetFlashlightTexture() )
	self.flashlight:Input( "FOV", NULL, NULL, tostring( fov ) )
	self.flashlight:SetKeyValue( "farz", dist )

	local c = self:GetColor()
	local b = bright
	self.flashlight:SetKeyValue( "lightcolor", Format( "%i %i %i 255", c.r*b, c.g*b, c.b*b ) )

end

function ENT:OnRemove()
	Wire_Remove(self)
end

function ENT:OnRestore()
	Wire_Restored(self)
end

function ENT:Setup( r, g, b, Texture, fov, dist, brightness )
	self:SetLightColor( r, g, b )
	self:SetFlashlightTexture( Texture  or "effects/flashlight001" )
	
	Parameters.FOV = fov
	Parameters.Distance = dist
	Parameters.Brightness = brightness
	
	self:UpdateLight( Parameters.FOV, Parameters.Distance, Parameters.Brightness )
	--for dupe
	self.fov = fov
	self.dist = dist
	self.brightness = brightness
end

include('shared.lua')

function MakeWireLamp( pl, r, g, b, Texture, fov, dist, brightness, Data )

	if ( !pl:CheckLimit( "wire_lamps" ) ) then return false end

	local wire_lamp = ents.Create( "gmod_wire_lamp" )
	if (!wire_lamp:IsValid()) then return end
		duplicator.DoGeneric( wire_lamp, Data )
		wire_lamp:Setup( r, g, b, Texture, fov, dist, brightness )
	wire_lamp:Spawn()
	
	duplicator.DoGenericPhysics( wire_lamp, pl, Data )

	wire_lamp:SetPlayer( pl )
	wire_lamp.pl = pl

	pl:AddCount( "wire_lamps", wire_lamp )
	pl:AddCleanup( "wire_lamp", wire_lamp )

	return wire_lamp
end

duplicator.RegisterEntityClass( "gmod_wire_lamp", MakeWireLamp, "lightr", "lightg", "lightb", "Texture", "fov", "dist", "brightness", "Data" )
