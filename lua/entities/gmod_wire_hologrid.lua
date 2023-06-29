AddCSLuaFile()
DEFINE_BASECLASS( "base_wire_entity" )
ENT.PrintName       = "Wire Holo Grid"
ENT.Author          = "Chad 'Jinto'"
ENT.WireDebugName = "Holo Grid"

if CLIENT then return end -- No more client

function ENT:Initialize()
	self:PhysicsInit( SOLID_VPHYSICS );
	self:SetMoveType( MOVETYPE_VPHYSICS );
	self:SetSolid( SOLID_VPHYSICS );
	self:SetUseType(SIMPLE_USE)

	self:Setup(false)

	-- create inputs.
	self.Inputs = WireLib.CreateSpecialInputs(self, { "UseGPS", "Reference" }, { "NORMAL", "ENTITY" })
	self.reference = self
end

function ENT:Setup(UseGPS)
	if UseGPS then
		self.usesgps = true
		self:SetNWEntity( "reference", ents.GetByIndex(-1) )
		self:SetOverlayText( "(GPS)" )
	else
		self.usesgps = false
		self:SetNWEntity( "reference", self.reference )
		self:SetOverlayText( "(Local)" )
	end
end

function ENT:TriggerInput( inputname, value )
	-- store values.
	if inputname == "UseGPS" then
		self:Setup(value ~= 0)
	elseif inputname == "Reference" then
		if IsValid(value) then
			self.reference = value
		else
			self.reference = self
		end
		self:Setup(self.usesgps)
	end
end

function ENT:Use( activator, caller )
	if caller:IsPlayer() then self:Setup(not self.usesgps) end
end

duplicator.RegisterEntityClass("gmod_wire_hologrid", WireLib.MakeWireEnt, "Data", "usegps")


function ENT:BuildDupeInfo()
	local info = BaseClass.BuildDupeInfo(self) or {}

	info.hologrid_usegps = self.usesgps and 1 or 0

	if IsValid(self.reference) then
		info.reference = self.reference:EntIndex()
	else
		info.reference = nil
	end

	return info
end

function ENT:ApplyDupeInfo(ply, ent, info, GetEntByID)
	BaseClass.ApplyDupeInfo(self, ply, ent, info, GetEntByID)

	self.reference = GetEntByID(info.reference, self)
	self:Setup(info.hologrid_usegps ~= 0)
end
