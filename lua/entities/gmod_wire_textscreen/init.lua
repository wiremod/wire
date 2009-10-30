AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include('shared.lua')

ENT.WireDebugName = "Text Screen"

function ENT:Initialize()
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )

	self.Inputs = WireLib.CreateSpecialInputs(self.Entity, { "String", "FGColor", "BGColor" }, { "STRING", "VECTOR", "VECTOR" })
	self:InitializeShared()
end

function ENT:Setup(DefaultText, chrPerLine, textJust, fgcolor, bgcolor)
	self.fgcolor = fgcolor
	self.bgcolor = bgcolor
	self.chrPerLine = chrPerLine
	self.textJust = textJust
	self:SendConfig()

	self:TriggerInput("String", DefaultText)
end

function ENT:TriggerInput(iname, value)
	if iname == "String" then
		self:SetText(value)

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
	umsg.Start("wire_textscreen_SetText", ply)
		umsg.Entity(self.Entity)
		umsg.String(formatText(text))
	umsg.End()
end

function ENT:Think()
	if self.doSendConfig then
		self:SendConfig()
	end
end

function ENT:SendConfig(ply)
	self.doSendConfig = nil
	umsg.Start("wire_textscreen_SendConfig", ply)
		umsg.Entity(self.Entity)

		umsg.Char(self.chrPerLine)
		umsg.Char(self.textJust)

		umsg.Char(self.fgcolor.r-128)
		umsg.Char(self.fgcolor.g-128)
		umsg.Char(self.fgcolor.b-128)

		umsg.Char(self.bgcolor.r-128)
		umsg.Char(self.bgcolor.g-128)
		umsg.Char(self.bgcolor.b-128)
	umsg.End()
end

function ENT:PlayerInitialSpawn(ply)
	self:SetText(self.text, ply)
	self:SendConfig(ply)
end

hook.Add("PlayerInitialSpawn", "wire_textscreen", function(ply)
	for k,screen in ipairs(ents.FindByClass("gmod_wire_textscreen")) do
		screen:PlayerInitialSpawn(ply)
	end
end)

function MakeWireTextScreen( pl, Pos, Ang, model, text, chrPerLine, textJust, fgcolor, bgcolor, frozen)
	if ( !pl:CheckLimit( "wire_textscreens" ) ) then return false end
	local wire_textscreen = ents.Create( "gmod_wire_textscreen" )
	if (!wire_textscreen:IsValid()) then return false end
	wire_textscreen:SetModel(model)
	wire_textscreen:SetAngles( Ang )
	wire_textscreen:SetPos( Pos )
	wire_textscreen:Spawn()

	wire_textscreen:Setup(text, chrPerLine, textJust, fgcolor, bgcolor)

	if wire_textscreen:GetPhysicsObject():IsValid() then
		local Phys = wire_textscreen:GetPhysicsObject()
		Phys:EnableMotion(!frozen)
	end

	wire_textscreen:SetPlayer(pl)
	wire_textscreen.pl = pl

	pl:AddCount( "wire_textscreens", wire_textscreen )
	return wire_textscreen
end
duplicator.RegisterEntityClass("gmod_wire_textscreen", MakeWireTextScreen, "Pos", "Ang", "Model", "text", "chrPerLine", "textJust", "fgcolor", "bgcolor", "frozen")
