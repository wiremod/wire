AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include('shared.lua')

ENT.WireDebugName = "Text Screen"

function ENT:Initialize()
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )

	self.Inputs = WireLib.CreateSpecialInputs(self, { "String", "FGColor", "BGColor" }, { "STRING", "VECTOR", "VECTOR" })
	self:InitializeShared()
end

function ENT:Setup(DefaultText, chrPerLine, textJust, valign, fgcolor, bgcolor)
	self.fgcolor = fgcolor or Color(255,255,255)
	self.bgcolor = bgcolor or Color(0,0,0)
	self.chrPerLine = math.Clamp(math.ceil(chrPerLine or 10), 1, 15)
	self.textJust = textJust or 1
	self.valign = valign or 0
	self:SendConfig()

	self:TriggerInput("String", DefaultText or "")
end

function ENT:TriggerInput(iname, value)
	if iname == "String" then
		self:SetText(tostring(value))
	elseif iname == "FGColor" then
		self.fgcolor = Color(value.x, value.y, value.z)
		self.doSendConfig = true
	elseif iname == "BGColor" then
		self.bgcolor = Color(value.x, value.y, value.z)
		self.doSendConfig = true
	end
end

local function formatText(text)
	return text:gsub("<br>", "\n")
end

function ENT:SetText(text, ply)
	self.text = text
	self:umsg(ply)
		self.umsg.Char(2) -- text

		self.umsg.String(formatText(text))
	self.umsg.End()
end

function ENT:Think()
	if self.doSendConfig then
		self:SendConfig()
	end
end

function ENT:SendConfig(ply)
	self.doSendConfig = nil
	self:umsg(ply)
		self.umsg.Char(1) -- config

		self.umsg.Char(self.chrPerLine)
		self.umsg.Char(self.textJust)
		self.umsg.Char(self.valign)

		self.umsg.Char(self.fgcolor.r-128)
		self.umsg.Char(self.fgcolor.g-128)
		self.umsg.Char(self.fgcolor.b-128)

		self.umsg.Char(self.bgcolor.r-128)
		self.umsg.Char(self.bgcolor.g-128)
		self.umsg.Char(self.bgcolor.b-128)
	self.umsg.End()
end

function ENT:Retransmit(ply)
	self:SetText(self.text, ply)
	self:SendConfig(ply)
end

duplicator.RegisterEntityClass("gmod_wire_textscreen", MakeWireEnt, "Data", "text", "chrPerLine", "textJust", "valign", "fgcolor", "bgcolor")
