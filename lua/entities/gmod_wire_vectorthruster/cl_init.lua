
include('shared.lua')

CreateConVar( "cl_drawthrusterseffects", "1" )

local matHeatWave		= Material( "sprites/heatwave" )
local matFire			= Material( "effects/fire_cloud1" )
local matPlasma			= Material( "effects/strider_muzzle" )
local matColor			= Material( "effects/bloodstream" )


// Thrusters only really need to be twopass when they're active.. something to think about..
ENT.RenderGroup 		= RENDERGROUP_BOTH

function ENT:Initialize()
	self.ShouldDraw = 1
	self.NextSmokeEffect = 0

	mx, mn = self:GetRenderBounds()
	self:SetRenderBounds( mn + Vector(0,0,128), mx, 0 )
end


function ENT:Draw()
	self.BaseClass.Draw( self )

	self:DrawTranslucent()
end

function ENT:DrawTranslucent()
	if ( self.ShouldDraw == 0 ) then return end

	if ( !self:IsOn() ) then return end
	if ( self:GetEffect() == "none" ) then return end

	local EffectThink = self[ "EffectDraw_"..self:GetEffect() ]
	if ( EffectThink ) then EffectThink( self ) end
end


function ENT:Think()
	self.BaseClass.Think(self)

	self.ShouldDraw = GetConVarNumber( "cl_drawthrusterseffects" )

	local bDraw = true

	if ( self.ShouldDraw == 0 ) then bDraw = false end

	if ( !self:IsOn() ) then bDraw = false end
	if ( self:GetEffect() == "none" ) then bDraw = false end

	if ( !bDraw ) then return end

	local EffectThink = self[ "EffectThink_"..self:GetEffect() ]
	if ( EffectThink ) then EffectThink( self ) end
end


function ENT:EffectThink_fire()
end


function ENT:vOffset()
	local mode = self:GetMode()
	if (mode == 1) then
		return self:GetPos() + self:GetOffset()
	elseif (mode == 2) then
		local v =self:GetOffset()
		local z = v.z
		v.z = 0
		v = self:LocalToWorld( v )
		v.z = v.z + z
		return v
	else
		return self:LocalToWorld( self:GetOffset() )
	end

end



function ENT:EffectDraw_fire()

	local vOffset = self:vOffset()
	local vNormal = (vOffset - self:GetPos()):GetNormalized()

	local scroll = CurTime() * -10

	render.SetMaterial( matFire )

	render.StartBeam( 3 )
		render.AddBeam( vOffset, 8, scroll, Color( 0, 0, 255, 128) )
		render.AddBeam( vOffset + vNormal * 60, 32, scroll + 1, Color( 255, 255, 255, 128) )
		render.AddBeam( vOffset + vNormal * 148, 32, scroll + 3, Color( 255, 255, 255, 0) )
	render.EndBeam()

	scroll = scroll * 0.5

	render.UpdateRefractTexture()
	render.SetMaterial( matHeatWave )
	render.StartBeam( 3 )
		render.AddBeam( vOffset, 8, scroll, Color( 0, 0, 255, 128) )
		render.AddBeam( vOffset + vNormal * 32, 32, scroll + 2, Color( 255, 255, 255, 255) )
		render.AddBeam( vOffset + vNormal * 128, 48, scroll + 5, Color( 0, 0, 0, 0) )
	render.EndBeam()


	scroll = scroll * 1.3
	render.SetMaterial( matFire )
	render.StartBeam( 3 )
		render.AddBeam( vOffset, 8, scroll, Color( 0, 0, 255, 128) )
		render.AddBeam( vOffset + vNormal * 60, 16, scroll + 1, Color( 255, 255, 255, 128) )
		render.AddBeam( vOffset + vNormal * 148, 16, scroll + 3, Color( 255, 255, 255, 0) )
	render.EndBeam()

end

function ENT:EffectDraw_heatwave()

	local vOffset = self:vOffset()
	local vNormal = (vOffset - self:GetPos()):GetNormalized()

	local scroll = CurTime() * -10

	render.SetMaterial( matHeatWave )

	render.StartBeam( 3 )
		render.AddBeam( vOffset, 8, scroll, Color( 0, 0, 255, 128) )
		render.AddBeam( vOffset + vNormal * 60, 32, scroll + 1, Color( 255, 255, 255, 128) )
		render.AddBeam( vOffset + vNormal * 148, 32, scroll + 3, Color( 255, 255, 255, 0) )
	render.EndBeam()

	scroll = scroll * 0.5

	render.UpdateRefractTexture()
	render.SetMaterial( matHeatWave )
	render.StartBeam( 3 )
		render.AddBeam( vOffset, 8, scroll, Color( 0, 0, 255, 128) )
		render.AddBeam( vOffset + vNormal * 32, 32, scroll + 2, Color( 255, 255, 255, 255) )
		render.AddBeam( vOffset + vNormal * 128, 48, scroll + 5, Color( 0, 0, 0, 0) )
	render.EndBeam()


	scroll = scroll * 1.3
	render.SetMaterial( matHeatWave )
	render.StartBeam( 3 )
		render.AddBeam( vOffset, 8, scroll, Color( 0, 0, 255, 128) )
		render.AddBeam( vOffset + vNormal * 60, 16, scroll + 1, Color( 255, 255, 255, 128) )
		render.AddBeam( vOffset + vNormal * 148, 16, scroll + 3, Color( 255, 255, 255, 0) )
	render.EndBeam()

end


function ENT:EffectDraw_color()

	local vOffset = self:vOffset()
	local vNormal = (vOffset - self:GetPos()):GetNormalized()

	local scroll = CurTime() * -10

	render.SetMaterial( matColor )

	render.StartBeam( 3 )
		render.AddBeam( vOffset, 8, scroll, Color( 255, 0, 0, 128) )
		render.AddBeam( vOffset + vNormal * 60, 32, scroll + 1, Color( 255, 255, 255, 128) )
		render.AddBeam( vOffset + vNormal * 148, 32, scroll + 3, Color( 255, 255, 255, 0) )
	render.EndBeam()

	scroll = scroll * 0.5

	render.UpdateRefractTexture()
	render.SetMaterial( matColor )
	render.StartBeam( 3 )
		render.AddBeam( vOffset, 8, scroll, Color( 0, 255, 0, 128) )
		render.AddBeam( vOffset + vNormal * 32, 32, scroll + 2, Color( 255, 255, 255, 255) )
		render.AddBeam( vOffset + vNormal * 128, 48, scroll + 5, Color( 0, 0, 0, 0) )
	render.EndBeam()


	scroll = scroll * 1.3
	render.SetMaterial( matColor )
	render.StartBeam( 3 )
		render.AddBeam( vOffset, 8, scroll, Color( 0, 0, 255, 128) )
		render.AddBeam( vOffset + vNormal * 60, 16, scroll + 1, Color( 255, 255, 255, 128) )
		render.AddBeam( vOffset + vNormal * 148, 16, scroll + 3, Color( 255, 255, 255, 0) )
	render.EndBeam()

end

