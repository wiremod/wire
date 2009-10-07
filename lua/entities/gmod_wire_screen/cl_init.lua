
include('shared.lua')

ENT.Spawnable			= false
ENT.AdminSpawnable		= false
ENT.RenderGroup 		= RENDERGROUP_BOTH

function ENT:Initialize()

	surface.CreateFont( "coolvetica", 64, 400, false, false, "screen_font" )

	// Create new fonts here for Single Value screens
	// According to the wiki, the font size is capped at 128 (TheApathetic)
	surface.CreateFont("coolvetica", 128, 400, false, false, "screen_font_single")
	surface.CreateFont("Trebuchet", 36, 400, false, false, "Trebuchet36")

end

function ENT:Draw()
	self.Entity:DrawModel()

	local OF = 0
	local OU = 0
	local OR = 0
	local Res = 0.1
	local RatioX = 1

	if self.Entity:GetModel() == "models/props_lab/monitor01b.mdl" then
		OF = 6.53
		OU = 0
		OR = 0
		Res = 0.05
	elseif self.Entity:GetModel() == "models/kobilica/wiremonitorsmall.mdl" then
		OF = 0.2
		OU = 4.5
		OR = -0.85
		Res = 0.045
	elseif self.Entity:GetModel() == "models/kobilica/wiremonitorbig.mdl" then
		OF = 0.3
		OU = 11.8
		OR = -2.35
		Res = 0.12
	elseif self.Entity:GetModel() == "models/props/cs_office/computer_monitor.mdl" then
		OF = 3.25
		OU = 15.85
		OR = -2.2
		Res = 0.085
		RatioX = 0.75
	elseif self.Entity:GetModel() == "models/props/cs_office/tv_plasma.mdl" then
		OF = 6.1
		OU = 17.05
		OR = -5.99
		Res = 0.175
		RatioX = 0.57
	end

	local ang = self.Entity:GetAngles()
	local rot = Vector(-90,90,0)
	ang:RotateAroundAxis(ang:Right(), 	rot.x)
	ang:RotateAroundAxis(ang:Up(), 		rot.y)
	ang:RotateAroundAxis(ang:Forward(), rot.z)

	local pos = self.Entity:GetPos() + (self.Entity:GetForward() * OF) + (self.Entity:GetUp() * OU) + (self.Entity:GetRight() * OR)

	cam.Start3D2D(pos,ang,Res)

	local x = -112
	local y = -104
	local w = 296
	local h = 292

	local x1 = -5.535
	local x2 = 3.5
	local y1 = 5.091
	local y2 = -4.1

	local ox = 5
	local oy = 5

	local pos
	local cx
	local cy

	surface.SetDrawColor(0,0,0,255)
	surface.DrawRect(x/RatioX,y,(x+w)/RatioX,y+h)

	// Check for Single Value (TheApathetic)
	if (self:GetSingleValue()) then
		local rectheight = 20
		local fontsize = "18"
		local sf_suffix = ""

		// Check for Single Bigger Font setting
		if (self:GetSingleBigFont()) then
			rectheight = 40
			fontsize = "36"
			sf_suffix = "_single"
		end

		// Sizes here have been doubled when possible
		surface.SetDrawColor(100,100,150,255)
		surface.DrawRect(x/RatioX,y,(x+w)/RatioX,rectheight)

		draw.DrawText(self:GetTextA(),"Trebuchet"..fontsize,(x + 92)/RatioX,y + 2,Color(255,255,255,255),1)

		local DisplayA

		if (self:GetFloor()) then
			DisplayA = math.floor(self:GetDisplayA( ))
		else
			DisplayA = math.floor(self:GetDisplayA( ) * 1000)/ 1000
		end

		if (self:GetLeftAlign()) then
			draw.DrawText(DisplayA,"screen_font"..sf_suffix,x/RatioX,y + rectheight,Color(255,255,255,255),0)
		else
			draw.DrawText(DisplayA,"screen_font"..sf_suffix,(x + 92)/RatioX,y + rectheight,Color(255,255,255,255),1)
		end
	else
		// Normal two-value Wire Screen
		surface.SetDrawColor(100,100,150,255)
		surface.DrawRect(x/RatioX,y,(x+w)/RatioX,20)

		surface.SetDrawColor(100,100,150,255)
		surface.DrawRect(x/RatioX,y+94,(x+w)/RatioX,20)

		// Replaced "Value A" and "Value B" here (TheApathetic)
		draw.DrawText(self:GetTextA(),"Trebuchet18",(x + 92)/RatioX,y + 2,Color(255,255,255,255),1)
		draw.DrawText(self:GetTextB(),"Trebuchet18",(x + 92)/RatioX,y + 96,Color(255,255,255,255),1)

		local DisplayA
		local DisplayB

		if (self:GetFloor()) then
			DisplayA = math.floor(self:GetDisplayA( ))
			DisplayB = math.floor(self:GetDisplayB( ))
		else
			DisplayA = math.floor(self:GetDisplayA( ) * 1000)/ 1000
			DisplayB = math.floor(self:GetDisplayB( ) * 1000)/ 1000
		end

		if (self:GetLeftAlign()) then
			draw.DrawText(DisplayA,"screen_font",x/RatioX,y + 20,Color(255,255,255,255),0)
			draw.DrawText(DisplayB,"screen_font",x/RatioX,y + 114,Color(255,255,255,255),0)
		else
			draw.DrawText(DisplayA,"screen_font",(x + 90)/RatioX,y + 20,Color(255,255,255,255),1)
			draw.DrawText(DisplayB,"screen_font",(x + 92)/RatioX,y + 114,Color(255,255,255,255),1)
		end
	end

	cam.End3D2D()

	Wire_Render(self.Entity)
end

function ENT:IsTranslucent()
	return true
end
