
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "Lamp"

local MODEL = Model( "models/props_wasteland/prison_lamp001c.mdl" )

AccessorFunc( ENT, "Texture", "FlashlightTexture" )

ENT:SetFlashlightTexture( "effects/flashlight001" )

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

	self.Inputs = WireLib.CreateSpecialInputs(self.Entity, {"Red", "Green", "Blue", "RGB", "On", "Texture"}, {"NORMAL", "NORMAL", "NORMAL", "VECTOR", "NORMAL", "STRING"})
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

	self:SetColor( r, g, b, 255 )

	self.Entity:SetColor( r, g, b, 255 )

	self.m_strLightColor = Format( "%i %i %i", r, g, b )

	if ( self.flashlight ) then
		self.flashlight:SetKeyValue( "lightcolor", self.m_strLightColor )
	end

	self:SetOverlayText( "Red:" .. r .. " Green:" .. g .. " Blue" .. b )
end

function ENT:Setup( r, g, b )
	self:SetLightColor( r, g, b )
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
	self.Entity:TakePhysicsDamage( dmginfo )
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
	elseif (iname == "On") then
		if value > 0 then
			if !self.flashlight then self:TurnOn() end
		elseif self.flashlight then
			self:TurnOff()
		end
	elseif (iname == "Texture") then
		self:SetFlashlightTexture(value)
	end


end

function ENT:TurnOn()
	self:SetOn(true)
	local angForward = self.Entity:GetAngles() + Angle( 90, 0, 0 )

	self.flashlight = ents.Create( "env_projectedtexture" )

		self.flashlight:SetParent( self.Entity )

		// The local positions are the offsets from parent..
		self.flashlight:SetLocalPos( Vector( 0, 0, 0 ) )
		self.flashlight:SetLocalAngles( Angle(90,90,90) )

		// Looks like only one flashlight can have shadows enabled!
		self.flashlight:SetKeyValue( "enableshadows", 1 )
		self.flashlight:SetKeyValue( "farz", 2048 )
		self.flashlight:SetKeyValue( "nearz", 8 )

		//Todo: Make this tweakable?
		self.flashlight:SetKeyValue( "lightfov", 50 )

		// Color.. Bright pink if none defined to alert us to error
		self.flashlight:SetKeyValue( "lightcolor", self.m_strLightColor or "255 0 255" )


	self.flashlight:Spawn()

	self.flashlight:Input( "SpotlightTexture", NULL, NULL, self:GetFlashlightTexture() )
end

function ENT:TurnOff()
	self:SetOn(false)
	SafeRemoveEntity( self.flashlight )
	self.flashlight = nil
end

function ENT:OnRemove()
	Wire_Remove(self.Entity)
end

function ENT:OnRestore()
	Wire_Restored(self.Entity)
end

function ENT:Setup( r, g, b, Texture )
	self:SetLightColor( r, g, b )
	self:SetFlashlightTexture( Texture  or "effects/flashlight001" )
end

include('shared.lua')

function MakeWireLamp( pl, r, g, b, Texture, Data )

	if ( !pl:CheckLimit( "wire_lamps" ) ) then return false end

	local wire_lamp = ents.Create( "gmod_wire_lamp" )
	if (!wire_lamp:IsValid()) then return end
		duplicator.DoGeneric( wire_lamp, Data )
		wire_lamp:Setup( r, g, b, Texture )
	wire_lamp:Spawn()

	duplicator.DoGenericPhysics( wire_lamp, pl, Data )

	wire_lamp:SetPlayer( pl )
	wire_lamp.pl = pl

	pl:AddCount( "wire_lamps", wire_lamp )
	pl:AddCleanup( "wire_lamp", wire_lamp )

	return wire_lamp
end

duplicator.RegisterEntityClass( "gmod_wire_lamp", MakeWireLamp, "lightr", "lightg", "lightb", "Texture", "Data" )
