CreateConVar( "cl_drawthrusterseffects", "1" )

local matHeatWave		= Material( "sprites/heatwave" )
local matFire			= Material( "effects/fire_cloud1" )
local matPlasma			= Material( "effects/strider_muzzle" )
local matColor			= Material( "effects/bloodstream" )

-- fixed by WeltEnSTurm: one emitter is enough!
local emitter = ParticleEmitter(Vector(0,0,0))

WireLib.ThrusterEffectThink = {}
WireLib.ThrusterEffectDraw = {}

WireLib.ThrusterEffectDraw.fire = function(self)

	local vOffset = self:LocalToWorld(self:GetOffset())
	local vNormal = self:CalcNormal()

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

WireLib.ThrusterEffectDraw.heatwave = function(self)

	local vOffset = self:LocalToWorld(self:GetOffset())
	local vNormal = self:CalcNormal()

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

WireLib.ThrusterEffectDraw.color = function(self)

	local vOffset = self:LocalToWorld(self:GetOffset())
	local vNormal = self:CalcNormal()

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

WireLib.ThrusterEffectDraw.color_random = function(self)

	local vOffset = self:LocalToWorld(self:GetOffset())
	local vNormal = self:CalcNormal()

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

WireLib.ThrusterEffectDraw.color_diy = function(self)

	local vOffset = self:LocalToWorld(self:GetOffset())
	local vNormal = self:CalcNormal()
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

WireLib.ThrusterEffectDraw.plasma = function(self)

	local vOffset = self:LocalToWorld(self:GetOffset())
	local vNormal = self:CalcNormal()

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

WireLib.ThrusterEffectDraw.fire_smoke = function(self)

	local vOffset = self:LocalToWorld(self:GetOffset())
	local vNormal = self:CalcNormal()
	
	self.EffectAvg = ( self.EffectAvg * 29 + math.min( self:GetNWFloat("Thrust") / 100000, 100 ) ) / 30
	local Magnitude = self.EffectAvg

	local scroll = CurTime() * -10

	render.SetMaterial( matFire )

	render.StartBeam( 3 )
		render.AddBeam( vOffset, Magnitude/6, scroll, Color( 0, 0, 255, 128) )
		render.AddBeam( vOffset + vNormal * Magnitude, Magnitude/2, scroll + 1, Color( 255, 255, 255, 128) )
		render.AddBeam( vOffset + vNormal * Magnitude * 2, Magnitude/2, scroll + 3, Color( 255, 255, 255, 0) )
	render.EndBeam()

	scroll = scroll * 0.5

	render.UpdateRefractTexture()
	render.SetMaterial( matHeatWave )
	render.StartBeam( 3 )
		render.AddBeam( vOffset, 8, scroll, Color( 0, 0, 255, 128) )
		render.AddBeam( vOffset + vNormal * Magnitude, 32, scroll + 2, Color( 255, 255, 255, 255) )
		render.AddBeam( vOffset + vNormal * Magnitude * 2, 48, scroll + 5, Color( 0, 0, 0, 0) )
	render.EndBeam()


	scroll = scroll * 1.3
	render.SetMaterial( matFire )
	render.StartBeam( 3 )
		render.AddBeam( vOffset, 8, scroll, Color( 0, 0, 255, 128) )
		render.AddBeam( vOffset + vNormal * Magnitude, 16, scroll + 1, Color( 255, 255, 255, 128) )
		render.AddBeam( vOffset + vNormal * Magnitude * 2, 16, scroll + 3, Color( 255, 255, 255, 0) )
	render.EndBeam()

		self.SmokeTimer = self.SmokeTimer or 0
	if ( self.SmokeTimer > CurTime() ) then return end

	self.SmokeTimer = CurTime() + 0.015

	local orth1 = Vector( vNormal.z, vNormal.x, vNormal.y )
	orth1 = ( orth1 - vNormal * vNormal:Dot(orth1) ):GetNormalized()
	local orth2 = vNormal:Cross( orth1 )

		local particle = emitter:Add( "particles/smokey", vOffset )
			particle:SetVelocity( vNormal * math.Rand( Magnitude*19, Magnitude*20 ) + orth1 * math.Rand( -50, 50 ) + orth2 * math.Rand( -50, 50 ) )
			particle:SetAirResistance( 60 )
			particle:SetDieTime( 2.0 )
			particle:SetStartAlpha( math.Rand( 0, 10 ) )
			particle:SetEndAlpha( 200 )
			particle:SetStartSize( math.Rand( 16, 24 ) )
			particle:SetEndSize( math.Rand( 10+Magnitude/2, 30+Magnitude/2 ) )
			particle:SetRoll( math.Rand( -0.2, 0.2 ) )
			particle:SetColor( 200, 200, 210 )
end

