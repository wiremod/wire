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
	
	self.Trail = {
		Color = Color(255, 255, 255, 255),
		Length = 5,
		StartSize = 32,
		EndSize = 0,
		Material = "trails/lol"
	}
end

function ENT:Setup(Trail)
	self.Trail = table.Merge(self.Trail, Trail)
end

function ENT:TriggerInput(iname, value)
	if iname == "Set" and value ~= 0 then
		duplicator.EntityModifiers.trail(self:GetOwner(), self, self.Trail)
	elseif iname == "Length" then
		self.Trail.Length = value
	elseif iname == "StartSize" then
		self.Trail.StartSize = value
	elseif iname == "EndSize" then
		self.Trail.EndSize = value
	elseif iname == "R" then
		self.Trail.Color.r = value
	elseif iname == "G" then
		self.Trail.Color.g = value
	elseif iname == "B" then
		self.Trail.Color.b = value
	elseif iname == "A" then
		self.Trail.Color.a = value
	end
end

function MakeWireTrail( pl, Pos, Ang, model, Trail)
	if not pl:CheckLimit( "wire_trails" ) then return false end

	local wire_trail = ents.Create( "gmod_wire_trail" )
	if not wire_trail:IsValid() then return false end

	wire_trail:SetAngles( Ang )
	wire_trail:SetPos( Pos )
	wire_trail:SetModel( Model(model or "models/jaanus/wiretool/wiretool_range.mdl") )
	wire_trail:Spawn()
	wire_trail:Setup(Trail)

	wire_trail:SetPlayer( pl )
	wire_trail.pl = pl

	pl:AddCount( "wire_trails", wire_trail )

	return wire_trail
end
duplicator.RegisterEntityClass("gmod_wire_trail", MakeWireTrail, "Pos", "Ang", "Model", "Trail")
