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

	self.Memory = {}
	self.ROM = false
	self.AllowWrite = true

	self:SetOverlayText("DHDD")
end

-- Read cell
function ENT:ReadCell( Address )
	-- 256 KiB limit
	if Address < 0 or Address >= 262144 then return 0 end

	local data = self.Memory[Address or 0] or 0
	return isnumber(data) and data or 0
end

-- Write cell
function ENT:WriteCell( Address, value )
	-- 256 KiB limit
	if Address < 0 or Address >= 262144 then return false end

	if self.AllowWrite then
		self.Memory[Address] = value
	end
	self:ShowOutputs()
	return true
end

function ENT:ShowOutputs()
	WireLib.TriggerOutput( self, "Memory", self.Memory )
	local n = #self.Memory
	WireLib.TriggerOutput( self, "Size", n )
	if not self.ROM then
		self:SetOverlayText("DHDD\nSize: " .. n .." bytes" )
	else
		self:SetOverlayText("ROM\nSize: " .. n .." bytes" )
	end
end

function ENT:TriggerInput( name, value )
	if (name == "Data") then
		if not value then return end -- if the value is invalid, abort
		if not IsValid(self.Inputs.Data.Src) then return end -- if the input is not wired to anything, abort
		if not self.AllowWrite then return end -- if we don't allow writing, abort

		self.Memory = value
		self:ShowOutputs()
	elseif (name == "Clear") then
		self.Memory = {}
		self:ShowOutputs()
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
		ent.Memory = (info.DHDD.Memory or {})
		if info.DHDD.AllowWrite ~= nil then
			ent.AllowWrite = info.DHDD.AllowWrite
		end
		self:ShowOutputs()
	end
	self.ROM = info.ROM or false

	self.BaseClass.ApplyDupeInfo(self, ply, ent, info, GetEntByID)
end

duplicator.RegisterEntityClass( "gmod_wire_dhdd", WireLib.MakeWireEnt, "Data" )