WireLib.ThrusterEffectDraw.fire_smoke_big = function(self)

	self.RingTimer = self.RingTimer or 0
	if ( self.RingTimer > CurTime() ) then return end
	self.RingTimer = CurTime() + 0.005

	local vOffset = self:LocalToWorld(self:GetOffset())
	local vNormal = self:CalcNormal()

	local effectdata = EffectData()
		effectdata:SetOrigin( vOffset )
		effectdata:SetNormal( vNormal )
		effectdata:SetRadius( 5 )
		effectdata:SetScale( 3 )
	util.Effect( "HelicopterMegaBomb", effectdata )

	vOffset = self:LocalToWorld(self:GetOffset()) + Vector( math.Rand( -3, 3 ), math.Rand( -3, 3 ), math.Rand( -3, 3 ) )
	vNormal = self:CalcNormal()

		local particle = emitter:Add( "particles/smokey", vOffset )
			particle:SetVelocity( vNormal * math.Rand( 10, 20 ) )
			particle:SetDieTime( 3.0 )
			particle:SetStartAlpha( math.Rand( 150, 255 ) )
			particle:SetStartSize( math.Rand( 64, 128 ) )
			particle:SetEndSize( math.Rand( 256, 128 ) )
			particle:SetRoll( math.Rand( -0.2, 0.2 ) )
			particle:SetColor( 200, 200, 210 )

	

	local effectdata = EffectData()
		effectdata:SetOrigin( vOffset )
		effectdata:SetNormal( vNormal )
	util.Effect( "ThumperDust ", effectdata )
end

WireLib.ThrusterEffectThink.smoke = function(self)

	self.SmokeTimer = self.SmokeTimer or 0
	if ( self.SmokeTimer > CurTime() ) then return end

	self.SmokeTimer = CurTime() + 0.015

	local vOffset = self:LocalToWorld(self:GetOffset()) + Vector( math.Rand( -3, 3 ), math.Rand( -3, 3 ), math.Rand( -3, 3 ) )
	local vNormal = self:CalcNormal()

		local particle = emitter:Add( "particles/smokey", vOffset )
			particle:SetVelocity( vNormal * math.Rand( 10, 30 ) )
			particle:SetDieTime( 2.0 )
			particle:SetStartAlpha( math.Rand( 50, 150 ) )
			particle:SetStartSize( math.Rand( 16, 32 ) )
			particle:SetEndSize( math.Rand( 64, 128 ) )
			particle:SetRoll( math.Rand( -0.2, 0.2 ) )
			particle:SetColor( 200, 200, 210 )
end

WireLib.ThrusterEffectThink.smoke_firecolors = function(self)

	self.SmokeTimer = self.SmokeTimer or 0
	if ( self.SmokeTimer > CurTime() ) then return end

	self.SmokeTimer = CurTime() + 0.015

	local vOffset = self:LocalToWorld(self:GetOffset()) + Vector( math.Rand( -3, 3 ), math.Rand( -3, 3 ), math.Rand( -3, 3 ) )
	local vNormal = self:CalcNormal()

		local particle = emitter:Add( "particles/smokey", vOffset )
			particle:SetVelocity( vNormal * math.Rand( 10, 30 ) )
			particle:SetDieTime( 2.0 )
			particle:SetStartAlpha( math.Rand( 50, 150 ) )
			particle:SetStartSize( math.Rand( 16, 32 ) )
			particle:SetEndSize( math.Rand( 64, 128 ) )
			particle:SetRoll( math.Rand( -0.2, 0.2 ) )
			particle:SetColor(math.random(220,255),math.random(110,220),0 )
end

WireLib.ThrusterEffectThink.smoke_random = function(self)

	self.SmokeTimer = self.SmokeTimer or 0
	if ( self.SmokeTimer > CurTime() ) then return end

	self.SmokeTimer = CurTime() + 0.015

	local vOffset = self:LocalToWorld(self:GetOffset()) + Vector( math.Rand( -3, 3 ), math.Rand( -3, 3 ), math.Rand( -3, 3 ) )
	local vNormal = self:CalcNormal()

		local particle = emitter:Add( "particles/smokey", vOffset )
			particle:SetVelocity( vNormal * math.Rand( 10, 30 ) )
			particle:SetDieTime( 2.0 )
			particle:SetStartAlpha( math.Rand( 50, 150 ) )
			particle:SetStartSize( math.Rand( 16, 32 ) )
			particle:SetEndSize( math.Rand( 64, 128 ) )
			particle:SetRoll( math.Rand( -0.2, 0.2 ) )
			particle:SetColor( math.random(100,255),math.random(100,255),math.random(100,255) )
end

WireLib.ThrusterEffectThink.smoke_diy = function(self)
	self.SmokeTimer = self.SmokeTimer or 0
	if ( self.SmokeTimer > CurTime() ) then return end

	self.SmokeTimer = CurTime() + 0.015

	local vOffset = self:LocalToWorld(self:GetOffset()) + Vector( math.Rand( -3, 3 ), math.Rand( -3, 3 ), math.Rand( -3, 3 ) )
	local vNormal = self:CalcNormal()

		local particle = emitter:Add( "particles/smokey", vOffset )
			particle:SetVelocity( vNormal * math.Rand( 10, 30 ) )
			particle:SetDieTime( 2.0 )
			particle:SetStartAlpha( math.Rand( 50, 150 ) )
			particle:SetStartSize( math.Rand( 16, 32 ) )
			particle:SetEndSize( math.Rand( 64, 128 ) )
			particle:SetRoll( math.Rand( -0.2, 0.2 ) )
			particle:SetColor(self:GetColor())
