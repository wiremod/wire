
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "Indicator"

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

function ENT:Setup(a, ar, ag, ab, aa, b, br, bg, bb, ba, material)
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
	self:SetMaterial( material )

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


function MakeWireIndicator( pl, Pos, Ang, model, a, ar, ag, ab, aa, b, br, bg, bb, ba, material, nocollide, frozen )
	if not pl:CheckLimit( "wire_indicators" ) then return false end

	local wire_indicator = ents.Create( "gmod_wire_indicator" )
	if not wire_indicator:IsValid() then return false end

	wire_indicator:SetModel( model )
	wire_indicator:SetAngles( Ang )
	wire_indicator:SetPos( Pos )
	wire_indicator:Spawn()

	wire_indicator:Setup(a, ar, ag, ab, aa, b, br, bg, bb, ba, material)
	wire_indicator:SetPlayer(pl)

	if wire_indicator:GetPhysicsObject():IsValid() then
		wire_indicator:GetPhysicsObject():EnableMotion(!frozen)
	end
	if nocollide == true then
		wire_indicator:SetCollisionGroup(COLLISION_GROUP_WORLD)
	end

	local ttable = {
		material = material,
		pl	= pl,
		nocollide = nocollide
	}
	table.Merge(wire_indicator:GetTable(), ttable )

	pl:AddCount( "wire_indicators", wire_indicator )

	return wire_indicator
end

duplicator.RegisterEntityClass("gmod_wire_indicator", MakeWireIndicator, "Pos", "Ang", "Model", "a", "ar", "ag", "ab", "aa", "b", "br", "bg", "bb", "ba", "material", "nocollide", "frozen")

function MakeWire7Seg( pl, Pos, Ang, Model, a, ar, ag, ab, aa, b, br, bg, bb, ba, nocollide, Vel, aVel, frozen  )

	if not pl:CheckLimit( "wire_indicators" ) then return false end

	local wire_indicators = {}

	Ang = Ang - Angle(90, 0, 0)

	--make the center one first so we can get use its OBBMins/OBBMaxs
	wire_indicators[1] = ents.Create( "gmod_wire_indicator" )
	if not wire_indicators[1]:IsValid() then return false end
	wire_indicators[1]:SetModel( Model )
	wire_indicators[1]:SetAngles( Ang + Angle(90, 0, 0) )
	wire_indicators[1]:SetPos( Pos )
	wire_indicators[1]:Spawn()
	wire_indicators[1]:Setup(a, ar, ag, ab, aa, b, br, bg, bb, ba)
	wire_indicators[1]:SetPlayer(pl)
	wire_indicators[1]:SetNetworkedString("WireName", "G")
	pl:AddCount( "wire_indicators", wire_indicators[1] )
	local min = wire_indicators[1]:OBBMins(wire_indicators[1])
	//Pos = Pos - Ang:Up() * min.x --correct Pos for thichness of segment
	wire_indicators[1]:SetPos( Pos + Ang:Up() )

	if wire_indicators[1]:GetPhysicsObject():IsValid() then
		wire_indicators[1]:GetPhysicsObject():EnableMotion(!frozen)
	end
	if nocollide == true then
		wire_indicators[1]:SetCollisionGroup(COLLISION_GROUP_WORLD)
	end

	local ttable = {
		pl	= pl,
		nocollide = nocollide
	}
	table.Merge(wire_indicators[1]:GetTable(), ttable )

	local max = wire_indicators[1]:OBBMaxs(wire_indicators[1])

	local angles = {Angle( 90, 0, 90 ), Angle( 90, 0, 90 ), Angle( 90, 0, 90 ), Angle( 90, 0, 90 ), Angle( 90, 0, 0 ), Angle( 90, 0, 0 )}
	local vectors = {Vector( 1, (-1 * max.y), max.y ), Vector( 1, (-1 * max.y), (-1 * max.y) ), Vector( 1, max.y, max.y ), Vector( 1, max.y, (-1 * max.y) ), Vector( 1, 0, (2 * max.y) ), Vector( 1, 0, (-2 * max.y) ) }
	local segname = {"B", "C", "F", "E", "A", "D"}

	for x=2, 7 do
		wire_indicators[x] = ents.Create( "gmod_wire_indicator" )
		if (!wire_indicators[x]:IsValid()) then return false end
		wire_indicators[x]:SetModel( Model )
		wire_indicators[x]:SetPos( Pos + Ang:Up() * vectors[x-1].X + Ang:Forward() * -1 * vectors[x-1].Z + Ang:Right() * vectors[x-1].Y )
		wire_indicators[x]:SetAngles( Ang + angles[x-1] )
		wire_indicators[x]:Spawn()
		wire_indicators[x]:Setup(cmin, ar, ag, ab, aa, cmax, br, bg, bb, ba)
		wire_indicators[x]:SetPlayer(pl)
		wire_indicators[x]:SetNetworkedString("WireName", segname[x-1])
		if wire_indicators[x]:GetPhysicsObject():IsValid() then
			wire_indicators[x]:GetPhysicsObject():EnableMotion(!frozen)
		end
		if nocollide == true then
			wire_indicators[x]:SetCollisionGroup(COLLISION_GROUP_WORLD)
		end
		table.Merge(wire_indicators[x]:GetTable(), ttable )
		pl:AddCount( "wire_indicators", wire_indicators[x] )

		--weld this segment to eveyone before it
		for y=1,x do
			const = constraint.Weld( wire_indicators[x], wire_indicators[y], 0, 0, 0, true, true )
		end
		wire_indicators[x-1]:DeleteOnRemove( wire_indicators[x] ) --when one is removed, all are. a linked chain
	end
	wire_indicators[7]:DeleteOnRemove( wire_indicators[1] ) --loops chain back to first

	return wire_indicators
end

