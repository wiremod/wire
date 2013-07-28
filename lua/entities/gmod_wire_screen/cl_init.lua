
include('shared.lua')

ENT.Spawnable			= false
ENT.AdminSpawnable		= false
ENT.RenderGroup 		= RENDERGROUP_BOTH

function ENT:Initialize()


	self.GPU = WireGPU(self, true)
end

function ENT:OnRemove()
	self.GPU:Finalize()
end

function ENT:Draw()
	self:DrawModel()

	self.GPU:RenderToWorld(nil, 188, function(x, y, w, h)
		surface.SetDrawColor(0, 0, 0, 255)
		surface.DrawRect(x, y, w, h)

		// Check for Single Value (TheApathetic)
		if (self:GetSingleValue()) then
			local rectheight = 20
			local textfont = "Trebuchet18"
			local valuefont = "screen_font"

			// Check for Single Bigger Font setting
			if (self:GetSingleBigFont()) then
				rectheight = 40
				textfont = "Trebuchet36"
				valuefont = "screen_font_single"
			end

			// Sizes here have been doubled when possible
			surface.SetDrawColor(100,100,150,255)
			surface.DrawRect(x,y,w,rectheight)

			draw.DrawText(self:GetTextA(), textfont, x + w/2, y + 2, Color(255,255,255,255), 1)

			local DisplayA

			if (self:GetFloor()) then
				DisplayA = math.floor(self:GetDisplayA( ))
			else
				DisplayA = math.floor(self:GetDisplayA( ) * 1000)/ 1000
			end

			local halign = self:GetLeftAlign() and 0 or 1
			draw.DrawText(DisplayA,valuefont,x + w/2*halign,y + rectheight,Color(255,255,255,255),halign)
		else
			// Normal two-value Wire Screen

			-- draw top bars
			surface.SetDrawColor(100,100,150,255)
			surface.DrawRect(x,y,w,20)

			surface.SetDrawColor(100,100,150,255)
			surface.DrawRect(x,y+94,w,20)

			// Replaced "Value A" and "Value B" here (TheApathetic)
			draw.DrawText(self:GetTextA(), "Trebuchet18", x + w/2, y +  2, Color(255,255,255,255), 1)
			draw.DrawText(self:GetTextB(), "Trebuchet18", x + w/2, y + 96, Color(255,255,255,255), 1)

			local DisplayA
			local DisplayB

			if (self:GetFloor()) then
				DisplayA = math.floor(self:GetDisplayA( ))
				DisplayB = math.floor(self:GetDisplayB( ))
			else
				DisplayA = math.floor(self:GetDisplayA( ) * 1000)/ 1000
				DisplayB = math.floor(self:GetDisplayB( ) * 1000)/ 1000
			end

			local halign = self:GetLeftAlign() and 0 or 1
			draw.DrawText(DisplayA, "screen_font", x + w/2*halign, y +  20, Color(255,255,255,255), halign)
			draw.DrawText(DisplayB, "screen_font", x + w/2*halign, y + 114, Color(255,255,255,255), halign)
		end

	end)

	Wire_Render(self)
end

function ENT:IsTranslucent()
	return true
end


local fontData = 
{
	font = "coolvetica",
	size = 64,
	weight = 400,
	antialias = false,
	additive = false,

}
surface.CreateFont("screen_font", fontData )
fontData.size = 128
surface.CreateFont("screen_font_single", fontData )
fontData.size = 36
surface.CreateFont("Trebuchet36", fontData )