end

WireLib.ThrusterEffectDraw.color_magic = function(self)

	local vOffset = self:LocalToWorld(self:GetOffset())
	local vNormal = self:CalcNormal()

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

	vOffset = self:LocalToWorld(self:GetOffset())
	vNormal = self:CalcNormal()

	vOffset = vOffset + VectorRand() * 5

		local particle = emitter:Add( "sprites/gmdm_pickups/light", vOffset )
			particle:SetVelocity( vNormal * math.Rand( 50, 80 ) )
			particle:SetDieTime( 1 )
			particle:SetStartAlpha( 255 )
			particle:SetEndAlpha( 255 )
			particle:SetStartSize( math.Rand( 1, 3 ) )
			particle:SetEndSize( 0 )
			particle:SetRoll( math.Rand( -0.2, 0.2 ) )
end

WireLib.ThrusterEffectThink.money = function(self)

	self.SmokeTimer = self.SmokeTimer or 0
	if ( self.SmokeTimer > CurTime() ) then return end

	self.SmokeTimer = CurTime() + math.random(0.005,0.00005)

	local vOffset = self:LocalToWorld(self:GetOffset())
	local vNormal = self:CalcNormal()

	vOffset = vOffset + VectorRand() * 20

		local particle = emitter:Add( "thrusteraddon/money"..math.floor(math.random(1,3)).."", vOffset )
			particle:SetVelocity( vNormal * math.Rand( 0, 70 ) )
			particle:SetDieTime( math.Rand(3,5 ) )
			particle:SetStartAlpha( 255 )
			particle:SetEndAlpha( 0 )
			particle:SetStartSize( 5 )
			particle:SetEndSize( 5 )
			particle:SetRoll( math.Rand( -90, 90 ) )
end

WireLib.ThrusterEffectThink.debug_10 = function(self)

	self.SmokeTimer = self.SmokeTimer or 0
	if ( self.SmokeTimer > CurTime() ) then return end

	self.SmokeTimer = CurTime() + 0.05

	local vOffset = self:LocalToWorld(self:GetOffset())
	local vNormal = self:CalcNormal()

		local particle = emitter:Add( "decals/cross", vOffset )
			particle:SetVelocity( vNormal * 0 )
			particle:SetDieTime( 10 )
			particle:SetStartAlpha( 255 )
			particle:SetEndAlpha( 255 )
			particle:SetColor(0,255,0 )
			particle:SetStartSize( 5 )
			particle:SetEndSize( math.Rand(7,10) )
			particle:SetRoll(0)
end

WireLib.ThrusterEffectThink.debug_30 = function(self)

	self.SmokeTimer = self.SmokeTimer or 0
	if ( self.SmokeTimer > CurTime() ) then return end

	self.SmokeTimer = CurTime() + 0.05

	local vOffset = self:LocalToWorld(self:GetOffset())
	local vNormal = self:CalcNormal()

		local particle = emitter:Add( "decals/cross", vOffset )
			particle:SetVelocity( vNormal * 0 )
			particle:SetDieTime( 30 )
			particle:SetStartAlpha( 255 )
			particle:SetEndAlpha( 255 )
			particle:SetColor(0,255,0 )
			particle:SetStartSize( 5 )
			particle:SetEndSize( math.Rand(7,10) )
			particle:SetRoll(0)
end

WireLib.ThrusterEffectThink.debug_60 = function(self)

	self.SmokeTimer = self.SmokeTimer or 0
	if ( self.SmokeTimer > CurTime() ) then return end

	self.SmokeTimer = CurTime() + 0.05

	local vOffset = self:LocalToWorld(self:GetOffset())
	local vNormal = self:CalcNormal()

		local particle = emitter:Add( "decals/cross", vOffset )
			particle:SetVelocity( vNormal * 0 )
			particle:SetDieTime( 60 )
			particle:SetStartAlpha( 255 )
			particle:SetEndAlpha( 255 )
			particle:SetColor(0,255,0 )
			particle:SetStartSize( 5 )
			particle:SetEndSize( math.Rand(7,10) )
			particle:SetRoll(0)
end

WireLib.ThrusterEffectThink.souls = function(self)

	self.SmokeTimer = self.SmokeTimer or 0
	if ( self.SmokeTimer > CurTime() ) then return end

	self.SmokeTimer = CurTime() + 0.05

	local vOffset = self:LocalToWorld(self:GetOffset())
	local vNormal = self:CalcNormal()

	vOffset = vOffset + VectorRand() * 20

		local particle = emitter:Add( "sprites/soul", vOffset )
			particle:SetVelocity( vNormal * math.Rand( 0, 50 ) )
			particle:SetDieTime( math.Rand(3,5 ) )
			particle:SetStartAlpha( 255 )
			particle:SetEndAlpha( 0 )
			particle:SetColor(255,255,255 )
			particle:SetStartSize( 0 )
			particle:SetEndSize( math.Rand(7,10) )
			particle:SetRoll( math.Rand( -90, 90 ) )
