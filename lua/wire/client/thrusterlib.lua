CreateConVar( "cl_drawthrusterseffects", "1" )

local matHeatWave		= Material( "sprites/heatwave" )
local matFire			= Material( "effects/fire_cloud1" )
local matPlasma			= Material( "effects/strider_muzzle" )
local matColor			= Material( "effects/bloodstream" )

-- fixed by WeltEnSTurm: one emitter is enough!
local emitter = ParticleEmitter(Vector(0,0,0))

WireLib.ThrusterEffectThink = {}
WireLib.ThrusterEffectDraw = {}

local function fire(fireMaterial, heatwaveMaterial)
	return function(self)

		local vOffset = self:LocalToWorld(self:GetOffset())
		local vNormal = self:CalcNormal()

		local scroll = CurTime() * -10

		render.SetMaterial(fireMaterial)

		render.StartBeam( 3 )
			render.AddBeam( vOffset, 8, scroll, Color( 0, 0, 255, 128) )
			render.AddBeam( vOffset + vNormal * 60, 32, scroll + 1, Color( 255, 255, 255, 128) )
			render.AddBeam( vOffset + vNormal * 148, 32, scroll + 3, Color( 255, 255, 255, 0) )
		render.EndBeam()

		scroll = scroll * 0.5

		render.UpdateRefractTexture()
		render.SetMaterial(heatwaveMaterial)
		render.StartBeam( 3 )
			render.AddBeam( vOffset, 8, scroll, Color( 0, 0, 255, 128) )
			render.AddBeam( vOffset + vNormal * 32, 32, scroll + 2, Color( 255, 255, 255, 255) )
			render.AddBeam( vOffset + vNormal * 128, 48, scroll + 5, Color( 0, 0, 0, 0) )
		render.EndBeam()


		scroll = scroll * 1.3
		render.SetMaterial(fireMaterial)
		render.StartBeam( 3 )
			render.AddBeam( vOffset, 8, scroll, Color( 0, 0, 255, 128) )
			render.AddBeam( vOffset + vNormal * 60, 16, scroll + 1, Color( 255, 255, 255, 128) )
			render.AddBeam( vOffset + vNormal * 148, 16, scroll + 3, Color( 255, 255, 255, 0) )
		render.EndBeam()

	end
end

WireLib.ThrusterEffectDraw.fire = fire(matFire, matHeatWave)
WireLib.ThrusterEffectDraw.heatwave = fire(matHeatWave, matHeatWave)

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



	effectdata = EffectData()
		effectdata:SetOrigin( vOffset )
		effectdata:SetNormal( vNormal )
	util.Effect( "ThumperDust ", effectdata )
end

local function smoke(color)
	return function(self)

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
		particle:SetColor(color(self))
	end
end

WireLib.ThrusterEffectThink.smoke = smoke(function() return 200, 200, 210 end)
WireLib.ThrusterEffectThink.smoke_firecolors = smoke(function() return math.random(220, 255), math.random(110, 220), 0 end)
WireLib.ThrusterEffectThink.smoke_random = smoke(function() return math.random(100, 255), math.random(100, 255), math.random(100, 255) end)
WireLib.ThrusterEffectThink.smoke_diy = smoke(function(self) local c = self:GetColor() return c.r, c.g, c.b end)

local function exhaust(color)
	return function(self)

		self.SmokeTimer = self.SmokeTimer or 0
		if ( self.SmokeTimer > CurTime() ) then return end

		self.SmokeTimer = CurTime() + 0.015

		local vOffset = self:LocalToWorld(self:GetOffset() + VectorRand(-1.5, 1.5) )
		local vNormal = self:CalcNormal()

		local particle = emitter:Add( "particles/smokey", vOffset )
		particle:SetVelocity( vNormal * math.Rand( 40, 60 ) )
		particle:SetGravity(Vector(0, 0, 25))
		particle:SetAirResistance(20)
		particle:SetDieTime( 2.0 )
		particle:SetStartAlpha( math.Rand( 32, 64 ) )
		particle:SetStartSize( math.Rand( 3, 5 ) )
		particle:SetEndSize( math.Rand( 20, 26 ) )
		particle:SetRoll( math.Rand( -20, 20 ) )
		particle:SetRollDelta( math.Rand( -2.5, 2.5 ))
		particle:SetColor(color(self))
	end
end
WireLib.ThrusterEffectThink.exhaust = exhaust(function() return 200, 200, 210 end)
WireLib.ThrusterEffectThink.exhaust_diy = exhaust(function(self) local c = self:GetColor() return c.r, c.g, c.b end)

