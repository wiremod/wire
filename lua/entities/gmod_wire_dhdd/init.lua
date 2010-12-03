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

	self:SetOverlayText("DHDD")
end

-- Check if we're going to hit the max size if we add 1 more
function ENT:CheckMaxSize( size )
	if (self.MaxSize < (size or (self.MemSize + 1))) then return false end
	return true
end

-- Write an address & check max size etc
function ENT:WriteAddress( Address, value )
	if (!self.Memory[Address]) then
		if (!self:CheckMaxSize()) then return false end
		self.MemSize = self.MemSize + 1
	end
	self.Memory[Address] = value
	return true
end

-- Copy an array into the gate's memory
function ENT:CopyArray( R )
	local firstloop = true
	for k,v in pairs( R ) do
		if (firstloop) then -- If the new array actually has any data in it, clear the memory, then write to it
			firstloop = false
			self.Memory = {}
			self.MemSize = 0
		end
		if (!self:WriteAddress( k, v )) then -- Write to memory
			return
		end
	end
end

-- Read cell
function ENT:ReadCell( Address )
	local data = self.Memory[Address or 1] or 0
	return (type(data) == "number") and data or 0
end

-- Write cell
function ENT:WriteCell( Address, value )
	self:WriteAddress( Address or 1, value or 0 )
	self:ShowOutputs()
	return true
end

function ENT:ShowOutputs()
	WireLib.TriggerOutput( self, "Size", self.MemSize )
	WireLib.TriggerOutput( self, "Memory", table.Copy(self.Memory) )
	self:SetOverlayText("DHDD\nSize: " .. self.MemSize )
end

function ENT:TriggerInput( name, value )
	if (name == "Data") then
		if (!value) then return end
		self:CopyArray( value )
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