end

WireLib.ThrusterEffectThink.sperm = function(self)

	self.SmokeTimer = self.SmokeTimer or 0
	if ( self.SmokeTimer > CurTime() ) then return end

	self.SmokeTimer = CurTime() + math.random(0.005,0.00005)

	local vOffset = self:LocalToWorld(self:GetOffset())
	local vNormal = self:CalcNormal()

	vOffset = vOffset + VectorRand() * 5

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
end

WireLib.ThrusterEffectThink.feather = function(self)

	self.SmokeTimer = self.SmokeTimer or 0
	if ( self.SmokeTimer > CurTime() ) then return end

	self.SmokeTimer = CurTime() + math.random(0.005,0.00005)

	local vOffset = self:LocalToWorld(self:GetOffset())
	local vNormal = self:CalcNormal()

	vOffset = vOffset + VectorRand() * 30

		local particle = emitter:Add( "thrusteraddon/feather"..math.floor(math.random(2,4)).."", vOffset )
			particle:SetVelocity( vNormal * math.Rand( 0, 50 ) )
			particle:SetDieTime( math.Rand(5,7 ) )
			particle:SetStartAlpha( 120 )
			particle:SetEndAlpha( 0 )
			particle:SetStartSize( 5 )
			particle:SetEndSize( 5 )
			particle:SetRoll( math.Rand( -90, 90 ) )
end

WireLib.ThrusterEffectThink.goldstar = function(self)

	self.SmokeTimer = self.SmokeTimer or 0
	if ( self.SmokeTimer > CurTime() ) then return end

	self.SmokeTimer = CurTime() + math.random(0.005,0.00005)

	local vOffset = self:LocalToWorld(self:GetOffset())
	local vNormal = self:CalcNormal()

	vOffset = vOffset + VectorRand() * 10

		local particle = emitter:Add( "thrusteraddon/Goldstar", vOffset )
			particle:SetVelocity( vNormal * math.Rand( 150, 200 ) )
			particle:SetDieTime( math.Rand(0,1 ) )
			particle:SetStartAlpha( 120 )
			particle:SetEndAlpha( 0 )
			particle:SetStartSize( 5 )
			particle:SetEndSize( 5 )
			particle:SetRoll( math.Rand( -90, 90 ) )
end

WireLib.ThrusterEffectThink.candy_cane = function(self)

	self.SmokeTimer = self.SmokeTimer or 0
	if ( self.SmokeTimer > CurTime() ) then return end

	self.SmokeTimer = CurTime() + math.random(0.005,0.00005)

	local vOffset = self:LocalToWorld(self:GetOffset())
	local vNormal = self:CalcNormal()

	vOffset = vOffset + VectorRand() * 5

		local particle = emitter:Add( "thrusteraddon/candy", vOffset )
			particle:SetVelocity( vNormal * math.Rand( 0, 20 ) )
			particle:SetDieTime( math.Rand(5,7 ) )
			particle:SetStartAlpha( 120 )
			particle:SetEndAlpha( 0 )
			particle:SetStartSize( 5 )
			particle:SetEndSize( 5 )
			particle:SetRoll( math.Rand( -90, 90 ) )
end

WireLib.ThrusterEffectThink.jetflame = function(self)

	self.SmokeTimer = self.SmokeTimer or 0
	if ( self.SmokeTimer > CurTime() ) then return end

	self.SmokeTimer = CurTime() + 0.0000005

	local vOffset = self:LocalToWorld(self:GetOffset())
	local vNormal = self:CalcNormal()

	//vOffset = vOffset + VectorRand() * 5

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

			vOffset = self:LocalToWorld(self:GetOffset())

		local particle2 = emitter:Add( "particle/fire", vOffset )
			particle2:SetVelocity( vNormal * speed )
			particle2:SetDieTime( 0.2 )
			particle2:SetStartAlpha( 200 )
			particle2:SetEndAlpha( 50 )
			particle2:SetStartSize( 8.8 )
			particle2:SetEndSize( 5 )
			particle2:SetColor( 200,200,200 )
			particle2:SetRoll( roll )
end

WireLib.ThrusterEffectThink.jetflame_purple = function(self)

	self.SmokeTimer = self.SmokeTimer or 0
	if ( self.SmokeTimer > CurTime() ) then return end

	self.SmokeTimer = CurTime() + 0.0000005

	local vOffset = self:LocalToWorld(self:GetOffset())
	local vNormal = self:CalcNormal()

	//vOffset = vOffset + VectorRand() * 5

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

			vOffset = self:LocalToWorld(self:GetOffset())

		local particle2 = emitter:Add( "particle/fire", vOffset )
			particle2:SetVelocity( vNormal * speed )
			particle2:SetDieTime( 0.2 )
			particle2:SetStartAlpha( 200 )
			particle2:SetEndAlpha( 50 )
			particle2:SetStartSize( 8.8 )
			particle2:SetEndSize( 5 )
			particle2:SetColor( 200,200,200 )
			particle2:SetRoll( roll )
