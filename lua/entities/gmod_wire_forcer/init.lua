AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include('shared.lua')

ENT.WireDebugName = "Forcer"

function ENT:Initialize()
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )

	self.ForceMul = 0
	self.Force = 0
	self.OffsetForce = 0
	self.Velocity = 0
	self.Length = 100
	self.Reaction = false
	self.ShowBeam = true

	self.Inputs = WireLib.CreateInputs( self, { "Force", "OffsetForce", "Velocity", "Length" } )

	self:SetNWBool("ShowBeam",false)
	self:SetNWBool("ShowForceBeam",false)
	self:SetBeamLength(100)
	self:ShowOutput()
end

function ENT:Setup( Force, Length, ShowBeam, Reaction )
	self.ForceMul = Force or 1
	self.Length = math.max(Length or 100,1)
	self.Reaction = Reaction or false
	self:SetNWBool("ShowBeam",ShowBeam)
	self.ShowBeam = ShowBeam or true
	self:SetBeamLength(math.Round(Length or 100))
	self:ShowOutput()
end

function ENT:TriggerInput( name, value )
	if (name == "Force") then
		self.Force = value
		self:SetForceBeam(value != 0)
		self:ShowOutput()
	elseif (name == "OffsetForce") then
		self.OffsetForce = value
		self:SetForceBeam(value != 0)
		self:ShowOutput()
	elseif (name == "Velocity") then
		self.Velocity = math.Clamp(value,-100000,100000)
		self:SetForceBeam(value != 0)
		self:ShowOutput()
	elseif (name == "Length") then
		self.Length = value
		self:SetBeamLength(math.Round(value))
		self:ShowOutput()
	end
end

function ENT:Think()
	if (self.Force != 0 or self.OffsetForce != 0 or self.Velocity != 0) then
		local Forward = self:GetUp()
		local StartPos = self:GetPos() + Forward * self:OBBMaxs().z

		local tr = {}
		tr.start = StartPos
		tr.endpos = StartPos + self.Length * Forward
		tr.filter = self
		local trace = util.TraceLine( tr )
		if (trace) then
			if (trace.Entity and trace.Entity:IsValid()) then
				if (trace.Entity:GetMoveType() == MOVETYPE_VPHYSICS) then
					local phys = trace.Entity:GetPhysicsObject()
					if (phys:IsValid()) then
						if (self.Force != 0) then phys:ApplyForceCenter( Forward * self.Force * self.ForceMul ) end
						if (self.OffsetForce != 0) then phys:ApplyForceOffset( Forward * self.OffsetForce * self.ForceMul, trace.HitPos ) end
						if (self.Velocity != 0) then phys:SetVelocityInstantaneous( Forward * self.Velocity ) end
					end
				else
					if (self.Velocity != 0) then trace.Entity:SetVelocity( Forward * self.Velocity ) end
				end
			end
		end

		if (self.Reaction) then
			local phys = self:GetPhysicsObject()
			if (phys:IsValid()) then
				if (self.Force != 0 or self.OffsetForce != 0) then phys:ApplyForceCenter( Forward * -self.Force * self.ForceMul ) end
			end
		end
	end
	self:NextThink( CurTime() )
	return true
end

function ENT:ShowOutput()
	self:SetOverlayText(
		"Center Force = "..math.Round(self.ForceMul * self.Force)..
		"\nOffset Force = "..math.Round(self.ForceMul * self.OffsetForce)..
		"\nVelocity = "..math.Round(self.Velocity)..
		"\nLength = " .. math.Round(self.Length)
	)
end

function ENT:BuildDupeInfo()
	local info = self.BaseClass.BuildDupeInfo(self) or {}
	info.ForceMul = self.ForceMul
	info.ShowBeam = self.ShowBeam
	info.Reaction = self.Reaction
	info.Length = self.Length
	return info
end


function ENT:ApplyDupeInfo(ply, ent, info, GetEntByID)
	--Moves old "A" input to new "Force" input for older saves
	if info.Wires and info.Wires.A then
		info.Wires.Force = info.Wires.A
		info.Wires.A = nil
	end

	self:Setup( info.ForceMul, info.Length, info.ShowBeam, info.Reaction )

	self.BaseClass.ApplyDupeInfo(self, ply, ent, info, GetEntByID)
end


function MakeWireForcer( pl, Pos, Ang, model, Force, Length, ShowBeam, Reaction )
	if not pl:CheckLimit( "wire_forcers" ) then return false end

	local wire_forcer = ents.Create( "gmod_wire_forcer" )
	if not wire_forcer:IsValid() then return false end

	wire_forcer:SetAngles( Ang )
	wire_forcer:SetPos( Pos )
	wire_forcer:SetModel( model )
	wire_forcer:Spawn()

	wire_forcer:Setup(Force, Length, ShowBeam, Reaction)
	wire_forcer:SetPlayer( pl )
	wire_forcer.pl = pl

	pl:AddCount( "wire_forcers", wire_forcer )

	return wire_forcer
end

duplicator.RegisterEntityClass("gmod_wire_forcer", MakeWireForcer, "Pos", "Ang", "Model", "Force", "Length", "ShowBeam", "Reaction")
