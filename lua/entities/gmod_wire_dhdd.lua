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
	self.Size = 0
	self.ROM = false
	self.AllowWrite = true

	self:SetOverlayText("DHDD")
end

-- Read cell
function ENT:ReadCell( Address )
	-- 256 KiB limit
	if Address < 0 or Address >= 262144 then return 0 end
	Address = math.floor(Address)

	local data = self.Memory[Address or 0] or 0
	return isnumber(data) and data or 0
end

-- Write cell
function ENT:WriteCell( Address, value )
	-- 256 KiB limit
	if Address < 0 or Address >= 262144 then return false end
  Address = math.floor(Address)

	if self.AllowWrite then
		self.Memory[Address] = value ~= 0 and value or nil
		self.Size = math.max(self.Size, Address + 1)
	end

	self.WantsUpdate = true
	return true
end

function ENT:Think()
	self.BaseClass.Think( self )

	--[[
		The workaround using WantsUpdate should not be required.
		However, the server crashes (for no reason whatsoever) if you
		create a string of the following structure too often
		[~11 chars] .. number .. [~3 chars]
		(such as "DHDD\nSize: " .. self.Size .." bytes")
		No, string.format doesn't help
	]]
	if self.WantsUpdate then
		self.WantsUpdate = nil
		self:ShowOutputs()
	end
end

function ENT:ShowOutputs()
	WireLib.TriggerOutput( self, "Memory", self.Memory )
	WireLib.TriggerOutput( self, "Size", self.Size )
	if not self.ROM then
		self:SetOverlayText("DHDD\nSize: " .. self.Size .." bytes" )
	else
		self:SetOverlayText("ROM\nSize: " .. self.Size .." bytes" )
	end
end

function ENT:TriggerInput( name, value )
	if (name == "Data") then
		if not value then return end -- if the value is invalid, abort
		if not self.AllowWrite then return end -- if we don't allow writing, abort

		self.Memory = value

		-- HiSpeed interfaces are 0-based, but Lua arrays are typically 1-based.
		-- This gives the right 0-based size if the input is a 0-based or 1-based array:
		--     {} ⇒ 0
		--     { 0 = 0 } ⇒ 1
		--     { 1 = 1 }, { 0 = 0, 1 = 1 } ⇒ 2
		local size = table.maxn(value)
		if size ~= 0 or value[0] ~= nil then
			size = size + 1
		end
		self.Size = size
		self.WantsUpdate = true
	elseif (name == "Clear") then
		if value ~= 0 then
			self.Memory = {}
			self.Size = 0
			self.WantsUpdate = true
		end
	elseif (name == "AllowWrite") then
		self.AllowWrite = value >= 1
	end
end

function ENT:BuildDupeInfo()
	local info = BaseClass.BuildDupeInfo( self ) or {}

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

		local size = table.maxn(ent.Memory)
		if size ~= 0 or ent.Memory[0] ~= nil then
			size = size + 1
		end
		self.Size = size

		if info.DHDD.AllowWrite ~= nil then
			ent.AllowWrite = info.DHDD.AllowWrite
		end
		self:ShowOutputs()
	end
	self.ROM = info.ROM or false

	BaseClass.ApplyDupeInfo(self, ply, ent, info, GetEntByID)
end

duplicator.RegisterEntityClass( "gmod_wire_dhdd", WireLib.MakeWireEnt, "Data" )
