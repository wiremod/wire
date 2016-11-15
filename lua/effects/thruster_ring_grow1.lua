EFFECT.Mat = Material( "effects/select_ring" )

--[[---------------------------------------------------------
   Initializes the effect. The data is a table of data
   which was passed from the server.
---------------------------------------------------------]]
function EFFECT:Init( data )

	local size = 16
	self:SetCollisionBounds( Vector( -size,-size,-size ), Vector( size,size,size ) )

	local Pos = data:GetOrigin() + data:GetNormal() * 2

	self:SetPos( Pos )
	self:SetAngles( data:GetNormal():Angle() + Angle( 0.01, 0.01, 0.01 ) )

	self.Pos = data:GetOrigin()
	self.Normal = data:GetNormal()

	self.Speed = 2
	self.Size = 16
	self.Alpha = 255

end


--[[---------------------------------------------------------
   THINK
---------------------------------------------------------]]
function EFFECT:Think( )

	local speed = FrameTime() * self.Speed

	--if (self.Speed > 100) then self.Speed = self.Speed - 1000 * speed end

	--self.Size = self.Size + speed * self.Speed
	self.Size = self.Size + (255 - self.Alpha)*0.06
	self.Alpha = self.Alpha - 250.0 * speed

	self:SetPos( self:GetPos() + self.Normal * speed * 128 )

	if self.Alpha < 0 then return false end
	if self.Size < 0 then return false end
	return true

end

--[[---------------------------------------------------------
   Draw the effect
---------------------------------------------------------]]
function EFFECT:Render( )

	if self.Alpha < 1 then return end

	render.SetMaterial( self.Mat )

	render.DrawQuadEasy( self:GetPos(),
		self:GetAngles():Forward(),
		self.Size, self.Size,
		Color( math.Rand( 10, 100), math.Rand( 100, 220), math.Rand( 240, 255), self.Alpha )
	)

end
