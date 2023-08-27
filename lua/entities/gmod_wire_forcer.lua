AddCSLuaFile()
DEFINE_BASECLASS( "base_wire_entity" )
ENT.PrintName       = "Wire Forcer"
ENT.RenderGroup		= RENDERGROUP_BOTH
ENT.WireDebugName	= "Forcer"

function ENT:SetupDataTables()
	self:NetworkVar( "Float", 0, "BeamLength" )
	self:NetworkVar( "Bool",  0, "ShowBeam" )
	self:NetworkVar( "Bool",  1, "BeamHighlight" )
end

if CLIENT then return end -- No more client

local wire_forcer_permissions = CreateConVar( "wire_forcer_permissions", 1, FCVAR_ARCHIVE, "0 = no check for forcers, 1 = GravGunPunt, 2 = GravGunPickupAllowed", 0, 2)

function ENT:Initialize()
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )

	self.Force = 0
	self.OffsetForce = 0
	self.Velocity = 0

	self.Inputs = WireLib.CreateInputs( self, { "Force", "OffsetForce", "Velocity", "Length" } )

	self:Setup(0, 100, true, false)
end

function ENT:Setup( Force, Length, ShowBeam, Reaction )
	self.ForceMul = Force or 1
	self.Reaction = Reaction or false
	if Length then self:SetBeamLength(Length) end
	if ShowBeam ~= nil then self:SetShowBeam(ShowBeam) end
	self:ShowOutput()
end

function ENT:TriggerInput( name, value )
	if (name == "Force") then
		self.Force = value
		self:SetBeamHighlight(value ~= 0)
		self:ShowOutput()
	elseif (name == "OffsetForce") then
		self.OffsetForce = value
		self:SetBeamHighlight(value ~= 0)
		self:ShowOutput()
	elseif (name == "Velocity") then
		self.Velocity = math.Clamp(value,-100000,100000)
		self:SetBeamHighlight(value ~= 0)
		self:ShowOutput()
	elseif (name == "Length") then
		self:SetBeamLength(math.Round(value))
		self:ShowOutput()
	end
end

local clamp = WireLib.clampForce

function ENT:Think()
	if self.Force == 0 and self.OffsetForce == 0 and self.Velocity == 0 then return end

	local Forward = self:GetUp()
	local BeamOrigin = self:GetPos() + Forward * self:OBBMaxs().z

	local trace = util.TraceLine {
		start = BeamOrigin,
		endpos = BeamOrigin + self:GetBeamLength() * Forward,
		filter = self
	}
	local ent = trace.Entity

	if not IsValid(ent) then return end

	if ent:GetMoveType() == MOVETYPE_PUSH then return end

	local convar_value = wire_forcer_permissions:GetInt()
	if convar_value==1 then
		if not IsValid(self:GetPlayer()) or gamemode.Call( "GravGunPunt", self:GetPlayer(), ent )==false then return end
	elseif convar_value==2 then
		if not IsValid(self:GetPlayer()) or gamemode.Call( "GravGunPickupAllowed", self:GetPlayer(), ent )==false then return end
	end

	if hook.Run( "Wire_ForcerCanUse", self:GetPlayer(), ent, self ) == false then return end

	if ent:GetMoveType() == MOVETYPE_VPHYSICS then
		local phys = ent:GetPhysicsObject()
		if not IsValid(phys) then return end

		local force = clamp(Forward * self.Force * self.ForceMul)
		local offsetForce = clamp(Forward * self.OffsetForce * self.ForceMul)
		local velocity = clamp(Forward * self.Velocity)

		if self.Force ~= 0 then phys:ApplyForceCenter( force ) end
		if self.OffsetForce ~= 0 then phys:ApplyForceOffset( offsetForce, trace.HitPos ) end
		if self.Velocity ~= 0 then phys:SetVelocityInstantaneous( velocity ) end
	else
		local velocity = clamp(Forward * self.Velocity)
		if self.Velocity ~= 0 then ent:SetVelocity( velocity ) end
	end

	if self.Reaction and IsValid(self:GetPhysicsObject()) and (self.Force + self.OffsetForce ~= 0) then
		local reactionForce = clamp(Forward * -(self.Force + self.OffsetForce) * self.ForceMul)
		self:GetPhysicsObject():ApplyForceCenter( reactionForce )
	end

	self:NextThink( CurTime() )
	return true
end

function ENT:ShowOutput()
	self:SetOverlayText(
		"Center Force = "..math.Round(self.ForceMul * self.Force)..
		"\nOffset Force = "..math.Round(self.ForceMul * self.OffsetForce)..
		"\nVelocity = "..math.Round(self.Velocity)..
		"\nLength = " .. math.Round(self:GetBeamLength())
	)
end

function ENT:BuildDupeInfo()
	local info = BaseClass.BuildDupeInfo(self) or {}
	info.ForceMul = self.ForceMul
	info.Reaction = self.Reaction
	return info
end


function ENT:ApplyDupeInfo(ply, ent, info, GetEntByID)
	self:Setup( info.ForceMul, info.Length, info.ShowBeam, info.Reaction )

	BaseClass.ApplyDupeInfo(self, ply, ent, info, GetEntByID)
end

--Moves old "A" input to new "Force" input for older saves
WireLib.AddInputAlias( "A", "Force" )

duplicator.RegisterEntityClass("gmod_wire_forcer", WireLib.MakeWireEnt, "Data", "Force", "Length", "ShowBeam", "Reaction")
