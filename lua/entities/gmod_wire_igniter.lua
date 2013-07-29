AddCSLuaFile()
DEFINE_BASECLASS( "base_wire_entity" )
ENT.PrintName       = "Wire Igniter"
ENT.RenderGroup		= RENDERGROUP_BOTH
ENT.WireDebugName	= "Igniter"


-- Shared

function ENT:SetupDataTables()
	self:NetworkVar( "Float", 0, "BeamLength" )
end

if CLIENT then return end -- No more client

function ENT:Initialize()
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )
	self.Inputs = Wire_CreateInputs(self, { "A", "Length" })
	self.IgniteLength = 10
	self:Setup(false, 2048)
end

function ENT:Setup(trgply,Range)
	self.TargetPlayers = trgply
	if Range then self:SetBeamLength(Range) end
end

function ENT:TriggerInput(iname, value)
	if (iname == "A") then
		if (value ~= 0) then
			local vStart = self:GetPos()
			local vForward = self:GetUp()

			local trace = {}
				trace.start = vStart
				trace.endpos = vStart + (vForward * self:GetBeamLength())
				trace.filter = { self }
			local trace = util.TraceLine( trace )

			local svarTargetPlayers = GetConVarNumber('sbox_wire_igniters_allowtrgply') > 0

			if not IsValid(trace.Entity) then return false end
			if (trace.Entity:IsPlayer() && (!self.TargetPlayers || !svarTargetPlayers)) then return false end
			if (trace.Entity:IsWorld()) then return false end
			
			trace.Entity:Extinguish()
			trace.Entity:Ignite( self.IgniteLength, 0 )
		end
	else
		if(iname == "Length") then
			self.IgniteLength = math.min(value,GetConVarNumber("sbox_wire_igniters_maxlen"))
		end
	end
end

function MakeWireIgniter( pl, Pos, Ang, model, TargetPlayers, Range )
	if not pl:CheckLimit( "wire_igniters" ) then return false end

	local wire_igniter = ents.Create( "gmod_wire_igniter" )
	if not wire_igniter:IsValid() then return false end

	wire_igniter:SetAngles( Ang )
	wire_igniter:SetPos( Pos )
	wire_igniter:SetModel( model )
	wire_igniter:Spawn()
	wire_igniter:Setup(TargetPlayers,Range)

	wire_igniter:SetPlayer( pl )

	pl:AddCount( "wire_igniters", wire_igniter )

	return wire_igniter
end
duplicator.RegisterEntityClass("gmod_wire_igniter", MakeWireIgniter, "Pos", "Ang", "Model", "TargetPlayers", "Range")