end

WireLib.ThrusterEffectThink.jetflame_red = function(self)

	self.SmokeTimer = self.SmokeTimer or 0
	if ( self.SmokeTimer > CurTime() ) then return end

	self.SmokeTimer = CurTime() + 0.0000005

	local vOffset = self:LocalToWorld(self:GetOffset())
	local vNormal = self:CalcNormal()

	//vOffset = vOffset + VectorRand() * 5

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

			vOffset = self:LocalToWorld(self:GetOffset())

		local particle2 = emitter:Add( "particle/fire", vOffset )
			particle2:SetVelocity( vNormal * speed )
			particle2:SetDieTime( 0.2 )
			particle2:SetStartAlpha( 200 )
			particle2:SetEndAlpha( 50 )
			particle2:SetStartSize( 8.8 )
			particle2:SetEndSize( 5 )
			particle2:SetColor( 200,200,200 )
			particle2:SetRoll( roll )
end

WireLib.ThrusterEffectThink.jetflame_blue = function(self)

	self.SmokeTimer = self.SmokeTimer or 0
	if ( self.SmokeTimer > CurTime() ) then return end

	self.SmokeTimer = CurTime() + 0.0000005

	local vOffset = self:LocalToWorld(self:GetOffset())
	local vNormal = self:CalcNormal()

	//vOffset = vOffset + VectorRand() * 5

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

			vOffset = self:LocalToWorld(self:GetOffset())

		local particle2 = emitter:Add( "particle/fire", vOffset )
			particle2:SetVelocity( vNormal * speed )
			particle2:SetDieTime( 0.2 )
			particle2:SetStartAlpha( 200 )
			particle2:SetEndAlpha( 50 )
			particle2:SetStartSize( 8.8 )
			particle2:SetEndSize( 5 )
			particle2:SetColor( 200,200,200 )
			particle2:SetRoll( roll )
end

WireLib.ThrusterEffectThink.balls_firecolors = function(self)
	self.SmokeTimer = self.SmokeTimer or 0
	if ( self.SmokeTimer > CurTime() ) then return end

	self.SmokeTimer = CurTime() + 0.025

	local vOffset = self:LocalToWorld(self:GetOffset())
	local vNormal = self:CalcNormal()
	vOffset = vOffset + VectorRand() * 2

		local particle = emitter:Add( "sprites/sent_ball", vOffset )
			particle:SetVelocity( vNormal * 80 )
			particle:SetDieTime( 1 )
			particle:SetStartAlpha( 255 )
			particle:SetEndAlpha( 255 )
			particle:SetColor(math.random(220,255),math.random(100,200),0)
			particle:SetStartSize( 4 )
			particle:SetEndSize( 0 )
			particle:SetRoll( 0 )
end

WireLib.ThrusterEffectThink.balls_random = function(self)
	self.SmokeTimer = self.SmokeTimer or 0
	if ( self.SmokeTimer > CurTime() ) then return end

	self.SmokeTimer = CurTime() + 0.025

	local vOffset = self:LocalToWorld(self:GetOffset())
	local vNormal = self:CalcNormal()
	vOffset = vOffset + VectorRand() * 2

		local particle = emitter:Add( "sprites/sent_ball", vOffset )
			particle:SetVelocity( vNormal * 80 )
			particle:SetDieTime( 1 )
			particle:SetStartAlpha( 255 )
			particle:SetEndAlpha( 255 )
			particle:SetColor(math.random(0,255),math.random(0,255),math.random(0,255))
			particle:SetStartSize( 4 )
			particle:SetEndSize( 0 )
			particle:SetRoll( 0 )
end

WireLib.ThrusterEffectThink.balls = function(self)
	self.SmokeTimer = self.SmokeTimer or 0
	if ( self.SmokeTimer > CurTime() ) then return end

	self.SmokeTimer = CurTime() + 0.025

	local vOffset = self:LocalToWorld(self:GetOffset())
	local vNormal = self:CalcNormal()
	vOffset = vOffset + VectorRand() * 2

		local particle = emitter:Add( "sprites/sent_ball", vOffset )
			particle:SetVelocity( vNormal * 80 )
			particle:SetDieTime( 1 )
			particle:SetStartAlpha( 255 )
			particle:SetEndAlpha( 255 )
			particle:SetColor(self:GetColor())
			particle:SetStartSize( 4 )
			particle:SetEndSize( 0 )
			particle:SetRoll( 0 )
end

