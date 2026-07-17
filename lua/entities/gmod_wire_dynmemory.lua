AddCSLuaFile()
DEFINE_BASECLASS( "base_wire_entity" )
ENT.PrintName		= "Wire Dynamic Memory"
ENT.Author			= "Sebastian J., the gabe"
ENT.WireDebugName = "Dynamic Memory"

if CLIENT then return end -- No more client

function ENT:Initialize()
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)

	self.Inputs = Wire_CreateInputs(self, {"Clk"})

	self.Outputs = Wire_CreateOutputs(self, {"Out", "Size"})

	self.Size = 1
	self.Memory = {}
	self.Memory[0] = 0

	--this flag assists in replacing the old ram gate chips
	--when adv. dupe 2 spawns something, it seems to run Setup() at least twice
	--at the first setup we successfully hijack the memory chip and imitate its capacity
	--at the second setup, the size is set back to 1 since were not being initialized through FromGate()
	--to fix this, the legacy flag disables resizing of the ram chip until it is duped and spawned in again,
	--since at this point we dont have to hijack the old ram chip
	self.Legacy = false

	--the old dynamic memory chips had persistence like the dhdd
	--if this feature is ever wanted, the required code is all here (and dynmemory.lua), but commented out
	--self.Persistent = false

	self.AddrWrite = 0
	self.AddrRead = 0
	self.AddrWriteY = 0
	self.AddrReadY = 0
	self.Clk = false
	self.Data = 0

	self.WOM = false
	self.Bifurcate = false
	self.BifurcateMagic = 0
end

function ENT:Setup(size, wom, bifurcate, legacy)
	if self.Legacy then return end
	self.WOM = (wom == 1)
	self.Bifurcate = (bifurcate == 1)

	local inputbuilt = {}

	if not self.WOM then
		if self.Bifurcate then
			inputbuilt = {"Clk", "AddrReadX", "AddrReadY", "AddrWriteX", "AddrWriteY", "Data", "Reset"}
		else
			inputbuilt = {"Clk", "AddrRead", "AddrWrite", "Data", "Reset"}
		end
	else
		if self.Bifurcate then
			inputbuilt = {"Clk", "AddrWriteX", "AddrWriteY", "Data", "Reset"}
		else
			inputbuilt = {"Clk", "AddrWrite", "Data", "Reset"}
		end
	end

	self.Inputs = Wire_AdjustInputs(self, inputbuilt)

	local size = math.Clamp(math.floor(size or self.Size), 1, 2097152) --2mb limit

	if self.Bifurcate then
		self.BifurcateMagic = math.floor(math.sqrt(size))
		size = self.BifurcateMagic * self.BifurcateMagic
	end

	local overheap = size - self.Size

	if (overheap < 0) then
		for i= size, self.Size -1 do
			self.Memory[i] = nil
		end
	elseif (overheap > 0) then
		for i = self.Size, size - 1 do
			self.Memory[i] = 0
		end
	end
	self.Size = size

	local sstr = self.Size
	local sunit = " Bytes"

	if self.Bifurcate then
		sstr = tostring(self.BifurcateMagic) .. "x" .. tostring(self.BifurcateMagic) .. sunit
	else
		if (sstr >= 1048576) then
			sunit = "MB"
			sstr = math.floor(sstr / 10485.76) / 100 --shows up to 2 decimals
		elseif (sstr >= 1024) then
			sunit = "KB"
			sstr = math.floor(sstr / 102.4) / 10 --shows up to 1 decimal
		end
		sstr = tostring(sstr) .. sunit
	end

	self:SetOverlayText(sstr .. (self.WOM == true and " Write-Only" or "") .. " RAM" .. (self.Size >= 1024 and " (" .. self.Size .. " bytes)" or "") .. (legacy and " (Legacy)" or "") )

	WireLib.TriggerOutput(self, "Size", self.Size)

	self.Legacy = legacy
end