function ENT:EffectDraw_color_random()

	local vOffset = self:vOffset()
	local vNormal = (vOffset - self:GetPos()):GetNormalized()

	local scroll = CurTime() * -10

	render.SetMaterial( matColor )

	render.StartBeam( 3 )
		render.AddBeam( vOffset, 8, scroll, Color( 255, 0, 0, 128) )
		render.AddBeam( vOffset + vNormal * 60, 32, scroll + 1, Color( math.random(0,255), math.random(0,255), math.random(0,255), 128) )
		render.AddBeam( vOffset + vNormal * 148, 32, scroll + 3, Color( math.random(0,255), math.random(0,255), math.random(0,255), 0) )
	render.EndBeam()

	scroll = scroll * 0.5

	render.UpdateRefractTexture()
	render.SetMaterial( matColor )
	render.StartBeam( 3 )
		render.AddBeam( vOffset, 8, scroll, Color( 0, 255, 0, 128) )
		render.AddBeam( vOffset + vNormal * 32, 32, scroll + 2, Color( math.random(0,255), math.random(0,255), math.random(0,255), 255) )
		render.AddBeam( vOffset + vNormal * 128, 48, scroll + 5, Color( 0, 0, 0, 0) )
	render.EndBeam()


	scroll = scroll * 1.3
	render.SetMaterial( matColor )
	render.StartBeam( 3 )
		render.AddBeam( vOffset, 8, scroll, Color( 0, 0, 255, 128) )
		render.AddBeam( vOffset + vNormal * 60, 16, scroll + 1, Color( math.random(0,255), math.random(0,255), math.random(0,255), 128) )
		render.AddBeam( vOffset + vNormal * 148, 16, scroll + 3, Color( math.random(0,255), math.random(0,255), math.random(0,255), 0) )
	render.EndBeam()

end

function ENT:EffectDraw_color_diy()

	local vOffset = self:vOffset()
	local vNormal = (vOffset - self:GetPos()):GetNormalized()
	local c = self:GetColor()

	local scroll = CurTime() * -10

	render.SetMaterial( matColor )


	render.StartBeam( 3 )
		render.AddBeam( vOffset, 8, scroll, Color( 255, 0, 0, 128) )
		render.AddBeam( vOffset + vNormal * 60, 32, scroll + 1, Color( c.r, c.g, c.g, 128) )
		render.AddBeam( vOffset + vNormal * 148, 32, scroll + 3, Color( c.r, c.g, c.b, 0) )
	render.EndBeam()

	scroll = scroll * 0.5

	render.UpdateRefractTexture()
	render.SetMaterial( matColor )
	render.StartBeam( 3 )
		render.AddBeam( vOffset, 8, scroll, Color( 0, 255, 0, 128) )
		render.AddBeam( vOffset + vNormal * 32, 32, scroll + 2, Color( c.r, c.g, c.g, 255) )
		render.AddBeam( vOffset + vNormal * 128, 48, scroll + 5, Color( 0, 0, 0, 0) )
	render.EndBeam()


	scroll = scroll * 1.3
	render.SetMaterial( matColor )
	render.StartBeam( 3 )
		render.AddBeam( vOffset, 8, scroll, Color( 0, 0, 255, 128) )
		render.AddBeam( vOffset + vNormal * 60, 16, scroll + 1, Color( c.r, c.g, c.g, 128) )
		render.AddBeam( vOffset + vNormal * 148, 16, scroll + 3, Color( 255, 255, 255, 0) )
	render.EndBeam()

end

function ENT:EffectDraw_plasma()

	local vOffset = self:vOffset()
	local vNormal = (vOffset - self:GetPos()):GetNormalized()

	local scroll = CurTime() * -20

	render.SetMaterial( matPlasma )

	scroll = scroll * 0.9

	render.StartBeam( 3 )
		render.AddBeam( vOffset, 16, scroll, Color( 0, 255, 255, 255) )
		render.AddBeam( vOffset + vNormal * 8, 16, scroll + 0.01, Color( 255, 255, 255, 255) )
		render.AddBeam( vOffset + vNormal * 64, 16, scroll + 0.02, Color( 0, 255, 255, 0) )
	render.EndBeam()

	scroll = scroll * 0.9

	render.StartBeam( 3 )
		render.AddBeam( vOffset, 16, scroll, Color( 0, 255, 255, 255) )
		render.AddBeam( vOffset + vNormal * 8, 16, scroll + 0.01, Color( 255, 255, 255, 255) )
		render.AddBeam( vOffset + vNormal * 64, 16, scroll + 0.02, Color( 0, 255, 255, 0) )
	render.EndBeam()

	scroll = scroll * 0.9

	render.StartBeam( 3 )
		render.AddBeam( vOffset, 16, scroll, Color( 0, 255, 255, 255) )
		render.AddBeam( vOffset + vNormal * 8, 16, scroll + 0.01, Color( 255, 255, 255, 255) )
		render.AddBeam( vOffset + vNormal * 64, 16, scroll + 0.02, Color( 0, 255, 255, 0) )
	render.EndBeam()

end

function ENT:EffectDraw_fire_smoke()

	local vOffset = self:vOffset()
	local vNormal = (vOffset - self:GetPos()):GetNormalized()

	local scroll = CurTime() * -10

	render.SetMaterial( matFire )

	render.StartBeam( 3 )
		render.AddBeam( vOffset, 8, scroll, Color( 0, 0, 255, 128) )
		render.AddBeam( vOffset + vNormal * 60, 32, scroll + 1, Color( 255, 255, 255, 128) )
		render.AddBeam( vOffset + vNormal * 148, 32, scroll + 3, Color( 255, 255, 255, 0) )
	render.EndBeam()

	scroll = scroll * 0.5

	render.UpdateRefractTexture()
	render.SetMaterial( matHeatWave )
	render.StartBeam( 3 )
		render.AddBeam( vOffset, 8, scroll, Color( 0, 0, 255, 128) )
		render.AddBeam( vOffset + vNormal * 32, 32, scroll + 2, Color( 255, 255, 255, 255) )
		render.AddBeam( vOffset + vNormal * 128, 48, scroll + 5, Color( 0, 0, 0, 0) )
	render.EndBeam()


	scroll = scroll * 1.3
	render.SetMaterial( matFire )
	render.StartBeam( 3 )
		render.AddBeam( vOffset, 8, scroll, Color( 0, 0, 255, 128) )
		render.AddBeam( vOffset + vNormal * 60, 16, scroll + 1, Color( 255, 255, 255, 128) )
		render.AddBeam( vOffset + vNormal * 148, 16, scroll + 3, Color( 255, 255, 255, 0) )
	render.EndBeam()

		self.SmokeTimer = self.SmokeTimer or 0
	if ( self.SmokeTimer > CurTime() ) then return end

	self.SmokeTimer = CurTime() + 0.015

	vOffset = self:vOffset() + Vector( math.Rand( -3, 3 ), math.Rand( -3, 3 ), math.Rand( -3, 3 ) )
	vNormal = (vOffset - self:GetPos()):GetNormalized()

	local emitter = ParticleEmitter( vOffset )

		local particle = emitter:Add( "particles/smokey", vOffset )
			particle:SetVelocity( vNormal * math.Rand( 10, 30 ) )
			particle:SetDieTime( 2.0 )
			particle:SetStartAlpha( math.Rand( 50, 150 ) )
			particle:SetStartSize( math.Rand( 8, 16 ) )
			particle:SetEndSize( math.Rand( 32, 64  ) )
			particle:SetRoll( math.Rand( -0.2, 0.2 ) )
			particle:SetColor( 200, 200, 210 )

	emitter:Finish()

