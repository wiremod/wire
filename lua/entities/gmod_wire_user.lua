AddCSLuaFile()
DEFINE_BASECLASS( "base_wire_entity" )
ENT.PrintName       = "Wire User"
ENT.RenderGroup		= RENDERGROUP_BOTH
ENT.WireDebugName	= "User"


-- Shared

function ENT:SetBeamLength(length)
	self:SetNetworkedFloat("BeamLength", length)
end

function ENT:GetBeamLength()
	return self:GetNetworkedFloat("BeamLength") or 0
end

if CLIENT then return end -- No more client

function ENT:Initialize()
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )
	self.Inputs = Wire_CreateInputs(self, { "Fire"})
	self:Setup(2048)
end

function ENT:Setup(Range)
	self:SetBeamLength(Range)
	self.Range = Range
end

function ENT:TriggerInput(iname, value)
	if (iname == "Fire") then
		if (value ~= 0) then
			local vStart = self:GetPos()

			local trace = util.TraceLine( {
				start = vStart,
				endpos = vStart + (self:GetUp() * self:GetBeamLength()),
				filter = { self },
			})

			if not IsValid(trace.Entity) then return false end
			local ply = self:GetPlayer()
			if not IsValid(ply) then ply = self end
			
			if trace.Entity.Use then
				trace.Entity:Use(ply,ply,USE_ON,0)
			else
				trace.Entity:Fire("use","1",0)
			end
		end
	end
end

function MakeWireUser( pl, Pos, Ang, model, Range )
	if ( !pl:CheckLimit( "wire_users" ) ) then return false end

	local wire_user = ents.Create( "gmod_wire_user" )
	if (!wire_user:IsValid()) then return false end

	wire_user:SetAngles( Ang )
	wire_user:SetPos( Pos )
	wire_user:SetModel( Model(model) )
	wire_user:Spawn()
	wire_user:Setup(Range)
	wire_user:SetPlayer( pl )
	wire_user.pl = pl

	pl:AddCount( "wire_users", wire_user )

	return wire_user
end
duplicator.RegisterEntityClass("gmod_wire_user", MakeWireUser, "Pos", "Ang", "Model", "Range")
