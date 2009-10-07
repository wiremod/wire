
ENT.RenderGroup 		= RENDERGROUP_BOTH

language.Add( "Cleanup_hoverdrivecontrolers", "Hoverdrive Controllers" )
language.Add( "Cleaned_hoverdrivecontrolers", "Cleaned up Hoverdrive Controllers" )
language.Add( "SBoxLimit_wire_hoverdrives", "You have hit the Hoverdrive Controllers limit!" )

include('shared.lua')

/*---------------------------------------------------------
   Name: Initialize
---------------------------------------------------------*/
function ENT:Initialize()

	self.Refraction = Material( "sprites/heatwave" )
	self.Glow		= Material( "sprites/light_glow02_add" )
	self.ShouldDraw = 1

	self.NextSmokeEffect = 0

end


/*---------------------------------------------------------
   Name: Draw
---------------------------------------------------------*/
function ENT:Draw()

	if ( self.ShouldDraw == 0 ) then return end
	self.BaseClass.Draw( self )

	Wire_Render(self.Entity)

end

/*---------------------------------------------------------
   Name: DrawTranslucent
   Desc: Draw translucent
---------------------------------------------------------*/
function ENT:DrawTranslucent()

	if ( self.ShouldDraw == 0 ) then return end

	if (self:GetHoverMode() > 0) then
		local vOffset = self.Entity:GetPos()
		local vPlayerEyes = LocalPlayer():EyePos()
		local vDiff = (vOffset - vPlayerEyes):GetNormalized()

		render.SetMaterial( self.Glow )
		local color = Color( 40, 50, 200, 255 ) //70,180,255,255
		render.DrawSprite( vOffset - vDiff * 2, 22, 22, color )

		local Distance = math.abs( (self:GetTargetZ() - self.Entity:GetPos().z) * math.sin( CurTime() * 20 )  ) * 0.05
		color.r = color.r * math.Clamp( Distance, 0, 1 )
		color.b = color.b * math.Clamp( Distance, 0, 1 )
		color.g = color.g * math.Clamp( Distance, 0, 1 )

		render.DrawSprite( vOffset + vDiff * 4, 48, 48, color )
		render.DrawSprite( vOffset + vDiff * 4, 52, 52, color )
	else
		local vOffset = self.Entity:GetPos()
		local vPlayerEyes = LocalPlayer():EyePos()
		local vDiff = (vOffset - vPlayerEyes):GetNormalized()

		render.SetMaterial( self.Glow )
		local color = Color( 255, 50, 60, 255 ) //70,180,255,255
		render.DrawSprite( vOffset - vDiff * 2, 22, 22, color )

		local Pulse = math.sin( CurTime() * 20 ) * 0.05
		color.r = color.r * math.Clamp( Pulse, 0, 1 )
		color.b = color.b * math.Clamp( Pulse, 0, 1 )
		color.g = color.g * math.Clamp( Pulse, 0, 1 )

		render.DrawSprite( vOffset + vDiff * 4, 48, 48, color )
		render.DrawSprite( vOffset + vDiff * 4, 52, 52, color )
	end

end


/*---------------------------------------------------------
   Name: Think
   Desc: Client Think - called every frame
---------------------------------------------------------*/
function ENT:Think()
	self.BaseClass.Think(self)

	self.ShouldDraw = GetConVarNumber( "cl_drawhoverballs" )
end