end

function ENT:EffectDraw_fire_smoke_big()

	self.RingTimer = self.RingTimer or 0
	if ( self.RingTimer > CurTime() ) then return end
	self.RingTimer = CurTime() + 0.00005

	local vOffset = self:vOffset()
	local vNormal = (vOffset - self:GetPos()):GetNormalized()

	local effectdata = EffectData()
		effectdata:SetOrigin( vOffset )
		effectdata:SetNormal( vNormal )
		effectdata:SetRadius( 10 )
		effectdata:SetScale( 6 )
	util.Effect( "HelicopterMegaBomb", effectdata )

	vOffset = self:vOffset() + Vector( math.Rand( -3, 3 ), math.Rand( -3, 3 ), math.Rand( -3, 3 ) )
	vNormal = (vOffset - self:GetPos()):GetNormalized()

	local emitter = ParticleEmitter( vOffset )

		local particle = emitter:Add( "particles/smokey", vOffset )
			particle:SetVelocity( vNormal * math.Rand( 10, 20 ) )
			particle:SetDieTime( 5.0 )
			particle:SetStartAlpha( math.Rand( 50, 150 ) )
			particle:SetStartSize( math.Rand( 64, 128 ) )
			particle:SetEndSize( math.Rand( 256, 128 ) )
			particle:SetRoll( math.Rand( -0.2, 0.2 ) )
			particle:SetColor( 200, 200, 210 )

	emitter:Finish()

	local effectdata = EffectData()
		effectdata:SetOrigin( vOffset )
		effectdata:SetNormal( vNormal )
	util.Effect( "ThumperDust ", effectdata )

end


function ENT:EffectThink_smoke()

	self.SmokeTimer = self.SmokeTimer or 0
	if ( self.SmokeTimer > CurTime() ) then return end

	self.SmokeTimer = CurTime() + 0.015

	local vOffset = self:vOffset() + Vector( math.Rand( -3, 3 ), math.Rand( -3, 3 ), math.Rand( -3, 3 ) )
	local vNormal = (vOffset - self:GetPos()):GetNormalized()

	local emitter = ParticleEmitter( vOffset )

		local particle = emitter:Add( "particles/smokey", vOffset )
			particle:SetVelocity( vNormal * math.Rand( 10, 30 ) )
			particle:SetDieTime( 2.0 )
			particle:SetStartAlpha( math.Rand( 50, 150 ) )
			particle:SetStartSize( math.Rand( 16, 32 ) )
			particle:SetEndSize( math.Rand( 64, 128 ) )
			particle:SetRoll( math.Rand( -0.2, 0.2 ) )
			particle:SetColor( 200, 200, 210 )

	emitter:Finish()

end

function ENT:EffectThink_smoke_firecolors()

	self.SmokeTimer = self.SmokeTimer or 0
	if ( self.SmokeTimer > CurTime() ) then return end

	self.SmokeTimer = CurTime() + 0.015

	local vOffset = self:vOffset() + Vector( math.Rand( -3, 3 ), math.Rand( -3, 3 ), math.Rand( -3, 3 ) )
	local vNormal = (vOffset - self:GetPos()):GetNormalized()

	local emitter = ParticleEmitter( vOffset )

		local particle = emitter:Add( "particles/smokey", vOffset )
			particle:SetVelocity( vNormal * math.Rand( 10, 30 ) )
			particle:SetDieTime( 2.0 )
			particle:SetStartAlpha( math.Rand( 50, 150 ) )
			particle:SetStartSize( math.Rand( 16, 32 ) )
			particle:SetEndSize( math.Rand( 64, 128 ) )
			particle:SetRoll( math.Rand( -0.2, 0.2 ) )
			particle:SetColor(math.random(220,255),math.random(110,220),0 )

	emitter:Finish()

end

function ENT:EffectThink_smoke_random()

	self.SmokeTimer = self.SmokeTimer or 0
	if ( self.SmokeTimer > CurTime() ) then return end

	self.SmokeTimer = CurTime() + 0.015

	local vOffset = self:vOffset() + Vector( math.Rand( -3, 3 ), math.Rand( -3, 3 ), math.Rand( -3, 3 ) )
	local vNormal = (vOffset - self:GetPos()):GetNormalized()

	local emitter = ParticleEmitter( vOffset )

		local particle = emitter:Add( "particles/smokey", vOffset )
			particle:SetVelocity( vNormal * math.Rand( 10, 30 ) )
			particle:SetDieTime( 2.0 )
			particle:SetStartAlpha( math.Rand( 50, 150 ) )
			particle:SetStartSize( math.Rand( 16, 32 ) )
			particle:SetEndSize( math.Rand( 64, 128 ) )
			particle:SetRoll( math.Rand( -0.2, 0.2 ) )
			particle:SetColor( math.random(100,255),math.random(100,255),math.random(100,255) )

	emitter:Finish()

end

function ENT:EffectThink_smoke_diy()
	self.SmokeTimer = self.SmokeTimer or 0
	if ( self.SmokeTimer > CurTime() ) then return end

	self.SmokeTimer = CurTime() + 0.015

	local vOffset = self:vOffset() + Vector( math.Rand( -3, 3 ), math.Rand( -3, 3 ), math.Rand( -3, 3 ) )
	local vNormal = (vOffset - self:GetPos()):GetNormalized()

	local emitter = ParticleEmitter( vOffset )

		local particle = emitter:Add( "particles/smokey", vOffset )
			particle:SetVelocity( vNormal * math.Rand( 10, 30 ) )
			particle:SetDieTime( 2.0 )
			particle:SetStartAlpha( math.Rand( 50, 150 ) )
			particle:SetStartSize( math.Rand( 16, 32 ) )
			particle:SetEndSize( math.Rand( 64, 128 ) )
			particle:SetRoll( math.Rand( -0.2, 0.2 ) )
			particle:SetColor(self:GetColor())

	emitter:Finish()

end

function ENT:EffectDraw_color_magic()

	local vOffset = self:vOffset()
	local vNormal = (vOffset - self:GetPos()):GetNormalized()

	local scroll = CurTime() * -10

	render.SetMaterial( matColor )

	render.StartBeam( 3 )
		render.AddBeam( vOffset, 8, scroll, Color( 255, 0, 0, 128) )
		render.AddBeam( vOffset + vNormal * 60, 32, scroll + 1, Color( 255, 255, 255, 128) )
		render.AddBeam( vOffset + vNormal * 148, 32, scroll + 3, Color( 255, 255, 255, 0) )
	render.EndBeam()

	scroll = scroll * 0.5

	render.UpdateRefractTexture()
	render.SetMaterial( matColor )
	render.StartBeam( 3 )
		render.AddBeam( vOffset, 8, scroll, Color( 0, 255, 0, 128) )
		render.AddBeam( vOffset + vNormal * 32, 32, scroll + 2, Color( 255, 255, 255, 255) )
		render.AddBeam( vOffset + vNormal * 128, 48, scroll + 5, Color( 0, 0, 0, 0) )
	render.EndBeam()


	scroll = scroll * 1.3
	render.SetMaterial( matColor )
	render.StartBeam( 3 )
		render.AddBeam( vOffset, 8, scroll, Color( 0, 0, 255, 128) )
		render.AddBeam( vOffset + vNormal * 60, 16, scroll + 1, Color( 255, 255, 255, 128) )
		render.AddBeam( vOffset + vNormal * 148, 16, scroll + 3, Color( 255, 255, 255, 0) )
	render.EndBeam()

		self.SmokeTimer = self.SmokeTimer or 0
	if ( self.SmokeTimer > CurTime() ) then return end

	self.SmokeTimer = CurTime() + 0.00005

	vOffset = self:LocalToWorld( self:GetOffset() )
	vNormal = (vOffset - self:GetPos()):GetNormalized()

	vOffset = vOffset + VectorRand() * 5

	local emitter = ParticleEmitter( vOffset )

		local particle = emitter:Add( "sprites/gmdm_pickups/light", vOffset )
			particle:SetVelocity( vNormal * math.Rand( 50, 80 ) )
			particle:SetDieTime( 1 )
			particle:SetStartAlpha( 255 )
			particle:SetEndAlpha( 255 )
			particle:SetStartSize( math.Rand( 1, 3 ) )
			particle:SetEndSize( 0 )
			particle:SetRoll( math.Rand( -0.2, 0.2 ) )

	emitter:Finish()

