AddCSLuaFile()
DEFINE_BASECLASS( "base_wire_entity" )
ENT.PrintName       = "Wire Pixel"
ENT.WireDebugName	= "Pixel"

if CLIENT then
	function ENT:Draw()
		self:DrawModel()
	end

	return  -- No more client
end

function ENT:Initialize()
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )

	self.R, self.G, self.B = 0, 0, 0
	self.Inputs = WireLib.CreateInputs( self, { "Red", "Green", "Blue", "PackedRGB", "RGB", "Color [VECTOR]" } )
end

function ENT:TriggerInput(iname, value)
	local R,G,B = self.R, self.G, self.B
	if (iname == "Red") then
		R = value
	elseif (iname == "Green") then
		G = value
	elseif (iname == "Blue") then
		B = value
	elseif (iname == "PackedRGB") then
		B = value % 256
		G = ( value / 256 ) % 256
		R = ( value / ( 256 * 256 ) ) % 256
	elseif (iname == "RGB") then
		local crgb = math.floor( value / 1000 )
		local cgray = value - math.floor( value / 1000 ) * 1000
		local cb = 24 * math.fmod( crgb, 10 )
		local cg = 24 * math.fmod( math.floor( crgb / 10 ), 10 )
		local cr = 24 * math.fmod( math.floor( crgb / 100 ), 10 )
		B = cgray + cb
		G = cgray + cg
		R = cgray + cr
	elseif (iname == "Color") then
		R = value.r
		G = value.g
		B = value.b
	end
	self:ShowOutput( math.floor( R ), math.floor( G ), math.floor( B ) )
end

function ENT:Setup()
	self:ShowOutput( 0, 0, 0 )
end

function ENT:ShowOutput( R, G, B )
	if ( R ~= self.R or G ~= self.G or B ~= self.B ) then
		self.R, self.G, self.B = R, G, B
		self:SetColor(Color(R, G, B, 255))
	end
end

duplicator.RegisterEntityClass("gmod_wire_pixel", WireLib.MakeWireEnt, "Data")
