AddCSLuaFile()
DEFINE_BASECLASS( "base_wire_entity" )
ENT.PrintName       = "Wire Radio"
ENT.WireDebugName = "Radio"

if CLIENT then return end -- No more client

local MODEL = Model( "models/props_lab/binderblue.mdl" )

local Channel = {
	__index = {
		register = function(self, ent)
			local olddata = ent.ChannelData
			ent.ChannelData = self
			if olddata then
				self:updateChannel(olddata)
			else
				ent:NotifyDataRecieved()
			end
			table.insert(self.subscribers, ent)
		end,
		unregister = function(self, ent)
			table.RemoveByValue(self.subscribers, ent)
		end,
		isEmpty = function(self)
			return #self.subscribers == 0
		end,
		send = function(self, ent, subch, x)
			self.data[subch] = x
			for k, v in ipairs(self.subscribers) do
				if v ~= ent then
					v:NotifyDataRecieved(subch)
				end
			end
		end,
		updateChannel = function(self, other)
			for i=1,32 do
				self.data[i] = other.data[i]
			end
			for k, v in ipairs(self.subscribers) do
				v:NotifyDataRecieved()
			end
		end
	},
	__call = function(meta)
		return setmetatable({
			data = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
			subscribers = {}
		}, meta)
	end
}
setmetatable(Channel, Channel)

local Channels = setmetatable({},{__index = function(t,k) local r=Channel() t[k]=r return r end})
local Secure_Channels = setmetatable({},{__index = function(t,k) local r=setmetatable({},{__index = function(t,k) local r=Channel() t[k]=r return r end}) t[k]=r return r end})

function Radio_Register(ent, channel)
	local chan
	if ent.Secure then
		chan = Secure_Channels[ent.Steamid][channel]
	else
		chan = Channels[channel]
	end
	if ent.ChannelData ~= nil then
		if ent.ChannelData == chan then
			return
		else
			Radio_ChangeChannel(ent, channel)
			return
		end
	end
	ent.Channel = channel
	chan:register(ent)
end

function Radio_Unregister(ent)
	ent.ChannelData = nil
	if ent.Secure then
		local chan = Secure_Channels[ent.Steamid][ent.Channel]
		chan:unregister(ent)
		if chan:isEmpty() then
			Secure_Channels[ent.Steamid][ent.Channel] = nil
			if next(Secure_Channels[ent.Steamid])==nil then
				Secure_Channels[ent.Steamid] = nil
			end
		end
	else
		local chan = Channels[ent.Channel]
		chan:unregister(ent)
		if chan:isEmpty() then
			Channels[ent.Channel] = nil
		end
	end
end

function Radio_ChangeChannel(ent, chan)
	Radio_Unregister(ent)
	Radio_Register(ent, chan)
end

function ENT:Initialize()
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )
end

function ENT:Setup(channel,values,secure)
	self.Channel = tostring(tonumber(channel) or "0")
	self.Secure = secure==true
	if (tonumber(values) == nil) then
		self.values = 4
		self.Old = true
	else
		self.values = math.Clamp(math.floor(values),1,32)
		self.Old = false
	end

	local onames = {}
	local inames = {}
	if self.Old then
		onames = {"A","B","C","D"}
		inames = {"A","B","C","D","Channel"}
	else
		for i = 1,self.values do
			onames[i] = tostring(i)
			inames[i] = onames[i]
		end
		inames[#inames + 1] = "Channel"
	end
	self.inames = inames
	self.onames = onames

	self.Inputs = WireLib.CreateInputs(self,inames)
	self.Outputs = WireLib.CreateOutputs(self,onames)

	self.Steamid = self:GetPlayer():SteamID()
	Radio_Register(self, self.Channel)
end

function ENT:TriggerInput(iname, value)
	if (iname == "Channel") then
		Radio_ChangeChannel(self, tostring(value))
	else
		if (self.Old == true) then
			if (iname == "A") then
				self.ChannelData:send(self,1,value)
			elseif (iname == "B") then
				self.ChannelData:send(self,2,value)
			elseif (iname == "C") then
				self.ChannelData:send(self,3,value)
			elseif (iname == "D") then
				self.ChannelData:send(self,4,value)
			end
		else
			self.ChannelData:send(self,tonumber(iname),value)
		end
		self:NextThink(CurTime())
	end
end

function ENT:NotifyDataRecieved(subch)
	WireLib.TriggerOutput(self,self.onames[subch],self.ChannelData.data[subch])
	self:NextThink(CurTime())
end

function ENT:ReadCell(Address)
	Address = math.floor(Address+1)
	if (Address > 0) and (Address <= self.values) then
		return self.ChannelData.data[Address]
	else
		return nil
	end
end

function ENT:WriteCell(Address, value)
	Address = math.floor(Address+1)
	if (Address > 0) and (Address <= self.values) then
		self.ChannelData:send(self,Address,value)
		self.Inputs[self.inames[Address]].Value = value
		self:NextThink(CurTime())
		return true
	else
		return false
	end
end

function ENT:ShowOutput()
	local overlay = {"(Channel " .. self.Channel .. ")\nTransmit"}
	for i=1,self.values do
		overlay[#overlay + 1] = " " .. i .. ":" .. math.Round((self.Inputs[self.inames[i]].Value)*1000)/1000
	end
	overlay[#overlay + 1] = "\nReceive"
	for i=1,self.values do
		overlay[#overlay + 1] = " " .. i .. ":" .. math.Round((self.Outputs[self.onames[i]].Value)*1000)/1000
	end
	if (self.Secure == true) then overlay[#overlay + 1] = "\nSecured" end
	self:SetOverlayText(table.concat(overlay))
end

function ENT:OnRestore()
	Radio_Register(self, self.Channel)
	BaseClass.OnRestore(self)
end

function ENT:OnRemove()
	Radio_Unregister(self)
end

function ENT:Think()
	self:ShowOutput()
	self:NextThink(CurTime()+1e3)
	return true
end

duplicator.RegisterEntityClass("gmod_wire_radio", WireLib.MakeWireEnt, "Data", "Channel", "values", "Secure")