end

function ENT:EffectThink_money()

	self.SmokeTimer = self.SmokeTimer or 0
	if ( self.SmokeTimer > CurTime() ) then return end

	self.SmokeTimer = CurTime() + math.random(0.005,0.00005)

	local vOffset = self:vOffset()
	local vNormal = (vOffset - self:GetPos()):GetNormalized()

	vOffset = vOffset + VectorRand() * 20

	local emitter = ParticleEmitter( vOffset )

		local particle = emitter:Add( "thrusteraddon/money"..math.floor(math.random(1,3)).."", vOffset )
			particle:SetVelocity( vNormal * math.Rand( 0, 70 ) )
			particle:SetDieTime( math.Rand(3,5 ) )
			particle:SetStartAlpha( 255 )
			particle:SetEndAlpha( 0 )
			particle:SetStartSize( 5 )
			particle:SetEndSize( 5 )
			particle:SetRoll( math.Rand( -90, 90 ) )

	emitter:Finish()

end

function ENT:EffectThink_debug_10()

	self.SmokeTimer = self.SmokeTimer or 0
	if ( self.SmokeTimer > CurTime() ) then return end

	self.SmokeTimer = CurTime() + 0.05

	local vOffset = self:vOffset()
	local vNormal = (vOffset - self:GetPos()):GetNormalized()


	local emitter = ParticleEmitter( vOffset )

		local particle = emitter:Add( "decals/cross", vOffset )
			particle:SetVelocity( vNormal * 0 )
			particle:SetDieTime( 10 )
			particle:SetStartAlpha( 255 )
			particle:SetEndAlpha( 255 )
			particle:SetColor(0,255,0 )
			particle:SetStartSize( 5 )
			particle:SetEndSize( math.Rand(7,10) )
			particle:SetRoll(0)

	emitter:Finish()

end

function ENT:EffectThink_debug_30()

	self.SmokeTimer = self.SmokeTimer or 0
	if ( self.SmokeTimer > CurTime() ) then return end

	self.SmokeTimer = CurTime() + 0.05

	local vOffset = self:vOffset()
	local vNormal = (vOffset - self:GetPos()):GetNormalized()


	local emitter = ParticleEmitter( vOffset )

		local particle = emitter:Add( "decals/cross", vOffset )
			particle:SetVelocity( vNormal * 0 )
			particle:SetDieTime( 30 )
			particle:SetStartAlpha( 255 )
			particle:SetEndAlpha( 255 )
			particle:SetColor(0,255,0 )
			particle:SetStartSize( 5 )
			particle:SetEndSize( math.Rand(7,10) )
			particle:SetRoll(0)

	emitter:Finish()

end

function ENT:EffectThink_debug_60()

	self.SmokeTimer = self.SmokeTimer or 0
	if ( self.SmokeTimer > CurTime() ) then return end

	self.SmokeTimer = CurTime() + 0.05

	local vOffset = self:vOffset()
	local vNormal = (vOffset - self:GetPos()):GetNormalized()


	local emitter = ParticleEmitter( vOffset )

		local particle = emitter:Add( "decals/cross", vOffset )
			particle:SetVelocity( vNormal * 0 )
			particle:SetDieTime( 60 )
			particle:SetStartAlpha( 255 )
			particle:SetEndAlpha( 255 )
			particle:SetColor(0,255,0 )
			particle:SetStartSize( 5 )
			particle:SetEndSize( math.Rand(7,10) )
			particle:SetRoll(0)

	emitter:Finish()

end

function ENT:EffectThink_souls()

	self.SmokeTimer = self.SmokeTimer or 0
	if ( self.SmokeTimer > CurTime() ) then return end

	self.SmokeTimer = CurTime() + 0.05

	local vOffset = self:vOffset()
	local vNormal = (vOffset - self:GetPos()):GetNormalized()

	vOffset = vOffset + VectorRand() * 20

	local emitter = ParticleEmitter( vOffset )

		local particle = emitter:Add( "sprites/soul", vOffset )
			particle:SetVelocity( vNormal * math.Rand( 0, 50 ) )
			particle:SetDieTime( math.Rand(3,5 ) )
			particle:SetStartAlpha( 255 )
			particle:SetEndAlpha( 0 )
			particle:SetColor(255,255,255 )
			particle:SetStartSize( 0 )
			particle:SetEndSize( math.Rand(7,10) )
			particle:SetRoll( math.Rand( -90, 90 ) )

	emitter:Finish()

end

function ENT:EffectThink_sperm()

	self.SmokeTimer = self.SmokeTimer or 0
	if ( self.SmokeTimer > CurTime() ) then return end

	self.SmokeTimer = CurTime() + math.random(0.005,0.00005)

	local vOffset = self:vOffset()
	local vNormal = (vOffset - self:GetPos()):GetNormalized()

	vOffset = vOffset + VectorRand() * 5

	local emitter = ParticleEmitter( vOffset )

		local particle = emitter:Add( "thrusteraddon/sperm", vOffset )
			particle:SetVelocity( vNormal * math.Rand( 0, 70 ) )
			particle:SetDieTime( math.Rand(3,5 ) )
			particle:SetStartAlpha( 255 )
			particle:SetEndAlpha( 200 )
			particle:SetStartSize( 10 )
			particle:SetEndSize( 1 )
			particle:SetRoll( math.random(-180, 180) )

		local particle2 = emitter:Add( "thrusteraddon/goo", vOffset )
			particle2:SetVelocity( vNormal * 0.5  )
			particle2:SetDieTime( math.Rand(3,5 ) )
			particle2:SetStartAlpha( 100 )
			particle2:SetEndAlpha( 5 )
			particle2:SetColor(255,255,255 )
			particle2:SetStartSize( 5 )
			particle2:SetEndSize( 1 )
			particle2:SetRoll( math.random(-180, 180) )

		local particle3 = emitter:Add( "thrusteraddon/goo2", vOffset )
			particle3:SetVelocity( vNormal * 0.5 )
			particle3:SetDieTime( math.Rand(3,5 ) )
			particle3:SetStartAlpha(100 )
			particle3:SetEndAlpha( 5 )
			particle3:SetColor(255,255,255 )
			particle3:SetStartSize( 5 )
			particle3:SetEndSize( 1 )
			particle3:SetRoll( math.random(-180, 180) )

	emitter:Finish()

