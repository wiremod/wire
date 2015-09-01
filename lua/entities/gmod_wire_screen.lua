AddCSLuaFile()
DEFINE_BASECLASS( "base_wire_entity" )
ENT.PrintName       = "Wire Screen"
ENT.WireDebugName	= "Screen"

function ENT:SetupDataTables()
	self:NetworkVar("Bool", 0, "SingleValue")
	self:NetworkVar("Bool", 1, "SingleBigFont")
	self:NetworkVar("Bool", 2, "LeftAlign")
	self:NetworkVar("Bool", 3, "Floor")
	self:NetworkVar("Bool", 4, "FormatNumber")
	self:NetworkVar("Bool", 5, "FormatTime")

	self:NetworkVar("String", 0, "TextA")
	self:NetworkVar("String", 1, "TextB")

	self:NetworkVarNotify("SingleValue", function(ent, name, oldval, newval)
		WireLib.AdjustInputs(ent, newval and {"A"} or {"A", "B"})
	end)
end

if CLIENT then

	net.Receive("gmod_wire_screen.updateA", function()
		local ent = net.ReadEntity()
		ent.ValueA = net.ReadFloat()
	end)

	net.Receive("gmod_wire_screen.updateB", function()
		local ent = net.ReadEntity()
		ent.ValueB = net.ReadFloat()
	end)

	net.Receive("gmod_wire_screen.updateAB", function()
		local ent = net.ReadEntity()
		ent.ValueA = net.ReadFloat()
		ent.ValueB = net.ReadFloat()
	end)

	function ENT:Initialize()
		self.GPU = WireGPU(self, true)

		self.ValueA = 0
		self.ValueB = 0
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
				self:DrawNumber( self:GetTextA(), self.ValueA, x,y,w,h )
			else
				local h = h/2
				self:DrawNumber( self:GetTextA(), self.ValueA, x,y,w,h )
				self:DrawNumber( self:GetTextB(), self.ValueB, x,y+h,w,h )
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
util.AddNetworkString("gmod_wire_screen.updateA")
util.AddNetworkString("gmod_wire_screen.updateB")
util.AddNetworkString("gmod_wire_screen.updateAB")

function ENT:Initialize()
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )

	self.Inputs = WireLib.CreateInputs(self, { "A", "B" })

	self.ValueA = 0
	self.ValueB = 0
end

function ENT:Think()
	if self.ValueA and self.ValueB then	net.Start("gmod_wire_screen.updateAB")
	elseif self.ValueA then net.Start("gmod_wire_screen.updateA")
	elseif self.ValueB then net.Start("gmod_wire_screen.updateB")
	else return end

	net.WriteEntity(self)

	if self.ValueA then
		net.WriteFloat(self.ValueA)
		self.ValueA = nil
	end

	if self.ValueB then
		net.WriteFloat(self.ValueB)
		self.ValueB = nil
	end

	net.SendPVS(self:GetPos())

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

-- only needed for compatibility with old dupes
function ENT:Setup(SingleValue, SingleBigFont, TextA, TextB, LeftAlign, Floor, FormatNumber, FormatTime)
	if SingleValue ~= nil then self:SetSingleValue(SingleValue) end
	if SingleBigFont ~= nil then self:SetSingleBigFont(SingleBigFont) end
	if type(TextA) == "string" then	self:SetTextA(TextA) end
	if type(TextB) == "string" then self:SetTextB(TextB) end
	if LeftAlign ~= nil then self:SetLeftAlign(LeftAlign) end
	if Floor ~= nil then self:SetFloor(Floor) end
	if FormatNumber ~= nil then self:SetFormatNumber(FormatNumber) end
	if FormatTime ~= nil then self:SetFormatTime(FormatTime) end
end

duplicator.RegisterEntityClass("gmod_wire_screen", WireLib.MakeWireEnt, "Data", "SingleValue", "SingleBigFont", "TextA", "TextB", "LeftAlign", "Floor", "FormatNumber", "FormatTime")
