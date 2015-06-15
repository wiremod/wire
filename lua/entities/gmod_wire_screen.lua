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

-- Extra stuff for Wire Screen (TheApathetic)
function ENT:SetSingleValue(singlevalue)
	self:SetNWBool("SingleValue",singlevalue)

	-- Change inputs if necessary
	if (singlevalue) then
		WireLib.AdjustInputs(self, {"A"})
	else
		WireLib.AdjustInputs(self, {"A","B"})
	end
end
function ENT:GetSingleValue()
	return self:GetNetworkedBool("SingleValue")
end

function ENT:SetSingleBigFont(singlebigfont)
	self:SetNWBool("SingleBigFont",singlebigfont)
end
function ENT:GetSingleBigFont()
	return self:GetNetworkedBool("SingleBigFont")
end

function ENT:SetTextA(text)
	self:SetNWString("TextA",text)
end
function ENT:GetTextA()
	return self:GetNetworkedString("TextA")
end

function ENT:SetTextB(text)
	self:SetNWString("TextB",text)
end
function ENT:GetTextB()
	return self:GetNWString("TextB")
end

function ENT:SetLeftAlign(leftalign)
	self:SetNWBool("LeftAlign",leftalign)
end
function ENT:GetLeftAlign()
	return self:GetNWBool("LeftAlign")
end

function ENT:SetFloor(Floor)
	self:SetNWBool("Floor",Floor)
end
function ENT:GetFloor()
	return self:GetNWBool("Floor")
end

function ENT:SetFormatNumber( FormatNumber )
	self:SetNWBool( "FormatNumber", FormatNumber )
end
function ENT:GetFormatNumber()
	return self:GetNWBool("FormatNumber")
end

function ENT:SetFormatTime( FormatTime )
	self:SetNWBool( "FormatTime", FormatTime )
end
function ENT:GetFormatTime()
	return self:GetNWBool("FormatTime")
end

if CLIENT then 
	function ENT:Initialize()
		self.GPU = WireGPU(self, true)
	end

	function ENT:OnRemove()
		self.GPU:Finalize()
	end

	local header_color = Color(100,100,150,255)
	local text_color = Color(255,255,255,255)
	local background_color = Color(0,0,0,255)

	local large_font = "Trebuchet36"
	local small_font = "Trebuchet18"
	local value_large_font = "screen_font_single"
	local value_small_font = "screen_font"

	local small_height = 20
	local large_height = 40

	function ENT:DrawNumber( header, value, x,y,w,h )
		local header_height = small_height
		local header_font = small_font
		local value_font = value_small_font

		if self:GetSingleValue() and self:GetSingleBigFont() then
			header_height = large_height
			header_font = large_font
			value_font = value_large_font
		end

		surface.SetDrawColor( header_color )
		surface.DrawRect( x, y, w, header_height )

		surface.SetFont( header_font )
		surface.SetTextColor( text_color )
		local _w,_h = surface.GetTextSize( header )
		surface.SetTextPos( x + w / 2 - _w / 2, y + 2 )
		surface.DrawText( header, header_font )

		if self:GetFormatTime() then -- format as time, aka duration - override formatnumber and floor settings
			value = WireLib.nicenumber.nicetime( value )
		elseif self:GetFormatNumber() then
			if self:GetFloor() then
				value = WireLib.nicenumber.format( math.floor( value ), 1 )
			else
				value = WireLib.nicenumber.formatDecimal( value )
			end
		elseif self:GetFloor() then
			value = "" .. math.floor( value )
		else
			-- note: loses precision after ~7 decimals, so don't bother displaying more
			value = "" .. math.floor( value * 10000000 ) / 10000000 
		end

		local align = self:GetLeftAlign() and 0 or 1
		surface.SetFont( value_font )
		local _w,_h = surface.GetTextSize( value )
		surface.SetTextPos( x + (w / 2 - _w / 2) * align, y + header_height )
		surface.DrawText( value )
	end

	function ENT:Draw()
		self:DrawModel()

		self.GPU:RenderToWorld(nil, 188, function(x, y, w, h)
			surface.SetDrawColor(background_color)
			surface.DrawRect(x, y, w, h)

			if self:GetSingleValue() then
				self:DrawNumber( self:GetTextA(), self:GetDisplayA(), x,y,w,h )
			else
				local h = h/2
				self:DrawNumber( self:GetTextA(), self:GetDisplayA(), x,y,w,h )
				self:DrawNumber( self:GetTextB(), self:GetDisplayB(), x,y+h,w,h )
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

function ENT:Initialize()
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )

	self.Inputs = WireLib.CreateInputs(self, { "A", "B" })

	self.ValueA = 0
	self.ValueB = 0
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

function ENT:TriggerInput(iname, value)
	if (iname == "A") then
		self.ValueA = value
	elseif (iname == "B") then
		self.ValueB = value
	end
end

function ENT:Setup(SingleValue, SingleBigFont, TextA, TextB, LeftAlign, Floor, FormatNumber, FormatTime)
	--for duplication
	self.SingleValue	= SingleValue
	self.SingleBigFont	= SingleBigFont
	self.TextA			= TextA
	self.TextB 			= TextB
	self.LeftAlign 		= LeftAlign
	self.Floor	 		= Floor
	self.FormatNumber	= FormatNumber
	self.FormatTime		= FormatTime

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

	-- Auto formatting (Divran)
	self:SetFormatNumber( FormatNumber )
	self:SetFormatTime( FormatTime )
end

duplicator.RegisterEntityClass("gmod_wire_screen", WireLib.MakeWireEnt, "Data", "SingleValue", "SingleBigFont", "TextA", "TextB", "LeftAlign", "Floor", "FormatNumber", "FormatTime")
