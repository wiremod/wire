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
	-- Edit the menu here. Maximum of 10 lines.
	self.menus = {
		[-1] = { "Channel", nil },
		[ 0] = { "Index", nil },
		{ "Ch. 1", "Channel 1" },
		{ "Ch. 2", "Channel 2" },
		{ "Ch. 3", "Channel 3" },
		{ "Ch. 4", "Channel 4" },
		{ "Ch. 5", "Channel 5" },
		{ "Ch. 6", "Channel 6" },
		{ "Ch. 7", "Channel 7" },
		{ "Ch. 8", "Channel 8" },
	}
	self.channels = {}
	for i = 1,#self.menus do
		self.channels[i] = 0
	end
	WireLib.umsgRegister(self)
end

if SERVER then
	function ENT:SetChannelValue(channel_number, value)
		if self.channels[channel_number] == value then return end

		self.channels[channel_number] = value
		self:umsg()
			self.umsg.Char(channel_number)
			self.umsg.Float(value)
			self.umsg.Char(0)
		self.umsg.End()
	end

	function ENT:SetChannelNumber(channel_number)
		if self.chan == channel_number then return end

		self.chan = channel_number
		Wire_TriggerOutput(self, "Out", self.channels[self.chan])

		self:umsg()
			self.umsg.Char(-1)
			self.umsg.Char(self.chan)
			self.umsg.Char(0)
		self.umsg.End()
	end

	concommand.Add("wire_panel_setchannel", function(ply, cmd, args)
		local self = Entity(tonumber(args[1]))
		if not self:IsValid() then return end

		-- set current channel
		if not gamemode.Call("PlayerUse", ply, self) then return end

		self:SetChannelNumber(math.Clamp(tonumber(args[2]) or 1, 1, #self.channels))
	end)

	function ENT:Retransmit(ply)
		self:umsg(ply)
			for channel_number,value in ipairs(self.channels) do
				self.umsg.Char(channel_number)
				self.umsg.Float(value)
			end
			self.umsg.Char(-1)
			self.umsg.Char(self.chan)
			self.umsg.Char(0)
		self.umsg.End()
	end
else
	function ENT:Receive(um)
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
		RunConsoleCommand("wire_panel_setchannel", self:EntIndex(), channel_number)
	end
end -- SERVER

function ENT:GetChannelValue(channel_number)
	return self.channels[channel_number]
end
