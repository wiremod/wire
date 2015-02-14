
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

hook.Add("PlayerDisconnect","wire_joystick_clear",function(ply)
	joystickdata[ply] = nil
end)

__e2setcost( 200 )

e2function void joystickRefresh()
	net.Start("E2_joystick_getdata")
	net.Send(self.player)
end

e2function void joystickSetActive(enum, on)
	if not IsValid(self.player) then joystickdata[self.player] = nil end
	if joystickdata[self.player] and joystickdata[self.player].joysticks[enum] then
		local enabled = on ~= 0
		
		net.Start("E2_joystick_setstream")
		net.WriteUInt(enum, 8)
		net.WriteBit(enabled)
		net.Send(self.player)
		
		if enabled then
			joystickdata[self.player].Ref[self] = true
			joystickdata[self.player].active_joystick = enum
		else
			joystickdata[self.player].Ref[self] = nil
			joystickdata[self.player].active_joystick = nil
		end	
	end
end

__e2setcost( 5 )

e2function number joystickCount()
	if joystickdata[self.player] then
		return #joystickdata[self.player].joysticks
	else
		return 0
	end
end

e2function string joystickName(enum)
	if joystickdata[self.player] and joystickdata[self.player].joysticks[enum] then
		return joystickdata[self.player].joysticks[enum].name
	else
		return ""
	end
end

e2function number joystickAxisCount(enum)
	if joystickdata[self.player] and joystickdata[self.player].joysticks[enum] then
		return joystickdata[self.player].joysticks[enum].num_axis
	else
		return 0
	end
end

e2function number joystickButtonCount(enum)
	if joystickdata[self.player] and joystickdata[self.player].joysticks[enum] then
		return joystickdata[self.player].joysticks[enum].num_buttons
	else
		return 0
	end
end

e2function number joystickPOVCount(enum)
	if joystickdata[self.player] and joystickdata[self.player].joysticks[enum] then
		return joystickdata[self.player].joysticks[enum].num_povs
	else
		return 0
	end
end

e2function array joystickAxisData(enum)
	if joystickdata[self.player] and joystickdata[self.player].joysticks[enum] then
		return joystickdata[self.player].joysticks[enum].axis_data
	else
		return {}
	end
end

e2function array joystickButtonData(enum)
	if joystickdata[self.player] and joystickdata[self.player].joysticks[enum] then
		return joystickdata[self.player].joysticks[enum].button_data
	else
		return {}
	end
end

e2function array joystickPOVData(enum)
	if joystickdata[self.player] and joystickdata[self.player].joysticks[enum] then
		return joystickdata[self.player].joysticks[enum].pov_data
	else
		return {}
	end
end

registerCallback( "destruct", function( self )
	if not IsValid(self.player) then joysticks[self.player] = nil end
	if joystickdata[self.player] then
		joystickdata[self.player].Ref[self] = nil
		if not next(joystickdata[self.player].Ref) then
			net.Start("E2_joystick_setstream")
			net.WriteUInt(0, 8)
			net.WriteBit(false)
			net.Send(self.player)
		end
	end
end)