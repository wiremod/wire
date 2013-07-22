
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "2W Radio"

function ENT:Initialize()
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )

	self.Inputs = Wire_CreateInputs(self, { "A", "B", "C", "D" })
	self.Outputs = Wire_CreateOutputs(self, { "A", "B", "C", "D" })

	self.PairID = nil
	self.Other = nil
end

function ENT:Setup( channel )
	self.Channel = channel
	self.PrevOutputA = nil
	self.PrevOutputB = nil
	self.PrevOutputC = nil
	self.PrevOutputD = nil

	self:ShowOutput("update", 1)
	Wire_TriggerOutput(self, "A", self.Outputs.A.Value or 0)
	Wire_TriggerOutput(self, "B", self.Outputs.B.Value or 0)
	Wire_TriggerOutput(self, "C", self.Outputs.C.Value or 0)
	Wire_TriggerOutput(self, "D", self.Outputs.D.Value or 0)
end

function ENT:TriggerInput(iname, value)
	if (self.Other) and (self.Other:IsValid()) then
		self.Other:ReceiveRadio(iname, value)
		self:ShowOutput("update", 1)
	end
end

function ENT:Think()
	self.BaseClass.Think(self)

	if (not self.Other) or (not self.Other:IsValid()) then
		self.Other = nil
		self.PairID = nil
	end
end

function ENT:ReceiveRadio(iname, value)
	if (iname == "A") and (self.Other) and (self.Other:IsValid()) then
		Wire_TriggerOutput(self, "A", value)
	elseif (iname == "B") and (self.Other) and (self.Other:IsValid()) then
		Wire_TriggerOutput(self, "B", value)
	elseif (iname == "C") and (self.Other) and (self.Other:IsValid()) then
		Wire_TriggerOutput(self, "C", value)
	elseif (iname == "D") and (self.Other) and (self.Other:IsValid()) then
		Wire_TriggerOutput(self, "D", value)
	end
	self:ShowOutput(iname, value)
end

function ENT:RadioLink(other, id)
	self.Other = other
	self.PairID = id
	self.PeerID = id

	self:TriggerInput("A", self.Inputs.A.Value or 0)
	self:TriggerInput("B", self.Inputs.B.Value or 0)
	self:TriggerInput("C", self.Inputs.C.Value or 0)
	self:TriggerInput("D", self.Inputs.D.Value or 0)
	self:ShowOutput("update", 1)
end


function ENT:ShowOutput(iname, value)
	local changed
	if (iname == "A") then
		if (A ~= self.PrevOutputA) then
			self.PrevOutputA = (value or 0)
			changed = 1
		end
	elseif (iname == "B") then
		if (B ~= self.PrevOutputB) then
			self.PrevOutputB = (value or 0)
			changed = 1
		end
	elseif (iname == "C") then
		if (C ~= self.PrevOutputC) then
			self.PrevOutputC = (value or 0)
			changed = 1
		end
	elseif (iname == "D") then
		if (D ~= self.PrevOutputD) then
			self.PrevOutputD = (value or 0)
			changed = 1
		end
	elseif (iname == "update") then
		changed = 1
	end
	if (changed) then
		if self.PairID == nil then
			self:SetOverlayText( "(Not Paired) Transmit: 0, 0, 0, 0" )
		else
			self:SetOverlayText( "(Pair ID: " .. self.PairID .. ")\nTransmit A: " .. (self.Inputs.A.Value or 0) .. " B: " .. (self.Inputs.B.Value or 0) ..  " C: " .. (self.Inputs.C.Value or 0) ..  " D: " .. (self.Inputs.D.Value or 0) .. "\nReceive A: " .. (self.Outputs.A.Value or 0) .. " B: " .. (self.Outputs.B.Value or 0) ..  " C: " .. (self.Outputs.C.Value or 0) ..  " D: " .. (self.Outputs.D.Value or 0) )
		end

	end
end

function ENT:OnRestore()
	self.BaseClass.OnRestore(self)

	Wire_AdjustInputs(self, { "A", "B", "C", "D" })
	Wire_AdjustOutputs(self, { "A", "B", "C", "D" })
end

// Dupe info functions added by TheApathetic
function ENT:BuildDupeInfo()
	local info = self.BaseClass.BuildDupeInfo(self) or {}

	if (self.Other) && (self.Other:IsValid()) then
		info.Other = self.Other:EntIndex()
	end

	return info
end

function ENT:ApplyDupeInfo(ply, ent, info, GetEntByID)
	self.BaseClass.ApplyDupeInfo(self, ply, ent, info, GetEntByID)

	if (info.Other) then
		local other = GetEntByID(info.Other)
		if (!other) then
			other = ents.GetByIndex(info.Other)
		end

		local id = 0
		// A new two-way ID is created upon paste to avoid
		// interference with current two-way radios
		// This works because ApplyDupeInfo is called after
		// all entities are already pasted (TheApathetic)
		if (other && other:IsValid() && other.PairID) then
			id = other.PairID
		else
			id = Radio_GetTwoWayID()
		end
		self:RadioLink(other, id)
	end
end