WireLib.ThrusterEffectThink.flamethrower = function(self)

	self.FlamethrowerTimer = self.FlamethrowerTimer or 0
	if ( self.FlamethrowerTimer > CurTime() ) then return end

	self.SmokeTimer = CurTime() + 0.003

	local vOffset = self:LocalToWorld(self:GetOffset() + VectorRand(-3, 3))
	local vNormal = self:CalcNormal()

	local particle = emitter:Add( "sprites/physg_glow2", vOffset )
	particle:SetVelocity( vNormal * math.Rand( 500, 520 ) )
	particle:SetDieTime(0.4)
	particle:SetCollide( true )
	particle:SetStartSize( math.Rand( 20, 30 ) )
	particle:SetEndSize( math.Rand( 100, 120 ) )
	particle:SetRoll( math.Rand( -180, 180 ) )
	particle:SetRollDelta( math.Rand( -20, 20 ))
	particle:SetStartAlpha( math.Rand( 60, 130 ) )
	particle:SetAirResistance(100)
	particle:SetColor(250, 100, 0)

	local particle2 = emitter:Add( "effects/fire_cloud2", vOffset )
	particle2:SetVelocity( vNormal * math.Rand( 500, 520 ) )
	particle2:SetDieTime(0.3)
	particle2:SetCollide( true )
	particle2:SetStartSize( math.Rand( 3, 4 ) )
	particle2:SetEndSize( math.Rand( 10, 40 ) )
	particle2:SetRoll( math.Rand( -180, 180 ) )
	particle2:SetRollDelta( math.Rand( -20, 20 ))
	particle2:SetStartAlpha( math.Rand( 30, 150 ) )
	particle2:SetAirResistance(100)
	particle2:SetColor(255, 255, 255)
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

local function debugcross(lifetime)
	return function(self)

		self.SmokeTimer = self.SmokeTimer or 0
		if ( self.SmokeTimer > CurTime() ) then return end

		self.SmokeTimer = CurTime() + 0.05

		local vOffset = self:LocalToWorld(self:GetOffset())
		local vNormal = self:CalcNormal()

		local particle = emitter:Add( "decals/cross", vOffset )
		particle:SetVelocity( vNormal * 0 )
		particle:SetDieTime(lifetime)
		particle:SetStartAlpha( 255 )
		particle:SetEndAlpha( 255 )
		particle:SetColor(0,255,0 )
		particle:SetStartSize( 5 )
		particle:SetEndSize( math.Rand(7,10) )
		particle:SetRoll(0)
	end
end

WireLib.ThrusterEffectThink.debug_10 = debugcross(10)
WireLib.ThrusterEffectThink.debug_30 = debugcross(30)
WireLib.ThrusterEffectThink.debug_60 = debugcross(60)

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

local function jetflame(color)
	return function(self)

		self.SmokeTimer = self.SmokeTimer or 0
		if ( self.SmokeTimer > CurTime() ) then return end

		self.SmokeTimer = CurTime() + 0.0000005

		local vOffset = self:LocalToWorld(self:GetOffset())
		local vNormal = self:CalcNormal()

		--vOffset = vOffset + VectorRand() * 5

		local speed = math.Rand(90,252)
		local roll = math.Rand(-90,90)

		local particle = emitter:Add( "particle/fire", vOffset )
		particle:SetVelocity( vNormal * speed )
		particle:SetDieTime( 0.3 )
		particle:SetStartAlpha( 255 )
		particle:SetEndAlpha( 150 )
		particle:SetStartSize( 15.8 )
		particle:SetEndSize( 9 )
		particle:SetColor(color(self))
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
end

WireLib.ThrusterEffectThink.jetflame = jetflame(function() return math.Rand(220, 255), math.Rand(180, 220), 55 end)
WireLib.ThrusterEffectThink.jetflame_purple = jetflame(function() return math.Rand(220, 255), 55, math.Rand(180, 220) end)
WireLib.ThrusterEffectThink.jetflame_red = jetflame(function() return math.Rand(220, 255), 55, 55 end)
WireLib.ThrusterEffectThink.jetflame_blue = jetflame(function() return 55, 55, math.Rand(220, 255) end)
WireLib.ThrusterEffectThink.jetflame_diy = jetflame(function(self) local c = self:GetColor() return c.r, c.g, c.b end)

local function balls(color)
	return function(self)
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
		particle:SetColor(color(self))
		particle:SetStartSize( 4 )
		particle:SetEndSize( 0 )
		particle:SetRoll( 0 )
	end
