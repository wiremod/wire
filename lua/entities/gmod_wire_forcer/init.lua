
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "Forcer"
ENT.OverlayDelay = .05


function ENT:Initialize()
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )

	self.ForceInput = 0
	self.OffsetForce = 0
	self.Velocity = 0

	self.Inputs = Wire_CreateInputs(self.Entity, { "Force", "OffsetForce", "Velocity" })
	self:SetForceBeam(false)
end

function ENT:Setup(Force, Length, showbeam, reaction)
	self.Force = math.max(Force, 1)
	self.Length = math.max(Length, 1)
	self.ForceInput = 0
	self.OffsetForce = 0
	self.Velocity = 0
	self.showbeam = showbeam
	if showbeam then
		self:SetBeamLength(Length)
	else
		self:SetBeamLength(0)
	end
	self.reaction = reaction
	self:TriggerInput("Force", 0)
end

function ENT:TriggerInput(iname, value)
	if iname == "Force" then
		self.ForceInput = value
		self:SetForceBeam(self.ForceInput != 0)
		self:ShowOutput()
	elseif iname == "OffsetForce" then
		self.OffsetForce = value
		self:ShowOutput()
	elseif iname == "Velocity" then
		self.Velocity = math.max(math.min(100000,value),-100000)
		self:SetForceBeam(self.Velocity != 0)
		self:ShowOutput()
	end
end

local function clamp_length(vector)
	local length = vector:length()
	if length > 100000 then return vector / length * 100000 end
	return vector
end

function ENT:Think()
	if self.ForceInput > 0.1 or self.OffsetForce > 0.1 or self.Velocity > 0.1 or self.ForceInput < -0.1 or self.OffsetForce < -0.1 or self.Velocity < -0.1 then
		local vForward = self.Entity:GetUp()
		local vStart = self.Entity:GetPos() + vForward*self.Entity:OBBMaxs().z

		local trace = {}
		trace.start = vStart
		trace.endpos = vStart + (vForward * self.Length)
		trace.filter = { self.Entity }

		local trace = util.TraceLine( trace )

		if trace.Entity and trace.Entity:IsValid() then
			if trace.Entity:GetMoveType() == MOVETYPE_VPHYSICS then
				local phys = trace.Entity:GetPhysicsObject()
				if phys:IsValid() then
					if self.ForceInput > 0.1 or self.ForceInput < -0.1 then phys:ApplyForceCenter( vForward * self.Force * self.ForceInput ) end
					if self.OffsetForce > 0.1 or self.OffsetForce < -0.1 then phys:ApplyForceOffset( vForward * self.OffsetForce, trace.HitPos ) end
					--if self.Velocity > 0.1 or self.Velocity < -0.1 then phys:SetVelocity( vForward * self.Velocity ) end
					if self.Velocity > 0.1 or self.Velocity < -0.1 then phys:SetVelocityInstantaneous( vForward * self.Velocity ) end
				end
			else
				if self.Velocity > 0.1 or self.Velocity < -0.1 then trace.Entity:SetVelocity( vForward * self.Velocity ) end
			end
		end
		if self.reaction then
			local phys = self.Entity:GetPhysicsObject()
			if (phys:IsValid()) then
				if self.ForceInput > 0.1 or self.ForceInput < -0.1 then phys:ApplyForceCenter( vForward * -self.Force * self.ForceInput ) end
				if self.OffsetForce > 0.1 or self.OffsetForce < -0.1 then phys:ApplyForceCenter( vForward * -self.OffsetForce ) end
			end
		end
	end

	self.Entity:NextThink(CurTime() + 0.1)
	return true
end

function ENT:ShowOutput()
	self:SetOverlayText(
		"Forcer"..
		"\nCenter Force= "..tostring(math.Round(self.ForceInput * self.Force))..
		"\nOffset Force= "..tostring(math.Round(self.OffsetForce))..
		"\nVelocity= "..tostring(math.Round(self.Velocity))
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
	wire_forcer.pl = pl

	pl:AddCount( "wire_forcers", wire_forcer )

	return wire_forcer
end

duplicator.RegisterEntityClass("gmod_wire_forcer", MakeWireForcer, "Pos", "Ang", "Model", "Force", "Length", "showbeam", "reaction")

