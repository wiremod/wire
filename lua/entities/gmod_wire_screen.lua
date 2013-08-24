AddCSLuaFile()
DEFINE_BASECLASS( "base_wire_entity" )
ENT.PrintName       = "Wire Screen"
ENT.WireDebugName	= "Screen"

function ENT:SetDisplayA( float )
	self:SetNetworkedBeamFloat( 1, float, true )
end

function ENT:SetDisplayB( float )
	self:SetNetworkedBeamFloat( 2, float, true )
end

function ENT:GetDisplayA( )
	return self:GetNetworkedBeamFloat( 1 )
end

function ENT:GetDisplayB( )
	return self:GetNetworkedBeamFloat( 2 )
end

// Extra stuff for Wire Screen (TheApathetic)
function ENT:SetSingleValue(singlevalue)
	self:SetNetworkedBool("SingleValue",singlevalue)

	// Change inputs if necessary
	if (singlevalue) then
		Wire_AdjustInputs(self, {"A"})
	else
		Wire_AdjustInputs(self, {"A","B"})
	end
end
function ENT:GetSingleValue()
	return self:GetNetworkedBool("SingleValue")
end

function ENT:SetSingleBigFont(singlebigfont)
	self:SetNetworkedBool("SingleBigFont",singlebigfont)
end
function ENT:GetSingleBigFont()
	return self:GetNetworkedBool("SingleBigFont")
end

function ENT:SetTextA(text)
	self:SetNetworkedString("TextA",text)
end
function ENT:GetTextA()
	return self:GetNetworkedString("TextA")
end

function ENT:SetTextB(text)
	self:SetNetworkedString("TextB",text)
end
function ENT:GetTextB()
	return self:GetNetworkedString("TextB")
end

function ENT:SetLeftAlign(leftalign)
	self:SetNetworkedBool("LeftAlign",leftalign)
end
function ENT:GetLeftAlign()
	return self:GetNetworkedBool("LeftAlign")
end

function ENT:SetFloor(Floor)
	self:SetNetworkedBool("Floor",Floor)
end
function ENT:GetFloor()
	return self:GetNetworkedBool("Floor")
end

if CLIENT then 
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

	function ENT:IsTranslucent() return true end

	local fontData = {
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
	
	return  -- No more client
end

-- Server

ENT.ValueA = 0
ENT.ValueB = 0

function ENT:Initialize()
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )

	self.Inputs = Wire_CreateInputs(self, { "A", "B" })
end

function ENT:Think()
	if self.ValueA then
		self:SetDisplayA( self.ValueA )
		self.ValueA = nil
	end

	if self.ValueB then
		self:SetDisplayB( self.ValueB )
		self.ValueB = nil
	end

	self:NextThink(CurTime() + 0.05)
	return true
end

function ENT:Use()
end

function ENT:TriggerInput(iname, value)
	if (iname == "A") then
		self.ValueA = value
	elseif (iname == "B") then
		self.ValueB = value
	end
end

function ENT:Setup(SingleValue, SingleBigFont, TextA, TextB, LeftAlign, Floor)
	--for duplication
	self.SingleValue	= SingleValue
	self.SingleBigFont	= SingleBigFont
	self.TextA			= TextA
	self.TextB 			= TextB
	self.LeftAlign 		= LeftAlign
	self.Floor	 		= Floor

	-- Extra stuff for Wire Screen (TheApathetic)
	self:SetTextA(TextA)
	self:SetTextB(TextB)
	self:SetSingleBigFont(SingleBigFont)

	--LeftAlign (TAD2020)
	self:SetLeftAlign(LeftAlign)
	--Floor (TAD2020)
	self:SetFloor(Floor)

	--Put it here to update inputs if necessary (TheApathetic)
	self:SetSingleValue(SingleValue)
end

duplicator.RegisterEntityClass("gmod_wire_screen", WireLib.MakeWireEnt, "Data", "SingleValue", "SingleBigFont", "TextA", "TextB", "LeftAlign", "Floor")