end


function ENT:EffectThink_feather()

	self.SmokeTimer = self.SmokeTimer or 0
	if ( self.SmokeTimer > CurTime() ) then return end

	self.SmokeTimer = CurTime() + math.random(0.005,0.00005)

	local vOffset = self:vOffset()
	local vNormal = (vOffset - self:GetPos()):GetNormalized()

	vOffset = vOffset + VectorRand() * 30

	local emitter = ParticleEmitter( vOffset )

		local particle = emitter:Add( "thrusteraddon/feather"..math.floor(math.random(2,4)).."", vOffset )
			particle:SetVelocity( vNormal * math.Rand( 0, 50 ) )
			particle:SetDieTime( math.Rand(5,7 ) )
			particle:SetStartAlpha( 120 )
			particle:SetEndAlpha( 0 )
			particle:SetStartSize( 5 )
			particle:SetEndSize( 5 )
			particle:SetRoll( math.Rand( -90, 90 ) )

	emitter:Finish()

end

function ENT:EffectThink_goldstar()

	self.SmokeTimer = self.SmokeTimer or 0
	if ( self.SmokeTimer > CurTime() ) then return end

	self.SmokeTimer = CurTime() + math.random(0.005,0.00005)

	local vOffset = self:vOffset()
	local vNormal = (vOffset - self:GetPos()):GetNormalized()

	vOffset = vOffset + VectorRand() * 10

	local emitter = ParticleEmitter( vOffset )

		local particle = emitter:Add( "thrusteraddon/Goldstar", vOffset )
			particle:SetVelocity( vNormal * math.Rand( 150, 200 ) )
			particle:SetDieTime( math.Rand(0,1 ) )
			particle:SetStartAlpha( 120 )
			particle:SetEndAlpha( 0 )
			particle:SetStartSize( 5 )
			particle:SetEndSize( 5 )
			particle:SetRoll( math.Rand( -90, 90 ) )

	emitter:Finish()

end

function ENT:EffectThink_candy_cane()

	self.SmokeTimer = self.SmokeTimer or 0
	if ( self.SmokeTimer > CurTime() ) then return end

	self.SmokeTimer = CurTime() + math.random(0.005,0.00005)

	local vOffset = self:vOffset()
	local vNormal = (vOffset - self:GetPos()):GetNormalized()

	vOffset = vOffset + VectorRand() * 5

	local emitter = ParticleEmitter( vOffset )

		local particle = emitter:Add( "thrusteraddon/candy", vOffset )
			particle:SetVelocity( vNormal * math.Rand( 0, 20 ) )
			particle:SetDieTime( math.Rand(5,7 ) )
			particle:SetStartAlpha( 120 )
			particle:SetEndAlpha( 0 )
			particle:SetStartSize( 5 )
			particle:SetEndSize( 5 )
			particle:SetRoll( math.Rand( -90, 90 ) )

	emitter:Finish()

end

function ENT:EffectThink_jetflame()

	self.SmokeTimer = self.SmokeTimer or 0
	if ( self.SmokeTimer > CurTime() ) then return end

	self.SmokeTimer = CurTime() + 0.0000005

	local vOffset = self:vOffset()
	local vNormal = (vOffset - self:GetPos()):GetNormalized()

	//vOffset = vOffset + VectorRand() * 5

	local emitter = ParticleEmitter( vOffset )
	local speed = math.Rand(90,252)
	local roll = math.Rand(-90,90)

		local particle = emitter:Add( "particle/fire", vOffset )
			particle:SetVelocity( vNormal * speed )
			particle:SetDieTime( 0.3 )
			particle:SetStartAlpha( 255 )
			particle:SetEndAlpha( 150 )
			particle:SetStartSize( 15.8 )
			particle:SetEndSize( 9 )
			particle:SetColor( math.Rand(220,255),math.Rand(180,220),55 )
			particle:SetRoll( roll )

		local particle3 = emitter:Add( "sprites/heatwave", vOffset )
			particle3:SetVelocity( vNormal * speed )
			particle3:SetDieTime( 0.7 )
			particle3:SetStartAlpha( 255 )
			particle3:SetEndAlpha( 255 )
			particle3:SetStartSize( 16 )
			particle3:SetEndSize( 18 )
			particle3:SetColor( 255,255,255 )
			particle3:SetRoll( roll )

			vOffset = self:LocalToWorld( self:GetOffset() )

		local particle2 = emitter:Add( "particle/fire", vOffset )
			particle2:SetVelocity( vNormal * speed )
			particle2:SetDieTime( 0.2 )
			particle2:SetStartAlpha( 200 )
			particle2:SetEndAlpha( 50 )
			particle2:SetStartSize( 8.8 )
			particle2:SetEndSize( 5 )
			particle2:SetColor( 200,200,200 )
			particle2:SetRoll( roll )




	emitter:Finish()

end

function ENT:EffectThink_jetflame_purple()

	self.SmokeTimer = self.SmokeTimer or 0
	if ( self.SmokeTimer > CurTime() ) then return end

	self.SmokeTimer = CurTime() + 0.0000005

	local vOffset = self:vOffset()
	local vNormal = (vOffset - self:GetPos()):GetNormalized()

	//vOffset = vOffset + VectorRand() * 5

	local emitter = ParticleEmitter( vOffset )
	local speed = math.Rand(90,252)
	local roll = math.Rand(-90,90)

		local particle = emitter:Add( "particle/fire", vOffset )
			particle:SetVelocity( vNormal * speed )
			particle:SetDieTime( 0.3 )
			particle:SetStartAlpha( 255 )
			particle:SetEndAlpha( 150 )
			particle:SetStartSize( 15.8 )
			particle:SetEndSize( 9 )
			particle:SetColor(  math.Rand(220,255),55, math.Rand(220,255) )
			particle:SetRoll( roll )

		local particle3 = emitter:Add( "sprites/heatwave", vOffset )
			particle3:SetVelocity( vNormal * speed )
			particle3:SetDieTime( 0.7 )
			particle3:SetStartAlpha( 255 )
			particle3:SetEndAlpha( 255 )
			particle3:SetStartSize( 16 )
			particle3:SetEndSize( 18 )
			particle3:SetColor( 255,255,255 )
			particle3:SetRoll( roll )

			vOffset = self:LocalToWorld( self:GetOffset() )

		local particle2 = emitter:Add( "particle/fire", vOffset )
			particle2:SetVelocity( vNormal * speed )
			particle2:SetDieTime( 0.2 )
			particle2:SetStartAlpha( 200 )
			particle2:SetEndAlpha( 50 )
			particle2:SetStartSize( 8.8 )
			particle2:SetEndSize( 5 )
			particle2:SetColor( 200,200,200 )
			particle2:SetRoll( roll )




	emitter:Finish()

end

