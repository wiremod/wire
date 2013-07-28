
include('shared.lua')

ENT.RenderGroup 	= RENDERGROUP_OPAQUE
ENT.Delay = 0.05

local matLight 		= Material( "sprites/light_ignorez" )
local matBeam		= Material( "effects/lamp_beam" )

/*---------------------------------------------------------
   Name: Draw
---------------------------------------------------------*/

function ENT:Draw()

	// Don't draw if we are in camera mode
	local ply = LocalPlayer()
	local wep = ply:GetActiveWeapon()
	if ( wep:IsValid() ) then
		local weapon_name = wep:GetClass()
		if ( weapon_name == "gmod_camera" ) then return end
	end

	self.BaseClass.Draw( self )

end

/*---------------------------------------------------------
   Name: Think
---------------------------------------------------------*/
function ENT:Think()

	if ( !(self:GetOn()~=0) ) then return end

	if ( self.Delay > CurTime() ) then return end
	self.Delay = CurTime() + self:GetDelay()

	local Effect = self:GetEffect()

	// Missing effect... replace it if possible :/
	if ( !self.Effects[ Effect ] ) then if ( self.Effects[1] ) then Effect = 1 else return end end

	local Angle = self:GetAngles()

	local FXDir = self:GetFXDir()
	if(FXDir && FXDir!=Vector(0,0,0))then Angle = FXDir:Angle() else self:GetUp():Angle() end

	local FXPos = self:GetFXPos()
	if (!FXPos || FXPos==Vector(0,0,0)) then FXPos=self:GetPos() + Angle:Forward() * 12 end

	local b, e = pcall( self.Effects[Effect], FXPos, Angle )

	// If there are errors..
	if (!b) then

		// Report the error
		Print(self.Effects)
		Print(FXPos)
		Print(Angle)
		Msg("Error in Emitter "..tostring(Effect).."\n -> "..tostring(e).."\n")

		// Remove the naughty function
		self.Effects[ Effect ] = nil

	end

end
