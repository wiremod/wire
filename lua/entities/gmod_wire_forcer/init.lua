
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "Forcer"
ENT.OverlayDelay = .05


function ENT:Initialize()
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )

	self.F = 0
	self.FoO = 0
	self.V = 0

	self.Inputs = Wire_CreateInputs(self.Entity, { "Force", "OffsetForce", "Velocity" })
	self:SetForceBeam(false)
end

function ENT:Setup(force, length, showbeam, reaction)
	self.Force = math.max(force, 1)
	self.Tlength = math.max(length, 1)
	self.F = 0
	self.FoO = 0
	self.V = 0
	if showbeam then
		self:SetBeamLength(length)
	else
		self:SetBeamLength(0)
	end
	self.Reaction = reaction
	self:TriggerInput("Force", 0)
end

function ENT:TriggerInput(iname, value)
	if iname == "Force" then
		self.F = value
		self:SetForceBeam(self.F != 0)
		self:ShowOutput()
	elseif iname == "OffsetForce" then
		self.FoO = value
		self:ShowOutput()
	elseif iname == "Velocity" then
		self.V = math.max(math.min(100000,value),-100000)
		self:SetForceBeam(self.V != 0)
		self:ShowOutput()
	end
end

local function clamp_length(vector)
	local length = vector:length()
	if length > 100000 then return vector / length * 100000 end
	return vector
end

function ENT:Think()
	if self.F > 0.1 or self.FoO > 0.1 or self.V > 0.1 or self.F < -0.1 or self.FoO < -0.1 or self.V < -0.1 then
		local vForward = self.Entity:GetUp()
		local vStart = self.Entity:GetPos() + vForward*self.Entity:OBBMaxs().z

		local trace = {}
		trace.start = vStart
		trace.endpos = vStart + (vForward * self.Tlength)
		trace.filter = { self.Entity }

		local trace = util.TraceLine( trace )

		if trace.Entity and trace.Entity:IsValid() then
			if trace.Entity:GetMoveType() == MOVETYPE_VPHYSICS then
				local phys = trace.Entity:GetPhysicsObject()
				if phys:IsValid() then
					if self.F > 0.1 or self.F < -0.1 then phys:ApplyForceCenter( vForward * self.Force * self.F ) end
					if self.FoO > 0.1 or self.FoO < -0.1 then phys:ApplyForceOffset( vForward * self.FoO, trace.HitPos ) end
					--if self.V > 0.1 or self.V < -0.1 then phys:SetVelocity( vForward * self.V ) end
					if self.V > 0.1 or self.V < -0.1 then phys:SetVelocityInstantaneous( vForward * self.V ) end
				end
				if self.Reaction then
					phys = self.Entity:GetPhysicsObject()
					if (phys:IsValid()) then
						if self.F > 0.1 or self.F < -0.1 then phys:ApplyForceCenter( vForward * -self.Force * self.F ) end
						if self.FoO > 0.1 or self.FoO < -0.1 then phys:ApplyForceCenter( vForward * -self.FoO ) end
					end
				end
			else
				if self.V > 0.1 or self.V < -0.1 then trace.Entity:SetVelocity( vForward * self.V ) end
			end
		end
	end

	self.Entity:NextThink(CurTime() + 0.1)
	return true
end

function ENT:ShowOutput()
	self:SetOverlayText(
		"Forcer\nCenter Force= "..tostring(math.Round(self.F * self.Force))..
		"\nOffset Force= "..tostring(math.Round(self.FoO))..
		"\nVelocity= "..tostring(math.Round(self.V))
	)
end

function ENT:ApplyDupeInfo(ply, ent, info, GetEntByID)
	--Moves old "A" input to new "Force" input for older saves
	if info.Wires and info.Wires.A then
		info.Wires.Force = info.Wires.A
		info.Wires.A = nil
	end

	self.BaseClass.ApplyDupeInfo(self, ply, ent, info, GetEntByID)
end


function MakeWireForcer( pl, Pos, Ang, model, Force, Length, showbeam, reaction )
	if not pl:CheckLimit( "wire_forcers" ) then return false end

	local wire_forcer = ents.Create( "gmod_wire_forcer" )
	if not wire_forcer:IsValid() then return false end

	wire_forcer:SetAngles( Ang )
	wire_forcer:SetPos( Pos )
	wire_forcer:SetModel( model )
	wire_forcer:Spawn()

	wire_forcer:Setup(Force, Length, showbeam, reaction)
	wire_forcer:SetPlayer( pl )

	local ttable = {
		pl		= pl,
		Force	= Force,
		Length	= Length,
		showbeam = showbeam,
		reaction = reaction,
	}
	table.Merge(wire_forcer:GetTable(), ttable )

	pl:AddCount( "wire_forcers", wire_forcer )

	return wire_forcer
end

duplicator.RegisterEntityClass("gmod_wire_forcer", MakeWireForcer, "Pos", "Ang", "Model", "Force", "Length", "showbeam", "reaction")

