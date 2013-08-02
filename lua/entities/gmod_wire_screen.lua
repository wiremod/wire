AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include('shared.lua')

ENT.WireDebugName = "Screen"

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

function MakeWireScreen( pl, Pos, Ang, model, SingleValue, SingleBigFont, TextA, TextB, LeftAlign, Floor, frozen )

	if ( !pl:CheckLimit( "wire_screens" ) ) then return false end

	local wire_screen = ents.Create( "gmod_wire_screen" )
	if (!wire_screen:IsValid()) then return false end
	wire_screen:SetModel(model)
	wire_screen:SetAngles( Ang )
	wire_screen:SetPos( Pos )
	wire_screen:Spawn()

	if wire_screen:GetPhysicsObject():IsValid() then
		local Phys = wire_screen:GetPhysicsObject()
		Phys:EnableMotion(!frozen)
	end

	wire_screen:Setup(SingleValue, SingleBigFont, TextA, TextB, LeftAlign, Floor)

	wire_screen:SetPlayer(pl)
	wire_screen.pl = pl

	pl:AddCount( "wire_screens", wire_screen )

	return wire_screen

end
duplicator.RegisterEntityClass("gmod_wire_screen", MakeWireScreen, "Pos", "Ang", "Model", "SingleValue", "SingleBigFont", "TextA", "TextB", "LeftAlign", "Floor", "frozen")

