EFFECT.Mat = Material( "effects/select_ring" )

/*---------------------------------------------------------
   Initializes the effect. The data is a table of data
   which was passed from the server.
---------------------------------------------------------*/
function EFFECT:Init( data )

	local TargetEntity = data:GetEntity()

	if ( not TargetEntity or not TargetEntity:IsValid() ) then return end

	//local vOffset = TargetEntity:GetPos()

	local Low, High = TargetEntity:WorldSpaceAABB()
	local Center = data:GetOrigin() //High - (( High - Low ) * 0.5)

	local NumParticles = TargetEntity:BoundingRadius()
	NumParticles = NumParticles * 2

	NumParticles = math.Clamp( NumParticles, 10, 500 )

	local emitter = ParticleEmitter( Center )

		for i=0, NumParticles do

			local vPos = Vector( math.Rand(Low.x,High.x), math.Rand(Low.y,High.y), math.Rand(Low.z,High.z) )
			local vVel = (vPos - Center) * 6
			local particle = emitter:Add( "effects/spark", Center )
			if (particle) then
				particle:SetVelocity( vVel )
				particle:SetLifeTime( 0 )
				particle:SetDieTime( math.Rand( 0.1, 0.4 ) )
				particle:SetStartAlpha( 0 )
				particle:SetEndAlpha( math.Rand( 200, 255 ) )
				particle:SetStartSize( 0 )
				particle:SetEndSize( 20 )
				particle:SetRoll( math.Rand(0, 360) )
				particle:SetRollDelta( 0 )
			end

		end

	emitter:Finish()

end


/*---------------------------------------------------------
   THINK
---------------------------------------------------------*/
function EFFECT:Think()
	return false
end

/*---------------------------------------------------------
   Draw the effect
---------------------------------------------------------*/
function EFFECT:Render()
end
