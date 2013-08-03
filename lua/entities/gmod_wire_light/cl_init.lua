
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

	local up = self:GetAngles():Up()
	
	local LightPos = self:GetPos()
	render.SetMaterial( matLight )
	
	local ViewNormal = self:GetPos() - EyePos()
	local Distance = ViewNormal:Length()
	ViewNormal:Normalize()
		
	local Visibile	= util.PixelVisible( LightPos, 4, self.PixVis )	
	
	if ( !Visibile || Visibile < 0.1 ) then return end

	local c = self:GetColor()
	c.a = 255 * Visibile
	
	if self:GetModel() == "models/maxofs2d/light_tubular.mdl" then
		render.DrawSprite( LightPos - up * 2, 8, 8, c, Visibile )
		render.DrawSprite( LightPos - up * 4, 8, 8, c, Visibile )
		render.DrawSprite( LightPos - up * 6, 8, 8, c, Visibile )
		render.DrawSprite( LightPos - up * 5, 64, 64, c, Visibile )
	else
		if self:GetModel() == "models/jaanus/wiretool/wiretool_siren.mdl" then c.a = 255 * -Visibile end
		render.DrawSprite( LightPos + up * ( self:OBBMaxs() - self:OBBMins() ) / 2, 128, 128, c, Visibile )
	end

end

local wire_light_block = CreateClientConVar("wire_light_block", 0, false, false)

function ENT:Think()
	if self:GetGlow() and not wire_light_block:GetBool() then

		local dlight = DynamicLight( self:EntIndex() )
		if ( dlight ) then
			dlight.Pos = self:GetPos()
			
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
