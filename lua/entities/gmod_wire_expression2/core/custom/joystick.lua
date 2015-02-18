
--[[
	Joystick Extension
	By: Sparky
]]--


E2Lib.RegisterExtension( "joystick", true )

local joystickdata = {}

util.AddNetworkString("E2_joystick_sendstream")
util.AddNetworkString("E2_joystick_setstream")
util.AddNetworkString("E2_joystick_getdata")
util.AddNetworkString("E2_joystick_senddata")

net.Receive("E2_joystick_sendstream",function(u,ply)
	if joystickdata[ply] and joystickdata[ply].active_joystick then 
		local tbl = joystickdata[ply].joysticks[joystickdata[ply].active_joystick]
		if tbl then
			for I=1, tbl.num_axis do
				tbl.axis_data[I] = net.ReadUInt(16)
			end
			for I=1, tbl.num_buttons do
				tbl.button_data[I] = net.ReadBit()
			end
			for I=1, tbl.num_povs do
				tbl.pov_data[I] = net.ReadUInt(16)
			end
		end
	end
end)

net.Receive("E2_joystick_senddata", function(u,ply)
	local count = net.ReadUInt(8)
	if count>0 then
		local tbl = {}
		for I=1, count do
			tbl[I] = {
				name = net.ReadString(), 
				num_axis = net.ReadUInt(8), 
				num_buttons = net.ReadUInt(8),
				num_povs = net.ReadUInt(8), 
				axis_data = {},
				button_data = {},
				pov_data = {}
			}
		end
		local r
		if joystickdata[ply] then r = joystickdata[ply].Ref else r = {} end
		joystickdata[ply] = {joysticks = tbl, Ref = r}
	end
end)

local function setJoystickStream(self,ply,enum,on)
	if joystickdata[ply] then
		if not ply:IsValid() then joystickdata[ply] = nil return end
		
		local enabled = on ~= 0
		
		net.Start("E2_joystick_setstream")
		net.WriteUInt(enum, 8)
		net.WriteBit(enabled)
		net.Send(ply)
		
		if enabled then
			joystickdata[ply].Ref[self] = true
			joystickdata[ply].active_joystick = enum
		else
			joystickdata[ply].Ref[self] = nil
			joystickdata[ply].active_joystick = nil
		end	
	end
end

hook.Add("PlayerDisconnect","wire_joystick_clear",function(ply)
	joystickdata[ply] = nil
end)

hook.Add("PlayerEnteredVehicle","wire_joystick_vehicle",function(ply, veh)
	local tbl = joystickdata[veh]
	if tbl then
		setJoystickStream(tbl.chip, ply, tbl.enum, 1)
		tbl.player = ply
	end
end)

hook.Add("PlayerLeaveVehicle","wire_joystick_vehicle",function(ply, veh)
	local tbl = joystickdata[veh]
	if tbl and tbl.player then
		setJoystickStream(tbl.chip, ply, 1, 0)
		tbl.player = nil
	end
end)

__e2setcost( 200 )

e2function void joystickRefresh()
	net.Start("E2_joystick_getdata")
	net.Send(self.player)
end

e2function void joystickSetActive(enum, on)
	setJoystickStream(self.player, enum, on)
end

e2function void entity:joystickSetActive(enum, on)
	if IsValid(this) and this:IsVehicle() then
		if on ~= 0 then
			joystickdata[this] = {chip = self, enum = enum}
		else
			joystickdata[this] = nil
		end
	end
end

__e2setcost( 5 )

e2function number entity:joystickCount()
	if joystickdata[this] then
		return #joystickdata[this].joysticks
	else
		return 0
	end
end

e2function string entity:joystickName(enum)
	if joystickdata[this] and joystickdata[this].joysticks[enum] then
		return joystickdata[this].joysticks[enum].name
	else
		return ""
	end
end

e2function number entity:joystickAxisCount(enum)
	if joystickdata[this] and joystickdata[this].joysticks[enum] then
		return joystickdata[this].joysticks[enum].num_axis
	else
		return 0
	end
end

e2function number entity:joystickButtonCount(enum)
	if joystickdata[this] and joystickdata[this].joysticks[enum] then
		return joystickdata[this].joysticks[enum].num_buttons
	else
		return 0
	end
end

e2function number entity:joystickPOVCount(enum)
	if joystickdata[this] and joystickdata[this].joysticks[enum] then
		return joystickdata[this].joysticks[enum].num_povs
	else
		return 0
	end
end

e2function array entity:joystickAxisData(enum)
	if joystickdata[this] and joystickdata[this].joysticks[enum] then
		return table.Copy(joystickdata[this].joysticks[enum].axis_data)
	else
		return {}
	end
end

e2function array entity:joystickButtonData(enum)
	if joystickdata[this] and joystickdata[this].joysticks[enum] then
		return table.Copy(joystickdata[this].joysticks[enum].button_data)
	else
		return {}
	end
end

e2function array entity:joystickPOVData(enum)
	if joystickdata[this] and joystickdata[this].joysticks[enum] then
		return table.Copy(joystickdata[this].joysticks[enum].pov_data)
	else
		return {}
	end
end

registerCallback( "destruct", function( self )
	if not IsValid(self.player) then joysticks[self.player] = nil end
	if joystickdata[self.player] then
		joystickdata[self.player].Ref[self] = nil
		if not next(joystickdata[self.player].Ref) then
			setJoystickStream(self.player,1,0)
		end
	end
	
	for k, v in pairs(joystickdata) do
		if v.chip == self then
			if v.player then
				setJoystickStream(v.player,1,0)
			end
			joystickdata[k] = nil
		end
	end
end)