AddCSLuaFile()
DEFINE_BASECLASS( "base_wire_entity" )
ENT.PrintName       = "Wire Screen"
ENT.WireDebugName	= "Screen"
ENT.Editable = true
ENT.RenderGroup = RENDERGROUP_BOTH

function ENT:SetupDataTables()
	self:NetworkVar("Bool", 0, "SingleValue", { KeyName = "SingleValue",
		Edit = { type = "Boolean", title = "#Tool_wire_screen_singlevalue", order = 1 } })
	self:NetworkVar("Bool", 1, "SingleBigFont", { KeyName = "SingleBigFont",
		Edit = { type = "Boolean", title = "#Tool_wire_screen_singlebigfont", order = 2 } })
	self:NetworkVar("Bool", 2, "LeftAlign", { KeyName = "LeftAlign",
		Edit = { type = "Boolean", title = "#Tool_wire_screen_leftalign", order = 3 } })
	self:NetworkVar("Bool", 3, "Floor", { KeyName = "Floor",
		Edit = { type = "Boolean", title = "#Tool_wire_screen_floor", order = 4 } })
	self:NetworkVar("Bool", 4, "FormatNumber", { KeyName = "FormatNumber",
		Edit = { type = "Boolean", title = "#Tool_wire_screen_formatnumber", order = 5 } })
	self:NetworkVar("Bool", 5, "FormatTime", { KeyName = "FormatTime",
		Edit = { type = "Boolean", title = "#Tool_wire_screen_formattime", order = 6 } })
	self:NetworkVar("String", 0, "TextA", { KeyName = "TextA",
		Edit = { type = "Generic", title = "#Tool_wire_screen_texta", order = 7 } })
	self:NetworkVar("String", 1, "TextB", { KeyName = "TextB",
		Edit = { type = "Generic", title = "#Tool_wire_screen_textb", order = 8 } })

	if SERVER then
		self:NetworkVarNotify("SingleValue", function(ent, key, old, single)
			WireLib.AdjustInputs(self, single and { "A" } or { "A", "B" })
		end)
	end
end

function ENT:SetDisplayA(float)	self:SetNWFloat("DisplayA", float) end
function ENT:SetDisplayB(float)	self:SetNWFloat("DisplayB", float) end
function ENT:GetDisplayA() return self:GetNWFloat("DisplayA") end
function ENT:GetDisplayB() return self:GetNWFloat("DisplayB") end

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

-- only needed for legacy dupes
function ENT:Setup(SingleValue, SingleBigFont, TextA, TextB, LeftAlign, Floor, FormatNumber, FormatTime)
	if type(TextA) == "string" then self:SetTextA(TextA) end
	if type(TextB) == "string" then self:SetTextB(TextB) end
	if SingleBigFont ~= nil then self:SetSingleBigFont(SingleBigFont) end
	if LeftAlign ~= nil then self:SetLeftAlign(LeftAlign) end
	if Floor ~= nil then self:SetFloor(Floor) end
	if SingleValue ~= nil then self:SetSingleValue(SingleValue) end
	if FormatNumber ~= nil then self:SetFormatNumber(FormatNumber) end
	if FormatTime ~= nil then self:SetFormatTime(FormatTime) end
end

duplicator.RegisterEntityClass("gmod_wire_screen", WireLib.MakeWireEnt, "Data", "SingleValue", "SingleBigFont", "TextA", "TextB", "LeftAlign", "Floor", "FormatNumber", "FormatTime")
