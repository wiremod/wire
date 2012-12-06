AddCSLuaFile()
DEFINE_BASECLASS( "base_wire_entity" )
ENT.PrintName		= "Wire Trail"
ENT.WireDebugName 	= "Trail"
ENT.RenderGroup		= RENDERGROUP_BOTH

if CLIENT then return end -- No more client

function ENT:Initialize()
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )
	self.Inputs = Wire_CreateInputs(self, {"Set", "Length","StartSize","EndSize","R","G","B","A"})
	self.Outputs = Wire_CreateOutputs(self, {})
	self.R = 0
	self.G = 0
	self.B = 0
	self.A = 0
	self.Length = 0
	self.StartSize = 0
	self.EndSize = 0
	self.Material = ""
end

function ENT:Setup(Material)
	self.Material = Material
	self.mat = Material
end

function ENT:SetTrails( Player, Entity, Data )

	if ( Entity.SToolTrail ) then
		Entity.SToolTrail:Remove()
	end

	if ( Data.StartSize == 0 ) then

		Data.StartSize = 0.0001;

	end

	local trail_entity = util.SpriteTrail( Entity,  //Entity
											0,  //iAttachmentID
											Data.Color,  //Color
											false, // bAdditive
											Data.StartSize, //fStartWidth
											Data.EndSize, //fEndWidth
											Data.Length, //fLifetime
											1 / ((Data.StartSize+Data.EndSize) * 0.5), //fTextureRes
											Data.Material .. ".vmt" ) //strTexture

	Entity.SToolTrail = trail_entity
end

function ENT:TriggerInput(iname, value)
	if (iname == "Set") then
		if (value ~= 0) then
			self:SetTrails( self:GetOwner(), self, {
		  		Color = Color( self.R, self.G, self.B, self.A ),
				Length = self.Length,
				StartSize = self.StartSize,
				EndSize = self.EndSize,
				Material = self.Material
			})
		end
	elseif(iname == "Length")then
		self.Length = value
	elseif(iname == "StartSize")then
		self.StartSize = value
	elseif(iname == "EndSize")then
		self.EndSize = value
	elseif(iname == "R")then
		self.R = value
	elseif(iname == "G")then
		self.G = value
	elseif(iname == "B")then
		self.B = value
	elseif(iname == "A")then
		self.A = value
	end
end

function MakeWireTrail( pl, Pos, Ang, model, mat)
	if not pl:CheckLimit( "wire_trails" ) then return false end

	local wire_trail = ents.Create( "gmod_wire_trail" )
	if not wire_trail:IsValid() then return false end

	wire_trail:SetAngles( Ang )
	wire_trail:SetPos( Pos )
	wire_trail:SetModel( Model(model or "models/jaanus/wiretool/wiretool_range.mdl") )
	wire_trail:Spawn()
	wire_trail:Setup(mat)

	wire_trail:SetPlayer( pl )
	wire_trail.pl = pl

	pl:AddCount( "wire_trails", wire_trail )

	return wire_trail
end
duplicator.RegisterEntityClass("gmod_wire_trail", MakeWireTrail, "Pos", "Ang", "Model", "mat")
