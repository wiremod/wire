AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

ENT.WireDebugName = "MultiSegmentLcdScreen"



function ENT:InitInteractive()
	local model = self:GetModel()
	local outputs = {"Memory"}
	local interactivemodel = WireLib.GetInteractiveModel(model)
	for i=1, #interactivemodel.widgets do
		outputs[i+1] = interactivemodel.widgets[i].name
	end
	self.BlockInput = false
	self.NextPrompt = 0
	self.Outputs=WireLib.CreateOutputs(self,outputs)
	self.IsInteractive = true
	self:UpdateOverlay()
end

util.AddNetworkString("wire_multisegmentlcd_init")

function ENT:Initialize()
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)

	self.InteractiveData = {}
	self.IsInteractive = false
	if WireLib.IsValidInteractiveModel(self:GetModel()) then
		self:InitInteractive()
	else
		self.Outputs = WireLib.CreateOutputs(self, { "Memory" })
	end

	self.ResolutionW = 1024
	self.ResolutionH = 1024
	
	self.Memory = {}
	self.Cache = GPUCacheManager(self,true)
end

function ENT:SendSerializedTree(ply)
	if self.Tree == nil then return end
	local serialized = WireLib.von.serialize(self.Tree)
	if #serialized > 65535 then
		return
	end
	WireLib.netStart(self)
		net.WriteEntity(self)
		net.WriteUInt(#serialized,16)
		net.WriteData(serialized)
		net.WriteUInt(self.ResolutionW,16)
		net.WriteUInt(self.ResolutionH,16)
	WireLib.netEnd(ply)
end

function ENT:Retransmit(ply)
	self:SendSerializedTree(ply)
	
	self.Cache:Flush()
	for address,value in pairs(self.Memory) do
		self.Cache:Write(address,value)
	end
	self.Cache:Flush(ply)
end

function ENT:Setup(IsInteractive, ResolutionW, ResolutionH)
	self.IsInteractive = WireLib.IsValidInteractiveModel(self:GetModel()) and (IsInteractive == 1)
	self.ResolutionW = ResolutionW
	self.ResolutionH = ResolutionH
	self:Retransmit()
end

function ENT:ReadCell(Address)
	Address = math.floor(Address)
	if Address < 0 then return nil end

	return self.Memory[Address]
end

function ENT:WriteCell(Address, value)
	Address = math.floor(Address)
	if Address < 0 then return false end

	self.Memory[Address] = value
	self.Cache:Write(Address, value)
	return true
end

function ENT:TriggerInput(iname, value)

end

function ENT:Think()
	self.Cache:Flush()
	self:NextThink(CurTime()+0.01)
	return true
end


function ENT:ReceiveData()
	if not self.IsInteractive then return end
	local data = WireLib.GetInteractiveModel(self:GetModel()).widgets
	for i = 1, #data do
		WireLib.TriggerOutput(self, data[i].name, net.ReadFloat())
	end
end


function ENT:UpdateOverlay()
	if not self.IsInteractive then
		return
	end

	txt = ""
	if IsValid(self.User) then
		txt = "In use by: " .. self.User:Nick()
	end

	self:SetOverlayText(txt)
end



function ENT:Prompt( ply )
	if not self.IsInteractive then return end
	if ply then
		if CurTime() < self.NextPrompt then return end -- anti spam
		self.NextPrompt = CurTime() + 0.1

		if IsValid( self.User ) then
			WireLib.AddNotify(ply,"That interactive prop is in use by another player!",NOTIFY_ERROR,5,6)
			return
		end

		self.User = ply

		net.Start( "wire_interactiveprop_show" )
			net.WriteEntity( self )
		net.Send( ply )
	else
		self:Prompt( self:GetPlayer() ) -- prompt for owner
	end
end

function ENT:Use(ply)
	if not IsValid( ply ) then return end
	self:Prompt( ply )
end

function ENT:Unprompt()
	if not self.IsInteractive then return end
	self.User = nil
end

duplicator.RegisterEntityClass("gmod_wire_multisegmentlcd", WireLib.MakeWireEnt, "Data", "IsInteractive")
