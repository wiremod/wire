AddCSLuaFile()

DEFINE_BASECLASS("base_wire_entity")
ENT.PrintName = "Wire Buoyancy"
ENT.RenderGroup = RENDERGROUP_BOTH
ENT.WireDebugName = "Buoyancy"

if CLIENT then return end

function ENT:Initialize()
	self.Marks = {}
	self:PhysicsInit(SOLID_VPHYSICS)
	WireLib.CreateInputs(self, { "Percent" })
end

local function SetBuoyancy(ent, controller)
	local phys = ent:GetPhysicsObject()
	ent.WireBuoyancyController = controller

	if phys:IsValid() then
		phys:SetBuoyancyRatio(controller.Percent)
		phys:Wake()
	end
end

local function UpdateBuoyancy(controller)
	for _, ent in ipairs(controller.Marks) do
		if ent:IsValid() then
			SetBuoyancy(ent, controller)
		end
	end
end

function ENT:UpdateOutputs()
	self:SetOverlayText(string.format("Buoyancy ratio: %.2f\nNumber of entities linked: %i", self.Percent, #self.Marks))
	WireLib.SendMarks(self)
end

function ENT:Setup(percent)
	self.Percent = math.Clamp(percent, -10, 10)
	UpdateBuoyancy(self)

	self:UpdateOutputs()
end

function ENT:TriggerInput(name, value)
	if name == "Percent" then
		self.Percent = math.Clamp(value, -10, 10)
		UpdateBuoyancy(self)

		self:UpdateOutputs()
	end
end

-- For some reason, buoyancy is reset by the physgun and gravgun
hook.Add("PhysgunDrop", "WireBuoyancy", function(ply, ent)
	if IsValid(ent.WireBuoyancyController) then
		timer.Simple(0 , function()
			if not IsValid(ent.WireBuoyancyController) then return end
			SetBuoyancy(ent, ent.WireBuoyancyController)
		end)
	end
end)

hook.Add("GravGunOnDropped", "WireBuoyancy", function(ply, ent)
	if IsValid(ent.WireBuoyancyController) then
		timer.Simple(0 , function()
			if not IsValid(ent.WireBuoyancyController) then return end
			SetBuoyancy(ent, ent.WireBuoyancyController)
		end)
	end
end)

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
	SetBuoyancy(ent, self)

	ent:CallOnRemove("WireBuoyancy.Unlink", function(ent)
		if self:IsValid() then
			self:UnlinkEnt(ent)
		end
	end)

	self:UpdateOutputs()

	return true
end

function ENT:UnlinkEnt(ent)
	local bool, index = self:CheckEnt(ent)

	if bool then
		table.remove(self.Marks, index)
		ent.WireBuoyancyController = nil
		self:UpdateOutputs()
	end

	return bool
end

function ENT:ClearEntities()
	for index, ent in ipairs(self.Marks) do
		if ent:IsValid() then
			ent:RemoveCallOnRemove("WireBuoyancy.Unlink")
			ent.WireBuoyancyController = nil
		end
	end

	self.Marks = {}
	self:UpdateOutputs()
end

function ENT:OnRemove()
	self:ClearEntities()
end

function ENT:BuildDupeInfo()
	local info = BaseClass.BuildDupeInfo(self) or {}

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
		self.Marks = self.Marks or {}

		for index, entid in ipairs(info.marks) do
			local ent = GetEntByID(entid)

			if ent:IsValid() then
				self:LinkEnt(ent)
			end
		end
	end
end

duplicator.RegisterEntityClass("gmod_wire_buoyancy", WireLib.MakeWireEnt, "Data", "Percent")
