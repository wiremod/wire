
include('shared.lua')

local matLight 		= Material( "sprites/light_ignorez" )
local matBeam		= Material( "effects/lamp_beam" )

ENT.RenderGroup 		= RENDERGROUP_BOTH

function ENT:Initialize()

	self.PixVis = util.GetPixelVisibleHandle()

end

/*---------------------------------------------------------
   Name: DrawTranslucent
   Desc: Draw translucent
---------------------------------------------------------*/
function ENT:DrawTranslucent()

	local LightNrm = self:GetAngles():Up()*(-1)
	local ViewDot = EyeVector():Dot( LightNrm )
	local LightPos = self:GetPos() + LightNrm * -10

	// glow sprite

	if ( ViewDot < 0 ) then return end

	render.SetMaterial( matLight )
	local Visible	= util.PixelVisible( LightPos, 16, self.PixVis )
	local Size = math.Clamp( 512 * (1 - Visible*ViewDot),128, 512 )
	
	local c = self:GetColor()
	c.a = 200*Visible*ViewDot

	render.DrawSprite( LightPos, Size, Size, c, Visible * ViewDot )

end

local wire_light_block = CreateClientConVar("wire_light_block", 0, false, false)

function ENT:Think()
	if self:GetGlow() and not wire_light_block:GetBool() then

		local dlight = DynamicLight( self:EntIndex() )
		if ( dlight ) then
			local LightNrm = self:GetAngles():Up()*(-1)

			dlight.Pos = self:GetPos() + LightNrm * -10
			
			local c = self:GetColor()
			dlight.r = c.r
			dlight.g = c.g
			dlight.b = c.b
			
			dlight.Brightness = self:GetBrightness()
			dlight.Decay = self:GetDecay()
			dlight.Size = self:GetSize()
			dlight.DieTime = CurTime() + 1
		end

	end
end
