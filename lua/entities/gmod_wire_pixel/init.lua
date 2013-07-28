
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "Pixel"

function ENT:Initialize()
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )

	self.R, self.G, self.B = 0, 0, 0
	self.Inputs = Wire_CreateInputs( self, { "Red", "Green", "Blue", "PackedRGB", "RGB" } )
end

function ENT:Think( )
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


function MakeWirePixel( pl, Pos, Ang, model, nocollide)
	if ( !pl:CheckLimit( "wire_pixels" ) ) then return false end

	local wire_pixel = ents.Create( "gmod_wire_pixel" )
	if (!wire_pixel:IsValid()) then return false end

	wire_pixel:SetModel( model )
	wire_pixel:SetAngles( Ang )
	wire_pixel:SetPos( Pos )
	wire_pixel:Spawn()

	wire_pixel:Setup()
	wire_pixel:SetPlayer(pl)

	if ( nocollide == true ) then wire_pixel:SetCollisionGroup(COLLISION_GROUP_WORLD) end

	local ttable = {
		pl	= pl,
		nocollide = nocollide
	}
	table.Merge(wire_pixel:GetTable(), ttable )

	pl:AddCount( "wire_pixels", wire_pixel )

	return wire_pixel
end

duplicator.RegisterEntityClass("gmod_wire_pixel", MakeWirePixel, "Pos", "Ang", "Model", "nocollide")
