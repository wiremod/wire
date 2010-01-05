ENT.Type           = "anim"
ENT.Base           = "base_wire_entity"

ENT.PrintName      = "Wire Control Panel"
ENT.Author         = ""
ENT.Contact        = ""
ENT.Purpose        = ""
ENT.Instructions   = ""

ENT.Spawnable      = false
ENT.AdminSpawnable = false

function ENT:InitializeShared()
	self.channels = { 0, 0, 0, 0, 0, 0, 0, 0 }
end

if SERVER then
	function ENT:SetChannelValue(channel_number, value)
		if self.channels[channel_number] == value then return end

		self.channels[channel_number] = value
		umsg.Start("wire_panel_data", self.rp)
			umsg.Short(self:EntIndex())
			umsg.Char(channel_number)
			umsg.Float(value)
			umsg.Char(0)
		umsg.End()
	end

	function ENT:SetChannelNumber(channel_number)
		if self.chan == channel_number then return end

		self.chan = channel_number
		Wire_TriggerOutput(self, "Out", self.channels[self.chan])

		umsg.Start("wire_panel_data", self.rp)
			umsg.Short(self:EntIndex())
			umsg.Char(-1)
			umsg.Char(self.chan)
			umsg.Char(0)
		umsg.End()
	end

	concommand.Add("wire_panel_data", function(ply, cmd, args)
		local self = Entity(tonumber(args[1]))
		if not self:IsValid() then return end
		local what = args[2]

		if what == "r" then
			-- register and transmit channel values
			self:Retransmit(ply)

		elseif what == "c" then
			-- set current channel
			if not gamemode.Call("PlayerUse", ply, self) then return end

			self:SetChannelNumber(math.Clamp(tonumber(args[3]) or 1, 1, #self.channels))
		end
	end)

	function ENT:Retransmit(ply)
		self.rp:AddPlayer(ply)
		umsg.Start("wire_panel_data", ply)
			umsg.Short(self:EntIndex())
			for channel_number,value in ipairs(self.channels) do
				umsg.Char(channel_number)
				umsg.Float(value)
			end
			umsg.Char(-1)
			umsg.Char(self.chan)
			umsg.Char(0)
		umsg.End()
	end
else
	usermessage.Hook("wire_panel_data", function(um)
		local self = Entity(um:ReadShort())
		if self:IsValid() and self.ReceiveChannel then self:ReceiveChannel(um) end
	end)

	function ENT:ReceiveChannel(um)
		local channel_number = um:ReadChar()
		while channel_number ~= 0 do
			if channel_number > 0 then
				local value = um:ReadFloat()
				self.channels[channel_number] = value
			elseif channel_number == -1 then
				self.chan = um:ReadChar()
			end

			channel_number = um:ReadChar()
		end
	end

	function ENT:ChangeChannelNumber(channel_number)
		RunConsoleCommand("wire_panel_data", self:EntIndex(), "c", channel_number)
	end
end -- SERVER

function ENT:GetChannelValue(channel_number)
	return self.channels[channel_number]
end