WireLib.ThrusterEffectThink.plasma_rings = function(self)

	self.SmokeTimer = self.SmokeTimer or 0
	if ( self.SmokeTimer > CurTime() ) then return end

	self.SmokeTimer = CurTime() + 0.00005

	local vOffset = self:LocalToWorld(self:GetOffset())
	local vNormal = self:CalcNormal()

	vOffset = vOffset + VectorRand() * 5

		local particle = emitter:Add( "sprites/magic", vOffset )
			particle:SetVelocity( vNormal * math.Rand( 50, 80 ) )
			particle:SetDieTime( 1 )
			particle:SetStartAlpha( 255 )
			particle:SetEndAlpha( 255 )
			particle:SetStartSize( math.Rand( 3,5 ) )
			particle:SetEndSize( 0 )
			particle:SetRoll( math.Rand( -0.2, 0.2 ) )
end

WireLib.ThrusterEffectThink.magic_firecolors = function(self)

	self.SmokeTimer = self.SmokeTimer or 0
	if ( self.SmokeTimer > CurTime() ) then return end

	self.SmokeTimer = CurTime() + 0.00005

	local vOffset = self:LocalToWorld(self:GetOffset())
	local vNormal = self:CalcNormal()

	vOffset = vOffset + VectorRand() * 5

		local particle = emitter:Add( "sprites/gmdm_pickups/light", vOffset )
			particle:SetVelocity( vNormal * math.Rand( 50, 80 ) )
			particle:SetDieTime( 1 )
			particle:SetStartAlpha( 255 )
			particle:SetEndAlpha( 255 )
			particle:SetColor(math.random(220,255),math.random(100,200),0)
			particle:SetStartSize( math.Rand( 1, 3 ) )
			particle:SetEndSize( 0 )
			particle:SetRoll( math.Rand( -0.2, 0.2 ) )
end

WireLib.ThrusterEffectThink.magic = function(self)

	self.SmokeTimer = self.SmokeTimer or 0
	if ( self.SmokeTimer > CurTime() ) then return end

	self.SmokeTimer = CurTime() + 0.00005

	local vOffset = self:LocalToWorld(self:GetOffset())
	local vNormal = self:CalcNormal()

	vOffset = vOffset + VectorRand() * 5

		local particle = emitter:Add( "sprites/gmdm_pickups/light", vOffset )
			particle:SetVelocity( vNormal * math.Rand( 50, 80 ) )
			particle:SetDieTime( 1 )
			particle:SetStartAlpha( 255 )
			particle:SetEndAlpha( 255 )
			particle:SetStartSize( math.Rand( 1, 3 ) )
			particle:SetEndSize( 0 )
			particle:SetRoll( math.Rand( -0.2, 0.2 ) )
end

WireLib.ThrusterEffectThink.magic_diy = function(self)
	self.SmokeTimer = self.SmokeTimer or 0
	if ( self.SmokeTimer > CurTime() ) then return end

	self.SmokeTimer = CurTime() + 0.00005

	local vOffset = self:LocalToWorld(self:GetOffset())
	local vNormal = self:CalcNormal()

	vOffset = vOffset + VectorRand() * 5

		local particle = emitter:Add( "sprites/gmdm_pickups/light", vOffset )
			particle:SetVelocity( vNormal * math.Rand( 50, 80 ) )
			particle:SetDieTime( 1 )
			particle:SetStartAlpha( 255 )
			particle:SetEndAlpha( 255 )
			particle:SetColor(self:GetColor())
			particle:SetStartSize( math.Rand( 1, 3 ) )
			particle:SetEndSize( 0 )
			particle:SetRoll( math.Rand( -0.2, 0.2 ) )
end

WireLib.ThrusterEffectThink.magic_color = function(self)

	self.SmokeTimer = self.SmokeTimer or 0
	if ( self.SmokeTimer > CurTime() ) then return end

	self.SmokeTimer = CurTime() + 0.00005

	local vOffset = self:LocalToWorld(self:GetOffset())
	local vNormal = self:CalcNormal()

	vOffset = vOffset + VectorRand() * 5

		local particle = emitter:Add( "sprites/gmdm_pickups/light", vOffset )
			particle:SetVelocity( vNormal * math.Rand( 50, 80) )
			particle:SetDieTime( 1 )
			particle:SetStartAlpha( 255 )
			particle:SetEndAlpha( 255 )
			particle:SetColor( math.random(0,255),math.random(0,255),math.random(0,255))
			particle:SetStartSize( math.Rand( 1, 3 ) )
			particle:SetEndSize( 0 )
			particle:SetRoll( math.Rand( -0.2, 0.2 ) )
end

WireLib.ThrusterEffectDraw.rings = function(self)

	self.RingTimer = self.RingTimer or 0
	if ( self.RingTimer > CurTime() ) then return end
	self.RingTimer = CurTime() + 0.00005

	local vOffset = self:LocalToWorld(self:GetOffset())
	local vNormal = self:CalcNormal()

	local effectdata = EffectData()
		effectdata:SetOrigin( vOffset )
		effectdata:SetNormal( vNormal )
	util.Effect( "thruster_ring", effectdata )

end

