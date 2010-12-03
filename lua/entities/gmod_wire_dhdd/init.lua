AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include('shared.lua')

ENT.WireDebugName = "Dupeable HDD"

ENT.MaxSize = 1024*1024

function ENT:Initialize()
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)

	self.Outputs = WireLib.CreateOutputs( self, { "Memory [ARRAY]", "Size" } )
	self.Inputs = WireLib.CreateInputs( self, { "Data [ARRAY]", "Clear" } )

	self.Memory = {}
	self.MemSize = 0

	self.overlay = "DHDD"
end

-- Check if we're going to hit the max size if we add 1 more
function ENT:CheckMaxSize( size )
	if (self.MaxSize < (size or (self.MemSize + 1))) then return false end
	return true
end

-- Add 1 to current size if we're creating a new index
function ENT:AddSize( Address )
	if (!self.Memory[Address or 1]) then
		self.MemSize = self.MemSize + 1
	end
end

-- Read cell
function ENT:ReadCell( Address )
	local data = self.Memory[Address or 1] or 0
	if (type(data) == "number") then
		return data
	end
end

-- Write cell
function ENT:WriteCell( Address, value )
	if (!self:CheckMaxSize()) then return false end
	self:AddSize( Address )
	self.Memory[Address or 1] = value or 0
	self:ShowOutputs()
	return true
end

function ENT:ShowOutputs()
	WireLib.TriggerOutput( self, "Size", self.MemSize )
	WireLib.TriggerOutput( self, "Memory", self.Memory )

	self.overlay = "DHDD\nSize: " .. self.MemSize
end

-- You don't need to update the overlay constantly...
function ENT:Think()
	if self.overlay != "DHDD\nSize: " .. self.MemSize then
		self.overlay = "DHDD\nSize: " .. self.MemSize

		self:SetOverlayText( self.overlay )
	end

	self:NextThink( CurTime() + 0.25 )
	return true
end

function ENT:TriggerInput( name, value )
	if (name == "Data") then
		if (!value) then return end
		local size = table.Count( value )
		if (size == 0) then return end
		if (!self:CheckMaxSize( size )) then return false end
		self.Memory = table.Copy( value )
		self.MemSize = size
		self:ShowOutputs()
	elseif (name == "Clear") then
		self.Memory = {}
		self.MemSize = 0
		self:ShowOutputs()
	end
end

function ENT:BuildDupeInfo()
	local info = self.BaseClass.BuildDupeInfo( self ) or {}

	info.DHDD = {}
	info.DHDD.Memory = table.Copy(self.Memory)
	info.DHDD.MemSize = self.MemSize

	return info
end

function ENT:ApplyDupeInfo(ply, ent, info, GetEntByID)
	if (!ply:CheckLimit("wire_dhdds")) then
		ent:Remove()
		return
	end
	ply:AddCount( "wire_dhdds", ent )

	if (info.DHDD) then
		ent.Memory = (info.DHDD.Memory or {})
		ent.MemSize = (info.DHDD.MemSize or 0)
		self:ShowOutputs()
	end

	ent:SetPlayer( ply )
	self.BaseClass.ApplyDupeInfo(self, ply, ent, info, GetEntByID)
end
