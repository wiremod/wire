AddCSLuaFile()

DEFINE_BASECLASS("base_wire_entity")
ENT.PrintName = "Adv Wire Entity Marker"
ENT.WireDebugName = "Adv EMarker"

if CLIENT then return end

function ENT:Initialize()
	self:PhysicsInit(SOLID_VPHYSICS)
	self.Marks = {}

	WireLib.CreateInputs(self, {
		"Entity (This entity will be added or removed once the other two inputs are changed) [ENTITY]",
		"Add Entity (Change to non-zero value to add the entity specified by the 'Entity' input)",
		"Remove Entity (Change to non-zero value to remove the entity specified by the 'Entity' input)",
		"Clear Entities (Removes all entities from the marker)"
	})

	WireLib.CreateOutputs(self, {
		"Entities [ARRAY]",
		"Nr (Number of entities linked)",
		"Entity1 [ENTITY]",
		"Entity2 [ENTITY]",
		"Entity3 [ENTITY]",
		"Entity4 [ENTITY]",
		"Entity5 [ENTITY]",
		"Entity6 [ENTITY]",
		"Entity7 [ENTITY]",
		"Entity8 [ENTITY]",
		"Entity9 [ENTITY]",
		"Entity10 [ENTITY]"
	})

	self:SetOverlayText("Number of entities linked: 0")
end

function ENT:TriggerInput(name, value)
	if name == "Entity" then
		if IsValid(value) then
			self.Target = value
		end
	elseif name == "Add Entity" then
		if value ~= 0 and IsValid(self.Target) and not self:CheckEnt(self.Target)  then
			self:LinkEnt(self.Target)
		end
	elseif name == "Remove Entity" then
		if value ~= 0 and IsValid(self.Target) and self:CheckEnt(self.Target) then
			self:UnlinkEnt(self.Target)
		end
	elseif name == "Clear Entities" then
		self:ClearEntities()
	end
end

function ENT:UpdateOutputs()
	local marks = self.Marks
	WireLib.TriggerOutput(self, "Entities", marks)
	WireLib.TriggerOutput(self, "Nr", #marks)

	for i = 3, 12 do
		local index = i - 2
		WireLib.TriggerOutput(self, "Entity" .. index, marks[index])
	end

	self:SetOverlayText("Number of entities linked: " .. #marks)
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

	ent:CallOnRemove("AdvEMarker.Unlink" .. self:EntIndex(), function(ent)
		self:UnlinkEnt(ent)
	end)

	self:UpdateOutputs()

	return true
end

function ENT:UnlinkEnt(ent)
	local bool, index = self:CheckEnt(ent)

	if bool then
		table.remove(self.Marks, index)
		ent:RemoveCallOnRemove("AdvEMarker.Unlink" .. self:EntIndex())
		self:UpdateOutputs()
	end

	return bool
end

function ENT:ClearEntities()
	for index, ent in ipairs(self.Marks) do
		ent:RemoveCallOnRemove("AdvEMarker.Unlink" .. self:EntIndex())
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

	if info.marks then
		for index, entid in ipairs(info.marks) do
			local ent = GetEntByID(entid)

			if ent:IsValid() then
				table.insert(self.Marks, ent)

				ent:CallOnRemove("AdvEMarker.Unlink" .. self:EntIndex(), function(ent)
					self:UnlinkEnt(ent)
				end)
			end
		end

		self:UpdateOutputs()
	end
end

duplicator.RegisterEntityClass("gmod_wire_adv_emarker", WireLib.MakeWireEnt, "Data")