function ENT:EffectThink_jetflame_red()

	self.SmokeTimer = self.SmokeTimer or 0
	if ( self.SmokeTimer > CurTime() ) then return end

	self.SmokeTimer = CurTime() + 0.0000005

	local vOffset = self:vOffset()
	local vNormal = (vOffset - self:GetPos()):GetNormalized()

	//vOffset = vOffset + VectorRand() * 5

	local emitter = ParticleEmitter( vOffset )
	local speed = math.Rand(90,252)
	local roll = math.Rand(-90,90)

		local particle = emitter:Add( "particle/fire", vOffset )
			particle:SetVelocity( vNormal * speed )
			particle:SetDieTime( 0.3 )
			particle:SetStartAlpha( 255 )
			particle:SetEndAlpha( 150 )
			particle:SetStartSize( 15.8 )
			particle:SetEndSize( 9 )
			particle:SetColor( math.Rand(220,255),55,55 )
			particle:SetRoll( roll )

		local particle3 = emitter:Add( "sprites/heatwave", vOffset )
			particle3:SetVelocity( vNormal * speed )
			particle3:SetDieTime( 0.7 )
			particle3:SetStartAlpha( 255 )
			particle3:SetEndAlpha( 255 )
			particle3:SetStartSize( 16 )
			particle3:SetEndSize( 18 )
			particle3:SetColor( 255,255,255 )
			particle3:SetRoll( roll )

			vOffset = self:LocalToWorld( self:GetOffset() )

		local particle2 = emitter:Add( "particle/fire", vOffset )
			particle2:SetVelocity( vNormal * speed )
			particle2:SetDieTime( 0.2 )
			particle2:SetStartAlpha( 200 )
			particle2:SetEndAlpha( 50 )
			particle2:SetStartSize( 8.8 )
			particle2:SetEndSize( 5 )
			particle2:SetColor( 200,200,200 )
			particle2:SetRoll( roll )


	emitter:Finish()

end


function ENT:EffectThink_jetflame_blue()

	self.SmokeTimer = self.SmokeTimer or 0
	if ( self.SmokeTimer > CurTime() ) then return end

	self.SmokeTimer = CurTime() + 0.0000005

	local vOffset = self:vOffset()
	local vNormal = (vOffset - self:GetPos()):GetNormalized()

	//vOffset = vOffset + VectorRand() * 5

	local emitter = ParticleEmitter( vOffset )
	local speed = math.Rand(90,252)
	local roll = math.Rand(-90,90)

		local particle = emitter:Add( "particle/fire", vOffset )
			particle:SetVelocity( vNormal * speed )
			particle:SetDieTime( 0.3 )
			particle:SetStartAlpha( 255 )
			particle:SetEndAlpha( 150 )
			particle:SetStartSize( 15.8 )
			particle:SetEndSize( 9 )
			particle:SetColor( 55,55, math.Rand(220,255) )
			particle:SetRoll( roll )

		local particle3 = emitter:Add( "sprites/heatwave", vOffset )
			particle3:SetVelocity( vNormal * speed )
			particle3:SetDieTime( 0.7 )
			particle3:SetStartAlpha( 255 )
			particle3:SetEndAlpha( 255 )
			particle3:SetStartSize( 16 )
			particle3:SetEndSize( 18 )
			particle3:SetColor( 255,255,255 )
			particle3:SetRoll( roll )

			vOffset = self:LocalToWorld( self:GetOffset() )

		local particle2 = emitter:Add( "particle/fire", vOffset )
			particle2:SetVelocity( vNormal * speed )
			particle2:SetDieTime( 0.2 )
			particle2:SetStartAlpha( 200 )
			particle2:SetEndAlpha( 50 )
			particle2:SetStartSize( 8.8 )
			particle2:SetEndSize( 5 )
			particle2:SetColor( 200,200,200 )
			particle2:SetRoll( roll )



	emitter:Finish()

end


function ENT:EffectThink_balls_firecolors()
	self.SmokeTimer = self.SmokeTimer or 0
	if ( self.SmokeTimer > CurTime() ) then return end

	self.SmokeTimer = CurTime() + 0.025

	local vOffset = self:vOffset()
	local vNormal = (vOffset - self:GetPos()):GetNormalized()
	vOffset = vOffset + VectorRand() * 2

	local emitter = ParticleEmitter( vOffset )

		local particle = emitter:Add( "sprites/sent_ball", vOffset )
			particle:SetVelocity( vNormal * 80 )
			particle:SetDieTime( 1 )
			particle:SetStartAlpha( 255 )
			particle:SetEndAlpha( 255 )
			particle:SetColor(math.random(220,255),math.random(100,200),0)
			particle:SetStartSize( 4 )
			particle:SetEndSize( 0 )
			particle:SetRoll( 0 )

	emitter:Finish()

end

function ENT:EffectThink_balls_random()
	self.SmokeTimer = self.SmokeTimer or 0
	if ( self.SmokeTimer > CurTime() ) then return end

	self.SmokeTimer = CurTime() + 0.025

	local vOffset = self:vOffset()
	local vNormal = (vOffset - self:GetPos()):GetNormalized()
	vOffset = vOffset + VectorRand() * 2

	local emitter = ParticleEmitter( vOffset )

		local particle = emitter:Add( "sprites/sent_ball", vOffset )
			particle:SetVelocity( vNormal * 80 )
			particle:SetDieTime( 1 )
			particle:SetStartAlpha( 255 )
			particle:SetEndAlpha( 255 )
			particle:SetColor(math.random(0,255),math.random(0,255),math.random(0,255))
			particle:SetStartSize( 4 )
			particle:SetEndSize( 0 )
			particle:SetRoll( 0 )

	emitter:Finish()

end

function ENT:EffectThink_balls()
	self.SmokeTimer = self.SmokeTimer or 0
	if ( self.SmokeTimer > CurTime() ) then return end

	self.SmokeTimer = CurTime() + 0.025

	local vOffset = self:vOffset()
	local vNormal = (vOffset - self:GetPos()):GetNormalized()
	vOffset = vOffset + VectorRand() * 2

	local emitter = ParticleEmitter( vOffset )

		local particle = emitter:Add( "sprites/sent_ball", vOffset )
			particle:SetVelocity( vNormal * 80 )
			particle:SetDieTime( 1 )
			particle:SetStartAlpha( 255 )
			particle:SetEndAlpha( 255 )
			particle:SetColor(self:GetColor())
			particle:SetStartSize( 4 )
			particle:SetEndSize( 0 )
			particle:SetRoll( 0 )

	emitter:Finish()

end

function ENT:EffectThink_plasma_rings()

	self.SmokeTimer = self.SmokeTimer or 0
	if ( self.SmokeTimer > CurTime() ) then return end

	self.SmokeTimer = CurTime() + 0.00005

	local vOffset = self:vOffset()
	local vNormal = (vOffset - self:GetPos()):GetNormalized()

	vOffset = vOffset + VectorRand() * 5

	local emitter = ParticleEmitter( vOffset )

		local particle = emitter:Add( "sprites/magic", vOffset )
			particle:SetVelocity( vNormal * math.Rand( 50, 80 ) )
			particle:SetDieTime( 1 )
			particle:SetStartAlpha( 255 )
			particle:SetEndAlpha( 255 )
			particle:SetStartSize( math.Rand( 3,5 ) )
			particle:SetEndSize( 0 )
			particle:SetRoll( math.Rand( -0.2, 0.2 ) )

	emitter:Finish()

end

