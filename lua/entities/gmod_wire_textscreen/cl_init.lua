--Wire text screen by greenarrow and wire team
--http://gmodreviews.googlepages.com/
--http://forums.facepunchstudios.com/greenarrow

include('shared.lua')
ENT.Spawnable			= false
ENT.AdminSpawnable		= false
ENT.RenderGroup 		= RENDERGROUP_BOTH
ENT.currentText = ""
ENT.allowDraw = false

function ENT:Initialize()
	self:GetConfig()
	self.allowDraw = true
	self.currentText = self:GetText()
end

function ENT:Draw()
	self.Entity:DrawModel()
	if (!self.allowDraw) then return true end
	--nighteagle screen vector rotation and positioning legacy code
	local OF = 0.3
	local OU = 11.8
	local OR = -2.35
	local Res = 0.12
	local RatioX = 1

	local ang = self.Entity:GetAngles()
	local rot = Vector(-90,90,0)
	ang:RotateAroundAxis(ang:Right(), rot.x)
	ang:RotateAroundAxis(ang:Up(), rot.y)
	ang:RotateAroundAxis(ang:Forward(), rot.z)
	local pos = self.Entity:GetPos() + (self.Entity:GetForward() * OF) + (self.Entity:GetUp() * OU) + (self.Entity:GetRight() * OR)

	cam.Start3D2D(pos,ang,Res)
		local x = -112
		local y = -104
		local w = 296
		local h = 292

		--add changable backround colour some time.
		surface.SetDrawColor(0,0,0,255)
		surface.DrawRect(x/RatioX,y,(x+w)/RatioX,y+h)

		local justOffset = (w / 3) + (self.textJust * (w / 3.5))
		self:GetConfig()
		self.currentText = self:GetText()
		if (self.chrPerLine ~= 0) then
			draw.DrawText(self.currentText, "textScreenfont"..tostring(self.chrPerLine), (x + justOffset - 92) / RatioX, y + 2, Color(self.tRed, self.tGreen, self.tBlue, 255), self.textJust)
		end
	cam.End3D2D()
	Wire_Render(self.Entity)
end

function ENT:IsTranslucent()
	return true
end


if !textScreenFontsCreated then
	textScreenFontsCreated = true
	local fontSize = 380
	surface.CreateFont( "coolvetica", fontSize, 400, false, false, "textScreenfont1" )
	surface.CreateFont( "coolvetica", fontSize / 2, 400, false, false, "textScreenfont2" )
	surface.CreateFont( "coolvetica", fontSize / 3, 400, false, false, "textScreenfont3" )
	surface.CreateFont( "coolvetica", fontSize / 4, 400, false, false, "textScreenfont4" )
	surface.CreateFont( "coolvetica", fontSize / 5, 400, false, false, "textScreenfont5" )
	surface.CreateFont( "coolvetica", fontSize / 6, 400, false, false, "textScreenfont6" )
	surface.CreateFont( "coolvetica", fontSize / 7, 400, false, false, "textScreenfont7" )
	surface.CreateFont( "coolvetica", fontSize / 8, 400, false, false, "textScreenfont8" )
	surface.CreateFont( "coolvetica", fontSize / 9, 400, false, false, "textScreenfont9" )
	surface.CreateFont( "coolvetica", fontSize / 10, 400, false, false, "textScreenfont10" )
	surface.CreateFont( "coolvetica", fontSize / 11, 400, false, false, "textScreenfont11" )
	surface.CreateFont( "coolvetica", fontSize / 12, 400, false, false, "textScreenfont12" )
	surface.CreateFont( "coolvetica", fontSize / 13, 400, false, false, "textScreenfont13" )
	surface.CreateFont( "coolvetica", fontSize / 14, 400, false, false, "textScreenfont14" )
	surface.CreateFont( "coolvetica", fontSize / 15, 400, false, false, "textScreenfont15" )
end
