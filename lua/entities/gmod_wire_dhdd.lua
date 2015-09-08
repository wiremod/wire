AddCSLuaFile()
DEFINE_BASECLASS( "base_wire_entity" )
ENT.PrintName		= "Wire Dupeable Hard Drive"
ENT.Author      	= "Divran"
ENT.WireDebugName 	= "Dupeable HDD"

if CLIENT then return end -- No more client

function ENT:Initialize()
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)

	self.Outputs = WireLib.CreateOutputs( self, { "Memory [ARRAY]", "Size" } )
	self.Inputs = WireLib.CreateInputs( self, { "Data [ARRAY]", "Clear", "AllowWrite" } )

	self:SetMemory()
	self.ROM = false
	self.AllowWrite = true
end

function ENT:SetMemory(Memory)
	self.Memory = Memory or {}

	local Metatable = {}

	function Metatable.__index(Proxy, Index)
		return self.Memory[Index]
	end

	function Metatable.__newindex(Proxy, Index, Value)
		if self.AllowWrite then
			self.Memory[Index] = value
			self:ShowOutputs()
		end
	end

	function Metatable.__len(Proxy)
		return #self.Memory
	end

	self.Proxy = setmetatable({}, Metatable)
	self:ShowOutputs()
end

-- Read cell
function ENT:ReadCell( Address )
	local data = self.Memory[Address or 0] or 0
	return isnumber(data) and data or 0
end

-- Write cell
function ENT:WriteCell( Address, value )
	if self.AllowWrite then
		self.Memory[Address] = value
	end
	self:ShowOutputs()
	return true
end

function ENT:ShowOutputs()
	local n = #self.Memory
	WireLib.TriggerOutput( self, "Memory", self.Proxy )
	WireLib.TriggerOutput( self, "Size", n )
	if not self.ROM then
		self:SetOverlayText( "DHDD\nSize: " .. n .." bytes" )
	else
		self:SetOverlayText( "ROM\nSize: " .. n .." bytes" )
	end
end

function ENT:TriggerInput( name, value )
	if (name == "Data") then
		if not value then return end -- if the value is invalid, abort
		if not IsValid(self.Inputs.Data.Src) then return end -- if the input is not wired to anything, abort
		if not self.AllowWrite then return end -- if we don't allow writing, abort

		self:SetMemory(value)
	elseif (name == "Clear") then
		self:SetMemory()
	elseif (name == "AllowWrite") then
		self.AllowWrite = value >= 1
	end
end

function ENT:BuildDupeInfo()
	local info = self.BaseClass.BuildDupeInfo( self ) or {}

	info.DHDD = {}
	info.ROM = self.ROM
	local n = 0
	info.DHDD.Memory = {}
	for k,v in pairs( self.Memory ) do -- Only save the first 512^2 values
		n = n + 1
		if (n > 512*512) then break end
		info.DHDD.Memory[k] = v
	end

	info.DHDD.AllowWrite = self.AllowWrite

	return info
end

function ENT:ApplyDupeInfo(ply, ent, info, GetEntByID)
	if (info.DHDD) then
		ent:SetMemory(info.DHDD.Memory)
		if info.DHDD.AllowWrite ~= nil then
			ent.AllowWrite = info.DHDD.AllowWrite
		end
	end
	self.ROM = info.ROM or false

	self.BaseClass.ApplyDupeInfo(self, ply, ent, info, GetEntByID)
end

duplicator.RegisterEntityClass( "gmod_wire_dhdd", WireLib.MakeWireEnt, "Data" )