function ENT:EffectThink_magic_firecolors()

	self.SmokeTimer = self.SmokeTimer or 0
	if ( self.SmokeTimer > CurTime() ) then return end

	self.SmokeTimer = CurTime() + 0.00005

	local vOffset = self:vOffset()
	local vNormal = (vOffset - self:GetPos()):GetNormalized()

	vOffset = vOffset + VectorRand() * 5

	local emitter = ParticleEmitter( vOffset )

		local particle = emitter:Add( "sprites/gmdm_pickups/light", vOffset )
			particle:SetVelocity( vNormal * math.Rand( 50, 80 ) )
			particle:SetDieTime( 1 )
			particle:SetStartAlpha( 255 )
			particle:SetEndAlpha( 255 )
			particle:SetColor(math.random(220,255),math.random(100,200),0)
			particle:SetStartSize( math.Rand( 1, 3 ) )
			particle:SetEndSize( 0 )
			particle:SetRoll( math.Rand( -0.2, 0.2 ) )

	emitter:Finish()

end

function ENT:EffectThink_magic()

	self.SmokeTimer = self.SmokeTimer or 0
	if ( self.SmokeTimer > CurTime() ) then return end

	self.SmokeTimer = CurTime() + 0.00005

	local vOffset = self:vOffset()
	local vNormal = (vOffset - self:GetPos()):GetNormalized()

	vOffset = vOffset + VectorRand() * 5

	local emitter = ParticleEmitter( vOffset )

		local particle = emitter:Add( "sprites/gmdm_pickups/light", vOffset )
			particle:SetVelocity( vNormal * math.Rand( 50, 80 ) )
			particle:SetDieTime( 1 )
			particle:SetStartAlpha( 255 )
			particle:SetEndAlpha( 255 )
			particle:SetStartSize( math.Rand( 1, 3 ) )
			particle:SetEndSize( 0 )
			particle:SetRoll( math.Rand( -0.2, 0.2 ) )

	emitter:Finish()

end

function ENT:EffectThink_magic_diy()
	self.SmokeTimer = self.SmokeTimer or 0
	if ( self.SmokeTimer > CurTime() ) then return end

	self.SmokeTimer = CurTime() + 0.00005

	local vOffset = self:vOffset()
	local vNormal = (vOffset - self:GetPos()):GetNormalized()

	vOffset = vOffset + VectorRand() * 5

	local emitter = ParticleEmitter( vOffset )

		local particle = emitter:Add( "sprites/gmdm_pickups/light", vOffset )
			particle:SetVelocity( vNormal * math.Rand( 50, 80 ) )
			particle:SetDieTime( 1 )
			particle:SetStartAlpha( 255 )
			particle:SetEndAlpha( 255 )
			particle:SetColor(self:GetColor())
			particle:SetStartSize( math.Rand( 1, 3 ) )
			particle:SetEndSize( 0 )
			particle:SetRoll( math.Rand( -0.2, 0.2 ) )

	emitter:Finish()

end

function ENT:EffectThink_magic_color()

	self.SmokeTimer = self.SmokeTimer or 0
	if ( self.SmokeTimer > CurTime() ) then return end

	self.SmokeTimer = CurTime() + 0.00005

	local vOffset = self:vOffset()
	local vNormal = (vOffset - self:GetPos()):GetNormalized()

	vOffset = vOffset + VectorRand() * 5

	local emitter = ParticleEmitter( vOffset )

		local particle = emitter:Add( "sprites/gmdm_pickups/light", vOffset )
			particle:SetVelocity( vNormal * math.Rand( 50, 80) )
			particle:SetDieTime( 1 )
			particle:SetStartAlpha( 255 )
			particle:SetEndAlpha( 255 )
			particle:SetColor( math.random(0,255),math.random(0,255),math.random(0,255))
			particle:SetStartSize( math.Rand( 1, 3 ) )
			particle:SetEndSize( 0 )
			particle:SetRoll( math.Rand( -0.2, 0.2 ) )

	emitter:Finish()

end


function ENT:EffectDraw_rings()

	self.RingTimer = self.RingTimer or 0
	if ( self.RingTimer > CurTime() ) then return end
	self.RingTimer = CurTime() + 0.00005

	local vOffset = self:vOffset()
	local vNormal = (vOffset - self:GetPos()):GetNormalized()

	local effectdata = EffectData()
		effectdata:SetOrigin( vOffset )
		effectdata:SetNormal( vNormal )
	util.Effect( "thruster_ring", effectdata )

end

function ENT:EffectDraw_tesla()

	self.RingTimer = self.RingTimer or 0
	if ( self.RingTimer > CurTime() ) then return end
	self.RingTimer = CurTime() + 0.00005

	local vOffset = self:vOffset()
	local vNormal = (vOffset - self:GetPos()):GetNormalized()

	local effectdata = EffectData()
		effectdata:SetOrigin( vOffset )
		effectdata:SetNormal( vNormal )
		effectdata:SetRadius( 1 )
		effectdata:SetScale( 1 )
	util.Effect( "TeslaZap ", effectdata )

end

function ENT:EffectDraw_blood()

	self.RingTimer = self.RingTimer or 0
	if ( self.RingTimer > CurTime() ) then return end
	self.RingTimer = CurTime() + 0.00005

	local vOffset = self:vOffset()
	local vNormal = (vOffset - self:GetPos()):GetNormalized()

	local effectdata = EffectData()
		effectdata:SetOrigin( vOffset )
		effectdata:SetNormal( vNormal )
		effectdata:SetRadius( 1 )
		effectdata:SetScale( 1 )
	util.Effect( "BloodImpact", effectdata )

end

function ENT:EffectDraw_some_sparks()

	self.RingTimer = self.RingTimer or 0
	if ( self.RingTimer > CurTime() ) then return end
	self.RingTimer = CurTime() + 0.00005

	local vOffset = self:vOffset()
	local vNormal = (vOffset - self:GetPos()):GetNormalized()

	local effectdata = EffectData()
		effectdata:SetOrigin( vOffset )
		effectdata:SetNormal( vNormal )
		effectdata:SetRadius( 1 )
		effectdata:SetScale( 1 )
	util.Effect( "StunstickImpact", effectdata )

end

function ENT:EffectDraw_spark_fountain()

	self.RingTimer = self.RingTimer or 0
	if ( self.RingTimer > CurTime() ) then return end
	self.RingTimer = CurTime() + 0.00005

	local vOffset = self:vOffset()
	local vNormal = (vOffset - self:GetPos()):GetNormalized()

	local effectdata = EffectData()
		effectdata:SetOrigin( vOffset )
		effectdata:SetNormal( vNormal )
		effectdata:SetRadius( 1 )
		effectdata:SetScale( 1 )
	util.Effect( "ManhackSparks", effectdata )

end

function ENT:EffectDraw_more_sparks()

	self.RingTimer = self.RingTimer or 0
	if ( self.RingTimer > CurTime() ) then return end
	self.RingTimer = CurTime() + 0.00005

	local vOffset = self:vOffset()
	local vNormal = (vOffset - self:GetPos()):GetNormalized()

	local effectdata = EffectData()
		effectdata:SetOrigin( vOffset )
		effectdata:SetNormal( vNormal )
		effectdata:SetRadius( 1 )
		effectdata:SetScale( 1 )
	util.Effect( "cball_explode", effectdata )

end

