AddCSLuaFile()
DEFINE_BASECLASS( "base_wire_entity" )
ENT.PrintName       = "Wire Two-way Radio"
ENT.WireDebugName = "2W Radio"

if CLIENT then return end -- No more client

function ENT:Initialize()
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )

	self.Inputs = Wire_CreateInputs(self, { "A", "B", "C", "D" })
	self.Outputs = Wire_CreateOutputs(self, { "A", "B", "C", "D" })

	self.PairID = nil
	self.Other = nil
end

function ENT:Setup()
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

local radio_twowaycounter = 0
function ENT:GetTwoWayID()
	radio_twowaycounter = radio_twowaycounter + 1
	return radio_twowaycounter
end

function ENT:TriggerInput(iname, value)
	if self.Other and self.Other:IsValid() and self.Other.Inputs then
		self.Other:ReceiveRadio(iname, value)
		self:ShowOutput("update", 1)
	end
end

function ENT:Think()
	BaseClass.Think(self)

	if (not self.Other) or (not self.Other:IsValid()) then
		self.Other = nil
		self.PairID = nil
	end
end
function IsRadio(entity)
	if IsValid(entity) and entity:GetClass() == "gmod_wire_twoway_radio" then return true end
	return false
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

function ENT:LinkEnt( other )
	if not IsRadio(other) then return false, "Must link to another Two-Way Radio" end
	if other == self then return false, "Cannot link Two-Way Radio to itself" end
	-- If it's already linked...
	if self.Other then
		-- to the same one, return
		if self.Other == other then return false end
		--to a different one, then tell it to unlink
		self.Other.UnlinkEnt()
	end

	local id = self:GetTwoWayID()
	self:RadioLink(other, id)
	other:RadioLink(self, id)
	WireLib.AddNotify(self:GetPlayer(), "The Radios are now paired. Pair ID is " .. tostring(id) .. ".", NOTIFY_GENERIC, 7)
	WireLib.SendMarks(self, {other})
	return true
end
function ENT:UnlinkEnt()
	if not IsRadio(self) then return false end
	if not IsRadio(self.Other) then return false end
	self.Other:RadioLink(nil, nil)
	WireLib.SendMarks(self.Other, {})
	self:RadioLink(nil, nil)
	WireLib.SendMarks(self, {})
	return true
end

function ENT:ShowOutput(iname, value)
	local changed
	if (iname == "A") then
		if (value ~= self.PrevOutputA) then
			self.PrevOutputA = (value or 0)
			changed = 1
		end
	elseif (iname == "B") then
		if (value ~= self.PrevOutputB) then
			self.PrevOutputB = (value or 0)
			changed = 1
		end
	elseif (iname == "C") then
		if (value ~= self.PrevOutputC) then
			self.PrevOutputC = (value or 0)
			changed = 1
		end
	elseif (iname == "D") then
		if (value ~= self.PrevOutputD) then
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
	BaseClass.OnRestore(self)

	Wire_AdjustInputs(self, { "A", "B", "C", "D" })
	Wire_AdjustOutputs(self, { "A", "B", "C", "D" })
end

// Dupe info functions added by TheApathetic
function ENT:BuildDupeInfo()
	local info = BaseClass.BuildDupeInfo(self) or {}

	if (self.Other) and (self.Other:IsValid()) then
		info.Other = self.Other:EntIndex()
	end

	return info
end

function ENT:ApplyDupeInfo(ply, ent, info, GetEntByID)
	BaseClass.ApplyDupeInfo(self, ply, ent, info, GetEntByID)

	local other = GetEntByID(info.Other)
	if IsValid(other) then
		-- A new two-way ID is created upon paste to avoid
		-- interference with current two-way radios
		-- This works because ApplyDupeInfo is called after
		-- all entities are already pasted (TheApathetic)
		local id = other.PairID or self:GetTwoWayID()
		self:RadioLink(other, id)
	end
end

duplicator.RegisterEntityClass("gmod_wire_twoway_radio", WireLib.MakeWireEnt, "Data")
