AddCSLuaFile()
DEFINE_BASECLASS( "base_wire_entity" )
ENT.PrintName       = "Wire GPS"
ENT.WireDebugName	= "GPS"

if CLIENT then
	function ENT:Think()
		BaseClass.Think(self)

		local pos = self:GetPos()
		local txt = string.format( "Position = %0.3f, %0.3f, %0.3f", math.Round(pos.x,3),math.Round(pos.y,3),math.Round(pos.z,3) )

		self:SetOverlayText( txt )

		self:NextThink(CurTime()+0.04)
		return true
	end

	return  -- No more client
end

-- Server

function ENT:Initialize()
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )

	self.storedpositions = {};
	self.arrayindex = 0;

	self.Inputs = Wire_CreateInputs(self, { "Store/Save Pos", "Next", "Remove Save Position"})
	self.Outputs = WireLib.CreateSpecialOutputs( self, { "X", "Y", "Z", "Vector", "Recall X", "Recall Y", "Recall Z", "Recall Vector", "Current Memory"}, { "NORMAL", "NORMAL", "NORMAL", "VECTOR", "NORMAL", "NORMAL", "NORMAL", "VECTOR", "NORMAL"})
end

function ENT:Setup()
	self.Value = 0
	self.PrevOutput = nil

	--self:ShowOutput(0, 0, 0)
	Wire_TriggerOutput(self, "X", 0)
	Wire_TriggerOutput(self, "Y", 0)
	Wire_TriggerOutput(self, "Z", 0)
	Wire_TriggerOutput(self, "Vector", Vector(0,0,0))
	Wire_TriggerOutput(self, "Recall X", 0)
	Wire_TriggerOutput(self, "Recall Y", 0)
	Wire_TriggerOutput(self, "Recall Z", 0)
	Wire_TriggerOutput(self, "Recall Vector", Vector(0,0,0))
	Wire_TriggerOutput(self, "Current Memory", 0)
end

function ENT:Think()
	BaseClass.Think(self)

	local pos = self:GetPos()

	Wire_TriggerOutput(self, "X", pos.x)
	Wire_TriggerOutput(self, "Y", pos.y)
	Wire_TriggerOutput(self, "Z", pos.z)
	Wire_TriggerOutput(self, "Vector", pos)
	Wire_TriggerOutput(self, "Current Memory", self.arrayindex)

	if self.arrayindex > 0 then
		Wire_TriggerOutput(self, "Recall X", self.storedpositions[self.arrayindex].x)
		Wire_TriggerOutput(self, "Recall Y", self.storedpositions[self.arrayindex].y)
		Wire_TriggerOutput(self, "Recall Z", self.storedpositions[self.arrayindex].z)
		Wire_TriggerOutput(self, "Recall Vector", self.storedpositions[self.arrayindex])
	else
		Wire_TriggerOutput(self, "Recall X", 0)
		Wire_TriggerOutput(self, "Recall Y", 0)
		Wire_TriggerOutput(self, "Recall Z", 0)
		Wire_TriggerOutput(self, "Recall Vector", Vector(0,0,0))
	end

	self:NextThink(CurTime()+0.04)
	return true
end

function ENT:TriggerInput(iname, value)
	if (iname == "Store/Save Pos") then
		if (value ~= 0) then
			local curpos = self:GetPos()
			table.insert(self.storedpositions, curpos)
			self.arrayindex = self.arrayindex+1
		end
	elseif (iname == "Next") then
		if (value ~= 0) then
			if # self.storedpositions > 0 then
				if self.arrayindex < #self.storedpositions then
					self.arrayindex = self.arrayindex+1;
				else
					self.arrayindex = 1; --loop back
				end
			end
		end
	elseif (iname == "Remove Save Position") then
		if (value ~= 0) then
			if self.arrayindex ~= 0 then
				table.remove(self.storedpositions, self.arrayindex)
			end
			if (self.arrayindex == 1) and (# self.storedpositions == 0) then
				self.arrayindex = 0
			end
			if (self.arrayindex == (# self.storedpositions+1)) then
				self.arrayindex = self.arrayindex-1
			end
		end
	end
end

duplicator.RegisterEntityClass("gmod_wire_gps", WireLib.MakeWireEnt, "Data")
