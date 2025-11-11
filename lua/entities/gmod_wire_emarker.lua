AddCSLuaFile()

DEFINE_BASECLASS("base_wire_entity")
ENT.PrintName = "Wire Entity Marker"
ENT.WireDebugName = "EMarker"

if CLIENT then return end

function ENT:Initialize()
	self:PhysicsInit(SOLID_VPHYSICS)

	WireLib.CreateOutputs(self, { "Entity [ENTITY]" })
	self:SetOverlayText("No linked mark")
end

function ENT:LinkEnt(ent)
	if ent ~= self.Mark then
		if self.Mark then
			self.Mark:RemoveCallOnRemove("EMarker.UnLink" .. self:EntIndex())
			self.Mark = nil
		end

		ent:CallOnRemove("EMarker.UnLink" .. self:EntIndex(), function(ent)
			self:UnlinkEnt()
		end)

		WireLib.SendMarks(self, { ent })
		WireLib.TriggerOutput(self, "Entity", ent)
		self:SetOverlayText("Linked to: " .. ent:GetClass())
		self.Mark = ent

		return true
	end

	return false
end

function ENT:UnlinkEnt()
	if self.Mark then
		WireLib.SendMarks(self, {})
		WireLib.TriggerOutput(self, "Entity", NULL)
		self:SetOverlayText("No linked mark")
		self.Mark:RemoveCallOnRemove("EMarker.UnLink" .. self:EntIndex())
		self.Mark = nil

		return true
	end

	return false
end

function ENT:OnRemove()
	if self.Mark then
		self.Mark:RemoveCallOnRemove("EMarker.UnLink" .. self:EntIndex())
		self.Mark = nil
	end
end

function ENT:BuildDupeInfo()
	local info = BaseClass.BuildDupeInfo(self)

	if self.Mark then
		info.mark = self.Mark:EntIndex()
	end

	return info
end

function ENT:ApplyDupeInfo(ply, ent, info, GetEntByID)
	BaseClass.ApplyDupeInfo(self, ply, ent, info, GetEntByID)

	if info.mark then
		local ent = GetEntByID(info.mark)

		if ent:IsValid() then
			self:LinkEnt(ent)
		end
	end
end

duplicator.RegisterEntityClass("gmod_wire_emarker", WireLib.MakeWireEnt, "Data")