function ENT:EffectDraw_water_small()

	self.RingTimer = self.RingTimer or 0
	if ( self.RingTimer > CurTime() ) then return end
	self.RingTimer = CurTime() + 0.00005

	local vOffset = self:vOffset()
	local vNormal = (vOffset - self:GetPos()):GetNormalized()

	local effectdata = EffectData()
		effectdata:SetOrigin( vOffset )
		effectdata:SetNormal( vNormal )
		effectdata:SetRadius( 1 )
		effectdata:SetScale( 1 )
	util.Effect( "watersplash", effectdata )

end

function ENT:EffectDraw_water_medium()

	self.RingTimer = self.RingTimer or 0
	if ( self.RingTimer > CurTime() ) then return end
	self.RingTimer = CurTime() + 0.00005

	local vOffset = self:vOffset()
	local vNormal = (vOffset - self:GetPos()):GetNormalized()

	local effectdata = EffectData()
		effectdata:SetOrigin( vOffset )
		effectdata:SetNormal( vNormal )
		effectdata:SetRadius( 5 )
		effectdata:SetScale( 3 )

	util.Effect( "watersplash", effectdata )

end

function ENT:EffectDraw_water_big()

	self.RingTimer = self.RingTimer or 0
	if ( self.RingTimer > CurTime() ) then return end
	self.RingTimer = CurTime() + 0.00005

	local vOffset = self:vOffset()
	local vNormal = (vOffset - self:GetPos()):GetNormalized()

	local effectdata = EffectData()
		effectdata:SetOrigin( vOffset )
		effectdata:SetNormal( vNormal )
		effectdata:SetRadius( 10 )
		effectdata:SetScale( 6 )
	util.Effect( "watersplash", effectdata )

end

function ENT:EffectDraw_water_huge()

	self.RingTimer = self.RingTimer or 0
	if ( self.RingTimer > CurTime() ) then return end
	self.RingTimer = CurTime() + 0.00005

	local vOffset = self:vOffset()
	local vNormal = (vOffset - self:GetPos()):GetNormalized()

	local effectdata = EffectData()
		effectdata:SetOrigin( vOffset )
		effectdata:SetNormal( vNormal )
		effectdata:SetRadius( 50 )
		effectdata:SetScale( 50 )
	util.Effect( "watersplash", effectdata )

end


function ENT:EffectDraw_striderblood_small()

	self.RingTimer = self.RingTimer or 0
	if ( self.RingTimer > CurTime() ) then return end
	self.RingTimer = CurTime() + 0.00005

	local vOffset = self:vOffset()
	local vNormal = (vOffset - self:GetPos()):GetNormalized()

	local effectdata = EffectData()
		effectdata:SetOrigin( vOffset )
		effectdata:SetNormal( vNormal )
		effectdata:SetRadius( 1 )
		effectdata:SetScale( 1 )
	util.Effect( "StriderBlood", effectdata )

end

function ENT:EffectDraw_striderblood_medium()

	self.RingTimer = self.RingTimer or 0
	if ( self.RingTimer > CurTime() ) then return end
	self.RingTimer = CurTime() + 0.00005

	local vOffset = self:vOffset()
	local vNormal = (vOffset - self:GetPos()):GetNormalized()

	local effectdata = EffectData()
		effectdata:SetOrigin( vOffset )
		effectdata:SetNormal( vNormal )
		effectdata:SetRadius( 2 )
		effectdata:SetScale( 2 )

	util.Effect( "StriderBlood", effectdata )

end

function ENT:EffectDraw_striderblood_big()

	self.RingTimer = self.RingTimer or 0
	if ( self.RingTimer > CurTime() ) then return end
	self.RingTimer = CurTime() + 0.00005

	local vOffset = self:vOffset()
	local vNormal = (vOffset - self:GetPos()):GetNormalized()

	local effectdata = EffectData()
		effectdata:SetOrigin( vOffset )
		effectdata:SetNormal( vNormal )
		effectdata:SetRadius( 3 )
		effectdata:SetScale( 3 )
	util.Effect( "StriderBlood", effectdata )

end

function ENT:EffectDraw_striderblood_huge()

	self.RingTimer = self.RingTimer or 0
	if ( self.RingTimer > CurTime() ) then return end
	self.RingTimer = CurTime() + 0.00005

	local vOffset = self:vOffset()
	local vNormal = (vOffset - self:GetPos()):GetNormalized()

	local effectdata = EffectData()
		effectdata:SetOrigin( vOffset )
		effectdata:SetNormal( vNormal )
		effectdata:SetRadius( 4)
		effectdata:SetScale( 4 )
	util.Effect( "StriderBlood", effectdata )

end

function ENT:EffectDraw_rings_grow()

	self.RingTimer = self.RingTimer or 0
	if ( self.RingTimer > CurTime() ) then return end
	self.RingTimer = CurTime() + 0.00005

	local vOffset = self:vOffset()
	local vNormal = (vOffset - self:GetPos()):GetNormalized()

	local effectdata = EffectData()
		effectdata:SetOrigin( vOffset )
		effectdata:SetNormal( vNormal )
	util.Effect( "thruster_ring_grow", effectdata )

end

function ENT:EffectDraw_rings_grow_rings()

	self.RingTimer = self.RingTimer or 0
	if ( self.RingTimer > CurTime() ) then return end
	self.RingTimer = CurTime() + 0.00005

	local vOffset = self:vOffset()
	local vNormal = (vOffset - self:GetPos()):GetNormalized()

	local effectdata = EffectData()
		effectdata:SetOrigin( vOffset )
		effectdata:SetNormal( vNormal )
	util.Effect( "thruster_ring", effectdata )
	util.Effect( "thruster_ring_grow", effectdata )
	util.Effect( "thruster_ring_grow1", effectdata )
	util.Effect( "thruster_ring_grow2", effectdata )
	util.Effect( "thruster_ring_grow3", effectdata )

end


function ENT:EffectDraw_rings_shrink()

	self.RingTimer = self.RingTimer or 0
	if ( self.RingTimer > CurTime() ) then return end
	self.RingTimer = CurTime() + 0.00005

	local vOffset = self:vOffset()
	local vNormal = (vOffset - self:GetPos()):GetNormalized()

	local effectdata = EffectData()
		effectdata:SetOrigin( vOffset )
		effectdata:SetNormal( vNormal )
	util.Effect( "thruster_ring_shrink", effectdata )

end


function ENT:EffectThink_bubble()
	self.SmokeTimer = self.SmokeTimer or 0
	if ( self.SmokeTimer > CurTime() ) then return end

	self.SmokeTimer = CurTime() + 0.005

	local vOffset = self:vOffset()
	local vNormal = (vOffset - self:GetPos()):GetNormalized()
	vOffset = vOffset + VectorRand() * 5


	local emitter = ParticleEmitter( vOffset )

	local particle = emitter:Add( "effects/bubble", vOffset )
	vNormal.x = vNormal.x * 0.7
	vNormal.y = vNormal.y * 0.7
	vNormal.z = (vNormal.z+1) * 20
	particle:SetVelocity( vNormal)
	particle:SetDieTime( 2 )
	particle:SetStartAlpha( 125 )
	particle:SetEndAlpha( 125 )
	particle:SetColor(255,255,255)
	particle:SetStartSize( 7 )
	particle:SetEndSize( 0 )
	particle:SetRoll( 0 )

	emitter:Finish()
end