WireLib.ThrusterEffectDraw.tesla = function(self)

	self.RingTimer = self.RingTimer or 0
	if ( self.RingTimer > CurTime() ) then return end
	self.RingTimer = CurTime() + 0.00005

	local vOffset = self:LocalToWorld(self:GetOffset())
	local vNormal = self:CalcNormal()

	local effectdata = EffectData()
		effectdata:SetOrigin( vOffset )
		effectdata:SetNormal( vNormal )
		effectdata:SetRadius( 1 )
		effectdata:SetScale( 1 )
	util.Effect( "TeslaZap ", effectdata )

end

WireLib.ThrusterEffectDraw.blood = function(self)

	self.RingTimer = self.RingTimer or 0
	if ( self.RingTimer > CurTime() ) then return end
	self.RingTimer = CurTime() + 0.00005

	local vOffset = self:LocalToWorld(self:GetOffset())
	local vNormal = self:CalcNormal()

	local effectdata = EffectData()
		effectdata:SetOrigin( vOffset )
		effectdata:SetNormal( vNormal )
		effectdata:SetRadius( 1 )
		effectdata:SetScale( 1 )
	util.Effect( "BloodImpact", effectdata )

end

WireLib.ThrusterEffectDraw.some_sparks = function(self)

	self.RingTimer = self.RingTimer or 0
	if ( self.RingTimer > CurTime() ) then return end
	self.RingTimer = CurTime() + 0.00005

	local vOffset = self:LocalToWorld(self:GetOffset())
	local vNormal = self:CalcNormal()

	local effectdata = EffectData()
		effectdata:SetOrigin( vOffset )
		effectdata:SetNormal( vNormal )
		effectdata:SetRadius( 1 )
		effectdata:SetScale( 1 )
	util.Effect( "StunstickImpact", effectdata )

end

WireLib.ThrusterEffectDraw.spark_fountain = function(self)

	self.RingTimer = self.RingTimer or 0
	if ( self.RingTimer > CurTime() ) then return end
	self.RingTimer = CurTime() + 0.00005

	local vOffset = self:LocalToWorld(self:GetOffset())
	local vNormal = self:CalcNormal()

	local effectdata = EffectData()
		effectdata:SetOrigin( vOffset )
		effectdata:SetNormal( vNormal )
		effectdata:SetRadius( 1 )
		effectdata:SetScale( 1 )
	util.Effect( "ManhackSparks", effectdata )

end

WireLib.ThrusterEffectDraw.more_sparks = function(self)

	self.RingTimer = self.RingTimer or 0
	if ( self.RingTimer > CurTime() ) then return end
	self.RingTimer = CurTime() + 0.00005

	local vOffset = self:LocalToWorld(self:GetOffset())
	local vNormal = self:CalcNormal()

	local effectdata = EffectData()
		effectdata:SetOrigin( vOffset )
		effectdata:SetNormal( vNormal )
		effectdata:SetRadius( 1 )
		effectdata:SetScale( 1 )
	util.Effect( "cball_explode", effectdata )

end

WireLib.ThrusterEffectDraw.water_small = function(self)

	self.RingTimer = self.RingTimer or 0
	if ( self.RingTimer > CurTime() ) then return end
	self.RingTimer = CurTime() + 0.05

	local vOffset = self:LocalToWorld(self:GetOffset())
	local vNormal = self:CalcNormal()

	local effectdata = EffectData()
		effectdata:SetOrigin( vOffset )
		effectdata:SetNormal( vNormal )
		effectdata:SetRadius( 2 )
		effectdata:SetScale( 2 )
	util.Effect( "watersplash", effectdata )

end

WireLib.ThrusterEffectDraw.water_medium = function(self)

	self.RingTimer = self.RingTimer or 0
	if ( self.RingTimer > CurTime() ) then return end
	self.RingTimer = CurTime() + 0.05

	local vOffset = self:LocalToWorld(self:GetOffset())
	local vNormal = self:CalcNormal()

	local effectdata = EffectData()
		effectdata:SetOrigin( vOffset )
		effectdata:SetNormal( vNormal )
		effectdata:SetRadius( 6 )
		effectdata:SetScale( 6 )

	util.Effect( "watersplash", effectdata )

end

WireLib.ThrusterEffectDraw.water_big = function(self)

	self.RingTimer = self.RingTimer or 0
	if ( self.RingTimer > CurTime() ) then return end
	self.RingTimer = CurTime() + 0.05

	local vOffset = self:LocalToWorld(self:GetOffset())
	local vNormal = self:CalcNormal()

	local effectdata = EffectData()
		effectdata:SetOrigin( vOffset )
		effectdata:SetNormal( vNormal )
		effectdata:SetRadius( 10 )
		effectdata:SetScale( 10 )
	util.Effect( "watersplash", effectdata )

end

WireLib.ThrusterEffectDraw.water_huge = function(self)

	self.RingTimer = self.RingTimer or 0
	if ( self.RingTimer > CurTime() ) then return end
	self.RingTimer = CurTime() + 0.05

	local vOffset = self:LocalToWorld(self:GetOffset())
	local vNormal = self:CalcNormal()

	local effectdata = EffectData()
		effectdata:SetOrigin( vOffset )
		effectdata:SetNormal( vNormal )
		effectdata:SetRadius( 18 )
		effectdata:SetScale( 18 )
	util.Effect( "watersplash", effectdata )

