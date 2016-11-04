AddCSLuaFile()
DEFINE_BASECLASS( "base_wire_entity" )
ENT.PrintName       = "Wire Indicator"
ENT.WireDebugName	= "Indicator"

if CLIENT then return end -- No more client

function ENT:Initialize()
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )

	self.a = 0
	self.ar = 0
	self.ag = 0
	self.ab = 0
	self.aa = 0
	self.b = 0
	self.br = 0
	self.bg = 0
	self.bb = 0
	self.ba = 0

	self.Inputs = Wire_CreateInputs(self, { "A" })
end

function ENT:Setup(a, ar, ag, ab, aa, b, br, bg, bb, ba)
	self.a = a or 0
	self.ar = ar or 255
	self.ag = ag or 0
	self.ab = ab or 0
	self.aa = aa or 255
	self.b = b or 1
	self.br = br or 0
	self.bg = bg or 255
	self.bb = bb or 0
	self.ba = ba or 255

	local factor = math.max(0, math.min(self.Inputs.A.Value-self.a/(self.b-self.a), 1))
	self:TriggerInput("A", 0)
end

function ENT:TriggerInput(iname, value)
	if iname == "A" then
		local factor = math.Clamp((value-self.a)/(self.b-self.a), 0, 1)
		self:ShowOutput(factor)

		local r = math.Clamp((self.br-self.ar)*factor+self.ar, 0, 255)
		local g = math.Clamp((self.bg-self.ag)*factor+self.ag, 0, 255)
		local b = math.Clamp((self.bb-self.ab)*factor+self.ab, 0, 255)
		local a = math.Clamp((self.ba-self.aa)*factor+self.aa, 0, 255)
		self:SetColor(Color(r, g, b, a))
	end
end

function ENT:ShowOutput(value)
	if value ~= self.PrevOutput then
		self:SetOverlayText( "Color = " .. string.format("%.1f", (value * 100)) .. "%" )
		self.PrevOutput = value
	end
end

duplicator.RegisterEntityClass("gmod_wire_indicator", WireLib.MakeWireEnt, "Data", "a", "ar", "ag", "ab", "aa", "b", "br", "bg", "bb", "ba")

function MakeWire7Seg( pl, Pos, Ang, Model, a, ar, ag, ab, aa, b, br, bg, bb, ba)
	if IsValid(pl) and not pl:CheckLimit( "wire_indicators" ) then return false end

	local function MakeWireIndicator(prototype, scale)
		local name, angOffset, posOffset = unpack(prototype)
		posOffset = Vector(0, posOffset.x, -posOffset.y)
		local Pos, Ang  = LocalToWorld(posOffset * scale, Angle(), Pos, Ang), Ang + angOffset
		local ent = WireLib.MakeWireEnt(pl,
		{ Class = "gmod_wire_indicator",
		Pos = Pos, Angle = Ang,
		Model = Model, frozen = frozen, nocollide = nocollide },
		a, ar, ag, ab, aa, b, br, bg, bb, ba )
		if IsValid(ent) then 
			ent:SetNWString("WireName", name) 
			duplicator.StoreEntityModifier( ent, "WireName", { name = name } )
		end
		return ent
	end


	local prototypes = {
		{ "G", Angle(0, 0, 0), Vector(0, 0) },
		{ "A", Angle(0, 0, 0), Vector(0, 2) },
		{ "B", Angle(0, 0, 90), Vector(1, 1) },
		{ "C", Angle(0, 0, 90), Vector(1, -1) },
		{ "D", Angle(0, 0, 0), Vector(0, -2) },
		{ "E", Angle(0, 0, 90), Vector(-1, -1) },
		{ "F", Angle(0, 0, 90), Vector(-1, 1) }
	}

	local wire_indicators = {}
	wire_indicators[1] = MakeWireIndicator( prototypes[1], 0 )

	-- get the scale (half the long side of the indicator) from the first one
	local scale = wire_indicators[1]:OBBMaxs().y

	for i = 2, 7 do
		wire_indicators[i] = MakeWireIndicator( prototypes[i], scale )
		if not IsValid( wire_indicators[i] ) then break end

		for y = 1, i-1 do
			const = constraint.Weld( wire_indicators[i], wire_indicators[y], 0, 0, 0, true, true )
		end
		wire_indicators[i - 1]:DeleteOnRemove( wire_indicators[i] ) --when one is removed, all are. a linked chain
	end
	
	if wire_indicators[7] then
		wire_indicators[7]:DeleteOnRemove( wire_indicators[1] ) --loops chain back to first
	end

	return wire_indicators
end
