AddCSLuaFile()
DEFINE_BASECLASS( "base_wire_entity" )
ENT.PrintName		= "Wire CD Lock"
ENT.WireDebugName = "CD Lock"

if CLIENT then return end -- No more client

-- Time after losing one disk to search for another
local NEW_DISK_WAIT_TIME = 2
local DISK_IN_SOCKET_CONSTRAINT_POWER = 5000
local DISK_IN_ATTACH_RANGE = 16

function ENT:Initialize()
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)

	self.Const = nil
	self.Disk = nil
	self.DisableLinking = 0

	self.Inputs = Wire_CreateInputs(self, { "Disable" })
	self.Outputs = Wire_CreateOutputs(self, { "Locked" })

	self:NextThink(CurTime() + 0.25)
end

function ENT:TriggerInput(iname, value)
	if iname == "Disable" then
		self.DisableLinking = value
		if (value >= 1) and (self.Const) then
			self.Const:Remove()
			--self.NoCollideConst:Remove()

			self.Const = nil
			self.Disk.Lock = nil
			self.Disk = nil
			--self.NoCollideConst = nil

			Wire_TriggerOutput(self, "Locked", 0)
			self:NextThink(CurTime() + NEW_DISK_WAIT_TIME)
		end
	end
end

function ENT:Think()
	self.BaseClass.Think(self)

	-- If we were undisked, reset the disk and socket to accept new ones.
	if (self.Const) and (not self.Const:IsValid()) then
		self.Const = nil
		self.Disk.Lock = nil
		self.Disk = nil
		self.NoCollideConst = nil

		Wire_TriggerOutput(self, "Locked", 0)

		self:NextThink(CurTime() + NEW_DISK_WAIT_TIME) -- Give time before next grabbing a disk.
		return true
	else
		if (self.DisableLinking < 1) and (self.Disk == nil) then
			-- Find entities near us
			local lockCenter = self:LocalToWorld(Vector(0, 0, 0))
			local local_ents = ents.FindInSphere(lockCenter, DISK_IN_ATTACH_RANGE)
			for key, disk in pairs(local_ents) do
				-- If we find a disk, try to attach it to us
				if disk:IsValid() and disk:GetClass() == "gmod_wire_cd_disk" then
					if disk.Lock == nil then
						self:AttachDisk(disk)
					end
				end
			end
		end
	end
	self:NextThink(CurTime() + 0.25)
end

function ENT:AttachDisk(disk)
	-- Position disk
	local min = disk:OBBMins()
	local max = disk:OBBMaxs()

	local newpos = self:LocalToWorld(Vector(0, 0, 0))
	local lockAng = self:GetAngles()
	disk:SetPos(newpos)
	disk:SetAngles(lockAng)

	self.NoCollideConst = constraint.NoCollide(self, disk, 0, 0)
	if not self.NoCollideConst then
		Wire_TriggerOutput(self, "Locked", 0)
		return
	end

	-- Constrain together
	self.Const = constraint.Weld(self, disk, 0, 0, DISK_IN_SOCKET_CONSTRAINT_POWER, true)
	if not self.Const then
	    self.NoCollideConst:Remove()
	    self.NoCollideConst = nil
	    Wire_TriggerOutput(self, "Locked", 0)
	    return
	end

	-- Prepare clearup incase one is removed
	disk:DeleteOnRemove(self.Const)
	self:DeleteOnRemove(self.Const)
	self.Const:DeleteOnRemove(self.NoCollideConst)

	disk.Lock = self
	self.Disk = disk
	Wire_TriggerOutput(self, "Locked", 1)
end

duplicator.RegisterEntityClass("gmod_wire_cd_lock", WireLib.MakeWireEnt, "Data")