end

WireLib.ThrusterEffectDraw.striderblood_small = function(self)

	self.RingTimer = self.RingTimer or 0
	if ( self.RingTimer > CurTime() ) then return end
	self.RingTimer = CurTime() + 0.05

	local vOffset = self:LocalToWorld(self:GetOffset())
	local vNormal = self:CalcNormal()

	local effectdata = EffectData()
		effectdata:SetOrigin( vOffset )
		effectdata:SetNormal( vNormal )
		effectdata:SetRadius( 0.1 )
		effectdata:SetScale( 0.1 )
	util.Effect( "StriderBlood", effectdata )

end

WireLib.ThrusterEffectDraw.striderblood_medium = function(self)

	self.RingTimer = self.RingTimer or 0
	if ( self.RingTimer > CurTime() ) then return end
	self.RingTimer = CurTime() + 0.05

	local vOffset = self:LocalToWorld(self:GetOffset())
	local vNormal = self:CalcNormal()

	local effectdata = EffectData()
		effectdata:SetOrigin( vOffset )
		effectdata:SetNormal( vNormal )
		effectdata:SetRadius( 0.7 )
		effectdata:SetScale( 0.7 )

	util.Effect( "StriderBlood", effectdata )

end

WireLib.ThrusterEffectDraw.striderblood_big = function(self)

	self.RingTimer = self.RingTimer or 0
	if ( self.RingTimer > CurTime() ) then return end
	self.RingTimer = CurTime() + 0.05

	local vOffset = self:LocalToWorld(self:GetOffset())
	local vNormal = self:CalcNormal()

	local effectdata = EffectData()
		effectdata:SetOrigin( vOffset )
		effectdata:SetNormal( vNormal )
		effectdata:SetRadius( 1.15 )
		effectdata:SetScale( 1.15 )
	util.Effect( "StriderBlood", effectdata )

end

WireLib.ThrusterEffectDraw.striderblood_huge = function(self)

	self.RingTimer = self.RingTimer or 0
	if ( self.RingTimer > CurTime() ) then return end
	self.RingTimer = CurTime() + 0.05

	local vOffset = self:LocalToWorld(self:GetOffset())
	local vNormal = self:CalcNormal()

	local effectdata = EffectData()
		effectdata:SetOrigin( vOffset )
		effectdata:SetNormal( vNormal )
		effectdata:SetRadius( 2 )
		effectdata:SetScale( 2 )
	util.Effect( "StriderBlood", effectdata )

end

WireLib.ThrusterEffectDraw.rings_grow = function(self)

	self.RingTimer = self.RingTimer or 0
	if ( self.RingTimer > CurTime() ) then return end
	self.RingTimer = CurTime() + 0.00005

	local vOffset = self:LocalToWorld(self:GetOffset())
	local vNormal = self:CalcNormal()

	local effectdata = EffectData()
		effectdata:SetOrigin( vOffset )
		effectdata:SetNormal( vNormal )
	util.Effect( "thruster_ring_grow", effectdata )

end

WireLib.ThrusterEffectDraw.rings_grow_rings = function(self)

	self.RingTimer = self.RingTimer or 0
	if ( self.RingTimer > CurTime() ) then return end
	self.RingTimer = CurTime() + 0.00005

	local vOffset = self:LocalToWorld(self:GetOffset())
	local vNormal = self:CalcNormal()

	local effectdata = EffectData()
		effectdata:SetOrigin( vOffset )
		effectdata:SetNormal( vNormal )
	util.Effect( "thruster_ring", effectdata )
	util.Effect( "thruster_ring_grow", effectdata )
	util.Effect( "thruster_ring_grow1", effectdata )
	util.Effect( "thruster_ring_grow2", effectdata )
	util.Effect( "thruster_ring_grow3", effectdata )

end

WireLib.ThrusterEffectDraw.rings_shrink = function(self)

	self.RingTimer = self.RingTimer or 0
	if ( self.RingTimer > CurTime() ) then return end
	self.RingTimer = CurTime() + 0.00005

	local vOffset = self:LocalToWorld(self:GetOffset())
	local vNormal = self:CalcNormal()

	local effectdata = EffectData()
		effectdata:SetOrigin( vOffset )
		effectdata:SetNormal( vNormal )
	util.Effect( "thruster_ring_shrink", effectdata )

end

WireLib.ThrusterEffectThink.bubble = function(self)
	self.SmokeTimer = self.SmokeTimer or 0
	if ( self.SmokeTimer > CurTime() ) then return end

	self.SmokeTimer = CurTime() + 0.005

	local vOffset = self:LocalToWorld(self:GetOffset())
	local vNormal = self:CalcNormal()
	vOffset = vOffset + VectorRand() * 5

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

	
end