end

WireLib.ThrusterEffectThink.balls_firecolors = balls(function() return math.random(220,255), math.random(100,200), 0 end)
WireLib.ThrusterEffectThink.balls_random = balls(function() return math.random(0, 255), math.random(0, 255), math.random(0, 255) end)
WireLib.ThrusterEffectThink.balls = balls(function(self) local color = self:GetColor() return color.r, color.g, color.b end)

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

local function magic(color)
	return function(self)

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
		particle:SetColor(color(self))
		particle:SetStartSize( math.Rand( 1, 3 ) )
		particle:SetEndSize( 0 )
		particle:SetRoll( math.Rand( -0.2, 0.2 ) )
	end
end

WireLib.ThrusterEffectThink.magic_firecolors = magic(function() return math.random(220, 255), math.random(100, 200), 0 end)
WireLib.ThrusterEffectThink.magic = magic(function() return 255, 255, 255 end)
WireLib.ThrusterEffectThink.magic_diy = magic(function(self) local c = self:GetColor() return c.r, c.g, c.b end)
WireLib.ThrusterEffectThink.magic_color = magic(function() return math.random(0,255), math.random(0,255), math.random(0,255) end)

local function squirt(effect, delay, scale, growthrate)
	growthrate = growthrate or 0
	return function(self)
		self.RingTimer = self.RingTimer or 0
		if ( self.RingTimer > CurTime() ) then return end
		self.RingTimer = CurTime() + delay

		local vOffset = self:LocalToWorld(self:GetOffset())
		local vNormal = self:CalcNormal()

		local effectdata = EffectData()
		effectdata:SetOrigin( vOffset )
		effectdata:SetNormal( vNormal )
		effectdata:SetRadius(scale)
		effectdata:SetScale(scale)
		effectdata:SetMagnitude(growthrate)
		util.Effect(effect, effectdata )
	end
end

WireLib.ThrusterEffectDraw.rings = squirt("thruster_ring", 0.00005, 1)
WireLib.ThrusterEffectDraw.tesla = squirt("TeslaZap", 0.00005, 1)

WireLib.ThrusterEffectDraw.blood = squirt("BloodImpact", 0.00005, 1)

WireLib.ThrusterEffectDraw.some_sparks = squirt("StunstickImpact", 0.00005, 1)
WireLib.ThrusterEffectDraw.spark_fountain = squirt("ManhackSparks", 0.00005, 1)
WireLib.ThrusterEffectDraw.more_sparks = squirt("cball_explode", 0.00005, 1)

WireLib.ThrusterEffectDraw.water_small = squirt("watersplash", 0.05, 2)
WireLib.ThrusterEffectDraw.water_medium = squirt("watersplash", 0.05, 6)
WireLib.ThrusterEffectDraw.water_big = squirt("watersplash", 0.05, 10)
WireLib.ThrusterEffectDraw.water_huge = squirt("watersplash", 0.05, 18)

WireLib.ThrusterEffectDraw.striderblood_small = squirt("StriderBlood", 0.05, 0.1)
WireLib.ThrusterEffectDraw.striderblood_medium = squirt("StriderBlood", 0.05, 0.7)
WireLib.ThrusterEffectDraw.striderblood_big = squirt("StriderBlood", 0.05, 1.15)
WireLib.ThrusterEffectDraw.striderblood_huge = squirt("StriderBlood", 0.05, 2)

WireLib.ThrusterEffectDraw.rings_grow = squirt("thruster_ring", 0.00005, 1, 0.08)

WireLib.ThrusterEffectDraw.rings_grow_rings = function(self)
	self.RingTimer = self.RingTimer or 0
	if ( self.RingTimer > CurTime() ) then return end
	self.RingTimer = CurTime() + 0.00005

	local effectdata = EffectData()
	effectdata:SetOrigin(self:LocalToWorld(self:GetOffset()))
	effectdata:SetNormal(self:CalcNormal())

	effectdata:SetMagnitude(0.08) -- growth rate
	util.Effect("thruster_ring", effectdata)
	effectdata:SetMagnitude(0.06)
	util.Effect("thruster_ring", effectdata)
	effectdata:SetMagnitude(0.04)
	util.Effect("thruster_ring", effectdata)
	effectdata:SetMagnitude(0.02)
	util.Effect("thruster_ring", effectdata)
	effectdata:SetMagnitude(0)
	util.Effect("thruster_ring", effectdata)
end

WireLib.ThrusterEffectDraw.rings_shrink = squirt("thruster_ring", 0.00005, 1, -0.02)

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
