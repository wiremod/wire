AddCSLuaFile()

DEFINE_BASECLASS("base_wire_entity")
ENT.PrintName = "Freezer"
ENT.WireDebugName = "Freezer"

if CLIENT then return end

function ENT:Initialize()
	self:PhysicsInit(SOLID_VPHYSICS)
	self.Marks = {}

	WireLib.CreateInputs(self, { "Activate", "Disable Collisions" })
	self:UpdateOverlay()
end

function ENT:TriggerInput(name, value)
	local ply = self:GetPlayer()
	if not ply:IsValid() then return end

	if name == "Activate" then
		self.State = value ~= 0

		for _, ent in ipairs(self.Marks) do
			local phys = ent:GetPhysicsObject()

			if phys:IsValid() then
				if self.State then
					gamemode.Call("OnPhysgunFreeze", self, phys, ent, ply)
				elseif gamemode.Call("CanPlayerUnfreeze", ply, ent, phys) then
					phys:EnableMotion(true)
					phys:Wake()
				end
			end
		end
	elseif name == "Disable Collisions" then
		local state = math.Clamp(math.floor(value), 0, 4)
		self.CollisionState = state

		for _, ent in ipairs(self.Marks) do
			local phys = ent:GetPhysicsObject()

			if phys:IsValid() and WireLib.CanTool(ply, ent, "nocollide") then
				if state == 0 then
					ent:SetCollisionGroup(COLLISION_GROUP_NONE)
					phys:EnableCollisions(true)
				elseif state == 1 then
					ent:SetCollisionGroup(COLLISION_GROUP_WORLD)
					phys:EnableCollisions(true)
				elseif state == 2 then
					ent:SetCollisionGroup(COLLISION_GROUP_NONE)
					phys:EnableCollisions(false)
				elseif state == 3 then
					ent:SetCollisionGroup(COLLISION_GROUP_WEAPON)
					phys:EnableCollisions(true)
				elseif state == 4 then
					ent:SetCollisionGroup(COLLISION_GROUP_WEAPON)
					phys:EnableCollisions(false)
				end
			end
		end
	end

	self:UpdateOverlay()
end

function ENT:UpdateOverlay()
	local description
	local state = self.CollisionState or 0

	if state == 0 then
		description = "Normal collisions"
	elseif state == 1 then
		description = "Disabled prop/player collisions"
	elseif state == 2 then
		description = "Disabled prop/world collisions"
	elseif state == 3 then
		description = "Disabled player collisions"
	elseif state == 4 then
		description = "Disabled prop/world/player collisions"
	end

	self:SetOverlayText(string.format("%s\n%s\nLinked Entities: %i", self.State and "Frozen" or "Unfrozen", description, #self.Marks))
end

function ENT:UpdateOutputs()
	self:UpdateOverlay()
	WireLib.SendMarks(self)
end

function ENT:CheckEnt(checkent)
	for index, ent in ipairs(self.Marks) do
		if checkent == ent then
			return true, index
		end
	end

	return false, 0
end

function ENT:LinkEnt(ent)
	if self:CheckEnt(ent) then return false	end

	table.insert(self.Marks, ent)

	ent:CallOnRemove("Freezer.Unlink" .. self:EntIndex(), function(ent)
		self:UnlinkEnt(ent)
	end)

	self:UpdateOutputs()

	return true
end

function ENT:UnlinkEnt(ent)
	local bool, index = self:CheckEnt(ent)

	if bool then
		table.remove(self.Marks, index)
		ent:RemoveCallOnRemove("Freezer.Unlink" .. self:EntIndex())
		self:UpdateOutputs()
	end

	return bool
end

function ENT:ClearEntities()
	for index, ent in ipairs(self.Marks) do
		ent:RemoveCallOnRemove("Freezer.Unlink" .. self:EntIndex())
	end

	self.Marks = {}
	self:UpdateOutputs()
end

function ENT:OnRemove()
	self:ClearEntities()
end

function ENT:BuildDupeInfo()
	local info = BaseClass.BuildDupeInfo(self)

	if #self.Marks > 0 then
		local tab = {}

		for index, ent in ipairs(self.Marks) do
			tab[index] = ent:EntIndex()
		end

		info.marks = tab
	end

	return info
end

function ENT:ApplyDupeInfo(ply, ent, info, GetEntByID)
	BaseClass.ApplyDupeInfo(self, ply, ent, info, GetEntByID)

	if info.marks or info.Ent1 then
		if info.Ent1 then
			-- Backwards compcatability
			local ent = GetEntByID(info.Ent1)

			if ent:IsValid() then
				table.insert(self.Marks, ent)
			end
		else
			for index, entid in ipairs(info.marks) do
				local ent = GetEntByID(entid)

				if ent:IsValid() then
					table.insert(self.Marks, ent)

					ent:CallOnRemove("Freezer.Unlink" .. self:EntIndex(), function(ent)
						self:UnlinkEnt(ent)
					end)
				end
			end
		end

		self:TriggerInput("Disable Collisions", self.Inputs["Disable Collisions"].Value)
		self:UpdateOutputs()
	end
end

duplicator.RegisterEntityClass("gmod_wire_freezer", WireLib.MakeWireEnt, "Data")
