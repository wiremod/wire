AddCSLuaFile()
DEFINE_BASECLASS( "gmod_wire_socket" )
ENT.PrintName		= "Wire Data Socket"
ENT.WireDebugName = "Socket"

function ENT:GetPlugClass()
	return "gmod_wire_dataplug"
end

if CLIENT then
	local sockets = ents.FindByClass("gmod_wire_datasocket") or {}
	local function DrawLinkHelperLinefunction()
		for k,self in ipairs( sockets ) do
			local Pos, _ = self:GetLinkPos()

			local Closest = self:GetClosestPlug()

			if IsValid(Closest) and self:CanLink(Closest) and Closest:GetNWBool( "PlayerHolding", false ) and Closest:GetClosestSocket() == self then
				local plugpos = Closest:GetPos():ToScreen()
				local socketpos = Pos:ToScreen()
				surface.SetDrawColor(255,255,100,255)
				surface.DrawLine(plugpos.x, plugpos.y, socketpos.x, socketpos.y)
			end
		end
	end

	function ENT:DrawEntityOutline() end -- never draw outline

	function ENT:Initialize()
		self:CacheData()
		table.insert(sockets, self)
		if #sockets == 1 then
			hook.Add("HUDPaint", "Wire_DataSocket_DrawLinkHelperLine",DrawLinkHelperLinefunction)
		end
	end

	function ENT:OnRemove()
		table.RemoveByValue(sockets, self)
		if #sockets == 0 then
			hook.Remove("HUDPaint", "Wire_DataSocket_DrawLinkHelperLine")
		end
	end

	return
end

function ENT:Initialize()
	self:CacheData()
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )

	self.Inputs = WireLib.CreateInputs(self, { "Memory" })
	self.Outputs = WireLib.CreateOutputs(self, { "Memory" })
	WireLib.TriggerOutput(self, "Memory", 0)

	self.Memory = nil
end

function ENT:Setup( WeldForce, AttachRange )
	self.WeldForce = WeldForce or 5000
	self.AttachRange = AttachRange or 5
	self:SetNWInt( "AttachRange", self.AttachRange )
end

-- Override some functions from gmod_wire_socket
function ENT:ResendValues()
	self:SetMemory(self.Plug.Memory)
end
function ENT:ResetValues()
	self.Memory = nil --We're now getting no signal
	WireLib.TriggerOutput(self, "Memory", 0)
end

duplicator.RegisterEntityClass( "gmod_wire_datasocket", WireLib.MakeWireEnt, "Data", "WeldForce", "AttachRange" )

function ENT:SetMemory(mement)
	self.Memory = mement
	WireLib.TriggerOutput(self, "Memory", 1)
end

function ENT:ReadCell( Address, infloop )
	infloop = infloop or 0
	if infloop > 50 then return end
	Address = math.floor(Address)

	if (self.Memory) then
		if (self.Memory.ReadCell) then
			return self.Memory:ReadCell( Address, infloop + 1 )
		else
			return nil
		end
	else
		return nil
	end
end

function ENT:WriteCell( Address, value, infloop )
	infloop = infloop or 0
	if infloop > 50 then return end
	Address = math.floor(Address)

	if (self.Memory) then
		if (self.Memory.WriteCell) then
			return self.Memory:WriteCell( Address, value, infloop + 1 )
		else
			return false
		end
	else
		return false
	end
end

function ENT:TriggerInput(iname, value, iter)
	if (iname == "Memory") then
		self.OwnMemory = self.Inputs.Memory.Src
	end
end

-- Override dupeinfo functions from wire plug
function ENT:BuildDupeInfo()
	local info = BaseClass.BuildDupeInfo(self)

	if info.Socket then info.Socket.ArrayInput = nil end -- this input is not used on this entity

	return info
end

function ENT:GetApplyDupeInfoParams(info)
	return info.Socket.WeldForce, info.Socket.AttachRange
end

duplicator.RegisterEntityClass("gmod_wire_datasocket", WireLib.MakeWireEnt, "Data", "WeldForce", "AttachRange")
