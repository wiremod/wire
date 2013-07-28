AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "Light"

function ENT:Initialize()
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )

	self.R, self.G, self.B = 0, 0, 0
	self:SetColor(Color(0, 0, 0, 255))

	self.Inputs = WireLib.CreateInputs(self, {"Red", "Green", "Blue", "RGB [VECTOR]"})
end

function ENT:OnRemove()
	if (!self.RadiantComponent) then return end
	if not self.RadiantComponent:IsValid() then return end
	self.RadiantComponent:SetParent() //Bugfix by aVoN
	self.RadiantComponent:Fire("TurnOff","",0)
	self.RadiantComponent:Fire("kill","",1)
end

function ENT:DirectionalOn()
	if (self.DirectionalComponent) then
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
	if (!self.DirectionalComponent) then return end

	self.DirectionalComponent:Remove()
	self.DirectionalComponent = nil
end

function ENT:RadiantOn()
	if (self.RadiantComponent) then
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
	if (!self.RadiantComponent) then return end
	if not self.RadiantComponent:IsValid() then return end
	self.RadiantComponent:Fire("TurnOff","","0")

	self.RadiantState = false
	--self.RadiantComponent:Remove()
	--self.RadiantComponent = nil
end


function ENT:GlowOn()
	self:SetGlow(true)

	self.GlowState = true
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
		self:SetBrightness(value)
	elseif (iname == "GlowDecay") then
		self:SetDecay(value)
	elseif (iname == "GlowSize") then
		self:SetSize(value)
	end
	self:ShowOutput( R, G, B )
end

function ENT:Setup(directional, radiant, glow)
	self.directional = directional
	self.radiant = radiant
	self.glow = glow
	if (self.directional) then
		if (!self.DirectionalComponent) then
			self:DirectionalOn()
		end
	else
		if (self.DirectionalComponent) then
			self:DirectionalOff()
		end
	end
	if (self.radiant) then
		if (!self.RadiantState) then
			self:RadiantOn()
		end
	else
		if (self.RadiantState) then
			self:RadiantOff()
		end
	end
	if (self.glow) then
		WireLib.AdjustInputs(self, {"Red", "Green", "Blue", "RGB [VECTOR]", "GlowBrightness", "GlowDecay", "GlowSize"})
		if (!self.GlowState) then
			self:GlowOn()
		end
	else
		WireLib.AdjustInputs(self, {"Red", "Green", "Blue", "RGB [VECTOR]"})
		if (self.GlowState) then
			self:GlowOff()
		end
	end
	self:ShowOutput( 0,0,0 )
end

function ENT:ShowOutput( R, G, B )
	if ( R ~= self.R or G ~= self.G or B ~= self.B ) then
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
		self:SetOverlayText( "Red:" .. R .. " Green:" .. G .. " Blue:" .. B )
		self.R, self.G, self.B = R, G, B
		self:SetColor(Color(R, G, B, self:GetColor().a))
	end
end

function MakeWireLight( pl, Pos, Ang, model, directional, radiant, glow, nocollide, frozen)
	if ( !pl:CheckLimit( "wire_lights" ) ) then return false end

	local wire_light = ents.Create( "gmod_wire_light" )
	if (!wire_light:IsValid()) then return false end

	wire_light:SetAngles( Ang )
	wire_light:SetPos( Pos )
	wire_light:SetModel( model )
	wire_light:Spawn()

	wire_light:Setup(directional, radiant, glow)
	wire_light:SetPlayer(pl)

	if wire_light:GetPhysicsObject():IsValid() then
		local Phys = wire_light:GetPhysicsObject()
		if nocollide == true then
			Phys:EnableCollisions(false)
		end
		Phys:EnableMotion(!frozen)
	end

	local ttable = {
		pl	= pl,
		nocollide = nocollide
	}
	table.Merge(wire_light:GetTable(), ttable )

	pl:AddCount( "wire_lights", wire_light )

	return wire_light
end
duplicator.RegisterEntityClass("gmod_wire_light", MakeWireLight, "Pos", "Ang", "Model", "directional", "radiant", "glow", "nocollide", "frozen")