function ENT:Think()
	if self.Bifurcate then
		if self.Clk and self.AddrWrite >= 0 and self.AddrWrite < self.BifurcateMagic and self.AddrWriteY >= 0 and self.AddrWriteY < self.BifurcateMagic then
			self:WriteCell(self.AddrWrite + self.AddrWriteY * self.BifurcateMagic, self.Data)
		end
		if not self.WOM and self.AddrRead >= 0 and self.AddrRead < self.BifurcateMagic and self.AddrReadY >= 0 and self.AddrReadY < self.BifurcateMagic then
			WireLib.TriggerOutput(self, "Out", self.Memory[self.AddrRead + self.AddrReadY * self.BifurcateMagic])
		end
	else
		if self.Clk and self.AddrWrite < self.Size and self.AddrWrite >= 0 then
			self:WriteCell(self.AddrWrite, self.Data)
		end
		if not self.WOM and self.AddrRead < self.Size and self.AddrRead >= 0 then
			WireLib.TriggerOutput(self, "Out", self.Memory[self.AddrRead])
		end
	end
	self:NextThink(CurTime() + 0.02) --same as gate ent
	return true
end

--[[function ENT:SetPersistent(val)
	self.Persistent = val or self.Persistent
end]]

function ENT:TriggerInput(iname, Value)
	if (iname == "Reset") then
		if (Value == 1) then
			for i=0, self.Size - 1 do
				self.Memory[i] = 0
			end
		end
	elseif (iname == "AddrWrite") or (iname == "AddrWriteX") then
		self.AddrWrite = math.floor(Value)
	elseif (iname == "AddrRead") or (iname == "AddrReadX") then
		self.AddrRead = math.floor(Value)
	elseif (iname == "AddrWriteY") then
		self.AddrWriteY = math.floor(Value)
	elseif (iname == "AddrReadY") then
		self.AddrReadY = math.floor(Value)
	elseif (iname == "Data") then
		self.Data = Value
	elseif (iname == "Clk") then
		self.Clk = Value > 0
	end
end

function ENT:ReadCell(Address)
	Address = math.floor(tonumber(Address))
	if self.WOM or Address < 0 or Address >= self.Size then
		return 0
	end
	return self.Memory[Address]
end

function ENT:WriteCell(Address, Value)
	Address = math.floor(tonumber(Address))
	if Address < 0 or Address >= self.Size then
		return false
	end
	self.Memory[Address] = Value or 0
	return true
end

local gateconv = {}
--{size, write only, bifurcate}
gateconv["ram8"] = {8, 0, 0}
gateconv["ram64"] = {64, 0, 0}
gateconv["ram1k"] = {1024, 0, 0}
gateconv["ram32k"] = {32768, 0, 0}
gateconv["ram128k"] = {131072, 0, 0}
gateconv["ram64x64"] = {4096, 0, 1}
gateconv["wom4"] = {4, 1, 0}

function ENT:FromGate(action)
	if gateconv[action] then
		self:Setup(gateconv[action][1], gateconv[action][2], gateconv[action][3], true)
		return
	end
	self:Setup(1, 0, 0, true) --this shouldnt be able to happen
end

function ENT:BuildDupeInfo()
	local info = self.BaseClass.BuildDupeInfo(self) or {}

	info.MemSize = self.Size
	info.WOM = (self.WOM and 1 or 0)
	info.Bifurcate = (self.Bifurcate and 1 or 0)
	--[[info.Persistent = self.Persistent
	if (self.Persistent) then
		info.Memory = {}
		--same 256k limit as DHDD
		for i=0, math.min(self.Size - 1, 262143)  do
			if (self.Memory[i]) then
				info.Memory[i] = self.Memory[i]
			end
		end
	end]]

	return info
end

function ENT:ApplyDupeInfo(ply, ent, info, GetEntByID)
	self.BaseClass.ApplyDupeInfo(self, ply, ent, info, GetEntByID)

	self:Setup(info.MemSize or 1, info.WOM or 0, info.Bifurcate or 0, false)

	--[[self.Persistent = info.Persistent
	if (info.Persistent) then
		info.Memory = info.Memory or {}
		--same 256k (512^2) limit as DHDD
		for i=0, math.min(self.Size - 1, 262143)  do
			if (info.Memory[i]) then
				self.Memory[i] = info.Memory[i]
			end
		end
	end]]
end

duplicator.RegisterEntityClass("gmod_wire_dynmemory", WireLib.MakeWireEnt, "Data", "Size", "WOM", "Bifurcate")--, "Persistent")
